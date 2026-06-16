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
