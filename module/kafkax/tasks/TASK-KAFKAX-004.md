---
scope: "TASK-KAFKAX-004: 幂等 Health + sanitized errors"
acceptance_criteria: ["AC-006"]
---

# TASK-KAFKAX-004: 幂等 Health + sanitized errors

- **Module**: kafkax
- **spec_ref**: module/kafkax/SPEC.md#FR-006
- **BR_ref**: module/kafkax/SPEC.md#BR-007 ,module/kafkax/SPEC.md#BR-008
- **ACs**: AC-006
- **Phase**: Core Implementation (Phase 2)
- **Priority**: P0
- **Dependencies**: none
- **Status**: Done

## Scope

实现幂等 Health 检查、错误消息不含 payload、sanitized errors

## Non-Scope

Does NOT implement Kafka broker deployment, topic auto-creation, or Kafka Connect integration. Does NOT implement business event semantics or domain DTOs.

## Files

- `/home/kafkax/pkg/kafkax/health.go:25` — `HealthCheck(ctx) HealthStatus`（幂等、无副作用）
- `/home/kafkax/pkg/kafkax/health.go:141,153` — health metric/gauge 上报
- `/home/kafkax/pkg/kafkax/health_golden_test.go` / `health_test.go` — golden + 单测
- `/home/kafkax/pkg/kafkax/config.go:70` — `Config.Sanitize()` 脱敏（Password/Token → [REDACTED]）
- `/home/kafkax/internal/sanitize/sanitize.go` + `sanitize_test.go` — 脱敏工具
- `/home/kafkax/pkg/kafkax/errors.go` — Error{Kind,Op,Message,Cause,Retryable}，Message 不含 payload

## Acceptance

- [x] FR-006 verified via TC — `go test -race -run="Health|Sanitize" ./pkg/kafkax/...`

## Evidence

- 幂等健康检查：`HealthCheck` 只读，返回 healthy/degraded/unhealthy + LatencyMs（BR-007）
- 脱敏：`Config.Sanitize()` 替换 Secret/Password/Token；Error.Message 只含 topic/op/kind 摘要（BR-008）
- 测试：`go test ./pkg/kafkax/ ./internal/sanitize/` ✅（含 golden test）
- 追溯：TRACEABILITY.md FR-006/BR-007/BR-008 ✅

## Non-scope

- 不涉及本 Task 范围外的功能
