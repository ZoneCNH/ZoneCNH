# TASK-XLIBGATE-001

> CLI 框架：子命令解析、flag 绑定

---

```yaml
task_id: TASK-XLIBGATE-001
module: xlibgate
scope: "实现 CLI 子命令框架：check imports/gomod/baseline/release/all"
spec_ref:
  - "specs/xlibgate/SPEC.md#9"
files:
  - "cmd/xlibgate/main.go"
  - "cli.go"
acceptance_criteria:
  - "check imports 子命令可解析 --config 参数"
  - "check gomod 子命令可解析 --path 参数"
  - "check baseline 子命令可解析 --expected 参数"
  - "check release 子命令可解析 --evidence 参数"
  - "check all 子命令可解析 --config 参数"
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
| §9 | CLI 接口 | 5 个子命令 + 参数 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Unit | 各子命令参数解析正确 |

## Implementation Notes

- 使用 `flag.FlagSet` 实现子命令
- 每个子命令返回对应的 Checker 函数

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 CLI 框架：子命令注册和分发 | `cli.go` | `go build ./...` 通过 |
| 2 | 实现 flag 绑定和参数校验 | `cli.go` | 参数解析测试通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 参数解析复杂 | Low | Low | 每个子命令独立 FlagSet |
