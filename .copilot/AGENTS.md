# Copilot CLI Agents

FoundationX 文档仓库的 Copilot CLI 代理配置。与 `.claude/agents/` 和 `.codex/agents/` 平行；Copilot 是三大 LLM scorer 之一，默认运行时状态写入 `.copilot/state/...`。

## 角色定位

Copilot CLI 在本仓库中承担三类职责：

1. **管线主代理（leader）**：协调 Spec → Code 全流程，调度 scorer 与 arbiter。
2. **Copilot LLM scorer**：与 Claude / Codex 并行对每个阶段产物独立打分。
3. **Goal Delivery OS prompt 投影**：读取 `.copilot/agents/goal-*.md` 扮演 Goal 专用角色，执行或审查 `docs/goal/` 定义的交付流程。

## 分支纪律

> 详见 `CONSTITUTION.md` 第零条。

- **所有分支必须从 `main` HEAD 创建**。创建前必须先 `git fetch origin && git rebase origin/main` 确保本地 main 为最新。
- 禁止从其他 feature branch 或旧 commit 拉取新分支。
- 所有开发工作必须通过 `git worktree` 或 feature branch 进行。

## Scorer 代理清单

| Agent | 评分对象 | Rubric |
|-------|----------|--------|
| `spec-structural-score` | `module/{module}/SPEC.md` | `docs/governance/scoring/RUBRIC-spec.md` |
| `matrix-structural-score` | `module/{module}/TRACEABILITY.md` | `docs/governance/scoring/RUBRIC-matrix.md` |
| `tasks-structural-score` | `module/{module}/tasks/TASK-*.md` | `docs/governance/scoring/RUBRIC-tasks.md` |
| `plan-structural-score` | `module/{module}/IMPLEMENTATION-PLAN.md` | `docs/governance/scoring/RUBRIC-plan.md` |
| `prompt-structural-score` | `module/{module}/TASK-*-PROMPT.md` | `docs/governance/scoring/RUBRIC-prompt.md` |
| `code-structural-score` | 本次 Task diff + 测试输出 | `docs/governance/scoring/RUBRIC-code.md` |
| `pipeline-arbiter` | 四源评分聚合 | `docs/governance/scoring/ARBITER-PROTOCOL.md` |
| `meta-arbiter` | 元仲裁，Goodhart 诊断与 RSI 建议 | `CONSTITUTION.md` §14、`.copilot/state/outer-metrics/SCHEMA.md` |

## Goal Delivery OS Agent 投影清单

以下 Agent 是 `docs/goal/` 的 Copilot prompt 投影，不是独立规则源。权威边界以 `docs/goal/00-authority-map.md` 和 `docs/goal/14-agent-protocols.md` 为准。

| Agent | 职责 | 维护文件 |
|-------|------|----------|
| `goal-spec` | Goal / Spec / Design / Plan / Task / Registry 编写 | `.config/goal/registry/*.yaml`, `.config/goal/pipeline/state.yaml` |
| `goal-reviewer` | G0-G11、Review、Release 对抗性审查 | `.config/goal/gates/state.yaml` |
| `goal-matrix` | 横向追溯 Matrix edge graph | `.config/goal/matrix/matrix.yaml` |
| `goal-prompt-builder` | 单 Task Context Package / Prompt | `.config/goal/prompts/TASK-*/v*.md` |
| `goal-evidence` | Evidence Bundle、No Evidence No Done、Release 证据闭环 | `.config/goal/evidence/**/*.md` |

Goal Agent 必须遵守以下边界：

- `CONSTITUTION.md` 高于 `docs/goal/`，`docs/goal/` 高于 `.config/goal/schema/rules.yaml`；schema 只是机器校验投影。
- Matrix 是横切 edge graph，不是主流程阶段。
- Agent 不得绕过 G0-G11；FAIL / BLOCKED 只能修复、补证据、重计划或发起 Change Request。
- Review、Release 和 Done 必须满足 No Evidence, No Done。
- 单 Task 同一时间只能有一个 writer；并行任务必须使用 worktree 或等价隔离。
- 已批准 Goal 核心目标、Non-goals、P0/P1 验收、安全、隐私、权限、资金、数据保留、Release Gate、Rollback、Incident、失败测试和失败证据不得由 Agent 自动放宽。

## 评分门禁

每个阶段：

```text
composite_score = min(claude.score, codex.score, copilot.score, rules.score)
composite_score >= 98 且无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内 → gate=pass
```

详见 `docs/governance/STRUCTURAL-SCORING.md` 与 `docs/governance/scoring/ARBITER-PROTOCOL.md`。

## 状态目录

```text
.copilot/state/pipeline/{module}/{stage}/
├── scores/
│   ├── claude.json
│   ├── claude.md
│   ├── codex.json
│   ├── codex.md
│   ├── copilot.json
│   ├── copilot.md
│   └── rules.json
├── verdict.json
└── attempts.json
```

## 触发方式

Copilot CLI 没有 `/agent` 这类内置切换命令。Copilot 主代理通过读取 `.copilot/agents/{name}.md` 的 prompt 模板，在子会话中以"扮演该角色"方式执行评分任务或 Goal 专用任务。Scorer 输出 JSON 与 Markdown 报告到上述状态目录；Goal Agent 输出必须回到 `.config/goal/` 控制面或任务指定的 evidence / prompt / matrix 路径。

## 与其他平台的关系

- 三大 LLM scorer 必须**独立运行**，不得共享中间结果；`rules` 由 `scripts/rule-scorer.py` 作为第四个机械源生成。
- Arbiter 在任一平台运行结果应一致（算法纯函数）；推荐使用 Copilot 主代理执行 arbiter 以减少切换成本。
- 唯一门禁是四源仲裁 `composite_score = min(claude.score, codex.score, copilot.score, rules.score) >= 98` 且无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内；失败只允许按有界 repair budget 自动路由，预算耗尽后输出 `pipeline_blocked`，不得人工把 fail 改成 pass。
