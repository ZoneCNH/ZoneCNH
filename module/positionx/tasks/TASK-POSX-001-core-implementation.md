# TASK-POSX-001 Core Implementation

## Objective

实现 positionx 持仓管理：Position 追踪、盈亏计算、持仓风险指标。

## Covers

All FR/BR/NFR defined in TRACEABILITY.md §1-§3.

## Acceptance Criteria

1. `go test ./... -count=1` 通过
2. `go vet ./...` 零警告

## Dependencies

- domainx (Position 模型)
- orderx (订单执行)
- riskx (风控)
