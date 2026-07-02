# alternative_data Goal

| 字段 | 值 |
| --- | --- |
| 模块 | `alternative_data` |
| 层级 | 数据域 · 另类数据（独立进程聚合层） |
| 仓库 | <https://github.com/ZoneCNH/alternative_data> |
| 当前版本 | v0.1.0-draft |
| 目标版本 | v0.1.0 |
| 状态 | Draft — 占位规格，完整 23 节 SPEC 待进入 Spec-Code 管线时补齐 |
| 最后更新 | 2026-06-29 |

## 目标

`alternative_data` 是另类数据聚合层（独立进程），整合链上数据（on-chain）、社交情绪（social sentiment）、新闻 NLP 等非结构化数据源，归一化为统一的信号/特征输入，供下游 factor_engine / signal_factory 消费。

## 非目标

- 不实现具体数据源爬取（→ 子模块/采集器）
- 不实现信号生成（→ signal_factory）
- 不实现数据持久化（聚合层只做分发协调）
- 不替代 market_data 或 macro_data 的职责

## 数据域定位

alternative_data 与 market_data / macro_data 并列，构成数据域三大聚合层：

| 聚合层 | 数据类型 | 子模块/采集器 |
| --- | --- | --- |
| market_data | 行情数据 | binance/okx/hyperliquid/coinglass |
| macro_data | 宏观经济数据 | fred/treasury |
| alternative_data | 另类数据 | pe_data 等 |

## 当前阻塞

| 优先级 | 阻塞项 | 处理方向 |
| --- | --- | --- |
| P0 | SPEC 仍为 Draft 占位规格 | 补齐 23 节完整 SPEC（FR/BR/NFR/AC/TC） |
| P0 | alternative_data 与 pe_data 边界未定 | 明确 pe_data 是子模块还是独立采集器 |
| P1 | 链上数据源清单待确认 | Glassnode/Etherscan/Chainlink 优先级排序 |
| P2 | 无 TRACEABILITY 矩阵 | SPEC 补全后创建 |
