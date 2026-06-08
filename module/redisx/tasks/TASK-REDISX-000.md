# TASK-REDISX-000

> 项目骨架：go.mod、doc.go、errors.go

---

```yaml
task_id: TASK-REDISX-000
module: redisx
scope: "创建 go.mod、doc.go、errors.go，定义公共错误变量"
spec_ref:
  - "module/redisx/SPEC.md#10"
  - "module/redisx/SPEC.md#15"
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
| §15 | go.mod 依赖声明 | redis 客户端依赖 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | CI Gate | `go build ./...` 编译通过 |

## Implementation Notes

- 错误变量：`ErrKeyNotFound`、`ErrLockNotAcquired`、`ErrLockExpired`、`ErrConnectionFailed`、`ErrPipelineFailed`
- `go.mod` 依赖 `github.com/redis/go-redis/v9`

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 创建 `go.mod` | `go.mod` | `go mod tidy` 无变化 |
| 2 | 创建 `doc.go` 和 `errors.go` | `doc.go`, `errors.go` | `go build ./...` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| redis 客户端版本冲突 | Low | Medium | 使用 v9 稳定版 |
