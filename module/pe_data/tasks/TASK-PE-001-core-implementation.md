# TASK-PE-001 Core Implementation

## Objective

实现 pe_data PE 另类数据采集：13F/内部交易/机构持仓采集、PEvent 归一化、AlternativeDataProvider 实现。

## Covers

- FR-PE-001 13F 数据采集
- FR-PE-002 内部人交易采集
- FR-PE-003 机构持仓变化检测
- FR-PE-004 PE 事件归一化
- FR-PE-005 数据时效性管理

## Acceptance Criteria

1. `go test ./... -count=1` 通过
2. `go vet ./...` 零警告
3. AlternativeDataProvider 接口实现
4. 免费数据源 rate limit 遵守

## Dependencies

- contracts (AlternativeDataProvider 接口)
- domain_market (InstrumentKey canonical)
