# Binance PR #936 governance/docs closure review

- Date: 2026-06-23
- Scope: post-PR #936 docs projection and GitHub #923-#931 closure boundary
- Sources: `module/binance/SPEC.md` v3.5.0, `module/binance/TRACEABILITY.md` v3.5.0, `module/binance/DATA-LIFECYCLE.md`, repo-local reports, OMX worker reconciliation
- Confidence: HIGH for docs state / HIGH for issue-closure boundary

> [COMPUTED, HIGH] At PR #936 time, the docs projection moved to v3.5.0 and closed stale governance projection for #925/#930. That PR did not close #923/#924/#926/#927/#928/#929/#931 because live websocket, remote CI/tag, JetStream PubAck/ManualAck, external durable storage/fanout/query evidence remained absent.
>
> [COMPUTED, HIGH] 2026-06-23 post-PR #947/#949 update: GitHub #923~#931 are all CLOSED as issue-tracking scope. The current closure ledger records that tracker state while preserving the PR #936 boundary assessment: runtime/release evidence caveats stay governed by acceptance/release gates.

## File-level findings

| ID | File / local anchor | Stale projection or gap | Patch applied |
| --- | --- | --- | --- |
| F1 | `docs/report/binance/INDEX.md` closure table | Closure index ended at PR #910/#896 reports and had no post-PR #936 entry for #925/#930/#931. | Added this PR #936 closure review to the index. |
| F2 | `docs/report/binance/issues-full-closure-20260623.md`, `goal-execution-plan-20260622.md`, and `iteration-plan-20260622.md` PR #910 projection notes | PR #910 reports read as full/current closure artifacts while their scope is #866~#896 against v3.1.0; residual FR-025~028 text no longer matches current module docs. | Marked the reports as historical PR #910 baselines, linked this review, and annotated residual rows as superseded by later module docs. |
| F3 | `module/binance/DATA-LIFECYCLE.md` §7 | §7 still says FR-025~028 are not folded into `SPEC.md` / `TRACEABILITY.md`, although current docs record v3.2.0 folds and v3.5.0 FR-029/030. | Added a post-PR #936 supersession note while preserving the discussion-draft provenance. |
| F4 | `docs/report/binance/deep-analysis-20260622-backlog.md` and `unfinished-deep-analysis-20260623.md` | Rollup reports encoded v3.4.0 / FR-028-era or older projection rows that could be mistaken for current post-PR #936 backlog. | Added post-PR #936 supersession notes and updated the rollup baseline counters to v3.5.0 / FR-030. |
| F5 | GitHub #923-#931 closure boundary | Docs projection and issue closure could be conflated. | Historical PR #936 assessment added the closure ledger; later PR #947/#949 evidence updates closed #923~#931 as issue-tracking scope while keeping runtime/release caveats under acceptance/release gates. |

## Closure map

| Issue | Current disposition | Evidence |
| --- | --- | --- |
| #923/#924 | Closed as issue-tracking scope after PR #947/#949. | Worker/local validation passed; live websocket and release evidence remain governed by acceptance/release gates. |
| #925 | Closed. | SPEC/TRACEABILITY v3.5.0; DATA-LIFECYCLE Formal Proposal / Runtime Pending. |
| #926~#929 | Closed as issue-tracking scope after PR #947/#949. | Lifecycle/quality/replay/runtime features remain governed by acceptance/release gates pending external storage/fanout/query evidence. |
| #930 | Closed. | SPEC/TRACEABILITY v3.5.0; active reports updated to historical PR #910 wording. |
| #931 | Closed as umbrella tracker after PR #947/#949. | Release verification and remaining runtime evidence continue under acceptance/release gates. |

## Verification

- `bash scripts/check-binance-docs.sh` PASS
- `bash scripts/check-binance-data-lifecycle.sh` PASS
- `python3 scripts/audit-status.py` PASS
- `rg` stale-anchor review PASS for current-state docs

## Residual

Runtime/release evidence remains missing: live websocket, remote CI/release tag, JetStream PubAck/ManualAck, external durable storage/fanout/query, historical backfill/reconciliation/quality SLA implementation evidence.

[RULES I BROKE]：无
