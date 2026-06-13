# transportx Specification

- Status: Approved
- Spec-Version: v1.1.0
- Last-Updated: 2026-06-14
- Owner: ZoneCNH
- Layer: 基座 · 传输契约
- Repository: https://github.com/ZoneCNH/transportx
- Related-Modules: contracts, observex, resiliencx, configx, natsx, kafkax, redisx, postgresx

## 1. Metadata

| Field | Value |
| --- | --- |
| Module | transportx |
| Domain | 基座 |
| Layer | 传输契约 · 应用通信底座 |
| Version | v1.1.0 |
| Status | Approved |
| Last Updated | 2026-06-14 |
| Source of Truth | `module/transportx/SPEC.md` |
| Traceability | `module/transportx/TRACEABILITY.md` |

## 2. Summary

`transportx` 是 ZoneCNH 的统一应用通信层（应用通信防腐层），负责服务之间、模块之间、服务器之间的通信语义。它为跨 runtime 与 adapter 的传输层建立稳定契约，定义 Envelope、Endpoint、DeliveryReceipt、ServiceIdentity、QoS、Codec、RPC、EventBus、Stream、六通信平面、Deadline、Retry Safety、Error Mapping、Trace Propagation、Auth、Idempotency、Delivery Semantics、DLQ、Replay、Audit 与 Adapter Contract。

定位三角：

```text
contracts 定义"传什么"
transportx 定义"怎么传"
kafkax / natsx / grpc / http / websocket 是"用什么传"
x.go / service adapter 负责"运行时接哪种实现"
```

六通信平面：

| Plane | 默认实现 | 典型通信 | 强约束 |
|---|---|---|---|
| InProcess | Go interface + memory runtime | factor → signal → risk | 无网络、可测试、低复杂度 |
| Command | gRPC / NATS Request-Reply | risk.CheckOrder、order.SubmitOrder | deadline、idempotency、error code |
| Event | Kafka / JetStream | signal.generated、order.filled | durable、ack、replay |
| Realtime | NATS Core / WebSocket / stream | tick、orderbook、dashboard | 低延迟、backpressure、可丢旧 |
| Admin | HTTP / gRPC health | config、health、ops command | auth、rate limit、audit |
| Audit | append-only log / Kafka / JetStream | risk reject、fill、settlement | 不可静默丢、可重放、可对账 |

`transportx` 不实现 broker client，也不定义业务事件语义。具体的 Kafka、NATS、HTTP、RPC、Redis stream 或本地队列实现必须依赖该契约，而不是把传输行为散落在领域模块中。

## 3. Problem Statement

Foundation 模块已有 `contracts` 用于跨域端口、事件协议和 DTO 契约，但传输层仍缺少独立规格。缺口集中在以下方面：

- Envelope 与 Endpoint 没有统一字段、限制和兼容性规则。
- runtime 生命周期缺少 pause、drain、resume、shutdown 与 force-stop 状态机。
- kill switch、mirror、canary、bulkhead 与 backpressure 控制面缺少可审计接口。
- ServiceIdentity、认证、授权、deadline、clock skew、幂等冲突和交付回执没有统一错误映射。
- QoS 分级（REALTIME_BEST_EFFORT / DURABLE_EVENT / COMMAND_IDEMPOTENT / COMMAND_STRICT / AUDIT）未定义，导致不同消息类型混用传输策略。
- Codec 接口未标准化，各 adapter 自行决定序列化方式。
- TopicRegistry、MethodRegistry、SchemaRegistry 未定义，RPC 方法和 Topic 缺少统一注册与兼容性验证。
- 执行模式（LIVE / PAPER / REPLAY / DRY_RUN）没有统一 gate 规则。
- Outbox/Inbox 模式未定义 SPI，业务状态与事件一致性缺少契约。
- Audit Plane 缺少独立接口，审计事件散落在各模块。
- 数据分级（PUBLIC / INTERNAL / CONFIDENTIAL / SECRET）未纳入传输契约。
- 中间件顺序没有强制 redaction 先于 logging，存在日志泄漏风险。
- CI 与发布 DoD 没有把 transport conformance 纳入门禁。

## 4. Scope

- 定义传输 Envelope、Endpoint、PayloadRef、Header 与 DeliveryReceipt。
- 定义 QoS 五级分类：REALTIME_BEST_EFFORT、DURABLE_EVENT、COMMAND_IDEMPOTENT、COMMAND_STRICT、AUDIT。
- 定义六通信平面：InProcess、Command、Event、Realtime、Admin、Audit。
- 定义 Codec 接口与 JSON codec 实现契约。
- 定义 TopicRegistry、MethodRegistry、SchemaRegistry 接口与兼容性规则。
- 定义 runtime 生命周期状态机与 drain/shutdown 语义。
- 定义 ServiceIdentity、认证、授权、租户隔离、审计字段和数据分级。
- 定义 control plane：kill switch、pause、resume、mirror、canary、bulkhead、rate limit、retry 与 dead-letter。
- 定义执行模式：LIVE、PAPER、REPLAY、DRY_RUN 及其 gate 规则。
- 定义 Outbox/Inbox SPI 与 Audit Plane 接口。
- 定义错误分类、幂等冲突、timeout、deadline、clock skew 与 saturation 映射。
- 定义 conformance test harness、CI gate 与 release evidence。

## 5. Non-Goals

- 不实现 Kafka、NATS、HTTP、RPC、Redis stream、S3 或数据库客户端。
- 不定义业务事件 schema、领域 DTO、订单语义、行情语义或风控语义。
- 不取代 `contracts` 的跨域端口和 DTO 契约。
- 不实现业务 outbox 编排、业务幂等语义或业务 workflow engine。
- 不提供通用 scheduler、service mesh 或 API gateway。
- 不保存 payload 明文归档；payload storage 由调用方或 adapter 管理。

## 6. Glossary

| Term | Definition |
| --- | --- |
| Envelope | 传输单元的标准外壳，包含元数据、header、payload reference 和 trace fields。 |
| Endpoint | 传输目的地或来源，包含 scheme、authority、path、topic、partition key 和 capability。 |
| DeliveryReceipt | publish 或 consume 后的可审计结果，包含 ack、offset、attempt、error 与 latency。 |
| ServiceIdentity | 代表调用方服务、租户、环境、权限和信任域的身份结构。 |
| Runtime | 执行 publish、subscribe、request、stream 或 bridge 的传输运行时。 |
| Control Plane | 对 runtime 施加 kill switch、mirror、canary、backpressure 和 drain 等控制的接口。 |
| Conformance | 任何实现必须通过的契约一致性测试集合。 |
| QoS Class | 消息传输质量分级（REALTIME_BEST_EFFORT / DURABLE_EVENT / COMMAND_IDEMPOTENT / COMMAND_STRICT / AUDIT），决定持久化、ack、幂等和可丢弃策略。 |
| Codec | 将业务对象与 Envelope payload 互转的序列化契约接口，第一版提供 JSON codec。 |
| TopicRegistry | 注册和校验业务 Topic 的接口，确保 Topic 命名、schema 和 QoS 绑定。 |
| MethodRegistry | 注册和校验 RPC 方法的接口，确保 method 命名、deadline、retry class 和幂等约束。 |
| SchemaRegistry | 校验 Envelope/Endpoint/Receipt schema 兼容性并记录版本演进的接口。 |
| Execution Mode | 运行时执行模式（LIVE / PAPER / REPLAY / DRY_RUN），决定是否允许真实下单、外部副作用和审计要求。 |
| Outbox/Inbox | 保证业务状态与事件发布一致性的模式：Outbox 在事务中写事件后异步发布；Inbox 去重消费。 |
| Audit Plane | 独立审计通道，记录风控决策、订单状态变更、成交、结算等不可抵赖事件。 |
| Data Class | 数据敏感度分级（PUBLIC / INTERNAL / CONFIDENTIAL / SECRET），决定脱敏和日志策略。 |

## 7. Functional Requirements

### FR-001: Envelope Schema

WHEN a producer sends a message through transportx, THEN the runtime MUST create an Envelope with id, type, version, source, endpoint, tenant, timestamp, deadline, trace context, idempotency key, headers and payload reference.

### FR-002: Payload Limits

WHEN payload bytes or headers exceed configured limits, THEN the runtime MUST reject the Envelope before publish and return `TX_PAYLOAD_LIMIT_EXCEEDED` or `TX_HEADER_LIMIT_EXCEEDED`.

### FR-003: Endpoint Model

WHEN an adapter registers an Endpoint, THEN transportx MUST validate scheme, authority, path, topic, partition key policy, capability flags, tenant scope and ownership metadata.

### FR-004: Runtime Lifecycle

WHEN runtime control changes state, THEN transportx MUST enforce the lifecycle sequence `new -> starting -> running -> paused -> draining -> stopped` with explicit transitions for resume, shutdown and force-stop.

### FR-005: Drain Semantics

WHEN drain is requested, THEN the runtime MUST stop accepting new outbound work, finish in-flight work within deadline and report remaining work in the drain result.

### FR-006: Control Plane

WHEN kill switch, pause, resume, mirror, canary or rate-limit commands are issued, THEN transportx MUST persist the command id, actor, timestamp, target, previous state, new state and rollback token.

### FR-007: Service Identity

WHEN a caller performs publish, subscribe, request or control operation, THEN transportx MUST require ServiceIdentity with service name, environment, tenant, trust domain, scopes and auth context.

### FR-008: Authorization

WHEN ServiceIdentity lacks a required scope for an Endpoint or control operation, THEN transportx MUST deny the call with `TX_AUTHZ_DENIED` and emit an audit event without payload content.

### FR-009: Deadline And Clock Skew

WHEN deadline is expired or producer timestamp exceeds configured skew, THEN transportx MUST reject or dead-letter the Envelope with `TX_DEADLINE_EXCEEDED` or `TX_CLOCK_SKEW`.

### FR-010: Idempotency

WHEN idempotency key collides with incompatible payload digest, THEN transportx MUST return `TX_IDEMPOTENCY_CONFLICT` and MUST NOT publish duplicate work.

### FR-011: Delivery Receipt

WHEN publish, subscribe, request or bridge work completes, THEN transportx MUST return DeliveryReceipt with status, endpoint, ack id, offset, attempt, latency, retry decision and error code.

### FR-012: Backpressure And Bulkhead

WHEN queue, concurrency, rate, memory or adapter saturation limits are exceeded, THEN transportx MUST apply the configured policy and return `TX_BACKPRESSURE` or `TX_BULKHEAD_REJECTED`.

### FR-013: Retry And Dead Letter

WHEN retryable transport failure occurs, THEN transportx MUST apply bounded retry policy and route exhausted work to dead-letter with reason, attempt count and original trace context.

### FR-014: Middleware Ordering

WHEN middleware runs, THEN transportx MUST execute validation, authn, authz, redaction, logging, tracing, metrics and adapter dispatch in that order.

### FR-015: Schema Compatibility

WHEN Envelope, Endpoint, Receipt or control command schema changes, THEN transportx MUST classify the change as compatible or breaking and record registry version plus migration notes.

### FR-016: Conformance Gates

WHEN a transportx implementation claims compatibility, THEN CI MUST run spec lint, traceability check, lifecycle conformance, control-plane conformance, error taxonomy conformance and release evidence checks.

### FR-017: QoS Classification

WHEN a message is produced, THEN transportx MUST classify it into one of five QoS classes: REALTIME_BEST_EFFORT (tick/orderbook, droppable), DURABLE_EVENT (factor/signal/position/PnL, must persist), COMMAND_IDEMPOTENT (order submit/cancel/modify, must have idempotency key), COMMAND_STRICT (risk approval/fund freeze, must persist + idempotent), AUDIT (fill/reject/settlement, immutable append-only). Hard rules: order/fill/risk/settlement events MUST NOT use REALTIME_BEST_EFFORT; COMMAND_IDEMPOTENT without idempotency key MUST be rejected; AUDIT events MUST enter audit sink or durable backend.

### FR-018: Codec Interface

WHEN an adapter serializes or deserializes payload, THEN transportx MUST provide a Codec interface with `Marshal(v any) ([]byte, error)` and `Unmarshal(data []byte, v any) error`. A JSON codec implementation MUST be provided as the default. The Codec MUST be pluggable per Endpoint or per method.

### FR-019: TopicRegistry

WHEN a business module registers a topic, THEN TopicRegistry MUST validate topic naming, schema binding, QoS assignment and ownership. Topic names MUST follow the pattern `{domain}.{version}.{entity}.{action}` (e.g. `order.v1.order.submitted`). Duplicate topic registration MUST be rejected.

### FR-020: MethodRegistry

WHEN a business module registers an RPC method, THEN MethodRegistry MUST validate method naming, input/output schema, required deadline, retry classification (READ_ONLY / IDEMPOTENT / UNSAFE) and idempotency requirement. Method names MUST follow `{service}.{version}.{Service}/{Method}` (e.g. `risk.v1.RiskService/CheckOrder`).

### FR-021: Execution Modes

WHEN the runtime starts, THEN transportx MUST enforce the configured ExecutionMode: LIVE requires auth + deadline + idempotency + audit sink; PAPER allows paper order adapter; REPLAY forbids live exchange adapter and real order submission; DRY_RUN forbids external side effects. Mode transitions MUST require explicit confirmation and emit audit events.

### FR-022: Outbox/Inbox SPI

WHEN business state and event publication must be consistent, THEN transportx MUST define Outbox interface (`Save`, `MarkPublished`, `Pending`) and Inbox interface (`Seen`, `MarkProcessed`). transportx/core MUST define only the SPI, not the business orchestration.

### FR-023: Audit Plane

WHEN audit-worthy events occur (risk decision, order status change, execution fill, settlement, manual override, config change, service lifecycle), THEN transportx MUST provide AuditSink interface (`Append`) and ReplaySource interface (`Replay`). Audit records MUST contain trace_id, correlation_id, and MUST NOT contain secrets. Order status changes MUST be reconstructable from audit log.

### FR-024: Data Classification

WHEN data flows through transportx, THEN it MUST be classified as PUBLIC, INTERNAL, CONFIDENTIAL, or SECRET. CONFIDENTIAL and SECRET data MUST be redacted before logging or tracing export. SECRET data MUST NOT appear in any audit record or DeliveryReceipt text.

### FR-025: SchemaRegistry

WHEN Envelope, Endpoint, Receipt or method schema is registered, THEN SchemaRegistry MUST record schema version, digest, compatibility classification and migration notes. Breaking schema changes MUST require a major version bump. Unknown schema versions MUST be rejected with compatibility error and registry evidence.

## 8. Business Rules

| Rule | Statement |
| --- | --- |
| BR-001 | Payload content MUST NOT appear in logs, metrics labels, audit events or DeliveryReceipt. |
| BR-002 | Redaction MUST execute before logging and tracing exporters receive stringified fields. |
| BR-003 | Control-plane commands MUST be auditable by command id, actor and rollback token. |
| BR-004 | Force-stop MUST mark unfinished work as abandoned and include receipt evidence. |
| BR-005 | Mirror and canary modes MUST preserve production path idempotency semantics. |
| BR-006 | Adapter-specific fields MUST live under namespaced extension blocks. |
| BR-007 | Envelope id and idempotency key MUST be stable across retries. |
| BR-008 | Deadline decisions MUST use monotonic runtime clock plus configured wall-clock skew guard. |
| BR-009 | Authorization failures MUST not expose endpoint secrets or payload bytes. |
| BR-010 | Dead-letter records MUST retain trace context and redacted failure metadata. |
| BR-011 | Breaking schema changes MUST require a major version bump. |
| BR-012 | Release evidence MUST include conformance output and drift-check output. |
| BR-013 | Order, fill, risk and settlement events MUST NOT use REALTIME_BEST_EFFORT QoS. |
| BR-014 | COMMAND_IDEMPOTENT without idempotency_key MUST be rejected before adapter dispatch. |
| BR-015 | Audit events MUST NOT be silently dropped; delivery failure MUST escalate. |
| BR-016 | REPLAY and DRY_RUN modes MUST prevent real order submission and external side effects. |
| BR-017 | READ_ONLY methods may be auto-retried; IDEMPOTENT methods require idempotency key for retry; UNSAFE methods MUST NOT be auto-retried. |
| BR-018 | SECRET-classified data MUST NOT appear in any log, metric, trace span attribute, audit record or receipt text under any circumstance. |

## 9. Interface Contracts

| Interface | Responsibility | Required Methods |
| --- | --- | --- |
| TransportRuntime | Runtime lifecycle and work execution | `Start`, `Pause`, `Resume`, `Drain`, `Shutdown`, `ForceStop` |
| Publisher | Outbound delivery | `Publish`, `Request`, `Stream` |
| Subscriber | Inbound delivery | `Subscribe`, `Ack`, `Nack`, `ExtendDeadline` |
| EndpointRegistry | Endpoint validation and lookup | `Register`, `Resolve`, `Capabilities`, `Deprecate` |
| ControlPlane | Runtime control commands | `Apply`, `Rollback`, `Snapshot`, `Audit` |
| ConformanceSuite | Implementation verification | `RunLifecycle`, `RunEnvelope`, `RunControlPlane`, `RunErrorTaxonomy` |
| Codec | Payload serialization | `Marshal(v any) ([]byte, error)`, `Unmarshal(data []byte, v any) error` |
| TopicRegistry | Topic registration and validation | `Register(topic Topic) error`, `Resolve(name string) (Topic, error)`, `List() []Topic` |
| MethodRegistry | RPC method registration | `Register(method Method) error`, `Resolve(name string) (Method, error)`, `RetryClass(method string) RetryClass` |
| SchemaRegistry | Schema compatibility and versions | `Register(schema Schema) error`, `CheckCompatibility(schema Schema) CompatibilityResult`, `Versions(name string) []Version` |
| AuditSink | Immutable audit append | `Append(ctx context.Context, record AuditRecord) error` |
| ReplaySource | Audit replay | `Replay(ctx context.Context, query ReplayQuery, handler ReplayHandler) error` |
| Outbox | Transactional outbox SPI | `Save(ctx, event Envelope[[]byte]) error`, `MarkPublished(ctx, messageID string) error`, `Pending(ctx, limit int) ([]Envelope[[]byte], error)` |
| Inbox | Idempotent consumer SPI | `Seen(ctx, messageID string) (bool, error)`, `MarkProcessed(ctx, messageID string) error` |

Interfaces must accept context, ServiceIdentity and immutable request structures. Implementations must return DeliveryReceipt or typed transport error.

## 10. Data Model

| Model | Required Fields |
| --- | --- |
| Envelope | `id`, `type`, `schemaVersion`, `source`, `endpoint`, `tenant`, `createdAt`, `deadlineAt`, `traceContext`, `idempotencyKey`, `headers`, `payloadRef`, `payloadDigest` |
| Endpoint | `scheme`, `authority`, `path`, `topic`, `partitionKeyPolicy`, `capabilities`, `tenantScope`, `owner`, `status`, `version` |
| DeliveryReceipt | `receiptId`, `envelopeId`, `endpoint`, `status`, `ackId`, `offset`, `attempt`, `latencyMs`, `retryDecision`, `errorCode`, `redactionVersion` |
| ServiceIdentity | `service`, `environment`, `tenant`, `trustDomain`, `scopes`, `authnMethod`, `principal`, `issuedAt`, `expiresAt` |
| ControlCommand | `commandId`, `actor`, `target`, `operation`, `previousState`, `newState`, `reason`, `rollbackToken`, `createdAt` |
| QoSClass | enum: `REALTIME_BEST_EFFORT`, `DURABLE_EVENT`, `COMMAND_IDEMPOTENT`, `COMMAND_STRICT`, `AUDIT` |
| ExecutionMode | enum: `LIVE`, `PAPER`, `REPLAY`, `DRY_RUN` |
| RetryClass | enum: `NONE`, `READ_ONLY`, `IDEMPOTENT`, `UNSAFE` |
| BackpressurePolicy | enum: `BLOCK`, `DROP_OLDEST`, `DROP_NEWEST`, `FAIL_FAST`, `SPILL_TO_DISK` |
| DLQPolicy | `enabled`, `maxAttempts`, `topicSuffix`, `includePayload`, `includeError` |
| DataClass | enum: `PUBLIC`, `INTERNAL`, `CONFIDENTIAL`, `SECRET` |
| AuditRecord | `recordId`, `traceId`, `correlationId`, `actor`, `action`, `target`, `result`, `timestamp`, `dataClass` |
| Topic | `name`, `domain`, `version`, `entity`, `action`, `qosClass`, `schemaRef`, `owner` |
| Method | `name`, `service`, `version`, `inputSchema`, `outputSchema`, `requiredDeadline`, `retryClass`, `requiresIdempotency` |

Payload storage is represented through `payloadRef` and `payloadDigest`. Raw payload bytes are never part of audit output.

## 11. Error Handling

| Error Code | Trigger | Required Response |
| --- | --- | --- |
| TX_PAYLOAD_LIMIT_EXCEEDED | Payload exceeds limit | Reject before publish |
| TX_HEADER_LIMIT_EXCEEDED | Header count or size exceeds limit | Reject before publish |
| TX_ENDPOINT_INVALID | Endpoint validation fails | Reject registration or request |
| TX_AUTHN_REQUIRED | Missing authentication context | Deny and audit |
| TX_AUTHZ_DENIED | Missing scope or tenant permission | Deny and audit |
| TX_DEADLINE_EXCEEDED | Deadline expired | Reject or dead-letter |
| TX_CLOCK_SKEW | Producer timestamp outside skew guard | Reject or dead-letter |
| TX_IDEMPOTENCY_CONFLICT | Same key with different digest | Reject duplicate work |
| TX_BACKPRESSURE | Rate, queue or memory saturation | Apply policy and return receipt |
| TX_BULKHEAD_REJECTED | Bulkhead capacity exhausted | Reject with retry hint |
| TX_ADAPTER_FAILURE | Adapter returns failure | Retry or dead-letter |
| TX_CONTROL_CONFLICT | Concurrent control command conflict | Reject command with current state |
| TX_QOS_VIOLATION | QoS constraints violated (e.g. order event on REALTIME) | Reject before publish |
| TX_MODE_VIOLATION | Execution mode constraint violated (e.g. real order in REPLAY) | Deny and audit |
| TX_SCHEMA_INCOMPATIBLE | Schema version unknown or breaking | Reject with registry evidence |
| TX_TOPIC_DUPLICATE | Duplicate topic registration | Reject registration |
| TX_METHOD_DUPLICATE | Duplicate method registration | Reject registration |
| TX_RETRY_UNSAFE | Auto-retry attempted on UNSAFE method | Deny retry and escalate |

Every error must include stable code, redacted message, retry classification, endpoint reference and trace id.

## 12. Edge Cases

| Case | Required Behavior |
| --- | --- |
| Drain deadline expires | Return partial drain result and mark unfinished work. |
| Pause during retry loop | Stop scheduling new attempts and keep pending work visible. |
| Force-stop during in-flight publish | Mark receipt abandoned and require adapter reconciliation. |
| Mirror target rejects work | Preserve primary delivery result and emit mirror failure receipt. |
| Canary rollback | Stop routing new canary work and keep existing receipts traceable. |
| Duplicate ack | Return idempotent receipt with original ack metadata. |
| Unknown schema version | Reject with compatibility error and registry evidence. |
| Redaction failure | Fail closed before logging or adapter dispatch. |
| QoS downgrade on saturation | For REALTIME_BEST_EFFORT, drop oldest; for AUDIT, spill to disk and alert. |
| Mode transition during in-flight work | Drain in-flight work before completing mode switch. |
| Outbox relay crash before mark | Re-publish must be idempotent via message_id dedup in Inbox. |
| DLQ poison message loop | After maxAttempts, park in DLQ and stop auto-retry; require manual runbook. |
| SECRET data in audit path | Fail closed: reject audit append if redaction version is missing. |

## 13. Acceptance Criteria

| AC | Requirement | Criterion |
| --- | --- | --- |
| AC-001 | FR-001 | Envelope validation rejects missing identity, endpoint, deadline, trace or payload reference. |
| AC-002 | FR-002 | Limit tests cover payload bytes, header count and header bytes. |
| AC-003 | FR-003 | Endpoint registration rejects invalid scheme, missing owner and unsupported capability. |
| AC-004 | FR-004 | Lifecycle tests cover every allowed transition and every forbidden transition. |
| AC-005 | FR-005 | Drain report includes accepted, completed, abandoned and timed-out counts. |
| AC-006 | FR-006 | Each control command emits audit evidence and rollback token. |
| AC-007 | FR-007 | Missing or expired ServiceIdentity is rejected before adapter dispatch. |
| AC-008 | FR-008 | Scope and tenant violations return `TX_AUTHZ_DENIED` without payload leakage. |
| AC-009 | FR-009 | Expired deadline and clock skew branches produce distinct error codes. |
| AC-010 | FR-010 | Idempotency conflict prevents duplicate publish. |
| AC-011 | FR-011 | Receipt includes status, ack, offset, attempt, latency and retry decision. |
| AC-012 | FR-012 | Saturation tests cover queue, concurrency, memory and rate limits. |
| AC-013 | FR-013 | Retry exhaustion creates dead-letter evidence with trace context. |
| AC-014 | FR-014 | Middleware test proves redaction occurs before logging and tracing. |
| AC-015 | FR-015 | Compatibility test detects breaking schema changes. |
| AC-016 | FR-016 | CI blocks release when conformance evidence is missing. |
| AC-017 | FR-017 | QoS validation: order/fill/risk events rejected on REALTIME_BEST_EFFORT; COMMAND_IDEMPOTENT without key rejected. |
| AC-018 | FR-018 | Codec round-trip test: Marshal → Unmarshal preserves equality for JSON codec. |
| AC-019 | FR-019 | TopicRegistry rejects duplicate topic name and invalid naming pattern. |
| AC-020 | FR-020 | MethodRegistry rejects UNSAFE method without explicit retry opt-out annotation. |
| AC-021 | FR-021 | Execution mode test: REPLAY prevents real order; DRY_RUN prevents external side effect; LIVE requires audit sink. |
| AC-022 | FR-022 | Outbox Save + Pending + MarkPublished cycle passes; Inbox Seen(idempotent) + MarkProcessed cycle passes. |
| AC-023 | FR-023 | AuditSink Append succeeds; Replay replays matching records in order. |
| AC-024 | FR-024 | CONFIDENTIAL and SECRET data redacted before logging; SECRET absent from audit and receipt. |
| AC-025 | FR-025 | SchemaRegistry rejects unknown version; breaking change returns incompatible classification. |

## 14. Directory Structure

The implementation repository must keep public contracts separate from adapter implementations:

| Path | Purpose |
| --- | --- |
| `envelope/` | Envelope, header, payload reference and validation contracts |
| `endpoint/` | Endpoint model, registry and capability contracts |
| `identity/` | ServiceIdentity and auth context contracts |
| `runtime/` | lifecycle interfaces and state machine |
| `control/` | control-plane command and audit contracts |
| `receipt/` | DeliveryReceipt and ack contracts |
| `errors/` | typed transport error taxonomy |
| `conformance/` | reusable implementation test suite |
| `docs/` | release evidence and compatibility notes |
| `codec/` | Codec interface; `codec/json/` default JSON implementation |
| `rpc/` | RPC client, server, handler, option and validation contracts |
| `eventbus/` | EventBus publisher, subscriber, subscription and validation contracts |
| `stream/` | Stream client, backpressure and message contracts |
| `middleware/` | Middleware chain and individual middleware (recover, validate, identity, trace, metrics, logging, redaction, deadline, auth, idempotency, retry_safety, ratelimit, circuit) |
| `registry/` | TopicRegistry, MethodRegistry and SchemaRegistry contracts |
| `memory/` | In-memory runtime, RPC, eventbus, stream and registry for testing |
| `adapters/` | Adapter implementations — each with independent `go.mod` |
| `adapters/grpc/` | gRPC adapter (module `github.com/ZoneCNH/transportx/adapters/grpc`) |
| `adapters/kafka/` | Kafka adapter (module `github.com/ZoneCNH/transportx/adapters/kafka`) |
| `adapters/nats/` | NATS adapter (module `github.com/ZoneCNH/transportx/adapters/nats`) |
| `adapters/http/` | HTTP adapter (module `github.com/ZoneCNH/transportx/adapters/http`) |
| `adapters/websocket/` | WebSocket adapter |
| `adapters/redisidem/` | Redis-backed idempotency store adapter |
| `adapters/postgresoutbox/` | PostgreSQL-backed outbox adapter |
| `adapters/clickhouseaudit/` | ClickHouse-backed audit sink adapter |
| `adapters/s3replay/` | S3-backed replay source adapter |

Multi-module layout: root `go.mod` (core module `github.com/ZoneCNH/transportx`), each `adapters/*/go.mod` is a separate Go module. `go.work` unifies for local development and CI. Core does not import any adapter. Adapters may import core.

## 15. Dependency Rules

| Dependency | Rule |
| --- | --- |
| contracts | transportx may reference public contract types, but must not import domain DTO implementations. |
| observex | transportx may export metrics and traces through observex interfaces. |
| resiliencx | transportx may consume retry, timeout and bulkhead policy interfaces. |
| configx | transportx may consume immutable runtime configuration. |
| kafkax/natsx/redisx | these modules may implement transportx adapters; transportx must not depend on them. |
| domain modules | domain modules may call transportx through ports; transportx must not import domain packages. |
| adapters/* | each adapter module MAY import transportx/core; transportx/core MUST NOT import any adapter. |

No production implementation may add a new dependency edge that violates `module/FOUNDATION-DEPS.yaml`.

## 16. Security Requirements

| Requirement | Control |
| --- | --- |
| Payload secrecy | Payload bytes stay outside logs, metrics, audit and receipt text. |
| Identity binding | Every operation requires ServiceIdentity and trust-domain validation. |
| Scope enforcement | Endpoint and control operations validate scopes before dispatch. |
| Tenant isolation | Endpoint resolution and idempotency stores include tenant scope. |
| Auditability | Control-plane and authorization failures produce immutable audit events. |
| Fail-closed redaction | Redaction errors block logging and adapter dispatch. |
| Data classification | CONFIDENTIAL and SECRET data redacted before telemetry; SECRET blocked from audit and receipt. |
| Mode gate | REPLAY and DRY_RUN modes prevent real order submission and external side effects. |
| Secret-free audit | AuditRecord must not contain SECRET-classified fields. |

## 17. Observability

| Signal | Required Fields |
| --- | --- |
| Metrics | endpoint, operation, status, error code, retry decision, qos class, tenant class, redaction version |
| Traces | trace id, span id, envelope id, endpoint reference, lifecycle state, control command id, qos class |
| Logs | redacted envelope id, endpoint reference, error code, receipt id, actor, command id, data class |
| Audit | ServiceIdentity, control command, authz decision, endpoint, timestamp, reason, execution mode |

Metrics labels must use bounded cardinality fields. Envelope payload and unredacted headers are prohibited in observability output. SECRET data must never appear in any observability output.

## 18. Performance Budget

| Budget | Target |
| --- | --- |
| Envelope validation overhead | p95 <= 1 ms for in-memory validation |
| Middleware overhead | p95 <= 2 ms excluding adapter I/O |
| Control command application | p95 <= 10 ms excluding durable store latency |
| Drain bookkeeping | O(in-flight work) with bounded memory per receipt |
| Redaction | p95 <= 1 ms for metadata-only Envelope |
| JSON codec round-trip | p95 <= 5 ms for 1 KB payload |
| TopicRegistry resolution | p95 <= 0.1 ms for in-memory registry |
| Audit append | p95 <= 20 ms excluding sink I/O |

Implementations must report benchmark hardware, runtime version and adapter type in release evidence.

## 19. Test Matrix

| Test | Coverage |
| --- | --- |
| **TC-001:** Envelope required fields | FR-001, AC-001 |
| **TC-002:** Payload and header limits | FR-002, AC-002 |
| **TC-003:** Endpoint registration | FR-003, AC-003 |
| **TC-004:** Lifecycle state machine | FR-004, AC-004 |
| **TC-005:** Drain semantics | FR-005, AC-005 |
| **TC-006:** Control-plane audit | FR-006, AC-006 |
| **TC-007:** ServiceIdentity validation | FR-007, AC-007 |
| **TC-008:** Authorization denial | FR-008, AC-008 |
| **TC-009:** Deadline and clock skew | FR-009, AC-009 |
| **TC-010:** Idempotency conflict | FR-010, AC-010 |
| **TC-011:** DeliveryReceipt shape | FR-011, AC-011 |
| **TC-012:** Backpressure and bulkhead | FR-012, AC-012 |
| **TC-013:** Retry and dead-letter | FR-013, AC-013 |
| **TC-014:** Middleware redaction order | FR-014, AC-014 |
| **TC-015:** Schema compatibility | FR-015, AC-015 |
| **TC-016:** Conformance gate failure | FR-016, AC-016 |
| **TC-017:** QoS classification and hard rules | FR-017, AC-017 |
| **TC-018:** Codec round-trip | FR-018, AC-018 |
| **TC-019:** TopicRegistry validation | FR-019, AC-019 |
| **TC-020:** MethodRegistry retry classification | FR-020, AC-020 |
| **TC-021:** Execution mode gate | FR-021, AC-021 |
| **TC-022:** Outbox/Inbox cycle | FR-022, AC-022 |
| **TC-023:** Audit append and replay | FR-023, AC-023 |
| **TC-024:** Data classification redaction | FR-024, AC-024 |
| **TC-025:** SchemaRegistry compatibility | FR-025, AC-025 |

## 20. CI Gate

| Gate | Command Or Evidence | Blocks Release |
| --- | --- | --- |
| TX-GATE-001 | `.github/ci/spec-lint.sh` includes `module/transportx/SPEC.md` | Yes |
| TX-GATE-002 | `.github/ci/traceability-check.sh` requires `transportx` | Yes |
| TX-GATE-003 | `.github/ci/status-consistency-check.sh` expects 17 Foundation specs | Yes |
| TX-GATE-004 | `.github/ci/spec-drift-guard.sh` checks README, ARCHITECTURE, STATUS and module index drift | Yes |
| TX-GATE-005 | Conformance suite passes Envelope, Endpoint and Receipt tests | Yes |
| TX-GATE-006 | Conformance suite passes lifecycle, drain and force-stop tests | Yes |
| TX-GATE-007 | Conformance suite passes control-plane, authz and redaction-order tests | Yes |
| TX-GATE-008 | Compatibility checker confirms no breaking schema drift inside v1.x | Yes |
| TX-GATE-009 | Release evidence contains changelog, tag, conformance output and drift output | Yes |
| TX-GATE-010 | Conformance suite passes QoS classification, Codec round-trip and Registry validation tests | Yes |
| TX-GATE-011 | Conformance suite passes Execution Mode gate, Outbox/Inbox and Audit Plane tests | Yes |
| TX-GATE-012 | Conformance suite passes Data Classification redaction and SchemaRegistry compatibility tests | Yes |

CI must fail if any required gate is absent, skipped or stale against the current `Spec-Version`.

## 21. Migration Plan

| Step | Action |
| --- | --- |
| 1 | Add tracked spec, goal and traceability documents under `module/transportx/`. |
| 2 | Add `transportx` to README, ARCHITECTURE, STATUS and module index. |
| 3 | Add `transportx` to traceability and status consistency gates. |
| 4 | Implement public contract packages in `transportx` repository (core module). |
| 5 | Add Codec interface and JSON codec implementation. |
| 6 | Add TopicRegistry, MethodRegistry and SchemaRegistry contracts. |
| 7 | Add conformance suite and in-memory adapter for all interfaces. |
| 8 | Wire kafkax, natsx or redisx adapters through transportx ports in follow-up tasks. |
| 9 | Implement adapter modules (grpc, kafka, nats, http) with independent go.mod. |
| 10 | Publish v1.1.0 tag with conformance report and release evidence. |

## 22. Release DoD

| Requirement | Evidence |
| --- | --- |
| Spec approved | `module/transportx/SPEC.md` status and version |
| Traceability complete | `module/transportx/TRACEABILITY.md` covers every FR |
| CI gates configured | traceability and status consistency scripts include `transportx` |
| Contract implementation | public package compiles in `transportx` repository |
| Codec verified | JSON codec round-trip tests pass |
| Registry verified | TopicRegistry, MethodRegistry, SchemaRegistry validation tests pass |
| Conformance passed | lifecycle, envelope, endpoint, control-plane, error taxonomy, QoS, mode, outbox/inbox, audit and data classification report |
| Security verified | redaction-before-logging, authz-denial, mode-gate and secret-free-audit tests pass |
| Compatibility verified | schema registry compatibility report for v1.1.0 |
| Release published | git tag, changelog entry and release notes reference evidence |

## 23. Open Questions

| # | Question | Status |
| --- | --- | --- |
| OQ-1 | Which reference adapter (kafkax, natsx, or in-memory) ships first with v1.1.0? | Deferred to implementation |
| OQ-2 | What durable store backs control-plane audit records and DLQ? | Deferred to implementation |
| OQ-3 | Should SchemaRegistry use a standalone service or embedded library? | Embedded library for v1.x; standalone deferred |
| OQ-4 | Protobuf codec: include in v1.1.0 or defer to v1.2.0? | Defer to v1.2.0 |
