# TASK-CONTRACTS-005 Binance C/S Ingestion Contract

- Status: Approved
- Owner: `module/contracts`
- Last-Updated: 2026-06-17
- Blocks: `module/binance` runtime implementation (PR-007)
- Depends-On: `module/domain-market` v1.1.0 §10; `module/market-data` v1.0.0 §4

## Objective

Publish the stable contracts-owned wire contract for Binance client/server market-data ingestion.

## Scope

- Define `MarketDataService.Ingest` bidirectional stream → **Done: SPEC §8.4**
- Define required `IngestRequest` envelope (12 fields) → **Done: §8.4.1 字段约束表**
- Define `IngestResult`/`IngestAck`/`IngestReject`/`RejectCode` (9 codes) → **Done: §8.4**
- Define durable acceptance and checkpoint advancement rules → **Done: §8.4 producer/consumer docs**
- Define compatibility and contract-test requirements → **Done: BR-005~BR-009**
- Define cross-layer naming mapping table → **Done: §8.4 命名约定映射表**

## Acceptance Criteria

1. `module/contracts/SPEC.md` §8.4 exists and contains `MarketDataService` + `IngestRequest`(12 fields)/`IngestResult`/`IngestAck`/`IngestReject` + `RejectCode`(9 codes). ✅
2. The contract explicitly states that domain semantics are owned by `module/domain-market` (§8.4 ownership table). ✅
3. The contract explicitly states that durable downstream handoff is owned by `module/market-data` (§8.4 producer/consumer notes). ✅
4. `module/binance` has no local proto/wire schema ownership after consuming this task (BOUNDARY-GATES §6). ✅
5. Contract tests TBD cover valid accept, duplicate accept, conflict reject, validation reject, downstream backpressure, and post-crash retry — pending runtime proto compilation.

## Implementation Notes

GitHub Release `v1.2.0` published at https://github.com/ZoneCNH/contracts/releases/tag/v1.2.0. Runtime repositories should generate gRPC bindings once concrete `.proto` files are created. Until then, SPEC §8.4 is the reviewable source of truth.
