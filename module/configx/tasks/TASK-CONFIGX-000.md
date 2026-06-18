# TASK-CONFIGX-000

> 项目骨架：go.mod、doc.go、errors.go（公共错误变量）

> ⚠️ **实现偏差注解（2026-06-18 校准）**：本任务规格要求「定义 5 个 `ErrXxx` sentinel 变量，错误格式 `configx: <描述>`」，但运行时实现已演进——实际 `errors.go` 采用 `ErrorKind` 枚举 + `*Error` 结构体 + `NewError/WrapError/IsKind` API，`Error()` 输出 `<kind>: <op>: <message>`。权威契约见 [SPEC.md §9.5](../SPEC.md#95-公共错误)。本任务文档保留原始任务下达记录，**不要据此编写代码**。

---

```yaml
task_id: TASK-CONFIGX-000
module: configx
scope: "创建 go.mod、doc.go、errors.go，定义公共错误变量"
spec_ref:
  - "module/configx/SPEC.md#BR-008"
  - "module/configx/SPEC.md#§15.1"
files:
  - "go.mod"
  - "doc.go"
  - "errors.go"
acceptance_criteria:
  - "go build ./... 编译通过"
  - "5 个错误变量可被外部包引用（首字母大写）"
  - "go vet ./... 无警告"
depends_on: []
estimated_effort: "0.5h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description      | Acceptance Criteria                |
| ----------- | ---------------- | ---------------------------------- |
| §10.1       | 公共错误变量定义 | 5 个错误变量均为 `errors.New` 创建 |
| §15.1       | go.mod 依赖声明  | 仅必要依赖                         |

## Test Plan

| Test Case | Type    | Description                                                                       |
| --------- | ------- | --------------------------------------------------------------------------------- |
| TC-009    | CI Gate | Release DoD: `go test -race -count=1 ./...` + `gitleaks detect --no-git` 全部通过 |
| —         | CI Gate | `go build ./...` 编译通过                                                         |
| —         | CI Gate | `go vet ./...` 无错误                                                             |

## Non-scope

- 不实现任何 Go 接口或逻辑代码
- 不包含测试文件（编译验证即可）
- 不处理配置文件内容

## Implementation Notes

- `go.mod` 声明 `module github.com/ZoneCNH/configx` 和 `go 1.23`
- `errors.go` 定义 5 个错误变量：`ErrInvalidFormat`、`ErrValidationFailed`、`ErrKeyNotFound`、`ErrTypeMismatch`、`ErrAlreadyLoaded`
- 错误格式为 `"configx: <描述>"`
- `doc.go` 说明 configx 是 Foundation L1 配置层

## Implementation Plan

| Step | Description                             | Deliverables | Verification          |
| ---- | --------------------------------------- | ------------ | --------------------- |
| 1    | 创建 `go.mod`，声明 module 和 go 版本   | `go.mod`     | `go mod tidy` 无变化  |
| 2    | 创建 `doc.go`，package doc 注释         | `doc.go`     | `go doc .` 输出正确   |
| 3    | 创建 `errors.go`，定义 5 个公共错误变量 | `errors.go`  | `go build ./...` 通过 |
| 4    | 运行 go vet 验证                        | —            | `go vet ./...` 无警告 |

### Risk Assessment

| Risk         | Probability | Impact | Mitigation          |
| ------------ | ----------- | ------ | ------------------- |
| 错误变量遗漏 | Low         | Low    | 对照 §10.1 列表核对 |
