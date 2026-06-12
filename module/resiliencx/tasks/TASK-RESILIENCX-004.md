# TASK-RESILIENCX-004

> CircuitBreaker 实现：三态转换

---

```yaml
task_id: TASK-RESILIENCX-004
module: resiliencx
scope: "实现 CircuitBreaker 接口，支持 Closed/Open/Half-Open 三态转换"
non_scope: "不包含 retry/rate limiter/bulkhead/fallback 等其他策略"
spec_ref:
  - "module/resiliencx/SPEC.md#FR-003"
  - "module/resiliencx/SPEC.md#BR-004"
files:
  - "circuit.go"
  - "circuit_impl.go"
  - "circuit_test.go"
acceptance_criteria:
  - "Closed 状态下执行 fn 并计数成功/失败"
  - "失败率超 threshold 且连续失败超 min_failures 时转 Open"
  - "Open 状态下立即返回 ErrCircuitOpen"
  - "recovery_timeout 后转 Half-Open，允许一次试探"
  - "试探成功转 Closed，失败保持 Open"
  - "并发安全"
depends_on:
  - "TASK-RESILIENCX-001"
estimated_effort: "3h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description                         | Acceptance Criteria                    |
| ----------- | ----------------------------------- | -------------------------------------- |
| FR-003      | CircuitBreaker：三态转换 + 试探调用 | AC-003: 三态转换正确; AC-004: 并发安全 |
| BR-004      | 熔断器状态必须并发安全              | `-race` 测试通过                       |

## Test Plan

| Test Case | Type | Description                         |
| --------- | ---- | ----------------------------------- |
| TC-002    | Unit | Closed→Open：失败率超阈值           |
| TC-003    | Unit | Open→Half-Open：recovery_timeout 后 |
| TC-003    | Unit | Half-Open→Closed：试探成功          |
| TC-003    | Unit | Half-Open→Open：试探失败            |
| —         | Unit | 并发安全：多 goroutine 同时 Execute |

## Implementation Notes

- 内部使用 `sync.RWMutex` 保护状态
- 记录连续失败次数和总失败率
- Half-Open 状态只允许一个试探调用（atomic CAS）

## Implementation Plan

| Step | Description                                                        | Deliverables      | Verification                                |
| ---- | ------------------------------------------------------------------ | ----------------- | ------------------------------------------- |
| 1    | 实现 `circuitBreakerImpl` 结构体（state, failures, threshold, mu） | `circuit_impl.go` | `go build ./...` 通过                       |
| 2    | 实现 `Execute`：Closed→执行→计数；Open→ErrCircuitOpen              | `circuit_impl.go` | TC-002, TC-003 通过                         |
| 3    | 实现 Half-Open 试探逻辑和状态转换                                  | `circuit_impl.go` | TC-003, TC-003 通过                         |
| 4    | 并发安全验证                                                       | `circuit_test.go` | `go test -race ./... -run TestCircuit` 通过 |

### Risk Assessment

| Risk         | Probability | Impact | Mitigation         |
| ------------ | ----------- | ------ | ------------------ |
| 状态转换竞态 | Medium      | High   | atomic CAS + mutex |
