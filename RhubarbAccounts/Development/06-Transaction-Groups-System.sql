-- Rhubarb Press Accounting System - Transaction Groups System
-- Transaction categorization and enhanced bank import procedures
-- Target: Azure SQL Database (rhubarbpressdb)
-- DEPLOYMENT-READY VERSION

USE rhubarbpressdb;
GO

PRINT 'Creating Transaction Groups System for Rhubarb Press';
PRINT 'Date: ' + CONVERT(NVARCHAR(19), GETDATE(), 120);
PRINT '';
GO

-- =============================================
-- Add BankDate and ReconciliationStatus to Transactions if not exists
-- =============================================
PRINT 'Adding transaction enhancement columns...';
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Transactions') AND name = 'BankDate')
BEGIN
    ALTER TABLE Transactions ADD BankDate DATE NULL;
    PRINT 'Added BankDate column to Transactions';
END
ELSE
BEGIN
    PRINT 'BankDate column already exists in Transactions';
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Transactions') AND name = 'ReconciliationStatus')
BEGIN
    ALTER TABLE Transactions ADD ReconciliationStatus NVARCHAR(20) DEFAULT 'Pending' CHECK (ReconciliationStatus IN ('Pending', 'Matched', 'Unmatched', 'Reconciled'));
    PRINT 'Added ReconciliationStatus column to Transactions';
END
ELSE
BEGIN
    PRINT 'ReconciliationStatus column already exists in Transactions';
END
GO

-- =============================================
-- Create TransactionGroup Lookup Table
-- =============================================
PRINT 'Creating TransactionGroup lookup table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TransactionGroup')
BEGIN
    CREATE TABLE TransactionGroup (
        TransactionGroupID INT IDENTITY(1,1) PRIMARY KEY,
        GroupName NVARCHAR(50) NOT NULL UNIQUE,
        GroupDescription NVARCHAR(255) NULL,
        IsActive BIT DEFAULT 1,
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        ModifiedDate DATETIME2 DEFAULT GETDATE()
    );
    PRINT 'TransactionGroup table created';
END
ELSE
BEGIN
    PRINT 'TransactionGroup table already exists';
END
GO

-- Insert standard transaction groups with specified IDs
IF NOT EXISTS (SELECT * FROM TransactionGroup WHERE TransactionGroupID = 1)
BEGIN
    SET IDENTITY_INSERT TransactionGroup ON;

    INSERT INTO TransactionGroup (TransactionGroupID, GroupName, GroupDescription)
    VALUES
        (1, 'Admin', 'Administrative expenses and general business operations'),
        (2, 'Marketing', 'Marketing, advertising, and promotional activities'),
        (3, 'Publishing', 'Publishing-specific tools, software, and services'),
        (4, 'Research', 'Research and development activities'),
        (5, 'Revenue', 'Income and revenue transactions'),
        (6, 'General', 'General or uncategorized transactions');

    SET IDENTITY_INSERT TransactionGroup OFF;
    PRINT 'Transaction groups populated with standard categories';
END
ELSE
BEGIN
    PRINT 'Transaction groups already populated';
END
GO

-- =============================================
-- Add TransactionGroupID to Transactions Table
-- =============================================
PRINT 'Adding TransactionGroupID to Transactions...';
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Transactions') AND name = 'TransactionGroupID')
BEGIN
    -- Add the new column
    ALTER TABLE Transactions ADD TransactionGroupID INT NULL;

    -- Add foreign key constraint
    ALTER TABLE Transactions
    ADD CONSTRAINT FK_Transactions_TransactionGroup
    FOREIGN KEY (TransactionGroupID) REFERENCES TransactionGroup(TransactionGroupID);

    -- Add index for performance
    CREATE INDEX IX_Transactions_TransactionGroup ON Transactions(TransactionGroupID);

    PRINT 'TransactionGroupID column added to Transactions table';
END
ELSE
BEGIN
    PRINT 'TransactionGroupID column already exists in Transactions table';
END
GO

-- =============================================
-- Helper Procedure for Category Lookup
-- =============================================
PRINT 'Creating transaction group helper procedures...';
GO

CREATE OR ALTER PROCEDURE sp_GetTransactionGroupID
    @GroupName NVARCHAR(50),
    @TransactionGroupID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TransactionGroupID = TransactionGroupID
    FROM TransactionGroup
    WHERE GroupName = @GroupName AND IsActive = 1;

    IF @TransactionGroupID IS NULL
        SET @TransactionGroupID = 6; -- Default to General
END
GO

-- =============================================
-- Enhanced Bank Import Procedure
-- =============================================
PRINT 'Creating enhanced bank import procedure...';
GO

CREATE OR ALTER PROCEDURE sp_ImportBankTransaction_v2
    @ActualDate DATE,
    @BankDate DATE = NULL,
    @Description NVARCHAR(255),
    @TransactionGroupID INT,
    @AmountIn MONEY = 0,
    @AmountOut MONEY = 0,
    @RunningBalance MONEY = NULL,
    @CreatedBy NVARCHAR(50) = 'CSV Import'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TransactionID INT;
    DECLARE @BankAccountID INT;
    DECLARE @ExpenseAccountID INT;
    DECLARE @IncomeAccountID INT;
    DECLARE @TransactionAmount MONEY;
    DECLARE @Reference NVARCHAR(50);
    DECLARE @ErrorMessage NVARCHAR(500);
    DECLARE @CategoryName NVARCHAR(50);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validate inputs
        IF @AmountIn = 0 AND @AmountOut = 0
        BEGIN
            RAISERROR('Transaction must have either In or Out amount', 16, 1);
            RETURN;
        END

        IF @AmountIn > 0 AND @AmountOut > 0
        BEGIN
            RAISERROR('Transaction cannot have both In and Out amounts', 16, 1);
            RETURN;
        END

        -- Validate TransactionGroupID
        SELECT @CategoryName = GroupName
        FROM TransactionGroup
        WHERE TransactionGroupID = @TransactionGroupID AND IsActive = 1;

        IF @CategoryName IS NULL
        BEGIN
            RAISERROR('Invalid TransactionGroupID: %d', 16, 1, @TransactionGroupID);
            RETURN;
        END

        -- Set bank date to actual date if not provided
        IF @BankDate IS NULL
            SET @BankDate = @ActualDate;

        -- Determine transaction amount and type
        SET @TransactionAmount = CASE
            WHEN @AmountOut > 0 THEN @AmountOut
            ELSE @AmountIn
        END;

        -- Generate reference number
        SET @Reference = 'BANK-' + FORMAT(@ActualDate, 'yyyyMMdd') + '-' +
                        RIGHT('000' + CAST(ABS(CHECKSUM(NEWID())) % 1000 AS NVARCHAR(3)), 3);

        -- Get Bank Account
        SELECT @BankAccountID = AccountID
        FROM ChartOfAccounts
        WHERE AccountCode = '1001' AND AccountType = 'Asset';

        IF @BankAccountID IS NULL
        BEGIN
            RAISERROR('Bank account (1001) not found in Chart of Accounts', 16, 1);
            RETURN;
        END

        -- Map category to account
        IF @AmountOut > 0 -- Expense
        BEGIN
            SELECT @ExpenseAccountID = AccountID
            FROM ChartOfAccounts
            WHERE PublishingCategory = @CategoryName
                AND AccountType = 'Expense'
                AND IsActive = 1;

            -- Default to general expenses if not found
            IF @ExpenseAccountID IS NULL
            BEGIN
                SELECT @ExpenseAccountID = AccountID
                FROM ChartOfAccounts
                WHERE AccountCode = '5000'
                    AND AccountType = 'Expense';
            END

            IF @ExpenseAccountID IS NULL
            BEGIN
                RAISERROR('No suitable expense account found for category: %s', 16, 1, @CategoryName);
                RETURN;
            END
        END
        ELSE -- Income
        BEGIN
            SELECT @IncomeAccountID = AccountID
            FROM ChartOfAccounts
            WHERE AccountType = 'Revenue'
                AND IsActive = 1;

            -- Default to general income
            IF @IncomeAccountID IS NULL
            BEGIN
                SELECT @IncomeAccountID = AccountID
                FROM ChartOfAccounts
                WHERE AccountCode = '4000'
                    AND AccountType = 'Revenue';
            END

            IF @IncomeAccountID IS NULL
            BEGIN
                RAISERROR('No suitable income account found', 16, 1);
                RETURN;
            END
        END

        -- Create transaction header
        INSERT INTO Transactions (
            TransactionDate, Reference, Description, TotalAmount,
            TransactionType, CreatedBy, BankDate, TransactionGroupID
        )
        VALUES (
            @ActualDate, @Reference, @Description, @TransactionAmount,
            CASE WHEN @AmountOut > 0 THEN 'Payment' ELSE 'Receipt' END,
            @CreatedBy, @BankDate, @TransactionGroupID
        );

        SET @TransactionID = SCOPE_IDENTITY();

        -- Create transaction lines
        IF @AmountOut > 0 -- Expense
        BEGIN
            INSERT INTO TransactionLines (TransactionID, AccountID, DebitAmount, CreditAmount, Description)
            VALUES
                (@TransactionID, @ExpenseAccountID, @AmountOut, 0, @Description + ' - ' + @CategoryName + ' expense'),
                (@TransactionID, @BankAccountID, 0, @AmountOut, 'Payment from bank account');
        END
        ELSE -- Income
        BEGIN
            INSERT INTO TransactionLines (TransactionID, AccountID, DebitAmount, CreditAmount, Description)
            VALUES
                (@TransactionID, @BankAccountID, @AmountIn, 0, 'Deposit to bank account'),
                (@TransactionID, @IncomeAccountID, 0, @AmountIn, @Description + ' - ' + @CategoryName + ' income');
        END

        COMMIT TRANSACTION;

        SELECT @TransactionID as TransactionID, @Reference as Reference, @CategoryName as Category;
        PRINT 'Transaction imported: ' + @Reference + ' (' + @CategoryName + ')';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMessage = 'Error importing transaction: ' + ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

-- =============================================
-- Backward Compatibility Wrapper
-- =============================================
PRINT 'Creating backward compatibility procedure...';
GO

CREATE OR ALTER PROCEDURE sp_ImportBankTransaction_Legacy
    @ActualDate DATE,
    @BankDate DATE = NULL,
    @Description NVARCHAR(255),
    @Category NVARCHAR(50),
    @AmountIn MONEY = 0,
    @AmountOut MONEY = 0,
    @RunningBalance MONEY = NULL,
    @CreatedBy NVARCHAR(50) = 'CSV Import'
AS
BEGIN
    DECLARE @TransactionGroupID INT;

    -- Map old category names to IDs
    EXEC sp_GetTransactionGroupID @Category, @TransactionGroupID OUTPUT;

    -- Call new version
    EXEC sp_ImportBankTransaction_v2
        @ActualDate, @BankDate, @Description, @TransactionGroupID,
        @AmountIn, @AmountOut, @RunningBalance, @CreatedBy;
END
GO

PRINT '';
PRINT '=== Transaction Groups System Created Successfully ===';
PRINT 'Tables created/enhanced:';
PRINT '  - TransactionGroup: Category lookup table';
PRINT '  - Transactions: Enhanced with BankDate, ReconciliationStatus, TransactionGroupID';
PRINT '';
PRINT 'Procedures created:';
PRINT '  - sp_ImportBankTransaction_v2: Enhanced import with transaction groups';
PRINT '  - sp_ImportBankTransaction_Legacy: Backward compatible import';
PRINT '  - sp_GetTransactionGroupID: Helper for category lookup';
PRINT '';
PRINT 'Available transaction groups:';
SELECT TransactionGroupID, GroupName, GroupDescription FROM TransactionGroup ORDER BY TransactionGroupID;
PRINT '';
PRINT 'Ready for enhanced transaction processing with categorization';
GO