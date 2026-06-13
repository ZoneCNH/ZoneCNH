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
  - "AC-FR-002: Event 接口包含 EventID/EventType/Timestamp/Source 四方法"
  - "AC-FR-003: Topic 常量全局唯一且命名合规"
  - "AC-FR-004: DTO JSON round-trip 序列化/反序列化后字段值不变"
  - "AC-BR-001: 所有跨域 DTO 定义集中在 contracts 包"
  - "AC-BR-005: DTO 创建后字段不可修改（不可变）"
  - "AC-BR-006: Topic 值无重复，命名符合 domain.action"
  - "AC-BR-009: 所有 DTO 字段 JSON tag 为 snake_case"
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
| FR-003      | Event 接口  | AC-FR-002: 四方法签名完整 |
| FR-004      | Topic 常量  | AC-FR-003: 全局唯一+命名合规 |
| FR-005      | DTO 契约    | AC-FR-004: JSON round-trip |
| BR-001      | DTO 集中定义 | AC-BR-001: 全部在 contracts 包 |
| BR-005      | DTO 不可变   | AC-BR-005: 只读字段 |
| BR-006      | Topic 命名   | AC-BR-006: domain.action 格式 |
| BR-009      | JSON tag    | AC-BR-009: snake_case |

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
