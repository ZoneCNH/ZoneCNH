# TASK-CMP-001 Core Implementation

## Objective

实现 composer 运行时组合根：25 进程编排、依赖注入、HTTP health、Docker Compose、RegimeCoordinator。

## Covers

- FR-CMP-001 进程编排
- FR-CMP-002 依赖注入与生命周期管理
- FR-CMP-003 HTTP health
- FR-CMP-004 Docker Compose
- FR-CMP-005 RegimeCoordinator

## Acceptance Criteria

1. `go test ./... -count=1` 通过
2. `go vet ./...` 零警告
3. composer 只做组装，不参与业务链路计算

## Dependencies

- bootstrap (进程组装)
- configx / observex / resiliencx
