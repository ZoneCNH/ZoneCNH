# TASK-TAOSX-001

> Config + NewClient

---

```yaml
task_id: TASK-TAOSX-001
module: taosx
scope: "Config.Normalize/Validate、NewClient 工厂、driver 注入"
spec_ref:
  - "module/taosx/SPEC.md#FR-001"
  - "module/taosx/SPEC.md#FR-002"
  - "module/taosx/SPEC.md#FR-003"
  - "module/taosx/SPEC.md#BR-001"
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
| FR-001 | Config + NewClient | TBD |
| FR-002 | Config + NewClient | TBD |
| FR-003 | Config + NewClient | TBD |
| BR-001 | Config + NewClient | TBD |

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
