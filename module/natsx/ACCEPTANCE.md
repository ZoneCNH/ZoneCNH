# natsx 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-30
- Module-Version: v1.2.0
- Module-State: Tag Exists / GitHub Release Pending
- Layer: L2 基础设施适配器
- Runtime-Repo: /home/natsx
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于验收 natsx 是否达到可发布、可追溯、可复验状态。除非条目明确记录为已通过，默认需要在运行时代码仓库重新执行验证并补充证据。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/ZoneCNH && test -f module/natsx/FEATURES.md && test -f module/natsx/ACCEPTANCE.md | FEATURES.md 与 ACCEPTANCE.md 均存在 |
| 文档格式 | cd /home/ZoneCNH && git diff --check -- module/natsx | 无尾随空格或补丁格式错误 |
| 运行时测试 | cd /home/natsx && go test ./... | 所有包测试通过 |
| 竞态检查 | cd /home/natsx && go test ./... -race -count=1 | 无 data race，测试稳定通过 |
| 静态检查 | cd /home/natsx && go vet ./... | 无 vet 问题 |
| 覆盖率证据 | cd /home/natsx && go test ./... -coverprofile=coverage.out | 覆盖率文件生成并满足模块 Spec 门槛 |
| 依赖边界 | cd /home/natsx && go list -deps ./... | 依赖不越过 FOUNDATION-DEPS.yaml 登记边界 |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-001 | FR-001 | TC-001 / Embedded broker publish plus invalid-precondition coverage | - | TRACEABILITY.md |
| AC-002 | FR-002 | TC-001 / Embedded broker subscribe/queue/unsubscribe, subscription Drain, and client close evidence | - | TRACEABILITY.md |
| AC-003 | FR-003 | TC-002 / Embedded responder, no-responder, timeout, and cancel coverage | - | TRACEABILITY.md |
| AC-004 | FR-004 | TC-003 / Embedded JetStream publish/pull plus missing-stream publish coverage | - | TRACEABILITY.md |
| AC-005 | FR-005 | TC-003 / Pull, ack, nack redelivery, and max-deliveries advisory coverage | - | TRACEABILITY.md |
| AC-006 | FR-006 | TC-003 / Embedded AddStream create/idempotency/conflict covered | - | TRACEABILITY.md |
| AC-007 | FR-007 | TC-003 / Embedded AddConsumer create/idempotency/conflict covered | - | TRACEABILITY.md |
| AC-008 | FR-008 | TC-005 / Healthy, disconnected, nil, canceled, closed, reconnect, and degraded health paths covered | - | TRACEABILITY.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-001, FR-002, BR-001, BR-004, BR-009 | /home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSCorePublishRequestAndQueue; /home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSCoreTimeoutUnsubscribeDrainAndHealth; /home/natsx/pkg/natsx/regression_test.go::TestCoreOperationsRejectInvalidPreconditions | - | TRACEABILITY.md |
| TC-002 | FR-003, BR-003 | /home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSCorePublishRequestAndQueue; /home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSRequestNoResponder; /home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSCoreTimeoutUnsubscribeDrainAndHealth | - | TRACEABILITY.md |
| TC-003 | FR-004, FR-005, FR-006, FR-007, BR-002, BR-007 | /home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSJetStreamPublishAndPull; /home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSJetStreamMaxDeliverAdvisory; covers JetStream publish/pull, missing-stream publish, AddStream/AddConsumer idempotency/conflict, management edge failures, nack redelivery, and max-deliveries advisory behavior | - | TRACEABILITY.md |
| TC-004 | BR-005 | /home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSReconnectBackoffAndDegradedHealth; reconnect/degraded health, retry/backoff knobs, connection-state metrics, and reconnect/disconnect guardrails covered; production exponential-backoff SLO gate remains external | - | TRACEABILITY.md |
| TC-005 | FR-008, BR-006 | /home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSCoreTimeoutUnsubscribeDrainAndHealth; /home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSReconnectBackoffAndDegradedHealth; /home/natsx/pkg/natsx/health_test.go::TestHealthCheckDisconnectedRecordsMetrics; /home/natsx/pkg/natsx/regression_test.go::TestHealthCheckNilAndCanceledContext | - | TRACEABILITY.md |
| TC-006 | NFR-006 | /home/natsx/pkg/natsx/subject_test.go | - | TRACEABILITY.md |
| TC-007 | NFR-007 | /home/natsx/pkg/natsx/envelope_test.go; embedded request/reply metadata propagation in /home/natsx/pkg/natsx/embedded_nats_test.go | - | TRACEABILITY.md |
| TC-008 | NFR-008 | /home/natsx/pkg/natsx/config_test.go and /home/natsx/pkg/natsx/env_test.go cover defaults/sanitize/validation plus ConfigFromEnv canonical precedence and legacy fallback | - | TRACEABILITY.md |
| TC-009 | NFR-009 | /home/natsx/pkg/natsx/regression_test.go::TestMetricNamesUseFoundationNATSPrefix; TestNoopMetricsMethodsAreSafe; /home/natsx/pkg/natsx/health_test.go::TestHealthCheckDisconnectedRecordsMetrics; embedded tests assert canonical foundationx_nats_* metric emission | - | TRACEABILITY.md |
| TC-011 | NFR-001, NFR-002, BR-008 | /home/natsx/pkg/natsx/config_test.go::TestConfigValidateDefaultsAndSanitize; /home/natsx/pkg/natsx/env_test.go::TestConfigFromEnvRejectsInvalidValuesWithoutSecretLeak; /home/natsx/pkg/natsx/live_integration_test.go; local auth live test passed with FOUNDATIONX_NATS_URL, FOUNDATIONX_NATS_USERNAME, and FOUNDATIONX_NATS_PASSWORD sourced from local NATS config without printing credentials | - | TRACEABILITY.md |
| TC-012 | NFR-003 | /home/natsx/pkg/natsx/benchmark_test.go::BenchmarkEmbeddedNATSPublish; /home/natsx/pkg/natsx/benchmark_test.go::BenchmarkEmbeddedNATSRequest; /home/natsx/pkg/natsx/benchmark_test.go::BenchmarkEmbeddedNATSJetStreamPublish; /home/natsx/pkg/natsx/embedded_nats_test.go adds request, JetStream publish/fetch SLO assertions and handler latency evidence | - | TRACEABILITY.md |
| TC-013 | NFR-004 | /home/natsx$ GOWORK=off go list -deps ./pkg/natsx ./examples/... plus forbidden-domain filter returned dependency boundary clean | - | TRACEABILITY.md |
| TC-014 | NFR-005 | /home/natsx commit 20f801f; this matrix refresh; formal four-source arbiter still pending | - | TRACEABILITY.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | Publish（Core NATS） | 发布成功、连接错误、空 subject 错误均有测试 / TC-001 / TASK-NATSX-001 | ✅ | TRACEABILITY.md |
| FR-002 | Subscribe（Core NATS） | subscribe/handler/unsubscribe/drain 均有测试 / TC-001 / TASK-NATSX-001 | ✅ | TRACEABILITY.md |
| FR-003 | Request（Core NATS） | responder、timeout、ctx cancel 均有测试 / TC-002 / TASK-NATSX-002 | ✅ | TRACEABILITY.md |
| FR-004 | JetStream.Publish | stream 存在/缺失场景均有测试 / TC-003 / TASK-NATSX-003 | ✅ | TRACEABILITY.md |
| FR-005 | JetStream.Subscribe | ack、redelivery、dead-letter 行为均有测试 / TC-003 / TASK-NATSX-003 | ✅ | TRACEABILITY.md |
| FR-006 | JetStream.AddStream | 创建、幂等、冲突配置均有测试 / TC-003 / TASK-NATSX-004 | ✅ | TRACEABILITY.md |
| FR-007 | JetStream.AddConsumer | 创建、幂等、冲突配置均有测试 / TC-003 / TASK-NATSX-004 | ✅ | TRACEABILITY.md |
| FR-008 | Health | ready/live/message 与连接状态映射有测试 / TC-005 / TASK-NATSX-005 | ✅ | TRACEABILITY.md |
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
| NFR-005 | Release evidence | SPEC、goal、traceability、matrix evidence 一致 / TC-014 / TASK-NATSX-014 | ✅ Documentation and executable evidence reconciled | TRACEABILITY.md |
| NFR-006 | SubjectBuilder | domain.resource.action.v{version} 构造和解析有测试 / TC-006 / TASK-NATSX-006 | ✅ Build/parse/validation tests | TRACEABILITY.md |
| NFR-007 | NatsMessageEnvelope | traceId/messageId/schemaVersion/header 双向映射有测试 / TC-007 / TASK-NATSX-007 | ✅ Header metadata round-trip and embedded propagation tests | TRACEABILITY.md |
| NFR-008 | Config contract | foundationx.nats.* 配置、默认值和旧别名兼容有测试 / TC-008 / TASK-NATSX-008 | ✅ Defaults/sanitize/validation plus canonical FOUNDATIONX_NATS_ over legacy NATS_ fallback covered | TRACEABILITY.md |
| NFR-009 | Observability contract | foundationx_nats_* 指标、错误脱敏和连接事件 guardrail 有测试 / TC-009 / TASK-NATSX-009 | ✅ Canonical foundationx_nats_* metrics and secret-safe error/live evidence covered | TRACEABILITY.md |

## 5. 发布 DoD 清单

- [ ] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。
- [ ] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。
- [ ] 运行时代码仓库 /home/natsx 通过 go test、go test -race、go vet 与覆盖率门槛。
- [ ] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据。
- [ ] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [ ] 版本号、发布标签、CHANGELOG 或 release note 与本目录状态一致，且当前目标发布版本为 `v0.4.7`。

## 6. 当前缺口登记

- 当前文档只记录验收口径，不替代运行时代码仓库的最新 CI 结果。
- 若上表存在 Pending、Draft、Blocked、Open 或未登记状态，发布前必须补充证据或在模块追溯矩阵中登记豁免理由。
- SPEC/TRACEABILITY 已登记 AC/TC 主链路；当前主要缺口是四源 98+ 仲裁、生产 benchmark 阈值、BLK-002 生产 TLS 闭环与上层 consumer lifecycle/API 集成证据需要归档。

## 7. v1.0.3 验收实测证据（/home/natsx PR #13 / tag v1.0.3）

> 2026-06-19 在 /home/natsx 分支 `test/natsx-coverage-100-20260619`（commit b5adee9）实测。pkg/natsx 包级覆盖率 90.0%（v1.0.2）→ **97.1%**。

| 命令 | 实测结果 |
| --- | --- |
| `GOWORK=off go build ./...` | ✅ rc=0 |
| `GOWORK=off go vet ./...` | ✅ clean |
| `GOWORK=off go test ./... -race -count=1` | ✅ 全 ok，无竞态 |
| pkg/natsx 包级覆盖率（`go tool cover -func` total） | ✅ **97.1%** ≥ 80% DoD（v1.0.1=73.3% → v1.0.2=90.0% → v1.0.3=97.1%） |
| 测试新增 | coverage_phase2/3/4_test.go：Wrap options 循环、Publish 的 PublishMsg 错误路径（MaxPayload 受限内嵌服务器）、core/client/jetstream/config/env/subject 防御与错误分支 |
| 生产代码（行为等价） | 移除 `Config.Validate` 永不可达的 `if len(endpoints)==0` 死分支（`withDefaults()` 已保证 URL 非空，`endpoints()` 恒返回 ≥1 端点）；覆盖率 97.0% → 97.1% |

### 7.1 覆盖率 100% 不可达登记（剩余 ~20 条语句）

经源码级分析为**确定性不可达**（不动生产代码、不写 flaky 测试）：

- **client.go L77-82 / L115-117**：依赖 `conn.JetStream()` 报错；本 nats.go 版本在非-JS 内嵌服务器上**不报错**（unavailable 检查发生在 API 调用时）——实测确认。
- **client.go L136-138**：`Drain()` 返回 `ErrConnectionClosed` 仅当 status==CLOSED，但 L132 `IsClosed()` 已先行拦截；单线程确定性不可达。
- **core.go L27-31 / L52-56**：`FlushWithContext`/Request 内部 deadline 与 `ready()` 同源 ctx；L130 `ctx.Err()` 先捕获，L52-56 仅在 race 窗口可达。
- **jetstream.go L44-46**：服务器对 same-config 执行静默 update（走 L38-40），conflict 配置必然 mismatch（走 L47），故 L45 match 分支不可达。
- **jetstream.go L105-114**：AddConsumer 后置 `ErrConsumerNameAlreadyInUse` 是 pre-check（L90 ConsumerInfo）与 `j.js.AddConsumer`（L101）之间的 TOCTOU 防御，单客户端确定性不可达。

100% 字面覆盖率需写 flaky race 测试（违反本仓"避免 flaky timeout 断言"规则）或删改生产防御代码（改变行为契约），二者均不可取，故以 **97.1% race-clean** 收尾。

## 7. v1.0.2 验收实测证据（/home/natsx commit 20f801f）

> 2026-06-19 在 /home/natsx（main @ 20f801f）实测全部 §1 验收命令，结果如下。CI/CD 已路由至 `sre/*` 机器池（CI: sre/storage-light；CD: sre/deploy）。

| 命令 | 实测结果 |
| --- | --- |
| 文档存在性（FEATURES.md + ACCEPTANCE.md） | ✅ 存在 |
| `git diff --check -- module/natsx` | ✅ 无格式错误 |
| `GOWORK=off go build ./pkg/natsx` | ✅ rc=0 |
| `GOWORK=off go vet ./...` | ✅ clean |
| `GOWORK=off go test ./...` | ✅ 全 ok |
| `GOWORK=off go test ./... -race -count=1` | ✅ 全 ok，无竞态 |
| 总覆盖率（`go test ./... -coverprofile`） | ✅ **84.2%** ≥ 80% gate |
| pkg/natsx 包级覆盖率（`go test ./pkg/natsx -cover`） | ✅ **90.0%** ≥ 80% DoD（v1.0.1 时为 73.3%，v1.0.2 补 streamConfigMatches 完整表驱动 + 错误路径后达标） |
| 依赖边界（`go list -deps` 禁止域过滤） | ✅ clean，无 kafkax / 上层域依赖 |
| CI/CD 机器池 | ✅ 6 个 workflow 全部 `sre/*`（commit 66656aa） |

- v1.0.1 变更：CICD SRE 机器池路由（66656aa）+ pkg/natsx 覆盖率补强（14916d3，client/jetstream/errors 三组测试 +722 行），总覆盖率 79.2% → 80.4%。
- v1.0.2 变更：pkg/natsx 包级覆盖率补强（coverage_phase2_test.go，+794 行），streamConfigMatches 7.2% → 100%、WithNATSOptions 0% → 100% 及 core/client/envelope/config/env/jetstream 错误路径；**pkg/natsx 包级 73.3% → 90.0%，首次满足 SPEC §DoD 单元测试覆盖率 ≥80%**。
