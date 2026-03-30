# Config snippets

## OpenClaw browser config

```json
{
  "browser": {
    "enabled": true,
    "defaultProfile": "remote",
    "profiles": {
      "remote": {
        "cdpUrl": "http://172.17.32.1:9223",
        "attachOnly": true,
        "color": "#00AA00"
      }
    }
  }
}
```

## Windows Chrome start command

```powershell
& 'C:\Program Files\Google\Chrome\Application\chrome.exe' --remote-debugging-port=9222
```

## Windows portproxy commands

```powershell
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=9223 connectaddress=127.0.0.1 connectport=9222
netsh interface portproxy show all
netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=9223
```

## Windows firewall commands

```powershell
netsh advfirewall firewall add rule name="ChromeCDP9223" dir=in action=allow protocol=TCP localport=9223
netsh advfirewall firewall show rule name="ChromeCDP9223"
netsh advfirewall firewall delete rule name="ChromeCDP9223"
```

## WSL validation commands

```bash
curl --connect-timeout 3 --max-time 5 http://172.17.32.1:9223/json/version
curl --connect-timeout 3 --max-time 5 http://172.17.32.1:9223/json/list
```

## Recovery scripts

```bash
~/bin/update-openclaw-remote-cdp.sh --dry-run
~/bin/update-openclaw-remote-cdp.sh --apply --set-default
~/bin/show-openclaw-remote-cdp.sh
```

## OpenClaw validation commands

```bash
openclaw gateway restart
openclaw browser profiles
openclaw browser --browser-profile remote status
openclaw browser --browser-profile remote tabs
openclaw browser --browser-profile remote open https://example.com
openclaw browser --browser-profile remote snapshot
openclaw browser --browser-profile remote navigate https://example.org
```
