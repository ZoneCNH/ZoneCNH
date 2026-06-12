---
name: spec-code-pipeline
description: Run the repo-local Spec -> Matrix -> Tasks -> Plan -> Prompt -> Code workflow for one module, with stage gates and agent routing.
---

# Spec Code Pipeline

Use this skill when the user asks for a complete development workflow, "开发工作流", "完整管线", or explicitly names:

```text
Spec -> Matrix -> Tasks -> Plan -> Prompt -> Code
```

The workflow target is one module under `module/{module}/`. It turns an approved module spec into traceability, tasks, implementation plan, task prompt, and one bounded code execution.

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

Expanded repo gate sequence (每个 executor 后都接 **四源团队评分 + 仲裁**)：

```text
spec
  -> [spec-team-score: claude + codex + copilot + rules-engine]
  -> pipeline-arbiter  (gate: composite_score = min(claude.score, codex.score, copilot.score, rules.score) >= 98 且无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内)
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

- `composite_score = min(claude.score, codex.score, copilot.score, rules.score)`
- `composite_score >= 98`
- 无任一评分源红线
- 无任一 LLM 平台低置信度，且三 LLM 平台分差不超过阈值
- `rules.score` 与三 LLM 中位数的异构分歧不超过阈值

Confidence 与分差属于 gate 条件，不能被忽略或人工豁免。失败一律自动路由回当前阶段 executor 或 scorer 修复；同阶段 3 次失败自动升级到上一阶段；上游再失败继续向上直到 spec。修复循环必须有界：默认 `max_stage_attempts = 3`，`max_total_gate_failures = 18`。达到全链路上限后输出 `pipeline_blocked` 和 retrospective，不得无限循环。

Workflow self-improvement is allowed only as bounded RSI: create `docs/governance/improvements/{YYYYMMDD}-{slug}/SPEC.md`, run the same Spec -> Matrix -> Tasks -> Plan -> Prompt -> Code gates, and obey `CONSTITUTION.md` §14 for protected files.

详见 `docs/governance/STRUCTURAL-SCORING.md` 与 `docs/governance/scoring/ARBITER-PROTOCOL.md`。

## Stage Contract

| Stage   | Executor         | Team Scorers (并行)                                      | Gate（唯一）                                                                         |
| ------- | ---------------- | -------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| Spec    | `spec`           | claude / codex / copilot `spec-structural-score` + rules | `composite_score >= 98` 且无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内 |
| Matrix  | `matrix`         | `matrix-structural-score` × 3 + rules                    | `composite_score >= 98` 且无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内 |
| Tasks   | `task-split`     | `tasks-structural-score` × 3 + rules                     | `composite_score >= 98` 且无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内 |
| Plan    | `task-planner`   | `plan-structural-score` × 3 + rules                      | `composite_score >= 98` 且无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内 |
| Prompt  | `prompt-builder` | `prompt-structural-score` × 3 + rules                    | `composite_score >= 98` 且无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内 |
| Code    | `task-executor`  | `code-structural-score` × 3 + rules                      | `composite_score >= 98` 且无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内 |

Arbiter agent：`pipeline-arbiter`（三运行时均有等价实现，结果等价）。
状态目录由运行时决定：

- Claude：`.omc/state/pipeline/{module}/{stage}/{scores/,verdict.json,attempts.json}`
- Codex：`.omx/state/pipeline/{module}/{stage}/{scores/,verdict.json,attempts.json}`
- Copilot：`.copilot/state/pipeline/{module}/{stage}/{scores/,verdict.json,attempts.json}`

每个阶段在三 LLM 评分后、调用 arbiter 前，必须运行规则引擎评分：

```bash
python3 scripts/rule-scorer.py <stage> <module> --runtime <claude|codex|copilot>
# 默认读取 SPEC_PIPELINE_RUNTIME；未设置时写入 .omc/state/pipeline/<module>/<stage>/scores/rules.json
```

`rules.json` 是宪法 §14.4 要求的异构第 4 源；arbiter 期望 4 个 scores/*.json 文件齐全。

## Execution Rules

1. Work one module at a time.
2. Do not code from a Draft spec.
3. **Every stage must pass team-scoring gate (`composite_score = min(claude.score, codex.score, copilot.score, rules.score) >= 98`, no redline, no LLM low confidence, bounded LLM score spread, heterogeneous divergence <= 15) before advancing. This is the only gate.**
4. **Every stage uses an agent team: executor + 3 LLM scorers + rule-scorer.py + pipeline-arbiter.**
5. Do not skip Matrix or Tasks before Plan.
6. Do not ask `task-executor` to implement more than one task unless the user explicitly requests a batch.
7. When using `--stage`, verify upstream artifacts AND upstream verdicts (`verdict.json` gate=pass) exist first.
8. When using `--from`, resume from that stage; downstream `verdict.json` and `scores/` must be re-generated.
9. Update `TRACEABILITY.md` and task status after each code task.
10. Never bypass scoring gate by editing `verdict.json` manually. There is no human override path.
11. Enforce bounded RSI: after 3 failed attempts in one stage, escalate upstream; after 18 total gate failures, write `pipeline_blocked` plus `PIPELINE-RETROSPECTIVE.md` and stop automatic advancement.
12. Do not modify protected workflow/rubric/agent/arbiter files through normal repair routing. Open a workflow-improvement spec and apply `CONSTITUTION.md` §14.

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
{state_root}/pipeline/{module}/{stage}/
├── scores/
│   ├── claude.json   ├── claude.md
│   ├── codex.json    ├── codex.md
│   ├── copilot.json  ├── copilot.md
│   └── rules.json
├── verdict.json      # arbiter output (gate=pass|fail)
└── attempts.json     # retry counter & escalation chain
```

Top-level pipeline state:

```text
{state_root}/pipeline/{module}.json
{state_root}/pipeline/{module}/repair-budget.json
{state_root}/pipeline/{module}/pipeline_blocked.json
module/{module}/PIPELINE-RETROSPECTIVE.md
```

## Final Report

End with:

- current stage and completed stages
- created or updated artifacts
- active task, if code started
- validation evidence
- blockers or remaining gates
