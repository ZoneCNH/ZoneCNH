---
id: TASK-BINANCE-006
title: "contracts dependency validation"
priority: P1
scope: "Validate that Binance client/server communication uses module/contracts gRPC and ACK/reject semantics."
acceptance_criteria:
  - "AC-006: FR-003/BR-006 — MarketDataService stream, IngestRequest, and ACK/reject types come from module/contracts."
  - "AC-006: FR-004 — Durable ACK semantics are sufficient for at-least-once client delivery."
  - "AC-006: FR-005/BR-007 — Idempotency keys are stable across retries and duplicate submissions."
---
# TASK-BINANCE-006 contracts dependency validation

## Machine-readable task

```yaml
task_id: TASK-BINANCE-006
module: binance
scope: "Validate that Binance client/server communication uses module/contracts gRPC and ACK/reject semantics."
spec_ref:
  - "module/binance/SPEC.md#FR-003"
  - "module/binance/SPEC.md#FR-004"
  - "module/binance/SPEC.md#FR-005"
files:
  - "module/binance/SPEC.md"
  - "module/binance/client/SPEC.md"
  - "module/binance/server/SPEC.md"
acceptance_criteria:
  - "AC-006: FR-003/BR-006 — MarketDataService stream, IngestRequest, and ACK/reject types come from module/contracts."
  - "AC-006: FR-004 — Durable ACK semantics are sufficient for at-least-once client delivery."
  - "AC-006: FR-005/BR-007 — Idempotency keys are stable across retries and duplicate submissions."
depends_on:
  - "TASK-BINANCE-001"
priority: P1
status: pending
```

## Objective

Validate that Binance client/server communication uses module/contracts gRPC and ACK/reject semantics.

## Scope

- Spec references: FR-003, FR-004, FR-005
- Files likely to change:
  - `module/binance/SPEC.md`
  - `module/binance/client/SPEC.md`
  - `module/binance/server/SPEC.md`


## Non-scope

No protobuf ownership or alternate wire protocol inside module/binance.

## Acceptance Criteria

- AC-006: FR-003/BR-006 — MarketDataService stream, IngestRequest, and ACK/reject types come from module/contracts.
- AC-006: FR-004 — Durable ACK semantics are sufficient for at-least-once client delivery.
- AC-006: FR-005/BR-007 — Idempotency keys are stable across retries and duplicate submissions.

## Test Plan

- TC-003: Contract generation checks are listed for both client sender and server receiver.

## Dependencies

- `TASK-BINANCE-001`

