# TASK-ALT-001 Core Implementation

## Objective

实现 alternative_data 另类数据聚合层核心功能：链上数据/社交情绪/新闻 NLP 归一化聚合。

## Covers

- FR-ALT-001 链上数据归一化
- FR-ALT-002 社交情绪归一化
- FR-ALT-003 新闻 NLP 归一化
- FR-ALT-004 聚合层分发

## Acceptance Criteria

1. `go test ./... -count=1` 通过
2. `go vet ./...` 零警告
3. 数据归一化到 canonical 类型

## Dependencies

- contracts (AlternativeDataProvider 接口)
- pe_data (PE 另类数据子模块)
