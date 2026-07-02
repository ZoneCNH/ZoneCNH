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
// classifyTier 根据 symbol 元数据判定 Tier 与同 Tier 内优先级。
// 返回 (tier, priority)：tier ∈ [0,4]，priority ∈ [0,3]，0 为最高优先。
func classifyTier(symbol, quoteAsset string, quoteVolumeUSD float64) (tier int, priority int) {
    // 第一层：显式配置（Level 决策）—— T0 列表人工维护，最高优先
    if t, ok := configuredTier(symbol); ok {
        return t, 0
    }
    // 第二层：流动性信号（依赖 decode 保留 quoteVolume）
    switch {
    case quoteVolumeUSD >= t1VolumeThreshold: // [INFERRED] 阈值待校准
        return 1, 1
    case quoteVolumeUSD >= 1_000_000:
        return 2, 2
    default:
        return 3, 3
    }
    // 第三层：计价资产兜底（无 volume 信号时）
    // quoteAsset ∈ {USDT, USDC} → 至少 T2；其他 → T3
}
```

**三层优先级**：第一层（显式配置，priority=0，人工边界）> 第二层（流动性信号，priority=1/2/3，数据驱动）> 第三层（计价资产兜底，容错决策，仅当 quoteVolumeUSD==0 时触发）。

**volume 阈值的 [INFERRED] 性质**：`t1VolumeThreshold` 不是硬编码常量，而是依赖 Binance 实测数据校准的运行时配置——初始建议 `50_000_000` USD（24h quoteVolume）起步 [GUESS, LOW]；校准方法是拉全量 symbol 的 quoteVolume 降序排列取第 100 名；初期保守配置（高阈值），灰度调整。产品线差异：spot / um_perp / cm_perp 各自维护独立阈值（cm_perp 流动性整体低于 spot，阈值应更低）。整体置信度 [INFERRED, MED]——方案合理，具体数值依赖实测数据校准。

**与"任务级 Priority"的消解**：现有 `LifecycleTask.Priority`（`lifecycle.go:16-19`，gapfill=100/coldstart=50/reconcile=20）是任务类型优先级。symbol 级用 `SymbolPriority`（或 `TierWeight`），任务级保留 `Priority`；任务最终出队键 = `(SymbolPriority, TaskPriority)` 复合排序。

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

---

## 8. 风险与缓解

| 风险 | 置信度 | 缓解 |
| --- | --- | --- |
| **T0 误降级**：quoteVolume 临时为 0 / decode 失败，核心 symbol 降为 REST 采样 → 实时策略失效 | [INFERRED, HIGH] | T0 配置**人工 review**（`symbols` 显式列表，不依赖自动判定）；admin API 强制 override 锁定 T0；metrics 监控 `binance_tier_symbol_count{tier="0"}`，低于阈值告警 |
| **volume 阈值偏离实际**：`t1VolumeThreshold` 初始值偏离，T1/T2 symbol 数量失衡 | [INFERRED, MED] | 初期保守配置（高阈值 → T1 偏少），灰度调整；用真实 exchangeInfo 响应校准（§3） |
| **options 量级数万**：不先修 TRADING 过滤，T4 / `rest_daily` / `far` 桶塞满无效合约 | [COMPUTED, HIGH] | **必须先修 §6.2 的 TRADING 过滤**（exchangeinfo_option.go:30-36 加 status），再启用 options_classification；分桶前 options 默认 `disabled` |
| **配置爆炸**：四产品线 × 五 Tier YAML 复杂，运维易配错 | [INFERRED, MED] | 配置加载 fail-fast（schema 校验）；`symbols` 与 `filter` 互斥校验；提供 `binancectl tier validate` 预检 |

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
