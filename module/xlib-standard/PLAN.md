# xlib-standard Implementation Plan

> 本 Plan 覆盖 xlib-standard 五类职责中后四类的实现任务：Go Reference Template、Generator、Harness Gate、Evidence Runtime。
> 标准事实源（文档规范）的完整定义见 `goal.md`，其验证通过分析管线（`ANALYSIS.md` / `FR-DETAIL.md` / `TRACEABILITY.md`）完成，不在此 Plan 中重复。
>
> Root-level plan for the Spec -> Code scorer. Detailed historical planning remains in `module/xlib-standard/plan/PLAN.md`.

## Steps

> 以下任务覆盖 G-1 至 G-5（Go Reference Template / Generator / Gate / Evidence Runtime）。G-0（标准事实源）由 `goal.md`、`ANALYSIS.md` 和分析管线覆盖，不属于本 Plan 的实现任务。

- TASK-XLIB-000: prune governance runtime and unrelated runtime directories from the target xlib template repository.
- TASK-XLIB-001: align `README.md`, `docs/standard.md`, and `docs/INDEX.md` with the v1 public standard.
- TASK-XLIB-002: rebuild the minimal make, lint, trace, render, and CI gate skeleton.
- TASK-XLIB-003: implement Config, Validate, Sanitize, and Version APIs in `pkg/templatex/`.
- TASK-XLIB-006: implement Error, ErrorKind, wrapping, Client construction, and idempotent Close behavior.
- TASK-XLIB-007: implement Health and Metrics reference interfaces with low-cardinality labels.
- TASK-XLIB-008: complete the public API template and verify that the generated template compiles.
- TASK-XLIB-004: generate the release manifest and compatibility metadata.
- TASK-XLIB-005: run final generated-library checks, template-residue checks, checksum validation, and release readiness gates.

## Dependencies

- TASK-XLIB-001 and TASK-XLIB-002 depend on TASK-XLIB-000 because pruning defines the target repository shape.
- TASK-XLIB-003 depends on TASK-XLIB-001 because Config and Version APIs follow the published standard.
- TASK-XLIB-006 depends on TASK-XLIB-003 because Client validation and error wrapping reuse the Config and ErrorKind contracts.
- TASK-XLIB-007 depends on TASK-XLIB-006 because Health and Metrics report client lifecycle and error status.
- TASK-XLIB-008 depends on TASK-XLIB-007 because the final public API template must expose the complete standard surface.
- TASK-XLIB-004 depends on TASK-XLIB-002 and TASK-XLIB-008 because manifest generation needs working gates and complete template APIs.
- TASK-XLIB-005 depends on all prior tasks because it validates the generated repository and final release artifacts.

## Validation

Run scorer checks for the local governance artifacts before code execution:

```bash
python3 scripts/rule-scorer.py spec xlib-standard --runtime codex --out /tmp/xlib-standard-spec-rules.json
python3 scripts/rule-scorer.py matrix xlib-standard --runtime codex --out /tmp/xlib-standard-matrix-rules.json
python3 scripts/rule-scorer.py tasks xlib-standard --runtime codex --out /tmp/xlib-standard-tasks-rules.json
python3 scripts/rule-scorer.py plan xlib-standard --runtime codex --out /tmp/xlib-standard-plan-rules.json
python3 scripts/rule-scorer.py prompt xlib-standard --runtime codex --out /tmp/xlib-standard-prompt-rules.json
python3 scripts/rule-scorer.py code xlib-standard --runtime codex --out /tmp/xlib-standard-code-rules.json
```

Run target-repository checks after the implementation files exist:

```bash
GOWORK=off go test ./...
bash scripts/check_boundary.sh
bash scripts/check_contracts.sh
```

## Risks

- The target xlib repository may not be checked out in this documentation workspace, so code validation can be limited to governance artifact scoring here.
- Old nested plan and prompt files still exist for history and may contain pre-split task labels, but the current scorer reads only root `PLAN.md` and root `TASK-*-PROMPT.md`.
- TASK-XLIB-005 spans generated output and release readiness, so it must run after all package and gate tasks are complete.

## Rollback

- Revert `module/xlib-standard/SPEC.md`, `module/xlib-standard/TRACEABILITY.md`, root `PLAN.md`, root `TASK-*-PROMPT.md`, and `module/xlib-standard/tasks/TASK-*.md` changes if scorer evidence regresses.
- Restore the previous task split only if the scorer contract is changed to allow non-numeric suffixes again.
- Keep generated target-repository code rollback separate from governance artifact rollback.
