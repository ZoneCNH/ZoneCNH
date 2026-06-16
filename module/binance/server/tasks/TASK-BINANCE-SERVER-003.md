---
task_id: TASK-BINANCE-SERVER-003
related_requirements:
  - FR-004
  - FR-005
scope: >
  Server-side idempotency covers:
acceptance_criteria:
  - "first valid event is accepted."
  - "duplicate valid event with same idempotency key does not duplicate dispatch."
  - "duplicate conflicting event is rejected as conflict."
  - "retryable failure before durable acceptance can be retried."
  - "idempotency decision is available to ACK logic."
---
# TASK-BINANCE-SERVER-003 Idempotent Acceptance

## Objective

Ensure each accepted idempotency key produces at most one downstream dispatch.

## Scope

Server-side idempotency covers:

- first accept
- duplicate accept
- duplicate with same payload
- duplicate with conflicting payload
- retryable failures before acceptance
- restart/recovery behavior depending on implementation


## Non-scope

- Does not change behavior outside `module/binance/server`.
- Does not import or modify client internals.

## Deliverables

- idempotency store interface
- acceptance state model
- duplicate/conflict behavior
- tests

## Acceptance Criteria

- first valid event is accepted.
- duplicate valid event with same idempotency key does not duplicate dispatch.
- duplicate conflicting event is rejected as conflict.
- retryable failure before durable acceptance can be retried.
- idempotency decision is available to ACK logic.

## Dependencies

- SERVER-002 validation
