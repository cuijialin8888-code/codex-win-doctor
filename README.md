# Codex Windows Doctor

[![CI](https://github.com/cuijialin8888-code/codex-win-doctor/actions/workflows/ci.yml/badge.svg)](https://github.com/cuijialin8888-code/codex-win-doctor/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/cuijialin8888-code/codex-win-doctor)](https://github.com/cuijialin8888-code/codex-win-doctor/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-5391FE.svg)](https://learn.microsoft.com/powershell/)

Codex behaving strangely on Windows? Codex Windows Doctor is a read-only diagnostic tool for your Windows, PowerShell, Codex, PATH, WSL, and related developer environment. It shows what is healthy, suspicious, or actually broken—and what to check next.

It is an unofficial diagnostics and troubleshooting toolkit for OpenAI Codex on Windows.

**This project is an independent community project and is not affiliated with or endorsed by OpenAI.**

[中文说明](README.zh-CN.md)

### It can help when...

- `codex`, `pwsh`, or `rg` resolves to the wrong executable or cannot run.
- PATH contains conflicting installations, shims, duplicates, or missing entries.
- A script expects Unix `unzip`, while Windows provides `tar.exe` or `Expand-Archive` instead.
- Codex Desktop, WSL, or `CODEX_HOME` appears present but behaves unexpectedly.
- You want a safe diagnostic report before changing your system.

### Safe by default

- Read-only diagnostics that run locally.
- No telemetry and no OpenAI API key required.
- No automatic PATH, registry, WSL, or AppX/MSIX changes.

## Quick start

### Option A — Clone with Git

```powershell
git clone https://github.com/cuijialin8888-code/codex-win-doctor.git
cd codex-win-doctor
.\codex-doctor.ps1
```

### Option B — Download the release

[Open the latest release](https://github.com/cuijialin8888-code/codex-win-doctor/releases/latest), download its ZIP asset (currently `codex-win-doctor-0.1.0.zip`), and extract it. Open PowerShell in the extracted `codex-win-doctor-0.1.0` folder, then run:

```powershell
cd .\codex-win-doctor-0.1.0
.\codex-doctor.ps1
```

## Example output

This is an abridged example; counts and findings depend on the machine.

```text
Codex Windows Doctor 0.1.0

Environment
  Windows:      Windows 11 25H2 (build 26200, X64)
  PowerShell:   7.x (Core)
  Architecture: process x64

Checks
  [PASS] Codex CLI is executable
  [WARN] Multiple PowerShell 7 (pwsh) commands were detected
  [INFO] Unix unzip is absent, but a Windows-native ZIP capability is available
  [PASS] Workspace is writable and the probe was cleaned up

Summary
  PASS: 9  WARN: 1  FAIL: 0  INFO: 2  UNKNOWN: 0
  Overall: HEALTHY WITH WARNINGS
```

If the doctor does not recognize your Windows/Codex problem, run `.\codex-doctor.ps1 -IssueReport`, review the output, and open a [Diagnostic help request](https://github.com/cuijialin8888-code/codex-win-doctor/issues/new/choose). The tool never creates or uploads an issue for you.

## What it checks

| Area | Diagnostics |
| --- | --- |
| Windows | Version, edition, build, OS/process architecture, long-path setting |
| PowerShell | Version, executable, execution policy, `pwsh`/`powershell` resolution and smoke tests |
| Codex CLI | Resolution path, `codex --version`, execution capability, competing install locations |
| Codex desktop | Current-user AppX/MSIX package metadata and package status |
| Developer tools | Git, optional GitHub CLI, Node.js, npm, Python, `py`, pip, ripgrep |
| Archives | `unzip`, `tar.exe`, and `Expand-Archive` as distinct capabilities |
| Codex state | `CODEX_HOME`, default `.codex` directory, path conflicts, disposable write probe |
| Filesystem | Workspace and temporary-directory write/delete probes |
| PATH | Duplicate/missing entries, command conflicts, and shell shims |
| WSL | `wsl.exe`, status, and installed distributions without installing or changing WSL |

## Requirements

- Windows 10 or Windows 11
- PowerShell 7+ preferred, or Windows PowerShell 5.1
- No Python or Node.js runtime is required
- Administrator rights are not required for normal diagnostics

If execution policy blocks the script, review it first, then use a one-process override rather than changing machine policy:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\codex-doctor.ps1
```

Organization-managed policy can override process settings. See [PowerShell command resolution](docs/troubleshooting/powershell-command-resolution.md) before changing any policy.

## Privacy and safety

The trust promises above apply to every normal run: `codex-doctor.ps1` makes no network requests; it does not read authentication/configuration contents or upload API keys and tokens; every built-in renderer redacts user-profile paths and secret-like values. Disposable write probes are deleted immediately and cleanup is tested.

Redaction recognizes common OpenAI/GitHub token names, bearer headers, API-key query parameters, JWT-like strings, and OpenAI-style secret prefixes. It is defense in depth, not a guarantee: **always review a report before posting it publicly**.

See [SECURITY.md](SECURITY.md) for the security policy.

## JSON reports

`-Json` returns one JSON object with tool metadata, timestamp, platform data, checks, summary counts, overall health, recommended next steps, and privacy metadata.

```powershell
$report = .\codex-doctor.ps1 -Json | ConvertFrom-Json
$report.checks | Where-Object status -In WARN, FAIL, UNKNOWN
```

An `.json` output extension selects JSON automatically:

```powershell
.\codex-doctor.ps1 -Output .\report.json
```

## Issue reports

`-IssueReport` creates Markdown that can be reviewed and pasted into a GitHub issue. It does not open an issue, log in to GitHub, or send data.

```powershell
.\codex-doctor.ps1 -IssueReport
.\codex-doctor.ps1 -IssueReport -Output .\doctor-report.md
```

For an interpretation question, choose [Diagnostic help request](https://github.com/cuijialin8888-code/codex-win-doctor/issues/new/choose). For a reproducible problem in this tool, choose Bug report. Never post API keys, tokens, cookies, credentials, or unreviewed authentication files.

## Troubleshooting guides

- [PowerShell command resolution](docs/troubleshooting/powershell-command-resolution.md)
- [Codex CLI not found](docs/troubleshooting/codex-cli-not-found.md)
- [Multiple Codex installations](docs/troubleshooting/multiple-codex-installations.md)
- [Archive tools on Windows](docs/troubleshooting/archive-tools.md)
- [WSL diagnostics](docs/troubleshooting/wsl-diagnostics.md)
- [ripgrep resolves but returns Access Denied](docs/troubleshooting/rg-access-denied.md)
- [Codex desktop package state](docs/troubleshooting/codex-desktop-package.md)
- [CODEX_HOME diagnostics](docs/troubleshooting/codex-home.md)

## Roadmap

- **v0.1:** Windows environment diagnostics, privacy-safe reports, tests, and CI
- **v0.2:** Expanded Codex desktop and WSL interpretation, driven by verified cases
- **v0.3:** Safe, explicit guided remediation with rollback notes
- **Future:** Community-contributed checks, an optional support bundle, and better issue matching

Only v0.1 features are implemented today. The project intentionally does not include a GUI, background service, telemetry, elevation, automatic PATH/registry/package changes, automatic issue creation, or an OpenAI API dependency.

## Contributing

Bug reports, diagnostic edge cases, documentation fixes, and narrowly scoped checks are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md), the [Code of Conduct](CODE_OF_CONDUCT.md), and the [security policy](SECURITY.md).

## Disclaimer

This project is an independent community project and is not affiliated with or endorsed by OpenAI. “OpenAI” and “Codex” are used only to describe compatibility and the environment being diagnosed. Verify recommendations against current official documentation before changing a managed or production system.

## License

[MIT](LICENSE) © 2026 cuijialin8888-code
