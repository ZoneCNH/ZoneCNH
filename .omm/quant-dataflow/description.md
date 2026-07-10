FoundationX 量化交易系统的业务数据流（活跃事实链路见 docs/architecture/01-overview.md / 08-contracts.md；详尽图谱见 06-dataflow.md）。主线：基座 → 数据域 → 分析域 ⇄ 决策域 → 执行域 → x.go。

数据从数据域采集器进入，经 L2.5 领域共享层质量门禁（MarketEventEnvelope 信封）后供分析域。分析域三引擎（market_regime/macro_regime/regime_engine）融合产出 DecisionCard。决策域据此生成信号，回测路径形成因子反馈回路。执行域 riskx→orderx→positionx→settlement 落单并回流 fills/PnL 形成闭环。
