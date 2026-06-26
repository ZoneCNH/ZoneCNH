# TASK-BINANCE-CLIENT-012 Boundary Gates

## Objective

Ensure client boundaries are enforceable in CI.

## Scope

Client-specific gates:

- no server internal import
- no `binance-market`
- no storage/query/API/fanout ownership
- no domain canonical type ownership
- no local proto/gRPC/contracts ownership

## Deliverables

- CI script additions
- documentation of allowed/forbidden imports
- negative fixtures if applicable

## Acceptance Criteria

- CI fails when client imports server internals.
- CI fails when client references `binance-market` outside allowlist.
- CI fails when client owns storage/query/API/fanout behavior.
- CI fails when client defines local proto/gRPC/contracts ingest types.
- CI allows `domain_market` and `natsx` imports.
- gate does not require `rg`; POSIX `grep` is sufficient.
