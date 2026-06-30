# fred 规格

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-30
- Layer: 数据域 · 宏观
- Module-Type: 独立 C/S Module
- Runtime-Service: `fred`
- Goal: [goal.md](goal.md)
- Traceability: [TRACEABILITY.md](TRACEABILITY.md)
- Implementation-Plan: [IMPLEMENTATION-PLAN.md](IMPLEMENTATION-PLAN.md)
- Config-Source: `sre/secrets/env/dev.md`

证据口径：本规格定义目标状态。`/home/fred` 当前实现仍保留旧 `Stores=None` 边界口径，实施阶段必须把该口径迁移为完整持久化服务边界。

## 1. 摘要

`fred` 是数据域 · 宏观的独立 C/S 服务，负责 FRED 宏观数据采集、规范化、修订识别、回放、查询和事件发布。服务必须共享基座组件，必须通过 `domain_macro` 领域共享层输出跨模块语义，必须具备 `taos`、`kafka`、`postgres`、`Redis`、`oss`、`nats`、`clickhouse` 七类持久化与消息能力。配置来源固定为 `sre/secrets/env/dev.md`，规格和源码只声明键名与映射，不记录密钥值。

## 2. 目标

- 建立 `fred` 模块的完整规格、目标架构、追溯矩阵和实施计划。
- 将 `fred` 从进程内 provider adapter 口径升级为独立服务口径。
- 明确 `fred` 与共享基座、`domain_macro`、`macro_data`、下游分析服务之间的边界。
- 明确七类持久化介质的职责、权威性和重建关系。
- 明确 dev 环境配置从 `sre/secrets/env/dev.md` 经共享配置组件映射。

## 3. 非目标

- 不在 `fred` 内实现跨宏观 provider 的统一排序、冲突仲裁或主数据决策。
- 不在 `fred` 内实现因子计算、特征生成、策略研究或回测。
- 不把 provider 原始 DTO 暴露为跨模块公共契约。
- 不在规格、示例、测试夹具或文档中保存 dev secret 值。
- 不把 Redis 或 ClickHouse 定义为唯一权威数据源。

## 4. 用户与消费者

| 消费者 | 使用方式 | 边界 |
| ------ | -------- | ---- |
| `macro_data` | 通过服务 API、Kafka 事件和 `domain_macro` 模型读取宏观数据 | 不依赖 `fred/internal/*` |
| `ms_brain` | 读取 PIT 宏观观测、修订事件、发布日历和 freshness/degrade 元数据，用于 LGIP/M-state、事件覆盖和回放 | 不依赖 `fred/internal/*`，且 `fred` 不承接策略、仓位或状态分类逻辑 |
| 分析域服务 | 读取 ClickHouse 分析读模型或订阅 Kafka 事件 | 不直接调用 FRED provider |
| 运维与数据治理 | 通过 admin API、NATS 控制面和观测指标管理作业 | 不写入业务数据表 |
| 回放与审计任务 | 读取 OSS 原始载荷和 Postgres checkpoint | 不绕过服务幂等账本 |
| Go 调用方 | 使用 `pkg/fredx` client | 不依赖传输实现细节 |

## 5. 功能需求

| ID | WHEN | THEN |
| -- | ---- | ---- |
| FR-001 | WHEN 服务进程启动 | THEN 必须通过共享 `bootstrap` 组装生命周期、readiness、liveness、shutdown 和版本信息。 |
| FR-002 | WHEN 服务加载配置 | THEN 必须通过共享配置组件从 `sre/secrets/env/dev.md` 映射 dev 配置，且不得复制密钥值。 |
| FR-003 | WHEN 拉取 FRED series、observations、releases 或 vintages | THEN client 必须支持分页、限流、退避重试、错误分类和请求审计字段。 |
| FR-004 | WHEN 触发 backfill、incremental ingest、series sync 或 revision scan | THEN server 必须创建可追踪 job、checkpoint 和幂等键。 |
| FR-005 | WHEN provider response 进入规范化流程 | THEN 必须转换为 `domain_macro` 兼容模型，并记录 `released_at`、`available_at`、`vintage_at`。 |
| FR-006 | WHEN 收到 provider 原始响应 | THEN 必须先写入 `oss`，再执行规范化、多存储写入和事件发布。 |
| FR-007 | WHEN observation 通过校验 | THEN 必须写入 `taos`，并支持按 series、时间区间、vintage selector 查询。 |
| FR-008 | WHEN series metadata、release calendar、idempotency ledger 或 checkpoint 变化 | THEN 必须写入 `postgres` 并参与事务边界。 |
| FR-009 | WHEN 查询热点 series、获取分布式锁、维护限流桶或短期游标 | THEN 必须使用 `Redis`，且缓存值必须可由权威数据重建。 |
| FR-010 | WHEN 业务事实形成 | THEN 必须通过 `kafka` 发布版本化事件，事件包含幂等键和 no-lookahead 字段。 |
| FR-011 | WHEN 运维触发 reload、backfill、pause、resume 或 worker heartbeat | THEN 必须通过 `nats` 控制面处理，不替代 Kafka durable event。 |
| FR-012 | WHEN 分析读模型或批量校验结果生成 | THEN 必须写入 `clickhouse`，且可由权威写入流重放重建。 |
| FR-013 | WHEN 外部消费者读取服务数据 | THEN 服务 API 必须提供 series metadata、observation query、job status 和 admin trigger。 |
| FR-014 | WHEN 边界门禁运行 | THEN 必须允许目标存储适配器经共享基座接入，并禁止模块绕过基座组件直连基础设施。 |
| FR-015 | WHEN `ms_brain` 消费宏观数据 | THEN `fred` 必须提供 `ms_brain` integration profile，包含初始序列锚点、PIT observation、revision delta event、release/calendar event、freshness/degrade metadata 和 no-lookahead 查询语义。 |

## 6. 业务规则

| ID | 规则 |
| -- | ---- |
| BR-001 | `fred` 对外只暴露服务 API、Kafka 事件、`pkg/fredx` client 和 `domain_macro` 模型。 |
| BR-002 | 相同 provider、series、period、vintage 的写入必须幂等。 |
| BR-003 | `available_at` 晚于 `released_at` 时，下游只能在 `available_at` 后使用该 observation。 |
| BR-004 | Kafka 是下游异步消费的 durable event 通道；NATS 只承载控制面命令和轻量状态通知。 |
| BR-005 | Postgres checkpoint 成功推进前，backfill job 不得进入 completed 状态。 |
| BR-006 | Redis 与 ClickHouse 均为可重建缓存或读模型，不作为唯一权威源。 |
| BR-007 | OSS 原始载荷路径必须包含 provider、endpoint、日期、job_id 和 content hash。 |
| BR-008 | `macro_data` 不得依赖 `fred/internal/*`、provider DTO 或存储私有表结构。 |
| BR-009 | `fred` 只向 `ms_brain` 提供宏观事实、发布日历、修订、质量和新鲜度语义；不得实现 `ms_brain` 的 M/S 状态分类、LGIP 权重、TradePermission、仓位折扣或风控决策。 |

## 7. 公共 API 契约

| API | 请求字段 | 响应字段 | 约束 |
| --- | -------- | -------- | ---- |
| `GetSeries` | provider、series_id | `MacroSeries` | 返回 `domain_macro` 语义模型 |
| `QueryObservations` | series_id、time range、vintage selector、as_of | `MacroObservation[]` | 必须执行 no-lookahead 过滤 |
| `StartBackfill` | series set、range、mode、priority | `MacroIngestJob` | 必须返回 job_id 和初始 checkpoint |
| `GetJobStatus` | job_id | state、checkpoint、error summary | 必须可观测失败分类 |
| `ScanRevisions` | series set、vintage range | revision job state | 必须记录 detected_at |
| `ReloadConfig` | admin command、request id | accepted 或 rejected | 只允许控制面配置 reload |

## 8. C/S 服务边界

| 组件 | 职责 | 禁止事项 |
| ---- | ---- | -------- |
| `cmd/fred-server` | 服务入口、依赖注入、生命周期、健康检查 | 不写 provider 业务逻辑 |
| `internal/client` | FRED provider client、分页、限流、重试、错误分类 | 不暴露跨模块类型 |
| `internal/server` | 服务 API、作业编排、读写流程 | 不直接保存密钥值 |
| `internal/cs` | 命令、响应、错误码、版本协商 | 不承载 provider DTO |
| `pkg/fredx` | 对外 Go client | 不泄漏 server transport 细节 |
| `scripts/boundary-gates.sh` | 本地边界门禁 | 不保留旧零存储豁免作为目标状态 |

## 9. 领域共享层

`fred` 必须使用 `domain_macro` 作为领域共享层。该层定义宏观时间序列、发布日历、修订版本、信息集时间和 no-lookahead 语义。`fred` 负责把 FRED provider response 转换为该层模型，下游只消费领域模型、服务 API 或事件。

| 模型 | 必备字段 |
| ---- | -------- |
| `MacroSeries` | provider、series_id、title、frequency、units、seasonal_adjustment、source、tags、created_at、updated_at |
| `MacroObservation` | provider、series_id、period_start、period_end、value、unit、released_at、available_at、vintage_at、observed_at |
| `MacroRelease` | release_id、name、scheduled_at、actual_at、timezone、source_url |
| `MacroRevision` | series_id、period_start、old_value、new_value、previous_vintage_at、vintage_at、detected_at |
| `MacroIngestJob` | job_id、series_id、mode、cursor、started_at、finished_at、status、error_class |

### 9.1 `domain_macro` 绑定状态

[COMPUTED][HIGH] 上表 5 个模型为 fred 目标领域语义。`domain-macro` 仓库 v0.1.0 源码（`pkg/domainmacro/`）当前只有 `MacroPoint`（字段 `SeriesCode/Value/ObservedAt/ReleasedAt/AvailableAt/RevisionVersion/IsPreliminary/Source`，含 `Validate()` 与 `IsVisibleAt()` no-lookahead 判定）和 `MacroInformationSet`；`MacroSeries/MacroRelease/MacroRevision/MacroIngestJob` 尚不存在。

[INFERRED][HIGH] 绑定决策（详见 [stage2-contracts-binding-20260622.md](../../report/fred/stage2-contracts-binding-20260622.md) §2）：
- `MacroObservation` 映射到现有 `MacroPoint`，fred 实施期推动 `domain-macro` 补 `provider/unit/period_start/period_end/vintage_at` 字段。
- `MacroSeries/MacroRelease/MacroRevision` 标注为 fred 实施期在 `domain-macro` 补齐。
- `MacroIngestJob` 为 fred internal 定义，不进 `domain-macro`。
- FRED DTO → `MacroPoint` 字段映射见 stage2 报告 §2.3。

[INFERRED][HIGH] 该决策需在阶段 3 实施前由数据域 owner 确认（OPEN-006）。若选方案 A（`domain-macro` 预先补齐 5 类型），需 `domain-macro` 发 v0.2.0。

### 9.2 `ms_brain` 初始数据契约

`ms_brain` 当前配置和规格要求宏观数据支持 PIT、发布延迟、修订、事件覆盖和数据质量降级。`fred` 的初始 integration profile 必须覆盖下列 FRED 序列锚点；非 FRED 或混合来源数据只在 FRED 端点具备权威来源时由 `fred` 负责，否则通过 `source_component` 标记外部来源并交由上游数据域路由。

| 类别 | 初始序列锚点 | `fred` 输出要求 |
| ---- | ------------ | --------------- |
| Real yield / inflation | `DFII10`、`T10YIE`、`DFF` | 支持日度刷新、as-of 查询、freshness/degrade 标记。 |
| Credit / cycle | `BAMLH0A0HYM2`、`T10Y2Y`、`ICSA` | 支持 revision scan、release lag、missing value 语义和 `MacroRevisionObserved`。 |
| Fiscal | `FYFSGDA188S`、`FDHBFRBN` | 支持月度/季度发布延迟；`FDHBFRBN` 如需 Treasury.gov 组合输入，必须显式标记 `source_component`。 |
| Event/replay | release calendar、revision delta、data_version | 支持 Kafka durable event、ClickHouse 读模型和 no-lookahead replay。 |

## 10. 持久化模型

| 介质 | 职责 | 权威性 |
| ---- | ---- | ------ |
| `taos` | 按 series、period、vintage 存储规范化 observation | 时间序列事实权威 |
| `kafka` | 发布 `MacroSeriesDiscovered`、`MacroObservationUpserted`、`MacroRevisionObserved`、`FredBackfillCompleted`、`FredIngestFailed` | durable event 权威 |
| `postgres` | series catalog、release calendar、checkpoint、idempotency ledger、schema migration state | 控制平面权威 |
| `Redis` | 热缓存、分布式锁、限流桶、短期游标 | 可重建缓存 |
| `oss` | FRED raw response、回放批次、错误样本、审计快照 | 原始载荷权威 |
| `nats` | admin command、reload signal、backfill trigger、worker heartbeat | 控制面传输 |
| `clickhouse` | 分析宽表、materialized view、批量校验结果 | 可重建读模型 |

## 11. 配置模式

配置来源为 `sre/secrets/env/dev.md`。`fred` 只声明配置分类、键名映射和必填性，不在仓库文档或源码中保存 secret 值。

| 配置类别 | 键名类别 | 必填性 |
| -------- | -------- | ------ |
| FRED provider | credential reference、base URL、timeout、rate limit、user agent | required |
| Postgres | DSN reference、schema、pool size、migration flag | required |
| TDengine | endpoint、database、retention、batch size | required |
| Kafka | brokers、topic prefix、producer options、consumer group | required |
| Redis | address、DB、TTL、lock namespace | required |
| OSS | bucket、prefix、region、credential reference | required |
| NATS | server URL、subject prefix、queue group | required |
| ClickHouse | DSN reference、database、table prefix、batch settings | required |
| Observability | service name、log level、metrics endpoint、trace exporter | required |

## 12. 错误处理

| 错误类 | 服务行为 | 验证证据 |
| ------ | -------- | -------- |
| Provider rate limit | 使用共享 resiliency 组件退避，维护 Redis rate bucket | rate limit 指标与重试日志 |
| Provider schema drift | 原始载荷进入 OSS，规范化流程隔离该批次 | drift error event 与 OSS key |
| Partial store failure | 保留 checkpoint，不确认 job 完成 | checkpoint 状态与补偿任务 |
| Duplicate payload | 根据幂等键跳过副作用 | idempotency ledger 命中记录 |
| Missing secret reference | 启动失败或 readiness failed | 配置校验错误 |
| Kafka publish failure | 不推进已发布水位，保留 outbox 记录 | outbox backlog 指标 |

## 13. 边界情况

| 场景 | 处理 |
| ---- | ---- |
| FRED 返回 `.`、空值或单位变化 | 转换层保留缺失语义，并记录单位版本 |
| 历史 period 出现新 vintage | 生成 revision 记录和 `MacroRevisionObserved` 事件 |
| 发布日历晚到或更正 | 更新 Postgres release calendar，并保留 previous value |
| 查询 as_of 早于 `available_at` | 返回空结果或不含未来 observation |
| OSS raw 写入成功但下游写入失败 | checkpoint 不推进，后续从 OSS 回放 |
| ClickHouse 重建 | 从 Kafka event 或权威存储重放生成读模型 |

## 14. 目录结构

| 路径 | 目标职责 |
| ---- | -------- |
| `cmd/fred-server/` | 独立服务入口 |
| `pkg/fredx/` | 对外稳定 Go client |
| `internal/client/` | FRED provider client |
| `internal/server/` | API handler、job 编排、读写流程 |
| `internal/cs/` | C/S 契约、错误码、版本协商 |
| `internal/domain/` | provider response 到 `domain_macro` 的转换 |
| `internal/store/` | 经共享基座封装的存储端口与适配器 |
| `internal/events/` | Kafka event schema 与 outbox |
| `internal/control/` | NATS 控制面命令 |
| `scripts/` | 边界、lint、集成校验脚本 |

## 15. 依赖

| 依赖 | 用途 | 边界 |
| ---- | ---- | ---- |
| `bootstrap` | 生命周期、健康检查、shutdown | 必须作为入口组装层 |
| `configx` | dev 配置映射 | 不保存 secret 值 |
| `observex` | 日志、指标、trace | 所有 job 带 correlation id |
| `resiliencx` | 重试、熔断、退避、限流 | provider client 必须接入 |
| `contracts` / `transportx` | API 与事件契约版本化 | 公共契约必须可校验 |
| `taosx`、`kafkax`、`postgresx`、`redisx`、`ossx`、`natsx`、`clickhousex` | 七类基础设施访问 | 只能经共享基座访问 |
| `domain_macro` | 宏观领域模型与 no-lookahead 语义 | 对外模型必须来自该层 |

## 16. 测试

| ID | 覆盖对象 | 关联需求 |
| -- | -------- | -------- |
| TC-001 | `pkg/fredx` 参数编码、错误分类、分页 | FR-003、FR-013 |
| TC-002 | provider response 到 `domain_macro` 的转换 | FR-005、BR-001 |
| TC-003 | 重复 observation、重复 event、重复 backfill job 幂等 | FR-004、BR-002 |
| TC-004 | OSS raw、Postgres checkpoint、TDengine observation、Kafka event、ClickHouse read model 的集成写入 | FR-006、FR-007、FR-008、FR-010、FR-012 |
| TC-005 | Redis 缓存清空后的查询重建 | FR-009、BR-006 |
| TC-006 | NATS admin trigger 与 Kafka durable event 分离 | FR-011、BR-004 |
| TC-007 | as_of 查询 no-lookahead | FR-005、BR-003 |
| TC-008 | 边界脚本阻断绕过共享基座的直连实现 | FR-014 |
| TC-009 | `ms_brain` profile fixture 覆盖初始序列锚点、PIT/no-lookahead、freshness/degrade 和发布日历事件 | FR-015、BR-009 |

## 17. 性能预算

| 指标 | 预算 |
| ---- | ---- |
| 单 series incremental ingest | dev 环境 P95 小于 5 秒，不含 provider 等待时间 |
| observation 批量写入 | 每批不超过共享基座批量上限，失败批次可重放 |
| API 查询 | 热点 series 查询 P95 小于 300 毫秒 |
| Kafka publish lag | 稳态小于 10 秒 |
| ClickHouse read model lag | 稳态小于 60 秒 |
| OSS raw 归档 | 每个 provider response 在规范化前完成 |

## 18. 可观测性

| 类型 | 指标或字段 |
| ---- | ---------- |
| Logs | job_id、series_id、provider endpoint、request id、error_class |
| Metrics | ingest_count、revision_count、rate_limit_wait、store_write_latency、event_publish_lag |
| Traces | provider request、raw archive、normalize、store write、event publish |
| Health | provider config loaded、store connectivity、Kafka producer readiness、NATS control readiness |
| Audit | OSS raw key、content hash、idempotency key、checkpoint version |

## 19. 安全

| 控制点 | 要求 |
| ------ | ---- |
| Secret handling | 只保存 secret reference，不在仓库文档、日志或错误消息中输出值 |
| Config source | dev 环境只从 `sre/secrets/env/dev.md` 映射 |
| Admin API | 必须有鉴权、请求 id 和审计日志 |
| OSS raw payload | 路径含 hash，访问受最小权限约束 |
| Event payload | 不包含 secret、账户凭证或私有端点值 |
| Logs | provider request 记录不包含 credential value |

## 20. CI 门禁

| Gate | 命令或检查 |
| ---- | ---------- |
| Markdown patch | `git diff --check` |
| Spec structure | `.github/ci/spec-lint.sh` 中 `fred` 必须达到 23/23 sections |
| Traceability | `TRACEABILITY.md` 必须闭合 Goal、FR、BR、AC、TC |
| Boundary | `scripts/boundary-gates.sh` 必须允许目标存储经共享基座接入，并禁止直连 |
| Secret scan | 对 `module/fred` 与服务源码执行 secret-like assignment 扫描 |
| Go checks | `go test ./...` 与边界测试通过 |
| Integration | dev 配置下完成单 series 端到端写入验证 |

## 21. 升级兼容性

| 变更 | 兼容策略 |
| ---- | -------- |
| 旧零存储门禁迁移 | 先修改边界声明，再接入共享基座存储端口 |
| API 版本升级 | 通过 `internal/cs` 与 `pkg/fredx` 做版本协商 |
| Event schema 升级 | Kafka event 带 schema version 与兼容读者 |
| Store schema 升级 | Postgres migration state 记录迁移版本 |
| ClickHouse 重建 | 从 Kafka event 或权威存储重放 |
| Redis key 变更 | 使用 namespace version，旧 key 可过期 |

## 22. 发布 DoD

| ID | 完成条件 |
| -- | -------- |
| AC-001 | `fred` dev 服务可启动，并暴露 health、version、readiness。 |
| AC-002 | 配置扫描证明 `module/fred` 和源码不包含 dev secret 值。 |
| AC-003 | 单 series backfill 完成 OSS raw、Postgres metadata/checkpoint、TDengine observation、Kafka event、ClickHouse read model 写入。 |
| AC-004 | Redis 缓存清空后，查询结果可由权威存储重建。 |
| AC-005 | NATS admin trigger 可启动受控 backfill，且不会替代 Kafka durable event。 |
| AC-006 | no-lookahead 测试证明查询不会提前暴露未来 vintage。 |
| AC-007 | 边界门禁禁止绕过共享基座组件的基础设施直连。 |
| AC-008 | 追溯矩阵闭合 Goal、FR、BR、AC、TC，并记录剩余风险。 |
| AC-009 | `ms_brain` integration profile 可查询初始序列锚点和 release/calendar 事件，并在缺失、滞后或修订数据上输出可解释的质量标记。 |

## 23. 待解决问题

| ID | 问题 | 关闭条件 |
| -- | ---- | -------- |
| OPEN-001 | `/home/fred` 旧 `Stores=None` 注释和边界脚本仍需迁移 | 边界门禁改为允许七类目标存储经共享基座接入 |
| OPEN-002 | `domain_macro` 具体包路径与字段名需以实现仓库为准 | 实施前完成领域共享层 API 对齐 |
| OPEN-003 | `sre/secrets/env/dev.md` 的键名需映射到 `configx` schema | dev 配置 schema 审查通过且不暴露值 |
| OPEN-004 | 七类介质的本地集成环境需确认可用性 | integration profile 可启动并跑通单 series 验证 |
| OPEN-005 | `ms_brain` 当前仍以文档、规格和配置为主，尚无可运行消费者契约测试 | `/home/ms_brain` 提供 runtime fixture 或 contract test 后纳入 `fred` 集成验收 |
| OPEN-006 | `domain_macro` 绑定方案待定：SPEC §9 五模型与 `domain-macro` v0.1.0 源码（仅 `MacroPoint`）不一致，方案 A（`domain-macro` 补齐发 v0.2.0）vs 方案 B（SPEC 锚定 `MacroPoint`，fred 实施期补） | 数据域 owner 确认方案，详见 stage2 报告 §2 |
