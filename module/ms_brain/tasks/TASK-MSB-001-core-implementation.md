# TASK-MSB-001 Core Implementation

## Objective

实现 ms_brain 微观结构分析引擎：order flow 分析、市场微观结构特征提取、流动性分析。

## Covers

All FR/BR/NFR defined in TRACEABILITY.md §1-§3.

## Acceptance Criteria

1. `go test ./... -count=1` 通过
2. `go vet ./...` 零警告

## Dependencies

- domain_market (行情数据)
- market_data (tick/trade/orderbook 数据)
