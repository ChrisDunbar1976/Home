# Windows Server Diagnostics Guide

*How to investigate why a Windows server is failing or shutting down unexpectedly*

---

## 1. Event Log Analysis (Most Important)

### Critical Shutdown Events
```powershell
# Shutdown/restart events with reasons
Get-WinEvent -FilterHashtable @{LogName='System'; ID=1074,1076} -MaxEvents 20 | 
  Select TimeCreated, Id, LevelDisplayName, Message | Format-List

# Unexpected shutdowns (power loss, crash)
Get-WinEvent -FilterHashtable @{LogName='System'; ID=6008,6009,41} -MaxEvents 10 | 
  Select TimeCreated, Message | Format-List

# Blue screen/crash dumps
Get-WinEvent -FilterHashtable @{LogName='System'; ID=1001,1003} -MaxEvents 10
```

### Application/Service Crashes
```powershell
# Critical application errors
Get-WinEvent -FilterHashtable @{LogName='Application'; Level=1,2} -MaxEvents 50 | 
  Where-Object {$_.TimeCreated -gt (Get-Date).AddDays(-2)} | 
  Group-Object Id | Sort Count -Descending

# SQL Server specific errors
Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='MSSQLSERVER'} -MaxEvents 30 | 
  Where-Object {$_.LevelDisplayName -eq 'Error'}
```

---

## 2. Hardware Health Checks

### Memory Diagnostics
```powershell
# Check for memory errors
Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-MemoryDiagnostics-Results'} -MaxEvents 10

# Schedule memory test (requires reboot)
mdsched.exe
```

### Disk Health
```powershell
# Check disk errors
Get-WinEvent -FilterHashtable @{LogName='System'; ID=7,11,51} -MaxEvents 20

# SMART status
Get-PhysicalDisk | Get-StorageReliabilityCounter | Format-Table DeviceId, Temperature, PowerOnHours, UnsafeShutdownCount

# Disk space and health
Get-Volume | Where-Object {$_.DriveType -eq 'Fixed'} | Select DriveLetter, FileSystem, Size, SizeRemaining, HealthStatus
```

---

## 3. Temperature/Power Issues

### System Temperature Events
```powershell
# Overheating warnings
Get-WinEvent -FilterHashtable @{LogName='System'; ID=6008,37,6006} | 
  Where-Object {$_.Message -like "*temperature*" -or $_.Message -like "*thermal*"}

# Check WMI temperature (if available)
Get-CimInstance -ClassName Win32_Temperature -ErrorAction SilentlyContinue
```

### Power Events
```powershell
# Power-related shutdowns
Get-WinEvent -FilterHashtable @{LogName='System'; ID=42,6005,6006,6008} -MaxEvents 20
```

---

## 4. Running Processes/Services

### Resource-Heavy Processes
```powershell
# Top CPU/Memory consumers
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name, CPU, WorkingSet, PagedMemorySize

# Services that stopped unexpectedly
Get-EventLog -LogName System -EntryType Error | Where-Object {$_.Source -eq 'Service Control Manager'} | Select-Object -First 10
```

---

## 5. Windows Updates/Driver Issues

### Recent Updates
```powershell
# Recent Windows updates
Get-HotFix | Where-Object {$_.InstalledOn -gt (Get-Date).AddDays(-14)} | Sort InstalledOn -Descending

# Update-related errors
Get-WinEvent -FilterHashtable @{LogName='System'; ID=19,20,43} -MaxEvents 20
```

---

## 6. Network/External Factors

### Network Issues
```powershell
# Network adapter problems
Get-WinEvent -FilterHashtable @{LogName='System'; ID=4202,4207} -MaxEvents 10

# DNS resolution issues
nslookup your-domain-controller
```

---

## 7. Comprehensive Diagnostic Tools

### Reliability Monitor
```powershell
# Open Reliability Monitor GUI
perfmon.exe /rel
```

### System File Checker
```powershell
# Check for corrupted system files
sfc /scannow
DISM /Online /Cleanup-Image /CheckHealth
```

---

## Most Likely Culprits for Daily Shutdowns

1. **Scheduled tasks/Group Policy** forcing reboots
2. **Windows Updates** with automatic restart
3. **Hardware overheating** 
4. **Memory failures**
5. **Power supply issues**
6. **SQL Server memory pressure** causing system instability
7. **Third-party software** with scheduled maintenance

---

## Key Event IDs to Monitor

| Event ID | Log | Description |
|----------|-----|-------------|
| 1074 | System | System shutdown initiated by process |
| 1076 | System | System shutdown reason |
| 6005 | System | System startup |
| 6006 | System | System shutdown |
| 6008 | System | Unexpected system shutdown |
| 6009 | System | System startup after unexpected shutdown |
| 41 | System | System rebooted without cleanly shutting down |
| 1001 | System | Bug check (Blue Screen) |
| 1003 | System | Bug check recovery |

---

## Quick Investigation Steps

1. **Start with Event ID 1074** - This will tell you exactly what process initiated the shutdown and why
2. **Check for Event ID 6008 or 41** - These indicate unexpected shutdowns (crashes, power loss)
3. **Look for patterns** - Same time of day, same day of week, after specific events
4. **Check hardware health** - Memory, disks, temperature
5. **Review recent changes** - Updates, new software, configuration changes

---

*This guide provides the essential PowerShell commands and strategies for diagnosing Windows server shutdown issues. Focus on Event Log analysis first, as it typically provides the most direct answers.*