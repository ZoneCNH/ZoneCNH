# Binance reports archive index

- Last-Updated: 2026-06-26
- Scope: `report/binance` 历史深度分析、生产就绪、治理闭环与 SRE 跟进记录归档。
- Archive Root: [`archive/`](archive/)

> [COMPUTED, HIGH] 本目录根层只保留索引；历史报告已按报告日期归档到 `archive/YYYYMMDD/`。
>
> [COMPUTED, HIGH] 归档文件是时间点快照。读取生产就绪、runtime/release readiness 或 issue 状态时，应以最新 runtime 仓库、验收矩阵、release evidence 和后续报告复核为准。
>
> [COMPUTED, HIGH] 本次归档共覆盖 28 份 Markdown 报告：20260622 9 份、20260623 9 份、20260624 2 份、20260625 8 份。

## 当前有效基线

| 字段 | 值 |
| --- | --- |
| Runtime-Anchor | `/home/binance@f046e16` |
| Issue-Ledger | [`issues-sync-20260625.md`](issues-sync-20260625.md) |
| Status-Projection | `24 Done / 10 Partial / 0 Pending` + `6 Draft`（FR-031~036） |
| Issue-Range | GitHub / Beads `#1104`-`#1118` + `#1123`（16 项） |
| Closed-By-This-Slice | 全部 16 项（7 代码修复+实证 + 9 能力边界文档化） |
| Still-Open | 无（全部 Closed） |

> [COMPUTED, HIGH] 历史报告继续作为语境保留；任何当前行动清单、关闭条件和 issue 状态以 [`issues-sync-20260625.md`](issues-sync-20260625.md) 为准。当前 16 个 gap issue 已全部闭合（issues-sync §当前结论）。

## 归档批次

| 批次 | 数量 | 说明 |
| --- | ---: | --- |
| [`archive/20260622/`](archive/20260622/) | 9 | 初始深度分析、业务覆盖、Goal 与迭代方案。 |
| [`archive/20260623/`](archive/20260623/) | 9 | 数据流、基础设施解耦、治理闭环、issue/PR 审计与未完成项。 |
| [`archive/20260624/`](archive/20260624/) | 2 | 生产就绪差距分析与 HEAD 复核。 |
| [`archive/20260625/`](archive/20260625/) | 8 | 20 轮深度分析、生产就绪评估/修复/SRE 清单，以及本轮主分析、架构、规范报告。 |

## 根层活跃报告

> [COMPUTED, HIGH] 根层保留当前生效的分析与裁决报告；历史快照归档至 `archive/`。根层报告是最新口径权威，归档报告被根层覆盖时以根层为准。

| Report | Purpose |
| --- | --- |
| [binance-module-analysis.md](binance-module-analysis.md) | 生产级模块分析报告（当前主分析）。 |
| [binance-data-flow-architecture.md](binance-data-flow-architecture.md) | 数据流架构图与职责边界。 |
| [binance-module-standards.md](binance-module-standards.md) | binance 模块开发与生产规范。 |
| [issues-sync-20260625.md](issues-sync-20260625.md) | 2026-06-25 Beads/GitHub issue 同步账本（16 缺口映射，全部 Closed）。 |
| [v0.2.0-release-gate-verdict-20260625.md](v0.2.0-release-gate-verdict-20260625.md) | v0.2.0 发布门禁增量裁决（推翻「零阻塞」断言，记录 readiness-audit gate 红 + FR 状态漂移）。 |
| [symbol-sync-deep-analysis-20260625.md](symbol-sync-deep-analysis-20260625.md) | **Symbol 同步深度分析**：实测 3,616 symbol 规模、数据量、限流权重、服务器评估、分批规则。 |
| [exchangeinfo-sync-design-20260625.md](exchangeinfo-sync-design-20260625.md) | **ExchangeInfo 同步技术选型**：落库触发方/DB/刷新策略/分级白名单/优先级模型 6 项决策权衡分析。配套 `module/binance/SPEC-exchangeinfo-sync.md`。 |
| [HANDOFF-FOR-CODEX-20260625.md](HANDOFF-FOR-CODEX-20260625.md) | **并发 agent 交接说明**：Draft FR（FR-031~036 禁止执行）、已完成工作、历史 issue ledger（全部 Closed）、依赖交叉、恢复前必做检查。 |

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
