# Local Development Setup Script for SpendTracker
# This script helps set up the local development environment

param(
    [string]$PythonPath = "python",
    [switch]$InstallAzureFunctionsCore = $false
)

Write-Host "Setting up SpendTracker local development environment..." -ForegroundColor Green

# Check if we're in the right directory
$projectRoot = Split-Path $PSScriptRoot -Parent
if (!(Test-Path (Join-Path $projectRoot "requirements.txt"))) {
    Write-Error "Please run this script from the SpendTracker project directory"
    exit 1
}

Set-Location $projectRoot

# Check Python installation
Write-Host "Checking Python installation..." -ForegroundColor Yellow
try {
    $pythonVersion = & $PythonPath --version 2>&1
    Write-Host "Found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Error "Python not found. Please install Python 3.9+ or specify the correct path with -PythonPath"
    exit 1
}

# Install Azure Functions Core Tools if requested
if ($InstallAzureFunctionsCore) {
    Write-Host "Installing Azure Functions Core Tools..." -ForegroundColor Yellow
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install Microsoft.Azure.FunctionsCoreTools
    } else {
        Write-Host "Please install Azure Functions Core Tools manually from: https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local"
    }
}

# Create virtual environment
Write-Host "Creating Python virtual environment..." -ForegroundColor Yellow
& $PythonPath -m venv venv

# Activate virtual environment and install dependencies
Write-Host "Installing Python dependencies..." -ForegroundColor Yellow
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    & ".\venv\Scripts\activate.ps1"
    & ".\venv\Scripts\pip" install -r requirements.txt
} else {
    & "./venv/bin/activate"
    & "./venv/bin/pip" install -r requirements.txt
}

# Create sample local.settings.json if it doesn't exist
$localSettingsPath = "local.settings.json"
if (!(Test-Path $localSettingsPath)) {
    Write-Host "Creating sample local.settings.json..." -ForegroundColor Yellow
    
    $sampleSettings = @{
        IsEncrypted = $false
        Values = @{
            AzureWebJobsStorage = "UseDevelopmentStorage=true"
            FUNCTIONS_WORKER_RUNTIME = "python"
            GOOGLE_SHEETS_CREDENTIALS_PATH = "C:\path\to\your\service-account-key.json"
            GOOGLE_SHEET_ID = "your-google-sheet-id-here"
            AZURE_SQL_CONNECTION_STRING = "Driver={ODBC Driver 18 for SQL Server};Server=your-server.database.windows.net,1433;Database=your-database;Uid=your-username;Pwd=your-password;Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
            AZURE_KEY_VAULT_URL = "https://your-keyvault.vault.azure.net/"
            SYNC_SECRET_KEY = "your-secret-key-here"
        }
    } | ConvertTo-Json -Depth 3
    
    $sampleSettings | Out-File -FilePath $localSettingsPath -Encoding UTF8
    Write-Host "Sample configuration created at $localSettingsPath" -ForegroundColor Green
    Write-Host "Please update the values in local.settings.json with your actual configuration" -ForegroundColor Yellow
}

# Create development scripts
Write-Host "Creating development helper scripts..." -ForegroundColor Yellow

# Create start script
$startScript = @'
# Start local Azure Functions development server
Write-Host "Starting SpendTracker Azure Functions..." -ForegroundColor Green
Write-Host "Webhook URL will be: http://localhost:7071/api/sync_webhook" -ForegroundColor Cyan
Write-Host "Status URL will be: http://localhost:7071/api/sync_status" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

func start
'@
$startScript | Out-File -FilePath "start-dev.ps1" -Encoding UTF8

# Create test script
$testScript = @'
# Test SpendTracker functions locally
param(
    [string]$BaseUrl = "http://localhost:7071",
    [string]$SecretKey = "your-secret-key-here"
)

Write-Host "Testing SpendTracker functions..." -ForegroundColor Green

# Test status endpoint
Write-Host "`nTesting status endpoint..." -ForegroundColor Yellow
try {
    $statusResponse = Invoke-RestMethod -Uri "$BaseUrl/api/sync_status" -Method GET
    Write-Host "Status endpoint working!" -ForegroundColor Green
    $statusResponse | ConvertTo-Json -Depth 3
} catch {
    Write-Error "Status endpoint failed: $_"
}

# Test webhook endpoint
Write-Host "`nTesting webhook endpoint..." -ForegroundColor Yellow
$webhookPayload = @{
    timestamp = (Get-Date).ToString("o")
    eventType = "test"
    eventData = @{
        message = "Test from PowerShell"
    }
    sheetId = "test-sheet-id"
    sheetName = "Test Sheet"
} | ConvertTo-Json

try {
    $webhookResponse = Invoke-RestMethod -Uri "$BaseUrl/api/sync_webhook" -Method POST -Body $webhookPayload -ContentType "application/json" -Headers @{"X-Sync-Secret" = $SecretKey}
    Write-Host "Webhook endpoint working!" -ForegroundColor Green
    $webhookResponse | ConvertTo-Json -Depth 3
} catch {
    Write-Error "Webhook endpoint failed: $_"
}
'@
$testScript | Out-File -FilePath "test-local.ps1" -Encoding UTF8

Write-Host "`nLocal development setup completed!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Update local.settings.json with your configuration" -ForegroundColor White
Write-Host "2. Run 'start-dev.ps1' to start the local development server" -ForegroundColor White
Write-Host "3. Run 'test-local.ps1' to test the functions" -ForegroundColor White
Write-Host "4. Use ngrok or similar tool to expose localhost for Google Sheets webhooks" -ForegroundColor White

Write-Host "`nUseful commands:" -ForegroundColor Cyan
Write-Host "- Start development server: .\start-dev.ps1" -ForegroundColor White
Write-Host "- Test functions: .\test-local.ps1" -ForegroundColor White
Write-Host "- View logs: Check the Azure Functions output in the terminal" -ForegroundColor White