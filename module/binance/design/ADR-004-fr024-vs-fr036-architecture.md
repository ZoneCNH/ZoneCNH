# ADR-004: FR-024 vs FR-036 架构路径裁决

> 状态：Accepted
> 日期：2026-06-27
> 决策者：ZoneCNH architecture
> 来源：MO-3 · spec-structural-analysis-20260627 · #1116 降级闭合
> 仓库归属：ZoneCNH 主仓 `module/binance/`

## 背景

FR-024（Runtime Config Hot Reload）当前实现为全量重连（catalog Reload 替换全部条目 → stream 重建）。FR-036（Tier-Aware Connection Topology）需要增量 stream add/remove diff，与 FR-024 当前全量重连路径冲突。

Issue #1116 通过"维持 Partial（symbol reload 已够）"关闭。`FEATURES.md:88` 标注"建议前置 ADR"。两个 FR 都卡在 Partial，需要裁决架构路径。

## 决策

**FR-036 自建增量 diff，不依赖 FR-024 升级。** 两者保持独立实现路径。

## 理由

1. **职责分离**：FR-024 是 catalog/symbol 级热重载（白黑名单变更 → catalog reload），FR-036 是 stream 连接拓扑管理（per productLine tier 分组连接）。两者操作粒度不同。
2. **全量重连可接受**：FR-024 的全量重连对于 symbol 级变更（新增/移除几个 symbol）是可接受的——重连时间 < 10s（SPEC §17 性能预算），不影响实时采集连续性。
3. **FR-036 增量 diff 复杂度独立**：FR-036 的增量 diff 需要 stream manager 按 (productLine, tier) 分组，计算 added/removed/updated stream diff，逐个建立/关闭连接。这与 FR-024 的 catalog reload 是不同层次的操作。
4. **避免耦合**：如果 FR-036 依赖 FR-024 升级为增量 diff，两者形成循环依赖（FR-024 需要 FR-036 的 stream diff 能力，FR-036 需要 FR-024 的 catalog reload 触发）。独立实现避免耦合。

## 影响

- FR-024 维持当前全量重连实现（Partial → 可升 Done，全量重连对 symbol 级变更可接受）
- FR-036 独立实现增量 stream add/remove diff（Pending → 需实现 stream manager diff 逻辑）
- 两者通过 `binance.control.symbols.changed` subject 解耦：FR-024 触发 catalog reload，FR-036 独立监听 catalog 变更并计算 stream diff

## 实现路径

FR-036 增量 diff 实现：
1. stream manager 维护 `activeStreams map[StreamKey]*StreamConnection`
2. catalog reload 后，计算 `desiredStreams = StreamsForProductLineTier(catalog, tierConfig)`
3. diff = `desiredStreams - activeStreams`（新增）+ `activeStreams - desiredStreams`（移除）
4. 新增 stream 异步建立（不阻塞现有采集）
5. 移除 stream 先 drain（复用 FR-004 NakWithDelay + DLQ 语义）再 unsubscribe

## 关联

- FR-024 Runtime Config Hot Reload（维持全量重连）
- FR-036 Tier-Aware Connection Topology（独立增量 diff）
- #1116 降级闭合（FEATURES.md §2 能力边界声明）
- spec-structural-analysis-20260627.md MO-3
