# Codex desktop package state

## Symptom

The doctor detects a Codex AppX/MSIX package with a non-OK status, or package metadata cannot be queried.

## Official guidance

OpenAI documents the current [Codex/ChatGPT desktop app for Windows](https://learn.chatgpt.com/docs/windows/windows-app). Microsoft documents [`Get-AppxPackage`](https://learn.microsoft.com/en-us/powershell/module/appx/get-appxpackage) as the supported PowerShell cmdlet for reading installed package metadata.

## Community evidence

Issue comments sometimes recommend taking ownership of WindowsApps or editing installed package files. Those steps can break permissions and MSIX signatures and are not treated as official guidance by this project.

## Doctor interpretation

The v0.1 check is current-user and non-elevated:

- visible package with `Ok` status: `PASS`;
- no visible package: `INFO` because the user may use another client;
- `Modified`, `NeedsRemediation`, or another non-OK state: `WARN`;
- query unavailable or blocked: `UNKNOWN`.

Only package name, version, architecture, status, and install location are reported. Package contents are never modified.

## Safe next steps

```powershell
Get-AppxPackage -Name '*Codex*' |
    Select-Object Name, Version, Architecture, Status, InstallLocation
```

Restart Windows and use Microsoft Store or your organization's deployment support for remediation. Do not change TrustedInstaller permissions, take ownership of WindowsApps, edit package contents, or bypass signing.
