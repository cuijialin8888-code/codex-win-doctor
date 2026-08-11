# Multiple Codex installations

## Symptom

`Get-Command codex -All` returns commands from more than one directory, or `codex --version` differs between terminals and applications.

## Official guidance

OpenAI's [Codex CLI documentation](https://learn.chatgpt.com/docs/codex/cli) is the source of truth for current installation methods. PowerShell's [`Get-Command -All`](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/get-command) exposes resolution order; the first applicable command is normally the one invoked by name.

## Community evidence

Package-manager changes, standalone binaries, desktop-bundled executables, and stale shims can coexist. Public issue workarounds that delete a specific file or PATH entry are environment-specific and are not official guidance.

## Doctor interpretation

Two command files in the same installation directory are not automatically treated as two installations. The doctor raises `WARN` when Codex resolves from more than one directory, and it keeps the discovered order as evidence. It does not guess which installation the user should keep.

## Safe next steps

```powershell
Get-Command codex -All | Select-Object CommandType, Source
```

Run each intended executable by absolute path with `--version`. Identify which installer or application owns it before uninstalling or changing PATH. Never modify files inside WindowsApps or bypass MSIX signing.
