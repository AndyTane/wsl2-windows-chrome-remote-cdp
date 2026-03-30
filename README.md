# wsl2-windows-chrome-remote-cdp

An OpenClaw skill for controlling **Windows Chrome** from **WSL2** through **Remote CDP**, with special attention to real-world environments that include:

- WSL2 Ubuntu + Windows host split
- OpenClaw Gateway running inside WSL
- Google Chrome running on Windows
- `portproxy` bridge (`9223 -> 127.0.0.1:9222`)
- Windows firewall rules
- proxy software / global mode / virtual NICs / Clash / FClash / Mihomo style environments

This repository focuses on **operational reliability** rather than abstract browser theory.

---

## What this skill solves

OpenClaw in WSL2 cannot always control a Linux-local browser reliably when the real target browser is the user's Windows Chrome.

This skill documents and automates the working pattern:

```text
OpenClaw (WSL2) -> browser profile: remote -> http://HOST_IP:9223
-> Windows portproxy -> 127.0.0.1:9222 -> Windows Chrome (CDP)
```

It includes:

- WSL-side recovery scripts
- Windows-side setup / teardown / self-check scripts
- Mermaid architecture diagrams
- explicit verification steps
- troubleshooting guidance
- novice-friendly dependency/install guidance

---

## Repository layout

```text
.
├── SKILL.md
├── README.md
├── references/
│   ├── runbook.md
│   ├── config-snippets.md
│   └── troubleshooting.md
└── scripts/
    ├── self-check.sh
    ├── show-openclaw-remote-cdp.sh
    ├── update-openclaw-remote-cdp.sh
    ├── windows-self-check.ps1
    ├── setup-windows-chrome-cdp.ps1
    └── teardown-windows-chrome-cdp.ps1
```

---

## Recommended usage flow

### WSL side

1. Enter the skill root directory
2. Run preflight:

```bash
bash ./scripts/self-check.sh
```

3. If dependencies are missing, install them (or let the agent do it after confirmation)
4. Refresh remote CDP profile:

```bash
bash ./scripts/update-openclaw-remote-cdp.sh --dry-run
bash ./scripts/update-openclaw-remote-cdp.sh --apply --set-default
```

### Windows side

Prefer copying the PowerShell scripts to a local Windows directory before running them.

1. Self-check:

```powershell
powershell -NoExit -ExecutionPolicy Bypass -File .\windows-self-check.ps1
```

2. Preview setup changes:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-windows-chrome-cdp.ps1 -DryRun
```

3. Execute setup:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-windows-chrome-cdp.ps1
```

4. Preview teardown if needed:

```powershell
powershell -ExecutionPolicy Bypass -File .\teardown-windows-chrome-cdp.ps1 -DryRun
```

---

## Key design principles learned during development

- **Parser stability beats elegance** for Windows PowerShell helper scripts.
- Prefer **minimal line-by-line output** over complex formatting.
- Prefer **simple matching and direct commands** over over-engineered abstractions.
- Prefer **dry-run first** for Windows-side changes.
- Do not assume users know WSL, PowerShell, host IPs, or OpenClaw config details.

---

## Verification targets

A healthy setup should eventually confirm:

- Windows Chrome path exists
- `127.0.0.1:9222/json/version` is reachable
- `127.0.0.1:9222/json/list` is reachable
- Windows `portproxy` exists for `9223 -> 127.0.0.1:9222`
- Windows firewall rule exists for `ChromeCDP9223`
- WSL can reach `http://HOST_IP:9223/json/version`
- OpenClaw browser profile `remote` is healthy

---

## Notes

- The Windows PowerShell scripts were intentionally simplified after more abstract versions proved parser-fragile in real user environments.
- For Windows-side execution, local copies are preferred over directly executing `.ps1` files from `\\wsl$` paths.
- This repository values **tested practicality** over pretty scripting.

---

## License

No explicit license file has been added yet. Add one if you want broader reuse terms to be unambiguous.
