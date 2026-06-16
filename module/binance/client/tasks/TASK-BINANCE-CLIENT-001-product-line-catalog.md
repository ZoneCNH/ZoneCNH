# TASK-BINANCE-CLIENT-001 Product-Line Catalog

## Objective

Define and implement the Binance product-line catalog for Spot, USDⓈ-M, COIN-M, and Options.

## Scope

The catalog stores exchange-native metadata required to create canonical instrument identities.

## Deliverables

- catalog schema
- product-line enum mapping input
- metadata loader
- fixtures for four product lines
- catalog validation tests

## Acceptance Criteria

- Spot `BTCUSDT` can be represented.
- USDⓈ-M `BTCUSDT` can be represented separately from Spot.
- COIN-M `BTCUSD` can be represented with settlement asset.
- Options symbols can represent expiry, strike, and option type.
- disabled/delisted instruments are visible as status, not silently dropped.
- catalog does not define canonical domain source of truth.

## Dependencies

- `module/domain-market` ProductLine and InstrumentKey semantics.
