# natsx Matrix Score Evidence

Last-Updated: 2026-06-12
Status: Draft evidence refreshed; not Approved.

## Score Snapshot

| Dimension | Score | Evidence |
| --- | ---: | --- |
| Goal/SPEC naming alignment | 4/5 | SPEC now uses goal.md API/config/metric names. |
| Traceability structure | 5/5 | Forward, reverse, task coverage, and risks are present. |
| Executable test evidence | 3/5 | `/home/natsx/pkg/natsx` embedded tests cover Core publish/request/queue, JetStream publish/pull, AddStream/AddConsumer idempotency/conflict, missing-stream publish, nack redelivery, executable example smoke coverage, and a Core publish benchmark; dead-letter, reconnect/backoff, request/JetStream benchmark/SLO, and full health/observability lifecycle remain pending. |
| Release approval readiness | 2/5 | Documentation evidence is current, but implementation and integration gates are not complete. |

Overall matrix evidence score: **14/20**.

## Verification Notes

- `TRACEABILITY.md` explicitly separates complete, partial, and pending FR/BR/NFR rows.
- Executable evidence is pinned to `/home/natsx` commit `d4072fe` and remains outside this documentation repo.
- This score refresh does not mark `SPEC.md` Approved or satisfy the formal four-source 98+ arbiter.
