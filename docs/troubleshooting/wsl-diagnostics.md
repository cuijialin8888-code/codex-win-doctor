# WSL diagnostics

## Symptom

`wsl.exe` exists, but no distribution is installed, `wsl --status` fails, or Codex was configured for WSL and cannot start the expected environment.

## Official guidance

OpenAI documents [native Windows Codex](https://learn.chatgpt.com/docs/windows/windows-sandbox) and [WSL workflows](https://learn.chatgpt.com/docs/windows/wsl) as separate choices. Native Windows mode does not require WSL. Microsoft documents [`wsl --status` and `wsl --list --verbose`](https://learn.microsoft.com/en-us/windows/wsl/basic-commands) as read-only status/list commands.

## Community evidence

Public reports show that enabling a WSL-oriented desktop mode without a runnable distribution can cause startup failures, for example [openai/codex#16169](https://github.com/openai/codex/issues/16169). The configuration edits suggested in comments are community workarounds unless OpenAI documentation adopts them.

## Doctor interpretation

- WSL absent: `INFO`.
- WSL available with a distribution: `PASS` as a capability, not proof every WSL workflow works.
- WSL enabled without a distribution: `INFO` unless future evidence safely proves the user selected WSL mode.
- Status commands fail or time out: `UNKNOWN`, with the reason preserved.

## Safe next steps

```powershell
wsl.exe --status
wsl.exe --list --verbose
```

Confirm whether you intend to use native Windows or WSL. Do not install WSL automatically, terminate distributions, or edit global Codex state merely to clear a diagnostic status.
