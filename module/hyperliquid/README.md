# module/hyperliquid

`module/hyperliquid` is the Hyperliquid-specific Market Data C/S Module for ZoneCNH.

It is split into two submodules:

```text
module/hyperliquid/client
module/hyperliquid/server
```

Hyperliquid 是 ZoneCNH 接入的首个**去中心化交易所（DEX）**，与 CEX 在鉴权、链上事件、speed-throttle 等维度差异显著。本模块在 binance C/S Module 模板基础上声明 DEX 特异性。

## Role

`module/hyperliquid` owns Hyperliquid-specific market_data ingestion into ZoneCNH.

- Canonical semantics → `module/domain_market`
- Wire protocol → `module/contracts`
- Downstream storage / query / fanout → `module/market_data`

## Submodules

| Submodule | Role |
|---|---|
| `module/hyperliquid/client` | 连接 Hyperliquid WebSocket（wallet-signed auth），采集 Perp + Spot 行情，包含 onchain metadata（block_height、tx_hash），spool + checkpoint，gRPC 发送 |
| `module/hyperliquid/server` | Hyperliquid 专属 ingest server，校验、幂等去重（含链上 reorg 兼容）、ACK、下游分发 |

## Pattern Inheritance

本模块结构继承自 [`module/binance`](../binance/) C/S Module 模板。客制化差异：

| 差异点 | 与 binance 不同 |
|--------|----------------|
| 鉴权 | wallet signature（非 API key） |
| 产品线 | 仅 Perp + Spot（无 COIN-M / Options） |
| 事件元数据 | 必须包含 `block_height`、`tx_hash`（onchain origin） |
| Idempotency key | 维度增加 `block_height` 以兼容链 reorg |
| Rate limit | 按 wallet address 分配（非 IP / API key） |

边界门禁与 runtime mapping 引用 binance 同名文档（详见 `BOUNDARY-GATES.md`、`RUNTIME-MAPPING.md`）。

## Removed Legacy

旧 `hyperliquid` SDK 已硬切移除。GitHub 仓库 `github.com/ZoneCNH/hyperliquid` 保留并改造为 C/S Module 实现。

## Read Next

- `goal.md`
- `SPEC.md`
- `client/SPEC.md`
- `server/SPEC.md`
- `IMPLEMENTATION-PLAN.md`
- `TRACEABILITY.md`
