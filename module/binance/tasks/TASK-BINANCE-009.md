---
id: TASK-BINANCE-009
title: "Runtime server implementation slice"
priority: P0
scope: "Implement the server runtime slice for gRPC ingest, validation, idempotent acceptance, ACK, and downstream dispatch."
acceptance_criteria:
  - "AC-009: FR-003 — Server accepts MarketDataService ingest streams from the generated contract."
  - "AC-009: FR-005/BR-007 — Duplicate idempotency keys are accepted exactly once and return stable ACK semantics."
---
# TASK-BINANCE-009 Runtime server implementation slice

## Machine-readable task

```yaml
task_id: TASK-BINANCE-009
module: binance
scope: "Implement the server runtime slice for gRPC ingest, validation, idempotent acceptance, ACK, and downstream dispatch."
spec_ref:
  - "module/binance/SPEC.md#FR-003"
  - "module/binance/SPEC.md#FR-005"
files:
  - "cmd/binance-server/main.go"
  - "internal/server/ingest.go"
  - "internal/server/validator.go"
  - "internal/server/idempotency.go"
  - "internal/server/dispatch.go"
acceptance_criteria:
  - "AC-009: FR-003 — Server accepts MarketDataService ingest streams from the generated contract."
  - "AC-009: FR-005/BR-007 — Duplicate idempotency keys are accepted exactly once and return stable ACK semantics."
depends_on:
  - "TASK-BINANCE-004"
  - "TASK-BINANCE-006"
priority: P0
status: pending
```

## Objective

Implement the server runtime slice for gRPC ingest, validation, idempotent acceptance, ACK, and downstream dispatch.

## Scope

- Spec references: FR-003, FR-005
- Files likely to change:
  - `cmd/binance-server/main.go`
  - `internal/server/ingest.go`
  - `internal/server/validator.go`
  - `internal/server/idempotency.go`
  - `internal/server/dispatch.go`


## Non-scope

No exchange connectors, client checkpoint persistence, or physical storage/query ownership.

## Acceptance Criteria

- AC-009: FR-003 — Server accepts MarketDataService ingest streams from the generated contract.
- AC-009: FR-005/BR-007 — Duplicate idempotency keys are accepted exactly once and return stable ACK semantics.

## Test Plan

- TC-003: go test ./module/binance/server/...
- TC-005: Idempotency tests cover first accept and duplicate replay.

## Dependencies

- `TASK-BINANCE-004`
- `TASK-BINANCE-006`

