决策域回测路径。事件驱动回测引擎，与实盘共享 factor/signal/risk 代码（P6）。回测结果经 optimizer（Walk-forward 参数优化）反馈 factor_eval 调整因子权重，最终沉淀为 strategyx 策略。
