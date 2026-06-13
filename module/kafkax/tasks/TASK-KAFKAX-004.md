# TASK-KAFKAX-004

> Health + 错误脱敏

---

```yaml
task_id: TASK-KAFKAX-004
module: kafkax
scope: "实现幂等 Health 检查、错误消息不含 payload、sanitized errors"
spec_ref:
  - "module/kafkax/SPEC.md#FR-006"
  - "module/kafkax/SPEC.md#BR-007"
  - "module/kafkax/SPEC.md#BR-008"
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
| FR-006 | Health + 错误脱敏 | TBD |
| BR-007 | Health + 错误脱敏 | TBD |
| BR-008 | Health + 错误脱敏 | TBD |

## Non-scope

- 不超出本 Task FR 范围
- 不实现其他 Task 的 FR

## Test Plan

| Test Case | Type | Description |
|-----------|------|-------------|
| TBD | Unit | TBD |

## Implementation Notes

- 遵循 kafkax SPEC.md 规范
- 使用 kernel/observex 通过接口注入
- 不直接依赖 configx
