# Context Packet: TASK-XLIB-003

## Context

TASK-XLIB-003 implements the Config and Version slice for `xlib-standard`.
Use `module/xlib-standard/SPEC.md`, `module/xlib-standard/TRACEABILITY.md`, `module/xlib-standard/tasks/TASK-XLIB-003.md`, and `module/xlib-standard/PLAN.md` as the current governance inputs.

Relevant target files for the implementation are `pkg/templatex/doc.go`, `pkg/templatex/config.go`, and `pkg/templatex/config_test.go`.

## Scope

- Implement the `Config` type, `Validate` behavior, and `Sanitize` behavior for the template package.
- Implement the Version API described by TASK-XLIB-003.
- Keep the implementation in the target package surface documented by `docs/standard.md`.

## Non-scope

- Do not implement Error, Client, Health, Metrics, release manifest, or final generated-library checks in this task.
- Do not add external dependencies.
- Do not change CI or release scripts except where TASK-XLIB-003 explicitly requires local test invocation support.

## Acceptance

- TASK-XLIB-003 covers the Config acceptance checks for missing required fields, negative timeout, and secret redaction.
- TASK-XLIB-003 covers the Version acceptance check for module path, version, commit, and build time fields.
- The changed files remain consistent with `module/xlib-standard/TRACEABILITY.md`.

## Validation

```bash
GOWORK=off go test ./pkg/templatex/ -run TestConfig -v
GOWORK=off go test ./pkg/templatex/ -run TestVersion -v
python3 scripts/rule-scorer.py prompt xlib-standard --runtime codex --out /tmp/xlib-standard-prompt-rules.json
```
