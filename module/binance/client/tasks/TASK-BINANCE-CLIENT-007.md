---
task_id: TASK-BINANCE-CLIENT-007
related_requirements:
  - FR-004
  - FR-005
  - FR-006
scope: >
  The mapper converts internal client normalized events into domain/contract-compatible envelopes.
acceptance_criteria:
  - "mapper uses `domain-market` canonical types."
  - "mapper does not define independent canonical enum source of truth."
  - "idempotency keys are stable across retry."
  - "bars include interval/open-time dimensions in idempotency key."
  - "trades include trade id where available."
  - "depth updates include sequence/update dimensions where available."
  - "mapping covers all four product lines."
---
# TASK-BINANCE-CLIENT-007 Market Event Mapper

## Objective

Map normalized Binance client events to canonical market events.

## Scope

The mapper converts internal client normalized events into domain/contract-compatible envelopes.


## Non-scope

- Does not change behavior outside `module/binance/client`.
- Does not define canonical domain source of truth or server persistence semantics.

## Deliverables

- mapper package
- idempotency key generation
- event-type mapping fixtures
- product-line mapping tests

## Acceptance Criteria

- mapper uses `domain-market` canonical types.
- mapper does not define independent canonical enum source of truth.
- idempotency keys are stable across retry.
- bars include interval/open-time dimensions in idempotency key.
- trades include trade id where available.
- depth updates include sequence/update dimensions where available.
- mapping covers all four product lines.

## Dependencies

- CLIENT-001 through CLIENT-006
- `module/domain-market`
- `module/contracts`
