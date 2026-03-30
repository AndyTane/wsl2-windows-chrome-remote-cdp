---
name: wsl2-windows-chrome-remote-cdp
description: Diagnose, configure, and validate OpenClaw browser control when the Gateway runs inside WSL2 but Google Chrome runs on Windows, especially in environments with proxy software, global mode, virtual network adapters, or host/guest split networking. Use when browser control must attach through Remote CDP instead of launching a Linux browser, when WSL can reach Windows only through a forwarded host port, or when users mention portproxy, 9222/9223, virtual NICs, Clash/FClash/Mihomo, or WSL2-to-Windows Chrome automation.
---

Use this skill to make OpenClaw in WSL2 control Windows Chrome through a stable Remote CDP bridge.

## Core rule

Do not change OpenClaw browser config until WSL2 can successfully reach the Windows-side CDP bridge with `curl`.

Working pattern:

```text
OpenClaw (WSL2) -> profile remote -> http://HOST_IP:9223 -> Windows portproxy -> 127.0.0.1:9222 -> Chrome
```

## Minimal workflow

1. Read `references/runbook.md`.
2. Verify Windows Chrome local CDP on `127.0.0.1:9222`.
3. Verify Windows `portproxy` and firewall for `9223`.
4. From WSL2, verify `curl http://HOST_IP:9223/json/version` and `/json/list`.
5. Only then write OpenClaw remote profile config.
6. Restart gateway.
7. Validate with `openclaw browser profiles`, `status`, `tabs`, `open`, `snapshot`, `navigate`.

## Read these references when needed

- `references/runbook.md` — full end-to-end executable procedure with Mermaid diagrams
- `references/config-snippets.md` — OpenClaw JSON, Windows commands, and validation snippets
- `references/troubleshooting.md` — layered failure analysis and fast triage

## Use bundled scripts

### WSL-side recovery

- `scripts/update-openclaw-remote-cdp.sh` — detect current WSL host gateway IP, validate the Windows CDP bridge, backup `~/.openclaw/openclaw.json`, update `browser.profiles.remote.cdpUrl`, optionally set `browser.defaultProfile=remote`, restart the gateway, and print verification output
- `scripts/show-openclaw-remote-cdp.sh` — print the currently detected host IP and derived CDP URL and probe `/json/version`

Run the WSL-side scripts from the skill root directory, for example:

```bash
./scripts/update-openclaw-remote-cdp.sh --dry-run
```

Use `update-openclaw-remote-cdp.sh --dry-run` before modifying config when the environment may have changed after Windows or WSL reboot.

### Windows-side recovery

- `scripts/setup-windows-chrome-cdp.ps1` — start Windows Chrome with `--remote-debugging-port=9222`, verify local CDP, create `portproxy` `9223 -> 127.0.0.1:9222`, add firewall allow rule, and print verification guidance
- `scripts/teardown-windows-chrome-cdp.ps1` — remove the Windows bridge `portproxy` and firewall rule

Use these when Windows reboot, proxy software reset, or network stack changes cause the bridge layer to disappear even though WSL-side config remains correct.

## Key invariants

- Prefer `browser.profiles.remote.cdpUrl` for split-host WSL2/Windows setups.
- Use `attachOnly: true` for externally managed Windows Chrome.
- Treat Windows local `9222` and WSL-visible `9223` as separate layers.
- Do not confuse a higher-layer action failure (for example screenshot timeout) with remote CDP transport failure.

## What to avoid

- Do not keep retrying Linux local browser launch when the real target is Windows Chrome.
- Do not write unverified host IPs into OpenClaw config.
- Do not assume proxy software that affects internet traffic automatically solves local WSL2-to-Windows TCP reachability.
- Do not diagnose browser action failures before proving `/json/version` and `/json/list` are reachable from WSL2.
