# TASK-BINANCE-CLIENT-004 USDⓈ-M Futures Connector

## Objective

Collect Binance USDⓈ-M futures market-data events and normalize them.

## Scope

Initial scope:

- ticker
- trade
- kline/bar
- funding-related market facts where supported
- depth/update events where applicable

## Deliverables

- USDⓈ-M connector lifecycle
- subscription config
- reconnect handling
- normalized event output
- futures-specific metadata tests

## Acceptance Criteria

- connector annotates events with ProductLine `um_perp`（USDⓈ-M）.
- `BTCUSDT` `um_perp` USDⓈ-M does not collide with Spot `BTCUSDT`.
- perpetual and dated contracts can be represented.
- connector preserves exchange sequence/update ids where available.
- connector does not own canonical ProductLine definition.

## Dependencies

- CLIENT-001 catalog
- CLIENT-002 parser
