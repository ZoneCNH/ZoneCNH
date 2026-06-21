# binance 完整实现清单

## 元数据

| 字段 | 值 |
| --- | --- |
| Status | Generated from current module SSOT |
| Last-Updated | 2026-06-21 |
| Module-Version | v2.0.0 |
| Module-State | 规格重构；v2.0.0 runtime 大部分仍为 Pending |
| Layer | 数据域 / Binance-specific market_data C/S module |
| Runtime-Repo | `/home/binance` |
| Source | `goal.md`, `SPEC.md`, `TRACEABILITY.md`, `BOUNDARY-GATES.md`, `RUNTIME-MAPPING.md`, `IMPLEMENTATION-PLAN.md`, `client/`, `server/`, `tasks/` |

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

| FR | 功能 | 当前状态 | 已有证据 | 剩余实现面 |
| --- | --- | --- | --- | --- |
| FR-001 | Product-Line Support | Partial | `TRACEABILITY.md` 标注 Spot 已实现，USDM/COINM/Options 待补齐。 | 四条 product line 的连接、订阅、映射、发布与服务端消费验收。 |
| FR-002 | Instrument Identity | Partial | `TRACEABILITY.md` 标注 Spot parser/mapper 已实现。 | USDM、COINM、Options 的 `instrument_key` 与身份冲突测试。 |
| FR-003 | natsx Communication | Pending | 规格定义 `js.Publish("binance.market.{product_line}.{event_type}", jsonPayload)` 与 durable consumer。 | Client publisher、Server consumer、subject 校验、PubAck 与 durable replay。 |
| FR-004 | At-Least-Once Delivery | Pending | 规格定义 ManualAck、失败 NakWithDelay、MaxDeliver 5、dead-letter。 | Ack/Nak 策略、失败注入、重复投递与死信处理。 |
| FR-005 | Idempotent Acceptance | Pending | 规格定义 idempotency key 与 duplicate/conflict 行为。 | `redisx` SetNX、重复跳过、冲突终止、重放测试。 |
| FR-006 | Full-Stack Storage | Pending | 规格定义 `taosx`、`postgresx`、`redisx`、`ossx` 分工。 | tick/depth 写入、catalog upsert、缓存 TTL、归档生命周期。 |
| FR-007 | Gin Market API | Pending | 规格定义 `/api/v1/market/ticks` 与 `/api/v1/market/depth/{instrument_key}`。 | 认证、限流、统一错误、readyz、market_data HTTP 调用方兼容。 |
| FR-008 | ossx Archival | Pending | 规格定义对象路径与 ETag 删除前校验。 | Parquet 归档、ETag 校验、生命周期删除、防误删测试。 |
| FR-009 | Downstream Broadcast | Pending | 规格定义 `kafkax` topic、symbol key 与 handoff 后 Ack。 | Kafka dispatch、失败不 Ack、重试、下游消费契约。 |
| FR-010 | Boundary Enforcement | Implemented / Documented | `BOUNDARY-GATES.md` v2.0.0 已落地，`TRACEABILITY.md` 标注 FR-010 Implemented，TC-020 PASS。 | TC-021 与 TC-022 仍需 runtime/repo CI 执行证据闭合。 |

## 3. 边界与质量需求投影

| 项 | 当前状态 | 说明 |
| --- | --- | --- |
| BR-001 No binance-market | Pending | 禁止旧仓库或旧 module 名称回流；需要 CI grep gate。 |
| BR-002 Client Must Not Import Server | Pending | Client 禁止导入 server internals。 |
| BR-003 Server Must Not Import Client | Pending | Server 禁止导入 client internals。 |
| BR-004 natsx ManualAck | Pending | Server 必须在持久化与广播 handoff 后 Ack。 |
| BR-005 No cs Package | Documented | `BOUNDARY-GATES.md` 已声明禁止 runtime `internal/cs`。 |
| BR-006 Server Owns Binance Storage | Pending | Server 只拥有 Binance-specific storage，不上移为通用 market_data。 |
| BR-007 No Domain Ownership | Pending | Binance 只能消费 `domain_market` 语义，不能定义 canonical domain。 |
| BR-008 Wire Contract Externality | Pending | Wire contract 外置在 `natsx` subject 与 `domain_market` envelope，不落本地 proto/gRPC ingest schema。 |
| BR-009 go.mod Dependency Compliance | Pending | 需要 runtime `go.mod` 与边界依赖检查。 |
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
| Boundary gates | `BOUNDARY-GATES.md` | 已形成文档化 gate 清单，仍需 CI 执行命令与 runtime 证据闭合。 |

## 5. 文档资产清单

| 文档 | 用途 | 当前使用方式 |
| --- | --- | --- |
| `goal.md` | 业务目标与模块意图 | 作为实现清单的目标来源。 |
| `SPEC.md` | v2.0.0 功能与边界规格 | 作为 FR/BR/NFR 语义来源。 |
| `TRACEABILITY.md` | 根级 FR/AC/TC/Task 追溯 | 作为当前状态与验收编号来源。 |
| `client/TRACEABILITY.md` | Client 子域追溯 | 作为 client active/pending 实现面来源。 |
| `server/TRACEABILITY.md` | Server 子域追溯 | 作为 server active/pending 实现面来源。 |
| `BOUNDARY-GATES.md` | 边界漂移防线 | 作为 FR-010 与 BR-005 的文档证据。 |
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
| Boundary gate 文档已形成 | Done | `BOUNDARY-GATES.md` v2.0.0。 |
| Product line 全覆盖实现 | Not Done | FR-001 Partial。 |
| Instrument identity 全覆盖实现 | Not Done | FR-002 Partial。 |
| natsx publish/consume runtime 闭合 | Not Done | FR-003 Pending。 |
| ManualAck 与 at-least-once runtime 闭合 | Not Done | FR-004 Pending。 |
| Server idempotency runtime 闭合 | Not Done | FR-005 Pending。 |
| Storage/API/archival/broadcast runtime 闭合 | Not Done | FR-006~FR-009 Pending。 |
| 全量 AC/TC 通过 | Not Done | TC-001~019、TC-021、TC-022 仍 Pending；TC-020 PASS。 |

## 7. 当前缺口登记

| 缺口 | 影响 | 关闭条件 |
| --- | --- | --- |
| FR-001/FR-002 只有 Partial | 不能声明四条 product line 完整支持。 | Spot、USDM、COINM、Options 的 parser、mapper、connector、server acceptance 全部通过。 |
| FR-003~FR-009 Pending | 不能声明 distributed runtime 已实现。 | `/home/binance` 中 client/server runtime、存储、API、广播、归档对应测试全部通过。 |
| Client active FR 仍为 0/8 implemented | Client 侧 v2.0.0 交付尚未闭合。 | `client/TRACEABILITY.md` 中 active FR 状态更新并附 runtime 证据。 |
| Server active FR 仍为 0/9 implemented | Server 侧 v2.0.0 交付尚未闭合。 | `server/TRACEABILITY.md` 中 active FR 状态更新并附 runtime 证据。 |
| TC-021/TC-022 Pending | FR-010 尚缺完整 CI 证据。 | 边界 gate 在 runtime/repo CI 中稳定执行并记录 PASS。 |
