# TASK-KERNEL-000

> 项目骨架：go.mod、Makefile、README.md、LICENSE

---

```yaml
task_id: TASK-KERNEL-000
module: kernel
scope: "创建 go.mod、Makefile、README.md、LICENSE，确保 stdlib-only"
spec_ref:
  - "module/kernel/SPEC.md#14"
  - "module/kernel/SPEC.md#15.1"
  - "module/kernel/SPEC.md#BR-009"
files:
  - "go.mod"
  - "Makefile"
  - "README.md"
  - "LICENSE"
acceptance_criteria:
  - "AC-SKEL-01: go.mod 声明 module github.com/ZoneCNH/kernel，go 1.23，无 require 块"
  - "AC-SKEL-02: Makefile 包含 build/test/cover/bench/lint/vet/check-stdlib 目标"
  - "AC-SKEL-03: README.md 包含模块定位、12 子包清单、快速开始"
  - "AC-SKEL-04: go build ./... 编译通过"
  - "AC-SKEL-05: go list -deps ./... 无非 stdlib 依赖"
depends_on: []
estimated_effort: "0.5h"
priority: P0
status: pending
```

---

## Files Likely to Change

- `go.mod` — 新建
- `Makefile` — 新建
- `README.md` — 新建
- `LICENSE` — 新建

## Requirements Covered

| Requirement | Description                       | Acceptance Criteria              |
| ----------- | --------------------------------- | -------------------------------- |
| §15.1       | go.mod stdlib-only                | `go list -deps` 无非 stdlib 依赖 |
| BR-009      | kernel 不 import 任何非 stdlib 包 | CI stdlib-only gate 通过         |
| §14         | 目录结构                          | 12 子包目录已创建                |

## Non-scope

- 不创建子包代码（→ TASK-KERNEL-001~013）
- 不创建 contracts（→ TASK-KERNEL-014）
- 不创建 examples（→ TASK-KERNEL-015）

## Test Plan

| Test Case | Type    | Description                            |
| --------- | ------- | -------------------------------------- |
| —         | CI Gate | `go build ./...` 编译通过              |
| —         | CI Gate | `go list -deps ./...` 无非 stdlib 依赖 |
| —         | CI Gate | `make check-stdlib` 通过               |

## Implementation Notes

- `go.mod` 仅声明 `module github.com/ZoneCNH/kernel` 和 `go 1.23`，无 require 块
- `Makefile` 包含常用 Go 开发目标
- `README.md` 列出 12 子包及其用途
- 12 子包目录创建为空目录（含 .gitkeep 或在 Makefile 中处理）
