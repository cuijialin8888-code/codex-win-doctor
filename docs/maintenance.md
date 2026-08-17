# Maintenance checklist

Keep maintenance evidence-driven and small. This project is a read-only diagnostic tool, so routine maintenance should preserve that boundary rather than add automatic repair or background behavior.

## Review triggers

- A new Windows, PowerShell, Codex CLI, Codex Desktop, WSL, or archive-tool behavior is reported with reproducible evidence.
- A diagnostic check, redaction rule, report field, or supported entry point changes.
- A release is prepared, or the release archive contents need to change.

## Routine checks

- Use the CI workflow as the compatibility check for Windows PowerShell 5.1 and PowerShell 7.
- Keep the JSON and Markdown issue-report smoke checks passing when report or version metadata changes.
- Add a focused regression test for a confirmed edge case; do not add a check based only on an unverified assumption.
- Review the README, Chinese README, CHANGELOG, and `VERSION` together when preparing a release.

## Release checks

- Update `VERSION` and the matching CHANGELOG entry.
- Create a matching `vX.Y.Z` tag so the release workflow can build the versioned ZIP archive.
- Confirm the release archive contains only the intended script, source, documentation, license, security policy, changelog, and version files.
- Run the released archive on a clean Windows environment when practical, and review any report before sharing it publicly.

## Safety boundaries

- Preserve read-only behavior, no telemetry, no API-key requirement, and no automatic PATH, registry, WSL, AppX/MSIX, or policy changes.
- Do not create activity-only commits, artificial issues, or unverified compatibility claims.

## Review log

- 2026-08-17: verified the public `main` branch, recent GitHub Actions runs, and open issue/PR queues; no follow-up was required.
