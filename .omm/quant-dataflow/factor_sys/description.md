因子三元组：factor_engine（alpha 因子计算）⇄ feature_store（特征版本管理）⇄ factor_eval（IC/IR 评估）。与 regime_engine 协作输入 signal_factory。回测结果经 factor_eval 反馈调整因子权重，形成自我改进回路。
