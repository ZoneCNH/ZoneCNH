# market_regime Production Runtime v1

- Status: Proposed / Runtime Pending
- Parent: module/market_regime/spec/SPEC.md
- ADR: module/ADR-five-module-production-pipeline-v1.md

## Role

market_regime is the S-state analytics service. It consumes market.fact.accepted.v1 and produces market.regime.snapshot.v1.

It does not produce final trade permission, risk permit, leverage, target position or orders.

## Input Rules

- accepted canonical facts only；
- final/corrected bars only under explicit correction policy；
- event-time windows；
- per-stream watermark；
- finite reorder window；
- gap and stale state；
- real OI/funding/basis/liquidation inputs for leverage/deleverage dimensions；
- missing dimensions lower confidence or produce UNKNOWN, never substitute unrelated features。

## Determinism

- injected Clock；
- stable parameter_set_id；
- SnapshotID derived from canonical input/model/parameter hash；
- no random UUID in replay core；
- no silent future-time clamp；
- same input/version/config produces byte-identical snapshot。

## State Machine

Required states: S1-S7, UNKNOWN, DISLOCATED.

Required controls:

- warm-up；
- hysteresis；
- minimum dwell；
- degraded/recovering freshness；
- correction/retraction；
- feature evidence；
- model version；
- confidence calibration。

Feed failure is not itself a market crash. Data quality and market state are separate axes.

## Acceptance Criteria

- AC-MR-R1-001: Open/Unknown bar is rejected from official window.
- AC-MR-R1-002: future available_at causes fail-closed/no-lookahead violation.
- AC-MR-R1-003: out-of-order within window is deterministic.
- AC-MR-R1-004: out-of-window late event follows explicit correction policy.
- AC-MR-R1-005: same replay repeated 100 times yields identical snapshot hash.
- AC-MR-R1-006: missing OI/funding/liquidation cannot be synthesized from price heat.
- AC-MR-R1-007: stale/gap input cannot emit Healthy.
- AC-MR-R1-008: state transition golden and property tests pass.
- AC-MR-R1-009: walk-forward, holdout, threshold sensitivity and confidence calibration evidence exist.
- AC-MR-R1-010: service builds, runs, persists, queries and rolls back independently.
