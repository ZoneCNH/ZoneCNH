# module/binance/client IMPLEMENTATION PLAN

## Phase 1: Domain and Publish Boundary

- consume `domain_market` semantic types
- consume `natsx` publisher APIs
- define mapping adapters without owning canonical semantics
- keep pre-v2 contracts/gRPC/spool tasks archived only

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

- map normalized events to `domain_market.MarketFactEnvelope`
- generate idempotency keys
- add fixtures for each product line

## Phase 5: `natsx` Publisher

- implement JetStream publisher
- select configured subject/stream
- treat JetStream PubAck as publish evidence
- classify retryable publish failures and terminal serialization/schema failures

## Phase 6: Admin and Observability

- implement `/healthz`
- implement `/readyz`
- implement `/debug/*`
- implement safe `/admin/*`
- add metrics/logging/tracing dimensions

## Phase 7: Tests and Gates

- connector tests
- parser tests
- mapper tests
- publisher tests
- PubAck/retry tests
- envelope compatibility tests
- boundary gates
