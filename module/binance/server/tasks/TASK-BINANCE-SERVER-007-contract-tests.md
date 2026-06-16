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
