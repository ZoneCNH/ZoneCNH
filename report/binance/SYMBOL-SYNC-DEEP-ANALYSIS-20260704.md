# Binance 模块币种采集/同步深度分析（2026-07-04）

## 1. 执行结论

- `binance` 当前币种同步逻辑分三层：默认 catalog、ExchangeInfo 全量发现、`STREAM_SYMBOLS` 白名单过滤。
- 实时流采集当前仅由 `SpotConnector` 启动，`um_perp/cm_perp/options` 主要进入 catalog 与生命周期管理，不进入当前 WS 实时采集主路径。
- `cm_perp` 在当前线上数据口径下会被判定为非 active（返回体无 `status` 字段，代码仅 `status=="TRADING"` 视为 active）。

## 2. 代码口径（权威）

### 2.1 默认同步范围（未配置 ExchangeInfo）

- `internal/client/catalog.go` `DefaultSpotCatalog()`：默认仅 `BTCUSDT`、`ETHUSDT`。

### 2.2 ExchangeInfo 启用后的同步范围

- `internal/client/runtime.go`：
  - 启用条件：`cfg.ExchangeInfoURL != ""`
  - 同步产品线：`spot`、`um_perp`、`cm_perp`、`options`
  - 白名单：`buildSymbolWhitelist` + `filterCatalogEntriesByWhitelist` 仅作用于 `spot/um_perp/cm_perp`，`options` 跳过白名单过滤。

### 2.3 active 判定规则

- `internal/client/catalog.go` `ActiveSymbols()`：仅 `Status == "active"`。
- `internal/client/exchangeinfo.go`：
  - `spot/um/cm`：仅 `status=="TRADING"` 转为 `active`，否则 `paused`。
- `internal/client/exchangeinfo_option.go`：
  - `options`：无 `status`；以 `expiryDate > now` 判定活跃。

### 2.4 实时采集生效路径

- `internal/client/runtime.go`：当前仅 `NewSpotConnector(...)` 启动 WS 采集。
- `internal/client/stream_control.go`：实时流列表来源于 `catalog.ActiveSymbols(productLine)`。

## 3. 实测统计（2026-07-04 14:00+08）

基于 Binance 公共接口实时抓取并按当前代码口径计算：

| Product Line | 总符号数 | active 判定后 | 备注 |
| --- | ---: | ---: | --- |
| spot | 3625 | 1356 | `status=="TRADING"` |
| um_perp | 820 | 695 | `status=="TRADING"` |
| cm_perp | 30 | 0 | 返回体 `status=None`，现逻辑全部非 active |
| options | 1578 | 1578 | `expiryDate > now` |

补充：

- spot active 覆盖 `baseAsset` 443 个。
- um_perp active 覆盖 `baseAsset` 648 个。
- options 活跃 underlying：`BNBUSDT`、`BTCUSDT`、`DOGEUSDT`、`ETHUSDT`、`SOLUSDT`、`XRPUSDT`。

## 4. 配置面影响

- 配置字段：`pkg/binancecfg/config.go` `StreamSymbols`（`FOUNDATIONX_BINANCE_STREAM_SYMBOLS`）。
- `cmd/binance-client/main.go`：`cfg.StreamSymbols = bc.StreamSymbolsList()` 注入 runtime。
- 当前 `configs/binance-client.env.example` 未显式给出 `FOUNDATIONX_BINANCE_STREAM_SYMBOLS` 示例项，默认即“不过滤”（全量按 active）。

## 5. 风险与建议

1. `cm_perp` active 口径与 Binance DAPI 返回体存在不一致，导致该产品线实时路径可能长期空集。
2. 白名单仅控制 catalog 输入，不等价于“多产品线实时流均已启动”；当前实时能力仍以 `spot` 为主。
3. 若目标是“采集同步的币种可控且可解释”，建议补齐：
   - `cm_perp` active 判定适配；
   - 多产品线 connector 启动路径；
   - `STREAM_SYMBOLS` 与 Tier 策略的统一配置语义。

## 6. 关键证据文件

- `/home/workspace/binance/internal/client/runtime.go`
- `/home/workspace/binance/internal/client/catalog.go`
- `/home/workspace/binance/internal/client/exchangeinfo.go`
- `/home/workspace/binance/internal/client/exchangeinfo_option.go`
- `/home/workspace/binance/pkg/binancecfg/config.go`
- `/home/workspace/binance/cmd/binance-client/main.go`

