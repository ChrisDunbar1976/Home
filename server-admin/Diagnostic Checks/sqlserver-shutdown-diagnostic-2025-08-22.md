# SQL Server Shutdown Diagnostic - 2025-08-22

## Investigation Summary

**Server**: MLNOESQLEXP01\SQLEXPRESS  
**Investigation Date**: 2025-08-22  
**Issue**: Unexpected server shutdown around 12:00 UTC  

## Timeline Analysis

### Actual Timeline (Corrected)
- **Last shutdown**: 10:49:36 UTC (2025-08-22) - Process ID 4796
- **Restart**: 11:14:12 UTC (2025-08-22) - Process ID 7380  
- **Downtime**: ~25 minutes
- **Previous uptime**: Since 21/08/2025 20:18:02 UTC (~14.5 hours)

## SQL Server Analysis Results

### Connection Test
```sql
SELECT @@SERVERNAME AS ServerName, GETDATE() AS CurrentTime
-- Result: MLNOESQLEXP01\SQLEXPRESS, 2025-08-22 16:29:39.423
```

### Startup Information
```sql
-- SQL Server startup time confirmed at 11:14:12 UTC
-- Previous instance PID 4796 last reported at 10:49:36 UTC
```

### System Information
- **Platform**: VMware Virtual Platform (VM)
- **SQL Version**: Microsoft SQL Server 2022 (RTM-CU20-GDR) KB5063814 - 16.0.4210.1
- **OS**: Windows Server 2019 Datacenter 10.0 Build 17763 (Hypervisor)
- **Memory**: 46079 MB RAM, 39238 MB available
- **CPUs**: 4 logical processors

### Database Recovery Status
All databases came online successfully:
- DAS
- Vehicles  
- Curtailments
- SDG
- Callover
- Purchasing

## Key Findings

### ✅ Positive Indicators
- Normal SQL Server startup sequence
- No crash indicators or error messages
- All databases recovered successfully
- Clean shutdown (no forced termination logged)
- Proper parallel redo completion for all databases

### ❓ Missing Information
- **No SQL-level shutdown reason found** - SQL Server doesn't log external shutdown causes
- Error logs don't contain shutdown initiation details
- Previous error log archive doesn't show shutdown events

## Root Cause Analysis

SQL Server shutdown appears to be **external** (not SQL Server initiated). Likely causes:
1. **Windows system shutdown** (scheduled or manual)
2. **VM host maintenance** or resource management
3. **Windows Updates** with automatic restart
4. **Scheduled tasks/Group Policy** forcing reboot
5. **Hardware/infrastructure maintenance**

## Recommendations

### Immediate Actions
1. **Check Windows Event Logs** using the PowerShell script:
   ```powershell
   # Run on MLNOESQLEXP01 around 10:49:36 UTC
   Get-WinEvent -FilterHashtable @{
       LogName='System'
       ID=1074,1076,6005,6006,6008,6009,41
       StartTime=(Get-Date "2025-08-22 10:40")
       EndTime=(Get-Date "2025-08-22 11:00")
   } | Select-Object TimeCreated, Id, Message | Sort-Object TimeCreated -Descending
   ```

2. **Check VMware vSphere logs** for VM-level events around 10:49 UTC

3. **Review Windows Update history** for scheduled installations

### Long-term Monitoring
1. Set up **Windows Event Log monitoring** for shutdown events (1074, 1076)
2. Configure **SQL Server startup/shutdown alerts**
3. Implement **VM-level monitoring** for unexpected state changes

## Investigation Tools Used
- SQL Server Error Log Analysis (`xp_readerrorlog`)
- System Information Queries (`sys.dm_os_sys_info`)
- Process ID tracking and startup time verification

## Next Steps
Run Windows Event Log analysis on MLNOESQLEXP01 to determine the exact shutdown reason and initiating process around 10:49:36 UTC on 2025-08-22.

---
*Diagnostic completed: 2025-08-22 16:30 UTC*