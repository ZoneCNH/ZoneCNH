# TASK-RESILIENCX-002

> Timeout 实现

---

```yaml
task_id: TASK-RESILIENCX-002
module: resiliencx
scope: "实现 Timeout 策略函数"
spec_ref:
  - "module/resiliencx/SPEC.md#FR-001"
  - "module/resiliencx/SPEC.md#BR-001"
files:
  - "timeout.go"
  - "timeout_test.go"
acceptance_criteria:
  - "fn 在 duration 内完成时返回 fn 结果"
  - "fn 超时时返回 ErrTimeout"
  - "ctx 取消时返回 ctx.Err()"
depends_on:
  - "TASK-RESILIENCX-000"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-001 | Timeout：超时返回 ErrTimeout | 3 个 WHEN/THEN 场景 |
| BR-001 | 所有策略必须接受 context.Context | 函数签名包含 ctx |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| §7.1-1 | Unit | 正常完成：fn 在 duration 内返回，结果正确 |
| §7.1-2 | Unit | 超时：fn 超过 duration，返回 ErrTimeout |
| §7.1-3 | Unit | ctx 取消：返回 ctx.Err() |

## Implementation Notes

- `Timeout(ctx, d, fn)` 使用 `context.WithTimeout` 创建子 ctx
- 在 goroutine 中执行 fn，通过 channel 收集结果
- select 等待 fn 完成或 ctx 超时

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `Timeout` 函数：WithTimeout + goroutine + select | `timeout.go` | `go build ./...` 通过 |
| 2 | 编写 3 个场景测试 | `timeout_test.go` | §7.1 全部通过 |
| 3 | 并发安全验证 | `timeout_test.go` | `go test -race ./... -run TestTimeout` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| goroutine 泄漏 | Low | High | ctx 超时自动取消 |
