# 公开分享诊断报告前的审阅

Codex Windows Doctor 尽量让诊断在本地完成，但报告仍可能包含有用的环境证据。把每份生成的报告都当作需要人工审阅的文档，在粘贴到 Issue、聊天、工单或公开仓库前先检查。

## 推荐流程

1. 只生成能够回答当前问题的最小报告：

   ```powershell
   .\codex-doctor.ps1 -IssueReport -Output .\doctor-report.md
   .\codex-doctor.ps1 -Json -Output .\doctor-report.json
   ```

2. 在本地以文本方式打开，不要自动上传，也不要把整目录作为诊断附件。
3. 只保留复现问题所需的检查和证据，删除无关的机器名、用户名、工作区、路径或软件包信息。
4. 确认没有 API Key、Token、cookie、credential、Authorization Header、私有 URL 或认证/配置文件内容。
5. 完成人工审阅后，再分享精简后的报告。

## 自动化验收门槛

只有本地脚本或 CI 需要明确退出码策略时才使用 `-FailOn Fail`、`-FailOn Warn` 或 `-FailOn Unknown`。`Fail` 仅对 `FAIL` 触发；`Warn` 包含 `WARN` 和 `FAIL`；`Unknown` 包含 `UNKNOWN`、`WARN` 和 `FAIL`。默认 `None` 保持为只报告模式。门槛不会额外执行命令、修复 Windows 设置或上传报告。

## 审阅清单

- [ ] 没有密钥、cookie、Bearer 值或 credential 内容。
- [ ] 用户名、用户目录、仓库路径和组织名称可以公开。
- [ ] 命令和环境值与问题相关，没有暴露私有参数。
- [ ] 报告来自预期的电脑和本次运行；旧报告已明确标注。
- [ ] “观察到的证据”和“建议的下一步”已经区分。

## 自动脱敏的边界

内置输出会识别常见密钥名称、GitHub 官方 Token 前缀、Bearer Header、API Key 查询参数、JWT 形态、OpenAI 风格前缀和用户目录路径，并进行脱敏。这只是纵深防御，不保证能够识别所有私有值，最终文本仍必须人工检查。

如果报告中出现真实密钥，立即停止分享，并通过对应服务商撤销或轮换该密钥；确认暴露来源后再重新生成报告。不要只替换报告里的可见文本。

## 公开 Issue 建议只放什么

公开 Issue 优先提供以下精简信息：

- Windows 和 PowerShell 版本；
- 相关 check ID 与状态；
- 足以复现问题的脱敏证据；
- 使用的命令或 Release 版本；
- 预期行为与实际行为。

只有在已经认真脱敏且确实需要更多证据时，才附上完整报告。
