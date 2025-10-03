# RhubarbPress Database Direct Deployment via sqlcmd

## Timestamp
**Date/Time**: Friday, October 3, 2025 - 3:13 PM BST

## Overview
This document describes the successful direct deployment of the RhubarbPress database to Azure SQL Database using sqlcmd command-line tool, bypassing the limitations of the MSSQL MCP server.

## Problem Identified

### MCP Server Limitations
The MSSQL MCP server (configured for Claude Code) has limited DDL capabilities:

**Available MCP Tools:**
- `mcp__mssql__insert_data` - INSERT operations
- `mcp__mssql__read_data` - SELECT queries only
- `mcp__mssql__describe_table` - Get table schema
- `mcp__mssql__update_data` - UPDATE operations
- `mcp__mssql__create_table` - CREATE TABLE
- `mcp__mssql__create_index` - CREATE INDEX
- `mcp__mssql__drop_table` - DROP TABLE
- `mcp__mssql__list_table` - List tables

**MCP Limitations:**
- ❌ Cannot create stored procedures
- ❌ Cannot create views
- ❌ Cannot create triggers
- ❌ Cannot execute multi-statement batches with `GO`
- ❌ Cannot run `PRINT` statements
- ❌ Cannot execute `.sql` script files

### MCP Commands Used Successfully
Despite limitations, MCP was used for database inspection:

```sql
-- List all tables in database
SELECT * FROM sys.tables

-- Check foreign key relationships
SELECT
    OBJECT_NAME(fk.parent_object_id) AS child_table,
    OBJECT_NAME(fk.referenced_object_id) AS parent_table,
    fk.name AS constraint_name
FROM sys.foreign_keys AS fk
ORDER BY parent_table, child_table

-- Verify mcp_user permissions
SELECT
    pr.name AS principal_name,
    pe.state_desc AS permission_state,
    pe.permission_name,
    OBJECT_SCHEMA_NAME(pe.major_id) AS schema_name,
    OBJECT_NAME(pe.major_id) AS object_name
FROM sys.database_principals pr
JOIN sys.database_permissions pe ON pe.grantee_principal_id = pr.principal_id
WHERE pr.name = 'mcp_user'

-- Check database roles
SELECT r.name AS role_name, r.principal_id
FROM sys.database_principals r
WHERE r.principal_id IN (16387, 16390, 16391)
```

## Solution: Installing sqlcmd

### Installation Process

1. **Check if sqlcmd is installed:**
```bash
which sqlcmd
# Result: command not found
```

2. **Search for sqlcmd in Chocolatey:**
```bash
choco search sqlcmd
```

**Available packages:**
- SQL2008.CmdLine 10.0.2531
- SQL2008R2.CmdLine 10.50.1600.1
- **sqlcmd 1.6.0** [Approved] ✅
- sqlserver-cmdlineutils 15.0.4298.100 [Approved]

3. **Install sqlcmd via Chocolatey:**
```bash
choco install sqlcmd -y
```

**Installation details:**
- Version: 1.6.0
- Size: 6.38 MB
- Source: https://github.com/microsoft/go-sqlcmd/releases
- Install location: C:\Program Files\sqlcmd\

4. **Verify installation:**
```bash
"/c/Program Files/sqlcmd/sqlcmd.exe" -?
```

## Database Deployment Process

### Connection Parameters
```bash
sqlcmd \
  -S rhubarbpress-sqlsrv.database.windows.net \
  -d rhubarbpressdb \
  -U mcp_user \
  -P "Sc0tsCup2!May!994!" \
  -N \
  -C
```

**Parameter explanation:**
- `-S` : Server name (Azure SQL Server)
- `-d` : Database name
- `-U` : Username (SQL authentication)
- `-P` : Password
- `-N` : Encrypt connection
- `-C` : Trust server certificate
- `-i` : Input file (SQL script)
- `-Q` : Execute query and exit

### Scripts Executed in Order

#### 1. Master Deployment Script (Drop All Objects)
```bash
sqlcmd -S <server> -d <database> -U mcp_user -P <password> \
  -i "00-MASTER-DEPLOYMENT.sql" -N -C
```

**Issue encountered:**
- TransactionGroup table couldn't be dropped due to foreign key constraint
- TransactionLines references TransactionGroup

**Fix applied:**
Changed drop order from:
```sql
DROP TABLE TransactionGroup;
DROP TABLE TransactionLines;
```
To:
```sql
DROP TABLE TransactionLines;
DROP TABLE TransactionGroup;
```

**Objects dropped:**
- 14 Views
- 13 Stored Procedures
- 2 Triggers
- 24 Tables

#### 2. Core Schema (Tables and Indexes)
```bash
sqlcmd -S <server> -d <database> -U mcp_user -P <password> \
  -i "01-Core-Schema.sql" -N -C
```

**Tables created:**
- ChartOfAccounts (with self-referencing foreign key)
- Transactions
- TransactionLines
- Contacts
- Invoices
- InvoiceLines
- AuditLog

**Commands executed within script:**
- `CREATE TABLE` statements
- `CREATE INDEX` statements
- `ALTER TABLE` for foreign keys

#### 3. Publishing Schema
```bash
sqlcmd -S <server> -d <database> -U mcp_user -P <password> \
  -i "02-Publishing-Schema.sql" -N -C
```

**Tables created:**
- Authors
- BookCategories
- Books
- SalesChannels
- BookSales
- RoyaltyCalculations
- RoyaltyCalculationDetails
- ProductionCosts

**Views created:**
- vw_BookProfitability
- vw_AuthorPerformance

#### 4. UK Compliance
```bash
sqlcmd -S <server> -d <database> -U mcp_user -P <password> \
  -i "03-UK-Compliance.sql" -N -C
```

**Tables created:**
- VATRates
- VATReturns
- CorporationTaxCalculations
- CapitalAllowances
- VATTransactionMapping
- ComplianceDocuments

**Stored procedures created:**
- sp_CalculateVATReturn

**Triggers created:**
- TR_Transactions_Audit

#### 5. Initial Data Setup
```bash
sqlcmd -S <server> -d <database> -U mcp_user -P <password> \
  -i "04-Initial-Data-Setup.sql" -N -C
```

**Data inserted:**
- VAT rates (4 rows)
- Chart of Accounts (56 rows)
- Book categories (7 rows)
- Sales channels (10 rows)
- Sample contacts (2 rows)
- Sample author (1 row)
- Sample book (1 row)

**Commands used:**
- `INSERT INTO` statements

**Views created:**
- TrialBalance
- ProfitAndLoss
- BalanceSheet

#### 6. Bank Balance System
```bash
sqlcmd -S <server> -d <database> -U mcp_user -P <password> \
  -i "05-Bank-Balance-System.sql" -N -C
```

**Tables created:**
- BankBalance
- BankBalanceHistory

**Stored procedures created:**
- sp_InitializeBankBalance
- sp_UpdateBankBalance

**Triggers created:**
- tr_TransactionLines_UpdateBankBalance

#### 7. Transaction Groups System
```bash
sqlcmd -S <server> -d <database> -U mcp_user -P <password> \
  -i "06-Transaction-Groups-System.sql" -N -C
```

**Schema modifications:**
- Added BankDate column to Transactions
- Added ReconciliationStatus column to Transactions
- Added TransactionGroupID column to Transactions

**Table created:**
- TransactionGroup (9 rows of categories)

**Stored procedures created:**
- sp_ImportBankTransaction
- sp_GetTransactionGroupID

#### 8. Enhanced Views
```bash
sqlcmd -S <server> -d <database> -U mcp_user -P <password> \
  -i "07-Enhanced-Views.sql" -N -C
```

**Views created:**
- vw_AccountBalances
- vw_TrialBalance
- vw_BankBalanceAuditTrail
- vw_BankRunningBalance
- vw_MonthlySummary
- vw_BankReconciliation
- vw_TransactionSummaryByGroup
- vw_TransactionDetails
- vw_CurrentBankBalances
- vw_TransactionGroupAnalysis
- vw_CashFlowSummary

#### 9. Publishing Business Procedures
```bash
sqlcmd -S <server> -d <database> -U mcp_user -P <password> \
  -i "08-Publishing-Business-Procedures.sql" -N -C
```

**Stored procedures created:**
- sp_CreateJournalEntry
- sp_CreateInvoice
- sp_ProcessBookSales
- sp_CalculateAuthorRoyalties
- sp_BookProfitabilityReport
- sp_GenerateTrialBalance
- sp_DashboardSummary
- sp_SetupBankImportAccounts
- sp_BulkImportBankTransactions

#### 10. Test Transaction Data (Initial Attempt - Failed)
```bash
sqlcmd -S <server> -d <database> -U mcp_user -P <password> \
  -i "09-Test-Transaction-Data.sql" -N -C
```

**Error encountered:**
```
Msg 229, Level 14, State 5
The EXECUTE permission was denied on the object 'sp_InitializeBankBalance'
The EXECUTE permission was denied on the object 'sp_ImportBankTransaction'
```

## Permission Elevation for mcp_user

### Initial Permissions
The `mcp_user` account had the following roles:
- **db_ddladmin** - Can CREATE, ALTER, DROP objects
- **db_datareader** - Can SELECT from all tables
- **db_datawriter** - Can INSERT, UPDATE, DELETE data
- **CONNECT** - Can connect to database

### Missing Permission
Despite having `db_ddladmin` (which allows creating procedures), the account did NOT have EXECUTE permissions on the procedures it created.

### Permission Grant Attempts (Failed)

**Attempt 1: Grant individual procedure permissions**
```sql
GRANT EXECUTE ON sp_InitializeBankBalance TO mcp_user;
GRANT EXECUTE ON sp_UpdateBankBalance TO mcp_user;
-- ... etc for all procedures
```
**Result:** ❌ Failed - "Cannot grant permissions to yourself"

**Attempt 2: Grant schema-level EXECUTE**
```sql
GRANT EXECUTE ON SCHEMA::dbo TO mcp_user;
```
**Result:** ❌ Failed - "Cannot grant permissions to yourself"

### Solution: Admin Account Required

The `mcp_user` account **cannot grant permissions to itself**. The permission grant must be executed by an **Azure SQL admin account**.

**Command executed by admin account:**
```sql
GRANT EXECUTE ON SCHEMA::dbo TO mcp_user;
```

This grants EXECUTE permission on all objects in the `dbo` schema to `mcp_user`.

### Post-Permission Test Data Creation

After permissions were granted, the test data script was re-run successfully:

```bash
sqlcmd -S <server> -d <database> -U mcp_user -P <password> \
  -i "09-Test-Transaction-Data.sql" -N -C
```

**Results:**
- ✅ 48 test transactions created
- ✅ Opening balance: £10,000.00
- ✅ Final balance: £8,920.38
- ✅ Total expenses: £13,414.62
- ✅ Total revenue: £12,335.00
- ✅ Net: -£1,079.62

## SQL Command Types Used

### SELECT (Read Operations)
```sql
-- List tables
SELECT * FROM sys.tables;

-- Query data
SELECT * FROM vw_BankRunningBalance ORDER BY ActualDate;

-- Check permissions
SELECT * FROM sys.database_permissions WHERE grantee_principal_id = USER_ID('mcp_user');
```

### CREATE (Create Objects)
```sql
-- Create table
CREATE TABLE Transactions (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    TransactionDate DATE NOT NULL,
    -- ... more columns
);

-- Create index
CREATE INDEX IX_Transactions_Date ON Transactions(TransactionDate);

-- Create view
CREATE VIEW vw_BankRunningBalance AS
SELECT ...;

-- Create stored procedure
CREATE PROCEDURE sp_ImportBankTransaction
    @TransactionDate DATE,
    @Description NVARCHAR(500),
    -- ... parameters
AS
BEGIN
    -- ... procedure body
END;

-- Create trigger
CREATE TRIGGER tr_TransactionLines_UpdateBankBalance
    ON TransactionLines
    AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- ... trigger body
END;
```

### DROP (Delete Objects)
```sql
-- Drop view
IF OBJECT_ID('vw_CashFlowSummary', 'V') IS NOT NULL
    DROP VIEW vw_CashFlowSummary;

-- Drop procedure
IF OBJECT_ID('sp_ImportBankTransaction', 'P') IS NOT NULL
    DROP PROCEDURE sp_ImportBankTransaction;

-- Drop trigger
IF OBJECT_ID('tr_TransactionLines_UpdateBankBalance', 'TR') IS NOT NULL
    DROP TRIGGER tr_TransactionLines_UpdateBankBalance;

-- Drop table
IF OBJECT_ID('TransactionLines', 'U') IS NOT NULL
    DROP TABLE TransactionLines;
```

### INSERT (Insert Data)
```sql
-- Insert VAT rates
INSERT INTO VATRates (RateName, Rate, EffectiveFrom)
VALUES
    ('Standard', 0.20, '2011-01-04'),
    ('Reduced', 0.05, '1997-09-01'),
    ('Zero', 0.00, '1973-01-01'),
    ('Exempt', 0.00, '1973-01-01');

-- Insert via stored procedure
EXEC sp_ImportBankTransaction
    @TransactionDate = '2025-09-02',
    @Description = 'Adobe Creative Cloud',
    @Amount = -79.99,
    @AccountCode = '5200',
    @TransactionGroup = 'Publishing';
```

### UPDATE (Modify Data)
```sql
-- Update table data
UPDATE Transactions
SET ReconciliationStatus = 'Reconciled'
WHERE TransactionID = 1;

-- Update via stored procedure
EXEC sp_UpdateBankBalance
    @AccountCode = '1001',
    @Amount = 100.00,
    @TransactionID = 1;
```

### DELETE (Remove Data)
```sql
-- Delete from table
DELETE FROM TransactionLines
WHERE TransactionID = 1;
```

### ALTER (Modify Structure)
```sql
-- Add column
ALTER TABLE Transactions
ADD BankDate DATE NULL;

-- Add foreign key
ALTER TABLE TransactionLines
ADD CONSTRAINT FK_TransactionLines_TransactionGroup
    FOREIGN KEY (TransactionGroupID)
    REFERENCES TransactionGroup(TransactionGroupID);
```

### GRANT (Permissions)
```sql
-- Grant schema-level execute (requires admin)
GRANT EXECUTE ON SCHEMA::dbo TO mcp_user;

-- Grant table permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ChartOfAccounts TO mcp_user;
```

## Final Database State

### Tables: 24
- Core accounting: ChartOfAccounts, Transactions, TransactionLines, Contacts, Invoices, InvoiceLines, AuditLog
- Publishing: Authors, BookCategories, Books, SalesChannels, BookSales, RoyaltyCalculations, RoyaltyCalculationDetails, ProductionCosts
- UK Compliance: VATRates, VATReturns, CorporationTaxCalculations, CapitalAllowances, VATTransactionMapping, ComplianceDocuments
- Bank tracking: BankBalance, BankBalanceHistory, TransactionGroup

### Views: 11
- vw_AccountBalances, vw_TrialBalance, vw_BankBalanceAuditTrail
- vw_BankRunningBalance, vw_CurrentBankBalances, vw_BankReconciliation
- vw_MonthlySummary, vw_TransactionSummaryByGroup, vw_TransactionDetails
- vw_TransactionGroupAnalysis, vw_CashFlowSummary
- Plus: TrialBalance, ProfitAndLoss, BalanceSheet, vw_BookProfitability, vw_AuthorPerformance

### Stored Procedures: 14
- sp_InitializeBankBalance, sp_UpdateBankBalance
- sp_CalculateVATReturn
- sp_ImportBankTransaction, sp_GetTransactionGroupID
- sp_CreateJournalEntry, sp_CreateInvoice
- sp_ProcessBookSales, sp_CalculateAuthorRoyalties
- sp_BookProfitabilityReport, sp_GenerateTrialBalance
- sp_DashboardSummary, sp_SetupBankImportAccounts
- sp_BulkImportBankTransactions

### Triggers: 2
- TR_Transactions_Audit
- tr_TransactionLines_UpdateBankBalance

### Data Loaded
- 4 VAT rates
- 56 Chart of Accounts entries
- 7 Book categories
- 10 Sales channels
- 9 Transaction groups
- 2 Sample contacts
- 1 Sample author
- 1 Sample book
- 48 Test transactions

## Key Learnings

1. **MSSQL MCP Limitations**: The MCP server is great for CRUD operations but cannot handle complex DDL operations like stored procedures, views, and triggers.

2. **sqlcmd is Essential**: For full database deployment with procedures, views, and triggers, sqlcmd (or similar tool) is required.

3. **Permission Management**: Users cannot grant permissions to themselves. Admin intervention is required for permission elevation.

4. **Drop Order Matters**: Foreign key constraints must be considered when dropping tables. Child tables must be dropped before parent tables.

5. **GO Statements**: SQL Server batch separator `GO` is not standard SQL and is only understood by SSMS, Azure Data Studio, and sqlcmd.

## Recommendations

### For Future Deployments
1. Use sqlcmd for initial database setup and major schema changes
2. Use MCP for day-to-day CRUD operations and data inspection
3. Always test scripts in a development environment first
4. Document all permission requirements upfront
5. Keep deployment scripts in version control

### Tools for Different Scenarios

**Use MSSQL MCP when:**
- Reading data (SELECT)
- Inserting/updating data
- Creating/dropping tables
- Creating indexes
- Inspecting database schema

**Use sqlcmd when:**
- Creating stored procedures
- Creating views
- Creating triggers
- Executing multi-statement batches
- Running existing .sql scripts
- Initial database deployments

## Related Documentation
- Connection details: `Installation VM\rhubarbpressdb connection vm.md`
- MCP connection: `Installation VM\rhubarbpressdb mcp connection.md`
- Deployment scripts: `RhubarbPress DB Refactor\*.sql`
