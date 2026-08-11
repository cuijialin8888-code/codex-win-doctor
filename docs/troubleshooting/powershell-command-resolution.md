# PowerShell command resolution

## Symptom

`Get-Command pwsh -All` returns one or more paths, but Codex or the doctor cannot start the resolved shell. A `.cmd` shim or Windows application alias may appear before the intended `pwsh.exe`.

## Official guidance

Microsoft documents [`Get-Command`](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/get-command) as command discovery and [`about_Execution_Policies`](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies) as the policy model for script execution. OpenAI's [Windows sandbox guidance](https://learn.chatgpt.com/docs/windows/windows-sandbox) confirms that Codex can run natively in PowerShell and recommends preserving sandbox boundaries.

An execution-policy value and a command path are evidence, but neither proves a new child process can start. Process-scope execution policy is temporary; organization Group Policy can still take precedence.

## Community evidence

OpenAI's public Codex issue tracker includes a Windows report where an unusable `pwsh` alias resolved first and prevented shell commands from running: [openai/codex#18937](https://github.com/openai/codex/issues/18937). This is evidence that the failure class exists, not an official remediation policy.

## Doctor interpretation

- `PASS`: the resolved executable completes a minimal non-interactive child-process smoke test.
- `WARN`: multiple resolution locations or a command shim is first.
- `FAIL`: the command resolves but the smoke test fails, times out, or returns Access Denied.
- `INFO`: optional `pwsh` is absent but supported Windows PowerShell 5.1 remains available.
- `UNKNOWN`: policy or process evidence could not be read reliably.

## Safe next steps

```powershell
Get-Command pwsh -All
Get-Command powershell -All
Get-ExecutionPolicy -List
```

Run the listed absolute executable with `-NoProfile -NonInteractive -Command "Write-Output OK"`. Compare the result in the same terminal and in Codex. Do not delete shims or rewrite PATH until you know which application created each path.
