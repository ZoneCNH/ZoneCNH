---
task_id: TASK-BINANCE-CLIENT-006
related_requirements:
  - FR-003
scope: >
  Initial scope:
acceptance_criteria:
  - "connector annotates events with ProductLine Options."
  - "options identity includes expiry, strike, and option type."
  - "call and put contracts do not collide."
  - "invalid option symbols produce structured parser errors."
  - "connector does not own option canonical semantics."
---
# TASK-BINANCE-CLIENT-006 Options Connector

## Objective

Collect Binance Options market-data events and normalize them.

## Scope

Initial scope:

- option ticker
- trade
- kline/bar where supported
- option-specific facts where available


## Non-scope

- Does not change behavior outside `module/binance/client`.
- Does not define canonical domain source of truth or server persistence semantics.

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
