# TASK-CONTRACTS-004

> 文档 + Release DoD

---

```yaml
task_id: TASK-CONTRACTS-004
module: contracts
scope: "创建 README、CHANGELOG，验证 Release DoD"
spec_ref:
  - "module/contracts/SPEC.md#FR-006"
  - "module/contracts/SPEC.md#BR-002"
  - "module/contracts/SPEC.md#NFR-004"
  - "module/contracts/SPEC.md#NFR-007"
files:
  - "README.md"
  - "CHANGELOG.md"
acceptance_criteria:
  - "AC-FR-005: CHANGELOG.md 记录所有 breaking changes"
  - "AC-BR-002: README 包含消费方/生产方/稳定期说明"
  - "AC-NFR-004: gitleaks 扫描通过"
  - "AC-NFR-007: README/CHANGELOG/godoc 齐全"
depends_on:
  - "TASK-CONTRACTS-001"
  - "TASK-CONTRACTS-002"
  - "TASK-CONTRACTS-003"
estimated_effort: "1h"
priority: P1
status: pending
non_scope:
  - "不编写Go代码（纯文档）"
  - "不修改SPEC（已完成）"
```

---

## Requirements Covered

| Requirement | Description   | Acceptance Criteria           |
| ----------- | ------------- | ----------------------------- |
| FR-006      | BC 变更记录   | AC-FR-005: CHANGELOG 记录 |
| BR-002      | 契约三方说明   | AC-BR-002: README 含消费方/生产方/稳定期 |
| NFR-004     | Secret 扫描   | AC-NFR-004: gitleaks 通过 |
| NFR-007     | 文档齐全      | AC-NFR-007: README+CHANGELOG+godoc |

## Test Plan

| Test Case | Type    | Description           |
| --------- | ------- | --------------------- |
| TC-003    | CI Gate | go build 编译通过 |
| TC-003    | CI Gate | gitleaks Secret 扫描 |
| TC-003    | Review  | README 模块定位/端口概览/消费方说明 |

## Implementation Notes

- README 说明 contracts 是跨域接口契约包

## Implementation Plan

| Step | Description       | Deliverables   | Verification |
| ---- | ----------------- | -------------- | ------------ |
| 1    | 创建 README.md    | `README.md`    | 人工 review  |
| 2    | 创建 CHANGELOG.md | `CHANGELOG.md` | 格式正确     |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| 无   | Low         | Low    | —          |
