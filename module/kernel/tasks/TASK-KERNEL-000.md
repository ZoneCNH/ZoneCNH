# TASK-KERNEL-000

> 项目骨架：go.mod、doc.go、errors.go（公共错误变量）

---

```yaml
task_id: TASK-KERNEL-000
module: kernel
scope: "创建 go.mod、doc.go、errors.go，定义公共错误变量，确保 stdlib-only"
spec_ref:
  - "module/kernel/SPEC.md#10.1"
  - "module/kernel/SPEC.md#15.1"
  - "module/kernel/SPEC.md#BR-008"
files:
  - "go.mod"
  - "doc.go"
  - "errors.go"
acceptance_criteria:
  - "AC-009: go list -deps ./... 无非 stdlib 依赖"
  - "AC-NEW-01: 所有 10 个错误变量可被外部包引用（首字母大写）"
  - "AC-NEW-02: go build ./... 编译通过"
  - "AC-NEW-03: go vet ./... 无警告"
depends_on: []
estimated_effort: "0.5h"
priority: P0
status: pending
```

---

## Files Likely to Change

- `go.mod` — 新建
- `doc.go` — 新建
- `errors.go` — 新建

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| §10.1 | 公共错误变量定义 | 所有 10 个错误变量均为 `errors.New` 创建 |
| §15.1 | go.mod stdlib-only | `go list -deps` 无非 stdlib 依赖 |
| BR-008 | kernel 不 import 任何非 stdlib 包 | CI stdlib-only gate 通过 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | CI Gate | `go build ./...` 编译通过 |
| — | CI Gate | `go list -deps ./... | grep -v "^std" | grep -v "kernel"` 无输出 |
| — | CI Gate | `go vet ./...` 无错误 |

## Implementation Notes

- `go.mod` 仅声明 `module` 和 `go` 版本，无 `require` 块
- `errors.go` 使用标准库 `errors.New`，格式为 `"kernel: <错误描述>"`
- 错误变量列表：`ErrCycleDetected`、`ErrModuleNotFound`、`ErrAlreadyRegistered`、`ErrStartupFailed`、`ErrShutdownTimeout`、`ErrNilModule`、`ErrAlreadyRunning`、`ErrAlreadyStopped`、`ErrAlreadyStarted`、`ErrShutdownInProgress`
- `doc.go` 应说明 kernel 是 Foundation L0 原语层，负责应用生命周期管理

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 创建 `go.mod`，声明 `module github.com/ZoneCNH/kernel` 和 `go 1.23`，无 require 块 | `go.mod` | `go mod tidy` 无变化 |
| 2 | 创建 `doc.go`，包含 package doc 注释说明 kernel 定位 | `doc.go` | `go doc .` 输出正确 |
| 3 | 创建 `errors.go`，定义 10 个公共错误变量（`errors.New`，格式 `"kernel: <描述>"`） | `errors.go` | `go build ./...` 通过 |
| 4 | 运行 stdlib-only 验证和 go vet | — | `go list -deps` 无非 stdlib 依赖，`go vet` 无警告 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| go.mod module path 不正确 | Medium | High | 对照上游仓库确认 path |
| 错误变量遗漏 | Low | Medium | 对照 §10.1 列表逐一核对 |
