# TASK-KAFKAX-002

> Consumer.Subscribe + Poll

---

```yaml
task_id: TASK-KAFKAX-002
module: kafkax
scope: "实现 Consumer 接口：Subscribe 消费组加入、Poll 阻塞拉取、ctx 超时取消"
spec_ref:
  - "module/kafkax/SPEC.md#FR-003"
  - "module/kafkax/SPEC.md#FR-004"
  - "module/kafkax/SPEC.md#BR-003"
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
| FR-003 | Consumer.Subscribe + Poll | TBD |
| FR-004 | Consumer.Subscribe + Poll | TBD |
| BR-003 | Consumer.Subscribe + Poll | TBD |

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
