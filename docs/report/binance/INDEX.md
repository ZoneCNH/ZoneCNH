# Binance reports index

- Last-Updated: 2026-06-25
- Scope: `docs/report/binance` report set for Stage0–Stage2 repair and audit follow-up.

> [COMPUTED, HIGH] 2026-06-23 final disposition: GitHub #923~#931 are all closed. Runtime/release evidence remains Pending where `module/binance/ACCEPTANCE.md` and `TRACEABILITY.md` keep FR/runtime/release gates open.
>
> [COMPUTED, HIGH] 2026-06-24 recheck: runtime HEAD advanced to `8290dc9` (PR #73「Plan006 final」) which deleted v1 architecture and implemented the natsx distributed path. The `production-readiness-gap-analysis-20260624.md` core conclusions (architecture split / 27 FR Pending) are superseded; see `production-readiness-recheck-20260624.md` for the current baseline (22 FR implemented / 8 partial / 0 unimplemented; remaining gaps narrowed to G1~G5).
>
> [COMPUTED, HIGH] 2026-06-25 assessment: runtime HEAD advanced to `e02b190` (Plan007 A1~A10 + B1~B8 executed). G1/G3/G4 closed; G2/G5 partial. **New finding G0: `cmd/binance-server/main.go` does not wire any storage writer** — persist() silently no-ops, so data never lands in taosx/postgresx/clickhousex/ossx/redisx. Also新增 G7（合约/期权产品线实质验证）与 G8（订单簿 diff/snapshot 重建）。See `production-readiness-assessment-20260625.md` for the current baseline.
>
> [COMPUTED, HIGH] 2026-06-25 fix-execution: **G0~G8 + C1/C4/C7 全部修复落地**（feature branch `fix/binance-production-readiness`, PR #93）。G0 存储装配闭合（storageFromEnv 真实装配 5 client + 7 writer）；FR 19/30→28/30 Done (93%)；C4 mainnet 四线 LIVE-PASS（spot/um/cm trade 实证）；10 轮独立验证全部 PASS；26 beads issues 闭环。剩余：SRE infra 解锁（redis/taos/kafka/oss）+ CI 私有依赖修复（issue #94）后打 v0.2.0 tag。See `production-readiness-fix-execution-20260625.md` + `sre-unblock-checklist-20260625.md`.

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
| [github-issues-923-931-closure-ledger-20260623.md](github-issues-923-931-closure-ledger-20260623.md) | GitHub #923-#931 closure ledger: 9/9 GitHub issues closed, with runtime/release readiness explicitly kept under acceptance and release gates. |

## Production readiness reports

| Report | Purpose |
| --- | --- |
| [production-readiness-gap-analysis-20260624.md](production-readiness-gap-analysis-20260624.md) | 5-round 58-dimension gap analysis based on runtime HEAD `4fa920b`. **Core conclusions superseded by PR #73** — kept for audit trail. |
| [production-readiness-recheck-20260624.md](production-readiness-recheck-20260624.md) | Recheck based on runtime HEAD `8290dc9` (PR #73). Corrects the predecessor: architecture split resolved, 22/30 FR implemented, remaining gaps narrowed to G1 (history fetcher stub) / G2 (real integration evidence) / G3 (NakWithDelay+DLQ) / G4 (cross-product-line collision test) / G5 (release artifact). Estimated 0.8~1.8 person-months to production. |
| [production-readiness-assessment-20260625.md](production-readiness-assessment-20260625.md) | Comprehensive assessment based on runtime HEAD `e02b190` (Plan007 executed). Verifies G1/G3/G4 closed, G2/G5 partial. **New finding G0 (storage wiring gap): main.go does not wire any storage writer, persist() silently no-ops.** Adds G7 (futures/options product-line substantive verification) and G8 (orderbook diff/snapshot rebuild). Includes实测数据流架构图、业务类型覆盖矩阵、模块规范建议。Estimated 1.5~2.5 person-months to production. §9 追加修复执行记录（G0 闭合后修订为 1-2 工作日）。 |
| [production-readiness-fix-execution-20260625.md](production-readiness-fix-execution-20260625.md) | **修复执行记录**：G0~G8 + C1/C4/C7 全部 P0+P1 修复落地。Agent Team Wave1-3 + 10 轮独立验证（全部 PASS）+ 实证推进（mainnet LIVE-PASS / pg+ch 建连 / Kafka driver 修复）+ beads 26 闭环 + PR #93/#1076 + CI issue #94。 |
| [sre-unblock-checklist-20260625.md](sre-unblock-checklist-20260625.md) | **SRE 解锁清单**：redisx（密码）/taosx（driver）/Kafka（topic）/OSS（凭据）的 infra 侧阻塞项操作清单，含解锁后完整验证命令。零代码工作。 |
| [issues-sync-final-20260625.md](issues-sync-final-20260625.md) | 21 条 issues 拆解映射（beads ↔ GitHub）。§2 追加本次修复闭环记录（26 beads closed + PR #93/#1076 + issue #94）。 |

## Stage0–Stage2 executable gates

- Stage1 doc gate: `scripts/check-binance-docs.sh`
- Stage2 lifecycle draft: `module/binance/DATA-LIFECYCLE.md` (v3.5.0 — FR-012~FR-030 registered in SPEC/TRACEABILITY; runtime evidence largely in place post-PR #73, see `production-readiness-assessment-20260625.md` for residual G0/G7/G8 gaps)
- Stage6 `module/binance/STANDARD.md` is Active (v0.1.1) and wired into R9 + check-binance-docs.sh.
