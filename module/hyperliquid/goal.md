# module/hyperliquid GOAL

## Purpose

`module/hyperliquid` defines the Hyperliquid-specific market-data ingest module for ZoneCNH.

It replaces the legacy passive `hyperliquid` SDK with a single explicit C/S architecture:

```text
module/hyperliquid/client
module/hyperliquid/server
```

Pattern owner: see [`module/_template/cex-cs-module/README.md`](../_template/cex-cs-module/README.md). Canonical reference: [`module/binance`](../binance/).

## Primary Goal

Provide a reliable, canonical, Hyperliquid-specific market-data ingestion path for:

- Perpetual（USDⓈ-margined，唯一产品线）
- Spot（部分支持，按 venue capability）

Hyperliquid 是去中心化永续合约 DEX，与 CEX 在以下维度有显著差异：

- 链上结算（Arbitrum One / Hyperliquid L1），事件含 onchain block height + tx hash
- WebSocket 鉴权机制基于 wallet signature 而非 API key
- Rate limit 按 wallet address 分配
- 无 sub-account 概念

## Non-Goals

`module/hyperliquid` does not own:

- 跨交易所 market-data 通用语义（→ `module/domain-market`）
- wire protocol（→ `module/contracts`）
- 链上交易签名 / 钱包管理（属于执行域 `order-engine` 与 wallet 模块）
- onchain query API（属于其他模块）
- DEX 链上撮合机制（不是数据域职责）
- 旧 hyperliquid SDK 兼容（硬切）

## Success Criteria

`module/hyperliquid` is successful when:

1. Hyperliquid market data can be collected by `module/hyperliquid/client` across Perp 与可用的 Spot 产品线
2. Canonical events 通过 contracts-defined gRPC 传输
3. `module/hyperliquid/server` validates, deduplicates, ACKs, dispatches downstream
4. Hyperliquid Perp `BTC` 与未来可能加入的其他 venue 的同名 symbol 产生非碰撞 canonical identity（通过 `exchange=hyperliquid` 维度区分）
5. 链上事件的 `block_height` + `tx_hash` 维度纳入 idempotency key，避免链 reorg 后重复 dispatch
6. Client checkpoint 仅在 server durable ACK 后推进
7. No legacy passive `hyperliquid` SDK 引用残留
