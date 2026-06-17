# module/hyperliquid BOUNDARY GATES

本模块的 9 项 CI 边界门禁结构与 [`module/binance/BOUNDARY-GATES.md`](../binance/BOUNDARY-GATES.md) 一致，按以下规则替换后接入 CI。

## 替换规则

- `binance` → `hyperliquid`
- `Binance` → `Hyperliquid`
- `binance-market` → 不适用（不存在 `hyperliquid-market` legacy）；§2 gate 改为：禁止 active code 引用旧 passive `hyperliquid` SDK 接口
- `BNC-` 错误码前缀 → `HYP-`

## 9 项 Gate 简表

| § | Gate 名称 | Hyperliquid 适配说明 |
|---|-----------|----------------------|
| 2 | No legacy passive SDK | 禁止旧 passive SDK 接口（`docs/migrations/hyperliquid-sdk-removal.md` 与 `CHANGELOG.md` 例外） |
| 3 | Client Must Not Import Server Internals | path：`module/hyperliquid/client` ↛ `module/hyperliquid/server/*` |
| 4 | Server Must Not Import Client Internals | 同上反向 |
| 5 | No Storage/Query/Strategy Ownership | 通用 |
| 6 | Contracts Are Wire Representation Only | 禁止 `module/hyperliquid/proto/*` |
| 7 | Domain-Market Is Semantic Source | 禁止 Hyperliquid 重定义 ProductLine/InstrumentKey |
| 8 | Admin Surface Cannot Cross Module Boundaries | 通用 |
| 9 | Checkpoint Requires ACK | 通用 |

## Hyperliquid-Specific Gates

新增 DEX 特异 gates：

| § | Gate 名称 | 通过条件 |
|---|-----------|----------|
| 10 | Onchain Idempotency Key | onchain_l1 事件的 idempotency key parsing 必须包含 `block_height` + `tx_hash` 维度；`go test -run TestIdempotencyKeyOnchain ./...` 通过 |
| 11 | Wallet Secret Isolation | (a) `gitleaks detect --no-git` 零匹配；(b) 自定义 hex pattern 扫描（`grep -rE '[0-9a-fA-F]{64}'` 排除测试 fixture）零私钥泄露；(c) `HYPERLIQUID_PRIVATE_KEY` 不出现在 spool/log/admin/debug 输出 |
| 12 | Reorg Tolerance | `go test -run TestReorg ./...` 通过：reorg 后旧 key 不撤销，新 block_height 视为新事件 |

## CI 集成

CI workflow 复制 binance 同名脚本，sed 替换名称后执行。新增 §10/§11/§12 三个 hyperliquid 专属 step。
