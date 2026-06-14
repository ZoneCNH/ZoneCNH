# TASK-OBSERVEX-003b

> Label Policy 实现：AllowedLabels/ForbiddenLabels 检查 + 并发安全

---

```yaml
task_id: TASK-OBSERVEX-003b
module: observex
scope: "实现 label policy 检查：AllowedLabels 允许通过，ForbiddenLabels 拒绝并返回错误"
spec_ref:
  - "module/observex/SPEC.md#FR-006"
files:
  - "label_policy.go"
  - "label_policy_test.go"
acceptance_criteria:
  - "AllowedLabels 中的 label 允许通过"
  - "ForbiddenLabels 中的 label 返回 ErrLabelForbidden"
  - "label policy 并发调用安全"
depends_on:
  - "TASK-OBSERVEX-002"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Non-scope

- 不涉及本 Task 范围外的功能

## Requirements Covered

| Requirement | Description                                | Acceptance Criteria |
| ----------- | ------------------------------------------ | ------------------- |
| FR-006      | Label Policy：Allowed 允许，Forbidden 拒绝 | 2 个 WHEN/THEN 场景 |

## Test Plan

| Test Case | Type | Description                                                  |
| --------- | ---- | ------------------------------------------------------------ |
| TC-002    | Unit | Label Policy 拒绝高基数：ForbiddenLabels 中的 label 返回错误 |
| —         | Unit | AllowedLabels 中的 label 允许通过                            |
| —         | Unit | 并发调用安全（`-race` 通过）                                 |

## Implementation Notes

- label policy checker 在每次 Add/Record/Set 前检查 attrs
- 使用 `sync.RWMutex` 保护策略配置的并发读写
- 策略配置可通过 `SetPolicy` 动态更新

## Implementation Plan

| Step | Description                                                | Deliverables      | Verification                              |
| ---- | ---------------------------------------------------------- | ----------------- | ----------------------------------------- |
| 1    | 实现 `label_policy.go`：AllowedLabels/ForbiddenLabels 检查 | `label_policy.go` | `go test ./... -run TestLabelPolicy` 通过 |
| 2    | 实现并发安全：RWMutex 保护策略读写                         | `label_policy.go` | `go test ./... -race` 通过                |

### Risk Assessment

| Risk                  | Probability | Impact | Mitigation         |
| --------------------- | ----------- | ------ | ------------------ |
| label policy 过于严格 | Low         | Medium | 提供配置项放宽限制 |
