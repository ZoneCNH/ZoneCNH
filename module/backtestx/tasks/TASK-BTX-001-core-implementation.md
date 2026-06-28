# TASK-BTX-001 Core Implementation

## Objective

实现 backtestx 核心回测引擎：事件驱动仿真、绩效指标计算、Walk-Forward 优化、Monte Carlo 模拟、压力测试、基准对比、滑点/手续费模型。

## Covers

- FR-001 Event-Driven Simulation
- FR-002 Performance Metrics
- FR-003 Walk-Forward Optimization
- FR-004 Monte Carlo Simulation
- FR-005 Stress Testing
- FR-006 Benchmark Comparison
- FR-007 Slippage and Fee Model
- FR-008 Module Identity

## Acceptance Criteria

1. `go test ./... -count=1` 通过
2. `go vet ./...` 零警告
3. 覆盖率 >= 80%
4. 所有 FR 对应 AC 验证通过

## Dependencies

- domain_market (canonical types)
- positionx (虚拟仓位)
- riskx (风控模拟)
- orderx (订单执行模拟)
