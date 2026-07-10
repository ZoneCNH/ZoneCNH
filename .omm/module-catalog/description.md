module/ 下 68 个模块的规格制品目录（每子目录一个模块）。本仓库只含规格（spec/SPEC.md、matrix/TRACEABILITY.md、plan/PLAN.md、tasks/、goal/goal.md 等），不含实现代码——代码在 registry.yaml local_path 指向的独立 git 仓库。

按域分布（registry.yaml 实测）：基座 foundation 20、数据 data 18、分析 analytics 8、执行 execution 7、决策 decision 6、L2.5 领域共享 5、入口 entry 2（x.go/composer）、横切 crosscut 2（alertx/observex）。三 SSOT 分立：registry（身份）/ FOUNDATION-DEPS（依赖）/ status（成熟度）。
