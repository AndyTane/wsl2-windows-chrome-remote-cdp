param(
  [int]$ChromePort = 9222,
  [int]$BridgePort = 9223,
  [string]$ChromePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
)

$ErrorActionPreference = 'Continue'

function Write-Section {
  param([string]$Title)
  Write-Host ''
  Write-Host ('==== {0} ====' -f $Title)
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

Write-Section 'Windows self-check'
Write-Host ('Current directory: {0}' -f (Get-Location))
Write-Host ('ChromePath       : {0}' -f $ChromePath)
Write-Host ('ChromePort       : {0}' -f $ChromePort)
Write-Host ('BridgePort       : {0}' -f $BridgePort)
Write-Host ''
Write-Host 'Tip: run this from an existing Windows PowerShell console.'
Write-Host 'Do not rely on double-clicking the .ps1 file or opening it directly from \wsl$ and expecting a temporary window to stay open.'

$chromePathOk = $false
$chromeVersionOk = $false
$chromeListOk = $false
$portproxyOk = $false
$firewallOk = $false
$firewallRuleName = ('ChromeCDP{0}' -f $BridgePort)

if (Test-Path $ChromePath) { $chromePathOk = $true }
if (Test-HttpJson ("http://127.0.0.1:{0}/json/version" -f $ChromePort)) { $chromeVersionOk = $true }
if (Test-HttpJson ("http://127.0.0.1:{0}/json/list" -f $ChromePort)) { $chromeListOk = $true }

$portproxyText = ((& netsh interface portproxy show all) | Out-String)
if ($portproxyText -match ("(?m)^\s*0\.0\.0\.0\s+{0}\s+127\.0\.0\.1\s+{1}\s*$" -f $BridgePort, $ChromePort)) {
  $portproxyOk = $true
}
elseif ($portproxyText -match ("(?m)^\s*\*\s+{0}\s+127\.0\.0\.1\s+{1}\s*$" -f $BridgePort, $ChromePort)) {
  $portproxyOk = $true
}

$firewallText = ((& netsh advfirewall firewall show rule name=$firewallRuleName) | Out-String)
$firewallMissing = $false
if ($firewallText -match 'No rules match') { $firewallMissing = $true }
if ($firewallText -match '没有与指定条件匹配的规则') { $firewallMissing = $true }
if ($firewallText -match '指定的值无效') { $firewallMissing = $true }
if ((-not $firewallMissing) -and ($firewallText -match [regex]::Escape($firewallRuleName))) {
  $firewallOk = $true
}

Write-Section 'Check summary'
$rows = @(
  [pscustomobject]@{ Check = 'Chrome executable path'; Status = $(if ($chromePathOk) { 'OK' } else { 'MISS' }); Detail = $ChromePath },
  [pscustomobject]@{ Check = 'Chrome local CDP /json/version'; Status = $(if ($chromeVersionOk) { 'OK' } else { 'MISS' }); Detail = $(if ($chromeVersionOk) { 'reachable' } else { 'unreachable' }) },
  [pscustomobject]@{ Check = 'Chrome local CDP /json/list'; Status = $(if ($chromeListOk) { 'OK' } else { 'MISS' }); Detail = $(if ($chromeListOk) { 'reachable' } else { 'unreachable' }) },
  [pscustomobject]@{ Check = 'portproxy bridge'; Status = $(if ($portproxyOk) { 'OK' } else { 'MISS' }); Detail = ('expect 0.0.0.0:{0} -> 127.0.0.1:{1}' -f $BridgePort, $ChromePort) },
  [pscustomobject]@{ Check = 'firewall rule'; Status = $(if ($firewallOk) { 'OK' } else { 'MISS' }); Detail = $firewallRuleName }
)
$rows | Format-Table -AutoSize

$ready = $chromePathOk -and $chromeVersionOk -and $chromeListOk -and $portproxyOk -and $firewallOk

Write-Section 'Overall result'
if ($ready) {
  Write-Host 'OVERALL: READY'
  Write-Host ('Windows side looks ready for WSL to probe http://<host-ip>:{0}/json/version' -f $BridgePort)
}
else {
  Write-Host 'OVERALL: NOT READY'
  Write-Host 'Recommended next step:'
  Write-Host '  powershell -ExecutionPolicy Bypass -File .\scripts\setup-windows-chrome-cdp.ps1'
}

Write-Section 'Useful manual checks'
Write-Host '  [Windows PowerShell]'
Write-Host '  Get-Location'
Write-Host ('  curl http://127.0.0.1:{0}/json/version' -f $ChromePort)
Write-Host ('  curl http://127.0.0.1:{0}/json/list' -f $ChromePort)
Write-Host '  netsh interface portproxy show all'
Write-Host ("  netsh advfirewall firewall show rule name='{0}'" -f $firewallRuleName)
Write-Host ''
Write-Host 'If you need to keep the window open after running manually, use:'
Write-Host '  powershell -NoExit -ExecutionPolicy Bypass -File .\scripts\windows-self-check.ps1'
