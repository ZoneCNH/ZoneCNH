# TASK-SCHEDULEX-005

> Stop 实现：graceful shutdown

---

```yaml
task_id: TASK-SCHEDULEX-005
module: schedulex
scope: "实现 Stop 方法，支持 graceful shutdown 和 deadline 超时"
non_scope: "不实现 Start 主循环逻辑，不处理 Overlap/Misfire 策略"
spec_ref:
  - "module/schedulex/SPEC.md#FR-006"
files:
  - "stop.go"
  - "stop_test.go"
acceptance_criteria:
  - "Stop 等待正在执行的 job 完成"
  - "超过 deadline 时强制取消，返回 ErrShutdownTimeout"
depends_on:
  - "TASK-SCHEDULEX-002"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-006 | Stop：等待完成或超时强制取消 | 2 个 WHEN/THEN 场景 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-006 | Unit | Stop 正常：等待 job 完成 |
| TC-006 | Unit | Stop 超时：强制取消，ErrShutdownTimeout |

## Implementation Notes

- `Stop(ctx)` 调用内部 cancel 取消主循环
- 使用 `sync.WaitGroup` 等待所有正在执行的 job
- select 等待 WaitGroup 完成或 ctx 超时

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `Stop`：cancel 主循环 → 等待 WaitGroup | `stop.go` | `go build ./...` 通过 |
| 2 | 实现超时逻辑：select WaitGroup vs ctx.Done | `stop.go` | §7.6-2 通过 |
| 3 | 编写测试 | `stop_test.go` | §7.6 全部通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| WaitGroup 计数错误 | Low | High | defer Done() |
