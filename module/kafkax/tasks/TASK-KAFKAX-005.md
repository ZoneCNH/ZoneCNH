# TASK-KAFKAX-005

> Config 校验 + Consumer 配置

---

```yaml
task_id: TASK-KAFKAX-005
module: kafkax
scope: "实现 Consumer 配置校验：max_poll_records/session_timeout/heartbeat_interval"
spec_ref:
  - "module/kafkax/SPEC.md#BR-006"
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
| BR-006 | Config 校验 + Consumer 配置 | TBD |

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
