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
3. **Every stage must pass team-scoring gate**: 3 platforms (claude/codex/copilot) score in parallel; `pipeline-arbiter` enforces `composite_score = min(claude.score, codex.score, copilot.score)`, `composite_score >= 98`, no redline, no low confidence, and bounded score spread. This is the only gate at every stage.
4. After Spec stage gate passes, arbiter auto-flips SPEC.md to `Status: Approved`. No separate `spec-review` Go/No-Go required.
5. Generate or validate `TRACEABILITY.md` with `matrix`; then matrix team-scoring + arbiter.
6. Split into bounded task specs with `task-split`; then tasks team-scoring + arbiter.
7. Generate `IMPLEMENTATION-PLAN.md` with `task-planner`; then plan team-scoring + arbiter.
8. Generate one ready task prompt with `prompt-builder`; then prompt team-scoring + arbiter.
9. Implement exactly one task with `task-executor`; then code team-scoring + arbiter.
10. After every gate fail: auto-route back to current executor for repair. 3 fails → auto-route to upstream stage. Continues looping all the way back to spec if needed. **No human escalation, no manual override.**
11. State directory: `.omx/state/pipeline/{module}/{stage}/{scores/,verdict.json,attempts.json}`.
12. Reference: `specs/STRUCTURAL-SCORING.md`, `specs/scoring/ARBITER-PROTOCOL.md`, `specs/scoring/RUBRIC-*.md`.

## Output

Report:

- completed stages
- created or updated artifacts
- active task
- validation evidence
- blockers or remaining gates
