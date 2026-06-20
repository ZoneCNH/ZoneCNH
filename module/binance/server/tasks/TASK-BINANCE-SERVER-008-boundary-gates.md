# TASK-BINANCE-SERVER-008 Boundary Gates

## Objective

Ensure server boundaries are enforceable in CI.

## Scope

Server-specific gates:

- no client internal import
- no `binance-market`
- no storage/query/strategy ownership
- no exchange connector ownership
- no local proto ownership

## Deliverables

- CI script additions
- allowed/forbidden import documentation
- negative fixtures if applicable

## Acceptance Criteria

- CI fails when server imports client internals.
- CI fails when server references `binance-market` outside allowlist.
- CI fails when server owns exchange connector code.
- CI fails when server owns storage/query/strategy.
- CI allows contracts/domain_market/market_data downstream port dependencies.
- gate does not require `rg`; POSIX `grep` is sufficient.
