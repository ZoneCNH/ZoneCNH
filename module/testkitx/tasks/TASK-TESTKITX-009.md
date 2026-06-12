# TASK-TESTKITX-009

> GoroutineLeakCheck 实现

---

```yaml
task_id: TASK-TESTKITX-009
module: testkitx
scope: "实现 GoroutineLeakCheck，检测测试中的 goroutine 泄漏"
non_scope: "不分析 goroutine 根因，不自动修复泄漏"
spec_ref:
  - "module/testkitx/SPEC.md#FR-010"
files:
  - "leakcheck.go"
  - "leakcheck_test.go"
acceptance_criteria:
  - "AC-010: 测试后无新增 goroutine → pass"
  - "AC-010: 有泄漏 → fail + 输出 goroutine 堆栈"
depends_on:
  - "TASK-TESTKITX-000"
estimated_effort: "1h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description                            | Acceptance Criteria |
| ----------- | -------------------------------------- | ------------------- |
| FR-010      | GoroutineLeakCheck：goroutine 泄漏检测 | AC-010              |

## Test Plan

| Test Case | Type | Description             |
| --------- | ---- | ----------------------- |
| TC-010    | Unit | 无泄漏：通过            |
| TC-010    | Unit | 有泄漏：fail 并输出堆栈 |

## Implementation Notes

- `GoroutineLeakCheck(t *testing.T)` 在 t.Cleanup 中注册
- 记录测试开始时的 goroutine 数
- 测试结束后比较，差异 > 0 则 fail

## Implementation Plan

| Step | Description                    | Deliverables   | Verification |
| ---- | ------------------------------ | -------------- | ------------ |
| 1    | 实现 `GoroutineLeakCheck` 函数 | `leakcheck.go` | 全部测试通过 |

### Risk Assessment

| Risk                      | Probability | Impact | Mitigation   |
| ------------------------- | ----------- | ------ | ------------ |
| 误报（runtime goroutine） | Low         | Low    | 允许少量差异 |
