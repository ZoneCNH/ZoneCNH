# TASK-BINANCE-SERVER-007 Consumer / Envelope Tests

## Objective

Verify server compatibility with `domain_market` envelope semantics, `natsx` consumer behavior, and durable processing expectations.

## Scope

Tests cover:

- JetStream consumer startup
- envelope validation
- ManualAck after durable processing
- terminal reject/negative ack behavior
- duplicate behavior
- redelivery behavior

## Deliverables

- consumer tests
- client-published envelope fixtures
- ManualAck/reject fixtures
- duplicate and redelivery tests

## Acceptance Criteria

- server accepts valid client request.
- server rejects invalid request with machine-readable reason.
- server ManualAck occurs only after validation, idempotency, durable storage, and `kafkax` handoff succeed.
- duplicate idempotency key does not duplicate storage or `kafkax` fanout.
- server does not require client internal packages.

## Dependencies

- SERVER-010 through SERVER-016
- CLIENT-011
