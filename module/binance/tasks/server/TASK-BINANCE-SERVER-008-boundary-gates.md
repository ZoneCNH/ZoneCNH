# TASK-BINANCE-SERVER-008 Boundary Gates

## Objective

Ensure server boundaries are enforceable in CI.

## Scope

Server-specific gates:

- no client internal import
- no `binance-market`
- no exchange connector ownership
- no generic market data or strategy ownership
- no local proto/gRPC/contracts ingest ownership
- server-owned Binance storage/query/API/fanout stays inside the documented adapters

## Deliverables

- CI script additions
- allowed/forbidden import documentation
- negative fixtures if applicable

## Acceptance Criteria

- CI fails when server imports client internals.
- CI fails when server references `binance-market` outside allowlist.
- CI fails when server owns exchange connector code.
- CI fails when server owns generic market data or strategy semantics.
- CI fails when server defines local proto/gRPC/contracts ingest types.
- CI allows `domain_market`, `natsx`, `redisx`, `taosx`, `postgresx`, `ossx`, `kafkax`, and Gin dependencies for the documented server surface.
- gate does not require `rg`; POSIX `grep` is sufficient.
