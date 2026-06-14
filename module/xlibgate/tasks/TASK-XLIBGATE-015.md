# TASK-XLIBGATE-015

> trust import-boundary 实现

---

```yaml
task_id: TASK-XLIBGATE-015
module: xlibgate
scope: "实现 trust import-boundary 命令：消费 FOUNDATION-DEPS.yaml 的 allowed_deps 和 forbidden_foundation_edges"
spec_ref:
  - "module/xlibgate/SPEC.md#FR-016"
  - "module/xlibgate/SPEC.md#TC-022"
  - "module/xlibgate/SPEC.md#TC-023"
files:
  - "cmd/trust_boundary.go"
  - "scanner/trust/boundary.go"
acceptance_criteria:
  - "AC-015: import 符合 allowed_deps 且不违反 forbidden_foundation_edges → exit 0"
  - "AC-015: 违反 allowed_deps 或 forbidden_foundation_edges → exit 1, reason_code=IMPORT_BOUNDARY_VIOLATION"
  - "AC-015: kernel 导入非 stdlib → 标记为 kernel_stdlib_violation, reason_code=IMPORT_BOUNDARY_VIOLATION"
  - "AC-015: FOUNDATION-DEPS.yaml 缺失 → exit 2, reason_code=CONTRACT_PARSE_ERROR"
depends_on:
  - "TASK-XLIBGATE-010"
estimated_effort: "3h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description                                                    |
| ----------- | -------------------------------------------------------------- |
| FR-016      | trust import-boundary：FOUNDATION-DEPS.yaml 驱动的 import 边界 |
| TC-022      | import 合规 → pass                                             |
| TC-023      | 违反 forbidden edge → IMPORT_BOUNDARY_VIOLATION                |

## Non-scope

- 不实现 check imports 的 deps.yaml 逻辑（check 版独立实现）
- 不解析间接依赖图

## Test Plan

| Test Case | Type | Description                              |
| --------- | ---- | ---------------------------------------- |
| TC-022    | Unit | import 合规 → pass                       |
| TC-023    | Unit | binance import kernel → IMPORT_BOUNDARY_VIOLATION |
| —         | Unit | kernel 导入非 stdlib → kernel_stdlib_violation |
| —         | Unit | FOUNDATION-DEPS.yaml 缺失 → CONTRACT_PARSE_ERROR |
