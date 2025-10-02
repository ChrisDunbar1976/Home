# Transaction Group Remediation Summary

## 2025-10-02 10:05 BST
- Context: Cleaned supplemental imports so every transaction uses the TransactionGroup system.
- Actions:
  - Added lookup rows to dbo.TransactionGroup for Production, Distribution, and Royalties.
  - Backfilled TransactionGroupID on existing rows by matching category hints in descriptions (UPDATE with CROSS APPLY).
  - Removed bracketed category suffixes from affected descriptions once groups were assigned.
  - Verified vw_BankRunningBalance shows the correct TransactionGroup labels for 26-30 Sep transactions.
- Verification queries:
  - SELECT COUNT(*) FROM dbo.Transactions WHERE TransactionGroupID IS NULL; -> 0
  - SELECT TransactionID, Description, TransactionGroupID FROM dbo.Transactions WHERE TransactionID BETWEEN 6 AND 10;
  - SELECT ActualDate, Item, TransactionGroup FROM dbo.vw_BankRunningBalance WHERE ActualDate BETWEEN '2025-09-26' AND '2025-09-30';

## 2025-10-02 10:15 BST
- Elevated mcp_user to run DDL, then enforced TransactionGroupID as NOT NULL (dropped/recreated FK and index).
- Created/updated procedures:
  - dbo.sp_GetTransactionGroupID
  - dbo.sp_ImportBankTransaction_v2
  - dbo.sp_ImportBankTransaction
  - dbo.sp_ImportBankTransaction_Legacy
- Post-change checks:
  - SELECT IS_NULLABLE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='Transactions' AND COLUMN_NAME='TransactionGroupID'; -> NO
  - SELECT name FROM sys.procedures WHERE name LIKE 'sp_ImportBankTransaction%' OR name = 'sp_GetTransactionGroupID'; confirms expected procedures.
  - SELECT ActualDate, Item, TransactionGroup FROM dbo.vw_BankRunningBalance WHERE ActualDate BETWEEN '2025-09-26' AND '2025-09-30'; still returns correct group labels.

## 2025-10-02 10:17 BST
- Confirmed local VM time reports in UTC; adjusted log times above to reflect BST.
