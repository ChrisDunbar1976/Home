# SpendTracker Google Sheets to Azure SQL Integration - Conversation Log

**Date:** August 21, 2025  
**Project:** SpendTracker Azure Functions Solution

## Initial Request

**User asked:** For a Google sheet that maintains expenditure data (ingoings, outgoings, date, spend type, spend item, balance) with daily updates, and considering moving to Azure SQL Server from local MS SQL Server - is it possible to build an API that will poll the Google Sheet daily and import data into MS SQL Server?

## Solution Overview

**Architecture Decided Upon:**
- Python + Azure Functions (for flexibility)
- Azure SQL Server (cloud-based)
- Hybrid approach: Real-time push notifications + backup polling
- Google Apps Script for push notifications + Timer trigger for backup

## Key Requirements Addressed

1. **Flexibility:** User wanted maximum flexibility over daily polling
2. **Real-time capability:** Push notifications for immediate sync when sheet changes
3. **Reliability:** Backup timer trigger every 15 minutes for missed changes
4. **Cloud-based:** Azure SQL instead of local SQL Server
5. **Comprehensive solution:** Complete deployment and monitoring capabilities

## Technical Architecture Implemented

```
Google Sheet → Apps Script (onChange trigger) → Azure Function (HTTP) → Azure SQL Database
                                                      ↓
                                Timer Function (every 15 min) → Backup sync
```

## Solution Components Created

### 1. Azure Functions (3 functions)
- **sync_webhook** - HTTP trigger for real-time sync from Google Apps Script
- **sync_timer** - Timer trigger (every 15 minutes) for backup/reconciliation sync  
- **sync_status** - HTTP endpoint for monitoring and status checking

### 2. Core Python Modules
- **google_sheets_client.py** - Google Sheets API integration with data parsing
- **azure_sql_client.py** - Azure SQL Database operations with upsert logic
- **sync_service.py** - Main orchestration service with error handling

### 3. Google Apps Script
- **google-apps-script.js** - Real-time change detection and webhook notifications
- Debounced triggering (2-second delay after last change)
- Retry logic with exponential backoff
- Connection testing and status logging

### 4. Database Schema
- **spend_records** table - Main expenditure data with unique constraints
- **sync_log** table - Comprehensive audit trail of all sync attempts
- Views for monitoring and reporting

### 5. Deployment & Configuration
- **deploy.ps1** - Complete Azure resource provisioning script
- **azure-sql-setup.sql** - Database schema and initial setup
- **local-development.ps1** - Local development environment setup
- **README.md** - Complete documentation
- **SETUP-GUIDE.md** - Step-by-step setup instructions

## Key Features Implemented

### Sync Frequency Options
- **Real-time:** Immediate sync via Google Apps Script webhooks
- **Backup polling:** Every 15 minutes (configurable)
- **Custom frequencies:** Easy to modify timer expressions
  - Every minute: `0 * * * * *`
  - Every 5 minutes: `0 */5 * * * *`
  - Every hour: `0 0 * * * *`

### Data Handling
- **Flexible column mapping** - Handles various header names
- **Data validation** - Proper date and currency parsing
- **Upsert operations** - Updates existing records, inserts new ones
- **Unique tracking** - Sheet row numbers prevent duplicates

### Security & Monitoring
- **Webhook authentication** - Secret key validation
- **Comprehensive logging** - All sync attempts tracked
- **Error handling** - Retry logic with detailed error messages
- **Status monitoring** - REST API for health checking

### Deployment Options
- **Azure deployment** - Fully automated PowerShell script
- **Local development** - Complete local testing environment
- **Configuration management** - Environment variables and Key Vault support

## Technical Decisions Made

1. **Azure Functions over other options** for serverless scaling and cost efficiency
2. **Python** for flexibility and rich library ecosystem
3. **Hybrid push/pull approach** for maximum reliability
4. **Google Apps Script** for real-time change detection without polling overhead
5. **Comprehensive logging** for debugging and monitoring
6. **Flexible sheet parsing** to handle various column arrangements

## Files Created

**Project Location:** `C:\Users\cdunbar\Projects\RhubarbAccounts\SpendTracker-AzureFunction\`

### Core Application
```
src/
├── shared/
│   ├── google_sheets_client.py     # Google Sheets API integration
│   ├── azure_sql_client.py         # Azure SQL operations
│   ├── sync_service.py              # Main sync orchestration
│   └── __init__.py
├── sync_webhook/                    # HTTP trigger function
│   ├── function.json
│   └── __init__.py
├── sync_timer/                      # Timer trigger function
│   ├── function.json
│   └── __init__.py
└── sync_status/                     # Status monitoring function
    ├── function.json
    └── __init__.py
```

### Configuration & Deployment
```
config/
└── google-apps-script.js            # Google Apps Script code

deployment/
├── deploy.ps1                       # Azure deployment script
├── azure-sql-setup.sql              # Database setup script
└── local-development.ps1            # Local dev setup

requirements.txt                      # Python dependencies
host.json                            # Azure Functions config
local.settings.json                  # Local development config
README.md                            # Complete documentation
SETUP-GUIDE.md                       # Step-by-step setup guide
```

## Next Steps for Implementation

1. **Azure Setup:**
   ```powershell
   .\deployment\deploy.ps1 -SubscriptionId "your-id" -ResourceGroupName "SpendTracker-RG" -FunctionAppName "spendtracker-func" -StorageAccountName "spendtrackerstorage" -AzureSqlServerName "spendtracker-sql" -AzureSqlDatabaseName "SpendTrackerDB" -GoogleSheetId "your-sheet-id" -SyncSecretKey "your-secret" -CreateResources
   ```

2. **Google Cloud Setup:**
   - Enable Google Sheets API
   - Create service account and download JSON credentials
   - Share Google Sheet with service account email

3. **Google Apps Script Setup:**
   - Add script to Google Sheet via Extensions → Apps Script
   - Update configuration constants with Azure Function URLs
   - Run initialization function

4. **Testing:**
   - Use status endpoint to verify configuration
   - Test real-time sync by modifying sheet
   - Monitor sync logs in Azure SQL database

## User's Original Environment Context

- **Working Directory:** C:\Users\cdunbar\Projects
- **Platform:** Windows 32-bit
- **Date:** August 21, 2025
- **Existing Credentials:** Microsoft credentials stored in RhubarbAccounts\Credentials folder
- **Email:** christopherdunbar@hotmail.com

## Solution Benefits

1. **Cost Efficient:** Serverless functions only run when needed
2. **Scalable:** Azure Functions automatically handle load
3. **Reliable:** Dual sync approach ensures no data loss
4. **Monitorable:** Comprehensive logging and status endpoints
5. **Secure:** Encrypted connections and authentication
6. **Flexible:** Easy to modify sync frequency and data mapping
7. **Complete:** Ready-to-deploy solution with full documentation

---

**Project Status:** ✅ Complete and ready for deployment  
**Location:** `C:\Users\cdunbar\Projects\RhubarbAccounts\SpendTracker-AzureFunction\`