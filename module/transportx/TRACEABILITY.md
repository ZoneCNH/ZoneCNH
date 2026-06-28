# transportx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-29
Source: `module/transportx/SPEC.md` v1.1.1

---

## §1 功能需求追溯（FR）

| Requirement | Description | Acceptance Criteria | TC ID(s) | Task | Status |
| --- | --- | --- | --- | --- | --- |
| FR-001 | Envelope Schema — 创建包含id/type/version/source/endpoint/tenant/timestamp/deadline/trace/idempotency key/headers/payloadRef的标准信封 | AC-001 | TC-001 | TASK-TRANSPORTX-001 | Pending |
| FR-002 | Payload Limits — 载荷/Header超限时拒绝并返回TX_PAYLOAD_LIMIT_EXCEEDED或TX_HEADER_LIMIT_EXCEEDED | AC-002 | TC-002 | TASK-TRANSPORTX-001, TASK-TRANSPORTX-006 | Pending |
| FR-003 | Endpoint Model — 校验scheme/authority/path/topic/partitionKey/capability/tenantScope/owner | AC-003 | TC-003 | TASK-TRANSPORTX-002 | Pending |
| FR-004 | Runtime Lifecycle — 强制执行Start/Pause/Resume/Drain/Shutdown/ForceStop生命周期状态机 | AC-004 | TC-004 | TASK-TRANSPORTX-004 | Pending |
| FR-005 | Drain Semantics — 停止接受新工作，完成在途工作并在deadline内报告剩余 | AC-005 | TC-005 | TASK-TRANSPORTX-004 | Pending |
| FR-006 | Control Plane — 持久化kill switch/pause/resume/mirror/canary/rate-limit命令的审计证据和rollback token | AC-006 | TC-006 | TASK-TRANSPORTX-013 | Pending |
| FR-007 | Service Identity — 要求ServiceIdentity含service/environment/tenant/trustDomain/scopes/authContext | AC-007 | TC-007 | TASK-TRANSPORTX-003 | Pending |
| FR-008 | Authorization — 缺少scope时拒绝并返回TX_AUTHZ_DENIED，审计事件不含载荷内容 | AC-008 | TC-008 | TASK-TRANSPORTX-006b, TASK-TRANSPORTX-016 | Pending |
| FR-009 | Deadline And Clock Skew — 截止时间过期或时钟偏差超限时拒绝/死信 | AC-009 | TC-009 | TASK-TRANSPORTX-006b, TASK-TRANSPORTX-017 | Pending |
| FR-010 | Idempotency — 幂等键冲突时返回TX_IDEMPOTENCY_CONFLICT且不发布重复工作 | AC-010 | TC-010 | TASK-TRANSPORTX-006, TASK-TRANSPORTX-018 | Pending |
| FR-011 | Delivery Receipt — 返回含status/endpoint/ackId/offset/attempt/latency/retryDecision/errorCode的回执 | AC-011 | TC-011 | TASK-TRANSPORTX-005 | Pending |
| FR-012 | Backpressure And Bulkhead — 饱和时应用策略并返回TX_BACKPRESSURE或TX_BULKHEAD_REJECTED | AC-012 | TC-012 | TASK-TRANSPORTX-006, TASK-TRANSPORTX-014 | Pending |
| FR-013 | Retry And Dead Letter — 可重试失败应用有界重试策略，耗尽后路由到死信并保留trace | AC-013 | TC-013 | TASK-TRANSPORTX-006b, TASK-TRANSPORTX-015 | Pending |
| FR-014 | Middleware Ordering — 按validation/authn/authz/redaction/logging/tracing/metrics/adapter顺序执行 | AC-014 | TC-014 | TASK-TRANSPORTX-012 | Pending |
| FR-015 | Schema Compatibility — schema变更分类为兼容或破坏性并记录注册表版本 | AC-015 | TC-015 | TASK-TRANSPORTX-023 | Pending |
| FR-016 | Conformance Gates — CI运行spec lint/traceability/lifecycle/control-plane/error taxonomy/release evidence检查 | AC-016 | TC-016 | TASK-TRANSPORTX-024, TASK-TRANSPORTX-025 | Pending |
| FR-017 | QoS Classification — 消息分五级QoS；order/fill/risk/settlement禁用REALTIME_BEST_EFFORT | AC-017 | TC-017 | TASK-TRANSPORTX-006c, TASK-TRANSPORTX-007 | Pending |
| FR-018 | Codec Interface — 提供Marshal/Unmarshal接口；默认JSON codec实现 | AC-018 | TC-018 | TASK-TRANSPORTX-008 | Pending |
| FR-019 | TopicRegistry — 校验topic命名({domain}.{version}.{entity}.{action})、schema绑定、QoS分配和所有权 | AC-019 | TC-019 | TASK-TRANSPORTX-009 | Pending |
| FR-020 | MethodRegistry — 校验method命名/deadline/retry分类(READ_ONLY/IDEMPOTENT/UNSAFE)和幂等要求 | AC-020 | TC-020 | TASK-TRANSPORTX-010 | Pending |
| FR-021 | Execution Modes — LIVE需auth+deadline+idempotency+audit；REPLAY禁止真实订单；DRY_RUN禁止外部副作用 | AC-021 | TC-021 | TASK-TRANSPORTX-006c, TASK-TRANSPORTX-019 | Pending |
| FR-022 | Outbox/Inbox SPI — 定义Outbox(Save/MarkPublished/Pending)和Inbox(Seen/MarkProcessed)接口 | AC-022 | TC-022 | TASK-TRANSPORTX-020 | Pending |
| FR-023 | Audit Plane — 提供AuditSink和ReplaySource接口；审计记录含trace_id/correlation_id，不含secrets | AC-023 | TC-023 | TASK-TRANSPORTX-021 | Pending |
| FR-024 | Data Classification — 数据分PUBLIC/INTERNAL/CONFIDENTIAL/SECRET四级；敏感数据日志前脱敏 | AC-024 | TC-024 | TASK-TRANSPORTX-022 | Pending |
| FR-025 | SchemaRegistry — 记录版本/digest/兼容性分类/迁移说明；破坏性变更需主版本升级 | AC-025 | TC-025 | TASK-TRANSPORTX-011, TASK-TRANSPORTX-023 | Pending |
| FR-026 | Module Identity — README H1 与 go.mod module path 必须为 transportx | AC-026 | TC-016 | TASK-TRANSPORTX-024 | Pending |

---

## §2 业务规则追溯（BR）

| BR ID | Rule | Error Code | Task | Status |
| --- | --- | --- | --- | --- |
| BR-001 | Payload absent from logs/metrics/audit/receipt | `TX_REDACTION_FAILED` | TASK-TRANSPORTX-022 | Pending |
| BR-002 | Middleware order: redaction before logging | `TX_REDACTION_FAILED` | TASK-TRANSPORTX-012 | Pending |
| BR-003 | Control command audit + rollback token | `TX_AUDIT_MISSING` | TASK-TRANSPORTX-013 | Pending |
| BR-004 | Force-stop marks abandoned with receipt | receipt = `ABANDONED` | TASK-TRANSPORTX-004 | Pending |
| BR-005 | Mirror/canary preserve idempotency | `TX_MIRROR_IDEMPOTENCY_VIOLATION` | TASK-TRANSPORTX-013 | Pending |
| BR-006 | Adapter fields in namespaced extensions | `TX_SCHEMA_INCOMPATIBLE` | TASK-TRANSPORTX-012 | Pending |
| BR-007 | Envelope id + idempotency key stable | `TX_IDEMPOTENCY_CONFLICT` | TASK-TRANSPORTX-001, TASK-TRANSPORTX-018 | Pending |
| BR-008 | Monotonic clock + wall-clock skew guard | `TX_CLOCK_SKEW` | TASK-TRANSPORTX-017 | Pending |
| BR-009 | Authz failure: no secret/payload leak | `TX_AUTHZ_DENIED` | TASK-TRANSPORTX-016 | Pending |
| BR-010 | DLQ retains trace context | `TX_DLQ_INCOMPLETE` | TASK-TRANSPORTX-015 | Pending |
| BR-011 | Breaking change → major version bump | `TX_SCHEMA_INCOMPATIBLE` | TASK-TRANSPORTX-023 | Pending |
| BR-012 | Release evidence: conformance + drift | CI gate TX-GATE-009 | TASK-TRANSPORTX-024, TASK-TRANSPORTX-025 | Pending |
| BR-013 | Order/fill/risk/settlement != REALTIME | `TX_QOS_VIOLATION` | TASK-TRANSPORTX-007 | Pending |
| BR-014 | COMMAND_IDEMPOTENT requires key | `TX_QOS_VIOLATION` | TASK-TRANSPORTX-007 | Pending |
| BR-015 | Audit events not silently dropped | `TX_AUDIT_DROPPED` | TASK-TRANSPORTX-021 | Pending |
| BR-016 | REPLAY/DRY_RUN prevent real order | `TX_MODE_VIOLATION` | TASK-TRANSPORTX-019 | Pending |
| BR-017 | Retry class enforcement | `TX_RETRY_UNSAFE` | TASK-TRANSPORTX-015 | Pending |
| BR-018 | SECRET absent from all telemetry | `TX_REDACTION_FAILED` | TASK-TRANSPORTX-022 | Pending |

---

## §3 非功能需求追溯（NFR）

| NFR | Category | Verification | Task | Status |
| --- | --- | --- | --- | --- |
| NFR-001 | Security | TC-024: Data classification redaction | TASK-TRANSPORTX-022 | Pending |
| NFR-002 | Security | TC-014: Middleware redaction order | TASK-TRANSPORTX-012 | Pending |
| NFR-003 | Security | TC-008: Authz denial no leak | TASK-TRANSPORTX-016 | Pending |
| NFR-004 | Security | TC-021: Execution mode gate | TASK-TRANSPORTX-019 | Pending |
| NFR-005 | Observability | Bounded cardinality review | TASK-TRANSPORTX-012 | Pending |
| NFR-006 | Observability | TC-007: Identity trace fields | TASK-TRANSPORTX-003 | Pending |
| NFR-007 | Performance | Benchmark: envelope validation <= 1 ms | TASK-TRANSPORTX-001 | Pending |
| NFR-008 | Performance | Benchmark: middleware <= 2 ms | TASK-TRANSPORTX-012 | Pending |
| NFR-009 | Performance | Benchmark: JSON codec <= 5 ms | TASK-TRANSPORTX-008 | Pending |
| NFR-010 | Reliability | BR-015: Audit drop alert | TASK-TRANSPORTX-021 | Pending |
| NFR-011 | Reliability | TC-013: DLQ trace context | TASK-TRANSPORTX-015 | Pending |
| NFR-012 | Compatibility | TC-025: SchemaRegistry breaking change | TASK-TRANSPORTX-023 | Pending |

---

## §4 CI Gate 追溯

| Gate | Covers | Evidence | Status |
| --- | --- | --- | --- |
| TX-GATE-001 | 23-section spec structure | `.github/ci/spec-lint.sh` | Pending |
| TX-GATE-002 | FR to AC/TC closure | `.github/ci/traceability-check.sh` | Pending |
| TX-GATE-003 | Foundation module count | `.github/ci/status-consistency-check.sh` | Pending |
| TX-GATE-004 | README/ARCHITECTURE/STATUS/module index drift | `.github/ci/spec-drift-guard.sh` | Pending |
| TX-GATE-005 | Envelope, Endpoint, Receipt conformance | conformance report | Pending |
| TX-GATE-006 | lifecycle, drain, force-stop conformance | conformance report | Pending |
| TX-GATE-007 | control-plane, authz, redaction-order conformance | conformance report | Pending |
| TX-GATE-008 | v1.x compatibility | schema compatibility report | Pending |
| TX-GATE-009 | release evidence | tag, changelog, conformance, drift | Pending |
| TX-GATE-010 | QoS, Codec, Registry conformance | conformance report | Pending |
| TX-GATE-011 | Execution Mode, Outbox/Inbox, Audit Plane conformance | conformance report | Pending |
| TX-GATE-012 | Data Classification, SchemaRegistry conformance | conformance report | Pending |

---

## §5 全局 AC 注册表

> transportx 的 AC 凭证嵌入于 §1 FR 表的 Acceptance Criteria 列（AC-001 ~ AC-026），与 FR 一体化定义。各 BR 对应的错误码亦在 §2 表中引用。

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| --- | --- | --- | --- |
| FR | 26 | 0 | 0% |
| BR | 18 | 0 | 0% |


| NFR | 12 | 0 | 0% |
| CI Gate | 12 | 0 | 0% |
| **合计** | **68** | **0** | **0%** |

> 说明：transportx 为 Foundation 传输契约模块（非 broker 实现），所有状态初始为 Pending。Task 总数 = TASK-TRANSPORTX-001~025 + 006b/006c 共 27 项。

---

## §7 变更历史

| 日期 | 变更内容 |
| --- | --- |
| 2026-06-29 | Goal 管线对齐：英文标题中文化（§1 功能需求/§2 业务规则/§3 非功能需求/§4 CI Gate）；FR 表简化（移除 Type/Source 列）；BR 表新增 BR ID 列 + Task 列；NFR 表新增 Task 列；Gate Traceability 重编号为 §4；新增 §6 覆盖率仪表盘；新增 §7 变更历史 |
| 2026-06-14 | 初始版本：Functional/Business Rule/NFR/Gate Traceability 四表结构 |

---

## Coverage Notes

- 26 FRs, 18 BRs (with error codes), 12 NFRs, 26 ACs (with verification commands), 25 TCs (with commands), 12 CI gates, 27 Tasks (TASK-TRANSPORTX-001~025, TASK-006b, TASK-006c).
- All FR -> AC -> TC chains closed. All BRs have explicit violation error codes. All FRs mapped to at least one Task.
- `transportx` is a Foundation transport-contract module, not a broker implementation.
- CI gates TX-GATE-001 through TX-GATE-004 are repository-documentation gates.
- CI gates TX-GATE-005 through TX-GATE-012 must be satisfied by the implementation repository before release.
