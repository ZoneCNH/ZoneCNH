# TASK-SCHEDULEX-001

> 接口定义：Scheduler、Job、Trigger、OverlapPolicy、MisfirePolicy、EventSink、Locker、Clock

---

```yaml
task_id: TASK-SCHEDULEX-001
module: schedulex
scope: "定义 Scheduler 接口、Job 结构体、Trigger 类型、策略枚举和辅助接口"
spec_ref:
  - "specs/schedulex/SPEC.md#9"
files:
  - "scheduler.go"
  - "job.go"
  - "trigger.go"
  - "policy.go"
  - "event.go"
  - "locker.go"
  - "clock.go"
acceptance_criteria:
  - "Scheduler 接口包含 Schedule/Cancel/Start/Stop 方法"
  - "Job 结构体包含 ID/Handler/Trigger/OverlapPolicy/MisfirePolicy 字段"
  - "Trigger 支持 cron 和 interval 两种类型"
  - "go build ./... 编译通过"
depends_on:
  - "TASK-SCHEDULEX-000"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| §9 | 接口契约 | 所有接口签名与 SPEC 一致 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Compile | 接口完整性编译验证 |

## Implementation Notes

- Trigger 类型：`Cron string` 或 `Interval time.Duration`，互斥
- OverlapPolicy 枚举：Skip/Queue/Replace
- MisfirePolicy 枚举：Skip/RunOnce/CatchUp
- JobEvent 结构体：JobID/Event/Time/Error

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 定义 `Scheduler` 接口和 `Job` 结构体 | `scheduler.go`, `job.go` | `go build ./...` 通过 |
| 2 | 定义 `Trigger` 类型和解析逻辑 | `trigger.go` | `go build ./...` 通过 |
| 3 | 定义 `OverlapPolicy`/`MisfirePolicy` 枚举 | `policy.go` | `go build ./...` 通过 |
| 4 | 定义 `EventSink`/`Locker`/`Clock` 接口 | `event.go`, `locker.go`, `clock.go` | `go build ./...` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Trigger 类型设计不合理 | Low | Medium | 支持 cron 和 interval 两种 |
