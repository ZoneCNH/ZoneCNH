# Binance reports index

- Last-Updated: 2026-06-23
- Scope: `docs/report/binance` report set for Stage0–Stage2 repair and audit follow-up.

> [COMPUTED, HIGH] 2026-06-23 final disposition: 3 doc-complete issues (#925/#926/#930) closed; 5 runtime-dependent issues (#923/#924/#927/#928/#929) remain open with updated status; umbrella #931 closed. Runtime/release evidence Pending for implementation-tracked issues.

## Execution and iteration plans

| Report | Purpose |
| --- | --- |
| [goal-execution-plan-20260622.md](goal-execution-plan-20260622.md) | Goal execution plan, stage gates, acceptance criteria, and issue mapping. |
| [iteration-plan-20260622.md](iteration-plan-20260622.md) | Iteration breakdown and verification sequence. |

## Analysis reports

| Report | Purpose |
| --- | --- |
| [business-types-coverage-20260622.md](business-types-coverage-20260622.md) | Product-line and business-type coverage assessment. |
| [dataflow-architecture-analysis-20260623.md](dataflow-architecture-analysis-20260623.md) | Dataflow architecture gaps, delivery-futures product_line gap, and ruleset maturity assessment. |
| [infrastructure-decoupling-report-20260623.md](infrastructure-decoupling-report-20260623.md) | Binance decoupling target for redisx/kafkax/natsx/postgresx/taosx/ossx/clickhousex boundaries, config/lifecycle ownership, and final dependency graph. |
| [multi-exchange-adr-20260623.md](multi-exchange-adr-20260623.md) | ADR for OQ-005/006 multi-exchange generalization — recommends per-exchange module template (Option B). |
| [deep-analysis-20260622.md](deep-analysis-20260622.md) | Initial deep analysis snapshot. |
| [deep-analysis-20260622-v2.md](deep-analysis-20260622-v2.md) | Follow-up analysis snapshot. |
| [deep-analysis-20260622-v3.md](deep-analysis-20260622-v3.md) | Follow-up analysis snapshot. |
| [deep-analysis-20260622-v4.md](deep-analysis-20260622-v4.md) | Follow-up analysis snapshot. |
| [deep-analysis-20260622-v5-cleansing-processing-gaps.md](deep-analysis-20260622-v5-cleansing-processing-gaps.md) | Cleansing and processing gap analysis. |

## Closure and audit reports

| Report | Purpose |
| --- | --- |
| [pr-936-governance-docs-closure-20260623.md](pr-936-governance-docs-closure-20260623.md) | Post-PR #936 governance/docs closure audit for #925/#930/#931, stale PR #910 projections, and exact patch set. |
| [governance-closure-20260623.md](governance-closure-20260623.md) | Worker-3 governance slice closure for #869/#871/#893/#894/#895/#896. |
| [commit-coverage-audit-20260623.md](commit-coverage-audit-20260623.md) | 50-candidate preserve/stash/backup commit coverage audit for #896. |
| [issues-full-closure-20260623.md](issues-full-closure-20260623.md) | Full 25-issue closure review (PR #910) — final status, evidence, residual actions. |
| [github-issues-923-931-closure-ledger-20260623.md](github-issues-923-931-closure-ledger-20260623.md) | GitHub #923-#931 final closure ledger — 3 doc-complete closed (#925/#926/#930); 5 runtime-open (#923/#924/#927/#928/#929); umbrella #931 closed with summary. |

## Stage0–Stage2 executable gates

- Stage1 doc gate: `scripts/check-binance-docs.sh`
- Stage2 lifecycle draft: `module/binance/DATA-LIFECYCLE.md` (v3.5.0 — FR-012~FR-030 registered in SPEC/TRACEABILITY; runtime/release evidence Pending)
- Stage6 `module/binance/STANDARD.md` is Active (v0.1.1) and wired into R9 + check-binance-docs.sh.
