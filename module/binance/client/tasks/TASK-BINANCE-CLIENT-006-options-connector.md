# TASK-BINANCE-CLIENT-006 Options Connector

## Objective

Collect Binance Options market-data events and normalize them.

## Scope

Initial scope:

- option ticker
- trade
- kline/bar where supported
- option-specific facts where available

## Deliverables

- Options connector lifecycle
- subscription config
- reconnect handling
- normalized event output
- option symbol fixtures

## Acceptance Criteria

- connector annotates events with ProductLine Options.
- options identity includes expiry, strike, and option type.
- call and put contracts do not collide.
- invalid option symbols produce structured parser errors.
- connector does not own option canonical semantics.

## Dependencies

- CLIENT-001 catalog
- CLIENT-002 parser
