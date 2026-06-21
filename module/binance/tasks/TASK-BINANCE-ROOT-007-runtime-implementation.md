# TASK-BINANCE-ROOT-007 Runtime Implementation

## Objective

Implement the full Binance C/S module runtime, producing `binance-client` and `binance-server` binaries that satisfy all documented acceptance criteria from client and server task specs.

## Scope

This task covers the complete runtime implementation: `domain_market` mapping, connector implementations, `natsx` publishing, server JetStream consumption, validation, idempotency, durable Binance storage, query/admin APIs, `kafkax` fanout, observability, integration tests, and CI boundary gates.

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

1. `domain_market` and `natsx` integration
2. Domain type mapping (Binance-native -> `MarketFactEnvelope`)
3. Server mock and publisher/envelope tests
4. Client catalog and parser
5. Spot, USDⓈ-M, COIN-M, Options connectors
6. Market event mapper
7. `natsx` publisher with PubAck evidence
8. Real server JetStream consumer pipeline
9. Validation and idempotency
10. Durable storage and query API
11. `kafkax` fanout
12. Admin endpoints and observability
13. Integration tests (client -> `natsx` -> server -> storage/API/`kafkax`)
14. Boundary gates in CI

## Acceptance Criteria

1. All docs compile as a coherent module.
2. All client and server tasks have acceptance criteria met.
3. Client/server boundary is enforced (client does not implement server behavior, server does not connect to exchange endpoints).
4. Client publish success is proven by JetStream PubAck; server durable processing is proven by storage/API/`kafkax` evidence and ManualAck.
5. Duplicate idempotency keys are durably processed exactly once.
6. No `binance-market` active reference exists anywhere in the codebase.
7. Integration test demonstrates end-to-end flow: client -> `natsx` -> server -> storage/API/`kafkax`.

## Dependencies

- PR-000 (binance-market removed).
- PR-001 (root docs established).
- PR-002 (client docs and task specs in place).
- PR-003 (server docs and task specs in place).
- PR-004 (domain_market types available and verified).
- PR-005 (`natsx` publisher/consumer semantics available and verified).
- PR-006 (runtime transport/admin/storage/fanout policies available and verified).
