---
name: spec-code-pipeline
description: Run the repo-local Spec -> Matrix -> Tasks -> Plan -> Prompt -> Code workflow for one module, with stage gates and agent routing.
---

# Spec Code Pipeline

Use this skill when the user asks for a complete development workflow, "开发工作流", "完整管线", or explicitly names:

```text
Spec -> Matrix -> Tasks -> Plan -> Prompt -> Code
```

The workflow target is one module under `specs/{module}/`. It turns an approved module spec into traceability, tasks, implementation plan, task prompt, and one bounded code execution.

## Invocation

```text
$spec-code-pipeline {module}
$spec-code-pipeline {module} --from matrix
$spec-code-pipeline {module} --stage prompt
```

Chinese trigger equivalents:

```text
完整工作流 {module}
开发工作流 {module}
Spec 到 Code {module}
```

## Canonical Flow

```text
Spec -> Matrix -> Tasks -> Plan -> Prompt -> Code
```

Expanded repo gate sequence (每个 executor 后都接 **三平台团队评分 + 仲裁**)：

```text
spec
  -> [spec-team-score: claude + codex + copilot]
  -> pipeline-arbiter  (gate: composite_score >= 98 且无红线、低置信度、异常分差)
  -> 自动翻转 Status: Approved
  -> matrix
  -> [matrix-team-score] -> pipeline-arbiter (gate)
  -> task-split
  -> [tasks-team-score] -> pipeline-arbiter (gate)
  -> task-planner
  -> [plan-team-score] -> pipeline-arbiter (gate)
  -> prompt-builder
  -> [prompt-team-score] -> pipeline-arbiter (gate)
  -> task-executor
  -> [code-team-score] -> pipeline-arbiter (gate)
```

每个阶段必须满足（唯一门禁）：

- `composite_score = min(claude.score, codex.score, copilot.score)`
- `composite_score >= 98`
- 无任一平台红线
- 无任一平台低置信度，且三平台分差不超过阈值

Confidence 与分差属于 gate 条件，不能被忽略或人工豁免。失败一律自动路由回当前阶段 executor 或 scorer 修复；3 次失败自动升级到上一阶段；上游再失败继续向上直到 spec，由 spec executor 重写后继续循环。**全自动，无人工接管**。

详见 `specs/STRUCTURAL-SCORING.md` 与 `specs/scoring/ARBITER-PROTOCOL.md`。

## Stage Contract

| Stage | Executor | Team Scorers (并行) | Gate（唯一） |
|-------|----------|--------------------|--------------|
| Spec | `spec` | claude / codex / copilot `spec-structural-score` | `composite_score >= 98` 且无红线、低置信度、异常分差 |
| Matrix | `matrix` | `matrix-structural-score` × 3 | `composite_score >= 98` 且无红线、低置信度、异常分差 |
| Tasks | `task-split` | `tasks-structural-score` × 3 | `composite_score >= 98` 且无红线、低置信度、异常分差 |
| Plan | `task-planner` | `plan-structural-score` × 3 | `composite_score >= 98` 且无红线、低置信度、异常分差 |
| Prompt | `prompt-builder` | `prompt-structural-score` × 3 | `composite_score >= 98` 且无红线、低置信度、异常分差 |
| Code | `task-executor` | `code-structural-score` × 3 | `composite_score >= 98` 且无红线、低置信度、异常分差 |

Arbiter agent：`pipeline-arbiter`（三平台均有实现，结果等价）。
状态目录：`.omx/state/pipeline/{module}/{stage}/{scores/,verdict.json,attempts.json}`。

## Execution Rules

1. Work one module at a time.
2. Do not code from a Draft spec.
3. **Every stage must pass team-scoring gate (`composite_score >= 98`, no redline, no low confidence, bounded score spread) before advancing. This is the only gate.**
4. **Every stage uses an agent team: executor + 3 scorers (claude/codex/copilot) + pipeline-arbiter.**
5. Do not skip Matrix or Tasks before Plan.
6. Do not ask `task-executor` to implement more than one task unless the user explicitly requests a batch.
7. When using `--stage`, verify upstream artifacts AND upstream verdicts (`verdict.json` gate=pass) exist first.
8. When using `--from`, resume from that stage; downstream `verdict.json` and `scores/` must be re-generated.
9. Update `TRACEABILITY.md` and task status after each code task.
10. Never bypass scoring gate by editing `verdict.json` manually. There is no human override path.

## Repair Routing

- Missing or incomplete spec structure: route to `spec`.
- Structural redline at any stage: route to that stage's executor.
- Broken FR/AC/TC chain: route to `matrix`.
- Overlarge or cross-module task: route to `task-split`.
- Ambiguous execution order: route to `task-planner`.
- Missing implementation context: route to `prompt-builder`.
- Code/test failure: keep scope in current task and route to `task-executor`.

## State

Per-stage state under:

```text
.omx/state/pipeline/{module}/{stage}/
├── scores/
│   ├── claude.json   ├── claude.md
│   ├── codex.json    ├── codex.md
│   └── copilot.json  └── copilot.md
├── verdict.json      # arbiter output (gate=pass|fail)
└── attempts.json     # retry counter & escalation chain
```

Top-level pipeline state:

```text
.omx/state/pipeline/{module}.json
```

## Final Report

End with:

- current stage and completed stages
- created or updated artifacts
- active task, if code started
- validation evidence
- blockers or remaining gates
