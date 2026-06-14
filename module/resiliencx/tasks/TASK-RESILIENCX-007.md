# TASK-RESILIENCX-007

> Fallback 实现

---

```yaml
task_id: TASK-RESILIENCX-007
module: resiliencx
scope: "实现 Fallback 策略函数"
non_scope: "不包含 retry/circuit breaker 等复杂策略；不负责业务 fallback 内容"
spec_ref:
  - "module/resiliencx/SPEC.md#FR-006"
files:
  - "fallback.go"
  - "fallback_test.go"
acceptance_criteria:
  - "primary 成功时返回 primary 结果"
  - "primary 失败时执行 secondary 并返回结果"
depends_on:
  - "TASK-RESILIENCX-000"
estimated_effort: "0.5h"
priority: P0
status: pending
```

---

## Non-scope

- 不涉及本 Task 范围外的功能

## Requirements Covered

| Requirement | Description                            | Acceptance Criteria            |
| ----------- | -------------------------------------- | ------------------------------ |
| FR-006      | Fallback：primary 失败时执行 secondary | AC-007: primary成功 / 失败降级 |

## Test Plan

| Test Case | Type | Description                     |
| --------- | ---- | ------------------------------- |
| TC-006    | Unit | primary 成功：返回 primary 结果 |
| TC-006    | Unit | primary 失败：执行 secondary    |

## Implementation Notes

- `Fallback(primary, secondary func() error) error`
- 简单的 try-catch 模式

## Implementation Plan

| Step | Description          | Deliverables       | Verification          |
| ---- | -------------------- | ------------------ | --------------------- |
| 1    | 实现 `Fallback` 函数 | `fallback.go`      | `go build ./...` 通过 |
| 2    | 编写 2 个场景测试    | `fallback_test.go` | TC-006 全部通过       |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| 无   | Low         | Low    | 简单实现   |
