# TASK-NATSX-002

> Core NATS: Request + 超时

---

```yaml
task_id: TASK-NATSX-002
module: natsx
scope: "Request-Reply 模式：responder、timeout、ctx cancel"
spec_ref:
  - "module/natsx/SPEC.md#FR-003"
  - "module/natsx/SPEC.md#BR-003"
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
| FR-003 | Core NATS: Request + 超时 | TBD |
| BR-003 | Core NATS: Request + 超时 | TBD |

## Non-scope

- 不超出本 Task FR 范围
- 不实现其他 Task 的 FR

## Test Plan

| Test Case | Type | Description |
|-----------|------|-------------|
| TBD | Unit | TBD |

## Implementation Notes

- 遵循 natsx SPEC.md 规范
- 使用 kernel/observex 通过接口注入
- 不直接依赖 configx
