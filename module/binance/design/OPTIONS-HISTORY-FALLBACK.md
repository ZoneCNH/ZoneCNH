# Options 历史 Backfill 替代方案

> 状态：Design
> 来源：Phase 2 实测确认 + ADR-010 R-P2
> Last-Updated：2026-07-07
> 关联：[HISTORICAL-DATA-SYNC-STRATEGY.md](HISTORICAL-DATA-SYNC-STRATEGY.md)、[ADR-010](ADR-010-platform-change-risks.md)

## 1. 问题

Binance European Options（eapi.binance.com）**无公开历史数据端点**：

- `data.binance.vision` 不提供 options 历史数据（仅 spot/futures）
- eapi REST API 无 kline/historicalTrades 端点
- GitHub `binance/binance-public-data` 不含 options 数据
- `history_rest.go` 中 options 回退 `ErrNotConnected`（已知缺口）

这意味着 options 的历史 kline/trade/depth 数据**无法从官方源回填**。

## 2. 替代方案

### 方案 A：从系统启动起持续落库（推荐）

**策略**：options 数据从 binance-client 启动的那一刻起持续采集并落库，历史深度 = 系统运行时长。

**优势**：
- 零外部依赖，完全自主
- 与 spot/um/cm 的实时采集链路一致（WS → normalize → natsx → server → TDengine/OSS）
- cold-start/gap-fill/reconcile 生命周期对 options 同样生效

**劣势**：
- 无历史回填能力（启动前数据不可得）
- 首次部署时 options 无历史数据可用

**实现**：已在 `history_lifecycle.go` 中支持，options 的 `HistoryFetcher` 返回 `ErrNotConnected` 时，lifecycle 跳过 backfill，仅依赖实时采集。

### 方案 B：eapi REST 近期数据有限回填

**策略**：eapi REST 提供近期数据查询端点（24hr ticker、recent trades），可有限回填最近 24 小时数据。

**可用端点**：
- `GET /eapi/v1/ticker/24hr` — 24hr 统计（无逐笔数据）
- `GET /eapi/v1/depth` — 当前 depth 快照（非历史）
- `GET /eapi/v1/trades` — 近期成交（默认 500 条，最大 1000）

**限制**：
- trades 仅返回最近 1000 条，无分页/时间范围参数
- 无 kline 端点，无法回填 K 线
- depth 只有当前快照，无历史

**结论**：仅能用于 gap-fill 最近 1000 笔 trade，不适合完整历史回填。

### 方案 C：第三方数据源（不推荐）

**策略**：从第三方数据提供商（如 Tardis.dev、Kaiko）购买 options 历史数据。

**劣势**：
- 引入外部依赖和成本
- 数据格式需适配
- 违反"不持有生产凭证"原则（需第三方 API key）

**结论**：不纳入当前实现范围。

## 3. 决议

采用 **方案 A（从系统启动起持续落库）** 作为 options 历史 backfill 的替代策略：

1. `history_rest.go` 的 options 路径保持 `ErrNotConnected`（无公开历史端点）
2. `history_lifecycle.go` 对 options 的 backfill 任务标记为 `skipped (no historical source)`
3. options 数据完整性依赖实时采集 + daily reconcile（FR-026）
4. options 的 staleness 策略需考虑长时间无推送的场景（见 ORDER-BOOK-STATE-MACHINE.md §8）

## 4. 影响评估

| 维度 | 影响 |
|------|------|
| FR-016（Historical Backfill Planner） | options 不适用，spec 标注"无公开历史源" |
| FR-026（Checkpoint Recovery） | options 依赖实时采集 checkpoint，无历史回填 |
| FR-027（Cold Data Rehydration） | options 无冷数据可水化 |
| 数据完整性 | options 历史深度 = 系统运行时长，非全量历史 |

## 5. 开放问题

- options WS 推送稀疏（流动性低）导致 staleness 频繁触发，需评估 staleness 超时阈值是否需要 per-product-line 配置（options 可能需要更长超时，如 5min 无更新才标 stale）
- 未来如 Binance 开放 options 历史数据端点，需更新 `history_rest.go` 支持回填
