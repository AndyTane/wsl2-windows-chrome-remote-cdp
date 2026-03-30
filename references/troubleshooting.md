# Troubleshooting

## Fast triage order

1. Verify Windows local Chrome CDP on `127.0.0.1:9222`.
2. Verify Windows portproxy and firewall for `9223`.
3. Verify WSL2 can reach `http://172.17.32.1:9223/json/version`.
4. Verify OpenClaw remote profile config.
5. Verify OpenClaw browser actions.

## If Windows `9222` fails

Problem is in Windows Chrome startup or local listener state.

Commands:

```powershell
curl http://127.0.0.1:9222/json/version
netstat -ano | findstr 9222
```

## If Windows `9222` works but WSL `9223` fails

Problem is in portproxy, firewall, or WSL-to-host path.

Preferred recovery:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-windows-chrome-cdp.ps1
```

Commands:

```powershell
netsh interface portproxy show all
netsh advfirewall firewall show rule name="ChromeCDP9223"
```

```bash
curl --connect-timeout 3 --max-time 5 http://172.17.32.1:9223/json/version
```

## If WSL `9223` works but OpenClaw remote fails

From the skill root directory, first run the recovery script in dry-run mode, then apply mode if the derived host IP/CDP URL are correct.

```bash
./scripts/update-openclaw-remote-cdp.sh --dry-run
./scripts/update-openclaw-remote-cdp.sh --apply --set-default
```

Problem is in OpenClaw browser config or wrong profile usage.

Commands:

```bash
openclaw browser profiles
openclaw browser --browser-profile remote status
grep -n 'defaultProfile\|cdpUrl\|attachOnly' ~/.openclaw/openclaw.json
```

## If remote is connected but one action fails

Do not confuse action failure with transport failure.

Example: screenshot timeout can happen even when remote CDP transport is already healthy.
