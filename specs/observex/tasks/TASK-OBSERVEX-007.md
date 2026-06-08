# TASK-OBSERVEX-007

> Health：JSON schema 输出

---

```yaml
task_id: TASK-OBSERVEX-007
module: observex
scope: "实现 health JSON schema 输出，包含 ready/live/message/components"
spec_ref:
  - "specs/observex/SPEC.md#FR-007"
files:
  - "health.go"
  - "health_test.go"
acceptance_criteria:
  - "health.JSON() 输出符合 health JSON schema"
  - "包含 ready、live、message、components 字段"
depends_on:
  - "TASK-OBSERVEX-000"
estimated_effort: "1h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-007 | Health：JSON 输出符合 schema | ready/live/message/components |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-006 | Unit | Health schema：输出符合约定 JSON schema |
| — | Unit | 各字段类型正确 |

## Implementation Notes

- HealthStatus 结构体：`Ready bool`, `Live bool`, `Message string`, `Components map[string]ComponentHealth`
- `JSON()` 方法返回 JSON 编码的 health 状态
- 与 kernel 的 HealthStatus 概念对齐

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 定义 `HealthStatus` 和 `ComponentHealth` 结构体 | `health.go` | `go build ./...` 通过 |
| 2 | 实现 `JSON()` 方法：序列化为 JSON | `health.go` | TC-006 通过 |
| 3 | 编写 schema 验证测试 | `health_test.go` | 所有字段类型正确 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| schema 与 kernel 不一致 | Low | Medium | 对照 kernel HealthStatus |
