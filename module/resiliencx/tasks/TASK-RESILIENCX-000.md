# TASK-RESILIENCX-000

> 项目骨架：go.mod、doc.go、errors.go

---

```yaml
task_id: TASK-RESILIENCX-000
module: resiliencx
scope: "创建 go.mod、doc.go、errors.go，定义公共错误变量"
non_scope: "不包含具体策略实现和测试文件"
spec_ref:
  - "module/resiliencx/SPEC.md#10"
  - "module/resiliencx/SPEC.md#15"
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

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| §10 | 公共错误变量定义 | 错误变量均为 `errors.New` 创建 |
| §15 | go.mod 依赖声明 | 仅必要依赖 |

| BR-002 | configx.Reader 参数化 | go.mod 仅含声明依赖 |

| BR-007 | stdlib + 最少依赖 | go.mod 无框架依赖 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | CI Gate | `go build ./...` 编译通过 |
| — | CI Gate | `go vet ./...` 无错误 |

| — | CI Gate | go mod tidy 依赖整洁 |

## Implementation Notes

- `go.mod` 声明 `module github.com/ZoneCNH/resiliencx` 和 `go 1.23`
- `errors.go` 定义：`ErrTimeout`、`ErrCircuitOpen`、`ErrBulkheadFull`、`ErrRateLimited`、`ErrMaxRetriesExceeded`
- 错误格式为 `"resiliencx: <描述>"`

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 创建 `go.mod` | `go.mod` | `go mod tidy` 无变化 |
| 2 | 创建 `doc.go` 和 `errors.go` | `doc.go`, `errors.go` | `go build ./...` 通过 |
| 3 | 运行 go vet 验证 | — | `go vet ./...` 无警告 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 错误变量遗漏 | Low | Low | 对照 §10 列表核对 |
