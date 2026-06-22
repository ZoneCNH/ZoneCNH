# Binance Data Lifecycle Discussion Draft

Status: discussion draft  
Last-Updated: 2026-06-22  
Source: `docs/report/binance/goal-execution-plan-20260622.md` stage 2  
Spec-Impact: none in this draft; `SPEC.md` remains unchanged until the listed FRs are approved.

## Purpose

This document collects the data-lifecycle gaps that must be resolved before expanding the Binance module beyond the current 4×4 market-data contract. It is intentionally a planning artifact: it defines landing points, version bumps, and dependencies without claiming runtime implementation.

## Fifteen lifecycle gaps

| Gap | Area | Description | Proposed landing |
|---|---|---|---|
| RT-01 | Real-time | Symbol discovery and filtering must define which instruments are subscribed, excluded, and refreshed. | FR-012 |
| RT-02 | Real-time | WebSocket connection policy must define sharding, reconnect, backoff, and listen-key/session boundaries. | FR-013 |
| RT-03 | Real-time | Bar interval subscriptions must be explicit instead of implied by event type alone. | FR-014 |
| RT-04 | Real-time | Depth snapshot tier and delta reconciliation must define freshness and recovery limits. | FR-015 |
| RT-05 | Real-time | Real-time gap detection must state when a stream gap becomes a backfill job. | FR-017 |
| RT-06 | Real-time | Stream lifecycle operations must expose safe pause/resume/reload behavior. | FR-024 |
| HIST-01 | Historical | Cold-start bootstrap must define how far back each product/event line is hydrated. | FR-016 |
| HIST-02 | Historical | Backfill scheduling must preserve priority between catch-up and live ingestion. | FR-018 |
| HIST-03 | Historical | Backfill idempotency keys must prevent duplicate writes across retries. | FR-019 |
| HIST-04 | Historical | Pagination, rate limits, and retry budgets must be bounded per Binance API family. | FR-018 |
| HIST-05 | Historical | Hot/cold retention must define taosx, clickhousex, and ossx ownership by data class. | FR-016 |
| HIST-06 | Historical | Replay manifests must make archival reloads auditable and repeatable. | FR-022 |
| HIST-07 | Historical | Completeness checks must compare expected vs persisted intervals and events. | FR-017 |
| HIST-08 | Historical | Daily reconciliation must define correction, alerting, and replay triggers. | FR-021 |
| HIST-09 | Historical | Funding-rate and mark-price data need dedicated lifecycle rules before event-type expansion. | FR-020 |

## Proposed FR landing map

| Issue | FR | Scope | Bump | Depends on |
|---|---|---|---|---|
| #880 | FR-012 Symbol Discovery & Filtering | Define catalog source, include/exclude filters, and symbol identity refresh. | SPEC v2.4.0 | Stage 0 naming/topic convergence |
| #881 | FR-013 WebSocket Connection Policy | Define stream sharding, reconnect/backoff, and session ownership. | SPEC v2.4.0 | FR-012 |
| #882 | FR-014 Bar Interval Subscription Set | Define supported intervals and subscription matrix per product line. | SPEC v2.4.0 | FR-012 |
| #883 | FR-015 Depth Snapshot Tier | Define snapshot levels, delta reconciliation, and freshness limits. | SPEC v2.4.0 | FR-013 |
| #884 | FR-016 Historical Backfill on Cold Start | Define bootstrap ranges and storage ownership. | SPEC v2.5.0 | FR-012, FR-014 |
| #885 | FR-017 Gap Detection & Fill | Convert stream/persistence gaps into bounded backfill jobs. | SPEC v2.5.0 | FR-013, FR-016 |
| #886 | FR-018 Backfill Throttle & Priority | Define scheduling priority, rate limits, and API budgets. | SPEC v2.5.0 | FR-016 |
| #887 | FR-019 Backfill Idempotency Key Strategy | Define dedupe keys and retry-safe writes. | SPEC v2.5.0 | FR-016, FR-017 |
| #888 | FR-020 Funding Rate / Mark Price Stream | Add funding/mark-price lifecycle and event-type expansion plan. | SPEC v3.0.0 MAJOR | Stages 3–4 complete |
| #889 | FR-021 Daily Reconciliation Job | Define daily completeness/correction workflow. | SPEC v3.0.0 MAJOR | FR-017, FR-019 |
| #890 | FR-022 Cold Data Rehydration | Define archive replay manifests and reload workflow. | SPEC v3.0.0 MAJOR | FR-016, FR-021 |
| #891 | FR-023 Backfill Progress API | Expose backfill state and progress through admin/API boundaries. | SPEC v3.1.0 | FR-018, FR-019 |
| #892 | FR-024 Symbol Subscription Hot Reload | Expose safe symbol reload without process restart. | SPEC v3.1.0 | FR-012, FR-013 |

## Non-goals for this draft

- No runtime code changes.
- No `SPEC.md`, `TRACEABILITY.md`, or `ACCEPTANCE.md` claim that FR-012 through FR-024 are implemented.
- No event-type expansion before the stage-5 major-bump migration.
- No reintroduction of local spool/checkpoint/sender paths, gRPC/proto ingest, or embedded server assumptions.
