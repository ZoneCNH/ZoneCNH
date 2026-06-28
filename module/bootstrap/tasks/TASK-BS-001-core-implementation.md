# TASK-BS-001 Core Implementation

## Objective

实现 bootstrap L1 Assembly 核心功能：Build/Run/Shutdown + configx/observex/lifecycle 集成。

## Covers

- FR-001 Build 入口
- FR-002 configx 加载
- FR-003 observex 初始化
- FR-004 stores 可选构造
- FR-005 lifecycle 编排
- FR-006 组件注册
- FR-007 信号捕获
- FR-008 EffectiveConfigHash 暴露

## Acceptance Criteria

1. `go test ./... -count=1` 通过
2. `go vet ./...` 零警告
3. boundary gate 通过
4. Stores=None 端到端就绪

## Dependencies

- kernel (lifecycle, errx, healthx)
- configx / observex / resiliencx
