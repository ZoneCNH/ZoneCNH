# TASK-CONTRACTS-003

> Breaking Change 检测工具

---

```yaml
task_id: TASK-CONTRACTS-003
module: contracts
scope: "实现 Breaking Change 检测，比较接口版本差异"
spec_ref:
  - "module/contracts/SPEC.md#FR-006"
  - "module/contracts/SPEC.md#BR-003"
  - "module/contracts/SPEC.md#BR-010"
files:
  - "compat.go"
  - "compat_test.go"
acceptance_criteria:
  - "检测接口方法签名变更"
  - "检测 DTO 字段删除"
  - "输出 breaking change 列表"
depends_on:
  - "TASK-CONTRACTS-001"
  - "TASK-CONTRACTS-002"
estimated_effort: "2h"
priority: P1
status: pending
non_scope:
  - "不实现运行时版本切换"
  - "不管理CHANGELOG（→TASK-004）"
```

---

## Requirements Covered

| Requirement | Description          | Acceptance Criteria   |
| ----------- | -------------------- | --------------------- |
| FR-006      | Breaking Change 检测 | 签名变更/字段删除检测 |

## Test Plan

| Test Case | Type | Description        |
| --------- | ---- | ------------------ |
| TC-003    | Unit | 接口方法签名变更检测 |
| TC-003    | Unit | DTO字段删除/类型变更检测 |
| TC-003    | Unit | 新增可选字段判定 |

## Implementation Notes

- 使用 AST 比较两个版本的接口定义
- 输出 breaking change 列表

## Implementation Plan

| Step | Description      | Deliverables     | Verification          |
| ---- | ---------------- | ---------------- | --------------------- |
| 1    | 实现接口比较逻辑 | `compat.go`      | `go build ./...` 通过 |
| 2    | 编写测试         | `compat_test.go` | 全部测试通过          |

### Risk Assessment

| Risk         | Probability | Impact | Mitigation         |
| ------------ | ----------- | ------ | ------------------ |
| AST 比较复杂 | Medium      | Medium | 简化为方法列表比较 |
