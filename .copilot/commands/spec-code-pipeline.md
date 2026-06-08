---
description: Run the Spec -> Matrix -> Tasks -> Plan -> Prompt -> Code workflow with 3-platform team scoring at every stage.
argument-hint: <module> [--from stage|--stage stage]
---

# Spec Code Pipeline (Copilot)

Run the complete repo-local development workflow for `$ARGUMENTS` with three-platform team scoring at every stage:

```text
Spec -> Matrix -> Tasks -> Plan -> Prompt -> Code
```

Every stage: executor → 3 scorers (claude/codex/copilot) in parallel → pipeline-arbiter → gate.

## Gate

`composite_score = min(claude.score, codex.score, copilot.score)` AND `composite_score >= 98` AND no redline AND no low confidence AND bounded score spread. Pure machine gate.

## Rules

1. Module resolves to `specs/{module}/`.
2. Every stage produces team scores under `.omx/state/pipeline/{module}/{stage}/scores/` and verdict under `verdict.json`.
3. After Spec stage gate passes, arbiter auto-flips SPEC.md to `Status: Approved`. No separate `spec-review` Go required.
4. Fail routing: 1-2 attempts retry current stage; 3rd+ auto-routes to upstream stage, looping all the way to spec if needed.
5. No manual override of `verdict.json`. No human escalation path.

## Reference

- `specs/STRUCTURAL-SCORING.md`
- `specs/scoring/ARBITER-PROTOCOL.md`
- `specs/scoring/RUBRIC-{stage}.md`
- `.copilot/AGENTS.md`

## Output

Report per stage: executor agent, 3 platform scores, arbiter verdict, gate status, next action.
