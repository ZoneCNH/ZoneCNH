# treasury 规格

- Status: Planned（Production Target）
- Spec-Version: v0.2.0
- Last-Updated: 2026-07-03
- Layer: 数据域 · 宏观
- Module-Type: 独立 C/S Module（多子模块双服务）
- Runtime-Service: `treasury-{yield,auction,fiscal,tic}-{client,server}`
- Goal: [goal/goal.md](../goal/goal.md)
- Traceability: [matrix/TRACEABILITY.md](../matrix/TRACEABILITY.md)
- Implementation-Plan: [plan/PLAN.md](../plan/PLAN.md)
- Features: [FEATURES.md](FEATURES.md)
- Acceptance: [ACCEPTANCE.md](ACCEPTANCE.md)
- Runtime-Repo: `/home/workspace/treasury`
- Template-Reference: `module/binance`

> 本规格定义 `treasury` 的生产目标状态。运行时实现、测试和发布证据以 `/home/workspace/treasury` 为准。

---

## 1. 摘要

`treasury` 是数据域 · 宏观的美国国债/财政数据服务。它不是单一抓取器，而是由 `yield`、`auction`、`fiscal`、`tic` 四个可独立部署的 C/S 子模块组成。所有子模块必须：

1. 复用共享基座组件（配置、观测、弹性、基础设施适配器）；
2. 统一通过 `domain_macro` 输出领域语义（含 no-lookahead 时间字段）；
3. 完整落地 `taos + kafka + postgres + Redis + oss + nats + clickhouse`。

样板对齐原则：目录分层、追溯闭合、验收门禁与 C/S 边界写法对齐 `module/binance`，并按宏观数据域特性扩展采集与同步策略。

---

## 2. 目标

- 建立 `treasury` 四子模块独立 C/S 服务边界与统一治理口径。
- 明确采集清单、更新频率、同步周期、历史起点与采集策略。
- 输出可回放、可审计、可追溯的宏观财政事实数据。
- 为 `macro_data`、`factor_engine`、`macro_regime` 提供稳定查询/事件契约。

---

## 3. 非目标

- 不在 `treasury` 内实现跨 provider 聚合、冲突仲裁或主数据决策。
- 不在 `treasury` 内实现因子计算、策略决策、交易或风控。
- 不向下游暴露 provider 原始 DTO 作为长期契约。
- 不在文档或代码中提交 secret 值。

---

## 4. 用户与消费者

| 消费者 | 使用方式 | 边界 |
| ------ | -------- | ---- |
| `macro_data` | 通过 API、Kafka 事件、`domain_macro` 模型消费 | 不依赖 `treasury/internal/*` |
| `factor_engine` / `macro_regime` | 读取期限结构、财政流、海外需求相关宏观事实 | 不依赖 provider DTO |
| 运维治理 | 通过 admin API 与 NATS 控制面管理作业 | 不写业务事实表 |
| 回放审计任务 | 读取 OSS raw 与 Postgres checkpoint | 不绕过幂等账本 |

---

## 5. 功能需求

| ID | WHEN | THEN |
| -- | ---- | ---- |
| FR-TRY-001 | WHEN 任一子模块启动 | THEN 必须以独立 client/server 双服务运行并暴露 health/readiness/version。 |
| FR-TRY-002 | WHEN 服务加载配置 | THEN 必须经共享配置组件加载，且只使用 secret reference。 |
| FR-TRY-003 | WHEN 采集收益率曲线 | THEN 必须覆盖 Par/Real/Bill/Long-Term 曲线并标准化期限结构。 |
| FR-TRY-004 | WHEN 采集拍卖数据 | THEN 必须覆盖拍卖日历、公告、结果与关键发行字段。 |
| FR-TRY-005 | WHEN 采集财政与债务数据 | THEN 必须覆盖 DTS（日）、MTS（月）、Debt to the Penny、Revenue Collections 与 Exchange Rates，并保留发布时间语义。 |
| FR-TRY-006 | WHEN 采集 TIC | THEN 必须覆盖月度持仓/净流入核心口径并保留修订版本。 |
| FR-TRY-007 | WHEN provider 响应进入规范化流程 | THEN 必须转换为 `domain_macro` 语义并写入 `observed_at/released_at/available_at/vintage_at`。 |
| FR-TRY-008 | WHEN 收到原始响应 | THEN 必须先写 OSS raw，再执行归一化、存储写入与事件发布。 |
| FR-TRY-009 | WHEN client 输出 ingest/control 消息 | THEN 必须使用 NATS handoff/control subject，不替代 Kafka durable event。 |
| FR-TRY-010 | WHEN metadata/checkpoint/idempotency 变化 | THEN 必须写入 Postgres 并保持事务一致性。 |
| FR-TRY-011 | WHEN 时序观测通过校验 | THEN 必须写入 taos 并支持按时间、期限、vintage 查询。 |
| FR-TRY-012 | WHEN 业务事实形成 | THEN 必须发布版本化 Kafka 事件（含 idempotency key 与数据时间语义）。 |
| FR-TRY-013 | WHEN 需要分析读模型 | THEN 必须写入 ClickHouse，且支持从权威流重建。 |
| FR-TRY-014 | WHEN 查询热点数据或执行分布式协调 | THEN 必须使用 Redis 缓存、锁与限流桶，且可重建。 |
| FR-TRY-015 | WHEN 外部读取服务数据 | THEN API 必须提供曲线、拍卖、财政、TIC、覆盖率、作业管理与配置重载能力。 |
| FR-TRY-016 | WHEN 执行增量/全量同步、full sync 或治理审计 | THEN 必须输出覆盖率报告并支持缺口重采、手动重同步与可追溯闭环。 |

### 5.1 模块采集清单（子模块独立 C/S）

| 子模块 | 来源/端点族 | 采集内容 | 输出主题 |
| ------ | ----------- | -------- | -------- |
| `yield` | Treasury Interest Rates 数据集 | 名义/实际/短券/长期收益率与期限结构 | `treasury.yield.*` |
| `auction` | TreasuryDirect Securities / Auctions | 拍卖日历、公告、结果、发行结构 | `treasury.auction.*` |
| `fiscal` | DTS / MTS / Debt to the Penny / Revenue / Exchange Rates | TGA、收入支出、赤字、债务余额、汇率口径 | `treasury.fiscal.*` |
| `tic` | TIC 月度发布 | 海外持仓、净流入/流出、国家维度口径 | `treasury.tic.*` |

#### 5.1.1 Fiscal Data API 分类映射（>80 endpoint）

| 官方分类 | 典型数据集 | `treasury` 子模块映射 |
| -------- | ---------- | --------------------- |
| National Debt | Debt to the Penny | `fiscal` |
| Interest Rates | Yield Curve / Real Yield | `yield` |
| Exchange Rates | Treasury Exchange Rates | `fiscal` |
| Daily / Monthly Statements | DTS / MTS | `fiscal` |
| Securities | Auctions / Offerings | `auction` |
| Revenue Collections | Tax / Customs Aggregates | `fiscal` |
| International Capital | TIC | `tic` |

### 5.2 定时更新频率与同步周期

| 子模块 | 默认调度频率 | 增量同步周期 | 全量对账周期 | 修订回拉窗口 | 主同步模式 | 目标单轮耗时 |
| ------ | ------------ | ------------ | ------------ | ------------ | ---------- | ------------ |
| `yield` | 每交易日 + 发布窗口 15min 轮询 | 1h | 每月首个交易日 | 最近 30 天 | 增量为主 + 手动全量 | ≤30min |
| `auction` | 拍卖日 10min；非拍卖日日频 | 30min | 每周 | 最近 90 天 | 增量为主 + 手动全量 | ≤30min |
| `fiscal` | DTS 小时级；MTS 发布后 4h 内 | DTS 1h / MTS 6h | 每月 | 最近 180 天 | 增量为主 + 手动全量 | ≤30min |
| `tic` | 发布周 6h；其余每日 | 24h | 每月 | 最近 24 个月 | 增量为主 + 手动全量 | ≤30min |

调度时点约定：美国财政部日度批次默认按 ET 16:00 发布窗口触发解析；若窗口异常则按轮询兜底重试。

### 5.3 历史数据同步启点（工程默认）

| 子模块 | 默认历史起点 | 规则 |
| ------ | ------------ | ---- |
| `yield` | `1990-01-01` | 若源站最早可用日更晚，则以源站最早日期为准 |
| `auction` | `2003-01-01` | 若公告/结果分段可用，按分段起点回补 |
| `fiscal` | DTS:`2005-01-01` / MTS:`2000-01-01` / Debt:`1993-01-01` | DTS、MTS、Debt 分别维护起点与游标；支持按数据族独立回补 |
| `tic` | `2000-01-01` | 以月度周期回补，保留版本修订记录 |

历史窗口支持 `StartBackfill` 指定起始日期。`Debt to the Penny` 可用窗口从 `1993-01` 开始，工程上默认全量回补。

### 5.4 采集策略

| 策略 | 规则 |
| ---- | ---- |
| Open REST Pull | 默认通过 Fiscal Data API GET 拉取（JSON/CSV），无需 API key。 |
| Raw-First | 所有响应先落 OSS raw（带 hash、job_id、endpoint），再进入归一化。 |
| Incremental + Full Re-sync | 日常增量同步；初始化/迁移/修复支持手动全量重同步。 |
| Calendar-First | 发布日历触发优先，定时轮询兜底；避免仅靠固定 cron 漏采。 |
| Idempotent Pipeline | 用 Postgres ledger + checkpoint + idempotency key 保证重放不重复副作用。 |
| Dual-Bus | NATS 仅 ingest/control；Kafka 仅 durable downstream event。 |
| Warehouse Push（可选） | 可将标准化数据定期推送至 Snowflake/BigQuery，减少下游轮询成本。 |
| ETL/ELT 分层 | 采集先入 staging，再标准化加载贴源层/整合层。 |
| Tiered Storage | staging 仅保留近 1 个月；贴源层保留全量历史 + 最新快照副本。 |
| Multi-Store Authority | taos（时序事实）+ postgres（控制面）+ oss（原始载荷）为权威层；Redis/ClickHouse 为可重建层。 |
| Gap Replay | 覆盖率审计发现缺口时，自动生成重采任务并闭合到 traceability。 |

### 5.5 同步方式与重同步策略

| 模式 | 触发条件 | 说明 |
| ---- | -------- | ---- |
| 增量同步 | 定时调度/发布触发 | 仅同步上次游标后变更，作为默认主路径。 |
| 全量同步（Full Sync） | 初始化、迁移、数据修复、月度兜底 | 拉取完整窗口，生成干净副本并重建校验基线。 |
| 手动重同步（Re-sync） | 运维/API 手动触发 | 支持按子模块、按日期范围、按数据族重跑。 |

单轮同步目标耗时 ≤30 分钟；超时任务需自动分片并进入重试队列。

---

## 6. 行为约束

| ID | 规则 |
| -- | ---- |
| BR-TRY-001 | 四个子模块均保持独立 C/S 进程边界，不得退化为单体进程 handoff。 |
| BR-TRY-002 | `available_at` 是 no-lookahead 判定依据，缺失时不得出域。 |
| BR-TRY-003 | 同一 provider/series/period/vintage 的写入必须幂等。 |
| BR-TRY-004 | Kafka durable event 与 NATS handoff/control 必须严格分层。 |
| BR-TRY-005 | Postgres checkpoint 成功推进前，作业不得标记 completed。 |
| BR-TRY-006 | Redis 与 ClickHouse 仅作为可重建层，不作为唯一权威源。 |
| BR-TRY-007 | OSS raw 路径必须包含 provider、endpoint、date、job_id、content hash。 |
| BR-TRY-008 | 下游只能依赖 API/Kafka/`domain_macro`，不得依赖 provider DTO 与私有表。 |
| BR-TRY-009 | 发布日历触发优先于固定轮询，轮询只做兜底。 |
| BR-TRY-010 | 历史起点、增量游标、修订回拉窗口必须版本化可审计。 |

---

## 7. 非功能需求

| ID | 类别 | 要求 |
| -- | ---- | ---- |
| NFR-TRY-001 | Freshness | 日频数据最大滞后 <24h；月频数据发布后 <48h 完成有效同步。 |
| NFR-TRY-002 | Latency | 增量采集到可查询链路 P95 <10min（不含上游发布时间）。 |
| NFR-TRY-003 | Throughput | 支持子模块并行 backfill，且互不阻塞。 |
| NFR-TRY-004 | Reliability | 任一存储写入失败不得推进 checkpoint；必须可重放恢复。 |
| NFR-TRY-005 | Observability | 每个 job 具备 request_id、job_id、endpoint、error_class、store_lag 指标。 |
| NFR-TRY-006 | Security | 文档/日志/错误输出不暴露 secret 值，仅允许 secret reference。 |
| NFR-TRY-007 | Governance | 采集覆盖率、缺口任务、回放证据必须可追溯到 matrix/acceptance。 |

---

## 8. Acceptance Criteria Registry

| AC | 验收摘要 | 覆盖需求 |
| -- | -------- | -------- |
| AC-TRY-001 | 四子模块 client/server 可独立启动并通过 health/readiness。 | FR-TRY-001 |
| AC-TRY-002 | 配置加载仅使用 secret reference，且通过 redaction 扫描。 | FR-TRY-002, NFR-TRY-006 |
| AC-TRY-003 | 采集清单四子模块端点覆盖完整并通过契约测试。 | FR-TRY-003~006 |
| AC-TRY-004 | no-lookahead 语义正确：`available_at` 缺失或未来数据被拒绝。 | FR-TRY-007, BR-TRY-002 |
| AC-TRY-005 | raw-first + 多存储写入链路闭合，失败可回放恢复。 | FR-TRY-008, FR-TRY-010~014 |
| AC-TRY-006 | NATS/Kafka 双总线分层验证通过。 | FR-TRY-009, FR-TRY-012, BR-TRY-004 |
| AC-TRY-007 | API 契约满足查询与作业控制场景。 | FR-TRY-015 |
| AC-TRY-008 | 覆盖率审计可发现缺口并自动生成重采任务。 | FR-TRY-016, BR-TRY-010 |
| AC-TRY-009 | 边界门禁禁止绕过共享基座直连基础设施。 | BR-TRY-001, BR-TRY-008 |
| AC-TRY-010 | 宏观分析补充项（见 §21）具备最小可用输出与证据。 | BR-TRY-009, NFR-TRY-007 |

---

## 9. 追溯与测试门禁

追溯矩阵见 [matrix/TRACEABILITY.md](../matrix/TRACEABILITY.md)。本规格的 FR/BR/NFR/AC/TC 变更必须同步更新矩阵与验收文档，并保持编号一致。

---

## 10. 版本记录

| 日期 | 版本 | 变更 | 作者 |
| ---- | ---- | ---- | ---- |
| 2026-07-03 | v0.2.0 | 从 Draft 占位升级为生产目标规格：补齐采集清单、更新频率、同步周期、历史起点、采集策略、宏观分析补充项 | ZoneCNH |
| 2026-06-30 | v0.1.0 | 初始占位规格 | ZoneCNH |

---

## 11. 错误处理

| 错误类 | 服务行为 | 证据 |
| ------ | -------- | ---- |
| Source rate limit / 429 | 限流退避，不推进 checkpoint | rate_limit_wait 指标 |
| Schema drift | raw 入 OSS，隔离异常批次并告警 | drift event + raw key |
| Partial store failure | 保留 checkpoint，创建补偿任务 | replay queue / backlog |
| Duplicate payload | 按幂等键跳过副作用 | idempotency ledger |
| Missing secret reference | 启动失败或 readiness failed | config validation log |
| Revision detected | 触发回拉窗口重算与 revision event | revision job report |

---

## 12. 边界情况

| 场景 | 处理 |
| ---- | ---- |
| 上游临时停更或延迟发布 | 标记 freshness 降级，继续轮询并保留最后有效版本。 |
| 同一日期多次修订 | 记录 `vintage_at` 链并输出修订事件。 |
| 拍卖取消/重排期 | 更新日历状态并触发重采计划。 |
| 月度数据晚发布 | 日历驱动补采 + 48h 窗口内高频重试。 |
| OSS 成功但下游失败 | 不推进 checkpoint，从 raw 重放。 |

---

## 13. 目录结构

| 路径 | 目标职责 |
| ---- | -------- |
| `cmd/treasury-yield-client/` | 收益率子模块采集入口 |
| `cmd/treasury-yield-server/` | 收益率子模块消费/查询入口 |
| `cmd/treasury-auction-client/` | 拍卖子模块采集入口 |
| `cmd/treasury-auction-server/` | 拍卖子模块消费/查询入口 |
| `cmd/treasury-fiscal-client/` | 财政子模块采集入口 |
| `cmd/treasury-fiscal-server/` | 财政子模块消费/查询入口 |
| `cmd/treasury-tic-client/` | TIC 子模块采集入口 |
| `cmd/treasury-tic-server/` | TIC 子模块消费/查询入口 |
| `internal/client/` | provider client、调度、归一化 |
| `internal/server/` | consumer、存储编排、API |
| `internal/cs/` | C/S 契约、错误码、版本协商 |
| `pkg/treasuryx/` | 对外稳定 Go client |
| `scripts/` | boundary gate、lint、集成校验 |

---

## 14. 依赖

| 依赖 | 用途 | 边界 |
| ---- | ---- | ---- |
| `bootstrap` | 生命周期与服务装配 | 必须作为入口编排层 |
| `configx` | 配置映射与校验 | 仅引用 secret reference |
| `observex` | 日志、指标、trace | 所有 job 带 correlation id |
| `resiliencx` | 重试、熔断、限流 | 全部采集 client 强制接入 |
| `contracts` / `transportx` | API 与事件契约版本化 | 公共契约必须可校验 |
| `domain_macro` | 领域共享语义与 no-lookahead | 对外模型必须来自该层 |
| `taosx` / `kafkax` / `postgresx` / `redisx` / `ossx` / `natsx` / `clickhousex` | 七类基础设施访问 | 只能经共享基座访问 |

---

## 15. 测试

| TC | 覆盖对象 | 关联需求 |
| -- | -------- | -------- |
| TC-TRY-001 | 四子模块端点覆盖与解析测试 | FR-TRY-003~006 |
| TC-TRY-002 | `domain_macro` 归一化与 no-lookahead 测试 | FR-TRY-007, BR-TRY-002 |
| TC-TRY-003 | checkpoint + 幂等账本一致性 | FR-TRY-010, BR-TRY-003, BR-TRY-005 |
| TC-TRY-004 | OSS→Postgres→taos→Kafka→ClickHouse 集成写入 | FR-TRY-008, FR-TRY-011~013 |
| TC-TRY-005 | NATS ingest/control 与 Kafka durable event 分层 | FR-TRY-009, FR-TRY-012, BR-TRY-004 |
| TC-TRY-006 | API 查询与作业控制契约测试 | FR-TRY-015 |
| TC-TRY-007 | 调度器频率与发布触发策略测试 | §5.2, BR-TRY-009 |
| TC-TRY-008 | 历史起点 backfill 与修订回拉窗口测试 | §5.3, FR-TRY-016 |
| TC-TRY-009 | boundary gates 阻断直连实现 | BR-TRY-001, BR-TRY-008 |
| TC-TRY-010 | 覆盖率审计与缺口重采闭环测试 | FR-TRY-016, AC-TRY-008 |

---

## 16. 性能预算

| 指标 | 预算 |
| ---- | ---- |
| 增量采集链路 | P95 <10min（不含上游发布时间） |
| API 热点查询 | P95 <300ms |
| Kafka publish lag | 稳态 <10s |
| ClickHouse read model lag | 稳态 <60s |
| 日频 freshness | <24h |
| 月频 freshness | <48h |

---

## 17. 可观测性

| 类型 | 指标或字段 |
| ---- | ---------- |
| Logs | module、job_id、endpoint、release_slot、error_class |
| Metrics | ingest_count、freshness_lag_sec、revision_count、store_write_latency、publish_lag |
| Traces | fetch、raw_archive、normalize、store_write、event_publish、api_query |
| Health | source connectivity、store readiness、bus readiness、scheduler status |
| Audit | raw key、hash、idempotency key、checkpoint version、coverage ratio |

---

## 18. 安全

| 控制点 | 要求 |
| ------ | ---- |
| Secret handling | 仅保存 secret reference，不输出 secret 值 |
| Access control | admin API 必须鉴权、审计、限流 |
| Event payload | 不包含凭证、私有端点或敏感配置 |
| OSS raw | 最小权限访问，路径含 hash 便于审计 |
| Log redaction | 错误日志禁止打印密钥与连接串明文 |

---

## 19. CI 门禁

| Gate | 命令或检查 |
| ---- | ---------- |
| Markdown patch | `git diff --check` |
| Spec structure | `.github/ci/spec-lint.sh`（`treasury` 需保持 23 节） |
| Traceability | `.github/ci/traceability-check.sh` |
| Boundary | `bash scripts/boundary-gates.sh` |
| Go checks | `go test ./...`、`go vet ./...` |
| Secret scan | `gitleaks detect --no-git`（runtime 仓） |

---

## 20. 升级兼容性

| 变更 | 兼容策略 |
| ---- | -------- |
| 新增子模块 | 子模块独立版本与迁移脚本，避免跨模块破坏性变更 |
| API 升级 | 通过 `internal/cs` 与 `pkg/treasuryx` 版本协商 |
| Event schema 升级 | Kafka event 强制 schema version 与兼容读者 |
| 存储 schema 升级 | Postgres migration state 记录并可回滚 |
| Redis key 升级 | namespace version + TTL 迁移 |

---

## 21. 做宏观分析还需补充项

| 补充项 | 目的 | 最小交付 |
| ------ | ---- | -------- |
| 核心宏观联动（GDP/CPI/PPI/就业/消费） | 避免仅凭财政数据做单因子判断 | 与 FRED/BLS 指标的联动视图与滞后校正 |
| 美联储货币政策联动 | 建立财政-货币联合解释框架 | 联邦基金利率、OMO、资产负债表字段映射 |
| 发布日历与时区标准化 | 避免“已发布未可用”误判 | release calendar + timezone 归一规则 |
| Surprise 因子（实际 vs 预期） | 提升事件解释能力 | `actual/consensus/surprise_z` 字段 |
| 期限结构衍生特征 | 支持宏观 regime 判定 | `2s10s`、`3m10y`、`real_yield_spread` |
| 财政脉冲与供给压力 | 连接债务发行与流动性冲击 | `net_issuance`、`deficit_impulse` |
| 财政可持续性评估 | 识别债务与利息负担风险 | `interest_to_gdp`、`interest_to_revenue`、债务结构拆分 |
| 拍卖融资质量 | 评估一级市场需求强弱 | `bid_to_cover`、tail、得标利率偏离 |
| 海外需求稳定性 | 识别外需拐点 | TIC 持仓变化与集中度指标 |
| 全球比较框架（G7） | 定位美国财政与利率所处相对位置 | G7 债务率/赤字率/利率曲线对比面板 |
| 高频补充（期货/互换） | 捕捉日内政策预期变化 | 国债期货、利率互换基差实时特征 |
| 另类数据补充 | 提升政策预期与风险预警敏感度 | 评级展望、政策新闻情绪特征 |
| 跨源对账（Treasury vs FRED） | 降低口径漂移风险 | 定期对账报表与偏差阈值告警 |
| 版本链与修订可见性 | 保证回测无前视偏差 | `released_at/available_at/vintage_at` 全链证据 |
| 数据质量分级 | 下游按质量降级决策 | completeness/freshness/anomaly score |
| 数据治理与环境隔离 | 防止口径漂移与测试污染生产 | 字段血缘字典 + 质量监控任务 + prod/sandbox 隔离规则 |

---

## 22. 运行时边界

| 组件 | 职责 | 禁止事项 |
| ---- | ---- | -------- |
| `*-client` | 采集、归一化、NATS 发布 | 不直接写业务权威存储 |
| `*-server` | 消费、持久化、查询 API、Kafka 事件 | 不直接抓上游源站 |
| `internal/cs` | 子模块契约、错误码、版本协商 | 不承载业务策略 |
| `pkg/treasuryx` | 对外 Go client | 不泄漏传输层实现细节 |
| `scripts/boundary-gates.sh` | 边界门禁 | 不允许直连基础设施绕过基座 |

---

## 23. 变更历史

| 日期 | 版本 | 变更 | 作者 |
| ---- | ---- | ---- | ---- |
| 2026-07-03 | v0.2.0 | 完整补齐生产目标规格（采集清单、频率、周期、起点、策略、宏观分析补充项） | ZoneCNH |
| 2026-06-30 | v0.1.0 | Draft 占位规格初始化 | ZoneCNH |
