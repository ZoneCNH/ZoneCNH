> ⚠️ **DEPRECATED** — 本文件已合并（v3.8.0），FR-031~036 / BR-010~012 已合并至 [`SPEC.md`](../SPEC.md) §7/§8。仅保留为历史参考，不作为活跃规范。所有后续变更必须以 [`SPEC.md`](../SPEC.md) 为 canonical source。

# SPEC 增补：ExchangeInfo DB 持久化与分级白名单同步

- Spec-ID: binance-exchangeinfo-sync
- Status: Merged into SPEC.md v3.8.0（原 Draft — 2026-06-26 合并）
- Created: 2026-06-25
- Parent: [`SPEC.md`](../SPEC.md) v3.8.0（FR-031~036 已合并入根 SPEC）（§8 Control Plane、§11.1 Config、§4.1 Boundaries）
- Supersedes: 无（增补，非替代）
- Scope: 在 SPEC v3.8.0 的 FR-030 之后新增 FR-031~036 / BR-010~012 / AC-131~154 / TC-066~083（v3 结构性审查修正：拆分 FR-033→FR-033+FR-036、StreamsForProductLineTier 按 productLine 分化、control stream LimitsPolicy、diff Updated/SpecUpdated 分离、options 到期峰值 BR-012；编号已协调：AC-105~130 / TC-050~065 保留给 Current FR-037~044）
- Runtime-Anchor: `/home/binance@f18a329`

> [COMPUTED, HIGH] 本文档是 `SPEC.md` 的**增补章节**，原编号在 v3.7.1 之后顺延。v3.8.0 已将 FR-031~036 / BR-010~012 合并入根 SPEC。本文档保留为历史参考。

> §0-§11 内容（FR-031~036 WHEN/THEN 定义、BR-010~012、AC-131~154、TC-066~083、数据流图、DB schema、实施顺序、风险矩阵）已合并至 [`SPEC.md`](../SPEC.md) §7 FR-031~FR-036 和 §8 BR-010~BR-012。本文件不再作为活跃规范。
