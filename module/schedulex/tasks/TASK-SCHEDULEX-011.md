# TASK-SCHEDULEX-011

> 接口定义：OverlapPolicy、MisfirePolicy、EventSink、Locker、Clock

---

```yaml
task_id: TASK-SCHEDULEX-011
module: schedulex
scope: "定义 OverlapPolicy/MisfirePolicy 枚举、EventSink/Locker/Clock 接口"
non_scope: "不实现任何方法，不引入存储/网络依赖，不定义 Scheduler/Job/Trigger（参见 TASK-001）"
spec_ref:
  - "module/schedulex/SPEC.md#FR-003"
  - "module/schedulex/SPEC.md#FR-004"
  - "module/schedulex/SPEC.md#FR-007"
  - "module/schedulex/SPEC.md#FR-008"
  - "module/schedulex/SPEC.md#FR-009"
files:
  - "policy.go"
  - "event.go"
  - "locker.go"
  - "clock.go"
acceptance_criteria:
  - "OverlapPolicy 枚举：Skip/Queue/Replace"
  - "MisfirePolicy 枚举：Skip/RunOnce/CatchUp"
  - "EventSink 回调接口签名与 SPEC §9.4 一致"
  - "Locker 接口包含 Acquire/Release 方法"
  - "Clock 接口包含 Now/After 方法"
  - "go build ./... 编译通过"
depends_on:
  - "TASK-SCHEDULEX-001"
estimated_effort: "0.5h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description            | Acceptance Criteria                     |
| ----------- | ---------------------- | --------------------------------------- |
| FR-003      | OverlapPolicy 枚举定义 | Skip/Queue/Replace 三种策略常量         |
| FR-004      | MisfirePolicy 枚举定义 | Skip/RunOnce/CatchUp 三种策略常量       |
| FR-007      | EventSink 回调接口     | JobEvent/JobEventData/JobEventType 类型 |
| FR-008      | Locker 分布式锁接口    | Acquire/Release 方法签名                |
| FR-009      | Clock 可注入时钟接口   | Now/After 方法签名                      |

## Test Plan

| Test Case | Type    | Description             |
| --------- | ------- | ----------------------- |
| —         | Compile | 接口/枚举完整性编译验证 |

## Implementation Notes

- OverlapPolicy iota：Skip=0, Queue=1, Replace=2
- MisfirePolicy iota：Skip=0, RunOnce=1, CatchUp=2
- JobEventType iota：Triggered/Started/Completed/Failed/Misfired/Skipped
- Locker 接口：Acquire(ctx, key, ttl) (bool, error) / Release(ctx, key) error
- Clock 接口：Now() time.Time / After(d time.Duration) <-chan time.Time

## Implementation Plan

| Step | Description                            | Deliverables | Verification          |
| ---- | -------------------------------------- | ------------ | --------------------- |
| 1    | 定义 OverlapPolicy/MisfirePolicy 枚举  | `policy.go`  | `go build ./...` 通过 |
| 2    | 定义 EventSink 回调类型和 JobEventData | `event.go`   | `go build ./...` 通过 |
| 3    | 定义 Locker 接口                       | `locker.go`  | `go build ./...` 通过 |
| 4    | 定义 Clock 接口                        | `clock.go`   | `go build ./...` 通过 |

### Risk Assessment

| Risk                 | Probability | Impact | Mitigation                |
| -------------------- | ----------- | ------ | ------------------------- |
| 枚举值与 SPEC 不一致 | Low         | Medium | 对照 SPEC §9 常量定义验证 |
