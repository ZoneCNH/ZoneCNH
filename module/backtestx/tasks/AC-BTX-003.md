---
AC-BTX-003:
  module: backtestx
  fr_ref: "FR-003"
  scope: "Walk-Forward Optimization"
  acceptance_criteria: "执行 WalkForward(config, strategy, paramSpace, data)"
  test_case: "将历史数据分为多个训练/测试窗口；每个窗口训练集优化参数→测试集评估；最终参数=各窗口最优参数平均值"
  status: "Done"
  last_updated: "2026-06-29"
---
