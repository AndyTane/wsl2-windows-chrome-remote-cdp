# Release Notes — v0.2.0

## Summary

`v0.2.0` is the first repository-structure-focused public release of **wsl2-windows-chrome-remote-cdp**.

This version promotes the project from a working internal skill folder into a more installable and publicly understandable repository layout.

---

## Highlights

### 1. Installable repository layout

The repository was restructured to separate human-facing documentation from the actual OpenClaw skill payload.

New layout:

```text
repo-root/
├── README.md
└── skill-wsl2-windows-chrome-remote-cdp/
    ├── SKILL.md
    ├── references/
    └── scripts/
```

This makes it clearer which folder should be used as the actual skill installation target.

### 2. Bilingual README

The root `README.md` now includes:

- Chinese + English overview
- architecture diagram
- feature summary
- quick-start flow
- repository layout
- verification targets
- installation hint

### 3. Windows PowerShell hardening

Windows-side scripts were simplified significantly after real parser failures in practical environments.

The current design favors:

- parser stability
- line-by-line output
- dry-run support
- operational clarity over abstraction elegance

### 4. Dry-run workflow

Windows setup/teardown scripts now support a safer preview-first usage model.

Examples:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-windows-chrome-cdp.ps1 -DryRun
powershell -ExecutionPolicy Bypass -File .\teardown-windows-chrome-cdp.ps1 -DryRun
```

### 5. User-validated Windows self-check

The Windows self-check script was simplified and aligned with a user-validated, actually runnable structure instead of a more abstract but parser-fragile version.

---

## Recommended usage target

When installing this skill into OpenClaw, use:

```text
skill-wsl2-windows-chrome-remote-cdp/
```

not the repository root.

---

## Notes

This release emphasizes practical reliability and installability.

It is not yet a final polished ecosystem package, but it is now much closer to a real public skill repository than the initial internal layout.

---

## Tag

- `v0.2.0`
