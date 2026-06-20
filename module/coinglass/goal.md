# module/coinglass GOAL

## Purpose

`module/coinglass` defines the Coinglass-specific market_data ingest module for ZoneCNH.

它提供加密衍生品**聚合数据**（funding rate、open interest、liquidation、long-short ratio 等），与 CEX/DEX 不同：Coinglass 不是交易所，**没有自营订单簿**，只对外暴露多家交易所聚合后的衍生品市场结构数据。

它替换旧的 passive `coinglass` SDK，统一为显式 C/S 双端架构：

```text
module/coinglass/client
module/coinglass/server
```

Pattern owner: see [`module/_template/cex-cs-module/README.md`](../_template/cex-cs-module/README.md). Canonical reference: [`module/binance`](../binance/).

## Primary Goal

Provide a reliable, canonical, Coinglass-specific market_data ingestion path for:

- Funding rate（资金费率，跨交易所）
- Open interest（持仓量，跨交易所）
- Liquidation events（爆仓数据流）
- Long-short ratio（多空比）
- Other derivatives aggregates（按 venue capability）

`product_line` 字段在 Coinglass 的语义为 **derivatives_aggregate**，与交易所产品线（Spot/Perp/...）不同。

## Non-Goals

`module/coinglass` does not own:

- 通用 market_data 语义（→ `module/domain_market`）
- wire protocol（→ `module/contracts`）
- Coinglass 数据的 storage / query / dashboard（属于下游分析域 `factor_engine` / 决策域）
- 跨数据源的衍生品聚合算法（如本仓库自营聚合，应另立模块）
- 旧 Coinglass SDK 兼容（硬切）

## Success Criteria

`module/coinglass` is successful when:

1. Coinglass HTTP polling 数据可由 `module/coinglass/client` 采集（不同于 CEX 的 WebSocket 主导，Coinglass 主要是 REST polling）
2. Canonical events 通过 contracts-defined gRPC 传输
3. `module/coinglass/server` 校验、幂等去重、ACK、下游分发
4. 同一 `funding_rate@BTC@binance@2026-06-17T08:00:00` 事件不会因 Coinglass 偶尔延迟回填而被重复 dispatch（idempotency key 含 venue + symbol + window_start）
5. Client checkpoint 仅在 server durable ACK 后推进
6. 旧 `coinglass` SDK 引用零残留
7. 与 CEX C/S Module 共享同一 `MarketDataService` wire contract，下游不感知数据来源差异
