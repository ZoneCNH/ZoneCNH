# Options 历史 Backfill 替代方案

> 状态：Partial（2026-07-10 已纠正“无 kline 端点”的旧假设）
> 来源：Phase 2 实测确认 + ADR-010 R-P2
> Last-Updated：2026-07-10
> 关联：[HISTORICAL-DATA-SYNC-STRATEGY.md](HISTORICAL-DATA-SYNC-STRATEGY.md)、[ADR-010](ADR-010-platform-change-risks.md)

## 1. 问题

[COMPUTED, HIGH] Binance Options 的公共历史能力是不对称的：

- `GET /eapi/v1/klines` 提供按 symbol/interval/time window 查询的公共 kline；本轮 runtime 已接入。
- `GET /eapi/v1/trades` 只提供近期成交，没有当前 runtime 所需的完整时间窗历史回填语义。
- `GET /eapi/v1/depth` 是当前订单簿 snapshot，不是历史 depth 归档。
- 当前 runtime 对 Options history 明确支持 kline；trade/depth 历史仍 fail-closed 为 unsupported。

[COMPUTED, HIGH] 因此 Options kline 可以从官方源回填；启动前的完整逐笔 trade 与 depth 序列仍不能由现有公共 REST 路径重建。

## 2. 替代方案

### 方案 A：从系统启动起持续落库（推荐）

**策略**：对没有完整历史源的 Options trade/depth，从 binance-client 启动时持续采集并落库；kline 使用官方 REST 回填。

**优势**：
- 零外部依赖，完全自主
- 与 spot/um/cm 的实时采集链路一致（WS → normalize → natsx → server → TDengine/OSS）
- cold-start/gap-fill/reconcile 生命周期对 options 同样生效

**劣势**：
- 启动前的逐笔 trade/depth 无完整回填能力
- 首次部署时只能回填 kline，不能恢复完整历史订单簿序列

**实现**：`history_rest.go` 已支持 Options kline；其他 Options event type 返回 unsupported，job 必须 failed，不得跳过后伪造 coverage。

### 方案 B：eapi REST 近期数据有限回填

**策略**：eapi REST 提供近期数据查询端点（24hr ticker、recent trades），可有限回填最近 24 小时数据。

**可用端点**：
- `GET /eapi/v1/klines` — kline 时间窗查询（已接入）
- `GET /eapi/v1/ticker/24hr` — 24hr 统计（无逐笔数据）
- `GET /eapi/v1/depth` — 当前 depth 快照（非历史）
- `GET /eapi/v1/trades` — 近期成交（默认 500 条，最大 1000）

**限制**：
- trades 仅返回最近 1000 条，无分页/时间范围参数
- kline 可回填，但不能证明逐笔 trade/depth 历史完整
- depth 只有当前快照，无历史

**结论**：kline 可作为受支持的历史类型；近期 trades 只能作有限恢复，不能声明完整历史覆盖。

### 方案 C：第三方数据源（不推荐）

**策略**：从第三方数据提供商（如 Tardis.dev、Kaiko）购买 options 历史数据。

**劣势**：
- 引入外部依赖和成本
- 数据格式需适配
- 违反"不持有生产凭证"原则（需第三方 API key）

**结论**：不纳入当前实现范围。

## 3. 决议

采用 **kline REST 回填 + trade/depth 持续落库** 的组合策略：

1. `history_rest.go` 的 Options kline 路径使用 `/eapi/v1/klines`
2. Options trade/depth 历史请求显式 unsupported/failed，不得标记 skipped/completed
3. trade/depth 完整性依赖实时采集、durable checkpoint 与 gap evidence；daily reconcile 不能凭空恢复启动前序列
4. options 的 staleness 策略需考虑长时间无推送的场景（见 ORDER-BOOK-STATE-MACHINE.md §8）

## 4. 影响评估

| 维度 | 影响 |
|------|------|
| FR-016（Historical Backfill Planner） | Options kline supported；trade/depth unsupported |
| FR-026（Checkpoint Recovery） | trade/depth 依赖实时采集 durable checkpoint |
| FR-027（Cold Data Rehydration） | kline 可回填；trade/depth 只能水化已归档的本系统数据 |
| 数据完整性 | kline 与 trade/depth 必须分别判定，禁止聚合为一个“Options history complete”状态 |

## 5. 开放问题

- options WS 推送稀疏（流动性低）导致 staleness 频繁触发，需评估 staleness 超时阈值是否需要 per-product-line 配置（options 可能需要更长超时，如 5min 无更新才标 stale）
- 未来如 Binance 开放可分页的 Options trade/depth 历史端点或官方归档，需新增独立 capability 与完整性证明
