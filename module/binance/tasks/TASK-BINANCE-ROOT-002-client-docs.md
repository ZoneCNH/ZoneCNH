# TASK-BINANCE-ROOT-002 Client Documentation

## Objective

Establish the complete documentation set for `module/binance/client`, including spec, traceability, implementation plan, and 12 task definitions.

## Scope

The client is responsible for connecting to Binance exchange endpoints, parsing raw market data, mapping to canonical domain types, and sending data upstream via gRPC. This task defines the documentation that specifies these responsibilities.

## Deliverables

- `module/binance/client/README.md`
- `module/binance/client/SPEC.md`
- `module/binance/client/TRACEABILITY.md`
- `module/binance/client/IMPLEMENTATION-PLAN.md`
- 12 client task specs covering:
  - Product-line catalog
  - Instrument parser
  - Spot/USDⓈ-M/COIN-M/Options connectors
  - Market event mapper
  - Spool/checkpoint
  - gRPC sender
  - Gin admin
  - Contract tests
  - Boundary gates

## Acceptance Criteria

1. Each client task has defined acceptance criteria.
2. Client does not implement server behavior (no ingest acceptance logic).
3. Checkpoint depends on server ACK semantics.
4. Client docs define product-line catalog, parser, mapping, spool, checkpoint, sender, and admin responsibilities.
5. Client boundary gates are documented and enforceable.

## Dependencies

- PR-001 (root docs must exist before client docs).
