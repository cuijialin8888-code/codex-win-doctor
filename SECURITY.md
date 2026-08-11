# Security Policy

## Supported versions

Security fixes are provided for the latest released version. During the initial development period, reports against `main` are also welcome.

## Reporting a vulnerability

Please use GitHub's private vulnerability reporting / Security Advisory feature for this repository. If that feature is unavailable, open a minimal public issue asking for a private contact channel without including exploit details, secrets, tokens, credentials, or an unredacted diagnostic report.

Include the affected version, impact, minimal reproduction, and whether the issue can expose secrets or modify a system. The maintainer will acknowledge a credible report as soon as practical for a small volunteer-run project and will coordinate disclosure when a fix is ready.

## Product security and privacy guarantees

- No telemetry by default.
- No secrets collection or credential upload.
- No network requests from the diagnostic script.
- No automatic changes to PATH, the registry, AppX/MSIX packages, Defender, firewall rules, execution policy, WSL, or user configuration.
- Reports are redacted by every built-in renderer and are designed for safer sharing.
- Users must still review reports before posting them publicly.

The doctor never reads the contents of `auth.json`, credential files, cookies, sessions, history, `.sandbox-secrets`, or similarly sensitive stores. A security fix must not weaken these boundaries merely to provide more evidence.

This project is an independent community project and is not affiliated with or endorsed by OpenAI.
