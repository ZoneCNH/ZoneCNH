# TASK-MARKET-DATA-001 downstream dispatch port

| 字段 | 值 |
| --- | --- |
| 状态 | Runtime Pending |
| 优先级 | P0 |
| 来源 | `module/market_data/SPEC.md` |
| 最后更新 | 2026-06-17 |

## 目标

将已发布的 `DownstreamDispatchPort` 文档基线后续落地为可测试实现，供 Binance 与后续交易所 adapter 提交引用 `domain_market` canonical `ProductLine`、`InstrumentKey`、`MarketEventEnvelope` 语义的 market event。

> 当前任务文件是后续实现任务基线；SPEC v1.0.0 已 Approved，运行时实现待 Domain Gate + Contract Gate + Test Gate 通过后启动。

## 前置条件

- `module/domain_market` 已冻结 canonical `MarketEventEnvelope`、quality、`ProductLine` 与 `InstrumentKey` 语义（docs-only baseline 已补充，运行时冻结待后续）。
- `module/contracts` 已决定进程内接口或 wire schema 形态（§8.4 docs-only baseline 已补充）。
- `module/binance` SPEC 已引用本端口作为下游交付边界（OQ-002 已确认）。

## 验收标准

> 以下 runtime checks 为后续实现门禁，不在本任务中声明已执行。

- 支持单条 dispatch 与批量 dispatch。
- 返回 DispatchAck、DispatchReject 或 DispatchFailure。
- 同一 idempotencyKey + 相同 payload fingerprint 返回幂等 ack。
- 同一 idempotencyKey + 不同 payload fingerprint 返回 reject。
- reject/failure 的 retryable 分类可测试。
