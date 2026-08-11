# Contributing

Thanks for helping make Windows Codex diagnostics safer and more accurate. Small, evidence-backed contributions are preferred over broad rewrites.

## Development setup

```powershell
git clone https://github.com/cuijialin8888-code/codex-win-doctor.git
cd codex-win-doctor
.\codex-doctor.ps1
```

Running the doctor requires only PowerShell 5.1 or later. Development tests use Pester, and static analysis uses PSScriptAnalyzer; these are development dependencies, not user runtime dependencies.

```powershell
Invoke-Pester .\tests
Invoke-ScriptAnalyzer -Path . -Recurse -Settings .\.psscriptanalyzer.psd1
```

CI installs its own development modules on the ephemeral GitHub Actions runner. Do not add Python, Node.js, administrator access, or online services as runtime requirements without prior discussion.

## Add a check

1. Add or update a narrowly scoped function under `src/Checks`.
2. Perform only bounded, local diagnostics. Do not change PATH, the registry, AppX/MSIX packages, security settings, or user configuration.
3. Do not read authentication/configuration contents merely to prove a file exists.
4. Return `New-DoctorCheck` with `id`, `category`, `status`, `summary`, `details`, `recommendation`, and `evidence`.
5. Use `UNKNOWN` when the evidence cannot support a reliable conclusion, and explain why.
6. Register the check group in `src/Invoke-CodexDoctor.ps1`.
7. Add tests for success, absence, failure, and any privacy boundary introduced by the check.

Check ids are lowercase dotted identifiers and should remain stable after release.

## Test a change

- Run the relevant Pester tests.
- Validate both `-Json` and `-IssueReport` if output changes.
- Confirm disposable files are removed.
- Run PSScriptAnalyzer and address findings instead of broadly disabling rules.
- When possible, run the entry script in both Windows PowerShell 5.1 and PowerShell 7.

Never add real API keys, tokens, cookies, auth files, private paths, or unredacted user reports to a fixture. Use explicit fake values such as `sk-test-THIS_IS_NOT_REAL`.

## Issues and pull requests

Before opening an issue, search existing issues and include the doctor version, Windows/PowerShell/Codex versions, and a reviewed redacted report. **Do not post API keys or tokens.**

Pull requests should explain the problem, evidence, change boundary, tests, and any remaining uncertainty. Keep unrelated formatting or refactors out of a bug fix. By contributing, you agree that your contribution is licensed under the MIT License.
