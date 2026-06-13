# TASK-CONTRACTS-000

> 项目骨架：go.mod、doc.go

---

```yaml
task_id: TASK-CONTRACTS-000
module: contracts
scope: "创建 go.mod、doc.go，定义包结构"
spec_ref:
  - "module/contracts/SPEC.md#BR-008"
  - "module/contracts/SPEC.md#NFR-003"
  - "module/contracts/SPEC.md#NFR-008"
files:
  - "go.mod"
  - "doc.go"
acceptance_criteria:
  - "go build ./... 编译通过"
depends_on: []
estimated_effort: "0.5h"
priority: P0
status: pending
non_scope:
  - "不定义接口或DTO（→TASK-001/002）"
  - "不编写测试文件（骨架任务）"
```

---

## Requirements Covered

| Requirement | Description     | Acceptance Criteria |
| ----------- | --------------- | ------------------- |
| BR-008      | 依赖边界约束 | go.mod无L1运行时依赖 |
| NFR-003     | vet/lint零告警 | go vet+golangci-lint |
| NFR-008     | 错误格式统一 | contracts:<desc>格式 |

## Test Plan

| Test Case | Type    | Description               |
| --------- | ------- | ------------------------- |
| TC-001    | CI Gate | go build编译通过 |
| —         | CI Gate | go mod tidy整洁检查 |

## Implementation Notes

- `go.mod` 声明 `module github.com/ZoneCNH/contracts`
- 无外部依赖，仅定义接口和 DTO

## Implementation Plan

| Step | Description   | Deliverables | Verification          |
| ---- | ------------- | ------------ | --------------------- |
| 1    | 创建 `go.mod` | `go.mod`     | `go mod tidy` 无变化  |
| 2    | 创建 `doc.go` | `doc.go`     | `go build ./...` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| 无   | Low         | Low    | —          |
