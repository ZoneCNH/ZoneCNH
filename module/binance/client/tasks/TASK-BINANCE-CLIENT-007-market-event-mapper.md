# TASK-BINANCE-CLIENT-007 Market Event Mapper

## Objective

Map normalized Binance client events to `domain_market.MarketFactEnvelope` payloads.

## Scope

The mapper converts internal client normalized events into `domain_market` envelopes that the `natsx` publisher can serialize. It must not depend on a local proto or contracts-owned gRPC shape.

## Deliverables

- mapper package
- idempotency key generation
- event-type mapping fixtures
- product-line mapping tests

## Acceptance Criteria

- mapper uses `domain_market` canonical types.
- mapper does not define independent canonical enum source of truth.
- idempotency keys are stable across retry.
- bars include interval/open-time dimensions in idempotency key.
- trades include trade id where available.
- depth updates include sequence/update dimensions where available.
- mapping covers all four product lines.

## Dependencies

- CLIENT-001 through CLIENT-006
- `module/domain_market`
