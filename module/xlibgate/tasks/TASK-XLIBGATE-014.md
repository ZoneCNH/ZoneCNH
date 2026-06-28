# TASK-XLIBGATE-014

> trust maturity 实现

---

```yaml
task_id: TASK-XLIBGATE-014
module: xlibgate
scope: "实现 trust maturity --factory 命令：11 维工厂级成熟度判定"
spec_ref:
  - "module/xlibgate/spec/SPEC.md#FR-015"
  - "module/xlibgate/spec/SPEC.md#TC-020"
  - "module/xlibgate/spec/SPEC.md#TC-021"
files:
  - "cmd/trust_maturity.go"
  - "scanner/trust/maturity.go"
acceptance_criteria:
  - "AC-014: 11 维全 true → exit 0, reason_code=\"\""
  - "AC-014: 任一维度 false → exit 1, reason_code=FACTORY_GATE_BLOCKED"
  - "AC-014: 数据源仅提供单个百分比 → exit 1, reason_code=FACTORY_GATE_BLOCKED"
  - "AC-014: maturity 节缺失 → exit 2, reason_code=CONTRACT_PARSE_ERROR"
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
| FR-015      | trust maturity --factory：11 维工厂级判定                |
| TC-020      | 11 维全 true → pass                                      |
| TC-021      | 部分维度 false → FACTORY_GATE_BLOCKED                    |

## 11 判定维度

`spec_complete`, `implementation_complete`, `unit_tests_complete`, `contract_tests_complete`, `traceability_complete`, `release_manifest_complete`, `live_integration_complete`, `failure_profiles_complete`, `external_ci_artifacts_complete`, `downstream_adoption_complete`, `production_soak_complete`

## Non-scope

- 不自动修复未满足维度
- 不倒推维度数据来源（数据来自 .repo-contract.yaml）

## Test Plan

| Test Case | Type | Description                           |
| --------- | ---- | ------------------------------------- |
| TC-020    | Unit | 11 维全 true → pass                   |
| TC-021    | Unit | 部分维度 false → FACTORY_GATE_BLOCKED |
| —         | Unit | 单百分比拒绝 → FACTORY_GATE_BLOCKED   |
| —         | Unit | maturity 节缺失 → CONTRACT_PARSE_ERROR |
