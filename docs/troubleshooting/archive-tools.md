# Archive tools on Windows

## Symptom

A cross-platform script expects `unzip`, but Windows reports that the command is not found.

## Official guidance

Microsoft documents [`Expand-Archive`](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.archive/expand-archive) as a built-in PowerShell ZIP extraction capability. Supported Windows systems may also provide `tar.exe`. These capabilities are different from the Unix command named `unzip`.

## Community evidence

Many repository scripts use `unzip` without checking the host platform. Installing an unrelated Unix compatibility layer can make one script pass while creating a new PATH conflict. That is a community workaround, not a universal Windows requirement.

## Doctor interpretation

- Missing `unzip` is `INFO` when `tar.exe` or `Expand-Archive` is available.
- A discovered archive command that cannot execute is `WARN` because it can mislead scripts.
- No tested extraction capability is `WARN`, not proof that Codex itself is broken.

## Safe next steps

Prefer a platform-aware script with a documented fallback. For ZIP-only work in PowerShell:

```powershell
Get-Command Expand-Archive
Expand-Archive -LiteralPath .\archive.zip -DestinationPath .\destination
```

Do not install Unix `unzip` solely to make the doctor display `PASS`.
