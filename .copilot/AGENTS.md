# Copilot CLI Agents

FoundationX 文档仓库的 Copilot CLI 代理配置。与 `.claude/agents/` 和 `.codex/agents/` 平行，作为三平台评分体系中的第三平台。

## 角色定位

Copilot CLI 在本仓库中承担两类职责：

1. **管线主代理（leader）**：协调 Spec → Code 全流程，调度 scorer 与 arbiter。
2. **第三平台 scorer**：与 Claude / Codex 并行对每个阶段产物独立打分。

## Scorer 代理清单

| Agent | 评分对象 | Rubric |
|-------|----------|--------|
| `spec-structural-score` | `specs/{module}/SPEC.md` | `specs/scoring/RUBRIC-spec.md` |
| `matrix-structural-score` | `specs/{module}/TRACEABILITY.md` | `specs/scoring/RUBRIC-matrix.md` |
| `tasks-structural-score` | `specs/{module}/tasks/TASK-*.md` | `specs/scoring/RUBRIC-tasks.md` |
| `plan-structural-score` | `specs/{module}/IMPLEMENTATION-PLAN.md` | `specs/scoring/RUBRIC-plan.md` |
| `prompt-structural-score` | `specs/{module}/TASK-*-PROMPT.md` | `specs/scoring/RUBRIC-prompt.md` |
| `code-structural-score` | 本次 Task diff + 测试输出 | `specs/scoring/RUBRIC-code.md` |
| `pipeline-arbiter` | 三平台评分聚合 | `specs/scoring/ARBITER-PROTOCOL.md` |
| `meta-arbiter` | 元仲裁，Goodhart 诊断与 RSI 建议 | `CONSTITUTION.md` §14、`.omx/state/outer-metrics/SCHEMA.md` |

## 评分门禁

每个阶段：

```text
composite_score = min(claude.score, codex.score, copilot.score)
composite_score >= 98 且无红线、无低置信度、分差在阈值内 → gate=pass
```

详见 `specs/STRUCTURAL-SCORING.md` 与 `specs/scoring/ARBITER-PROTOCOL.md`。

## 状态目录

```text
.omx/state/pipeline/{module}/{stage}/
├── scores/
│   ├── claude.json
│   ├── claude.md
│   ├── codex.json
│   ├── codex.md
│   ├── copilot.json
│   └── copilot.md
├── verdict.json
└── attempts.json
```

## 触发方式

Copilot CLI 没有 `/agent` 这类内置切换命令。Copilot 主代理通过读取 `.copilot/agents/{name}.md` 的 prompt 模板，在子会话中以"扮演该角色"方式执行评分任务，输出 JSON 与 Markdown 报告到上述状态目录。

## 与其他平台的关系

- 三平台 scorer 必须**独立运行**，不得共享中间结果。
- Arbiter 在任一平台运行结果应一致（算法纯函数）；推荐使用 Copilot 主代理执行 arbiter 以减少切换成本。
- 唯一门禁是三平台仲裁 `composite_score >= 98` 且无红线、无低置信度、分差在阈值内，全自动循环，无人工接管路径。
