# TASK-RESILIENCX-003

> Retry 实现：指数退避

---

```yaml
task_id: TASK-RESILIENCX-003
module: resiliencx
scope: "实现 Retry 策略，支持指数退避和 max_retries"
non_scope: "不包含 timeout/circuit breaker/bulkhead/rate limiter/fallback 等其他策略"
spec_ref:
  - "module/resiliencx/SPEC.md#FR-002"
  - "module/resiliencx/SPEC.md#BR-001"
files:
  - "retry.go"
  - "retry_test.go"
acceptance_criteria:
  - "首次成功时不重试"
  - "持续失败时按 policy 重试"
  - "达到 max_retries 后返回最后错误"
  - "ctx 取消时立即返回"
depends_on:
  - "TASK-RESILIENCX-000"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Non-scope

- 不涉及本 Task 范围外的功能

## Requirements Covered

| Requirement | Description                            | Acceptance Criteria                              |
| ----------- | -------------------------------------- | ------------------------------------------------ |
| FR-002      | Retry：指数退避、max_retries、ctx 取消 | AC-002: 首次成功 / 持续失败 / 达到上限 / ctx取消 |
| BR-001      | 所有策略必须接受 context.Context       | 函数签名包含 ctx                                 |

## Test Plan

| Test Case | Type | Description                   |
| --------- | ---- | ----------------------------- |
| TC-001    | Unit | 首次成功：不重试              |
| TC-001    | Unit | 持续失败：重试 max_retries 次 |
| TC-001    | Unit | 达到上限：返回最后错误        |
| TC-001    | Unit | ctx 取消：立即返回            |

## Implementation Notes

- RetryPolicy：MaxRetries, InitialWait, MaxWait, Multiplier
- 退避公式：`wait = min(InitialWait * Multiplier^attempt, MaxWait)`
- 每次重试前检查 ctx.Done()

## Implementation Plan

| Step | Description                               | Deliverables    | Verification                              |
| ---- | ----------------------------------------- | --------------- | ----------------------------------------- |
| 1    | 实现 `RetryPolicy` 结构体和验证           | `retry.go`      | `go build ./...` 通过                     |
| 2    | 实现 `Retry` 函数：循环 + 退避 + ctx 检查 | `retry.go`      | TC-001 全部通过                           |
| 3    | 编写完整测试：成功/失败/上限/取消         | `retry_test.go` | `go test -race ./... -run TestRetry` 通过 |

### Risk Assessment

| Risk         | Probability | Impact | Mitigation              |
| ------------ | ----------- | ------ | ----------------------- |
| 退避计算溢出 | Low         | Low    | 使用 `min` 限制 MaxWait |
