# module/binance/server IMPLEMENTATION PLAN

## Phase 1: Contract Server Skeleton

- consume generated gRPC server interface
- implement stream handler shell
- add contract fixtures

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

- implement ACK generation
- implement reject response generation
- define stream-level and event-level response behavior
- test checkpoint-driving ACK semantics

## Phase 5: Downstream Dispatch

- implement downstream market-data port adapter
- dispatch accepted events
- ensure duplicate accepted events do not duplicate dispatch

## Phase 6: Admin and Observability

- implement `/healthz`
- implement `/readyz`
- implement `/debug/*`
- implement safe `/admin/*`
- expose metrics/logging/tracing dimensions

## Phase 7: Contract and Integration Tests

- contract tests with client
- duplicate/retry tests
- stream reconnect tests
- downstream dispatch tests

## Phase 8: Boundary Gates

- no client internal imports
- no `binance-market`
- no storage/query/strategy ownership
- no local proto ownership
