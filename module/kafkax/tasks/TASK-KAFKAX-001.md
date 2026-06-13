# TASK-KAFKAX-001

> Producer.Send + SendBatch

---

```yaml
task_id: TASK-KAFKAX-001
module: kafkax
scope: "实现 Producer 接口：Send 单条发送、SendBatch 批量发送、acks=all 同步确认、重试策略"
spec_ref:
  - "module/kafkax/SPEC.md#FR-001"
  - "module/kafkax/SPEC.md#FR-002"
  - "module/kafkax/SPEC.md#BR-001"
  - "module/kafkax/SPEC.md#BR-005"
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
| FR-001 | Producer.Send + SendBatch | TBD |
| FR-002 | Producer.Send + SendBatch | TBD |
| BR-001 | Producer.Send + SendBatch | TBD |
| BR-005 | Producer.Send + SendBatch | TBD |

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
