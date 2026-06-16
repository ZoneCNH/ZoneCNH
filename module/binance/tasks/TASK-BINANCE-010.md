---
id: TASK-BINANCE-010
title: "Runtime admin and boundary gates slice"
priority: P0
scope: "Implement admin endpoint expectations and executable boundary gates for the client/server runtime split."
acceptance_criteria:
  - "AC-010: FR-006/BR-008 — Client and server admin endpoints expose health/readiness without API keys or secrets."
  - "AC-010: FR-007/BR-002/BR-003/BR-005 — CI gates reject client/server cross-imports and forbidden storage/query/strategy ownership."
---
# TASK-BINANCE-010 Runtime admin and boundary gates slice

## Machine-readable task

```yaml
task_id: TASK-BINANCE-010
module: binance
scope: "Implement admin endpoint expectations and executable boundary gates for the client/server runtime split."
spec_ref:
  - "module/binance/SPEC.md#FR-006"
  - "module/binance/SPEC.md#FR-007"
files:
  - "internal/client/admin.go"
  - "internal/server/admin.go"
  - "module/binance/BOUNDARY-GATES.md"
  - "module/binance/RUNTIME-MAPPING.md"
  - "module/binance/IMPLEMENTATION-PLAN.md"
acceptance_criteria:
  - "AC-010: FR-006/BR-008 — Client and server admin endpoints expose health/readiness without API keys or secrets."
  - "AC-010: FR-007/BR-002/BR-003/BR-005 — CI gates reject client/server cross-imports and forbidden storage/query/strategy ownership."
depends_on:
  - "TASK-BINANCE-008"
  - "TASK-BINANCE-009"
  - "TASK-BINANCE-007"
priority: P0
status: pending
```

## Objective

Implement admin endpoint expectations and executable boundary gates for the client/server runtime split.

## Scope

- Spec references: FR-006, FR-007
- Files likely to change:
  - `internal/client/admin.go`
  - `internal/server/admin.go`
  - `module/binance/BOUNDARY-GATES.md`
  - `module/binance/RUNTIME-MAPPING.md`
  - `module/binance/IMPLEMENTATION-PLAN.md`


## Non-scope

No public unauthenticated production admin exposure and no secrets in logs or debug output.

## Acceptance Criteria

- AC-010: FR-006/BR-008 — Client and server admin endpoints expose health/readiness without API keys or secrets.
- AC-010: FR-007/BR-002/BR-003/BR-005 — CI gates reject client/server cross-imports and forbidden storage/query/strategy ownership.

## Test Plan

- TC-006: go test ./module/binance/...
- TC-007: Boundary gate command rejects forbidden imports and legacy binance-market references.

## Dependencies

- `TASK-BINANCE-008`
- `TASK-BINANCE-009`
- `TASK-BINANCE-007`

