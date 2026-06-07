# Claude Code Agents

FoundationX 文档仓库的 Claude Code 代理配置。

## 代理清单

| Agent | 模型 | 职责 |
|-------|------|------|
| spec | Opus | 编写或修订模块 Spec，补齐 23 节结构与追溯链 |
| spec-review | Opus | 对抗性审查 spec，给出 Go/No-Go 判断 |
| matrix | Sonnet | 生成或校验需求追溯矩阵，闭合 FR/BR/AC/TC 链条 |
| task-split | Sonnet | 将已批准的 SPEC.md 拆分为可执行的 Task spec |
| task-planner | Opus | 为单个 TASK 生成分步实现计划 |
| prompt-builder | Sonnet | 为单个 Task 生成 Context Packet（结构化开发提示词） |
| task-executor | Sonnet | 按照 Task spec 和实现计划编写代码 |

## 使用方式

```text
/agent spec
/agent spec-review
/agent matrix
```

## 管线流程

```text
spec → spec-review → matrix → task-split → task-planner → prompt-builder → task-executor
```

## 目录结构

```text
.claude/
├── agents/          # 代理配置（7 个 MD 文件）
├── commands/        # 自定义命令（release.md）
├── settings.local.json  # 本地设置（含敏感信息，已 gitignore）
└── AGENTS.md        # 本文件
```
