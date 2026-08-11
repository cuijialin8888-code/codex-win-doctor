# Codex Windows Doctor

[![CI](https://github.com/cuijialin8888-code/codex-win-doctor/actions/workflows/ci.yml/badge.svg)](https://github.com/cuijialin8888-code/codex-win-doctor/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/cuijialin8888-code/codex-win-doctor)](https://github.com/cuijialin8888-code/codex-win-doctor/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-5391FE.svg)](https://learn.microsoft.com/powershell/)

一个面向 Windows 用户的非官方 OpenAI Codex 环境诊断与故障排查工具。

运行一个本地 PowerShell 脚本，即可了解哪些能力正常、哪些地方可疑、哪些检查确实失败，以及下一步最值得检查什么。本工具只诊断，不替用户修改系统。

**This project is an independent community project and is not affiliated with or endorsed by OpenAI.**

[English README](README.md)

## 快速开始

```powershell
git clone https://github.com/cuijialin8888-code/codex-win-doctor.git
cd codex-win-doctor
.\codex-doctor.ps1
```

生成 JSON 或适合复制到 GitHub Issue 的 Markdown 报告：

```powershell
.\codex-doctor.ps1 -Json
.\codex-doctor.ps1 -Json -Output .\report.json
.\codex-doctor.ps1 -IssueReport -Output .\doctor-report.md
.\codex-doctor.ps1 -Verbose
```

## 为什么需要它

Windows 上的 Codex 故障经常表现相似，原因却可能完全不同：命令被错误 shim 抢占、PATH 中存在多个版本、PowerShell 无法启动子进程、AppX 包状态异常、WSL 已启用但没有可运行发行版，或者跨平台脚本错误地假设 Windows 一定有 Unix `unzip`。

Codex Windows Doctor 不承诺“一键修复 Windows”。它先安全地回答：

> 我的 Codex 环境到底哪里有问题？

每项检查都返回统一的 id、category、status、summary、details、recommendation 和 evidence。状态固定为 `PASS`、`WARN`、`FAIL`、`INFO`、`UNKNOWN`；可选软件未安装不会被武断地判定为失败。

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

## 检查内容

| 类别 | 诊断内容 |
| --- | --- |
| Windows | 版本、Edition、Build、系统/进程架构、Long Paths 只读状态 |
| PowerShell | 版本、实际 executable、执行策略、`pwsh`/`powershell` 解析顺序与 smoke test |
| Codex CLI | 解析路径、`codex --version`、实际执行能力、多个安装位置 |
| Codex Desktop | 当前用户的 AppX/MSIX 包元数据与 Package Status |
| 开发工具 | Git、可选 gh、Node.js、npm、Python、`py`、pip、ripgrep |
| 压缩能力 | 分别检查 `unzip`、`tar.exe`、`Expand-Archive` |
| Codex 状态目录 | `CODEX_HOME`、默认 `.codex`、路径冲突、一次性写入探针 |
| 文件系统 | 当前工作区和 TEMP 的写入/删除探针 |
| PATH | 重复项、不存在目录、命令冲突和 shell shim |
| WSL | `wsl.exe`、状态、已安装发行版；不安装、不修改 WSL |

## 示例输出

以下是删减示例，数量和结论会随实际电脑变化：

```text
Codex Windows Doctor 0.1.0

Environment
  Windows:      Windows 11 25H2 (build 26200, X64)
  PowerShell:   7.x (Core)
  Architecture: process x64

Checks
  [PASS] Windows 11 build 26200
  [PASS] Codex CLI is executable
  [WARN] Multiple PowerShell 7 (pwsh) commands were detected
  [INFO] Unix unzip is absent, but a Windows-native ZIP capability is available
  [PASS] Workspace is writable and the probe was cleaned up

Summary
  PASS: 9  WARN: 1  FAIL: 0  INFO: 2  UNKNOWN: 0
  Overall: HEALTHY WITH WARNINGS
```

## 隐私与安全

默认行为保持克制：

- 完全本地运行，无 telemetry；
- `codex-doctor.ps1` 不发起网络请求；
- 不修改注册表、PATH、AppX/MSIX、Defender、防火墙或系统策略；
- 不读取 `auth.json`、credential、session、history、cookie 或配置文件内容；
- 不上传 API Key 或 Token；
- 三种输出统一脱敏用户目录和疑似密钥；
- 写权限测试使用一次性文件，测试后立即删除，并验证是否清理成功。

脱敏层识别常见 OpenAI/GitHub Token 名称、Bearer Header、API Key 查询参数、JWT 形态和 OpenAI 风格密钥前缀。但自动脱敏不是绝对保证：**公开粘贴报告前仍应人工检查。**

详见 [SECURITY.md](SECURITY.md)。

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

## Issue Report

`-IssueReport` 生成可检查、可复制的 Markdown。它不会替用户登录 GitHub、创建 Issue 或发送数据。

```powershell
.\codex-doctor.ps1 -IssueReport
.\codex-doctor.ps1 -IssueReport -Output .\doctor-report.md
```

## 故障排查文档

- [PowerShell 命令解析](docs/troubleshooting/powershell-command-resolution.md)
- [找不到 Codex CLI](docs/troubleshooting/codex-cli-not-found.md)
- [多个 Codex 安装](docs/troubleshooting/multiple-codex-installations.md)
- [Windows 压缩工具](docs/troubleshooting/archive-tools.md)
- [WSL 诊断](docs/troubleshooting/wsl-diagnostics.md)
- [rg 能解析但 Access Denied](docs/troubleshooting/rg-access-denied.md)
- [Codex Desktop 包状态](docs/troubleshooting/codex-desktop-package.md)
- [CODEX_HOME 诊断](docs/troubleshooting/codex-home.md)

## 添加检查

检查函数位于 `src/Checks`。单个检查应边界明确，不直接向终端打印，并通过 `New-DoctorCheck` 返回统一对象。`src/Output` 中的 renderer 再从同一报告生成控制台、JSON 和 Markdown。

测试和贡献流程见 [CONTRIBUTING.md](CONTRIBUTING.md)。

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
