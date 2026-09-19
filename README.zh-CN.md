<p align="center">
  <img src="docs/assets/hero.svg" alt="Codex Windows Doctor——只读 Windows 环境诊断" width="100%">
</p>

<h1 align="center">Codex Windows Doctor</h1>

<p align="center"><strong>面向 Windows、PowerShell、Codex、PATH、WSL 与周边开发工具的只读诊断工具。</strong></p>

<p align="center">
  <a href="https://github.com/cuijialin8888-code/codex-win-doctor/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/cuijialin8888-code/codex-win-doctor/actions/workflows/ci.yml/badge.svg"></a>
  <a href="https://github.com/cuijialin8888-code/codex-win-doctor/releases"><img alt="Release" src="https://img.shields.io/github/v/release/cuijialin8888-code/codex-win-doctor"></a>
  <a href="https://learn.microsoft.com/powershell/"><img alt="PowerShell 5.1 and 7+" src="https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-5391FE.svg"></a>
  <a href="LICENSE"><img alt="MIT License" src="https://img.shields.io/badge/License-MIT-blue.svg"></a>
  <a href="https://github.com/cuijialin8888-code/codex-win-doctor/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/cuijialin8888-code/codex-win-doctor?style=flat"></a>
</p>

<p align="center">
  <a href="#快速开始">快速开始</a> ·
  <a href="#检查内容">检查范围</a> ·
  <a href="#隐私与安全">安全边界</a> ·
  <a href="README.md">English</a>
</p>

Codex 在 Windows 上运行异常，却不知道问题出在哪一环？Codex Windows Doctor 是一个只读诊断工具，检查 Windows、PowerShell、Codex、PATH、WSL 及相关开发环境，并说明哪些正常、哪些可疑、哪些确实失败，以及下一步该查什么。

这是一个面向 Windows 用户的非官方 OpenAI Codex 环境诊断与故障排查工具。

**This project is an independent community project and is not affiliated with or endorsed by OpenAI.**

[English README](README.md)

| 先诊断再修改 | 默认安全 | 证据可复核 |
| --- | --- | --- |
| 区分缺失、损坏、冲突与可选工具 | 本地运行、无遥测、不提权、不自动修复 | 输出 Console、JSON 与可审查 Markdown |

### 适用的常见情况

- `codex`、`pwsh` 或 `rg` 解析到了错误的 executable，或能找到却无法运行。
- PATH 中有冲突安装、shim、重复项或失效路径。
- 脚本假设存在 Unix `unzip`，而 Windows 实际提供的是 `tar.exe` 或 `Expand-Archive`。
- Codex Desktop、WSL 或 `CODEX_HOME` 看似存在，实际行为却不符合预期。
- 想在改动系统之前先拿到一份安全的诊断报告。

### 默认安全

- 只读诊断，完全在本地运行。
- 无 telemetry，不需要 OpenAI API Key。
- 不自动修改 PATH、注册表、WSL 或 AppX/MSIX。

公开 CI 当前覆盖 Windows PowerShell 5.1 和 PowerShell 7，并执行语法验证、测试、静态分析和报告入口 smoke test。

## 快速开始

### 方式 A — 使用 Git clone

```powershell
git clone https://github.com/cuijialin8888-code/codex-win-doctor.git
cd codex-win-doctor
.\codex-doctor.ps1
```

### 方式 B — 下载 Release

[打开最新 Release](https://github.com/cuijialin8888-code/codex-win-doctor/releases/latest)，下载其中的 ZIP 资源（当前为 `codex-win-doctor-0.1.0.zip`）并解压。打开 PowerShell，进入解压后的 `codex-win-doctor-0.1.0` 文件夹后运行：

```powershell
cd .\codex-win-doctor-0.1.0
.\codex-doctor.ps1
```

## 示例输出

以下是删减示例，数量和结论会随实际电脑变化：

```text
Codex Windows Doctor 0.1.0

Environment
  Windows:      Windows 11 25H2 (build 26200, X64)
  PowerShell:   7.x (Core)
  Architecture: process x64

Checks
  [PASS] Codex CLI is executable
  [WARN] Multiple PowerShell 7 (pwsh) commands were detected
  [INFO] Unix unzip is absent, but a Windows-native ZIP capability is available
  [PASS] Workspace is writable and the probe was cleaned up

Summary
  PASS: 9  WARN: 1  FAIL: 0  INFO: 2  UNKNOWN: 0
  Overall: HEALTHY WITH WARNINGS
```

如果 Doctor 没有识别你的 Windows/Codex 问题，运行 `.\codex-doctor.ps1 -IssueReport`，审查输出后打开 [Diagnostic help request](https://github.com/cuijialin8888-code/codex-win-doctor/issues/new/choose)。工具不会替你创建或上传 Issue。

## 检查内容

| 类别 | 诊断内容 |
| --- | --- |
| Windows | 版本、Edition、Build、系统/进程架构、Long Paths 只读状态 |
| PowerShell | 版本、实际 executable、执行策略、`pwsh`/`powershell` 解析顺序与 smoke test |
| Codex CLI | 解析路径、`codex --version`、实际执行能力、多个安装位置 |
| Codex Desktop | 当前用户的 AppX/MSIX 包元数据与 Package Status |
| 开发工具 | Git、可选 gh、Node.js、npm、Python、`py`、pip、ripgrep |
| 压缩能力 | `unzip`、`tar.exe`、`Expand-Archive` |
| Codex 状态目录 | `CODEX_HOME`、默认 `.codex`、路径冲突、一次性写入探针 |
| 文件系统 | 当前工作区和 TEMP 的写入/删除探针 |
| PATH | 重复项、不存在目录、命令冲突和 shell shim |
| WSL | `wsl.exe`、状态、已安装发行版；不安装、不修改 WSL |

## 运行要求

- Windows 10 或 Windows 11
- 优先 PowerShell 7+，同时支持 Windows PowerShell 5.1
- 运行工具不需要 Python 或 Node.js
- 普通诊断不需要管理员权限

如果执行策略阻止脚本，请先阅读脚本，再使用仅对当前进程有效的方式运行，不要直接修改整机策略：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\codex-doctor.ps1
```

组织管理的组策略可能覆盖进程设置。修改任何策略前请阅读[PowerShell 命令解析说明](docs/troubleshooting/powershell-command-resolution.md)。

## 隐私与安全

上述信任边界适用于每次正常运行：`codex-doctor.ps1` 不发起网络请求，不读取认证/配置文件内容，不上传 API Key 或 Token；内置输出会脱敏用户目录和疑似密钥。写权限测试使用一次性文件，测试后立即删除，并验证是否清理成功。

脱敏层识别常见密钥名称、GitHub 官方各类 Token 前缀、Bearer Header、API Key 查询参数、JWT 形态和 OpenAI 风格密钥前缀。但自动脱敏不是绝对保证：**公开粘贴报告前仍应人工检查。**

详见 [SECURITY.md](SECURITY.md)。 公开分享报告前，请先阅读[报告审阅与安全分享指南](docs/troubleshooting/report-review.zh-CN.md)。

## JSON 报告

`-Json` 输出单个 JSON 对象，包含工具版本、时间、平台、全部 checks、统计、Overall、关键建议和隐私元数据。

```powershell
$report = .\codex-doctor.ps1 -Json | ConvertFrom-Json
$report.checks | Where-Object status -In WARN, FAIL, UNKNOWN
```

输出扩展名为 `.json` 时会自动选择 JSON：

```powershell
.\codex-doctor.ps1 -Output .\report.json
```

需要接入代码扫描消费端时，可使用 `-Sarif` 输出 SARIF 2.1.0；结果只包含非 PASS 检查，保留脱敏后的建议，并标记执行为只读：

```powershell
.\codex-doctor.ps1 -Sarif -Output .\doctor.sarif
```

## 自动化门槛

默认情况下，Doctor 只报告观察结果并返回退出码 `0`。只有在脚本或 CI 需要明确的验收门槛时才使用 `-FailOn`：

```powershell
# 仅在存在确认的 FAIL 时返回 1；JSON 仍输出到标准输出。
.\codex-doctor.ps1 -Json -FailOn Fail

# 对 WARN/FAIL 设门槛，或将 UNKNOWN 也视为需要人工复核。
.\codex-doctor.ps1 -Json -FailOn Warn
.\codex-doctor.ps1 -Json -FailOn Unknown
```

`Fail` 只选择 `FAIL`；`Warn` 选择 `WARN` 和 `FAIL`；`Unknown` 选择 `UNKNOWN`、`WARN` 和 `FAIL`；`None` 为默认值。门槛触发时会向标准错误输出一条已脱敏的摘要并返回退出码 `1`，仍不会执行项目命令或修复 Windows 设置。

## Issue Report

`-IssueReport` 生成可检查、可复制的 Markdown。它不会替用户登录 GitHub、创建 Issue 或发送数据。

```powershell
.\codex-doctor.ps1 -IssueReport
.\codex-doctor.ps1 -IssueReport -Output .\doctor-report.md
```

需要解读某项检查时，请选择 [Diagnostic help request](https://github.com/cuijialin8888-code/codex-win-doctor/issues/new/choose)；工具本身出现可复现的问题时请选择 Bug report。不要发布 API Key、Token、cookie、credential 或未经审查的认证文件。

## 故障排查文档

- [PowerShell 命令解析](docs/troubleshooting/powershell-command-resolution.md)
- [找不到 Codex CLI](docs/troubleshooting/codex-cli-not-found.md)
- [多个 Codex 安装](docs/troubleshooting/multiple-codex-installations.md)
- [Windows 压缩工具](docs/troubleshooting/archive-tools.md)
- [WSL 诊断](docs/troubleshooting/wsl-diagnostics.md)
- [rg 能解析但 Access Denied](docs/troubleshooting/rg-access-denied.md)
- [Codex Desktop 包状态](docs/troubleshooting/codex-desktop-package.md)
- [CODEX_HOME 诊断](docs/troubleshooting/codex-home.md)
- [报告审阅与安全分享](docs/troubleshooting/report-review.zh-CN.md)

## Roadmap

- **v0.1：** Windows 环境诊断、隐私安全报告、测试和 CI
- **v0.2：** 基于已核验案例扩展 Codex Desktop / WSL 判断
- **v0.3：** 带边界和回滚说明的安全引导式修复
- **未来：** 社区 checks、可选 support bundle、更好的 Issue 匹配

目前只有 v0.1 功能已经实现。项目暂不做 GUI、后台服务、telemetry、自动提权、自动修改 PATH/注册表/应用包、自动创建 Issue，也不依赖 OpenAI API。

## 参与贡献

欢迎真实 Bug、边界案例、文档修正和范围清晰的新 check。提交前请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)、[行为准则](CODE_OF_CONDUCT.md)和[安全政策](SECURITY.md)。

## 免责声明

This project is an independent community project and is not affiliated with or endorsed by OpenAI. “OpenAI”和“Codex”仅用于描述兼容对象和被诊断环境。修改受管理设备或生产环境前，请以当前官方文档为准。

## 许可证

[MIT](LICENSE) © 2026 cuijialin8888-code
