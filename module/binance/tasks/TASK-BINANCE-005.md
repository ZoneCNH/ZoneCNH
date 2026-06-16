---
id: TASK-BINANCE-005
title: "domain-market dependency validation"
priority: P1
scope: "Validate that Binance docs consume domain-market types for product lines, instrument identity, and event envelopes."
acceptance_criteria:
  - "AC-005: FR-001/BR-004 — ProductLine and supported product classes are consumed from domain-market semantics."
  - "AC-005: FR-002/BR-004/BR-007 — InstrumentKey collision avoidance is documented for spot, futures, and options."
---
# TASK-BINANCE-005 domain-market dependency validation

## Machine-readable task

```yaml
task_id: TASK-BINANCE-005
module: binance
scope: "Validate that Binance docs consume domain-market types for product lines, instrument identity, and event envelopes."
spec_ref:
  - "module/binance/SPEC.md#FR-001"
  - "module/binance/SPEC.md#FR-002"
files:
  - "module/binance/SPEC.md"
  - "module/binance/client/SPEC.md"
  - "module/binance/server/SPEC.md"
acceptance_criteria:
  - "AC-005: FR-001/BR-004 — ProductLine and supported product classes are consumed from domain-market semantics."
  - "AC-005: FR-002/BR-004/BR-007 — InstrumentKey collision avoidance is documented for spot, futures, and options."
depends_on:
  - "TASK-BINANCE-001"
priority: P1
status: pending
```

## Objective

Validate that Binance docs consume domain-market types for product lines, instrument identity, and event envelopes.

## Scope

- Spec references: FR-001, FR-002
- Files likely to change:
  - `module/binance/SPEC.md`
  - `module/binance/client/SPEC.md`
  - `module/binance/server/SPEC.md`


## Non-scope

No redefinition of canonical domain types inside module/binance.

## Acceptance Criteria

- AC-005: FR-001/BR-004 — ProductLine and supported product classes are consumed from domain-market semantics.
- AC-005: FR-002/BR-004/BR-007 — InstrumentKey collision avoidance is documented for spot, futures, and options.

## Test Plan

- TC-007: Cross-product-line same-symbol examples produce distinct canonical identities in task specs.

## Dependencies

- `TASK-BINANCE-001`

