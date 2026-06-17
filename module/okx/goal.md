# module/okx GOAL

## Purpose

`module/okx` defines the OKX-specific market-data ingest module for ZoneCNH.

It replaces the legacy passive `okx` SDK with a single explicit C/S architecture:

```text
module/okx/client
module/okx/server
```

Pattern owner: see [`module/_template/cex-cs-module/README.md`](../_template/cex-cs-module/README.md). Canonical reference: [`module/binance`](../binance/).

## Primary Goal

Provide a reliable, canonical, OKX-specific market-data ingestion path for:

- Spot
- Margin
- USDⓈ-margined Perpetual / Futures
- Coin-margined Perpetual / Futures
- Options

OKX 五条产品线全部通过 `client/server` 链路统一进入下游 `module/market-data`。

## Non-Goals

`module/okx` does not own:

- generic market-data domain semantics（由 `module/domain-market` 拥有）
- cross-exchange market-data ingestion policy
- market-data storage engine（由 `module/market-data` 拥有）
- query / strategy / order execution APIs（属于其他域）
- OKX trading 下单（本模块仅采集行情）
- 旧 OKX SDK 兼容层（已硬切移除）

## Success Criteria

`module/okx` is successful when:

1. OKX market data can be collected by `module/okx/client` across 5 product lines.
2. Canonical market events transit through contracts-defined gRPC (`MarketDataService`).
3. `module/okx/server` validates, deduplicates, ACKs, and dispatches accepted events.
4. Spot `BTC-USDT`, USDⓈ-M Perp `BTC-USDT-SWAP`, Coin-M Perp `BTC-USD-SWAP`, Futures `BTC-USDT-240628`, Options `BTC-USD-240628-50000-C` produce non-colliding canonical instrument identities.
5. Client checkpoints advance only after durable server ACK.
6. No code or documentation reintroduces the legacy passive `okx` SDK.
7. Client/server internals remain separated by boundary gates.
