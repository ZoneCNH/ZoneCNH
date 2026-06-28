# TASK-XGO-001 Core Implementation

## Objective

实现 x.go 治理 CLI 工具：goalcli + templatex 命令行。

## Covers

- FR-XGO-001 goalcli
- FR-XGO-002 templatex

## Acceptance Criteria

1. `go build ./...` 通过
2. `go vet ./...` 零警告
3. x.go 不参与运行时进程组装

## Dependencies

- xlib_standard (标准事实源)
- xlib_harness (生成器/门禁)
