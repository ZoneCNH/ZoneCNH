# TASK-MKR-001 Core Implementation

## Objective

实现 market_regime 市场状态判定引擎：趋势/震荡/高波动识别、市场状态机、RegimeCard 生成。

## Covers

All FR/BR/NFR defined in TRACEABILITY.md §1-§3.

## Acceptance Criteria

1. `go test ./... -count=1` 通过
2. `go vet ./...` 零警告

## Dependencies

- domain_market (行情数据)
- market_data (market data dispatch)
- contracts (RegimeCard 契约)
