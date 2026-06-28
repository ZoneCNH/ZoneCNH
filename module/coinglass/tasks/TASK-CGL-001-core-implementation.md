# TASK-CGL-001 Core Implementation

## Objective

实现 coinglass 加密货币衍生品数据采集模块：清算数据、持仓量、资金费率等另类行情数据采集与归一化。

## Covers

All FR/BR/NFR defined in TRACEABILITY.md §1-§3.

## Acceptance Criteria

1. `go test ./... -count=1` 通过
2. `go vet ./...` 零警告
3. 数据归一化到 canonical domain_market 类型

## Dependencies

- domain_market (canonical types)
- market_data (dispatch port)
