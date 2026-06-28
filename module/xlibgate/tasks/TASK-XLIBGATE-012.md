# TASK-XLIBGATE-012

> trust template-residue 实现

---

```yaml
task_id: TASK-XLIBGATE-012
module: xlibgate
scope: "实现 trust template-residue 命令：扫描下游仓库中的 BR-010 禁止模板身份短语"
spec_ref:
  - "module/xlibgate/spec/SPEC.md#FR-013"
  - "module/xlibgate/spec/SPEC.md#BR-010"
  - "module/xlibgate/spec/SPEC.md#TC-016"
  - "module/xlibgate/spec/SPEC.md#TC-017"
files:
  - "cmd/trust_template.go"
  - "scanner/trust/template.go"
acceptance_criteria:
  - "AC-012: 下游仓库无禁止短语 → exit 0, reason_code=\"\""
  - "AC-012: 下游仓库含禁止短语 → exit 1, reason_code=TEMPLATE_RESIDUE"
  - "AC-012: xlib_standard 仓库 → exit 0, reason_code=TEMPLATE_RESIDUE_SELF_SKIP"
  - "AC-012: --summary 输出命中统计"
  - "AC-012: 二进制文件跳过不扫描"
depends_on:
  - "TASK-XLIBGATE-010"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description                                      | Acceptance Criteria |
| ----------- | ------------------------------------------------ | ------------------- |
| FR-013      | trust template-residue：禁止短语扫描             | 4 个 WHEN 路径      |
| BR-010      | 5 条禁止模板身份短语，精确字符串匹配             | 仅 xlib_standard 豁免 |

## Non-scope

- 不做模糊匹配或正则匹配（BR-010 要求精确字符串）
- 不扫描二进制文件

## Test Plan

| Test Case | Type | Description                           |
| --------- | ---- | ------------------------------------- |
| TC-016    | Unit | 无禁止短语 → pass                     |
| TC-017    | Unit | 含 "承担五类职责..." → TEMPLATE_RESIDUE |
| —         | Unit | xlib_standard target → self-skip      |
| —         | Unit | --summary 输出统计                    |
