---
AC-BTX-001:
  module: backtestx
  fr_ref: "FR-001"
  scope: "Event-Driven Simulation"
  acceptance_criteria: "启动 Backtest(config, strategy, data)"
  test_case: "按时间序列顺序回放历史数据（tick/bar）；每个事件驱动 strategy.OnTick/OnBar；模拟 orderx 订单执行（延迟+滑点+手续费）；模拟 riskx 风控；通过 positionx 追踪虚拟仓位"
  status: "Done"
  last_updated: "2026-06-29"
---
