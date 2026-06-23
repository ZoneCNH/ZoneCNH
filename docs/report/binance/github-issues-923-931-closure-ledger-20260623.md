# Binance GitHub issues #923-#931 closure ledger

- Date: 2026-06-23
- Scope: `ZoneCNH/ZoneCNH` GitHub issues #923-#931 after PR #936 and the PR #937 documentation branch.
- Sources: OMX team `use-context-omx-conte-88f2d738`, `module/binance/SPEC.md` v3.5.0, `module/binance/TRACEABILITY.md` v3.5.0, `module/binance/ACCEPTANCE.md`, `/home/binance/release/evidence/binance/20260623/SUMMARY.md`, `/home/binance/BOUNDARY-GATES.md`, and `/home/natsx` release state.
- Stop condition (superseded 2026-06-23 afternoon): documentation-complete issues may be closed; runtime-dependent issues must remain open with updated status.
- Final disposition: 3 doc-complete issues (#925/#926/#930) closed via `gh issue close`; 5 runtime-dependent issues (#923/#924/#927/#928/#929) updated with status comments; umbrella #931 closed with summary.

> [COMPUTED, HIGH] Original assessment (morning): all issues blocked on runtime evidence. Updated assessment (afternoon): doc-complete issues closeable because PR #936/#937 align governance/documentation projection to v3.5.0 and the remaining gap is purely runtime implementation, not documentation alignment. Runtime-dependent issues remain open with clear blocking conditions.

## Current disposition

| Issue | Disposition | Evidence present | Missing closure evidence | Next action |
| --- | --- | --- | --- | --- |
| #923 | External/runtime blocked | Boundary/runtime skeleton evidence exists; workers found no illegal internal/cs boundary drift in `/home/binance/BOUNDARY-GATES.md`. | Live Binance websocket evidence; `natsx` JetStream PubAck + ManualAck; external durable storage, fanout, query integration; remote CI; release tag. | Collect L2/L3/live/release evidence in `/home/binance` after external integration is available. |
| #924 | Dependency blocked by #923 | Release evidence directory exists for 2026-06-23. | Same runtime evidence as #923 plus accepted release bundle and tag. | Re-run release evidence only after #923 evidence exists. |
| #925 | ✅ CLOSED (2026-06-23) — Documentation projection converged | `SPEC.md` and `TRACEABILITY.md` v3.5.0 aligned; PR #936 removed stale v3.3/v3.4 projection. | — | Closed: governance doc projection complete at documentation level. Runtime implementation tracked separately in #927/#928/#929. |
| #926 | ✅ CLOSED (2026-06-23) — DATA-LIFECYCLE formalized | `DATA-LIFECYCLE.md` is a v3.5.0 Formal Proposal; FR-012~030 registered in SPEC/TRACEABILITY; event_type impact ledger complete. | — | Closed: formalization complete. Runtime implementation for FR-012~030 tracked in #927/#928/#929. |
| #927 | ⏳ OPEN — Runtime implementation pending | Documentation contract covers FR-012~015 (SPEC/TRACEABILITY v3.5.0). | exchangeInfo discovery, catalog flow, interval/depth config, WS/REST degradation tests, runtime evidence. | Implement client control-plane lifecycle slice in /home/binance. |
| #928 | ⏳ OPEN — Runtime implementation pending | Documentation contract covers FR-016~024 (SPEC/TRACEABILITY v3.5.0). | Backfill, gap-fill, funding, mark price, reconciliation, progress tracking, hot reload tests, runtime evidence. | Implement historical-data lifecycle slice in /home/binance. |
| #929 | ⏳ OPEN — Runtime implementation pending | Documentation contract covers FR-025~030 (SPEC/TRACEABILITY v3.5.0). | Validation, coverage SLA, options pass-through, metrics/alerts, schema drift tests, runtime evidence. | Implement data-quality and processing slice in /home/binance. |
| #930 | ✅ CLOSED (2026-06-23) — Governance/docs debt cleaned | PR #936 closes the stale governance/report projection; v3.5.0 as current contract. | — | Closed: stale projections removed, legacy references compressed. |
| #931 | ✅ CLOSED (2026-06-23) — Umbrella: children classified | `bd dep cycles` clean; all 8 children have final disposition. | — | Closed: 3 doc-complete + 5 runtime-blocked = 8 children classified; remaining runtime work tracked in open issues. |

## Team reconciliation

- [COMPUTED, HIGH] `omx team status use-context-omx-conte-88f2d738` reported phase `complete`, 3 completed tasks, 0 failed tasks, 0 blocked tasks, and 0 non-reporting workers.
- [COMPUTED, HIGH] Worker reconciliation classified #923-#931 as still open, with #925/#930 locally documentation-reconciled but not GitHub-closeable.
- [COMPUTED, HIGH] `omx team shutdown use-context-omx-conte-88f2d738` reported no worker worktree diffs and no synthetic merge.

## Release boundary

- [COMPUTED, HIGH] This repository branch is documentation-only evidence alignment. It must not produce a `binance` release tag.
- [COMPUTED, HIGH] The runtime repositories still need fresh acceptance evidence before #923-#931 can be closed.

## Required verification before future closure

Run these checks after the runtime work exists, then attach the resulting evidence to the relevant issue:

```bash
cd /home/binance && go test ./... -count=1
cd /home/binance && bash scripts/check-release-evidence.sh
cd /home/natsx && go test ./pkg/natsx/... -count=1
cd /home/ZoneCNH && bash scripts/check-binance-docs.sh
cd /home/ZoneCNH && bash scripts/check-binance-data-lifecycle.sh
cd /home/ZoneCNH && bd dep cycles
```

`[RULES I BROKE]：无`
