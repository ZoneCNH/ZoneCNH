---
scope: "TASK-KAFKAX-003: 手动 offset 提交 + Close 边界 + 无自动提交"
acceptance_criteria: ["AC-005"]
---

# TASK-KAFKAX-003: 手动 offset 提交 + Close 边界 + 无自动提交

- **Module**: kafkax
- **spec_ref**: module/kafkax/SPEC.md#FR-005
- **BR_ref**: module/kafkax/SPEC.md#BR-002 ,module/kafkax/SPEC.md#BR-004 ,module/kafkax/SPEC.md#BR-009
- **ACs**: AC-005
- **Phase**: Core Implementation (Phase 2)
- **Priority**: P0
- **Dependencies**: none
- **Status**: Done

## Scope

实现手动 offset 提交、Close 时最终 offset 边界处理、无自动提交

## Non-Scope

Does NOT implement Kafka broker deployment, topic auto-creation, or Kafka Connect integration. Does NOT implement business event semantics or domain DTOs.

## Files

- `/home/kafkax/pkg/kafkax/kafkago/consumer.go:84` — `Commit(ctx, offsets...)` 手动提交
- `/home/kafkax/pkg/kafkax/kafkago/consumer.go:132` — `Close(ctx)` 资源释放 + ctx 检查
- `/home/kafkax/pkg/kafkax/kafkago/consumer.go:29` — `CommitInterval: 0` 禁用自动提交（BR-002/009）
- `/home/kafkax/pkg/kafkax/consumer.go:14` — `Handler` 接口（Run 模式 Poll→Handle→Commit）

## Acceptance

- [x] FR-005 verified via TC — `go test -race -run="Commit|Close|ManualOffset" ./pkg/kafkax/...`

## Evidence

- 手动提交：`Commit(ctx, offsets...)` 显式提交，未调用不提交 offset（BR-002/009）
- 无自动提交：`ReaderConfig.CommitInterval = 0` 关闭 driver 自动提交
- Close 边界：`Close(ctx)` 检查 ctx 取消，失败返回包装错误不吞错（BR-004）
- 测试：`go test ./pkg/kafkax/` ✅
- 追溯：TRACEABILITY.md FR-005/BR-002/BR-004/BR-009 ✅

## Non-scope

- 不涉及本 Task 范围外的功能
