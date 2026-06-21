# TASK-BINANCE-CLIENT-011 Publisher / Envelope Tests

## Objective

Verify client compatibility with `domain_market` envelope semantics and `natsx` publishing behavior.

## Scope

Tests cover:

- `MarketFactEnvelope` encoding
- `natsx` subject selection
- JetStream PubAck handling
- publish retry/backoff behavior
- terminal serialization failure handling
- no server-internal dependency

## Deliverables

- publisher tests
- golden envelope fixtures
- PubAck/retry fixtures
- compatibility tests against `domain_market` and `natsx`

## Acceptance Criteria

- client can serialize a valid `MarketFactEnvelope`.
- client publishes to the configured `natsx` subject.
- client treats JetStream PubAck as publish evidence.
- client retries retryable publish failures without mutating server state.
- client treats terminal serialization/schema failures as skipped with observability.
- client does not depend on server internal packages.

## Dependencies

- `module/domain_market`
- `module/natsx`
- CLIENT-007
- CLIENT-014
