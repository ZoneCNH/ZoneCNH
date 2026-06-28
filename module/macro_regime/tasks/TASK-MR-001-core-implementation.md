# TASK-MR-001 Core Implementation

## Objective

实现 macro_regime 宏观状态判定引擎：经济周期识别、宏观状态机、状态转变检测。

## Covers

All FR/BR/NFR defined in TRACEABILITY.md §1-§3.

## Acceptance Criteria

1. `go test ./... -count=1` 通过
2. `go vet ./...` 零警告

## Dependencies

- domain_macro (MacroPoint/MacroState)
- macro_data (宏观数据)
