# TASK-KERNEL-010

> 文档 + Release：README、CHANGELOG、example_test.go、godoc

---

```yaml
task_id: TASK-KERNEL-010
module: kernel
scope: "创建 README、CHANGELOG、example_test.go，确保 godoc 完整，验证 Release DoD"
spec_ref:
  - "module/kernel/SPEC.md#22"
  - "module/kernel/SPEC.md#9.2"
files:
  - "README.md"
  - "CHANGELOG.md"
  - "example_test.go"
acceptance_criteria:
  - "AC-NEW-53: README.md 包含：模块定位、快速开始、配置说明、API 概览"
  - "AC-NEW-54: CHANGELOG.md 已创建并记录 v0.7.3 变更"
  - "AC-NEW-55: 所有公共接口有 godoc 注释"
  - "AC-NEW-56: 所有公共类型有示例代码（example_test.go）"
  - "AC-NEW-57: 单元测试覆盖率 >= 90%"
  - "AC-NEW-58: -race 测试通过"
  - "AC-NEW-59: go vet 无警告"
  - "AC-NEW-60: stdlib-only 检查通过"
  - "AC-NEW-61: 所有 Functional Requirements 有对应测试"
depends_on:
  - "TASK-KERNEL-009"
estimated_effort: "2h"
priority: P1
status: pending
```

---

## Files Likely to Change

- `README.md` — 新建
- `CHANGELOG.md` — 新建
- `example_test.go` — 新建

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| §22 | Release DoD | 所有 DoD 项通过 |
| §9.2 | 用法示例 | example_test.go 可运行 |

## Non-scope

- 不实现业务逻辑（→ TASK-KERNEL-002~008）
- 不实现集成测试（→ TASK-KERNEL-009）
- 不修改已有代码

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-019 | CI Gate | stdlib-only：`go list -deps ./... | grep -v "^std" | grep -v "kernel"` 无输出 |
| — | CI Gate | 覆盖率：`go test ./... -coverprofile=cover.out` >= 90% |
| — | CI Gate | data race：`go test ./... -race -count=1` |
| — | CI Gate | vet：`go vet ./...` 无警告 |
| — | CI Gate | lint：`golangci-lint run` 无错误 |
| — | CI Gate | benchmark：`go test -bench=. -benchmem -count=3 ./...` 结果附在 PR |
| — | Review | README 内容完整性检查 |
| — | Review | godoc 注释完整性检查 |

## Implementation Notes

- README 使用中文，技术术语保留英文
- example_test.go 使用 `Example` 前缀函数，确保 `go test` 能运行
- CHANGELOG 遵循 Keep a Changelog 格式
- godoc 注释应以被注释对象的名称开头（Go 惯例）
- README 的快速开始示例应可复制粘贴直接运行

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 创建 README.md：模块定位、快速开始、配置说明、API 概览 | `README.md` | 人工 review 内容完整性 |
| 2 | 创建 CHANGELOG.md：记录 v0.7.3 变更（Keep a Changelog 格式） | `CHANGELOG.md` | 格式正确 |
| 3 | 创建 example_test.go：所有公共类型的 Example 函数 | `example_test.go` | `go test ./... -run Example` 通过 |
| 4 | 补全所有公共接口的 godoc 注释（以被注释对象名称开头） | 各 `.go` 文件 | `go doc ./...` 输出完整 |
| 5 | 运行 Release DoD 全量验证：覆盖率 >= 90%、`-race`、`go vet`、stdlib-only、benchmark | — | 所有 CI gate 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 覆盖率未达 90% | Medium | Medium | 补充边界场景测试用例 |
| godoc 注释遗漏 | Low | Low | 用 `go doc` 逐一检查公共符号 |
