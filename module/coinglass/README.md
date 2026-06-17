# module/coinglass

`module/coinglass` is the Coinglass-specific Market Data C/S Module for ZoneCNH.

它接入加密衍生品**聚合数据源** Coinglass，是本架构中唯一**非交易所**的数据域 · 行情模块——但仍统一采用 C/S Module 范式，以保证下游 `module/market-data` 的输入面**对来源不敏感**。

```text
module/coinglass/client
module/coinglass/server
```

## Role

`module/coinglass` owns Coinglass-specific data acquisition into ZoneCNH.

- Canonical semantics → `module/domain-market`（衍生品聚合事件类型扩展）
- Wire protocol → `module/contracts`
- Downstream storage / query / fanout → `module/market-data` 及下游分析域 `factor-engine`

## Submodules

| Submodule | Role |
|---|---|
| `module/coinglass/client` | 通过 REST polling 采集 Coinglass 衍生品聚合数据（funding rate、open interest、liquidation、long-short ratio），按窗口规范化为 canonical events，spool + checkpoint，gRPC 发送 |
| `module/coinglass/server` | Coinglass 专属 ingest server，校验、幂等去重（含 polling 重叠窗口）、ACK、下游分发 |

## Pattern Inheritance

本模块结构继承自 [`module/binance`](../binance/) C/S Module 模板。客制化差异：

| 差异点 | 与 binance 不同 |
|--------|----------------|
| 数据来源 | 聚合数据源（非交易所），无原生订单簿 |
| 采集模式 | 主要 REST polling（非 WebSocket 主导） |
| Product line 语义 | `derivatives_aggregate`（非 Spot/Perp/Options） |
| 事件类型 | funding_rate / open_interest / liquidation / long_short_ratio 等聚合事件 |
| Idempotency key | 含 `venue + symbol + window_start`，兼容 polling 重叠窗口 |
| Rate limit | 按 API key 分配（与 CEX 类似，但 quota 显著更小） |

边界门禁与 runtime mapping 引用 binance 同名文档（详见 `BOUNDARY-GATES.md`、`RUNTIME-MAPPING.md`）。

## Removed Legacy

旧 `coinglass` SDK 已硬切移除。GitHub 仓库 `github.com/ZoneCNH/coinglass` 保留并改造为 C/S Module 实现。

## Read Next

- `goal.md`
- `SPEC.md`
- `client/SPEC.md`
- `server/SPEC.md`
- `IMPLEMENTATION-PLAN.md`
- `TRACEABILITY.md`
