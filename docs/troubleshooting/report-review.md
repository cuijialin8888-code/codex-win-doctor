# Review a diagnostic report before sharing

Codex Windows Doctor is designed to keep diagnostics local, but a report can still contain useful environment evidence. Treat every generated report as a document that needs review before it is pasted into an issue, chat, ticket, or public repository.

## Recommended workflow

1. Generate the smallest report that answers the question:

   ```powershell
   .\codex-doctor.ps1 -IssueReport -Output .\doctor-report.md
   .\codex-doctor.ps1 -Json -Output .\doctor-report.json
   ```

2. Open the output locally as text. Do not upload it automatically or attach an entire diagnostics directory.
3. Keep only the checks and evidence needed to reproduce the problem. Remove unrelated machine, username, workspace, or package details.
4. Confirm that no API key, token, cookie, credential, authorization header, private URL, or authentication/configuration file content is present.
5. Share the shortened report only after the manual review is complete.

## Automation policy gates

Use `-FailOn Fail`, `-FailOn Warn`, or `-FailOn Unknown` only when a local script or CI job needs a deliberate exit-code policy. `Fail` gates on `FAIL`; `Warn` includes `WARN` and `FAIL`; `Unknown` includes `UNKNOWN`, `WARN`, and `FAIL`. The default `None` remains informational. A gate does not execute extra commands, repair Windows settings, or upload the report.

## Review checklist

- [ ] The report does not contain secrets, cookies, bearer values, or credential material.
- [ ] Usernames, home directories, repository paths, and organization names are safe to disclose.
- [ ] Commands and environment values are relevant to the question and do not expose private arguments.
- [ ] The report is from the intended machine and run; stale reports are labeled as such.
- [ ] The requested next step is separated from the tool's observed evidence.

## What redaction does and does not promise

The built-in renderers redact common secret names, documented GitHub token prefixes, bearer headers, API-key query parameters, JWT-like values, OpenAI-style prefixes, and user-profile paths. This is defense in depth, not a guarantee that every private value can be recognized. Review the final text yourself.

If a real secret appears in a report, stop sharing it, revoke or rotate the secret through its provider, and then produce a new report after checking the source of the exposure. Do not rely on replacing the visible text alone.

## Issue excerpts

For a public issue, prefer a short excerpt containing:

- the operating-system and PowerShell versions;
- the relevant check ID and status;
- the redacted evidence needed to reproduce the behavior;
- the command or release version used; and
- what you expected versus what happened.

Attach the full report only when it has been deliberately sanitized and the extra evidence is necessary.
