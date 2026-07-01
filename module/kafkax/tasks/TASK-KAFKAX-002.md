---
scope: "TASK-KAFKAX-002: Consumer Subscribe/Poll + ctx"
acceptance_criteria: ["AC-003", "AC-004"]
---

# TASK-KAFKAX-002: Consumer Subscribe/Poll + ctx

- **Module**: kafkax
- **spec_ref**: module/kafkax/SPEC.md#FR-003 ,module/kafkax/SPEC.md#FR-004
- **BR_ref**: module/kafkax/SPEC.md#BR-003
- **ACs**: AC-003, AC-004
- **Phase**: Foundation (Phase 1)
- **Priority**: P0
- **Dependencies**: none
- **Status**: Done

## Scope

实现 Consumer 接口：Subscribe 消费组加入、Poll 阻塞拉取、ctx 超时取消

## Non-Scope

Does NOT implement Kafka broker deployment, topic auto-creation, or Kafka Connect integration. Does NOT implement business event semantics or domain DTOs.

## Files

- `/home/workspace/kafkax/pkg/kafkax/consumer.go` — Consumer / Handler 接口
- `/home/workspace/kafkax/pkg/kafkax/kafkago/consumer.go:21` — `newConsumer`（消费组 + StartOffset 配置）
- `/home/workspace/kafkax/pkg/kafkax/kafkago/consumer.go:44` — `Run(ctx, handler)` 消费循环
- `/home/workspace/kafkax/pkg/kafkax/kafkago/consumer.go:65` — `Poll(ctx)` 阻塞拉取
- `/home/workspace/kafkax/pkg/kafkax/kafkago/consumer.go:119,126,137` — Pause/Resume/Close ctx 取消处理
- `/home/workspace/kafkax/pkg/kafkax/config.go:114-116` — `GroupID` / `StartOffset` 配置

## Acceptance

- [x] FR-003 verified via TC — `go test -race -run="Subscribe|Consumer" ./pkg/kafkax/...`
- [x] FR-004 verified via TC — `go test -race -run="Poll|Context" ./pkg/kafkax/...`

## Evidence

- 实现：`pkg/kafkax/kafkago/consumer.go`
- ctx 传播：Run/Poll/Pause/Resume/Close 均检查 `ctx.Err()`（BR-003）
- 消费组：通过 `kafka.ReaderConfig.GroupID` / `GroupTopics` 实现消费组订阅
- 测试：`go test ./pkg/kafkax/` ✅
- 追溯：TRACEABILITY.md FR-003/FR-004 ✅

## Non-scope

- 不涉及本 Task 范围外的功能
