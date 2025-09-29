-- Rhubarb Press Accounting System - Comprehensive Test Data (Updated)
-- Tests the complete system including new bank balance tracking
-- Target: Azure SQL Database (rhubarbpressdb)
-- IDEMPOTENT: Safe to run multiple times

USE rhubarbpressdb;
GO

PRINT 'Starting comprehensive test data setup for Rhubarb Press Accounting System';
PRINT 'Test Date: ' + CONVERT(NVARCHAR(19), GETDATE(), 120);
PRINT '';

-- =============================================
-- Step 1: Initialize Bank Balance System
-- =============================================
PRINT '=== STEP 1: Bank Balance Initialization ===';

-- Check if bank balance already exists
IF EXISTS (SELECT 1 FROM BankBalance bb INNER JOIN ChartOfAccounts coa ON bb.AccountID = coa.AccountID WHERE coa.AccountCode = '1001')
BEGIN
    PRINT 'Bank balance already initialized. Current status:';
    SELECT
        coa.AccountCode,
        coa.AccountName,
        bb.CurrentBalance,
        bb.dtModified
    FROM BankBalance bb
    INNER JOIN ChartOfAccounts coa ON bb.AccountID = coa.AccountID
    WHERE coa.AccountCode = '1001';
END
ELSE
BEGIN
    PRINT 'Initializing bank balance with £10,000 opening balance...';
    EXEC sp_InitializeBankBalance '1001', 10000.00;
END
GO

-- =============================================
-- Step 2: Setup Test Contacts
-- =============================================
PRINT '=== STEP 2: Test Contacts Setup ===';

-- Test customer (if not exists)
IF NOT EXISTS (SELECT 1 FROM Contacts WHERE Email = 'test@bookstore.com')
BEGIN
    INSERT INTO Contacts (ContactType, CompanyName, Email, Country, TaxStatus)
    VALUES ('Customer', 'Test Independent Bookstore', 'test@bookstore.com', 'United Kingdom', 'Company');
    PRINT 'Created test customer contact';
END
ELSE
BEGIN
    PRINT 'Test customer contact already exists';
END

-- Test supplier (if not exists)
IF NOT EXISTS (SELECT 1 FROM Contacts WHERE Email = 'admin@printingcompany.co.uk')
BEGIN
    INSERT INTO Contacts (ContactType, CompanyName, Email, Country, TaxStatus)
    VALUES ('Supplier', 'Quality Printing Ltd', 'admin@printingcompany.co.uk', 'United Kingdom', 'Company');
    PRINT 'Created test supplier contact';
END
ELSE
BEGIN
    PRINT 'Test supplier contact already exists';
END

-- Test author (if not exists)
IF NOT EXISTS (SELECT 1 FROM Contacts WHERE Email = 'author@example.com')
BEGIN
    INSERT INTO Contacts (ContactType, FirstName, LastName, Email, Country, TaxStatus)
    VALUES ('Author', 'Jane', 'Smith', 'author@example.com', 'United Kingdom', 'Self-Employed');
    PRINT 'Created test author contact';
END
ELSE
BEGIN
    PRINT 'Test author contact already exists';
END
GO

-- =============================================
-- Step 3: Test Bank Transactions (Using CSV Import Procedure)
-- =============================================
PRINT '=== STEP 3: Sample Bank Transactions ===';

-- Marketing expense
IF NOT EXISTS (SELECT 1 FROM Transactions WHERE Description LIKE '%Social Media Marketing%')
BEGIN
    PRINT 'Adding social media marketing expense...';
    EXEC sp_ImportBankTransaction
        @ActualDate = '2025-09-20',
        @BankDate = '2025-09-20',
        @Description = 'Social Media Marketing',
        @Category = 'Marketing',
        @AmountOut = 150.00,
        @CreatedBy = 'Test Data';
END
ELSE
BEGIN
    PRINT 'Social media marketing expense already exists';
END

-- Publishing expense
IF NOT EXISTS (SELECT 1 FROM Transactions WHERE Description LIKE '%Book Design Software%')
BEGIN
    PRINT 'Adding book design software expense...';
    EXEC sp_ImportBankTransaction
        @ActualDate = '2025-09-21',
        @BankDate = '2025-09-21',
        @Description = 'Book Design Software',
        @Category = 'Publishing',
        @AmountOut = 89.99,
        @CreatedBy = 'Test Data';
END
ELSE
BEGIN
    PRINT 'Book design software expense already exists';
END

-- Admin expense
IF NOT EXISTS (SELECT 1 FROM Transactions WHERE Description LIKE '%Office Supplies%')
BEGIN
    PRINT 'Adding office supplies expense...';
    EXEC sp_ImportBankTransaction
        @ActualDate = '2025-09-22',
        @BankDate = '2025-09-23',
        @Description = 'Office Supplies',
        @Category = 'Admin',
        @AmountOut = 75.50,
        @CreatedBy = 'Test Data';
END
ELSE
BEGIN
    PRINT 'Office supplies expense already exists';
END

-- Book sale income
IF NOT EXISTS (SELECT 1 FROM Transactions WHERE Description LIKE '%Book Sales Revenue%')
BEGIN
    PRINT 'Adding book sales revenue...';
    EXEC sp_ImportBankTransaction
        @ActualDate = '2025-09-23',
        @BankDate = '2025-09-24',
        @Description = 'Book Sales Revenue',
        @Category = 'Admin',
        @AmountIn = 450.00,
        @CreatedBy = 'Test Data';
END
ELSE
BEGIN
    PRINT 'Book sales revenue already exists';
END

-- Research expense
IF NOT EXISTS (SELECT 1 FROM Transactions WHERE Description LIKE '%Industry Research%')
BEGIN
    PRINT 'Adding industry research expense...';
    EXEC sp_ImportBankTransaction
        @ActualDate = '2025-09-24',
        @BankDate = '2025-09-24',
        @Description = 'Industry Research',
        @Category = 'Research',
        @AmountOut = 125.00,
        @CreatedBy = 'Test Data';
END
ELSE
BEGIN
    PRINT 'Industry research expense already exists';
END
GO

-- =============================================
-- Step 4: Test Invoice Creation
-- =============================================
PRINT '=== STEP 4: Test Invoice Creation ===';

DECLARE @CustomerContactID INT;
SELECT TOP 1 @CustomerContactID = ContactID FROM Contacts WHERE ContactType = 'Customer';

IF @CustomerContactID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Invoices WHERE InvoiceNumber = 'TEST-INV-001')
BEGIN
    PRINT 'Creating test sales invoice...';

    -- Create invoice using existing procedure (if available) or manual insert
    INSERT INTO Invoices (
        InvoiceType, InvoiceNumber, ContactID, InvoiceDate, DueDate,
        SubTotal, VATAmount, TotalAmount, Status, CreatedBy
    )
    VALUES (
        'Sales', 'TEST-INV-001', @CustomerContactID, '2025-09-25', '2025-10-25',
        416.67, 83.33, 500.00, 'Sent', 'Test Data'
    );

    DECLARE @InvoiceID INT = SCOPE_IDENTITY();

    -- Add invoice line
    INSERT INTO InvoiceLines (
        InvoiceID, Description, Quantity, UnitPrice, LineTotal, VATRate, VATAmount
    )
    VALUES (
        @InvoiceID, 'Test Book Sales - Various Titles', 25, 16.67, 416.67, 0.2000, 83.33
    );

    PRINT 'Test invoice created successfully';
END
ELSE
BEGIN
    PRINT 'Test invoice already exists or no customer contact available';
END
GO

-- =============================================
-- Step 5: Verification Queries
-- =============================================
PRINT '';
PRINT '=== VERIFICATION: System Status ===';

-- Current bank balance
PRINT 'Current Bank Balance:';
SELECT
    AccountCode,
    AccountName,
    CurrentBalance as 'Current Balance',
    LastModified as 'Last Modified'
FROM vw_CurrentBankBalances;

-- Recent transactions with running balance
PRINT '';
PRINT 'Recent Transactions (Running Balance):';
SELECT TOP 10
    ActualDate,
    Item as Description,
    [In] as 'Money In',
    [Out] as 'Money Out',
    Balance as 'Running Balance'
FROM vw_BankRunningBalance
ORDER BY ActualDate DESC;

-- Balance audit trail
PRINT '';
PRINT 'Balance Audit Trail (Last 10 changes):';
SELECT TOP 10
    TransactionDate,
    TransactionDescription,
    PreviousBalance as 'Previous',
    BalanceChange as 'Change',
    NewBalance as 'New Balance',
    ChangeType
FROM vw_BankBalanceAuditTrail;

-- Account balances summary
PRINT '';
PRINT 'Account Balances by Type:';
SELECT
    AccountType,
    COUNT(*) as 'Number of Accounts',
    SUM(CurrentBalance) as 'Total Balance'
FROM vw_AccountBalances
WHERE CurrentBalance != 0
GROUP BY AccountType
ORDER BY AccountType;

-- Transaction summary by category
PRINT '';
PRINT 'Transaction Summary by Category:';
SELECT
    coa.PublishingCategory as Category,
    COUNT(t.TransactionID) as 'Transaction Count',
    SUM(CASE WHEN coa.AccountType = 'Expense' THEN tl.DebitAmount ELSE 0 END) as 'Total Expenses',
    SUM(CASE WHEN coa.AccountType = 'Revenue' THEN tl.CreditAmount ELSE 0 END) as 'Total Revenue'
FROM Transactions t
INNER JOIN TransactionLines tl ON t.TransactionID = tl.TransactionID
INNER JOIN ChartOfAccounts coa ON tl.AccountID = coa.AccountID
WHERE t.CreatedBy LIKE '%Test Data%' OR t.CreatedBy LIKE '%CSV Import%'
GROUP BY coa.PublishingCategory
ORDER BY coa.PublishingCategory;

-- Invoice summary
PRINT '';
PRINT 'Invoice Summary:';
SELECT
    InvoiceType,
    COUNT(*) as 'Count',
    SUM(TotalAmount) as 'Total Amount',
    AVG(TotalAmount) as 'Average Amount'
FROM Invoices
GROUP BY InvoiceType;

PRINT '';
PRINT '=== Test Data Setup Complete ===';
PRINT 'System is ready for use with comprehensive test data';
PRINT 'All bank balance tracking and audit features are active';
GO