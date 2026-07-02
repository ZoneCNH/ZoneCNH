# TASK-BINANCE-CLIENT-017 Tier 分级决策层与 Collection 路由

> 版本：v1.0.0
> 关联：ADR-005（决策层实现）、TIER-DESIGN-DETAILS §2/§3/§4/§6
> 缺口：GAP-E24 [HIGH]（RUNTIME-GAP-MATRIX.md L60，采集治理：全量 active symbol 资源不可承受）
> 上游报告：EXCHANGEINFO-SYMBOL-TIER-ANALYSIS-20260702.md §4.3/§4.5/§8（含 §8.1 options 单列 + §8.3 白名单 MVP 两项勘误）

## Objective

实现 ADR-005 的**决策层**——把 catalog 数据字段（CLIENT-015 已落地的 Tier/SymbolPriority/Collection/QuoteVolumeUSD）真正驱动到采集决策上，消灭"全量 active symbol 平等对待"的治理黑洞（GAP-E24）。三个能力点：

1. **白名单 MVP 优先**（ADR-005 §5/§6.3，EXCHANGEINFO §8.3 勘误）：`STREAM_SYMBOLS` 配置存在时，仅白名单内 symbol 进 WS 订阅，~0.5d 改动覆盖 ~90% 业务需求，先于完整动态分级落地。
2. **classifyTier 三层降级 + Collection 路由**（ADR-005 §4，DETAILS §3/§2）：显式配置 → quoteVolume 阈值 → quoteAsset 兜底；Tier 映射到 6 种 Collection 采集策略。
3. **options 单列维度**（ADR-005 §6.1，EXCHANGEINFO §8.1 勘误）：options 不进 Tier 模型，按 `(距到期天数, moneyness)` 分桶，规避末日/近月 gamma 丢失。

## 分布式约束

- 本任务只改 **client 决策逻辑**：不动 CatalogEntry 字段定义（CLIENT-015 已加）、不动 interval SSOT（CLIENT-016 已建）、不动 server schema（SERVER-018 专责）、不引入分片（CLIENT-018 可选）。
- `CatalogEntry` 是 binance 仓内部类型，决策层读取其字段，不跨 ADR-002 wire 边界。
- 决策谓词从 `Status` 单字段扩展为 `(Status, Collection, Tier)` 复合谓词（ADR-005 §8.2）。

## Scope

```text
scope_in:
  internal/client/tier.go              ← 新建：classifyTier 三层降级 + activeSymbolsByProductLineAndTier
  internal/client/options_classify.go  ← 新建：options 按 (距到期天数, moneyness) 分桶，不进 Tier
  internal/client/lifecycle.go:161-174 ← SyncCatalog 加 Collection/Tier 过滤（原 L167 唯一谓词 Status==active）
  internal/client/lifecycle.go:177-291 ← QueueColdStartBackfill / QueueDailyReconciliation 按 Collection 分配 REST budget
  internal/client/history_lifecycle.go:530-583,775-783 ← Reconcile 按 Tier 决定对账频率
  internal/client/stream_control.go:333-357 ← streamConfig 按 Collection 过滤 WS 订阅 + STREAM_SYMBOLS 白名单
  pkg/binancecfg/config.go:249-269     ← 加 tiers per-tier 配置 + STREAM_SYMBOLS 白名单字段

scope_out:
  internal/client/catalog.go:16-46         ← CatalogEntry 字段（CLIENT-015）
  internal/client/exchangeinfo*.go         ← decode 与 TRADING 过滤（CLIENT-015）
  internal/client/interval.go / product_line.go:26 ← interval SSOT（CLIENT-016）
  internal/server/                          ← binance_symbols 表加列（SERVER-018）
  分片 / 一致性哈希 / ClientRegistry        ← CLIENT-018（可选，ADR-005 §6.2）
```

## 接口设计

### classifyTier 三层降级（DETAILS §3）

```go
// internal/client/tier.go
// classifyTier 按 ADR-005 §4 三层降级判定 Tier 与同 Tier 内优先级。
// 返回 (tier, priority)：tier ∈ [0,4]，priority ∈ [0,3]，0 为最高优先。
func classifyTier(symbol, quoteAsset string, quoteVolumeUSD float64, cfg TierConfig) (tier int, priority int) {
    // 第一层：显式配置（Level 决策，T0 人工维护，最高优先）
    if t, ok := cfg.ConfiguredTier(symbol); ok {
        return t, 0
    }
    // 第二层：流动性信号（依赖 CLIENT-015 decode 保留的 quoteVolumeUSD）
    switch {
    case quoteVolumeUSD >= cfg.T1VolumeThreshold: // [INFERRED] 阈值待校准，初始建议 50_000_000
        return 1, 1
    case quoteVolumeUSD >= 1_000_000:
        return 2, 2
    default:
        return 3, 3
    }
    // 第三层：计价资产兜底（quoteVolumeUSD==0 时）—— USDT/USDC 至少 T2，其他 → T3
}
```

### stream_control 按 Collection 过滤 + 白名单 MVP（DETAILS §2）

```go
// internal/client/stream_control.go:streamConfig（原 L333-357）
// 改：从 ActiveSymbols() 全量笛卡尔积，改为按 Collection 过滤 + STREAM_SYMBOLS 白名单优先。
func (sc *SpotConnector) streamConfig() ([]string, []string, []string, string) {
    // 白名单 MVP（ADR-005 §5）：配置存在时仅白名单 symbol 进 WS
    if whitelist := sc.cfg.StreamSymbols; len(whitelist) > 0 {
        return sc.buildStreams(whitelist, suffixesForCollection("full_stream"))
    }
    // 完整分级：仅 Collection ∈ {full_stream, stream_no_depth, kline_only} 才订阅 WS
    entries := sc.catalog.EntriesByProductLine(sc.ProductLine())
    symbols, suffixes := []string{}, []string(nil)
    for _, e := range entries {
        if e.Status != "active" || shouldSkipWS(e.Collection) { continue }
        symbols = append(symbols, e.Symbol)
        suffixes = suffixesForCollection(e.Collection) // 按 Collection 选后缀集合
    }
    // ... 拼 streamURL
}

func shouldSkipWS(collection string) bool {
    switch collection {
    case "full_stream", "stream_no_depth", "kline_only": return false
    default: return true // rest_sample / rest_daily / disabled 不占 WS
    }
}
```

### 白名单 MVP 配置示例（ADR-005 §5）

```yaml
# pkg/binancecfg —— MVP 阶段仅需白名单字段，动态 tiers 矩阵延后
stream_symbols: [BTCUSDT, ETHUSDT, BNBUSDT, SOLUSDT]  # 仅这俩进 WS，覆盖 ~90% 业务
# 完整 tiers[product_line][tier] 矩阵见 DETAILS §4，本任务仅预留加载入口
```

### 复合排序（消解 Priority 冲突，ADR-005 §2.1）

```go
// 任务出队键 = (SymbolPriority, TaskPriority)，先按 symbol 级，再按任务类型级
// SymbolPriority 来自 CatalogEntry（classifyTier 派生）；TaskPriority 来自 LifecycleTask.Priority
func taskSortKey(t LifecycleTask) (int, int) {
    return t.SymbolPriority, t.Priority
}
```

## Functional Requirements

**FR-017-001**（白名单 MVP，ADR-005 §5/§6.3）：WHEN `STREAM_SYMBOLS` 配置存在且非空 THEN streamConfig 仅订阅白名单内 symbol，classifyTier/per-tier 配置矩阵不生效（被白名单短路）；WHEN 配置为空 THEN 回退到完整 classifyTier + Collection 路由。

**FR-017-002**（classifyTier 三层降级，DETAILS §3）：第一层显式配置（priority=0）> 第二层 quoteVolume 阈值（priority=1/2/3）> 第三层 quoteAsset 兜底（quoteVolumeUSD==0 时，USDT/USDC→T2，其他→T3）。T0 必须由显式配置指定，禁止自动判定降级。

**FR-017-003**（Collection 路由，DETAILS §2）：Tier 映射到 6 种 Collection——T0=full_stream / T1=stream_no_depth / T2=kline_only / T3=rest_sample / T4=rest_daily / disabled。仅 `Collection ∈ {full_stream, stream_no_depth, kline_only}` 占用 WS 连接；rest_sample/rest_daily 走 REST cron。

**FR-017-004**（options 单列，ADR-005 §6.1，EXCHANGEINFO §8.1 勘误）：options **不进 Tier 模型**，由 options_classify 按 `(距到期天数, moneyness)` 分桶——near_atm(≤30d, 0.9~1.1)→full_stream / near_otm(≤30d, OTM)→rest_sample / far(>30d)→rest_daily / 深度虚值→disabled。前置依赖 CLIENT-015 已修 options TRADING 过滤。

**FR-017-005**（复合排序，ADR-005 §2.1）：lifecycle 任务出队按 `(SymbolPriority, TaskPriority)` 复合排序，与既有 `LifecycleTask.Priority`（gapfill=100/coldstart=50/reconcile=20）共存不冲突。

**FR-017-006**（SyncCatalog 复合谓词，ADR-005 §8.2）：SyncCatalog（lifecycle.go:161-174）从 `Status==active` 单谓词扩展为 `(Status==active && Collection!=disabled && tierEnabled(productLine, tier))` 复合谓词。

**FR-017-007**（REST budget 按 Collection 分配）：QueueColdStartBackfill / QueueDailyReconciliation（lifecycle.go:177-291）按 Collection 分配 REST budget——stream 系列不额外对账，rest_sample 每小时、rest_daily 每日。

## Acceptance Criteria

| AC | 验证方式 |
|----|---------|
| AC-017-001 白名单 MVP 生效 | 配置 `STREAM_SYMBOLS=[BTCUSDT,ETHUSDT]`，断言 streamConfig 输出的 activeStreams 仅含这两 symbol 的后缀流，spot 全量 catalog 其他 symbol 不进 WS |
| AC-017-002 spot 全量但 WS 仅 T0+T1+T2 子集 | 不配白名单时，spot catalog 含 ~2000 active symbol，但 streamConfig 仅订阅 T0+T1+T2 子集 ≈940 stream（2 连接），T3/T4 不占 WS |
| AC-017-003 options 不进 Tier 模型 | options symbol 经 options_classify 分桶而非 classifyTier；近月 ATM 期权走 full_stream，远月走 rest_daily；assert options 不调用 classifyTier |
| AC-017-004 classifyTier 三层降级 | 显式配置 symbol 命中第一层（priority=0）；quoteVolume≥阈值命中第二层；quoteVolume==0 + USDT 计价命中第三层 T2 |
| AC-017-005 复合排序 | 任务队列中 (SymbolPriority=0, TaskPriority=20) 排在 (SymbolPriority=2, TaskPriority=100) 之前 |
| AC-017-006 T0 不自动降级 | quoteVolumeUSD==0 时，非显式配置的 symbol 最多降到 T1，T0 必须由 configuredTier 显式返回 |
| AC-017-007 无 server/cs 依赖 | `go list -deps ./internal/client/...` 不含 internal/server、internal/cs |

## Dependencies

| 依赖 | 版本 | 用途 |
|------|------|------|
| TASK-BINANCE-CLIENT-015 | v1.0.0 | **前置**：CatalogEntry 4 字段 + decode quoteVolume + options TRADING 过滤（FR-017-002/004 数据地基） |
| TASK-BINANCE-CLIENT-016 | v1.0.0 | **前置**：interval SSOT（per-tier interval 配置引用权威源） |
| TASK-BINANCE-SERVER-018 | — | **并行**：binance_symbols 表加列（server 侧持久化，本任务不动） |
| ADR-005 / TIER-DESIGN-DETAILS | 2026-07-02 | 决策与细节权威 |

## Non-scope

- 不动 CatalogEntry 字段定义（CLIENT-015 scope_in）
- 不动 decode 结构体与 TRADING 过滤（CLIENT-015 scope_in）
- 不动 interval SSOT（CLIENT-016 scope_in）
- 不动 server schema 与 binance_symbols 表（SERVER-018）
- 不引入一致性哈希分片 / ClientRegistry / NATS heartbeat（CLIENT-018 可选，ADR-005 §6.2 已改为非依赖）
- 不做 retention 按 Tier 差异化 TTL（DETAILS §7 GAP-E14 联动，独立任务）
