# natsx Matrix Score Evidence

Last-Updated: 2026-06-12
Status: Draft evidence refreshed; not Approved.

## Score Snapshot

| Dimension | Score | Evidence |
| --- | ---: | --- |
| Goal/SPEC naming alignment | 4/5 | SPEC now uses goal.md API/config/metric names. |
| Traceability structure | 5/5 | Forward, reverse, task coverage, and risks are present. |
| Executable test evidence | 4/5 | `/home/natsx/pkg/natsx` embedded tests cover Core publish/request/queue/unsubscribe/drain, reconnect/degraded health, JetStream publish/pull, AddStream/AddConsumer idempotency/conflict, missing-stream publish, nack redelivery, max-deliveries advisory, executable examples, and publish/request/JetStream publish benchmarks; formal SLO assertions, live TLS/auth, config-alias breadth, and higher-level consumer/API/observability remain partial. |
| Release approval readiness | 3/5 | Documentation and executable gates are current, but formal four-source arbiter, live TLS/auth/config-alias breadth, production SLO thresholds, and consumer lifecycle/API/observability remain open. |

Overall matrix evidence score: **16/20**.

## Verification Notes

- `TRACEABILITY.md` explicitly separates complete, partial, and pending FR/BR/NFR rows.
- Executable evidence is pinned to `/home/natsx` commit `3053e80` and remains outside this documentation repo.
- This score refresh does not mark `SPEC.md` Approved or satisfy the formal four-source 98+ arbiter.
