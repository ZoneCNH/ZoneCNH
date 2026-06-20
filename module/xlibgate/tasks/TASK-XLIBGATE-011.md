# TASK-XLIBGATE-011

> trust identity 实现

---

```yaml
task_id: TASK-XLIBGATE-011
module: xlibgate
scope: "实现 trust identity 命令：五源身份比对（README H1 / go.mod / .repo-contract.yaml / public_package / 身份声明）"
spec_ref:
  - "module/xlibgate/SPEC.md#FR-012"
  - "module/xlibgate/SPEC.md#TC-014"
  - "module/xlibgate/SPEC.md#TC-015"
files:
  - "cmd/trust_identity.go"
  - "scanner/trust/identity.go"
acceptance_criteria:
  - "AC-011: 五源一致 → exit 0, reason_code=\"\""
  - "AC-011: README H1 不匹配 → exit 1, reason_code=IDENTITY_MISMATCH"
  - "AC-011: go.mod module 不匹配 → exit 1, reason_code=IDENTITY_MISMATCH"
  - "AC-011: 下游仓库声称 xlib_standard 身份 → exit 1, reason_code=IDENTITY_MISMATCH"
  - "AC-011: 缺少 public_package → exit 1, reason_code=IDENTITY_MISMATCH"
  - "AC-011: .repo-contract.yaml 缺失 → exit 2, reason_code=CONTRACT_PARSE_ERROR"
depends_on:
  - "TASK-XLIBGATE-010"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description                                                  | Acceptance Criteria |
| ----------- | ------------------------------------------------------------ | ------------------- |
| FR-012      | trust identity：五源比对                                     | 5 pass/fail + 1 error 路径 |
| TC-014      | trust identity pass                                          | 五源一致 → exit 0   |
| TC-015      | trust identity mismatch                                      | README H1 不匹配 → exit 1 |

## Non-scope

- 不检查 SPEC.md 内容格式（仅标题比对）
- 不验证 go.mod 依赖版本

## Test Plan

| Test Case | Type | Description                              |
| --------- | ---- | ---------------------------------------- |
| TC-014    | Unit | 五源一致 → pass                          |
| TC-015    | Unit | README H1 不匹配 → IDENTITY_MISMATCH     |
| —         | Unit | go.mod module 不匹配 → IDENTITY_MISMATCH |
| —         | Unit | 下游声称 Standard Source → IDENTITY_MISMATCH |
| —         | Unit | 缺少 public_package → IDENTITY_MISMATCH  |
| —         | Unit | .repo-contract.yaml 缺失 → CONTRACT_PARSE_ERROR |
