# yahoo 模块索引

`yahoo` 是数据域 · 宏观的独立 C/S 模块，按 **client/server 双服务** 运行，负责 Yahoo Finance 宏观相关数据采集、归一化、持久化、事件发布和查询服务；跨模块语义统一通过 `domain_macro` 输出。

## 文档入口

| 文档 | 用途 |
| ---- | ---- |
| [goal/goal.md](goal/goal.md) | 目标、边界、成功标准 |
| [spec/SPEC.md](spec/SPEC.md) | 根规格（生产级约束） |
| [spec/client/SPEC.md](spec/client/SPEC.md) | client 子模块规格 |
| [spec/server/SPEC.md](spec/server/SPEC.md) | server 子模块规格 |
| [matrix/TRACEABILITY.md](matrix/TRACEABILITY.md) | 追溯矩阵 |
| [plan/PLAN.md](plan/PLAN.md) | 实施计划 |
| [design/DESIGN.md](design/DESIGN.md) | 架构与数据流 |
| [gate/BOUNDARY-GATES.md](gate/BOUNDARY-GATES.md) | 边界门禁 |
| [schema/README.md](schema/README.md) | 契约与 schema 说明 |

## C/S 子模块与独立服务

| 子模块 | 运行形态 | 核心职责 |
| ---- | ---- | ---- |
| `yahoo-client` | 独立进程（`cmd/yahoo-client`） | 采集 Yahoo 数据、写 OSS raw、发布 NATS ingest envelope |
| `yahoo-server` | 独立进程（`cmd/yahoo-server`） | 消费 NATS、执行幂等校验、写多存储、发布 Kafka、提供查询 API |

## 生产级持久化职责

| 介质 | 职责 | 权威性 |
| ---- | ---- | ---- |
| `oss` | provider raw 归档、回放输入、审计快照 | 原始数据权威 |
| `taos` | 规范化 observation 时间序列 | 时间序列权威 |
| `postgres` | catalog、发布日历、checkpoint、幂等账本 | 控制面权威 |
| `Redis` | 热缓存、分布式锁、限流桶、短游标 | 可重建派生层 |
| `clickhouse` | 分析读模型、宽表聚合、质量审计 | 可重建派生层 |
| `nats` | client→server ingest handoff + control plane | 服务间通信通道 |
| `kafka` | 下游 durable business event | 事件分发权威 |

## 模块采集清单（Yahoo 宏观相关）

1. 行情数据（OHLCV）：open/high/low/close/adj_close/volume（1d/1wk/1mo/最大历史）。
2. 实时报价：最新价、涨跌幅、当日 OHLC、昨收、成交量、市值、50/200MA、52 周高低。
3. 基本面：财报（年/季）、估值（P/E、P/B、PEG）、盈利（ROE/ROA/EBITDA）、财务结构、股息率、Beta、EPS。
4. 分析师数据：目标价、评级汇总、上调/下调记录。
5. 期权链与持仓：call/put、主要持有人、机构持仓、内部交易。
6. 新闻公告：每标的最多 200 条新闻。
7. 多资产覆盖：股票、ETF、指数、外汇、加密货币、大宗商品期货、美债相关符号。
8. 宏观代理符号：`^TNX`、`^IRX`、`DX-Y.NYB`、`CL=F`、`GC=F`、`HG=F`、`^VIX`、`^GSPC`、`^NDX`、`^RUT`、`EURUSD=X`、`BTC-USD`。

## 定时更新频率与同步周期（默认）

| 数据类型 | 定时频率 | 同步周期 | 备注 |
| --- | --- | --- | --- |
| 高频行情（分钟） | 每 5 分钟 | T+0 增量 | 盘中启用，非交易时段降频 |
| 日频行情 | 每日 06:30/12:30/18:30 UTC | 日增量 + 30 天回拉 | 处理晚到修订 |
| 周频指标 | 每周一 07:00 UTC | 周增量 + 12 周回拉 | 覆盖周频回补 |
| 月频/季频代理指标 | 每日检查发布日历 + 发布后 1h/24h/7d 回补 | 月增量 + 12 月回拉 / 季增量 + 8 季回拉 | 发布触发优先 |

## 历史数据同步起点

- 默认全量起点：`2000-01-01`。
- 指数/ETF 若可用历史更早，按 symbol `earliest_available_date` 回溯。
- 增量同步：`last_success_cursor -> now`，每次附带近 3 个月修订回拉窗口。

## 采集策略（生产级）

1. 先 raw 后规范化：先写 OSS，再做归一化、多存储写入与事件发布。
2. 幂等优先：`provider+symbol+interval+ts+vintage+hash` 作为幂等键。
3. no-lookahead：统一记录 `observed_at/released_at/available_at/vintage_at`。
4. 双通道分层：NATS 仅 handoff/control；Kafka 仅 durable business event。
5. 分片并行：按 symbol bucket 并发拉取，429/5xx 指数退避 + jitter。
6. 质量闭环：覆盖率、时效性、修订延迟三维评分，低分触发重采。

## 宏观分析还需补充

1. 跨源校验：Yahoo 与 FRED/ECB/BEA 同指标口径映射与偏差告警。
2. 事件冲击窗：发布前后 5m/1h/1d/1w 多窗口影响归因。
3. Revision Alpha：首发值与修订值差异因子化。
4. 质量因子入模：freshness、coverage、revision-lag 三维质量分。
5. Regime 标签：通胀/增长/流动性三轴状态标签，供 `ms_brain` 消费。

## 必须补充的数据源

1. 美国：FRED、BLS、EIA。
2. 全球：World Bank、IMF、ECB、BIS。
3. 中国：国家统计局、中国人民银行。
4. 市场增强：TradingView、Polygon.io、OpenBB。

## 采集工具建议

1. `yfinance`、`yahooquery`：Yahoo 采集主工具。
2. `fredapi`、`pandas-datareader`：宏观补充源。
3. `pdfetch`、`Bootleg_Macro`：多源原型整合。

## 深度检查

详见 [design/DEEP-ANALYSIS-20-PASS.md](design/DEEP-ANALYSIS-20-PASS.md)。
