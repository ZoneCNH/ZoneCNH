# TASK-OPT-001 Core Implementation

## Objective

实现 optimizer 组合优化器：均值-方差优化、风险平价、Black-Litterman、约束优化。

## Covers

All FR/BR/NFR defined in TRACEABILITY.md §1-§3.

## Acceptance Criteria

1. `go test ./... -count=1` 通过
2. `go vet ./...` 零警告

## Dependencies

- factor_engine (因子数据)
- riskx (风险模型)
