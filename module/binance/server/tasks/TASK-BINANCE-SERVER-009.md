---
task_id: TASK-BINANCE-SERVER-009
related_requirements:
  - FR-001
  - FR-002
  - FR-003
  - FR-004
  - FR-005
  - FR-006
  - FR-007
  - FR-008
scope: >
  Implement contracts-generated `MarketDataService.Ingest` server from `module/contracts/SPEC.md` §8.4.
acceptance_criteria:
  - "Scorer-compatible task acceptance remains traceable to the linked requirement IDs."
---
# TASK-BINANCE-SERVER-009 Implementation Readiness — Dispatch Binding

- Status: Ready
- Owner: `module/binance/server`
- Last-Updated: 2026-06-17
- Dependencies: `module/contracts/SPEC.md` §8.4, `module/market-data/SPEC.md` v1.0.0 §4

## Objective

Bind the server implementation to contracts-owned ingest types and market-data-owned downstream dispatch port.

## Scope

- Implement contracts-generated `MarketDataService.Ingest` server from `module/contracts/SPEC.md` §8.4.
- Validate `IngestRequest` 12 fields against domain-market `ProductLine` (4 values), `InstrumentKey` (12 dimensions), `MarketFactEnvelope` semantics.
- Perform idempotent durable acceptance with payload-hash conflict detection using `RejectCode` (9 codes).
- Dispatch accepted facts through `market-data.DownstreamDispatchPort` per `module/market-data/SPEC.md` §4.
- Map binance-native reject classifications to market-data unified reasons per market-data §4.4.1.
- Emit durable ACK only after receiver `DispatchAck` / idempotent ack result or durable server outbox write.


## Non-scope

- Does not change behavior outside `module/binance/server`.
- Does not import or modify client internals.

## Acceptance Criteria

1. Server has no client internal imports and no local proto (BOUNDARY-GATES §3–§6).
2. Duplicate same key/hash returns idempotent durable ACK and does not dispatch twice.
3. Duplicate key/different hash returns `terminal_conflict` reject.
4. Receiver `DispatchFailure` (backpressure) maps to `retryable` reject and does not advance client checkpoint.
5. Successful receiver `DispatchAck` / idempotent ack maps to `durable_acceptance=true`.
6. Server handles all 9 `RejectCode` paths per contracts §8.4 (including `contract_violation`, `quality_gate`, `ordering_violation`).
7. `contract_violation` → reject with detailed field-level reason; `quality_gate` → reject with degraded-channel metadata; `ordering_violation` → reject with expected-vs-actual sequence.
