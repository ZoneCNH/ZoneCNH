# Symbol 分级体系治理制品交叉引用（tier-gap-cross-reference）

> **Evidence ID**: EVID-TIER-XREF-20260702
> **Date**: 2026-07-02（UTC）
> **Type**: 治理制品交叉引用（修复 GAP-E57：evidence 无 GAP-E 引用）
> **Scope**: binance 模块 ExchangeInfo symbol 采集分级体系（GAP-E6/E24/E25/E26）

## 目的

首次建立 `evidence/` 目录与运行时缺口（GAP-E）、设计决策（ADR）、实施任务（TASK）三者之间的**显式交叉引用**，修复 `RUNTIME-GAP-MATRIX.md` 记录的 GAP-E57（evidence 目录无任何 GAP-E 引用）。

本证据不验证代码运行时行为（运行时验证待 binance 仓库 feature branch 落地后补），只**固化治理制品间的追溯链闭合**。

## 交叉引用矩阵

### 缺口（GAP-E）→ 设计（ADR）→ 任务（TASK）→ 验收（AC）

| GAP-E | 严重度 | 设计制品 | 实施任务 | 运行时 AC | 状态 |
|-------|--------|----------|----------|-----------|------|
| **GAP-E6** | CRITICAL | [ADR-005](../../design/ADR-005-symbol-tier-classification.md) §1/§3（数据字段层） | [CLIENT-015](../../tasks/client/TASK-BINANCE-CLIENT-015-tier-schema-and-refresher.md) | AC-TIER-001 / AC-TIER-002 | Open（task spec 已建，待落地） |
| **GAP-E24**（数据层） | HIGH | [ADR-005](../../design/ADR-005-symbol-tier-classification.md) §3（四字段） | [CLIENT-015](../../tasks/client/TASK-BINANCE-CLIENT-015-tier-schema-and-refresher.md) | AC-TIER-002 | Open |
| **GAP-E24**（决策层） | HIGH | [ADR-005](../../design/ADR-005-symbol-tier-classification.md) §4/§5/§6 + [TIER-DESIGN-DETAILS](../../design/TIER-DESIGN-DETAILS.md) §2/§3/§6 | [CLIENT-017](../../tasks/client/TASK-BINANCE-CLIENT-017-tier-classify-and-collection.md) | AC-TIER-004 / AC-TIER-005 | Open |
| **GAP-E24**（server） | HIGH | [ADR-005](../../design/ADR-005-symbol-tier-classification.md) §3 | [SERVER-018](../../tasks/server/TASK-BINANCE-SERVER-018-catalog-tier-columns.md) | AC-TIER-006 | Open |
| **GAP-E25** | CRITICAL（§8.2 降可选） | [ADR-005](../../design/ADR-005-symbol-tier-classification.md) §6 + [TIER-DESIGN-DETAILS](../../design/TIER-DESIGN-DETAILS.md) §9 | [CLIENT-018](../../tasks/client/TASK-BINANCE-CLIENT-018-optional-sharding.md)（OPTIONAL） | — | Open（可选，待负载评估） |
| **GAP-E26** | HIGH | [TIER-DESIGN-DETAILS](../../design/TIER-DESIGN-DETAILS.md) §1（interval 列） | [CLIENT-016](../../tasks/client/TASK-BINANCE-CLIENT-016-interval-ssot.md) | AC-TIER-003 | Open |

### 报告 → 制品溯源

| 上位报告 | 章节 | 落地制品 |
|----------|------|----------|
| `report/binance/EXCHANGEINFO-SYMBOL-TIER-ANALYSIS-20260702.md` | §1 现状证据 | ADR-005 §1 背景 |
| 同上 | §2 三维度（Tier/Level/Priority） | ADR-005 §2 |
| 同上 | §3 分级体系设计 | ADR-005 §3 + TIER-DESIGN-DETAILS §1/§2 |
| 同上 | §4 四支撑层 | ADR-005 §3/§4 + TIER-DESIGN-DETAILS §3/§4 |
| 同上 | §8.1 options 勘误 | ADR-005 §6 + TIER-DESIGN-DETAILS §6 + CLIENT-017 options_classify |
| 同上 | §8.2 E25 可选化勘误 | ADR-005 §6 + TIER-DESIGN-DETAILS §9 + CLIENT-018 OPTIONAL |
| 同上 | §8.3 白名单 MVP 勘误 | ADR-005 §5 + CLIENT-017 STREAM_SYMBOLS |
| `report/binance/DATA-INTEGRITY-E2E-20260701.md` | GAP-E6/E24/E25/E26 | RUNTIME-GAP-MATRIX §2.1/§2.2 + 本交叉引用 |

## 命名裁决记录

- **symbol 级优先级**用 `SymbolPriority`（避开既有任务级 `LifecycleTask.Priority`，lifecycle.go:16-19），复合排序 `(SymbolPriority, TaskPriority)`。[源自 ADR-005 §2]
- **Tier 五级**：T0 核心 / T1 主流 / T2 次主流 / T3 长尾 / T4 监控。[TIER-DESIGN-DETAILS §1]
- **Collection 六种**：full_stream / stream_no_depth / kline_only / rest_sample / rest_daily / disabled。[TIER-DESIGN-DETAILS §2]
- **AC 编号**：运行时口径用 `AC-TIER-*` 前缀，与规格口径数字编号（AC-001~AC-104）区分，不计入 48 Done 统计。[ACCEPTANCE.md §2.1]

## GAP-E57 修复声明

GAP-E57 记录：`evidence/` 目录此前无任何 GAP-E 引用，导致运行时缺口与交付证据断链。本文件首次建立该引用链：每个相关 GAP-E（E6/E24/E25/E26）均显式映射到 ADR、TASK、AC 三类治理制品。**GAP-E57 由此闭合**。

## 双口径合规声明

- 本证据及关联制品（ADR-005、5 个 TASK、AC-TIER 段、FR-033 括注）均属**运行时口径**。
- 规格口径（SPEC.md `48 Done / 0 Partial / 0 Drifted / 0 Pending`）**未受影响**：
  - 未新增 FR-045+（分级体系不进 SPEC FR 表）
  - FR-033 仅加澄清括注，状态仍 Done、名称未改
  - AC-TIER-* 不计入 AC-001~AC-104 的 48 Done 统计
- 验证命令：`bash .github/ci/binance-status-consistency-check.sh` 期望 PASS。

## 认识论声明

- 治理制品补齐 = [KNOWN]（本 PR 直接创建，可审计）
- 分级体系设计合理性 = [INFERRED]（基于 EXCHANGEINFO 报告源码审计 + §8 对抗复核，HIGH 置信度）
- 运行时 AC 状态 = [FRAME]（"Open" 表示 task spec 已建但代码未落地，非运行验证结论；禁止 FRAME→REALITY）

> **[RULES I BROKE]**：无。所有引用路径与编号经文件系统核验存在。
