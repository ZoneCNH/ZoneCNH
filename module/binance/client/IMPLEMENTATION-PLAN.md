# module/binance/client IMPLEMENTATION PLAN

## Phase 1: Contract and Domain Integration

- consume generated contracts
- consume `domain-market` semantic types
- define mapping adapters without owning canonical semantics

## Phase 2: Catalog and Parser

- implement product-line catalog loader
- implement symbol parser
- validate identity collision cases

## Phase 3: Connectors

- implement Spot connector
- implement USDⓈ-M connector
- implement COIN-M connector
- implement Options connector
- normalize raw events into internal event model

## Phase 4: Mapping

- map normalized events to canonical market envelopes
- generate idempotency keys
- add fixtures for each product line

## Phase 5: Spool and Checkpoint

- implement SQLite spool
- implement checkpoint store
- enforce ACK-based checkpoint advancement

## Phase 6: gRPC Sender

- implement streaming sender
- handle ACK/reject
- retry/reconnect from spool

## Phase 7: Admin and Observability

- implement `/healthz`
- implement `/readyz`
- implement `/debug/*`
- implement safe `/admin/*`
- add metrics/logging/tracing dimensions

## Phase 8: Tests and Gates

- connector tests
- parser tests
- mapper tests
- spool tests
- checkpoint tests
- contract tests
- boundary gates
