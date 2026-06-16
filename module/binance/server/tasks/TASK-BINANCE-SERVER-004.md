---
task_id: TASK-BINANCE-SERVER-004
related_requirements:
  - FR-006
scope: >
  ACK logic covers:
acceptance_criteria:
  - "accepted event returns durable ACK."
  - "duplicate already accepted event returns idempotent ACK or equivalent accepted status."
  - "terminal reject is clearly classified."
  - "retryable reject is clearly classified."
  - "client can determine whether checkpoint may advance."
  - "ACK never claims durable acceptance before acceptance boundary is satisfied."
---
# TASK-BINANCE-SERVER-004 Ingest ACK

## Objective

Generate ACK/reject responses that allow client checkpoint progression.

## Scope

ACK logic covers:

- accepted events
- duplicates
- rejects
- retry hints
- stream restart compatibility


## Non-scope

- Does not change behavior outside `module/binance/server`.
- Does not import or modify client internals.

## Deliverables

- ACK model
- reject model
- ACK builder
- tests with client checkpoint fixtures

## Acceptance Criteria

- accepted event returns durable ACK.
- duplicate already accepted event returns idempotent ACK or equivalent accepted status.
- terminal reject is clearly classified.
- retryable reject is clearly classified.
- client can determine whether checkpoint may advance.
- ACK never claims durable acceptance before acceptance boundary is satisfied.

## Dependencies

- SERVER-003 idempotency
- CLIENT-009 checkpoint semantics
