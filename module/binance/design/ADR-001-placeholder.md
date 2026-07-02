# ADR-001：早期架构决策并入规格（编号占位）

> 状态：Accepted（占位）— 此编号保留，不承载独立决策
> 日期：2026-07-02
> 决策者：binance 模块维护者
> 仓库归属：ZoneCNH 主仓 `module/binance/`

## 背景

binance 模块 `design/` 目录现有 ADR-002（wire-boundary）、ADR-003（order-book-rebuild-exclusion）、ADR-004（fr024-vs-fr036-architecture）、ADR-005（symbol-tier），编号从 002 起跳，ADR-001 空缺。

历史原因：binance 模块最早的架构决策——wire 边界（client/server 互不 import）、product-line 四分类（spot / futures / options / portfolio margin）、catalog 数据模型（CatalogEntry 基础字段）、client/server 责任划分——在建仓时已直接写入 `spec/SPEC.md` §1-§6 与根 SPEC，未单独形成 ADR 文档。后续需要专门裁决的新议题才从 ADR-002 开始记录，导致 ADR 编号链从 002 起跳。

GAP-E56（见 RUNTIME-GAP-MATRIX）记录了此跳号问题。

## 决策

正式保留 ADR-001 编号为占位，**不回溯补写**独立决策文档。明确指向：早期架构决策已并入 `spec/SPEC.md` §1-§6，主要包括：

- wire 边界（client/server 互不 import，见 SPEC §3）
- 产品线四分类（spot / futures / options / portfolio margin，见 SPEC §1）
- CatalogEntry 基础字段（symbol / productLine / tier / status，见 SPEC §4）
- client/server 边界（采集端 vs 入库端职责划分，见 SPEC §6）

## 理由

1. **回溯补写成本高且无新增信息**：早期决策的原始上下文（讨论记录、备选方案）已不可考，从 SPEC 反推写 ADR 只是把已有内容换格式复述，不产生新的决策价值。
2. **后续 ADR 形成连续编号链**：ADR-002（wire-boundary）、003（order-book-exclusion）、004（fr024-vs-fr036）、005（symbol-tier）已建立连续编号。补 ADR-001 占位即可消除跳号疑问，无需改动既有编号。
3. **符合 CONSTITUTION 文档层级**：按 `Constitution > Spec > Design > Plan > Task > Local Choice`，早期决策记录在 SPEC 层合法（SPEC 高于 Design）。ADR 是 Design 层产物，用于 SPEC 之后的新议题裁决，无需为已落入 SPEC 的历史决策补 Design 层文档。

## 影响

- ADR 编号链 `001（占位）→ 002 → 003 → 004 → 005` 连续，读者不再困惑跳号。
- GAP-E56（ADR 跳号）由此关闭。
- 后续新增 ADR 从 006 起继续编号。

## 关联

- GAP-E56（RUNTIME-GAP-MATRIX）
- ADR-002-wire-boundary、ADR-003-order-book-rebuild-exclusion、ADR-004-fr024-vs-fr036-architecture、ADR-005-symbol-tier
- `spec/SPEC.md` §1-§6（早期决策权威来源）
