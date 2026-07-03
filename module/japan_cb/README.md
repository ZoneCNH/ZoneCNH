# japan_cb 模块索引

`japan_cb` 是数据域 · 宏观的独立 C/S 模块，按 **client/server 双服务** 运行。该名词存在双语义：**Japanese Convertible Bonds（可转债）** 与 **Bank of Japan（日本央行）**。模块默认主线为 **BoJ 宏观政策数据**，并支持可转债（CB）扩展采集框架；跨模块语义统一通过 `domain_macro` 领域共享层输出。

> 分析原则：**默认 BoJ 宏观主线；若目标为融资与资本结构分析，切换 Japanese CB 扩展画像**。

## 语义消歧与分析路由

| 分析目标 | 语义 | 默认画像 |
| --- | --- | --- |
| 货币政策、经济周期、通胀传导 | Bank of Japan | `boj_macro`（默认） |
| 企业融资、可转债发行、资本市场稀释效应 | Japanese Convertible Bonds | `jcb_market`（扩展） |

## 文档入口

| 文档 | 用途 |
| ---- | ---- |
| [goal/goal.md](goal/goal.md) | 目标、边界、成功标准 |
| [spec/SPEC.md](spec/SPEC.md) | 根规格（生产级约束） |
| [spec/client/SPEC.md](spec/client/SPEC.md) | client 子模块规格 |
| [spec/server/SPEC.md](spec/server/SPEC.md) | server 子模块规格 |
| [matrix/TRACEABILITY.md](matrix/TRACEABILITY.md) | 追溯矩阵 |
| [matrix/client/TRACEABILITY.md](matrix/client/TRACEABILITY.md) | client 追溯矩阵 |
| [matrix/server/TRACEABILITY.md](matrix/server/TRACEABILITY.md) | server 追溯矩阵 |
| [plan/PLAN.md](plan/PLAN.md) | 实施计划 |
| [plan/client/PLAN.md](plan/client/PLAN.md) | client 实施计划 |
| [plan/server/PLAN.md](plan/server/PLAN.md) | server 实施计划 |
| [design/DESIGN.md](design/DESIGN.md) | 架构与数据流 |
| [gate/BOUNDARY-GATES.md](gate/BOUNDARY-GATES.md) | 边界门禁 |
| [schema/README.md](schema/README.md) | 契约与 schema 说明 |

## C/S 子模块与独立服务

| 子模块 | 运行形态 | 核心职责 |
| ---- | ---- | ---- |
| `japan-cb-policy-client/server` | 独立进程 | 政策利率、YCC 区间、政策声明/会议摘要采集 |
| `japan-cb-expectation-client/server` | 独立进程 | Tankan、通胀预期、企业景气预期采集 |
| `japan-cb-prices-client/server` | 独立进程 | CPI（全国/东京）、PPI、进口价格采集 |
| `japan-cb-growth-client/server` | 独立进程 | GDP、工业生产、零售销售、机械订单采集 |
| `japan-cb-labor-client/server` | 独立进程 | 失业率、就业、薪资、职位供需采集 |
| `japan-cb-rates-client/server` | 独立进程 | JGB 曲线、短端利率、汇率与风险利差采集 |

## 生产级持久化职责

| 介质 | 职责 | 权威性 |
| ---- | ---- | ---- |
| `oss` | provider raw 归档、回放输入、审计快照 | 原始数据权威 |
| `taos` | 规范化 observation 时间序列 | 时间序列权威 |
| `postgres` | catalog、发布日历、checkpoint、幂等账本 | 控制面权威 |
| `Redis` | 热缓存、分布式锁、限流桶、短游标 | 可重建派生层 |
| `clickhouse` | 分析读模型、宽表聚合、质量审计 | 可重建派生层 |
| `nats` | client->server ingest handoff + control plane | 服务间通信通道 |
| `kafka` | 下游 durable business event | 事件分发权威 |

## 模块采集清单（BoJ 主干）

1. 政策链：政策利率、YCC 目标区间、政策会议声明与摘要、政策路径指引。
2. 预期链：Tankan（大企业制造/非制造景气）、通胀预期、企业资本开支计划。
3. 通胀链：全国 CPI、东京 CPI（领先）、核心 CPI、PPI、进口价格。
4. 增长链：GDP（季频）、工业生产、机械订单、零售销售、外需相关指标。
5. 劳动力链：失业率、就业人数、薪资增速、职位供需比（job offers-to-applicants）。
6. 金融条件：JGB 收益率曲线、短端利率、JPY 汇率、信用利差。
7. 发布日历与修订：scheduled/actual 发布时刻、revision/vintage 时间线。

## 可转债（Japanese CB）扩展采集清单

1. 发行端：发行规模、发行笔数、行业分布、发行节奏（月/季）。
2. 条款端：转股价格、转股溢价率、票息/零息、期限结构、赎回/回售条款。
3. 环境端：政策利率、JGB 收益率、日经指数、波动率（Nikkei VI）。
4. 二级市场：CB 交易量、价格、转股执行、稀释冲击。
5. 对比层：普通社债/增发融资规模、历史高点年份横向比较。

## 定时更新频率与同步周期（默认）

| 数据类型 | 定时频率 | 同步周期 | 备注 |
| --- | --- | --- | --- |
| 日频/市场相关 | 每日 06:30/12:30/18:30 UTC | T+0 日内增量 | BoJ 会议日与 CPI 日触发优先 |
| 周频 | 每周一 07:00 UTC | 周增量 + 12 周回拉 | 覆盖晚到修订 |
| 月频 | 发布日触发 + 发布后 1h/6h/24h 补拉 | 月增量 + 12 个月回拉 | CPI/PPI/工业生产重点 |
| 季频 | 发布日触发 + 发布后 1h/24h/7d 回补 | 季增量 + 8 季回拉 | GDP/Tankan 重点 |

## 历史数据同步起点

- 默认全量起点：`1998-04-01`（BoJ 新法后政策口径起点）。
- 长序列扩展：对可获得更早历史的序列，允许回补到最早可用日期并标注口径。
- 增量同步：`last_success_cursor -> now`，并附带 3 个月/12 个月/8 季修订回拉窗口。

## 采集策略（生产级）

1. 先 raw 后规范化：先写 OSS，再进入归一化/多存储写入。
2. 幂等优先：`provider+dataset+series+period+vintage+hash` 作为写入幂等键。
3. no-lookahead：统一记录 `observed_at/released_at/available_at/vintage_at`，以 `available_at` 做可见性裁剪。
4. 双通道分层：NATS 仅 handoff/control；Kafka 仅 durable business event。
5. 分批并行与退避：按 dataset 分片并发拉取，429/5xx 指数退避 + jitter，错误分级入账。
6. 回放可审计：任一下游事实可回溯到 OSS raw + Postgres checkpoint + Kafka offset。

## 宏观分析还需补充

1. 政策语义结构化：会议声明语义标签化（正常化/宽松延续/风险偏好）。
2. 跨央行对照：Fed/ECB/BoE/BoJ 同口径映射，形成相对政策强弱因子。
3. 事件冲击窗：发布前后多窗口（5m/1h/1d/1w）影响归因。
4. Revision Alpha：修订方向与幅度因子化，区分首发值与终值信号。
5. 数据质量分层：freshness、coverage、revision-lag 三维质量分数入模。
6. 日元传导链：政策预期 -> JGB 曲线 -> JPY -> 出口/进口价格传导。
7. CB 融资周期：发行活跃度与股市波动、信用利差、融资替代效应联动。
