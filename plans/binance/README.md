# binance 修复执行 Plan 索引

> Plan006 基于 `report/binance/production-readiness-gap-analysis-20260624.md`（五轮 58 维度分析）。
> **Plan007 基于 Plan006 完成后的两份复核报告**：[`production-readiness-recheck-20260624.md`](../../report/binance/production-readiness-recheck-20260624.md)（生产就绪复核，HEAD 8290dc9）+ [`foundationx-binance-decoupling-architecture-20260624.md`](../../report/arch/foundationx-binance-decoupling-architecture-20260624.md)（解耦架构）。
> 执行顺序见各 Plan 内部 Phase；状态更新到本文件。

## 执行顺序与状态

| Plan | Title | Priority | Effort | Depends on | Status |
|------|-------|----------|--------|------------|--------|
| 006 | binance 模块生产就绪修复（49 Task，8 Phase；Phase 4-ALT 作废；新增 Task 7.0 infra 凭据+configx 接入） | P0 | XL(4.8~9pm) | Task 0.1 DONE(v2.0.0) | ✅ DONE（2026-06-24 六批次 PR#68/69/70/71/72/73 + 四文档 PR#1020/1021/1022/1023 合并）：**49/49 Task 全闭环**。beads 0 open · GitHub 0 open。验证：build(100x)/vet(100x)/test-race/boundary-gates(13)/govulncheck(0) 全绿。详见 [006-execution-alignment.md](006-execution-alignment.md) |
| 007 | binance 生产就绪收尾 + FoundationX 解耦隐患修复（双轨：Track A 功能 G1~G6/R1~R8 + Track B 跨仓库 §7.1~§7.7；18 Task，8 Phase） | P0/P1/P2 | M(1.1~2.05pm) | Plan006 DONE | ✅ **DONE（2026-06-25）** — 18/18 全部完成。A1/A2/A3/A4/A5/A6/A7/A8/A9/A10 + B1/B2/B3/B4/B5/B6/B7/B8。22/22 GitHub issues 关闭。证据: testnet 3/3 PASS + NATS JetStream PASS + 24 benchmarks PASS。详见 [007-binance-readiness-arch-fix.md](007-binance-readiness-arch-fix.md) · [007-execution-alignment.md](007-execution-alignment.md) |
| 008 | binance final closeout / release evidence sync（40 Task；GitHub/beads ledger + release gate） | P0 | S | Plan007 DONE | ✅ **DONE（2026-06-26）** — 40/40 Task 全部闭合；GitHub #1132-#1171 CLOSED；beads `plan008` 40/40 `closed`；GitHub Release `v0.2.0` + workflow `28126779885` completed/success；`release_closeable=YES`。**代码落地 33/40 (82.5%)**，核心链路（Phase 1 因果链 13/13 + Phase 4 门禁 2/2）全部合入 main `f046e16`（PR #145）。剩余 7 项（T005/T006/T027/T028/T031/T034/T035-038）为 Foundation 扩展与 P2 规模化合规，已开 [#1180-#1186](https://github.com/ZoneCNH/ZoneCNH/issues?q=is%3Aopen+label%3Aplan008) 追踪。详见 [008-binance-production-fix-master-plan.md](008-binance-production-fix-master-plan.md) · [008-issues-sync-report.md](008-issues-sync-report.md) · [009-remaining-issues-map.tsv](009-remaining-issues-map.tsv) |
| 010 | runtime gap fix execution（历史同步批次） | P0/P1/P2/P3 | L | Plan008 DONE | 🗂️ **ARCHIVED（2026-07-02）** — 010 系列为历史同步产物，含旧仓 `ZoneCNH/binance` 上下文，不再作为当前执行主链。保留用于审计追溯。 |
| 011 | runtime gap master plan（主仓 issue 执行链） | P0/P1/P2/P3 | XL | Plan010 ARCHIVED | 🔄 **IN PROGRESS（当前主链）** — 主仓 issue #1540~#1592 + beads `ZoneCNH-gg63` 双向映射，按 8 阶段推进闭环。详见 [011-runtime-gap-master-plan-20260702.md](011-runtime-gap-master-plan-20260702.md) · [011-master-issue-map.tsv](011-master-issue-map.tsv) |
| — | **Spec 缺口闭合**（35 项 plans/reports→spec 交叉比对补齐；SPEC v3.6.0→v3.7.0） | P0 | M | Plan008 DONE | ✅ **DONE（2026-06-26）** — `module/binance/SPEC.md` v3.7.0：新增 FR-037~044（8 个 FR 覆盖发布安全网/taosx retention/分布式 tracing/资源隔离/审计/成本/合规/Schema 版本策略）；AC 104→130；TC 49→65；BNC 13→16。`TRACEABILITY.md` / `FEATURES.md` / `ACCEPTANCE.md` 同步更新。4 文件 +287/-37 行。详见 [spec-gap-closure-20260626.md](../../report/binance/spec-gap-closure-20260626.md) |
| 010 | binance 运行时缺口修复执行计划（v2.0，58 GAP-E + 11 治理陷阱 + 15 漏洞链；beads/GitHub issue 同步） | P0 | XL | Spec 缺口闭合 | ⚠️ **SUPERSEDED by 011**（v2.0 → v2.1，5 轮 → 10 轮复核）。beads `ZoneCNH-gg63` 树 + 子仓 #365~#402 保留作历史 cross-reference。详见 [010-runtime-gap-fix-execution-plan-20260702.md](010-runtime-gap-fix-execution-plan-20260702.md) |
| 011 | binance 运行时缺口修复主计划（v2.1，10 轮深度分析定稿；8 Phase，58 GAP-E + 11 陷阱 + 4 EXCHANGEINFO 勘误） | P0 | XL(49d+32d) | Plan010 superseded | 🔄 **IN PROGRESS** — Phase 1 ✅ DONE（2026-07-03）：11 治理陷阱全部闭合（#1541~#1551 全部 closed），PRG-006 降级 Partial，release_closeable=NO，版本对齐 v3.9.8。Phase 2-8（58 GAP-E，55.25 人天）待 binance 子仓独立排期。详见 [011-runtime-gap-master-plan-20260702.md](011-runtime-gap-master-plan-20260702.md) · [todo.md](../../module/binance/todo.md) |

Status values: TODO | IN PROGRESS | DONE | BLOCKED (with one-line reason) | REJECTED (with one-line rationale)

## 执行对齐记录

- 2026-06-24: [Plan006 执行对齐记录](006-execution-alignment.md) 同步本地验证、Beads、GitHub issue 状态；不改变 Plan006 生产级验收口径。
- 2026-06-25: [Plan008 final closeout](008-binance-production-fix-master-plan.md) 与 [issues sync report](008-issues-sync-report.md) 同步 GitHub/beads 40/40 closed、Release `v0.2.0`、workflow `28126779885` completed/success、`release_closeable=YES`；不自动重判 FR 为 30/30 Done。
- 2026-06-26: Plan008 验证脚本从脚本目录解析 Plan、SSOT 与映射文件，feature worktree 内运行时读取 PR 分支文件，不再误读主 checkout。
- 2026-07-03: Plan011 Phase 1 治理分裂修复完成（11 陷阱全闭合，#1541~#1551 closed）。commit `2f3b03eb`：8 文件对齐 PRG-006 Partial / release_closeable=NO / v3.9.8。Phase 2-8 runtime gap 待 binance 子仓排期。

## 依赖说明

- **Phase 0（架构决策）阻断一切**：未决定 v1.0.0 回退 vs v2.0.0 迁移前，禁止启动 Phase 4+ runtime 修改
- **Phase 3 探针前置于 Phase 0**：Task 3.1 接口存在性探针须先于架构决策（v2.0.0 是否可选取决于依赖仓就绪）；Task 3.1 完整验证仍阻断 Phase 4
- **Phase 1（仓库卫生）+ Phase 2（规格治理）可与架构决策并行**：与架构无关，应立即启动
- **Phase 4-ALT（v1.0.0 回退）与 Phase 4~8 互斥**：Phase 0 选 v1.0.0 时走 4A.1~4A.3，跳过 v2.0.0 runtime 实现
- **Phase 4~7 严格串行（仅 v2.0.0）**：架构重写 → 扩展 → 测试 → 部署发布
- **Phase 8 贯穿**：错误码/文档对齐可随各 Phase 推进

## 关键 STOP 条件

1. Phase 0 未决策 → 禁止 Phase 4+
2. Task 3.1 依赖仓未就绪 → Phase 4 阻塞
3. 任一 P0 Task（1.1/4.1~4.7，或 v1 路径 4A.1/4A.2）未过 → 不得声明 Release Done
4. TRACEABILITY.md 无 runtime SHA + CI URL 时不得改 Pending → Implemented

## 覆盖率声明

`[COMPUTED, HIGH]` Plan 006 覆盖分析报告全部 58 维度发现（含第六轮复核：§11.1 go.sum 由 P0 降级 P2）：
- 2 P0 → Task 1.1, 4.1~4.7
- 29 P1 → Task 0.1, 1.3, 2.1~2.5, 3.1, 4.x, 5.x, 6.1~6.5, 7.1~7.4, 8.1, 8.5
- 19 P2 → Task 1.2, 1.4~1.7, 3.2, 6.6~6.8, 7.5, 8.2~8.4

> Phase 4-ALT（4A.1~4A.3）是 Phase 0 选 v1.0.0 回退时的条件 Task，与 Phase 4~8 互斥，不计入上述 v2.0.0 路径统计。

来源追溯矩阵见 Plan 006 末尾。

## 验收口径

- **发布就绪**：Phase 0~7 全 DONE + Phase 8 关键项 DONE
- **生产级别**：30/30 FR L2 Done + 104/104 AC PASS + 49/49 TC PASS + CI 全绿 + release tag/artifact + live websocket 证据
