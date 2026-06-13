# TASK-TAOSX-002

> Exec + Query

---

```yaml
task_id: TASK-TAOSX-002
module: taosx
scope: "SQL 执行接口：非空校验、context 传播、Rows 迭代"
spec_ref:
  - "module/taosx/SPEC.md#FR-004"
  - "module/taosx/SPEC.md#FR-005"
  - "module/taosx/SPEC.md#BR-002"
files:
  - (implementation files)
acceptance_criteria:
  - "All related FRs verified via TC"
depends_on: []
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|-------------|-------------|---------------------|
| FR-004 | Exec + Query | TBD |
| FR-005 | Exec + Query | TBD |
| BR-002 | Exec + Query | TBD |

## Non-scope

- 不超出本 Task FR 范围
- 不实现其他 Task 的 FR

## Test Plan

| Test Case | Type | Description |
|-----------|------|-------------|
| TBD | Unit | TBD |

## Implementation Notes

- 遵循 taosx SPEC.md 规范
- 使用 kernel/observex 通过接口注入
- 不直接依赖 configx
