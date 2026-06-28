# TASK-HL-001 Core Implementation

## Objective

实现 hyperliquid Hyperliquid 去中心化交易所 C/S Module：行情数据采集、订单簿数据、MarketDataProvider 接口实现。

## Covers

All FR/BR/NFR defined in TRACEABILITY.md §1-§3.

## Acceptance Criteria

1. `go test ./... -count=1` 通过
2. `go vet ./...` 零警告
3. C/S Module 标准结构

## Dependencies

- domain_market (canonical types)
- contracts (MarketDataProvider 接口)
- market_data (dispatch port)
