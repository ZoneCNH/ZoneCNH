# natsx 完整实现清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-30
- Module-Version: v1.2.0
- Module-State: Tag Exists / GitHub Release Pending
- Layer: L2 基础设施适配器
- Runtime-Repo: /home/workspace/natsx
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于约束 natsx 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档；若运行时代码状态与本文不一致，以相应模块仓库的最新验证证据补充更新本文。
>
> [COMPUTED, HIGH] 2026-06-23 核查：origin refs/tags/v1.0.3 存在且 PR #17 已合并，但 `gh release view v1.0.3 --repo ZoneCNH/natsx` 返回 `release not found`；本清单不得作为 GitHub Release 完成证明。

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | NATS core/JetStream、KV、Object、request-reply 与健康检查适配 |
| 文档目录 | module/natsx |
| 运行时代码目录 | /home/workspace/natsx |
| Go 基线 | 1.23 |
| 允许依赖 | kernel |
| 禁止依赖 | 禁止越过 FOUNDATION-DEPS.yaml 登记边界依赖上层业务域或未授权基座模块 |
| 对外承诺 | API、配置、错误、观测、测试与证据口径必须与本目录追溯文档闭合 |

## 2. 功能实现清单（FR）

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | Publish（Core NATS） | 发布成功、连接错误、空 subject 错误均有测试 / TC-001 / TASK-NATSX-001 | ✅ | TRACEABILITY.md |
| FR-002 | Subscribe（Core NATS） | subscribe/handler/unsubscribe/drain 均有测试 / TC-001 / TASK-NATSX-001 | ✅ | TRACEABILITY.md |
| FR-003 | Request（Core NATS） | responder、timeout、ctx cancel 均有测试 / TC-002 / TASK-NATSX-002 | ✅ | TRACEABILITY.md |
| FR-004 | JetStream.Publish | stream 存在/缺失场景均有测试 / TC-003 / TASK-NATSX-003 | ✅ | TRACEABILITY.md |
| FR-005 | JetStream.Subscribe | ack、redelivery、dead-letter 行为均有测试 / TC-003 / TASK-NATSX-003 | ✅ | TRACEABILITY.md |
| FR-006 | JetStream.AddStream | 创建、幂等、冲突配置均有测试 / TC-003 / TASK-NATSX-004 | ✅ | TRACEABILITY.md |
| FR-007 | JetStream.AddConsumer | 创建、幂等、冲突配置均有测试 / TC-003 / TASK-NATSX-004 | ✅ | TRACEABILITY.md |
| FR-008 | Health | ready/live/message 与连接状态映射有测试 / TC-005 / TASK-NATSX-005 | ✅ | TRACEABILITY.md |
| FR-009 | JetStream IngestPublisher Adapter | IngestAck{Durable}/retryable reject/duplicate 幂等 / TC-010 / TASK-NATSX-010 | ✅ PR #17 merged; GitHub Release pending | TRACEABILITY.md |
| FR-010 | JetStream IngestConsumer Adapter | Fetch+ManualAck/重投递/DLQ/poison message / TC-015 / TASK-NATSX-010 | ✅ PR #17 merged; GitHub Release pending | TRACEABILITY.md |

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| BR-001 | Core NATS at-most-once | 不承诺持久化，低延迟发布订阅场景有说明和测试 / TC-001 / TASK-NATSX-001 | ✅ | TRACEABILITY.md |
| BR-002 | JetStream at-least-once | ack/nack/redelivery 语义有测试 / TC-003 / TASK-NATSX-003 | ✅ | TRACEABILITY.md |
| BR-003 | Context boundary | 所有网络操作接受 context 并尊重取消/超时 / TC-002 / TASK-NATSX-002 | ✅ | TRACEABILITY.md |
| BR-004 | Handler latency | 订阅 handler 快速返回/异步化约束有测试或示例 / TC-001 / TASK-NATSX-001 | ✅ | TRACEABILITY.md |
| BR-005 | 自动重连指数退避 | 断线重连、max-attempts、状态事件有测试 / TC-004 / TASK-NATSX-004 | ✅ | TRACEABILITY.md |
| BR-006 | Health 幂等无副作用 | 多次 Health() 调用无副作用，健康状态一致 / TC-005 / TASK-NATSX-005 | ✅ | TRACEABILITY.md |
| BR-007 | JetStream 启动时创建 | stream/consumer 在启动时创建，运行时创建失败返回预期错误 / TC-003 / TASK-NATSX-004 | ✅ | TRACEABILITY.md |
| BR-008 | 错误不含消息内容 | 错误/日志不包含 payload 内容，防止敏感数据泄露 / TC-011 / TASK-NATSX-011 | ✅ | TRACEABILITY.md |
| BR-009 | Subscription 资源释放 | Close/Drain 时正确释放资源，无泄漏 / TC-001 / TASK-NATSX-001 | ✅ | TRACEABILITY.md |
| NFR-001 | Security redaction | credentials/token/连接串敏感片段脱敏 / TC-011 / TASK-NATSX-011 | ✅ Config/env sanitize and live-test output without secret values covered | TRACEABILITY.md |
| NFR-002 | TLS/auth | TLS 与认证配置可表达且不泄漏凭据 / TC-011 / TASK-NATSX-011 | ✅ Config expression/sanitize, canonical auth env vars, and local auth live test with redacted credentials covered; production TLS closure packet remains external release blocker BLK-002 | TRACEABILITY.md |
| NFR-003 | Performance budget | publish/request/JetStream 延迟预算有 benchmark / TC-012 / TASK-NATSX-012 | ✅ Publish/request/JetStream benchmarks plus embedded request/publish/fetch SLO assertions and handler latency metric covered | TRACEABILITY.md |
| NFR-004 | Layer boundary | 不依赖 kafkax，不替代 RPC/治理框架 / TC-013 / TASK-NATSX-013 | ✅ Dependency boundary clean | TRACEABILITY.md |
| NFR-005 | Release evidence | SPEC、goal、traceability、matrix evidence 一致 / TC-014 / TASK-NATSX-014 | 🟡 Documentation and executable evidence reconciled for PR #17; GitHub Release v1.0.3 pending | TRACEABILITY.md |
| NFR-006 | SubjectBuilder | domain.resource.action.v{version} 构造和解析有测试 / TC-006 / TASK-NATSX-006 | ✅ Build/parse/validation tests | TRACEABILITY.md |
| NFR-007 | NatsMessageEnvelope | traceId/messageId/schemaVersion/header 双向映射有测试 / TC-007 / TASK-NATSX-007 | ✅ Header metadata round-trip and embedded propagation tests | TRACEABILITY.md |
| NFR-008 | Config contract | foundationx.nats.* 配置、默认值和旧别名兼容有测试 / TC-008 / TASK-NATSX-008 | ✅ Defaults/sanitize/validation plus canonical FOUNDATIONX_NATS_ over legacy NATS_ fallback covered | TRACEABILITY.md |
| NFR-009 | Observability contract | foundationx_nats_* 指标、错误脱敏和连接事件 guardrail 有测试 / TC-009 / TASK-NATSX-009 | ✅ Canonical foundationx_nats_* metrics and secret-safe error/live evidence covered | TRACEABILITY.md |

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-001 | Publish/Subscribe：subject 校验、handler 注册、连接错误处理 | client.go, subscription.go, msg.go, errors.go, client_test.go / 2h | - | IMPLEMENTATION-PLAN.md |
| TASK-002 | Request-Reply：responder、timeout、ctx cancel | client.go, client_test.go / 1h | - | IMPLEMENTATION-PLAN.md |
| TASK-003 | JetStream Publish/Subscribe：ack/redelivery/dead-letter | jetstream.go, errors.go, jetstream_test.go / 2h | - | IMPLEMENTATION-PLAN.md |
| TASK-004 | AddStream/AddConsumer：创建、幂等、冲突配置、reconnect | jetstream.go, options.go, internal/reconnect/backoff.go, jetstream_test.go / 2h | - | IMPLEMENTATION-PLAN.md |
| TASK-005 | Health 检查、GracefulShutdown、Drain | health.go, health_test.go / 1h | - | IMPLEMENTATION-PLAN.md |
| TASK-006 | SubjectBuilder：构造与解析 | subject.go, subject_test.go / 1h | - | IMPLEMENTATION-PLAN.md |
| TASK-007 | NatsMessageEnvelope：trace/message/schema header 双向映射 | msg.go, msg_test.go / 1h | - | IMPLEMENTATION-PLAN.md |
| TASK-008 | Config：foundationx.nats.* 加载、环境变量、旧别名兼容 | config.go, env.go, options.go, config_test.go / 2h | - | IMPLEMENTATION-PLAN.md |
| TASK-009 | Observability：foundationx_nats_* 指标、连接日志、错误脱敏 | natsx.go, metrics_test.go / 1h | - | IMPLEMENTATION-PLAN.md |
| TASK-011 | Security/TLS：凭证注入、TLS 配置、live integration | config.go, live_integration_test.go / 1h | - | IMPLEMENTATION-PLAN.md |
| TASK-012 | Performance：benchmark 基线 + SLO 断言 | benchmark_test.go / 1h | - | IMPLEMENTATION-PLAN.md |
| TASK-013 | Layer boundary：依赖边界检查 | go.mod / 0.5h | - | IMPLEMENTATION-PLAN.md |
| TASK-014 | Release：README、CHANGELOG、CI gate、覆盖率 | go.mod, README.md, CHANGELOG.md, example_test.go, integration_test.go / 2h | - | IMPLEMENTATION-PLAN.md |
| TASK-NATSX-001 | FR-001, FR-002, BR-001, BR-004, BR-009 | - | Complete publish/subscribe/request/queue baseline with unsubscribe, subscription Drain, handler latency, and client close evidence | TRACEABILITY.md |
| TASK-NATSX-001-PROMPT | TASK-NATSX-001 实现 Prompt | module/natsx/tasks/TASK-NATSX-001-PROMPT.md | - | tasks/TASK-NATSX-001-PROMPT.md |
| TASK-NATSX-002 | FR-003, BR-003 | - | Complete responder/no-responder/timeout/cancel coverage | TRACEABILITY.md |
| TASK-NATSX-002-PROMPT | TASK-NATSX-002 实现 Prompt | module/natsx/tasks/TASK-NATSX-002-PROMPT.md | - | tasks/TASK-NATSX-002-PROMPT.md |
| TASK-NATSX-003 | FR-004, FR-005, BR-002 | - | Complete JetStream publish/pull, missing-stream publish, nack redelivery, and max-deliveries advisory coverage | TRACEABILITY.md |
| TASK-NATSX-003-PROMPT | TASK-NATSX-003 实现 Prompt | module/natsx/tasks/TASK-NATSX-003-PROMPT.md | - | tasks/TASK-NATSX-003-PROMPT.md |
| TASK-NATSX-004 | FR-006, FR-007, BR-005, BR-007 | - | Complete AddStream/AddConsumer idempotency/conflict, startup creation enforcement, management edge failures, reconnect/degraded health, retry/backoff knobs, connection-state metrics, and reconnect/disconnect guardrail evidence; production SLO gate remains separate | TRACEABILITY.md |
| TASK-NATSX-004-PROMPT | TASK-NATSX-004 实现 Prompt | module/natsx/tasks/TASK-NATSX-004-PROMPT.md | - | tasks/TASK-NATSX-004-PROMPT.md |
| TASK-NATSX-005 | FR-008, BR-006 | - | Complete health healthy/closed/failure/reconnect/degraded coverage | TRACEABILITY.md |
| TASK-NATSX-005-PROMPT | TASK-NATSX-005 实现 Prompt | module/natsx/tasks/TASK-NATSX-005-PROMPT.md | - | tasks/TASK-NATSX-005-PROMPT.md |
| TASK-NATSX-006 | NFR-006 | - | Complete SubjectBuilder Build/Parse/Validate coverage; canonical token rejection tests; SPEC §9.1 interface alignment | TRACEABILITY.md |
| TASK-NATSX-006-PROMPT | TASK-NATSX-006 实现 Prompt | module/natsx/tasks/TASK-NATSX-006-PROMPT.md | - | tasks/TASK-NATSX-006-PROMPT.md |
| TASK-NATSX-007 | NFR-007 | - | Complete envelope/header metadata round-trip coverage | TRACEABILITY.md |
| TASK-NATSX-007-PROMPT | TASK-NATSX-007 实现 Prompt | module/natsx/tasks/TASK-NATSX-007-PROMPT.md | - | tasks/TASK-NATSX-007-PROMPT.md |
| TASK-NATSX-008 | NFR-008 | - | Complete config default/sanitize/validation plus canonical/legacy env alias precedence coverage | TRACEABILITY.md |
| TASK-NATSX-008-PROMPT | TASK-NATSX-008 实现 Prompt | module/natsx/tasks/TASK-NATSX-008-PROMPT.md | - | tasks/TASK-NATSX-008-PROMPT.md |
| TASK-NATSX-009 | NFR-009 | - | Complete repair-slice canonical metrics and secret-safe error/log evidence; distributed tracing is not claimed by this matrix | TRACEABILITY.md |
| TASK-NATSX-009-PROMPT | TASK-NATSX-009 实现 Prompt | module/natsx/tasks/TASK-NATSX-009-PROMPT.md | - | tasks/TASK-NATSX-009-PROMPT.md |
| TASK-NATSX-010 | FR-009, FR-010 | - | ✅ PR #17 merged; GitHub Release pending | TRACEABILITY.md |
| TASK-NATSX-011 | NFR-001, NFR-002, BR-008 | - | Complete repair-slice sanitize/config evidence plus local auth live integration passed with redacted local config; production TLS closure packet remains separate release blocker BLK-002 in release/trust/foundation-maturity-evidence-matrix-20260615.md | TRACEABILITY.md |
| TASK-NATSX-011-PROMPT | TASK-NATSX-011 实现 Prompt | module/natsx/tasks/TASK-NATSX-011-PROMPT.md | - | tasks/TASK-NATSX-011-PROMPT.md |
| TASK-NATSX-012 | NFR-003 | - | Complete repair-slice SLO assertions for embedded request, JetStream publish/fetch, and handler latency; production benchmark gate still separate | TRACEABILITY.md |
| TASK-NATSX-012-PROMPT | TASK-NATSX-012 实现 Prompt | module/natsx/tasks/TASK-NATSX-012-PROMPT.md | - | tasks/TASK-NATSX-012-PROMPT.md |
| TASK-NATSX-013 | NFR-004 | Dependency boundary check passed for forbidden ZoneCNH messaging/storage modules | - | TRACEABILITY.md |
| TASK-NATSX-013-PROMPT | TASK-NATSX-013 实现 Prompt | module/natsx/tasks/TASK-NATSX-013-PROMPT.md | - | tasks/TASK-NATSX-013-PROMPT.md |
| TASK-NATSX-014 | NFR-005 | Release evidence + CI gate: README.md quickstart/API overview, CHANGELOG.md v1.0.0, CI gate (build/test/vet/lint/secret scan), coverage >=80%, benchmark regression guard; PR #17 merge and remote tag v1.0.3 observed; GitHub Release v1.0.3 pending | - | TRACEABILITY.md |
| TASK-NATSX-014-PROMPT | TASK-NATSX-014 实现 Prompt | module/natsx/tasks/TASK-NATSX-014-PROMPT.md | - | tasks/TASK-NATSX-014-PROMPT.md |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| goal.md | 存在 | module/natsx/goal.md |
| SPEC.md | 存在 | module/natsx/SPEC.md |
| TRACEABILITY.md | 存在 | module/natsx/TRACEABILITY.md |
| IMPLEMENTATION-PLAN.md | 存在 | module/natsx/IMPLEMENTATION-PLAN.md |
| tasks/ | 26 个 Markdown 文件 | module/natsx/tasks |

## 6. 实现完成判定

- [ ] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖。
- [ ] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖。
- [ ] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC。
- [ ] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖。
- [ ] 运行时代码仓库 /home/workspace/natsx 的 lint、typecheck、test、race、coverage 验证证据已归档。
- [ ] 发布说明、版本标签与本目录登记状态一致；当前已确认 `v1.0.3` 远端 tag，GitHub Release `v1.0.3` 待补。
