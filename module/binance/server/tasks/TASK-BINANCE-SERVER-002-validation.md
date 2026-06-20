# TASK-BINANCE-SERVER-002 Validation

## Objective

Validate incoming Binance market_data ingest requests before acceptance.

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
- validation rejects do not dispatch downstream.
- reject reason is machine-readable.

## Dependencies

- SERVER-001
- `module/domain_market`
- `module/contracts`
