# binance 修复执行 Plan 索引

> Plan006 基于 `docs/report/binance/production-readiness-gap-analysis-20260624.md`（五轮 58 维度分析）。
> **Plan007 基于 Plan006 完成后的两份复核报告**：[`production-readiness-recheck-20260624.md`](../../docs/report/binance/production-readiness-recheck-20260624.md)（生产就绪复核，HEAD 8290dc9）+ [`foundationx-binance-decoupling-architecture-20260624.md`](../../docs/report/arch/foundationx-binance-decoupling-architecture-20260624.md)（解耦架构）。
> 执行顺序见各 Plan 内部 Phase；状态更新到本文件。

## 执行顺序与状态

| Plan | Title | Priority | Effort | Depends on | Status |
|------|-------|----------|--------|------------|--------|
| 006 | binance 模块生产就绪修复（49 Task，8 Phase；Phase 4-ALT 作废；新增 Task 7.0 infra 凭据+configx 接入） | P0 | XL(4.8~9pm) | Task 0.1 DONE(v2.0.0) | ✅ DONE（2026-06-24 六批次 PR#68/69/70/71/72/73 + 四文档 PR#1020/1021/1022/1023 合并）：**49/49 Task 全闭环**。beads 0 open · GitHub 0 open。验证：build(100x)/vet(100x)/test-race/boundary-gates(13)/govulncheck(0) 全绿。详见 [006-execution-alignment.md](006-execution-alignment.md) |
| 007 | binance 生产就绪收尾 + FoundationX 解耦隐患修复（双轨：Track A 功能 G1~G6/R1~R8 + Track B 跨仓库 §7.1~§7.7；18 Task，8 Phase） | P0/P1/P2 | M(1.1~2.05pm) | Plan006 DONE | ⏳ TODO。基于两份复核报告（HEAD 8290dc9）：Report1 勘误架构分裂已解决（22 FR 已实现），剩余 G1~G6 收尾；Report2 新增 transportx name bug + domain_* path 分叉 + wire→contracts 等 7 工程隐患。双轨可并行。详见 [007-binance-readiness-arch-fix.md](007-binance-readiness-arch-fix.md) |

Status values: TODO | IN PROGRESS | DONE | BLOCKED (with one-line reason) | REJECTED (with one-line rationale)

## 执行对齐记录

- 2026-06-24: [Plan006 执行对齐记录](006-execution-alignment.md) 同步本地验证、Beads、GitHub issue 状态；不改变 Plan006 生产级验收口径。

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
