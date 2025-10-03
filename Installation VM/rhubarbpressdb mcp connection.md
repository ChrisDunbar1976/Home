# MSSQL MCP Connection Settings

## Azure SQL Database Connection

### Server Configuration
- **Server Name**: `rhubarbpress-sqlsrv.database.windows.net`
- **Database Name**: `rhubarbpressdb`
- **Username**: `mcp_user`
- **Password**: `Sc0tsCup2!May!994!`
- **Read-Only Mode**: `false` (write operations allowed)

### MCP Server Configuration
- **Type**: stdio
- **Command**: `node`
- **Script Path**: `C:\Users\cdunbar\Documents\Projects\SQL-AI-samples\MssqlMcp\Node\dist\index.js`

### Configuration Location
Settings stored in: `C:\Users\cdunbar\.claude.json`

### Configuration Block
```json
"mssql": {
  "type": "stdio",
  "command": "node",
  "args": [
    "C:\\Users\\cdunbar\\Documents\\Projects\\SQL-AI-samples\\MssqlMcp\\Node\\dist\\index.js"
  ],
  "env": {
    "SERVER_NAME": "rhubarbpress-sqlsrv.database.windows.net",
    "DATABASE_NAME": "rhubarbpressdb",
    "USER_NAME": "mcp_user",
    "PASSWORD": "Sc0tsCup2!May!994!",
    "READONLY": "false"
  }
}
```

### Connection Status
✅ **Active** - Successfully connected and verified on 2025-10-03

### Database Tables (24 tables)
- dbo.AuditLog
- dbo.Authors
- dbo.BankBalance
- dbo.BankBalanceHistory
- dbo.BookCategories
- dbo.Books
- dbo.BookSales
- dbo.CapitalAllowances
- dbo.ChartOfAccounts
- dbo.ComplianceDocuments
- dbo.Contacts
- dbo.CorporationTaxCalculations
- dbo.InvoiceLines
- dbo.Invoices
- dbo.ProductionCosts
- dbo.RoyaltyCalculationDetails
- dbo.RoyaltyCalculations
- dbo.SalesChannels
- dbo.TransactionGroup
- dbo.TransactionLines
- dbo.Transactions
- dbo.VATRates
- dbo.VATReturns
- dbo.VATTransactionMapping

### Security Notes
- Password stored in plain text in `.claude.json`
- Ensure `.claude.json` has appropriate file permissions
- Do not commit `.claude.json` to version control
- READONLY mode set to `false` (allows INSERT, UPDATE, DELETE operations)

### Azure Firewall
- Ensure Azure SQL Server firewall rules allow connections from this VM's IP address
