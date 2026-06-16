---
task_id: TASK-BINANCE-CLIENT-002
related_requirements:
  - FR-002
scope: >
  Parser covers:
acceptance_criteria:
  - "Spot `BTCUSDT` and USDⓈ-M `BTCUSDT` do not collide."
  - "COIN-M `BTCUSD` includes settlement/margin dimensions."
  - "Options include expiry, strike, and call/put side."
  - "parser emits structured errors for unknown formats."
  - "parser output can be mapped into `domain-market` canonical identity."
---
# TASK-BINANCE-CLIENT-002 Instrument Parser

## Objective

Parse Binance-native symbols and metadata into canonical identity components.

## Scope

Parser covers:

- Spot symbols
- USDⓈ-M futures symbols
- COIN-M futures symbols
- Options symbols


## Non-scope

- Does not change behavior outside `module/binance/client`.
- Does not define canonical domain source of truth or server persistence semantics.

## Deliverables

- parser package
- parsing fixtures
- collision tests
- invalid symbol handling

## Acceptance Criteria

- Spot `BTCUSDT` and USDⓈ-M `BTCUSDT` do not collide.
- COIN-M `BTCUSD` includes settlement/margin dimensions.
- Options include expiry, strike, and call/put side.
- parser emits structured errors for unknown formats.
- parser output can be mapped into `domain-market` canonical identity.

## Dependencies

- CLIENT-001 product-line catalog.
