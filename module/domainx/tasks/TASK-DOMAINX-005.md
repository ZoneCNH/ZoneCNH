# TASK-DOMAINX-005

> JSON 序列化 + 不可变性 + testdata

---

```yaml
task_id: TASK-DOMAINX-005
module: domainx
scope: "验证所有值对象 JSON round-trip、不可变性（并发安全）、JSON 错误处理"
spec_ref:
  - "module/domainx/SPEC.md#FR-005"
  - "module/domainx/SPEC.md#FR-006"
  - "module/domainx/SPEC.md#BR-005"
  - "module/domainx/SPEC.md#BR-006"
files:
  - "json_test.go"
  - "testdata/order_valid.json"
  - "testdata/order_invalid.json"
  - "testdata/fill_valid.json"
  - "testdata/position_valid.json"
  - "testdata/exposure_valid.json"
acceptance_criteria:
  - "AC-011: Order JSON round-trip → 字段值一致"
  - "AC-012: Fill JSON round-trip → 字段值一致"
  - "AC-013: JSON 缺失必填字段 → 返回错误"
  - "AC-014: 多 goroutine 并发读取 → 零 data race"
depends_on:
  - "TASK-DOMAINX-001"
  - "TASK-DOMAINX-002"
  - "TASK-DOMAINX-003"
  - "TASK-DOMAINX-004"
estimated_effort: "1.5h"
priority: P0
status: done
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|-------------|-------------|---------------------|
| FR-005 | JSON 序列化/反序列化 | AC-011 ~ AC-013 |
| FR-006 | 不可变性 + 并发安全 | AC-014 |
| BR-005 | 不可变性编译期约束 | AC-014 |
| BR-006 | snake_case JSON tag | AC-011, AC-012 |

## Non-scope

- 不做 protobuf 序列化（OQ-005 待评估）

## Test Plan

| Test Case | Type | Description |
|-----------|------|-------------|
| TC-011 | Unit | Order: Marshal → Unmarshal → 字段一致 |
| TC-012 | Unit | Fill: Marshal → Unmarshal → 字段一致 |
| TC-013 | Unit | JSON 缺 symbol → 返回错误 |
| TC-014 | Unit | 100 goroutines 并发 getter → `go test -race` 零告警 |

## Implementation Notes

- JSON tag 全部使用 snake_case：`json:"order_id"`, `json:"created_at"` 等
- decimal.Decimal 的 JSON 序列化依赖 decimalx 提供的 MarshalJSON/UnmarshalJSON
- 不可变性通过私有字段 + 公开 getter 保证（编译期约束）
- testdata/ 目录存放 golden files 用于 JSON round-trip 测试
