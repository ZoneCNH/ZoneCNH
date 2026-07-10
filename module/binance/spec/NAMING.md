# module/binance NAMING.md — 命名 SSOT

- Module-Version: v4.1.0
- Last-Updated: 2026-07-09
- Applies-To: `module/binance/spec/SPEC.md` v4.1.0, `module/binance/gate/RULES.md` v4.1.0
- Scope: product_line、event_type、natsx subject、Kafka topic、TDengine stable、Redis key、REST endpoint、OSS path、PostgreSQL table、ClickHouse table

> [COMPUTED, HIGH] 本文件是 `module/binance` 命名权威入口。所有新增规格、任务和 runtime 代码必须使用本文件的 canonical token；历史别名只允许出现在本文件、治理报告、漂移清单和归档 task 中。canonical 命名对齐 Binance 原生事件名（camelCase → snake_case），详见 [EVENT-TYPE-MAPPING.md](../design/EVENT-TYPE-MAPPING.md) §2.0。

---

## 1. Canonical Product Line

| product_line | 含义 | 历史别名（禁止新用） |
|---|---|---|
| `spot` | 现货 | `cash`, `spot_market` |
| `um_perp` | USDⓈ-M 合约（永续 + 交割，见 §1.1） | `usdm`, `usdm_futures`, `futures_usdt` |
| `cm_perp` | COIN-M 合约（永续 + 交割，见 §1.1） | `coinm`, `coinm_futures`, `futures_coin` |
| `options` | 期权 | `option`, `opts` |

> [COMPUTED, HIGH] `um_perp` / `cm_perp` 的 product_line 标识沿袭 Binance 保证金口径（U 本位 / 币本位），**不锁定合约类型**。同一 product_line 下永续与交割合约通过 §1.1 `instrument_subtype` 维度区分，不拆分 product_line，以保证 subject/topic/path 稳定与 4×6 矩阵不膨胀。

### 1.1 Instrument Subtype（FR-002a）

[COMPUTED, HIGH] `instrument_subtype` 是 `um_perp` / `cm_perp` product_line 内区分永续与交割合约的 canonical 维度，来源 `module/domain_market`。

| instrument_subtype | 含义 | 典型 symbol | expiry |
|---|---|---|---|
| `perpetual` | 永续合约 | `BTCUSDT` | null |
| `delivery` | 交割合约（当季 / 次季 / 季度） | `BTCUSDT_240329`、`BTCUSD_240628` | 非零 |

> [COMPUTED, HIGH] `instrument_subtype` **不进入** natsx subject / Kafka topic / OSS path（这些键仍只含 `product_line` + `event_type`），只进入 `InstrumentKey` identity 矩阵（SPEC §9）与 TDengine tag / Redis key 的 identity 段，确保下游消费者能从 payload 元数据区分永续 vs 交割，而无需拆分 subject 订阅。

> [KNOWN, HIGH] `spot` 与 `options` product_line 不适用 `instrument_subtype`（spot 无合约细分；options 已由 `instrument_type=Option` + expiry/strike/option_type 三维定位）。

## 2. Canonical Event Type

> [COMPUTED, HIGH] v3.18.0 将 canonical 命名对齐 Binance 原生事件名（camelCase → snake_case），消除自创名。命名规则：1:1 映射（`bookTicker`→`book_ticker`）；多事件聚合取公共词干（`24hrTicker`/`24hrMiniTicker`→`ticker`）；派生类型保留自命名（`funding_rate`）；语义分组用分组名（`index_reference`）。

### 2.1 已实现类型（runtime 已装配）

| event_type | legacy alias | 语义分类 | Binance 原生 |
|---|---|---|---|
| `book_ticker` | ~~`tick`~~ | 状态型 | `bookTicker` |
| `kline` | ~~`bar`~~ | 状态型 | `kline` |
| `depth_update` | ~~`depth`~~ | 增量型 | `depthUpdate` |
| `trade` | — | 事件型 | `aggTrade` / `trade` |
| `funding_rate` | — | 状态型 | (派生自 `markPriceUpdate` `r` 字段) |
| `mark_price_update` | ~~`mark_price`~~ | 状态型 | `markPriceUpdate` |
| `option_tick` | — | 状态型 | `optionTicker` |

### 2.2 扩展类型（local runtime 已接入；发布证据仍受 gate 约束）

| event_type | 语义分类 | Binance 原生 |
|---|---|---|
| `ticker` | 状态型 | `24hrTicker` / `24hrMiniTicker` |
| `force_order` | 事件型(不完整) | `forceOrder` |
| `open_interest` | 状态型 | `openInterest` |
| `index_reference` | 状态型 | `compositeIndex` / `assetIndex` / `avgPrice` / `referencePrice` |
| `contract_info` | 事件型(低频) | `contractInfo` |

> [COMPUTED, HIGH] v4.1.0 起 product_line × event_type 为 **4 × 12** 矩阵（7 baseline + 4 local extended + 1 opt-in/postponed force_order）。runtime 必须用 capability/status 标识不适用、未默认订阅和待 external release evidence 的组合。

### 2.3 Bar 订阅周期集（FR-014）

| product_line | 订阅周期 | 说明 |
|---|---|---|
| `spot` / `um_perp` / `cm_perp` | `1s, 1m, 5m, 15m, 1h, 4h, 1d` | 全周期直采 |
| `options` | `1m, 5m, 1h, 1d` | 期权不含 1s/15m/4h |

> [COMPUTED, HIGH] 其他周期（如 `3m, 2h, 1w`）下游通过 `clickhousex` 重采样生成，不在 client 订阅集内。

## 3. natsx Subject Matrix

格式：`binance.market.{product_line}.{event_type}.v1`

### 3.1 Baseline subjects

| product_line | 已实现 event_types |
|---|---|
| `spot` | `book_ticker`, `trade`, `kline`, `depth_update` |
| `um_perp` | `book_ticker`, `trade`, `kline`, `depth_update`, `funding_rate`, `mark_price_update` |
| `cm_perp` | `book_ticker`, `trade`, `kline`, `depth_update`, `funding_rate`, `mark_price_update` |
| `options` | `trade`, `kline`, `depth_update`, `option_tick` |

> [COMPUTED, HIGH] 上表是 7 个 baseline subject；扩展能力与 opt-in 状态见 §3.2。`—` 表示 baseline 组合不适用，不代表扩展 event_type 的 server/storage/API 路由不存在。

### 3.2 扩展 subjects（4 local implemented + 1 opt-in/postponed）

```
binance.market.{product_line}.ticker.v1
binance.market.{product_line}.force_order.v1
binance.market.{product_line}.open_interest.v1
binance.market.{product_line}.index_reference.v1
binance.market.{product_line}.contract_info.v1
```

> [COMPUTED, HIGH] `ticker`、`open_interest`、`index_reference`、`contract_info` 已完成 local runtime chain；`force_order` 仅为独立 opt-in scaffold，默认不订阅，仍需 release owner/live gate。NATS wildcard 允许 canonical subject，但 unsupported/postponed product-line 组合不得产生消息。

### 3.3 Control Subjects（FR-012 / FR-024）

| Subject | 触发 | 消费方 | 说明 |
|---|---|---|---|
| `binance.control.instruments.changed` | client 每 6h 刷新 exchangeInfo 发现合约目录变更 | server | 触发 server 重读 instrument catalog（FR-012） |
| `binance.control.symbols.changed` | `POST /api/v1/admin/symbols/reload` 应用白黑名单 diff | client | client 增减 active stream，不重启进程（FR-024） |

> [COMPUTED, HIGH] control subjects 不属于 4×11 market 矩阵，是独立控制面 subject；用 `binance.control.*` 前缀与 `binance.market.*.*.v1` 区分。

## 4. Kafka Topic Matrix

格式：`binance.{product_line}.{event_type}.v1`

### 4.1 已实现 topics

| product_line | 已实现 event_types |
|---|---|
| `spot` | `book_ticker`, `trade`, `kline`, `depth_update` |
| `um_perp` | `book_ticker`, `trade`, `kline`, `depth_update`, `funding_rate`, `mark_price_update` |
| `cm_perp` | `book_ticker`, `trade`, `kline`, `depth_update`, `funding_rate`, `mark_price_update` |
| `options` | `trade`, `kline`, `depth_update`, `option_tick` |

### 4.2 计划 topics（待 FR 驱动）

```
binance.{product_line}.ticker.v1
binance.{product_line}.force_order.v1
binance.{product_line}.open_interest.v1
binance.{product_line}.index_reference.v1
binance.{product_line}.contract_info.v1
```

### 4.3 Consumer Groups

```
signal_engine  risk_engine  backtestx  market_regime
```

## 5. TDengine Naming

| 层级 | 格式 | 示例 |
|---|---|---|
| Database | `binance_market` | `binance_market` |
| Supertable | `{event_type}` (无前缀) | `book_ticker`, `trade`, `kline`, `depth_update`, `funding_rate`, `mark_price_update`, `option_tick` |
| Subtable | `{event_type}_{product_line}_{symbol_slug}` | `book_ticker_spot_btcusdt` |
| Tags | `exchange`, `product_line`, `symbol`, `event_type` | `binance`, `um_perp`, `BTCUSDT`, `mark_price_update` |

> [COMPUTED, HIGH] v3.18.0 去掉 `st_` 前缀和 `binance_` 前缀——TDengine 靠 `CREATE STABLE` 语法区分超级表，前缀是实现细节泄漏。Supertable 名 = canonical event_type（1:1），与 NATS subject `event_type` 段、Binance 原生事件名 snake_case 完全一致。迁移通过 `ALTER STABLE ... RENAME TO ...` 执行，详见 [EVENT-TYPE-MAPPING.md](../design/EVENT-TYPE-MAPPING.md) §2.4。

### 5.1 Extended stable 表（已建立 local schema；发布仍受 external gate 约束）

| supertable | event_type | Binance 原生 |
|---|---|---|
| `ticker` | `ticker` | `24hrTicker`/`24hrMiniTicker` |
| `force_order` | `force_order` | `forceOrder` |
| `open_interest` | `open_interest` | `openInterest` |
| `index_reference` | `index_reference` | `compositeIndex`/`assetIndex`/`avgPrice`/`referencePrice` |
| `contract_info` | `contract_info` | `contractInfo` |

## 6. Redis Key Naming

| 用途 | 格式 | TTL |
|---|---|---|
| 最新事件缓存 | `binance:{event_type}:{product_line}:{symbol}` | book_ticker/trade/kline/funding_rate/mark_price_update/option_tick 60s；depth_update 5s |
| 幂等标记 | `binance:idem:{idempotency_key}` | 72h |
| 分布式锁 | `binance:lock:{scope}` | 30s lease |
| 限流桶 | `binance:ratelimit:{endpoint}:{token}` | 1s |

> [COMPUTED, HIGH] `{event_type}` 段使用 §2.1 canonical 名称。幂等键维度详见 [EVENT-TYPE-MAPPING.md](../design/EVENT-TYPE-MAPPING.md) §5。

## 7. REST Endpoint Naming

| endpoint | event_type | legacy path |
|---|---|---|
| `GET /api/v1/market/book_ticker/:symbol` | `book_ticker` | ~~`/ticks/:symbol`~~ |
| `GET /api/v1/market/book_ticker/:symbol/range` | `book_ticker` | ~~`/ticks/:symbol/range`~~ |
| `GET /api/v1/market/trade/:symbol` | `trade` | ~~`/trades/:symbol`~~ |
| `GET /api/v1/market/kline/:symbol` | `kline` | ~~`/bars/:symbol`~~ |
| `GET /api/v1/market/kline/:symbol/range` | `kline` | ~~`/bars/:symbol/range`~~ |
| `GET /api/v1/market/depth_update/:symbol` | `depth_update` | ~~`/depth/:symbol`~~ |
| `GET /api/v1/market/funding_rate/:symbol` | `funding_rate` | ~~`/funding-rate/:symbol`~~ |
| `GET /api/v1/market/mark_price_update/:symbol` | `mark_price_update` | ~~`/mark-price/:symbol`~~ |

> [CONVENTION] REST API URL 路径统一使用 snake_case，与 product_line / event_type / subject / topic / TDengine / Redis / OSS / ENV 全命名面一致。优先于 RFC 3986 kebab-case 惯例：本模块命名一致性优先于通用 REST 风格指南。路径段 = event_type（singular），与 NATS subject / Kafka topic / TDengine supertable 1:1 对齐。

## 8. OSS Path Naming

格式：`binance/{product_line}/{symbol}/{YYYY}/{MM}/{DD}/{event_type}.parquet`

示例：

```text
binance/spot/BTCUSDT/2026/06/23/book_ticker.parquet
binance/um_perp/BTCUSDT/2026/06/23/funding_rate.parquet
binance/cm_perp/BTCUSD_PERP/2026/06/23/mark_price_update.parquet
```

## 9. PostgreSQL Table Naming

| 用途 | 表名 | 说明 |
|---|---|---|
| 合约元数据 | `catalog_symbols` | 合约目录（FR-006b, FR-050） |
| 白名单 | `whitelist`, `whitelist_meta`, `whitelist_sync_log` | 白名单三层表（FR-046） |
| 幂等日志 | `binance_idempotency_log` | 幂等持久备份（FR-005） |
| 审计日志 | `audit_log` | 操作审计（FR-015） |
| 流会话 | `binance_stream_sessions` | 流状态跟踪 |
| 时钟偏移 | `binance_clock_offsets` | 时钟同步 |
| 采集状态 | `binance_ingest_status` | 采集状态 |

> [COMPUTED, HIGH] PostgreSQL 表名不使用 canonical event_type——这些是操作型/元数据表，不是事件流表。命名使用 `binance_` 前缀 + 描述性名称，或 domain_market 标准表名（`catalog_symbols`, `whitelist`）。

## 10. ClickHouse Table Naming

| 用途 | 表名 | 说明 |
|---|---|---|
| OLAP 数据库 | `market_binance` | ClickHouse 库名 |
| 1 分钟 OHLCV | `binance_ohlcv_1m` | 从 TDengine 聚合的 1m K 线 |
| 5 分钟 VWAP | `binance_vwap_5m` | 跨符号 VWAP 聚合 |
| 15 分钟统计 | `binance_stats_15m` | 统计聚合 |

> [COMPUTED, HIGH] ClickHouse 表名不使用 canonical event_type——这些是派生分析聚合表，不是原始事件流存储。命名使用 `binance_{聚合类型}_{窗口}` 格式。原始事件存储由 TDengine 承载（§5）。

## 11. Environment Variable Naming

| 范围 | 格式 | 示例 |
|---|---|---|
| client + server | `XGO_BINANCE_{NAME}` | `XGO_BINANCE_INGEST_URL`, `XGO_BINANCE_ADMIN_ADDR` |
| 基础设施凭据 | 各模块规范前缀 | `XGO_REDIS_PASSWORD`, `XGO_KAFKA_PASSWORD` |

## 12. Drift Detection

```bash
# 旧 event_type 名残留检测（期望 0 命中，排除 legacy alias 标注和归档）
rg -n '\btick\b' module/binance --glob '*.md' | rg -v 'legacy|~~|archive|CHANGELOG|NAMING|RUNTIME-GAP|DATA-INTEGRITY|2026070'
rg -n '\bbar\b' module/binance --glob '*.md' | rg -v 'legacy|~~|archive|CHANGELOG|NAMING|bar_|bar\.|subscribe|Bar|crossbar'
rg -n '\bdepth\b' module/binance --glob '*.md' | rg -v 'legacy|~~|archive|CHANGELOG|NAMING|depth_update|depth\.|Depth|depth_'
rg -n '\bmark_price\b' module/binance --glob '*.md' | rg -v 'legacy|~~|archive|CHANGELOG|NAMING|mark_price_update|MarkPrice'

# 旧 product_line 别名检测
rg -n 'usdm_futures|coinm_futures|futures_usdt|futures_coin' module/binance
rg -n '\boption\b|\bopts\b' module/binance --glob '*.md' | rg -v 'options|Options'

# 旧 TDengine 表名检测
rg -n 'st_tick|st_bar|st_depth|st_mark_price|st_trade|st_funding_rate' module/binance --glob '*.md' | rg -v 'legacy|~~|archive|CHANGELOG|RUNTIME-GAP|DATA-INTEGRITY|ALTER STABLE'

# 旧 REST path 检测
rg -n '/ticks/|/bars/|/funding-rate/|/mark-price/' module/binance --glob '*.md' | rg -v 'legacy|~~|archive|CHANGELOG|NAMING|RUNTIME-GAP|DEEP-ANALYSIS'
```

## 13. Change History

| Date | Version | Change |
|---|---|---|
| 2026-07-06 | v3.18.0 | **canonical 命名对齐 Binance 原生事件名**：§2 event_type 6→11（6 implemented rename + 5 planned）；§3 NATS subject 全量更新；§4 Kafka topic 全量更新；§5 TDengine supertable 去掉 `st_`/`binance_` 前缀，= canonical event_type；§6 Redis key 更新 event_type；§7 REST endpoint 路径段 = event_type（singular snake_case）；§8 OSS path 更新 event_type；新增 §9 PostgreSQL table naming；新增 §10 ClickHouse table naming；§12 drift detection 更新。 |
| 2026-06-23 | v3.3.1 | 新增 §1.1 `instrument_subtype`（perpetual/delivery）维度，修订 §1 um_perp/cm_perp 语义注释为"合约（永续 + 交割）"；补 §10 drift detection。语义澄清，无 subject/topic/path 格式变更。 |
| 2026-06-23 | v3.3.0 | 版本号统一：Doc-Version → Module-Version，对齐 root SPEC v3.3.0；补 §2.1 bar 订阅周期集 + §3.1 control subjects。 |
| 2026-06-23 | v2.0.0 | MAJOR taxonomy fold：event_type 从 4 扩为 6，新增 `funding_rate`、`mark_price`；natsx subject 与 Kafka topic 扩为 4 × 6。 |
| 2026-06-22 | v1.0.0 | 建立 product_line、event_type、subject/topic 命名 SSOT。 |
