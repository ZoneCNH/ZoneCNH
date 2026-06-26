# TASK-BINANCE-ROOT-002 Client Documentation

## Objective

Establish the complete documentation set for `module/binance/client`, including spec, traceability, implementation plan, and current task definitions.

## Scope

The client is responsible for connecting to Binance exchange endpoints, parsing raw market data, mapping to `domain_market.MarketFactEnvelope`, and publishing through `natsx` JetStream. Client-side delivery evidence is JetStream PubAck; durable processing evidence remains server-owned. This task defines the documentation that specifies these responsibilities.

## Deliverables

- `module/binance/client/README.md`
- `module/binance/client/SPEC.md`
- `module/binance/client/TRACEABILITY.md`
- `module/binance/client/IMPLEMENTATION-PLAN.md`
- client task specs covering:
  - Product-line catalog
  - Instrument parser
  - Spot/USDⓈ-M/COIN-M/Options connectors
  - Market event mapper
  - `natsx` publisher
  - Gin admin
  - Publisher/envelope tests
  - Boundary gates
  - Archived pre-v2 tasks clearly marked as historical reference only

## Acceptance Criteria

1. Each client task has defined acceptance criteria.
2. Client does not implement server behavior (no ingest acceptance logic).
3. Delivery evidence depends on JetStream PubAck, not server ACK/checkpoint semantics.
4. Client docs define product-line catalog, parser, mapping, `natsx` publisher, and admin responsibilities.
5. Client boundary gates are documented and enforceable.

## Dependencies

- PR-001 (root docs must exist before client docs).
