---
description: Run the Spec -> Matrix -> Tasks -> Plan -> Prompt -> Code workflow with 4-source team scoring at every stage.
argument-hint: <module> [--from stage|--stage stage]
---

# Spec Code Pipeline (Copilot)

Run the complete repo-local development workflow for `$ARGUMENTS` with four-source team scoring at every stage:

```text
Spec -> Matrix -> Tasks -> Plan -> Prompt -> Code
```

Every stage: executor → 3 LLM scorers (claude/codex/copilot) + 1 rule scorer (`scripts/rule-scorer.py`) in parallel → pipeline-arbiter → gate.

## Gate

`composite_score = min(claude.score, codex.score, copilot.score, rules.score)` AND `composite_score >= 98` AND no redline AND no LLM low confidence AND bounded LLM score spread AND rules divergence <= 15. Pure machine gate.

## Rules

1. Module resolves to `module/{module}/`.
2. Every stage produces team scores under `.copilot/state/pipeline/{module}/{stage}/scores/` and verdict under `verdict.json`.
3. After Spec stage gate passes, arbiter auto-flips SPEC.md to `Status: Approved`. No separate `spec-review` Go required.
4. Fail routing: 1-2 attempts retry current stage; the 3rd failed attempt auto-routes to upstream stage, continuing up to spec if needed.
5. Bounded RSI: default `max_stage_attempts = 3`, `max_total_gate_failures = 18`; budget exhaustion writes `pipeline_blocked` and `module/{module}/PIPELINE-RETROSPECTIVE.md`, then stops automatic advancement.
6. Workflow self-improvement must start as `docs/governance/improvements/{YYYYMMDD}-{slug}/SPEC.md`, pass the same gates, and obey `CONSTITUTION.md` §14 for protected files.
7. No manual override of `verdict.json`. No human escalation path for turning a failed stage into pass.

## Reference

- `docs/governance/STRUCTURAL-SCORING.md`
- `docs/governance/scoring/ARBITER-PROTOCOL.md`
- `docs/governance/scoring/RUBRIC-{stage}.md`
- `.copilot/AGENTS.md`

## Output

Report per stage: executor agent, 4 source scores, arbiter verdict, gate status, next action.
