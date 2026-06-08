# Codex Agents

FoundationX 文档仓库的 Codex 代理配置。Codex 是三大 LLM scorer 之一；默认运行时状态写入 `.omx/state/...`。

## 执行类代理

| Agent | 模型 | reasoning | 职责 |
|-------|------|-----------|------|
| spec | gpt-5.5 | high | 编写或修订模块 Spec |
| spec-review | gpt-5.5 | high | 对抗性审查 spec，作为结构评分证据与参考 |
| matrix | gpt-5.5 | high | 生成或校验需求追溯矩阵 |
| task-split | gpt-5.5 | high | 将 Approved Spec 拆分为可执行的 Task |
| task-planner | gpt-5.5 | high | 为单个 TASK 生成实现计划 |
| prompt-builder | gpt-5.5 | medium | 为单个 Task 生成 Context Packet |
| task-executor | gpt-5.5 | high | 按 Task spec 编写代码 |

## 评分类代理（Codex 平台）

| Agent | 阶段 | Rubric |
|-------|------|--------|
| spec-structural-score | Spec | `docs/governance/scoring/RUBRIC-spec.md` |
| matrix-structural-score | Matrix | `docs/governance/scoring/RUBRIC-matrix.md` |
| tasks-structural-score | Tasks | `docs/governance/scoring/RUBRIC-tasks.md` |
| plan-structural-score | Plan | `docs/governance/scoring/RUBRIC-plan.md` |
| prompt-structural-score | Prompt | `docs/governance/scoring/RUBRIC-prompt.md` |
| code-structural-score | Code | `docs/governance/scoring/RUBRIC-code.md` |

## 仲裁类代理

| Agent | 用途 |
|-------|------|
| pipeline-arbiter | 汇总四源评分，按 `docs/governance/scoring/ARBITER-PROTOCOL.md` 输出 gate 判定 |
| meta-arbiter | 读 `.omx/state/outer-metrics/`，按宪法 §14.4 诊断 Goodhart 信号、输出 RSI 建议（不修改任何受保护文件） |

所有评分与仲裁 agent 均使用 `gpt-5.5` 模型 + `high` reasoning。

## 使用方式

```bash
codex --agent spec
codex --agent spec-structural-score
codex --agent pipeline-arbiter
```

## 端到端工作流入口

```text
$spec-code-pipeline {module}
$spec-code-pipeline {module} --from matrix
$spec-code-pipeline {module} --stage prompt
```

## 管线流程

每个阶段都由 **agent team** 执行：

```text
executor → [claude scorer | codex scorer | copilot scorer | rules scorer]（并行/独立）
        → pipeline-arbiter（composite_score = min(claude.score, codex.score, copilot.score, rules.score)；composite_score >= 98 且无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内）
        → 通过则进入下一阶段；失败则路由回 executor 修复
```

详见 `docs/governance/STRUCTURAL-SCORING.md` 与 `docs/governance/scoring/ARBITER-PROTOCOL.md`。
