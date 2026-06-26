# module/binance ENDPOINTS.md — Mainnet-Only Endpoint Strategy

## Metadata

| Field | Value |
| --- | --- |
| Status | Active |
| Module-Version | v3.7.1 |
| Last-Updated | 2026-06-25 |
| Scope | `module/binance` 四产品线 mainnet 官方端点清单与 mainnet-only 策略 |
| Spec-Impact | C1（清除 testnet 依赖）的规范基线 |
| Source | `pkg/binancecfg/endpoints.go`（runtime HEAD `e549967`+） |

> [FRAME, HIGH] 本文档定义 binance 模块的 mainnet-only 策略：所有 release evidence 必须基于 mainnet 官方端点，禁止使用 testnet 端点作为发布证据。

## 1. Scope

[FRAME, HIGH] 本规范覆盖 spot/um_perp/cm_perp/options 四产品线的 WS 与 REST mainnet 端点清单，以及 mainnet-only 证据策略。

[FRAME, HIGH] 本规范不定义采集逻辑（由 client 包治理），不定义凭据管理（由 SECURITY.md 治理）。

## 2. 四产品线 Mainnet 端点清单

[COMPUTED, HIGH] 基于代码核实（`pkg/binancecfg/endpoints.go`）：

| 产品线 | WS StreamBase | REST Base | 常量名 | 官方确认 |
| --- | --- | --- | --- | --- |
| spot | `wss://stream.binance.com:9443` | `https://api.binance.com` | `MainnetSpotStreamBaseURL` / `MainnetRESTBaseURL` | ✅ |
| USDⓈ-M Futures (um_perp) | `wss://fstream.binance.com` | `https://fapi.binance.com` | `UMPerpStreamBaseURL` | ✅ |
| COIN-M Futures (cm_perp) | `wss://dstream.binance.com` | `https://dapi.binance.com` | `CMPerpStreamBaseURL` | ✅ |
| Options | `wss://fstream.binance.com/public` | `https://vapi.binance.com` | `OptionsStreamBaseURL` | ✅（issue #77 勘误） |

[KNOWN, HIGH] 四产品线 mainnet 公开市场流（trade/bookTicker/kline/depth）均开放，无需账户凭据。这是 C4 四线覆盖矩阵可一次性完成的基础。

## 3. Mainnet-Only 策略（C1）

[FRAME, HIGH] 规则：
1. **release evidence 禁止 testnet**：`release/evidence/binance/` 下所有证据文件必须基于 mainnet 端点。前序 `testnet-live.txt` 已删除（C1/P0）。
2. **集成测试用 mainnet**：`test/e2e/mainnet_live_test.go` gate `BINANCE_MAINNET_LIVE`，四产品线 mainnet WS 连通性验证。
3. **testnet 代码保留为环境抽象**：`endpoints.go` 的 `Testnet*` 常量与 `NormalizeMode` testnet 分支保留——这是合法的多环境抽象（开发/沙箱用），非缺陷。清除的是「以 testnet 作为 release 证据」的做法，不是清除 testnet 代码。

[COMPUTED, HIGH] options 端点勘误（issue #77）：初判认为 `wss://fstream.binance.com/public` 非期权官方端点（应为 `nbstream`/`eoptions`）。经 Binance Developer Center 官方文档复核，`fstream.binance.com/public/` 是正确的 Binance Options WS 端点。该 issue 已 CLOSED/NOT_PLANNED，端点值未改动。

## 4. 四产品线覆盖矩阵（C4）

[COMPUTED, HIGH] `test/e2e/mainnet_live_test.go` 的覆盖矩阵：

| 测试函数 | 产品线 | stream | gate |
| --- | --- | --- | --- |
| `TestMainnetLive_SpotTrade` | spot | btcusdt@trade | BINANCE_MAINNET_LIVE |
| `TestMainnetLive_SpotBookTicker` | spot | btcusdt@bookTicker | BINANCE_MAINNET_LIVE |
| `TestMainnetLive_UMPerpTrade` | um_perp | btcusdt@trade | BINANCE_MAINNET_LIVE |
| `TestMainnetLive_CMPerpTrade` | cm_perp | btcusd_perp@trade | BINANCE_MAINNET_LIVE |
| `TestMainnetLive_OptionsTicker` | options | 连通性验证 | BINANCE_MAINNET_LIVE |

[FRAME, HIGH] options 用例降级为连通性验证（wss 握手成功），因期权 symbol 带到期日需动态解析活跃 symbol（FR-030）。

## 5. Evidence Gates

[FRAME, HIGH] C1/C4 闭合的证据要求：

| Gate | 证据 |
| --- | --- |
| testnet evidence 清除 | `release/evidence/binance/` 无 testnet URL 残留 |
| mainnet 矩阵就绪 | `mainnet-coverage-matrix.txt` 存在（CODE-READY, PENDING-LIVE-RUN） |
| 四线端点正确 | `endpoints.go` 常量与官方文档一致（上表） |

## 6. Document Synchronization

[FRAME, HIGH] 本文档与 `SPEC.md` §2（数据流）、`RUNTIME-MAPPING.md` 端点映射同步。
