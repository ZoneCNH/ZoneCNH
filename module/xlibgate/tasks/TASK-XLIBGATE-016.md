# TASK-XLIBGATE-016

> trust testkit-prod-import 实现

---

```yaml
task_id: TASK-XLIBGATE-016
module: xlibgate
scope: "实现 trust testkit-prod-import 命令：检测生产代码中的 testkitx import"
spec_ref:
  - "module/xlibgate/SPEC.md#FR-017"
  - "module/xlibgate/SPEC.md#TC-024"
  - "module/xlibgate/SPEC.md#TC-025"
files:
  - "cmd/trust_testkit.go"
  - "scanner/trust/testkit.go"
acceptance_criteria:
  - "AC-016: 生产代码无 testkitx import → exit 0"
  - "AC-016: 生产代码有 testkitx import → exit 1, reason_code=TESTKIT_PROD_IMPORT"
  - "AC-016: *_test.go / test/ / testkit/ / examples/ → 不触发违规"
  - "AC-016: --strict 模式下 internal/ 非 test 子目录 → 视为生产代码"
depends_on:
  - "TASK-XLIBGATE-010"
estimated_effort: "1.5h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description                                              |
| ----------- | -------------------------------------------------------- |
| FR-017      | trust testkit-prod-import：testkitx 生产隔离             |
| TC-024      | test 文件有 testkitx 但生产代码无 → pass                 |
| TC-025      | pkg/ 中 import testkitx → TESTKIT_PROD_IMPORT            |

## 路径分类规则

| 路径模式         | 判定     |
| ---------------- | -------- |
| pkg/             | 生产代码 |
| internal/        | 生产代码（--strict 含子目录） |
| internal/test*   | 允许     |
| cmd/ (生产二进制) | 生产代码 |
| cmd/test*        | 允许     |
| *_test.go        | 允许     |
| test/            | 允许     |
| testkit/         | 允许     |
| examples/        | 允许     |

## Non-scope

- 不检查 go.mod 中的 testkitx 依赖（仅检查源码 import）

## Test Plan

| Test Case | Type | Description                              |
| --------- | ---- | ---------------------------------------- |
| TC-024    | Unit | 生产无 testkitx，test 文件有 → pass      |
| TC-025    | Unit | pkg/ 有 testkitx → TESTKIT_PROD_IMPORT   |
| —         | Unit | --strict 模式 internal/ → 检查           |
