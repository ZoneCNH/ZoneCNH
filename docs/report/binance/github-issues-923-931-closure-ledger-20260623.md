# Binance GitHub issues #923-#931 closure ledger

- Date: 2026-06-23
- Scope: `ZoneCNH/ZoneCNH` GitHub issues #923-#931 after PR #936 and the PR #937 documentation branch.
- Sources: OMX team `use-context-omx-conte-88f2d738`, `module/binance/SPEC.md` v3.5.0, `module/binance/TRACEABILITY.md` v3.5.0, `module/binance/ACCEPTANCE.md`, `/home/binance/release/evidence/binance/20260623/SUMMARY.md`, `/home/binance/BOUNDARY-GATES.md`, and `/home/natsx` release state.
- Stop condition: do not close GitHub issues, create a release tag, or claim runtime acceptance until the missing closure evidence below exists.

> [COMPUTED, HIGH] No issue in #923-#931 is closeable as of this snapshot. PR #936 and PR #937 align governance and documentation projection; they do not replace live websocket, external `natsx` / storage / fanout / query, remote CI, release tag, or FR-012~030 runtime implementation evidence.

## Current disposition

| Issue | Disposition | Evidence present | Missing closure evidence | Next action |
| --- | --- | --- | --- | --- |
| #923 | External/runtime blocked | Boundary/runtime skeleton evidence exists; workers found no illegal internal/cs boundary drift in `/home/binance/BOUNDARY-GATES.md`. | Live Binance websocket evidence; `natsx` JetStream PubAck + ManualAck; external durable storage, fanout, query integration; remote CI; release tag. | Collect L2/L3/live/release evidence in `/home/binance` after external integration is available. |
| #924 | Dependency blocked by #923 | Release evidence directory exists for 2026-06-23. | Same runtime evidence as #923 plus accepted release bundle and tag. | Re-run release evidence only after #923 evidence exists. |
| #925 | Documentation projection reconciled locally; GitHub closure still blocked | `SPEC.md` and `TRACEABILITY.md` v3.5.0 are aligned; PR #936 removed stale v3.3/v3.4 projection. | Runtime/release acceptance chain from #923/#924. | Keep PR #937 linked as documentation evidence; close only after runtime release evidence is accepted. |
| #926 | Lifecycle formalization documented; implementation blocked | `DATA-LIFECYCLE.md` is a v3.5.0 Formal Proposal and FR-012~030 are registered as Pending. | Spec-to-code tasks, implementation, and tests for FR-012~030. | Split and execute runtime lifecycle tasks before closure. |
| #927 | Locally implementable runtime work; not done | Documentation contract covers FR-012~015. | `exchangeInfo` discovery, catalog flow, interval/depth configuration, websocket/REST degradation tests, and runtime evidence. | Implement client control-plane lifecycle slice. |
| #928 | Locally implementable runtime work; not done | Documentation contract covers FR-016~024. | Backfill, gap-fill, funding, mark price, reconciliation, progress tracking, hot reload tests, and runtime evidence. | Implement historical-data lifecycle slice. |
| #929 | Locally implementable runtime work; not done | Documentation contract covers FR-025~030. | Validation, coverage SLA, options pass-through, metrics/alerts, schema drift tests, and runtime evidence. | Implement data-quality and processing slice. |
| #930 | Governance cleanup reconciled locally; GitHub closure still blocked | PR #936 closes the stale governance/report projection and records v3.5.0 as the current contract. | Runtime lifecycle closure for #926 and final acceptance evidence. | Keep this ledger and PR #937 as documentation evidence; close after #926 closes. |
| #931 | Umbrella blocked | `bd dep cycles` is clean; worker reconciliation found all children classified. | Closure of #923-#930, accepted release evidence, and release tags. | Close last, after all child issues have objective evidence. |

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
