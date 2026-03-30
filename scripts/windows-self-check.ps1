param(
  [int]$ChromePort = 9222,
  [int]$BridgePort = 9223,
  [string]$ChromePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
)

$ErrorActionPreference = 'Continue'

function Section($title) {
  Write-Host ''
  Write-Host ('==== ' + $title + ' ====')
}

function TestHttp($url) {
  try {
    $null = Invoke-RestMethod -Uri $url -TimeoutSec 5
    return $true
  }
  catch {
    return $false
  }
}

function StatusText($v) {
  if ($v) { return 'OK' }
  return 'MISS'
}

function ReachText($v) {
  if ($v) { return 'reachable' }
  return 'unreachable'
}

Section 'Windows self-check'
Write-Host ('Current directory: ' + (Get-Location))
Write-Host ('ChromePath       : ' + $ChromePath)
Write-Host ('ChromePort       : ' + $ChromePort)
Write-Host ('BridgePort       : ' + $BridgePort)
Write-Host ''
Write-Host 'Tip: run this from an existing Windows PowerShell console.'
Write-Host 'Recommended: copy this .ps1 file to a local Windows folder before executing it.'
Write-Host 'Avoid executing directly from \wsl$ when PowerShell parsing behaves inconsistently.'

$chromePathOk = Test-Path $ChromePath
$chromeVersionOk = TestHttp ('http://127.0.0.1:' + $ChromePort + '/json/version')
$chromeListOk = TestHttp ('http://127.0.0.1:' + $ChromePort + '/json/list')
$portproxyOk = $false
$firewallOk = $false
$firewallRuleName = 'ChromeCDP' + $BridgePort

$portproxyText = (& netsh interface portproxy show all | Out-String)
if ($portproxyText -match '0\.0\.0\.0') {
  if ($portproxyText -match [regex]::Escape([string]$BridgePort)) {
    if ($portproxyText -match '127\.0\.0\.1') {
      if ($portproxyText -match [regex]::Escape([string]$ChromePort)) {
        $portproxyOk = $true
      }
    }
  }
}
if (-not $portproxyOk) {
  if ($portproxyText -match '^\s*\*' -or $portproxyText -match '\s\*\s') {
    if ($portproxyText -match [regex]::Escape([string]$BridgePort)) {
      if ($portproxyText -match '127\.0\.0\.1') {
        if ($portproxyText -match [regex]::Escape([string]$ChromePort)) {
          $portproxyOk = $true
        }
      }
    }
  }
}

$firewallText = (& netsh advfirewall firewall show rule name=$firewallRuleName | Out-String)
$firewallMissing = $false
if ($firewallText -match 'No rules match') { $firewallMissing = $true }
if ($firewallText -match '没有与指定条件匹配的规则') { $firewallMissing = $true }
if ($firewallText -match '指定的值无效') { $firewallMissing = $true }
if (-not $firewallMissing) {
  if ($firewallText -match [regex]::Escape($firewallRuleName)) {
    $firewallOk = $true
  }
}

Section 'Check summary'
$rows = @()
$rows += [pscustomobject]@{ Check = 'Chrome executable path'; Status = (StatusText $chromePathOk); Detail = $ChromePath }
$rows += [pscustomobject]@{ Check = 'Chrome local CDP /json/version'; Status = (StatusText $chromeVersionOk); Detail = (ReachText $chromeVersionOk) }
$rows += [pscustomobject]@{ Check = 'Chrome local CDP /json/list'; Status = (StatusText $chromeListOk); Detail = (ReachText $chromeListOk) }
$rows += [pscustomobject]@{ Check = 'portproxy bridge'; Status = (StatusText $portproxyOk); Detail = ('expect 0.0.0.0:' + $BridgePort + ' -> 127.0.0.1:' + $ChromePort) }
$rows += [pscustomobject]@{ Check = 'firewall rule'; Status = (StatusText $firewallOk); Detail = $firewallRuleName }
$rows | Format-Table -AutoSize

$ready = $chromePathOk -and $chromeVersionOk -and $chromeListOk -and $portproxyOk -and $firewallOk

Section 'Overall result'
if ($ready) {
  Write-Host 'OVERALL: READY'
  Write-Host ('Windows side looks ready for WSL to probe http://<host-ip>:' + $BridgePort + '/json/version')
}
else {
  Write-Host 'OVERALL: NOT READY'
  Write-Host 'Recommended next step:'
  Write-Host '  powershell -ExecutionPolicy Bypass -File .\setup-windows-chrome-cdp.ps1'
}

Section 'Useful manual checks'
Write-Host '  [Windows PowerShell]'
Write-Host '  Get-Location'
Write-Host ('  curl http://127.0.0.1:' + $ChromePort + '/json/version')
Write-Host ('  curl http://127.0.0.1:' + $ChromePort + '/json/list')
Write-Host '  netsh interface portproxy show all'
Write-Host ("  netsh advfirewall firewall show rule name='" + $firewallRuleName + "'")
Write-Host ''
Write-Host 'If you need to keep the window open after running manually, use:'
Write-Host '  powershell -NoExit -ExecutionPolicy Bypass -File .\windows-self-check.ps1'
