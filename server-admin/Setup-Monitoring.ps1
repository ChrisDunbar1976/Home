<# Setup-Monitoring.ps1
   Sets up the monitoring environment for ServerWatch.ps1
   Run this once to prepare directories and scheduled tasks
#>

# Ensure running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator to set up monitoring properly."
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then run this script again."
    exit 1
}

Write-Host "SERVERWATCH MONITORING SETUP" -ForegroundColor Green
Write-Host "=" * 40

# Create monitoring directory
$monitorDir = "C:\Monitors"
if (-not (Test-Path $monitorDir)) {
    Write-Host "Creating monitoring directory: $monitorDir" -ForegroundColor Yellow
    New-Item -Path $monitorDir -ItemType Directory -Force | Out-Null
    Write-Host "✓ Directory created" -ForegroundColor Green
} else {
    Write-Host "✓ Monitoring directory exists: $monitorDir" -ForegroundColor Green
}

# Set permissions on monitoring directory
try {
    $acl = Get-Acl $monitorDir
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM","FullControl","ContainerInherit,ObjectInherit","None","Allow")
    $acl.SetAccessRule($accessRule)
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators","FullControl","ContainerInherit,ObjectInherit","None","Allow")
    $acl.SetAccessRule($accessRule)
    Set-Acl -Path $monitorDir -AclObject $acl
    Write-Host "✓ Permissions set on monitoring directory" -ForegroundColor Green
} catch {
    Write-Warning "Could not set permissions: $($_.Exception.Message)"
}

# Test email configuration
Write-Host "`nTesting email configuration..." -ForegroundColor Yellow
try {
    $testMail = @{
        From       = "MLNOESQLEXP01@metroline.co.uk"
        To         = "BISupport@metroline.co.uk"
        Subject    = "[TEST] ServerWatch Setup - Email Test"
        Body       = "This is a test email from ServerWatch setup. If you receive this, email alerting is configured correctly.`n`nTime: $(Get-Date)"
        SmtpServer = "mail.metroline.co.uk"
        Port       = 25
    }
    Send-MailMessage @testMail -ErrorAction Stop
    Write-Host "✓ Test email sent successfully" -ForegroundColor Green
} catch {
    Write-Warning "Email test failed: $($_.Exception.Message)"
    Write-Host "Please verify SMTP settings in ServerWatch.ps1" -ForegroundColor Yellow
}

# Create scheduled task for continuous monitoring
Write-Host "`nSetting up scheduled task..." -ForegroundColor Yellow
$taskName = "ServerWatch-MLNOESQLEXP01"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$serverWatchPath = Join-Path $scriptPath "ServerWatch.ps1"

if (Test-Path $serverWatchPath) {
    try {
        # Remove existing task if it exists
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-Host "Removing existing scheduled task..." -ForegroundColor Yellow
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }
        
        # Create new task
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$serverWatchPath`""
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 1) -RepetitionDuration (New-TimeSpan -Days 365)
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
        $principal = New-ScheduledTaskPrincipal -UserID "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Monitors MLNOESQLEXP01 server health every minute"
        
        Write-Host "✓ Scheduled task created: $taskName" -ForegroundColor Green
        Write-Host "  - Runs every minute as SYSTEM account" -ForegroundColor Gray
        Write-Host "  - Script: $serverWatchPath" -ForegroundColor Gray
    } catch {
        Write-Warning "Failed to create scheduled task: $($_.Exception.Message)"
        Write-Host "You may need to create the scheduled task manually" -ForegroundColor Yellow
    }
} else {
    Write-Warning "ServerWatch.ps1 not found at: $serverWatchPath"
    Write-Host "Please ensure ServerWatch.ps1 is in the same directory as this setup script" -ForegroundColor Yellow
}

# Test connectivity to target server
Write-Host "`nTesting connectivity to MLNOESQLEXP01..." -ForegroundColor Yellow
if (Test-Connection -ComputerName "MLNOESQLEXP01" -Count 2 -Quiet) {
    Write-Host "✓ Can reach MLNOESQLEXP01 via ping" -ForegroundColor Green
    
    # Test SQL port
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connect = $tcpClient.BeginConnect("MLNOESQLEXP01", 1433, $null, $null)
        if ($connect.AsyncWaitHandle.WaitOne(3000)) {
            $tcpClient.EndConnect($connect)
            $tcpClient.Close()
            Write-Host "✓ SQL Server port 1433 is accessible" -ForegroundColor Green
        } else {
            $tcpClient.Close()
            Write-Warning "Cannot connect to SQL Server port 1433"
        }
    } catch {
        Write-Warning "SQL port test failed: $($_.Exception.Message)"
    }
} else {
    Write-Warning "Cannot reach MLNOESQLEXP01 via ping"
    Write-Host "Please verify network connectivity and server name" -ForegroundColor Yellow
}

# Test WMI/CIM access for enhanced monitoring
Write-Host "`nTesting remote monitoring capabilities..." -ForegroundColor Yellow
try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName "MLNOESQLEXP01" -OperationTimeoutSec 10 -ErrorAction Stop
    Write-Host "✓ Can access system information remotely" -ForegroundColor Green
    Write-Host "  Server OS: $($os.Caption)" -ForegroundColor Gray
} catch {
    Write-Warning "Cannot access remote system information: $($_.Exception.Message)"
    Write-Host "Enhanced monitoring features may not work properly" -ForegroundColor Yellow
    Write-Host "Ensure WMI/CIM access is enabled and firewall allows connections" -ForegroundColor Yellow
}

# Display final instructions
Write-Host "`n" + "=" * 60 -ForegroundColor Green
Write-Host "SETUP COMPLETE!" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Green

Write-Host "`nNEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. The scheduled task will start monitoring automatically"
Write-Host "2. Check logs at: $monitorDir\ServerWatch.log"
Write-Host "3. State file at: $monitorDir\ServerWatch.state.json"
Write-Host "4. Run DiagnoseShutdowns.ps1 to analyze existing shutdown history"

Write-Host "`nTO INVESTIGATE CURRENT SHUTDOWNS:" -ForegroundColor Yellow
Write-Host "Run this command:"
Write-Host "  .\DiagnoseShutdowns.ps1 -ExportReport" -ForegroundColor Cyan

Write-Host "`nTO MANUALLY RUN MONITORING:" -ForegroundColor Yellow
Write-Host "  .\ServerWatch.ps1" -ForegroundColor Cyan

Write-Host "`nTO VIEW SCHEDULED TASK:" -ForegroundColor Yellow
Write-Host "  Get-ScheduledTask -TaskName '$taskName'" -ForegroundColor Cyan

Write-Host "`nMonitoring will now run every minute and alert on:" -ForegroundColor Green
Write-Host "  • Server downtime" 
Write-Host "  • High CPU/Memory usage"
Write-Host "  • Low disk space"
Write-Host "  • SQL Server issues"
Write-Host "  • System shutdown events"
Write-Host "  • Critical system errors"

Write-Host "`nPress any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")