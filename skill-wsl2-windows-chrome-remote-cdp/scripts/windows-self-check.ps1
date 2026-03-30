# Windows self-check script for Chrome CDP setup
param(
  [int]$ChromePort = 9222,
  [int]$BridgePort = 9223,
  [string]$ChromePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
)

$ErrorActionPreference = 'Continue'
$RuleName = 'ChromeCDP' + $BridgePort

Write-Host ""
Write-Host "==== Windows self-check (minimal) ===="
Write-Host "ChromePath  : $ChromePath"
Write-Host "ChromePort  : $ChromePort"
Write-Host "BridgePort  : $BridgePort"
Write-Host "RuleName    : $RuleName"
Write-Host ""
Write-Host "Run this from an existing Windows PowerShell console."
Write-Host "Recommended: copy this .ps1 file to a local Windows folder before executing it."
Write-Host ""

$ChromePathOk = Test-Path $ChromePath
if ($ChromePathOk) {
  Write-Host "OK - Chrome executable path"
} else {
  Write-Host "MISS - Chrome executable path"
}

try {
  $uri = "http://127.0.0.1:$ChromePort/json/version"
  $null = Invoke-RestMethod -Uri $uri -TimeoutSec 5
  Write-Host "OK - Chrome local CDP /json/version"
  $ChromeVersionOk = $true
} catch {
  Write-Host "MISS - Chrome local CDP /json/version"
  $ChromeVersionOk = $false
}

try {
  $uri = "http://127.0.0.1:$ChromePort/json/list"
  $null = Invoke-RestMethod -Uri $uri -TimeoutSec 5
  Write-Host "OK - Chrome local CDP /json/list"
  $ChromeListOk = $true
} catch {
  Write-Host "MISS - Chrome local CDP /json/list"
  $ChromeListOk = $false
}

$PortproxyText = (& netsh interface portproxy show all | Out-String)
$PortproxyOk = $false
if ($PortproxyText -match '127.0.0.1') {
  if ($PortproxyText -match $BridgePort) {
    if ($PortproxyText -match $ChromePort) {
      $PortproxyOk = $true
    }
  }
}
if ($PortproxyOk) {
  Write-Host "OK - portproxy bridge"
} else {
  Write-Host "MISS - portproxy bridge"
}

$FirewallText = (& netsh advfirewall firewall show rule name=$RuleName 2>&1 | Out-String)
$FirewallOk = $false
if ($FirewallText -like "*$RuleName*" -and $FirewallText -notlike "*No rules match*" -and $FirewallText -notlike "*没有与指定条件匹配的规则*" -and $FirewallText -notlike "*指定的值无效*") {
  $FirewallOk = $true
}
if ($FirewallOk) {
  Write-Host "OK - firewall rule"
} else {
  Write-Host "MISS - firewall rule"
}

Write-Host ""
$AllOk = $ChromePathOk -and $ChromeVersionOk -and $ChromeListOk -and $PortproxyOk -and $FirewallOk
if ($AllOk) {
  Write-Host "OVERALL: READY"
} else {
  Write-Host "OVERALL: NOT READY"
  Write-Host "Recommended next step:"
  Write-Host "  powershell -ExecutionPolicy Bypass -File .\setup-windows-chrome-cdp.ps1"
}

Write-Host ""
Write-Host "Useful manual checks:"
Write-Host "  Test-Path '$ChromePath'"
Write-Host "  curl http://127.0.0.1:$ChromePort/json/version"
Write-Host "  curl http://127.0.0.1:$ChromePort/json/list"
Write-Host "  netsh interface portproxy show all"
Write-Host "  netsh advfirewall firewall show rule name=$RuleName"
Write-Host ""
Write-Host "If needed, keep the window open with:"
Write-Host "  powershell -NoExit -ExecutionPolicy Bypass -File .\windows-self-check.ps1"
Write-Host ""
