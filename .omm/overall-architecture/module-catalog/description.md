69 个模块的规格制品目录（module/ 下每个子目录一个模块）。每个模块包含 spec/SPEC.md（规格）、matrix/TRACEABILITY.md（追溯矩阵）、plan/PLAN.md（计划）、tasks/（任务清单）、goal/goal.md（目标）等制品。实现代码不在本仓库，而在 registry.yaml local_path 指向的独立 git 仓库。

模块按域分布：基座层（kernel/configx/observex/...）、L2.5 领域共享层（domain_market/domain_macro/domainx/decimalx）、数据域采集器（market_data/macro_data/binance/fred/...）、分析域、决策域、执行域、入口（x.go/composer）和横切（alertx/observex）。独立展开见 module-catalog perspective。
