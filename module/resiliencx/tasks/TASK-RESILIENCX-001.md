# TASK-RESILIENCX-001

> 接口定义：CircuitBreaker、Bulkhead、RateLimiter、Option 类型

---

```yaml
task_id: TASK-RESILIENCX-001
module: resiliencx
scope: "定义 CircuitBreaker、Bulkhead、RateLimiter 接口及 Option 类型"
non_scope: "不包含具体实现逻辑，仅定义接口签名和类型枚举"
spec_ref:
  - "module/resiliencx/SPEC.md#9"
files:
  - "circuit.go"
  - "bulkhead.go"
  - "ratelimiter.go"
  - "options.go"
acceptance_criteria:
  - "CircuitBreaker 接口包含 Execute/State 方法"
  - "Bulkhead 接口包含 Execute/Available 方法"
  - "RateLimiter 接口包含 Allow/Wait 方法"
  - "go build ./... 编译通过"
depends_on:
  - "TASK-RESILIENCX-000"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Non-scope

- 不涉及本 Task 范围外的功能

## Requirements Covered

| Requirement | Description         | Acceptance Criteria               |
| ----------- | ------------------- | --------------------------------- |
| §9.3        | CircuitBreaker 接口 | Execute/State + CircuitState 枚举 |
| §9.4        | Bulkhead 接口       | Execute/Available                 |
| §9.5        | RateLimiter 接口    | Allow/Wait                        |

## Test Plan

| Test Case | Type    | Description        |
| --------- | ------- | ------------------ |
| —         | Compile | 接口完整性编译验证 |

## Implementation Notes

- CircuitState 枚举：CircuitClosed=0, CircuitOpen=1, CircuitHalfOpen=2
- CircuitOption/BulkheadOption/RateLimiterOption 函数类型
- 接口在各自文件中定义，避免单文件过大

## Implementation Plan

| Step | Description                                                           | Deliverables     | Verification          |
| ---- | --------------------------------------------------------------------- | ---------------- | --------------------- |
| 1    | 定义 `CircuitBreaker` 接口、`CircuitState` 枚举、`CircuitOption` 类型 | `circuit.go`     | `go build ./...` 通过 |
| 2    | 定义 `Bulkhead` 接口和 `BulkheadOption` 类型                          | `bulkhead.go`    | `go build ./...` 通过 |
| 3    | 定义 `RateLimiter` 接口和 `RateLimiterOption` 类型                    | `ratelimiter.go` | `go build ./...` 通过 |
| 4    | 定义通用 Option 类型和配置结构                                        | `options.go`     | `go build ./...` 通过 |

### Risk Assessment

| Risk                 | Probability | Impact | Mitigation        |
| -------------------- | ----------- | ------ | ----------------- |
| 接口签名与下游不匹配 | Medium      | High   | 对照 SPEC §9 确认 |
