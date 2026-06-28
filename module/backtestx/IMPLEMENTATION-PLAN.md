# backtestx 实现计划

> 来源：[SPEC.md](./SPEC.md) v1.0.0 | 生成日期：2026-06-29

## Phase 1: Core Engine

| Task | Scope | Effort |
|------|-------|--------|
| TASK-BTX-001 | 事件驱动仿真/绩效指标/Walk-Forward/Monte Carlo/压力测试 | 8h |

## CI Gate

| Gate | 条件 |
|------|------|
| go build | 零错误 |
| go test -race | 全部通过 |
| coverage >= 80% | 达标 |
| go vet | 零警告 |

## 风险

| 风险 | 缓解 |
|------|------|
| 回测结果可重现性 | deterministic seed + snapshot |
