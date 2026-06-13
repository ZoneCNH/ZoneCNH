# TASK-CONTRACTS-002

> Event 接口 + Topic 常量 + DTO 契约

---

```yaml
task_id: TASK-CONTRACTS-002
module: contracts
scope: "定义 Event 接口、Topic 常量和 DTO 契约"
spec_ref:
  - "module/contracts/SPEC.md#FR-003"
  - "module/contracts/SPEC.md#FR-004"
  - "module/contracts/SPEC.md#FR-005"
  - "module/contracts/SPEC.md#BR-001"
  - "module/contracts/SPEC.md#BR-005"
  - "module/contracts/SPEC.md#BR-006"
  - "module/contracts/SPEC.md#BR-009"
files:
  - "event.go"
  - "event_test.go"
  - "topic.go"
  - "topic_test.go"
  - "dto.go"
acceptance_criteria:
  - "Event 接口包含 EventID/EventType/Timestamp/Source 方法"
  - "Topic 常量覆盖所有事件类型"
  - "DTO 结构体定义完整"
depends_on:
  - "TASK-CONTRACTS-000"
estimated_effort: "1h"
priority: P0
status: pending
non_scope:
  - "不实现具体Event类型"
  - "不实现MQ发布逻辑（→kafkax）"
  - "不定义数据端口（→TASK-001）"
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria    |
| ----------- | ----------- | ---------------------- |
| FR-003      | Event 接口  | EventID/EventType/Timestamp/Source |
| FR-004      | Topic 常量  | 所有事件类型           |
| FR-005      | DTO 契约    | 结构体定义完整         |

## Test Plan

| Test Case | Type    | Description        |
| --------- | ------- | ------------------ |
| TC-002    | Unit | DTO JSON round-trip |
| TC-004    | Unit | Topic唯一性检查 |
| TC-005    | Unit | Event接口完整性 |
| TC-007    | Unit | DTO不可变性检查 |

## Implementation Notes

- Topic 常量使用 `const` 定义
- DTO 使用标准 Go 结构体

## Implementation Plan

| Step | Description       | Deliverables | Verification          |
| ---- | ----------------- | ------------ | --------------------- |
| 1    | 定义 `Event` 接口 | `event.go`   | `go build ./...` 通过 |
| 2    | 定义 Topic 常量   | `topic.go`   | `go build ./...` 通过 |
| 3    | 定义 DTO 结构体   | `dto.go`     | `go build ./...` 通过 |

### Risk Assessment

| Risk       | Probability | Impact | Mitigation   |
| ---------- | ----------- | ------ | ------------ |
| Topic 遗漏 | Low         | Low    | 对照 SPEC §9 |
