# transportx Specification

- Status: Approved
- Spec-Version: v1.0.1
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
| Layer | 传输契约 |
| Version | v1.0.1 |
| Status | Approved |
| Last Updated | 2026-06-14 |
| Source of Truth | `module/transportx/SPEC.md` |
| Traceability | `module/transportx/TRACEABILITY.md` |

## 2. Summary

`transportx` 为跨 runtime 与 adapter 的传输层建立稳定契约。它负责定义 Envelope、Endpoint、DeliveryReceipt、ServiceIdentity、运行时生命周期、控制面、错误分类、背压、幂等、观测和 conformance gates，使不同传输实现能被替换、测试和审计。

`transportx` 不实现 broker client，也不定义业务事件语义。具体的 Kafka、NATS、HTTP、RPC、Redis stream 或本地队列实现必须依赖该契约，而不是把传输行为散落在领域模块中。

## 3. Problem Statement

Foundation 模块已有 `contracts` 用于跨域端口、事件协议和 DTO 契约，但传输层仍缺少独立规格。缺口集中在以下方面：

- Envelope 与 Endpoint 没有统一字段、限制和兼容性规则。
- runtime 生命周期缺少 pause、drain、resume、shutdown 与 force-stop 状态机。
- kill switch、mirror、canary、bulkhead 与 backpressure 控制面缺少可审计接口。
- ServiceIdentity、认证、授权、deadline、clock skew、幂等冲突和交付回执没有统一错误映射。
- 中间件顺序没有强制 redaction 先于 logging，存在日志泄漏风险。
- CI 与发布 DoD 没有把 transport conformance 纳入门禁。

## 4. Scope

- 定义传输 Envelope、Endpoint、PayloadRef、Header 与 DeliveryReceipt。
- 定义 runtime 生命周期状态机与 drain/shutdown 语义。
- 定义 ServiceIdentity、认证、授权、租户隔离和审计字段。
- 定义 control plane：kill switch、pause、resume、mirror、canary、bulkhead、rate limit、retry 与 dead-letter。
- 定义错误分类、幂等冲突、timeout、deadline、clock skew 与 saturation 映射。
- 定义 conformance test harness、CI gate 与 release evidence。

## 5. Non-Goals

- 不实现 Kafka、NATS、HTTP、RPC、Redis stream、S3 或数据库客户端。
- 不定义业务事件 schema、领域 DTO、订单语义、行情语义或风控语义。
- 不取代 `contracts` 的跨域端口和 DTO 契约。
- 不提供通用 workflow engine、scheduler、service mesh 或 API gateway。
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

## 9. Interface Contracts

| Interface | Responsibility | Required Methods |
| --- | --- | --- |
| TransportRuntime | Runtime lifecycle and work execution | `Start`, `Pause`, `Resume`, `Drain`, `Shutdown`, `ForceStop` |
| Publisher | Outbound delivery | `Publish`, `Request`, `Stream` |
| Subscriber | Inbound delivery | `Subscribe`, `Ack`, `Nack`, `ExtendDeadline` |
| EndpointRegistry | Endpoint validation and lookup | `Register`, `Resolve`, `Capabilities`, `Deprecate` |
| ControlPlane | Runtime control commands | `Apply`, `Rollback`, `Snapshot`, `Audit` |
| ConformanceSuite | Implementation verification | `RunLifecycle`, `RunEnvelope`, `RunControlPlane`, `RunErrorTaxonomy` |

Interfaces must accept context, ServiceIdentity and immutable request structures. Implementations must return DeliveryReceipt or typed transport error.

## 10. Data Model

| Model | Required Fields |
| --- | --- |
| Envelope | `id`, `type`, `schemaVersion`, `source`, `endpoint`, `tenant`, `createdAt`, `deadlineAt`, `traceContext`, `idempotencyKey`, `headers`, `payloadRef`, `payloadDigest` |
| Endpoint | `scheme`, `authority`, `path`, `topic`, `partitionKeyPolicy`, `capabilities`, `tenantScope`, `owner`, `status`, `version` |
| DeliveryReceipt | `receiptId`, `envelopeId`, `endpoint`, `status`, `ackId`, `offset`, `attempt`, `latencyMs`, `retryDecision`, `errorCode`, `redactionVersion` |
| ServiceIdentity | `service`, `environment`, `tenant`, `trustDomain`, `scopes`, `authnMethod`, `principal`, `issuedAt`, `expiresAt` |
| ControlCommand | `commandId`, `actor`, `target`, `operation`, `previousState`, `newState`, `reason`, `rollbackToken`, `createdAt` |

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

## 15. Dependency Rules

| Dependency | Rule |
| --- | --- |
| contracts | transportx may reference public contract types, but must not import domain DTO implementations. |
| observex | transportx may export metrics and traces through observex interfaces. |
| resiliencx | transportx may consume retry, timeout and bulkhead policy interfaces. |
| configx | transportx may consume immutable runtime configuration. |
| kafkax/natsx/redisx | these modules may implement transportx adapters; transportx must not depend on them. |
| domain modules | domain modules may call transportx through ports; transportx must not import domain packages. |

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

## 17. Observability

| Signal | Required Fields |
| --- | --- |
| Metrics | endpoint, operation, status, error code, retry decision, tenant class, redaction version |
| Traces | trace id, span id, envelope id, endpoint reference, lifecycle state, control command id |
| Logs | redacted envelope id, endpoint reference, error code, receipt id, actor, command id |
| Audit | ServiceIdentity, control command, authz decision, endpoint, timestamp, reason |

Metrics labels must use bounded cardinality fields. Envelope payload and unredacted headers are prohibited in observability output.

## 18. Performance Budget

| Budget | Target |
| --- | --- |
| Envelope validation overhead | p95 <= 1 ms for in-memory validation |
| Middleware overhead | p95 <= 2 ms excluding adapter I/O |
| Control command application | p95 <= 10 ms excluding durable store latency |
| Drain bookkeeping | O(in-flight work) with bounded memory per receipt |
| Redaction | p95 <= 1 ms for metadata-only Envelope |

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

CI must fail if any required gate is absent, skipped or stale against the current `Spec-Version`.

## 21. Migration Plan

| Step | Action |
| --- | --- |
| 1 | Add tracked spec, goal and traceability documents under `module/transportx/`. |
| 2 | Add `transportx` to README, ARCHITECTURE, STATUS and module index. |
| 3 | Add `transportx` to traceability and status consistency gates. |
| 4 | Implement public contract packages in `transportx` repository. |
| 5 | Add conformance suite and adapter examples against one in-memory adapter. |
| 6 | Wire kafkax, natsx or redisx adapters through transportx ports in follow-up tasks. |
| 7 | Publish v1.0.1 tag with conformance report and release evidence. |

## 22. Release DoD

| Requirement | Evidence |
| --- | --- |
| Spec approved | `module/transportx/SPEC.md` status and version |
| Traceability complete | `module/transportx/TRACEABILITY.md` covers every FR |
| CI gates configured | traceability and status consistency scripts include `transportx` |
| Contract implementation | public package compiles in `transportx` repository |
| Conformance passed | lifecycle, envelope, endpoint, control-plane and error taxonomy report |
| Security verified | redaction-before-logging and authz-denial tests pass |
| Compatibility verified | schema registry compatibility report for v1.0.1 |
| Release published | git tag, changelog entry and release notes reference evidence |

## 23. Open Questions

No open questions block v1.0.1 documentation baseline. Future implementation work must decide the first reference adapter and the durable store used for control-plane audit records.
