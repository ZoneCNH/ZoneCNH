# Binance Event Type Mapping

> 状态：Reference
> 来源：report/binance/20260704.md + SPEC v4.0.0 §6 + client SPEC §FR-005
> Last-Updated: 2026-07-07

## 1. Classification Criteria

`[INFERRED]` 在做 Binance 原生事件 → canonical event_type 映射之前，先确立分类判据。对每个事件问 4 个问题：

| #   | 问题                                                              | 判定                                              | 意义                                         |
| --- | ----------------------------------------------------------------- | ------------------------------------------------- | -------------------------------------------- |
| Q1  | 有没有全局唯一、不可变的 ID？（如 trade 的 `t`、aggTrade 的 `a`） | 有 → **事件型**，可去重、可计数、可审计           | 事件型数据丢一条就是丢一条，不能靠下一条覆盖 |
| Q2  | 是不是"当前值快照"？（新的一条整体覆盖旧的，不是叠加）            | 是 → **状态型**，覆盖式写入                       | 状态型数据丢一条不影响下一条正确性（自愈）   |
| Q3  | 是不是连接层控制信号，本身不携带业务数据？                        | 是 → **传输层**，不进业务映射表                   | 映射成任何业务类型都是语义错误               |
| Q4  | 是不是"风险提示/非权威参考"，官方明确不能做交易依据？             | 是 → **需独立打标**，不能混入正式行情接入策略引擎 | 混入会导致下游策略基于非权威数据做决策       |

**核心原则**：映射的依据是语义结构（有没有 ID、是增量还是快照、用途是什么），不是"字段长得像不像"。`forceOrder` 和 `trade` 都有 price/qty，但 `forceOrder` 无 orderId/tradeId、每 symbol 1000ms 只推最新一笔、是强平事件而非正常成交——硬塞进 `trade` 会导致下游 VWAP/成交量统计系统性偏低且无报错。

## 2. Canonical Event Types

`[KNOWN]` SPEC §6 定义 canonical event_type 枚举。v3.18.0 将 canonical 命名对齐 Binance 原生事件名（camelCase → snake_case），消除自创名。

### 2.0 命名规则

| 规则           | 说明                                                  | 示例                                                                                 |
| -------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------ |
| **1:1 映射**   | canonical = Binance 原生事件名转 snake_case           | `bookTicker` → `book_ticker`、`depthUpdate` → `depth_update`                         |
| **多事件聚合** | 取 Binance 事件名的公共词干                           | `24hrTicker`/`24hrMiniTicker` → `ticker`                                             |
| **派生类型**   | Binance 无独立事件、从 payload 字段提取的，保留自命名 | `funding_rate`（从 `markPriceUpdate` 的 `r` 字段提取）                               |
| **语义分组**   | 多个 Binance 事件共享语义分类但无公共词干，使用分组名 | `index_reference`（`compositeIndex` + `assetIndex` + `avgPrice` + `referencePrice`） |

### 2.1 已实现类型（runtime 已装配，v3.18.0 命名对齐）

| canonical (v3.18.0) | legacy alias     | 语义分类 | 用途                                        | Binance 原生         | 幂等键维度                                                      |
| ------------------- | ---------------- | -------- | ------------------------------------------- | -------------------- | --------------------------------------------------------------- |
| `book_ticker`       | ~~`tick`~~       | 状态型   | 最优买卖价，实时盘口快照                    | `bookTicker`         | `{exchange}:{pl}:{symbol}:book_ticker:{event_time}:{bid}:{ask}` |
| `kline`             | ~~`bar`~~        | 状态型   | K 线 OHLCV 当前完整状态                     | `kline`              | `{exchange}:{pl}:{symbol}:kline:{interval}:{open_time}`         |
| `depth_update`      | ~~`depth`~~      | 增量型   | 订单簿增量，需 U/u 序号连续性校验           | `depthUpdate`        | `{exchange}:{pl}:{symbol}:depth_update:{U}:{u}`                 |
| `trade`             | —                | 事件型   | 成交，有全局唯一 ID                         | `aggTrade` / `trade` | `{exchange}:{pl}:{symbol}:trade:{trade_id}`                     |
| `funding_rate`      | —                | 状态型   | 资金费率（从 markPriceUpdate `r` 字段提取） | (派生)               | `{exchange}:{pl}:{symbol}:funding_rate:{funding_time}`          |
| `mark_price_update` | ~~`mark_price`~~ | 状态型   | 标记价格                                    | `markPriceUpdate`    | `{exchange}:{pl}:{symbol}:mark_price_update:{event_time}`       |

> **Migration（implemented 类型 4 个 rename）**：NATS subject `binance.market.{pl}.{event_type}.v1` 中的 `event_type` 需同步改名；TDengine super table（`st_tick`→`book_ticker`、`st_bar`→`kline`、`st_depth`→`depth_update`、`st_mark_price`→`mark_price_update`，同时去掉 `st_` 前缀）；idempotency key 格式变更。属于 runtime MAJOR 版本迁移，由独立 FR + migration plan 承接，不在本文档仓执行。迁移期间 NATS subject 可双发（新旧名同时发布）过渡。

### 2.2 新增类型（planned，设计层定义，runtime 待 FR 驱动）

| canonical (v3.18.0) | 语义分类         | 用途                                          | Binance 原生                                                 | 不能套用现有类型的理由                                                                                                                             |
| ------------------- | ---------------- | --------------------------------------------- | ------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ticker`            | 状态型           | 滚动窗口统计行情                              | `24hrTicker`, `24hrMiniTicker`, rolling window ticker        | 与 `book_ticker`（实时盘口快照）语义不同：ticker 是窗口聚合统计。混用会让下游误把 24h 涨跌幅当实时价格用                                           |
| `force_order`       | 事件型（不完整） | 强平单流                                      | `forceOrder`                                                 | **绝不映射成 `trade`**：无 orderId/tradeId，每 symbol 1000ms 只推最新一笔，天然丢笔数。混入 trade 会导致总成交量系统性偏低且无报错——最危险的误映射 |
| `open_interest`     | 状态型           | 持仓量（张数+名义价值）                       | `openInterest`                                               | 量纲与价格/成交量不同，混进 ticker 会导致 schema 语义混乱                                                                                          |
| `index_reference`   | 状态型           | 指数/参考价（多资产换算、强平参考、移动均价） | `compositeIndex`, `assetIndex`, `avgPrice`, `referencePrice` | 不是行情展示数据，用途在风控/保证金计算层。`avgPrice` 是给强平/保证金计算用的移动平均参考价，不是给展示用的行情                                    |
| `contract_info`     | 事件型（低频）   | 合约元数据变更通知                            | `contractInfo`                                               | 低频事件驱动（上新/结算/分级变更才推），与 FR-031~036 REST ExchangeInfo 互补                                                                       |

### 2.3 传输层信号（不进业务枚举）

| 信号           | 处理方式                                 | 理由                                                    |
| -------------- | ---------------------------------------- | ------------------------------------------------------- |
| serverShutdown | WS reconnect 层拦截，触发"停止消费+重连" | 不携带任何行情/账户语义，映射成任何业务类型都是语义错误 |

### 2.4 TDengine Super Table 命名

`[KNOWN]` TDengine super table 名 = canonical event*type（与 NATS subject `event_type` 段、Binance 原生事件名 snake_case 完全一致）。不加 `st*`前缀——TDengine 靠`CREATE STABLE` 语法区分超级表，不靠名字前缀；前缀是实现细节泄漏。

#### 已实现表（runtime 已建，v3.18.0 命名对齐）

| table (v3.18.0)     | legacy table          | event_type          | Binance 原生       | 迁移操作                                                 |
| ------------------- | --------------------- | ------------------- | ------------------ | -------------------------------------------------------- |
| `book_ticker`       | ~~`st_tick`~~         | `book_ticker`       | `bookTicker`       | `ALTER STABLE st_tick RENAME TO book_ticker`             |
| `kline`             | ~~`st_bar`~~          | `kline`             | `kline`            | `ALTER STABLE st_bar RENAME TO kline`                    |
| `depth_update`      | ~~`st_depth`~~        | `depth_update`      | `depthUpdate`      | `ALTER STABLE st_depth RENAME TO depth_update`           |
| `mark_price_update` | ~~`st_mark_price`~~   | `mark_price_update` | `markPriceUpdate`  | `ALTER STABLE st_mark_price RENAME TO mark_price_update` |
| `trade`             | ~~`st_trade`~~        | `trade`             | `aggTrade`/`trade` | `ALTER STABLE st_trade RENAME TO trade`                  |
| `funding_rate`      | ~~`st_funding_rate`~~ | `funding_rate`      | (派生)             | `ALTER STABLE st_funding_rate RENAME TO funding_rate`    |

#### Planned 表（待 FR 驱动创建）

| table             | event_type        | Binance 原生                                              |
| ----------------- | ----------------- | --------------------------------------------------------- |
| `ticker`          | `ticker`          | `24hrTicker`/`24hrMiniTicker`                             |
| `force_order`     | `force_order`     | `forceOrder`                                              |
| `open_interest`   | `open_interest`   | `openInterest`                                            |
| `index_reference` | `index_reference` | `compositeIndex`/`assetIndex`/`avgPrice`/`referencePrice` |
| `contract_info`   | `contract_info`   | `contractInfo`                                            |

> **Migration（runtime MAJOR）**：6 个 implemented 表统一去掉 `st_` 前缀 + 4 个 rename，通过 TDengine `ALTER STABLE ... RENAME TO ...` 执行；`taos_writer.go` 的 `toPoint()` 路由需同步更新表名常量；`taosDeleteStable()` 需双匹配（legacy + new）过渡期。NATS subject 也需同步改名（见 §2.1 migration note）。属于 runtime MAJOR 版本迁移，由独立 FR + migration plan 承接。

## 3. Binance Native → Canonical Mapping

`[COMPUTED]` 基于 §1 分类判据，对 20 种 Binance 原生行情事件逐一归类：

| Binance 原生事件          | Q1(有ID?) | Q2(快照?) | Q3(传输层?) | Q4(非权威?) | → canonical                          | 子类型/维度                              | 不能套用现有类型的理由                                                                                                                          |
| ------------------------- | --------- | --------- | ----------- | ----------- | ------------------------------------ | ---------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| aggTrade                  | ✓ `a`     | ✗         | ✗           | ✗           | `trade`                              | —                                        | 已正确映射                                                                                                                                      |
| trade                     | ✓ `t`     | ✗         | ✗           | ✗           | `trade`                              | —                                        | 已正确映射                                                                                                                                      |
| kline                     | ✗         | ✓         | ✗           | ✗           | `kline`                              | —                                        | 已正确映射（legacy alias: `bar`）                                                                                                               |
| depthUpdate               | ✓ `U/u`   | ✗(增量)   | ✗           | ✗           | `depth_update`                       | —                                        | 已正确映射（legacy alias: `depth`）                                                                                                             |
| bookTicker                | ✗         | ✓         | ✗           | ✗           | `book_ticker`                        | —                                        | 已正确映射（legacy alias: `tick`）                                                                                                              |
| markPriceUpdate           | ✗         | ✓         | ✗           | ✗           | `mark_price_update` / `funding_rate` | —                                        | 已正确映射（legacy alias: `mark_price`）                                                                                                        |
| **blockTrade**            | ✓ `t`     | ✗         | ✗           | ✗           | `trade`                              | `trade_subtype=block`                    | 大宗/场外成交，价格可能偏离盘口；直接汇入普通成交流做 VWAP/滑点计算会被污染。保留独立 ID 空间，不与 aggTrade/trade 的 ID 混排                   |
| **continuousKline**       | ✗         | ✓         | ✗           | ✗           | `kline`                              | key 从 `symbol` 换成 `pair+contractType` | 主键结构变了（合约到期换 symbol，但 pair+contractType 连续），混表会导致连续合约 K 线展示"断档"。单独一张表或加维度字段                         |
| **indexPriceKline**       | ✗         | ✓         | ✗           | ✗           | `kline`                              | `price_type=index`                       | 必须与 last price kline 物理隔离存储：策略把 index price kline 误当 last price kline 算止损/止盈，会直接导致触发价错误                          |
| **markPriceKline**        | ✗         | ✓         | ✗           | ✗           | `kline`                              | `price_type=mark`                        | 同上，mark price ≠ last price，混用导致触发价错误                                                                                               |
| **24hrTicker**            | ✗         | ✓         | ✗           | ✗           | `ticker`                             | `detail_level=full`                      | 状态型，直接覆盖。与 `book_ticker`（实时盘口快照）语义不同：24h 涨跌幅 ≠ 实时盘口                                                               |
| **24hrMiniTicker**        | ✗         | ✓         | ✗           | ✗           | `ticker`                             | `detail_level=mini`                      | 同上，字段更少                                                                                                                                  |
| **rolling window ticker** | ✗         | ✓         | ✗           | ✗           | `ticker`                             | `window=1h/4h/1d`                        | 与 24hrTicker 同类，用 window 字段区分                                                                                                          |
| **avgPrice**              | ✗         | ✓         | ✗           | ✓(Q4)       | `index_reference`                    | `source=avg_price`                       | 是给强平/保证金计算用的移动平均参考价，不是给展示用的行情。不能塞进 `ticker`——语义用途完全不同                                                  |
| **referencePrice**        | ✗         | ✓         | ✗           | ✓(Q4)       | `index_reference`                    | `source=engine_reference`                | 官方只在极少数新资产上用，当"透传字段"处理，先别固化太具体的业务含义                                                                            |
| **forceOrder**            | ✗(无ID)   | ✗         | ✗           | ✗           | `force_order`                        | —                                        | **绝不映射成 `trade`**：无 orderId/tradeId，每 symbol 1000ms 只推最新一笔，天然丢强平笔数。下游统计总成交量会系统性偏低且无报错——最危险的误映射 |
| **compositeIndex**        | ✗         | ✓         | ✗           | ✓(Q4)       | `index_reference`                    | `index_type=composite`                   | 多资产保证金模式的换算参考，不是行情展示数据，用途在风控层而非行情层                                                                            |
| **assetIndex**            | ✗         | ✓         | ✗           | ✓(Q4)       | `index_reference`                    | `index_type=asset`                       | 同上                                                                                                                                            |
| **contractInfo**          | ✗         | ✓(元数据) | ✗           | ✗           | `contract_info`                      | —                                        | 低频事件驱动（上新/结算/分级变更才推），与 FR-031~036 REST ExchangeInfo 互补                                                                    |
| **openInterest**          | ✗         | ✓         | ✗           | ✗           | `open_interest`                      | —                                        | 单位是"张数+名义价值"，和价格/成交量不是一个量纲，混进 ticker 会让下游 schema 出现语义混乱的字段                                                |
| **serverShutdown**        | ✗         | ✗         | ✓           | ✗           | **传输层**（不进枚举）               | —                                        | 不携带任何行情/账户语义，本质是传输层健康检查信号                                                                                               |

### 3.1 误映射后果速查

`[INFERRED]` 以下列出如果强行套用现有 canonical 类型会造成的实质性后果（不是风格问题，是会算错钱/算错风控的）：

| 误映射                                                 | 后果                                                                  | 严重度               |
| ------------------------------------------------------ | --------------------------------------------------------------------- | -------------------- |
| forceOrder → `trade`                                   | 下游 VWAP/总成交量系统性偏低（1000ms 只推最新一笔，丢笔无报错）       | **致命**             |
| markPriceKline → `kline`（无 price_type 隔离）         | 策略把 mark price kline 误当 last price kline 算止损/止盈，触发价错误 | **致命**             |
| blockTrade → `trade`（无 subtype 区分）                | 大宗成交价格偏离盘口，污染 VWAP/滑点计算                              | **高**               |
| avgPrice → `ticker`                                    | 下游把保证金参考价当行情展示价用，误导用户                            | **高**               |
| continuousKline → `kline`（无 pair+contractType 维度） | 连续合约 K 线在展示上"断档"，主键冲突                                 | **中**               |
| compositeIndex/assetIndex → `ticker`                   | 多资产换算参考被当行情展示数据，风控层与行情层数据混淆                | **中**               |
| openInterest → `ticker`                                | 张数+名义价值混入价格类 schema，量纲不一致                            | **中**               |
| serverShutdown → 任何业务类型                          | 传输层信号被当业务事件落库，产生无意义的"行情"记录                    | **低**（但概念错误） |

## 4. Coverage Matrix — 行情数据流 × 四产品线

`[KNOWN]` 以下为 report/binance/20260704.md §一 的原始覆盖矩阵。✓ = 支持，✗ = 不支持，? = 不确定。

| event_type                       | spot      | um_perp         | cm_perp | options                    | 幂等键建议维度                       |
| -------------------------------- | --------- | --------------- | ------- | -------------------------- | ------------------------------------ |
| aggTrade                         | ✓         | ✓               | ✓       | ✗                          | symbol + a                           |
| trade                            | ✓         | ✗               | ✗       | ✓（underlyingAsset@trade） | symbol + t                           |
| blockTrade                       | ✓（新增） | ✗               | ✗       | ✗                          | symbol + t                           |
| kline                            | ✓         | ✓               | ✓       | ✓                          | symbol + interval + k.t              |
| continuousKline                  | ✗         | ✓               | ✓       | ✗                          | pair + contractType + interval + k.t |
| indexPriceKline / markPriceKline | ✗         | ✓               | ✓       | ✗                          | symbol/pair + interval + k.t         |
| depthUpdate                      | ✓         | ✓               | ✓       | ✓                          | symbol + u，配合 pu 做连续性校验     |
| bookTicker                       | ✓         | ✓               | ✓       | ✗                          | symbol + u                           |
| 24hrTicker / 24hrMiniTicker      | ✓         | ✓               | ✓       | ✓                          | symbol + E                           |
| 滚动窗口 ticker（1h/4h/1d）      | ✓         | ✗               | ✗       | ✗                          | symbol + window + E                  |
| avgPrice                         | ✓         | ✗               | ✗       | ✗                          | symbol + T                           |
| markPriceUpdate                  | ✗         | ✓               | ✓       | ?                          | symbol + E                           |
| forceOrder（强平单）             | ✗         | ✓               | ✓       | ✗                          | symbol + T（每 1000ms 只推最新一笔） |
| compositeIndex                   | ✗         | ✓（多资产模式） | ✗       | ✗                          | symbol + E                           |
| assetIndex                       | ✗         | ✓               | ✗       | ✗                          | assetSymbol + E                      |
| contractInfo                     | ✗         | ✓               | ✓       | ✗                          | symbol + E                           |
| openInterest                     | ✗         | ✗（仅 REST）    | ✗       | ✓                          | symbol（含到期日）+ E                |
| referencePrice                   | ✓（少量） | ✗               | ✗       | ✗                          | symbol + t                           |
| serverShutdown                   | ✓         | ✓               | ✓       | ✓                          | 传输层信号，无需去重                 |

### 4.1 逐产品线覆盖分析

`[COMPUTED]` 基于 §3 映射 + §4 矩阵，按四产品线汇总 canonical event_type 覆盖情况。已实现 = runtime 已装配；planned = 设计层已定义，待 FR 驱动。

#### Spot

| canonical           | 对应 Binance 原生                                             | 状态                            |
| ------------------- | ------------------------------------------------------------- | ------------------------------- |
| `trade`             | aggTrade ✓, trade ✓, blockTrade ✓                             | 已实现（blockTrade 待 planned） |
| `kline`             | kline ✓, continuousKline ✗(spot无), indexPriceKline ✗(spot无) | 已实现                          |
| `depth_update`      | depthUpdate ✓                                                 | 已实现                          |
| `book_ticker`       | bookTicker ✓                                                  | 已实现                          |
| `funding_rate`      | —                                                             | 不适用                          |
| `mark_price_update` | —                                                             | 不适用                          |
| `ticker`            | 24hrTicker ✓, MiniTicker ✓, rolling window ✓                  | planned                         |
| `force_order`       | —                                                             | 不适用（spot 无强平）           |
| `open_interest`     | —                                                             | 不适用                          |
| `index_reference`   | avgPrice ✓, referencePrice ✓                                  | planned                         |
| `contract_info`     | —                                                             | 不适用                          |

#### UM Perp (USDⓈ-M)

| canonical           | 对应 Binance 原生                                                                          | 状态                               |
| ------------------- | ------------------------------------------------------------------------------------------ | ---------------------------------- |
| `trade`             | aggTrade ✓                                                                                 | 已实现                             |
| `kline`             | kline ✓, continuousKline ✓(planned), indexPriceKline ✓(planned), markPriceKline ✓(planned) | 已实现（3 种 planned）             |
| `depth_update`      | depthUpdate ✓                                                                              | 已实现                             |
| `book_ticker`       | bookTicker ✓                                                                               | 已实现                             |
| `funding_rate`      | markPriceUpdate `r` 字段 ✓                                                                 | 已实现                             |
| `mark_price_update` | markPriceUpdate ✓                                                                          | 已实现                             |
| `ticker`            | 24hrTicker ✓, MiniTicker ✓                                                                 | planned                            |
| `force_order`       | forceOrder ✓                                                                               | planned                            |
| `open_interest`     | —（仅 REST）                                                                               | 不适用（WS 不可用）                |
| `index_reference`   | compositeIndex ✓, assetIndex ✓                                                             | planned                            |
| `contract_info`     | contractInfo ✓                                                                             | planned（与 FR-031~036 REST 互补） |

#### CM Perp (COIN-M)

| canonical           | 对应 Binance 原生                                                                          | 状态                                      |
| ------------------- | ------------------------------------------------------------------------------------------ | ----------------------------------------- |
| `trade`             | aggTrade ✓                                                                                 | 已实现                                    |
| `kline`             | kline ✓, continuousKline ✓(planned), indexPriceKline ✓(planned), markPriceKline ✓(planned) | 已实现（3 种 planned）                    |
| `depth_update`      | depthUpdate ✓                                                                              | 已实现                                    |
| `book_ticker`       | bookTicker ✓                                                                               | 已实现                                    |
| `funding_rate`      | markPriceUpdate `r` 字段 ✓                                                                 | 已实现                                    |
| `mark_price_update` | markPriceUpdate ✓                                                                          | 已实现                                    |
| `ticker`            | 24hrTicker ✓, MiniTicker ✓                                                                 | planned                                   |
| `force_order`       | forceOrder ✓                                                                               | planned                                   |
| `open_interest`     | —                                                                                          | 不适用                                    |
| `index_reference`   | —                                                                                          | 不适用（CM 无 compositeIndex/assetIndex） |
| `contract_info`     | contractInfo ✓                                                                             | planned                                   |

> **平台变更风险**：CM 于 2026-06-29 完成向 UM 架构迁移整合（ADR-010 R-P1）。payload 用 `fs`:"UM"/"CM" 区分。公开行情流是否受影响待确认。

#### Options

| canonical           | 对应 Binance 原生                | 状态                       |
| ------------------- | -------------------------------- | -------------------------- |
| `trade`             | trade ✓（underlyingAsset@trade） | 已实现                     |
| `kline`             | kline ✓                          | 已实现                     |
| `depth_update`      | depthUpdate ✓                    | 已实现                     |
| `book_ticker`       | —                                | ✗（options 无 bookTicker） |
| `funding_rate`      | —                                | 不适用                     |
| `mark_price_update` | ?（期权有独立 markPrice 结构）   | **不确定**——需验证 eapi    |
| `ticker`            | 24hrTicker ✓, MiniTicker ✓       | planned                    |
| `force_order`       | —                                | 不适用                     |
| `open_interest`     | openInterest ✓                   | planned                    |
| `index_reference`   | —                                | 不适用                     |
| `contract_info`     | —                                | 不适用                     |

> **平台变更风险**：Options 处于系统重构期，事件名可能变更（ADR-010 R-P2）。

### 4.2 产品线差异速查

| 差异维度             | spot                                                                       | um_perp                                                                   | cm_perp                                                  | options                                                                |
| -------------------- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------- | -------------------------------------------------------- | ---------------------------------------------------------------------- |
| 已实现 canonical 数  | 4/6                                                                        | 6/6                                                                       | 6/6                                                      | 3-4/6                                                                  |
| planned canonical 数 | 2（ticker, index_reference）                                               | 5（ticker, force_order, index_reference, contract_info, +3 kline 子类型） | 4（ticker, force_order, contract_info, +3 kline 子类型） | 2（ticker, open_interest）                                             |
| 独有事件             | blockTrade, rolling ticker, avgPrice, referencePrice                       | compositeIndex, assetIndex, continuousKline                               | —                                                        | openInterest(WS)                                                       |
| 不适用               | funding_rate, mark_price_update, force_order, open_interest, contract_info | open_interest(WS)                                                         | open_interest, index_reference, force_order?             | book_ticker, funding_rate, force_order, index_reference, contract_info |

## 5. Idempotency Key Dimensions

`[INFERRED]` 以下为每个 Binance 原生事件类型的幂等键建议维度。按 payload 字段推出的工程建议，不是币安官方定义的概念。

### 5.1 行情数据流幂等键

| event_type                  | → canonical                          | 幂等键建议维度                                 | SPEC §FR-005 覆盖       |
| --------------------------- | ------------------------------------ | ---------------------------------------------- | ----------------------- |
| aggTrade                    | `trade`                              | symbol + a                                     | ✓                       |
| trade                       | `trade`                              | symbol + t                                     | ✓                       |
| blockTrade                  | `trade` (subtype=block)              | symbol + t（独立 ID 空间）                     | planned                 |
| kline                       | `kline`                              | symbol + interval + k.t                        | ✓                       |
| continuousKline             | `kline` (key=pair+contractType)      | pair + contractType + interval + k.t           | planned                 |
| indexPriceKline             | `kline` (price_type=index)           | symbol/pair + interval + k.t                   | planned                 |
| markPriceKline              | `kline` (price_type=mark)            | symbol/pair + interval + k.t                   | planned                 |
| depthUpdate                 | `depth_update`                       | symbol + u，配合 pu 做连续性校验               | ✓                       |
| bookTicker                  | `book_ticker`                        | symbol + u                                     | ✓                       |
| 24hrTicker / 24hrMiniTicker | `ticker`                             | symbol + E                                     | planned                 |
| 滚动窗口 ticker             | `ticker`                             | symbol + window + E                            | planned                 |
| avgPrice                    | `index_reference`                    | symbol + T                                     | planned                 |
| markPriceUpdate             | `mark_price_update` / `funding_rate` | symbol + E                                     | ✓                       |
| forceOrder                  | `force_order`                        | symbol + T（每 1000ms 只推最新一笔，天然去重） | planned                 |
| compositeIndex              | `index_reference`                    | symbol + E                                     | planned                 |
| assetIndex                  | `index_reference`                    | assetSymbol + E                                | planned                 |
| contractInfo                | `contract_info`                      | symbol + E                                     | planned（与 REST 互补） |
| openInterest                | `open_interest`                      | symbol（含到期日）+ E                          | planned                 |
| referencePrice              | `index_reference`                    | symbol + t                                     | planned                 |
| serverShutdown              | 传输层                               | 无需去重，触发重连                             | ✗（传输层处理）         |

### 5.2 用户数据流幂等键（未来参考）

> **用户数据流当前排除**（SPEC §3 + ADR-009），以下仅作未来扩展参考。

| event_type                     | 幂等键建议维度                             |
| ------------------------------ | ------------------------------------------ |
| outboundAccountPosition        | u（账户最后更新时间）                      |
| balanceUpdate                  | a（资产）+ T                               |
| executionReport                | i（订单ID）+ t（成交ID，成交时）否则 i + T |
| listStatus                     | g（OrderListId）+ T                        |
| eventStreamTerminated          | E                                          |
| externalLockUpdate             | a（资产）+ T                               |
| listenKeyExpired               | listenKey + E                              |
| ACCOUNT_UPDATE                 | T + 涉及 symbol 集合                       |
| BALANCE_POSITION_UPDATE        | T + 涉及 symbol 集合                       |
| ORDER_TRADE_UPDATE             | o.i + o.t（成交时）否则 o.i + T            |
| TRADE_LITE                     | i + t                                      |
| MARGIN_CALL                    | 无强制去重；如需用 E + symbol 集合         |
| ACCOUNT_CONFIG_UPDATE          | ac.s + T                                   |
| ALGO_UPDATE                    | o.aid + E                                  |
| CONDITIONAL_ORDER_TRADE_UPDATE | so.si + so.ut                              |
| STRATEGY_UPDATE                | su.si + su.ut                              |
| GRID_UPDATE                    | 策略ID + 子订单更新时间                    |

## 6. Platform Change Notes

`[KNOWN]` 以下平台变更来自 report/binance/20260704.md，详细风险登记见 [ADR-010](ADR-010-platform-change-risks.md)：

1. **CM Perp → UM 架构迁移**（2026-06-29）：CM 用户数据流事件与 UM 趋同，payload 用 `fs`:"UM"/"CM" 区分。公开行情流是否受影响待确认。
2. **Options 系统重构期**（进行中）：事件名可能变更（官方 "Options Demo Trading" 升级）。
3. **现货 CSV 时间戳单位变更**（2025-01-01 起）：spot CSV 从毫秒变微秒，futures 不变。详见 [HISTORICAL-DATA-SYNC-STRATEGY.md](HISTORICAL-DATA-SYNC-STRATEGY.md) §5.1。

---

> **证据标签汇总**：
>
> - `[KNOWN]`：SPEC §6 canonical 定义、client SPEC §FR-005 幂等键规则、报告中直接引用的覆盖矩阵和平台变更
> - `[COMPUTED]`：映射表、分类判据应用、逐产品线覆盖分析（基于报告矩阵和分类判据交叉计算）
> - `[INFERRED]`：四问分类判据、幂等键建议维度、误映射后果评估（工程推断，非币安官方定义）
> - 置信度：`HIGH`（已实现类型的映射关系）/ `MED`（planned 类型的语义归类和误映射后果评估）
