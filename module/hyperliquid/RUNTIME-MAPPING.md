# module/hyperliquid RUNTIME MAPPING

## 1. Purpose

将 `module/hyperliquid` 规格映射到推荐的 runtime 仓库结构。结构以 [`module/binance/RUNTIME-MAPPING.md`](../binance/RUNTIME-MAPPING.md) 为基线，叠加 DEX 特异目录。

文档路径：`module/hyperliquid/`
Runtime 仓库：`github.com/ZoneCNH/hyperliquid`

## 2. Recommended Runtime Tree

```text
github.com/ZoneCNH/hyperliquid/
  go.mod

  cmd/
    hyperliquid-client/main.go
    hyperliquid-server/main.go

  internal/
    client/
      app/
      config/
      catalog/
      parser/
      perp/                 # Perpetual connector
      spot/                 # Spot connector（如 venue capability 允许）
      chain/                # 链上 L1 RPC connector + reorg detection（DEX 特异）
      signer/               # Wallet signature 封装（DEX 特异）
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
      validation/           # 含 onchain metadata 校验
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
    integration/            # 含 reorg 场景
    fixtures/
```

## 3. 与 binance 的差异

| 差异点 | binance | hyperliquid |
|--------|---------|-------------|
| Connector | 4 product line | 2 product line（perp/spot）+ chain L1 RPC connector |
| Auth | API key + secret | Wallet signature（EIP-191 typed message） |
| Signer | 不需要 | `internal/client/signer`：local key 或 external endpoint |
| Idempotency key | 5 维 | onchain 事件多 3 维（block_height + tx_hash + log_index） |
| Idempotency TTL | 24h | 48h（覆盖 reorg 窗口） |
| Server validation | 通用 | 额外校验 onchain metadata 必填 |

## 4. Forbidden Runtime Imports

继承 binance §7，并新增：
- 禁止引入完整 `github.com/ethereum/go-ethereum`（仅允许 `crypto` 子包用于签名）
- 禁止 wallet management UI 或多签管理库
- 禁止 onchain order placement 库（属于执行域）

## 5. Allowed External Dependencies

继承 binance §8。Hyperliquid 特异：
- `github.com/ethereum/go-ethereum/crypto` — EIP-191 签名
- `github.com/btcsuite/btcd/btcec` 或同类 — 椭圆曲线签名

## 6. Runtime Acceptance

继承 binance §10，新增：
- chain RPC connector 可独立运行（不依赖 WebSocket 连通性）
- reorg 测试通过（chaos test 模拟 L1 reorg）
- Wallet secret 在所有 artifact 零出现
