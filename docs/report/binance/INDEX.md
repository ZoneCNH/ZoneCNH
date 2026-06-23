# Binance reports index

- Last-Updated: 2026-06-23
- Scope: `docs/report/binance` report set for Stage0–Stage2 repair and audit follow-up.

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
| [deep-analysis-20260622.md](deep-analysis-20260622.md) | Initial deep analysis snapshot. |
| [deep-analysis-20260622-v2.md](deep-analysis-20260622-v2.md) | Follow-up analysis snapshot. |
| [deep-analysis-20260622-v3.md](deep-analysis-20260622-v3.md) | Follow-up analysis snapshot. |
| [deep-analysis-20260622-v4.md](deep-analysis-20260622-v4.md) | Follow-up analysis snapshot. |
| [deep-analysis-20260622-v5-cleansing-processing-gaps.md](deep-analysis-20260622-v5-cleansing-processing-gaps.md) | Cleansing and processing gap analysis. |

## Closure and audit reports

| Report | Purpose |
| --- | --- |
| [governance-closure-20260623.md](governance-closure-20260623.md) | Worker-3 governance slice closure for #869/#871/#893/#894/#895/#896. |
| [commit-coverage-audit-20260623.md](commit-coverage-audit-20260623.md) | 50-candidate preserve/stash/backup commit coverage audit for #896. |
| [issues-full-closure-20260623.md](issues-full-closure-20260623.md) | Full 25-issue closure review (PR #910) — final status, evidence, residual actions. |

## Stage0–Stage2 executable gates

- Stage1 doc gate: `scripts/check-binance-docs.sh`
- Stage2 lifecycle draft: `module/binance/DATA-LIFECYCLE.md` (v0.2.0 — includes §6 issue→FR coverage map + §7 candidate FR-025~028 landing)
- Stage6 `module/binance/STANDARD.md` is Active (v0.1.1) and wired into R9 + check-binance-docs.sh.

