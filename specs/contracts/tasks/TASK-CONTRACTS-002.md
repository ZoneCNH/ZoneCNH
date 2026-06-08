# TASK-CONTRACTS-002

> Event 接口 + Topic 常量 + DTO 契约

---

```yaml
task_id: TASK-CONTRACTS-002
module: contracts
scope: "定义 Event 接口、Topic 常量和 DTO 契约"
spec_ref:
  - "specs/contracts/SPEC.md#FR-003"
  - "specs/contracts/SPEC.md#FR-004"
  - "specs/contracts/SPEC.md#FR-005"
files:
  - "event.go"
  - "topic.go"
  - "dto.go"
acceptance_criteria:
  - "Event 接口包含 Type/Payload/Timestamp 方法"
  - "Topic 常量覆盖所有事件类型"
  - "DTO 结构体定义完整"
depends_on:
  - "TASK-CONTRACTS-000"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-003 | Event 接口 | Type/Payload/Timestamp |
| FR-004 | Topic 常量 | 所有事件类型 |
| FR-005 | DTO 契约 | 结构体定义完整 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Compile | 类型完整性编译验证 |

## Implementation Notes

- Topic 常量使用 `const` 定义
- DTO 使用标准 Go 结构体

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 定义 `Event` 接口 | `event.go` | `go build ./...` 通过 |
| 2 | 定义 Topic 常量 | `topic.go` | `go build ./...` 通过 |
| 3 | 定义 DTO 结构体 | `dto.go` | `go build ./...` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Topic 遗漏 | Low | Low | 对照 SPEC §9 |
