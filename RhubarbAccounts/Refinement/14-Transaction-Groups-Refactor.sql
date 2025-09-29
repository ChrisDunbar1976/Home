-- Rhubarb Press Accounting System - Transaction Groups Refactor
-- Normalizes transaction descriptions by creating TransactionGroup lookup table
-- Separates categories (Admin, Marketing, etc.) from descriptions
-- Target: Azure SQL Database (rhubarbpressdb)

USE rhubarbpressdb;
GO

PRINT 'Starting Transaction Groups refactoring for normalized descriptions';
PRINT 'Refactor Date: ' + CONVERT(NVARCHAR(19), GETDATE(), 120);
PRINT '';

-- =============================================
-- Step 1: Create TransactionGroup Lookup Table
-- =============================================
PRINT '=== STEP 1: Creating TransactionGroup Lookup Table ===';

CREATE TABLE TransactionGroup (
    TransactionGroupID INT IDENTITY(1,1) PRIMARY KEY,
    GroupName NVARCHAR(50) NOT NULL UNIQUE,
    GroupDescription NVARCHAR(255) NULL,
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
);

-- Insert standard transaction groups with specified IDs
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

PRINT 'TransactionGroup table created with standard categories';
GO

-- =============================================
-- Step 2: Add TransactionGroupID to Transactions Table
-- =============================================
PRINT '=== STEP 2: Adding TransactionGroupID to Transactions Table ===';

-- Add the new column
ALTER TABLE Transactions
ADD TransactionGroupID INT NULL;

-- Add foreign key constraint
ALTER TABLE Transactions
ADD CONSTRAINT FK_Transactions_TransactionGroup
FOREIGN KEY (TransactionGroupID) REFERENCES TransactionGroup(TransactionGroupID);

-- Add index for performance
CREATE INDEX IX_Transactions_TransactionGroup ON Transactions(TransactionGroupID);

PRINT 'TransactionGroupID column added to Transactions table';
GO

-- =============================================
-- Step 3: Data Migration - Extract Categories from Descriptions
-- =============================================
PRINT '=== STEP 3: Migrating Existing Transaction Data ===';

-- Update transactions with categories in brackets
UPDATE t
SET TransactionGroupID = CASE
    WHEN t.Description LIKE '%(Admin)%' THEN 1
    WHEN t.Description LIKE '%(Marketing)%' THEN 2
    WHEN t.Description LIKE '%(Publishing)%' THEN 3
    WHEN t.Description LIKE '%(Research)%' THEN 4
    ELSE 6 -- General for uncategorized
END
FROM Transactions t
WHERE t.TransactionGroupID IS NULL;

-- Clean up descriptions - remove category brackets
UPDATE Transactions
SET Description = LTRIM(RTRIM(
    REPLACE(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(Description, '(Admin)', ''),
                    '(Marketing)', ''
                ),
                '(Publishing)', ''
            ),
            '(Research)', ''
        ),
        '(Revenue)', ''
    )
))
WHERE Description LIKE '%(%';

PRINT 'Existing transaction data migrated successfully';

-- Show migration results
SELECT
    tg.GroupName,
    COUNT(*) as TransactionCount
FROM Transactions t
INNER JOIN TransactionGroup tg ON t.TransactionGroupID = tg.TransactionGroupID
GROUP BY tg.GroupName, tg.TransactionGroupID
ORDER BY tg.TransactionGroupID;
GO

-- =============================================
-- Step 4: Update Bank Import Procedure
-- =============================================
PRINT '=== STEP 4: Updating Bank Import Procedure ===';

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

        -- Get Bank Account (assuming account code 1001)
        SELECT @BankAccountID = AccountID
        FROM ChartOfAccounts
        WHERE AccountCode = '1001' AND AccountType = 'Asset';

        IF @BankAccountID IS NULL
        BEGIN
            RAISERROR('Bank account (1001) not found in Chart of Accounts', 16, 1);
            RETURN;
        END

        -- Map category to account using new lookup
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
                WHERE AccountCode = '5000' -- General expenses
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
                WHERE AccountCode = '4000' -- General income
                    AND AccountType = 'Revenue';
            END

            IF @IncomeAccountID IS NULL
            BEGIN
                RAISERROR('No suitable income account found', 16, 1);
                RETURN;
            END
        END

        -- Create transaction header with TransactionGroupID
        IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Transactions') AND name = 'BankDate')
        BEGIN
            INSERT INTO Transactions (
                TransactionDate,
                Reference,
                Description,
                TotalAmount,
                TransactionType,
                CreatedBy,
                BankDate,
                TransactionGroupID
            )
            VALUES (
                @ActualDate,
                @Reference,
                @Description, -- Clean description without category
                @TransactionAmount,
                CASE WHEN @AmountOut > 0 THEN 'Payment' ELSE 'Receipt' END,
                @CreatedBy,
                @BankDate,
                @TransactionGroupID
            );
        END
        ELSE
        BEGIN
            INSERT INTO Transactions (
                TransactionDate,
                Reference,
                Description,
                TotalAmount,
                TransactionType,
                CreatedBy,
                TransactionGroupID
            )
            VALUES (
                @ActualDate,
                @Reference,
                @Description, -- Clean description without category
                @TransactionAmount,
                CASE WHEN @AmountOut > 0 THEN 'Payment' ELSE 'Receipt' END,
                @CreatedBy,
                @TransactionGroupID
            );
        END

        SET @TransactionID = SCOPE_IDENTITY();

        -- Create double-entry transaction lines
        IF @AmountOut > 0 -- Expense transaction
        BEGIN
            -- Debit expense account
            INSERT INTO TransactionLines (
                TransactionID, AccountID, DebitAmount, CreditAmount, Description
            )
            VALUES (
                @TransactionID, @ExpenseAccountID, @AmountOut, 0,
                @Description + ' - ' + @CategoryName + ' expense'
            );

            -- Credit bank account
            INSERT INTO TransactionLines (
                TransactionID, AccountID, DebitAmount, CreditAmount, Description
            )
            VALUES (
                @TransactionID, @BankAccountID, 0, @AmountOut,
                'Payment from bank account'
            );
        END
        ELSE -- Income transaction
        BEGIN
            -- Debit bank account
            INSERT INTO TransactionLines (
                TransactionID, AccountID, DebitAmount, CreditAmount, Description
            )
            VALUES (
                @TransactionID, @BankAccountID, @AmountIn, 0,
                'Deposit to bank account'
            );

            -- Credit income account
            INSERT INTO TransactionLines (
                TransactionID, AccountID, DebitAmount, CreditAmount, Description
            )
            VALUES (
                @TransactionID, @IncomeAccountID, 0, @AmountIn,
                @Description + ' - ' + @CategoryName + ' income'
            );
        END

        COMMIT TRANSACTION;

        -- Return transaction ID for reference
        SELECT @TransactionID as TransactionID, @Reference as Reference, @CategoryName as Category;

        PRINT 'Transaction imported successfully: ' + @Reference + ' (' + @CategoryName + ')';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMessage = 'Error importing bank transaction: ' + ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END CATCH
END
GO

-- =============================================
-- Step 5: Create Helper Procedure for Category Lookup
-- =============================================
PRINT '=== STEP 5: Creating Helper Procedures ===';

-- Procedure to get TransactionGroupID by name
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

-- Wrapper procedure for backward compatibility
CREATE OR ALTER PROCEDURE sp_ImportBankTransaction_Legacy
    @ActualDate DATE,
    @BankDate DATE = NULL,
    @Description NVARCHAR(255),
    @Category NVARCHAR(50), -- Old parameter
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
        @ActualDate = @ActualDate,
        @BankDate = @BankDate,
        @Description = @Description,
        @TransactionGroupID = @TransactionGroupID,
        @AmountIn = @AmountIn,
        @AmountOut = @AmountOut,
        @RunningBalance = @RunningBalance,
        @CreatedBy = @CreatedBy;
END
GO

PRINT 'Helper procedures created successfully';
PRINT '';
PRINT '=== Transaction Groups Refactor Complete ===';
PRINT 'Changes made:';
PRINT '  1. Created TransactionGroup lookup table';
PRINT '  2. Added TransactionGroupID FK to Transactions';
PRINT '  3. Migrated existing data and cleaned descriptions';
PRINT '  4. Created new import procedure: sp_ImportBankTransaction_v2';
PRINT '  5. Created backward compatibility wrapper: sp_ImportBankTransaction_Legacy';
PRINT '';
PRINT 'Transaction Groups:';
SELECT TransactionGroupID, GroupName, GroupDescription FROM TransactionGroup ORDER BY TransactionGroupID;
GO