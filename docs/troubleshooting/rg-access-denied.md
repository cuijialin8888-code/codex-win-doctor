# ripgrep resolves but returns Access Denied

## Symptom

`Get-Command rg -All` finds `rg.exe`, but `rg --version` or a harmless search fails with Access Denied.

## Official guidance

PowerShell's [`Get-Command`](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/get-command) reports discoverable commands. It does not guarantee the current process token can execute the resolved file. OpenAI's [Windows sandbox guidance](https://learn.chatgpt.com/docs/windows/windows-sandbox) explains that filesystem and process permissions can be bounded by the selected Windows sandbox.

## Community evidence

The public Codex tracker contains a related Windows shell-resolution failure where an unusable application alias was selected: [openai/codex#18937](https://github.com/openai/codex/issues/18937). The exact root cause of an `rg` failure can still be different.

## Doctor interpretation

The doctor separates discovery from capability:

- no command: `INFO`;
- command resolves and `rg --version` succeeds: `PASS` (or `WARN` for competing locations);
- command resolves but Access Denied occurs: `FAIL` with “resolved but not executable”;
- another unexplained execution failure: `FAIL` or `UNKNOWN` based on available evidence.

## Safe next steps

```powershell
Get-Command rg -All | Select-Object CommandType, Source
& 'C:\absolute\path\to\rg.exe' --version
```

Record the exact resolved path and error. Check whether the path is an application alias, managed package, sandbox-inaccessible directory, or stale file. Do not take ownership of WindowsApps, disable Defender, or weaken sandbox policy to make this check pass.
