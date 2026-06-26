# TASK-BINANCE-CLIENT-003 Spot Connector

## Objective

Collect Binance Spot market_data events and normalize them into client internal events.

## Scope

Initial scope:

- ticker
- trade
- kline/bar
- depth/update events where applicable

## Deliverables

- Spot connector lifecycle
- subscription config
- reconnect handling
- normalized event output
- fixtures and tests

## Acceptance Criteria

- connector annotates events with ProductLine Spot.
- connector preserves exchange event time.
- connector records local receive time.
- connector handles reconnect without changing canonical identity.
- connector does not emit canonical events directly; mapper owns canonical conversion.

## Dependencies

- CLIENT-001 catalog
- CLIENT-002 parser
