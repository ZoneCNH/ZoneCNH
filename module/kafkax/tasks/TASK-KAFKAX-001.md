---
scope: "TASK-KAFKAX-001: Producer Send/SendBatch + acks + retry"
acceptance_criteria: ["AC-001", "AC-002"]
---

# TASK-KAFKAX-001: Producer Send/SendBatch + acks + retry

- **Module**: kafkax
- **spec_ref**: module/kafkax/SPEC.md#FR-001 ,module/kafkax/SPEC.md#FR-002
- **BR_ref**: module/kafkax/SPEC.md#BR-001 ,module/kafkax/SPEC.md#BR-005
- **ACs**: AC-001, AC-002
- **Phase**: Foundation (Phase 1)
- **Priority**: P0
- **Dependencies**: none
- **Status**: Done

## Scope

实现 Producer 接口：Send 单条发送、SendBatch 批量发送、acks=all 同步确认、重试策略

## Non-Scope

Does NOT implement Kafka broker deployment, topic auto-creation, or Kafka Connect integration. Does NOT implement business event semantics or domain DTOs.

## Files

- `/home/workspace/kafkax/pkg/kafkax/producer.go` — Producer 接口
- `/home/workspace/kafkax/pkg/kafkax/kafkago/producer.go:40` — `Send(ctx, message, opts...)`
- `/home/workspace/kafkax/pkg/kafkax/kafkago/producer.go:51` — `SendBatch(ctx, messages, opts...)`
- `/home/workspace/kafkax/pkg/kafkax/kafkago/producer.go:24-26` — `RequiredAcks` / `MaxAttempts` 透传
- `/home/workspace/kafkax/pkg/kafkax/config.go:47` — `RequiredAcks < 0` 校验
- `/home/workspace/kafkax/pkg/kafkax/config.go:59` — `Retry.MaxAttempts < 0` 校验

## Acceptance

- [x] FR-001 verified via TC — `go test -race -run="ProducerSend|Send" ./pkg/kafkax/...`
- [x] FR-002 verified via TC — `go test -race -run=SendBatch ./pkg/kafkax/...`

## Evidence

- 实现：`pkg/kafkax/kafkago/producer.go`（基于 `segmentio/kafka-go v0.4.51`）
- 校验：`Config.Validate()` 拒绝 `RequiredAcks<0`、`MaxAttempts<0`（BR-001/005）
- 默认 `acks=all`（RequiredAcks=-1），重试默认 3 次
- 测试：`go test ./pkg/kafkax/` ✅（含 api_contract_test、config_test）
- 追溯：TRACEABILITY.md FR-001/FR-002 ✅

## Non-scope

- 不涉及本 Task 范围外的功能
