# TASK-BINANCE-SERVER-002 Validation

## Objective

Validate incoming `domain_market.MarketFactEnvelope` JSON messages from `natsx` before storage/fanout.

## Scope

Validation covers:

- envelope structure
- product-line support
- instrument identity
- event type
- event time
- idempotency key
- source metadata
- payload shape
- schema/version compatibility

## Deliverables

- validator package
- reject reason model
- validation fixtures
- tests for valid/invalid events

## Acceptance Criteria

- missing idempotency key is rejected.
- unknown product line is rejected.
- malformed instrument identity is rejected.
- payload mismatch is rejected.
- validation rejects do not write storage/fanout and do not Ack.
- reject reason is machine-readable.

## Dependencies

- SERVER-010
- `module/domain_market`
