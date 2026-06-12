# TASK-CONFIGX-005

> Schema 校验：Validate 方法、错误列表、required 检查

---

```yaml
task_id: TASK-CONFIGX-005
module: configx
scope: "实现 Validate() 方法，根据 schema 校验配置，返回所有违规字段"
spec_ref:
  - "module/configx/SPEC.md#FR-003"
  - "module/configx/SPEC.md#BR-002"
  - "module/configx/SPEC.md#BR-006"
files:
  - "schema.go"
  - "schema_test.go"
acceptance_criteria:
  - "配置符合 schema 时返回 nil"
  - "配置不符合 schema 时返回包含所有违规字段的错误列表"
  - "required 字段缺失时 Validate 报错"
depends_on:
  - "TASK-CONFIGX-001"
  - "TASK-CONFIGX-003"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-003 | Validate：符合→nil，不符合→错误列表 | 2 个 WHEN/THEN 场景 |
| BR-002 | 启动时必须通过 schema 校验（fail-fast） | Validate 在启动流程中调用 |
| BR-006 | 配置值类型必须与 schema 定义一致 | 类型不匹配报错 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-002 | Unit | schema 校验失败：类型不匹配返回错误（含 BR-002 fail-fast 路径） |
| — | Unit | schema 校验通过：返回 nil |
| — | Unit | required 字段缺失：返回错误 |
| — | Unit | 未知字段 strict 模式：返回错误（BR-007） |

## Non-scope

- 不做配置文件解析（→ TASK-002）
- 不做环境变量处理（→ TASK-004）
- 不做配置读取（→ TASK-006）

## Implementation Notes

- 校验遍历 schema 中所有字段，逐一检查 data 中的值
- 错误列表格式：`[]ValidationError{Field, Expected, Actual}`
- required 检查：schema 中标记 required 的字段在 data 中必须存在

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 定义 `ValidationError` 结构体和 `Schema` 类型 | `schema.go` | `go build ./...` 通过 |
| 2 | 实现类型校验：检查 data 中的值是否匹配 schema 定义的类型 | `schema.go` | `go test ./... -run TestTypeCheck` 通过 |
| 3 | 实现 required 检查 | `schema.go` | `go test ./... -run TestRequired` 通过 |
| 4 | 实现 `Validate()` 方法：收集所有违规字段，返回错误列表或 nil | `schema.go` | TC-002 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| schema 格式定义不清晰 | Medium | Medium | 对照 SPEC §11 的 schema 示例 |
| 嵌套字段校验遗漏 | Low | Medium | 递归遍历嵌套 map |
