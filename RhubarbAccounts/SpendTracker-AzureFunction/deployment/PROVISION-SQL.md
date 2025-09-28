Azure SQL Provisioning (Week 1 Pre‑check)

Overview
- Create an Azure SQL logical server and a Serverless General Purpose database sized for dev/test.
- Configure firewall (allow Azure services, optionally your current IP).
- Optionally set Azure AD admin and/or SQL admin credentials.
- Deploy Functions and wire up the connection string.

Recommended SKUs (Dev/Test)
- Region: UK South (or your nearest region).
- Compute model: Serverless (General Purpose, Gen5).
- vCores: min 0.5, max 2.
- Auto‑pause: 60 minutes.
- Backup redundancy: Local (dev/test). Consider Geo for prod.

Indicative cost
- Serverless dev/test typically low double‑digits USD/month when mostly idle + storage.
- Use Azure Pricing Calculator to refine for your region and usage.

How to run
1) Login and pick subscription
- az login
- az account set --subscription <SUBSCRIPTION_ID>

2) Run deploy.ps1 with SQL provisioning enabled

Example (replace placeholders):

```powershell
cd "Rhubarb Accounts/SpendTracker-AzureFunction/deployment"

./deploy.ps1 `
  -SubscriptionId "<SUBSCRIPTION_ID>" `
  -ResourceGroupName "rg-rhubarb-accounts" `
  -FunctionAppName "rhubarb-spend-func" `
  -StorageAccountName "rhubarbspendstg" `
  -AzureSqlServerName "sql-rhubarb-uk" `
  -AzureSqlDatabaseName "rhubarb-accounts-db" `
  -GoogleSheetId "<GOOGLE_SHEET_ID>" `
  -SyncSecretKey "<GENERATE_A_SECURE_KEY>" `
  -Location "UK South" `
  -CreateResources `
  -ProvisionAzureSql `
  -ServerlessMinVcores 0.5 `
  -ServerlessMaxVcores 2 `
  -AutoPauseDelayMinutes 60 `
  -BackupStorageRedundancy Local `
  -AllowAzureServices `
  -AllowClientIp `
  -AzureAdAdminLogin "rhubarbpress@hotmail.com" `
  -AzureAdAdminObjectId "<OBJECT_ID_OF_AAD_USER>"
```

Notes
- To find the Azure AD Object ID:
  - az ad user show --id rhubarbpress@hotmail.com --query id -o tsv
  - If using an Entra ID tenant different from your personal Microsoft Account, ensure the user exists in that tenant.
- If you prefer SQL authentication for the app connection string, pass:
  - -AzureSqlAdminLogin "sqladmin"
  - -AzureSqlAdminPassword "<STRONG_PASSWORD>"
  (The script will embed these in the connection string set on the Function App.)
- For production, consider:
  - Region redundancy for backups (Geo), Private Endpoint, Key Vault references, and higher vCores if consistently busy.

Next steps
- Run the Week 1 schema script to create ledger and staging tables:
  - File: Accounting Software/db/01-schemas-and-core.sql
  - Apply via Azure Data Studio or sqlcmd against the new database.
- Keep SpendTracker writing to its current tables for now; migrate to staging schema later.

