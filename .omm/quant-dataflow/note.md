DecisionCard 是分析域到决策域的核心契约：action（A/B/C/D/E 五档动作）、profile（agg/mod/... 激进度）、risk_tier（1-5）、template、position_caps、risk_multiplier、conflict（bool）、explain（string）。

三引擎输出：market_regime 产 RegimeSnapshot（regime_state S1-S7、bias L/S/N、trade_permission、confidence、five_dim_scores）；macro_regime 产 RegimeCard（m_state M1-M7、lgip、confidence、data_freshness）。M×S 联合决策矩阵在 regime_engine 中查表。

运行时组装（01-overview §运行时组装）：composer/bootstrap.Build(ctx, Spec{Module, Stores, Hooks}) 组装 App{Config, Observe, Resilience, Lifecycle, ConfigHash}，StoreSet 可选 None/TD/PG/Redis/Kafka/NATS/CH。
