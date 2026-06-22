# module/binance NAMING.md — 命名权威 SSOT

- Doc-Version: v1.0.0
- Last-Updated: 2026-06-22
- 权威性：本文件为 `module/binance/` 全部命名的 **Single Source of Truth**。任何子规格、task、runtime 代码、CI gate 与本文冲突时，**以本文为准**。
- 适用范围：`module/binance/` 全部规格 + `github.com/ZoneCNH/binance` runtime 仓全部代码

> 历史背景：2026-06-22 治理审计发现 `usdm_futures/coinm_futures`、`um_perp/cm_perp`、`futures_usdt/futures_coin` 4 套不兼容命名分散在 5 处，击穿 NATS subject / Redis key / TDengine tag / Kafka topic / Gin API 五条管线一致性。本文建立后命名漂移视为治理违规（RULES.md R1）。

---

## 1. product_line 枚举（4 值唯一合法）

| 合法值    | 含义                                                                     | 历史别名（已废弃）              |
| --------- | ------------------------------------------------------------------------ | ------------------------------- |
| `spot`    | Binance 现货                                                             | —                               |
| `um_perp` | USDⓈ-Margined Perpetuals（USDT/USDC 保证金永续，含未来 USDⓈ-M Delivery） | `usdm_futures`、`futures_usdt`  |
| `cm_perp` | COIN-Margined Perpetuals（币本位永续，含未来 COIN-M Delivery）           | `coinm_futures`、`futures_coin` |
| `options` | Binance EOptions                                                         | `option`、`opts`                |

**强制约束：**

- snake_case，全小写
- 子规格、task、wire envelope、Redis key、TDengine tag、Kafka topic、Gin API 参数、Go enum 全部使用以上 4 值
- runtime 代码中 `string` 类型的 `product_line` 字段必须通过同名 Go enum/常量赋值，**禁止内嵌字符串字面量**

---

## 2. event_type 枚举（4 值唯一合法）

| 合法值  | 含义                                  | 适用产品线                                   |
| ------- | ------------------------------------- | -------------------------------------------- |
| `tick`  | 行情快照（含 best bid/ask、24h 统计） | 全部 4 条                                    |
| `trade` | 成交流（逐笔）                        | 全部 4 条                                    |
| `bar`   | K 线（多周期）                        | 全部 4 条                                    |
| `depth` | 订单簿深度（增量 + 快照）             | 全部 4 条（Options 用 `<symbol>@depth1000`） |

**强制约束：4 × 4 对称矩阵无缺口**（违反此规则即触发 RULES R2）

---

## 3. natsx Subject 命名

格式：`binance.market.{product_line}.{event_type}`

| product_line | tick                          | trade                          | bar                          | depth                          |
| ------------ | ----------------------------- | ------------------------------ | ---------------------------- | ------------------------------ |
| spot         | `binance.market.spot.tick`    | `binance.market.spot.trade`    | `binance.market.spot.bar`    | `binance.market.spot.depth`    |
| um_perp      | `binance.market.um_perp.tick` | `binance.market.um_perp.trade` | `binance.market.um_perp.bar` | `binance.market.um_perp.depth` |
| cm_perp      | `binance.market.cm_perp.tick` | `binance.market.cm_perp.trade` | `binance.market.cm_perp.bar` | `binance.market.cm_perp.depth` |
| options      | `binance.market.options.tick` | `binance.market.options.trade` | `binance.market.options.bar` | `binance.market.options.depth` |

**权威来源**：`module/binance/SPEC.md` §9 + `module/binance/RUNTIME-MAPPING.md` §natsx subject 表

---

## 4. Kafka Topic 命名

格式：`binance.{product_line}.{event_type}.v1`

| product_line | tick                      | trade                      | bar                      | depth                      |
| ------------ | ------------------------- | -------------------------- | ------------------------ | -------------------------- |
| spot         | `binance.spot.tick.v1`    | `binance.spot.trade.v1`    | `binance.spot.bar.v1`    | `binance.spot.depth.v1`    |
| um_perp      | `binance.um_perp.tick.v1` | `binance.um_perp.trade.v1` | `binance.um_perp.bar.v1` | `binance.um_perp.depth.v1` |
| cm_perp      | `binance.cm_perp.tick.v1` | `binance.cm_perp.trade.v1` | `binance.cm_perp.bar.v1` | `binance.cm_perp.depth.v1` |
| options      | `binance.options.tick.v1` | `binance.options.trade.v1` | `binance.options.bar.v1` | `binance.options.depth.v1` |

**Schema 演进**：版本后缀（`.v1`/`.v2`）通过 Schema Registry 管理；topic 删除走 ADR 流程

---

## 5. TDengine 超表 + Tag 命名

**超表（stable）**：

| event_type | stable name             |
| ---------- | ----------------------- |
| tick       | `binance_market_ticks`  |
| trade      | `binance_market_trades` |
| bar        | `binance_market_bars`   |
| depth      | `binance_market_depth`  |

**Tag 列（全部超表共用）**：

```sql
TAGS (
  symbol      VARCHAR(32),  -- 原始 Binance symbol，如 "BTCUSDT"
  product_line VARCHAR(16)  -- spot / um_perp / cm_perp / options
)
```

**子表名**：`{stable}_{product_line}_{symbol_lower}`，例如 `binance_market_ticks_um_perp_btcusdt`

---

## 6. Redis Key 命名

格式：`binance:{event_type}:{product_line}:{symbol}`

| 类型        | 示例                                                   |
| ----------- | ------------------------------------------------------ |
| tick 缓存   | `binance:tick:spot:BTCUSDT`                            |
| trade 缓存  | `binance:trade:um_perp:BTCUSDT`                        |
| bar 缓存    | `binance:bar:cm_perp:BTCUSD_PERP`                      |
| depth 缓存  | `binance:depth:options:BTC-260626-50000-C`             |
| dedup SetNX | `binance:dedup:{product_line}:{event_type}:{event_id}` |
| 分布式锁    | `binance:lock:{resource}`                              |

**TTL**：tick=60s、trade=5s、bar=按周期 ×2、depth=5s、dedup=1h

---

## 7. ossx 归档路径命名

格式：`binance/{product_line}/{event_type}/{yyyy}/{mm}/{dd}/{hh}/{file}.{format}`

| 示例                                                             |
| ---------------------------------------------------------------- |
| `binance/spot/tick/2026/06/22/14/btcusdt.parquet`                |
| `binance/um_perp/depth/2026/06/22/14/btcusdt.parquet`            |
| `binance/cm_perp/bar/2026/06/22/btcusd_perp_1m.parquet`          |
| `binance/options/depth/2026/06/22/14/BTC-260626-50000-C.parquet` |

**强制约束**：4 产品线 × 4 event_type 路径前缀必须全部存在（即使当前 task 未实现）

---

## 8. Gin REST API 路径

格式：`/api/v1/market/{event_type}/{symbol}?product_line={product_line}`

| 端点  | 示例                                                               |
| ----- | ------------------------------------------------------------------ |
| tick  | `GET /api/v1/market/ticks/BTCUSDT?product_line=spot`               |
| depth | `GET /api/v1/market/depth/BTCUSDT?product_line=um_perp`            |
| bar   | `GET /api/v1/market/bars/BTCUSDT?product_line=cm_perp&interval=1m` |
| trade | `GET /api/v1/market/trades/BTCUSDT?product_line=options`           |

**响应 envelope**：统一使用 `domain_market.MarketEvent` JSON 编码，`product_line` 字段使用本文 §1 枚举

---

## 9. Go 文件名与包结构

| 路径                   | 命名                                                      |
| ---------------------- | --------------------------------------------------------- |
| client connector       | `internal/client/{product_line}/connector.go`             |
| client parser          | `internal/client/{product_line}/parser.go`                |
| client publisher       | `internal/client/{product_line}/publisher.go`             |
| server consumer        | `internal/server/consumer/{product_line}/{event_type}.go` |
| server storage adapter | `internal/server/storage/{infra}/binance_{stable}.go`     |

**强制约束**：文件名全部 snake_case；禁止 `usdm_futures.go`、`coinm.go` 等历史别名

---

## 10. 环境变量与配置键名

格式：`BINANCE_{COMPONENT}_{KEY}`（全大写、snake_case）

| 示例                            |
| ------------------------------- |
| `BINANCE_CLIENT_NATSX_URL`      |
| `BINANCE_SERVER_TAOSX_DSN`      |
| `BINANCE_SERVER_REDISX_ADDR`    |
| `BINANCE_SERVER_KAFKAX_BROKERS` |

配置文件 YAML 键使用 snake_case：`product_line`、`event_type`、`nats_subject`，**禁止** camelCase 或 PascalCase

---

## 11. 命名漂移检测命令

```bash
# 1. 旧 product_line 别名扫描（反向过滤变更历史与例外文档）
grep -rE "(usdm_futures|coinm_futures|futures_usdt|futures_coin)" module/binance/ \
  | grep -vE "NAMING\.md|RULES\.md|ARCHITECTURE-DRIFT|历史别名|废弃|archive/|命名同步|命名收敛|旧命名"

# 2. natsx subject 不规范扫描
grep -rE "binance\.market\.[a-z_]+\." module/binance/ | grep -vE "binance\.market\.(spot|um_perp|cm_perp|options)\.(tick|trade|bar|depth)"

# 3. Kafka topic 不规范扫描
grep -rE "binance\.[a-z_]+\.[a-z]+\.v[0-9]" module/binance/ | grep -vE "binance\.(spot|um_perp|cm_perp|options)\.(tick|trade|bar|depth)\.v1"

# 4. Redis key 不规范扫描
grep -rE "binance:[a-z]+:[a-z_]+:" module/binance/ | grep -vE "binance:(tick|trade|bar|depth|dedup|lock):(spot|um_perp|cm_perp|options):"
```

期望：以上 4 条命令返回 0 行（命中均视为治理违规，触发 RULES R1）

---

## 12. 变更历史

| 日期       | 版本   | 变更内容                                                                                                                   | 作者    |
| ---------- | ------ | -------------------------------------------------------------------------------------------------------------------------- | ------- |
| 2026-06-22 | v1.0.0 | 首次建立。整合 SPEC §9 natsx subject 表 + RUNTIME-MAPPING + 各 task 命名约定，统一为 4 产品线 × 4 event_type 对称矩阵 SSOT | ZoneCNH |
