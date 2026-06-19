# transportx

## 1. 模块定位
ZoneCNH 统一应用通信层（应用通信防腐层），为跨 runtime 与 adapter 的传输层建立稳定契约。定义 Envelope、Endpoint、DeliveryReceipt、ServiceIdentity、QoS 五级、Codec、六通信平面、Deadline、Retry Safety、Error Mapping、Trace Propagation、Auth、Idempotency、DLQ、Replay、Audit 与 Adapter Contract。Status=Docs Baseline Approved / Runtime Pending、Spec v1.2.0、Layer=基座·传输契约。定位：contracts 定义"传什么"，transportx 定义"怎么传"，kafkax/natsx/grpc/http 是"用什么传"，x.go 负责"接哪种实现"。

## 2. 生产职责
- Envelope/Endpoint/PayloadRef/Header/DeliveryReceipt 契约（FR-001/002/003/011）
- QoS 五级分类 + 六通信平面（InProcess/Command/Event/Realtime/Admin/Audit）（FR-017）
- Runtime 生命周期状态机 Start/Pause/Resume/Drain/Shutdown/ForceStop（FR-004/005）
- Control Plane：kill switch/pause/resume/mirror/canary/rate-limit 审计与 rollback token（FR-006）
- ServiceIdentity、Authz、Deadline、Clock Skew、Idempotency、Retry+DLQ、Backpressure/Bulkhead（FR-007..013）
- Codec 接口 + 默认 JSON codec；TopicRegistry/MethodRegistry/SchemaRegistry（FR-018..025）

## 3. 边界定义
- 定义传输层"语法规则"（Envelope 格式、中间件顺序、错误码体系、生命周期状态机）
- 允许依赖 contracts（仅公共类型，不导入领域 DTO）、observex、resiliencx、configx
- kafkax/natsx/redisx 可实现 transportx adapter，但 transportx core 禁止依赖 adapter
- 中间件强制顺序：validation → authn → authz → redaction → logging → tracing → metrics → adapter dispatch（FR-014，redaction 必须先于 logging）
- `production_import_allowed=false` 直至实现完成并通过 TX-GATE-001..012

## 4. 不负责什么
- 业务 DTO、业务 Event/Command schema、领域错误码（→ contracts）
- 具体 Kafka/NATS/HTTP/RPC/Redis stream/S3/数据库客户端（→ kafkax/natsx/postgresx 等 adapter）
- 业务 outbox 编排、业务幂等语义、业务 workflow engine
- 通用 scheduler、service mesh、API gateway
- payload 明文归档（payload storage 由调用方或 adapter 管理）

## 5. 架构位置
基座·传输契约（L2.5 通信契约层）。六通信平面默认实现：InProcess（Go interface + memory）、Command（gRPC/NATS Request-Reply）、Event（Kafka/JetStream）、Realtime（NATS Core/WebSocket/stream）、Admin（HTTP/gRPC health）、Audit（append-only log/Kafka/JetStream）。多模块布局：root go.mod（core）+ 每个 `adapters/*/go.mod`（grpc/kafka/nats/http/websocket/redisidem/postgresoutbox/clickhouseaudit/s3replay）。go.mod：`github.com/ZoneCNH/transportx`，go 1.23。

## 6. 生命周期
状态机：`new → starting → running ⇄ paused → draining → stopped → [terminal]`，ForceStop() 从任意状态 → stopped(abandoned)。
- Drain：停止接受新工作，完成在途工作，在 deadline 内报告剩余（accepted/completed/abandoned/timed-out 计数）
- 禁止转换：paused→running（需 Resume）、draining→running、stopped→*
- ForceStop：标记所有在途工作为 abandoned 并附 receipt 证据（BR-004）
- Drain deadline 过期：返回部分 drain result，标记未完成工作

## 7. 标准目录结构
```text
transportx/
├── go.mod (core) / go.work
├── envelope/          # Envelope/header/payloadRef/validation
├── endpoint/          # Endpoint model/registry/capability
├── identity/          # ServiceIdentity/auth context
├── runtime/           # lifecycle interfaces/state machine
├── control/           # control-plane command/audit
├── receipt/           # DeliveryReceipt/ack
├── errors/            # typed transport error taxonomy
├── codec/ + codec/json/
├── rpc/ eventbus/ stream/ middleware/ registry/ memory/
├── conformance/       # reusable test suite
├── docs/              # release evidence
└── adapters/
    ├── grpc/ kafka/ nats/ http/ websocket/
    ├── redisidem/     # Redis-backed idempotency store
    ├── postgresoutbox/  # PostgreSQL outbox
    ├── clickhouseaudit/ # ClickHouse audit sink
    └── s3replay/        # S3 replay source
```
Core 不 import adapters；每个 adapter 独立 go.mod。

## 8. 配置规范
通过 configx immutable config 消费：
| Key | 默认 | 说明 |
|-----|------|------|
| `tx.payload.max_bytes` | 1_048_576 | 最大 payload 字节 |
| `tx.header.max_count` / `max_bytes` | 64 / 8_192 | header 数量/字节上限 |
| `tx.deadline.default_ms` | 30_000 | 默认 RPC deadline |
| `tx.clock_skew.max_ms` | 5_000 | 最大时钟偏差 |
| `tx.retry.max_attempts` | 3 | 默认重试上限 |
| `tx.backpressure.policy` | BLOCK | BLOCK/DROP_OLDEST/DROP_NEWEST/FAIL_FAST/SPILL_TO_DISK |
| `tx.bulkhead.max_concurrency` | 100 | 隔舱并发上限 |
| `tx.dlq.enabled/max_attempts` | true / 5 | DLQ 开关与上限 |
| `tx.redaction.version` | v1 | 脱敏规则集版本 |
| `tx.audit.batch_size` | 100 | 审计 append 批大小 |
| `tx.execution_mode` | LIVE | LIVE/PAPER/REPLAY/DRY_RUN |

## 9. 错误模型
typed transport error taxonomy，错误码注册表（23 个）：`TX_PAYLOAD_LIMIT_EXCEEDED / TX_HEADER_LIMIT_EXCEEDED / TX_ENDPOINT_INVALID / TX_AUTHN_REQUIRED / TX_AUTHZ_DENIED / TX_DEADLINE_EXCEEDED / TX_CLOCK_SKEW / TX_IDEMPOTENCY_CONFLICT / TX_BACKPRESSURE / TX_BULKHEAD_REJECTED / TX_ADAPTER_FAILURE / TX_CONTROL_CONFLICT / TX_QOS_VIOLATION / TX_MODE_VIOLATION / TX_SCHEMA_INCOMPATIBLE / TX_TOPIC_DUPLICATE / TX_METHOD_DUPLICATE / TX_RETRY_UNSAFE / TX_REDACTION_FAILED / TX_AUDIT_MISSING / TX_AUDIT_DROPPED / TX_DLQ_INCOMPLETE / TX_MIRROR_IDEMPOTENCY_VIOLATION`。每个错误含 stable code、redacted message、retry classification、endpoint reference、trace id。

## 10. 日志规范
日志字段：redacted envelope id、endpoint reference、error code、receipt id、actor、command id、data class。payload/unredacted headers 禁止出现在日志；SECRET 数据禁止出现在任何日志（BR-018）。redaction 必须先于 logging/tracing exporters（BR-002），失败 fail-closed（`TX_REDACTION_FAILED`）。

## 11. Metrics
metrics labels：endpoint、operation、status、error code、retry decision、qos class、tenant class、redaction version。labels 必须使用 bounded cardinality 字段（NFR-005）。payload/unredacted headers 禁止；SECRET 禁止出现在任何 metric。

## 12. Tracing
trace fields：trace id、span id、envelope id、endpoint reference、lifecycle state、control command id、qos class。trace context 跨六通信平面传播（NFR-006，TC-007 验证 trace fields 存在）。Audit 独立平面记录 ServiceIdentity、authz decision、execution mode。

## 13. Reliability
- retry：READ_ONLY 可自动重试；IDEMPOTENT 需幂等键才能重试；UNSAFE 禁止自动重试（BR-017，`TX_RETRY_UNSAFE`）
- timeout/deadline：单调时钟 + wall-clock skew guard（BR-008，默认 skew 5000ms），过期返回 `TX_DEADLINE_EXCEEDED`/`TX_CLOCK_SKEW`
- backpressure/bulkhead：饱和时按 policy 处理，返回 `TX_BACKPRESSURE`/`TX_BULKHEAD_REJECTED`（默认并发 100）
- circuit breaker/DLQ：有界重试耗尽路由到 DLQ，保留 trace context（BR-010，`TX_DLQ_INCOMPLETE`），maxAttempts 后 park 停止自动重试需人工 runbook
- idempotency：键冲突返回 `TX_IDEMPOTENCY_CONFLICT`，不发布重复工作

## 14. Security
| 要求 | 控制 |
|------|------|
| payload 保密 | payload bytes 不出现在 logs/metrics/audit/receipt |
| 身份绑定 | 每个操作要求 ServiceIdentity + trust-domain 验证 |
| scope 强制 | Endpoint 和控制操作 dispatch 前验证 scopes |
| 租户隔离 | Endpoint 解析和幂等存储含 tenant scope |
| 可审计 | control-plane 和 authz 失败产生不可变 audit 事件 |
| fail-closed redaction | 脱敏失败阻塞 logging 和 adapter dispatch |
| 数据分级 | CONFIDENTIAL/SECRET 日志前脱敏；SECRET 禁入 audit/receipt |
| mode gate | REPLAY/DRY_RUN 禁止真实下单和外部副作用（BR-016） |
| secret-free audit | AuditRecord 不得含 SECRET 字段 |

## 15. Performance SLO
| 操作 | p95 目标 |
|------|---------|
| Envelope validation | ≤ 1 ms（in-memory） |
| Middleware（不含 adapter I/O） | ≤ 2 ms |
| Control command application（不含 durable store） | ≤ 10 ms |
| Redaction（metadata-only） | ≤ 1 ms |
| JSON codec round-trip（1KB） | ≤ 5 ms |
| TopicRegistry resolution | ≤ 0.1 ms |
| Audit append（不含 sink I/O） | ≤ 20 ms |

Drain bookkeeping O(in-flight work)，每 receipt bounded memory。实现需在 release evidence 报告 benchmark hardware/runtime/adapter。

## 16. 测试标准
Conformance suite 25 个 TC（TC-001..TC-025）覆盖 Envelope/Endpoint/Receipt/Lifecycle/Drain/ControlPlane/ServiceIdentity/Authz/Deadline/Idempotency/Backpressure/Retry+DLQ/RedactionOrder/SchemaCompat/QoS/Codec/TopicRegistry/MethodRegistry/ExecutionMode/Outbox-Inbox/AuditPlane/DataClassification/SchemaRegistry。测试命令形如 `go test ./conformance/... -run TestXxx`。当前状态：所有 FR/BR/NFR 为 Pending（/home/transportx 实现未归档），conformance gates 未执行。

## 17. Chaos
SPEC 未定义独立 chaos 矩阵，但边界情况表覆盖等效维度：Drain deadline 过期返回 partial result、Pause 期间 retry loop、ForceStop 期间 in-flight publish 标记 abandoned、mirror target 拒绝保留 primary、canary rollback、duplicate ack 幂等、QoS 饱和降级（REALTIME 丢旧/AUDIT spill-to-disk+alert）、mode transition drain 在途工作、outbox relay crash 幂等重发、DLQ poison loop maxAttempts 后 park、SECRET 在 audit path fail-closed。

## 18. Contract
核心接口：`TransportRuntime`（Start/Pause/Resume/Drain/Shutdown/ForceStop）、`Publisher`（Publish/Request/Stream）、`Subscriber`（Subscribe/Ack/Nack/ExtendDeadline）、`EndpointRegistry`（Register/Resolve/Capabilities/Deprecate）、`ControlPlane`（Apply/Rollback/Snapshot/Audit）、`ConformanceSuite`（RunLifecycle/RunEnvelope/RunControlPlane/RunErrorTaxonomy）、`Codec`（Marshal/Unmarshal）、`TopicRegistry`/`MethodRegistry`/`SchemaRegistry`、`AuditSink`（Append）/`ReplaySource`（Replay）、`Outbox`（Save/MarkPublished/Pending）/`Inbox`（Seen/MarkProcessed）。接口必须接受 context、ServiceIdentity、immutable request；返回 DeliveryReceipt 或 typed transport error。

## 19. CI Gate
12 个 TX-GATE：TX-GATE-001 spec-lint 含 transportx、TX-GATE-002 traceability-check、TX-GATE-003 status-consistency-check（17 Foundation specs）、TX-GATE-004 spec-drift-guard、TX-GATE-005 Envelope/Endpoint/Receipt conformance、TX-GATE-006 lifecycle/drain/force-stop、TX-GATE-007 control-plane/authz/redaction-order、TX-GATE-008 schema 兼容性（破坏性阻塞）、TX-GATE-009 release evidence（changelog/tag/conformance/drift）、TX-GATE-010 QoS/Codec/Registry、TX-GATE-011 Execution Mode/Outbox-Inbox/Audit、TX-GATE-012 Data Classification/SchemaRegistry。全部阻塞 release。

## 20. Release Gate
- [x] Spec approved（SPEC v1.2.0）
- [x] Traceability complete（FR-001..026、BR-001..018、NFR-001..012 已登记）
- [ ] CI gates configured（TX-GATE-001..012 全通过）— **未归档**
- [ ] Contract implementation（/home/transportx public package 编译）— **未归档**
- [ ] Codec/Registry/Conformance 验证 — **Pending**
- [ ] Security verified（redaction-order/authz-denial/mode-gate/secret-free-audit）— **Pending**
- [ ] Compatibility verified（v1.2.0 schema registry report）— **Pending**
- [ ] NFR-001..012 验证证据 — **Pending**
- [ ] Release published（git tag/changelog/release notes）— **Pending**
- **`production_import_allowed=false`** 直至 release gate 全通过

## 21. Versioning
semver。Envelope/Endpoint/Receipt/ServiceIdentity 结构体破坏性变更=major（BR-011，`TX_SCHEMA_INCOMPATIBLE`），新增可选字段=minor。SchemaRegistry 记录 version/digest/兼容性分类/迁移说明；未知版本拒绝；破坏性变更需 major bump。破坏性变更回滚：CI TX-GATE-008 阻塞 → SchemaRegistry 记录 incompatible 版本 + migration notes → rollback token 存储 → 消费方 pin 旧版 → adapter 迁移窗口支持双版本（最少一个 release cycle）→ 旧版本 deprecated（非删除）一个额外 release cycle。当前 Spec v1.2.0。

## 22. 兼容性策略
- Envelope id + idempotency key 跨重试稳定（BR-007）
- Adapter 特定字段必须放在 namespaced extension blocks（BR-006，`TX_SCHEMA_INCOMPATIBLE`）
- Mirror/canary 必须保持生产路径幂等语义（BR-005）
- Unknown schema version 拒绝（带 registry 证据）
- Duplicate ack 返回幂等 receipt（原始 ack metadata）
- 兼容性分类：compatible/breaking，记录 registry 版本 + migration notes（FR-015）

## 23. Failover
- Drain deadline 过期：返回 partial drain result，标记未完成工作
- ForceStop：标记所有在途工作 abandoned，要求 adapter reconciliation（receipt=ABANDONED）
- Mirror target 拒绝：保留 primary delivery result，发出 mirror failure receipt
- Canary rollback：停止路由新 canary 工作，保持既有 receipts 可追溯
- DLQ poison message loop：maxAttempts 后 park 在 DLQ 停止自动重试，需人工 runbook
- Audit event delivery 失败：escalate + retry（BR-015，`TX_AUDIT_DROPPED`，不得静默丢）

## 24. Backpressure
- BackpressurePolicy 五选一：BLOCK / DROP_OLDEST / DROP_NEWEST / FAIL_FAST / SPILL_TO_DISK（默认 BLOCK）
- Bulkhead：默认 max_concurrency 100，耗尽返回 `TX_BULKHEAD_REJECTED`
- QoS 饱和降级：REALTIME_BEST_EFFORT 丢旧；AUDIT spill-to-disk + alert
- 硬规则：order/fill/risk/settlement 禁用 REALTIME_BEST_EFFORT（BR-013，`TX_QOS_VIOLATION`）；COMMAND_IDEMPOTENT 无幂等键拒绝（BR-014）；AUDIT 必须进 audit sink 或 durable backend

## 25. 审计要求
Audit Plane 提供 AuditSink（Append）+ ReplaySource（Replay）接口。审计记录含 recordId/traceId/correlationId/actor/action/target/result/timestamp/dataClass，不含 secrets。审计事件不得静默丢（BR-015），delivery 失败 escalate + retry。Control-plane 命令必须可审计（command id/actor/rollback token，BR-003，`TX_AUDIT_MISSING` 拒绝命令）。AuditRecord 不得含 SECRET 字段。SECRET 在 audit path fail-closed（redaction version 缺失拒绝 append）。

## 26. 熵减规则
全局：禁止 util dumping、hidden abstraction、cyclic dependency。模块特有：core 不 import adapters（单向依赖）；adapter 特定字段放 namespaced extensions；错误集中在 errors/ taxonomy；registry 三件套（Topic/Method/Schema）统一注册与兼容性验证；中间件顺序固定不可乱序（redaction 先于 logging）；multi-module layout（core + 每个 adapter 独立 go.mod）。

## 27. AI Constraints
全局：AI 不允许新增未注册模块、绕过 contracts、动态扩展目录。模块特有：AI 修改 transportx 不得承载业务 DTO（→ contracts）、不得直接绑定 HTTP/gRPC/Kafka/NATS 实现、不得在 core import adapter、不得打乱中间件顺序（尤其 redaction 必须先于 logging）、不得让 payload/SECRET 进入任何 telemetry、不得静默丢 audit 事件；所有 FR-001..026 / BR-001..018 行为约束必须保持。

## 28. Forbidden Patterns
- payload 出现在 logs/metrics/audit/receipt（BR-001，`TX_REDACTION_FAILED` fail-closed）
- redaction 晚于 logging/tracing（BR-002）
- control 命令无 audit 证据（BR-003，`TX_AUDIT_MISSING`）
- Envelope id/idempotency key 跨重试变化（BR-007）
- deadline 用 wall-clock 而非 monotonic + skew guard（BR-008）
- authz 失败泄露 endpoint secret/payload（BR-009）
- DLQ 丢 trace context（BR-010，`TX_DLQ_INCOMPLETE`）
- order/fill/risk/settlement 用 REALTIME_BEST_EFFORT（BR-013）
- COMMAND_IDEMPOTENT 无幂等键（BR-014）
- REPLAY/DRY_RUN 允许真实下单/外部副作用（BR-016）
- UNSAFE 方法自动重试（BR-017）
- SECRET 出现在任何 telemetry（BR-018）
- core import adapter；业务 DTO 下沉到 transportx

## 29. Production Ready Checklist
- [ ] observability ready（metrics bounded cardinality + trace 跨六平面 + redaction fail-closed）— Pending
- [ ] resilience ready（retry class 强制、deadline/skew、backpressure/bulkhead、DLQ+trace）— Pending
- [ ] audit ready（AuditSink/ReplaySource、不静默丢、secret-free）— Pending
- [ ] rollback ready（SchemaRegistry 兼容性、破坏性 major、双版本迁移窗口）— Pending
- [ ] conformance ready（25 TC + NFR-001..012 验证）— Pending
- [ ] CI gates（TX-GATE-001..012 全通过）— Pending
- **`production_import_allowed=false`**：所有 FR/BR/NFR 为 Pending，/home/transportx 实现、conformance gates、CI gates、release evidence 均需归档后方可 factory-grade

## 30. Roadmap
- v1.2.0（Spec approved，runtime pending）：统一传输契约、六通信平面、Envelope/Endpoint/Receipt/ServiceIdentity/QoS/Codec/Registry/ControlPlane/Outbox-Inbox/AuditPlane/DataClassification
- v1.1.1（计划）：首个参考 adapter（kafkax/natsx/in-memory 之一）+ conformance report + release evidence
- 待解决（OQ）：参考 adapter 顺序、control-plane audit/DLQ durable store 选型、SchemaRegistry standalone vs embedded（v1.x embedded）、Protobuf codec（defer 到 v1.3.0）
- 后续：执行模式 gate 集成、跨六平面 trace 完整证据、四源评分
