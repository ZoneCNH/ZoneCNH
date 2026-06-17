# module/coinglass BOUNDARY GATES

本模块的 9 项 CI 边界门禁结构与 [`module/binance/BOUNDARY-GATES.md`](../binance/BOUNDARY-GATES.md) 一致，按以下规则替换后接入 CI。

## 替换规则

- `binance` → `coinglass`
- `Binance` → `Coinglass`
- `binance-market` → 不适用；§2 gate 改为：禁止 active code 引用旧 passive `coinglass` SDK 接口
- `BNC-` 错误码前缀 → `CGS-`

## 9 项 Gate 简表

| § | Gate 名称 | Coinglass 适配说明 |
|---|-----------|-------------------|
| 2 | No legacy passive SDK | 禁止旧 passive SDK 接口（`docs/migrations/coinglass-sdk-removal.md` 与 `CHANGELOG.md` 例外） |
| 3 | Client Must Not Import Server Internals | path：`module/coinglass/client` ↛ `module/coinglass/server/*` |
| 4 | Server Must Not Import Client Internals | 同上反向 |
| 5 | No Storage/Query/Strategy Ownership | 通用 |
| 6 | Contracts Are Wire Representation Only | 禁止 `module/coinglass/proto/*` |
| 7 | Domain-Market Is Semantic Source | 禁止 Coinglass 重定义 ProductLine/InstrumentKey；`derivatives_aggregate` 通过 `source_metadata` 表达，不在 canonical core 重定义 |
| 8 | Admin Surface Cannot Cross Module Boundaries | 通用 |
| 9 | Checkpoint Requires ACK | 通用 |

## Coinglass-Specific Gates

新增聚合数据源特异 gates：

| § | Gate 名称 | 通过条件 |
|---|-----------|----------|
| 10 | Window-Start Idempotency | 4 channel 各自的 idempotency key parsing 必须包含相应 window 维度（period_start / snapshot_time / liquidation_id / interval+window_start）；`go test -run TestCoinglassIdempotencyKey ./...` 通过 |
| 11 | Venue Map Completeness | venue map 必须覆盖至少 13 项已知 venue（CEX + DEX）；新增交易所时同步更新；`go test -run TestVenueMap ./...` 通过 |
| 12 | API Key Isolation | (a) `gitleaks detect --no-git` 零匹配；(b) `COINGLASS_API_KEY` 不出现在任何 spool/log/admin/debug 输出 |

## CI 集成

CI workflow 复制 binance 同名脚本，sed 替换名称后执行。新增 §10/§11/§12 三个 coinglass 专属 step。
