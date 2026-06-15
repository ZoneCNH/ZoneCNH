# transportx Traceability Matrix

- Module: transportx
- Spec-Version: v1.1.1
- Last-Updated: 2026-06-14
- Source: `module/transportx/SPEC.md`

## Functional Traceability

| Requirement | Description | Type | Source | Acceptance Criteria | Test Case | Task | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| FR-001 | Envelope Schema — 创建包含id/type/version/source/endpoint/tenant/timestamp/deadline/trace/idempotency key/headers/payloadRef的标准信封 | Functional | SPEC §7 | AC-001 | TC-001 | TASK-TRANSPORTX-001 | ✅ |
| FR-002 | Payload Limits — 载荷/Header超限时拒绝并返回TX_PAYLOAD_LIMIT_EXCEEDED或TX_HEADER_LIMIT_EXCEEDED | Functional | SPEC §7 | AC-002 | TC-002 | TASK-TRANSPORTX-001, TASK-TRANSPORTX-006 | ✅ |
| FR-003 | Endpoint Model — 校验scheme/authority/path/topic/partitionKey/capability/tenantScope/owner | Functional | SPEC §7 | AC-003 | TC-003 | TASK-TRANSPORTX-002 | ✅ |
| FR-004 | Runtime Lifecycle — 强制执行Start/Pause/Resume/Drain/Shutdown/ForceStop生命周期状态机 | Functional | SPEC §7 | AC-004 | TC-004 | TASK-TRANSPORTX-004 | ✅ |
| FR-005 | Drain Semantics — 停止接受新工作，完成在途工作并在deadline内报告剩余 | Functional | SPEC §7 | AC-005 | TC-005 | TASK-TRANSPORTX-004 | ✅ |
| FR-006 | Control Plane — 持久化kill switch/pause/resume/mirror/canary/rate-limit命令的审计证据和rollback token | Functional | SPEC §7 | AC-006 | TC-006 | TASK-TRANSPORTX-013 | ✅ |
| FR-007 | Service Identity — 要求ServiceIdentity含service/environment/tenant/trustDomain/scopes/authContext | Functional | SPEC §7 | AC-007 | TC-007 | TASK-TRANSPORTX-003 | ✅ |
| FR-008 | Authorization — 缺少scope时拒绝并返回TX_AUTHZ_DENIED，审计事件不含载荷内容 | Functional | SPEC §7 | AC-008 | TC-008 | TASK-TRANSPORTX-006b, TASK-TRANSPORTX-016 | ✅ |
| FR-009 | Deadline And Clock Skew — 截止时间过期或时钟偏差超限时拒绝/死信 | Functional | SPEC §7 | AC-009 | TC-009 | TASK-TRANSPORTX-006b, TASK-TRANSPORTX-017 | ✅ |
| FR-010 | Idempotency — 幂等键冲突时返回TX_IDEMPOTENCY_CONFLICT且不发布重复工作 | Functional | SPEC §7 | AC-010 | TC-010 | TASK-TRANSPORTX-006, TASK-TRANSPORTX-018 | ✅ |
| FR-011 | Delivery Receipt — 返回含status/endpoint/ackId/offset/attempt/latency/retryDecision/errorCode的回执 | Functional | SPEC §7 | AC-011 | TC-011 | TASK-TRANSPORTX-005 | ✅ |
| FR-012 | Backpressure And Bulkhead — 饱和时应用策略并返回TX_BACKPRESSURE或TX_BULKHEAD_REJECTED | Functional | SPEC §7 | AC-012 | TC-012 | TASK-TRANSPORTX-006, TASK-TRANSPORTX-014 | ✅ |
| FR-013 | Retry And Dead Letter — 可重试失败应用有界重试策略，耗尽后路由到死信并保留trace | Functional | SPEC §7 | AC-013 | TC-013 | TASK-TRANSPORTX-006b, TASK-TRANSPORTX-015 | ✅ |
| FR-014 | Middleware Ordering — 按validation/authn/authz/redaction/logging/tracing/metrics/adapter顺序执行 | Functional | SPEC §7 | AC-014 | TC-014 | TASK-TRANSPORTX-012 | ✅ |
| FR-015 | Schema Compatibility — schema变更分类为兼容或破坏性并记录注册表版本 | Functional | SPEC §7 | AC-015 | TC-015 | TASK-TRANSPORTX-023 | ✅ |
| FR-016 | Conformance Gates — CI运行spec lint/traceability/lifecycle/control-plane/error taxonomy/release evidence检查 | Functional | SPEC §7 | AC-016 | TC-016 | TASK-TRANSPORTX-024, TASK-TRANSPORTX-025 | ✅ |
| FR-017 | QoS Classification — 消息分五级QoS；order/fill/risk/settlement禁用REALTIME_BEST_EFFORT | Functional | SPEC §7 | AC-017 | TC-017 | TASK-TRANSPORTX-006c, TASK-TRANSPORTX-007 | ✅ |
| FR-018 | Codec Interface — 提供Marshal/Unmarshal接口；默认JSON codec实现 | Functional | SPEC §7 | AC-018 | TC-018 | TASK-TRANSPORTX-008 | ✅ |
| FR-019 | TopicRegistry — 校验topic命名({domain}.{version}.{entity}.{action})、schema绑定、QoS分配和所有权 | Functional | SPEC §7 | AC-019 | TC-019 | TASK-TRANSPORTX-009 | ✅ |
| FR-020 | MethodRegistry — 校验method命名/deadline/retry分类(READ_ONLY/IDEMPOTENT/UNSAFE)和幂等要求 | Functional | SPEC §7 | AC-020 | TC-020 | TASK-TRANSPORTX-010 | ✅ |
| FR-021 | Execution Modes — LIVE需auth+deadline+idempotency+audit；REPLAY禁止真实订单；DRY_RUN禁止外部副作用 | Functional | SPEC §7 | AC-021 | TC-021 | TASK-TRANSPORTX-006c, TASK-TRANSPORTX-019 | ✅ |
| FR-022 | Outbox/Inbox SPI — 定义Outbox(Save/MarkPublished/Pending)和Inbox(Seen/MarkProcessed)接口 | Functional | SPEC §7 | AC-022 | TC-022 | TASK-TRANSPORTX-020 | ✅ |
| FR-023 | Audit Plane — 提供AuditSink和ReplaySource接口；审计记录含trace_id/correlation_id，不含secrets | Functional | SPEC §7 | AC-023 | TC-023 | TASK-TRANSPORTX-021 | ✅ |
| FR-024 | Data Classification — 数据分PUBLIC/INTERNAL/CONFIDENTIAL/SECRET四级；敏感数据日志前脱敏 | Functional | SPEC §7 | AC-024 | TC-024 | TASK-TRANSPORTX-022 | ✅ |
| FR-025 | SchemaRegistry — 记录版本/digest/兼容性分类/迁移说明；破坏性变更需主版本升级 | Functional | SPEC §7 | AC-025 | TC-025 | TASK-TRANSPORTX-011, TASK-TRANSPORTX-023 | ✅ |
| FR-026 | Module Identity — README H1 与 go.mod module path 必须为 transportx | Functional | SPEC §7 | AC-026 | TC-016 | TASK-TRANSPORTX-024 | ✅ |

## Business Rule Traceability

| Rule | Source | Verification | Error Code | Status |
| --- | --- | --- | --- | --- |
| BR-001 | SPEC §8 | Payload absent from logs/metrics/audit/receipt | `TX_REDACTION_FAILED` | ✅ |
| BR-002 | SPEC §8 | Middleware order: redaction before logging | `TX_REDACTION_FAILED` | ✅ |
| BR-003 | SPEC §8 | Control command audit + rollback token | `TX_AUDIT_MISSING` | ✅ |
| BR-004 | SPEC §8 | Force-stop marks abandoned with receipt | receipt = `ABANDONED` | ✅ |
| BR-005 | SPEC §8 | Mirror/canary preserve idempotency | `TX_MIRROR_IDEMPOTENCY_VIOLATION` | ✅ |
| BR-006 | SPEC §8 | Adapter fields in namespaced extensions | `TX_SCHEMA_INCOMPATIBLE` | ✅ |
| BR-007 | SPEC §8 | Envelope id + idempotency key stable | `TX_IDEMPOTENCY_CONFLICT` | ✅ |
| BR-008 | SPEC §8 | Monotonic clock + wall-clock skew guard | `TX_CLOCK_SKEW` | ✅ |
| BR-009 | SPEC §8 | Authz failure: no secret/payload leak | `TX_AUTHZ_DENIED` | ✅ |
| BR-010 | SPEC §8 | DLQ retains trace context | `TX_DLQ_INCOMPLETE` | ✅ |
| BR-011 | SPEC §8 | Breaking change → major version bump | `TX_SCHEMA_INCOMPATIBLE` | ✅ |
| BR-012 | SPEC §8 | Release evidence: conformance + drift | CI gate TX-GATE-009 | ✅ |
| BR-013 | SPEC §8 | Order/fill/risk/settlement != REALTIME | `TX_QOS_VIOLATION` | ✅ |
| BR-014 | SPEC §8 | COMMAND_IDEMPOTENT requires key | `TX_QOS_VIOLATION` | ✅ |
| BR-015 | SPEC §8 | Audit events not silently dropped | `TX_AUDIT_DROPPED` | ✅ |
| BR-016 | SPEC §8 | REPLAY/DRY_RUN prevent real order | `TX_MODE_VIOLATION` | ✅ |
| BR-017 | SPEC §8 | Retry class enforcement | `TX_RETRY_UNSAFE` | ✅ |
| BR-018 | SPEC §8 | SECRET absent from all telemetry | `TX_REDACTION_FAILED` | ✅ |

## NFR Traceability

| NFR | Category | Verification | Status |
| --- | --- | --- | --- |
| NFR-001 | Security | TC-024: Data classification redaction | ✅ |
| NFR-002 | Security | TC-014: Middleware redaction order | ✅ |
| NFR-003 | Security | TC-008: Authz denial no leak | ✅ |
| NFR-004 | Security | TC-021: Execution mode gate | ✅ |
| NFR-005 | Observability | Bounded cardinality review | ✅ |
| NFR-006 | Observability | TC-007: Identity trace fields | ✅ |
| NFR-007 | Performance | Benchmark: envelope validation <= 1 ms | ✅ |
| NFR-008 | Performance | Benchmark: middleware <= 2 ms | ✅ |
| NFR-009 | Performance | Benchmark: JSON codec <= 5 ms | ✅ |
| NFR-010 | Reliability | BR-015: Audit drop alert | ✅ |
| NFR-011 | Reliability | TC-013: DLQ trace context | ✅ |
| NFR-012 | Compatibility | TC-025: SchemaRegistry breaking change | ✅ |

## Gate Traceability

| Gate | Covers | Evidence | Status |
| --- | --- | --- | --- |
| TX-GATE-001 | 23-section spec structure | `.github/ci/spec-lint.sh` | ✅ |
| TX-GATE-002 | FR to AC/TC closure | `.github/ci/traceability-check.sh` | ✅ |
| TX-GATE-003 | Foundation module count | `.github/ci/status-consistency-check.sh` | ✅ |
| TX-GATE-004 | README/ARCHITECTURE/STATUS/module index drift | `.github/ci/spec-drift-guard.sh` | ✅ |
| TX-GATE-005 | Envelope, Endpoint, Receipt conformance | conformance report | ✅ |
| TX-GATE-006 | lifecycle, drain, force-stop conformance | conformance report | ✅ |
| TX-GATE-007 | control-plane, authz, redaction-order conformance | conformance report | ✅ |
| TX-GATE-008 | v1.x compatibility | schema compatibility report | ✅ |
| TX-GATE-009 | release evidence | tag, changelog, conformance, drift | ✅ |
| TX-GATE-010 | QoS, Codec, Registry conformance | conformance report | ✅ |
| TX-GATE-011 | Execution Mode, Outbox/Inbox, Audit Plane conformance | conformance report | ✅ |
| TX-GATE-012 | Data Classification, SchemaRegistry conformance | conformance report | ✅ |

## Coverage Notes

- 25 FRs, 18 BRs (with error codes), 12 NFRs, 25 ACs (with verification commands), 25 TCs (with commands), 12 CI gates, 27 Tasks (TASK-TRANSPORTX-001~025, TASK-006b, TASK-006c).
- All FR -> AC -> TC chains closed. All BRs have explicit violation error codes. All FRs mapped to at least one Task.
- `transportx` is a Foundation transport-contract module, not a broker implementation.
- CI gates TX-GATE-001 through TX-GATE-004 are repository-documentation gates.
- CI gates TX-GATE-005 through TX-GATE-012 must be satisfied by the implementation repository before release.
