# TASK-TRY-001 Core Implementation

## Objective

实现 treasury 美国国债 C/S 采集器：收益率曲线/拍卖/TIC 数据采集、MacroPoint 归一化、MacroDataProvider 实现。

## Covers

- FR-TRY-001 国债收益率曲线采集
- FR-TRY-002 国债拍卖数据采集
- FR-TRY-003 TIC 数据采集
- FR-TRY-004 MacroPoint 归一化
- FR-TRY-005 MacroDataProvider 实现

## Acceptance Criteria

1. `go test ./... -count=1` 通过
2. `go vet ./...` 零警告
3. C/S Module 标准结构 (data_cs_module 模板)

## Dependencies

- domain_macro (MacroPoint canonical)
- contracts (MacroDataProvider 接口)
- data_cs_module (C/S Module 模板)
