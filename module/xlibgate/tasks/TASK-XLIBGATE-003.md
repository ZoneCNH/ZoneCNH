# TASK-XLIBGATE-003

> check gomod 实现

---

```yaml
task_id: TASK-XLIBGATE-003
module: xlibgate
scope: "实现 check gomod 命令：运行 go mod tidy 检查 diff"
spec_ref:
  - "module/xlibgate/SPEC.md#FR-002"
files:
  - "check_gomod.go"
  - "check_gomod_test.go"
acceptance_criteria:
  - "go mod tidy 无 diff：exit 0"
  - "go mod tidy 有 diff：输出详情，exit 1"
  - "无 go.mod：exit 2"
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
| FR-002 | check gomod：go mod tidy diff 检查 | 3 个 WHEN/THEN 场景 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| §7.2-1 | Unit | 无 diff：exit 0 |
| §7.2-2 | Unit | 有 diff：exit 1 |
| §7.2-3 | Unit | 无 go.mod：exit 2 |

## Implementation Notes

- 执行 `go mod tidy` 后检查 `git diff go.mod go.sum`
- 使用 `os/exec` 调用外部命令

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `check_gomod.go`：执行 go mod tidy → 检查 diff | `check_gomod.go` | §7.2 全部通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 外部命令依赖 | Low | Low | 检查 go 命令可用性 |
