# Binance GitHub issues #923-#931 closure ledger

- Date: 2026-06-23
- Scope: GitHub issue state reconciliation for `ZoneCNH/ZoneCNH` #923-#931 and the corresponding `module/binance` documentation projection.
- Sources: `gh issue view` for #923-#931, `docs/report/binance/`, `module/binance/README.md`, `module/binance/ACCEPTANCE.md`, `module/binance/TRACEABILITY.md`.

> [COMPUTED, HIGH] Final disposition: GitHub issues #923-#931 are all `CLOSED` as of 2026-06-23.
>
> [COMPUTED, HIGH] This ledger records GitHub issue-tracking state. It does not promote runtime or release readiness: live Binance websocket evidence, external `natsx` JetStream proof, durable storage/fanout/query proof, remote CI, release artifacts, release tag, and FR-012~FR-030 runtime evidence remain governed by `module/binance/ACCEPTANCE.md` and release gates.

## 1. Issue state

| Issue | GitHub state | Closed at (UTC) | Closed evidence basis | Runtime/release boundary |
| --- | --- | --- | --- | --- |
| #923 | Closed | 2026-06-23T14:16:57Z | Runtime mapping, boundary gates, and local evidence bundle registered. | Does not close live websocket, external `natsx` PubAck/ManualAck, durable storage/fanout/query, remote CI, or release tag. |
| #924 | Closed | 2026-06-23T14:18:07Z | Local release evidence entry and PR linkage registered. | Does not replace remote CI, GitHub Release, live smoke, or release artifact linkage. |
| #925 | Closed | 2026-06-23T14:10:10Z | README, architecture docs, SPEC, TRACEABILITY, and DATA-LIFECYCLE projection aligned to v3.5.0. | No separate runtime claim. |
| #926 | Closed | 2026-06-23T14:10:33Z | DATA-LIFECYCLE formalization memo records FR-012~FR-030 registration and issue mapping. | Runtime implementation remains governed by FR/runtime gates. |
| #927 | Closed | 2026-06-23T14:18:21Z | FR-012~FR-015 contracts registered. | Does not close exchangeInfo discovery, catalog refresh, stream policy, depth tier, reconnect, or degradation runtime proof. |
| #928 | Closed | 2026-06-23T14:18:28Z | FR-016~FR-024 contracts registered. | Does not close backfill, gap replay, funding/mark-price, reconciliation, rehydration, progress API, or hot reload runtime proof. |
| #929 | Closed | 2026-06-23T14:18:40Z | FR-025~FR-030 contracts registered. | Does not close throttle, validation, gap repair, SLA metrics, schema drift, or quality evidence. |
| #930 | Closed | 2026-06-23T14:10:40Z | Governance docs debt projection aligned and legacy references compressed to boundary/traceability contexts. | No separate runtime claim. |
| #931 | Closed | 2026-06-23T14:10:57Z | Umbrella issue classified after #923~#930 entries were resolved in GitHub state. | Runtime/release readiness remains tracked by acceptance and release gates, not by open issue count. |

## 2. Release boundary

| Boundary | Current conclusion |
| --- | --- |
| GitHub issue tracking | #923~#931 are closed. |
| Documentation projection | Docs now describe closed GitHub state and keep runtime/release readiness separate. |
| Runtime implementation | FR-012~FR-030 remain Pending where `module/binance/TRACEABILITY.md` marks them Pending. |
| Release evidence | Remote CI, live websocket, external integration, release artifact, and release tag evidence remain Pending unless separately linked by release evidence. |

## 3. Follow-up rule

[COMPUTED, HIGH] Do not reopen or reclassify #923~#931 merely because runtime/release evidence is still pending. Record future runtime or release gaps against the active FR/AC/TC and release evidence gates instead.

[RULES I BROKE]：无 — 本报告只记录 GitHub issue 状态与 release/runtime 边界分离口径，未声称 runtime/release 已完成。
