# natsx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。本矩阵保持 Draft / Pending Evidence 状态；不得替代发布批准。

Last-Updated: 2026-06-12
Source: `goal.md` 1.0 发布基线 + `SPEC.md` Draft v1.0.0

## Forward Coverage

| Requirement | Description             | Acceptance Criteria                                   | Test Case | Task           | Status                             |
| ----------- | ----------------------- | ----------------------------------------------------- | --------- | -------------- | ---------------------------------- |
| FR-001      | Publish（Core NATS）    | 发布成功、连接错误、空 subject 错误均有测试           | TC-001    | TASK-NATSX-001 | ⬜ Pending implementation test      |
| FR-002      | Subscribe（Core NATS）  | subscribe/handler/unsubscribe/drain 均有测试          | TC-001    | TASK-NATSX-001 | ⬜ Pending implementation test      |
| FR-003      | Request（Core NATS）    | responder、timeout、ctx cancel 均有测试               | TC-002    | TASK-NATSX-002 | ⬜ Pending implementation test      |
| FR-004      | JetStream.Publish       | stream 存在/缺失场景均有测试                          | TC-003    | TASK-NATSX-003 | ⬜ Pending implementation test      |
| FR-005      | JetStream.Subscribe     | ack、redelivery、dead-letter 行为均有测试             | TC-003    | TASK-NATSX-003 | ⬜ Pending implementation test      |
| FR-006      | JetStream.AddStream     | 创建、幂等、冲突配置均有测试                          | TC-003    | TASK-NATSX-003 | ⬜ Pending implementation test      |
| FR-007      | JetStream.AddConsumer   | 创建、幂等、冲突配置均有测试                          | TC-003    | TASK-NATSX-003 | ⬜ Pending implementation test      |
| FR-008      | Health                  | ready/live/message 与连接状态映射有测试               | TC-005    | TASK-NATSX-005 | ⬜ Pending implementation test      |
| FR-009      | SubjectBuilder          | `domain.resource.action.v{version}` 构造和解析有测试  | TC-006    | TASK-NATSX-006 | ⬜ Pending implementation test      |
| FR-010      | NatsMessageEnvelope     | traceId/messageId/schemaVersion/header 双向映射有测试 | TC-007    | TASK-NATSX-007 | ⬜ Pending implementation test      |
| FR-011      | Config contract         | `foundationx.nats.*` 配置、默认值和旧别名兼容有测试   | TC-008    | TASK-NATSX-008 | ⬜ Pending implementation test      |
| FR-012      | Observability contract  | `foundationx_nats_*` 指标和结构化日志字段有测试       | TC-009    | TASK-NATSX-009 | ⬜ Pending implementation test      |
| BR-001      | Core NATS at-most-once  | 不承诺持久化，低延迟发布订阅场景有说明和测试          | TC-001    | TASK-NATSX-001 | ⬜ Pending implementation test      |
| BR-002      | JetStream at-least-once | ack/nack/redelivery 语义有测试                        | TC-003    | TASK-NATSX-003 | ⬜ Pending implementation test      |
| BR-003      | Context boundary        | 所有网络操作接受 context 并尊重取消/超时              | TC-002    | TASK-NATSX-002 | ⬜ Pending implementation test      |
| BR-004      | Handler latency         | 订阅 handler 快速返回/异步化约束有测试或示例          | TC-010    | TASK-NATSX-010 | ⬜ Pending implementation test      |
| BR-005      | 自动重连指数退避        | 断线重连、max-attempts、状态事件有测试                | TC-004    | TASK-NATSX-004 | ⬜ Pending implementation test      |
| NFR-001     | Security redaction      | credentials/token/连接串敏感片段脱敏                  | TC-011    | TASK-NATSX-011 | ⬜ Pending implementation test      |
| NFR-002     | TLS/auth                | TLS 与认证配置可表达且不泄漏凭据                      | TC-011    | TASK-NATSX-011 | ⬜ Pending implementation test      |
| NFR-003     | Performance budget      | publish/request/JetStream 延迟预算有 benchmark        | TC-012    | TASK-NATSX-012 | ⬜ Pending benchmark                |
| NFR-004     | Layer boundary          | 不依赖 kafkax，不替代 RPC/治理框架                    | TC-013    | TASK-NATSX-013 | ⬜ Pending dependency check         |
| NFR-005     | Release evidence        | SPEC、goal、traceability、matrix evidence 一致        | TC-014    | TASK-NATSX-014 | ✅ Documentation evidence refreshed |

## Reverse Coverage

| Test Case | Covers                                 | Required Evidence                                      |
| --------- | -------------------------------------- | ------------------------------------------------------ |
| TC-001    | FR-001, FR-002, BR-001                 | Core NATS publish/subscribe unit or integration tests  |
| TC-002    | FR-003, BR-003                         | Request/reply timeout and cancellation tests           |
| TC-003    | FR-004, FR-005, FR-006, FR-007, BR-002 | JetStream publish/consume/admin tests                  |
| TC-004    | BR-005                                 | reconnect/backoff tests                                |
| TC-005    | FR-008                                 | health state tests                                     |
| TC-006    | FR-009                                 | SubjectBuilder construction/parsing tests              |
| TC-007    | FR-010                                 | Envelope/Header/Trace propagation tests                |
| TC-008    | FR-011                                 | config parsing/default/compatibility tests             |
| TC-009    | FR-012                                 | metrics/logging/tracing contract tests                 |
| TC-010    | BR-004                                 | handler dispatch behavior test or documented benchmark |
| TC-011    | NFR-001, NFR-002                       | redaction and TLS/auth config tests                    |
| TC-012    | NFR-003                                | benchmark evidence                                     |
| TC-013    | NFR-004                                | dependency boundary check                              |
| TC-014    | NFR-005                                | doc/matrix consistency checks                          |

## Task Coverage

| Task           | Requirement Coverage                   | Current Evidence                                                        |
| -------------- | -------------------------------------- | ----------------------------------------------------------------------- |
| TASK-NATSX-001 | FR-001, FR-002, BR-001                 | Pending executable NATS tests                                           |
| TASK-NATSX-002 | FR-003, BR-003                         | Pending executable request/reply tests                                  |
| TASK-NATSX-003 | FR-004, FR-005, FR-006, FR-007, BR-002 | Pending executable JetStream tests                                      |
| TASK-NATSX-004 | BR-005                                 | Pending reconnect/backoff tests                                         |
| TASK-NATSX-005 | FR-008                                 | Pending health tests                                                    |
| TASK-NATSX-006 | FR-009                                 | Pending SubjectBuilder tests                                            |
| TASK-NATSX-007 | FR-010                                 | Pending envelope/header tests                                           |
| TASK-NATSX-008 | FR-011                                 | Pending config tests                                                    |
| TASK-NATSX-009 | FR-012                                 | Pending observability tests                                             |
| TASK-NATSX-010 | BR-004                                 | Pending handler behavior evidence                                       |
| TASK-NATSX-011 | NFR-001, NFR-002                       | Pending security tests                                                  |
| TASK-NATSX-012 | NFR-003                                | Pending benchmarks                                                      |
| TASK-NATSX-013 | NFR-004                                | Pending dependency boundary check                                       |
| TASK-NATSX-014 | NFR-005                                | `SPEC.md` / `TRACEABILITY.md` / matrix evidence refreshed on 2026-06-12 |

## Matrix Score Evidence

- Structural traceability coverage: **21 / 21 rows mapped** to requirements, test-case IDs, and task IDs.
- Executable implementation coverage: **0 / 14 task groups complete** in `/home/ZoneCNH/module/natsx`; this directory contains documentation only.
- Approval status: **Not Approved**. Status remains Draft / Pending Evidence until implementation and integration tests exist.
- Verification commands for this refresh:
  - `python3` Markdown fence sanity check for `SPEC.md`
  - `/home/ZoneCNH$ git diff --check`
  - `/home/natsx$ GOWORK=off go test ./...`

## Known Risks / Blockers

- `/home/ZoneCNH/module/natsx` has no Go source or executable tests, so TC-001 through TC-013 remain pending.
- `/home/natsx` repository identity repair is a separate code slice from module-level API approval; passing Go tests there does not prove NATS functional behavior.
