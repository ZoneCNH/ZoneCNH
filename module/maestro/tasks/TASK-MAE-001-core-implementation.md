# TASK-MAE-001 Core Implementation

## Objective

实现 maestro 策略编排与调度引擎：策略注册、调度、生命周期管理、多策略并发执行。

## Covers

All FR/BR/NFR defined in TRACEABILITY.md §1-§3.

## Acceptance Criteria

1. `go test ./... -count=1` 通过
2. `go vet ./...` 零警告

## Dependencies

- strategyx (策略接口)
- signal_factory (信号)
- riskx (风控)
