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
  - "Shutdown 等待正在执行的 job 完成"
  - "超过 ctx deadline 时返回 ctx.Err()（v1.1：专属 ErrShutdownTimeout）"
depends_on:
  - "TASK-SCHEDULEX-002"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Non-scope

- 不涉及本 Task 范围外的功能

## Requirements Covered

| Requirement | Description                  | Acceptance Criteria |
| ----------- | ---------------------------- | ------------------- |
| FR-006      | Shutdown：等待完成或 ctx 超时返回 | 2 个 WHEN/THEN 场景 |

## Test Plan

| Test Case | Type | Description                                   |
| --------- | ---- | --------------------------------------------- |
| TC-006    | Unit | Shutdown 正常：等待 job 完成                  |
| TC-006    | Unit | Shutdown 超时：返回 ctx.Err()（v1.1：ErrShutdownTimeout） |

## Implementation Notes

- `Shutdown(ctx)` 调用内部 cancel 取消主循环
- 使用 `sync.WaitGroup` 等待所有正在执行的 job
- select 等待 WaitGroup 完成或 ctx 超时

## Implementation Plan

| Step | Description                                    | Deliverables   | Verification          |
| ---- | ---------------------------------------------- | -------------- | --------------------- |
| 1    | 实现 `Shutdown`：cancel 主循环 → 等待 WaitGroup | `stop.go`      | `go build ./...` 通过 |
| 2    | 实现超时逻辑：select WaitGroup vs ctx.Done     | `stop.go`      | §8.1 通过             |
| 3    | 编写测试                                       | `stop_test.go` | §8.1 全部通过         |

### Risk Assessment

| Risk               | Probability | Impact | Mitigation   |
| ------------------ | ----------- | ------ | ------------ |
| WaitGroup 计数错误 | Low         | High   | defer Done() |
