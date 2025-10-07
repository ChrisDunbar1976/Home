# ServerWatch.ps1 Version 1.1 Change Log

## Version Information
- **Version:** 1.1
- **Date:** 2025-01-07
- **Modified By:** Claude Code
- **Reason:** Fix orphaned RECOVERED alerts issue

## Problem Description
The script was sending RECOVERED alerts without corresponding DOWN alerts. This occurred because:
- RECOVERED alerts were sent based solely on status transition (`Down` → `Up`)
- DOWN alerts had additional conditions (failure threshold, cooldown) that could prevent them from being sent
- This resulted in users receiving RECOVERED alerts without prior DOWN notification

## Changes Made

### 1. Added DownAlertSent State Tracking
**From:**
```powershell
foreach ($k in @('FailStreak','LastStatus','LastAlert')) {
  if (-not $state.ContainsKey($k)) { $state[$k] = $null }
}
```

**To:**
```powershell
foreach ($k in @('FailStreak','LastStatus','LastAlert','DownAlertSent')) {
  if (-not $state.ContainsKey($k)) { $state[$k] = $null }
}
```

### 2. Initialize DownAlertSent Flag
**From:**
```powershell
if ($null -eq $state['FailStreak']) { $state['FailStreak'] = 0 }
if ([string]::IsNullOrEmpty($state['LastStatus'])) { $state['LastStatus'] = 'Unknown' }
if ([string]::IsNullOrEmpty($state['LastAlert']))  { $state['LastAlert']  = '2000-01-01T00:00:00Z' }
```

**To:**
```powershell
if ($null -eq $state['FailStreak']) { $state['FailStreak'] = 0 }
if ([string]::IsNullOrEmpty($state['LastStatus'])) { $state['LastStatus'] = 'Unknown' }
if ([string]::IsNullOrEmpty($state['LastAlert']))  { $state['LastAlert']  = '2000-01-01T00:00:00Z' }
if ($null -eq $state['DownAlertSent']) { $state['DownAlertSent'] = $false }
```

### 3. Modified RECOVERED Alert Logic
**From:**
```powershell
if ($isUp) {
  if ($state['LastStatus'] -eq 'Down') {
    TeamsPost "[RECOVERED] $($Config.TargetName) reachable" ("Host: {0}`nStatus: UP`n{1}`nUTC: {2}" -f $Config.Host, ($details -join "`n"), $nowUtc.ToString('o')) "16A34A"
    $state['LastAlert'] = '2000-01-01T00:00:00Z'  # Reset alert cooldown for future DOWN alerts
  }
  $state['FailStreak'] = 0
  $state['LastStatus'] = 'Up'
}
```

**To:**
```powershell
if ($isUp) {
  if ($state['LastStatus'] -eq 'Down' -and $state['DownAlertSent']) {
    TeamsPost "[RECOVERED] $($Config.TargetName) reachable" ("Host: {0}`nStatus: UP`n{1}`nUTC: {2}" -f $Config.Host, ($details -join "`n"), $nowUtc.ToString('o')) "16A34A"
    $state['DownAlertSent'] = $false  # Reset only the alert sent flag
  }
  $state['FailStreak'] = 0
  $state['LastStatus'] = 'Up'
}
```

### 4. Set DownAlertSent Flag When Sending DOWN Alerts
**From:**
```powershell
      TeamsPost "[ALERT] $($Config.TargetName) appears DOWN" $body "E81123"
      $state['LastAlert'] = $nowUtc.ToString('o')
```

**To:**
```powershell
      TeamsPost "[ALERT] $($Config.TargetName) appears DOWN" $body "E81123"
      $state['LastAlert'] = $nowUtc.ToString('o')
      $state['DownAlertSent'] = $true
```

## Impact
- **Fixes:** Orphaned RECOVERED alerts without corresponding DOWN alerts
- **Preserves:** All existing functionality including cooldown logic and failure thresholds
- **Improves:** Alert reliability and reduces confusion for monitoring recipients

## Testing Recommendations
1. Test normal DOWN → RECOVERED cycle
2. Test partial failures that don't meet threshold
3. Verify cooldown logic still works correctly
4. Check state file persistence across script runs