# TASK-TESTKITX-006

> Eventually 实现

---

```yaml
task_id: TASK-TESTKITX-006
module: testkitx
scope: "实现 Eventually 断言函数，轮询条件直到满足或超时"
non_scope: "不实现异步断言框架，不替代 testing.T"
spec_ref:
  - "module/testkitx/SPEC.md#FR-007"
  - "module/testkitx/SPEC.md#BR-003"
files:
  - "eventually.go"
  - "eventually_test.go"
acceptance_criteria:
  - "AC-007: fn 在 timeout 内返回 true → 通过"
  - "AC-007: fn 超时仍 false → fail + 清晰诊断"
  - "BR-003: 使用 testing.T 而非 panic"
depends_on:
  - "TASK-TESTKITX-000"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Non-scope

- 不涉及本 Task 范围外的功能

## Requirements Covered

| Requirement | Description              | Acceptance Criteria |
| ----------- | ------------------------ | ------------------- |
| FR-007      | Eventually：轮询条件断言 | AC-007              |
| BR-003      | 使用 testing.T 报告失败  | eventually_test.go  |

## Test Plan

| Test Case | Type | Description           |
| --------- | ---- | --------------------- |
| TC-007    | Unit | 条件立即满足：通过    |
| TC-007    | Unit | 条件延迟满足：通过    |
| TC-007    | Unit | 超时：fail + 清晰诊断 |

## Implementation Notes

- `Eventually(t *testing.T, fn func() bool, opts ...Option)`
- 默认 timeout=5s，interval=100ms
- 使用 `time.Ticker` 轮询

## Implementation Plan

| Step | Description                           | Deliverables    | Verification |
| ---- | ------------------------------------- | --------------- | ------------ |
| 1    | 实现 `Eventually` 函数                | `eventually.go` | 全部测试通过 |
| 2    | 实现 Option：WithTimeout/WithInterval | `eventually.go` | 配置生效     |

### Risk Assessment

| Risk       | Probability | Impact | Mitigation       |
| ---------- | ----------- | ------ | ---------------- |
| 测试不稳定 | Medium      | Low    | 合理默认 timeout |
