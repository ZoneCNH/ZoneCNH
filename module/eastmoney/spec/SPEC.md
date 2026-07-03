# eastmoney 规格

- Status: Draft
- Spec-Version: v0.1.0
- Last-Updated: 2026-07-04
- Layer: 数据域 · 宏观
- Module-Type: 独立 C/S Module（双服务）
- Runtime-Service: `eastmoney-client` + `eastmoney-server`
- Goal: [goal/goal.md](../goal/goal.md)
- Traceability: [matrix/TRACEABILITY.md](../matrix/TRACEABILITY.md)
- Implementation-Plan: [plan/PLAN.md](../plan/PLAN.md)
- Client-SPEC: [spec/client/SPEC.md](client/SPEC.md)
- Server-SPEC: [spec/server/SPEC.md](server/SPEC.md)

## 1. 摘要

`eastmoney` 是数据域 · 宏观的独立 C/S 服务。client 负责 Eastmoney 采集、归一化、OSS raw 归档与 NATS ingest 发布；server 负责 NATS 消费、幂等校验、多存储写入、Kafka durable event、查询 API 与回补编排。

## 2. 目标

1. 形成可生产落地的 Eastmoney 模块目标、边界、追溯和计划基线。
2. 明确 C/S 双服务边界、共享基座接入和 `domain_macro` 语义输出。
3. 明确七类持久化介质职责与权威性。
4. 明确采集清单、定时频率、同步周期、历史起点、采集策略。

## 3. 非目标

1. 不承载跨 provider 聚合和口径仲裁（归 `macro_data`）。
2. 不承载因子、策略、执行和风控逻辑。
3. 不暴露 Eastmoney 私有 DTO 给跨模块契约。

## 4. 用户与消费者

| 消费者 | 使用方式 | 边界 |
| ------ | -------- | ---- |
| `macro_data` | 消费 API/事件/领域模型 | 不依赖 `eastmoney/internal/*` |
| `ms_brain` | 消费 PIT 宏观事实、修订、发布事件、质量标签 | `eastmoney` 不实现状态机与交易判断 |
| 分析域 | 读 ClickHouse 或订阅 Kafka | 不直连 provider |

## 5. 功能需求

| ID | WHEN | THEN |
| -- | ---- | ---- |
| FR-001 | 服务启动 | `eastmoney-client` 与 `eastmoney-server` 均经共享 bootstrap 启动并暴露 health/readiness/version。 |
| FR-002 | 加载配置 | 通过共享配置组件读取配置映射，不记录 secret 值。 |
| FR-003 | 拉取 provider 数据 | 覆盖 CMD/GMD/IED 三大模块及核心指标包，不得遗漏。 |
| FR-004 | 收到 raw 响应 | 先写 `oss`，再规范化与下游写入。 |
| FR-005 | 规范化事件形成 | 转换为 `domain_macro`，保留 `observed_at/released_at/available_at/vintage_at`。 |
| FR-006 | 通过校验 | 写 `taos` 时间序列并可按 as-of 查询。 |
| FR-007 | metadata/checkpoint/ledger 变化 | 写 `postgres`。 |
| FR-008 | 热点读取与锁/限流 | 使用 `Redis` 可重建缓存层。 |
| FR-009 | 业务事实形成 | 发布 Kafka durable event。 |
| FR-010 | client->server handoff 与控制命令 | 仅使用 `nats`。 |
| FR-011 | 分析读模型构建 | 写 `clickhouse`，并支持回放重建。 |
| FR-012 | 执行增量同步 | 以 `last_success_cursor -> now` 同步并含修订回拉窗口。 |
| FR-013 | 执行历史回补 | 默认起点 `2005-01-01`，支持按系列 earliest date 覆写。 |
| FR-014 | 边界门禁运行 | 允许共享基座接入目标基础设施，禁止模块绕过基座直连。 |
| FR-015 | 动态页面采集 | 动态渲染页面必须通过受控 headless + XHR 契约采集，禁止无审计抓取。 |
| FR-016 | 口径标准化 | 同比/环比、季调/未季调、时区、发布时间必须标准化后入库。 |
| FR-017 | 深度校验 | 对采集覆盖、字段映射、调度策略执行多轮一致性检查并产出审计证据。 |

## 6. 模块采集清单

### 6.1 中国宏观（CMD）

1. 国民经济核算：GDP（季/年）、GDP 平减指数、三大产业增加值。
2. 价格指数：CPI（全国/城市/农村）、PPI、企业商品价格指数、房价指数。
3. 工业：工业增加值、工业企业利润、粗钢产量、PTA 负荷率、半钢胎开工率。
4. 固定资产投资：城镇固投、基建、制造业、房地产投资。
5. 国内贸易：社零。
6. 对外经济：进出口、FDI、外汇与黄金储备。
7. 财政：财政收入、税收收入。
8. 货币金融：M0/M1/M2、新增信贷、本外币存款、外汇贷款、RRR、LPR/政策利率。
9. 就业工资：城镇调查失业率。
10. 景气指数：制造业/非制造业 PMI、消费者信心、企业景气与企业家信心。
11. 区域层级：34 省级、500+ 地级市、2000+ 县域。

### 6.2 全球宏观（GMD）

美国、欧元区、日本、英国、德国、澳大利亚六大区块的 GDP/CPI/就业/利率决议/景气与贸易指标。

### 6.3 行业经济（IED）

21 行业大类：价格、产量、销量、产能、开工率、进出口、库存、财务指标。

### 6.4 宏观分析核心指标包

| 维度 | 指标 | 频率 |
| --- | --- | --- |
| 增长 | GDP、工业增加值、社零、固投、进出口/贸易差额 | 季/月 |
| 通胀 | CPI、PPI、GDP 平减指数 | 月/季 |
| 就业 | 城镇调查失业率 | 月 |
| 货币流动性 | M2、社融、新增人民币贷款、RRR、LPR/逆回购 | 月/不定期 |
| 景气领先 | 制造业 PMI、非制造业 PMI、消费者信心 | 月 |

## 7. 定时更新频率与同步周期

| 数据类型 | 定时频率 | 同步周期 |
| --- | --- | --- |
| 日频 | 每日 07:00/12:00/19:00 CST | T+0 增量 |
| 周频 | 每周一 07:30 CST | 周增量 + 12 周回拉 |
| 月频 | 发布后 1h/6h/24h 补拉 + 每日发布日历检查 | 月增量 + 18 个月回拉 |
| 季频 | 发布后 1h/24h/7d 回补 + 每日发布日历检查 | 季增量 + 12 季回拉 |
| 不定期政策 | 事件触发 + 15 分钟内补采 | 事件增量 + 90 天回溯 |

## 8. 历史同步起点

- 默认：`2005-01-01`。
- 覆写：系列 earliest available date。
- 增量：每轮附带修订回拉（日频 3 个月、月频 18 个月、季频 12 季）。

## 9. 采集策略

1. `OSS first`：先 raw 落盘，再规范化写入。
2. 幂等键：`provider+dataset+series+period+vintage+hash`。
3. no-lookahead：`available_at` 为空或未来时间即 fail-closed。
4. 双通道：NATS 仅 handoff/control，Kafka 仅 durable event。
5. 并行与退避：分片并发、429/5xx 指数退避 + jitter。
6. 修订治理：保留首发值/修订值并发布 revision event。
7. 采集通道优先级：Choice API > XHR 接口 > headless 页面采集。
8. 质量治理：采集后执行覆盖率、时效、修订滞后、口径一致性四类审计。
9. 容量治理：按指标-时间二维分区与冷热分层，支持亿级时序增长。

## 10. 持久化边界

| 介质 | 职责 | 权威性 |
| ---- | ---- | ------ |
| `taos` | 规范化 observation 时序 | 时间序列权威 |
| `kafka` | durable 业务事件 | 事件分发权威 |
| `postgres` | 目录、日历、checkpoint、幂等账本 | 控制面权威 |
| `Redis` | 热缓存、锁、限流、短游标 | 可重建派生层 |
| `oss` | raw 与审计快照 | 原始数据权威 |
| `nats` | ingest handoff + 控制面 | 服务间通信通道 |
| `clickhouse` | 分析宽表与质量审计 | 可重建派生层 |

## 11. 业务规则

| ID | 规则 |
| -- | ---- |
| BR-001 | 对外只输出服务 API、Kafka 事件和 `domain_macro` 语义。 |
| BR-002 | 相同幂等键重复写入不得产生重复副作用。 |
| BR-003 | `available_at` 是 no-lookahead 判定基准。 |
| BR-004 | Redis/ClickHouse 不得作为唯一权威数据源。 |
| BR-005 | NATS 与 Kafka 通道职责严格分层。 |
| BR-006 | 动态页面采集必须具备接口契约与反爬失败降级策略。 |
| BR-007 | 各指标必须标注频率、发布日历、口径标签。 |

## 12. 验收标准

| AC | 验收项 |
| -- | ------ |
| AC-001 | 双服务可独立启动并通过健康检查。 |
| AC-002 | 配置映射正确且文档/日志不含 secret 值。 |
| AC-003 | 七类持久化链路职责闭环。 |
| AC-004 | 同步频率/周期、历史起点与修订回拉规则可执行。 |
| AC-005 | no-lookahead、幂等、重放、回补策略有可审计证据。 |
| AC-006 | CMD/GMD/IED 与核心指标包覆盖清单完整。 |
| AC-007 | 高频/政策/国际联动/特色补充四类扩展数据有明确采集策略。 |
| AC-008 | 完成 20 轮深度一致性检查并留档。 |

## 13. 宏观分析还需补充

1. 高频数据：高炉/水泥/PTA/半钢胎开工率、30 城地产成交、土地溢价、货运、港口、农产品与猪价。
2. 政策与事件：财经日历、政策文件、议息会议、预期-实际偏差。
3. 国际联动：汇率、美元指数、原油/铜/黄金、全球股指、全球债券收益率。
4. 特色补充：情绪指标（开户/申赎）、地方债与广义财政、人口结构。
5. 多源口径校验与偏差告警。
6. 事件冲击窗口归因（5m/1h/1d/1w）。
7. Revision Alpha（首发-修订差异因子化）。
8. 政策文本结构化标签。
9. 质量分（freshness/coverage/revision-lag）入模。

## 14. 采集注意事项

1. Eastmoney 页面多为 JavaScript 动态渲染，采集应优先 Choice API，其次受控 XHR。
2. 建立发布日历驱动 + 定时调度双轨机制，避免漏采。
3. 不同指标发布时间不同，必须做统一时间轴对齐。
4. 大规模指标与时序数据采用时序优先 + 分层存储架构，保证回放与审计能力。
