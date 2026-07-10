决策域 decision，6 模块。signal_factory（信号生成/组合）、optimizer（参数优化/Walk-forward）、strategyx（策略管理）、backtestx（事件驱动回测）、backtest_engine、maestro（编排注入）。与执行域通过 riskx 衔接，与因子体系形成反馈回路（回测结果反馈 factor_eval）。
