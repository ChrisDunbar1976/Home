# RhubarbPress DB - SQL Deployment Scripts

Consolidated SQL scripts for deploying the Rhubarb Press accounting system to Azure SQL Database.

## Database Information
- **Target Database**: rhubarbpressdb (Azure SQL Database)
- **Purpose**: Double-entry bookkeeping system for publishing company
- **Features**: UK compliance, VAT/MTD, transaction tracking, bank reconciliation

## Deployment Order

Execute the SQL scripts in the following order:

### 1. Core Schema (01-Core-Schema.sql)
Creates fundamental accounting tables:
- ChartOfAccounts
- Transactions & TransactionLines
- Contacts
- Invoices & InvoiceLines
- AuditLog

### 2. Publishing Schema (02-Publishing-Schema.sql)
Creates publishing-specific tables:
- Authors
- Books & BookCategories
- SalesChannels & BookSales
- RoyaltyCalculations
- ProductionCosts

### 3. UK Compliance (03-UK-Compliance.sql)
Creates compliance and tax tables:
- VATRates & VATReturns
- CorporationTaxCalculations
- CapitalAllowances
- VATTransactionMapping
- ComplianceDocuments
- Includes sp_CalculateVATReturn procedure

### 4. Initial Data Setup (04-Initial-Data-Setup.sql)
Populates reference data:
- UK VAT rates
- Chart of accounts for publishing
- Book categories
- Sales channels
- Sample contacts and books
- Core reporting views (TrialBalance, ProfitAndLoss, BalanceSheet)

### 5. Bank Balance System (05-Bank-Balance-System.sql)
Creates bank balance tracking:
- BankBalance & BankBalanceHistory tables
- sp_InitializeBankBalance procedure
- sp_UpdateBankBalance procedure
- Auto-update trigger (tr_TransactionLines_UpdateBankBalance)
- Balance reporting views

### 6. Transaction Groups System (06-Transaction-Groups-System.sql)
Adds transaction categorization:
- TransactionGroup lookup table
- Enhances Transactions table with BankDate, ReconciliationStatus, TransactionGroupID
- sp_ImportBankTransaction_v2 procedure
- Transaction group helper procedures

### 7. Enhanced Views (07-Enhanced-Views.sql)
Creates comprehensive reporting views:
- vw_BankRunningBalance
- vw_MonthlySummary
- vw_BankReconciliation
- vw_TransactionSummaryByGroup
- vw_TransactionDetails
- vw_TransactionGroupAnalysis
- vw_CashFlowSummary

## Post-Deployment Steps

1. Initialize bank balance:
   ```sql
   EXEC sp_InitializeBankBalance '1001', 10000.00;
   ```

2. Verify deployment:
   ```sql
   SELECT * FROM vw_CurrentBankBalances;
   SELECT * FROM TransactionGroup ORDER BY TransactionGroupID;
   ```

3. Import transactions using:
   ```sql
   EXEC sp_ImportBankTransaction_v2
       @ActualDate = '2025-01-01',
       @Description = 'Sample transaction',
       @TransactionGroupID = 1,
       @AmountOut = 100.00,
       @CreatedBy = 'Import';
   ```

## Key Features

- **Double-Entry Bookkeeping**: Full double-entry accounting system
- **UK Tax Compliance**: VAT returns, Making Tax Digital (MTD), Corporation Tax
- **Publishing Features**: Author royalties, book sales tracking, production costs
- **Bank Reconciliation**: Automated balance tracking with audit trail
- **Transaction Categories**: Organized by business function (Admin, Marketing, Publishing, etc.)
- **Comprehensive Reporting**: Multiple views for financial analysis

## Transaction Groups

| ID | Group Name | Description |
|----|------------|-------------|
| 1 | Admin | Administrative expenses and general business operations |
| 2 | Marketing | Marketing, advertising, and promotional activities |
| 3 | Publishing | Publishing-specific tools, software, and services |
| 4 | Research | Research and development activities |
| 5 | Revenue | Income and revenue transactions |
| 6 | General | General or uncategorized transactions |
| 7 | Production | Production and printing costs |
| 8 | Distribution | Distribution and delivery costs |
| 9 | Royalties | Author royalty payments |

## Notes

- All scripts are idempotent (safe to run multiple times)
- Scripts include comprehensive error checking
- Audit trail automatically tracks all transaction changes
- Bank balances update automatically via triggers
- All views support transaction group filtering

## Version Information

- **Created**: 2025-10-02
- **Source**: Consolidated from RhubarbAccounts/Development
- **Database Target**: Azure SQL Database (rhubarbpressdb)
