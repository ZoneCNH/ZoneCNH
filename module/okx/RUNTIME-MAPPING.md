# module/okx RUNTIME MAPPING

## 1. Purpose

本文件将 `module/okx` 规格映射到推荐的 runtime 仓库结构。结构与 [`module/binance/RUNTIME-MAPPING.md`](../binance/RUNTIME-MAPPING.md) 一致，按下列差异客制化。

文档路径：`module/okx/`
Runtime 仓库：`github.com/ZoneCNH/okx`

## 2. Recommended Runtime Tree（与 binance 一致 + OKX 特异 5 个 connector）

```text
github.com/ZoneCNH/okx/
  go.mod

  cmd/
    okx-client/main.go
    okx-server/main.go

  internal/
    client/
      app/
      config/
      catalog/
      parser/
      spot/             # OKX Spot connector
      margin/           # OKX Margin connector（特异，binance 无对应目录）
      usdm_swap/        # USDⓈ-M perp/future
      coinm_swap/       # Coin-M perp/future
      options/
      normalize/
      mapper/
      idempotency/
      spool/
      checkpoint/
      sender/
      admin/
      observability/

    server/
      app/
      config/
      ingest/
      validation/       # 含 OKX source_metadata 校验
      idempotency/
      ack/
      dispatch/
      admin/
      observability/

  pkg/
    config/
    observability/
    version/

  test/
    contract/
    integration/
    fixtures/
```

## 3. 与 binance 的差异

| 差异点 | binance | okx |
|--------|---------|-----|
| Connector 数量 | 4（spot/usdm/coinm/options） | 5+（spot + margin + usdm_swap + coinm_swap + options，可能加 usdm_future + coinm_future） |
| Symbol parser | 4 product line 区分 | 5 product line + Spot/Margin 同 instId 通过 instType 上下文区分 |
| Endpoint | 单一 WebSocket | public + business 双 WebSocket endpoint |
| Auth | 2 段（API key + secret） | 3 段（API key + secret + passphrase） |
| Environment | 单一（production） | production + simulated 双环境（互斥） |

## 4. Forbidden Runtime Imports

继承 binance §7：
- client ↛ `internal/server/*`
- server ↛ `internal/client/*`
- 禁止引入 `github.com/ZoneCNH/storage` / `strategy` 作为 owned dependency
- 禁止重新引入 v0.1.1 旧 passive SDK 接口

## 5. Allowed External Dependencies

继承 binance §8。OKX 特异：
- WebSocket client：`nhooyr.io/websocket`（需支持 OKX 100MB/min frame）

## 6. Runtime Acceptance

继承 binance §10：cmd 可独立运行；boundary check pass；ACK-driven checkpoint；duplicate idempotency key 不重复 dispatch。OKX 特异：simulated/production 不混入；source_metadata 校验通过。
