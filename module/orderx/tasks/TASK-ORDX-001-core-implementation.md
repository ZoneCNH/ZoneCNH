# TASK-ORDX-001 Core Implementation

## Objective

实现 orderx 订单抽象层：Order 生命周期管理、多交易所订单适配、执行报告处理。

## Covers

All FR/BR/NFR defined in TRACEABILITY.md §1-§3.

## Acceptance Criteria

1. `go test ./... -count=1` 通过
2. `go vet ./...` 零警告

## Dependencies

- domainx (Order/Position/ExecutionReport 模型)
- contracts (订单相关契约)
- riskx (风控检查)
