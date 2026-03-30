param(
  [int]$ChromePort = 9222,
  [int]$BridgePort = 9223,
  [string]$ChromePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe',
  [switch]$DryRun
)

$ErrorActionPreference = 'Continue'
$RuleName = 'ChromeCDP' + $BridgePort

Write-Host ''
Write-Host '==== Windows setup for Chrome CDP (minimal) ===='
Write-Host ('ChromePath  : ' + $ChromePath)
Write-Host ('ChromePort  : ' + $ChromePort)
Write-Host ('BridgePort  : ' + $BridgePort)
Write-Host ('RuleName    : ' + $RuleName)
Write-Host ('DryRun      : ' + $DryRun)
Write-Host ''

if (-not (Test-Path $ChromePath)) {
  Write-Host 'ERROR: Chrome executable not found.'
  Write-Host ('Expected path: ' + $ChromePath)
  exit 1
}

if ($DryRun) {
  Write-Host 'DRY RUN - no changes will be made.'
  Write-Host ('Would start Chrome with: ' + $ChromePath + ' --remote-debugging-port=' + $ChromePort)
  Write-Host ('Would run: netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=' + $BridgePort)
  Write-Host ('Would run: netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=' + $BridgePort + ' connectaddress=127.0.0.1 connectport=' + $ChromePort)
  Write-Host ('Would run: netsh advfirewall firewall delete rule name=' + $RuleName)
  Write-Host ('Would run: netsh advfirewall firewall add rule name=' + $RuleName + ' dir=in action=allow protocol=TCP localport=' + $BridgePort)
  exit 0
}

Write-Host 'Starting Chrome with remote debugging...'
Start-Process -FilePath $ChromePath -ArgumentList ('--remote-debugging-port=' + $ChromePort) | Out-Null
Start-Sleep -Seconds 2

try {
  $uri = 'http://127.0.0.1:' + $ChromePort + '/json/version'
  $null = Invoke-RestMethod -Uri $uri -TimeoutSec 5
  Write-Host 'OK - Chrome local CDP /json/version'
} catch {
  Write-Host 'MISS - Chrome local CDP /json/version after start'
}

Write-Host 'Resetting portproxy rule...'
& netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=$BridgePort | Out-Null
& netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=$BridgePort connectaddress=127.0.0.1 connectport=$ChromePort | Out-Null

Write-Host 'Resetting firewall rule...'
& netsh advfirewall firewall delete rule name=$RuleName | Out-Null
& netsh advfirewall firewall add rule name=$RuleName dir=in action=allow protocol=TCP localport=$BridgePort | Out-Null

Write-Host ''
Write-Host 'Current portproxy:'
& netsh interface portproxy show all
Write-Host ''
Write-Host 'Current firewall rule:'
& netsh advfirewall firewall show rule name=$RuleName
Write-Host ''
Write-Host 'Done.'
Write-Host 'Now verify from WSL with:'
Write-Host ('  curl --connect-timeout 3 --max-time 5 http://<WSL_HOST_GATEWAY>:' + $BridgePort + '/json/version')
