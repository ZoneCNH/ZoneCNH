# uk_cb 规格

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-07-04
- Layer: 数据域 · 宏观
- Module-Type: 独立 C/S Module（双服务 + 多子模块）
- Runtime-Service: `uk_cb-client` + `uk_cb-server`
- Goal: [goal/goal.md](../goal/goal.md)
- Traceability: [matrix/TRACEABILITY.md](../matrix/TRACEABILITY.md)
- Implementation-Plan: [plan/PLAN.md](../plan/PLAN.md)
- Config-Source: `sre/secrets/env/dev.md`

## 1. 摘要

`uk_cb` 提供英国宏观商业周期数据采集、归一化、持久化、事件发布和查询服务；在宏观分析语境下，模块以 **CBI 商业调查 + Companies House 工商注册** 为双主源，并结合 BoE/ONS/DMP 形成完整证据链。模块按 client/server 分离运行，强制共享基座接入，强制 `domain_macro` 语义输出，强制七类持久化与消息链路：`taos + kafka + postgres + Redis + oss + nats + clickhouse`。

## 2. 目标

- 把 `uk_cb` 从缺失规格状态补齐为可执行生产级规格。
- 明确 CBI + Companies House 双主源采集清单、更新频率、同步周期、历史回补起点与采集策略。
- 建立 `uk_cb` 与 `macro_data`、分析域服务之间的稳定契约。
- 采用“CBI + Companies House 主干、BoE/ONS/DMP 与全球数据补充”的宏观分析组织策略。

## 3. 非目标

- 不实现跨 provider 聚合与主数据冲突仲裁（归属 `macro_data`）。
- 不实现因子计算、策略研究、交易执行或风险决策。
- 不暴露 BoE 原始 DTO 作为跨模块长期契约。

## 4. 用户与消费者

| 消费者 | 使用方式 | 边界 |
| ------ | -------- | ---- |
| `macro_data` | 订阅 Kafka 或调用查询 API | 不依赖 `uk_cb/internal/*` |
| `ms_brain` / 分析域 | 使用 PIT 宏观观测与修订事件 | 不读取 provider 原始字段 |
| 运维治理 | 使用 admin API 与控制主题 | 不直接写业务事实表 |

## 5. 功能需求

| ID | WHEN | THEN |
| -- | ---- | ---- |
| FR-001 | WHEN `uk_cb-client` 或 `uk_cb-server` 启动 | THEN 两个服务必须独立启动、独立探活、独立扩缩容。 |
| FR-002 | WHEN 加载配置 | THEN 必须经共享配置组件映射，不复制 secret 值。 |
| FR-003 | WHEN client 执行采集 | THEN 必须覆盖 §5.1 的 CBI+Companies House 双主源清单并支持增量/回补。 |
| FR-004 | WHEN raw 响应到达 | THEN 必须先写 OSS，再归一化与多存储写入。 |
| FR-005 | WHEN observation 归一化 | THEN 必须映射为 `domain_macro` 语义并记录四时间字段。 |
| FR-006 | WHEN server 消费 ingest | THEN 必须执行幂等校验、写 `taos/postgres/Redis/clickhouse` 并发布 Kafka 事件。 |
| FR-007 | WHEN 查询请求到达 | THEN 必须支持 series、时间区间、as-of、vintage selector。 |
| FR-008 | WHEN 发布日历触发或定时任务触发 | THEN 必须按 §5.2~§5.4 调度同步与回补。 |
| FR-009 | WHEN 数据发布/修订 | THEN 必须产生可追踪 revision 事件与质量标签。 |
| FR-010 | WHEN 边界门禁执行 | THEN 必须禁止绕过共享基座直连基础设施。 |

### 5.1 模块采集清单（CBI + Companies House 双主源）

| 数据族 | 采集对象（示例） | 备注 |
| -- | ---- | ---- |
| CBI 工业调查 | Total Orders Book Balance、产出预期、价格预期 | 领先软数据，月频主导 |
| CBI 分销/服务调查 | 零售销售差值、服务业景气 | 增长结构分解 |
| Companies House CHRT | incorporations、dissolutions、liquidations | 企业出生/死亡日频领先指标 |
| 企业结构补充 | SIC 行业分类、企业规模分层 | 结构性分析必要补充 |
| 政策与利率 | Bank Rate、MPC 决议、会议纪要、投票结构 | 决议日触发优先 |
| 货币市场与收益率 | SONIA、gilt 曲线关键期限点、利差 | 利率传导链核心 |
| 通胀与增长硬数据 | CPI/Core CPI、GDP、工业产出、零售销售、劳动力 | ONS 硬数据校准层 |
| 发布日历 | scheduled/actual release time | 作为调度源 |
| 修订与 vintage | 首发值、修订值、版本时间线 | 支持回测与审计 |

### 5.2 定时更新频率

| 数据频率 | 默认调度 |
| ---- | ---- |
| 日频（CHRT/市场利率） | 每日 06:30 / 12:30 / 18:30 UTC |
| 周频（补充统计） | 每周一 07:00 UTC |
| 月频（CBI/DMP/多数宏观） | 发布日触发 + 发布后 1h/6h/24h 补拉 |
| 季频（GDP/部门账户） | 发布日触发 + 发布后 1h/24h/7d 补拉 |

### 5.3 同步周期

| 模式 | 周期 |
| ---- | ---- |
| 增量同步 | `last_success_cursor -> now` |
| CHRT 日度回拉 | 最近 30 天 |
| 高频修订回拉 | 最近 3 个月 |
| 月频修订回拉 | 最近 12 个月 |
| 季频修订回拉 | 最近 8 季 |
| 全量覆盖审计 | 每周一次 |

### 5.4 历史数据同步起点

- CBI 默认：`1960-01-01`（可得历史窗口起点，按实际可得性裁剪）。
- Companies House 默认：`2005-01-01`（现代电子登记口径起点，按 CHRT 可得性裁剪）。
- BoE/政策链默认：`1997-05-06`（BoE 政策独立后可比起点）。
- 若序列起点晚于默认值：以 `series earliest_available_date` 为准。
- 若序列存在更长历史：可采集但必须标注口径与来源差异。

### 5.5 采集策略

1. **分片采集**：按 dataset/series 分片并发，统一限流桶。
2. **幂等写入**：`provider+dataset+series+period+vintage+checksum`。
3. **双总线分层**：NATS=ingest/control，Kafka=durable business events。
4. **错误分级**：429/5xx/contract_drift/schema_error 分级处理并记录。
5. **no-lookahead**：`available_at` 作为下游可见性裁剪唯一准则。
6. **回放审计**：事实可回溯到 OSS key + Postgres checkpoint + Kafka offset。
7. **软硬融合**：CBI 软数据必须与 ONS 硬数据做周期性偏差校准。
8. **企业活力链路**：CH 注册/解散需关联就业、破产、行业结构标签。

### 5.6 宏观分析还需补充

1. CBI Total Orders 与 GDP/IP/零售硬数据联合建模（soft-hard spread）。
2. CH 注册/解散与 GDP/就业的领先滞后映射（early warning）。
3. MPC 纪要语义层（鹰鸽倾向、增长/通胀权重）结构化。
4. Fed/ECB/BoJ/BoE 跨央行相对政策强弱因子。
5. 发布冲击窗归因（5m/1h/1d/1w）。
6. Revision surprise 因子（初值 vs 修订值偏离）。
7. 质量评分（freshness/coverage/revision-lag）并入下游特征。

### 5.7 外部数据枝叶补充（建议采集）

| 维度 | 推荐来源 | 作用 |
| --- | --- | --- |
| 企业预期分布 | BoE DMP | 销售/就业/投资/价格预期与不确定性建模 |
| 全球增长与贸易 | IMF WEO、OECD CLI、WTO、CPB | 补齐英国外需与全球周期 |
| 大宗商品与能源 | EIA/ICE（Brent, WTI）、TTF/NBP、LME、CBOT、GSCI、BCOM | 输入成本与通胀传导 |
| 汇率与资金流 | BIS NEER/REER、IIF、EPFR | 汇率竞争力与资本流向 |
| 中国相关 | 国家统计局、海关总署、CFETS/CNY | 对英外需与外部冲击 |
| 金融风险 | iBoxx、CDS、VIX/VSTOXX、压力测试口径 | 风险偏好与信用条件 |
| 官方互补库 | ONS、Eurostat、DBnomics、FRED | 交叉校验与口径补齐 |

### 5.8 CBI 与 Companies House 专项分析要求

1. **CBI 工业趋势**：必须采集 Total Orders Book Balance，并与工业产出、GDP nowcast 对齐。
2. **CBI 分销/服务**：必须纳入零售销售差值与服务景气，生成行业结构扩散指数。
3. **CHRT 企业活力**：必须跟踪 incorporations、dissolutions、liquidations，并构建净活力指标。
4. **领先性检验**：CHRT 指标需执行与 GDP/就业的领先滞后窗口检验（至少 1/3/6/12 个月）。
5. **市场映射**：CBI/CHRT 发布窗口需生成 GBP 与 FTSE100 事件反应快照。

### 5.9 补充数据与交叉验证要求

1. **硬数据确认层**：ONS GDP、工业产出、零售销售、就业、工资、通胀必须作为确认层接入。
2. **企业结构层**：Companies House 必须附带 SIC/规模分层标签，避免仅数量分析。
3. **破产校验层**：CH 解散需与 Insolvency Service 破产/清算口径交叉验证。
4. **预期分布层**：BoE DMP 调查（销售/就业/投资/价格预期）需按月接入并做不确定性分层。
5. **产业联动层**：接入 ONS 行业支付流与 LBD，用于行业链路风险传导分析。

### 5.10 数据获取与合规要求

1. CBI 调查数据：来自 CBI 官方发布与授权数据源。
2. Companies House：优先 CHRT/官方 API 与公开数据集。
3. DMP/ONS：走官方渠道获取并保留来源元数据、许可与更新时间。
4. 所有外部源必须记录 `source_url/license/retrieved_at/schema_version`。

### 5.11 RTDB / Vintage 规范

- 必须保留实时快照（vintage）用于修订分析。
- 每条观测保留 `snapshot_at/released_at/available_at` 维度。
- 分析侧必须支持 as-of 回放，严禁使用未来修订值回看历史决策。

## 6. 业务规则

| ID | 规则 |
| -- | ---- |
| BR-001 | `uk_cb` 对外只暴露 API、Kafka 事件、`domain_macro` 语义。 |
| BR-002 | 相同 provider+series+period+vintage 写入必须幂等。 |
| BR-003 | `available_at` 是 no-lookahead 判定基准。 |
| BR-004 | Kafka 是 durable event，NATS 不替代 Kafka。 |
| BR-005 | Postgres checkpoint 未推进前，不得标记作业 completed。 |
| BR-006 | 分析默认以 CBI+CHRT 主干指标为先行层，ONS/BoE 为校准与确认层。 |

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
| `cmd/uk-cb-client` | 采集、限流、归档、NATS 发布 | 不写业务库 |
| `cmd/uk-cb-server` | 消费、幂等、持久化、查询 API | 不直连 provider 抓取 |
| `internal/client` | provider 适配、分页、重试、归一化 | 不泄漏 DTO |
| `internal/server` | 作业编排、存储写入、查询服务 | 不保存 secret 值 |
| `internal/cs` | 客户端/服务端契约与校验 | 不承载业务决策 |

## 9. 领域共享层

`uk_cb` 必须使用 `domain_macro` 作为唯一跨模块领域语义层，至少包含 `observed_at/released_at/available_at/vintage_at` 四时间语义。

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

- 决议发布延迟与修订并存。
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
| v1.0.1 | 2026-07-04 | 对齐 uk_cb 语义为 CBI+Companies House 双主源，补齐 DMP/ONS 组合链路 |
| v1.0.0 | 2026-07-04 | 初始化 uk_cb 生产级规格基线 |

## 23. 停止条件

`uk_cb` 形成可审计的生产级 C/S 数据服务，且采集、持久化、事件、回补、no-lookahead 与质量评分链路闭合。
