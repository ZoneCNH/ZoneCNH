# market_data Production Runtime v1

- Status: Proposed / Runtime Pending
- Parent: module/market_data/spec/SPEC.md
- ADR: module/ADR-five-module-production-pipeline-v1.md

## Process Boundary

market_data is an independent Gin service with its own command, config, database migrations, health, metrics, release and rollback artifacts.

Required command: cmd/market-data/main.go.

## Capture Transaction

The authoritative transaction writes:

1. append-only capture_log；
2. capture identity: idempotency_key + payload_hash；
3. acceptance outbox entry。

Only after commit may the HTTP handler return CAPTURED.

Forbidden order:

```text
idempotency CheckAndSet → Sink Write → ACK
```

Synchronous TDengine + Kafka dual-write is not an ACK barrier.

## Owned State

- capture_log
- capture_identity
- acceptance_outbox
- accepted_fact
- stream_watermark
- coverage_interval
- gap_record
- quarantine_record
- projection_checkpoint
- reconciliation_run

No sibling service may write these tables.

## Acceptance Pipeline

- wire validation；
- domain validation；
- same-key/same-hash duplicate；
- same-key/different-hash conflict；
- per-stream ordering；
- finite reorder window；
- watermark；
- gap detection；
- late/correction policy；
- quarantine；
- accepted fact event。

## Projection

Kafka, TDengine, Redis, ClickHouse and OSS are idempotent projections driven from outbox/checkpoint state. Every projector supports replay and reconciliation.

## Acceptance Criteria

- AC-MD-R1-001: Capture commit precedes receipt.
- AC-MD-R1-002: injected Sink failure never returns Projected or ambiguous Durable success.
- AC-MD-R1-003: process kill after request preserves committed Capture.
- AC-MD-R1-004: same-key/different-hash returns 409 and quarantine.
- AC-MD-R1-005: ordering store errors are not ignored.
- AC-MD-R1-006: gap remains visible until verified repair.
- AC-MD-R1-007: Capture-to-Sink count/hash/watermark reconciliation closes.
- AC-MD-R1-008: latest/range/coverage use UTC [from,to).
- AC-MD-R1-009: no Binance implementation import exists.
- AC-MD-R1-010: service builds, runs, migrates and rolls back independently.
