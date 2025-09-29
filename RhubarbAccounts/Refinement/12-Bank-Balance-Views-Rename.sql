-- Rhubarb Press Accounting System - Bank Balance Views Rename
-- Updates view names to use vw_ prefix convention
-- From: 10-Bank-Balance-System-Fixed.sql (Views section only)
-- Target: Azure SQL Database (rhubarbpressdb)

USE rhubarbpressdb;
GO

-- =============================================
-- Drop old views if they exist (without vw_ prefix)
-- =============================================
IF EXISTS (SELECT * FROM sys.views WHERE name = 'CurrentBankBalances')
    DROP VIEW CurrentBankBalances;

IF EXISTS (SELECT * FROM sys.views WHERE name = 'BankBalanceAuditTrail')
    DROP VIEW BankBalanceAuditTrail;

PRINT 'Dropped old bank balance views (if they existed)';
GO

-- =============================================
-- Create renamed views with vw_ prefix
-- =============================================

-- Current Bank Balances View
CREATE OR ALTER VIEW vw_CurrentBankBalances AS
SELECT
    coa.AccountCode,
    coa.AccountName,
    bb.CurrentBalance,
    bb.dtModified as LastModified,
    t.TransactionDate as LastTransactionDate,
    t.Description as LastTransactionDescription,
    bb.CreatedDate as BalanceCreatedDate
FROM BankBalance bb
INNER JOIN ChartOfAccounts coa ON bb.AccountID = coa.AccountID
LEFT JOIN Transactions t ON bb.LastTransactionID = t.TransactionID
WHERE bb.IsActive = 1;
GO

-- Bank Balance History View
CREATE OR ALTER VIEW vw_BankBalanceAuditTrail AS
SELECT TOP (100) PERCENT
    coa.AccountCode,
    coa.AccountName,
    bbh.TransactionDate,
    bbh.TransactionDescription,
    bbh.PreviousBalance,
    bbh.BalanceChange,
    bbh.NewBalance,
    bbh.ChangeType,
    bbh.TransactionAmount,
    bbh.RecordedDate,
    bbh.RecordedBy
FROM BankBalanceHistory bbh
INNER JOIN ChartOfAccounts coa ON bbh.AccountID = coa.AccountID
ORDER BY bbh.TransactionDate DESC, bbh.RecordedDate DESC;
GO

PRINT 'Bank balance views renamed successfully with vw_ prefix';
PRINT '';
PRINT 'Updated view names:';
PRINT '  - vw_CurrentBankBalances: Current bank account balances';
PRINT '  - vw_BankBalanceAuditTrail: Complete audit trail of balance changes';
PRINT '';
PRINT 'Usage examples:';
PRINT '  SELECT * FROM vw_CurrentBankBalances;';
PRINT '  SELECT * FROM vw_BankBalanceAuditTrail;';
GO