# TASK-XLIBGATE-007

> 集成测试

---

```yaml
task_id: TASK-XLIBGATE-007
module: xlibgate
scope: "实现集成测试，端到端验证所有子命令"
spec_ref:
  - "module/xlibgate/SPEC.md#16"
files:
  - "integration_test.go"
acceptance_criteria:
  - "所有子命令端到端测试通过"
  - "exit code 正确"
depends_on:
  - "TASK-XLIBGATE-002"
  - "TASK-XLIBGATE-003"
  - "TASK-XLIBGATE-004"
  - "TASK-XLIBGATE-005"
  - "TASK-XLIBGATE-006"
estimated_effort: "2h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| §16 | 集成测试 | 端到端测试通过 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Integration | 各子命令端到端 |

## Implementation Notes

- 使用 `os/exec` 调用编译后的二进制
- 测试各种 exit code 场景

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现集成测试 | `integration_test.go` | 全部通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 二进制编译依赖 | Low | Low | TestMain 中编译 |
