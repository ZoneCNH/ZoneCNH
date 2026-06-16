# TASK-BINANCE-CLIENT-005 COIN-M Futures Connector

## Objective

Collect Binance COIN-M futures market-data events and normalize them.

## Scope

Initial scope:

- ticker
- trade
- kline/bar
- futures-specific market facts where supported
- depth/update events where applicable

## Deliverables

- COIN-M connector lifecycle
- subscription config
- reconnect handling
- normalized event output
- settlement-aware fixtures

## Acceptance Criteria

- connector annotates events with ProductLine `cm_perp`（COIN-M）.
- settlement asset is represented.
- `cm_perp` COIN-M `BTCUSD` does not collide with Spot or USDⓈ-M instruments.
- connector preserves contract code/expiry when present.
- connector does not implement server acceptance logic.

## Dependencies

- CLIENT-001 catalog
- CLIENT-002 parser
