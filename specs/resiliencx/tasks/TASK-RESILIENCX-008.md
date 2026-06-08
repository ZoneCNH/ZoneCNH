# TASK-RESILIENCX-008

> 策略组合：装饰器模式嵌套执行

---

```yaml
task_id: TASK-RESILIENCX-008
module: resiliencx
scope: "实现策略组合功能，支持装饰器模式嵌套执行（timeout+retry+circuit 等）"
spec_ref:
  - "specs/resiliencx/SPEC.md#BR-003"
files:
  - "compose.go"
  - "compose_test.go"
acceptance_criteria:
  - "外层策略包装内层策略"
  - "组合链可任意嵌套"
  - "组合后的 metrics 可分别采集"
depends_on:
  - "TASK-RESILIENCX-002"
  - "TASK-RESILIENCX-003"
  - "TASK-RESILIENCX-004"
  - "TASK-RESILIENCX-005"
  - "TASK-RESILIENCX-006"
  - "TASK-RESILIENCX-007"
estimated_effort: "2h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| BR-003 | 策略组合时外层包装内层（装饰器模式） | 嵌套执行正确 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Unit | timeout(retry(fn))：重试在超时内执行 |
| — | Unit | retry(circuit(fn))：熔断时重试停止 |
| — | Unit | 多层嵌套：timeout(retry(circuit(fn))) |

## Implementation Notes

- 组合通过函数嵌套实现，不需要额外接口
- 每个策略函数接受 `func(ctx) error` 并返回 `func(ctx) error`
- 示例：`composed := Timeout(d, Retry(policy, CircuitBreaker(cb).Execute)(fn))`

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 创建 `compose.go`，提供 `Chain` 辅助函数 | `compose.go` | `go build ./...` 通过 |
| 2 | 编写组合测试：timeout+retry, retry+circuit | `compose_test.go` | 所有组合场景通过 |
| 3 | 编写三层嵌套测试 | `compose_test.go` | 多层嵌套正确 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 组合顺序影响行为 | Medium | Medium | 文档说明推荐顺序 |
