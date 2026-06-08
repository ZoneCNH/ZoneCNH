# TASK-XLIBGATE-004

> check baseline 实现

---

```yaml
task_id: TASK-XLIBGATE-004
module: xlibgate
scope: "实现 check baseline 命令：检查所有模块 Go 版本一致性"
spec_ref:
  - "module/xlibgate/SPEC.md#FR-003"
files:
  - "check_baseline.go"
  - "check_baseline_test.go"
acceptance_criteria:
  - "版本一致：exit 0"
  - "版本不匹配：输出列表，exit 1"
  - "无 --expected：exit 2"
depends_on:
  - "TASK-XLIBGATE-001"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-003 | check baseline：Go 版本一致性 | 3 个 WHEN/THEN 场景 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| §7.3-1 | Unit | 版本一致：exit 0 |
| §7.3-2 | Unit | 版本不匹配：exit 1 |
| §7.3-3 | Unit | 无 --expected：exit 2 |

## Implementation Notes

- 遍历目录查找所有 `go.mod`，提取 `go` 指令版本
- 与 `--expected` 参数比较

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `check_baseline.go`：遍历 go.mod → 提取版本 → 比较 | `check_baseline.go` | §7.3 全部通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| go.mod 解析错误 | Low | Low | 标准库解析 |
