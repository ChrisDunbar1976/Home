# SpendTracker - Google Sheets to Azure SQL Sync

A comprehensive solution that automatically syncs your Google Sheets expenditure data to Azure SQL Database using Azure Functions with both real-time push notifications and scheduled polling.

## 🏗️ Architecture

```
Google Sheet → Apps Script → Azure Function (HTTP) → Azure SQL Database
                              ↓
              Azure Function (Timer) → Check for missed updates
```

## ✨ Features

- **Real-time sync**: Immediate updates when Google Sheet is modified
- **Backup polling**: Timer-triggered sync every 15 minutes as fallback
- **Robust error handling**: Retry logic and comprehensive logging
- **Data validation**: Proper parsing and validation of expense data
- **Status monitoring**: REST API for checking sync status
- **Secure**: Secret key authentication for webhooks

## 📁 Project Structure

```
SpendTracker-AzureFunction/
├── src/
│   ├── shared/                    # Shared utilities
│   │   ├── google_sheets_client.py    # Google Sheets API client
│   │   ├── azure_sql_client.py        # Azure SQL Database client
│   │   └── sync_service.py             # Main sync orchestration
│   ├── sync_webhook/              # HTTP trigger for real-time sync
│   ├── sync_timer/                # Timer trigger for scheduled sync
│   └── sync_status/               # Status and monitoring endpoint
├── config/
│   └── google-apps-script.js      # Google Apps Script for push notifications
├── deployment/
│   ├── deploy.ps1                 # Azure deployment script
│   ├── azure-sql-setup.sql        # Database setup script
│   └── local-development.ps1      # Local development setup
├── requirements.txt               # Python dependencies
├── host.json                      # Azure Functions configuration
└── local.settings.json            # Local development settings
```

## 🚀 Quick Start

### Prerequisites

1. **Azure Account** with subscription
2. **Google Cloud Project** with Sheets API enabled
3. **Google Sheet** with your expenditure data
4. **Azure CLI** installed and logged in
5. **Python 3.9+** for local development

### Step 1: Clone and Configure

```bash
# Clone or download the project
cd SpendTracker-AzureFunction

# Update local.settings.json with your configuration
```

### Step 2: Set Up Google Sheets API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable the Google Sheets API
4. Create a Service Account and download the JSON key
5. Share your Google Sheet with the service account email address

### Step 3: Deploy to Azure

```powershell
# Run the deployment script
.\deployment\deploy.ps1 `
    -SubscriptionId "your-subscription-id" `
    -ResourceGroupName "SpendTracker-RG" `
    -FunctionAppName "spendtracker-functions" `
    -StorageAccountName "spendtrackerstorage" `
    -AzureSqlServerName "spendtracker-sql" `
    -AzureSqlDatabaseName "SpendTrackerDB" `
    -GoogleSheetId "your-google-sheet-id" `
    -SyncSecretKey "your-secure-secret-key" `
    -CreateResources
```

### Step 4: Configure Database

1. Create Azure SQL Database
2. Run the setup script: `deployment/azure-sql-setup.sql`
3. Update the connection string in Azure Function App settings

### Step 5: Set Up Google Apps Script

1. Open your Google Sheet
2. Go to Extensions → Apps Script
3. Replace default code with `config/google-apps-script.js`
4. Update the configuration constants with your Azure Function URLs
5. Run `initializeSpendTracker()` function
6. Authorize the script when prompted

## 🔧 Configuration

### Environment Variables (Azure Function App Settings)

| Variable | Description | Example |
|----------|-------------|---------|
| `GOOGLE_SHEET_ID` | Your Google Sheet ID from the URL | `1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms` |
| `AZURE_SQL_CONNECTION_STRING` | Azure SQL Database connection string | `Driver={ODBC Driver 18 for SQL Server};Server=...` |
| `SYNC_SECRET_KEY` | Secret key for webhook authentication | `your-secure-random-key` |
| `GOOGLE_SHEETS_CREDENTIALS_JSON` | Google service account JSON (optional) | `{"type": "service_account",...}` |
| `GOOGLE_SHEETS_CREDENTIALS_PATH` | Path to credentials file (local dev) | `/path/to/credentials.json` |

### Google Sheet Format

Your Google Sheet should have these columns (order flexible):

| Date | Spend Type | Spend Item | Ingoing | Outgoing | Balance |
|------|------------|------------|---------|----------|---------|
| 2024-01-15 | Food | Groceries | | 50.00 | 950.00 |
| 2024-01-15 | Income | Salary | 1000.00 | | 1000.00 |

## 📊 Database Schema

### `spend_records` Table
- `id`: Primary key
- `sheet_row_number`: Row number from Google Sheet
- `date_recorded`: Transaction date
- `spend_type`: Category of expenditure
- `spend_item`: Description of the item/transaction
- `ingoing`: Income amount
- `outgoing`: Expense amount
- `balance`: Account balance
- `created_at`/`updated_at`: Timestamps
- `sheet_sync_id`: Unique sync session identifier

### `sync_log` Table
- Tracks all sync attempts with success/failure status
- Records execution time and error messages
- Useful for monitoring and debugging

## 🔍 API Endpoints

### Webhook Endpoint (Real-time Sync)
```
POST /api/sync_webhook
Headers: X-Sync-Secret: your-secret-key
```

### Status Endpoint (Monitoring)
```
GET /api/sync_status
GET /api/sync_status?validate=true  # Include validation check
```

### Timer Function
- Runs automatically every 15 minutes
- Provides backup sync in case webhooks fail
- Intelligent: skips sync if recent webhook sync occurred

## 🛠️ Local Development

```powershell
# Set up local development environment
.\deployment\local-development.ps1 -InstallAzureFunctionsCore

# Start local development server
.\start-dev.ps1

# Test the functions
.\test-local.ps1
```

Local URLs:
- Webhook: `http://localhost:7071/api/sync_webhook`
- Status: `http://localhost:7071/api/sync_status`

## 📈 Monitoring

### Check Sync Status
```bash
curl "https://your-function-app.azurewebsites.net/api/sync_status"
```

### Database Queries
```sql
-- Recent sync activity
SELECT TOP 10 * FROM sync_log ORDER BY sync_timestamp DESC;

-- Recent spend records
SELECT TOP 10 * FROM spend_records ORDER BY updated_at DESC;

-- Sync success rate
SELECT * FROM v_sync_summary;
```

## 🔒 Security

- **Webhook Authentication**: Secret key required for all webhook calls
- **Azure SQL**: Encrypted connections with proper authentication
- **Google Sheets**: Service account with minimal required permissions
- **Azure Functions**: Function-level authorization

## 🐛 Troubleshooting

### Common Issues

1. **Google Sheets Access Denied**
   - Ensure service account email has access to the sheet
   - Check Google Cloud Project has Sheets API enabled

2. **Azure SQL Connection Failed**
   - Verify connection string format
   - Check firewall rules allow Azure services
   - Ensure database exists and user has permissions

3. **Webhook Not Triggering**
   - Verify Google Apps Script is configured correctly
   - Check secret key matches between script and Azure Function
   - Ensure Azure Function URL is accessible

4. **Timer Function Not Running**
   - Check Azure Function App is running
   - Verify timer trigger configuration in `function.json`
   - Check Application Insights for logs

### Debug Tools

1. **Azure Function Logs**: Monitor via Azure Portal → Function App → Monitor
2. **Google Apps Script Logs**: View via Apps Script Editor → Executions
3. **Database Monitoring**: Query `sync_log` table for detailed history

## 🔄 Sync Frequency Options

### Current Configuration
- **Real-time**: Immediate sync via Google Apps Script webhooks
- **Backup**: Every 15 minutes via timer trigger

### Customization
Change timer frequency in `src/sync_timer/function.json`:
```json
{
  "schedule": "0 */5 * * * *"  // Every 5 minutes
}
```

Common cron expressions:
- Every minute: `0 * * * * *`
- Every 5 minutes: `0 */5 * * * *`
- Every hour: `0 0 * * * *`
- Daily at 9 AM: `0 0 9 * * *`

## 📝 Customization

### Adding New Data Fields
1. Update `google_sheets_client.py` parsing logic
2. Modify database schema in `azure_sql_client.py`
3. Update `azure-sql-setup.sql` with new columns

### Changing Sheet Structure
1. Modify `header_mapping` in `google_sheets_client.py`
2. Adjust parsing logic as needed

### Enhanced Notifications
1. Add email/SMS notifications to `sync_service.py`
2. Integrate with Azure Logic Apps or Power Automate

## 📄 License

This project is provided as-is for personal and educational use.

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

---

**Built with ❤️ using Azure Functions, Python, and Google Sheets API**