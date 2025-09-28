# SpendTracker Setup Guide

Complete step-by-step instructions for setting up your Google Sheets to Azure SQL sync solution.

## 🎯 Overview

This guide will help you set up a complete data pipeline that:
1. **Monitors** your Google Sheet for changes in real-time
2. **Syncs** data immediately to Azure SQL Database
3. **Provides backup** scheduled sync every 15 minutes
4. **Offers monitoring** and status checking capabilities

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] **Azure subscription** with ability to create resources
- [ ] **Google account** with access to Google Cloud Console
- [ ] **Google Sheet** with your expenditure data
- [ ] **Azure CLI** installed on your machine
- [ ] **PowerShell** (Windows) or **Bash** (Linux/Mac)
- [ ] **Git** (optional, for version control)

## 🏗️ Part 1: Azure Setup

### Step 1.1: Login to Azure
```bash
az login
az account list
az account set --subscription "your-subscription-id"
```

### Step 1.2: Create Azure Resources

```powershell
# Use the deployment script to create all resources
.\deployment\deploy.ps1 `
    -SubscriptionId "your-subscription-id" `
    -ResourceGroupName "SpendTracker-RG" `
    -FunctionAppName "spendtracker-func-app" `
    -StorageAccountName "spendtrackerstorage123" `
    -AzureSqlServerName "spendtracker-sql-server" `
    -AzureSqlDatabaseName "SpendTrackerDB" `
    -GoogleSheetId "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms" `
    -SyncSecretKey "your-secure-secret-key-here" `
    -CreateResources
```

**Note the Function URLs from the output - you'll need them later!**

### Step 1.3: Create Azure SQL Database

1. **Via Azure Portal:**
   - Navigate to SQL databases → Create
   - Choose your resource group
   - Server: Create new or use existing
   - Database name: `SpendTrackerDB`
   - Pricing: Basic or Standard (for development)

2. **Configure Firewall:**
   - Add your client IP address
   - Enable "Allow Azure services and resources to access this server"

3. **Create Database User:**
   ```sql
   -- Run this in Azure SQL Query Editor
   CREATE LOGIN spendtracker_user WITH PASSWORD = 'YourSecurePassword123!';
   CREATE USER spendtracker_user FOR LOGIN spendtracker_user;
   GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO spendtracker_user;
   ```

4. **Run Setup Script:**
   Execute `deployment/azure-sql-setup.sql` to create tables and views.

### Step 1.4: Update Connection String

Update your Azure Function App settings with the correct SQL connection string:

```bash
az functionapp config appsettings set \
    --name "spendtracker-func-app" \
    --resource-group "SpendTracker-RG" \
    --settings "AZURE_SQL_CONNECTION_STRING=Driver={ODBC Driver 18 for SQL Server};Server=tcp:spendtracker-sql-server.database.windows.net,1433;Database=SpendTrackerDB;Uid=spendtracker_user;Pwd=YourSecurePassword123!;Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
```

## 🔑 Part 2: Google Cloud Setup

### Step 2.1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Note your project ID

### Step 2.2: Enable APIs

1. Navigate to **APIs & Services** → **Library**
2. Search for and enable:
   - **Google Sheets API**
   - **Google Drive API** (recommended)

### Step 2.3: Create Service Account

1. Go to **IAM & Admin** → **Service Accounts**
2. Click **Create Service Account**
3. Fill in details:
   - **Name**: `spendtracker-service`
   - **Description**: `Service account for SpendTracker Azure Functions`
4. Click **Create and Continue**
5. Skip role assignment (not needed for Sheets API)
6. Click **Done**

### Step 2.4: Generate Service Account Key

1. Click on your newly created service account
2. Go to **Keys** tab
3. Click **Add Key** → **Create new key**
4. Choose **JSON** format
5. Download the key file and keep it secure

### Step 2.5: Upload Credentials to Azure

#### Option A: Use Key Vault (Recommended)
```bash
# Create Key Vault if not exists
az keyvault create --name "spendtracker-kv" --resource-group "SpendTracker-RG"

# Upload service account JSON
az keyvault secret set \
    --vault-name "spendtracker-kv" \
    --name "google-service-account" \
    --file "path/to/your-service-account-key.json"

# Update Function App to use Key Vault
az functionapp config appsettings set \
    --name "spendtracker-func-app" \
    --resource-group "SpendTracker-RG" \
    --settings "GOOGLE_SHEETS_CREDENTIALS_JSON=@Microsoft.KeyVault(SecretUri=https://spendtracker-kv.vault.azure.net/secrets/google-service-account/)"
```

#### Option B: Direct Upload (Development only)
```bash
# Read JSON file content and set as environment variable
az functionapp config appsettings set \
    --name "spendtracker-func-app" \
    --resource-group "SpendTracker-RG" \
    --settings "GOOGLE_SHEETS_CREDENTIALS_JSON=$(cat path/to/your-service-account-key.json)"
```

## 📊 Part 3: Google Sheets Setup

### Step 3.1: Prepare Your Sheet

Ensure your Google Sheet has these columns (order can vary):

| Column | Description | Example |
|--------|-------------|---------|
| Date | Transaction date | 2024-01-15 |
| Spend Type | Category | Food, Transport, Income |
| Spend Item | Description | Groceries, Bus fare, Salary |
| Ingoing | Income amount | 1000.00 |
| Outgoing | Expense amount | 25.50 |
| Balance | Account balance | 974.50 |

### Step 3.2: Share Sheet with Service Account

1. Open your Google Sheet
2. Click **Share** button
3. Add the service account email (from the JSON key file)
4. Give **Editor** permissions
5. Uncheck "Notify people" and click **Share**

### Step 3.3: Get Sheet ID

From your Google Sheet URL:
```
https://docs.google.com/spreadsheets/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit
```
The Sheet ID is: `1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms`

## 🔗 Part 4: Google Apps Script Setup

### Step 4.1: Open Apps Script

1. In your Google Sheet, go to **Extensions** → **Apps Script**
2. You'll see a new project with `Code.gs` file

### Step 4.2: Add the Script

1. Replace all code in `Code.gs` with the content from `config/google-apps-script.js`
2. Update the configuration constants at the top:

```javascript
const AZURE_FUNCTION_URL = 'https://spendtracker-func-app.azurewebsites.net/api/sync_webhook';
const SECRET_KEY = 'your-secure-secret-key-here';
```

### Step 4.3: Initialize the Script

1. Save the script (Ctrl+S)
2. Click **Run** → select `initializeSpendTracker`
3. Authorize the script when prompted:
   - Click **Review permissions**
   - Choose your Google account
   - Click **Advanced** → **Go to Untitled project (unsafe)**
   - Click **Allow**

### Step 4.4: Test the Connection

1. Run the `testWebhookConnection` function
2. You should see a success message
3. If it fails, check your Azure Function URL and secret key

## 🧪 Part 5: Testing

### Step 5.1: Test Status Endpoint

Visit your status URL in a browser:
```
https://spendtracker-func-app.azurewebsites.net/api/sync_status
```

You should see JSON response with sync information.

### Step 5.2: Test Real-time Sync

1. Add a new row to your Google Sheet
2. Check the Apps Script execution logs:
   - In Apps Script editor → **Executions**
3. Check Azure Function logs:
   - Azure Portal → Function App → Monitor

### Step 5.3: Verify Database

Connect to your Azure SQL Database and check:
```sql
-- Check if data was synced
SELECT TOP 10 * FROM spend_records ORDER BY created_at DESC;

-- Check sync logs
SELECT TOP 10 * FROM sync_log ORDER BY sync_timestamp DESC;
```

## 🔧 Part 6: Fine-tuning

### Adjust Timer Frequency

Edit `src/sync_timer/function.json` to change backup sync frequency:
```json
{
  "schedule": "0 */5 * * * *"  // Every 5 minutes instead of 15
}
```

### Configure Monitoring

Set up Azure Application Insights for detailed monitoring:
1. Enable Application Insights for your Function App
2. Set up alerts for failed syncs
3. Create dashboards for sync metrics

### Optimize Performance

For large sheets (1000+ rows):
1. Consider pagination in Google Sheets API calls
2. Implement incremental sync based on timestamps
3. Add database indexing for frequently queried columns

## 🚨 Troubleshooting

### Issue: "Access denied" for Google Sheets
**Solution:**
- Verify service account email has access to the sheet
- Check if Google Sheets API is enabled
- Ensure JSON credentials are valid

### Issue: Azure SQL connection fails
**Solution:**
- Check connection string format
- Verify firewall rules
- Test connection with SQL Server Management Studio

### Issue: Webhook not triggering
**Solution:**
- Verify Google Apps Script is deployed
- Check secret key matches
- Ensure Azure Function URL is correct and accessible

### Issue: Timer function not running
**Solution:**
- Check if Function App is running
- Verify timer trigger configuration
- Check Application Insights for errors

## 📈 Next Steps

Once everything is working:

1. **Set up monitoring alerts** for failed syncs
2. **Create backup strategies** for your data
3. **Consider adding notifications** (email/SMS) for important events
4. **Implement data validation rules** for your specific needs
5. **Set up automated testing** for the sync process

## 🆘 Getting Help

If you encounter issues:

1. Check the **Azure Function logs** in the portal
2. Review **Google Apps Script execution logs**
3. Query the `sync_log` table for error details
4. Test individual components (Google Sheets API, Azure SQL, etc.)

---

**🎉 Congratulations! Your SpendTracker sync solution is now ready!**

Your Google Sheet changes will now automatically sync to Azure SQL Database in real-time, with a backup sync every 15 minutes to ensure no data is missed.