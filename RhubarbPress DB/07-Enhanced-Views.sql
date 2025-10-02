-- Rhubarb Press Accounting System - Enhanced Views and Reporting
-- Comprehensive views with transaction group support
-- Target: Azure SQL Database (rhubarbpressdb)
-- DEPLOYMENT-READY VERSION

USE rhubarbpressdb;
GO

PRINT 'Creating Enhanced Views and Reporting for Rhubarb Press';
PRINT 'Date: ' + CONVERT(NVARCHAR(19), GETDATE(), 120);
PRINT '';
GO

-- =============================================
-- Enhanced Bank Running Balance View
-- =============================================
PRINT 'Creating enhanced bank running balance view...';
GO

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
-- Enhanced Monthly Summary View
-- =============================================
PRINT 'Creating enhanced monthly summary view...';
GO

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
-- Enhanced Bank Reconciliation View
-- =============================================
PRINT 'Creating enhanced bank reconciliation view...';
GO

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
-- Transaction Summary by Group View
-- =============================================
PRINT 'Creating transaction summary by group view...';
GO

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
-- Detailed Transaction View
-- =============================================
PRINT 'Creating detailed transaction view...';
GO

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
-- Enhanced Current Bank Balances View (update existing)
-- =============================================
PRINT 'Updating current bank balances view...';
GO

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
-- Transaction Group Analysis View
-- =============================================
PRINT 'Creating transaction group analysis view...';
GO

CREATE OR ALTER VIEW vw_TransactionGroupAnalysis AS
SELECT
    tg.GroupName as TransactionGroup,
    YEAR(t.TransactionDate) as [Year],
    MONTH(t.TransactionDate) as [Month],
    DATENAME(MONTH, t.TransactionDate) + ' ' + CAST(YEAR(t.TransactionDate) AS NVARCHAR(4)) as MonthYear,
    COUNT(*) as TransactionCount,
    SUM(CASE WHEN t.TransactionType = 'Payment' THEN t.TotalAmount ELSE 0 END) as MonthlyExpenses,
    SUM(CASE WHEN t.TransactionType = 'Receipt' THEN t.TotalAmount ELSE 0 END) as MonthlyRevenue,
    SUM(CASE WHEN t.TransactionType = 'Receipt' THEN t.TotalAmount ELSE 0 END) -
    SUM(CASE WHEN t.TransactionType = 'Payment' THEN t.TotalAmount ELSE 0 END) as MonthlyNet,
    AVG(t.TotalAmount) as AverageTransactionAmount
FROM TransactionGroup tg
LEFT JOIN Transactions t ON tg.TransactionGroupID = t.TransactionGroupID
WHERE tg.IsActive = 1 AND t.TransactionDate IS NOT NULL
GROUP BY
    tg.GroupName,
    YEAR(t.TransactionDate),
    MONTH(t.TransactionDate),
    DATENAME(MONTH, t.TransactionDate);
GO

-- =============================================
-- Cash Flow Summary View
-- =============================================
PRINT 'Creating cash flow summary view...';
GO

CREATE OR ALTER VIEW vw_CashFlowSummary AS
WITH BankMovements AS (
    SELECT
        t.TransactionDate,
        tg.GroupName as TransactionGroup,
        CASE
            WHEN tl.DebitAmount > 0 THEN tl.DebitAmount  -- Money in
            WHEN tl.CreditAmount > 0 THEN -tl.CreditAmount -- Money out
            ELSE 0
        END as CashFlow
    FROM Transactions t
    INNER JOIN TransactionLines tl ON t.TransactionID = tl.TransactionID
    INNER JOIN ChartOfAccounts coa ON tl.AccountID = coa.AccountID
    LEFT JOIN TransactionGroup tg ON t.TransactionGroupID = tg.TransactionGroupID
    WHERE coa.AccountCode = '1001' -- Bank account
)
SELECT
    TransactionDate,
    TransactionGroup,
    SUM(CashFlow) as DailyCashFlow,
    SUM(SUM(CashFlow)) OVER (
        ORDER BY TransactionDate
        ROWS UNBOUNDED PRECEDING
    ) as RunningCashPosition
FROM BankMovements
GROUP BY TransactionDate, TransactionGroup;
GO

PRINT '';
PRINT '=== Enhanced Views and Reporting Created Successfully ===';
PRINT 'Views created/updated:';
PRINT '  - vw_BankRunningBalance: Enhanced with transaction groups';
PRINT '  - vw_MonthlySummary: Monthly breakdown by transaction group';
PRINT '  - vw_BankReconciliation: Bank reconciliation with groups';
PRINT '  - vw_TransactionSummaryByGroup: Summary statistics by group';
PRINT '  - vw_TransactionDetails: Detailed transaction view';
PRINT '  - vw_CurrentBankBalances: Updated with last transaction group';
PRINT '  - vw_TransactionGroupAnalysis: Monthly analysis by group';
PRINT '  - vw_CashFlowSummary: Cash flow tracking by group';
PRINT '';
PRINT 'Sample queries:';
PRINT '  SELECT * FROM vw_BankRunningBalance ORDER BY ActualDate;';
PRINT '  SELECT * FROM vw_TransactionSummaryByGroup ORDER BY TotalExpenses DESC;';
PRINT '  SELECT * FROM vw_TransactionGroupAnalysis WHERE [Year] = YEAR(GETDATE());';
PRINT '  SELECT * FROM vw_CashFlowSummary ORDER BY TransactionDate DESC;';
PRINT '';
PRINT 'Enhanced reporting system is ready for use';
GO
