# TASK-STG-001 Core Implementation

## Objective

实现 strategyx 策略框架：策略接口定义、信号生成、策略参数管理、策略组合。

## Covers

All FR/BR/NFR defined in TRACEABILITY.md §1-§3.

## Acceptance Criteria

1. `go test ./... -count=1` 通过
2. `go vet ./...` 零警告

## Dependencies

- signal_factory (信号管线)
- factor_engine (因子数据)
- riskx (风控检查)
- orderx (订单执行)
