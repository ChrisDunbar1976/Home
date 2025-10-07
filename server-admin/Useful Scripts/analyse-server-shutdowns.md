# Server Shutdown Analysis Script

## PowerShell Query for Today's Shutdown Events

This script queries Windows Event Log for all shutdown/restart events that occurred today only, filtering out noise from other events.

```powershell
# Get all shutdown/restart events for today only
$Today = Get-Date -Format "yyyy-MM-dd"
Get-WinEvent -FilterHashtable @{
    LogName='System'
    ID=1074,1076,6005,6006,6008,6009,41
    StartTime=(Get-Date $Today)
    EndTime=(Get-Date $Today).AddDays(1)
} -ErrorAction SilentlyContinue | 
Select-Object TimeCreated, Id, LevelDisplayName, @{Name='Event';Expression={
    switch($_.Id) {
        1074 {'System shutdown initiated'}
        1076 {'System shutdown reason'}
        6005 {'System startup'}
        6006 {'System shutdown'}
        6008 {'Unexpected shutdown'}
        6009 {'Startup after unexpected shutdown'}
        41 {'System rebooted without clean shutdown'}
    }
}}, Message | 
Sort-Object TimeCreated -Descending | Format-Table -AutoSize
```

## Event ID Reference

| Event ID | Description |
|----------|-------------|
| 1074 | System shutdown initiated by process |
| 1076 | System shutdown reason |
| 6005 | System startup |
| 6006 | System shutdown |
| 6008 | Unexpected system shutdown |
| 6009 | System startup after unexpected shutdown |
| 41 | System rebooted without clean shutdown |

## Usage

1. Open PowerShell as Administrator
2. Copy and paste the script above
3. Press Enter to execute
4. Results will show chronologically (newest first) for today only

## Performance Monitor Setup for Shutdown Monitoring

1. Run `perfmon.msc`
2. Expand **Data Collector Sets** → **User Defined**
3. Right-click → **New** → **Data Collector Set**
4. Name it "Shutdown Monitor" → **Create manually** → **Next**
5. Select **Performance Counter Alert** → **Next**
6. Click **Add** and add these counters:
   - **System\System Up Time** (tracks uptime)
   - **System\Processes** (monitor for sudden drops)
   - **System\Context Switches/sec** (activity indicator)
7. Set **Alert when** value is **Below** threshold (e.g., System Up Time below 3600 for recent restarts)
8. **Next** → **Finish**