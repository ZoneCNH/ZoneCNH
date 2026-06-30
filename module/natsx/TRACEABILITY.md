# natsx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。本矩阵记录 PR #17 merged + v1.0.3 remote tag evidence；GitHub Release v1.0.3 仍需独立发布证据，不得由 tag 推导。

Last-Updated: 2026-06-30
Source: `goal.md` v1.2.0 + `SPEC.md` Approved v1.2.0 + `/home/natsx` PR #17 merge `29503212` + remote tag `v1.0.3`

---

## §1 功能需求追溯（FR）

| Requirement | Description | Acceptance Criteria | TC ID(s) | Task | Status |
| ----------- | ----------- | ------------------- | -------- | ---- | ------ |
| FR-001 | Publish（Core NATS） | 发布成功、连接错误、空 subject 错误均有测试 | TC-001 | TASK-NATSX-001 | ✅ |
| FR-002 | Subscribe（Core NATS） | subscribe/handler/unsubscribe/drain 均有测试 | TC-001 | TASK-NATSX-001 | ✅ |
| FR-003 | Request（Core NATS） | responder、timeout、ctx cancel 均有测试 | TC-002 | TASK-NATSX-002 | ✅ |
| FR-004 | JetStream.Publish | stream 存在/缺失场景均有测试 | TC-003 | TASK-NATSX-003 | ✅ |
| FR-005 | JetStream.Subscribe | ack、redelivery、dead-letter 行为均有测试 | TC-003 | TASK-NATSX-003 | ✅ |
| FR-006 | JetStream.AddStream | 创建、幂等、冲突配置均有测试 | TC-003 | TASK-NATSX-004 | ✅ |
| FR-007 | JetStream.AddConsumer | 创建、幂等、冲突配置均有测试 | TC-003 | TASK-NATSX-004 | ✅ |
| FR-008 | Health | ready/live/message 与连接状态映射有测试 | TC-005 | TASK-NATSX-005 | ✅ |
| FR-009 | JetStream IngestPublisher Adapter | IngestAck{Durable}/JETSTREAM_PUBLISH_FAILED retryable/duplicate 幂等 | TC-010 | TASK-NATSX-010 | ✅ PR #17 merged; GitHub Release pending |
| FR-010 | JetStream IngestConsumer Adapter | Fetch+ManualAck/重投递/DLQ/poison message 不吞没 payload | TC-015 | TASK-NATSX-010 | ✅ PR #17 merged; GitHub Release pending |

---


| Requirement | Description | Acceptance Criteria | TC ID(s) | Task | Status |
| ----------- | ----------- | ------------------- | -------- | ---- | ------ |
| BR-001 | Core NATS at-most-once | 不承诺持久化，低延迟发布订阅场景有说明和测试 | TC-001 | TASK-NATSX-001 | ✅ |
| BR-002 | JetStream at-least-once | ack/nack/redelivery 语义有测试 | TC-003 | TASK-NATSX-003 | ✅ |
| BR-003 | Context boundary | 所有网络操作接受 context 并尊重取消/超时 | TC-002 | TASK-NATSX-002 | ✅ |
| BR-004 | Handler latency | 订阅 handler 快速返回/异步化约束有测试或示例 | TC-001 | TASK-NATSX-001 | ✅ |
| BR-005 | 自动重连指数退避 | 断线重连、max-attempts、状态事件有测试 | TC-004 | TASK-NATSX-004 | ✅ |
| BR-006 | Health 幂等无副作用 | 多次 Health() 调用无副作用，健康状态一致 | TC-005 | TASK-NATSX-005 | ✅ |
| BR-007 | JetStream 启动时创建 | stream/consumer 在启动时创建，运行时创建失败返回预期错误 | TC-003 | TASK-NATSX-004 | ✅ |
| BR-008 | 错误不含消息内容 | 错误/日志不包含 payload 内容，防止敏感数据泄露 | TC-011 | TASK-NATSX-011 | ✅ |
| BR-009 | Subscription 资源释放 | Close/Drain 时正确释放资源，无泄漏 | TC-001 | TASK-NATSX-001 | ✅ |

---

## §3 非功能需求追溯（NFR）

| Requirement | Description | Acceptance Criteria | TC ID(s) | Task | Status |
| ----------- | ----------- | ------------------- | -------- | ---- | ------ |
| NFR-001 | Security redaction | credentials/token/连接串敏感片段脱敏 | TC-011 | TASK-NATSX-011 | ✅ Config/env sanitize and live-test output without secret values covered |
| NFR-002 | TLS/auth | TLS 与认证配置可表达且不泄漏凭据 | TC-011 | TASK-NATSX-011 | ✅ Config expression/sanitize, canonical auth env vars, and local auth live test with redacted credentials covered; production TLS closure packet remains external release blocker `BLK-002` |
| NFR-003 | Performance budget | publish/request/JetStream 延迟预算有 benchmark | TC-012 | TASK-NATSX-012 | ✅ Publish/request/JetStream benchmarks plus embedded request/publish/fetch SLO assertions and handler latency metric covered |
| NFR-004 | Layer boundary | 不依赖 kafkax，不替代 RPC/治理框架 | TC-013 | TASK-NATSX-013 | ✅ Dependency boundary clean |
| NFR-005 | Release evidence | SPEC、goal、traceability、matrix evidence 一致 | TC-014 | TASK-NATSX-014 | 🟡 Documentation and executable evidence reconciled; GitHub Release v1.0.3 pending |
| NFR-006 | SubjectBuilder | `domain.resource.action.v{version}` 构造和解析有测试 | TC-006 | TASK-NATSX-006 | ✅ Build/parse/validation tests |
| NFR-007 | NatsMessageEnvelope | traceId/messageId/schemaVersion/header 双向映射有测试 | TC-007 | TASK-NATSX-007 | ✅ Header metadata round-trip and embedded propagation tests |
| NFR-008 | Config contract | `foundationx.nats.*` 配置、默认值和旧别名兼容有测试 | TC-008 | TASK-NATSX-008 | ✅ Defaults/sanitize/validation plus canonical `FOUNDATIONX_NATS_*` over legacy `NATS_*` fallback covered |
| NFR-009 | Observability contract | `foundationx_nats_*` 指标、错误脱敏和连接事件 guardrail 有测试 | TC-009 | TASK-NATSX-009 | ✅ Canonical `foundationx_nats_*` metrics and secret-safe error/live evidence covered |

---

## §4 TC→FR 反向追溯

| Test Case | Covers | Current Evidence |
| --------- | ------ | ---------------- |
| *TC-001 至 TC-005 在 SPEC.md §16.2 注册为正式 TC ID；TC-006 至 TC-014 为矩阵内部追溯标签，对应证据如右侧可执行文件路径所示，非 SPEC.md 注册的正式 TC ID。* | | |
| TC-001 | FR-001, FR-002, BR-001, BR-004, BR-009 | `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSCorePublishRequestAndQueue`; `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSCoreTimeoutUnsubscribeDrainAndHealth`; `/home/natsx/pkg/natsx/regression_test.go::TestCoreOperationsRejectInvalidPreconditions` |
| TC-002 | FR-003, BR-003 | `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSCorePublishRequestAndQueue`; `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSRequestNoResponder`; `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSCoreTimeoutUnsubscribeDrainAndHealth` |
| TC-003 | FR-004, FR-005, FR-006, FR-007, BR-002, BR-007 | `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSJetStreamPublishAndPull`; `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSJetStreamMaxDeliverAdvisory`; covers JetStream publish/pull, missing-stream publish, AddStream/AddConsumer idempotency/conflict, management edge failures, nack redelivery, and max-deliveries advisory behavior |
| TC-004 | BR-005 | `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSReconnectBackoffAndDegradedHealth`; reconnect/degraded health, retry/backoff knobs, connection-state metrics, and reconnect/disconnect guardrails covered; production exponential-backoff SLO gate remains external |
| TC-005 | FR-008, BR-006 | `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSCoreTimeoutUnsubscribeDrainAndHealth`; `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSReconnectBackoffAndDegradedHealth`; `/home/natsx/pkg/natsx/health_test.go::TestHealthCheckDisconnectedRecordsMetrics`; `/home/natsx/pkg/natsx/regression_test.go::TestHealthCheckNilAndCanceledContext` |
| TC-006 | NFR-006 | `/home/natsx/pkg/natsx/subject_test.go` |
| TC-007 | NFR-007 | `/home/natsx/pkg/natsx/envelope_test.go`; embedded request/reply metadata propagation in `/home/natsx/pkg/natsx/embedded_nats_test.go` |
| TC-008 | NFR-008 | `/home/natsx/pkg/natsx/config_test.go` and `/home/natsx/pkg/natsx/env_test.go` cover defaults/sanitize/validation plus `ConfigFromEnv` canonical precedence and legacy fallback |
| TC-009 | NFR-009 | `/home/natsx/pkg/natsx/regression_test.go::TestMetricNamesUseFoundationNATSPrefix`; `TestNoopMetricsMethodsAreSafe`; `/home/natsx/pkg/natsx/health_test.go::TestHealthCheckDisconnectedRecordsMetrics`; embedded tests assert canonical `foundationx_nats_*` metric emission |
| TC-010 | FR-009 | ✅ PR #17 merged — `/home/natsx` pkg/natsx/ingest covers IngestPublisher PubAck→Durable Ack, retryable reject, empty IdempotencyKey non-retryable, duplicate idempotency; GitHub Release v1.0.3 pending |
| TC-015 | FR-010 | ✅ PR #17 merged — `/home/natsx` pkg/natsx/ingest covers Fetch return (req, Ack, err), Ack offset advance, AckWait redelivery, MaxDeliver DLQ, poison message payload preservation; GitHub Release v1.0.3 pending |
| TC-011 | NFR-001, NFR-002, BR-008 | `/home/natsx/pkg/natsx/config_test.go::TestConfigValidateDefaultsAndSanitize`; `/home/natsx/pkg/natsx/env_test.go::TestConfigFromEnvRejectsInvalidValuesWithoutSecretLeak`; `/home/natsx/pkg/natsx/live_integration_test.go`; local auth live test passed with `FOUNDATIONX_NATS_URL`, `FOUNDATIONX_NATS_USERNAME`, and `FOUNDATIONX_NATS_PASSWORD` sourced from local NATS config without printing credentials |
| TC-012 | NFR-003 | `/home/natsx/pkg/natsx/benchmark_test.go::BenchmarkEmbeddedNATSPublish`; `/home/natsx/pkg/natsx/benchmark_test.go::BenchmarkEmbeddedNATSRequest`; `/home/natsx/pkg/natsx/benchmark_test.go::BenchmarkEmbeddedNATSJetStreamPublish`; `/home/natsx/pkg/natsx/embedded_nats_test.go` adds request, JetStream publish/fetch SLO assertions and handler latency evidence |
| TC-013 | NFR-004 | `/home/natsx$ GOWORK=off go list -deps ./pkg/natsx ./examples/...` plus forbidden-domain filter returned `dependency boundary clean` |
| TC-014 | NFR-005 | `/home/natsx` PR #17 merge `29503212`, remote tag `v1.0.3`; GitHub Release `v1.0.3` pending; formal four-source arbiter still pending |

---

## §5 全局 AC 注册表

| Acceptance Criterion | Requirement | Test Case | Current Evidence |
| -------------------- | ----------- | --------- | ---------------- |
| AC-001 | FR-001 | TC-001 | Embedded broker publish plus invalid-precondition coverage |
| AC-002 | FR-002 | TC-001 | Embedded broker subscribe/queue/unsubscribe, subscription Drain, and client close evidence |
| AC-003 | FR-003 | TC-002 | Embedded responder, no-responder, timeout, and cancel coverage |
| AC-004 | FR-004 | TC-003 | Embedded JetStream publish/pull plus missing-stream publish coverage |
| AC-005 | FR-005 | TC-003 | Pull, ack, nack redelivery, and max-deliveries advisory coverage |
| AC-006 | FR-006 | TC-003 | Embedded AddStream create/idempotency/conflict covered |
| AC-007 | FR-007 | TC-003 | Embedded AddConsumer create/idempotency/conflict covered |
| AC-008 | FR-008 | TC-005 | Healthy, disconnected, nil, canceled, closed, reconnect, and degraded health paths covered |
| AC-009 | FR-009 | TC-010 | ✅ PR #17 merged — IngestPublisher runtime adapter 已实现；GitHub Release v1.0.3 待补 |
| AC-010 | FR-010 | TC-015 | ✅ PR #17 merged — IngestConsumer runtime adapter 已实现；GitHub Release v1.0.3 待补 |

---

## Task Coverage

| Task | Requirement Coverage | Current Evidence |
| ---- | -------------------- | ---------------- |
| TASK-NATSX-001 | FR-001, FR-002, BR-001, BR-004, BR-009 | Complete publish/subscribe/request/queue baseline with unsubscribe, subscription Drain, handler latency, and client close evidence |
| TASK-NATSX-002 | FR-003, BR-003 | Complete responder/no-responder/timeout/cancel coverage |
| TASK-NATSX-003 | FR-004, FR-005, BR-002 | Complete JetStream publish/pull, missing-stream publish, nack redelivery, and max-deliveries advisory coverage |
| TASK-NATSX-004 | FR-006, FR-007, BR-005, BR-007 | Complete AddStream/AddConsumer idempotency/conflict, startup creation enforcement, management edge failures, reconnect/degraded health, retry/backoff knobs, connection-state metrics, and reconnect/disconnect guardrail evidence; production SLO gate remains separate |
| TASK-NATSX-005 | FR-008, BR-006 | Complete health healthy/closed/failure/reconnect/degraded coverage |
| TASK-NATSX-006 | NFR-006 | Complete SubjectBuilder Build/Parse/Validate coverage; canonical token rejection tests; SPEC §9.1 interface alignment |
| TASK-NATSX-007 | NFR-007 | Complete envelope/header metadata round-trip coverage |
| TASK-NATSX-008 | NFR-008 | Complete config default/sanitize/validation plus canonical/legacy env alias precedence coverage |
| TASK-NATSX-009 | NFR-009 | Complete repair-slice canonical metrics and secret-safe error/log evidence; distributed tracing is not claimed by this matrix |
| TASK-NATSX-010 | FR-009, FR-010 | ✅ PR #17 merged — implemented `IngestPublisher`（PubAck→Durable Ack/JetStream 幂等去重）与 `IngestConsumer`（durable+ManualAck/DLQ/poison message）域适配器；GitHub Release v1.0.3 pending |
| TASK-NATSX-011 | NFR-001, NFR-002, BR-008 | Complete repair-slice sanitize/config evidence plus local auth live integration passed with redacted local config; production TLS closure packet remains separate release blocker `BLK-002` in `release/trust/foundation-maturity-evidence-matrix-20260615.md` |
| TASK-NATSX-012 | NFR-003 | Complete repair-slice SLO assertions for embedded request, JetStream publish/fetch, and handler latency; production benchmark gate still separate |
| TASK-NATSX-013 | NFR-004 | Dependency boundary check passed for forbidden ZoneCNH messaging/storage modules |
| TASK-NATSX-014 | NFR-005 | Release evidence + CI gate: `README.md` quickstart/API overview, `CHANGELOG.md` v1.0.0, CI gate (build/test/vet/lint/secret scan), coverage >=80%, benchmark regression guard; PR #17 merge and remote tag v1.0.3 observed; GitHub Release v1.0.3 pending |

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| ------ | ------ | --- | ------ |
| FR | 10 | 10 | 100% |
| BR | 9 | 9 | 100% |


| NFR | 9 | 8 | 88.9% |
| AC | 10 | 10 | 100% |
| TC | 15 | 15 | 100% |

> 说明：NFR-005 标记为 🟡（Documentation and executable evidence reconciled; GitHub Release v1.0.3 pending），未计入 Done。FR-009/FR-010 的 Status 列标记 ✅（PR #17 merged），计入 Done。覆盖率 = Done / 总数。

---

## §7 变更历史

| 日期 | 变更内容 | 作者 |
| ---------- | -------- | ---- |
| 2026-06-29 | Goal 管线对齐：Forward Coverage 拆分为 §1 FR/§2 BR/§3 NFR 独立表，统一 TC ID(s) 列名，Task 列置于 TC ID(s) 与 Status 之间；§4 TC→FR 反向追溯与 §5 全局 AC 注册表章节重编号；新增 §6 覆盖率仪表盘；新增 §7 变更历史 | ZoneCNH |
| 2026-06-23 | 初始版本：PR #17 merge + v1.0.3 remote tag evidence；Forward Coverage 含 FR/BR/NFR 混排表、AC 关联表、Reverse Coverage、Task Coverage、Documentation Evidence Inventory、Matrix Score Evidence | ZoneCNH |

---

## Documentation Evidence Inventory

| Artifact | Evidence state | Release meaning |
| --- | --- | --- |
| `/home/natsx/README.md` | Identifies `github.com/ZoneCNH/natsx/pkg/natsx` as the 1.0 target and legacy `pkg/templatex` as non-release residue. | Documentation identity evidence only. |
| `/home/natsx/examples/README.md` | Lists runnable `basic`, `config`, `health`, and `jetstream` examples that import `pkg/natsx` and use embedded test brokers. | Example smoke evidence for the repaired subset, not full release approval. |
| `/home/natsx/examples/basic`, `/home/natsx/examples/config`, `/home/natsx/examples/health`, `/home/natsx/examples/jetstream` | Executable examples now import `pkg/natsx`; tests use embedded brokers or secret-sanitization checks. | Scenario smoke evidence for examples, not complete release evidence. |
| `/home/natsx/pkg/natsx/embedded_nats_test.go` | Adds embedded broker coverage for core publish/request/queue, unsubscribe, subscription Drain, client-close health, reconnect/degraded health, JetStream publish/pull, missing-stream publish, management idempotency/conflict, edge failures, nack redelivery, and max-deliveries advisory behavior. | Executable behavior evidence for the repaired subset, not full release approval. |
| `/home/natsx/pkg/natsx/benchmark_test.go` | Adds embedded Core NATS publish, Request, and JetStream publish benchmark coverage. | Complete repair-slice benchmark evidence; production threshold gate remains separate. |
| `/home/natsx/pkg/natsx/subject_test.go` | Covers subject build/parse/validation and canonical token rejection. | Complete evidence for SubjectBuilder baseline. |
| `/home/natsx/pkg/natsx/envelope_test.go` | Covers data/header copy and trace/message/schema metadata round-trip. | Complete evidence for envelope baseline. |
| `/home/natsx/pkg/natsx/config_test.go` | Covers defaults, endpoint validation, canonical/legacy env alias precedence, and secret sanitization. | Complete repair-slice config/security evidence; production TLS endpoint remains external. |
| `/home/natsx/pkg/natsx/health_test.go`, `/home/natsx/pkg/natsx/regression_test.go`, `/home/natsx/pkg/natsx/env_test.go`, and `/home/natsx/pkg/natsx/live_integration_test.go` | Cover disconnected health, nil/canceled context, invalid preconditions, noop metrics safety, canonical metric names, secret-safe env validation/live evidence, and race-safe recording metrics; embedded broker tests cover healthy, closed-client, reconnect, and degraded health. | Regression evidence for failure paths, metric naming, redaction, and guardrails. |
| `/home/ZoneCNH/module/natsx/SPEC.md` | Keeps Approved target-contract semantics explicit and separates that from GitHub Release approval. | Target contract, not release approval. |
| `/home/ZoneCNH/module/natsx/TRACEABILITY.md` | Separates repair-slice complete local evidence from external formal release gates. | Prevents documentation-only release approval claims. |

## Matrix Score Evidence

- Structural traceability coverage: **26 / 26 rows mapped** to requirements, test-case IDs, and task IDs.
- Documentation identity coverage: **4 / 4 tracked docs refreshed** for the repair slice (`README.md`, `examples/README.md`, `SPEC.md`, `TRACEABILITY.md`).
- Executable implementation coverage in `/home/natsx/pkg/natsx` and `/home/natsx/examples`: **14 / 14 task groups complete**, **0 / 14 partial**, **0 / 14 pending** for the repair slice.
- Module directory coverage in `/home/ZoneCNH/module/natsx`: documentation only; no local Go source or executable tests.
- Repair-slice score: **20 / 20** (module self-assessment of repair completeness).
- Structural matrix score: **100 / 100** (Claude rubric scoring, 2026-06-14, post D1/D2/D3 repair). Formal release approval remains **Not Approved** until GitHub Release evidence, four-source 98+ arbiter, production benchmark thresholds, and production TLS endpoint gates run.
- Code evidence: `/home/natsx` PR #17 merge `29503212e762c82bc91790c714e167f4f970a49f`; remote tag `v1.0.3` annotated tag `d2c12bed9a61e5411b6aadc103df611f0e4c59ce` peels to `f4db0b76ea7c86515559b04fcaa0853e1d08a02d`; GitHub Release v1.0.3 pending.
- Verification commands for this refresh:
  - `/home/natsx$ GOWORK=off go test ./pkg/natsx -run TestEmbeddedNATSJetStreamMaxDeliverAdvisory -count=1 -v`
  - `/home/natsx$ GOWORK=off go test ./pkg/natsx -count=1`
  - `/home/natsx$ GOWORK=off go test -race ./pkg/natsx -count=1`
  - `/home/natsx$ GOWORK=off go test ./pkg/natsx -bench 'BenchmarkEmbeddedNATS(Publish|Request|JetStreamPublish)$' -run '^$' -count=1 -benchtime=100x`
  - `/home/natsx$ GOWORK=off go test ./examples/... -count=1`
  - `/home/natsx$ GOWORK=off go test ./... -count=1`
  - `/home/natsx$ GOWORK=off go list -deps ./pkg/natsx ./examples/...` plus forbidden dependency filter => `dependency boundary clean`
  - `/home/natsx$ git diff --check`
  - `/home/ZoneCNH$ git diff --check -- README.md STATUS.md module/natsx`
  - `/home/ZoneCNH$ rg <stale natsx evidence phrases> README.md STATUS.md module/natsx` => no matches
  - `/home/natsx$ GOWORK=off go test ./pkg/natsx -count=1`
  - `/home/natsx$ GOWORK=off go vet ./pkg/natsx`
  - `/home/natsx$ GOWORK=off go test -race ./pkg/natsx -run TestEmbeddedNATSCorePublishRequestAndQueue -count=1`
  - `/home/natsx$ GOWORK=off go test ./pkg/natsx -bench 'BenchmarkEmbeddedNATS(Publish|Request|JetStreamPublish)$' -run '^$' -count=1 -benchtime=100x`
  - `/home/natsx$ GOWORK=off go test ./examples/... -count=1`
  - `/home/natsx$ GOWORK=off go test ./... -count=1`
  - `/home/natsx$ NATSX_LIVE_INTEGRATION=1 FOUNDATIONX_NATS_URL=<redacted-dev-url> FOUNDATIONX_NATS_USERNAME=<redacted> FOUNDATIONX_NATS_PASSWORD=<redacted> GOWORK=off go test ./pkg/natsx -run TestLiveNATSIntegration -count=1 -v` => PASS; no credentials printed
  - `/home/natsx$ git diff --check`
  - `/home/ZoneCNH/.worktree/workspaces/natsx$ git diff --check`
  - `/home/ZoneCNH$ gh release view v1.0.3 --repo ZoneCNH/natsx --json tagName,name,publishedAt,targetCommitish` => `release not found`
  - `/home/ZoneCNH$ git -C /home/natsx ls-remote origin refs/tags/v1.0.3 'refs/tags/v1.0.3^{}' refs/heads/main` => refs for `main`, `refs/tags/v1.0.3`, and peeled `refs/tags/v1.0.3^{}`
  - `/home/natsx$ GOCACHE=/tmp/omx-readonly-audit-gocache GOWORK=off go test ./pkg/natsx/ingest -count=1` => PASS

## Known Risks / Blockers

- `/home/ZoneCNH/module/natsx` has no Go source or executable tests; executable evidence lives in `/home/natsx/pkg/natsx`.
- `/home/natsx` now has embedded NATS core/JetStream lifecycle, delivery, env loading, handler latency, canonical metric, secret-safe live auth, and SLO-smoke coverage, but this repair slice is not full release approval.
- Examples import `pkg/natsx` and include embedded smoke tests, but they are scenario smoke evidence only; they do not close production SLO or formal release gates.
- Remaining blockers: formal four-source 98+ arbiter, production benchmark threshold enforcement, production TLS closure packet for `BLK-002`, and higher-level consumer lifecycle/API integration gates.
