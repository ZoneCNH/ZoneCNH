# binance Goal

| 字段 | 值 |
| --- | --- |
| 模块 | `binance` |
| 层级 | 数据域 · 行情（C/S Module 参考实现） |
| 仓库 | <https://github.com/ZoneCNH/binance> |
| 当前版本 | v0.7.0 |
| Spec 版本 | v3.9.6 |
| 状态 | Released — 48/48 FR Done, release_closeable=YES |

## 目标

`binance` 是 Binance 行情数据 C/S Module 参考实现，覆盖 5 条产品线（Spot/Margin/USDⓈ-M/Coin-M/Options）和 7 种 stream 类型。作为首个完整 C/S Module，它为 okx/hyperliquid/coinglass 等后续模块提供架构模板。

## 非目标

- 不实现交易执行决策（→ riskx/strategyx）
- 不替代 domain_market 领域模型

## 架构类型

C/S Module — `internal/client`（数据源采集）+ `internal/server`（数据服务）+ `internal/wire`（契约层）+ `pkg/binancecfg` + `pkg/binancex`

## 验证

- 构建: `go build ./...` PASS
- 测试: 21/21 packages PASS
- 覆盖率: 73.7%（较 59.6% 提升）
- 安全: 1 CRITICAL + 10 HIGH 全部修复（deep-review 2026-06-29）
- CI: 15 道边界门禁
