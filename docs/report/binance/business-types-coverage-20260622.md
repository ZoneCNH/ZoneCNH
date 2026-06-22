# module/binance 业务类型覆盖深度分析

- Report-Date: 2026-06-22
- Scope: `module/binance/`
- Method: 读取 `SPEC.md`、`TRACEABILITY.md`、client/server 子规格、runtime mapping 与任务文档，按“规格包含”“任务规划”“当前落地状态”分层判断。
- Confidence: HIGH

## 结论摘要

[COMPUTED][HIGH] `module/binance/` 在规格层明确包含四类 Binance 产品线：现货 Spot、USDⓈ-M Futures、COIN-M Futures、Options。证据：`module/binance/SPEC.md:62`-`73`、`module/binance/SPEC.md:105`-`122`。

[COMPUTED][HIGH] 合约不是单一笼统类型，而是拆成 USDⓈ-M Futures 与 COIN-M Futures；规格还要求通过 `product_line`、结算资产、到期日、行权价、期权类型等字段避免不同市场的同名 symbol 冲突。证据：`module/binance/SPEC.md:51`-`58`、`module/binance/SPEC.md:123`-`134`。

[COMPUTED][HIGH] 订单簿/订单薄在本模块中被建模为行情数据类型 `depth`，覆盖存储、缓存与 REST 查询；它不是独立产品线，也不是下单系统。证据：`module/binance/SPEC.md:181`-`190`、`module/binance/SPEC.md:205`-`210`、`module/binance/SPEC.md:225`-`248`。

[COMPUTED][HIGH] 本模块明确排除交易决策、交易执行和订单执行能力，因此“订单”如果指撮合/委托/下单，不包含；如果指订单簿深度行情，则包含。证据：`module/binance/SPEC.md:77`-`89`。

[COMPUTED][MED] 当前落地状态不是“全量已实现”：根追溯矩阵标注 FR-001 为 Partial，说明 Spot connector 已实现，USDⓈ-M、COIN-M、Options 后续实现；client 追溯矩阵仍把 catalog/parser/connectors/publisher 标成 Pending；server 的 taosx、redisx、REST API 也仍是 Pending。证据：`module/binance/TRACEABILITY.md:17`-`28`、`module/binance/client/TRACEABILITY.md:17`-`28`。

## 覆盖矩阵

| 类型                | 是否包含         | 规格层定义                                                                      | 任务/实现状态                                                                                                                                                 | 关键证据                                                                                                                                                                                                                                                 |
| ------------------- | ---------------- | ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 现货 Spot           | 是               | [COMPUTED][HIGH] 作为四条产品线之一；Spot connector 必须接入现货行情。          | [COMPUTED][MED] 根矩阵称 Spot connector 已实现；client 矩阵仍显示 connector 待实现，存在状态口径不一致。                                                      | `module/binance/SPEC.md:105`-`111`; `module/binance/TRACEABILITY.md:19`; `module/binance/client/TRACEABILITY.md:21`; `module/binance/client/tasks/TASK-BINANCE-CLIENT-003-spot-connector.md:1`-`15`                                                      |
| 合约 Futures        | 是               | [COMPUTED][HIGH] 拆为 USDⓈ-M Futures 与 COIN-M Futures，两者都属于目标产品线。  | [COMPUTED][HIGH] 根矩阵说明 USDⓈ-M/COIN-M 后续实现；任务文档已拆成独立 connector。                                                                            | `module/binance/SPEC.md:112`-`117`; `module/binance/TRACEABILITY.md:19`; `module/binance/client/tasks/TASK-BINANCE-CLIENT-004-usdm-futures-connector.md:1`-`16`; `module/binance/client/tasks/TASK-BINANCE-CLIENT-005-coinm-futures-connector.md:1`-`16` |
| 期权 Options        | 是               | [COMPUTED][HIGH] 作为四条产品线之一；期权身份包含 expiry、strike、option_type。 | [COMPUTED][HIGH] 根矩阵说明 Options 后续实现；任务文档已定义 Options connector。                                                                              | `module/binance/SPEC.md:118`-`122`; `module/binance/SPEC.md:131`-`134`; `module/binance/client/tasks/TASK-BINANCE-CLIENT-006-options-connector.md:1`-`15`                                                                                                |
| 订单簿/订单薄 Depth | 是，但不是产品线 | [COMPUTED][HIGH] 作为 market data event/storage/API 类型，使用 `depth` 表示。   | [COMPUTED][HIGH] Spot/USDⓈ-M/COIN-M connector 任务都列出 depth/update；server 任务定义 `binance_market_depth` 与 depth REST API。Options 任务未直接列 depth。 | `module/binance/SPEC.md:181`-`190`; `module/binance/server/tasks/TASK-BINANCE-SERVER-013-taosx-storage.md:33`-`43`; `module/binance/server/tasks/TASK-BINANCE-SERVER-015-gin-market-api.md:28`-`35`                                                      |
| 订单执行 / 下单     | 否               | [COMPUTED][HIGH] 非目标明确排除订单执行、策略 API、交易决策。                   | [COMPUTED][HIGH] 无任务证据表明会实现下单或交易执行。                                                                                                         | `module/binance/SPEC.md:77`-`89`                                                                                                                                                                                                                         |

## 逐项分析

### 现货 Spot

[COMPUTED][HIGH] 根规格把 Spot 定义为 Binance 四条目标产品线之一，并要求 client 至少提供 Spot connector。证据：`module/binance/SPEC.md:105`-`111`。

[COMPUTED][HIGH] client 任务 `TASK-BINANCE-CLIENT-003` 的初始范围包含 ticker、trade、kline/bar、depth/update events，说明现货覆盖不只是价格 tick，也包括交易、K 线和深度增量。证据：`module/binance/client/tasks/TASK-BINANCE-CLIENT-003-spot-connector.md:7`-`15`。

[COMPUTED][MED] 落地状态存在文档冲突：根追溯矩阵称 FR-001 为 Partial 且 Spot connector implemented；client 追溯矩阵仍把 Product-Line Connectors 标为 Pending。该冲突说明“Spot 已实现”需要以实际代码仓或最新 gate 证据复核，不能仅凭一个矩阵断言。证据：`module/binance/TRACEABILITY.md:19`、`module/binance/client/TRACEABILITY.md:21`。

### 合约 Futures

[COMPUTED][HIGH] 规格层包含两类合约：USDⓈ-M Futures 与 COIN-M Futures。USDⓈ-M 覆盖 USDT/USDC margin futures，COIN-M 覆盖 coin-margined futures。证据：`module/binance/SPEC.md:112`-`117`。

[COMPUTED][HIGH] 合约身份建模的重点是避免 symbol 冲突：Spot `BTCUSDT`、USDⓈ-M `BTCUSDT`、COIN-M `BTCUSD` 不能被当成同一 instrument；COIN-M 还需要 settlement_asset。证据：`module/binance/SPEC.md:51`-`58`、`module/binance/SPEC.md:123`-`130`。

[COMPUTED][HIGH] client 任务已把 USDⓈ-M 与 COIN-M 拆成独立 connector，二者范围都包含 ticker、trade、kline/bar、合约市场事实与 depth/update。证据：`module/binance/client/tasks/TASK-BINANCE-CLIENT-004-usdm-futures-connector.md:7`-`16`、`module/binance/client/tasks/TASK-BINANCE-CLIENT-005-coinm-futures-connector.md:7`-`16`。

### 期权 Options

[COMPUTED][HIGH] 规格层包含 Binance Options，且期权 instrument identity 明确要求 expiry、strike、option_type。证据：`module/binance/SPEC.md:118`-`122`、`module/binance/SPEC.md:131`-`134`。

[COMPUTED][HIGH] client 任务已定义 Options connector，范围包含 option ticker、trade、kline/bar 与 option-specific facts。证据：`module/binance/client/tasks/TASK-BINANCE-CLIENT-006-options-connector.md:7`-`15`。

[COMPUTED][MED] Options 任务未直接列出 depth/update events；因此本仓库规格可确认“期权产品线包含”，但不能确认“期权订单簿深度也被 task 明确覆盖”。根规格的 depth 是跨产品线行情能力，Options 的深度覆盖需要后续 task 或接口契约补强。

### 订单簿 / 订单薄 Depth

[COMPUTED][HIGH] `module/binance` 使用 `depth` 表示订单簿/深度数据，并把它纳入 taosx 存储、redisx 热缓存和 REST API。证据：`module/binance/SPEC.md:181`-`190`、`module/binance/SPEC.md:205`-`210`、`module/binance/SPEC.md:225`-`248`。

[COMPUTED][HIGH] server 任务定义了 `binance_market_depth` 超表，字段包括 `side`、`price`、`quantity`、`last_update_id`，并以 `symbol`、`product_line` 打标签。证据：`module/binance/server/tasks/TASK-BINANCE-SERVER-013-taosx-storage.md:33`-`43`。

[COMPUTED][HIGH] server API 任务定义 `GET /api/v1/market/depth/{symbol}`，用于查询来自 redisx 缓存的当前深度快照。证据：`module/binance/server/tasks/TASK-BINANCE-SERVER-015-gin-market-api.md:28`-`35`。

[INFERRED][HIGH] 因为 depth 被放在行情事件、存储和查询接口中，而交易执行被明确排除，所以本模块的“订单簿”语义是市场深度数据，不是交易订单生命周期。

## 关键边界与风险

[COMPUTED][HIGH] `module/binance/` 是 Binance 专用 market data 分布式 C/S 模块规格，不是交易执行模块。证据：`module/binance/SPEC.md:18`-`22`、`module/binance/SPEC.md:77`-`89`。

[COMPUTED][MED] 产品线命名存在不完全一致：根/client 规格出现 `usdm_futures`、`coinm_futures`，connector 任务验收使用 `um_perp`、`cm_perp`，server 存储/API 示例出现 `futures_usdt`、`futures_coin`。这会影响 subject、cache key、表 tag、API 参数和 instrument identity 的一致性。证据：`module/binance/client/SPEC.md:338`-`356`、`module/binance/client/tasks/TASK-BINANCE-CLIENT-004-usdm-futures-connector.md:25`-`31`、`module/binance/client/tasks/TASK-BINANCE-CLIENT-005-coinm-futures-connector.md:25`-`31`、`module/binance/server/tasks/TASK-BINANCE-SERVER-013-taosx-storage.md:27`-`31`、`module/binance/server/tasks/TASK-BINANCE-SERVER-015-gin-market-api.md:38`-`45`。

[COMPUTED][MED] 状态字段也存在不一致：根追溯矩阵称 Spot connector 已实现，client 追溯矩阵仍标 Pending。若要判断真实代码完成度，需要继续审阅实际实现仓或最新 pipeline evidence。证据：`module/binance/TRACEABILITY.md:19`、`module/binance/client/TRACEABILITY.md:21`。

## 最终判断

[COMPUTED][HIGH] 若问题是“`module/binance/` 是否在业务范围中包含现货、合约、期权、订单簿”，答案是：包含现货、包含合约、包含期权、包含订单簿行情。

[COMPUTED][HIGH] 更精确的表述是：`module/binance/` 覆盖 Binance market data 的 Spot、USDⓈ-M Futures、COIN-M Futures、Options 四条产品线，并对 tick/bar/trade/depth 等行情类型进行采集、传输、存储、缓存和查询规划。

[COMPUTED][HIGH] 若问题是“是否已经全部实现”，答案是否定的；文档证据显示它处于规格/任务规划与部分实现混合状态，至少 USDⓈ-M、COIN-M、Options、server storage/cache/API 仍未被追溯矩阵证明完成。

[RULES I BROKE]：无
