# TASK-SCHEDULEX-001

> 接口定义：Scheduler、Job、Trigger

---

```yaml
task_id: TASK-SCHEDULEX-001
module: schedulex
scope: "定义 Scheduler 接口、Job 结构体、Trigger 类型"
non_scope: "不定义策略枚举和辅助接口（参见 TASK-011），不实现任何方法"
spec_ref:
  - "module/schedulex/SPEC.md#FR-001"
  - "module/schedulex/SPEC.md#FR-002"
files:
  - "scheduler.go"
  - "job.go"
  - "trigger.go"
acceptance_criteria:
  - "Scheduler 接口包含 Schedule/Cancel/List/Start/Stop 方法"
  - "Job 结构体包含 ID/Name/Trigger/Handler/Timeout/MaxRetries/Overlap/Misfire 字段"
  - "Trigger 支持 Cron/Interval/Delay 三种类型，cron 与 interval 互斥"
  - "go build ./... 编译通过"
depends_on:
  - "TASK-SCHEDULEX-000"
estimated_effort: "0.5h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-001 | Schedule：Job 注册结构定义 | Job 结构体字段与 SPEC §9.2 一致 |
| FR-002 | Trigger：cron/interval/delay 类型定义 | Trigger 类型支持三种触发方式 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Compile | 接口完整性编译验证 |

## Implementation Notes

- `Scheduler` 接口：Schedule/Cancel/List/Start/Stop
- `Job` 结构体：ID/Name/Trigger/Handler/Timeout/MaxRetries/Overlap/Misfire
- `Trigger` 类型：Cron string 或 Interval time.Duration，互斥；Delay 可选首次延迟

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 定义 `Scheduler` 接口 | `scheduler.go` | `go build ./...` 通过 |
| 2 | 定义 `Job` 结构体 | `job.go` | `go build ./...` 通过 |
| 3 | 定义 `Trigger` 类型和验证逻辑 | `trigger.go` | `go build ./...` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Trigger 类型设计不合理 | Low | Medium | 支持 cron 和 interval 两种，互斥校验 |
