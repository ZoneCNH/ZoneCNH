---
task_id: TASK-BINANCE-SERVER-007
related_requirements:
  - FR-001
  - FR-002
  - FR-003
  - FR-004
  - FR-005
  - FR-006
  - FR-007
  - FR-008
scope: >
  Tests cover:
acceptance_criteria:
  - "server accepts valid client request."
  - "server rejects invalid request with machine-readable reason."
  - "server ACK drives client checkpoint fixture."
  - "duplicate idempotency key does not duplicate dispatch."
  - "server does not require client internal packages."
---
# TASK-BINANCE-SERVER-007 Contract Tests

## Objective

Verify server compatibility with contracts-defined gRPC service and client expectations.

## Scope

Tests cover:

- gRPC stream startup
- request validation
- ACK response
- reject response
- duplicate behavior
- reconnect behavior


## Non-scope

- Does not change behavior outside `module/binance/server`.
- Does not import or modify client internals.

## Deliverables

- generated server interface tests
- client fixture tests
- golden ACK/reject fixtures
- duplicate event tests

## Acceptance Criteria

- server accepts valid client request.
- server rejects invalid request with machine-readable reason.
- server ACK drives client checkpoint fixture.
- duplicate idempotency key does not duplicate dispatch.
- server does not require client internal packages.

## Dependencies

- SERVER-001 through SERVER-004
- CLIENT-011
