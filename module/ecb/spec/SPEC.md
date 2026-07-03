# ecb 规格

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-07-04
- Layer: 数据域 · 宏观
- Module-Type: 独立 C/S Module（双服务）
- Runtime-Service: `ecb-client` + `ecb-server`
- Goal: [goal/goal.md](../goal/goal.md)
- Traceability: [matrix/TRACEABILITY.md](../matrix/TRACEABILITY.md)
- Implementation-Plan: [plan/PLAN.md](../plan/PLAN.md)
- Config-Source: `sre/secrets/env/dev.md`

## 1. 摘要

`ecb` 提供欧元区宏观数据采集、归一化、持久化、事件发布和查询服务。模块按 client/server 分离运行，强制共享基座接入，强制 `domain_macro` 语义输出，强制七类持久化与消息链路：`taos + kafka + postgres + Redis + oss + nats + clickhouse`。

## 2. 目标

- 把 `ecb` 从 Proto-C/S 规格空位补齐为可执行生产级规格。
- 明确 ECB 数据域采集清单、更新频率、同步周期、历史回补起点与采集策略。
- 建立 `ecb` 与 `macro_data`、分析域服务之间的稳定契约。
- 采用“ECB 数据为主干、外部数据为枝叶”的宏观分析数据组织策略。

## 3. 非目标

- 不实现跨 provider 聚合与主数据冲突仲裁（归属 `macro_data`）。
- 不实现因子计算、策略研究、交易执行或风险决策。
- 不暴露 ECB 原始 DTO 作为跨模块长期契约。

## 4. 用户与消费者

| 消费者 | 使用方式 | 边界 |
| ------ | -------- | ---- |
| `macro_data` | 订阅 Kafka 或调用查询 API | 不依赖 `ecb/internal/*` |
| `ms_brain` / 分析域 | 使用 PIT 宏观观测与修订事件 | 不读取 provider 原始字段 |
| 运维治理 | 使用 admin API 与控制主题 | 不直接写业务事实表 |

## 5. 功能需求

| ID | WHEN | THEN |
| -- | ---- | ---- |
| FR-001 | WHEN `ecb-client` 或 `ecb-server` 启动 | THEN 两个服务必须独立启动、独立探活、独立扩缩容。 |
| FR-002 | WHEN 加载配置 | THEN 必须经共享配置组件映射，不复制 secret 值。 |
| FR-003 | WHEN client 执行采集 | THEN 必须覆盖 §5.1 的 ECB 采集清单并支持增量/回补。 |
| FR-004 | WHEN raw 响应到达 | THEN 必须先写 OSS，再归一化与多存储写入。 |
| FR-005 | WHEN observation 归一化 | THEN 必须映射为 `domain_macro` 语义并记录四时间字段。 |
| FR-006 | WHEN server 消费 ingest | THEN 必须执行幂等校验、写 `taos/postgres/Redis/clickhouse` 并发布 Kafka 事件。 |
| FR-007 | WHEN 查询请求到达 | THEN 必须支持 series、时间区间、as-of、vintage selector。 |
| FR-008 | WHEN 发布日历触发或定时任务触发 | THEN 必须按 §5.2~§5.4 调度同步与回补。 |
| FR-009 | WHEN 数据发布/修订 | THEN 必须产生可追踪 revision 事件与质量标签。 |
| FR-010 | WHEN 边界门禁执行 | THEN 必须禁止绕过共享基座直连基础设施。 |

### 5.1 模块采集清单（ECB）

> 主干数据源：ECB Data Portal（SDMX API）统一拉取。

| 数据族 | 采集对象（示例） | 备注 |
| -- | ---- | ---- |
| 政策利率 | `MRO/DFR/MLF` 历史序列与变更事件 | 决议日触发优先 |
| 货币市场与收益率 | ESTR、欧元区收益率曲线、银行存贷款利率 | 利率传导链核心 |
| 资产负债表/流动性 | APP/PEPP、央行资产负债表关键项 | 周/月频混合 |
| 通胀 | HICP headline/core 与分项 | 月频，重点 revision |
| 价格与成本 | 工业生产者价格、房地产价格、相关输入价格 | 通胀前瞻补充 |
| 货币与信贷 | M1/M2/M3、贷款增长、信贷条件 | 月频 |
| 实体经济 | 工业产出、失业率、景气指标 | 月/季频 |
| 增长核算 | GDP 总量/分项、增加值、产能利用率、产出缺口 | 季频核心 |
| 财政 | 政府赤字/盈余、政府债务、政府收支 | 与 Eurostat 对齐 |
| 收益率曲线 | 欧元区关键国债期限点与利差 | 日频/周频 |
| 对外部门 | 国际收支、经常账户、国际投资头寸、外债 | 外部均衡链 |
| 发布日历 | scheduled/actual release time | 作为调度源 |
| 修订与 vintage | 首发值、修订值、版本时间线 | 支持回测与审计 |
| 预测与调查 | ECB MPD、CES、BLS、SPF | 预期与信用供给信号 |

### 5.2 定时更新频率

| 数据频率 | 默认调度 |
| ---- | ---- |
| 日频 | 每日 06:30 / 12:30 / 18:30 UTC |
| 周频 | 每周一 07:00 UTC |
| 月频 | 发布日触发 + 发布后 1h/6h/24h 补拉 |
| 季频 | 发布日触发 + 发布后 1h/24h/7d 补拉 |

### 5.3 同步周期

| 模式 | 周期 |
| ---- | ---- |
| 增量同步 | `last_success_cursor -> now` |
| 高频修订回拉 | 最近 3 个月 |
| 月频修订回拉 | 最近 12 个月 |
| 季频修订回拉 | 最近 8 季 |
| 全量覆盖审计 | 每周一次 |

### 5.4 历史数据同步起点

- 默认：`1999-01-01`（欧元区统一口径起点）。
- 若序列起点晚于默认值：以 `series earliest_available_date` 为准。
- 若序列存在 pre-euro 历史：可采集但必须标注口径与来源差异。

### 5.5 采集策略

1. **分片采集**：按 dataset/series 分片并发，统一限流桶。
2. **幂等写入**：`provider+dataset+series+period+vintage+checksum`。
3. **双总线分层**：NATS=ingest/control，Kafka=durable business events。
4. **错误分级**：429/5xx/contract_drift/schema_error 分级处理并记录。
5. **no-lookahead**：`available_at` 作为下游可见性裁剪唯一准则。
6. **回放审计**：事实可回溯到 OSS key + Postgres checkpoint + Kafka offset。

### 5.6 宏观分析还需补充

1. 央行语义层（鹰鸽倾向、政策路径）结构化。
2. ECB/Fed/BoE/BoJ 跨央行相对政策强弱因子。
3. 发布冲击窗归因（5m/1h/1d/1w）。
4. Revision surprise 因子（初值 vs 修订值偏离）。
5. 质量评分（freshness/coverage/revision-lag）并入下游特征。

### 5.7 外部数据枝叶补充（建议采集）

| 维度 | 推荐来源 | 作用 |
| --- | --- | --- |
| 全球增长与贸易 | IMF WEO、OECD CLI、WTO、CPB | 补齐欧元区外需与全球周期 |
| 大宗商品与能源 | EIA/ICE（Brent, WTI）、TTF/NBP、LME、CBOT、GSCI、BCOM | 输入成本与通胀传导 |
| 汇率与资金流 | BIS NEER/REER、IIF、EPFR | 汇率竞争力与资本流向 |
| 中国相关 | 国家统计局、海关总署、CFETS/CNY | 欧元区对华需求与外部冲击 |
| 金融风险 | iBoxx、CDS、VSTOXX、EBA stress test | 风险偏好与信用条件 |
| 官方互补库 | Eurostat、AMECO、DBnomics | 交叉校验与口径补齐 |

### 5.8 数据采集方法

1. ECB 主干：优先使用 ECB Data Portal SDMX API。
2. 多源聚合：DBnomics 作为跨库统一入口，源站 API 作为校验回退。
3. 发布驱动：统计日历触发优先，定时轮询兜底。
4. 接口封装：可提供 R `{readecb}` 或脚本封装给研究环境使用。

### 5.9 宏观分析联动框架

1. 增长周期：GDP -> 产能利用率 -> 就业/失业 -> 劳动生产率。
2. 通胀周期：HICP -> 核心 HICP -> 工资/单位劳动力成本 -> 进口价格传导。
3. 货币政策传导：政策利率 -> ESTR -> 银行利率 -> 信贷增长 -> 实体经济。
4. 外部均衡：经常账户 -> 汇率 -> 外债/国际投资头寸 -> 全球贸易环境。
5. 财政可持续：赤字率 -> 债务/GDP -> 期限结构 -> 融资成本。

### 5.10 RTDB / Vintage 规范

- 必须接入 ECB Real-Time Database（RTDB）口径。
- 每条观测保留至少一组 vintage 维度：`snapshot_at`、`released_at`、`available_at`。
- 分析侧必须支持 as-of 回放，严禁使用未来修订值回看历史决策。

## 6. 业务规则

| ID | 规则 |
| -- | ---- |
| BR-001 | `ecb` 对外只暴露 API、Kafka 事件、`domain_macro` 语义。 |
| BR-002 | 相同 provider+series+period+vintage 写入必须幂等。 |
| BR-003 | `available_at` 是 no-lookahead 判定基准。 |
| BR-004 | Kafka 是 durable event，NATS 不替代 Kafka。 |
| BR-005 | Postgres checkpoint 未推进前，不得标记作业 completed。 |
| BR-006 | 分析默认以 ECB 主干指标为主，外部数据仅作为补充解释变量。 |

## 7. API 契约

| API | 说明 |
| --- | ---- |
| `GetSeries` | 查询 series 元信息 |
| `QueryObservations` | 按 series/time/as-of/vintage 查询 |
| `GetReleaseCalendar` | 发布日历 |
| `StartBackfill` | 回补作业 |
| `GetJobStatus` | 作业状态与 checkpoint |
| `ReloadConfig` | 控制面重载 |

## 8. C/S 边界

| 组件 | 职责 | 禁止事项 |
| ---- | ---- | -------- |
| `cmd/ecb-client` | 采集、限流、归档、NATS 发布 | 不写业务库 |
| `cmd/ecb-server` | 消费、幂等、持久化、查询 API | 不直连 provider 抓取 |
| `internal/client` | provider 适配、分页、重试、归一化 | 不泄漏 DTO |
| `internal/server` | 作业编排、存储写入、查询服务 | 不保存 secret 值 |
| `internal/cs` | 客户端/服务端契约与校验 | 不承载业务决策 |

## 9. 领域共享层

`ecb` 必须使用 `domain_macro` 作为唯一跨模块领域语义层，至少包含 `observed_at/released_at/available_at/vintage_at` 四时间语义。

## 10. 持久化模型

见 [README](../README.md) “生产级持久化职责”。

## 11. 配置模式

配置来源固定 `sre/secrets/env/dev.md`，文档仅声明键名类别，不保存值。

## 12. 错误处理

| 错误类 | 行为 |
| ------ | ---- |
| 429 / rate_limited | 指数退避 + jitter，不推进 checkpoint |
| schema_drift | raw 入 OSS，批次隔离并告警 |
| partial_store_failure | 保留作业为 retryable |
| duplicate_payload | 幂等跳过副作用 |

## 13. 边界情况

- 发布延迟与修订并存。
- 回补窗口与增量窗口重叠。
- 单次批量任务部分失败。

## 14. 目录结构

本模块遵循 `goal/spec/matrix/plan/prompt/tasks/design/evidence/gate/schema` 嵌套结构。

## 15. 测试要求

- 单元：归一化、幂等键、时间可见性。
- 集成：`client -> nats -> server -> stores -> kafka`。
- 回归：回补与修订窗口重放一致性。

## 16. 可观测性

- 指标：采集成功率、延迟、回补覆盖、修订命中率、质量评分。
- 日志：request-id/job-id/checkpoint-id 全链路可追踪。

## 17. 安全

- secret 引用不落盘。
- API 鉴权与最小权限。
- 依赖扫描与密钥扫描通过后方可发布。

## 18. 部署

- client/server 分离部署。
- 支持水平扩容与故障隔离。

## 19. 追溯

见 [matrix/TRACEABILITY.md](../matrix/TRACEABILITY.md)。

## 20. Issue 对齐

实现阶段任务需在 `tasks/` 制品中映射 FR/BR/AC。

## 21. Release Gate

达到 FR 完成、AC 通过、边界门禁通过、证据归档后可进入 release 候选。

## 22. 变更历史

| Version | Date | Change |
| --- | --- | --- |
| v1.0.0 | 2026-07-04 | 初始化 ecb 生产级规格基线 |

## 23. 停止条件

`ecb` 形成可审计的生产级 C/S 数据服务，且采集、持久化、事件、回补、no-lookahead 与质量评分链路闭合。
