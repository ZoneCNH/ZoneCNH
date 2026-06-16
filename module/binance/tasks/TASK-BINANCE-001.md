---
id: TASK-BINANCE-001
title: "Root requirements and boundary docs"
priority: P0
scope: "Normalize root entrypoint docs for product-line support, instrument identity, and boundary gates."
acceptance_criteria:
  - "AC-001: FR-001 — Root docs describe Spot, USDⓈ-M, COIN-M, and Options product-line support."
  - "AC-002: FR-002 — Root docs define canonical ProductLine and InstrumentKey expectations without redefining domain types."
  - "AC-007: FR-007/BR-002/BR-003 — Boundary gates document client/server separation."
---
# TASK-BINANCE-001 Root requirements and boundary docs

## Machine-readable task

```yaml
task_id: TASK-BINANCE-001
module: binance
scope: "Normalize root entrypoint docs for product-line support, instrument identity, and boundary gates."
spec_ref:
  - "module/binance/SPEC.md#FR-001"
  - "module/binance/SPEC.md#FR-002"
  - "module/binance/SPEC.md#FR-007"
files:
  - "module/binance/goal.md"
  - "module/binance/README.md"
  - "module/binance/SPEC.md"
  - "module/binance/BOUNDARY-GATES.md"
acceptance_criteria:
  - "AC-001: FR-001 — Root docs describe Spot, USDⓈ-M, COIN-M, and Options product-line support."
  - "AC-002: FR-002 — Root docs define canonical ProductLine and InstrumentKey expectations without redefining domain types."
  - "AC-007: FR-007/BR-002/BR-003 — Boundary gates document client/server separation."
depends_on:
  - "TASK-BINANCE-000"
priority: P0
status: pending
```

## Objective

Normalize root entrypoint docs for product-line support, instrument identity, and boundary gates.

## Scope

- Spec references: FR-001, FR-002, FR-007
- Files likely to change:
  - `module/binance/goal.md`
  - `module/binance/README.md`
  - `module/binance/SPEC.md`
  - `module/binance/BOUNDARY-GATES.md`


## Non-scope

No client/server submodule task rewrites and no runtime code implementation.

## Acceptance Criteria

- AC-001: FR-001 — Root docs describe Spot, USDⓈ-M, COIN-M, and Options product-line support.
- AC-002: FR-002 — Root docs define canonical ProductLine and InstrumentKey expectations without redefining domain types.
- AC-007: FR-007/BR-002/BR-003 — Boundary gates document client/server separation.

## Test Plan

- TC-001: python3 scripts/rule-scorer.py spec binance --runtime codex
- TC-007: Review BOUNDARY-GATES.md for client/server import and ownership gates.

## Dependencies

- `TASK-BINANCE-000`

