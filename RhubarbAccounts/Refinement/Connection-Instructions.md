# VS Code SQL Server Connection Instructions

## Connecting to your Azure SQL Database (rhubarbpressdb)

### Step 1: Open SQL Server Extension
1. Press `Ctrl+Shift+P` to open command palette
2. Type "SQL Server: Connect" and select it
3. Or click the SQL Server icon in the Activity Bar

### Step 2: Add Connection
1. Click "Add Connection" or the "+" icon
2. Enter your connection details:

**Connection Profile:**
- **Server name**: `your-server-name.database.windows.net`
- **Database name**: `rhubarbpressdb`
- **Authentication Type**: `SQL Login` or `Azure Active Directory`
- **User name**: Your SQL username
- **Password**: Your SQL password
- **Save Password**: ✅ (optional, for convenience)
- **Profile Name**: `Rhubarb Press DB` (or your preferred name)

### Step 3: Test Connection
1. Click "Connect"
2. You should see your database appear in the SQL Server explorer
3. Expand the database to see tables, views, etc.

## Running the Schema Scripts

### Execute in Order:
1. **01-Core-Accounting-Schema.sql** - Core tables
2. **02-Publishing-Schema.sql** - Publishing-specific tables
3. **03-UK-Compliance-Schema.sql** - VAT and compliance tables
4. **04-Initial-Data-Setup.sql** - Sample data and views

### How to Execute:
1. Open each SQL file in VS Code
2. Right-click in the editor → "Execute Query"
3. Or press `Ctrl+Shift+E`
4. Select your `Rhubarb Press DB` connection
5. Check the Results/Messages tab for success confirmation

## Verification Queries

After running all scripts, test with these queries:

```sql
-- Check table count
SELECT COUNT(*) as TableCount
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

-- Check chart of accounts
SELECT AccountCode, AccountName, AccountType
FROM ChartOfAccounts
ORDER BY AccountCode;

-- Check VAT rates
SELECT VATCode, Rate, Description
FROM VATRates;

-- Test views
SELECT * FROM TrialBalance;
```

## Troubleshooting

### Common Issues:
1. **Firewall**: Ensure your IP is whitelisted in Azure SQL
2. **Authentication**: Check username/password are correct
3. **Database Name**: Verify "rhubarbpressdb" exists and is spelled correctly
4. **Permissions**: Ensure user has CREATE TABLE permissions

### Azure SQL Firewall Setup:
1. Go to Azure Portal → SQL Database → rhubarbpressdb
2. Click "Set server firewall"
3. Add your current IP address
4. Click "Save"

## Next Steps

Once connected and schema is deployed:

1. **Test Data Entry**: Create sample transactions
2. **Verify Views**: Check TrialBalance, ProfitAndLoss reports
3. **Author Setup**: Add real author information
4. **Book Catalog**: Add your published books
5. **Sales Import**: Import sales data from Amazon, etc.

## Security Notes

- Store connection credentials securely
- Use Azure Key Vault for production
- Enable audit logging in Azure SQL
- Regular backup verification
- Consider Always Encrypted for sensitive data

Your Rhubarb Press accounting system is ready for use!