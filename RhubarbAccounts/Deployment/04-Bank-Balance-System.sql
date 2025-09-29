-- Rhubarb Press Accounting System - Bank Balance System
-- Complete bank balance tracking with automatic updates and audit trail
-- Target: Azure SQL Database (rhubarbpressdb)
-- IDEMPOTENT: Safe to run multiple times

USE rhubarbpressdb;
GO

PRINT 'Rhubarb Press Bank Balance System Deployment';
PRINT 'Deployment Date: ' + CONVERT(NVARCHAR(19), GETDATE(), 120);
PRINT '';

-- =============================================
-- Bank Balance Table
-- =============================================
PRINT 'Creating Bank Balance table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'BankBalance')
BEGIN
    CREATE TABLE BankBalance (
        BalanceID INT IDENTITY(1,1) PRIMARY KEY,
        AccountID INT NOT NULL,
        CurrentBalance MONEY NOT NULL DEFAULT 0,
        LastTransactionID INT NULL,
        LastUpdateDate DATETIME2 DEFAULT GETDATE(),
        dtModified DATETIME2 DEFAULT GETDATE(),
        IsActive BIT DEFAULT 1,
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (AccountID) REFERENCES ChartOfAccounts(AccountID)
        -- Note: No FK on LastTransactionID to avoid circular dependency
    );

    PRINT 'Bank Balance table created successfully';
END
ELSE
BEGIN
    PRINT 'Bank Balance table already exists';
END
GO

-- =============================================
-- Bank Balance History Table
-- =============================================
PRINT 'Creating Bank Balance History table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'BankBalanceHistory')
BEGIN
    CREATE TABLE BankBalanceHistory (
        HistoryID INT IDENTITY(1,1) PRIMARY KEY,
        AccountID INT NOT NULL,
        TransactionID INT NULL, -- NULL for opening balances
        PreviousBalance MONEY NOT NULL,
        BalanceChange MONEY NOT NULL,
        NewBalance MONEY NOT NULL,
        ChangeType NVARCHAR(20) NOT NULL CHECK (ChangeType IN ('Opening', 'Transaction', 'Adjustment', 'Correction')),
        Description NVARCHAR(255) NULL,
        RecordedDate DATETIME2 DEFAULT GETDATE(),
        RecordedBy NVARCHAR(50) NOT NULL DEFAULT SYSTEM_USER,
        FOREIGN KEY (AccountID) REFERENCES ChartOfAccounts(AccountID)
        -- Note: No FK on TransactionID to allow opening balances
    );

    PRINT 'Bank Balance History table created successfully';
END
ELSE
BEGIN
    PRINT 'Bank Balance History table already exists';
END
GO

-- =============================================
-- Bank Balance Update Trigger
-- =============================================
PRINT 'Creating bank balance update trigger...';
GO

CREATE OR ALTER TRIGGER tr_UpdateBankBalance
ON TransactionLines
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AccountID INT;
    DECLARE @TransactionID INT;
    DECLARE @BalanceChange MONEY = 0;
    DECLARE @PreviousBalance MONEY;
    DECLARE @NewBalance MONEY;
    DECLARE @Description NVARCHAR(255);

    -- Handle bank account updates only
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN ChartOfAccounts coa ON i.AccountID = coa.AccountID
        WHERE coa.AccountCode = '1001' AND coa.AccountType = 'Asset'
    ) OR EXISTS (
        SELECT 1
        FROM deleted d
        INNER JOIN ChartOfAccounts coa ON d.AccountID = coa.AccountID
        WHERE coa.AccountCode = '1001' AND coa.AccountType = 'Asset'
    )
    BEGIN
        -- Get bank account ID
        SELECT @AccountID = AccountID
        FROM ChartOfAccounts
        WHERE AccountCode = '1001' AND AccountType = 'Asset';

        -- Calculate balance change
        SELECT @BalanceChange =
            ISNULL(SUM(DebitAmount - CreditAmount), 0)
        FROM (
            SELECT DebitAmount, CreditAmount FROM inserted WHERE AccountID = @AccountID
            UNION ALL
            SELECT -DebitAmount, -CreditAmount FROM deleted WHERE AccountID = @AccountID
        ) changes;

        -- Get transaction details from first affected transaction
        SELECT TOP 1
            @TransactionID = COALESCE(i.TransactionID, d.TransactionID),
            @Description = t.Description
        FROM inserted i
        FULL OUTER JOIN deleted d ON i.LineID = d.LineID
        INNER JOIN Transactions t ON t.TransactionID = COALESCE(i.TransactionID, d.TransactionID)
        WHERE COALESCE(i.AccountID, d.AccountID) = @AccountID;

        -- Get current balance
        SELECT @PreviousBalance = ISNULL(CurrentBalance, 0)
        FROM BankBalance
        WHERE AccountID = @AccountID AND IsActive = 1;

        -- If no balance record exists, create one with zero starting balance
        IF @PreviousBalance IS NULL
        BEGIN
            INSERT INTO BankBalance (AccountID, CurrentBalance, LastTransactionID)
            VALUES (@AccountID, 0, NULL);
            SET @PreviousBalance = 0;
        END

        -- Calculate new balance
        SET @NewBalance = @PreviousBalance + @BalanceChange;

        -- Update bank balance
        UPDATE BankBalance
        SET CurrentBalance = @NewBalance,
            LastTransactionID = @TransactionID,
            dtModified = GETDATE()
        WHERE AccountID = @AccountID AND IsActive = 1;

        -- Record in history
        INSERT INTO BankBalanceHistory (
            AccountID, TransactionID, PreviousBalance, BalanceChange,
            NewBalance, ChangeType, Description
        )
        VALUES (
            @AccountID, @TransactionID, @PreviousBalance, @BalanceChange,
            @NewBalance, 'Transaction', @Description
        );
    END
END
GO

-- =============================================
-- Bank Balance Initialization Procedure
-- =============================================
PRINT 'Creating bank balance initialization procedure...';
GO

CREATE OR ALTER PROCEDURE sp_InitializeBankBalance
    @AccountCode NVARCHAR(20) = '1001',
    @OpeningBalance MONEY = 10000.00,
    @EffectiveDate DATE = NULL,
    @Description NVARCHAR(255) = 'Opening Bank Balance'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AccountID INT;
    DECLARE @ExistingBalance MONEY;
    DECLARE @ErrorMessage NVARCHAR(500);

    BEGIN TRY
        -- Default to today if no date provided
        IF @EffectiveDate IS NULL
            SET @EffectiveDate = CAST(GETDATE() AS DATE);

        -- Get account ID
        SELECT @AccountID = AccountID
        FROM ChartOfAccounts
        WHERE AccountCode = @AccountCode AND AccountType = 'Asset';

        IF @AccountID IS NULL
        BEGIN
            RAISERROR('Bank account with code %s not found', 16, 1, @AccountCode);
            RETURN;
        END

        -- Check if balance already exists
        SELECT @ExistingBalance = CurrentBalance
        FROM BankBalance
        WHERE AccountID = @AccountID AND IsActive = 1;

        IF @ExistingBalance IS NOT NULL
        BEGIN
            PRINT 'Bank balance already initialized with £' + FORMAT(@ExistingBalance, 'N2');
            PRINT 'Use sp_AdjustBankBalance to make corrections';
            RETURN;
        END

        -- Initialize bank balance
        INSERT INTO BankBalance (AccountID, CurrentBalance, LastTransactionID)
        VALUES (@AccountID, @OpeningBalance, NULL);

        -- Record opening balance in history
        INSERT INTO BankBalanceHistory (
            AccountID, TransactionID, PreviousBalance, BalanceChange,
            NewBalance, ChangeType, Description, RecordedBy
        )
        VALUES (
            @AccountID, NULL, 0, @OpeningBalance,
            @OpeningBalance, 'Opening', @Description, SYSTEM_USER
        );

        PRINT 'Bank balance initialized successfully';
        PRINT 'Account: ' + @AccountCode;
        PRINT 'Opening Balance: £' + FORMAT(@OpeningBalance, 'N2');
        PRINT 'Effective Date: ' + FORMAT(@EffectiveDate, 'dd/MM/yyyy');

    END TRY
    BEGIN CATCH
        SET @ErrorMessage = 'Error initializing bank balance: ' + ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

-- =============================================
-- Bank Balance Adjustment Procedure
-- =============================================
PRINT 'Creating bank balance adjustment procedure...';
GO

CREATE OR ALTER PROCEDURE sp_AdjustBankBalance
    @AccountCode NVARCHAR(20) = '1001',
    @AdjustmentAmount MONEY,
    @Reason NVARCHAR(255),
    @AdjustmentType NVARCHAR(20) = 'Adjustment'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AccountID INT;
    DECLARE @PreviousBalance MONEY;
    DECLARE @NewBalance MONEY;
    DECLARE @ErrorMessage NVARCHAR(500);

    BEGIN TRY
        -- Validate adjustment type
        IF @AdjustmentType NOT IN ('Adjustment', 'Correction')
        BEGIN
            RAISERROR('Invalid adjustment type. Use ''Adjustment'' or ''Correction''', 16, 1);
            RETURN;
        END

        -- Get account ID
        SELECT @AccountID = AccountID
        FROM ChartOfAccounts
        WHERE AccountCode = @AccountCode AND AccountType = 'Asset';

        IF @AccountID IS NULL
        BEGIN
            RAISERROR('Bank account with code %s not found', 16, 1, @AccountCode);
            RETURN;
        END

        -- Get current balance
        SELECT @PreviousBalance = CurrentBalance
        FROM BankBalance
        WHERE AccountID = @AccountID AND IsActive = 1;

        IF @PreviousBalance IS NULL
        BEGIN
            RAISERROR('Bank balance not initialized. Use sp_InitializeBankBalance first', 16, 1);
            RETURN;
        END

        -- Calculate new balance
        SET @NewBalance = @PreviousBalance + @AdjustmentAmount;

        -- Update balance
        UPDATE BankBalance
        SET CurrentBalance = @NewBalance,
            dtModified = GETDATE()
        WHERE AccountID = @AccountID AND IsActive = 1;

        -- Record in history
        INSERT INTO BankBalanceHistory (
            AccountID, TransactionID, PreviousBalance, BalanceChange,
            NewBalance, ChangeType, Description, RecordedBy
        )
        VALUES (
            @AccountID, NULL, @PreviousBalance, @AdjustmentAmount,
            @NewBalance, @AdjustmentType, @Reason, SYSTEM_USER
        );

        PRINT 'Bank balance adjusted successfully';
        PRINT 'Account: ' + @AccountCode;
        PRINT 'Previous Balance: £' + FORMAT(@PreviousBalance, 'N2');
        PRINT 'Adjustment: £' + FORMAT(@AdjustmentAmount, 'N2');
        PRINT 'New Balance: £' + FORMAT(@NewBalance, 'N2');
        PRINT 'Reason: ' + @Reason;

    END TRY
    BEGIN CATCH
        SET @ErrorMessage = 'Error adjusting bank balance: ' + ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

-- =============================================
-- Bank Balance Query Procedure
-- =============================================
PRINT 'Creating bank balance query procedure...';
GO

CREATE OR ALTER PROCEDURE sp_GetBankBalanceInfo
    @AccountCode NVARCHAR(20) = '1001'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AccountID INT;

    -- Get account ID
    SELECT @AccountID = AccountID
    FROM ChartOfAccounts
    WHERE AccountCode = @AccountCode AND AccountType = 'Asset';

    IF @AccountID IS NULL
    BEGIN
        PRINT 'Bank account with code ' + @AccountCode + ' not found';
        RETURN;
    END

    -- Current balance
    SELECT
        coa.AccountCode,
        coa.AccountName,
        bb.CurrentBalance,
        bb.LastUpdateDate,
        t.TransactionDate as LastTransactionDate,
        t.Description as LastTransactionDescription
    FROM BankBalance bb
    INNER JOIN ChartOfAccounts coa ON bb.AccountID = coa.AccountID
    LEFT JOIN Transactions t ON bb.LastTransactionID = t.TransactionID
    WHERE bb.AccountID = @AccountID AND bb.IsActive = 1;

    -- Recent history (last 10 entries)
    SELECT TOP 10
        bbh.RecordedDate,
        bbh.ChangeType,
        bbh.PreviousBalance,
        bbh.BalanceChange,
        bbh.NewBalance,
        bbh.Description,
        bbh.RecordedBy
    FROM BankBalanceHistory bbh
    WHERE bbh.AccountID = @AccountID
    ORDER BY bbh.RecordedDate DESC;
END
GO

-- =============================================
-- Indexes for Performance
-- =============================================
PRINT 'Creating bank balance system indexes...';
GO

-- BankBalance indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('BankBalance') AND name = 'IX_BankBalance_Account')
    CREATE INDEX IX_BankBalance_Account ON BankBalance(AccountID, IsActive);

-- BankBalanceHistory indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('BankBalanceHistory') AND name = 'IX_BankBalanceHistory_Account')
    CREATE INDEX IX_BankBalanceHistory_Account ON BankBalanceHistory(AccountID);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('BankBalanceHistory') AND name = 'IX_BankBalanceHistory_Date')
    CREATE INDEX IX_BankBalanceHistory_Date ON BankBalanceHistory(RecordedDate);

PRINT 'Bank balance system indexes created successfully';
GO

PRINT '';
PRINT '=== Bank Balance System Deployment Complete ===';
PRINT 'Tables created/verified:';
PRINT '  - BankBalance: Current account balances';
PRINT '  - BankBalanceHistory: Complete audit trail of all changes';
PRINT '';
PRINT 'Triggers created:';
PRINT '  - tr_UpdateBankBalance: Automatic balance updates on transactions';
PRINT '';
PRINT 'Procedures created:';
PRINT '  - sp_InitializeBankBalance: Set opening balance (default £10,000)';
PRINT '  - sp_AdjustBankBalance: Manual balance corrections';
PRINT '  - sp_GetBankBalanceInfo: Query current balance and recent history';
PRINT '';
PRINT 'Next steps:';
PRINT '  1. Run: EXEC sp_InitializeBankBalance; -- Sets £10,000 opening balance';
PRINT '  2. Import transactions to see automatic balance updates';
PRINT '';
PRINT 'Bank balance system ready for views and procedures setup';
GO