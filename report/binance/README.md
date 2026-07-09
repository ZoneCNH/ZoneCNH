# Binance 模块分析报告

> **分析日期**：2026-07-05
> **代码仓库**：`/home/workspace/binance`（`github.com/ZoneCNH/binance`）
> **执行方式**：4 agent team 并行分析 + 交叉验证

## 报告索引

| 文件 | 内容 |
|------|------|
| [00-summary.md](00-summary.md) | 执行摘要（项目定位、核心结论、关键风险、测试结果） |
| [01-structure.md](01-structure.md) | 代码结构：模块划分、依赖关系、对外接口 |
| [02-features.md](02-features.md) | 功能点清单（17 项逐项确认） |
| [03-static-analysis.md](03-static-analysis.md) | 静态分析：异常处理、边界条件、限频、密钥安全、并发 |
| [04-test-report.md](04-test-report.md) | 测试执行报告与用例设计 |
| [DATA-INTEGRITY-E2E-20260708.md](DATA-INTEGRITY-E2E-20260708.md) | 15 个归档 GAP-E 项的主运行时证据源；替代已归档的 20260701 版本 |
| [orderbook-deep-analysis.md](orderbook-deep-analysis.md) | `knowledge/OrderBook.md` 草稿 vs binance 实现 19 章对照（维度 A/B/C + 同步协议 + Market State Engine 对齐度量化） |
| [ORDERBOOK-REVIEW-MEMO-20260709.md](ORDERBOOK-REVIEW-MEMO-20260709.md) | 对 orderbook-deep-analysis.md 的评审异议：草稿事实性错误、反对 PolicyManager 过度抽象、Market State Engine 域归属 |
| [WHITELIST-LOGIC-ANALYSIS-20260709.md](WHITELIST-LOGIC-ANALYSIS-20260709.md) | 行情流 vs 订单簿白名单逻辑梳理：7 套机制仅 3 套生效、tier 词表冲突、whitelist.yaml/policy.Manager 死代码、订单簿 DepthLevel 断链。**Plan 013 已据此报告完成修复**（tier 词表统一 prime/standard/lite/blocked + tierCapabilityMap + DepthLevel 全链路，2026-07-09） |
| [PRODUCTION-READINESS-DEEP-ANALYSIS-20260709.md](PRODUCTION-READINESS-DEEP-ANALYSIS-20260709.md) | 生产级可发布深度分析：本地 runtime P0 gate 已闭合；覆盖数据流架构、现货/合约/期权/订单簿业务矩阵、canonical event_type 修复、重连队列并发修复、剩余 release evidence 和模块规则/标准升级建议 |

## 一句话总结

Binance 公共行情采集 C/S 模块；当前本地 runtime P0 gates 已恢复，覆盖现货、USDⓈ-M、COIN-M、Options 的公共行情路径与订单簿主路径测试。交易/账户/私有流不在本模块发布口径内；最终 release Go 仍需远端 CI、release tag、live capture、外部依赖 E2E 与 rollback 证据。
