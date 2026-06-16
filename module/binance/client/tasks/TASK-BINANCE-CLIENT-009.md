---
task_id: TASK-BINANCE-CLIENT-009
related_requirements:
  - FR-007
  - FR-008
scope: >
  The client persists events before send and tracks durable server acceptance.
acceptance_criteria:
  - "event is persisted before first send attempt."
  - "process restart preserves pending events."
  - "checkpoint advances only after durable server ACK."
  - "gRPC write success alone does not advance checkpoint."
  - "duplicate sends after restart are safe when paired with server idempotency."
  - "terminal rejects are retained or exported according to policy."
---
# TASK-BINANCE-CLIENT-009 Spool and Checkpoint

## Objective

Implement durable local spool and ACK-based checkpoint.

## Scope

The client persists events before send and tracks durable server acceptance.


## Non-scope

- Does not change behavior outside `module/binance/client`.
- Does not define canonical domain source of truth or server persistence semantics.

## Deliverables

- SQLite spool schema
- checkpoint store
- state transition logic
- compaction/retention policy
- restart recovery tests

## Spool States

```text
pending
sending
acked
failed_retryable
failed_terminal
```

## Acceptance Criteria

- event is persisted before first send attempt.
- process restart preserves pending events.
- checkpoint advances only after durable server ACK.
- gRPC write success alone does not advance checkpoint.
- duplicate sends after restart are safe when paired with server idempotency.
- terminal rejects are retained or exported according to policy.

## Dependencies

- CLIENT-008 gRPC sender
- SERVER-004 ACK semantics
