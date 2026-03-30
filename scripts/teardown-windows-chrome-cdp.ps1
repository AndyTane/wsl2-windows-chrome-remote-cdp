param(
  [int]$BridgePort = 9223
)

$ErrorActionPreference = 'Stop'

Write-Host "Removing portproxy for $BridgePort..."
cmd /c "netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=$BridgePort"

Write-Host "Removing firewall rule ChromeCDP$BridgePort..."
cmd /c "netsh advfirewall firewall delete rule name=\"ChromeCDP$BridgePort\""

Write-Host "Remaining portproxy:"
cmd /c "netsh interface portproxy show all"

Write-Host "Done."
