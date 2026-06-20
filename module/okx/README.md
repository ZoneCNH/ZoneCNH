# module/okx

`module/okx` is the OKX-specific Market Data C/S Module for ZoneCNH.

It is split into two submodules:

```text
module/okx/client
module/okx/server
```

## Role

`module/okx` owns OKX-specific market_data ingestion into ZoneCNH.

- Canonical semantics → `module/domain_market`
- Wire protocol → `module/contracts`
- Downstream storage / query / fanout → `module/market_data` 及下游模块

## Submodules

| Submodule | Role |
|---|---|
| `module/okx/client` | 连接 OKX REST/WebSocket，解析 5 条产品线，规范化为 canonical events，spool + checkpoint，gRPC 发送至 server |
| `module/okx/server` | OKX 专属 ingest server，校验、幂等去重、ACK、下游分发 |

## Pattern Inheritance

本模块结构继承自 [`module/binance`](../binance/) C/S Module 模板。仅交易所特异性内容（product lines / instrument identity / endpoints / API quirks）在本模块独立声明。

边界门禁与 runtime mapping 引用 binance 同名文档（参见 `BOUNDARY-GATES.md`、`RUNTIME-MAPPING.md`）。

## Removed Legacy

旧的 `okx` SDK（v0.1.1 前的 passive 客户端）已在本架构中**移除**。新代码与文档不得引用：

```text
github.com/ZoneCNH/okx (v0.1.1 SDK 接口)
```

GitHub 仓库 `github.com/ZoneCNH/okx` 保留并改造为 C/S Module 实现仓库。

## Read Next

- `goal.md`
- `SPEC.md`
- `client/SPEC.md`
- `server/SPEC.md`
- `IMPLEMENTATION-PLAN.md`
- `TRACEABILITY.md`
