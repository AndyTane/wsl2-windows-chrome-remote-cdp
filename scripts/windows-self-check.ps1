param(
  [int]$ChromePort = 9222,
  [int]$BridgePort = 9223,
  [string]$ChromePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
)

$ErrorActionPreference = "Continue"

function Write-Section {
  param([string]$Title)
  Write-Host ""
  Write-Host ("==== {0} ====" -f $Title)
}

function Test-HttpJson {
  param([string]$Url)
  try {
    $null = Invoke-RestMethod -Uri $Url -TimeoutSec 5
    return $true
  }
  catch {
    return $false
  }
}

function To-Status {
  param([bool]$Value)
  if ($Value) { return "OK" }
  return "MISS"
}

function To-Reachability {
  param([bool]$Value)
  if ($Value) { return "reachable" }
  return "unreachable"
}

Write-Section "Windows self-check"
Write-Host ("Current directory: {0}" -f (Get-Location))
Write-Host ("ChromePath       : {0}" -f $ChromePath)
Write-Host ("ChromePort       : {0}" -f $ChromePort)
Write-Host ("BridgePort       : {0}" -f $BridgePort)
Write-Host ""
Write-Host "Tip: run this from an existing Windows PowerShell console."
Write-Host "Recommended: copy this .ps1 file to a local Windows folder before executing it."
Write-Host "Avoid executing directly from \\wsl$ when PowerShell parsing behaves inconsistently."

$chromePathOk = $false
$chromeVersionOk = $false
$chromeListOk = $false
$portproxyOk = $false
$firewallOk = $false
$firewallRuleName = "ChromeCDP$BridgePort"

$chromePathOk = Test-Path $ChromePath
$chromeVersionOk = Test-HttpJson -Url ("http://127.0.0.1:{0}/json/version" -f $ChromePort)
$chromeListOk = Test-HttpJson -Url ("http://127.0.0.1:{0}/json/list" -f $ChromePort)

$portproxyText = ((& netsh interface portproxy show all) | Out-String)
if ($portproxyText -match ("(?m)^\s*0\.0\.0\.0\s+{0}\s+127\.0\.0\.1\s+{1}\s*$" -f $BridgePort, $ChromePort)) {
  $portproxyOk = $true
}
if ($portproxyText -match ("(?m)^\s*\*\s+{0}\s+127\.0\.0\.1\s+{1}\s*$" -f $BridgePort, $ChromePort)) {
  $portproxyOk = $true
}

$firewallText = ((& netsh advfirewall firewall show rule name=$firewallRuleName) | Out-String)
$firewallMissing = $false
if ($firewallText -match "No rules match") { $firewallMissing = $true }
if ($firewallText -match "没有与指定条件匹配的规则") { $firewallMissing = $true }
if ($firewallText -match "指定的值无效") { $firewallMissing = $true }
if ((-not $firewallMissing) -and ($firewallText -match [regex]::Escape($firewallRuleName))) {
  $firewallOk = $true
}

Write-Section "Check summary"
$rows = @(
  [pscustomobject]@{ Check = "Chrome executable path"; Status = (To-Status -Value $chromePathOk); Detail = $ChromePath },
  [pscustomobject]@{ Check = "Chrome local CDP /json/version"; Status = (To-Status -Value $chromeVersionOk); Detail = (To-Reachability -Value $chromeVersionOk) },
  [pscustomobject]@{ Check = "Chrome local CDP /json/list"; Status = (To-Status -Value $chromeListOk); Detail = (To-Reachability -Value $chromeListOk) },
  [pscustomobject]@{ Check = "portproxy bridge"; Status = (To-Status -Value $portproxyOk); Detail = ("expect 0.0.0.0:{0} -> 127.0.0.1:{1}" -f $BridgePort, $ChromePort) },
  [pscustomobject]@{ Check = "firewall rule"; Status = (To-Status -Value $firewallOk); Detail = $firewallRuleName }
)
$rows | Format-Table -AutoSize

$ready = $chromePathOk -and $chromeVersionOk -and $chromeListOk -and $portproxyOk -and $firewallOk

Write-Section "Overall result"
if ($ready) {
  Write-Host "OVERALL: READY"
  Write-Host ("Windows side looks ready for WSL to probe http://<host-ip>:{0}/json/version" -f $BridgePort)
}
else {
  Write-Host "OVERALL: NOT READY"
  Write-Host "Recommended next step:"
  Write-Host "  powershell -ExecutionPolicy Bypass -File .\setup-windows-chrome-cdp.ps1"
}

Write-Section "Useful manual checks"
Write-Host "  [Windows PowerShell]"
Write-Host "  Get-Location"
Write-Host ("  curl http://127.0.0.1:{0}/json/version" -f $ChromePort)
Write-Host ("  curl http://127.0.0.1:{0}/json/list" -f $ChromePort)
Write-Host "  netsh interface portproxy show all"
Write-Host ("  netsh advfirewall firewall show rule name='{0}'" -f $firewallRuleName)
Write-Host ""
Write-Host "If you need to keep the window open after running manually, use:"
Write-Host "  powershell -NoExit -ExecutionPolicy Bypass -File .\windows-self-check.ps1"
