<# ServerWatch.ps1 — Teams-only (remote watcher)
   Checks MLNOESQLEXP01 (ping + TCP ports). Alerts to Teams via Incoming Webhook.
#>

# ======================= CONFIG =======================
$Config = @{
  TargetName      = "MLNOESQLEXP01"
  Host            = "MLNOESQLEXP01"
  Ports           = @(1433)               # add more if needed: @(1433,3389,443)
  FailAfter       = 3				#3
  CooldownMinutes = 5			#5

  TeamsWebhook    = "https://metrolinecouk.webhook.office.com/webhookb2/0dedf7e5-1854-4d15-a926-d30e42617e13@84f4da41-c996-4f9e-8dd9-8a01a28b7ecc/IncomingWebhook/de4a039b600e4de5a0d68cdbf156122d/27d81ee9-45de-40d3-9c49-198379a0f0d6/V2wfK9It1SybtqGjvkkbGDENuC7Be25jKVosrslyI-NU41"

  PingTimeoutMs   = 1500
  TcpTimeoutMs    = 1500
  PerCheckDelayMs = 200

# --- BOX AVAILABILITY SETTINGS ---
RequirePing      = $true                    # try ping first (set $false if you never want ping)
ReachabilityPorts = @(3389, 445, 135)       # neutral OS ports to prove host is up
# Leave SQL ports empty since SQL health is handled elsewhere
Ports            = @()                      # <-- no SQL port checks here


  StateFile       = "C:\ProgramData\ServerWatch\state.json"   # moved here
}
# Ensure state directory exists
$stateDir = Split-Path $Config.StateFile
if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }

# ======================= HELPERS =======================
function Test-HostUp {
  param([string]$HostName,[int]$TimeoutMs)
  try { (New-Object Net.NetworkInformation.Ping).Send($HostName,$TimeoutMs).Status -eq 'Success' } catch { $false }
}

function Test-TcpPort {
  param([string]$HostName,[int]$PortNumber,[int]$TimeoutMs)
  try {
    $c = New-Object Net.Sockets.TcpClient
    $iar = $c.BeginConnect($HostName,$PortNumber,$null,$null)
    if (-not $iar.AsyncWaitHandle.WaitOne($TimeoutMs)) { $c.Close(); return $false }
    $c.EndConnect($iar); $c.Close(); $true
  } catch { $false }
}

function TeamsPost {
  param([string]$Title,[string]$Text,[string]$Color="E81123")
  $payload = @{
    "@type"="MessageCard"; "@context"="http://schema.org/extensions"
    summary=$Title; title=$Title; themeColor=$Color; text=$Text
  } | ConvertTo-Json -Depth 4
  try { Invoke-RestMethod -Method Post -Uri $Config.TeamsWebhook -ContentType "application/json" -Body $payload | Out-Null } catch {}
}

# ======================= STATE ========================
# Load state (coerce to hashtable and ensure required keys)
$state = $null
if (Test-Path $Config.StateFile) {
  try { $raw = Get-Content $Config.StateFile -Raw; if ($raw) { $state = $raw | ConvertFrom-Json } } catch { $state = $null }
}
if ($state -isnot [hashtable]) { $state = @{} }
foreach ($k in @('FailStreak','LastStatus','LastAlert')) {
  if (-not $state.ContainsKey($k)) { $state[$k] = $null }
}
if ($null -eq $state['FailStreak']) { $state['FailStreak'] = 0 }
if ([string]::IsNullOrEmpty($state['LastStatus'])) { $state['LastStatus'] = 'Unknown' }
if ([string]::IsNullOrEmpty($state['LastAlert']))  { $state['LastAlert']  = '2000-01-01T00:00:00Z' }

# ======================= CHECK ========================
$isUp = Test-HostUp -HostName $Config.Host -TimeoutMs $Config.PingTimeoutMs
Start-Sleep -Milliseconds $Config.PerCheckDelayMs

$details = @()
if ($isUp -and $Config.Ports.Count -gt 0) {
  foreach ($p in $Config.Ports) {
    $ok = Test-TcpPort -HostName $Config.Host -PortNumber $p -TimeoutMs $Config.TcpTimeoutMs
    $details += "Port ${p}: " + ($(if ($ok) { "open" } else { "closed" }))
    if (-not $ok) { $isUp = $false }
    Start-Sleep -Milliseconds $Config.PerCheckDelayMs
  }
}

# ===================== DECIDE / ALERT =================
$nowUtc         = [datetime]::UtcNow
$cooldownCutoff = $nowUtc.AddMinutes(-$Config.CooldownMinutes)

if ($isUp) {
  if ($state['LastStatus'] -eq 'Down') {
    TeamsPost "[RECOVERED] $($Config.TargetName) reachable" ("Host: {0}`nStatus: UP`n{1}`nUTC: {2}" -f $Config.Host, ($details -join "`n"), $nowUtc.ToString('o')) "16A34A"
  }
  $state['FailStreak'] = 0
  $state['LastStatus'] = 'Up'
}
else {
  $state['FailStreak'] = [int]$state['FailStreak'] + 1
  $state['LastStatus'] = 'Down'
  if ($state['FailStreak'] -ge $Config.FailAfter) {
    $lastAlertUtc = [datetime]::Parse($state['LastAlert'])
    if ($lastAlertUtc -lt $cooldownCutoff) {
      $body = @"
Host: $($Config.Host)
Checks: Ping + Ports ($($Config.Ports -join ', '))
Observed: $($details -join '; ')
Consecutive failures: $($state['FailStreak']) (threshold $($Config.FailAfter))
UTC: $($nowUtc.ToString('o'))
"@
      TeamsPost "[ALERT] $($Config.TargetName) appears DOWN" $body "E81123"
      $state['LastAlert'] = $nowUtc.ToString('o')
    }
  }
}

# ======================= SAVE ========================
try {
  ($state | ConvertTo-Json -Depth 5) | Set-Content -Path $Config.StateFile -Encoding UTF8 -Force
} catch {
  # As a fallback, try the Monitors folder
  try { ($state | ConvertTo-Json -Depth 5) | Set-Content -Path "C:\Monitors\ServerWatch.state.json" -Encoding UTF8 -Force } catch {}
}
