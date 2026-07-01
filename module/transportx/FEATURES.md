# transportx 完整实现清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-30
- Module-Version: v1.1.1-spec
- Module-State: 已发布
- Layer: L2.5 通信契约
- Runtime-Repo: /home/workspace/transportx
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于约束 transportx 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档；若运行时代码状态与本文不一致，以相应模块仓库的最新验证证据补充更新本文。

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | HTTP/gRPC/NATS 等传输抽象、拦截器、编码与错误映射契约 |
| 文档目录 | module/transportx |
| 运行时代码目录 | /home/workspace/transportx |
| Go 基线 | 1.23 |
| 允许依赖 | contracts, configx, observex, resiliencx |
| 禁止依赖 | 禁止越过 FOUNDATION-DEPS.yaml 登记边界依赖上层业务域或未授权基座模块 |
| 对外承诺 | API、配置、错误、观测、测试与证据口径必须与本目录追溯文档闭合 |

## 2. 功能实现清单（FR）

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
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

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
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

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-TRANSPORTX-001 | TASK-TRANSPORTX-001: Envelope Schema + Payload Limits | module/transportx/tasks/TASK-TRANSPORTX-001.md | - | tasks/TASK-TRANSPORTX-001.md |
| TASK-TRANSPORTX-002 | TASK-TRANSPORTX-002: Endpoint Model + Registry | module/transportx/tasks/TASK-TRANSPORTX-002.md | - | tasks/TASK-TRANSPORTX-002.md |
| TASK-TRANSPORTX-003 | TASK-TRANSPORTX-003: ServiceIdentity | module/transportx/tasks/TASK-TRANSPORTX-003.md | - | tasks/TASK-TRANSPORTX-003.md |
| TASK-TRANSPORTX-004 | TASK-TRANSPORTX-004: Runtime Lifecycle + Drain | module/transportx/tasks/TASK-TRANSPORTX-004.md | - | tasks/TASK-TRANSPORTX-004.md |
| TASK-TRANSPORTX-005 | TASK-TRANSPORTX-005: DeliveryReceipt | module/transportx/tasks/TASK-TRANSPORTX-005.md | - | tasks/TASK-TRANSPORTX-005.md |
| TASK-TRANSPORTX-006 | TASK-TRANSPORTX-006: Error Taxonomy — Transport + Idempotency | module/transportx/tasks/TASK-TRANSPORTX-006.md | - | tasks/TASK-TRANSPORTX-006.md |
| TASK-TRANSPORTX-006B | TASK-TRANSPORTX-006b: Error Taxonomy — Auth + Deadline + Retry | module/transportx/tasks/TASK-TRANSPORTX-006b.md | - | tasks/TASK-TRANSPORTX-006b.md |
| TASK-TRANSPORTX-006C | TASK-TRANSPORTX-006c: Error Taxonomy — QoS + Mode | module/transportx/tasks/TASK-TRANSPORTX-006c.md | - | tasks/TASK-TRANSPORTX-006c.md |
| TASK-TRANSPORTX-007 | TASK-TRANSPORTX-007: QoS Classification | module/transportx/tasks/TASK-TRANSPORTX-007.md | - | tasks/TASK-TRANSPORTX-007.md |
| TASK-TRANSPORTX-008 | TASK-TRANSPORTX-008: Codec Interface + JSON Implementation | module/transportx/tasks/TASK-TRANSPORTX-008.md | - | tasks/TASK-TRANSPORTX-008.md |
| TASK-TRANSPORTX-009 | TASK-TRANSPORTX-009: TopicRegistry | module/transportx/tasks/TASK-TRANSPORTX-009.md | - | tasks/TASK-TRANSPORTX-009.md |
| TASK-TRANSPORTX-010 | TASK-TRANSPORTX-010: MethodRegistry | module/transportx/tasks/TASK-TRANSPORTX-010.md | - | tasks/TASK-TRANSPORTX-010.md |
| TASK-TRANSPORTX-011 | TASK-TRANSPORTX-011: SchemaRegistry | module/transportx/tasks/TASK-TRANSPORTX-011.md | - | tasks/TASK-TRANSPORTX-011.md |
| TASK-TRANSPORTX-012 | TASK-TRANSPORTX-012: Middleware Chain + Redaction Order | module/transportx/tasks/TASK-TRANSPORTX-012.md | - | tasks/TASK-TRANSPORTX-012.md |
| TASK-TRANSPORTX-013 | TASK-TRANSPORTX-013: Control Plane | module/transportx/tasks/TASK-TRANSPORTX-013.md | - | tasks/TASK-TRANSPORTX-013.md |
| TASK-TRANSPORTX-014 | TASK-TRANSPORTX-014: Backpressure + Bulkhead | module/transportx/tasks/TASK-TRANSPORTX-014.md | - | tasks/TASK-TRANSPORTX-014.md |
| TASK-TRANSPORTX-015 | TASK-TRANSPORTX-015: Retry + Dead Letter | module/transportx/tasks/TASK-TRANSPORTX-015.md | - | tasks/TASK-TRANSPORTX-015.md |
| TASK-TRANSPORTX-016 | TASK-TRANSPORTX-016: Authorization Middleware | module/transportx/tasks/TASK-TRANSPORTX-016.md | - | tasks/TASK-TRANSPORTX-016.md |
| TASK-TRANSPORTX-017 | TASK-TRANSPORTX-017: Deadline + Clock Skew | module/transportx/tasks/TASK-TRANSPORTX-017.md | - | tasks/TASK-TRANSPORTX-017.md |
| TASK-TRANSPORTX-018 | TASK-TRANSPORTX-018: Idempotency | module/transportx/tasks/TASK-TRANSPORTX-018.md | - | tasks/TASK-TRANSPORTX-018.md |
| TASK-TRANSPORTX-019 | TASK-TRANSPORTX-019: Execution Modes | module/transportx/tasks/TASK-TRANSPORTX-019.md | - | tasks/TASK-TRANSPORTX-019.md |
| TASK-TRANSPORTX-020 | TASK-TRANSPORTX-020: Outbox/Inbox SPI | module/transportx/tasks/TASK-TRANSPORTX-020.md | - | tasks/TASK-TRANSPORTX-020.md |
| TASK-TRANSPORTX-021 | TASK-TRANSPORTX-021: Audit Plane | module/transportx/tasks/TASK-TRANSPORTX-021.md | - | tasks/TASK-TRANSPORTX-021.md |
| TASK-TRANSPORTX-022 | TASK-TRANSPORTX-022: Data Classification + Redaction | module/transportx/tasks/TASK-TRANSPORTX-022.md | - | tasks/TASK-TRANSPORTX-022.md |
| TASK-TRANSPORTX-023 | TASK-TRANSPORTX-023: Schema Compatibility | module/transportx/tasks/TASK-TRANSPORTX-023.md | - | tasks/TASK-TRANSPORTX-023.md |
| TASK-TRANSPORTX-024 | TASK-TRANSPORTX-024: Conformance Suite | module/transportx/tasks/TASK-TRANSPORTX-024.md | - | tasks/TASK-TRANSPORTX-024.md |
| TASK-TRANSPORTX-025 | TASK-TRANSPORTX-025: CI Gates + Release Evidence | module/transportx/tasks/TASK-TRANSPORTX-025.md | - | tasks/TASK-TRANSPORTX-025.md |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| goal.md | 存在 | module/transportx/goal.md |
| SPEC.md | 存在 | module/transportx/SPEC.md |
| TRACEABILITY.md | 存在 | module/transportx/TRACEABILITY.md |
| IMPLEMENTATION-PLAN.md | 存在 | module/transportx/IMPLEMENTATION-PLAN.md |
| tasks/ | 27 个 Markdown 文件 | module/transportx/tasks |

## 6. 实现完成判定

- [ ] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖。
- [ ] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖。
- [ ] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC。
- [ ] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖。
- [ ] 运行时代码仓库 /home/workspace/transportx 的 lint、typecheck、test、race、coverage 验证证据已归档。
- [ ] 发布说明、版本标签与本目录登记状态一致。
