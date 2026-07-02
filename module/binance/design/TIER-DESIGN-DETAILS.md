# Symbol 分级体系设计细节（TIER-DESIGN-DETAILS）

> 本文是 ADR-005-symbol-tier-classification.md 的可演进细节子文档。ADR-005 承载决策与边界（稳定），本文承载具体表格/配置/伪代码（可演进）。两者合称 binance symbol 分级体系设计。

---

## 0. 文档定位

| 维度 | ADR-005（决策文档） | TIER-DESIGN-DETAILS（本文） |
| --- | --- | --- |
| 内容性质 | 决策、边界、不可违背的原则 | 表格、配置 schema、伪代码、资源推算 |
| 变更频率 | 低 | 高（随 Binance 实测数据 / 业务增长演进） |
| 审批级别 | 架构裁决 | 实现评审 |
| 冲突时 | 以 ADR-005 为准 | 本文需修订 |

**引用链**：决策依据 `report/binance/EXCHANGEINFO-SYMBOL-TIER-ANALYSIS-20260702.md`（下称 EXCHANGEINFO 报告）；缺口链 `report/binance/DATA-INTEGRITY-E2E-20260701.md`（下称 DATA-INTEGRITY 报告）；上游决策 ADR-005。

---

## 1. Tier 五级分层表（修正版，对齐 Binance REST interval 全集）

引用 EXCHANGEINFO 报告 §3.1，T0~T4 × {含义, 默认 symbol 数（spot）, 采集策略（Collection）, interval, 频率, 产品线}：

| Tier | 含义 | 默认 symbol 数（spot） | 采集策略（Collection） | interval | 频率 | 产品线 |
| :--: | --- | :--: | --- | --- | --- | --- |
| **T0**（核心） | BTC/ETH/BNB/SOL 蓝筹 | ~10 | `full_stream`：trade+quote+depth+kline | WebSocket trade + REST `1m` | 实时 stream | spot + um_perp |
| **T1**（主流） | Top 流动性 | ~100 | `stream_no_depth`：trade+quote+kline | WebSocket `1m` + REST `5m` | 实时 stream | spot + um_perp |
| **T2**（次主流） | Top 500 | ~500 | `kline_only`：仅 kline stream | WebSocket `1m` | stream + 5min 重连 | spot + um_perp |
| **T3**（长尾） | TRADING 全集 | ~2000+ | `rest_sample`：REST 周期采样 | REST `1h` + `4h` | 每小时拉 | spot |
| **T4**（监控） | 其他产品线 | ~1000+ | `rest_daily`：日线 + funding | REST `1d` + `1w` | 每日拉 | cm_perp + options |

### 勘误标注：T4 行的语义错配

> ⚠️ **T4「监控」原把 options 整条线归入（EXCHANGEINFO §8.1 已勘误为语义错配）**。

**问题**（详见 EXCHANGEINFO §8.1）：

1. **末日/近月期权归 T4 daily 丢失全部日内 gamma** [INFERRED, HIGH]。临近到期的期权（0DTE、近月）是 gamma 交易最活跃的合约，日级 REST 采样等同于丢弃核心数据。Tier 按流动性分档，但期权"重要性"由 **距到期天数 + moneyness** 决定，而非 quoteVolume——Tier 维度对 options 语义错配。
2. **options 量级被严重低估** [INFERRED, MED]。单标的（BTC/ETH/...）可达上千张合约（~10-20 到期日 × ~20-50 strike × CALL/PUT），全量 options 实际数万张。把数万张走 `rest_daily` 仍是不可承受的 REST 负载，分级并未真正解决 options 问题。

**修正后 T4 行拆分**：

| 子项 | 归属 | 分级方式 | 备注 |
| --- | --- | --- | --- |
| cm_perp | T4 可保留 | 按 Tier 分（cm_perp 有 volume 信号） | 与 spot/um 同走 classifyTier |
| options | **不进 Tier 模型** | 单列 `options_classification` 维度（见 §6） | 按 (距到期天数, moneyness) 分桶 |

---

## 2. 采集策略路由矩阵（Collection × 触发路径）

引用 EXCHANGEINFO 报告 §3.2，6 个 Collection × {触发路径, 占用 WS?, 占用 REST budget?, 走 SyncCatalog?, 走 Reconcile?}：

| Collection | 触发路径 | 占用 WS 连接? | 占用 REST budget? | 走 SyncCatalog? | 走 Reconcile? |
| --- | --- | :--: | :--: | :--: | :--: |
| `full_stream` | SpotConnector 实时订阅 | ✅ | ❌（冷启动 backfill 例外） | ✅ | ✅ |
| `stream_no_depth` | SpotConnector（减 depth 后缀） | ✅ | ❌ | ✅ | ✅ |
| `kline_only` | SpotConnector（仅 kline 后缀） | ✅ | ❌ | ✅ | ✅ |
| `rest_sample` | backfill cron 周期触发 | ❌ | ✅ | ❌（不进实时 catalog 同步） | ✅（每小时） |
| `rest_daily` | backfill cron 每日触发 | ❌ | ✅ | ❌ | ✅（每日） |
| `disabled` | 不采集 | ❌ | ❌ | ❌ | ❌ |

**路由判定**：`stream_control.go:streamConfig`（L333-357）改为按 `Collection` 字段判定——仅 `Collection ∈ {full_stream, stream_no_depth, kline_only}` 的 symbol 才订阅 WS：

```go
func shouldSubscribeWS(entry CatalogEntry) bool {
    switch entry.Collection {
    case "full_stream", "stream_no_depth", "kline_only":
        return true
    default:
        return false
    }
}

var streamSuffixesByCollection = map[string][]string{
    "full_stream":     {"@trade", "@bookTicker", "@depth20", "@kline_1m"},
    "stream_no_depth": {"@trade", "@bookTicker", "@kline_1m"},
    "kline_only":      {"@kline_1m"},
}
```

### 与 SyncCatalog / Reconcile 的关系

| 生命周期阶段 | 参与 Collection | 行为 |
| --- | --- | --- |
| `SyncCatalog`（实时 catalog 同步） | full_stream / stream_no_depth / kline_only | symbol 进/出实时订阅集合，触发 WS 订阅 diff |
| `QueueColdStartBackfill`（冷启动回填） | 全部（含 rest_sample / rest_daily） | 按 Collection 分配 REST budget |
| `QueueDailyReconciliation`（每日对账） | 全部 | stream 系列不额外对账，REST 系列按小时/日 |

**关键约束**：`rest_sample` / `rest_daily` 的 symbol 不进 SyncCatalog 实时同步——它们的 catalog 状态变更（如 delisted）由独立的低频 reconcile 任务发现，避免长尾 symbol 频繁触发 catalog diff。

---

## 3. classifyTier 三层降级算法（伪代码）

```go
// classifyTier 根据 symbol 元数据判定 Tier 与同 Tier 内初始优先级。
// 返回 (tier, priorityWithinTier)：tier ∈ [0,4]，priority ∈ [0,3] 为 Tier 内初始值
// （非同 Tier 内最终排序，最终 SymbolPriority 由 §3.1 派生规则计算）。
func classifyTier(symbol, quoteAsset string, quoteVolumeUSD float64) (tier int, priorityWithinTier int) {
    // 第一层：显式配置（Level 决策）—— T0 列表人工维护，最高优先
    if t, ok := configuredTier(symbol); ok {
        return t, 0
    }
    // 第三层（前置短路）：计价资产兜底——quoteVolumeUSD==0 时流动性信号缺失，
    // 必须在第二层 switch 之前判定，否则第二层会走 default 返回 T3，丢失 quoteAsset 信息。
    if quoteVolumeUSD == 0 {
        switch quoteAsset {
        case "USDT", "USDC", "FDUSD", "BTC":
            return 2, 2 // 容错：主流计价资产至少 T2，避免误降 T3
        default:
            return 3, 3
        }
    }
    // 第二层：流动性信号（依赖 decode 保留 quoteVolume，quoteVolumeUSD > 0）
    switch {
    case quoteVolumeUSD >= t1VolumeThreshold: // [INFERRED] 阈值待校准，初始建议 50_000_000
        return 1, 1
    case quoteVolumeUSD >= 1_000_000:
        return 2, 2
    default:
        return 3, 3
    }
}
```

**三层优先级**：第一层（显式配置，priority=0，人工边界）> 第三层（计价资产兜底，**quoteVolumeUSD==0 时前置短路**）> 第二层（流动性信号，priority=1/2/3，数据驱动，仅 quoteVolumeUSD>0 时进入）。

| 层 | 触发条件 | 优先级 | 决策性质 |
| --- | --- | --- | --- |
| **第一层**：显式配置 | symbol 在配置文件的 `symbols` 列表中 | 最高（priority=0） | Level 决策（人工边界） |
| **第三层**：计价资产兜底 | `quoteVolumeUSD == 0`（流动性信号缺失，前置短路） | 低 | 容错决策（信号缺失兜底） |
| **第二层**：流动性信号 | `quoteVolumeUSD > 0` 且满足阈值 | 中（priority=1/2/3） | 自动决策（数据驱动） |

> **第三层为何前置**：`quoteVolumeUSD==0` 时第二层 switch 必走 `default` 返回 T3，会丢失"主流计价资产至少 T2"的容错语义。故第三层必须在第二层之前短路判定 quoteAsset。AC-017-004（quoteVolume==0 + USDT 命中第三层 T2）即验证此顺序。

### 3.1 同 Tier 内 SymbolPriority 派生规则

classifyTier 返回的 `priorityWithinTier`（0/1/2/3）只是 Tier 标记初值，**非同 Tier 内最终排序**——否则同 Tier 内所有 symbol priority 相同，调度退化为无序。refresher 全量重算后，按以下规则计算最终 `SymbolPriority`：

1. 按 Tier ASC 分组（T0 组 / T1 组 / ...）；
2. 同 Tier 内按 `quoteVolumeUSD DESC` 排序得 rank，**SymbolPriority = rank**（0 为 Tier 内最高流动性，优先调度）；
3. `quoteVolumeUSD` 相同（含第三层兜底组全为 0）按 `symbol ASC` 字母序兜底，确保稳定排序（同名 symbol 跨 refresher 周期 rank 不抖动）。

示例：T2 组 3 个 symbol，quoteVolumeUSD 分别 5M / 2M / 2M，symbol 为 `BBBUSDT` / `AAACUSDT` / `CCCUSDT`。按 quoteVolume DESC：BBBUSDT(5M) rank=0；AAACUSDT 与 CCCUSDT quoteVolume 相同（2M），按字母序 AAACUSDT < CCCUSDT，故 AAACUSDT rank=1、CCCUSDT rank=2。最终 SymbolPriority：BBBUSDT=0、AAACUSDT=1、CCCUSDT=2。

> **调用时机**：classifyTier 由 ExchangeInfoRefresher（CLIENT-015）每 N 分钟（建议 N=5 [GUESS, LOW]，待校准——依据：Binance ExchangeInfo 变更频率低，5min 足以捕捉 symbol 上线/退市；过短会放大 WS diff 风暴）全量重算一次，结果写 CatalogEntry 的 Tier/SymbolPriority/Collection 字段，触发 ADR-004 stream manager diff。降级施加 hysteresis（见 §8.1.1），升级即时生效。详见 CLIENT-017 FR-017-008。

### 3.2 边界场景规则

1. **status≠TRADING 强制 disabled**：classifyTier 第一层之前短路——若 `CatalogEntry.Status != "TRADING"`（BREAK/HALT/DELISTED/EXPIRED 等），直接返回 `(tier=4, collection="disabled")`，不进三层判定。覆盖退市/停牌 symbol 污染 WS 订阅（与 FR-033 delist lifecycle 协同）。
2. **新上线 symbol 宽限期**：catalog 中 symbol 的 `firstSeenAt` 距今 < N 天（N=7 [GUESS, LOW]，待校准）且 quoteVolumeUSD==0（无历史）时，给予 T2 宽限（`kline_only`），避免新 symbol 因无 volume 信号被立即降到 T3 长尾。宽限期过后 quoteVolumeUSD 仍为 0 则按第三层兜底降级。依赖：CatalogEntry 需记录 `firstSeenAt`（CLIENT-015 后续扩展，标记待落地）。
3. **跨产品线同标的 Tier 派生**：spot T0 symbol ⇒ 同 underlying 的 `um_perp` / `cm_perp` 至少 T1（不强制 T0，因衍生品流动性与 spot 不完全同步）。实现：classifyTier 全量重算后做一次 cross-product-line 提升 pass——`if spot_tier(symbol)==0 && perp_tier(symbol)>1 { perp_tier=1 }`。覆盖 `BTCUSDT`(spot T0) → `BTCUSDT`(um_perp) 不应被降到 T2+ 的场景。

**volume 阈值的 [INFERRED] 性质**：`t1VolumeThreshold` 不是硬编码常量，而是依赖 Binance 实测数据校准的运行时配置——初始建议 `50_000_000` USD（24h quoteVolume）起步 [GUESS, LOW]；校准方法是拉全量 symbol 的 quoteVolume 降序排列取第 100 名；初期保守配置（高阈值），灰度调整。产品线差异：spot / um_perp / cm_perp 各自维护独立阈值（cm_perp 流动性整体低于 spot，阈值应更低）。整体置信度 [INFERRED, MED]——方案合理，具体数值依赖实测数据校准。

**与"任务级 Priority"的消解**：现有 `LifecycleTask.Priority`（`lifecycle.go:16-19`，gapfill=100/coldstart=50/reconcile=20）是任务类型优先级。symbol 级统一用 `SymbolPriority`（命名裁决见 ADR-005 §2.1 / tier-gap-cross-reference.md L42，无备选名），任务级保留 `Priority`；任务最终出队键 = `(SymbolPriority, TaskPriority)` 复合排序。

---

## 4. per-tier 配置 schema（binancecfg 扩展）

引用 EXCHANGEINFO 报告 §4.4，四产品线完整 YAML：

```yaml
# pkg/binancecfg: per-tier 采集配置
# 环境变量前缀 FOUNDATIONX_BINANCE_TIERS_*
tiers:
  spot:
    t0:
      max_symbols: 10
      collection: full_stream
      symbols: [BTCUSDT, ETHUSDT, BNBUSDT, SOLUSDT]  # 显式指定（Level 边界）
    t1:
      max_symbols: 100
      collection: stream_no_depth
      filter: { quote_asset: [USDT], min_volume_usd: 50_000_000 }  # [INFERRED] 待校准
    t2:
      max_symbols: 500
      collection: kline_only
      filter: { quote_asset: [USDT, USDC], min_volume_usd: 1_000_000 }
    t3:
      max_symbols: 0  # 0 = 不限（全量 TRADING 长尾）
      collection: rest_sample
      filter: { status: [TRADING] }
    t4:
      max_symbols: 0
      collection: disabled  # spot 不使用 T4

  um_perp:
    t0: { max_symbols: 10, collection: full_stream, symbols: [BTCUSDT, ETHUSDT] }
    t1: { max_symbols: 100, collection: stream_no_depth, filter: { quote_asset: [USDT], min_volume_usd: 30_000_000 } }
    t2: { max_symbols: 200, collection: kline_only, filter: { min_volume_usd: 500_000 } }
    t3: { max_symbols: 0, collection: rest_sample }
    t4: { max_symbols: 0, collection: disabled }

  cm_perp:
    # cm_perp 有 volume 信号，可按 Tier 分（与 spot/um 同结构）
    t0: { max_symbols: 5, collection: full_stream, symbols: [BTCUSD_PERP, ETHUSD_PERP] }
    t1: { max_symbols: 30, collection: stream_no_depth, filter: { min_volume_usd: 10_000_000 } }
    t2: { max_symbols: 50, collection: kline_only, filter: { min_volume_usd: 100_000 } }
    t3: { max_symbols: 0, collection: rest_sample }
    t4: { max_symbols: 0, collection: rest_daily }  # cm_perp 长尾（delivery 合约）

  options:
    # options 不进 Tier 模型，按 options_classification 分桶（见 §6）
    classification: options_classification
    buckets:
      near_atm:  { collection: full_stream }    # 近月 + 近价（ATM）→ 实时 stream
      near_otm:  { collection: rest_sample }    # 近月 + 虚值 → REST 采样
      far:       { collection: rest_daily }     # 远月 → 日线
      disabled:  { collection: disabled }       # 深度虚值 / 流动性极差 → 不采
```

**字段语义**：`max_symbols`（int，0=不限，必填）；`collection`（枚举，必填）；`symbols`（显式列表，走 classifyTier 第一层，与 filter 互斥）；`filter.quote_asset` / `filter.min_volume_usd` / `filter.status`（自动筛选条件）。`symbols` 与 `filter` 同时指定时配置加载 fail-fast。

**配置加载优先级**：环境变量 `FOUNDATIONX_BINANCE_TIERS_SPOT_T0_SYMBOLS` > 配置文件 `tiers.spot.t0.symbols` > 内置默认值（`DefaultSpotCatalog`，`catalog.go:64-87`）。

**STREAM_SYMBOLS 白名单 env var 全名**：`FOUNDATIONX_BINANCE_STREAM_SYMBOLS`（逗号分隔，如 `FOUNDATIONX_BINANCE_STREAM_SYMBOLS=BTCUSDT,ETHUSDT`）。配置文件键为 `stream_symbols`；env var 优先级高于配置文件（与上述 tiers 配置同优先级链）。白名单存在时短路 classifyTier/per-tier 矩阵（ADR-005 §5 白名单 MVP），非空时仅采集列表内 symbol。

---

## 5. 资源推算（分级核心收益）

引用 EXCHANGEINFO 报告 §3.2 / §7 论断 3。

### 5.1 WebSocket 占用对比

| 场景 | 订阅 stream 数 | WS 连接数 | 相对 `defaultMaxWSConns=10` | 可行性 |
| --- | --- | --- | --- | --- |
| **全量不分级** | spot ~2000 × 4 流后缀 = ~8000 | 8 | 80% | ❌ 物理接近不可行 |
| **分级后** | T0+T1(110)×4 + T2(500)×1 = ~940 | 2 | 20% | ✅ 轻松承载 |

**结论**：分级把 WS 占用从「物理不可行」（8 连接逼近上限）降到「轻松承载」（2 连接，20% 容量）——这是分级的核心收益 [INFERRED, MED]。

**物理约束依据**：单 WS 连接最多 1024 stream（Binance 物理限制）[COMMON]；`defaultMaxWSConns = 10`（`stream_control.go:13`）[COMPUTED]；全量 spot ~2000 symbol 需 8 连接，逼近上限。

### 5.2 REST 冷启动推算

| 项 | 全量不分级 | 分级后 | 备注 |
| --- | --- | --- | --- |
| T3 长尾 REST 冷启动 | ~103K 请求 | ~60K 请求 | 8h 完成（throttle=120/min） |
| T4 daily | 数万（options 压入） | cm_perp 长尾 + options 远月 | options 近月/ATM 走 stream |
| 总冷启动时长 | ~14h | ~8h | 分级后单副本可承受 |

---

## 6. options_classification 分桶规则

EXCHANGEINFO §8.1 勘误核心论断：**Tier 模型按流动性分档，但期权"重要性"由距到期天数 + moneyness 决定**。强行把 options 塞进 T0-T4 会导致末日/近月期权（高 gamma）被日级 REST 采样丢失全部日内信息，同时远月/深虚值期权占用过多资源。

### 6.1 分桶规则：(距到期天数, moneyness)

options 按 `(距到期天数, moneyness)` 二维分桶，每个桶对应一个 Collection：

| 桶 | 距到期天数 | moneyness（strike/标的现价） | Collection | 类比 Tier |
| --- | --- | --- | --- | --- |
| `near_atm` | ≤ 30 天（近月） | 0.9 ~ 1.1（近价 ATM） | `full_stream` | T0/T1 |
| `near_otm` | ≤ 30 天（近月） | < 0.9 或 > 1.1（虚值 OTM） | `rest_sample` | T3 |
| `far` | > 30 天（远月） | 任意 | `rest_daily` | T4 |
| `disabled` | 任意 | 深度虚值（< 0.5 或 > 2.0） | `disabled` | 不采 |

**moneyness 计算**：`moneyness = strike_price / underlying_spot_price`。`underlying_spot_price` 从 spot 产品线 T0 实时流获取；`strike_price` 已存于 `CatalogEntry.Strike`（`catalog.go:38`）。

### 6.2 前置：options decode 加 status 字段

**根因前置** [COMPUTED, HIGH]：`exchangeinfo_option.go:30-36` 的 `optionsExchangeSymbol` 结构体无 status 字段，`DecodeOptionsExchangeInfo`（L74-84）仅按 `expiryDate > now` 判 active，**不做 TRADING 过滤**（spot/um/cm 都做了）。所有未过期合约——含大量流动性极差、远月、深度虚值的"垃圾合约"——全部以 `status="active"` 灌入 catalog。

```go
// exchangeinfo_option.go:30-36 扩展
type optionsExchangeSymbol struct {
    Symbol      string  `json:"symbol"`
    Underlying  string  `json:"underlying"`
    Side        string  `json:"side"`
    StrikePrice float64 `json:"strikePrice"`
    ExpiryDate  int64   `json:"expiryDate"`
    Status      string  `json:"status"`    // 新增：TRADING / EXPIRED 等
    OpenTime    int64   `json:"openTime"`  // 新增：可推断活跃度
}
// DecodeOptionsExchangeInfo L74-84：if status == "TRADING" && expiryDate > now → active
```

**风险**：不修此过滤，T4 / `rest_daily` / `far` 桶会被数万张无效合约塞满，分级形同虚设。**options 量级数万** [INFERRED, MED]——必须先修 TRADING 过滤再启用分桶；分桶前 options 默认 `disabled`。

---

## 7. 与既有缺口的连锁影响

引用 EXCHANGEINFO 报告 §6 表格：

| 缺口 | 分级引入后的影响 | 联动点 |
| --- | --- | --- |
| **GAP-E5'** 资源治理 | T0+T1 实时流 ~110 symbol × 4 后缀 = 440 stream，需 ResourceGovernor 限制并发 | WS 连接数 / 订阅并发上限 |
| **GAP-E4** throttle | T2/T3 共享 repair budget；T0+T1 不占 budget（stream 不算 REST） | REST budget 分配 |
| **GAP-E14** retention | 按 Tier 差异化 TTL：T0 365d / T1 180d / T2 90d / T3 7d / T4 30d | 存储层 TTL 配置 |
| **GAP-E6** 全量化 | catalog 仍需全量（含所有 TRADING），但**采集层**按 Tier 过滤 | catalog 全量 + 采集层分级 |
| **GAP-E25** 分片 | 多副本时分级配置 × 分片：每副本只采自己分片内、自己 Tier 的 symbol | 一致性哈希 × Tier 过滤（见 §9） |

**GAP-E6 与 GAP-E24 的边界**：GAP-E6 修复后 catalog 仍包含**所有 TRADING symbol**（全量），GAP-E24 在**采集层**按 Tier 过滤——catalog 知道 T3 长尾 symbol 存在，但 WS / REST 采集层只采其 Tier 对应数据。symbol 流动性增长（T3→T2）时 catalog 无需变更，只需 classifyTier 重新判定并更新 `Tier` / `Collection` 字段。

### GAP-E14 retention 按 Tier 差异化 TTL

| Tier | TTL | 理由 |
| --- | --- | --- |
| T0 | 365 天 | 核心蓝筹，长期回测/审计 |
| T1 | 180 天 | 主流，中期回测 |
| T2 | 90 天 | 次主流，短期回测 |
| T3 | 7 天 | 长尾，仅近期可查询 |
| T4 | 30 天 | 监控级，中期保留 |
| options（near_atm） | 90 天 | 高价值期权数据 |
| options（far/disabled） | 不存 / 7 天 | 低价值 |

---

## 8. 风险与缓解

| 风险 | 置信度 | 缓解 |
| --- | --- | --- |
| **T0 误降级**：quoteVolume 临时为 0 / decode 失败，核心 symbol 降为 REST 采样 → 实时策略失效 | [INFERRED, HIGH] | 详见 §8.1（hysteresis N=3 降级迟滞 + admin override API + `tier_symbol_count{tier="0"}<4` 告警）；T0 由第一层显式配置决定，classifyTier 第二/三层无权降级 T0（§8.1.1 T0 豁免） |
| **volume 阈值偏离实际**：`t1VolumeThreshold` 初始值偏离，T1/T2 symbol 数量失衡 | [INFERRED, MED] | 初期保守配置（高阈值 → T1 偏少），灰度调整；用真实 exchangeInfo 响应校准（§3） |
| **options 量级数万**：不先修 TRADING 过滤，T4 / `rest_daily` / `far` 桶塞满无效合约 | [COMPUTED, HIGH] | **必须先修 §6.2 的 TRADING 过滤**（exchangeinfo_option.go:30-36 加 status），再启用 options_classification；分桶前 options 默认 `disabled` |
| **配置爆炸**：四产品线 × 五 Tier YAML 复杂，运维易配错 | [INFERRED, MED] | 配置加载 fail-fast（schema 校验）；`symbols` 与 `filter` 互斥校验；提供 `binancectl tier validate` 预检 |

### 8.1 T0 误降级缓解机制（hysteresis + admin override + 告警）

§8 风险表"T0 误降级"行的具体机制展开。三段所有阈值均为初始建议值，标 `[GUESS]`/`[INFERRED]` + 待校准，禁止冒充实测。

#### 8.1.1 hysteresis 降级稳定窗口 [GUESS, LOW]

为防 `quoteVolume` 单次抖动（decode 失败、Binance 短暂返回 0、API 限流）导致 symbol 被误降级，classifyTier 对**降级**（高 Tier → 低 Tier）施加迟滞，**升级**（低 Tier → 高 Tier）即时生效：

- **降级需连续 N 次 refresher 都判定为更低 Tier 才生效**，N=3 [GUESS, LOW]，待校准。
  - 实现形态：classifyTier 维护 per-symbol 的 `pendingDowngrade{targetTier, consecutiveHits}` 计数器；连续命中目标 Tier 计数 +1，中断（中间出现高 Tier）归零；计数达 N 后写 catalog 触发 ADR-004 stream manager diff。
  - 按 §3 调用时机（N=5min refresher 周期），稳定窗口 ≈ 15min。
- **升级即时生效**：流动性增长（T3→T2）不应被迟滞，避免错失升 Tier 的采集覆盖。
- 备选形态（与计数器二选一，待运行时评估）：7 天滑动均值 `quoteVolumeUSD` 低于阈值才降级 [GUESS, LOW]。
- **T0 豁免**：T0 由第一层显式配置（`configuredTier`）决定，**完全不参与 hysteresis**——T0 降级只能由 admin override（§8.1.2）或配置变更触发，classifyTier 第二/三层无权降级 T0（对应 AC-017-006）。

#### 8.1.2 admin override API [INFERRED, MED]

人工强制锁定 symbol 的 Tier，优先级高于 classifyTier 三层与 hysteresis。

- **路径**：`POST /admin/v1/symbols/{symbol}/tier-override`（复用 gin-admin，CLIENT-010/server-006 既有 admin 路由族）
- **请求体**：`{"tier": <0-4>, "reason": "<free text>", "ttl_seconds": <optional>}`
- **行为**：写入 `binance_symbols.tier_override`（运行时字段，非本 PR schema 范围；SERVER-018 已预留 `shard_id` 列，override 列待后续 migration 扩展），优先级高于 classifyTier 三层；`ttl_seconds` 过期后回归 classifyTier 自动判定（不传则永久）。
- **持久化**：override 记录进 audit log（复用 FR-015 AuditLog）。
- 标记 [INFERRED]：API 路径与字段为推断设计，待 CLIENT-017 实现阶段确认与 gin-admin 既有路由风格一致。

#### 8.1.3 metrics 告警阈值 [GUESS, LOW]

- **指标**：`binance_tier_symbol_count{product_line, tier}`（CLIENT-017 metrics 暴露）
- **告警规则（AlertManager）**：
  - `binance_tier_symbol_count{tier="0"} < 4` → CRITICAL（T0 核心蓝筹不应少于 4，对应 §4 spot T0 默认 `BTCUSDT/ETHUSDT/BNBUSDT/SOLUSDT`）
  - `binance_tier_symbol_count{tier="0"} == 0` → P0 页面（分级体系完全失效，所有 symbol 误降级）
- 阈值 `4` 为 [GUESS]：基于 §4 spot T0 四个默认值；待校准依据：上线 2 周后观察实际 T0 symbol 数稳定值。

---

## 9. 缺口依赖链（修正版，含 §8.2 勘误）

引用 EXCHANGEINFO 报告 §8.2 勘误，依赖链从"E25 是 E24 下游依赖"修正为"E25 是可选扩容"：

```
GAP-E6（全量化：4 线 refresher 装配）
   ↓
GAP-E26（interval SSOT：interval 列表标准化）
   ↓
GAP-E24（分级采集：Tier/Priority/Collection）  ← 用户指令的核心
   ↓
[评估单副本负载]
   ↓ 大概率够（940 stream，2 连接）
   完成
   ↓ 极少数情况不够（业务增长、T0+T1 ≥ 500）
   GAP-E25（可选扩容：一致性哈希分片，非依赖）
```

### E24 与 E25 是互斥扩容路径

**逻辑依据**（EXCHANGEINFO §8.2）：报告 §3.2 已论证分级后单副本 WS 占用 = T0+T1(110)×4 + T2(500)×1 = **940 stream（2 连接）**，REST 冷启动 T3 ~60K（8h）。即**分级后单副本完全扛得住**。"无分片时 3 副本都跑全量"的前提**在分级落地后不成立**——单副本只采 T0+T1+T2 子集（≤940 stream），不存在 3 倍浪费。**GAP-E25 的前提消失，它不是 E24 下游依赖，而是分级后单副本仍不够时的可选扩容手段** [INFERRED, HIGH]。

| 场景 | 单副本 WS | 单副本 REST 冷启动 | 是否需要 GAP-E25 |
| --- | --- | --- | --- |
| 全量、不分级（现状） | 8000 stream（8 连接，逼近上限） | 103K（14h） | 需要 |
| **分级后（E24 落地）** | **940 stream（2 连接）** | **~60K（8h）** | **不需要** |
| 分级 + 业务增长到 T0+T1=500 | ~2000 stream（2 连接） | 更高 | 视负载评估 |

**渐进路径建议**（EXCHANGEINFO §8.3 补充，遵循 Simplicity First）：先做静态白名单 MVP（0.5d，~20 行，`stream_control.go` 加 `STREAM_SYMBOLS` 白名单，覆盖 ~90% 业务需求）→ 评估是否需要完整分级（GAP-E24，2.5d，覆盖 100%）→ 评估是否需要分片（GAP-E25，4d，水平扩展）。

### 实施步骤

| 步骤 | 缺口 | 工时估算 | 必做? |
| --- | --- | --- | --- |
| 1 | GAP-E6（全量化） | ~0.5d（80 行） | ✅ 必做 |
| 2 | GAP-E26（interval SSOT） | ~1.5d（150 行） | ✅ 必做 |
| 3 | GAP-E24（分级采集） | ~2.5d（300 行） | ✅ 必做 |
| 4 | 评估单副本负载 | 观察期 1-2 周 | ✅ 必做 |
| 5 | GAP-E25（分片） | ~4d（500 行） | ❌ 可选（仅当步骤 4 评估不够时） |

---

## 10. 源码索引（核验日期 2026-07-02）

| 文件 | 关键内容 | 行号 |
| --- | --- | --- |
| `internal/client/exchangeinfo.go` | spot/um/cm decode + fetch（TRADING 过滤；丢弃 quoteVolume） | 19-24, 40, 95-102, 118-120, 174-183, 199-202 |
| `internal/client/exchangeinfo_option.go` | options decode + fetch（无 status，仅 expiry 过滤） | 30-36, 74-84 |
| `internal/client/catalog.go` | CatalogEntry（12 字段，零分级）+ DiffSync + DefaultMarketCatalog | 16-43, 64-87, 236 |
| `internal/client/lifecycle.go` | SyncCatalog / Queue\*（全量 active）+ 任务级 Priority | 16-19, 161-174, 177-215, 259-291 |
| `internal/client/stream_control.go` | streamConfig 全量笛卡尔积订阅 + `defaultMaxWSConns=10` | 13, 333-357 |
| `pkg/binancecfg/config.go` | binanceFields（无 symbol/tier 范围项） | 249-269 |

---

## 附录：版本与变更日志

| 版本 | 日期 | 变更 |
| --- | --- | --- |
| v0.1 | 2026-07-02 | 初始草案。承载 ADR-005 的可演进细节：Tier 五级表、Collection 路由矩阵、classifyTier 算法、per-tier YAML、资源推算、options 分桶、缺口依赖链修正 |

[RULES I BROKE]：无。所有源码引用与表格数据均来自 EXCHANGEINFO 报告（2026-07-02）与 DATA-INTEGRITY 报告（v3.9），行号经现场核验。volume 阈值、options 量级、资源推算标为 [INFERRED] 并附置信度；Binance 物理约束（单连接 1024 stream）标为 [COMMON]。
