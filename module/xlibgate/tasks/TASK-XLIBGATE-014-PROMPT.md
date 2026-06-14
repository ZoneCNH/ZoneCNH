# Context Packet — TASK-XLIBGATE-014

> trust maturity --factory：11 维工厂级成熟度判定
> 来源：SPEC.md v1.1.1 FR-015, TC-020, TC-021

## Current Task

TASK-XLIBGATE-014: 实现 trust maturity --factory 命令，11 维工厂级成熟度判定

## Related Spec

- module/xlibgate/SPEC.md FR-015 (trust maturity)
- module/xlibgate/SPEC.md TC-020 (factory pass), TC-021 (factory blocked)

## Scope

| Deliverable | Description |
|-------------|-------------|
| cmd/trust_maturity.go | CLI 命令入口，--factory 参数 |
| scanner/trust/maturity.go | 11 维判定逻辑 |

### 11 维判定维度

`spec_complete`, `implementation_complete`, `unit_tests_complete`, `contract_tests_complete`, `traceability_complete`, `release_manifest_complete`, `live_integration_complete`, `failure_profiles_complete`, `external_ci_artifacts_complete`, `downstream_adoption_complete`, `production_soak_complete`

### 规则

- 所有 11 维必须为 true 方可通过
- 拒绝单个 "100%" 百分比值 —— 必须逐维判定
- 数据来源：.repo-contract.yaml maturity 节

## Non-Scope

- 不自动修复未满足维度
- 不倒推维度数据来源

## Acceptance Criteria

- TC-020: 11 维全 true → exit 0
- TC-021: unit_tests_complete=false → exit 1, FACTORY_GATE_BLOCKED
- 单百分比值 → exit 1, FACTORY_GATE_BLOCKED
- maturity 节缺失 → exit 2, CONTRACT_PARSE_ERROR

## Constraints

- 11 维枚举在代码中定义为常量列表
- 输出 JSON evidence 字段含 11 维逐项判定明细
- 统一 JSON 输出

## Validation

```bash
xlibgate trust maturity --factory --repo testdata/trust-pass 2>&1; [ $? -eq 0 ]
xlibgate trust maturity --factory --repo testdata/trust-bad-maturity 2>&1; [ $? -eq 1 ]
```
