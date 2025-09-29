-- Rhubarb Press Accounting System - September 2025 CSV Import v2 (Updated for TransactionGroups)
-- Bank transaction imports from AccountsCSV.csv using new TransactionGroup system
-- Target: Azure SQL Database (rhubarbpressdb)
-- Import order: Furthest back first, most recent last
-- IDEMPOTENT: Safe to run multiple times - checks for existing transactions

USE rhubarbpressdb;
GO

PRINT 'Starting IDEMPOTENT import of September 2025 bank transactions (TransactionGroups v2)';
PRINT 'Import Date: ' + CONVERT(NVARCHAR(19), GETDATE(), 120);
PRINT '';

-- =============================================
-- Check if this import has already been run
-- =============================================
IF EXISTS (
    SELECT 1 FROM Transactions
    WHERE CreatedBy = 'CSV Import September 2025 v2'
    AND TransactionDate BETWEEN '2025-09-01' AND '2025-09-30'
)
BEGIN
    PRINT 'WARNING: September 2025 CSV v2 transactions already exist!';
    PRINT 'Existing transactions found - checking individual transactions...';
    PRINT '';
END

-- =============================================
-- September 2025 Bank Transactions Import (v2)
-- Using new TransactionGroup system
-- =============================================

-- Row 2: Twitter Marketing (01/09/2025) - Furthest back
IF NOT EXISTS (
    SELECT 1 FROM Transactions
    WHERE TransactionDate = '2025-09-01'
    AND Description = 'Twitter'
    AND TotalAmount = 8.00
    AND TransactionGroupID = 2 -- Marketing
)
BEGIN
    PRINT 'Importing: Twitter Marketing expense (01/09/2025)';
    EXEC sp_ImportBankTransaction_v2
        @ActualDate = '2025-09-01',
        @BankDate = '2025-09-01',
        @Description = 'Twitter',
        @TransactionGroupID = 2, -- Marketing
        @AmountOut = 8.00,
        @CreatedBy = 'CSV Import September 2025 v2';
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
    AND Description = 'Hoxton Mix'
    AND TotalAmount = 55.19
    AND TransactionGroupID = 1 -- Admin
)
BEGIN
    PRINT 'Importing: Hoxton Mix admin expense (01/09/2025)';
    EXEC sp_ImportBankTransaction_v2
        @ActualDate = '2025-09-01',
        @BankDate = '2025-09-02',
        @Description = 'Hoxton Mix',
        @TransactionGroupID = 1, -- Admin
        @AmountOut = 55.19,
        @CreatedBy = 'CSV Import September 2025 v2';
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
    AND Description = 'Google G Suite RhubarbP'
    AND TotalAmount = 10.68
    AND TransactionGroupID = 1 -- Admin
)
BEGIN
    PRINT 'Importing: Google G Suite admin expense (04/09/2025)';
    EXEC sp_ImportBankTransaction_v2
        @ActualDate = '2025-09-04',
        @BankDate = '2025-09-04',
        @Description = 'Google G Suite RhubarbP',
        @TransactionGroupID = 1, -- Admin
        @AmountOut = 10.68,
        @CreatedBy = 'CSV Import September 2025 v2';
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
    AND Description = 'Refund'
    AND TotalAmount = 15.00
    AND TransactionType = 'Receipt'
    AND TransactionGroupID = 5 -- Revenue
)
BEGIN
    PRINT 'Importing: Refund income (15/09/2025)';
    EXEC sp_ImportBankTransaction_v2
        @ActualDate = '2025-09-15',
        @BankDate = '2025-09-15',
        @Description = 'Refund',
        @TransactionGroupID = 5, -- Revenue
        @AmountIn = 15.00,
        @CreatedBy = 'CSV Import September 2025 v2';
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
    AND Description = 'Google Gemini'
    AND TotalAmount = 18.99
    AND TransactionGroupID = 3 -- Publishing
)
BEGIN
    PRINT 'Importing: Google Gemini publishing expense (16/09/2025)';
    EXEC sp_ImportBankTransaction_v2
        @ActualDate = '2025-09-16',
        @BankDate = '2025-09-16',
        @Description = 'Google Gemini',
        @TransactionGroupID = 3, -- Publishing
        @AmountOut = 18.99,
        @CreatedBy = 'CSV Import September 2025 v2';
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
    AND Description = 'Udemy'
    AND TotalAmount = 15.99
    AND TransactionGroupID = 4 -- Research
)
BEGIN
    PRINT 'Importing: Udemy research expense (17/09/2025)';
    EXEC sp_ImportBankTransaction_v2
        @ActualDate = '2025-09-17',
        @BankDate = '2025-09-18',
        @Description = 'Udemy',
        @TransactionGroupID = 4, -- Research
        @AmountOut = 15.99,
        @CreatedBy = 'CSV Import September 2025 v2';
END
ELSE
BEGIN
    PRINT 'SKIPPED: Udemy research expense (17/09/2025) - already exists';
END
GO

PRINT '';
PRINT 'September 2025 CSV import v2 completed successfully';
PRINT 'Total transactions: 6';
PRINT 'Transaction breakdown by group:';

-- Show transaction summary by group
SELECT
    tg.GroupName as 'Transaction Group',
    COUNT(*) as 'Count',
    SUM(CASE WHEN t.TransactionType = 'Payment' THEN t.TotalAmount ELSE 0 END) as 'Total Expenses',
    SUM(CASE WHEN t.TransactionType = 'Receipt' THEN t.TotalAmount ELSE 0 END) as 'Total Revenue'
FROM Transactions t
INNER JOIN TransactionGroup tg ON t.TransactionGroupID = tg.TransactionGroupID
WHERE t.CreatedBy = 'CSV Import September 2025 v2'
GROUP BY tg.GroupName, tg.TransactionGroupID
ORDER BY tg.TransactionGroupID;

PRINT 'Net outflow: £93.85 (£124.85 expenses - £15.00 revenue + £15.00 refund)';

-- =============================================
-- Verification Queries
-- =============================================

PRINT '';
PRINT 'Verification: Recent transactions imported with TransactionGroups';

-- Show recently imported transactions with groups
SELECT TOP 10
    t.TransactionDate,
    t.Description,
    tg.GroupName as 'Transaction Group',
    t.TotalAmount,
    t.TransactionType,
    t.CreatedBy
FROM Transactions t
LEFT JOIN TransactionGroup tg ON t.TransactionGroupID = tg.TransactionGroupID
WHERE t.CreatedBy = 'CSV Import September 2025 v2'
ORDER BY t.TransactionDate, t.CreatedDate;

-- Show running balance with transaction groups
PRINT '';
PRINT 'Running balance with transaction groups:';

SELECT TOP 10
    ActualDate,
    Item as Description,
    TransactionGroup,
    [In] as 'Money In',
    [Out] as 'Money Out',
    Balance as 'Running Balance'
FROM vw_BankRunningBalance
WHERE CreatedBy = 'CSV Import September 2025 v2'
ORDER BY ActualDate;

PRINT '';
PRINT 'Import verification complete - all transactions properly categorized!';
GO