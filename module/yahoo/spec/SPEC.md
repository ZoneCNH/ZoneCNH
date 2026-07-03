# yahoo 规格

- Status: Draft
- Spec-Version: v1.0.1
- Last-Updated: 2026-07-04
- Layer: 数据域 · 宏观
- Module-Type: 独立 C/S Module（双服务）
- Runtime-Service: `yahoo-client` + `yahoo-server`
- Goal: [goal/goal.md](../goal/goal.md)
- Traceability: [matrix/TRACEABILITY.md](../matrix/TRACEABILITY.md)
- Implementation-Plan: [plan/PLAN.md](../plan/PLAN.md)
- Client-SPEC: [spec/client/SPEC.md](client/SPEC.md)
- Server-SPEC: [spec/server/SPEC.md](server/SPEC.md)
- Config-Source: `sre/secrets/env/dev.md`

## 1. 摘要

`yahoo` 是数据域 · 宏观的独立 C/S 服务：client 负责采集 Yahoo 数据、归一化、OSS raw 归档与 NATS ingest 发布；server 负责 NATS 消费、持久化、查询 API 和 Kafka durable event。两个服务必须共享基座组件，必须通过 `domain_macro` 输出跨模块语义，并具备 `taos`、`kafka`、`postgres`、`Redis`、`oss`、`nats`、`clickhouse` 七类能力。

## 2. 目标

- 建立 `yahoo` 的生产级目标架构、追溯矩阵和实施计划。
- 明确 `yahoo` 与共享基座、`domain_macro`、`macro_data`、下游分析服务的边界。
- 明确七类持久化与消息介质职责、权威性和重建关系。
- 明确采集清单、更新频率、同步周期、历史回补起点与采集策略。

## 3. 非目标

- 不在 `yahoo` 内实现跨宏观 provider 的统一仲裁。
- 不在 `yahoo` 内实现因子计算、策略研究或回测。
- 不把 provider DTO 暴露为跨模块公共契约。
- 不在文档、示例、测试夹具中保存 secret 值。

## 4. 功能需求

| ID | WHEN | THEN |
| -- | ---- | ---- |
| FR-001 | WHEN `yahoo-client`/`yahoo-server` 启动 | THEN 必须通过共享 `bootstrap` 组装生命周期、readiness、liveness、shutdown 和版本信息。 |
| FR-002 | WHEN 服务加载配置 | THEN 必须通过共享配置组件从 `sre/secrets/env/dev.md` 映射配置，且不得复制密钥值。 |
| FR-003 | WHEN 触发采集 | THEN client 必须覆盖 §4.1 的 Yahoo 宏观采集清单，支持分页、限流、重试与错误分类。 |
| FR-004 | WHEN provider response 到达 | THEN 必须先写 OSS raw，再执行归一化、多存储写入和事件发布。 |
| FR-005 | WHEN 数据进入领域层 | THEN 必须转换为 `domain_macro` 兼容模型，并记录 `released_at`、`available_at`、`vintage_at`。 |
| FR-006 | WHEN observation 校验通过 | THEN 必须写入 `taos`。 |
| FR-007 | WHEN 元数据/checkpoint/幂等账本变化 | THEN 必须写入 `postgres`。 |
| FR-008 | WHEN 查询热点与短期游标 | THEN 必须使用 `Redis`，且缓存可由权威源重建。 |
| FR-009 | WHEN 业务事实形成 | THEN 必须通过 `kafka` 发布版本化 durable event。 |
| FR-010 | WHEN client 产生 ingest envelope 或 admin 控制命令 | THEN 必须通过 `nats` 传输 handoff/control，不替代 Kafka。 |
| FR-011 | WHEN 分析读模型生成 | THEN 必须写入 `clickhouse`，且支持重放重建。 |
| FR-012 | WHEN 执行增量/回补/修订扫描 | THEN 必须维护可追踪 job、checkpoint 和幂等键。 |
| FR-013 | WHEN 下游访问数据 | THEN 服务 API 必须支持查询、作业状态和 as-of/no-lookahead。 |
| FR-014 | WHEN 边界门禁运行 | THEN 必须允许目标存储适配器经共享基座接入，禁止绕过基座直连基础设施。 |

### 4.1 模块采集清单

| 大类 | 必采项 |
| -- | -- |
| 行情数据（OHLCV） | open/high/low/close/adj_close/volume，支持 1d/1wk/1mo 与最大历史回溯 |
| 实时报价 | 最新价、涨跌幅、当日 OHLC、昨收、成交量、市值、50/200MA、52 周高低 |
| 基本面 | 财报字段（利润表/资产负债表/现金流，年度+季度），估值（P/E、P/B、PEG），盈利（ROE、ROA、EBITDA），财务结构与分红/Beta/EPS |
| 分析师数据 | 目标价、评级汇总、上调/下调记录 |
| 期权与持仓 | call/put option chain、major/institutional holders、insider transactions |
| 新闻公告 | 每标的最多 200 条新闻 |
| 多资产覆盖 | 股票、ETF、指数、外汇、加密货币、大宗商品期货、美债相关符号 |
| 宏观代理符号（首批） | `^TNX`、`^IRX`、`DX-Y.NYB`、`CL=F`、`GC=F`、`HG=F`、`^VIX`、`^GSPC`、`^NDX`、`^RUT`、`^FTSE`、`^N225`、`^HSI`、`EURUSD=X`、`BTC-USD` |

### 4.1.1 宏观分析核心指标覆盖与缺口

| 维度 | 核心指标 | Yahoo 覆盖 |
| -- | -- | -- |
| 经济增长 | GDP、GDP 增速、工业增加值、服务业增加值 | 缺口（需外部源） |
| 物价水平 | CPI、PPI、GDP 平减指数 | 缺口（需外部源） |
| 就业市场 | 非农就业、失业率、劳动参与率 | 缺口（需外部源） |
| 货币金融 | M2、贷款、居民储蓄 | 缺口（需外部源） |
| 财政政策 | 财政力度/空间指数 | 缺口（需外部源） |
| 国际贸易 | 进出口总额、贸易差额 | 缺口（需外部源） |
| 市场情绪 | VIX 等波动指标 | 可覆盖（`^VIX`） |
| 流动性 | 央行资产负债表、全球 M2 | 缺口（需外部源） |

### 4.2 定时更新频率与同步周期

| 数据类型 | 定时频率 | 同步周期 |
| -- | -- | -- |
| 高频行情 | 每 5 分钟 | T+0 增量 |
| 日频 | 每日 06:30/12:30/18:30 UTC | 日增量 + 30 天回拉 |
| 周频 | 每周一 07:00 UTC | 周增量 + 12 周回拉 |
| 月频/季频 | 发布触发 + 1h/24h/7d 回补 | 月增量 + 12 月 / 季增量 + 8 季 |

### 4.3 历史数据同步起点

- 默认全量起点：`2000-01-01`。
- 若 symbol 更早可得，按 `earliest_available_date` 回溯。
- 每次增量附带最近 3 个月修订回拉窗口。

### 4.4 采集策略

1. 先 raw 后归一化：OSS raw -> 规范化 -> 多存储 -> 事件发布。
2. 幂等键：`provider+symbol+interval+ts+vintage+hash`。
3. no-lookahead：统一记录 `observed_at/released_at/available_at/vintage_at`。
4. 双通道分层：NATS for handoff/control；Kafka for durable business event。
5. 分片并发 + 退避：按 symbol bucket 并发，429/5xx 指数退避 + jitter。
6. 质量闭环：coverage/freshness/revision-lag 评分驱动重采。

## 5. 业务规则

| ID | 规则 |
| -- | ---- |
| BR-001 | 对外只暴露服务 API、Kafka 事件和 `domain_macro` 模型。 |
| BR-002 | 同 provider/symbol/interval/timestamp/vintage 写入必须幂等。 |
| BR-003 | `available_at` 是 no-lookahead 判定基准。 |
| BR-004 | Kafka 是 durable business event；NATS 只承载 handoff/control。 |
| BR-005 | Postgres checkpoint 成功推进前，job 不得标记 completed。 |
| BR-006 | Redis 与 ClickHouse 均为可重建派生层，不作为唯一权威源。 |
| BR-007 | `macro_data` 不得依赖 `yahoo/internal/*` 或 provider DTO。 |

## 6. 宏观分析补充（必须纳入路线图）

1. 跨源校验：Yahoo 与 FRED/ECB/BEA 同口径映射与偏差监控。
2. 事件冲击窗：发布前后 5m/1h/1d/1w 归因。
3. Revision Alpha：首发值与修订值差异信号。
4. 质量因子：freshness、coverage、revision-lag 三维评分。
5. Regime 标签：通胀/增长/流动性三轴状态，供 `ms_brain` 消费。

## 7. 必须补充的数据源与工具

### 7.1 外部数据源（宏观缺口补齐）

| 区域 | 数据源 | 用途 |
| -- | -- | -- |
| 美国 | FRED、BLS、EIA | GDP/CPI/PPI/就业/利率/能源等 |
| 全球 | World Bank、IMF、ECB、BIS | 全球增长、财政、金融稳定、货币数据 |
| 中国 | 国家统计局、中国人民银行 | 中国宏观核心指标 |
| 市场增强 | TradingView、Polygon.io、OpenBB | 多资产与研究增强 |

### 7.2 采集工具建议

| 工具 | 用途 |
| -- | -- |
| `yfinance` | Yahoo Finance 批量采集 |
| `yahooquery` | Yahoo API 端点采集（支持异步） |
| `fredapi` / `pandas-datareader` | FRED、World Bank 等宏观源 |
| `pdfetch` / `Bootleg_Macro` | 多源宏观聚合（研究/原型） |

### 7.3 架构建议

以 Yahoo 作为市场数据核心，以 FRED/World Bank/央行官方源作为宏观核心，统一映射到 `domain_macro`，经 C/S 双服务沉淀到七介质链路并输出 durable event。
