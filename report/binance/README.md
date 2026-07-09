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

## 一句话总结

Binance 行情数据采集 C/S 模块，交易适配器覆盖现货下单/撤单/查询（合约未实现），行情侧覆盖四产品线 K线/深度/WS 实时推送，存储层四套（TDengine+ClickHouse+OSS+PG）完整带降级。核心包覆盖率 100%，`go vet`/race 零告警。主要风险：限频逻辑已实现未接线、SubmitOrder 无客户端参数校验、StreamExecutions 阻塞读不响应 ctx 取消。
