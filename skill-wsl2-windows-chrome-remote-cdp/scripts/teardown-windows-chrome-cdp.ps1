param(
  [int]$BridgePort = 9223,
  [switch]$DryRun
)

$ErrorActionPreference = 'Continue'
$RuleName = 'ChromeCDP' + $BridgePort

Write-Host ''
Write-Host '==== Windows teardown for Chrome CDP bridge (minimal) ===='
Write-Host ('BridgePort  : ' + $BridgePort)
Write-Host ('RuleName    : ' + $RuleName)
Write-Host ('DryRun      : ' + $DryRun)
Write-Host ''

if ($DryRun) {
  Write-Host 'DRY RUN - no changes will be made.'
  Write-Host ('Would run: netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=' + $BridgePort)
  Write-Host ('Would run: netsh advfirewall firewall delete rule name=' + $RuleName)
  exit 0
}

Write-Host 'Removing portproxy rule...'
& netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=$BridgePort | Out-Null

Write-Host 'Removing firewall rule...'
& netsh advfirewall firewall delete rule name=$RuleName | Out-Null

Write-Host ''
Write-Host 'Remaining portproxy:'
& netsh interface portproxy show all
Write-Host ''
Write-Host 'Done.'
