# Rhubarb Press Accounting System - Development Folder Documentation

## Overview

The Development folder contains production-ready SQL scripts for deploying the complete Rhubarb Press accounting system. This is a comprehensive double-entry bookkeeping system specifically designed for a publishing company, with specialized features for author management, book tracking, royalty calculations, and UK tax compliance.

## Database Architecture

**Target Database**: Azure SQL Database (rhubarbpressdb)
**Database System**: SQL Server 2016+ / Azure SQL Database
**Deployment Method**: Sequential execution of numbered SQL scripts

## File Structure and Deployment Order

### File Listing
```
00-DEPLOYMENT-GUIDE.md     - Complete deployment instructions and system overview
01-Core-Schema.sql         - Core accounting tables and double-entry foundation
02-Publishing-Schema.sql   - Publishing-specific tables (authors, books, royalties)
03-UK-Compliance.sql       - UK tax compliance (VAT, Corporation Tax, MTD)
04-Initial-Data-Setup.sql  - Chart of accounts, VAT rates, and sample data
05-Bank-Balance-System.sql - Bank balance tracking with audit history
06-Transaction-Groups-System.sql - Transaction categorization system
07-Enhanced-Views.sql      - Comprehensive reporting views
```

### Critical Deployment Notes
- **Execute files in numerical order (00-07)**
- Each script is idempotent (can be run multiple times safely)
- All scripts include proper error handling and rollback mechanisms
- Dependencies are clearly documented in the deployment guide

## Core System Components

### 1. Core Accounting Foundation (01-Core-Schema.sql)
**Primary Tables:**
- `ChartOfAccounts` - Complete chart of accounts with publishing categories
- `Transactions` - Transaction headers with double-entry support
- `TransactionLines` - Individual debit/credit entries
- `Contacts` - Customer and supplier management
- `Invoices` & `InvoiceLines` - Invoice management
- `AuditLog` - Complete audit trail

**Key Features:**
- Full double-entry bookkeeping compliance
- Publishing-specific account categorization
- VAT integration for UK compliance
- Comprehensive audit logging

### 2. Publishing Business Logic (02-Publishing-Schema.sql)
**Specialized Tables:**
- `Authors` - Author contract and payment details
- `Books` - Book catalog with pricing and metadata
- `BookCategories` - Genre classification system
- `SalesChannels` - Sales platform management
- `BookSales` - Sales transaction tracking
- `RoyaltyCalculations` - Automated royalty calculations
- `ProductionCosts` - Book production cost tracking

**Business Rules:**
- Automatic royalty calculations (default 40% rate)
- Minimum payment thresholds (£25 default)
- Multi-channel sales tracking
- Production cost allocation

### 3. UK Tax Compliance (03-UK-Compliance.sql)
**Compliance Tables:**
- `VATRates` - UK VAT rate management with date ranges
- `VATReturns` - Making Tax Digital (MTD) submissions
- `CorporationTaxCalculations` - Corporation tax planning
- `CapitalAllowances` - Asset depreciation tracking
- `ComplianceDocuments` - Document management for HMRC

**Regulatory Features:**
- Zero-rate VAT for books (UK publishing exemption)
- Automated VAT return calculations
- Corporation tax provision calculations
- Digital record keeping for MTD compliance

### 4. Operational Data (04-Initial-Data-Setup.sql)
**Initial Configuration:**
- Complete UK VAT rate setup (Standard 20%, Reduced 5%, Zero 0%, Exempt)
- Full chart of accounts for publishing operations
- Sample authors, books, and sales channels
- Default transaction groups and categories

### 5. Banking Integration (05-Bank-Balance-System.sql)
**Banking Features:**
- Real-time bank balance tracking
- Historical balance audit trail
- Automated balance updates via triggers
- Bank reconciliation support

**Key Procedures:**
- `sp_InitializeBankBalance` - Set opening balances
- `sp_ImportBankTransaction_v2` - Import with transaction groups
- Automated balance calculation and validation

### 6. Transaction Organization (06-Transaction-Groups-System.sql)
**Transaction Categories:**
- **Admin** - Administrative expenses and business operations
- **Marketing** - Marketing, advertising, promotional activities
- **Publishing** - Publishing-specific tools, software, services
- **Research** - Research and development activities
- **Revenue** - Income and revenue transactions
- **General** - Uncategorized transactions

**Enhanced Features:**
- Bank reconciliation status tracking
- Improved import procedures
- Category-based reporting and analysis

### 7. Business Intelligence (07-Enhanced-Views.sql)
**Financial Reporting Views:**
- `vw_BankRunningBalance` - Real-time bank balance with running totals
- `vw_TransactionSummaryByGroup` - Category-based financial summaries
- `vw_MonthlySummary` - Monthly financial performance
- `vw_BankReconciliation` - Bank reconciliation workspace
- `TrialBalance` - Standard trial balance report
- `ProfitAndLoss` - P&L statement
- `BalanceSheet` - Balance sheet report

**Publishing-Specific Analytics:**
- `vw_BookProfitability` - Individual book performance analysis
- `vw_AuthorPerformance` - Author revenue and royalty metrics
- `vw_TransactionDetails` - Detailed transaction analysis

## Technical Specifications

### Database Features Used
- **Identity Columns** - Auto-incrementing primary keys
- **Check Constraints** - Data validation
- **Foreign Key Relationships** - Referential integrity
- **Triggers** - Automated balance updates
- **Views** - Complex reporting logic
- **Stored Procedures** - Business logic encapsulation
- **Window Functions** - Advanced analytics

### Error Handling
- Comprehensive transaction rollback on failures
- IF NOT EXISTS checks for idempotent execution
- Detailed error logging and user feedback
- Proper GO statement placement for batch execution

### Security Considerations
- No hardcoded credentials or sensitive data
- Parameterized stored procedures to prevent SQL injection
- Audit logging for compliance requirements
- Role-based access through standard SQL Server security

## Business Process Integration

### Daily Operations
1. **Transaction Import** - Bank transactions imported via `sp_ImportBankTransaction_v2`
2. **Invoice Processing** - Sales invoices create automatic accounting entries
3. **Royalty Calculations** - Automated based on sales data and author contracts
4. **Balance Reconciliation** - Real-time bank balance tracking and validation

### Monthly Procedures
1. **VAT Return Preparation** - Using `sp_CalculateVATReturn` procedure
2. **Financial Reporting** - Standard reports via enhanced views
3. **Author Payments** - Royalty calculations and payment processing
4. **Management Reporting** - Performance analytics and trend analysis

### Quarterly/Annual Tasks
1. **Corporation Tax Planning** - Using tax calculation tables
2. **Annual Accounts Preparation** - Full trial balance and statutory reports
3. **Author Contract Reviews** - Performance analysis and contract renewals
4. **System Maintenance** - Data archival and performance optimization

## Migration and Deployment Strategy

### Fresh Installation
1. Create new Azure SQL Database
2. Execute scripts 01-07 in sequence
3. Initialize bank balances using `sp_InitializeBankBalance`
4. Import historical data if required
5. Test all procedures and views

### Production Considerations
- **Backup Strategy** - Full backups before any script execution
- **Testing Protocol** - Complete testing in development environment
- **Rollback Plan** - Transaction-based rollback capabilities
- **Performance Monitoring** - Query performance and index usage analysis

## Support and Maintenance

### Documentation Updates
This documentation should be updated when:
- New scripts are added to the Development folder
- Database schema changes are implemented
- Business requirements change
- Compliance requirements are updated

### Performance Optimization
Regular monitoring of:
- Query execution plans
- Index usage statistics
- Transaction log growth
- Bank balance calculation performance

### Compliance Monitoring
Ongoing attention to:
- UK VAT rate changes
- Making Tax Digital (MTD) requirements
- Corporation tax regulation updates
- Publishing industry compliance changes

---

**Generated**: $(Get-Date)
**Version**: 1.0
**Last Updated**: September 2024
**Status**: Production Documentation ✅