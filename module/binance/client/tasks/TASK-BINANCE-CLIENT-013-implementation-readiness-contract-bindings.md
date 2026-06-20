# TASK-BINANCE-CLIENT-013 Implementation Readiness — Contracts and Domain Bindings

- Status: Ready
- Owner: `module/binance/client`
- Last-Updated: 2026-06-17
- Dependencies: `module/contracts/SPEC.md` §8.4, `module/domain_market/SPEC.md` v1.1.0 §10

## Objective

Bind the client implementation to the now-closed upstream contracts and domain semantics.

## Scope

- Generate/import contracts-owned `MarketDataService` client bindings from `module/contracts/SPEC.md` §8.4.
- Emit `IngestRequest` 12 fields: `request_id`, `source`, `product_line`, `instrument_key`, `event_type`, `event_time`, `received_at`, `schema_version`, `payload`, `sequence`, `ordering_key`, `source_metadata`.
- Map Binance-native product lines and symbols to domain_market `InstrumentKey` (12 dimensions) and `MarketFactEnvelope` (time semantics: EventTime/ReceivedAt/AvailableAt/DecisionTime).
- Use contract-defined `RejectCode` enum (10 codes) for error classification.
- Preserve ACK-only checkpoint advancement per BOUNDARY-GATES §9.

## Acceptance Criteria

1. Client sender uses contracts-generated `MarketDataService.Ingest` client; no local proto exists.
2. Client mapper uses `MarketFactEnvelope` naming and time semantics from domain_market §10.
3. Idempotency keys include `exchange + product_line + instrument_key + event_type + event_time + source_sequence + payload_fingerprint` dimensions (§7 BR-007).
4. Checkpoint advances only on durable accepted/duplicate ACK per BOUNDARY-GATES §9.
5. RejectCode `retryable` → exponential backoff retry; `terminal_validation`/`terminal_conflict` → logged + skipped.
6. Server `contract_violation`/`quality_rejected`/`ordering_violation`/`unsupported_channel` rejects are surfaced in client observability.
