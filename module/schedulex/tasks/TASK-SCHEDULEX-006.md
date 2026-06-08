# TASK-SCHEDULEX-006

> EventSink 实现

---

```yaml
task_id: TASK-SCHEDULEX-006
module: schedulex
scope: "实现 EventSink，支持 job 生命周期事件回调"
spec_ref:
  - "module/schedulex/SPEC.md#FR-007"
files:
  - "event_impl.go"
  - "event_test.go"
acceptance_criteria:
  - "job 触发/开始/完成/失败/misfire 时调用注册的回调"
  - "多个 EventSink 可同时注册"
depends_on:
  - "TASK-SCHEDULEX-001"
estimated_effort: "1h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-007 | EventSink：job 事件回调 | 触发/开始/完成/失败/misfire |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| §7.7-1 | Unit | 事件触发时回调被调用 |
| — | Unit | 多个 sink 同时收到事件 |

## Implementation Notes

- `eventBus` 内部维护 `[]JobEventHandler` 列表
- `emit(event JobEvent)` 遍历所有 handler 调用

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `eventBus`：注册 handler + emit | `event_impl.go` | `go build ./...` 通过 |
| 2 | 集成到 scheduler：job 生命周期 emit 事件 | `scheduler_impl.go` | §7.7-1 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| handler panic 影响调度 | Low | High | recover handler panic |
