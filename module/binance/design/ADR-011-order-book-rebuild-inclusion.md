# ADR-011: Order Book Rebuild 纳入决策

> 状态：Accepted（spec-review 2026-07-06 通过，5 项 minor fix 已闭合）
> 日期：2026-07-06
> 决策者：ZoneCNH architecture
> Supersedes：[ADR-003](ADR-003-order-book-rebuild-exclusion.md)
> 仓库归属：ZoneCNH 主仓 `module/binance/`

## 背景

ADR-003（2026-06-27, Accepted）决定 v0.2.0 排除 order book rebuild 状态机，depth 数据以快照级落库，不维护本地 order book。排除理由：复杂度收益不对等、无下游消费者需要完整 order book 序列、存储成本高。

ADR-003 §未来升级路径 预测：若下游需要完整 order book 序列（做市策略、微观结构分析），升级路径为 client 侧 order book manager + 新增 FR + 存储扩展 + MAJOR 版本升级（v4.0.0）。

[SEQUENCE-CONTINUITY-STRATEGY.md](SEQUENCE-CONTINUITY-STRATEGY.md) §4 已记录 Binance 官方 8 步 depthUpdate 重建算法作为技术参考，标注为"未实施的参考实现"。

## 变化

自 ADR-003 以来，以下条件发生了变化：

1. **下游需求已明确**：做市策略 / 风控 / 微观结构分析场景需要完整 order book 序列，而非仅 TopN 快照。快照级落库无法支持"档位级别变化历史回放"和"实时 book building"。
2. **depthUpdate 重建算法已充分验证**：SEQUENCE-CONTINUITY-STRATEGY.md §4 的 8 步算法来自 Binance 官方文档，spot（U/u）与 futures（U/u/pu）的差异已明确。
3. **命名体系已对齐**：v3.18.0 canonical 命名对齐 Binance 原生事件名（`depthUpdate` → `depth_update`），NATS subject / Kafka topic / TDengine 表名全链路一致，为新功能提供了干净的命名基础。
4. **状态机设计已就绪**：[ORDER-BOOK-STATE-MACHINE.md](ORDER-BOOK-STATE-MACHINE.md) 定义了完整的状态转换、并发模型、staleness 语义和市场差异，回答了 ADR-003 未覆盖的持久化恢复、限档/全量互斥、重建期 buffer、TopN 推送频率等设计问题。

## 决策

**纳入 order book rebuild 状态机，作为 v4.0.0 MAJOR 版本升级的核心功能。**

### 范围

| 范围内 | 范围外 |
|--------|--------|
| 全量增量深度（`full_incremental` 模式）的本地 order book 状态机 | 用户数据流落库（ADR-009 仍排除） |
| 限档快照流（`snapshot_topn` 模式）的无状态转发 | 跨交易所 order book 聚合 |
| 多市场并行（spot / um_perp / cm_perp） | options depth（待实测验证，见 §待确认） |
| 快照持久化与快速恢复 | 做市策略逻辑（本模块只提供数据，不做策略） |
| Staleness 标记与对外接口 | — |
| 自动重建与重建频率告警 | — |

### 版本影响

- SPEC：v3.18.0 → v4.0.0（MAJOR）
- Runtime：v0.13.0 → v0.14.0（MAJOR，新增 order book manager 组件）
- 新增 FR：FR-052 ~ FR-061（10 个 FR，全部 Pending）

## 理由

1. **下游需求已materialized**：ADR-003 排除时的前提"无下游消费者需要完整 order book 序列"已不成立。
2. **"错了不会报错"的风险无法接受**：当前快照级落库模式下，depth 数据完整性依赖 `updateId` 跳跃检测 → 快照刷新。但"校验通过但实际漂移"的隐性 bug 无兜底机制。order book 状态机提供连续性校验 + 定期 checksum 抽样，是唯一能发现隐性漂移的方案。
3. **设计已就绪，风险可控**：状态机设计文档已定义完整的状态转换、invariant、guard/action、并发模型，8 步重建算法来自官方文档，实现路径清晰。
4. **MAJOR 升级的边界清晰**：不影响 v3.18.0 的 canonical 命名、NATS subject、Kafka topic、TDengine 表名。新增的 order book manager 是 client 侧组件，不改变 C/S 通信协议。
5. **存储成本可控**：ADR-003 排除时的"100x+ 存储成本"担忧针对的是"完整 order book 增量序列持久化"。本方案的设计是：内存维护 book + 5min 快照持久化（非逐条增量落盘），存储成本与快照模式同级（O(1) per snapshot vs O(N) per event）。完整增量序列仅通过 Kafka topic 转发给下游（Kafka 7d retention，不进 TDengine），不额外增加持久化存储。

## 后果

### 正面

- 下游可获得经过序号校验的完整 order book 增量流
- 支持做市 / 风控 / 微观结构分析场景
- Staleness 标记让下游不会拿到"看起来正常但已过期"的订单簿
- 定期 checksum 抽样提供隐性漂移兜底

### 负面

- **复杂度增加**：order book 状态机是整条链路中最复杂的状态管理组件
- **内存占用增加**：每个 symbol 维护完整 order book（有序价格→数量结构），按 symbol 数线性增长
- **MAJOR 版本升级**：需要 migration plan，runtime 代码变更量大
- **options 待确认**：options depth 的 U/u/pu 语义未验证，可能需要独立实现

### 对 ADR-003 的影响

ADR-003 状态从 Accepted 变为 **Superseded**。ADR-003 §影响 中的限制（depth 数据仅存快照、不存增量 diff 序列、下游无法获取历史 order book 变化序列）在 v4.0.0 后不再适用。ADR-003 §未来升级路径 的 4 步方案（order book manager + 新 FR + 存储扩展 + MAJOR 版本）由本 ADR 正式启动。

## 待确认

| 项目 | 说明 | 阻塞级别 |
|------|------|----------|
| options depth 协议 | options 的 depth 事件是否有 U/u/pu 字段、更新频率可选项、限档快照流级别 | 阻塞 options 实现（不阻塞 spot/um/cm） |
| checksum 抽样频率 | 定期 REST 快照 vs 内存 diff 的建议频率（1min? 5min?） | 非阻塞，可配置 |
| 全量增量存储格式 | TDengine depth_update 表是否需要 schema 扩展（加 side/level 字段） | 非阻塞，设计层决定 |

## 合规验证

- [x] ORDER-BOOK-STATE-MACHINE.md 通过 spec-review 审查（2026-07-06，5 项 minor fix 已闭合）
- [ ] options depth 协议实测确认（或明确排除 options 范围）
- [x] 新增 FR 编号分配（FR-052~061），进入 Spec → Code 管线（S1-S5 完成）
- [x] ADR-003 状态更新为 Superseded，添加交叉引用
- [x] RUNTIME-MAPPING.md 更新（新增 order book manager 组件路径）

## 关联

- [ADR-003](ADR-003-order-book-rebuild-exclusion.md)（Superseded by 本 ADR）
- [ORDER-BOOK-STATE-MACHINE.md](ORDER-BOOK-STATE-MACHINE.md)（状态机设计）
- [SEQUENCE-CONTINUITY-STRATEGY.md](SEQUENCE-CONTINUITY-STRATEGY.md) §4（8 步重建算法参考）
- [EVENT-TYPE-MAPPING.md](EVENT-TYPE-MAPPING.md) §2.1 `depth_update`（canonical 命名）
- [NAMING.md](../spec/NAMING.md) §5（TDengine `depth_update` supertable）
- [HISTORICAL-DATA-SYNC-STRATEGY.md](HISTORICAL-DATA-SYNC-STRATEGY.md) §depth 无回溯声明
