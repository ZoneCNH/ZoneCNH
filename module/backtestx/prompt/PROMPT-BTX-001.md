# TASK-BTX-001 开发 Prompt

- 上游 Task：[TASK-BTX-001-core-implementation.md](../tasks/TASK-BTX-001-core-implementation.md)
- 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
- 权威 Spec：[SPEC.md](../SPEC.md)

## 任务

实现 backtestx 核心回测引擎：事件驱动仿真、绩效指标、Walk-Forward 优化、Monte Carlo、压力测试。

## 关联需求

FR-001~008（事件驱动/绩效/Walk-Forward/Monte Carlo/压力测试/基准对比/滑点/Module Identity）。

## 实现要点

1. 按时间序列回放 tick/bar 数据
2. 模拟 orderx 订单执行（延迟+滑点+手续费）
3. Walk-Forward 训练/测试窗口分离
4. Monte Carlo 随机打乱交易序列
5. 回测可重现性（deterministic seed + snapshot）
