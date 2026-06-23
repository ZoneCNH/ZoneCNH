# binance 完整实现清单

## 元数据

| 字段 | 值 |
| --- | --- |
| Status | Generated from current module SSOT |
| Last-Updated | 2026-06-23 |
| Module-Version | v3.5.0 |
| Module-State | 规格扩展到 v3.1.0；FR-009 boundary 已有本地 runtime 证据，其余 FR 仍以 `/home/binance` 证据为准 |
| Layer | 数据域 / Binance-specific market_data C/S module |
| Runtime-Repo | `/home/binance` |
| Source | `goal.md`, `SPEC.md`, `TRACEABILITY.md`, `DATA-LIFECYCLE.md`, `STANDARD.md`, `BOUNDARY-GATES.md`, `RUNTIME-MAPPING.md`, `IMPLEMENTATION-PLAN.md`, `client/`, `server/`, `tasks/` |

本文档是 `module/binance` 当前规格库的实现投影，不是 runtime 代码验收证据。实际完成状态以 `TRACEABILITY.md`、`client/TRACEABILITY.md`、`server/TRACEABILITY.md` 和 `/home/binance` 的测试证据为准。

## 1. 模块边界

| 维度 | 当前定义 |
| --- | --- |
| 模块职责 | Binance 专属 market data C/S 模块，负责交易所接入、Binance 事件标准化、服务端存储、查询 API 与下游广播。 |
| 进程拆分 | `binance-client` 与 `binance-server` 必须独立部署、独立运行，不能通过同进程调用或共享内存通信。 |
| Client 职责 | 连接 Binance，解析交易所原生数据，映射到 `domain_market` envelope，并通过 `natsx` JetStream 发布。 |
| Server 职责 | 订阅 `natsx` JetStream，校验与去重事实，写入 Binance 专属存储，提供 Gin REST API，并通过 `kafkax` 广播。 |
| 允许依赖 | `domain_market`, `natsx`, `redisx`, `postgresx`, `taosx`, `ossx`, `kafkax`, `gin`, `observability` 等按规格边界使用。 |
| 禁止归属 | 不拥有 canonical market domain，不定义跨交易所通用 `market_data` 语义，不实现策略、下单、撮合或风控。 |
| 禁止路径 | 禁止恢复 `module/binance-market`、`github.com/ZoneCNH/binance-market`、运行时 `internal/cs`。 |
| Wire Contract | Client -> Server 的 wire contract 必须是 `natsx` subject 加 `domain_market` envelope JSON，不能新增本地 proto/gRPC ingest schema。 |

## 2. 功能实现投影

> v3.1.0 编号体系：FR-006 拆分为 6a/6b/6c/6d；FR-007a 新增（analytics API）；FR-009 升为 Boundary Enforcement；FR-010 新增（clickhousex OLAP）；FR-011 新增（分布式锁）；FR-012~FR-024 登记 realtime control、historical lifecycle、event governance、release evidence 与 runtime hot reload。

> 状态口径 L1/L2 分层（RULES R4）：`Done`=L1 Boundary/Governance（boundary-gate + runtime SHA 证据）；`Partial`=L2 Functional（部分产品线已实现，TC 未全绿）；`Pending`=L2 Functional（runtime 仓未推送，默认 `Pending — 以 runtime 仓为准`）。L1 不可替代 L2 功能验收。

| FR | 功能 | 当前状态 | 已有证据 | 剩余实现面 |
| --- | --- | --- | --- | --- |
| FR-001 | Product-Line Support | Partial | `TRACEABILITY.md` 标注 Spot 已实现，USDM/COINM/Options 待补齐。 | 四条 product line 的连接、订阅、映射、发布与服务端消费验收。 |
| FR-002 | Instrument Identity | Partial | `TRACEABILITY.md` 标注 Spot parser/mapper 已实现。 | USDM、COINM、Options 的 `instrument_key` 与身份冲突测试。 |
| FR-003 | natsx Communication | Pending | 规格定义 `js.Publish("binance.market.{product_line}.{event_type}", jsonPayload)` 与 durable consumer。 | Client publisher、Server consumer、subject 校验、PubAck 与 durable replay。 |
| FR-004 | At-Least-Once Delivery | Pending | 规格定义 ManualAck、失败 NakWithDelay、MaxDeliver 5、dead-letter。 | Ack/Nak 策略、失败注入、重复投递与死信处理。 |
| FR-005 | Idempotent Acceptance | Pending | 规格定义 idempotency key 与 duplicate/conflict 行为。 | `redisx` SetNX、重复跳过、冲突终止、重放测试。 |
| FR-006a | taosx Time-Series Storage | Pending | 规格定义 WriteBatch 写入 tick/bar/depth 到超级表子表。 | 时序写入吞吐 100K TPS、子表自动建表、查询时间范围过滤。 |
| FR-006b | postgresx Metadata Storage | Pending | 规格定义幂等 upsert instrument catalog + 审计日志。 | UpsertSymbol 幂等性、ON CONFLICT 行为、审计完整性。 |
| FR-006c | redisx Hot Cache | Pending | 规格定义最新 tick/bar/depth 热缓存（60s/5s TTL）+ 失败降级。 | SET 命令封装、TTL 验证、失败不阻塞主管线。 |
| FR-006d | ossx Archival | Pending | 规格定义对象路径与 ETag 删除前校验。 | Parquet 归档、ETag 校验、生命周期删除、防误删测试。 |
| FR-007 | Gin Market API | Pending | 规格定义 `/api/v1/market/ticks/depth/bars/trades` REST 接口。 | 认证、限流、统一错误、readyz、market_data HTTP 调用方兼容。 |
| FR-007a | clickhousex Analytics API | Pending | 规格定义 `/api/v1/analytics/vwap/top-movers/correlation` OLAP 查询。 | analytics 查询正确性、查询 P99 < 2s、降级到 503。 |
| FR-008 | kafkax Broadcast | Pending | 规格定义 `kafkax` topic、symbol key 与 handoff 后 Ack。 | Kafka dispatch、失败不 Ack、重试、下游消费契约。 |
| FR-009 | Boundary Enforcement | Implemented / Documented | `BOUNDARY-GATES.md` 与 `TRACEABILITY.md` 标注 FR-009 Done；`/home/binance` boundary-gates 10/10、go test、lint、smoke self-test 已通过。 | 远端 CI/release evidence 仍需归档；非边界 FR 不因此闭合。 |
| FR-010 | clickhousex OLAP Storage | Pending | 规格定义定时 ETL 聚合 taosx → clickhousex。 | ETL 调度、InsertBatch 性能、ClickHouse 不可达降级。 |
| FR-011 | Distributed Coordinator Lock | Pending | 规格定义 redisx SetNX 分布式锁 + lease 续期 + coordinator HA。 | SetNX 锁获取、lease 续期失败后停止任务、主动释放。 |
| FR-012 | Stream Session Lifecycle | Pending | `SPEC.md`/`TRACEABILITY.md` v3.1.0 已登记。 | active stream registry 运行中增删订阅且不重启进程的集成证据。 |
| FR-013 | Exchange Reliability Controls | Pending | `SPEC.md`/`TRACEABILITY.md` v3.1.0 已登记。 | retry budget、rate-limit、clock skew 与 disconnect 策略测试。 |
| FR-014 | Runtime Stream Observability | Pending | `SPEC.md`/`TRACEABILITY.md` v3.1.0 已登记。 | admin/metrics 暴露 stream state、lag、unhealthy reason 的验证。 |
| FR-015 | Runtime Pause/Resume/Drain | Pending | `SPEC.md`/`TRACEABILITY.md` v3.1.0 已登记。 | pause/resume/drain API、in-flight drain 与 audit event 证据。 |
| FR-016 | Historical Backfill Planner | Pending | `SPEC.md`/`TRACEABILITY.md` v3.1.0 已登记。 | window validation、cursor persistence、overlap rejection 与限速测试。 |
| FR-017 | Gap Detection and Replay | Pending | `SPEC.md`/`TRACEABILITY.md` v3.1.0 已登记。 | gap detect、replay idempotency、失败恢复 cursor 证据。 |
| FR-018 | Archive Manifest and Restore | Pending | `SPEC.md`/`TRACEABILITY.md` v3.1.0 已登记。 | manifest、checksum、restore、retention delete guard 证据。 |
| FR-019 | Backfill Resource Governance | Pending | `SPEC.md`/`TRACEABILITY.md` v3.1.0 已登记。 | job caps、cancellation、queue/active/throttled metrics 证据。 |
| FR-020 | Funding Rate Event Support | Pending | `SPEC.md`/`TRACEABILITY.md` v3.1.0 已登记。 | funding_rate mapping/storage/query/fanout 与 replay 一致性证据。 |
| FR-021 | Mark and Index Price Support | Pending | `SPEC.md`/`TRACEABILITY.md` v3.1.0 已登记。 | mark_price/index_price topic/storage/query 分离证据。 |
| FR-022 | Event-Type Governance Matrix | Pending | `TRACEABILITY.md` 与 checker 已登记 R2 120-cell matrix。 | matrix checker 持续阻断旧 topic、旧 product_line、旧 endpoint。 |
| FR-023 | Release Evidence Bundle | Pending | `SPEC.md`/`TRACEABILITY.md` v3.1.0 已登记。 | local/CI/live/release evidence bundle 与 release gate 证据。 |
| FR-024 | Runtime Config Hot Reload | Pending | `STANDARD.md`、`SPEC.md` 与 `TRACEABILITY.md` v3.1.0 已登记 endpoint：`POST /api/v1/admin/symbols/reload`。 | no-restart stream add/remove、live websocket、remote CI 与 release snapshot 证据。 |

## 3. 边界与质量需求投影

| 项 | 当前状态 | 说明 |
| --- | --- | --- |
| BR-001 No binance-market | Done | `/home/binance/BOUNDARY-GATES.md` §2 + `scripts/boundary-gates.sh` 10/10 PASS，禁止旧仓库或旧 module 名称回流。 |
| BR-002 Client Must Not Import Server | Done | `/home/binance/BOUNDARY-GATES.md` §3 证明 Client 无 server internals import。 |
| BR-003 Server Must Not Import Client | Done | `/home/binance/BOUNDARY-GATES.md` §4 证明 Server 无 client internals import。 |
| BR-004 natsx ManualAck | Pending | Server 必须在持久化与广播 handoff 后 Ack；该业务路径需要 TC-006 集成测试，不由 boundary gate 证明。 |
| BR-005 No cs Package | Done | `/home/binance/BOUNDARY-GATES.md` §5/§6 证明无 runtime `internal/cs` 依赖且无同进程 C/S 通信。 |
| BR-006 Server Owns Binance Storage | Done | `/home/binance/BOUNDARY-GATES.md` §7 证明 Server 只拥有 Binance-specific storage，不上移为通用 market_data。 |
| BR-007 No Domain Ownership | Done | `/home/binance/BOUNDARY-GATES.md` §9 证明 Binance 只消费 `domain_market` 语义，不能定义 canonical domain。 |
| BR-008 Wire Contract Externality | Done | `/home/binance/BOUNDARY-GATES.md` §8 证明无本地 `.proto`/gRPC ingest schema；当前 runtime 使用 HTTP JSON `/ingest` 与 `internal/wire` skeleton，canonical 语义仍外置。 |
| BR-009 go.mod Dependency Compliance | Done | `/home/binance/BOUNDARY-GATES.md` §11 证明 runtime `go.mod` 与边界依赖合规。 |
| NFR-001~004 Performance | Pending | 延迟、吞吐、回压、重放预算需要 runtime 压测证据。 |
| NFR-005~009 Storage/API | Pending | 数据一致性、查询 SLA、归档安全、故障恢复需要集成测试证据。 |
| NFR-010~011 Observability | Pending | metrics、logs、trace、health/readiness 需要 runtime 验证。 |
| NFR-012~013 Security | Pending | Secret scan、auth、rate limit、least privilege 需要 CI 与 API 测试证据。 |

## 4. 任务交付视图

| 任务域 | 覆盖范围 | 当前投影 |
| --- | --- | --- |
| Root tasks | `TASK-BINANCE-ROOT-000` ~ `TASK-BINANCE-ROOT-007` | 模块级拆分、边界、通信、存储、API、广播、归档与治理任务已登记；完成度仍受 FR 状态约束。 |
| Client tasks | `TASK-BINANCE-CLIENT-001` ~ `TASK-BINANCE-CLIENT-014` | product line catalog、parser、connector、mapping、idempotency、admin、natsx publisher 等已拆分；`CLIENT-008/009` spool/checkpoint 已归档。 |
| Server tasks | `TASK-BINANCE-SERVER-010` ~ `TASK-BINANCE-SERVER-016` | natsx consumer、idempotency、storage、kafkax、Gin API、ossx archival 等为 v2.0.0 active server 交付面。 |
| Boundary gates | `BOUNDARY-GATES.md` | 已对齐 `/home/binance` runtime gate 清单；`scripts/boundary-gates.sh` 本地 10/10 PASS，证据归档于 `/home/binance/release/evidence/binance/20260623/`。 |

## 5. 文档资产清单

| 文档 | 用途 | 当前使用方式 |
| --- | --- | --- |
| `goal.md` | 业务目标与模块意图 | 作为实现清单的目标来源。 |
| `SPEC.md` | v2.0.0 功能与边界规格 | 作为 FR/BR/NFR 语义来源。 |
| `TRACEABILITY.md` | 根级 FR/AC/TC/Task 追溯 | 作为当前状态与验收编号来源。 |
| `client/TRACEABILITY.md` | Client 子域追溯 | 作为 client active/pending 实现面来源。 |
| `server/TRACEABILITY.md` | Server 子域追溯 | 作为 server active/pending 实现面来源。 |
| `BOUNDARY-GATES.md` | 边界漂移防线 | 作为 FR-009 与 BR-001~BR-009 的边界治理证据。 |
| `RUNTIME-MAPPING.md` | docs 到 runtime repo 的路径映射 | 用于避免把文档仓库误当 runtime。 |
| `IMPLEMENTATION-PLAN.md` | 实施顺序与依赖计划 | 用于任务排序与风险解释。 |
| `tasks/` | 可执行 task specs | 用于 Root/Client/Server 任务粒度追踪。 |

## 6. 完成度勾稽

| 检查项 | 状态 | 依据 |
| --- | --- | --- |
| v2.0.0 根规格存在 | Done | `SPEC.md`。 |
| 根级 traceability 存在 | Done | `TRACEABILITY.md`。 |
| Client/Server 子域 traceability 存在 | Done | `client/TRACEABILITY.md`, `server/TRACEABILITY.md`。 |
| C/S 独立进程边界已定义 | Done | `README.md`, `SPEC.md`, `BOUNDARY-GATES.md`。 |
| Boundary gate 文档已形成 | Done | `BOUNDARY-GATES.md` v2.2.4；runtime evidence commit `66f60b3945dce215f68ff833bbd336364d635ae8`；verified source commit `9777a5b0db9a3de5db53942b9aaf6b55eec04f24`。 |
| Product line 全覆盖实现 | Not Done | FR-001 Partial。 |
| Instrument identity 全覆盖实现 | Not Done | FR-002 Partial。 |
| natsx publish/consume runtime 闭合 | Not Done | FR-003 Pending。 |
| ManualAck 与 at-least-once runtime 闭合 | Not Done | FR-004 Pending。 |
| Server idempotency runtime 闭合 | Not Done | FR-005 Pending。 |
| Storage/API/archival/broadcast/runtime 扩展闭合 | Not Done | FR-006~FR-008、FR-010~FR-024 Pending；FR-009 local boundary evidence closed。 |
| 全量 AC/TC 通过 | Not Done | Boundary gates 10/10 PASS，TC-020~TC-022 local PASS；TC-001~019、TC-023~TC-042 仍 Pending。 |

## 7. 当前缺口登记

| 缺口 | 影响 | 关闭条件 |
| --- | --- | --- |
| FR-001/FR-002 只有 Partial | 不能声明四条 product line 完整支持。 | Spot、USDM、COINM、Options 的 parser、mapper、connector、server acceptance 全部通过。 |
| FR-003~FR-008/FR-010~FR-011 Pending | 不能声明 distributed runtime 已实现。 | `/home/binance` 中 client/server runtime、存储、API、广播、归档对应测试全部通过。 |
| FR-012~FR-024 Pending | 不能声明 realtime control、historical lifecycle、event governance、release evidence 或 hot reload 完成。 | 对应 runtime 集成、R2 matrix、live websocket、远端 CI 和 release snapshot 全部闭合。 |
| Client active FR 仍为 0/8 implemented | Client 侧 v2.0.0 交付尚未闭合。 | `client/TRACEABILITY.md` 中 active FR 状态更新并附 runtime 证据。 |
| Server active FR 仍为 0/9 implemented | Server 侧 v2.0.0 交付尚未闭合。 | `server/TRACEABILITY.md` 中 active FR 状态更新并附 runtime 证据。 |
