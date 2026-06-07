# Codex Agents

FoundationX 文档仓库的 Codex 代理配置。

## 代理清单

| Agent | 模型 | reasoning | 职责 |
|-------|------|-----------|------|
| spec | gpt-5.5 | high | 编写或修订模块 Spec，补齐 23 节结构与追溯链 |
| spec-review | gpt-5.5 | high | 对抗性审查 spec，给出 Go/No-Go 判断 |
| matrix | gpt-5.5 | high | 生成或校验需求追溯矩阵，闭合 FR/BR/AC/TC 链条 |
| task-split | gpt-5.5 | high | 将已批准的 SPEC.md 拆分为可执行的 Task spec |
| task-planner | gpt-5.5 | high | 为单个 TASK 生成分步实现计划 |
| prompt-builder | gpt-5.5 | medium | 为单个 Task 生成 Context Packet（结构化开发提示词） |
| task-executor | gpt-5.5 | high | 按照 Task spec 和实现计划编写代码 |

## 使用方式

```bash
codex --agent spec
codex --agent spec-review
codex --agent matrix
```

## 管线流程

```text
spec → spec-review → matrix → task-split → task-planner → prompt-builder → task-executor
```
