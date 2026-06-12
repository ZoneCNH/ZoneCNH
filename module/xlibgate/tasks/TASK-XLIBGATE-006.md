# TASK-XLIBGATE-006

> check all 实现 + 输出格式

---

```yaml
task_id: TASK-XLIBGATE-006
module: xlibgate
scope: "实现 check all 命令（聚合所有子检查）和统一输出格式"
spec_ref:
  - "module/xlibgate/SPEC.md#FR-005"
  - "module/xlibgate/SPEC.md#FR-006"
files:
  - "check_all.go"
  - "output.go"
  - "check_all_test.go"
acceptance_criteria:
  - "所有子检查通过：exit 0"
  - "任一子检查失败：exit 1"
  - "内部错误：exit 2"
  - "输出格式统一（JSON/text）"
depends_on:
  - "TASK-XLIBGATE-002"
  - "TASK-XLIBGATE-003"
  - "TASK-XLIBGATE-004"
  - "TASK-XLIBGATE-005"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-005 | check all：聚合所有子检查 | 3 个 WHEN/THEN 场景 |
| FR-006 | 输出格式：统一 JSON/text | 格式化输出 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| §7.5-1 | Unit | 全部通过：exit 0 |
| §7.5-2 | Unit | 任一失败：exit 1 |
| §7.5-3 | Unit | 内部错误：exit 2 |

## Implementation Notes

- `check_all` 依次调用 imports/gomod/baseline/release
- `output.go` 统一格式化输出

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `check_all.go`：聚合所有子检查 | `check_all.go` | §7.5 全部通过 |
| 2 | 实现 `output.go`：统一输出格式 | `output.go` | 格式正确 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 子检查执行顺序 | Low | Low | 顺序执行，继续执行所有子检查（BR-006） |
