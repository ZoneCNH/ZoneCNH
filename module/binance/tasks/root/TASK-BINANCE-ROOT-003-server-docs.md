# TASK-BINANCE-ROOT-003 Server Documentation

## Objective

Establish the complete documentation set for `module/binance/server`, including spec, traceability, implementation plan, and current task definitions.

## Scope

The server implements the Binance-specific consumer side of the `natsx` / `domain_market` contract: it consumes `MarketFactEnvelope` messages, validates, deduplicates, persists Binance market facts, exposes read/admin APIs, and fans out accepted facts through `kafkax`. This task defines the documentation that specifies these responsibilities without reaching into exchange connectivity or generic market/strategy ownership.

## Deliverables

- `module/binance/server/README.md`
- `module/binance/server/SPEC.md`
- `module/binance/server/TRACEABILITY.md`
- `module/binance/server/IMPLEMENTATION-PLAN.md`
- server task specs covering:
  - `natsx` consumer
  - Validation
  - Idempotent acceptance
  - Durable storage
  - `kafkax` fanout
  - Query/admin API
  - Gin admin
  - Consumer/envelope tests
  - Boundary gates
  - Archived pre-v2 tasks clearly marked as historical reference only

## Acceptance Criteria

1. Server owns Binance-specific ingest acceptance semantics.
2. Server does not connect to Binance exchange endpoints.
3. Server owns Binance-specific storage/query/fanout while not owning generic market data or strategy semantics.
4. Server docs define validation, idempotency, durable storage, API, ManualAck, and `kafkax` fanout responsibilities.
5. Server boundary gates are documented and enforceable.

## Dependencies

- PR-001 (root docs must exist before server docs).
