---
task_id: TASK-BINANCE-CLIENT-011
related_requirements:
  - FR-001
  - FR-002
  - FR-003
  - FR-004
  - FR-005
  - FR-006
  - FR-007
  - FR-008
  - FR-009
  - FR-010
scope: >
  Tests cover:
acceptance_criteria:
  - "client can send valid `IngestRequest`."
  - "client handles accepted ACK."
  - "client handles retryable reject."
  - "client handles terminal reject."
  - "client resumes from checkpoint after reconnect."
  - "client does not depend on server internal packages."
---
# TASK-BINANCE-CLIENT-011 Contract Tests

## Objective

Verify client compatibility with contracts-defined gRPC service and server ACK semantics.

## Scope

Tests cover:

- generated gRPC client usage
- request encoding
- ACK handling
- reject handling
- reconnect behavior
- checkpoint behavior


## Non-scope

- Does not change behavior outside `module/binance/client`.
- Does not define canonical domain source of truth or server persistence semantics.

## Deliverables

- mock server tests
- golden request fixtures
- ACK/reject fixtures
- compatibility tests

## Acceptance Criteria

- client can send valid `IngestRequest`.
- client handles accepted ACK.
- client handles retryable reject.
- client handles terminal reject.
- client resumes from checkpoint after reconnect.
- client does not depend on server internal packages.

## Dependencies

- `module/contracts`
- SERVER-001
- SERVER-004
