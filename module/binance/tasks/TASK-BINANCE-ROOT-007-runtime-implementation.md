# TASK-BINANCE-ROOT-007 Runtime Implementation

## Objective

Implement the full Binance C/S module runtime, producing `binance-client` and `binance-server` binaries that satisfy all documented acceptance criteria from client and server task specs.

## Scope

This task covers the complete runtime implementation: generated contracts integration, domain type mapping, connector implementations, spool/checkpoint, gRPC sender, server ingest pipeline (validation, idempotency, ACK, dispatch), admin endpoints, observability, integration tests, and CI boundary gates.

## Deliverables

Runtime layout:

```text
github.com/ZoneCNH/binance/
  cmd/
    binance-client/
    binance-server/
  internal/
    client/
    server/
  pkg/
    config/
    observability/
```

Implementation steps (in order):

1. Generated contracts integration
2. Domain type mapping (Binance-native → domain types)
3. Server mock and contract tests
4. Client catalog and parser
5. Spot, USDⓈ-M, COIN-M, Options connectors
6. Market event mapper
7. Spool and checkpoint
8. gRPC sender
9. Real server ingest pipeline
10. Validation, idempotency, and ACK
11. Downstream dispatch
12. Admin endpoints and observability
13. Integration tests (client → server → downstream port flow)
14. Boundary gates in CI

## Acceptance Criteria

1. All docs compile as a coherent module.
2. All client and server tasks have acceptance criteria met.
3. Client/server boundary is enforced (client does not implement server behavior, server does not connect to exchange endpoints).
4. Server ACK can drive client checkpoint advancement.
5. Duplicate idempotency keys are accepted exactly once.
6. No `binance-market` active reference exists anywhere in the codebase.
7. Integration test demonstrates end-to-end flow: client → server → downstream port.

## Dependencies

- PR-000 (binance-market removed).
- PR-001 (root docs established).
- PR-002 (client docs and task specs in place).
- PR-003 (server docs and task specs in place).
- PR-004 (domain_market types available and verified).
- PR-005 (contracts types available and verified).
- PR-006 (transportx policies available and verified).
