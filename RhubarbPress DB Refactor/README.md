# RhubarbPress DB - SQL Deployment Scripts (Refactored)

**Complete, workflow-ready deployment scripts for the Rhubarb Press accounting system**

## Overview

This is a complete double-entry bookkeeping system designed specifically for publishing companies, with full UK tax compliance (VAT/MTD, Corporation Tax), author royalty tracking, book sales management, and bank reconciliation.

### Key Features

- ✅ **Double-Entry Bookkeeping**: Full double-entry accounting system with automated validation
- ✅ **UK Tax Compliance**: VAT returns, Making Tax Digital (MTD), Corporation Tax calculations
- ✅ **Publishing-Specific**: Author royalties, book sales tracking, production cost management
- ✅ **Bank Reconciliation**: Automated balance tracking with complete audit trail
- ✅ **Transaction Categorization**: Organized by business function (Admin, Marketing, Publishing, etc.)
- ✅ **Comprehensive Reporting**: 12+ views for financial analysis and business intelligence
- ✅ **Business Procedures**: 9 stored procedures for common publishing operations

## Database Information

- **Target Database**: rhubarbpressdb (Azure SQL Database)
- **Purpose**: Publishing company accounting and financial management
- **Deployment**: Sequential execution of 9 scripts
- **Status**: Production-ready

## Quick Start

### Prerequisites

- Azure SQL Database or SQL Server 2019+
- Database: `rhubarbpressdb` (must already exist)
- Permissions: db_owner or equivalent

### Deployment Steps

Execute the SQL scripts in order:

```bash
# Connect to your Azure SQL Database
sqlcmd -S your-server.database.windows.net -d rhubarbpressdb -U your-username -P your-password

# Execute scripts in sequence
:r 01-Core-Schema.sql
:r 02-Publishing-Schema.sql
:r 03-UK-Compliance.sql
:r 04-Initial-Data-Setup.sql
:r 05-Bank-Balance-System.sql
:r 06-Transaction-Groups-System.sql
:r 07-Enhanced-Views.sql
:r 08-Publishing-Business-Procedures.sql
:r 09-Test-Transaction-Data.sql
```

**Total deployment time**: ~2-3 minutes

## Deployment Order & Script Details

### 1. Core Schema (01-Core-Schema.sql)
**Creates fundamental accounting tables**

**Tables:**
- `ChartOfAccounts` - Chart of accounts with publishing categories
- `Transactions` - Transaction headers with status tracking
- `TransactionLines` - Double-entry transaction lines
- `Contacts` - Authors, suppliers, customers
- `Invoices` - Sales and purchase invoices
- `InvoiceLines` - Invoice line items
- `AuditLog` - Complete audit trail

**Indexes:** 7 performance indexes for optimal query performance

---

### 2. Publishing Schema (02-Publishing-Schema.sql)
**Creates publishing-specific tables**

**Tables:**
- `Authors` - Author contracts and payment details
- `BookCategories` - Genre classifications
- `Books` - Book catalog with production tracking
- `SalesChannels` - Sales channel configurations (Amazon, bookstores, etc.)
- `BookSales` - Sales transaction tracking
- `RoyaltyCalculations` - Royalty period calculations
- `RoyaltyCalculationDetails` - Detailed royalty breakdowns
- `ProductionCosts` - Book production cost tracking

**Views:**
- `vw_BookProfitability` - Book profitability analysis
- `vw_AuthorPerformance` - Author performance metrics

**Indexes:** 9 performance indexes

---

### 3. UK Compliance (03-UK-Compliance.sql)
**Creates compliance and tax tables**

**Tables:**
- `VATRates` - UK VAT rate configurations
- `VATReturns` - VAT return calculations (9 boxes)
- `CorporationTaxCalculations` - Corporation tax tracking
- `CapitalAllowances` - Capital allowances for tax
- `VATTransactionMapping` - Transaction to VAT box mapping
- `ComplianceDocuments` - Document storage for submissions

**Stored Procedures:**
- `sp_CalculateVATReturn` - Automated VAT return calculation

**Triggers:**
- `TR_Transactions_Audit` - Audit trail trigger

**Indexes:** 3 performance indexes

---

### 4. Initial Data Setup (04-Initial-Data-Setup.sql)
**Populates reference data and sample data**

**Reference Data:**
- UK VAT rates (Zero Rate, Standard, Reduced, Exempt)
- Chart of accounts (60+ accounts for publishing)
- Book categories (7 genre classifications)
- Sales channels (10 distribution channels)

**Sample Data:**
- Rhubarb Press company contact
- Sample author (Jane Smith)
- Sample book ("The Mystery of Rhubarb House")

**Views:**
- `TrialBalance` - Traditional trial balance report
- `ProfitAndLoss` - P&L statement
- `BalanceSheet` - Balance sheet report

---

### 5. Bank Balance System (05-Bank-Balance-System.sql)
**Creates bank balance tracking with automation**

**Tables:**
- `BankBalance` - Current bank balance
- `BankBalanceHistory` - Complete balance audit trail

**Stored Procedures:**
- `sp_InitializeBankBalance` - Initialize bank balance
- `sp_UpdateBankBalance` - Update bank balance (auto-called)

**Triggers:**
- `tr_TransactionLines_UpdateBankBalance` - Auto-update balance on transactions

**Views:**
- `vw_CurrentBankBalances` - Current balance summary
- `vw_BankBalanceHistory` - Balance history view

---

### 6. Transaction Groups System (06-Transaction-Groups-System.sql)
**Adds transaction categorization**

**Tables:**
- `TransactionGroup` - Transaction category lookup (9 groups)

**Table Alterations:**
- Adds `BankDate`, `ReconciliationStatus`, `TransactionGroupID` to Transactions

**Stored Procedures:**
- `sp_ImportBankTransaction` - Import bank transactions with categorization
- `sp_GetTransactionGroupID` - Helper for category lookup

**Transaction Groups:**
| ID | Group Name | Description |
|----|------------|-------------|
| 1 | Admin | Administrative expenses and general operations |
| 2 | Marketing | Marketing, advertising, promotional activities |
| 3 | Publishing | Publishing-specific tools, software, services |
| 4 | Research | Research and development activities |
| 5 | Revenue | Income and revenue transactions |
| 6 | General | General or uncategorized transactions |
| 7 | Production | Production and printing costs |
| 8 | Distribution | Distribution and delivery costs |
| 9 | Royalties | Author royalty payments |

---

### 7. Enhanced Views (07-Enhanced-Views.sql)
**Creates comprehensive reporting views**

**Core Reporting Views:**
- `vw_AccountBalances` - Current balance for all accounts
- `vw_TrialBalance` - Traditional trial balance
- `vw_BankBalanceAuditTrail` - Bank balance history audit

**Bank Transaction Views:**
- `vw_BankRunningBalance` - Running balance with transaction groups
- `vw_BankReconciliation` - Bank reconciliation status
- `vw_CurrentBankBalances` - Current bank balance summary

**Analysis Views:**
- `vw_MonthlySummary` - Monthly breakdown by transaction group
- `vw_TransactionSummaryByGroup` - Summary statistics by group
- `vw_TransactionDetails` - Detailed transaction view
- `vw_TransactionGroupAnalysis` - Monthly analysis by group
- `vw_CashFlowSummary` - Cash flow tracking

**Total Views:** 11 comprehensive views

---

### 8. Publishing Business Procedures (08-Publishing-Business-Procedures.sql)
**Business logic procedures for publishing operations**

**Stored Procedures:**

| Procedure | Purpose |
|-----------|---------|
| `sp_CreateJournalEntry` | Create manual journal entries with JSON input |
| `sp_CreateInvoice` | Create customer invoices with JSON line items |
| `sp_ProcessBookSales` | Import and process book sales data |
| `sp_CalculateAuthorRoyalties` | Calculate royalties for a period |
| `sp_BookProfitabilityReport` | Generate book profitability analysis |
| `sp_GenerateTrialBalance` | Generate trial balance as of date |
| `sp_DashboardSummary` | Generate dashboard summary metrics |
| `sp_SetupBankImportAccounts` | Setup accounts for bank imports |
| `sp_BulkImportBankTransactions` | Placeholder for CSV bulk import |

**Total Procedures:** 9 business procedures

---

### 9. Test Transaction Data (09-Test-Transaction-Data.sql)
**Generates realistic test transactions**

**Data Created:**
- Initializes bank balance (£10,000 opening balance)
- Creates 60+ test transactions (Sep-Oct 2025)
- Covers all 9 transaction groups
- Includes both income and expenses
- Realistic publishing industry transactions

**Transaction Types:**
- Book sales (Amazon, bookstores, direct)
- Production costs (printing, editing, design)
- Marketing expenses (ads, events, campaigns)
- Royalty payments
- Administrative expenses

---

## Post-Deployment Steps

### 1. Verify Deployment

```sql
-- Check all tables exist (24 tables expected)
SELECT COUNT(*) as TableCount FROM sys.tables WHERE type = 'U';

-- Check all views exist (14 views expected)
SELECT COUNT(*) as ViewCount FROM sys.views WHERE type = 'V';

-- Check all stored procedures exist (12 procedures expected)
SELECT COUNT(*) as ProcedureCount FROM sys.procedures WHERE type = 'P';

-- Verify transaction groups
SELECT * FROM TransactionGroup ORDER BY TransactionGroupID;

-- Check bank balance
SELECT * FROM vw_CurrentBankBalances;

-- View test transactions
SELECT TOP 10 * FROM vw_BankRunningBalance ORDER BY ActualDate DESC;
```

### 2. Initialize Production Data

If not using test data, initialize your bank balance:

```sql
-- Initialize with your opening balance
EXEC sp_InitializeBankBalance '1001', 10000.00, '2025-01-01';
```

### 3. Import Your Transactions

```sql
-- Import a bank transaction
EXEC sp_ImportBankTransaction
    @ActualDate = '2025-01-01',
    @Description = 'Sample transaction',
    @TransactionGroupID = 1,
    @AmountOut = 100.00,
    @CreatedBy = 'Import';
```

---

## Database Statistics

### Tables: 24
- Core Accounting: 7
- Publishing-Specific: 8
- Compliance: 6
- Bank System: 2
- Lookup: 1

### Views: 14
- Core: 3 (Trial Balance, P&L, Balance Sheet)
- Enhanced: 11 (Bank, Analysis, Reporting)

### Stored Procedures: 12
- Tax/Compliance: 1
- Bank System: 3
- Publishing Business: 9

### Triggers: 2
- Audit: 1
- Bank Balance Auto-update: 1

### Indexes: 22
- Performance optimized for common queries

---

## Key Features Detail

### Double-Entry Bookkeeping

Every transaction creates balanced debit/credit entries:

```sql
-- Example: £100 expense payment
Debit:  Expense Account  £100
Credit: Bank Account     £100
```

Enforced by database constraint on `TransactionLines`.

### UK Tax Compliance

**VAT Returns:**
- Automated calculation of all 9 VAT boxes
- Maps transactions to appropriate boxes
- Supports Zero Rate (books), Standard, Reduced, Exempt
- Ready for Making Tax Digital (MTD) submission

**Corporation Tax:**
- Tracks taxable profits
- Capital allowances tracking
- Tax computation support

### Author Royalty Management

**Automated Calculation:**
1. Import book sales with `sp_ProcessBookSales`
2. Calculate royalties with `sp_CalculateAuthorRoyalties`
3. Generate payment file
4. Track payment status

**Features:**
- Per-author royalty rates
- Minimum payment thresholds
- Quarterly/monthly calculations
- Detailed breakdowns by book

### Bank Reconciliation

**Automated Balance Tracking:**
- Real-time balance updates via triggers
- Complete audit trail
- Support for bank date vs transaction date
- Reconciliation status tracking

**Workflow:**
1. Import bank transactions
2. System auto-updates balance
3. View running balance in `vw_BankRunningBalance`
4. Reconcile using `vw_BankReconciliation`

### Transaction Categorization

All transactions categorized into 9 business groups:
- Simplifies reporting
- Enables budget tracking
- Supports cash flow analysis
- Facilitates tax planning

---

## Sample Queries

### Financial Reporting

```sql
-- Trial Balance
SELECT * FROM TrialBalance;

-- Profit & Loss
SELECT AccountType, SUM(Amount) as Total
FROM ProfitAndLoss
GROUP BY AccountType;

-- Balance Sheet
SELECT AccountType, SUM(Balance) as Total
FROM BalanceSheet
GROUP BY AccountType;
```

### Bank Analysis

```sql
-- Current bank balance
SELECT * FROM vw_CurrentBankBalances;

-- Running balance by date
SELECT * FROM vw_BankRunningBalance
ORDER BY ActualDate;

-- Monthly cash flow
SELECT
    [Year], [Month],
    SUM(TotalExpenses) as Expenses,
    SUM(TotalRevenue) as Revenue,
    SUM(NetAmount) as NetCashFlow
FROM vw_MonthlySummary
GROUP BY [Year], [Month]
ORDER BY [Year], [Month];
```

### Transaction Group Analysis

```sql
-- Summary by group
SELECT * FROM vw_TransactionSummaryByGroup
ORDER BY TotalExpenses DESC;

-- Monthly breakdown
SELECT * FROM vw_TransactionGroupAnalysis
WHERE [Year] = 2025
ORDER BY [Year], [Month], TransactionGroup;
```

### Publishing Analysis

```sql
-- Book profitability
EXEC sp_BookProfitabilityReport;

-- Author performance
SELECT * FROM vw_AuthorPerformance
ORDER BY TotalRevenue DESC;

-- Sales by channel
SELECT
    sc.ChannelName,
    COUNT(*) as SalesCount,
    SUM(bs.NetRevenue) as TotalRevenue
FROM BookSales bs
INNER JOIN SalesChannels sc ON bs.ChannelID = sc.ChannelID
GROUP BY sc.ChannelName
ORDER BY TotalRevenue DESC;
```

---

## Common Workflows

### 1. Import Bank Statement

```sql
-- For each line in bank statement:
EXEC sp_ImportBankTransaction
    @ActualDate = '2025-01-15',
    @BankDate = '2025-01-16',
    @Description = 'Amazon Sales Payment',
    @TransactionGroupID = 5,  -- Revenue
    @AmountIn = 1250.00,
    @CreatedBy = 'Bank Import';
```

### 2. Calculate VAT Return

```sql
-- Calculate VAT for quarter
EXEC sp_CalculateVATReturn
    @PeriodStart = '2025-01-01',
    @PeriodEnd = '2025-03-31',
    @CreatedBy = 'Accountant';

-- View VAT return
SELECT TOP 1 *
FROM VATReturns
ORDER BY ReturnID DESC;
```

### 3. Process Author Royalties

```sql
-- Calculate royalties for Q1
EXEC sp_CalculateAuthorRoyalties
    @PeriodStart = '2025-01-01',
    @PeriodEnd = '2025-03-31',
    @CalculatedBy = 'Finance';

-- View royalties to be paid
SELECT
    a.AuthorID,
    CONCAT(c.FirstName, ' ', c.LastName) as AuthorName,
    rc.TotalDue,
    rc.Status
FROM RoyaltyCalculations rc
INNER JOIN Authors a ON rc.AuthorID = a.AuthorID
INNER JOIN Contacts c ON a.ContactID = c.ContactID
WHERE rc.Status = 'Calculated'
ORDER BY rc.TotalDue DESC;
```

### 4. Create Customer Invoice

```sql
DECLARE @Lines NVARCHAR(MAX) = '[
    {"Description":"The Mystery of Rhubarb House","Quantity":10,"UnitPrice":12.99,"VATRate":0.0000,"VATAmount":0.00,"BookID":1}
]';

EXEC sp_CreateInvoice
    @ContactID = 1,
    @InvoiceDate = '2025-01-15',
    @DueDate = '2025-02-15',
    @CreatedBy = 'Sales',
    @InvoiceLines = @Lines;
```

---

## Maintenance

### Database Backup

```sql
-- Backup database (Azure SQL)
-- Use Azure Portal or Azure CLI for automated backups
-- Point-in-time restore available for 7-35 days

-- On-premise SQL Server:
BACKUP DATABASE rhubarbpressdb
TO DISK = 'C:\Backups\rhubarbpressdb.bak'
WITH COMPRESSION, STATS = 10;
```

### Index Maintenance

```sql
-- Rebuild fragmented indexes
ALTER INDEX ALL ON ChartOfAccounts REBUILD;
ALTER INDEX ALL ON Transactions REBUILD;
ALTER INDEX ALL ON TransactionLines REBUILD;

-- Update statistics
UPDATE STATISTICS ChartOfAccounts;
UPDATE STATISTICS Transactions;
UPDATE STATISTICS TransactionLines;
```

### Archive Old Data

```sql
-- Archive transactions older than 7 years
-- (Recommend creating archive tables first)
SELECT * INTO TransactionsArchive
FROM Transactions
WHERE TransactionDate < DATEADD(YEAR, -7, GETDATE());
```

---

## Troubleshooting

### Common Issues

**Issue: Bank balance not updating**
```sql
-- Check trigger is enabled
SELECT name, is_disabled
FROM sys.triggers
WHERE name = 'tr_TransactionLines_UpdateBankBalance';

-- Manually recalculate if needed
EXEC sp_UpdateBankBalance @TransactionID, @AccountID, @BalanceChange, 'Manual';
```

**Issue: VAT calculation incorrect**
```sql
-- Check VAT rate configuration
SELECT * FROM VATRates WHERE IsActive = 1;

-- Check VAT mappings
SELECT * FROM VATTransactionMapping WHERE VATReturnID = @ReturnID;
```

**Issue: Duplicate transactions**
```sql
-- Find duplicates by reference
SELECT Reference, COUNT(*)
FROM Transactions
GROUP BY Reference
HAVING COUNT(*) > 1;
```

---

## Security Considerations

### User Roles

Recommended database roles:

```sql
-- Create roles
CREATE ROLE AccountingStaff;
CREATE ROLE FinanceManagers;
CREATE ROLE ReadOnlyReports;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON Transactions TO AccountingStaff;
GRANT SELECT, INSERT, UPDATE, DELETE ON Transactions TO FinanceManagers;
GRANT SELECT ON ALL VIEWS TO ReadOnlyReports;
```

### Sensitive Data

- Bank account details encrypted at rest (Azure SQL TDE)
- Author payment information requires restricted access
- VAT returns contain sensitive financial data

---

## Version History

### v1.0 (Current) - 2025-01-03
- Complete refactored deployment
- All 24 tables, 14 views, 12 procedures
- Full UK tax compliance
- Automated bank reconciliation
- Publishing-specific functionality
- Comprehensive test data

---

## Support & Documentation

### Further Reading

- [Azure SQL Documentation](https://docs.microsoft.com/azure/sql-database/)
- [Double-Entry Bookkeeping](https://en.wikipedia.org/wiki/Double-entry_bookkeeping)
- [UK VAT Returns](https://www.gov.uk/vat-returns)
- [Making Tax Digital](https://www.gov.uk/government/publications/making-tax-digital)

### Contact

For questions or issues with these scripts:
- Create an issue in the repository
- Contact: chris@rhubarbpress.com

---

## License

Proprietary - Rhubarb Press Ltd
All rights reserved.

---

**Last Updated:** 2025-01-03
**Deployment Version:** 1.0
**Database Target:** Azure SQL Database (rhubarbpressdb)
