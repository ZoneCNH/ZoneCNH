# module/binance/server IMPLEMENTATION PLAN

## Phase 1: `natsx` Consumer Skeleton

- consume `natsx` JetStream consumer APIs
- consume `domain_market.MarketFactEnvelope` semantics
- implement consumer loop shell
- add envelope fixtures

## Phase 2: Validation

- validate envelope fields
- validate domain enum mapping
- validate payload shape
- classify reject reasons

## Phase 3: Idempotency

- implement idempotency store interface
- implement duplicate detection
- implement conflict detection
- test retry behavior

## Phase 4: ACK / Reject

- implement ManualAck after durable processing
- implement terminal reject / retryable failure behavior
- define event-level processing result behavior
- test that no ManualAck occurs before validation, idempotency, storage, and fanout boundaries pass

## Phase 5: Durable Storage

- implement Redisx idempotency coordination
- implement Taosx hot fact writes
- implement Postgresx metadata/index writes where required
- implement OSSx archive path where required
- ensure duplicate accepted events do not duplicate storage

## Phase 6: API and `kafkax` Fanout

- implement read/query API for Binance-owned market facts
- implement `kafkax` accepted-fact fanout
- ensure duplicate accepted events do not duplicate fanout
- classify storage/fanout failures for retry behavior

## Phase 7: Admin and Observability

- implement `/healthz`
- implement `/readyz`
- implement `/debug/*`
- implement safe `/admin/*`
- expose metrics/logging/tracing dimensions

## Phase 8: Consumer and Integration Tests

- envelope compatibility tests with client publisher fixtures
- duplicate/retry tests
- JetStream redelivery tests
- storage/API/`kafkax` fanout tests

## Phase 9: Boundary Gates

- no client internal imports
- no `binance-market`
- no exchange connector ownership
- no generic market data or strategy ownership
- no local proto/gRPC/contracts ownership
