param(
  [int]$ChromePort = 9222,
  [int]$BridgePort = 9223,
  [string]$ChromePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
)

$ErrorActionPreference = 'Stop'

Write-Host "ChromePath : $ChromePath"
Write-Host "ChromePort : $ChromePort"
Write-Host "BridgePort : $BridgePort"

if (-not (Test-Path $ChromePath)) {
  throw "Chrome executable not found: $ChromePath"
}

Write-Host "Starting Chrome with remote debugging..."
Start-Process -FilePath $ChromePath -ArgumentList "--remote-debugging-port=$ChromePort" | Out-Null
Start-Sleep -Seconds 2

Write-Host "Checking local Chrome CDP..."
$ver = Invoke-RestMethod -Uri "http://127.0.0.1:$ChromePort/json/version" -TimeoutSec 5
$ver | ConvertTo-Json -Depth 4

Write-Host "Configuring portproxy..."
cmd /c "netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=$BridgePort" | Out-Null
cmd /c "netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=$BridgePort connectaddress=127.0.0.1 connectport=$ChromePort"

Write-Host "Configuring firewall rule..."
cmd /c "netsh advfirewall firewall delete rule name=\"ChromeCDP$BridgePort\"" | Out-Null
cmd /c "netsh advfirewall firewall add rule name=\"ChromeCDP$BridgePort\" dir=in action=allow protocol=TCP localport=$BridgePort"

Write-Host "Current portproxy:"
cmd /c "netsh interface portproxy show all"

Write-Host "Current firewall rule:"
cmd /c "netsh advfirewall firewall show rule name=\"ChromeCDP$BridgePort\""

Write-Host "Done."
Write-Host "Now verify from WSL with:"
Write-Host "curl --connect-timeout 3 --max-time 5 http://<WSL_HOST_GATEWAY>:$BridgePort/json/version"
