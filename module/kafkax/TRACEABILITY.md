# kafkax 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-12
Source: module/kafkax/SPEC.md（v1.0.0-baseline-candidate, Draft）
Status: Draft; rows define expected 1.0 baseline coverage and must be backed by implementation tests before approval.

## Coverage Summary

- Functional requirements covered: FR-001..FR-006.
- Business rules covered: BR-001..BR-009.
- Task IDs are delivery anchors for implementation and test work; this document does not claim those tasks are complete.

| Requirement | Description | Acceptance Criteria | Test Case | Task | Status |
| --- | --- | --- | --- | --- | --- |
| FR-001 | Producer.Send 同步发送单条消息 | `Send(ctx, topic, key, value)` validates topic/value, honors context cancellation/timeout, maps Kafka failures to typed/redacted errors, and requires configured retry/ack policy. | TC-001 single-message send success; TC-004 retry timeout/failure; TC-008 error redaction | TASK-KAFKAX-001 Producer API + retry/error tests | ⬜ |
| FR-002 | Producer.SendBatch 批量发送消息 | `SendBatch(ctx, msgs)` validates every message before send, treats empty batch as caller error, preserves per-message diagnostics where possible, and returns redacted typed errors. | TC-002 batch send success/failure; TC-004 retry exhaustion; TC-008 redaction | TASK-KAFKAX-002 Batch producer validation + diagnostics | ⬜ |
| FR-003 | Consumer.Subscribe 订阅主题 | `Subscribe(ctx, topics)` rejects empty/invalid topic lists, honors context cancellation, and configures manual offset management without enabling auto commit. | TC-003 subscribe validation; TC-006 context cancellation; TC-009 auto-commit guard | TASK-KAFKAX-003 Consumer subscribe/config guard | ⬜ |
| FR-004 | Consumer.Poll 拉取消息 | `Poll(ctx)` returns a `Message` with topic/partition/offset/key/value/headers, returns `ctx.Err()` on cancellation/timeout, and does not commit offsets implicitly. | TC-003 poll message mapping; TC-006 poll cancellation; TC-009 no implicit commit | TASK-KAFKAX-004 Consumer poll/message mapping | ⬜ |
| FR-005 | Consumer.Commit 手动提交 offset | `Commit(ctx, msg)` validates message topic/partition/offset, honors context, returns typed commit errors, and is the only baseline offset-commit path. | TC-003 manual commit success/failure; TC-006 commit cancellation; TC-009 commit-only offset movement | TASK-KAFKAX-005 Consumer commit policy | ⬜ |
| FR-006 | Health 健康检查 | `Health(ctx)` reports producer/consumer/client readiness without exposing payload data and distinguishes healthy/degraded/unhealthy states with redacted diagnostics. | TC-005 health state mapping; TC-006 health timeout; TC-008 diagnostic redaction | TASK-KAFKAX-006 Health contract + diagnostics | ⬜ |
| BR-001 | Producer 必须使用 `acks=all` | Default and generated config set producer acknowledgements to all replicas; weaker acknowledgement settings are rejected unless an explicitly documented future escape hatch is approved. | TC-001 config defaults; TC-007 invalid acks rejection | TASK-KAFKAX-007 Producer safety config validation | ⬜ |
| BR-002 | Consumer 必须手动提交 offset | Consumer config disables auto commit; offsets move only through `Commit(ctx, msg)`. | TC-003 manual commit; TC-009 auto-commit disabled | TASK-KAFKAX-005 Consumer commit policy | ⬜ |
| BR-003 | 所有外部操作必须接收 `context.Context` | Public producer, consumer, health, and close operations accept `context.Context`; cancellation/timeout surfaces as typed context-aware errors. | TC-006 context propagation across public operations | TASK-KAFKAX-008 Context contract audit | ⬜ |
| BR-004 | Topic 不能为空 | Producer send, batch send, subscribe, poll-derived commit validation, and DLQ publishing reject empty topic values before Kafka I/O. | TC-007 empty topic validation | TASK-KAFKAX-009 Input validation matrix | ⬜ |
| BR-005 | Producer 重试必须可配置 | Retry attempts/backoff/timeouts are config-driven, bounded, observable, and disabled only by explicit config. | TC-004 retry configuration; TC-010 retry metrics | TASK-KAFKAX-010 Retry policy implementation | ⬜ |
| BR-006 | 失败消息必须支持 DLQ 策略 | Exhausted send/consume failures can be routed to a configured DLQ publisher with original metadata, redacted failure reason, and explicit handling for DLQ publish failure. | TC-011 DLQ publish success/failure; TC-008 redacted DLQ error | TASK-KAFKAX-011 DLQ strategy boundary | ⬜ |
| BR-007 | Metrics 命名必须以 `kafkax_` 开头 | All exported counters/histograms/gauges use `kafkax_` prefix and stable labels; non-prefixed metric names fail validation/review. | TC-010 metrics name audit | TASK-KAFKAX-012 Metrics contract audit | ⬜ |
| BR-008 | 错误消息不得包含消息内容 | Returned errors, logs, health diagnostics, DLQ failure records, and metrics labels redact message key/value/payload bytes and include only safe metadata. | TC-008 payload redaction across errors/logs/DLQ/health | TASK-KAFKAX-013 Redaction test suite | ⬜ |
| BR-009 | Consumer 不得默认启用 auto commit | Default consumer config and constructor validation reject `enable_auto_commit=true` for the baseline contract. | TC-009 default config and invalid override rejection | TASK-KAFKAX-014 Auto-commit default guard | ⬜ |

## Test Case Index

| Test Case | Purpose | Scope |
| --- | --- | --- |
| TC-001 | Single-message producer send, `acks=all`, and baseline error mapping | FR-001, BR-001 |
| TC-002 | Batch send validation and partial/aggregate failure behavior | FR-002 |
| TC-003 | Subscribe, poll, and manual commit happy/error paths | FR-003, FR-004, FR-005, BR-002 |
| TC-004 | Retry attempts, backoff, timeout, and exhausted-send behavior | FR-001, FR-002, BR-005 |
| TC-005 | Health state and diagnostic mapping | FR-006 |
| TC-006 | Context cancellation/timeout propagation for every public operation | FR-003, FR-004, FR-005, FR-006, BR-003 |
| TC-007 | Input/config validation, including empty topics and invalid `acks` | BR-001, BR-004 |
| TC-008 | Redaction across returned errors, logs, DLQ records, metrics labels, and health diagnostics | FR-001, FR-002, FR-006, BR-006, BR-008 |
| TC-009 | Manual offset policy and `enable_auto_commit=false` defaults/validation | FR-003, FR-004, FR-005, BR-002, BR-009 |
| TC-010 | Metrics naming and retry/latency/error observation | BR-005, BR-007 |
| TC-011 | DLQ strategy success/failure boundaries | BR-006 |

## Notes

- `TASK-KAFKAX-*` rows are planned delivery anchors; they should map to concrete tickets or implementation commits when development starts.
- Async producer, transactions, schema registry, exactly-once semantics, and business-event envelopes remain post-baseline/future scope unless SPEC.md is deliberately re-opened.
