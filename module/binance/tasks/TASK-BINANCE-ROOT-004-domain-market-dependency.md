# TASK-BINANCE-ROOT-004 domain_market Dependency

## Objective

Validate and document the dependency of `module/binance` on `module/domain_market` for canonical market semantics, ensuring that instrument identity, product-line classification, and market fact envelope types are correctly consumed from the domain layer.

## Scope

`module/domain_market` owns the canonical definitions for market types. This task ensures that `module/binance/client` and `module/binance/server` reference these types without redefining them, and that mapping between Binance-native data and domain types is correct and testable.

## Deliverables

- Dependency declaration in root SPEC.md referencing `module/domain_market`
- Verification that all required domain types are available:
  - `InstrumentKey`
  - `ProductLine`
  - `InstrumentType`
  - `OptionType`
  - `PriceKind`
  - `MarketScope`
  - `MarketFactEnvelope`
  - `decision_time`
- Proto-to-domain mapping test plan
- Compatibility path documentation for old event envelopes (if needed)

## Acceptance Criteria

1. Spot, Futures, and Options instrument identity collisions are impossible (e.g., Spot `BTCUSDT` and USDⓈ-M `BTCUSDT` are distinguishable).
2. Proto-to-domain mapping can be verified with tests.
3. Old event envelopes have a documented compatibility path if the migration requires one.
4. No canonical domain types are redefined within `module/binance`.

## Dependencies

- PR-001 (root docs established).
- `module/domain_market` (external — must expose the listed types).
