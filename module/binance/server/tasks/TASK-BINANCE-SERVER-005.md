---
task_id: TASK-BINANCE-SERVER-005
related_requirements:
  - FR-007
scope: >
  Dispatch starts after server-side acceptance.
acceptance_criteria:
  - "accepted event is dispatched once."
  - "duplicate event is not dispatched again."
  - "validation reject is not dispatched."
  - "dispatch failures are reported."
  - "server does not own physical storage implementation."
  - "server does not expose query APIs."
  - "server does not call strategy APIs."
---
# TASK-BINANCE-SERVER-005 Downstream Dispatch

## Objective

Dispatch accepted Binance market events to downstream exchange-neutral market-data infrastructure.

## Scope

Dispatch starts after server-side acceptance.


## Non-scope

- Does not change behavior outside `module/binance/server`.
- Does not import or modify client internals.

## Deliverables

- downstream port interface usage
- dispatch adapter
- dispatch retry/error handling
- duplicate dispatch tests

## Acceptance Criteria

- accepted event is dispatched once.
- duplicate event is not dispatched again.
- validation reject is not dispatched.
- dispatch failures are reported.
- server does not own physical storage implementation.
- server does not expose query APIs.
- server does not call strategy APIs.

## Dependencies

- SERVER-003 idempotency
- SERVER-004 ACK semantics
- `module/market-data` downstream port
