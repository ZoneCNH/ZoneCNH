# ADR-003: Order Book Rebuild 排除决策

> 状态：Accepted
> 日期：2026-06-27
> 决策者：ZoneCNH architecture
> 来源：#1114 降级闭合 · spec-structural-analysis-20260627 MO-4
> 仓库归属：ZoneCNH 主仓 `module/binance/`

## 背景

FR-017（Gap Detection and Replay）的 depth 缺口检测策略在 v3.9.0 spec 中定义为「updateId 序列跳跃 → 触发 depth snapshot refresh（重新拉取 `GET /api/v3/depth` 全量快照），而非生成 gap replay job」。

当前 runtime（`/home/binance@2efc44a`）的 depth 处理为快照级落库（`stream_control.go` depth 处理为快照级），不维护本地 order book 状态机，不做增量 diff 重放。

Issue #1114 通过"明确排除（当前版本）"关闭 — order book rebuild 状态机非 v0.2.0 范围。但需 ADR 记录决策理由和未来路径。

## 决策

**当前版本（v0.2.0）排除 order book rebuild 状态机。** depth 数据以快照形式落库，不做本地增量重放。

## 理由

1. **复杂度收益不对等**：order book rebuild 需要维护本地 order book 状态机 + REST snapshot 拉取 + 增量 diff 重放，复杂度高。当前下游消费者（market_data / 分析域）仅需 depth 快照，不需要完整 order book 序列。
2. **v3.9.0 spec 已定义替代路径**：depth updateId 跳跃 → 快照刷新（`GET /api/v3/depth`），而非 replay job。这保证了 depth 数据的完整性，无需 order book rebuild。
3. **存储成本**：完整 order book 序列的存储量是快照的 100x+，当前存储预算不支持。
4. **下游需求验证**：经与 market_data / 分析域确认，当前无下游消费者需要完整 order book 序列。

## 影响

- depth 数据仅存快照（top-of-book + 部分/全量档位），不存增量 diff 序列
- 下游消费者通过 `GET /api/v1/market/depth/:symbol` 获取最新快照，无法获取历史 order book 变化序列
- FR-017 的 depth 缺口检测策略为「updateId 跳跃 → 快照刷新」，不生成 replay job

## 未来升级路径

如果未来下游需要完整 order book 序列（如做市策略、微观结构分析），升级路径为：
1. client 侧增加 order book manager（维护本地 book 状态 + REST snapshot + 增量 diff）
2. 新增 FR 定义 order book rebuild 状态机和存储格式
3. 存储层扩展（taosx depth 增量表 或 专用 order_book 表）
4. 预计 MAJOR 版本升级（v4.0.0）

## 关联

- FR-017 Gap Detection and Replay（v3.9.0 depth 策略）
- #1114 降级闭合（FEATURES.md §2 能力边界声明）
- spec-structural-analysis-20260627.md MO-4
