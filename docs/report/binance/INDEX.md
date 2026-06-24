# Binance reports archive index

- Last-Updated: 2026-06-25
- Scope: `docs/report/binance` 历史深度分析、生产就绪、治理闭环与 SRE 跟进记录归档。
- Archive Root: [`archive/`](archive/)

> [COMPUTED, HIGH] 本目录根层只保留索引；历史报告已按报告日期归档到 `archive/YYYYMMDD/`。
>
> [COMPUTED, HIGH] 归档文件是时间点快照。读取生产就绪、runtime/release readiness 或 issue 状态时，应以最新 runtime 仓库、验收矩阵、release evidence 和后续报告复核为准。
>
> [COMPUTED, HIGH] 本次归档共覆盖 28 份 Markdown 报告：20260622 9 份、20260623 9 份、20260624 2 份、20260625 8 份。

## 归档批次

| 批次 | 数量 | 说明 |
| --- | ---: | --- |
| [`archive/20260622/`](archive/20260622/) | 9 | 初始深度分析、业务覆盖、Goal 与迭代方案。 |
| [`archive/20260623/`](archive/20260623/) | 9 | 数据流、基础设施解耦、治理闭环、issue/PR 审计与未完成项。 |
| [`archive/20260624/`](archive/20260624/) | 2 | 生产就绪差距分析与 HEAD 复核。 |
| [`archive/20260625/`](archive/20260625/) | 8 | 20 轮深度分析、生产就绪评估/修复/SRE 清单，以及本轮主分析、架构、规范报告。 |

## 20260622

| Report | Purpose |
| --- | --- |
| [business-types-coverage-20260622.md](archive/20260622/business-types-coverage-20260622.md) | Product-line and business-type coverage assessment. |
| [deep-analysis-20260622.md](archive/20260622/deep-analysis-20260622.md) | Initial deep analysis snapshot. |
| [deep-analysis-20260622-v2.md](archive/20260622/deep-analysis-20260622-v2.md) | Follow-up analysis snapshot. |
| [deep-analysis-20260622-v3.md](archive/20260622/deep-analysis-20260622-v3.md) | Follow-up analysis snapshot. |
| [deep-analysis-20260622-v4.md](archive/20260622/deep-analysis-20260622-v4.md) | Historical data vs realtime data gap analysis. |
| [deep-analysis-20260622-v5-cleansing-processing-gaps.md](archive/20260622/deep-analysis-20260622-v5-cleansing-processing-gaps.md) | Cleansing and processing gap analysis. |
| [deep-analysis-20260622-backlog.md](archive/20260622/deep-analysis-20260622-backlog.md) | Deep-analysis unfinished/backlog summary. |
| [goal-execution-plan-20260622.md](archive/20260622/goal-execution-plan-20260622.md) | Goal execution plan, stage gates, acceptance criteria, and issue mapping. |
| [iteration-plan-20260622.md](archive/20260622/iteration-plan-20260622.md) | Iteration breakdown and verification sequence. |

## 20260623

| Report | Purpose |
| --- | --- |
| [commit-coverage-audit-20260623.md](archive/20260623/commit-coverage-audit-20260623.md) | 50-candidate preserve/stash/backup commit coverage audit. |
| [dataflow-architecture-analysis-20260623.md](archive/20260623/dataflow-architecture-analysis-20260623.md) | Dataflow architecture gaps and ruleset maturity assessment. |
| [github-issues-923-931-closure-ledger-20260623.md](archive/20260623/github-issues-923-931-closure-ledger-20260623.md) | GitHub #923-#931 closure ledger. |
| [governance-closure-20260623.md](archive/20260623/governance-closure-20260623.md) | Governance slice closure for #869/#871/#893/#894/#895/#896. |
| [infrastructure-decoupling-report-20260623.md](archive/20260623/infrastructure-decoupling-report-20260623.md) | Decoupling target for redisx/kafkax/natsx/postgresx/taosx/ossx/clickhousex boundaries. |
| [issues-full-closure-20260623.md](archive/20260623/issues-full-closure-20260623.md) | Full 25-issue closure review. |
| [multi-exchange-adr-20260623.md](archive/20260623/multi-exchange-adr-20260623.md) | ADR for multi-exchange generalization. |
| [pr-936-governance-docs-closure-20260623.md](archive/20260623/pr-936-governance-docs-closure-20260623.md) | Post-PR #936 governance/docs closure audit. |
| [unfinished-deep-analysis-20260623.md](archive/20260623/unfinished-deep-analysis-20260623.md) | Deep-analysis unfinished-item summary. |

## 20260624

| Report | Purpose |
| --- | --- |
| [production-readiness-gap-analysis-20260624.md](archive/20260624/production-readiness-gap-analysis-20260624.md) | 5-round production-readiness gap analysis; superseded by later rechecks where noted. |
| [production-readiness-recheck-20260624.md](archive/20260624/production-readiness-recheck-20260624.md) | Recheck based on runtime HEAD `8290dc9`. |

## 20260625

| Report | Purpose |
| --- | --- |
| [binance-module-analysis.md](archive/20260625/binance-module-analysis.md) | Production-level module analysis report. |
| [binance-data-flow-architecture.md](archive/20260625/binance-data-flow-architecture.md) | Data-flow architecture diagram and responsibility boundaries. |
| [binance-module-standards.md](archive/20260625/binance-module-standards.md) | Binance module development and production standards. |
| [deep-analysis-20rounds-20260625.md](archive/20260625/deep-analysis-20rounds-20260625.md) | 20-round deep production-readiness analysis. |
| [issues-sync-final-20260625.md](archive/20260625/issues-sync-final-20260625.md) | Issues decomposition and sync report. |
| [production-readiness-assessment-20260625.md](archive/20260625/production-readiness-assessment-20260625.md) | Comprehensive production-readiness assessment. |
| [production-readiness-fix-execution-20260625.md](archive/20260625/production-readiness-fix-execution-20260625.md) | Production-readiness fix execution record. |
| [sre-unblock-checklist-20260625.md](archive/20260625/sre-unblock-checklist-20260625.md) | SRE infra unblock checklist. |

## 读取口径

[INFERRED, HIGH] 这些文档跨多次修复、复核和状态推进，较早报告中的结论可能被后续报告明确覆盖。检索时建议按日期从新到旧阅读；引用历史结论时同时标注报告日期、对应 runtime HEAD 或 PR/issue 背景。

[RULES I BROKE]：无
