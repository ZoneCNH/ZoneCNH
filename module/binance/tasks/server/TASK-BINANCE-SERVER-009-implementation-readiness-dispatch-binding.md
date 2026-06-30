# TASK-BINANCE-SERVER-009 Implementation Readiness — Dispatch Binding

> Archived v2.0.0: this `contracts`/gRPC + `market_data` DownstreamDispatchPort readiness task is superseded by `natsx`, `domain_market`, server-owned storage, `kafkax`, and Gin REST tasks. Do not use it for implementation.

- Status: Archived
- Owner: `module/binance/server`
- Last-Updated: 2026-06-30
- Dependencies: `module/contracts/SPEC.md` §8.4, `module/market_data/SPEC.md` v1.0.0 §4

## Objective

Bind the server implementation to contracts-owned ingest types and market_data-owned downstream dispatch port.

## Scope

- Implement contracts-generated `MarketDataService.Ingest` server from `module/contracts/SPEC.md` §8.4.
- Validate `IngestRequest` 12 fields against domain_market `ProductLine` (4 values), `InstrumentKey` (12 dimensions), `MarketFactEnvelope` semantics.
- Perform idempotent durable acceptance with payload-hash conflict detection using `RejectCode` (10 codes).
- Dispatch accepted facts through `market_data.DownstreamDispatchPort` per `module/market_data/SPEC.md` §4.
- Map binance-native reject classifications to market_data unified reasons per market_data §4.4.1.
- Emit durable ACK only after receiver `DispatchAck` / idempotent ack result or durable server outbox write.

## Acceptance Criteria

1. Server has no client internal imports and no local proto (BOUNDARY-GATES §3–§6).
2. Duplicate same key/hash returns idempotent durable ACK and does not dispatch twice.
3. Duplicate key/different hash returns `terminal_conflict` reject.
4. Receiver `DispatchFailure` (backpressure) maps to `retryable` reject and does not advance client checkpoint.
5. Successful receiver `DispatchAck` / idempotent ack maps to `durable_acceptance=true`.
6. Server handles all 10 `RejectCode` paths per contracts §8.4 (including `contract_violation`, `quality_rejected`, `ordering_violation`, `unsupported_channel`).
7. `contract_violation` → reject with detailed field-level reason; `quality_rejected` → reject with degraded-channel metadata; `ordering_violation` → reject with expected-vs-actual sequence; `unsupported_channel` → reject with channel/product_line not enabled hint.
