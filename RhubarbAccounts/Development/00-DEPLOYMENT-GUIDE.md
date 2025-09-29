# Rhubarb Press Accounting System - Deployment Guide

## Overview
This folder contains clean, deployment-ready SQL scripts for the Rhubarb Press accounting system. All scripts have been consolidated from the organic development process and are now error-free with proper GO statement placement.

## Deployment Order

**IMPORTANT: Execute these scripts in the exact order shown below**

### 1. Core Database Schema
```sql
-- Execute: 01-Core-Schema.sql
-- Creates: ChartOfAccounts, Transactions, TransactionLines, Contacts, Invoices, InvoiceLines, AuditLog
-- Dependencies: None (requires existing database)
```

### 2. Publishing-Specific Schema
```sql
-- Execute: 02-Publishing-Schema.sql
-- Creates: Authors, BookCategories, Books, SalesChannels, BookSales, RoyaltyCalculations, ProductionCosts
-- Dependencies: 01-Core-Schema.sql
```

### 3. UK Compliance Schema
```sql
-- Execute: 03-UK-Compliance.sql
-- Creates: VATRates, VATReturns, CorporationTaxCalculations, CapitalAllowances, VATTransactionMapping, ComplianceDocuments
-- Dependencies: 01-Core-Schema.sql
```

### 4. Initial Data Setup
```sql
-- Execute: 04-Initial-Data-Setup.sql
-- Creates: VAT rates, Chart of Accounts data, sample contacts, authors, books, sales channels
-- Dependencies: 01, 02, 03
```

### 5. Bank Balance System
```sql
-- Execute: 05-Bank-Balance-System.sql
-- Creates: BankBalance, BankBalanceHistory tables, procedures, triggers
-- Dependencies: 01-Core-Schema.sql
```

### 6. Transaction Groups System
```sql
-- Execute: 06-Transaction-Groups-System.sql
-- Creates: TransactionGroup table, enhanced import procedures, adds columns to Transactions
-- Dependencies: 01-Core-Schema.sql, 05-Bank-Balance-System.sql
```

### 7. Enhanced Views and Reporting
```sql
-- Execute: 07-Enhanced-Views.sql
-- Creates: All reporting views with transaction group support
-- Dependencies: All previous scripts
```

## Post-Deployment Steps

### 1. Initialize Bank Balance
```sql
-- Set opening balance for main bank account
EXEC sp_InitializeBankBalance '1001', 10000.00, '2024-01-01';
```

### 2. Verify Installation
```sql
-- Check all tables exist
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME;

-- Check views
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS ORDER BY TABLE_NAME;

-- Check procedures
SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' ORDER BY ROUTINE_NAME;

-- Verify transaction groups
SELECT * FROM TransactionGroup ORDER BY TransactionGroupID;

-- Check bank balance
SELECT * FROM vw_CurrentBankBalances;
```

### 3. Test Transaction Import
```sql
-- Test importing a transaction
EXEC sp_ImportBankTransaction_v2
    @ActualDate = '2024-01-02',
    @Description = 'Test Transaction',
    @TransactionGroupID = 1,
    @AmountOut = 50.00,
    @CreatedBy = 'Test User';

-- Verify import worked
SELECT * FROM vw_BankRunningBalance ORDER BY ActualDate DESC;
```

## Key Features

### Transaction Groups
- **Admin**: Administrative expenses and general business operations
- **Marketing**: Marketing, advertising, and promotional activities
- **Publishing**: Publishing-specific tools, software, and services
- **Research**: Research and development activities
- **Revenue**: Income and revenue transactions
- **General**: General or uncategorized transactions

### Available Procedures
- `sp_InitializeBankBalance`: Initialize bank account balance
- `sp_ImportBankTransaction_v2`: Import bank transactions with groups
- `sp_ImportBankTransaction_Legacy`: Backward compatible import
- `sp_GetTransactionGroupID`: Helper for category lookup
- `sp_CalculateVATReturn`: Calculate VAT returns for compliance

### Key Views
- `vw_BankRunningBalance`: Bank transactions with running balance
- `vw_TransactionSummaryByGroup`: Summary by transaction group
- `vw_MonthlySummary`: Monthly financial summary
- `vw_BankReconciliation`: Bank reconciliation view
- `vw_TransactionDetails`: Detailed transaction analysis
- `vw_BookProfitability`: Book profitability analysis
- `vw_AuthorPerformance`: Author performance metrics
- `TrialBalance`: Trial balance report
- `ProfitAndLoss`: P&L statement
- `BalanceSheet`: Balance sheet report

## Error Handling

All scripts include:
- ✅ Proper GO statement placement
- ✅ IF NOT EXISTS checks for idempotent execution
- ✅ Error handling in procedures
- ✅ Transaction rollback on failures
- ✅ Comprehensive logging and feedback

## Database Requirements

- **Target**: Azure SQL Database
- **Database Name**: rhubarbpressdb
- **Minimum Version**: SQL Server 2016+ / Azure SQL Database
- **Features Used**:
  - IDENTITY columns
  - CHECK constraints
  - Foreign keys
  - Triggers
  - Views
  - Stored procedures
  - Window functions

## Migration from Refinement Scripts

If you have data from the organic development process in the Refinement folder:
1. **DO NOT** run these scripts on an existing database with Refinement data
2. Either start fresh OR carefully migrate data using INSERT INTO...SELECT statements
3. Test thoroughly in a development environment first

## Support

For issues or questions about deployment:
1. Check error messages in SQL Server Management Studio
2. Ensure all dependencies are met
3. Verify database permissions
4. Review the deployment order

---

**Generated**: $(Get-Date)
**Version**: Production Ready
**Status**: Deployment Ready ✅