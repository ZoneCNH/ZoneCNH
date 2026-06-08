---
description: Run the Spec -> Matrix -> Tasks -> Plan -> Prompt -> Code workflow for one module.
argument-hint: <module> [--from stage|--stage stage]
allowed-tools: Read, Write, Edit, MultiEdit, Bash, Grep, Glob, Task
---

# Spec Code Pipeline

Run the complete repo-local development workflow for `$ARGUMENTS`:

```text
Spec -> Matrix -> Tasks -> Plan -> Prompt -> Code
```

Expanded gate sequence:

```text
spec
  -> [3-platform team scoring] -> pipeline-arbiter (gate)
  -> auto-flip Status: Approved
  -> matrix
  -> [3-platform team scoring] -> pipeline-arbiter (gate)
  -> task-split
  -> [3-platform team scoring] -> pipeline-arbiter (gate)
  -> task-planner
  -> [3-platform team scoring] -> pipeline-arbiter (gate)
  -> prompt-builder
  -> [3-platform team scoring] -> pipeline-arbiter (gate)
  -> task-executor
  -> [3-platform team scoring] -> pipeline-arbiter (gate)
```

## Rules

1. Resolve the module as `specs/{module}/`.
2. Verify `SPEC.md` exists or create/revise it with the `spec` agent.
3. **Every stage must pass team-scoring gate**: 3 LLM platforms (claude/codex/copilot) + 1 rule engine (`scripts/rule-scorer.py`) score in parallel; `pipeline-arbiter` enforces `composite_score = min(claude.score, codex.score, copilot.score, rules.score)`, `composite_score >= 98`, no redline, no low confidence, bounded score spread, and heterogeneous divergence ≤ 15. This is the only gate at every stage.
4. After Spec stage gate passes, arbiter auto-flips SPEC.md to `Status: Approved`. No separate `spec-review` Go/No-Go required.
5. Generate or validate `TRACEABILITY.md` with `matrix`; then matrix team-scoring + arbiter.
6. Split into bounded task specs with `task-split`; then tasks team-scoring + arbiter.
7. Generate `IMPLEMENTATION-PLAN.md` with `task-planner`; then plan team-scoring + arbiter.
8. Generate one ready task prompt with `prompt-builder`; then prompt team-scoring + arbiter.
9. Implement exactly one task with `task-executor`; then code team-scoring + arbiter.
10. After every gate fail: auto-route back to current executor for repair. 3 fails in the same stage → auto-route to upstream stage. Default limits: `max_stage_attempts = 3`, `max_total_gate_failures = 18`.
11. If the total failure budget is exhausted, write `pipeline_blocked` and `specs/{module}/PIPELINE-RETROSPECTIVE.md`; do not continue after budget exhaustion.
12. Workflow self-improvement must be a meta-spec under `specs/workflow-improvement/{YYYYMMDD}-{slug}/SPEC.md`, pass the same 98-point pipeline, and obey `CONSTITUTION.md` §14 for protected files.
13. State directory: `.omx/state/pipeline/{module}/{stage}/{scores/,verdict.json,attempts.json}` plus top-level repair budget and blocked state.
14. Reference: `specs/STRUCTURAL-SCORING.md`, `specs/scoring/ARBITER-PROTOCOL.md`, `specs/scoring/RUBRIC-*.md`.

## Output

Report:

- completed stages
- created or updated artifacts
- active task
- validation evidence
- blockers or remaining gates
