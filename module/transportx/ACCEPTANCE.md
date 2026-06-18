# transportx 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v1.1.1-spec
- Module-State: 已发布
- Layer: L2.5 通信契约
- Runtime-Repo: /home/transportx
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于验收 transportx 是否达到可发布、可追溯、可复验状态。除非条目明确记录为已通过，默认需要在运行时代码仓库重新执行验证并补充证据。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/ZoneCNH && test -f module/transportx/FEATURES.md && test -f module/transportx/ACCEPTANCE.md | FEATURES.md 与 ACCEPTANCE.md 均存在 |
| 文档格式 | cd /home/ZoneCNH && git diff --check -- module/transportx | 无尾随空格或补丁格式错误 |
| 运行时测试 | cd /home/transportx && go test ./... | 所有包测试通过 |
| 竞态检查 | cd /home/transportx && go test ./... -race -count=1 | 无 data race，测试稳定通过 |
| 静态检查 | cd /home/transportx && go vet ./... | 无 vet 问题 |
| 覆盖率证据 | cd /home/transportx && go test ./... -coverprofile=coverage.out | 覆盖率文件生成并满足模块 Spec 门槛 |
| 依赖边界 | cd /home/transportx && go list -deps ./... | 依赖不越过 FOUNDATION-DEPS.yaml 登记边界 |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-001 | FR-001 | Envelope validation rejects missing identity, endpoint, deadline, trace or payload reference. / go test ./envelope/... -run TestValidateRequired | - | SPEC.md |
| AC-002 | FR-002 | Limit tests cover payload bytes, header count and header bytes. / go test ./envelope/... -run TestLimits | - | SPEC.md |
| AC-003 | FR-003 | Endpoint registration rejects invalid scheme, missing owner and unsupported capability. / go test ./endpoint/... -run TestRegisterInvalid | - | SPEC.md |
| AC-004 | FR-004 | Lifecycle tests cover every allowed transition and every forbidden transition. / go test ./runtime/... -run TestLifecycleTransitions | - | SPEC.md |
| AC-005 | FR-005 | Drain report includes accepted, completed, abandoned and timed-out counts. / go test ./runtime/... -run TestDrainReport | - | SPEC.md |
| AC-006 | FR-006 | Each control command emits audit evidence and rollback token. / go test ./control/... -run TestCommandAudit | - | SPEC.md |
| AC-007 | FR-007 | Missing or expired ServiceIdentity is rejected before adapter dispatch. / go test ./middleware/... -run TestIdentityValidation | - | SPEC.md |
| AC-008 | FR-008 | Scope and tenant violations return TX_AUTHZ_DENIED without payload leakage. / go test ./middleware/... -run TestAuthzDenialNoLeak | - | SPEC.md |
| AC-009 | FR-009 | Expired deadline and clock skew branches produce distinct error codes. / go test ./middleware/... -run TestDeadlineAndSkew | - | SPEC.md |
| AC-010 | FR-010 | Idempotency conflict prevents duplicate publish. / go test ./middleware/... -run TestIdempotencyConflict | - | SPEC.md |
| AC-011 | FR-011 | Receipt includes status, ack, offset, attempt, latency and retry decision. / go test ./receipt/... -run TestReceiptFields | - | SPEC.md |
| AC-012 | FR-012 | Saturation tests cover queue, concurrency, memory and rate limits. / go test ./middleware/... -run TestBackpressure | - | SPEC.md |
| AC-013 | FR-013 | Retry exhaustion creates dead-letter evidence with trace context. / go test ./middleware/... -run TestDLQWithTrace | - | SPEC.md |
| AC-014 | FR-014 | Middleware test proves redaction occurs before logging and tracing. / go test ./middleware/... -run TestRedactionOrder | - | SPEC.md |
| AC-015 | FR-015 | Compatibility test detects breaking schema changes. / go test ./registry/... -run TestSchemaBreakingChange | - | SPEC.md |
| AC-016 | FR-016 | CI blocks release when conformance evidence is missing. / CI gate TX-GATE-009 | - | SPEC.md |
| AC-017 | FR-017 | QoS validation: order/fill/risk events rejected on REALTIME_BEST_EFFORT; COMMAND_IDEMPOTENT without key rejected. / go test ./middleware/... -run TestQoSHardRules | - | SPEC.md |
| AC-018 | FR-018 | Codec round-trip test: Marshal → Unmarshal preserves equality for JSON codec. / go test ./codec/json/... -run TestRoundTrip | - | SPEC.md |
| AC-019 | FR-019 | TopicRegistry rejects duplicate topic name and invalid naming pattern. / go test ./registry/... -run TestTopicValidation | - | SPEC.md |
| AC-020 | FR-020 | MethodRegistry rejects UNSAFE method without explicit retry opt-out annotation. / go test ./registry/... -run TestMethodRetryClass | - | SPEC.md |
| AC-021 | FR-021 | Execution mode test: REPLAY prevents real order; DRY_RUN prevents external side effect; LIVE requires audit sink. / go test ./runtime/... -run TestExecutionModeGates | - | SPEC.md |
| AC-022 | FR-022 | Outbox Save + Pending + MarkPublished cycle passes; Inbox Seen(idempotent) + MarkProcessed cycle passes. / go test ./conformance/... -run TestOutboxInboxCycle | - | SPEC.md |
| AC-023 | FR-023 | AuditSink Append succeeds; Replay replays matching records in order. / go test ./conformance/... -run TestAuditPlane | - | SPEC.md |
| AC-024 | FR-024 | CONFIDENTIAL and SECRET data redacted before logging; SECRET absent from audit and receipt. / go test ./middleware/... -run TestDataClassRedaction | - | SPEC.md |
| AC-025 | FR-025 | SchemaRegistry rejects unknown version; breaking change returns incompatible classification. / go test ./registry/... -run TestSchemaCompatibility | - | SPEC.md |
| AC-026 | FR-026 | README.md H1 is # transportx (not # xlib-standard); go.mod declares module github.com/ZoneCNH/transportx. / grep '^# transportx$$' README.md && grep 'module github.com/ZoneCNH/transportx' go.mod | - | SPEC.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | Envelope required fields | FR-001, AC-001 / go test ./conformance/... -run TestEnvelopeRequiredFields | - | SPEC.md |
| TC-002 | Payload and header limits | FR-002, AC-002 / go test ./conformance/... -run TestPayloadLimits | - | SPEC.md |
| TC-003 | Endpoint registration | FR-003, AC-003 / go test ./conformance/... -run TestEndpointRegistration | - | SPEC.md |
| TC-004 | Lifecycle state machine | FR-004, AC-004 / go test ./conformance/... -run TestLifecycleAllTransitions | - | SPEC.md |
| TC-005 | Drain semantics | FR-005, AC-005 / go test ./conformance/... -run TestDrainSemantics | - | SPEC.md |
| TC-006 | Control-plane audit | FR-006, AC-006 / go test ./conformance/... -run TestControlPlaneAudit | - | SPEC.md |
| TC-007 | ServiceIdentity validation | FR-007, AC-007 / go test ./conformance/... -run TestIdentityValidation | - | SPEC.md |
| TC-008 | Authorization denial | FR-008, AC-008 / go test ./conformance/... -run TestAuthzDenialNoLeak | - | SPEC.md |
| TC-009 | Deadline and clock skew | FR-009, AC-009 / go test ./conformance/... -run TestDeadlineAndSkew | - | SPEC.md |
| TC-010 | Idempotency conflict | FR-010, AC-010 / go test ./conformance/... -run TestIdempotencyConflict | - | SPEC.md |
| TC-011 | DeliveryReceipt shape | FR-011, AC-011 / go test ./conformance/... -run TestReceiptShape | - | SPEC.md |
| TC-012 | Backpressure and bulkhead | FR-012, AC-012 / go test ./conformance/... -run TestBackpressureBulkhead | - | SPEC.md |
| TC-013 | Retry and dead-letter | FR-013, AC-013 / go test ./conformance/... -run TestRetryDLQ | - | SPEC.md |
| TC-014 | Middleware redaction order | FR-014, AC-014 / go test ./conformance/... -run TestRedactionOrder | - | SPEC.md |
| TC-015 | Schema compatibility | FR-015, AC-015 / go test ./conformance/... -run TestSchemaCompatibility | - | SPEC.md |
| TC-016 | Conformance gate failure | FR-016, AC-016 / CI: bash .github/ci/spec-lint.sh module/transportx/SPEC.md | - | SPEC.md |
| TC-017 | QoS classification | FR-017, AC-017 / go test ./conformance/... -run TestQoSHardRules | - | SPEC.md |
| TC-018 | Codec round-trip | FR-018, AC-018 / go test ./conformance/... -run TestCodecRoundTrip | - | SPEC.md |
| TC-019 | TopicRegistry validation | FR-019, AC-019 / go test ./conformance/... -run TestTopicValidation | - | SPEC.md |
| TC-020 | MethodRegistry retry class | FR-020, AC-020 / go test ./conformance/... -run TestMethodRetryClass | - | SPEC.md |
| TC-021 | Execution mode gate | FR-021, AC-021 / go test ./conformance/... -run TestExecutionModeGates | - | SPEC.md |
| TC-022 | Outbox/Inbox cycle | FR-022, AC-022 / go test ./conformance/... -run TestOutboxInboxCycle | - | SPEC.md |
| TC-023 | Audit append and replay | FR-023, AC-023 / go test ./conformance/... -run TestAuditPlane | - | SPEC.md |
| TC-024 | Data classification redaction | FR-024, AC-024 / go test ./conformance/... -run TestDataClassRedaction | - | SPEC.md |
| TC-025 | SchemaRegistry compatibility | FR-025, AC-025 / go test ./conformance/... -run TestSchemaCompatibility | - | SPEC.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | Envelope Schema — 创建包含id/type/version/source/endpoint/tenant/timestamp/deadline/trace/idempotency key/headers/payloadRef的标准信封 | Functional / SPEC §7 / AC-001 / TC-001 / TASK-TRANSPORTX-001 | Pending | TRACEABILITY.md |
| FR-002 | Payload Limits — 载荷/Header超限时拒绝并返回TX_PAYLOAD_LIMIT_EXCEEDED或TX_HEADER_LIMIT_EXCEEDED | Functional / SPEC §7 / AC-002 / TC-002 / TASK-TRANSPORTX-001, TASK-TRANSPORTX-006 | Pending | TRACEABILITY.md |
| FR-003 | Endpoint Model — 校验scheme/authority/path/topic/partitionKey/capability/tenantScope/owner | Functional / SPEC §7 / AC-003 / TC-003 / TASK-TRANSPORTX-002 | Pending | TRACEABILITY.md |
| FR-004 | Runtime Lifecycle — 强制执行Start/Pause/Resume/Drain/Shutdown/ForceStop生命周期状态机 | Functional / SPEC §7 / AC-004 / TC-004 / TASK-TRANSPORTX-004 | Pending | TRACEABILITY.md |
| FR-005 | Drain Semantics — 停止接受新工作，完成在途工作并在deadline内报告剩余 | Functional / SPEC §7 / AC-005 / TC-005 / TASK-TRANSPORTX-004 | Pending | TRACEABILITY.md |
| FR-006 | Control Plane — 持久化kill switch/pause/resume/mirror/canary/rate-limit命令的审计证据和rollback token | Functional / SPEC §7 / AC-006 / TC-006 / TASK-TRANSPORTX-013 | Pending | TRACEABILITY.md |
| FR-007 | Service Identity — 要求ServiceIdentity含service/environment/tenant/trustDomain/scopes/authContext | Functional / SPEC §7 / AC-007 / TC-007 / TASK-TRANSPORTX-003 | Pending | TRACEABILITY.md |
| FR-008 | Authorization — 缺少scope时拒绝并返回TX_AUTHZ_DENIED，审计事件不含载荷内容 | Functional / SPEC §7 / AC-008 / TC-008 / TASK-TRANSPORTX-006b, TASK-TRANSPORTX-016 | Pending | TRACEABILITY.md |
| FR-009 | Deadline And Clock Skew — 截止时间过期或时钟偏差超限时拒绝/死信 | Functional / SPEC §7 / AC-009 / TC-009 / TASK-TRANSPORTX-006b, TASK-TRANSPORTX-017 | Pending | TRACEABILITY.md |
| FR-010 | Idempotency — 幂等键冲突时返回TX_IDEMPOTENCY_CONFLICT且不发布重复工作 | Functional / SPEC §7 / AC-010 / TC-010 / TASK-TRANSPORTX-006, TASK-TRANSPORTX-018 | Pending | TRACEABILITY.md |
| FR-011 | Delivery Receipt — 返回含status/endpoint/ackId/offset/attempt/latency/retryDecision/errorCode的回执 | Functional / SPEC §7 / AC-011 / TC-011 / TASK-TRANSPORTX-005 | Pending | TRACEABILITY.md |
| FR-012 | Backpressure And Bulkhead — 饱和时应用策略并返回TX_BACKPRESSURE或TX_BULKHEAD_REJECTED | Functional / SPEC §7 / AC-012 / TC-012 / TASK-TRANSPORTX-006, TASK-TRANSPORTX-014 | Pending | TRACEABILITY.md |
| FR-013 | Retry And Dead Letter — 可重试失败应用有界重试策略，耗尽后路由到死信并保留trace | Functional / SPEC §7 / AC-013 / TC-013 / TASK-TRANSPORTX-006b, TASK-TRANSPORTX-015 | Pending | TRACEABILITY.md |
| FR-014 | Middleware Ordering — 按validation/authn/authz/redaction/logging/tracing/metrics/adapter顺序执行 | Functional / SPEC §7 / AC-014 / TC-014 / TASK-TRANSPORTX-012 | Pending | TRACEABILITY.md |
| FR-015 | Schema Compatibility — schema变更分类为兼容或破坏性并记录注册表版本 | Functional / SPEC §7 / AC-015 / TC-015 / TASK-TRANSPORTX-023 | Pending | TRACEABILITY.md |
| FR-016 | Conformance Gates — CI运行spec lint/traceability/lifecycle/control-plane/error taxonomy/release evidence检查 | Functional / SPEC §7 / AC-016 / TC-016 / TASK-TRANSPORTX-024, TASK-TRANSPORTX-025 | Pending | TRACEABILITY.md |
| FR-017 | QoS Classification — 消息分五级QoS；order/fill/risk/settlement禁用REALTIME_BEST_EFFORT | Functional / SPEC §7 / AC-017 / TC-017 / TASK-TRANSPORTX-006c, TASK-TRANSPORTX-007 | Pending | TRACEABILITY.md |
| FR-018 | Codec Interface — 提供Marshal/Unmarshal接口；默认JSON codec实现 | Functional / SPEC §7 / AC-018 / TC-018 / TASK-TRANSPORTX-008 | Pending | TRACEABILITY.md |
| FR-019 | TopicRegistry — 校验topic命名({domain}.{version}.{entity}.{action})、schema绑定、QoS分配和所有权 | Functional / SPEC §7 / AC-019 / TC-019 / TASK-TRANSPORTX-009 | Pending | TRACEABILITY.md |
| FR-020 | MethodRegistry — 校验method命名/deadline/retry分类(READ_ONLY/IDEMPOTENT/UNSAFE)和幂等要求 | Functional / SPEC §7 / AC-020 / TC-020 / TASK-TRANSPORTX-010 | Pending | TRACEABILITY.md |
| FR-021 | Execution Modes — LIVE需auth+deadline+idempotency+audit；REPLAY禁止真实订单；DRY_RUN禁止外部副作用 | Functional / SPEC §7 / AC-021 / TC-021 / TASK-TRANSPORTX-006c, TASK-TRANSPORTX-019 | Pending | TRACEABILITY.md |
| FR-022 | Outbox/Inbox SPI — 定义Outbox(Save/MarkPublished/Pending)和Inbox(Seen/MarkProcessed)接口 | Functional / SPEC §7 / AC-022 / TC-022 / TASK-TRANSPORTX-020 | Pending | TRACEABILITY.md |
| FR-023 | Audit Plane — 提供AuditSink和ReplaySource接口；审计记录含trace_id/correlation_id，不含secrets | Functional / SPEC §7 / AC-023 / TC-023 / TASK-TRANSPORTX-021 | Pending | TRACEABILITY.md |
| FR-024 | Data Classification — 数据分PUBLIC/INTERNAL/CONFIDENTIAL/SECRET四级；敏感数据日志前脱敏 | Functional / SPEC §7 / AC-024 / TC-024 / TASK-TRANSPORTX-022 | Pending | TRACEABILITY.md |
| FR-025 | SchemaRegistry — 记录版本/digest/兼容性分类/迁移说明；破坏性变更需主版本升级 | Functional / SPEC §7 / AC-025 / TC-025 / TASK-TRANSPORTX-011, TASK-TRANSPORTX-023 | Pending | TRACEABILITY.md |
| FR-026 | Module Identity — README H1 与 go.mod module path 必须为 transportx | Functional / SPEC §7 / AC-026 / TC-016 / TASK-TRANSPORTX-024 | Pending | TRACEABILITY.md |
| BR-001 | SPEC §8 | Payload absent from logs/metrics/audit/receipt / TX_REDACTION_FAILED | Pending | TRACEABILITY.md |
| BR-002 | SPEC §8 | Middleware order: redaction before logging / TX_REDACTION_FAILED | Pending | TRACEABILITY.md |
| BR-003 | SPEC §8 | Control command audit + rollback token / TX_AUDIT_MISSING | Pending | TRACEABILITY.md |
| BR-004 | SPEC §8 | Force-stop marks abandoned with receipt / receipt = ABANDONED | Pending | TRACEABILITY.md |
| BR-005 | SPEC §8 | Mirror/canary preserve idempotency / TX_MIRROR_IDEMPOTENCY_VIOLATION | Pending | TRACEABILITY.md |
| BR-006 | SPEC §8 | Adapter fields in namespaced extensions / TX_SCHEMA_INCOMPATIBLE | Pending | TRACEABILITY.md |
| BR-007 | SPEC §8 | Envelope id + idempotency key stable / TX_IDEMPOTENCY_CONFLICT | Pending | TRACEABILITY.md |
| BR-008 | SPEC §8 | Monotonic clock + wall-clock skew guard / TX_CLOCK_SKEW | Pending | TRACEABILITY.md |
| BR-009 | SPEC §8 | Authz failure: no secret/payload leak / TX_AUTHZ_DENIED | Pending | TRACEABILITY.md |
| BR-010 | SPEC §8 | DLQ retains trace context / TX_DLQ_INCOMPLETE | Pending | TRACEABILITY.md |
| BR-011 | SPEC §8 | Breaking change → major version bump / TX_SCHEMA_INCOMPATIBLE | Pending | TRACEABILITY.md |
| BR-012 | SPEC §8 | Release evidence: conformance + drift / CI gate TX-GATE-009 | Pending | TRACEABILITY.md |
| BR-013 | SPEC §8 | Order/fill/risk/settlement != REALTIME / TX_QOS_VIOLATION | Pending | TRACEABILITY.md |
| BR-014 | SPEC §8 | COMMAND_IDEMPOTENT requires key / TX_QOS_VIOLATION | Pending | TRACEABILITY.md |
| BR-015 | SPEC §8 | Audit events not silently dropped / TX_AUDIT_DROPPED | Pending | TRACEABILITY.md |
| BR-016 | SPEC §8 | REPLAY/DRY_RUN prevent real order / TX_MODE_VIOLATION | Pending | TRACEABILITY.md |
| BR-017 | SPEC §8 | Retry class enforcement / TX_RETRY_UNSAFE | Pending | TRACEABILITY.md |
| BR-018 | SPEC §8 | SECRET absent from all telemetry / TX_REDACTION_FAILED | Pending | TRACEABILITY.md |
| NFR-001 | Security | TC-024: Data classification redaction | Pending | TRACEABILITY.md |
| NFR-002 | Security | TC-014: Middleware redaction order | Pending | TRACEABILITY.md |
| NFR-003 | Security | TC-008: Authz denial no leak | Pending | TRACEABILITY.md |
| NFR-004 | Security | TC-021: Execution mode gate | Pending | TRACEABILITY.md |
| NFR-005 | Observability | Bounded cardinality review | Pending | TRACEABILITY.md |
| NFR-006 | Observability | TC-007: Identity trace fields | Pending | TRACEABILITY.md |
| NFR-007 | Performance | Benchmark: envelope validation <= 1 ms | Pending | TRACEABILITY.md |
| NFR-008 | Performance | Benchmark: middleware <= 2 ms | Pending | TRACEABILITY.md |
| NFR-009 | Performance | Benchmark: JSON codec <= 5 ms | Pending | TRACEABILITY.md |
| NFR-010 | Reliability | BR-015: Audit drop alert | Pending | TRACEABILITY.md |
| NFR-011 | Reliability | TC-013: DLQ trace context | Pending | TRACEABILITY.md |
| NFR-012 | Compatibility | TC-025: SchemaRegistry breaking change | Pending | TRACEABILITY.md |

## 5. 发布 DoD 清单

- [ ] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。
- [ ] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。
- [ ] 运行时代码仓库 /home/transportx 通过 go test、go test -race、go vet 与覆盖率门槛。
- [ ] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据。
- [ ] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [ ] 版本号、发布标签、CHANGELOG 或 release note 与本目录状态一致。

## 6. 当前缺口登记

- 当前文档只记录验收口径，不替代运行时代码仓库的最新 CI 结果。
- 若上表存在 Pending、Draft、Blocked、Open 或未登记状态，发布前必须补充证据或在模块追溯矩阵中登记豁免理由。
- SPEC/TRACEABILITY 已登记 AC/TC 主链路；当前主要缺口是 /home/transportx 实现、conformance gates、CI gates、release evidence 与集成证据需要归档。
