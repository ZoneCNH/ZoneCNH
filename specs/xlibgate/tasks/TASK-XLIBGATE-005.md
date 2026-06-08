# TASK-XLIBGATE-005

> check release 实现

---

```yaml
task_id: TASK-XLIBGATE-005
module: xlibgate
scope: "实现 check release 命令：检查 evidence.json 完整性"
spec_ref:
  - "specs/xlibgate/SPEC.md#FR-004"
files:
  - "check_release.go"
  - "check_release_test.go"
acceptance_criteria:
  - "所有 evidence 项存在且通过：exit 0"
  - "缺失/失败项：输出列表，exit 1"
  - "evidence 文件格式无效：exit 2"
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
| FR-004 | check release：evidence 完整性检查 | 3 个 WHEN/THEN 场景 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| §7.4-1 | Unit | 全部通过：exit 0 |
| §7.4-2 | Unit | 缺失项：exit 1 |
| §7.4-3 | Unit | 格式无效：exit 2 |

## Implementation Notes

- 解析 `evidence.json`，检查必需字段
- evidence schema 定义必需项列表

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `check_release.go`：解析 evidence → 校验必需项 | `check_release.go` | §7.4 全部通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| evidence schema 变更 | Low | Medium | 配置化必需项列表 |
