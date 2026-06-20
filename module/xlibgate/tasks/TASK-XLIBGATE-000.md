# TASK-XLIBGATE-000

> 项目骨架：go.mod、cmd/、errors.go

---

```yaml
task_id: TASK-XLIBGATE-000
module: xlibgate
scope: "创建 go.mod、cmd/xlibgate/main.go、errors.go"
spec_ref:
  - "module/xlibgate/SPEC.md#AC-008"
  - "module/xlibgate/SPEC.md#BR-009"
files:
  - "go.mod"
  - "cmd/xlibgate/main.go"
  - "errors.go"
acceptance_criteria:
  - "NFR-010: go build ./... 编译通过，go list -deps 无 ZoneCNH 运行时依赖"
  - "BR-009: go.mod 声明 go 1.23，仅含 stdlib + gopkg.in/yaml.v3 依赖"
depends_on: []
estimated_effort: "0.5h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description                                       | Acceptance Criteria               |
| ----------- | ------------------------------------------------- | --------------------------------- |
| NFR-010     | 无 Foundation 运行时依赖                          | go list -deps 零命中 ZoneCNH 模块 |
| BR-009      | FOUNDATION-DEPS.yaml schema 与 xlib_standard 一致 | go.mod 仅声明授权依赖             |

## Non-scope

- 不实现任何子命令逻辑
- 不添加 CLI 框架代码（由 TASK-001 负责）
- 不添加外部依赖（仅 stdlib + yaml.v3）
- 不配置 CI/CD pipeline

## Test Plan

| Test Case | Type    | Description                           |
| --------- | ------- | ------------------------------------- |
| NFR-010   | CI Gate | `go build ./...` 编译通过             |
| BR-009    | CI Gate | `go list -deps ./...` 无 ZoneCNH 模块 |

## Implementation Notes

- CLI 框架：使用 `flag` 或 `cobra`
- `errors.go` 定义：`ErrImportViolation`、`ErrGomodDirty`、`ErrBaselineMismatch`、`ErrReleaseEvidence`、`ErrConfigMissing`

## Implementation Plan

| Step | Description                      | Deliverables           | Verification          |
| ---- | -------------------------------- | ---------------------- | --------------------- |
| 1    | 创建 `go.mod`                    | `go.mod`               | `go mod tidy` 无变化  |
| 2    | 创建 `cmd/xlibgate/main.go` 入口 | `cmd/xlibgate/main.go` | `go build ./...` 通过 |
| 3    | 创建 `errors.go`                 | `errors.go`            | `go build ./...` 通过 |

### Risk Assessment

| Risk         | Probability | Impact | Mitigation       |
| ------------ | ----------- | ------ | ---------------- |
| CLI 框架选择 | Low         | Low    | 使用 stdlib flag |
