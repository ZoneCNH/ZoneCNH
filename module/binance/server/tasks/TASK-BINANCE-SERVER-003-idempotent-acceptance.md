# TASK-BINANCE-SERVER-003 Idempotent Acceptance

## Objective

Ensure each accepted idempotency key produces at most one durable storage mutation and at most one `kafkax` fanout.

## Scope

Server-side idempotency covers:

- first accept
- duplicate accept
- duplicate with same payload
- duplicate with conflicting payload
- retryable failures before acceptance
- restart/recovery behavior depending on implementation

## Deliverables

- idempotency store interface
- acceptance state model
- duplicate/conflict behavior
- tests

## Acceptance Criteria

- first valid event is accepted.
- duplicate valid event with same idempotency key does not duplicate storage or `kafkax` fanout.
- duplicate conflicting event is rejected as conflict.
- retryable failure before durable acceptance can be retried.
- idempotency decision is available to ACK logic.

## Dependencies

- SERVER-002 validation
