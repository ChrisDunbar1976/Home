# SpendTracker Azure Functions Deployment Script
# Prerequisites: Azure CLI installed and logged in

param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory=$true)]
    [string]$AzureSqlServerName,
    
    [Parameter(Mandatory=$true)]
    [string]$AzureSqlDatabaseName,
    
    [Parameter(Mandatory=$true)]
    [string]$GoogleSheetId,
    
    [Parameter(Mandatory=$true)]
    [string]$SyncSecretKey,
    
    [string]$Location = "East US",
    [string]$KeyVaultName = "",
    [switch]$CreateResources = $false,

    # Optional: Provision Azure SQL logical server + database (Serverless GP)
    [switch]$ProvisionAzureSql = $false,
    [double]$ServerlessMaxVcores = 2,
    [double]$ServerlessMinVcores = 0.5,
    [int]$AutoPauseDelayMinutes = 60,
    [string]$BackupStorageRedundancy = "Local",

    # Optional: SQL authentication for app connection string (if not using AAD)
    [string]$AzureSqlAdminLogin = "",
    [string]$AzureSqlAdminPassword = "",

    # Optional: Configure Azure AD admin for the SQL server
    [string]$AzureAdAdminLogin = "",      # e.g. user@domain.com
    [string]$AzureAdAdminObjectId = "",   # AAD Object ID for the admin principal

    # Optional: Firewall rules
    [switch]$AllowAzureServices = $true,   # Allow Azure services to access the server
    [switch]$AllowClientIp = $true,
    [string]$ClientIp = ""                 # Override client IP (x.x.x.x). If empty and AllowClientIp, script will detect
)

Write-Host "Starting SpendTracker deployment..." -ForegroundColor Green

# Set subscription
Write-Host "Setting Azure subscription..." -ForegroundColor Yellow
az account set --subscription $SubscriptionId

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to set subscription. Please ensure you're logged in with 'az login'"
    exit 1
}

# Create resource group if it doesn't exist
Write-Host "Checking resource group..." -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroupName --output tsv
if ($rgExists -eq "false") {
    if ($CreateResources) {
        Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Green
        az group create --name $ResourceGroupName --location $Location
    } else {
        Write-Error "Resource group '$ResourceGroupName' does not exist. Use -CreateResources to create it."
        exit 1
    }
}

# Create storage account if needed
Write-Host "Checking storage account..." -ForegroundColor Yellow
$storageExists = az storage account check-name --name $StorageAccountName --query "nameAvailable" --output tsv
if ($storageExists -eq "true" -and $CreateResources) {
    Write-Host "Creating storage account: $StorageAccountName" -ForegroundColor Green
    az storage account create `
        --name $StorageAccountName `
        --resource-group $ResourceGroupName `
        --location $Location `
        --sku Standard_LRS `
        --kind StorageV2
}

# Create Key Vault if specified
if ($KeyVaultName -and $CreateResources) {
    Write-Host "Creating Key Vault: $KeyVaultName" -ForegroundColor Green
    az keyvault create `
        --name $KeyVaultName `
        --resource-group $ResourceGroupName `
        --location $Location
}

# Create or configure Azure SQL logical server + database (optional)
if ($ProvisionAzureSql) {
    Write-Host "Checking Azure SQL logical server..." -ForegroundColor Yellow
    $server = az sql server show -g $ResourceGroupName -n $AzureSqlServerName --only-show-errors 2>$null | ConvertFrom-Json

    if (-not $server) {
        if (-not $CreateResources) {
            Write-Error "SQL server '$AzureSqlServerName' not found. Use -CreateResources with -ProvisionAzureSql to create it."
            exit 1
        }

        Write-Host "Creating Azure SQL logical server: $AzureSqlServerName" -ForegroundColor Green
        if ($AzureSqlAdminLogin -and $AzureSqlAdminPassword) {
            az sql server create `
                -g $ResourceGroupName `
                -n $AzureSqlServerName `
                -l $Location `
                -u $AzureSqlAdminLogin `
                -p $AzureSqlAdminPassword | Out-Null
        } else {
            Write-Warning "No SQL admin login/password provided. You can still set AAD admin below and use AAD auth."
            # Create the server with placeholder admin to satisfy CLI, then enforce AAD for operations
            $tmpLogin = "sqladminuser"
            $tmpPass = [Guid]::NewGuid().ToString('N') + "!Aa1"
            az sql server create `
                -g $ResourceGroupName `
                -n $AzureSqlServerName `
                -l $Location `
                -u $tmpLogin `
                -p $tmpPass | Out-Null
        }

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to create Azure SQL logical server"
            exit 1
        }
    } else {
        Write-Host "Azure SQL logical server exists." -ForegroundColor Green
    }

    # Configure AAD admin if provided
    if ($AzureAdAdminLogin -and $AzureAdAdminObjectId) {
        Write-Host "Configuring Azure AD admin: $AzureAdAdminLogin" -ForegroundColor Yellow
        az sql server ad-admin create `
            -g $ResourceGroupName `
            -s $AzureSqlServerName `
            -u $AzureAdAdminLogin `
            -i $AzureAdAdminObjectId | Out-Null
    }

    # Firewall rules
    if ($AllowAzureServices) {
        Write-Host "Allowing Azure services to access the SQL server" -ForegroundColor Yellow
        az sql server firewall-rule create `
            -g $ResourceGroupName `
            -s $AzureSqlServerName `
            -n AllowAzureServices `
            --start-ip-address 0.0.0.0 `
            --end-ip-address 0.0.0.0 | Out-Null
    }

    if ($AllowClientIp) {
        $detectedIp = $ClientIp
        if (-not $detectedIp) {
            try {
                $detectedIp = (Invoke-RestMethod -Uri "https://api.ipify.org").Trim()
            } catch {
                Write-Warning "Could not auto-detect client IP. Provide -ClientIp x.x.x.x to create a firewall rule."
            }
        }
        if ($detectedIp) {
            Write-Host "Allowing client IP: $detectedIp" -ForegroundColor Yellow
            az sql server firewall-rule create `
                -g $ResourceGroupName `
                -s $AzureSqlServerName `
                -n AllowClientIP `
                --start-ip-address $detectedIp `
                --end-ip-address $detectedIp | Out-Null
        }
    }

    # Create database if needed (Serverless GP)
    Write-Host "Checking Azure SQL database '$AzureSqlDatabaseName'..." -ForegroundColor Yellow
    $db = az sql db show -g $ResourceGroupName -s $AzureSqlServerName -n $AzureSqlDatabaseName --only-show-errors 2>$null | ConvertFrom-Json
    if (-not $db) {
        if (-not $CreateResources) {
            Write-Error "SQL database '$AzureSqlDatabaseName' not found. Use -CreateResources with -ProvisionAzureSql to create it."
            exit 1
        }
        Write-Host "Creating Azure SQL database (Serverless GP): $AzureSqlDatabaseName" -ForegroundColor Green
        az sql db create `
            -g $ResourceGroupName `
            -s $AzureSqlServerName `
            -n $AzureSqlDatabaseName `
            --compute-model Serverless `
            --tier GeneralPurpose `
            --family Gen5 `
            --capacity $ServerlessMaxVcores `
            --min-capacity $ServerlessMinVcores `
            --auto-pause-delay $AutoPauseDelayMinutes `
            --backup-storage-redundancy $BackupStorageRedundancy | Out-Null

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to create Azure SQL database"
            exit 1
        }
    } else {
        Write-Host "Azure SQL database exists." -ForegroundColor Green
    }
}

# Create Function App
Write-Host "Creating Function App: $FunctionAppName" -ForegroundColor Green
az functionapp create `
    --resource-group $ResourceGroupName `
    --consumption-plan-location $Location `
    --runtime python `
    --runtime-version 3.9 `
    --functions-version 4 `
    --name $FunctionAppName `
    --storage-account $StorageAccountName `
    --os-type Linux

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to create Function App"
    exit 1
}

# Configure application settings
Write-Host "Configuring application settings..." -ForegroundColor Yellow

# Build connection string for Azure SQL
if ($AzureSqlAdminLogin -and $AzureSqlAdminPassword) {
    $sqlConnectionString = "Driver={ODBC Driver 18 for SQL Server};Server=tcp:$AzureSqlServerName.database.windows.net,1433;Database=$AzureSqlDatabaseName;Uid=$AzureSqlAdminLogin;Pwd=$AzureSqlAdminPassword;Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
} else {
    # Placeholder for AAD or manual secret injection
    $sqlConnectionString = "Driver={ODBC Driver 18 for SQL Server};Server=tcp:$AzureSqlServerName.database.windows.net,1433;Database=$AzureSqlDatabaseName;Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
}

# Set application settings
az functionapp config appsettings set `
    --name $FunctionAppName `
    --resource-group $ResourceGroupName `
    --settings `
        "GOOGLE_SHEET_ID=$GoogleSheetId" `
        "AZURE_SQL_CONNECTION_STRING=$sqlConnectionString" `
        "SYNC_SECRET_KEY=$SyncSecretKey" `
        "FUNCTIONS_WORKER_RUNTIME=python" `
        "SCM_DO_BUILD_DURING_DEPLOYMENT=true" `
        "ENABLE_ORYX_BUILD=true"

if ($KeyVaultName) {
    az functionapp config appsettings set `
        --name $FunctionAppName `
        --resource-group $ResourceGroupName `
        --settings "AZURE_KEY_VAULT_URL=https://$KeyVaultName.vault.azure.net/"
}

# Deploy the function code
Write-Host "Deploying function code..." -ForegroundColor Green
$sourceDir = Join-Path $PSScriptRoot ".."
cd $sourceDir

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Yellow
$tempDir = Join-Path $env:TEMP "spendtracker-deploy"
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Copy files for deployment
Copy-Item "requirements.txt" $tempDir
Copy-Item "host.json" $tempDir
Copy-Item "src" $tempDir -Recurse

# Deploy using Azure CLI
az functionapp deployment source config-zip `
    --resource-group $ResourceGroupName `
    --name $FunctionAppName `
    --src (Compress-Archive -Path "$tempDir\*" -DestinationPath "$tempDir\deploy.zip" -PassThru).FullName

if ($LASTEXITCODE -eq 0) {
    Write-Host "Deployment completed successfully!" -ForegroundColor Green
    
    # Get function URLs
    Write-Host "`nFunction URLs:" -ForegroundColor Cyan
    $webhookUrl = az functionapp function show --name $FunctionAppName --resource-group $ResourceGroupName --function-name sync_webhook --query "invokeUrlTemplate" --output tsv
    $statusUrl = az functionapp function show --name $FunctionAppName --resource-group $ResourceGroupName --function-name sync_status --query "invokeUrlTemplate" --output tsv
    
    Write-Host "Webhook URL: $webhookUrl" -ForegroundColor White
    Write-Host "Status URL: $statusUrl" -ForegroundColor White
    
    Write-Host "`nNext Steps:" -ForegroundColor Cyan
    Write-Host "1. Update Azure SQL connection string with actual credentials"
    Write-Host "2. Upload Google Sheets service account credentials"
    Write-Host "3. Update Google Apps Script with webhook URL: $webhookUrl"
    Write-Host "4. Test the deployment using the status endpoint"
    
} else {
    Write-Error "Deployment failed!"
    exit 1
}

# Cleanup temp directory
Remove-Item $tempDir -Recurse -Force

Write-Host "`nDeployment script completed!" -ForegroundColor Green
