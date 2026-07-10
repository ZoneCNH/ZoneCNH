业务架构模型：基座 → 数据域 → 分析域 ⇄ 决策域 → 执行域 → x.go。分析域与决策域是唯一双向关系（因子驱动信号生成，回测反馈因子评估）。横切 alertx/observex 贯穿所有域。

模块命名强制 snake_case（仅 x.go 与 binance.rs 例外）。Go module 路径须与仓库名一致（module github.com/ZoneCNH/<module>）。新增模块须双闸门授权（§2.6：治理层 §12 修正程序 + 执行层人工会话显式授权）。

每个模块仓库通过 registry.yaml 的 repo（github.com/ZoneCNH/<module>）和 local_path（指向该模块独立 git 仓库）字段桥接到本仓库规格。
