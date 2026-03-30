param(
  [int]$ChromePort = 9222,
  [int]$BridgePort = 9223,
  [string]$ChromePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
)

$ErrorActionPreference = 'SilentlyContinue'

function Test-HttpJson($url) {
  try {
    $resp = Invoke-RestMethod -Uri $url -TimeoutSec 5
    return @{ ok = $true; data = $resp }
  } catch {
    return @{ ok = $false; error = $_.Exception.Message }
  }
}

Write-Host "Current directory: $(Get-Location)"
Write-Host "ChromePath       : $ChromePath"
Write-Host "ChromePort       : $ChromePort"
Write-Host "BridgePort       : $BridgePort"
Write-Host ""

$results = @()

$chromePathOk = Test-Path $ChromePath
$results += [pscustomobject]@{ Check = 'Chrome executable path'; Status = $(if ($chromePathOk) { 'OK' } else { 'MISS' }); Detail = $ChromePath }

$chromeJson = Test-HttpJson "http://127.0.0.1:$ChromePort/json/version"
$results += [pscustomobject]@{ Check = 'Chrome local CDP /json/version'; Status = $(if ($chromeJson.ok) { 'OK' } else { 'MISS' }); Detail = $(if ($chromeJson.ok) { 'reachable' } else { $chromeJson.error }) }

$chromeList = Test-HttpJson "http://127.0.0.1:$ChromePort/json/list"
$results += [pscustomobject]@{ Check = 'Chrome local CDP /json/list'; Status = $(if ($chromeList.ok) { 'OK' } else { 'MISS' }); Detail = $(if ($chromeList.ok) { 'reachable' } else { $chromeList.error }) }

$portproxyOut = cmd /c "netsh interface portproxy show all"
$portproxyOk = ($portproxyOut | Select-String -Pattern ":$BridgePort" -SimpleMatch) -ne $null -or ($portproxyOut -match "\b$BridgePort\b")
$results += [pscustomobject]@{ Check = 'portproxy bridge'; Status = $(if ($portproxyOk) { 'OK' } else { 'MISS' }); Detail = "expect 0.0.0.0:$BridgePort -> 127.0.0.1:$ChromePort" }

$firewallOut = cmd /c "netsh advfirewall firewall show rule name=\"ChromeCDP$BridgePort\""
$firewallOk = ($firewallOut -match "Rule Name:") -or ($firewallOut -match "No rules match") -eq $false
$results += [pscustomobject]@{ Check = 'firewall rule'; Status = $(if ($firewallOk) { 'OK' } else { 'MISS' }); Detail = "ChromeCDP$BridgePort" }

$ready = $chromePathOk -and $chromeJson.ok -and $chromeList.ok -and $portproxyOk -and $firewallOk

$results | Format-Table -AutoSize

Write-Host ""
if ($ready) {
  Write-Host "OVERALL: READY"
  Write-Host "Windows side looks ready for WSL to probe http://<host-ip>:$BridgePort/json/version"
} else {
  Write-Host "OVERALL: NOT READY"
  Write-Host "Recommended next step:"
  Write-Host "  powershell -ExecutionPolicy Bypass -File .\scripts\setup-windows-chrome-cdp.ps1"
}

Write-Host ""
Write-Host "Useful manual checks:"
Write-Host "  Get-Location"
Write-Host "  curl http://127.0.0.1:$ChromePort/json/version"
Write-Host "  curl http://127.0.0.1:$ChromePort/json/list"
Write-Host "  netsh interface portproxy show all"
Write-Host "  netsh advfirewall firewall show rule name=\"ChromeCDP$BridgePort\""
