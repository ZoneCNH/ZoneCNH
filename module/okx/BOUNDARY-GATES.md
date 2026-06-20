# module/okx BOUNDARY GATES

本模块的 9 项 CI 边界门禁结构与 [`module/binance/BOUNDARY-GATES.md`](../binance/BOUNDARY-GATES.md) 一致，按以下规则替换后接入 CI。

## 替换规则

- `binance` → `okx`
- `Binance` → `OKX`（首字母大写，仅文档措辞）
- `binance-market` → 不适用（OKX 历史不存在 `okx_market` legacy 模块）；§2 gate 改为：禁止 active code 引用旧 passive `okx` SDK v0.1.1 接口
- `BNC-` 错误码前缀 → `OKX-`

## 9 项 Gate 简表

| § | Gate 名称 | OKX 适配说明 |
|---|-----------|--------------|
| 2 | No legacy passive SDK | 禁止 `passive okx SDK` 接口出现在 active code（`docs/migrations/okx-sdk-removal.md` 与 `CHANGELOG.md` 例外） |
| 3 | Client Must Not Import Server Internals | 仅替换 path：`module/okx/client` ↛ `module/okx/server/*` |
| 4 | Server Must Not Import Client Internals | 同上反向 |
| 5 | No Storage/Query/Strategy Ownership | 通用；扫描关键字 `Owns.*storage` 等 |
| 6 | Contracts Are Wire Representation Only | 禁止 `module/okx/proto/*` |
| 7 | Domain-Market Is Semantic Source | 禁止 OKX 重定义 ProductLine/InstrumentKey |
| 8 | Admin Surface Cannot Cross Module Boundaries | 通用 |
| 9 | Checkpoint Requires ACK | 通用 |

## OKX-Specific Gate

新增第 10 项 OKX 特异 gate：

| § | Gate 名称 | 通过条件 |
|---|-----------|----------|
| 10 | Environment Isolation | 配置层校验：同一 client config 不得同时含 `simulated` 与 `production` endpoint；`go test -run TestEnvironmentIsolation ./...` 通过 |

## CI 集成

CI workflow 复制 binance 同名 shell 脚本，sed 替换 `binance → okx` / `Binance → OKX` / `BNC- → OKX-` 后执行。
