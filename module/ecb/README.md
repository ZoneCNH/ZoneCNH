# ecb 模块索引

`ecb` 是数据域 · 宏观的独立 C/S 模块，按 **client/server 双服务** 运行，负责欧元区宏观与央行数据采集、归一化、持久化、事件发布和查询服务；跨模块语义统一通过 `domain_macro` 领域共享层输出。

> 分析原则：**ECB 数据为主干，外部数据为枝叶**。

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
| `ecb-client` | 独立进程（`cmd/ecb-client`） | 采集 ECB SDW / Data Portal / press 事件，写 OSS raw，发布 NATS ingest envelope |
| `ecb-server` | 独立进程（`cmd/ecb-server`） | 消费 NATS envelope，执行幂等与 no-lookahead，写多存储，发布 Kafka durable event，提供查询/API |

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

## 模块采集清单（ECB）

1. 利率与政策：`MRO`, `DFR`, `MLF`, `APP/PEPP` 资产购买相关指标与公告。
2. HICP 通胀：Headline、Core、国家/欧元区聚合、分项指数。
3. 货币与信贷：`M1/M2/M3`、贷款余额、信贷增速、金融条件相关序列。
4. 真实经济：Industrial Production、PMI/ESI（若来源合法映射）、就业失业率（欧元区口径）。
5. 外汇与利差：`EURUSD`、欧元区国债收益率曲线关键期限点。
6. 发布日历与修订：发布计划、实际发布时间、vintage/revision 变更。

### ECB 必采维度（生产基线）

1. 货币政策与利率：政策利率、ESTR、收益率曲线、银行利率。
2. 通胀与价格：HICP（整体/核心）、PPI、房地产价格。
3. 增长与产出：GDP、增加值、产能利用率、产出缺口。
4. 货币与信贷：M3、MFI 贷款、信贷调查（BLS）。
5. 劳动力：就业、失业、劳动生产率、单位劳动力成本。
6. 财政：赤字/盈余、债务、政府收支。
7. 对外部门：国际收支、经常账户、国际投资头寸、外债。
8. 预测与调查：MPD、CES、BLS、SPF。

## 定时更新频率与同步周期（默认）

| 数据类型 | 定时频率 | 同步周期 | 备注 |
| --- | --- | --- | --- |
| 日频/市场相关 | 每日 06:30/12:30/18:30 UTC | T+0 日内增量 | 发布日触发优先，定时轮询兜底 |
| 周频 | 每周一 07:00 UTC | 周增量 + 12 周回拉 | 覆盖晚到修订 |
| 月频 | 每日检查发布日历 + 发布后 1h/6h/24h 三次补拉 | 月增量 + 12 个月回拉 | 适配初值/二次修订 |
| 季频 | 每日检查发布日历 + 发布后 1h/24h/7d 回补 | 季增量 + 8 季回拉 | GDP/账户类重点 |

## 历史数据同步起点

- 默认全量起点：`1999-01-01`（欧元区统一货币起点）。
- 早于欧元区统一口径的数据：按 series 实际 earliest_available_date 采集并显式标记来源口径。
- 增量同步：`last_success_cursor -> now`，每次附带最近 3 个月（高频）/12 个月（月频）/8 季（季频）修订回拉窗口。

## 采集策略（生产级）

1. 先 raw 后规范化：先写 OSS，再进入归一化/多存储写入。
2. 幂等优先：`provider+dataset+series+period+vintage+hash` 作为写入幂等键。
3. no-lookahead：统一记录 `observed_at/released_at/available_at/vintage_at`，以 `available_at` 做可见性裁剪。
4. 双通道分层：NATS 仅 handoff/control；Kafka 仅 durable business event。
5. 分批并行与退避：按 dataset 分片并发拉取，429/5xx 指数退避 + jitter，错误分级入账。
6. 回放可审计：任一下游事实可回溯到 OSS raw + Postgres checkpoint + Kafka offset。

## 宏观分析还需补充

1. 央行叙事结构化：将新闻稿/会议纪要语义标签化（hawkish/dovish、流动性倾向）。
2. 跨央行对照：与 Fed/BoE/BoJ 同步口径映射，形成相对政策强弱因子。
3. 事件冲击窗：发布前后多窗口（5m/1h/1d/1w）影响归因。
4. Revision Alpha：修订方向与幅度因子化，区分首发值与终值信号。
5. 数据质量分层：freshness、coverage、revision-lag 三维质量分数入模。

### 外部数据枝叶（建议）

1. 全球增长与贸易：IMF WEO、OECD CLI、WTO、CPB。
2. 大宗商品与能源：Brent/WTI、TTF/NBP、LME、CBOT、GSCI、BCOM。
3. 汇率与资金流：BIS 有效汇率、IIF、EPFR。
4. 中国相关：国家统计局、海关总署、CFETS/CNY。
5. 风险指标：iBoxx 利差、CDS、VSTOXX、EBA 压测。
6. 互补库：Eurostat、AMECO、DBnomics。

### 宏观联动框架（建议）

1. 增长链：GDP -> 产能利用率 -> 就业 -> 生产率。
2. 通胀链：HICP -> 核心 HICP -> 工资成本 -> 进口价格传导。
3. 政策链：政策利率 -> ESTR -> 银行利率 -> 信贷 -> 实体经济。
4. 外部链：经常账户 -> 汇率 -> 外债/头寸 -> 全球贸易。
5. 财政链：赤字率 -> 债务/GDP -> 融资期限 -> 融资成本。

### RTDB / Vintage 要求

- 必须保留实时快照（vintage）用于修订分析。
- 必须支持 as-of 查询，避免未来数据污染历史判断。
