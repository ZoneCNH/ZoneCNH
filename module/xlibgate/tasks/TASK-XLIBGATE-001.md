# TASK-XLIBGATE-001

> CLI 框架：子命令解析、flag 绑定

---

```yaml
task_id: TASK-XLIBGATE-001
module: xlibgate
scope: "实现 CLI 子命令框架：check imports/gomod/baseline/release/all"
spec_ref:
  - "module/xlibgate/SPEC.md#FR-001"
  - "module/xlibgate/SPEC.md#FR-005"
  - "module/xlibgate/SPEC.md#FR-006"
files:
  - "cmd/xlibgate/main.go"
  - "cli.go"
  - "cli_test.go"
acceptance_criteria:
  - "FR-001: check imports 子命令可解析 --config 参数"
  - "FR-002: check gomod 子命令可解析 --path 参数"
  - "FR-003: check baseline 子命令可解析 --expected 参数"
  - "FR-004: check release 子命令可解析 --evidence 参数"
  - "FR-005: check all 子命令可解析 --config 参数"
depends_on:
  - "TASK-XLIBGATE-000"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-001 | check imports：CLI 参数绑定 | --config 参数解析正确 |
| FR-005 | check all：CLI 聚合命令入口 | --config 参数解析正确 |
| FR-006 | 输出格式：--output/--artifact flag 绑定 | --output, --artifact 参数解析正确 |

## Non-scope

- 不实现任何子命令的具体检查逻辑（由 TASK-002~006 负责）
- 不实现配置文件加载和解析（由 TASK-002 config.go 负责）
- 不实现输出格式化（由 TASK-006 output.go 负责）
- 不处理跨平台兼容性（后续 Phase 迭代）

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-001 | Unit | check imports --config 参数解析正确 |
| TC-002 | Unit | check gomod --path 参数解析正确 |
| TC-003 | Unit | check baseline --expected 参数解析正确 |
| TC-004 | Unit | check release --evidence 参数解析正确 |
| TC-005 | Unit | check all --config 参数解析正确 |
| — | Unit | 未知子命令：exit 2 |

## Implementation Notes

- 使用 `flag.FlagSet` 实现子命令
- 每个子命令返回对应的 Checker 函数

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 CLI 框架：子命令注册和分发 | `cli.go` | `go build ./...` 通过 |
| 2 | 实现 flag 绑定和参数校验 | `cli.go`, `cli_test.go` | 参数解析测试通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 参数解析复杂 | Low | Low | 每个子命令独立 FlagSet |
