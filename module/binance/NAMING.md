# module/binance NAMING.md — 命名 SSOT

- Doc-Version: v2.0.0
- Last-Updated: 2026-06-23
- Applies-To: `module/binance/SPEC.md` v3.0.0, `module/binance/RULES.md` v2.0.0
- Scope: product_line、event_type、natsx subject、Kafka topic、TDengine stable、Redis key、REST endpoint、OSS path

> [COMPUTED, HIGH] 本文件是 `module/binance` 命名权威入口。所有新增规格、任务和 runtime 代码必须使用本文件的 canonical token；历史别名只允许出现在本文件、治理报告、漂移清单和归档 task 中。

---

## 1. Canonical Product Line

| product_line | 含义 | 历史别名（禁止新用） |
|---|---|---|
| `spot` | 现货 | `cash`, `spot_market` |
| `um_perp` | USDⓈ-M 永续 | `usdm`, `usdm_futures`, `futures_usdt` |
| `cm_perp` | COIN-M 永续 | `coinm`, `coinm_futures`, `futures_coin` |
| `options` | 期权 | `option`, `opts` |

## 2. Canonical Event Type

| event_type | 含义 | 主要来源 |
|---|---|---|
| `tick` | 最优价/最新行情快照 | WS ticker / bookTicker |
| `trade` | 逐笔或聚合成交 | WS trade / aggTrade |
| `bar` | K 线 | WS kline / REST klines |
| `depth` | 深度快照或增量 | WS depth / REST depth |
| `funding_rate` | 资金费率与 funding 信息 | futures mark price / fundingInfo |
| `mark_price` | 标记价格 | futures mark price stream |

> [COMPUTED, HIGH] v3.0.0 起 product_line × event_type 为 **4 × 6** 对称矩阵，共 24 个规范组合。即使交易所暂不提供某产品线的某事件，命名层仍保留组合，runtime 可用 capability/status 标识暂不产出。

## 3. natsx Subject Matrix

格式：`binance.market.{product_line}.{event_type}`

| product_line | tick | trade | bar | depth | funding_rate | mark_price |
|---|---|---|---|---|---|---|
| `spot` | `binance.market.spot.tick` | `binance.market.spot.trade` | `binance.market.spot.bar` | `binance.market.spot.depth` | `binance.market.spot.funding_rate` | `binance.market.spot.mark_price` |
| `um_perp` | `binance.market.um_perp.tick` | `binance.market.um_perp.trade` | `binance.market.um_perp.bar` | `binance.market.um_perp.depth` | `binance.market.um_perp.funding_rate` | `binance.market.um_perp.mark_price` |
| `cm_perp` | `binance.market.cm_perp.tick` | `binance.market.cm_perp.trade` | `binance.market.cm_perp.bar` | `binance.market.cm_perp.depth` | `binance.market.cm_perp.funding_rate` | `binance.market.cm_perp.mark_price` |
| `options` | `binance.market.options.tick` | `binance.market.options.trade` | `binance.market.options.bar` | `binance.market.options.depth` | `binance.market.options.funding_rate` | `binance.market.options.mark_price` |

## 4. Kafka Topic Matrix

格式：`binance.{product_line}.{event_type}.v1`

| product_line | tick | trade | bar | depth | funding_rate | mark_price |
|---|---|---|---|---|---|---|
| `spot` | `binance.spot.tick.v1` | `binance.spot.trade.v1` | `binance.spot.bar.v1` | `binance.spot.depth.v1` | `binance.spot.funding_rate.v1` | `binance.spot.mark_price.v1` |
| `um_perp` | `binance.um_perp.tick.v1` | `binance.um_perp.trade.v1` | `binance.um_perp.bar.v1` | `binance.um_perp.depth.v1` | `binance.um_perp.funding_rate.v1` | `binance.um_perp.mark_price.v1` |
| `cm_perp` | `binance.cm_perp.tick.v1` | `binance.cm_perp.trade.v1` | `binance.cm_perp.bar.v1` | `binance.cm_perp.depth.v1` | `binance.cm_perp.funding_rate.v1` | `binance.cm_perp.mark_price.v1` |
| `options` | `binance.options.tick.v1` | `binance.options.trade.v1` | `binance.options.bar.v1` | `binance.options.depth.v1` | `binance.options.funding_rate.v1` | `binance.options.mark_price.v1` |

## 5. TDengine Naming

| 层级 | 格式 | 示例 |
|---|---|---|
| Database | `binance_market` | `binance_market` |
| Supertable | `binance_{event_type}` | `binance_tick`, `binance_trade`, `binance_bar`, `binance_depth`, `binance_funding_rate`, `binance_mark_price` |
| Subtable | `binance_{event_type}_{product_line}_{symbol_slug}` | `binance_tick_spot_btcusdt` |
| Tags | `exchange`, `product_line`, `symbol`, `event_type` | `binance`, `um_perp`, `BTCUSDT`, `mark_price` |

## 6. Redis Key Naming

| 用途 | 格式 | TTL |
|---|---|---|
| 最新事件缓存 | `binance:{event_type}:{product_line}:{symbol}` | tick/trade/bar/funding_rate/mark_price 60s；depth 5s |
| 幂等标记 | `binance:idem:{idempotency_key}` | 72h |
| 分布式锁 | `binance:lock:{scope}` | 30s lease |
| 限流桶 | `binance:ratelimit:{endpoint}:{token}` | 1s |

## 7. REST Endpoint Naming

| endpoint | 事件 |
|---|---|
| `GET /api/v1/market/ticks/:symbol` | `tick` |
| `GET /api/v1/market/ticks/:symbol/range` | `tick` |
| `GET /api/v1/market/trades/:symbol` | `trade` |
| `GET /api/v1/market/bars/:symbol` | `bar` |
| `GET /api/v1/market/bars/:symbol/range` | `bar` |
| `GET /api/v1/market/depth/:symbol` | `depth` |
| `GET /api/v1/market/funding-rates/:symbol` | `funding_rate` |
| `GET /api/v1/market/mark-prices/:symbol` | `mark_price` |

## 8. OSS Path Naming

格式：`binance/{product_line}/{symbol}/{YYYY}/{MM}/{DD}/{event_type}.parquet`

示例：

```text
binance/spot/BTCUSDT/2026/06/23/tick.parquet
binance/um_perp/BTCUSDT/2026/06/23/funding_rate.parquet
binance/cm_perp/BTCUSD_PERP/2026/06/23/mark_price.parquet
```

## 9. Environment Variable Naming

| 范围 | 格式 | 示例 |
|---|---|---|
| client | `BINANCE_CLIENT_{NAME}` | `BINANCE_CLIENT_NATS_URL` |
| server | `BINANCE_SERVER_{NAME}` | `BINANCE_SERVER_REDIS_URL` |
| product line enable | `BINANCE_ENABLE_{PRODUCT_LINE}` | `BINANCE_ENABLE_UM_PERP` |

## 10. Drift Detection

```bash
rg -n 'usdm_futures|coinm_futures|futures_usdt|futures_coin|\\boption\\b|\\bopts\\b' module/binance
rg -n 'binance\\.market\\.(ticks|bars|depth|events)\\b' module/binance
rg -n '4 × [4]|16 × 5 = [8]0' module/binance/NAMING.md module/binance/RULES.md module/binance/server/tasks/TASK-BINANCE-SERVER-014-kafkax-dispatch.md
rg -n 'funding\\b' module/binance | rg -v 'funding_rate|fundingInfo|funding-rates'
```

## 11. Change History

| Date | Version | Change |
|---|---|---|
| 2026-06-23 | v2.0.0 | MAJOR taxonomy fold：event_type 从 4 扩为 6，新增 `funding_rate`、`mark_price`；natsx subject 与 Kafka topic 扩为 4 × 6。 |
| 2026-06-22 | v1.0.0 | 建立 product_line、event_type、subject/topic 命名 SSOT。 |
