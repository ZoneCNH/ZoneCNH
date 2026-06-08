# Copilot CLI Agents

FoundationX 文档仓库的 Copilot CLI 代理配置。与 `.claude/agents/` 和 `.codex/agents/` 平行；Copilot 是三大 LLM scorer 之一，默认运行时状态写入 `.copilot/state/...`。

## 角色定位

Copilot CLI 在本仓库中承担两类职责：

1. **管线主代理（leader）**：协调 Spec → Code 全流程，调度 scorer 与 arbiter。
2. **Copilot LLM scorer**：与 Claude / Codex 并行对每个阶段产物独立打分。

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

Copilot CLI 没有 `/agent` 这类内置切换命令。Copilot 主代理通过读取 `.copilot/agents/{name}.md` 的 prompt 模板，在子会话中以"扮演该角色"方式执行评分任务，输出 JSON 与 Markdown 报告到上述状态目录。

## 与其他平台的关系

- 三大 LLM scorer 必须**独立运行**，不得共享中间结果；`rules` 由 `scripts/rule-scorer.py` 作为第四个机械源生成。
- Arbiter 在任一平台运行结果应一致（算法纯函数）；推荐使用 Copilot 主代理执行 arbiter 以减少切换成本。
- 唯一门禁是四源仲裁 `composite_score = min(claude.score, codex.score, copilot.score, rules.score) >= 98` 且无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内；失败只允许按有界 repair budget 自动路由，预算耗尽后输出 `pipeline_blocked`，不得人工把 fail 改成 pass。
