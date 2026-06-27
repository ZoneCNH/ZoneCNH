# Claude Code Agents

FoundationX 文档仓库的 Claude Code 代理配置。Claude Code 是三大 LLM scorer 之一；默认运行时状态写入 `.omc/state/...`。

## 执行类代理

| Agent | 模型 | 职责 |
|-------|------|------|
| spec → 见 goal-spec | Opus | 编写或修订模块 Spec（已合并到 goal-spec） |
| spec-review | Opus | 对抗性审查 spec，作为结构评分证据与参考 |
| matrix → 见 goal-matrix | Sonnet | 生成或校验需求追溯矩阵（已合并到 goal-matrix） |
| task-split → 见 goal-planner | Sonnet | 将 Approved Spec 拆分为可执行的 Task（已合并到 goal-planner） |
| task-planner → 见 goal-planner | Opus | 为单个 TASK 生成分步实现计划（已合并到 goal-planner） |
| prompt-builder → 见 goal-prompt-builder | Sonnet | 为单个 Task 生成 Context Packet（已合并到 goal-prompt-builder） |
| task-executor | Sonnet | 按 Task spec 编写代码 |

## 评分类代理（Claude 平台）

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
| meta-arbiter | 读 `.omc/state/outer-metrics/`，按宪法 §14.4 诊断 Goodhart 信号、输出 RSI 建议（不修改任何受保护文件） |

## 使用方式

```text
/agent spec
/agent spec-structural-score
/agent pipeline-arbiter
```

## 端到端工作流入口

```text
/project:spec-code-pipeline {module}
/project:spec-code-pipeline {module} --from matrix
/project:spec-code-pipeline {module} --stage prompt
```

## 管线流程

每个阶段都由 **agent team** 执行：

```text
executor → [claude scorer | codex scorer | copilot scorer | rules scorer]（并行/独立）
        → pipeline-arbiter（composite_score = min(claude.score, codex.score, copilot.score, rules.score)；composite_score >= 98 且无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内）
        → 通过则进入下一阶段；失败则路由回 executor 修复
```

详见 `docs/governance/STRUCTURAL-SCORING.md` 与 `docs/governance/scoring/ARBITER-PROTOCOL.md`。

## 目录结构

```text
.claude/
├── agents/          # 代理配置（Markdown 文件，含 scorer 与 arbiter）
├── commands/        # 自定义命令（release.md、spec-code-pipeline.md）
├── settings.local.json  # 本地设置（已 gitignore）
└── AGENTS.md        # 本文件
```
