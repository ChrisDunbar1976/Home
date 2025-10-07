<# DiagnoseShutdowns.ps1
   Investigates server shutdown causes on MLNOESQLEXP01
   Run this script to analyze recent shutdown events and potential causes
#>

param(
    [string]$ComputerName = "MLNOESQLEXP01",
    [int]$DaysBack = 7,
    [switch]$ExportReport
)

# ====================== FUNCTIONS ======================
function Get-ShutdownEvents {
    param([string]$Computer, [int]$Days)
    
    $startTime = (Get-Date).AddDays(-$Days)
    
    Write-Host "`nGathering shutdown events from $Computer (last $Days days)..." -ForegroundColor Yellow
    
    try {
        $shutdownEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ID = 1074,1076,6005,6006,6008,6009,6013,41
            StartTime = $startTime
        } -ComputerName $Computer -ErrorAction SilentlyContinue
        
        return $shutdownEvents | Sort-Object TimeCreated -Descending
    } catch {
        Write-Warning "Failed to get shutdown events: $($_.Exception.Message)"
        return @()
    }
}

function Get-CriticalErrors {
    param([string]$Computer, [int]$Days)
    
    $startTime = (Get-Date).AddDays(-$Days)
    
    Write-Host "Gathering critical system errors..." -ForegroundColor Yellow
    
    try {
        $criticalEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            Level = 1,2  # Critical and Error
            StartTime = $startTime
        } -ComputerName $Computer -MaxEvents 50 -ErrorAction SilentlyContinue
        
        return $criticalEvents | Sort-Object TimeCreated -Descending
    } catch {
        Write-Warning "Failed to get critical errors: $($_.Exception.Message)"
        return @()
    }
}

function Get-SqlServerErrors {
    param([string]$Computer, [int]$Days)
    
    $startTime = (Get-Date).AddDays(-$Days)
    
    Write-Host "Gathering SQL Server errors..." -ForegroundColor Yellow
    
    try {
        $sqlEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'Application'
            ProviderName = 'MSSQLSERVER'
            Level = 1,2  # Critical and Error
            StartTime = $startTime
        } -ComputerName $Computer -MaxEvents 30 -ErrorAction SilentlyContinue
        
        return $sqlEvents | Sort-Object TimeCreated -Descending
    } catch {
        Write-Warning "Failed to get SQL Server errors: $($_.Exception.Message)"
        return @()
    }
}

function Get-SystemInfo {
    param([string]$Computer)
    
    Write-Host "Gathering system information..." -ForegroundColor Yellow
    
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $Computer
        $computer = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $Computer
        $cpu = Get-CimInstance -ClassName Win32_Processor -ComputerName $Computer
        $memory = Get-CimInstance -ClassName Win32_PhysicalMemory -ComputerName $Computer
        $disks = Get-CimInstance -ClassName Win32_LogicalDisk -ComputerName $Computer -Filter "DriveType=3"
        
        return @{
            OS = $os
            Computer = $computer
            CPU = $cpu
            Memory = $memory
            Disks = $disks
        }
    } catch {
        Write-Warning "Failed to get system info: $($_.Exception.Message)"
        return $null
    }
}

function Analyze-ShutdownPattern {
    param([array]$Events)
    
    if (-not $Events -or $Events.Count -eq 0) {
        return "No shutdown events found in the specified timeframe."
    }
    
    $analysis = @()
    $analysis += "SHUTDOWN PATTERN ANALYSIS"
    $analysis += "=" * 40
    $analysis += "Total shutdown events found: $($Events.Count)"
    
    # Group by event ID
    $groupedById = $Events | Group-Object Id
    foreach ($group in $groupedById) {
        $eventType = switch ($group.Name) {
            '1074' { 'System shutdown initiated by process' }
            '1076' { 'System shutdown reason' }
            '6005' { 'System startup' }
            '6006' { 'System shutdown' }
            '6008' { 'Unexpected system shutdown' }
            '6009' { 'System startup after unexpected shutdown' }
            '6013' { 'System uptime' }
            '41'   { 'System rebooted without cleanly shutting down' }
            default { "Event ID $($group.Name)" }
        }
        $analysis += "  $eventType : $($group.Count) events"
    }
    
    # Check for patterns
    $unexpectedShutdowns = $Events | Where-Object { $_.Id -in @(6008, 41) }
    if ($unexpectedShutdowns) {
        $analysis += "`nUNEXPECTED SHUTDOWNS DETECTED: $($unexpectedShutdowns.Count)"
        $analysis += "This indicates the server is not shutting down cleanly!"
        foreach ($shutdownItem in ($unexpectedShutdowns | Select-Object -First 5)) {
            $analysis += "  - $($shutdownItem.TimeCreated): $($shutdownItem.LevelDisplayName)"
        }
    }
    
    # Check timing patterns
    $recentEvents = $Events | Where-Object { $_.TimeCreated -gt (Get-Date).AddDays(-1) }
    if ($recentEvents.Count -gt 2) {
        $analysis += "`nFREQUENT RECENT SHUTDOWNS: $($recentEvents.Count) in last 24 hours"
        $analysis += "This suggests an ongoing issue requiring immediate attention!"
    }
    
    return $analysis -join "`r`n"
}

# ====================== MAIN EXECUTION ======================
Write-Host "SERVER SHUTDOWN DIAGNOSTIC TOOL" -ForegroundColor Green
Write-Host "Analyzing: $ComputerName" -ForegroundColor Green
Write-Host "Time Range: Last $DaysBack days" -ForegroundColor Green
Write-Host "=" * 50

# Test connectivity first
if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
    Write-Error "Cannot reach $ComputerName. Please check network connectivity."
    exit 1
}

# Gather all data
$shutdownEvents = Get-ShutdownEvents -Computer $ComputerName -Days $DaysBack
$criticalErrors = Get-CriticalErrors -Computer $ComputerName -Days $DaysBack
$sqlErrors = Get-SqlServerErrors -Computer $ComputerName -Days $DaysBack
$systemInfo = Get-SystemInfo -Computer $ComputerName

# Generate report
$report = @()
$report += "SHUTDOWN DIAGNOSTIC REPORT"
$report += "Server: $ComputerName"
$report += "Generated: $(Get-Date)"
$report += "Analysis Period: Last $DaysBack days"
$report += "=" * 60
$report += ""

# System Information
if ($systemInfo) {
    $report += "SYSTEM INFORMATION"
    $report += "-" * 20
    $report += "OS: $($systemInfo.OS.Caption) $($systemInfo.OS.Version)"
    $report += "Computer: $($systemInfo.Computer.Manufacturer) $($systemInfo.Computer.Model)"
    $report += "Total RAM: $([math]::Round(($systemInfo.Memory | Measure-Object Capacity -Sum).Sum / 1GB, 2)) GB"
    $report += "CPU: $($systemInfo.CPU[0].Name)"
    $report += "Last Boot: $($systemInfo.OS.LastBootUpTime)"
    $report += ""
}

# Shutdown Analysis
$report += Analyze-ShutdownPattern -Events $shutdownEvents
$report += ""

# Detailed Shutdown Events
if ($shutdownEvents) {
    $report += "DETAILED SHUTDOWN EVENTS"
    $report += "-" * 30
    foreach ($eventItem in ($shutdownEvents | Select-Object -First 10)) {
        $report += "$($eventItem.TimeCreated) - Event $($eventItem.Id) - $($eventItem.LevelDisplayName)"
        $report += "  Message: $($eventItem.Message -replace '\r?\n', ' ' | % { $_.Substring(0, [Math]::Min($_.Length, 100)) })"
        $report += ""
    }
}

# Critical System Errors
if ($criticalErrors) {
    $report += "CRITICAL SYSTEM ERRORS (Last $DaysBack days)"
    $report += "-" * 40
    $errorGroups = $criticalErrors | Group-Object Id | Sort-Object Count -Descending | Select-Object -First 10
    foreach ($group in $errorGroups) {
        $report += "Event ID $($group.Name): $($group.Count) occurrences"
        $sample = $group.Group | Select-Object -First 1
        $report += "  Latest: $($sample.TimeCreated)"
        $report += "  Message: $($sample.Message -replace '\r?\n', ' ' | % { $_.Substring(0, [Math]::Min($_.Length, 150)) })"
        $report += ""
    }
}

# SQL Server Errors
if ($sqlErrors) {
    $report += "SQL SERVER ERRORS (Last $DaysBack days)"
    $report += "-" * 35
    foreach ($errorItem in ($sqlErrors | Select-Object -First 5)) {
        $report += "$($errorItem.TimeCreated) - $($errorItem.LevelDisplayName)"
        $report += "  $($errorItem.Message -replace '\r?\n', ' ' | % { $_.Substring(0, [Math]::Min($_.Length, 150)) })"
        $report += ""
    }
}

# Recommendations
$report += "RECOMMENDATIONS"
$report += "-" * 15
$report += "1. Check Windows Update history for recent updates that might cause instability"
$report += "2. Verify hardware health: Run memory diagnostics, check disk health"
$report += "3. Review SQL Server error logs for database-related shutdown triggers"
$report += "4. Check for overheating: Monitor CPU/system temperatures"
$report += "5. Examine UPS logs if using uninterruptible power supply"
$report += "6. Review any recent software installations or configuration changes"
$report += ""
$report += "IMMEDIATE ACTIONS for Daily Shutdowns:"
$report += "- Set up continuous monitoring with the enhanced ServerWatch.ps1"
$report += "- Enable Memory Dump on system crash (Control Panel > System > Advanced)"
$report += "- Check Event Viewer on the server directly for more detailed logs"
$report += "- Consider enabling Boot Logging to capture startup issues"

# Display report
$reportText = $report -join "`r`n"
Write-Host $reportText

# Export if requested
if ($ExportReport) {
    $reportFile = "C:\Monitors\ShutdownDiagnostic_$($ComputerName)_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $reportText | Set-Content -Path $reportFile -Encoding UTF8
    Write-Host "`nReport exported to: $reportFile" -ForegroundColor Green
}

Write-Host "`nDiagnostic complete. Run with -ExportReport to save results to file." -ForegroundColor Green