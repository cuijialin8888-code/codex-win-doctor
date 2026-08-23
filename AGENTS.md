# Maintainer instructions

## Product boundaries

- Keep normal diagnostics local, bounded, and read-only. Do not add telemetry, network calls, elevation, package installation, or automatic system changes.
- Do not read credential or configuration contents merely to prove that a path exists. Preserve the privacy promises in `README.md` and `SECURITY.md`.
- Treat `PASS`, `WARN`, `FAIL`, `INFO`, and `UNKNOWN` as stable public semantics. Existing check IDs are compatibility-sensitive.

## Code organization

- `codex-doctor.ps1` is the public entry point.
- Put reusable primitives in `src/Core`, checks in `src/Checks`, redaction in `src/Privacy`, and renderers in `src/Output`.
- Keep PowerShell 5.1 compatibility. Avoid syntax or APIs available only in newer PowerShell versions unless a compatible fallback is included and tested.
- Prefer a focused check and explicit evidence over broad environment discovery. Every state-changing probe must be disposable and verify cleanup.

## Verification

- Add focused Pester coverage for behavior and privacy boundaries.
- Run `pwsh -NoProfile -File .\tests\Invoke-CI.ps1` and PSScriptAnalyzer before completion.
- Smoke-test `./codex-doctor.ps1 -Json` and `./codex-doctor.ps1 -IssueReport` when report data or rendering changes.
- Update both English and Chinese documentation when user-facing behavior or safety claims change, and record notable changes under `CHANGELOG.md` → `Unreleased`.
