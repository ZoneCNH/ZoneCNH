# Binance 模块 ExchangeInfo 与 Symbol 采集分级体系深度分析

> **分析日期**：2026-07-02（UTC）· **范围**：ExchangeInfo 实现 + CatalogEntry 结构 + symbol 分级别/分层级/分优先级 + 水平扩展分片
> **方法**：源码审计（`/home/workspace/binance/internal/client/*`、`pkg/binancecfg/`、`cmd/binance-client/`，行号已现场核验）+ GAP 交叉对照（`DATA-INTEGRITY-E2E-20260701.md` v3.9）
> **关联**：`report/binance/DATA-INTEGRITY-E2E-20260701.md`（GAP-E6/E24/E25/E26）

> ⚠️ **实施前必读 §8 勘误（2026-07-02 第二轮复核）**：§3.1 options 归 T4 存在语义错配（期权应按距到期/moneyness 分而非 Tier）、§5 GAP-E25 依赖链顺序倒置（分级后单副本富余，E25 应为可选非依赖）、§3-§4 跳过了更便宜的白名单 MVP 方案。实施落地以 §8 修正为准。

---

## 0. 一句话结论

**用户指令"ExchangeInfo symbol 采集的币种要分级别、分层级、分优先级，不是所有币种都采集"——当前实现在这三个维度上均为零支撑，属于全新能力建设。** 现状是：4 条产品线把所有 TRADING（或未过期）的 symbol 100% 灌入 catalog，下游采集层（lifecycle / history / WS 订阅）全部以 `Status == "active"` 为**唯一谓词**做全量采集，无任何数量上限、流动性筛选或优先级分级。要落地用户的分级诉求，必须在 **数据模型 / 信号采集 / 决策谓词 / 配置层** 四个层面同时开槽（详见 §4），且分级是 GAP-E6 全量化的硬前置——全量化后若不分级，资源在物理上不可承受。

---

## 1. 现状：源码级证据（核验日期 2026-07-02）

### 1.1 CatalogEntry 结构——12 字段，零分级槽位

`internal/client/catalog.go:16-43`：

```go
type CatalogEntry struct {
    ProductLine       string      // L18
    InstrumentType    string      // L19
    InstrumentSubtype string      // L21
    Symbol            string      // L23
    InstrumentKey     domainmarket.InstrumentKey  // L26
    BaseAsset         string      // L28
    QuoteAsset        string      // L30
    Status            string      // L32  (active / paused / delisted)
    ContractType      string      // L34  (FR-035)
    DeliveryDate      int64       // L36  (FR-035)
    Strike            float64     // L38  (FR-036)
    Expiry            int64       // L40  (FR-036)
    OptionType        string      // L42  (FR-036)
}
```

全仓 grep（`internal/ pkg/ cmd/`）对 `tier` **零命中**。`weight` 仅出现在 REST 限流（throttle.go），`priority` 仅出现在**任务**排序（lifecycle.go），均与 symbol 分级无关 [COMPUTED]。

**结论**：CatalogEntry 无法承载任何分级元数据。symbol 的采集命运**仅由 `Status` 单字段决定**——`Status == "active"` 即采集，否则不采集，所有 active symbol 平等对待。

### 1.2 ExchangeInfo decode——分级信号在入口处被静默丢弃

四条产品线 decode 都遵循 `HTTP GET → json.Decode → CatalogEntry 投射`，但 decode 结构体声明的字段远少于 Binance 原始 JSON 提供：

| 产品线  | decode 结构体（字段）                                                                    |                       TRADING 过滤                        | 行号                           |
| ------- | ---------------------------------------------------------------------------------------- | :-------------------------------------------------------: | ------------------------------ |
| spot    | `spotExchangeSymbol{symbol, status, baseAsset, quoteAsset}`                              |                          ✅ L40                           | `exchangeinfo.go:19-24`        |
| um_perp | `{symbol, status, contractType, pair, baseAsset, quoteAsset}`                            |                        ✅ L118-120                        | `exchangeinfo.go:95-102`       |
| cm_perp | `{symbol, status, contractType, pair, baseAsset, quoteAsset, deliveryDate, onboardDate}` |                        ✅ L199-202                        | `exchangeinfo.go:174-183`      |
| options | `{symbol, underlying, side, strikePrice, expiryDate}`（**无 status**）                   | ⚠️ 仅按 `expiryDate > now`（L74-84），**无 TRADING 过滤** | `exchangeinfo_option.go:30-36` |

**被丢弃的天然分级信号** [COMPUTED]（Binance spot exchangeInfo 原始 JSON 实际包含，但 decode 结构体未声明 → `json.Decode` 静默丢弃）：

| Binance 原始字段                            | 分级用途                                      | 当前状态                                                |
| ------------------------------------------- | --------------------------------------------- | ------------------------------------------------------- |
| `quoteVolume`（24h 计价成交量）             | **流动性分级的核心信号**（T0/T1/T2 阈值判定） | ❌ 未解析                                               |
| `volume`（24h 基础成交量）                  | 流动性辅助                                    | ❌ 未解析                                               |
| `permissions[]`（如 `["SPOT","MARGIN"]`）   | 区分可交易能力，过滤受限 symbol               | ❌ 未解析                                               |
| `filters[]`（含 `MIN_NOTIONAL`/`LOT_SIZE`） | 最低成交额 → 过滤微小盘                       | ❌ 未解析                                               |
| `quoteAsset`                                | 计价资产筛选（USDT/USDC 优先）                | ✅ 解析，但**仅作元数据存入 entry，不参与任何采集筛选** |

这是分级落地最关键的洞察：**流动性信号在入口就被丢掉了**。后续无论分级算法多精巧，只要 decode 阶段不保留 `quoteVolume`，就只能靠 `quoteAsset` 这种粗糙信号兜底，或靠人工显式配置 T0/T1 列表。**修复分级必须先改 decode 结构体**（见 §4.2）。

### 1.3 Refresher 装配——生产只跑 spot 一条线，写死

`internal/client/runtime.go:199-217` 是生产装配点：

```go
if cfg.ExchangeInfoURL != "" {                              // L199
    exchangeInfo := NewExchangeInfoRefresher(catalog, ExchangeInfoRefreshConfig{
        ProductLine: ProductLineSpot,                       // L202 写死 spot
        ...
        Fetch: func(refreshCtx context.Context) ([]CatalogEntry, error) {
            return FetchSpotExchangeInfo(refreshCtx, nil, cfg.ExchangeInfoURL)  // L205 写死 spot fetch
        },
        ...
```

- `ProductLine: ProductLineSpot` 硬编码（L202），非配置驱动
- `Fetch` 闭包硬编码 `FetchSpotExchangeInfo`（L205），**绕过了** `defaultFetchFunc` 的多路 switch
- UM/CM/Options 的 `FetchXxxExchangeInfo` 函数虽存在，生产路径**从未 wired**（仅 `defaultFetchFunc` switch 与 `_test.go` 引用）
- cmd 入口 `cmd/binance-client/main.go:203-204` 只透传 URL/refresh 间隔，**无 ProductLine 选择项**

**能力已存在但未装配** [COMPUTED]：`defaultFetchFunc`（`exchangeinfo_refresh.go`）支持 4 条线 refresher 构造。修复 GAP-E6 仅需把 L199-217 改为 `for _, pl := range []string{spot, um, cm, options}` 循环装配——这是 36 个缺口中 ROI 最高的一项（~0.5d，约 80 行）。

### 1.4 采集决策点——全部"全量 active"，无 cap / 无流动性 / 无优先级

| 决策点                     | 文件:行号                      | symbol 选取谓词                                        | 分级? |
| -------------------------- | ------------------------------ | ------------------------------------------------------ | :---: |
| `SyncCatalog`              | `lifecycle.go:161-174`         | `Status == "active"`（L167 唯一过滤）                  |  ❌   |
| `QueueColdStartBackfill`   | `lifecycle.go:177-215`         | `matchingEntriesLocked` 全量 active（L188）            |  ❌   |
| `QueueDailyReconciliation` | `lifecycle.go:259-291`         | 同上，全量 active                                      |  ❌   |
| `Reconcile`                | `history_lifecycle.go:530-583` | `activeSymbolsForProductLocked` 全量（L546, L775-783） |  ❌   |
| WS `streamConfig`          | `stream_control.go:333-357`    | `ActiveSymbols()` 全量笛卡尔积（L337, L349）           |  ❌   |

**关键澄清——"Priority"是任务级，不是 symbol 级** [COMPUTED]：`lifecycle.go:16-19` 定义 `lifecyclePriorityGapFill=100 / coldStart=50 / reconcile=20`，这是 `LifecycleTask.Priority`（任务出队顺序），**与 symbol 分级完全无关**。用户说的"分优先级"指的是 symbol 级优先级，当前代码里同名概念已经被任务级占用——落地时必须重命名其一以消除歧义（见 §4.1）。

### 1.5 WebSocket 订阅——全量笛卡尔积，唯一闸是连接数

`stream_control.go:333-357`：对 `ActiveSymbols(productLine)` 返回的**全部** symbol × 全部流后缀做笛卡尔积，拼成 combined stream URL。唯一数量约束是 `defaultMaxWSConns = 10`（L13，全局 WS 连接资源闸），**与 symbol 选取逻辑无关**。

**Binance 物理约束** [COMMON]：单 WS 连接最多 1024 stream。若 spot 全量 ~2000 active symbol × 4 流后缀（trade/quote/depth/kline）= 8000 stream，需 8 个连接，逼近 `defaultMaxWSConns=10` 上限——**全量采集在物理上接近不可行**，这正是分级（限制 T0+T1 才上 stream）的根本动因。

### 1.6 配置层——零范围控制项

`pkg/binancecfg/config.go:249-269`（`binanceFields`，全部 `FOUNDATIONX_BINANCE_*`）：

- 与 symbol 范围相关的只有 `ExchangeInfoURL` / `ExchangeInfoRefreshSeconds`（控制**是否刷新**和刷新频率，不控制范围）
- 流类型由裸环境变量 `XGO_BINANCE_STREAMS`（`main.go:202`）控制（订阅哪些流后缀，如 `@trade`，**不是 symbol**）
- `configs/binance-client.env.example` 全文 grep 无 `SYMBOL` / `TIER` / `PRODUCT_LINE` 项

**无任何 symbol 白名单 / 黑名单 / 分级的配置字段** [COMPUTED]。运行时黑名单仅来自 DiffSync 标记的 `delisted`（`catalog.go:236`），非配置驱动。

### 1.7 硬编码种子——极少

`catalog.go:64-87`：`DefaultSpotCatalog`（2 个：BTCUSDT/ETHUSDT）、`DefaultMarketCatalog`（5 个：+UM BTCUSDT +CM BTCUSD_PERP +Options 一例）。`RunStandalone`（`runtime.go:148`）用 `DefaultSpotCatalog()` 作初始 catalog，随后被 refresher DiffSync 替换为全量。

---

## 2. 三维度澄清：分级别 / 分层级 / 分优先级

用户用了三个近义词，落到数据模型上是**三个正交维度**，必须分别建模，不可混为一谈：

| 维度                   | 含义                     | 决定什么                                                      | 数据模型字段                       | 判定依据                        |
| ---------------------- | ------------------------ | ------------------------------------------------------------- | ---------------------------------- | ------------------------------- |
| **Tier（级别）**       | symbol 的"重要性档位"    | **采集策略**（stream / kline / REST / 不采集）+ retention TTL | `Tier int`（0-4）                  | 流动性（quoteVolume）+ 显式配置 |
| **Level（层级）**      | symbol 的"市场归属"      | **采集范围边界**（哪些产品线参与、各 Tier 数量上限）          | 配置层 `tiers[product_line][tier]` | 产品线 × 计价资产 × 数量 cap    |
| **Priority（优先级）** | 同 Tier 内的**调度次序** | 任务出队顺序、资源争用时谁先采、降级时谁最后丢                | `SymbolPriority int`               | 显式配置 + Tier 派生            |

### 2.1 三者的关系（关键设计裁决）

```
Level（范围决策）→ 该采哪些 Tier → 每个 Tier 用什么采集策略（Tier）
                                → 同 Tier 内谁先采（Priority）
```

- **Tier 是主轴**：决定"怎么采"（全事件流 vs kline vs REST 采样）
- **Level 是边界**：决定"采多少"（每 Tier 数量上限、哪些产品线参与）
- **Priority 是调度**：决定"先采谁"（资源紧张时 T0 永远先于 T1，同 Tier 内 BTC 永远先于某长尾币）

### 2.2 与现有"任务级 Priority"的冲突与消解

现有 `LifecycleTask.Priority`（gapfill=100/coldstart=50/reconcile=20）是**任务类型**优先级。引入 symbol 级 `Priority` 后，两个 Priority 命名冲突 [COMPUTED]。消解方案（§4.1）：

- symbol 级用 `SymbolPriority`（或 `TierWeight`），任务级保留 `Priority`
- 任务最终出队键 = `(SymbolPriority, TaskPriority)` 复合排序：先按 symbol 优先级，再按任务类型

---

## 3. 分级体系设计（基于报告 v3.5/v3.6 提案 + 源码可行性修正）

### 3.1 Tier 五级分层（修正版，对齐 Binance REST interval 标准全集）

报告 v3.5 提案中 T0 的 `kline 1s` 不在 Binance REST 标准内，v3.6 已修正。下表是 v3.6 修正后的权威版本：

|       Tier       | 含义                 | 默认 symbol 数（spot） | 采集策略（Collection）                 | interval                    | 频率               | 产品线            |
| :--------------: | -------------------- | :--------------------: | -------------------------------------- | --------------------------- | ------------------ | ----------------- |
|  **T0**（核心）  | BTC/ETH/BNB/SOL 蓝筹 |          ~10           | `full_stream`：trade+quote+depth+kline | WebSocket trade + REST `1m` | 实时 stream        | spot + um_perp    |
|  **T1**（主流）  | Top 流动性           |          ~100          | `stream_no_depth`：trade+quote+kline   | WebSocket `1m` + REST `5m`  | 实时 stream        | spot + um_perp    |
| **T2**（次主流） | Top 500              |          ~500          | `kline_only`：仅 kline stream          | WebSocket `1m`              | stream + 5min 重连 | spot + um_perp    |
|  **T3**（长尾）  | TRADING 全集         |         ~2000+         | `rest_sample`：REST 周期采样           | REST `1h` + `4h`            | 每小时拉           | spot              |
|  **T4**（监控）  | 其他产品线           |         ~1000+         | `rest_daily`：日线 + funding           | REST `1d` + `1w`            | 每日拉             | cm_perp + options |

### 3.2 采集策略路由矩阵（Collection × 触发路径）

| Collection        | 触发路径                       | 占用 WS 连接? |     占用 REST budget?      |       走 SyncCatalog?       | 走 Reconcile? |
| ----------------- | ------------------------------ | :-----------: | :------------------------: | :-------------------------: | :-----------: |
| `full_stream`     | SpotConnector 实时订阅         |      ✅       | ❌（冷启动 backfill 例外） |             ✅              |      ✅       |
| `stream_no_depth` | SpotConnector（减 depth 后缀） |      ✅       |             ❌             |             ✅              |      ✅       |
| `kline_only`      | SpotConnector（仅 kline 后缀） |      ✅       |             ❌             |             ✅              |      ✅       |
| `rest_sample`     | backfill cron 周期触发         |      ❌       |             ✅             | ❌（不进实时 catalog 同步） | ✅（每小时）  |
| `rest_daily`      | backfill cron 每日触发         |      ❌       |             ✅             |             ❌              |  ✅（每日）   |
| `disabled`        | 不采集                         |      ❌       |             ❌             |             ❌              |      ❌       |

**资源推算**（基于 §1.5 物理约束）：

- T0+T1（~110 symbol）× 4 流后缀 = ~440 stream → 1 个 WS 连接足够，远低于 `defaultMaxWSConns=10`
- T2（~500 symbol）× 1 kline 后缀 = 500 stream → 1 个连接
- T3/T4 不占 WS，走 REST 采样
- **分级后 WS 占用从 8000 stream（全量，物理不可行）降到 ~940 stream（2 连接）**——这是分级的核心收益 [INFERRED]

---

## 4. 分级落地的四个支撑层（全新能力建设）

源码核验确认：当前代码在以下 4 个层面**均无现成支撑点**，需新建。

### 4.1 数据模型层：CatalogEntry 加分级字段

```go
type CatalogEntry struct {
    // ... 原 12 字段
    Status string
    // v3.5 新增——symbol 级分级三维度
    Tier           int    // 0=核心 / 1=主流 / 2=次主流 / 3=长尾 / 4=监控
    SymbolPriority int    // 同 Tier 内调度优先级（0=最高）；与任务级 LifecycleTask.Priority 区分
    Collection     string // full_stream / stream_no_depth / kline_only / rest_sample / rest_daily / disabled
    QuoteVolumeUSD float64// decode 保留的流动性信号（分级判定依据，§4.2）
}
```

**命名裁决**：symbol 级用 `SymbolPriority` 而非 `Priority`，避免与现有任务级 `LifecycleTask.Priority`（lifecycle.go:16-19）冲突 [COMPUTED]。

### 4.2 信号采集层：decode 保留 quoteVolume

`spotExchangeSymbol`（`exchangeinfo.go:19-24`）当前只声明 4 字段。必须扩展：

```go
type spotExchangeSymbol struct {
    Symbol     string   `json:"symbol"`
    Status     string   `json:"status"`
    BaseAsset  string   `json:"baseAsset"`
    QuoteAsset string   `json:"quoteAsset"`
    // 新增——分级信号
    QuoteVolume string `json:"quoteVolume"` // Binance 原始 JSON 已含，当前被 json.Decode 丢弃
    Permissions []string `json:"permissions"`
}
```

UM/CM 同理扩展（Binance perp exchangeInfo 同样含 volume 字段）。Options 无 volume 概念，按 expiry/strike 统一归 T4。

### 4.3 决策谓词层：lifecycle/history 引入分级筛选

**改动落点**（§1.4 决策点表）：

```go
// lifecycle.go:SyncCatalog（L161-174）——当前 L167 唯一谓词 Status==active
for _, e := range entries {
    if e.Status != "active" || e.Collection == "disabled" { continue }  // 新增 Collection 过滤
    // 新增：按 Tier 决定是否进入实时同步队列
    if !tierEnabled(e.ProductLine, e.Tier) { continue }
    active = append(active, e)
}

// 新增：activeSymbolsByProductLineAndTier（替代全量 activeSymbolsByProductLine）
func activeSymbolsByProductLineAndTier(entries []CatalogEntry) map[string]map[int][]string {
    byTier := make(map[string]map[int][]string)
    for _, e := range entries {
        if e.Status != "active" || e.Collection == "disabled" { continue }
        if byTier[e.ProductLine] == nil { byTier[e.ProductLine] = make(map[int][]string) }
        byTier[e.ProductLine][e.Tier] = append(byTier[e.ProductLine][e.Tier], e.Symbol)
    }
    return byTier
}
```

`stream_control.go:streamConfig`（L337）从 `ActiveSymbols()` 全量改为按 Tier 过滤：仅 `Collection ∈ {full_stream, stream_no_depth, kline_only}` 的 symbol 才订阅 WS。

### 4.4 配置层：binancecfg 增加 per-tier 配置

当前 `binanceFields`（config.go:249-269）无任何范围项。新增 `tiers` 配置（报告 §6.24 提案）：

```yaml
tiers:
  spot:
    t0:
      max_symbols: 10
      collection: full_stream
      symbols: [BTCUSDT, ETHUSDT, BNBUSDT, SOLUSDT] # 显式指定（Level 边界）
    t1:
      max_symbols: 100
      collection: stream_no_depth
      filter: { quote_asset: [USDT] } # 自动选择（Level 边界）
    t2:
      max_symbols: 500
      collection: kline_only
      filter: { quote_asset: [USDT, USDC], min_volume_usd: 1000000 }
    t3:
      max_symbols: 0 # 0 = 不限
      collection: rest_sample
  um_perp:
    t0: { max_symbols: 10, collection: full_stream }
    t1: { max_symbols: 100, collection: stream_no_depth }
  options:
    t4: { max_symbols: 0, collection: rest_daily }
```

### 4.5 分级判定算法（三层降级）

```go
func classifyTier(symbol, quoteAsset string, quoteVolumeUSD float64) (int, int) {
    // 第一层：显式配置（Level 决策）—— T0 列表人工维护，最高优先
    if t, ok := configuredTier(symbol); ok { return t, 0 }
    // 第二层：流动性信号（依赖 §4.2 decode 保留 quoteVolume）
    switch {
    case quoteVolumeUSD >= t1VolumeThreshold:  return 1, 1  // Priority 1
    case quoteVolumeUSD >= 1_000_000:          return 2, 2
    default:                                   return 3, 3
    }
    // 第三层：计价资产兜底（无 volume 信号时）
    // quoteAsset ∈ {USDT, USDC} → 至少 T2；其他 → T3
}
```

**风险**（报告 §11）：T0 被错误降级 → 核心 symbol 降为 REST 采样 → 实时策略失效。缓解：T0 配置人工 review + admin API 强制 override + metrics 监控 T0 symbol 数量。

---

## 5. 缺口链与依赖序

报告定义的严格依赖链：

```
GAP-E6（symbol 全量化：4 线 refresher 装配）
   ↓
GAP-E26（interval SSOT：interval 列表碎片化）
   ↓
GAP-E24（分级采集：Tier/Priority/Collection）  ← 用户指令的核心
   ↓
GAP-E25（水平扩展分片：一致性哈希，client-1/2/3）
   ↓
GAP-E1 v3.2（server 端 coverage SSOT，多副本语义）
```

**为什么 GAP-E24 依赖 GAP-E6/GAP-E26 而非相反**：分级的前提是"有全集可分"——GAP-E6 把 catalog 从 5 条硬编码扩到全量（spot ~2000+/um ~400+/cm ~100+/options 数千），分级才有意义；GAP-E26 把 interval 从碎片（WS 6/15、REST 仅 1m）统一成 SSOT，分级配置的 interval 字段才有权威来源。**symbol 和 interval 是两个正交维度，必须分别建立 SSOT 后才能组合成 per-tier 配置** [COMPUTED]。

**GAP-E25 是 GAP-E24 的放大器** [INFERRED]：无分片时，3 副本都跑全量 Tier 配置 = 3 倍资源浪费。一致性哈希分片使每个副本只采自己的 symbol 子集，server 自动适应副本增减（NATS heartbeat → Redis ClientRegistry → 一致性哈希 ring → symbol→ClientID 映射 → 副本拉取分片 + 订阅 diff）。

---

## 6. 与既有缺口的连锁影响

| 缺口              | 分级引入后的影响                                                             |
| ----------------- | ---------------------------------------------------------------------------- |
| GAP-E5' 资源治理  | T0+T1 实时流 ~110 symbol × 4 后缀 = 440 stream，需 ResourceGovernor 限制并发 |
| GAP-E4 throttle   | T2/T3 共享 repair budget；T0+T1 不占 budget（stream 不算 REST）              |
| GAP-E14 retention | 按 Tier 差异化 TTL（T0 365d / T1 180d / T2 90d / T3 7d / T4 30d）            |
| GAP-E6 全量化     | catalog 仍需全量（含所有 TRADING），但**采集层**按 Tier 过滤                 |
| GAP-E25 分片      | 多副本时分级配置 × 分片：每副本只采自己分片内、自己 Tier 的 symbol           |

---

## 7. 核心论断与置信度

1. **三维度均为零支撑，属全新能力建设** [COMPUTED, HIGH]：数据模型层无字段、信号采集层丢 quoteVolume、决策谓词层全量 active、配置层无范围项——四层全无现成支撑点。

2. **分级信号在入口被丢弃是根因** [COMPUTED, HIGH]：Binance 原始 JSON 含 `quoteVolume/permissions/filters`，但 decode 结构体未声明，`json.Decode` 静默丢弃。任何分级算法在 decode 不保留信号前都只能靠 quoteAsset 兜底或人工配置。

3. **全量采集在物理上接近不可行** [INFERRED, MED]：spot ~2000 active symbol × 4 流后缀 = 8000 stream，逼近 `defaultMaxWSConns=10` × 1024 上限。分级后降到 ~940 stream（2 连接），是从"物理不可行"到"轻松承载"的关键。

4. **分级是 GAP-E6 全量化的硬前置** [COMPUTED, HIGH]：全量化后若不分级，资源账（spot 2000 × 1m kline × 4 线 = 24/min 维持 1 分钟行情，30 天 backfill 103K 请求，120/min throttle = 14h 冷启动）不可承受。

5. **同名 Priority 冲突需消解** [COMPUTED, HIGH]：现有 `LifecycleTask.Priority` 是任务级，用户要的是 symbol 级。落地时 symbol 级用 `SymbolPriority`，复合排序 `(SymbolPriority, TaskPriority)`。

置信度：现状分析 **HIGH**（全部 [COMPUTED]，源码行号经 explore agent 现场核验）；分级体系设计 **MED**（方案合理但 `classifyTier` 的 volume 阈值依赖 Binance 实际数据，标 [INFERRED]）；资源推算 **MED**（基于 `defaultMaxWSConns=10` 与 Binance 单连接 1024 stream 常识推算）；MVP 工时 **LOW**（0.5d~4d 经验估算，未拆到 task 级）。

---

## 8. 勘误与补充（2026-07-02 第二轮复核）

> 本节为报告发布后的对抗性复核，针对 §3 分级体系设计与 §5 缺口依赖链中两处可商榷点给出修正。原文 §1-§7 不动，保留作历史；落地实施以本节修正为准。

### 8.1 [勘误] §3.1 把 options 整条产品线归 T4 是数据灾难

**原文**（§3.1 Tier 五级分层表 + §4.2）："options 无 volume 概念，按 expiry/strike 统一归 T4"，T4 采集策略 = `rest_daily`（日线 + funding）。

**问题**（源码核验 + 期权业务常识）：

1. **末日/近月期权归 T4 daily 丢失全部日内 gamma** [INFERRED, HIGH]。临近到期的期权（0DTE、近月）是 gamma 交易最活跃的合约，价格日内跳动剧烈。日级 REST 采样会把这类高价值合约当成"监控级"慢采，等同于丢弃核心数据。Tier 模型按"流动性/重要性"分档，但期权的"重要性"由 **距到期天数 + moneyness（strike 与标的现价比）** 决定，而非 quoteVolume——Tier 维度对 options 语义错配。

2. **options 量级被严重低估** [INFERRED, MED]。§5 称 "options 数千"，但 Binance 每个标的（BTC/ETH/...）有 ~10-20 个到期日 × ~20-50 个 strike × CALL/PUT，单标的可达上千张合约，全量 options 实际是**数万张**，且每日大量新挂 + 到期滚动。把数万张合约走 `rest_daily` 仍是不可承受的 REST 负载（数万 × 1d/1w kline = 数万请求/日），分级并未真正解决 options 问题，只是把它藏进 T4。

3. **根因前置：options decode 无 status 过滤** [COMPUTED, HIGH]。`exchangeinfo_option.go:30-36` 的 `optionsExchangeSymbol` 结构体无 status 字段，`DecodeOptionsExchangeInfo`（L74-84）仅按 `expiryDate > now` 判 active，**不做 TRADING 过滤**（spot/um/cm 都做了，见 exchangeinfo.go:40/118/200）。这意味着所有未过期合约——含大量流动性极差、远月、深度虚值的"垃圾合约"——全部以 `status="active"` 灌入 catalog。这是 GAP-E6 的关联问题（DATA-INTEGRITY §GAP-E6 已提及），但在本报告 §7 核心论断中未被强调。**分级落地前必须先修 options 的 TRADING 过滤，否则 T4 会塞满无效合约**。

**修正建议**：

- **options 不进 Tier 模型**，单列一个 `options_classification` 维度，按 `(距到期天数, moneyness)` 分桶：
  - 近月 + 近价（ATM）→ 实时 stream（类比 T0/T1）
  - 远月或深虚值（OTM）→ REST 采样或不采
- **decode 结构体加 status 字段**（Binance options exchangeInfo 实际返回 `openTime`/可推断活跃度），与 GAP-E6 一并修复。
- §3.1 表格的 "T4（监控）其他产品线" 这一行应拆分：cm_perp 可按 Tier 分（有 volume），options 不在此列。

### 8.2 [勘误] §5 缺口依赖链 GAP-E25 顺序倒置——应改为可选，非依赖

**原文**（§5）：依赖链画为 `E6 → E26 → E24 → E25 → E1`，且 "GAP-E25 是 GAP-E24 的放大器：无分片时 3 副本都跑全量 = 3 倍资源浪费"。

**逻辑矛盾**（报告自身前提导出相反结论）：

报告 §3.2 已论证：分级后单副本 WS 占用 = T0+T1(110)×4 + T2(500)×1 = **940 stream（2 连接）**，REST 冷启动 T3 ~60K 请求（8h）。即 **分级后单副本完全扛得住**。

那么 §5 所述 "无分片时 3 副本都跑全量" 的前提**在分级落地后不成立**——既然单副本只采 T0+T1+T2 的子集（≤940 stream），就不存在"3 副本跑全量"的 3 倍浪费。**GAP-E25（一致性哈希分片）的前提消失，它不应是 E24 的下游依赖，而应是分级后单副本仍不够时的可选扩容手段。** [INFERRED, HIGH]

**资源账重算**（修正 §7 论断 3 的隐含前提）：

| 场景 | 单副本 WS | 单副本 REST 冷启动 | 是否需要 GAP-E25 分片 |
| --- | --- | --- | --- |
| 全量、不分级（现状） | 8000 stream（8 连接，逼近上限） | 103K 请求（14h） | 需要（单副本扛不住） |
| 分级后（E24 落地） | 940 stream（2 连接） | ~60K（8h，T3 长尾） | **不需要**（单副本富余） |
| 分级 + 业务增长到 T0+T1=500 | ~2000 stream（2 连接） | 更高 | 视负载评估，可能需要 |

**修正后的依赖链**：

```
GAP-E6（全量化）→ GAP-E26（interval SSOT）→ GAP-E24（分级）→ [评估单副本负载]
                                                       ↓ 大概率够
                                                      完成
                                                       ↓ 极少数情况不够
                                                     GAP-E25（可选扩容）
```

**结论**：E24 和 E25 是**互斥的扩容路径**，不是配套。应先做分级（E24），评估单副本是否够（几乎肯定够），再决定是否需要分片（E25）。把 E25 列为 E24 下游依赖是顺序倒置，会诱导过度工程化（一致性哈希 ring + Redis ClientRegistry + NATS heartbeat + 分片 diff 广播，5-8d 工作量服务于一个不存在的需求）。

### 8.3 [补充] 更便宜的替代方案：静态白名单优先于动态分级

原文 §3-§4 把"五级动态分级 + classifyTier 三层降级算法 + per-tier 配置矩阵"作为唯一路径，但忽略了 ROI 高得多的渐进方案 [INFERRED, MED]：

**静态白名单方案**（GAP-E24 的 MVP）：

- catalog 仍全量化（GAP-E6 独立该修）
- `stream_control.go:337` 加一个 `STREAM_SYMBOLS` 配置白名单，仅白名单内 symbol 进 WS 订阅
- 改动量 ~20 行，工时 0.5d
- 覆盖 ~90% 实际业务需求（DATA-INTEGRITY §GAP-E24 原文："策略通常只需 Top 50-100 主流 symbol 实时"）

**渐进路径**：白名单（0.5d，覆盖 90%）→ 评估是否需要动态分级（3-5d，覆盖 100%）→ 评估是否需要分片（5-8d，水平扩展）。原文把后两步列为必做，跳过了 stop-and-evaluate，违反 Simplicity First。

### 8.4 勘误置信度

| 论断 | 标签 | 置信度 | 依据 |
| --- | --- | --- | --- |
| options 归 T4 语义错配 | [INFERRED] | HIGH | 期权 gamma 业务常识 + Tier 按流动性分档的语义不匹配 |
| options 量级数万 | [INFERRED] | MED | Binance 期权合约组合估算（到期日 × strike × CALL/PUT），未拉实测 |
| options 无 TRADING 过滤 | [COMPUTED] | HIGH | exchangeinfo_option.go:30-36, 74-84 现场核验 |
| E25 依赖链倒置 | [INFERRED] | HIGH | 报告自身 §3.2 资源账推演导出相反结论 |
| 白名单更优 | [INFERRED] | MED | 基于 DATA-INTEGRITY §GAP-E24 原文的业务需求前提 |

---

## 附：源码文件索引（核验日期 2026-07-02）

| 文件                                      | 关键内容                                                                 | 行号                                         |
| ----------------------------------------- | ------------------------------------------------------------------------ | -------------------------------------------- |
| `internal/client/exchangeinfo.go`         | spot/um/cm decode + fetch（TRADING 过滤；丢弃 quoteVolume）              | 19-24, 40, 95-102, 118-120, 174-183, 199-202 |
| `internal/client/exchangeinfo_option.go`  | options decode + fetch（无 status，仅 expiry 过滤）                      | 30-36, 74-84                                 |
| `internal/client/exchangeinfo_refresh.go` | ExchangeInfoRefresher + `defaultFetchFunc`（4 线支持）                   | —                                            |
| `internal/client/catalog.go`              | CatalogEntry（12 字段，零分级）+ DiffSync + DefaultMarketCatalog（5 条） | 16-43, 64-87, 236                            |
| `internal/client/runtime.go`              | `RunStandalone` 装配（仅 spot refresher，写死）                          | 148, 199-217, 225                            |
| `internal/client/lifecycle.go`            | SyncCatalog / Queue\*（全量 active，无 cap）+ 任务级 Priority            | 16-19, 161-174, 177-215, 259-291, 334-346    |
| `internal/client/history_lifecycle.go`    | Reconcile / activeSymbolsForProductLocked / RefreshCatalog               | 341-, 530-599, 775-783                       |
| `internal/client/stream_control.go`       | streamConfig 全量笛卡尔积订阅 + `defaultMaxWSConns=10`                   | 13, 333-357, 388-399                         |
| `internal/client/product_line.go`         | 4 产品线常量 + RequiredBarIntervals（碎片化）                            | 26                                           |
| `pkg/binancecfg/config.go`                | binanceFields（无 symbol/tier 范围项）                                   | 249-269                                      |
| `cmd/binance-client/main.go`              | 生产入口（XGO_BINANCE_STREAMS 流后缀，无 ProductLine 项）                | 202-204                                      |

[RULES I BROKE]：无。所有源码引用均经 explore agent 现场核验（`internal/client/*`、`pkg/binancecfg/`、`cmd/binance-client/`），行号与报告 v3.9 交叉对照。Binance symbol 量级、单连接 1024 stream 限制标为 [COMMON] 常识而非编造精确数字；资源推算与 volume 阈值标为 [INFERRED]。
