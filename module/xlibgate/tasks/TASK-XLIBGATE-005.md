# TASK-XLIBGATE-005

> check release 实现

---

```yaml
task_id: TASK-XLIBGATE-005
module: xlibgate
scope: "实现 check release 命令：检查 evidence.json 完整性"
spec_ref:
  - "module/xlibgate/SPEC.md#FR-004"
  - "module/xlibgate/SPEC.md#BR-004"
files:
  - "check_release.go"
  - "check_release_test.go"
  - "evidence/collector.go"
  - "evidence/validator.go"
acceptance_criteria:
  - "AC-004: evidence 完整且通过 → pass，exit 0"
  - "AC-004: 缺失/失败项 → 输出缺失列表，exit 1"
  - "AC-004: evidence 文件格式无效 → error，exit 2"
depends_on:
  - "TASK-XLIBGATE-001"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description                           | Acceptance Criteria      |
| ----------- | ------------------------------------- | ------------------------ |
| FR-004      | check release：evidence 完整性校验    | 3 个 WHEN/THEN 场景      |
| BR-004      | evidence schema 与 xlib-standard 一致 | JSON 格式 + 必需字段校验 |

## Non-scope

- 不实现 evidence 生成（只读取和校验）
- 不修改 evidence.json 内容（只读检查）
- 不实现与 xlib-standard 的动态 schema 同步
- 不实现 evidence 历史版本比较

## Test Plan

| Test Case | Type | Description                                                         |
| --------- | ---- | ------------------------------------------------------------------- |
| TC-006    | Unit | evidence 完整且通过：exit 0                                         |
| TC-006    | Unit | 缺失项：exit 1，输出缺失列表                                        |
| TC-006    | Unit | 格式无效（非 JSON/缺必需字段）：exit 2                              |
| BR-004    | Unit | evidence schema 与 xlib-standard 一致：JSON 格式校验 + 必需字段检查 |

## Implementation Notes

- 解析 `evidence.json`，检查必需字段
- evidence schema 定义必需项列表
- BR-004 要求 evidence schema 与 xlib-standard 定义的 Evidence 标准一致
- evidence/collector.go 负责收集 evidence 项，evidence/validator.go 负责 schema 校验

## Implementation Plan

| Step | Description                                             | Deliverables                                     | Verification          |
| ---- | ------------------------------------------------------- | ------------------------------------------------ | --------------------- |
| 1    | 实现 `evidence/collector.go` 和 `evidence/validator.go` | `evidence/collector.go`, `evidence/validator.go` | `go build ./...` 通过 |
| 2    | 实现 `check_release.go`：解析 evidence → 校验必需项     | `check_release.go`                               | TC-006 全部通过       |

### Risk Assessment

| Risk                 | Probability | Impact | Mitigation       |
| -------------------- | ----------- | ------ | ---------------- |
| evidence schema 变更 | Low         | Medium | 配置化必需项列表 |
