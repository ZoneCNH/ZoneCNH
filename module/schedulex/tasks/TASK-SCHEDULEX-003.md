# TASK-SCHEDULEX-003

> Overlap Policy 实现

---

```yaml
task_id: TASK-SCHEDULEX-003
module: schedulex
scope: "实现 OverlapPolicy（Skip/Queue/Replace）策略"
spec_ref:
  - "module/schedulex/SPEC.md#FR-003"
files:
  - "overlap.go"
  - "overlap_test.go"
acceptance_criteria:
  - "Skip：上次未完成时跳过本次"
  - "Queue：上次未完成时排队等待"
  - "Replace：上次未完成时取消旧的启动新的"
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
| FR-003 | Overlap Policy：Skip/Queue/Replace | 3 个 WHEN/THEN 场景 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| §7.3-1 | Unit | Skip：上次未完成时跳过 |
| §7.3-2 | Unit | Queue：排队等待 |
| §7.3-3 | Unit | Replace：取消旧的启动新的 |

## Implementation Notes

- Skip：检查 `running` flag，true 则跳过
- Queue：使用 channel 排队
- Replace：取消旧 ctx，创建新 ctx

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 Skip 策略 | `overlap.go` | §7.3-1 通过 |
| 2 | 实现 Queue 策略 | `overlap.go` | §7.3-2 通过 |
| 3 | 实现 Replace 策略 | `overlap.go` | §7.3-3 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Replace 取消旧任务竞态 | Medium | Medium | atomic 操作 + ctx |
