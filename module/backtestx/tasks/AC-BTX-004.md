---
AC-BTX-004:
  module: backtestx
  fr_ref: "FR-004"
  scope: "Monte Carlo Simulation"
  acceptance_criteria: "执行 MonteCarlo(trades, iterations)"
  test_case: "随机打乱交易序列；每次迭代重新计算 Equity Curve 和绩效指标；输出指标分布（mean/median/5th/95th percentile）；MC 95% 置信区间不穿越零收益线时判定稳健"
  status: "Done"
  last_updated: "2026-06-29"
---
