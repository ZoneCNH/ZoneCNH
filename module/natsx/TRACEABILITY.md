# natsx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。本矩阵保持 Draft / Pending Evidence 状态；不得替代发布批准。

Last-Updated: 2026-06-12
Source: `goal.md` 1.0 发布基线 + `SPEC.md` Draft v1.0.0 + `/home/natsx` commit `d4072fe`

## Forward Coverage

| Requirement | Description | Acceptance Criteria | Test Case | Task | Status |
| ----------- | ----------- | ------------------- | --------- | ---- | ------ |
| FR-001 | Publish（Core NATS） | 发布成功、连接错误、空 subject 错误均有 embedded broker 或 precondition tests | TC-001 | TASK-NATSX-001 | Done |
| FR-002 | Subscribe（Core NATS） | subscribe、handler、unsubscribe、queue subscribe 和 client close 已覆盖；subscription Drain 证据待补齐 | TC-001 | TASK-NATSX-001 | In Progress |
| FR-003 | Request（Core NATS） | responder、no-responder、timeout、ctx cancel 均有 embedded broker tests | TC-002 | TASK-NATSX-002 | Done |
| FR-004 | JetStreamClientX.Publish | stream 存在与 missing-stream publish 场景均有 embedded JetStream tests | TC-003 | TASK-NATSX-003 | Done |
| FR-005 | JetStreamClientX.Subscribe | pull、ack、nack redelivery 已覆盖；dead-letter advisory 证据待补齐 | TC-003 | TASK-NATSX-003 | In Progress |
| FR-006 | JetStream.AddStream | 创建、幂等、冲突配置均有 embedded JetStream tests | TC-003 | TASK-NATSX-003 | Done |
| FR-007 | JetStream.AddConsumer | 创建、幂等、冲突配置均有 embedded JetStream tests | TC-003 | TASK-NATSX-003 | Done |
| FR-008 | Health | healthy、disconnected、nil、canceled、closed paths 已覆盖；degraded mapping 待补齐 | TC-005 | TASK-NATSX-005 | In Progress |
| BR-001 | Core NATS at-most-once | publish/subscribe/request/queue baseline 已覆盖，文档仍需明确不承诺持久化 | TC-001 | TASK-NATSX-001 | In Progress |
| BR-002 | JetStream at-least-once | ack/nack/redelivery 已覆盖；dead-letter advisory 证据待补齐 | TC-003 | TASK-NATSX-003 | In Progress |
| BR-003 | Context boundary | request timeout/cancel 与 health canceled context 已覆盖，完整网络操作矩阵待补齐 | TC-002 | TASK-NATSX-002 | In Progress |
| BR-004 | Handler latency | handler dispatch 已被 request/queue tests 间接覆盖；async/latency constraint 证据待补齐 | TC-001 | TASK-NATSX-010 | In Progress |
| BR-005 | 自动重连指数退避 | reconnect/backoff、max-attempts、state events tests 待补齐 | TC-004 | TASK-NATSX-004 | Pending |
| BR-006 | Health 幂等无副作用 | nil、canceled、closed、disconnected health paths 已覆盖；side-effect contract 待补齐 | TC-005 | TASK-NATSX-005 | In Progress |
| BR-007 | Stream/consumer 启动期创建 | AddStream/AddConsumer create/idempotency/conflict 已覆盖；启动期集成示例待补齐 | TC-003 | TASK-NATSX-003 | In Progress |
| BR-008 | 错误消息不泄露消息内容 | invalid precondition 与 selected error paths 已覆盖；完整错误红线矩阵待补齐 | TC-001, TC-003 | TASK-NATSX-011 | In Progress |
| BR-009 | Subscription 释放资源 | unsubscribe 与 client close 已覆盖；subscription Drain 释放语义证据待补齐 | TC-001 | TASK-NATSX-001 | In Progress |
| NFR-001 | Security redaction | config sanitize coverage exists；broader credential surfaces pending | TC-004 | TASK-NATSX-011 | In Progress |
| NFR-002 | TLS/auth | config expression/sanitize coverage exists；live TLS/auth integration pending | TC-004 | TASK-NATSX-011 | In Progress |
| NFR-003 | Performance budget | Core publish benchmark exists；request/JetStream benchmark and SLO assertions pending | TC-003 | TASK-NATSX-012 | In Progress |
| NFR-004 | Layer boundary | forbidden ZoneCNH messaging/storage dependency filter passed for repaired package/examples | CI Gate | TASK-NATSX-013 | Done |
| NFR-005 | Release evidence | SPEC、goal、traceability、matrix evidence reconciled; formal four-source arbiter still pending | Doc Gate | TASK-NATSX-014 | In Progress |

## Acceptance Criteria Linkage

| Acceptance Criterion | Requirement Set | Test Case | Current Evidence |
| -------------------- | --------------- | --------- | ---------------- |
| AC-001 | FR-001 | TC-001 | Embedded broker publish plus invalid-precondition coverage |
| AC-002 | FR-002, BR-009 | TC-001 | Embedded broker subscribe/queue/unsubscribe plus client close evidence; subscription Drain evidence pending |
| AC-003 | FR-003, BR-003 | TC-002 | Embedded responder, no-responder, timeout, and cancel coverage |
| AC-004 | FR-004 | TC-003 | Embedded JetStream publish/pull plus missing-stream publish coverage |
| AC-005 | FR-005, BR-002 | TC-003 | Pull, ack, and nack redelivery covered; dead-letter evidence pending |
| AC-006 | FR-006, BR-007 | TC-003 | Embedded AddStream create/idempotency/conflict covered |
| AC-007 | FR-007, BR-007 | TC-003 | Embedded AddConsumer create/idempotency/conflict covered |
| AC-008 | FR-008, BR-006 | TC-005 | Healthy, disconnected, nil, canceled, and closed health paths covered; degraded mapping pending |

## Reverse Coverage

| Test Case | Covers | Current Evidence |
| --------- | ------ | ---------------- |
| TC-001 | FR-001, FR-002, BR-001, BR-004, BR-008, BR-009 | `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSCorePublishRequestAndQueue`; `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSCoreTimeoutUnsubscribeDrainAndHealth`; `/home/natsx/pkg/natsx/regression_test.go::TestCoreOperationsRejectInvalidPreconditions` |
| TC-002 | FR-003, BR-003 | `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSCorePublishRequestAndQueue`; `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSRequestNoResponder`; `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSCoreTimeoutUnsubscribeDrainAndHealth` |
| TC-003 | FR-004, FR-005, FR-006, FR-007, BR-002, BR-007, BR-008 | `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSJetStreamPublishAndPull`; covers JetStream publish/pull, missing-stream publish, AddStream/AddConsumer idempotency/conflict, management edge failures, and nack redelivery; dead-letter advisory path remains |
| TC-004 | BR-005, NFR-001, NFR-002 | Reconnect/backoff tests pending; `/home/natsx/pkg/natsx/config_test.go::TestConfigValidateDefaultsAndSanitize` covers partial config sanitize evidence |
| TC-005 | FR-008, BR-006 | `/home/natsx/pkg/natsx/embedded_nats_test.go::TestEmbeddedNATSCoreTimeoutUnsubscribeDrainAndHealth`; `/home/natsx/pkg/natsx/health_test.go::TestHealthCheckDisconnectedRecordsMetrics`; `/home/natsx/pkg/natsx/regression_test.go::TestHealthCheckNilAndCanceledContext`; degraded mapping pending |
| Supplemental-Subject | SubjectBuilder baseline | `/home/natsx/pkg/natsx/subject_test.go` covers build/parse/validation and canonical token rejection |
| Supplemental-Envelope | NatsMessageEnvelope baseline | `/home/natsx/pkg/natsx/envelope_test.go`; embedded request/reply metadata propagation in `/home/natsx/pkg/natsx/embedded_nats_test.go` |
| Supplemental-Config | Config contract baseline | `/home/natsx/pkg/natsx/config_test.go`; old-alias compatibility pending |
| Supplemental-Observability | Observability baseline | `/home/natsx/pkg/natsx/regression_test.go::TestNoopMetricsMethodsAreSafe`; selected error metric assertions in regression and health tests; full metric/log contract pending |
| Supplemental-Performance | NFR-003 | `/home/natsx/pkg/natsx/benchmark_test.go::BenchmarkEmbeddedNATSPublish`; request and JetStream benchmark/SLO evidence pending |
| Supplemental-Boundary | NFR-004 | `/home/natsx$ GOWORK=off go list -deps ./pkg/natsx ./examples/...` plus forbidden dependency filter returned `dependency boundary clean` |
| Supplemental-Release | NFR-005 | `/home/natsx` commit `d4072fe`; this matrix refresh; formal four-source arbiter still pending |

## Task Coverage

| Task | Requirement Coverage | Current Evidence |
| ---- | -------------------- | ---------------- |
| TASK-NATSX-001 | FR-001, FR-002, BR-001, BR-009 | Partial publish/subscribe/request/queue baseline with unsubscribe and client close evidence; subscription Drain evidence pending |
| TASK-NATSX-002 | FR-003, BR-003 | Complete responder/no-responder/timeout/cancel coverage |
| TASK-NATSX-003 | FR-004, FR-005, FR-006, FR-007, BR-002, BR-007 | JetStream publish/pull, missing-stream publish, AddStream/AddConsumer idempotency/conflict, management edge failures, and nack redelivery covered; dead-letter advisory pending |
| TASK-NATSX-004 | BR-005 | Pending reconnect/backoff tests |
| TASK-NATSX-005 | FR-008, BR-006 | Partial health healthy/closed/failure-path coverage; degraded state mapping pending |
| TASK-NATSX-006 | SubjectBuilder supplemental baseline | Complete SubjectBuilder construction/parsing/validation coverage |
| TASK-NATSX-007 | Envelope supplemental baseline | Complete envelope/header metadata round-trip coverage |
| TASK-NATSX-008 | Config supplemental baseline | Partial config default/sanitize/validation coverage; old-alias compatibility pending |
| TASK-NATSX-009 | Observability supplemental baseline | Partial metrics coverage; full metric/log/tracing contract pending |
| TASK-NATSX-010 | BR-004 | Partial handler dispatch evidence; latency/async constraint evidence pending |
| TASK-NATSX-011 | BR-008, NFR-001, NFR-002 | Partial sanitize/config/error-path evidence; live TLS/auth integration pending |
| TASK-NATSX-012 | NFR-003 | Partial Core publish benchmark evidence; request/JetStream benchmark and SLO assertions pending |
| TASK-NATSX-013 | NFR-004 | Dependency boundary check passed for forbidden ZoneCNH messaging/storage modules |
| TASK-NATSX-014 | NFR-005 | `SPEC.md` / `TRACEABILITY.md` / matrix evidence refreshed on 2026-06-12; `/home/natsx` code evidence pinned to commit `d4072fe` |

## Documentation Evidence Inventory

| Artifact | Evidence state | Release meaning |
| --- | --- | --- |
| `/home/natsx/README.md` | Identifies `github.com/ZoneCNH/natsx/pkg/natsx` as the 1.0 target and legacy `pkg/templatex` as non-release residue. | Documentation identity evidence only. |
| `/home/natsx/examples/README.md` | Lists runnable `basic`, `config`, `health`, and `jetstream` examples that import `pkg/natsx` and use embedded test brokers. | Example smoke evidence for the repaired subset, not full release approval. |
| `/home/natsx/examples/basic`, `/home/natsx/examples/config`, `/home/natsx/examples/health`, `/home/natsx/examples/jetstream` | Executable examples now import `pkg/natsx`; tests use embedded brokers or secret-sanitization checks. | Scenario smoke evidence for examples, not complete release evidence. |
| `/home/natsx/pkg/natsx/embedded_nats_test.go` | Adds embedded broker coverage for core publish/request/queue, request timeout/cancel, unsubscribe/client close health, JetStream publish/pull, missing-stream publish, management idempotency/conflict, edge failures, and nack redelivery. | Executable behavior evidence for the repaired subset, not full release approval. |
| `/home/natsx/pkg/natsx/benchmark_test.go` | Adds embedded Core NATS publish benchmark coverage. | Partial performance evidence; request, JetStream, and SLO assertion coverage pending. |
| `/home/natsx/pkg/natsx/subject_test.go` | Covers subject build/parse/validation and canonical token rejection. | Complete evidence for SubjectBuilder baseline. |
| `/home/natsx/pkg/natsx/envelope_test.go` | Covers data/header copy and trace/message/schema metadata round-trip. | Complete evidence for envelope baseline. |
| `/home/natsx/pkg/natsx/config_test.go` | Covers defaults, endpoint validation, and secret sanitization. | Partial config/security evidence; alias and live TLS/auth evidence pending. |
| `/home/natsx/pkg/natsx/health_test.go` and `/home/natsx/pkg/natsx/regression_test.go` | Cover disconnected health, nil/canceled context, invalid preconditions, and noop metrics safety; embedded broker tests cover healthy and closed-client health. | Regression evidence for failure paths and guardrails. |
| `/home/ZoneCNH/module/natsx/SPEC.md` | Keeps Draft / not approved semantics explicit. | Target contract, not release approval. |
| `/home/ZoneCNH/module/natsx/TRACEABILITY.md` | Separates complete, partial, and pending executable evidence. | Prevents documentation-only 100/100 claims. |

## Matrix Score Evidence

- Structural traceability coverage: **8 / 8 FR rows**, **9 / 9 BR rows**, and **5 supplemental NFR evidence rows** tracked.
- Documentation identity coverage: **4 / 4 tracked docs refreshed** for the repair slice (`README.md`, `examples/README.md`, `SPEC.md`, `TRACEABILITY.md`).
- Executable implementation coverage in `/home/natsx/pkg/natsx` and `/home/natsx/examples`:
  **6 / 14 task groups complete**, **7 / 14 partial**, **1 / 14 pending**.
- TASK-NATSX-002 is complete. TASK-NATSX-003 now covers missing-stream, AddStream/AddConsumer,
  edge-failure, and redelivery subclaims, but remains partial for dead-letter evidence.
- TASK-NATSX-012 has partial Core publish benchmark coverage.
- Module directory coverage in `/home/ZoneCNH/module/natsx`: documentation only; no local Go source or executable tests.
- Approval status: **Not Approved**. Status remains Draft / Pending Evidence until remaining implementation, integration, performance, and formal gate evidence exists.
- Code evidence commit: `/home/natsx` `d4072fe` (`Prove natsx release edges with executable examples`), including parent `29b0821` (`Classify natsx JetStream edge failures`).
- Verification commands for this refresh:
  - `/home/natsx$ GOWORK=off go test ./pkg/natsx -count=1`
  - `/home/natsx$ GOWORK=off go test -race ./pkg/natsx -count=1`
  - `/home/natsx$ GOWORK=off go test ./examples/... -count=1`
  - `/home/natsx$ GOWORK=off go test ./pkg/natsx -run '^$' -bench BenchmarkEmbeddedNATSPublish -benchtime=100x`
  - `/home/natsx$ GOWORK=off go vet ./...`
  - `/home/natsx$ GOWORK=off go test ./... -count=1`
  - `/home/natsx$ GOWORK=off go list -deps ./pkg/natsx ./examples/...` plus forbidden dependency filter => `dependency boundary clean`
  - `/home/natsx$ git diff --check`
  - `/home/ZoneCNH$ git diff --check -- module/natsx/SPEC.md module/natsx/TRACEABILITY.md`

## Known Risks / Blockers

- `/home/ZoneCNH/module/natsx` has no Go source or executable tests; executable evidence lives in `/home/natsx/pkg/natsx`.
- `/home/natsx` now has embedded NATS core/JetStream subset coverage, but this repair slice is not full release approval.
- Examples now import `pkg/natsx` and include embedded smoke tests, but they are scenario smoke evidence only; they do not close reconnect, dead-letter, performance-SLO, or formal gate requirements.
- Remaining blockers include dead-letter advisory path, reconnect/backoff, request/JetStream benchmark plus SLO assertions,
  and degraded/full health-observability lifecycle.
- Live TLS/auth/config-alias breadth and the formal four-source 98+ arbiter also remain pending.
