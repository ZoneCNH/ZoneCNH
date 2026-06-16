---
id: TASK-BINANCE-000
title: "Remove legacy binance-market references"
priority: P0
scope: "Remove active binance-market references and keep the Binance module split on client/server boundaries."
acceptance_criteria:
  - "AC-000: FR-007/BR-001 — Active root docs no longer describe binance-market as current architecture."
  - "AC-000: BR-001 — A no-legacy gate rejects reintroduction of binance-market references."
---
# TASK-BINANCE-000 Remove legacy binance-market references

## Machine-readable task

```yaml
task_id: TASK-BINANCE-000
module: binance
scope: "Remove active binance-market references and keep the Binance module split on client/server boundaries."
spec_ref:
  - "module/binance/SPEC.md#FR-007"
files:
  - "module/binance/BOUNDARY-GATES.md"
  - "module/binance/TRACEABILITY.md"
  - "module/binance/SPEC.md"
acceptance_criteria:
  - "AC-000: FR-007/BR-001 — Active root docs no longer describe binance-market as current architecture."
  - "AC-000: BR-001 — A no-legacy gate rejects reintroduction of binance-market references."
depends_on:
priority: P0
status: pending
```

## Objective

Remove active binance-market references and keep the Binance module split on client/server boundaries.

## Scope

- Spec references: FR-007
- Files likely to change:
  - `module/binance/BOUNDARY-GATES.md`
  - `module/binance/TRACEABILITY.md`
  - `module/binance/SPEC.md`


## Non-scope

No runtime implementation, storage/query/strategy ownership, or exchange connector changes.

## Acceptance Criteria

- AC-000: FR-007/BR-001 — Active root docs no longer describe binance-market as current architecture.
- AC-000: BR-001 — A no-legacy gate rejects reintroduction of binance-market references.

## Test Plan

- TC-000: rg "binance-market" module/binance returns only explicit historical/deprecated references.

## Dependencies

- None.

