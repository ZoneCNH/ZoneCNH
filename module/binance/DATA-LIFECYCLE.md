# module/binance DATA-LIFECYCLE

## Metadata

- Status: Discussion draft for Stage2; not an approved SPEC change
- Last-Updated: 2026-06-22
- Scope: lifecycle gaps before the next `module/binance/SPEC.md` bump
- Spec-Impact: This document does not modify `SPEC.md`; it prepares review input for a later approved bump.
- Source: `SPEC.md`, `TRACEABILITY.md`, `RUNTIME-MAPPING.md`, `BOUNDARY-GATES.md`, `IMPLEMENTATION-PLAN.md`, `docs/report/binance/goal-execution-plan-20260622.md`

## Purpose

Stage2 needs a focused lifecycle draft so retention, replay, archival, idempotency, and deletion semantics can be reviewed before they become normative requirements. This file records proposed gaps and FR landing points only; runtime acceptance still depends on future SPEC, task, and test updates.

## Lifecycle gap register

| Gap | Area | Current risk | Proposed closure |
| --- | --- | --- | --- |
| DL-GAP-001 | Ingest identity | Product-line + symbol collisions can leak across spot, USDⓈ-M, COIN-M, and options. | Require canonical `InstrumentKey` on every persisted and fanned-out fact. |
| DL-GAP-002 | Event time | Exchange time, server receive time, and decision time are not uniformly distinguished. | Persist all three timestamps and declare query defaults. |
| DL-GAP-003 | Idempotency | Duplicate payload and duplicate key with different payload need separate outcomes. | Standardize `redisx` SetNX key, conflict marker, and retry handling. |
| DL-GAP-004 | Ack boundary | The exact side-effect set required before NATS Ack can drift. | Keep Ack after redisx + taosx + postgresx + kafkax required handoff. |
| DL-GAP-005 | Hot cache | Redis hot snapshots lack freshness and stale-read behavior. | Define TTL, stale response metadata, and degradation behavior. |
| DL-GAP-006 | Time-series retention | taosx retention cutoff and partition deletion are not independently reviewable. | Gate deletion behind archival ETag proof and replay window checks. |
| DL-GAP-007 | Cold archive | OSS path, object format, and replay metadata can diverge from query semantics. | Treat path format and parquet schema as acceptance-covered contracts. |
| DL-GAP-008 | Metadata catalog | Symbol lifecycle, contract expiry, and options identity updates need durable history. | Use postgresx catalog versioning and replayable status transitions. |
| DL-GAP-009 | OLAP backfill | clickhousex analytics can miss late or replayed facts. | Define taosx→clickhousex ETL watermark and correction policy. |
| DL-GAP-010 | Kafka fanout | Kafka topic naming drift can couple downstream consumers to NATS subjects. | Keep Kafka topics on `binance.{product_line}.{event_type}.v1`. |
| DL-GAP-011 | Dead letters | Retry exhaustion evidence is not tied to replay and incident ownership. | Add DLQ envelope, alert, and replay owner requirements. |
| DL-GAP-012 | Schema evolution | Payload field additions need compatibility rules before downstream use. | Add additive-only compatibility and versioned envelope guidance. |
| DL-GAP-013 | Audit evidence | Lifecycle operations can pass locally without durable proof. | Store command output / CI link / runtime SHA in traceability evidence. |
| DL-GAP-014 | Data deletion | Manual deletion has no documented safety interlock. | Require two-phase delete: archive proof, query drain, then hot-delete. |
| DL-GAP-015 | Recovery drill | No explicit restore drill proves cold archive can rebuild hot stores. | Add periodic replay drill and acceptance evidence. |

## Proposed FR landing points

These are suggested landing points for the next approved SPEC revision. They are intentionally not applied to `SPEC.md` in Stage2.

| Suggested FR | Draft title | Depends on | Bump impact |
| --- | --- | --- | --- |
| FR-012 | Lifecycle evidence bundle for ingest, storage, archive, and fanout | TRACEABILITY evidence convention | minor |
| FR-013 | Instrument identity history and contract lifecycle catalog | domain_market, postgresx | minor |
| FR-014 | Event-time / receive-time / decision-time semantics | domain_market, taosx, clickhousex | minor |
| FR-015 | Idempotency conflict ledger | redisx, postgresx | minor |
| FR-016 | Ack boundary proof before NATS Ack | natsx, redisx, taosx, postgresx, kafkax | minor |
| FR-017 | Hot cache freshness and stale-read contract | redisx, Gin API | minor |
| FR-018 | taosx retention and partition delete gate | taosx, ossx | minor |
| FR-019 | OSS archive manifest and replay contract | ossx, parquet reader, postgresx | minor |
| FR-020 | clickhousex ETL watermark and late-fact correction | clickhousex, taosx | minor |
| FR-021 | Kafka topic versioning and consumer compatibility | kafkax | patch |
| FR-022 | Dead-letter ownership and replay workflow | natsx, observability | minor |
| FR-023 | Schema evolution compatibility rules | domain_market, downstream consumers | minor |
| FR-024 | Recovery drill for cold-to-hot restore | ossx, taosx, postgresx, clickhousex | minor |

## Suggested bump and dependency notes

- Proposed bump: `v2.3.0` once these lifecycle requirements are accepted, because the draft adds new lifecycle acceptance surface rather than only correcting prose.
- No new repository dependency is proposed by this draft. It reuses existing module dependencies: `domain_market`, `natsx`, `redisx`, `taosx`, `postgresx`, `clickhousex`, `ossx`, `kafkax`, Gin, and runtime observability.
- Review dependency: Stage1 `scripts/check-binance-docs.sh` should pass before this draft is used as SPEC input.

## Non-goals

- Do not modify `SPEC.md` from this Stage2 draft.
- Do not mark runtime AC/TC items PASS without `/home/binance` evidence.
- Do not expand Stage2 into Stage3+ implementation work.
