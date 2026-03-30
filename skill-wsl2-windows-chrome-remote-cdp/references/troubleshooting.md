# Troubleshooting

## Fast triage order

0. Run `bash ./scripts/self-check.sh` from the skill root directory.
1. If dependencies are missing, explain the block in plain language, ask whether to install them, and continue automatically after explicit confirmation such as `YES`.
2. Verify Windows local Chrome CDP on `127.0.0.1:9222`.
3. Verify Windows portproxy and firewall for `9223`.
4. Verify WSL2 can reach `http://172.17.32.1:9223/json/version`.
5. Verify OpenClaw remote profile config.
6. Verify OpenClaw browser actions.

## If Windows `9222` fails

Problem is in Windows Chrome startup or local listener state.

Commands:

```powershell
curl http://127.0.0.1:9222/json/version
netstat -ano | findstr 9222
```

## If dependencies are missing in WSL

Do not end with raw install commands only. Preferred handling for an agent:

1. Explain what is missing and why it matters.
2. Ask whether to install it automatically.
3. On explicit confirmation like `YES`, run the install command.
4. Re-run `bash ./scripts/self-check.sh`.
5. Resume the blocked recovery step automatically.

Typical install command:

```bash
sudo apt update
sudo apt install -y jq curl iproute2
```

## If Windows-side state is unknown

Note: earlier versions of the Windows self-check script became too complex and regressed from “runnable but imperfect” to `ParserError`. The current version intentionally follows a much simpler structure validated against a known-good user-tested variant: straight-line checks, simple string matching, and minimal formatting. Parsing stability takes priority over pretty output.

### Windows PowerShell scripting rules learned from this incident

When writing Windows-side helper scripts for end users, especially on Windows PowerShell 5.x and localized systems:

1. Prefer the smallest syntax subset that gets the job done.
2. Prefer straight-line checks over helper-heavy abstractions.
3. Avoid decorative status markers such as `[OK]` / `[MISS]` in output strings.
4. Avoid complex inline expressions and nested `$(if (...) { ... })` inside output objects.
5. Avoid complicated quote nesting and aggressive string composition.
6. Prefer simple double-quoted strings with direct variable interpolation when they remain readable.
7. Prefer “ugly but stable” over “elegant but parser-fragile”.
8. If a script fails with parser errors twice in a row, stop patching incrementally and rewrite it in a more minimal style.

Start with Windows local self-check from the skill root directory:

Before making Windows-side changes, prefer a dry run first:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-windows-chrome-cdp.ps1 -DryRun
powershell -ExecutionPolicy Bypass -File .\teardown-windows-chrome-cdp.ps1 -DryRun
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows-self-check.ps1
```

If it prints `NOT READY`, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-windows-chrome-cdp.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows-self-check.ps1
```

## If Windows `9222` works but WSL `9223` fails

Problem is in portproxy, firewall, or WSL-to-host path.

Preferred recovery:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-windows-chrome-cdp.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows-self-check.ps1
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
bash ./scripts/update-openclaw-remote-cdp.sh --dry-run
bash ./scripts/update-openclaw-remote-cdp.sh --apply --set-default
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
