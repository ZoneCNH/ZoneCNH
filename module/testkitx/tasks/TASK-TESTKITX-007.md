# TASK-TESTKITX-007

> GoldenUpdate 实现

---

```yaml
task_id: TASK-TESTKITX-007
module: testkitx
scope: "实现 GoldenUpdate，自动更新 golden file 测试数据"
spec_ref:
  - "module/testkitx/SPEC.md#FR-008"
files:
  - "golden.go"
  - "golden_test.go"
acceptance_criteria:
  - "GoldenUpdate 比较实际输出与 golden file"
  - "不一致时更新 golden file"
  - "GOLDEN_UPDATE=true 环境变量控制"
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
| FR-008 | GoldenUpdate：golden file 自动更新 | 环境变量控制 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Unit | 默认模式：比较 golden file |
| — | Unit | GOLDEN_UPDATE=true：更新 golden file |

## Implementation Notes

- `GoldenUpdate(t *testing.T, name string, got []byte)`
- 读取 `testdata/<name>.golden` 比较
- 环境变量 `GOLDEN_UPDATE=true` 时写入更新

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `GoldenUpdate` 函数 | `golden.go` | 全部测试通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| golden file 路径错误 | Low | Low | 使用 t.Name() 生成路径 |
