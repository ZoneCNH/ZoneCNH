# TASK-TESTKITX-008

> BoundaryCheck 实现

---

```yaml
task_id: TASK-TESTKITX-008
module: testkitx
scope: "实现 BoundaryCheck，生产包 import 边界扫描（go list 验证生产依赖图不含 testkitx）"
spec_ref:
  - "module/testkitx/SPEC.md#FR-009"
files:
  - "boundary.go"
  - "boundary_test.go"
acceptance_criteria:
  - "BoundaryCheck 验证 min/max/zero/negative 边界"
  - "失败时输出清晰的错误信息"
depends_on:
  - "TASK-TESTKITX-000"
estimated_effort: "1h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-009 | BoundaryCheck：边界条件验证 | min/max/zero/negative |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Unit | 各边界条件正确检测 |

## Implementation Notes

- `BoundaryCheck(t *testing.T, fn func(v int) error, min, max int)`
- 自动测试 min-1, min, min+1, 0, max-1, max, max+1

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `BoundaryCheck` 函数 | `boundary.go` | 全部测试通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 边界值选择不合理 | Low | Low | 覆盖典型边界 |
