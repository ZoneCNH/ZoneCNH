# binance → market_data Handoff v1

- Status: Proposed
- Parent: module/binance/spec/SPEC.md
- ADR: module/ADR-five-module-production-pipeline-v1.md

## Role

binance is the Binance-specific collector. It owns exchange protocol and delivery retry, not canonical fact acceptance.

## Required Path

```text
Binance WS/REST
  → normalize to domain_market
  → persist module-owned outbox
  → HTTP submit using contracts v1
  → receive CAPTURED/DUPLICATE receipt
  → mark outbox delivered
```

NATS may exist only during migration shadow and is non-authoritative.

## Outbox Rules

- persist before network；
- stable event_id/idempotency_key/payload_hash；
- timeout, 429, 5xx retain item；
- same-hash DUPLICATE completes item；
- 409 conflict quarantines item and alerts；
- only CAPTURE_LOG receipt permits removal/compaction；
- crash/restart, disk-full and backpressure are tested；
- outbox depth and oldest age are readiness signals。

## Product Capability

Capability is tracked independently for spot, um_perp, cm_perp and options.

Each product/event pair declares realtime, history, sequence, recovery, rate budget, whitelist and live evidence status.

Spot success cannot satisfy derivative or options gates.

## Acceptance Criteria

- AC-BH-V1-001: no event is sent before durable outbox commit.
- AC-BH-V1-002: HTTP timeout cannot delete an item.
- AC-BH-V1-003: receipt hash mismatch cannot complete an item.
- AC-BH-V1-004: process restart resumes pending delivery.
- AC-BH-V1-005: collection and orderbook whitelists are separate.
- AC-BH-V1-006: product line is part of every identity and policy key.
- AC-BH-V1-007: binance server no longer owns canonical persistence/query/fanout after cutover.
