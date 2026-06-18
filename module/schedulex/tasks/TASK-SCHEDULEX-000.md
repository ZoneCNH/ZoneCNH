# TASK-SCHEDULEX-000

> 项目骨架：go.mod、doc.go、errors.go

---

```yaml
task_id: TASK-SCHEDULEX-000
module: schedulex
scope: "创建 go.mod、doc.go、errors.go，定义公共错误变量"
non_scope: "不定义接口，不实现调度逻辑"
spec_ref:
  - "module/schedulex/SPEC.md#FR-001"
files:
  - "go.mod"
  - "doc.go"
  - "errors.go"
acceptance_criteria:
  - "go build ./... 编译通过"
  - "错误变量可被外部包引用"
depends_on: []
estimated_effort: "0.5h"
priority: P0
status: pending
```

---

## Non-scope

- 不涉及本 Task 范围外的功能

## Requirements Covered

| Requirement | Description      | Acceptance Criteria            |
| ----------- | ---------------- | ------------------------------ |
| §8.6        | 公共错误变量定义 | 错误变量均为 `errors.New` 创建 |
| §14.1       | go.mod 依赖声明  | 仅必要依赖                     |

## Test Plan

| Test Case | Type    | Description               |
| --------- | ------- | ------------------------- |
| —         | CI Gate | `go build ./...` 编译通过 |

## Implementation Notes

- 错误变量：`ErrSchedulerClosed`、`ErrJobExists`、`ErrInvalidJob`、`ErrInvalidOption`、`ErrLockUnavailable`

## Implementation Plan

| Step | Description                  | Deliverables          | Verification          |
| ---- | ---------------------------- | --------------------- | --------------------- |
| 1    | 创建 `go.mod`                | `go.mod`              | `go mod tidy` 无变化  |
| 2    | 创建 `doc.go` 和 `errors.go` | `doc.go`, `errors.go` | `go build ./...` 通过 |
| 3    | 运行 go vet 验证             | —                     | `go vet ./...` 无警告 |

### Risk Assessment

| Risk         | Probability | Impact | Mitigation             |
| ------------ | ----------- | ------ | ---------------------- |
| 错误变量遗漏 | Low         | Low    | 对照 §8.6 列表核对     |
