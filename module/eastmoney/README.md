# eastmoney 模块索引

`eastmoney` 是数据域 · 宏观的独立 C/S 模块，按 **client/server 双服务** 运行，负责东方财富宏观数据采集、归一化、持久化、事件发布和查询服务；跨模块语义统一通过 `domain_macro` 输出。

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
| `eastmoney-client` | 独立进程（`cmd/eastmoney-client`） | 采集 Eastmoney 宏观数据、写 OSS raw、发布 NATS ingest envelope |
| `eastmoney-server` | 独立进程（`cmd/eastmoney-server`） | 消费 NATS、执行幂等校验、写多存储、发布 Kafka、提供查询 API |

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

## 模块采集清单（Eastmoney 宏观）

### A. 中国宏观数据（CMD）

1. 国民经济核算：GDP（季/年）、GDP 平减指数、三大产业增加值。
2. 价格指数：CPI（全国/城市/农村）、PPI、企业商品价格指数、房价指数。
3. 工业：工业增加值、工业企业利润、粗钢产量、PTA 产业链负荷率、半钢胎开工率。
4. 固定资产投资：城镇固定资产投资、基建投资、制造业投资、房地产投资。
5. 国内贸易：社会消费品零售总额。
6. 对外经济：进出口增减、FDI、外汇与黄金储备。
7. 财政：财政收入、税收收入。
8. 货币金融：M0/M1/M2、新增信贷、本外币存款、外汇贷款、存款准备金率、利率调整。
9. 就业工资：城镇调查失业率。
10. 景气指数：制造业/非制造业 PMI、消费者信心、企业景气与企业家信心。
11. 区域下沉：34 省级、500+ 地级市、2000+ 县域指标分层。

### B. 全球宏观数据（GMD）

1. 美国：ISM、非农、失业率、CPI/PPI、零售、新屋开工、耐用品、GDP、Fed 利率决议。
2. 欧元区：GDP、CPI、消费者信心、零售、ECB 利率决议、贸易差额。
3. 日本：利率决议、CPI、失业率、领先指标。
4. 英国：CPI、零售、GDP、失业率、BoE 利率决议。
5. 德国：Ifo、CPI、GDP、ZEW。
6. 澳大利亚：CPI、失业率、贸易差额、RBA 利率决议。

### C. 行业经济数据（IED）

覆盖 21 个行业大类（农林牧渔、能源、食品饮料、纺织服装、石油化工、钢铁、有色、汽车、电子电器等），指标含价格、产量、销量、产能、开工率、进出口、库存、财务指标。

### D. 宏观分析核心指标包（按目标）

| 目标维度 | 核心指标 | 频率 |
| --- | --- | --- |
| 经济增长 | GDP、工业增加值、社零、固定资产投资、进出口/贸易差额 | 季/月 |
| 物价通胀 | CPI、PPI、GDP 平减指数 | 月/季 |
| 就业劳动力 | 城镇调查失业率 | 月 |
| 货币流动性 | M2、社融、新增人民币贷款、存款准备金率、LPR/逆回购 | 月/不定期 |
| 景气领先 | 制造业 PMI、非制造业 PMI、消费者信心 | 月 |

## 定时更新频率与同步周期（默认）

| 数据类型 | 定时频率 | 同步周期 | 备注 |
| --- | --- | --- | --- |
| 日频市场与利率 | 每日 07:00/12:00/19:00 CST | T+0 增量 | 发布日触发优先，定时轮询兜底 |
| 周频指标 | 每周一 07:30 CST | 周增量 + 12 周回拉 | 覆盖晚到修订 |
| 月频指标 | 每日检查发布日历 + 发布后 1h/6h/24h 补拉 | 月增量 + 18 个月回拉 | 适配初值/修订值 |
| 季频指标 | 每日检查发布日历 + 发布后 1h/24h/7d 回补 | 季增量 + 12 季回拉 | GDP/社融季度结构重点 |
| 不定期政策 | 事件触发 + 15 分钟内补采 | 事件增量 + 90 天回溯 | 利率、RRR、重大政策公告 |

## 历史数据同步起点

- 默认全量起点：`2005-01-01`。
- 若系列 earliest_available_date 晚于起点，则以系列最早可用日期为准。
- 增量同步：`last_success_cursor -> now`，每次附带近 3 个月（日频）/18 个月（月频）/12 季（季频）修订回拉窗口。

## 采集策略（生产级）

1. 先 raw 后规范化：先写 OSS，再进入归一化、多存储写入与事件发布。
2. 幂等优先：`provider+dataset+series+period+vintage+hash` 作为幂等键。
3. no-lookahead：统一记录 `observed_at/released_at/available_at/vintage_at`，以 `available_at` 做可见性裁剪。
4. 双通道分层：NATS 仅 handoff/control；Kafka 仅 durable business event。
5. 分片并行：按 dataset/series bucket 拉取，429/5xx 指数退避 + jitter。
6. 数据修订闭环：保留初值与修订值并生成 revision 事件，支撑 as-of 回放。
7. 采集方式分层：优先 Choice API，其次可审计 XHR 接口；动态渲染页面采集需 headless 浏览器并固化接口契约。
8. 时间对齐规则：统一时区、同比/环比、季调/未季调标准化后入库。

## 宏观分析还需补充

1. 高频数据：高炉/水泥/PTA/半钢胎开工率、30 城地产成交、土地溢价率、货运流量、港口吞吐、农产品与猪价。
2. 政策事件：财经日历、央行议息、国务院/发改委/央行公告、预期值与实际值偏差。
3. 国际联动：汇率、美元指数、原油铜金、全球股指、全球债券收益率曲线。
4. 特色补充：开户/基金申赎情绪、地方债与广义财政、出生率与老龄化。
5. 跨源一致性：与统计局、央行、海关、交易所做口径对齐与偏差告警。
6. 事件冲击窗：发布前后 5m/1h/1d/1w 多窗口冲击归因。
7. Revision Alpha：首发值-修订值偏差因子化，纳入 `ms_brain` 输入。
8. 叙事因子：政策文本结构化（稳增长/稳汇率/宽信用）并输出事件标签。
9. 质量评分：freshness、coverage、revision-lag 三维质量分并入特征工程。

## 采集注意事项

1. 页面多为动态渲染，直采需走 Selenium/Playwright 或逆向 XHR；优先 Choice API/终端接口。
2. 建立发布日历驱动 + 定时轮询双轨调度；Choice 数据按 7x24 更新处理。
3. 严格做时间序列对齐：频率、口径、时区、发布日期、可用时间统一标准化。
4. 数据量级按百万指标、亿级时序规划：按指标-时间二维建模并做冷热分层存储。
