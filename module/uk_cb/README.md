# uk_cb 模块索引

`uk_cb` 是数据域 · 宏观的独立 C/S 模块，按 **client/server 双服务** 运行；在宏观分析语境下，`uk_cb` 以 **CBI 商业调查 + Companies House 工商注册** 为双主源，并接入 BoE/ONS/DMP 等补充源，统一完成采集、归一化、持久化、事件发布和查询服务；跨模块语义统一通过 `domain_macro` 领域共享层输出。

> 分析原则：**CBI+Companies House 为主干，BoE/ONS/DMP 与全球数据为补充**。

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
| `uk-cb-cbi-client/server` | 独立进程 | CBI 工业趋势/分销/服务业调查（软数据领先指标）采集 |
| `uk-cb-chrt-client/server` | 独立进程 | Companies House 实时注册/解散（企业出生死亡）采集 |
| `uk-cb-policy-client/server` | 独立进程 | Bank Rate、MPC 决议、会议纪要与投票结构化采集 |
| `uk-cb-balance-sheet-client/server` | 独立进程 | APF/QE/QT、资产负债表与流动性工具采集 |
| `uk-cb-prices-client/server` | 独立进程 | CPI/Core CPI/PPI 与通胀相关序列采集（BoE 主干 + ONS 补充） |
| `uk-cb-growth-client/server` | 独立进程 | GDP、工业产出、零售销售、PMI/景气指标采集 |
| `uk-cb-labor-client/server` | 独立进程 | 失业率、工资增速、职位空缺与劳动力紧张度采集 |
| `uk-cb-rates-client/server` | 独立进程 | SONIA、gilt 曲线关键期限点、信用利差采集 |

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

## 模块采集清单（CBI + Companies House 双主源）

1. CBI 软数据：Industrial Trends（Total Orders Book Balance）、Distributive Trades、Services、Growth Indicator。
2. Companies House 行政实时数据：incorporations、dissolutions/liquidations（CHRT 日频链路）。
3. 政策利率与决议：Bank Rate、MPC 投票、会议纪要、通胀报告摘要。
4. 资产负债表与流动性：APF 持仓、QE/QT 操作、准备金与流动性工具。
5. 通胀与价格：CPI/Core CPI、PPI、输入成本与住房相关价格指标。
6. 增长与需求：GDP、工业产出、零售销售、商业景气与 PMI。
7. 劳动力：失业率、就业、薪资增长、职位空缺与劳动参与。
8. 金融条件：SONIA、gilt 收益率曲线（关键期限）、信用利差。
9. 发布日历与修订：scheduled/actual 发布时刻、revision/vintage 时间线。

## 宏观分析口径（主干解释）

1. **CBI 领先信号**：以 Total Orders Book Balance 为制造业领先指标，结合分销与服务业调查构建增长方向判断。
2. **CHRT 实时活力**：以注册/解散/清算的净变化跟踪企业“出生-死亡”周期，作为 GDP/就业的先行观测层。
3. **软硬组合链路**：CBI/CHRT（领先）+ DMP（预期分布）+ ONS 硬数据（确认）构成完整分析链。
4. **市场映射**：调查与注册数据超预期时，重点观察 GBP 与 FTSE 风险偏好联动。

## 定时更新频率与同步周期（默认）

| 数据类型 | 定时频率 | 同步周期 | 备注 |
| --- | --- | --- | --- |
| 日频/市场相关 | 每日 06:30/12:30/18:30 UTC | T+0 日内增量 | 决议日和重大发布触发优先 |
| 周频 | 每周一 07:00 UTC | 周增量 + 12 周回拉 | 覆盖延迟修订 |
| 月频 | 发布日触发 + 发布后 1h/6h/24h 补拉 | 月增量 + 12 个月回拉 | 适配初值/二次修订 |
| 季频 | 发布日触发 + 发布后 1h/24h/7d 回补 | 季增量 + 8 季回拉 | GDP/政策报告重点 |

## 历史数据同步起点

- 默认全量起点：`1997-05-06`（BoE 获得政策独立性后可比口径起点）。
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

1. 央行叙事结构化：MPC 纪要文本标签化（hawkish/dovish、增长/通胀权重）。
2. 跨央行对照：Fed/ECB/BoJ/BoE 同口径映射，形成相对政策强弱因子。
3. 事件冲击窗：发布前后多窗口（5m/1h/1d/1w）影响归因。
4. Revision Alpha：修订方向与幅度因子化，区分首发值与终值信号。
5. 数据质量分层：freshness、coverage、revision-lag 三维质量分数入模。
6. CBI 软数据与 ONS 硬数据联合校准（confidence vs realized activity）。
7. CH 注册/解散领先指标与 GDP/就业滞后响应映射。
8. DMP 企业预期分布接入（销售/就业/投资/价格预期与不确定性）。

## 关键补充源（强制接入建议）

1. ONS 硬数据：GDP、工业产出、零售销售、就业、工资、通胀。
2. ONS 企业微观：LBD（Longitudinal Business Database）与商业调查。
3. Insolvency Service：企业破产与清算官方口径（与 CH 解散交叉校验）。
4. BoE DMP：企业销售/就业/投资/价格预期与不确定性分布。
5. ONS 产业链支付流：用于行业联动与压力传导分析。
