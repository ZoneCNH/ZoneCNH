# TASK-TESTKITX-007

> GoldenUpdate 实现

---

```yaml
task_id: TASK-TESTKITX-007
module: testkitx
scope: "实现 GoldenUpdate，自动更新 golden file 测试数据"
non_scope: "不实现 golden 文件版本管理，不自动提交变更"
spec_ref:
  - "module/testkitx/SPEC.md#FR-008"
  - "module/testkitx/SPEC.md#BR-004"
  - "module/testkitx/SPEC.md#BR-007"
files:
  - "golden.go"
  - "golden_test.go"
acceptance_criteria:
  - "AC-008: 比较实际输出与 golden file"
  - "AC-008: GOLDEN_UPDATE=1 → 更新 golden file"
  - "BR-004: GOLDEN_UPDATE 未设置 → 只读比较"
  - "BR-007: golden 更新时自动检查 secret"
depends_on:
  - "TASK-TESTKITX-000"
estimated_effort: "1h"
priority: P1
status: pending
```

---

## Non-scope

- 不涉及本 Task 范围外的功能

## Requirements Covered

| Requirement | Description                        | Acceptance Criteria |
| ----------- | ---------------------------------- | ------------------- |
| FR-008      | GoldenUpdate：golden file 自动更新 | AC-008              |
| BR-004      | GOLDEN_UPDATE=1 环境变量控制       | golden update guard |
| BR-007      | golden 文件不泄露 secret           | gitleaks CI Gate    |

## Test Plan

| Test Case | Type | Description                            |
| --------- | ---- | -------------------------------------- |
| TC-008    | Unit | 默认模式：比较 golden file 一致 → pass |
| TC-008    | Unit | GOLDEN_UPDATE=1：更新 golden file      |
| TC-008    | Unit | 内容不一致且未设 GOLDEN_UPDATE → fail  |

## Implementation Notes

- `GoldenUpdate(t *testing.T, name string, got []byte)`
- 读取 `testdata/<name>.golden` 比较
- 环境变量 `GOLDEN_UPDATE=true` 时写入更新

## Implementation Plan

| Step | Description              | Deliverables | Verification |
| ---- | ------------------------ | ------------ | ------------ |
| 1    | 实现 `GoldenUpdate` 函数 | `golden.go`  | 全部测试通过 |

### Risk Assessment

| Risk                 | Probability | Impact | Mitigation             |
| -------------------- | ----------- | ------ | ---------------------- |
| golden file 路径错误 | Low         | Low    | 使用 t.Name() 生成路径 |
