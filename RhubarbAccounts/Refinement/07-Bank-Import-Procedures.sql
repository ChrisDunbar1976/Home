-- Rhubarb Press Accounting System - Bank Transaction Import Procedures
-- CSV Import procedures for bank transaction data
-- Target: Azure SQL Database (rhubarbpressdb)

USE rhubarbpressdb;
GO

-- =============================================
-- Bank Transaction Import Procedure
-- Maps CSV data to double-entry accounting transactions
-- =============================================
CREATE OR ALTER PROCEDURE sp_ImportBankTransaction
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
    SET NOCOUNT ON;

    DECLARE @TransactionID INT;
    DECLARE @BankAccountID INT;
    DECLARE @ExpenseAccountID INT;
    DECLARE @IncomeAccountID INT;
    DECLARE @TransactionAmount MONEY;
    DECLARE @Reference NVARCHAR(50);
    DECLARE @ErrorMessage NVARCHAR(500);

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

        -- Map category to account
        IF @AmountOut > 0 -- Expense
        BEGIN
            SELECT @ExpenseAccountID = AccountID
            FROM ChartOfAccounts
            WHERE PublishingCategory = @Category
                AND AccountType = 'Expense'
                AND IsActive = 1;

            -- If no specific category account found, try to map common categories
            IF @ExpenseAccountID IS NULL
            BEGIN
                SELECT @ExpenseAccountID = AccountID
                FROM ChartOfAccounts
                WHERE AccountType = 'Expense'
                    AND IsActive = 1
                    AND (
                        (@Category = 'Admin' AND AccountName LIKE '%Admin%')
                        OR (@Category = 'Marketing' AND AccountName LIKE '%Marketing%')
                        OR (@Category = 'Publishing' AND AccountName LIKE '%Publishing%')
                        OR (@Category = 'Research' AND AccountName LIKE '%Research%')
                        OR (@Category = 'Research' AND AccountName LIKE '%Development%')
                    );
            END

            -- Default to general expenses if still not found
            IF @ExpenseAccountID IS NULL
            BEGIN
                SELECT @ExpenseAccountID = AccountID
                FROM ChartOfAccounts
                WHERE AccountCode = '5000' -- General expenses
                    AND AccountType = 'Expense';
            END

            IF @ExpenseAccountID IS NULL
            BEGIN
                RAISERROR('No suitable expense account found for category: %s', 16, 1, @Category);
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

        -- Create transaction header (check if BankDate column exists)
        IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Transactions') AND name = 'BankDate')
        BEGIN
            INSERT INTO Transactions (
                TransactionDate,
                Reference,
                Description,
                TotalAmount,
                TransactionType,
                CreatedBy,
                BankDate
            )
            VALUES (
                @ActualDate,
                @Reference,
                @Description + ' (' + @Category + ')',
                @TransactionAmount,
                CASE WHEN @AmountOut > 0 THEN 'Payment' ELSE 'Receipt' END,
                @CreatedBy,
                @BankDate
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
                CreatedBy
            )
            VALUES (
                @ActualDate,
                @Reference,
                @Description + ' (' + @Category + ')',
                @TransactionAmount,
                CASE WHEN @AmountOut > 0 THEN 'Payment' ELSE 'Receipt' END,
                @CreatedBy
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
                @Description + ' - ' + @Category + ' expense'
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
                @Description + ' - ' + @Category + ' income'
            );
        END

        COMMIT TRANSACTION;

        -- Return transaction ID for reference
        SELECT @TransactionID as TransactionID, @Reference as Reference;

        PRINT 'Transaction imported successfully: ' + @Reference;

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
-- Bulk CSV Import Procedure
-- Imports multiple transactions from CSV-like data
-- =============================================
CREATE OR ALTER PROCEDURE sp_BulkImportBankTransactions
    @CSVData NVARCHAR(MAX), -- CSV formatted data
    @CreatedBy NVARCHAR(50) = 'Bulk CSV Import'
AS
BEGIN
    SET NOCOUNT ON;

    -- This is a placeholder for bulk import functionality
    -- Would need to parse CSV data and call sp_ImportBankTransaction for each row
    -- For now, use individual calls to sp_ImportBankTransaction

    PRINT 'Use individual sp_ImportBankTransaction calls for each CSV row';
    PRINT 'Bulk import functionality can be added with CSV parsing logic';
END
GO

-- =============================================
-- Account Setup for Common CSV Categories
-- Creates expense accounts for typical categories
-- =============================================
CREATE OR ALTER PROCEDURE sp_SetupBankImportAccounts
AS
BEGIN
    SET NOCOUNT ON;

    -- Ensure we have a bank account
    IF NOT EXISTS (SELECT 1 FROM ChartOfAccounts WHERE AccountCode = '1001')
    BEGIN
        INSERT INTO ChartOfAccounts (AccountCode, AccountName, AccountType, AccountSubType)
        VALUES ('1001', 'Main Bank Account', 'Asset', 'Current Asset');
        PRINT 'Created bank account (1001)';
    END

    -- Common expense categories from CSV
    DECLARE @Accounts TABLE (
        Code NVARCHAR(20),
        Name NVARCHAR(100),
        Category NVARCHAR(50)
    );

    INSERT INTO @Accounts VALUES
        ('5001', 'Administrative Expenses', 'Admin'),
        ('5002', 'Publishing Tools & Software', 'Publishing'),
        ('5003', 'Research & Development', 'Research'),
        ('5004', 'Marketing & Advertising', 'Marketing'),
        ('5000', 'General Expenses', 'General');

    -- Insert accounts that don't exist
    INSERT INTO ChartOfAccounts (AccountCode, AccountName, AccountType, PublishingCategory, IsActive)
    SELECT a.Code, a.Name, 'Expense', a.Category, 1
    FROM @Accounts a
    WHERE NOT EXISTS (
        SELECT 1 FROM ChartOfAccounts c
        WHERE c.AccountCode = a.Code
    );

    -- Ensure we have a general income account
    IF NOT EXISTS (SELECT 1 FROM ChartOfAccounts WHERE AccountCode = '4000')
    BEGIN
        INSERT INTO ChartOfAccounts (AccountCode, AccountName, AccountType)
        VALUES ('4000', 'General Income', 'Revenue');
        PRINT 'Created general income account (4000)';
    END

    PRINT 'Bank import accounts setup completed';
END
GO

-- =============================================
-- Execute account setup
-- =============================================
EXEC sp_SetupBankImportAccounts;
GO

PRINT 'Bank import procedures created successfully';
PRINT '';
PRINT 'Usage example:';
PRINT 'EXEC sp_ImportBankTransaction';
PRINT '    @ActualDate = ''2025-09-01'',';
PRINT '    @BankDate = ''2025-09-01'',';
PRINT '    @Description = ''Twitter'',';
PRINT '    @Category = ''Marketing'',';
PRINT '    @AmountOut = 8.00;';