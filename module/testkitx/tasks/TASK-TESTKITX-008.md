# TASK-TESTKITX-008

> BoundaryCheck 实现

---

```yaml
task_id: TASK-TESTKITX-008
module: testkitx
scope: "实现 BoundaryCheck，验证生产包 import graph 不包含 testkitx"
non_scope: "不检查数值边界条件，不修改 go.mod，不扫描外部仓库"
spec_ref:
  - "module/testkitx/SPEC.md#FR-009"
  - "module/testkitx/SPEC.md#BR-005"
files:
  - "boundary.go"
  - "boundary_test.go"
acceptance_criteria:
  - "AC-009: 生产包依赖 testkitx → testing.T fail + 报告完整依赖路径"
  - "AC-009: 生产包不依赖 testkitx → testing.T pass"
  - "AC-009: testkitx 自身依赖自身不计为违规"
depends_on:
  - "TASK-TESTKITX-000"
estimated_effort: "1h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-009 | BoundaryCheck：生产 import 边界扫描 | AC-009 |
| BR-005 | 生产 import graph 无 testkitx | CI Gate: no-production-import |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-009 | Unit | 模拟生产包依赖 testkitx → fail + 依赖路径 |
| TC-009 | Unit | 模拟生产包不依赖 testkitx → pass |
| TC-009 | Unit | BoundaryCheck 自检通过 |

## Implementation Notes

- 使用 `go list -deps <module>/...` 检查传递依赖
- 白名单：testkitx 自身目录下的包不触发违规
- 错误消息格式：`"testkitx: production dependency on testkitx: <import_path>"`

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `BoundaryCheck` 函数 | `boundary.go` | 全部测试通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| `go list` 在 CI 中不可用 | Low | High | 降级为 skip 而非 fail |
| 误报（白名单不完整） | Medium | Medium | 日志输出完整依赖路径 |
