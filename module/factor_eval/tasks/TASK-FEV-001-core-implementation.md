# TASK-FEV-001 Core Implementation

## Objective

实现 factor_eval 因子评估模块：IC 分析、分层回测、因子衰减分析、因子相关性矩阵。

## Covers

All FR/BR/NFR defined in TRACEABILITY.md §1-§3.

## Acceptance Criteria

1. `go test ./... -count=1` 通过
2. `go vet ./...` 零警告

## Dependencies

- factor_engine (因子数据)
- backtestx (回测引擎)
- domain_market (行情数据)
