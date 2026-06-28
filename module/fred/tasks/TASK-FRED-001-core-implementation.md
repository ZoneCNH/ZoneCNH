# TASK-FRED-001 Core Implementation

## Objective

实现 fred FRED 宏观经济数据 C/S 采集器：FRED API 数据采集、MacroPoint 归一化、MacroDataProvider 接口实现。

## Covers

All FR/BR/NFR defined in TRACEABILITY.md §1-§3.

## Acceptance Criteria

1. `go test ./... -count=1` 通过
2. `go vet ./...` 零警告
3. C/S Module 标准结构（client/server/wire）

## Dependencies

- domain_macro (MacroPoint canonical 类型)
- contracts (MacroDataProvider 接口)
- data_cs_module (C/S Module 模板)
