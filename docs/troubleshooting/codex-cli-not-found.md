# Codex CLI not found

## Symptom

The doctor reports `INFO: Codex CLI not detected`, or `Get-Command codex` returns no result.

## Official guidance

The current [official Codex CLI documentation](https://learn.chatgpt.com/docs/codex/cli) describes installation, sign-in, and running `codex` in a project directory. OpenAI also documents native Windows app and CLI workflows separately, so not finding the CLI does not prove the desktop app is broken.

## Community evidence

Many public reports mix CLI, IDE-extension, desktop-app, native Windows, and WSL environments. A workaround for one client or package manager should not be treated as the official installation method for every client.

## Doctor interpretation

CLI absence is `INFO`, not `FAIL`, because the user may only use the desktop app or may not intend to use the CLI. A discovered `codex` that cannot execute is more important than an absent command and is reported as `FAIL`.

## Safe next steps

1. Decide whether you actually need the CLI.
2. Follow the current official installation method rather than copying an old package-manager command from an issue.
3. Open a new terminal and run:

```powershell
Get-Command codex -All
codex --version
```

Do not share sign-in tokens or `auth.json` to prove that Codex is installed.
