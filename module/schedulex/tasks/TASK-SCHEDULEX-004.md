# TASK-SCHEDULEX-004

> Misfire Policy 实现

---

```yaml
task_id: TASK-SCHEDULEX-004
module: schedulex
scope: "实现 MisfirePolicy（Skip/RunOnce/CatchUp）策略"
non_scope: "不实现 Overlap 策略，不修改 Trigger 逻辑"
spec_ref:
  - "module/schedulex/SPEC.md#FR-004"
files:
  - "misfire.go"
  - "misfire_test.go"
acceptance_criteria:
  - "Skip：跳过错过的触发"
  - "RunOnce：补执行一次"
  - "CatchUp：补执行所有错过的次数"
depends_on:
  - "TASK-SCHEDULEX-002"
  - "TASK-SCHEDULEX-011"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description                          | Acceptance Criteria |
| ----------- | ------------------------------------ | ------------------- |
| FR-004      | Misfire Policy：Skip/RunOnce/CatchUp | 3 个 WHEN/THEN 场景 |

## Test Plan

| Test Case | Type | Description         |
| --------- | ---- | ------------------- |
| TC-003    | Unit | Skip：跳过错过触发  |
| TC-003    | Unit | RunOnce：补执行一次 |
| TC-003    | Unit | CatchUp：补执行所有 |

## Implementation Notes

- Skip：直接跳到下一个调度周期
- RunOnce：计算错过的次数，只执行一次
- CatchUp：计算错过的次数，依次执行

## Implementation Plan

| Step | Description       | Deliverables | Verification |
| ---- | ----------------- | ------------ | ------------ |
| 1    | 实现 Skip 策略    | `misfire.go` | §7.4-1 通过  |
| 2    | 实现 RunOnce 策略 | `misfire.go` | §7.4-2 通过  |
| 3    | 实现 CatchUp 策略 | `misfire.go` | §7.4-3 通过  |

### Risk Assessment

| Risk             | Probability | Impact | Mitigation         |
| ---------------- | ----------- | ------ | ------------------ |
| CatchUp 执行风暴 | Medium      | Medium | 限制最大补执行次数 |
