# TASK-RESILIENCX-006

> RateLimiter 实现：令牌桶

---

```yaml
task_id: TASK-RESILIENCX-006
module: resiliencx
scope: "实现 RateLimiter 接口，支持令牌桶限流"
non_scope: "不包含 circuit breaker/bulkhead/retry 等其他策略"
spec_ref:
  - "module/resiliencx/SPEC.md#FR-005"
  - "module/resiliencx/SPEC.md#BR-005"
files:
  - "ratelimiter.go"
  - "ratelimiter_impl.go"
  - "ratelimiter_test.go"
acceptance_criteria:
  - "Allow() 在速率 < max_rate 时返回 true"
  - "Allow() 在速率 >= max_rate 时返回 false"
  - "Wait(ctx) 阻塞直到允许或 ctx 超时"
  - "并发安全"
depends_on:
  - "TASK-RESILIENCX-001"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Non-scope

- 不涉及本 Task 范围外的功能

## Requirements Covered

| Requirement | Description                      | Acceptance Criteria               |
| ----------- | -------------------------------- | --------------------------------- |
| FR-005      | RateLimiter：Allow/Wait + 令牌桶 | AC-006: Allow/Wait正确 & 并发安全 |
| BR-005      | 限流器必须并发安全               | `-race` 测试通过                  |

## Test Plan

| Test Case | Type | Description             |
| --------- | ---- | ----------------------- |
| TC-005    | Unit | Allow：速率内返回 true  |
| TC-005    | Unit | Allow：速率满返回 false |
| TC-005    | Unit | Wait：阻塞直到允许      |
| —         | Unit | 并发安全                |

## Implementation Notes

- 令牌桶算法：固定速率补充令牌，每次 Allow 消耗一个
- 使用 `time.Ticker` 定期补充
- `sync.Mutex` 保护桶状态

## Implementation Plan

| Step | Description                                       | Deliverables          | Verification                                    |
| ---- | ------------------------------------------------- | --------------------- | ----------------------------------------------- |
| 1    | 实现 `rateLimiterImpl`（tokens, max, ticker, mu） | `ratelimiter_impl.go` | `go build ./...` 通过                           |
| 2    | 实现 `Allow`：检查令牌 → 消耗 → 返回              | `ratelimiter_impl.go` | TC-005, TC-005 通过                             |
| 3    | 实现 `Wait`：循环 Allow + sleep + ctx 检查        | `ratelimiter_impl.go` | TC-005 通过                                     |
| 4    | 并发安全验证                                      | `ratelimiter_test.go` | `go test -race ./... -run TestRateLimiter` 通过 |

### Risk Assessment

| Risk         | Probability | Impact | Mitigation       |
| ------------ | ----------- | ------ | ---------------- |
| 令牌补充精度 | Low         | Low    | 使用 time.Ticker |
