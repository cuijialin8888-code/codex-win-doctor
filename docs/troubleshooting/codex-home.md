# CODEX_HOME diagnostics

## Symptom

`CODEX_HOME` points to a missing or relative path, differs from an existing default `.codex` directory, or is not writable by the current user.

## Official guidance

OpenAI's [configuration basics](https://learn.chatgpt.com/docs/config-file/config-basic) and [environment variable reference](https://learn.chatgpt.com/docs/config-file/environment-variables) define the current Codex configuration model. OpenAI's Windows troubleshooting guidance also warns users not to share sensitive sandbox-secret contents.

## Community evidence

Copying `auth.json`, full configuration, sessions, or global-state files into a public issue is sometimes suggested as a shortcut. This project does not consider that safe evidence. File existence and non-sensitive metadata are usually enough to begin diagnosis.

## Doctor interpretation

The doctor selects configured `CODEX_HOME` when present, otherwise the user-profile `.codex` directory. It checks path validity, directory existence, whether configured/default locations differ, and a disposable write/delete probe. It does **not** enumerate or read `config.toml`, `auth.json`, credentials, sessions, history, or `.sandbox-secrets`.

- unset and no default directory: `INFO`;
- configured path missing/relative or conflicting with an existing default: `WARN`;
- existing directory cannot complete the write/delete probe: `FAIL`;
- existing selected directory is writable: `PASS`.

## Safe next steps

```powershell
$env:CODEX_HOME
Test-Path -LiteralPath $env:CODEX_HOME
```

Share only a redacted path, `EXISTS`/`NOT FOUND`, and the doctor check id. Never paste credential or auth-file contents into an issue.
