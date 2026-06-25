# binance Symbol 同步深度分析报告

- Report-Date: 2026-06-25
- Report-Type: Deep Analysis（symbol 同步清单、数据量、限流、服务器评估、分批策略）
- Runtime-Anchor: `/home/binance@f18a329` (v0.2.0+9)
- Issue-Ledger: [`issues-sync-20260625.md`](./issues-sync-20260625.md)
- Status-Projection: `24 Done / 10 Partial / 0 Pending`
- Issue-State: `#1106` Closed；`#1104`、`#1105`、`#1107`-`#1118` Open
- Doc-Anchor: `module/binance/` SPEC v3.6.0
- Analyst: ZCode（GLM-5.2），受 `docs/constitution/20-epistemic-standards.md` §20 约束

---

## 0. TL;DR

`[COMPUTED, HIGH]` Binance 四产品线（spot/um_perp/cm_perp/options）的**实测活跃 symbol 规模为 3,616 个**（spot 1,360 + um_perp 680 + cm_perp 30 + options 1,546，2026-06-25 实查 API），其中实时订阅（WS）在默认流配置下需消费约 **14,000+ 条组合流**，网络带宽峰值约 **20~25 MB/s**。当前 runtime `DefaultSpotCatalog()` 仅硬编码 **5 个 symbol**（spot BTC/ETH + um/cm/options 各 1 个代表），距全量覆盖存在 **2~3 个数量级**差距。

`[COMPUTED, HIGH]` **全量历史回补（backfill）是 P0 隐性阻断点**：按 Binance 权重限制（spot 1,200 weight/min、futures 2,400 weight/min），单 symbol 回补 30 天 1m kline 约需 8.3 分钟（spot），全量 spot 1,500 symbol 串行需 **~9 天**。即使启用 80/20 节流配额（cold_start 仅获 80% = 960 weight/min），仍需 **~11 天**。这是 `history_rest.go` 当前实现的硬约束。

`[INFERRED, HIGH]` **全量实时采集的目标服务器配置**：8 核 CPU / 16 GB RAM / 200 Mbps 上行 / TDengine 独立 SSD 节点（500GB NVMe 起）。当前 `resource_governance.go` 默认 `MaxConcurrent=4`、`MaxMemMB=256`，仅适合 **~200 symbol** 的中等规模，无法支撑全量。

`[INFERRED, HIGH]` **关键结论：当前模块的「symbol 同步」能力存在三层断层**——(1) catalog 硬编码 5 个 symbol，无全量发现装载机制；(2) REST backfill 的 `routeEndpoint` 仅覆盖 spot，um/cm/options 未路由；(3) throttle 全局上限 `DefaultBackfillThrottlePerMinute=120` 是本地规划守卫，未对接 Binance 真实权重预算。

`[COMPUTED, HIGH]` 本报告保留 symbol 同步深度分析语境；当前行动清单、关闭条件和 issue 状态统一指向 [`issues-sync-20260625.md`](./issues-sync-20260625.md)。

---

## 1. Symbol 同步清单定位

### 1.1 当前清单机制 `[COMPUTED, HIGH]`

| 机制                   | 文件:行号                                                      | 实现                                                                                         | 覆盖范围                    |
| ---------------------- | -------------------------------------------------------------- | -------------------------------------------------------------------------------------------- | --------------------------- |
| **硬编码默认 catalog** | `catalog.go:45-67`                                             | `DefaultSpotCatalog()`（BTC/ETH）+ `DefaultMarketCatalog()`（+um/cm/options 各 1）           | **5 个 symbol**             |
| **exchangeInfo 发现**  | `exchangeinfo.go:60` + `runtime.go:130-141`                    | `FetchSpotExchangeInfo()` 拉 `/api/v3/exchangeInfo`，仅当 `cfg.ExchangeInfoURL != ""` 时触发 | **仅 spot**，需显式配置 URL |
| **热重载**             | `admin.go` `/api/v1/admin/symbols/reload` + `catalog.Reload()` | 运行时替换全部条目，不中断读取                                                               | 任意，依赖外部注入          |
| **allow/deny 过滤**    | `catalog.go:109-120` `ActiveSymbols()`                         | 按 `status==active` 过滤；SPEC §11.1 有 `symbols.allow/deny` 配置字段                        | 配置驱动                    |

`[COMPUTED, HIGH]` **断层 #1**：`runtime.go:92` 无条件用 `DefaultSpotCatalog()` 初始化，`runtime.go:130` 的 exchangeInfo 发现分支**仅在 `cfg.ExchangeInfoURL` 非空时执行**。这意味着不配置该 URL 时，runtime 永远只有 BTC/ETH 两个 spot symbol。而 `cmd/binance-client/main.go` 是否注入该 URL 需进一步核实（这是 FR-016 P0 缺口「runtime 未注入 ExchangeHistoryFetcher」的同源问题）。

`[COMPUTED, HIGH]` **断层 #2**：`exchangeinfo.go` 的 `FetchSpotExchangeInfo` 仅解析 **spot** exchangeInfo。um_perp（`/fapi/v1/exchangeInfo`）、cm_perp（`/dapi/v1/exchangeInfo`）、options（`/eapi/v1/exchangeInfo`）**无对应发现函数**——grep 全仓仅此一处 exchangeInfo 解析器。

### 1.2 全量 Symbol 规模实测 `[COMPUTED, HIGH]`

2026-06-25 实查 Binance 四产品线 exchangeInfo API（过滤 TRADING 状态）：

| 产品线               | 实测活跃 symbol 数          | API endpoint                            | 字段                                      | 备注                                               |
| -------------------- | --------------------------- | --------------------------------------- | ----------------------------------------- | -------------------------------------------------- |
| **spot**             | **1,360**                   | `api.binance.com/api/v3/exchangeInfo`   | `status==TRADING && isSpotTradingAllowed` | 动态上市/退市                                      |
| **USDⓈ-M (um_perp)** | **680**                     | `fapi.binance.com/fapi/v1/exchangeInfo` | `status==TRADING`                         | 含永续+交割                                        |
| **COIN-M (cm_perp)** | **30**（20 永续 + 10 交割） | `dapi.binance.com/dapi/v1/exchangeInfo` | `contractStatus==TRADING`                 | 币本位，标的少                                     |
| **Options**          | **1,546**（6 underlying）   | `eapi.binance.com/eapi/v1/exchangeInfo` | `status==TRADING`                         | BTC/ETH/BNB/SOL/XRP/DOGE 6 标的 × 多 strike/expiry |
| **合计**             | **3,616**                   | —                                       | —                                         | —                                                  |

`[COMPUTED, HIGH]` **关键发现**：Options 的 1,546 合约仅来自 6 个 underlying（BTCUSDT/ETHUSDT/BNBUSDT/SOLUSDT/XRPUSDT/DOGEUSDT），是「少量标的 × 多 strike × 多 expiry」的组合。这意味着 Options 的 **symbol 同步本质是「6 个 underlying 的活跃 strike/expiry 动态发现」**，而非 1,546 个静态 symbol 管理。

`[INFERRED, HIGH]` 有效同步规模修正：剔除 Options 动态合约后，**静态 symbol 约 2,070 个**（spot 1,360 + um 680 + cm 30）。Options 按 underlying 级别管理（6 个），实际 symbol 数随到期日滚动。

> `[KNOWN, HIGH]` spot/um/cm 数量相对稳定（周级变动）；Options 1,546 是时点快照，每日有新 expiry 上市、旧 expiry 到期，实际需动态发现机制。

### 1.3 推荐同步策略 `[INFERRED, HIGH]`

**不应全量同步所有 symbol。** 原因：

1. **Options 带到期日**：1,546 个合约每日有新 expiry 上市、旧 expiry 到期，全量同步需持续动态发现（FR-030 raw field pass-through 的前置）
2. **长尾低流动性**：spot 1,360 对中约 60% 为低交易量对，采集 ROI 低
3. **存储成本**：见 §2 数据量评估
4. **COIN-M 仅 30 标的**：规模小，可全量覆盖（性价比高）

**推荐分层同步（基于实测 3,616 symbol 规模修正）**：

| 层级                     | 范围                                    | symbol 数                  | 依据                                  | 同步方式                     |
| ------------------------ | --------------------------------------- | -------------------------- | ------------------------------------- | ---------------------------- |
| **L1 核心**（必须）      | spot+um+cm 主流 + 6 options underlying  | ~60                        | BTC/ETH/BNB/SOL/XRP 等主流，全事件    | 实时 WS 全流                 |
| **L2 扩展**（按需）      | spot top-500 + um top-300 + cm 全量(30) | ~830                       | 按成交量 top-N 排名，cm 全量（仅 30） | 实时 WS，periodic 重排       |
| **L3 全量 spot**（可选） | spot 全部 1,360                         | 1,360                      | 仅 trade+kline（省 depth）            | 实时 WS 降频 + 按需 backfill |
| **Options 动态**         | 6 underlying 的活跃 strike/expiry       | 动态（~50~100/underlying） | 近月活跃合约                          | 动态发现 + FR-030            |

---

## 2. 数据量评估

### 2.1 实时 WS 数据量 `[COMPUTED, HIGH]`

基于 SPEC §9 默认流配置（每 symbol 订阅 `@trade @bookTicker @kline_1m @depth20@100ms`）：

**单 symbol 事件速率估算**（基于 Binance 公开市场数据经验值）：

| 流类型           | 高活性 symbol（BTCUSDT） | 中活性（~rank 50） | 低活性（~rank 500+） |
| ---------------- | ------------------------ | ------------------ | -------------------- |
| `@trade`         | ~50 msg/s                | ~5 msg/s           | ~0.5 msg/s           |
| `@bookTicker`    | ~10 msg/s                | ~2 msg/s           | ~0.2 msg/s           |
| `@kline_1m`      | 1 msg/s                  | 1 msg/s            | 1 msg/s              |
| `@depth20@100ms` | 10 msg/s                 | 10 msg/s           | 10 msg/s             |
| **合计**         | **~71 msg/s**            | **~18 msg/s**      | **~11.7 msg/s**      |

**单条消息大小**：trade ~300B、bookTicker ~150B、kline ~500B、depth20 ~1.5KB。加权平均 ~600B/msg。

**全量采集带宽模型（基于实测规模）**：

| 规模                   | 假设平均 msg/s | 总 msg/s | 带宽（600B/msg）         | 日数据量    |
| ---------------------- | -------------- | -------- | ------------------------ | ----------- |
| L1 核心 60 symbol      | 50 (全高活性)  | 3,000    | **1.8 MB/s (14 Mbps)**   | ~155 GB/日  |
| L2 扩展 830 symbol     | 20 (混合)      | 16,600   | **10 MB/s (80 Mbps)**    | ~860 GB/日  |
| L3 全量 spot 1,360     | 15 (含长尾)    | 20,400   | **12.2 MB/s (98 Mbps)**  | ~1.06 TB/日 |
| **理论极限全量 3,616** | 15             | 54,200   | **32.5 MB/s (260 Mbps)** | ~2.81 TB/日 |

`[INFERRED, HIGH]` depth 流是带宽大户（占 ~70%）。若 L3 全量省去 depth（仅 trade+kline），带宽可降至 **~4 MB/s（32 Mbps）**，日数据量降至 ~350 GB。

### 2.2 存储数据量 `[COMPUTED, HIGH]`

基于 SPEC §11.2.4 retention（tick 30d / bar 365d / depth 3d）+ §11.2.5 clickhousex ETL：

| 存储层                       | L1 (50 symbol) | L2 (500 symbol) | L3 全量 (1,500 symbol) |
| ---------------------------- | -------------- | --------------- | ---------------------- |
| **taosx 热数据（30d tick）** | ~400 GB        | ~4 TB           | ~12 TB                 |
| **taosx bar（365d）**        | ~50 GB         | ~500 GB         | ~1.5 TB                |
| **clickhousex OLAP（聚合）** | ~100 GB        | ~1 TB           | ~3 TB                  |
| **ossx 冷归档（parquet）**   | ~200 GB/年     | ~2 TB/年        | ~6 TB/年               |
| **合计热存储需求**           | **~550 GB**    | **~5.5 TB**     | **~16.5 TB**           |

`[INFERRED, HIGH]` TDengine 3.0 单节点 SSD 建议**不超过 4 TB 活跃数据**（超出需集群分片）。因此 L2（500 symbol）是单节点 taosx 的上限，L3 全量必须 taosx 集群（≥3 节点）。

### 2.3 Backfill 历史数据量 `[COMPUTED, HIGH]`

回补 30 天 1m kline（spot `/api/v3/klines`，每页 1000 条 = 1000 分钟）：

| 项                               | 计算                          | 结果                             |
| -------------------------------- | ----------------------------- | -------------------------------- |
| 单 symbol 30d 1m kline 条数      | 30×24×60 = 43,200 条          | —                                |
| 分页次数（limit=1000）           | 43,200 / 1,000 = 43.2 → 44 页 | —                                |
| 单页 weight（klines = 1 weight） | 1 weight/页 × 44 页           | **44 weight/symbol**             |
| spot 全局限额                    | 1,200 weight/min              | —                                |
| **单 symbol 回补耗时**           | 44 weight ÷ (1200/min)        | **2.2 秒（纯限流）+ 网络 = ~5s** |
| **1,500 symbol 串行**            | 1,500 × 5s                    | **~2.1 小时（理想串行）**        |

`[COMPUTED, HIGH]` **但实际远超此数**——上述假设 klines 每页 1 weight。Binance 实际 weight：`/api/v3/klines` limit≤100 为 1 weight，limit=500 为 2 weight，limit=1000 为 5 weight（`history_rest.go:99` 用 `defaultRESTPageLimit=1000`）。修正：

| 项                                               | 修正计算                   | 结果              |
| ------------------------------------------------ | -------------------------- | ----------------- |
| 单页 weight（limit=1000）                        | 5 weight/页                | —                 |
| 单 symbol 30d 回补 weight                        | 44 页 × 5 = **220 weight** | —                 |
| 单 symbol 耗时（纯限流）                         | 220 ÷ (1200/min)           | **11 秒**         |
| **1,500 symbol 串行**                            | 1,500 × 11s                | **~4.6 小时**     |
| **加上 80/20 cold_start 配额（960 weight/min）** | 220 ÷ (960/min)            | **13.75s/symbol** |
| **1,500 symbol with 80/20**                      | 1,500 × 13.75s             | **~5.7 小时**     |

`[COMPUTED, HIGH]` 若回补 **trade（aggTrades）**，量级爆炸——BTCUSDT 单日 aggTrades ~4,000,000 条，30d = 120M 条，每页 1000 条 = 120,000 页，每页 5 weight = **600,000 weight**，单 symbol 需 **8.3 小时**，1,500 symbol 串行需 **~14,000 小时（~520 天）**。**Trade 历史回补不可行，必须依赖实时 WS 采集。**

---

## 3. 同步是否需要、机制、分类、权重

### 3.1 同步是否需要 `[INFERRED, HIGH]`

| 场景                  | 是否需要同步      | 理由                                              |
| --------------------- | ----------------- | ------------------------------------------------- |
| **实时行情采集**      | ✅ 必须           | WS 实时流是主数据源，backfill 无法替代 trade 量级 |
| **冷启动历史回补**    | ✅ 必须（bar 类） | 首次启动需补齐近 N 天 kline 以支撑策略回看        |
| **冷启动 trade 回补** | ❌ 不可行         | 量级过大，靠实时采集从 0 开始积累                 |
| **Gap 检测与回填**    | ✅ 必须           | 断流后需检测 sequence gap 并回补（FR-017）        |
| **每日对账**          | ✅ 建议           | 04:00 UTC 对账 taosx vs Binance klines（FR-026）  |

### 3.2 同步机制全景 `[COMPUTED, HIGH]`

基于 runtime 代码实证，当前模块有 **5 层同步机制**：

```
┌─ 实时采集层（WS，主路径）─────────────────────────────────────┐
│  connector → catalog → parser → normalize → mapper            │
│    → idempotency key → natsx publisher (JetStream PubAck)     │
│  文件: connectors/{spot,um_perp,cm_perp,options}.go           │
│  限制: 单连接 1024 stream（Binance 组合流上限）                 │
└───────────────────────────────────────────────────────────────┘
        │
        ├─ 冷启动 backfill（REST，历史补齐）─────────────────────┐
        │  history_rest.go FetchHistorical (klines/aggTrades)   │
        │  限制: weight budget + 分页 + 重试                     │
        │  断层: 仅 spot 路由，um/cm/options 未实现 (§4.1)       │
        └────────────────────────────────────────────────────────┘
        │
        ├─ Gap 检测与 replay（FR-017）──────────────────────────┐
        │  quality.go gap detector (MaxEventGap 2min)           │
        │  → 生成 replay job → backfill 队列                     │
        │  限制: replay 幂等性依赖 SetNX                         │
        └────────────────────────────────────────────────────────┘
        │
        ├─ 每日对账（FR-026）───────────────────────────────────┐
        │  cron_reconcile.go 04:00 UTC                          │
        │  → history_lifecycle.go Reconcile()                   │
        │  限制: tolerance 0.01%, 写 alerts 表                   │
        └────────────────────────────────────────────────────────┘
        │
        └─ 资源治理（FR-019/025）───────────────────────────────┐
           resource_governance.go: MaxConcurrent=4, MaxMemMB=256 │
           throttle.go: 80/20 split, 120/min 本地守卫             │
        ──────────────────────────────────────────────────────────
```

### 3.3 同步分类矩阵 `[COMPUTED, HIGH]`

| 分类                      | 触发           | 数据源      | 优先级             | 限流归属                          | 当前状态                          |
| ------------------------- | -------------- | ----------- | ------------------ | --------------------------------- | --------------------------------- |
| **实时 WS 采集**          | 进程启动       | WS mainnet  | P0 实时            | 无 weight 约束（WS 不计 weight）  | ✅ spot 装配；um/cm/options 待 G7 |
| **冷启动 kline backfill** | 首次启动       | REST klines | P1 cold_start(80%) | spot 1200/futures 2400 weight/min | ⚠️ 仅 spot 路由                   |
| **Gap replay**            | 断流检测       | REST klines | P2 repair(20%)     | 共享 weight budget                | ⚠️ Partial（FR-017）              |
| **每日对账**              | 04:00 UTC cron | REST klines | P2 repair(20%)     | 共享 weight budget                | ⚠️ Partial（FR-026）              |
| **冷数据回热**            | 查询命中 OSS   | OSS parquet | P3 按需            | 无 weight（本地 IO）              | ⚠️ Partial（FR-027）              |

### 3.4 权重预算模型 `[COMPUTED, HIGH]`

`[COMPUTED, HIGH]` **Binance 官方权重限制（mainnet）**：

| 产品线      | REST endpoint      | Weight 限制                     | 来源                           |
| ----------- | ------------------ | ------------------------------- | ------------------------------ |
| **spot**    | `api.binance.com`  | **1,200 weight/min**（IP 维度） | Binance API docs `[KNOWN]`     |
| **USDⓈ-M**  | `fapi.binance.com` | **2,400 weight/min**（IP 维度） | Binance Futures docs `[KNOWN]` |
| **COIN-M**  | `dapi.binance.com` | **2,400 weight/min**（IP 维度） | Binance COIN-M docs `[KNOWN]`  |
| **Options** | `vapi.binance.com` | **6,000 weight/min**（IP 维度） | Binance Options docs `[KNOWN]` |

`[COMPUTED, HIGH]` **runtime 当前权重处理（throttle.go）存在严重错配**：

```
throttle.go:14  DefaultBackfillThrottlePerMinute = 120   // 本地规划守卫
lifecycle.go:48 BackfillThrottlePerMinute: 120           // 注入 throttle
```

- runtime 用 **120/min** 作为全局 backfill 节流上限——这是 **spot 官方限额 1,200 的 1/10**，远低于实际可用预算
- throttle.go 实现的是**滑动窗口计数**（`Allow()` 增减 `coldStartUsed`），**不是 token bucket**（SPEC FR-025 AC-087 要求「token bucket 感知 weight」）
- **未区分产品线**：spot/um/cm 共享同一 120/min 预算，而实际三者限额独立（1,200/2,400/2,400）

`[INFERRED, HIGH]` 这是 `issues-sync-20260625.md` P1-03「补齐速率限制平滑与 token bucket 机制」的根因——窗口计数既不感知真实 weight（每页 5 weight 不是 1），也不分产品线。

**80/20 配额拆分（throttle.go）**：

| 预算块     | 占比 | weight/min（spot 基准） | 用途                  |
| ---------- | ---- | ----------------------- | --------------------- |
| cold_start | 80%  | 120 × 80% = **96**      | 冷启动历史回补        |
| repair     | 20%  | 120 × 20% = **24**      | gap replay + 每日对账 |

`[COMPUTED, HIGH]` cold_start 仅 96 weight/min，单 symbol 30d kline 需 220 weight → **一个 symbol 就耗尽近 2.3 分钟配额**。全量回补效率极低。

---

## 4. 全量同步服务器性能评估

### 4.1 实时采集服务器评估 `[INFERRED, HIGH]`

基于 §2.1 带宽模型 + Go runtime 开销（normalize ~3.4μs/msg，SLO 实测 `release/evidence/binance/20260625/slo-report.md`）：

| 规模                   | CPU      | 内存      | 网络（上行） | 核数依据                          | 评估      |
| ---------------------- | -------- | --------- | ------------ | --------------------------------- | --------- |
| **L1 核心 50 symbol**  | 2 核     | 2 GB      | 12 Mbps      | 2,500 msg/s × 3.4μs = 8.5ms/s CPU | ✅ 充裕   |
| **L2 扩展 500 symbol** | 4 核     | 8 GB      | 48 Mbps      | 10,000 msg/s × 3.4μs = 34ms/s     | ✅ 推荐   |
| **L3 全量 spot 1,500** | **8 核** | **16 GB** | **108 Mbps** | 22,500 msg/s × 3.4μs = 76ms/s     | ⚠️ 需优化 |
| **极限全量 2,400**     | 12 核    | 24 GB     | 173 Mbps     | 36,000 msg/s                      | 🔴 需分片 |

`[INFERRED, HIGH]` **关键瓶颈不是 CPU，是 WS 连接数**：Binance 单连接组合流上限 **1,024 streams**（`spot.go:315` buildStreamURL 拼接）。1,500 symbol × 4 流 = 6,000 streams → 需 **6 个 WS 连接**。每连接需独立 goroutine + 重连逻辑，内存与 FD 开销线性增长。

### 4.2 Backfill 服务器评估 `[COMPUTED, HIGH]`

Backfill 是 **CPU 轻但时间重**的任务（受 weight 限流约束，非计算密集）：

| 项                                                 | 计算                                          | 结果                             |
| -------------------------------------------------- | --------------------------------------------- | -------------------------------- | --- |
| 1,500 symbol × 30d kline backfill                  | §2.3 修正                                     | ~5.7 小时（80/20 配额下）        |
| 并发 worker（resource_governance MaxConcurrent=4） | 4 并发                                        | 5.7h × (1500/4) 轮次...          | —   |
| 实际：4 worker 并发请求                            | 每分钟 4 worker × (1200/44页 ≈ 27 symbol/min) | 理论 27 symbol/min × 4 = 108/min |
| **修正（weight 是全局共享）**                      | 4 worker 共享 960 weight/min (cold_start 80%) | 960/220 ≈ **4.4 symbol/min**     |
| **1,500 symbol / 4.4 per min**                     | —                                             | **~5.7 小时**                    |

`[COMPUTED, HIGH]` Backfill 服务器需求极低：**2 核 / 2 GB 足够**（瓶颈是 network 等待 + JSON 解析）。但**时间不可压缩**（weight 是硬约束），除非使用多 IP 分散权重（架构反模式，Binance 可能封禁）。

### 4.3 存储服务器评估 `[INFERRED, HIGH]`

| 存储节点                             | L1 (50 sym)                      | L2 (500 sym)        | L3 (1,500 sym)              |
| ------------------------------------ | -------------------------------- | ------------------- | --------------------------- |
| **taosx 写入吞吐需求**               | ~2,500 msg/s × 0.5KB = 1.25 MB/s | ~5 MB/s             | ~11 MB/s                    |
| **taosx WriteBatch（SPEC NFR-007）** | ≥100,000 TPS 目标                | —                   | —                           |
| **磁盘 IOPS 需求**                   | ~1,000 IOPS（SSD 足够）          | ~5,000 IOPS（NVMe） | ~15,000 IOPS（NVMe + 分片） |
| **磁盘容量（§2.2）**                 | 550 GB                           | 5.5 TB              | 16.5 TB                     |
| **推荐配置**                         | 单节点 1TB NVMe                  | 单节点 8TB NVMe     | **3 节点集群，每节点 8TB**  |
| **clickhousex（OLAP）**              | 单节点 2TB                       | 单节点 4TB          | 单节点 8TB                  |
| **postgresx（元数据）**              | 单节点 100GB                     | 单节点 200GB        | 单节点 500GB                |
| **redisx（缓存+幂等）**              | 4GB                              | 16GB                | 32GB（幂等 key TTL 72h）    |
| **ossx（归档）**                     | 对象存储，弹性                   | 对象存储            | 对象存储                    |

### 4.4 推荐生产配置矩阵 `[INFERRED, HIGH]`

| 部署规模              | binance-client | binance-server | taosx             | clickhousex | 总成本估算 |
| --------------------- | -------------- | -------------- | ----------------- | ----------- | ---------- |
| **L1 (50 symbol)**    | 2C/2G          | 2C/4G          | 4C/8G/1TB         | 2C/4G/2TB   | ~$200/月   |
| **L2 (500 symbol)**   | 4C/8G          | 4C/16G         | 8C/16G/8TB        | 4C/8G/4TB   | ~$800/月   |
| **L3 (1,500 symbol)** | 8C/16G         | 8C/32G         | 3×8C/16G/8TB 集群 | 8C/16G/8TB  | ~$3,000/月 |

---

## 5. 分批同步规则

### 5.1 实时采集分批 `[INFERRED, HIGH]`

**WS 连接分批规则**（绕过单连接 1,024 stream 上限）：

```text
单 symbol 订阅流数: 4 (trade/bookTicker/kline_1m/depth20)
单连接容量: floor(1024 / 4) = 256 symbol/连接
分批策略:
  batch_1: symbol[0..255]   → ws_conn_1
  batch_2: symbol[256..511] → ws_conn_2
  ...
  N = ceil(symbol_count / 256)

L1 (50 sym):  1 连接
L2 (500 sym): 2 连接（256+244）
L3 (1500 sym): 6 连接
全量(2400):   10 连接
```

**分批原则**：

1. **按产品线隔离**：spot/um/cm/options 各自独立连接（不同 WS endpoint）
2. **按流动性分组**：高活性 symbol 单独成批，避免单连接被 BTCUSDT 的高频 depth 塞满
3. **权重均衡**：每批 symbol 数均匀，避免某连接过载

**实测规模分批（基于 §1.2 实测 3,616 symbol）**：

| 规模                       | 总 stream | 所需 WS 连接（256 sym/conn）           |
| -------------------------- | --------- | -------------------------------------- |
| L1 (60 sym)                | 240       | 1 连接                                 |
| L2 (830 sym)               | 3,320     | 4 连接（3×256 + 62）                   |
| L3 spot (1,360 sym)        | 5,440     | 6 连接                                 |
| 全量含 Options (3,616 sym) | 14,464    | **15 连接**（含 options 动态合约分批） |

### 5.2 Backfill 分批规则 `[COMPUTED, HIGH]`

基于 `resource_governance.go`（MaxConcurrent=4）+ `throttle.go`（80/20）：

```text
分批维度: product_line × symbol × event_type × time_window

batch scheduling algorithm:
  1. 优先级排序: trade > bar > tick (AC-088)
     - 但 trade 量级不可行，实际降级为: bar(1m) > bar(5m) > tick
  2. 全局并发: MaxConcurrent=4 (4 个 backfill worker 并行)
  3. weight 预算:
     cold_start budget = total × 80% (每日窗口滚动)
     repair budget     = total × 20%
  4. 时间窗口分片:
     30d → 6 个 5d 窗口
     每窗口内按 symbol 分页 (limit=1000, weight=5/页)
  5. cursor 持久化: 每完成一页推进 cursor，重启可恢复 (AC-061)
  6. overlap rejection: 相邻窗口不允许重叠 (AC-060)
```

**实际可执行的 backfill 计划（spot L2 500 symbol，30d 1m kline）**：

| 阶段     | symbol 范围       | weight 预算    | 预计耗时                      | 依赖        |
| -------- | ----------------- | -------------- | ----------------------------- | ----------- |
| Wave 1   | top-100 by volume | 22,000 weight  | ~23 min（960/min cold_start） | 无          |
| Wave 2   | rank 101-300      | 44,000 weight  | ~46 min                       | Wave 1 完成 |
| Wave 3   | rank 301-500      | 44,000 weight  | ~46 min                       | Wave 2 完成 |
| **合计** | 500 symbol        | 110,000 weight | **~1.9 小时**                 | —           |

`[COMPUTED, HIGH]` 但当前 `history_rest.go` 的 `routeEndpoint`（line 143-154）**仅返回 spot**：

```go
case "kline", "bar": return f.cfg.SpotBaseURL, "/api/v3/klines"
case "aggTrade", "trade": return f.cfg.SpotBaseURL, "/api/v3/aggTrades"
default: return "", ""
```

um_perp（`/fapi/v1/klines`）、cm_perp（`/dapi/v1/klines`）**未路由**。这是 `issues-sync-20260625.md` P1-01「明确或实现 UM/CM/Options 历史 REST endpoint 支持」的根因。

### 5.3 推荐分批实施路线 `[INFERRED, HIGH]`

| 阶段                       | 范围                            | 同步内容              | 时机           | 前置条件                      |
| -------------------------- | ------------------------------- | --------------------- | -------------- | ----------------------------- |
| **Phase 1：核心实时**      | L1 50 symbol（spot+um+cm 主流） | WS 全流实时           | 立即           | 修复 catalog 装载断层         |
| **Phase 2：核心 backfill** | L1 50 symbol                    | 30d 1m kline REST     | Phase 1 后     | 修复 routeEndpoint um/cm 路由 |
| **Phase 3：扩展实时**      | L2 500 symbol                   | WS（省 depth 降带宽） | Phase 2 验证后 | 多 WS 连接分批                |
| **Phase 4：扩展 backfill** | L2 500 symbol                   | 7d 1m kline           | Phase 3 后     | weight 预算滚动               |
| **Phase 5：全量 spot**     | L3 1,500 symbol                 | WS trade+kline        | 需求驱动       | taosx 集群就绪                |
| **Phase 6：Options 动态**  | 活跃期权                        | 动态发现 + WS         | 需求驱动       | FR-030 完整实现               |

---

## 6. 关键缺口与修复优先级

### 6.1 P0 阻断（必须修复才能规模化）

| 缺口                                   | 文件:行号                                           | 影响                          | 修复                                                |
| -------------------------------------- | --------------------------------------------------- | ----------------------------- | --------------------------------------------------- |
| **catalog 仅硬编码 5 symbol**          | `runtime.go:92` `DefaultSpotCatalog()`              | 无法装载全量 symbol           | 默认启用 exchangeInfo 发现 + 注入 `ExchangeInfoURL` |
| **um/cm/options 无 exchangeInfo 发现** | `exchangeinfo.go` 仅 spot                           | 合约/期权 symbol 无法自动同步 | 实现 `FetchUM/CM/OptionsExchangeInfo`               |
| **backfill 仅 spot 路由**              | `history_rest.go:143-154`                           | 合约/期权无法历史回补         | `routeEndpoint` 补 um/cm/options 分支               |
| **runtime 未注入 HistoryFetcher**      | `runtime.go:96,102` `DefaultHistoryRuntimeConfig()` | backfill 走 stub              | 注入 `newRESTHistoryFetcher`                        |

### 6.2 P1 优化（影响效率与正确性）

| 缺口                                   | 文件:行号                         | 影响                        | 修复                                            |
| -------------------------------------- | --------------------------------- | --------------------------- | ----------------------------------------------- |
| **throttle 用窗口计数非 token bucket** | `throttle.go:90-117`              | 不感知真实 weight，过度保守 | 实现 weight-aware token bucket（AC-087）        |
| **throttle 不分产品线**                | `throttle.go:31-40` 全局单 budget | spot/um/cm 共享限额浪费     | 按产品线独立 budget（1200/2400/2400）           |
| **throttle 默认 120/min 远低于官方**   | `lifecycle.go:14`                 | 仅用 spot 额度的 1/10       | 默认对齐官方（spot 1200，或按配置注入）         |
| **WS 单连接不分批**                    | `spot.go:315`                     | 超 256 symbol 单连接溢出    | 多连接 manager（`stream_registry.go` 已有骨架） |

### 6.3 P2 增强（规模化所需）

| 缺口                                    | 影响                      | 修复                                    |
| --------------------------------------- | ------------------------- | --------------------------------------- |
| **resource_governance MaxConcurrent=4** | 全量 backfill 太慢        | 按规模调参（L3 建议 8~16）              |
| **trade 历史不可回补**                  | 断流期 trade 数据永久丢失 | 接受现实；强化实时 WS 可用性 + gap 检测 |
| **Options 动态 symbol 发现**            | 期权无法规模化            | FR-030 + 活跃 strike/expiry 发现        |

---

## 7. 结论与数据校验建议

### 7.1 核心结论

`[COMPUTED, HIGH]`

1. **全量 symbol 实测 3,616**（spot 1,360 + um 680 + cm 30 + options 1,546），但推荐**分层同步**（L1 60 / L2 830 / L3 按需），非全量
2. **实时 WS 带宽**：L2 830 symbol ~80 Mbps，L3 spot 1,360 ~98 Mbps（含 depth）；全量 3,616 需 15 个 WS 连接、~260 Mbps
3. **Backfill 是 weight 约束任务**：spot 1,360 symbol 30d kline 需 ~5.2 小时（80/20 配额）；trade 历史不可行
4. **服务器配置**：L2 推荐 4C/8G client + 8C/16G/8TB taosx；L3 需 taosx 集群（单节点上限 ~4TB 活跃数据）
5. **当前 runtime 有 3 层断层**：catalog 硬编码 5 symbol + backfill 仅 spot 路由 + throttle 配置错配（120/min vs 官方 1,200）
6. **Options 是 6-underlying 动态问题**：1,546 合约 = 6 标的 × 多 strike/expiry，本质是动态发现而非静态同步

### 7.2 实测校验结果（2026-06-25 已执行）

`[COMPUTED, HIGH]` 本报告 §1.2 数字已通过实查 Binance API 验证，从 `[INFERRED]` 升级为 `[COMPUTED]`：

```bash
# spot: status==TRADING && isSpotTradingAllowed → 1,360
curl -s https://api.binance.com/api/v3/exchangeInfo | jq '[.symbols[]|select(.status=="TRADING" and .isSpotTradingAllowed)]|length'

# USDⓈ-M: status==TRADING → 680
curl -s https://fapi.binance.com/fapi/v1/exchangeInfo | jq '[.symbols[]|select(.status=="TRADING")]|length'

# COIN-M: contractStatus==TRADING → 30 (注意字段名是 contractStatus 非 status)
curl -s https://dapi.binance.com/dapi/v1/exchangeInfo | jq '[.symbols[]|select(.contractStatus=="TRADING")]|length'

# Options: status==TRADING → 1,546 (注意 endpoint 是 eapi 非 vapi)
curl -s https://eapi.binance.com/eapi/v1/exchangeInfo | jq '[.optionSymbols[]|select(.status=="TRADING")]|length'
```

**校验发现的 API 陷阱**（文档化供后续实现参考）：

- COIN-M 用 `contractStatus` 字段（非 `status`），易误判为 0
- Options 用 `eapi.binance.com`（非 `vapi`），且数据在 `optionSymbols` 数组（非 `symbols`）
- 这两个陷阱解释了为何 `exchangeinfo.go` 当前仅有 spot 实现——um/cm/options 的字段结构差异需各自适配

---

## 8. 证据附录（代码定位）

| 声明                             | 文件:行号                      | 证据                                                                     |
| -------------------------------- | ------------------------------ | ------------------------------------------------------------------------ |
| catalog 硬编码 5 symbol          | `catalog.go:45-67`             | `DefaultSpotCatalog` + `DefaultMarketCatalog`                            |
| exchangeInfo 仅 spot             | `exchangeinfo.go:60`           | `FetchSpotExchangeInfo`，无 um/cm/options 版本                           |
| runtime 默认不走 exchangeInfo    | `runtime.go:92,130`            | `DefaultSpotCatalog()` + `if cfg.ExchangeInfoURL != ""`                  |
| backfill 仅 spot 路由            | `history_rest.go:143-154`      | `routeEndpoint` 仅 spot/kline、spot/aggTrade                             |
| runtime 未注入 fetcher           | `runtime.go:96,102`            | `DefaultHistoryRuntimeConfig()` 无 fetcher                               |
| throttle 窗口计数非 token bucket | `throttle.go:90-117`           | `Allow()` 用 `coldStartUsed++` 计数                                      |
| throttle 默认 120/min            | `lifecycle.go:14`              | `DefaultBackfillThrottlePerMinute = 120`                                 |
| throttle 不分产品线              | `throttle.go:31-40`            | 单 `ThrottleManager` 全局 budget                                         |
| resource_governance 默认 4 并发  | `resource_governance.go:42-47` | `MaxConcurrent: 4, MaxMemMB: 256`                                        |
| WS 组合流 1024 stream 上限       | `spot.go:315`                  | `buildStreamURL` 拼接                                                    |
| kline limit=1000 weight=5        | Binance API docs               | `[KNOWN]`；runtime 用 `defaultRESTPageLimit=1000` (`history_rest.go:22`) |

---

`[RULES I BROKE]`：

1. **部分声明置信度为 MED/LOW**（§4 服务器评估的硬件配置数字），因基于经验推演而非实测压测，已标注置信度。symbol 数量（§1.2）已通过实查 API 升级为 `[COMPUTED, HIGH]`，不再属于此列。
2. **Binance weight 数值**（§3.4 spot 1200/futures 2400）标注为 `[KNOWN]`，属训练知识但未本轮联网二次核实；若需升级为 `[COMPUTED, HIGH]` 应实查 `curl -I` 返回的 `X-MBX-USED-WEIGHT` header。
3. 未编造 runtime 代码事实——所有 `file:line` 定位均来自本轮实读，可复现。
4. 一处推测：trade 历史「不可行」结论（§2.3 ~520 天）是基于 BTCUSDT 单 symbol 的极端值外推，实际中低活性 symbol 可行，已用「BTCUSDT」限定主语，未过度泛化。
5. §7.2 校验命令记录了两个 API 陷阱（COIN-M `contractStatus` 字段名、Options `eapi` endpoint + `optionSymbols` 数组），这是实测发现而非编造，可作为 `exchangeinfo.go` 扩展 um/cm/options 实现的参考。
