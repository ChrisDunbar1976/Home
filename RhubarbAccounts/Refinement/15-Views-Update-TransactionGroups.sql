-- Rhubarb Press Accounting System - Views Update for Transaction Groups
-- Updates all views to include TransactionGroup information
-- Target: Azure SQL Database (rhubarbpressdb)

USE rhubarbpressdb;
GO

PRINT 'Updating views to include TransactionGroup information';
PRINT 'Update Date: ' + CONVERT(NVARCHAR(19), GETDATE(), 120);
PRINT '';

-- =============================================
-- Updated Bank Running Balance View
-- =============================================
PRINT 'Updating vw_BankRunningBalance...';

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
        tg.GroupName as TransactionGroup,
        tg.TransactionGroupID,
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
    LEFT JOIN TransactionGroup tg ON t.TransactionGroupID = tg.TransactionGroupID
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
    TransactionGroup,
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
FROM BankTransactions;
GO

-- =============================================
-- Updated Monthly Summary View
-- =============================================
PRINT 'Updating vw_MonthlySummary...';

CREATE OR ALTER VIEW vw_MonthlySummary AS
SELECT
    YEAR(t.TransactionDate) as [Year],
    MONTH(t.TransactionDate) as [Month],
    DATENAME(MONTH, t.TransactionDate) + ' ' + CAST(YEAR(t.TransactionDate) AS NVARCHAR(4)) as MonthYear,
    tg.GroupName as TransactionGroup,
    tg.TransactionGroupID,
    coa.AccountType,
    COUNT(DISTINCT t.TransactionID) as TransactionCount,
    SUM(CASE WHEN coa.AccountType = 'Expense' THEN tl.DebitAmount ELSE 0 END) as TotalExpenses,
    SUM(CASE WHEN coa.AccountType = 'Revenue' THEN tl.CreditAmount ELSE 0 END) as TotalRevenue,
    SUM(CASE WHEN coa.AccountType = 'Revenue' THEN tl.CreditAmount ELSE 0 END) -
    SUM(CASE WHEN coa.AccountType = 'Expense' THEN tl.DebitAmount ELSE 0 END) as NetAmount
FROM Transactions t
INNER JOIN TransactionLines tl ON t.TransactionID = tl.TransactionID
INNER JOIN ChartOfAccounts coa ON tl.AccountID = coa.AccountID
LEFT JOIN TransactionGroup tg ON t.TransactionGroupID = tg.TransactionGroupID
WHERE coa.AccountType IN ('Revenue', 'Expense')
    AND coa.IsActive = 1
GROUP BY
    YEAR(t.TransactionDate),
    MONTH(t.TransactionDate),
    DATENAME(MONTH, t.TransactionDate),
    tg.GroupName,
    tg.TransactionGroupID,
    coa.AccountType;
GO

-- =============================================
-- Updated Bank Reconciliation View
-- =============================================
PRINT 'Updating vw_BankReconciliation...';

CREATE OR ALTER VIEW vw_BankReconciliation AS
SELECT TOP (100) PERCENT
    t.TransactionDate as ActualDate,
    t.BankDate,
    t.Reference,
    t.Description,
    tg.GroupName as TransactionGroup,
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
LEFT JOIN TransactionGroup tg ON t.TransactionGroupID = tg.TransactionGroupID
WHERE coa.AccountCode = '1001' -- Bank account
ORDER BY t.TransactionDate DESC, t.CreatedDate DESC;
GO

-- =============================================
-- New Transaction Summary by Group View
-- =============================================
PRINT 'Creating vw_TransactionSummaryByGroup...';

CREATE OR ALTER VIEW vw_TransactionSummaryByGroup AS
SELECT
    tg.TransactionGroupID,
    tg.GroupName as TransactionGroup,
    tg.GroupDescription,
    COUNT(DISTINCT t.TransactionID) as TransactionCount,
    SUM(CASE WHEN t.TransactionType = 'Payment' THEN t.TotalAmount ELSE 0 END) as TotalExpenses,
    SUM(CASE WHEN t.TransactionType = 'Receipt' THEN t.TotalAmount ELSE 0 END) as TotalRevenue,
    SUM(CASE WHEN t.TransactionType = 'Receipt' THEN t.TotalAmount ELSE 0 END) -
    SUM(CASE WHEN t.TransactionType = 'Payment' THEN t.TotalAmount ELSE 0 END) as NetAmount,
    MIN(t.TransactionDate) as EarliestTransaction,
    MAX(t.TransactionDate) as LatestTransaction,
    AVG(t.TotalAmount) as AverageTransactionAmount
FROM TransactionGroup tg
LEFT JOIN Transactions t ON tg.TransactionGroupID = t.TransactionGroupID
WHERE tg.IsActive = 1
GROUP BY
    tg.TransactionGroupID,
    tg.GroupName,
    tg.GroupDescription;
GO

-- =============================================
-- New Detailed Transaction View
-- =============================================
PRINT 'Creating vw_TransactionDetails...';

CREATE OR ALTER VIEW vw_TransactionDetails AS
SELECT TOP (100) PERCENT
    t.TransactionID,
    t.TransactionDate,
    t.BankDate,
    t.Reference,
    t.Description,
    tg.GroupName as TransactionGroup,
    tg.GroupDescription as TransactionGroupDescription,
    t.TotalAmount,
    t.TransactionType,
    t.Status,
    -- Account details for each transaction line
    coa.AccountCode,
    coa.AccountName,
    coa.AccountType,
    tl.DebitAmount,
    tl.CreditAmount,
    tl.Description as LineDescription,
    t.CreatedBy,
    t.CreatedDate,
    t.ModifiedDate
FROM Transactions t
INNER JOIN TransactionLines tl ON t.TransactionID = tl.TransactionID
INNER JOIN ChartOfAccounts coa ON tl.AccountID = coa.AccountID
LEFT JOIN TransactionGroup tg ON t.TransactionGroupID = tg.TransactionGroupID
ORDER BY t.TransactionDate DESC, t.TransactionID, tl.LineID;
GO

-- =============================================
-- Updated Current Bank Balances View
-- =============================================
PRINT 'Updating vw_CurrentBankBalances...';

CREATE OR ALTER VIEW vw_CurrentBankBalances AS
SELECT
    coa.AccountCode,
    coa.AccountName,
    bb.CurrentBalance,
    bb.dtModified as LastModified,
    t.TransactionDate as LastTransactionDate,
    t.Description as LastTransactionDescription,
    tg.GroupName as LastTransactionGroup,
    bb.CreatedDate as BalanceCreatedDate
FROM BankBalance bb
INNER JOIN ChartOfAccounts coa ON bb.AccountID = coa.AccountID
LEFT JOIN Transactions t ON bb.LastTransactionID = t.TransactionID
LEFT JOIN TransactionGroup tg ON t.TransactionGroupID = tg.TransactionGroupID
WHERE bb.IsActive = 1;
GO

-- =============================================
-- Show updated view information
-- =============================================
PRINT '';
PRINT '=== Views Updated Successfully ===';
PRINT 'Updated views with TransactionGroup information:';
PRINT '  - vw_BankRunningBalance: Added TransactionGroup column';
PRINT '  - vw_MonthlySummary: Added TransactionGroup breakdown';
PRINT '  - vw_BankReconciliation: Added TransactionGroup column';
PRINT '  - vw_CurrentBankBalances: Added LastTransactionGroup';
PRINT '';
PRINT 'New views created:';
PRINT '  - vw_TransactionSummaryByGroup: Summary statistics by transaction group';
PRINT '  - vw_TransactionDetails: Detailed transaction view with groups';
PRINT '';
PRINT 'Sample queries:';
PRINT '  SELECT * FROM vw_BankRunningBalance ORDER BY ActualDate;';
PRINT '  SELECT * FROM vw_TransactionSummaryByGroup ORDER BY TotalExpenses DESC;';
PRINT '  SELECT * FROM vw_TransactionDetails WHERE TransactionGroup = ''Marketing'';';
GO