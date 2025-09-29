-- Rhubarb Press Accounting System - Balance and Running Balance Views
-- Creates views for easy balance reporting similar to CSV format
-- Target: Azure SQL Database (rhubarbpressdb)

USE rhubarbpressdb;
GO

-- =============================================
-- Bank Account Running Balance View
-- Shows transactions with running balance like CSV format
-- =============================================
CREATE OR ALTER VIEW vw_BankRunningBalance AS
WITH BankTransactions AS (
    -- Get all bank account transactions with their amounts
    SELECT
        t.TransactionID,
        t.TransactionDate,
        t.BankDate,
        t.Reference,
        t.Description,
        t.TransactionType,
        t.CreatedBy,
        t.CreatedDate,
        -- Calculate bank movement (positive = money in, negative = money out)
        CASE
            WHEN tl.DebitAmount > 0 THEN tl.DebitAmount  -- Money coming into bank
            WHEN tl.CreditAmount > 0 THEN -tl.CreditAmount -- Money going out of bank
            ELSE 0
        END as BankMovement,
        tl.Description as LineDescription
    FROM Transactions t
    INNER JOIN TransactionLines tl ON t.TransactionID = tl.TransactionID
    INNER JOIN ChartOfAccounts coa ON tl.AccountID = coa.AccountID
    WHERE coa.AccountCode = '1001' -- Bank account
        AND coa.AccountType = 'Asset'
),
OpeningBalance AS (
    -- Get the opening balance from BankBalanceHistory, or use current balance if no history
    SELECT COALESCE(
        (SELECT TOP 1 PreviousBalance + BalanceChange
         FROM BankBalanceHistory bbh
         INNER JOIN ChartOfAccounts coa ON bbh.AccountID = coa.AccountID
         WHERE coa.AccountCode = '1001'
           AND bbh.ChangeType = 'Opening'
         ORDER BY bbh.RecordedDate),
        (SELECT COALESCE(CurrentBalance, 0)
         FROM BankBalance bb
         INNER JOIN ChartOfAccounts coa ON bb.AccountID = coa.AccountID
         WHERE coa.AccountCode = '1001' AND bb.IsActive = 1),
        0
    ) as OpeningBalance
)
SELECT
    TransactionDate as ActualDate,
    BankDate,
    Reference,
    Description as Item,
    TransactionType,
    CASE WHEN BankMovement > 0 THEN BankMovement ELSE 0 END as [In],
    CASE WHEN BankMovement < 0 THEN ABS(BankMovement) ELSE 0 END as [Out],
    -- Running balance calculation using stored opening balance
    (SELECT OpeningBalance FROM OpeningBalance) + SUM(BankMovement) OVER (
        ORDER BY TransactionDate, TransactionID
        ROWS UNBOUNDED PRECEDING
    ) as Balance,
    CreatedBy,
    CreatedDate
FROM BankTransactions
-- Opening balance now retrieved from BankBalanceHistory table
;
GO

-- =============================================
-- Account Balances Summary View
-- Shows current balance for all accounts
-- =============================================
CREATE OR ALTER VIEW vw_AccountBalances AS
SELECT
    coa.AccountCode,
    coa.AccountName,
    coa.AccountType,
    coa.AccountSubType,
    coa.PublishingCategory,
    COALESCE(SUM(tl.DebitAmount), 0) as TotalDebits,
    COALESCE(SUM(tl.CreditAmount), 0) as TotalCredits,
    -- Calculate balance based on account type
    CASE coa.AccountType
        WHEN 'Asset' THEN COALESCE(SUM(tl.DebitAmount - tl.CreditAmount), 0)
        WHEN 'Expense' THEN COALESCE(SUM(tl.DebitAmount - tl.CreditAmount), 0)
        WHEN 'Liability' THEN COALESCE(SUM(tl.CreditAmount - tl.DebitAmount), 0)
        WHEN 'Equity' THEN COALESCE(SUM(tl.CreditAmount - tl.DebitAmount), 0)
        WHEN 'Revenue' THEN COALESCE(SUM(tl.CreditAmount - tl.DebitAmount), 0)
        ELSE 0
    END as CurrentBalance,
    COUNT(tl.LineID) as TransactionCount,
    MAX(t.TransactionDate) as LastTransactionDate
FROM ChartOfAccounts coa
LEFT JOIN TransactionLines tl ON coa.AccountID = tl.AccountID
LEFT JOIN Transactions t ON tl.TransactionID = t.TransactionID
WHERE coa.IsActive = 1
GROUP BY
    coa.AccountCode,
    coa.AccountName,
    coa.AccountType,
    coa.AccountSubType,
    coa.PublishingCategory
;
GO

-- =============================================
-- Trial Balance View
-- Traditional accounting trial balance
-- =============================================
CREATE OR ALTER VIEW vw_TrialBalance AS
SELECT
    AccountCode,
    AccountName,
    AccountType,
    -- Show debits and credits in separate columns
    CASE WHEN CurrentBalance >= 0 AND AccountType IN ('Asset', 'Expense')
         THEN CurrentBalance
         WHEN CurrentBalance < 0 AND AccountType IN ('Liability', 'Equity', 'Revenue')
         THEN ABS(CurrentBalance)
         ELSE 0
    END as DebitBalance,
    CASE WHEN CurrentBalance >= 0 AND AccountType IN ('Liability', 'Equity', 'Revenue')
         THEN CurrentBalance
         WHEN CurrentBalance < 0 AND AccountType IN ('Asset', 'Expense')
         THEN ABS(CurrentBalance)
         ELSE 0
    END as CreditBalance,
    CurrentBalance,
    TransactionCount,
    LastTransactionDate
FROM AccountBalances
WHERE CurrentBalance != 0 OR TransactionCount > 0
;
GO

-- =============================================
-- Monthly Summary View
-- Shows monthly totals by category
-- =============================================
CREATE OR ALTER VIEW vw_MonthlySummary AS
SELECT
    YEAR(t.TransactionDate) as [Year],
    MONTH(t.TransactionDate) as [Month],
    DATENAME(MONTH, t.TransactionDate) + ' ' + CAST(YEAR(t.TransactionDate) AS NVARCHAR(4)) as MonthYear,
    coa.PublishingCategory,
    coa.AccountType,
    COUNT(DISTINCT t.TransactionID) as TransactionCount,
    SUM(CASE WHEN coa.AccountType = 'Expense' THEN tl.DebitAmount ELSE 0 END) as TotalExpenses,
    SUM(CASE WHEN coa.AccountType = 'Revenue' THEN tl.CreditAmount ELSE 0 END) as TotalRevenue,
    SUM(CASE WHEN coa.AccountType = 'Revenue' THEN tl.CreditAmount ELSE 0 END) -
    SUM(CASE WHEN coa.AccountType = 'Expense' THEN tl.DebitAmount ELSE 0 END) as NetAmount
FROM Transactions t
INNER JOIN TransactionLines tl ON t.TransactionID = tl.TransactionID
INNER JOIN ChartOfAccounts coa ON tl.AccountID = coa.AccountID
WHERE coa.AccountType IN ('Revenue', 'Expense')
    AND coa.IsActive = 1
GROUP BY
    YEAR(t.TransactionDate),
    MONTH(t.TransactionDate),
    DATENAME(MONTH, t.TransactionDate),
    coa.PublishingCategory,
    coa.AccountType
;
GO

-- =============================================
-- Bank Reconciliation View
-- Helps with bank statement reconciliation
-- =============================================
CREATE OR ALTER VIEW vw_BankReconciliation AS
SELECT TOP (100) PERCENT
    t.TransactionDate as ActualDate,
    t.BankDate,
    t.Reference,
    t.Description,
    t.TotalAmount,
    t.TransactionType,
    COALESCE(t.ReconciliationStatus, 'Pending') as ReconciliationStatus,
    -- Days between actual and bank date
    CASE
        WHEN t.BankDate IS NOT NULL
        THEN DATEDIFF(day, t.TransactionDate, t.BankDate)
        ELSE NULL
    END as DateDifference,
    t.CreatedBy,
    t.CreatedDate
FROM Transactions t
INNER JOIN TransactionLines tl ON t.TransactionID = tl.TransactionID
INNER JOIN ChartOfAccounts coa ON tl.AccountID = coa.AccountID
WHERE coa.AccountCode = '1001' -- Bank account
ORDER BY t.TransactionDate DESC, t.CreatedDate DESC
;
GO

-- =============================================
-- Create indexes for performance
-- =============================================
-- Index for running balance calculations
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Transactions') AND name = 'IX_Transactions_Date_ID')
BEGIN
    CREATE INDEX IX_Transactions_Date_ID ON Transactions(TransactionDate, TransactionID);
    PRINT 'Created index IX_Transactions_Date_ID for running balance performance';
END

-- =============================================
-- Grant permissions (if needed)
-- =============================================
-- These views should be accessible to reporting users
-- GRANT SELECT ON BankRunningBalance TO [ReportingUsers];
-- GRANT SELECT ON AccountBalances TO [ReportingUsers];
-- GRANT SELECT ON TrialBalance TO [ReportingUsers];
-- GRANT SELECT ON MonthlySummary TO [ReportingUsers];
-- GRANT SELECT ON BankReconciliation TO [ReportingUsers];

PRINT 'Balance views created successfully for Rhubarb Press';
PRINT '';
PRINT 'Available Views:';
PRINT '  - vw_BankRunningBalance: CSV-like view with running bank balance';
PRINT '  - vw_AccountBalances: Current balance for all accounts';
PRINT '  - vw_TrialBalance: Traditional accounting trial balance';
PRINT '  - vw_MonthlySummary: Monthly totals by category';
PRINT '  - vw_BankReconciliation: Bank statement reconciliation helper';
PRINT '';
PRINT 'Usage examples:';
PRINT '  SELECT * FROM vw_BankRunningBalance; -- Pre-ordered by ActualDate';
PRINT '  SELECT * FROM vw_AccountBalances WHERE AccountType = ''Expense'';';
PRINT '  SELECT * FROM vw_TrialBalance;';
PRINT '  SELECT * FROM vw_BankReconciliation; -- Pre-ordered by date DESC';
GO