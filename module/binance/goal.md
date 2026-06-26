# module/binance GOAL

- Module-Version: v3.7.1
- Last-Updated: 2026-06-26

## Purpose

`module/binance` defines the Binance-specific market_data ingest module for ZoneCNH as a **distributed Client/Server architecture** connected exclusively through natsx JetStream.

## Primary Goals

### 1. Distributed C/S Market Data Ingestion（FR-001~004）
- Four product lines: Spot, USDⓈ-M Futures, COIN-M Futures, Options
- Client/Server as independent processes, deployed on different machines
- natsx JetStream as the sole communication channel (PubAck + ManualAck)
- At-least-once delivery with NakWithDelay + MaxDeliver dead-letter

### 2. Full-Stack Storage（FR-005~006e, FR-010）
- taosx: time-series tick/bar/depth storage
- postgresx: instrument catalog metadata + audit log
- redisx: idempotency (SetNX 72h TTL) + hot cache + distributed lock
- clickhousex: OLAP analytics storage (ETL from taosx)
- ossx: cold archival with ETag validation
- taosx data retention lifecycle (FR-006e)

### 3. Query API & Downstream Broadcast（FR-007~008）
- Gin REST API (:8080) for market_data queries
- clickhousex analytics API (VWAP, top-movers, correlation)
- kafkax fanout to downstream consumers

### 4. Runtime Control Plane（FR-012~015）
- Stream session lifecycle: dynamic subscription add/remove without restart
- Exchange reliability controls: retry budget, rate-limit, clock-skew guard
- Runtime observability: Prometheus metrics + admin API
- Operational pause/resume/drain with audit trail

### 5. Historical Data Lifecycle（FR-016~019, FR-025~028）
- Backfill planner: window validation, cursor persistence, overlap rejection
- Gap detection and replay with idempotent replay jobs
- Archive manifest, restore, and retention management
- Resource governance: concurrency budget, memory reservation
- Throttle (80/20 cold_start/repair split) + daily reconciliation + cold rehydration

### 6. Event Governance（FR-020~022, FR-029~030）
- Funding rate and mark/index price event support
- 4×6 product-line × event-type governance matrix (24 combinations)
- Data quality SLA: freshness P95/P99, stale alert, schema drift detection
- Options chain raw field pass-through (Greeks derivation belongs to analysis domain)

### 7. ExchangeInfo Discovery & Tiered Sync（FR-031~036 · Draft）
- Four product line exchangeInfo discovery with API trap fixes (COIN-M `contractStatus`, Options `eapi`/`optionSymbols`)
- ExchangeInfo persistence to postgresx with 6h scheduled diff-only refresh
- Sync tier classification (L1_core/L2_extended/L3_full/disabled)
- Selective sync whitelist (product_lines + allow/deny)

### 8. Production Standardization（FR-037~044 · Pending）
- Release safety net: feature flags + canary deployment + rollback runbook
- Distributed tracing: OpenTelemetry with W3C traceparent propagation
- Resource quota & isolation: per-consumer-group Kafka quota, per-product-line WS pool
- Audit log completeness: append-only, ≥1 year retention
- Schema version compatibility policy
- Cost observability: per-product-line Prometheus metrics
- Data compliance & destruction: data_classification + certificate_of_destruction

## Non-Goals

`module/binance` does not own:
- Generic market_data domain semantics（owned by `module/domain_market`）
- Cross-exchange ingestion policy
- Strategy APIs / trading decisions / order execution
- Portfolio accounting / risk management
- Legacy `binance-market` Provider compatibility
- **Storage access from client side（C7 — see SPEC §4.4）**: client 不落盘，仅通过 natsx publish
- **Exchange access from server side（C8 — see SPEC §4.4）**: server 不直连交易所，仅通过 natsx consume

## Success Criteria

1. Binance market data is collected by `binance-client` (independent process).
2. Canonical market events are durably published through `natsx` JetStream using `domain_market` envelopes.
3. `binance-server` validates, deduplicates, persists, exposes, and fans out accepted Binance events.
4. Spot `BTCUSDT`, USDⓈ-M `BTCUSDT`, COIN-M `BTCUSD`, and Options contracts produce non-colliding canonical instrument identities.
5. At-least-once delivery with ManualAck: storage + fanout success before Ack.
6. Boundary gates (13/13) enforce client/server process isolation and import discipline.
7. Storage assembly (G0) connects all 5 infra backends through `storageFromEnv`.
8. All 44 FRs are traceable through FR → AC → TC → Task chains.
