# Changelog

All notable changes to this project are documented here. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Repository-level maintainer instructions for safe, PowerShell 5.1-compatible contributions.
- A report-review guide in English and Chinese, covering local review and safe sharing of JSON and Markdown diagnostics.
- Optional `-FailOn` automation gates for FAIL, WARN, and UNKNOWN findings, with redacted standard-error summaries and exit code `1`.

### Changed

- Pin GitHub Actions dependencies to immutable commits and add grouped monthly update checks.

### Fixed

- Redact standalone classic, OAuth, user, server, refresh, and fine-grained GitHub token formats in every renderer.

## [0.1.0] - 2026-08-11

### Added

- Read-only Windows, PowerShell, Codex CLI, Codex desktop, PATH, WSL, long-path, archive-tool, developer-tool, and filesystem diagnostics.
- Unified `PASS`, `WARN`, `FAIL`, `INFO`, and `UNKNOWN` check schema.
- Console, JSON, and privacy-redacted Markdown issue reports.
- Disposable workspace, temporary-directory, and Codex-home write probes with cleanup verification.
- Pester tests, PowerShell 5.1/7 CI, PSScriptAnalyzer checks, release automation, English/Chinese documentation, and community health files.

[Unreleased]: https://github.com/cuijialin8888-code/codex-win-doctor/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/cuijialin8888-code/codex-win-doctor/releases/tag/v0.1.0
