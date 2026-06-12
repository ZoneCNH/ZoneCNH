# natsx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。本矩阵保持 Draft / Pending Evidence 状态；不得替代发布批准。

Last-Updated: 2026-06-12
Source: `goal.md` 1.0 发布基线 + `SPEC.md` Draft v1.0.0 + `/home/natsx` commit `3053e80`

## Forward Coverage

| Requirement | Description | Acceptance Criteria | Test Case | Task | Status |
| ----------- | ----------- | ------------------- | --------- | ---- | ------ |
| FR-001 | Publish（Core NATS） | 发布成功、连接错误、空 subject 错误均有测试 | TC-001 | TASK-NATSX-001 | ✅ Embedded broker publish and precondition tests |
| FR-002 | Subscribe（Core NATS） | subscribe/handler/unsubscribe/drain 均有测试 | TC-001 | TASK-NATSX-001 | ✅ Subscribe, queue subscribe, unsubscribe, subscription Drain, and client close covered |
| FR-003 | Request（Core NATS） | responder、timeout、ctx cancel 均有测试 | TC-002 | TASK-NATSX-002 | ✅ Responder, no-responder, timeout, and cancel covered |
| FR-004 | JetStream.Publish | stream 存在/缺失场景均有测试 | TC-003 | TASK-NATSX-003 | ✅ Stream-present and missing-stream publish covered |
| FR-005 | JetStream.Subscribe | ack、redelivery、dead-letter 行为均有测试 | TC-003 | TASK-NATSX-003 | ✅ Pull, ack, nack redelivery, and max-deliveries advisory behavior covered |
| FR-006 | JetStream.AddStream | 创建、幂等、冲突配置均有测试 | TC-003 | TASK-NATSX-003 | ✅ Embedded AddStream create/idempotency/conflict covered |
| FR-007 | JetStream.AddConsumer | 创建、幂等、冲突配置均有测试 | TC-003 | TASK-NATSX-003 | ✅ Embedded AddConsumer create/idempotency/conflict covered |
| FR-008 | Health | ready/live/message 与连接状态映射有测试 | TC-005 | TASK-NATSX-005 | ✅ Healthy, disconnected, nil, canceled, closed, reconnect, and degraded health paths covered |
| FR-009 | SubjectBuilder | `domain.resource.action.v{version}` 构造和解析有测试 | TC-006 | TASK-NATSX-006 | ✅ Build/parse/validation tests |
| FR-010 | NatsMessageEnvelope | traceId/messageId/schemaVersion/header 双向映射有测试 | TC-007 | TASK-NATSX-007 | ✅ Header metadata round-trip and embedded propagation tests |
| FR-011 | Config contract | `foundationx.nats.*` 配置、默认值和旧别名兼容有测试 | TC-008 | TASK-NATSX-008 | ◐ Defaults/sanitize/validation covered; old-alias compatibility pending |
| FR-012 | Observability contract | `foundationx_nats_*` 指标和结构化日志字段有测试 | TC-009 | TASK-NATSX-009 | ◐ Noop and selected error metrics covered; full metric/log contract pending |
| BR-001 | Core NATS at-most-once | 不承诺持久化，低延迟发布订阅场景有说明和测试 | TC-001 | TASK-NATSX-001 | ✅ Core publish/subscribe/request/queue baseline covered |
| BR-002 | JetStream at-least-once | ack/nack/redelivery 语义有测试 | TC-003 | TASK-NATSX-003 | ✅ Ack/nack/redelivery and max-deliveries advisory covered |
| BR-003 | Context boundary | 所有网络操作接受 context 并尊重取消/超时 | TC-002 | TASK-NATSX-002 | ◐ Request timeout/cancel and close context covered; broader network-operation matrix pending |
| BR-004 | Handler latency | 订阅 handler 快速返回/异步化约束有测试或示例 | TC-010 | TASK-NATSX-010 | ◐ Handler path covered; async/latency constraint evidence pending |
| BR-005 | 自动重连指数退避 | 断线重连、max-attempts、状态事件有测试 | TC-004 | TASK-NATSX-004 | ◐ Reconnect/degraded health and policy knobs covered; exponential-backoff SLO assertions pending |
| NFR-001 | Security redaction | credentials/token/连接串敏感片段脱敏 | TC-011 | TASK-NATSX-011 | ◐ Config sanitize coverage exists; broader credential surfaces pending |
| NFR-002 | TLS/auth | TLS 与认证配置可表达且不泄漏凭据 | TC-011 | TASK-NATSX-011 | ◐ Config expression/sanitize coverage exists; live TLS/auth integration pending |
| NFR-003 | Performance budget | publish/request/JetStream 延迟预算有 benchmark | TC-012 | TASK-NATSX-012 | ◐ Publish/request/JetStream publish benchmarks exist; formal SLO assertions plus JetStream consume/handler latency coverage pending |
| NFR-004 | Layer boundary | 不依赖 kafkax，不替代 RPC/治理框架 | TC-013 | TASK-NATSX-013 | ✅ Dependency boundary clean |
| NFR-005 | Release evidence | SPEC、goal、traceability、matrix evidence 一致 | TC-014 | TASK-NATSX-014 | ✅ Documentation and executable evidence reconciled |

## Acceptance Criteria Linkage

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

## Reverse Coverage

| Test Case | Covers | Current Evidence |
| --------- | ------ | ---------------- |
| TC-001 | FR-001, FR-002, BR-001 | `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSCorePublishRequestAndQueue`; `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSCoreTimeoutUnsubscribeDrainAndHealth`; `/home/natsx/pkg/natsx/regression_test.go::TestCoreOperationsRejectInvalidPreconditions` |
| TC-002 | FR-003, BR-003 | `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSCorePublishRequestAndQueue`; `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSRequestNoResponder`; `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSCoreTimeoutUnsubscribeDrainAndHealth` |
| TC-003 | FR-004, FR-005, FR-006, FR-007, BR-002 | `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSJetStreamPublishAndPull`; `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSJetStreamMaxDeliverAdvisory`; covers JetStream publish/pull, missing-stream publish, AddStream/AddConsumer idempotency/conflict, management edge failures, nack redelivery, and max-deliveries advisory behavior |
| TC-004 | BR-005 | `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSReconnectBackoffAndDegradedHealth`; reconnect/degraded health covered; exponential-backoff SLO assertions pending |
| TC-005 | FR-008 | `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSCoreTimeoutUnsubscribeDrainAndHealth`; `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSReconnectBackoffAndDegradedHealth`; `/home/natsx/pkg/natsx/health_test.go::TestHealthCheckDisconnectedRecordsMetrics`; `/home/natsx/pkg/natsx/regression_test.go::TestHealthCheckNilAndCanceledContext` |
| TC-006 | FR-009 | `/home/natsx/pkg/natsx/subject_test.go` |
| TC-007 | FR-010 | `/home/natsx/pkg/natsx/envelope_test.go`; embedded request/reply metadata propagation in `/home/natsx/pkg/natsx/embedded_nats_test.go` |
| TC-008 | FR-011 | `/home/natsx/pkg/natsx/config_test.go`; old-alias compatibility pending |
| TC-009 | FR-012 | `/home/natsx/pkg/natsx/regression_test.go::TestNoopMetricsMethodsAreSafe`; selected error metric assertions in regression and health tests; full contract pending |
| TC-010 | BR-004 | Handler dispatch exercised by embedded request/queue tests; latency or documented benchmark pending |
| TC-011 | NFR-001, NFR-002 | `/home/natsx/pkg/natsx/config_test.go::TestConfigValidateDefaultsAndSanitize`; live TLS/auth integration pending |
| TC-012 | NFR-003 | `/home/natsx/pkg/natsx/benchmark_test.go::BenchmarkEmbeddedNATSPublish`; `/home/natsx/pkg/natsx/benchmark_test.go::BenchmarkEmbeddedNATSRequest`; `/home/natsx/pkg/natsx/benchmark_test.go::BenchmarkEmbeddedNATSJetStreamPublish`; formal SLO assertions plus JetStream consume/handler latency evidence pending |
| TC-013 | NFR-004 | `/home/natsx$ GOWORK=off go list -deps ./pkg/natsx ./examples/...` plus forbidden-domain filter returned `dependency boundary clean` |
| TC-014 | NFR-005 | `/home/natsx` commit `3053e80`; this matrix refresh; formal four-source arbiter still pending |

## Task Coverage

| Task | Requirement Coverage | Current Evidence |
| ---- | -------------------- | ---------------- |
| TASK-NATSX-001 | FR-001, FR-002, BR-001 | Complete publish/subscribe/request/queue baseline with unsubscribe, subscription Drain, and client close evidence |
| TASK-NATSX-002 | FR-003, BR-003 | Complete responder/no-responder/timeout/cancel coverage |
| TASK-NATSX-003 | FR-004, FR-005, FR-006, FR-007, BR-002 | Complete JetStream publish/pull, missing-stream publish, AddStream/AddConsumer idempotency/conflict, management edge failures, nack redelivery, and max-deliveries advisory coverage |
| TASK-NATSX-004 | BR-005 | Partial reconnect/degraded health and policy knobs covered; exponential-backoff SLO assertions pending |
| TASK-NATSX-005 | FR-008 | Complete health healthy/closed/failure/reconnect/degraded coverage |
| TASK-NATSX-006 | FR-009 | Complete SubjectBuilder construction/parsing/validation coverage |
| TASK-NATSX-007 | FR-010 | Complete envelope/header metadata round-trip coverage |
| TASK-NATSX-008 | FR-011 | Partial config default/sanitize/validation coverage; old-alias compatibility pending |
| TASK-NATSX-009 | FR-012 | Partial metrics coverage; full metric/log/tracing contract pending |
| TASK-NATSX-010 | BR-004 | Partial handler dispatch evidence; latency/async constraint evidence pending |
| TASK-NATSX-011 | NFR-001, NFR-002 | Partial sanitize/config evidence; live TLS/auth integration pending |
| TASK-NATSX-012 | NFR-003 | Partial publish/request/JetStream publish benchmarks; formal thresholds, JetStream consume, and handler latency pending |
| TASK-NATSX-013 | NFR-004 | Dependency boundary check passed for forbidden ZoneCNH messaging/storage modules |
| TASK-NATSX-014 | NFR-005 | `SPEC.md` / `TRACEABILITY.md` / matrix evidence refreshed on 2026-06-12; `/home/natsx` code evidence pinned to commit `3053e80` |

## Documentation Evidence Inventory

| Artifact | Evidence state | Release meaning |
| --- | --- | --- |
| `/home/natsx/README.md` | Identifies `github.com/ZoneCNH/natsx/pkg/natsx` as the 1.0 target and legacy `pkg/templatex` as non-release residue. | Documentation identity evidence only. |
| `/home/natsx/examples/README.md` | Lists runnable `basic`, `config`, `health`, and `jetstream` examples that import `pkg/natsx` and use embedded test brokers. | Example smoke evidence for the repaired subset, not full release approval. |
| `/home/natsx/examples/basic`, `/home/natsx/examples/config`, `/home/natsx/examples/health`, `/home/natsx/examples/jetstream` | Executable examples now import `pkg/natsx`; tests use embedded brokers or secret-sanitization checks. | Scenario smoke evidence for examples, not complete release evidence. |
| `/home/natsx/pkg/natsx/embedded_nats_test.go` | Adds embedded broker coverage for core publish/request/queue, unsubscribe, subscription Drain, client-close health, reconnect/degraded health, JetStream publish/pull, missing-stream publish, management idempotency/conflict, edge failures, nack redelivery, and max-deliveries advisory behavior. | Executable behavior evidence for the repaired subset, not full release approval. |
| `/home/natsx/pkg/natsx/benchmark_test.go` | Adds embedded Core NATS publish, Request, and JetStream publish benchmark coverage. | Partial performance evidence; formal SLO, JetStream consume, and handler latency coverage pending. |
| `/home/natsx/pkg/natsx/subject_test.go` | Covers subject build/parse/validation and canonical token rejection. | Complete evidence for SubjectBuilder baseline. |
| `/home/natsx/pkg/natsx/envelope_test.go` | Covers data/header copy and trace/message/schema metadata round-trip. | Complete evidence for envelope baseline. |
| `/home/natsx/pkg/natsx/config_test.go` | Covers defaults, endpoint validation, and secret sanitization. | Partial config/security evidence; alias and live TLS/auth evidence pending. |
| `/home/natsx/pkg/natsx/health_test.go` and `/home/natsx/pkg/natsx/regression_test.go` | Cover disconnected health, nil/canceled context, invalid preconditions, noop metrics safety, and race-safe recording metrics; embedded broker tests cover healthy, closed-client, reconnect, and degraded health. | Regression evidence for failure paths and guardrails. |
| `/home/ZoneCNH/module/natsx/SPEC.md` | Keeps Draft / not approved semantics explicit. | Target contract, not release approval. |
| `/home/ZoneCNH/module/natsx/TRACEABILITY.md` | Separates complete, partial, and remaining open executable evidence. | Prevents documentation-only 100/100 claims. |

## Matrix Score Evidence

- Structural traceability coverage: **21 / 21 rows mapped** to requirements, test-case IDs, and task IDs.
- Documentation identity coverage: **4 / 4 tracked docs refreshed** for the repair slice (`README.md`, `examples/README.md`, `SPEC.md`, `TRACEABILITY.md`).
- Executable implementation coverage in `/home/natsx/pkg/natsx` and `/home/natsx/examples`: **8 / 14 task groups complete**, **6 / 14 partial**, **0 / 14 pending**; TASK-NATSX-001/002/003/005/006/007/013/014 are complete, and TASK-NATSX-004/008/009/010/011/012 remain partial.
- Module directory coverage in `/home/ZoneCNH/module/natsx`: documentation only; no local Go source or executable tests.
- Approval status: **Not Approved**. Status remains Draft / Pending Evidence until remaining integration, performance-SLO, API/observability, and formal gate evidence exists.
- Code evidence commit: `/home/natsx` `3053e80` (`Prove natsx lifecycle and delivery edges`).
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

## Known Risks / Blockers

- `/home/ZoneCNH/module/natsx` has no Go source or executable tests; executable evidence lives in `/home/natsx/pkg/natsx`.
- `/home/natsx` now has embedded NATS core/JetStream lifecycle and delivery coverage, but this repair slice is not full release approval.
- Examples import `pkg/natsx` and include embedded smoke tests, but they are scenario smoke evidence only; they do not close production SLO or formal release gates.
- Remaining blockers: formal four-source 98+ arbiter, live TLS/auth/config-alias breadth, production SLO thresholds, JetStream consume/handler latency benchmarks, and higher-level consumer lifecycle/API/observability polish.
