---
id: TASK-BINANCE-003
title: "Client documentation task set"
priority: P0
scope: "Define client docs for product catalogs, canonical mapping, spool/checkpoint, gRPC sender, and admin boundaries."
acceptance_criteria:
  - "AC-001: FR-001 — Client docs cover all supported Binance product lines and connector responsibilities."
  - "AC-002: FR-002 — Client mapping uses canonical domain-market identity and envelope semantics."
  - "AC-004: FR-004/BR-003 — Checkpoint advancement depends on durable server ACK semantics."
---
# TASK-BINANCE-003 Client documentation task set

## Machine-readable task

```yaml
task_id: TASK-BINANCE-003
module: binance
scope: "Define client docs for product catalogs, canonical mapping, spool/checkpoint, gRPC sender, and admin boundaries."
spec_ref:
  - "module/binance/SPEC.md#FR-001"
  - "module/binance/SPEC.md#FR-002"
  - "module/binance/SPEC.md#FR-004"
files:
  - "module/binance/client/README.md"
  - "module/binance/client/SPEC.md"
  - "module/binance/client/TRACEABILITY.md"
  - "module/binance/client/IMPLEMENTATION-PLAN.md"
  - "module/binance/client/tasks/TASK-*.md"
acceptance_criteria:
  - "AC-001: FR-001 — Client docs cover all supported Binance product lines and connector responsibilities."
  - "AC-002: FR-002 — Client mapping uses canonical domain-market identity and envelope semantics."
  - "AC-004: FR-004/BR-003 — Checkpoint advancement depends on durable server ACK semantics."
depends_on:
  - "TASK-BINANCE-001"
  - "TASK-BINANCE-002"
priority: P0
status: pending
```

## Objective

Define client docs for product catalogs, canonical mapping, spool/checkpoint, gRPC sender, and admin boundaries.

## Scope

- Spec references: FR-001, FR-002, FR-004
- Files likely to change:
  - `module/binance/client/README.md`
  - `module/binance/client/SPEC.md`
  - `module/binance/client/TRACEABILITY.md`
  - `module/binance/client/IMPLEMENTATION-PLAN.md`
  - `module/binance/client/tasks/TASK-*.md`


## Non-scope

No server ingest acceptance, dedupe, downstream dispatch, or physical storage implementation.

## Acceptance Criteria

- AC-001: FR-001 — Client docs cover all supported Binance product lines and connector responsibilities.
- AC-002: FR-002 — Client mapping uses canonical domain-market identity and envelope semantics.
- AC-004: FR-004/BR-003 — Checkpoint advancement depends on durable server ACK semantics.

## Test Plan

- TC-004: python3 scripts/rule-scorer.py tasks binance --runtime codex
- TC-005: Client TRACEABILITY rows cite AC-Cxx IDs for checkpoint behavior.

## Dependencies

- `TASK-BINANCE-001`
- `TASK-BINANCE-002`

