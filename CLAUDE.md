# Claude 工作指南

本文件说明 Claude Code 在本仓库中工作时应遵循的约束。

## 本仓库定位

本仓库是 ZoneCNH 的 `FoundationX` 量化交易基础设施文档枢纽，也是 `ZoneCNH/ZoneCNH` GitHub 个人主页仓库，其中 `README.md` 会渲染到个人主页。

本仓库不包含应用代码，核心内容是 Markdown 文档：

- `README.md`：个人主页、技术栈、分层架构摘要和组件仓库索引。
- `ARCHITECTURE.md`：依赖拓扑、领域职责、设计原则和状态表的权威文档。
- `AGENTS.md` / `CLAUDE.md`：面向自动化代理和贡献者的工作指南。

实际实现位于 `github.com/ZoneCNH` 下约 60 个独立仓库，例如 `kernel`、`binance`、`factor-engine`、`risk-engine`、`x.go`。本仓库只描述和链接这些模块，不承载它们的源码。

这里没有构建、lint 或测试步骤；主要工作是编辑 Markdown。

## 保持文档同步

`README.md` 和 `ARCHITECTURE.md` 从不同角度描述同一套系统，因此一个文件的架构变化通常需要同步到另一个文件：

- 新增或移除组件时，同时更新 `README.md` 的目录表，以及 `ARCHITECTURE.md` 的状态表和依赖图。
- 修改组件所属领域或分组时，同步更新两个文件中的 ASCII 依赖图，以及“各域说明”“数据域子模块明细”等相关章节。
- 图中的组件数量，例如 `market-data (19)`、`macro-data (10)`，必须与实际列出的表格行数一致。

`ARCHITECTURE.md` 的状态表是组件版本、状态和进度的事实来源。组件状态变化时，应优先更新该表。

## 当前架构模型

系统采用分层领域模型，而不是编号层级。依赖按数据流方向向下，同一领域内模块平级协作：

```text
基座 → 数据域 → 分析域 ⇄ 决策域 → 执行域 → x.go
```

- **基座**：生命周期、依赖注入、配置、可观测、存储和契约，包括 `kernel`、`configx`、`observex`、`contracts`、`redisx`、`kafkax` 等；同时包含 L2.5 领域共享层 `decimalx`、`domain-market`、`domain-exchange`、`domain-macro`。
- **数据域**：market-data、macro-data、alternative-data 采集器，按交易所或数据源拆分。
- **分析域 ⇄ 决策域**：唯一双向关系；因子驱动信号生成，回测结果反馈到因子评估。
- **横切**：`alertx` 和 `observex` 贯穿所有领域。

编辑时必须保留 `ARCHITECTURE.md` 中七条核心设计原则的意图：策略只能通过 `risk-engine` 提交订单；回测与实盘共享因子、信号和风控代码；`contracts` 定义跨域接口；数据不跨域；`order-engine` 抽象交易所差异；`x.go` 只做编排；域内模块平级协作。

## 约定

- **语言**：所有文档和提交信息默认使用中文，英文保留给仓库名、模块名、命令和标准技术术语。
- **提交**：使用 Conventional Commits 前缀和中文描述，例如 `docs:`、`feat:`、`refactor:`、`fix:`。
- **链接**：引用组件时，使用既有表格风格的 `https://github.com/ZoneCNH/<repo>` 链接。
- **安全**：不要提交凭证、API key、账户 ID、私有端点或实盘交易配置。
