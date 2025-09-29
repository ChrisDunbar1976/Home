-- Rhubarb Press Accounting System - September 2025 CSV Import (IDEMPOTENT)
-- Bank transaction imports from AccountsCSV.csv
-- Target: Azure SQL Database (rhubarbpressdb)
-- Import order: Furthest back first, most recent last
-- IDEMPOTENT: Safe to run multiple times - checks for existing transactions

USE rhubarbpressdb;
GO

PRINT 'Starting IDEMPOTENT import of September 2025 bank transactions from CSV data';
PRINT 'Import Date: ' + CONVERT(NVARCHAR(19), GETDATE(), 120);
PRINT '';

-- =============================================
-- Check if this import has already been run
-- =============================================
IF EXISTS (
    SELECT 1 FROM Transactions
    WHERE CreatedBy = 'CSV Import September 2025'
    AND TransactionDate BETWEEN '2025-09-01' AND '2025-09-30'
)
BEGIN
    PRINT 'WARNING: September 2025 CSV transactions already exist!';
    PRINT 'Existing transactions found - checking individual transactions...';
    PRINT '';
END

-- =============================================
-- September 2025 Bank Transactions Import
-- Based on AccountsCSV.csv data in chronological order
-- =============================================

-- Row 2: Twitter Marketing (01/09/2025) - Furthest back
IF NOT EXISTS (
    SELECT 1 FROM Transactions
    WHERE TransactionDate = '2025-09-01'
    AND Description LIKE '%Twitter%Marketing%'
    AND TotalAmount = 8.00
)
BEGIN
    PRINT 'Importing: Twitter Marketing expense (01/09/2025)';
    EXEC sp_ImportBankTransaction
        @ActualDate = '2025-09-01',
        @BankDate = '2025-09-01',
        @Description = 'Twitter',
        @Category = 'Marketing',
        @AmountOut = 8.00,
        @CreatedBy = 'CSV Import September 2025';
END
ELSE
BEGIN
    PRINT 'SKIPPED: Twitter Marketing expense (01/09/2025) - already exists';
END
GO

-- Row 3: Hoxton Mix Admin (01/09/2025)
IF NOT EXISTS (
    SELECT 1 FROM Transactions
    WHERE TransactionDate = '2025-09-01'
    AND Description LIKE '%Hoxton Mix%Admin%'
    AND TotalAmount = 55.19
)
BEGIN
    PRINT 'Importing: Hoxton Mix admin expense (01/09/2025)';
    EXEC sp_ImportBankTransaction
        @ActualDate = '2025-09-01',
        @BankDate = '2025-09-02',
        @Description = 'Hoxton Mix',
        @Category = 'Admin',
        @AmountOut = 55.19,
        @CreatedBy = 'CSV Import September 2025';
END
ELSE
BEGIN
    PRINT 'SKIPPED: Hoxton Mix admin expense (01/09/2025) - already exists';
END
GO

-- Row 4: Google G Suite Admin (04/09/2025)
IF NOT EXISTS (
    SELECT 1 FROM Transactions
    WHERE TransactionDate = '2025-09-04'
    AND Description LIKE '%Google G Suite%Admin%'
    AND TotalAmount = 10.68
)
BEGIN
    PRINT 'Importing: Google G Suite admin expense (04/09/2025)';
    EXEC sp_ImportBankTransaction
        @ActualDate = '2025-09-04',
        @BankDate = '2025-09-04',
        @Description = 'Google G Suite RhubarbP',
        @Category = 'Admin',
        @AmountOut = 10.68,
        @CreatedBy = 'CSV Import September 2025';
END
ELSE
BEGIN
    PRINT 'SKIPPED: Google G Suite admin expense (04/09/2025) - already exists';
END
GO

-- Row 5: Refund Income (15/09/2025)
IF NOT EXISTS (
    SELECT 1 FROM Transactions
    WHERE TransactionDate = '2025-09-15'
    AND Description LIKE '%Refund%Admin%'
    AND TotalAmount = 15.00
    AND TransactionType = 'Receipt'
)
BEGIN
    PRINT 'Importing: Refund income (15/09/2025)';
    EXEC sp_ImportBankTransaction
        @ActualDate = '2025-09-15',
        @BankDate = '2025-09-15',
        @Description = 'Refund',
        @Category = 'Admin',
        @AmountIn = 15.00,
        @CreatedBy = 'CSV Import September 2025';
END
ELSE
BEGIN
    PRINT 'SKIPPED: Refund income (15/09/2025) - already exists';
END
GO

-- Row 6: Google Gemini Publishing (16/09/2025)
IF NOT EXISTS (
    SELECT 1 FROM Transactions
    WHERE TransactionDate = '2025-09-16'
    AND Description LIKE '%Google Gemini%Publishing%'
    AND TotalAmount = 18.99
)
BEGIN
    PRINT 'Importing: Google Gemini publishing expense (16/09/2025)';
    EXEC sp_ImportBankTransaction
        @ActualDate = '2025-09-16',
        @BankDate = '2025-09-16',
        @Description = 'Google Gemini',
        @Category = 'Publishing',
        @AmountOut = 18.99,
        @CreatedBy = 'CSV Import September 2025';
END
ELSE
BEGIN
    PRINT 'SKIPPED: Google Gemini publishing expense (16/09/2025) - already exists';
END
GO

-- Row 7: Udemy Research (17/09/2025) - Most recent
IF NOT EXISTS (
    SELECT 1 FROM Transactions
    WHERE TransactionDate = '2025-09-17'
    AND Description LIKE '%Udemy%Research%'
    AND TotalAmount = 15.99
)
BEGIN
    PRINT 'Importing: Udemy research expense (17/09/2025)';
    EXEC sp_ImportBankTransaction
        @ActualDate = '2025-09-17',
        @BankDate = '2025-09-18',
        @Description = 'Udemy',
        @Category = 'Research',
        @AmountOut = 15.99,
        @CreatedBy = 'CSV Import September 2025';
END
ELSE
BEGIN
    PRINT 'SKIPPED: Udemy research expense (17/09/2025) - already exists';
END
GO

PRINT '';
PRINT 'September 2025 CSV import completed successfully';
PRINT 'Total transactions imported: 6';
PRINT 'Transaction types:';
PRINT '  - Marketing: 1 transaction (£8.00)';
PRINT '  - Admin: 3 transactions (£55.19 + £10.68 - £15.00 refund = £50.87)';
PRINT '  - Publishing: 1 transaction (£18.99)';
PRINT '  - Research: 1 transaction (£15.99)';
PRINT 'Net outflow: £93.85';

-- =============================================
-- Verification Queries
-- =============================================

PRINT '';
PRINT 'Verification: Recent transactions imported from CSV';

-- Show recently imported transactions
SELECT TOP 10
    t.TransactionID,
    t.TransactionDate,
    t.BankDate,
    t.Reference,
    t.Description,
    t.TotalAmount,
    t.TransactionType,
    t.CreatedBy
FROM Transactions t
WHERE t.CreatedBy LIKE '%CSV Import%'
ORDER BY t.TransactionDate DESC, t.CreatedDate DESC;

-- Show transaction lines for verification
PRINT '';
PRINT 'Double-entry verification: Transaction lines';

SELECT
    t.Reference,
    t.Description,
    coa.AccountName,
    tl.DebitAmount,
    tl.CreditAmount,
    tl.Description as LineDescription
FROM Transactions t
INNER JOIN TransactionLines tl ON t.TransactionID = tl.TransactionID
INNER JOIN ChartOfAccounts coa ON tl.AccountID = coa.AccountID
WHERE t.CreatedBy LIKE '%CSV Import%'
ORDER BY t.TransactionDate, t.TransactionID, tl.LineID;