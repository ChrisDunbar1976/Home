-- Rhubarb Press Accounting System - Bank Balance Tracking System
-- Creates persistent bank balance tables with audit history
-- Automatically updates balances when transactions are added
-- Target: Azure SQL Database (rhubarbpressdb)
-- DEPLOYMENT-READY VERSION

USE rhubarbpressdb;
GO

PRINT 'Creating Bank Balance Tracking System for Rhubarb Press';
PRINT 'Date: ' + CONVERT(NVARCHAR(19), GETDATE(), 120);
PRINT '';
GO

-- =============================================
-- Bank Balance Table (Current Balances)
-- =============================================
PRINT 'Creating BankBalance table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'BankBalance')
BEGIN
    CREATE TABLE BankBalance (
        BalanceID INT IDENTITY(1,1) PRIMARY KEY,
        AccountID INT NOT NULL,
        CurrentBalance MONEY NOT NULL DEFAULT 0,
        LastTransactionID INT NULL, -- Last transaction that affected this balance
        dtModified DATETIME2 NOT NULL DEFAULT GETDATE(),
        CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
        IsActive BIT DEFAULT 1,
        FOREIGN KEY (AccountID) REFERENCES ChartOfAccounts(AccountID),
        FOREIGN KEY (LastTransactionID) REFERENCES Transactions(TransactionID)
    );
    PRINT 'BankBalance table created';
END
ELSE
BEGIN
    PRINT 'BankBalance table already exists';
END
GO

-- Unique constraint - one balance record per account
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'UX_BankBalance_Account' AND object_id = OBJECT_ID('BankBalance'))
BEGIN
    SET ANSI_NULLS ON;
    SET QUOTED_IDENTIFIER ON;
    CREATE UNIQUE INDEX UX_BankBalance_Account ON BankBalance(AccountID) WHERE IsActive = 1;
    PRINT 'Created unique index UX_BankBalance_Account';
END
GO

-- =============================================
-- Bank Balance History Table (Audit Trail)
-- =============================================
PRINT 'Creating BankBalanceHistory table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'BankBalanceHistory')
BEGIN
    CREATE TABLE BankBalanceHistory (
        HistoryID INT IDENTITY(1,1) PRIMARY KEY,
        BalanceID INT NOT NULL,
        AccountID INT NOT NULL,
        PreviousBalance MONEY NOT NULL,
        NewBalance MONEY NOT NULL,
        BalanceChange MONEY NOT NULL, -- Calculated: NewBalance - PreviousBalance
        TransactionID INT NULL, -- Transaction that caused this change (NULL for opening balances)
        TransactionDate DATE NOT NULL,
        TransactionDescription NVARCHAR(255) NULL,
        TransactionAmount MONEY NOT NULL,
        ChangeType NVARCHAR(20) NOT NULL CHECK (ChangeType IN ('Credit', 'Debit', 'Opening', 'Adjustment')),
        RecordedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
        RecordedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
        FOREIGN KEY (BalanceID) REFERENCES BankBalance(BalanceID),
        FOREIGN KEY (AccountID) REFERENCES ChartOfAccounts(AccountID),
        FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID)
    );
    PRINT 'BankBalanceHistory table created';
END
ELSE
BEGIN
    PRINT 'BankBalanceHistory table already exists';
END
GO

-- =============================================
-- Indexes for Performance
-- =============================================
PRINT 'Creating indexes for performance...';
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_BankBalanceHistory_Account' AND object_id = OBJECT_ID('BankBalanceHistory'))
BEGIN
    CREATE INDEX IX_BankBalanceHistory_Account ON BankBalanceHistory(AccountID);
    PRINT 'Created index IX_BankBalanceHistory_Account';
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_BankBalanceHistory_Transaction' AND object_id = OBJECT_ID('BankBalanceHistory'))
BEGIN
    CREATE INDEX IX_BankBalanceHistory_Transaction ON BankBalanceHistory(TransactionID);
    PRINT 'Created index IX_BankBalanceHistory_Transaction';
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_BankBalanceHistory_Date' AND object_id = OBJECT_ID('BankBalanceHistory'))
BEGIN
    CREATE INDEX IX_BankBalanceHistory_Date ON BankBalanceHistory(TransactionDate);
    PRINT 'Created index IX_BankBalanceHistory_Date';
END
GO

-- =============================================
-- Initialize Bank Balance Procedure
-- =============================================
PRINT 'Creating sp_InitializeBankBalance procedure...';
GO

CREATE OR ALTER PROCEDURE sp_InitializeBankBalance
    @AccountCode NVARCHAR(20) = '1001',
    @OpeningBalance MONEY = 10000.00,
    @OpeningDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AccountID INT;
    DECLARE @BalanceID INT;
    DECLARE @ErrorMessage NVARCHAR(500);

    BEGIN TRY
        -- Set default opening date if not provided
        IF @OpeningDate IS NULL
            SET @OpeningDate = CAST(GETDATE() AS DATE);

        -- Get the account ID
        SELECT @AccountID = AccountID
        FROM ChartOfAccounts
        WHERE AccountCode = @AccountCode AND AccountType = 'Asset';

        IF @AccountID IS NULL
        BEGIN
            RAISERROR('Bank account with code %s not found', 16, 1, @AccountCode);
            RETURN;
        END

        -- Check if balance already exists
        SELECT @BalanceID = BalanceID
        FROM BankBalance
        WHERE AccountID = @AccountID AND IsActive = 1;

        IF @BalanceID IS NOT NULL
        BEGIN
            DECLARE @CurrentBalance MONEY;
            SELECT @CurrentBalance = CurrentBalance FROM BankBalance WHERE BalanceID = @BalanceID;

            PRINT 'Bank balance already exists for account ' + @AccountCode;
            PRINT 'Current balance: £' + CAST(@CurrentBalance AS NVARCHAR(20));
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Create the balance record
        INSERT INTO BankBalance (AccountID, CurrentBalance, dtModified)
        VALUES (@AccountID, @OpeningBalance, GETDATE());

        SET @BalanceID = SCOPE_IDENTITY();

        -- Create opening balance history record
        INSERT INTO BankBalanceHistory (
            BalanceID, AccountID, PreviousBalance, NewBalance, BalanceChange,
            TransactionID, TransactionDate, TransactionDescription, TransactionAmount,
            ChangeType, RecordedBy
        )
        VALUES (
            @BalanceID, @AccountID, 0, @OpeningBalance, @OpeningBalance,
            NULL, @OpeningDate, 'Opening Balance', @OpeningBalance,
            'Opening', 'System - Opening Balance'
        );

        COMMIT TRANSACTION;

        PRINT 'Bank balance initialized successfully:';
        PRINT '  Account: ' + @AccountCode;
        PRINT '  Opening Balance: £' + CAST(@OpeningBalance AS NVARCHAR(20));
        PRINT '  Date: ' + CAST(@OpeningDate AS NVARCHAR(10));

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMessage = 'Error initializing bank balance: ' + ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

-- =============================================
-- Update Bank Balance Procedure
-- =============================================
PRINT 'Creating sp_UpdateBankBalance procedure...';
GO

CREATE OR ALTER PROCEDURE sp_UpdateBankBalance
    @TransactionID INT,
    @AccountID INT,
    @BalanceChange MONEY,
    @ChangeType NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BalanceID INT;
    DECLARE @PreviousBalance MONEY;
    DECLARE @NewBalance MONEY;
    DECLARE @TransactionDate DATE;
    DECLARE @TransactionDescription NVARCHAR(255);
    DECLARE @TransactionAmount MONEY;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Get transaction details
        SELECT
            @TransactionDate = TransactionDate,
            @TransactionDescription = Description,
            @TransactionAmount = TotalAmount
        FROM Transactions
        WHERE TransactionID = @TransactionID;

        -- Get current balance
        SELECT @BalanceID = BalanceID, @PreviousBalance = CurrentBalance
        FROM BankBalance
        WHERE AccountID = @AccountID AND IsActive = 1;

        IF @BalanceID IS NULL
        BEGIN
            RAISERROR('No active balance record found for AccountID %d', 16, 1, @AccountID);
            RETURN;
        END

        -- Calculate new balance
        SET @NewBalance = @PreviousBalance + @BalanceChange;

        -- Update the current balance
        UPDATE BankBalance
        SET CurrentBalance = @NewBalance,
            LastTransactionID = @TransactionID,
            dtModified = GETDATE()
        WHERE BalanceID = @BalanceID;

        -- Record the history
        INSERT INTO BankBalanceHistory (
            BalanceID, AccountID, PreviousBalance, NewBalance, BalanceChange,
            TransactionID, TransactionDate, TransactionDescription, TransactionAmount,
            ChangeType
        )
        VALUES (
            @BalanceID, @AccountID, @PreviousBalance, @NewBalance, @BalanceChange,
            @TransactionID, @TransactionDate, @TransactionDescription, @TransactionAmount,
            @ChangeType
        );

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(500) = 'Error updating bank balance: ' + ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

-- =============================================
-- Trigger: Auto-update bank balance on transaction insert
-- =============================================
PRINT 'Creating bank balance update trigger...';
GO

IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'tr_TransactionLines_UpdateBankBalance')
BEGIN
    EXEC('
    CREATE TRIGGER tr_TransactionLines_UpdateBankBalance
    ON TransactionLines
    AFTER INSERT
    AS
    BEGIN
        SET NOCOUNT ON;

        -- Only process bank account transactions
        DECLARE transaction_cursor CURSOR FOR
        SELECT
            i.TransactionID,
            i.AccountID,
            CASE
                WHEN i.DebitAmount > 0 THEN i.DebitAmount    -- Money into bank
                WHEN i.CreditAmount > 0 THEN -i.CreditAmount -- Money out of bank
                ELSE 0
            END as BalanceChange,
            CASE
                WHEN i.DebitAmount > 0 THEN ''Debit''
                WHEN i.CreditAmount > 0 THEN ''Credit''
                ELSE ''Unknown''
            END as ChangeType
        FROM inserted i
        INNER JOIN ChartOfAccounts coa ON i.AccountID = coa.AccountID
        WHERE coa.AccountCode = ''1001'' -- Bank account
            AND coa.AccountType = ''Asset''
            AND (i.DebitAmount > 0 OR i.CreditAmount > 0);

        DECLARE @TransactionID INT, @AccountID INT, @BalanceChange MONEY, @ChangeType NVARCHAR(20);

        OPEN transaction_cursor;
        FETCH NEXT FROM transaction_cursor INTO @TransactionID, @AccountID, @BalanceChange, @ChangeType;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Update the bank balance
            EXEC sp_UpdateBankBalance @TransactionID, @AccountID, @BalanceChange, @ChangeType;

            FETCH NEXT FROM transaction_cursor INTO @TransactionID, @AccountID, @BalanceChange, @ChangeType;
        END

        CLOSE transaction_cursor;
        DEALLOCATE transaction_cursor;
    END
    ');
    PRINT 'Bank balance update trigger created';
END
ELSE
BEGIN
    PRINT 'Bank balance update trigger already exists';
END
GO

-- =============================================
-- Views for Balance Reporting
-- =============================================
PRINT 'Creating balance reporting views...';
GO

-- Current Bank Balances View
CREATE OR ALTER VIEW vw_CurrentBankBalances AS
SELECT
    coa.AccountCode,
    coa.AccountName,
    bb.CurrentBalance,
    bb.dtModified as LastModified,
    t.TransactionDate as LastTransactionDate,
    t.Description as LastTransactionDescription,
    bb.CreatedDate as BalanceCreatedDate
FROM BankBalance bb
INNER JOIN ChartOfAccounts coa ON bb.AccountID = coa.AccountID
LEFT JOIN Transactions t ON bb.LastTransactionID = t.TransactionID
WHERE bb.IsActive = 1;
GO

-- Bank Balance History View
CREATE OR ALTER VIEW vw_BankBalanceAuditTrail AS
SELECT TOP (100) PERCENT
    coa.AccountCode,
    coa.AccountName,
    bbh.TransactionDate,
    bbh.TransactionDescription,
    bbh.PreviousBalance,
    bbh.BalanceChange,
    bbh.NewBalance,
    bbh.ChangeType,
    bbh.TransactionAmount,
    bbh.RecordedDate,
    bbh.RecordedBy
FROM BankBalanceHistory bbh
INNER JOIN ChartOfAccounts coa ON bbh.AccountID = coa.AccountID
ORDER BY bbh.TransactionDate DESC, bbh.RecordedDate DESC;
GO

PRINT '';
PRINT '=== Bank Balance System Created Successfully ===';
PRINT 'Tables created:';
PRINT '  - BankBalance: Current balance tracking';
PRINT '  - BankBalanceHistory: Complete audit trail';
PRINT '';
PRINT 'Procedures created:';
PRINT '  - sp_InitializeBankBalance: Initialize bank balance';
PRINT '  - sp_UpdateBankBalance: Update balance on transactions';
PRINT '';
PRINT 'Trigger created:';
PRINT '  - tr_TransactionLines_UpdateBankBalance: Auto-update on transactions';
PRINT '';
PRINT 'Views created:';
PRINT '  - vw_CurrentBankBalances: Current balance summary';
PRINT '  - vw_BankBalanceAuditTrail: Balance change history';
PRINT '';
PRINT 'Next steps:';
PRINT '1. Run: EXEC sp_InitializeBankBalance ''1001'', 10000.00;';
PRINT '2. Import transactions - balances will update automatically';
PRINT '3. Query: SELECT * FROM vw_CurrentBankBalances;';
GO
