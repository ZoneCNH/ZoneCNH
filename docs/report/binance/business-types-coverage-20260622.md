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

[COMPUTED][MED] 当前落地状态不是“全量已实现”：根追溯矩阵标注 FR-001 为 Partial，说明 Spot connector 已实现，USDⓈ-M、COIN-M、Options 后续实现；client 追溯矩阵仍把 catalog/parser/connectors/publisher 标成 Pending；server 的 taosx、redisx、REST API 也仍是 Pending。证据：`module/binance/TRACEABILITY.md:17`-`33`（根矩阵 FR-006a/b/c/d、FR-007/007a/008、FR-010/011 全部 ⬜ Pending）、`module/binance/client/TRACEABILITY.md:17`-`28`（client FR-001~010 全部 ⬜ Pending，仅文档对齐）。

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

[COMPUTED][HIGH] **产品线命名漂移（升级为 HIGH 级风险）**：同一概念在 5 处使用 3 套不兼容命名，会击穿 NATS subject 路由、Redis cache key、TDengine tag、Kafka topic、Gin API 参数五条管线一致性。证据：

| 出处 | 命名 |
|------|------|
| `module/binance/client/SPEC.md:343` | `spot / usdm_futures / coinm_futures / options` |
| `module/binance/SPEC.md:482`-`495`（natsx subject 表） | `spot / um_perp / cm_perp / options` |
| `module/binance/client/tasks/TASK-BINANCE-CLIENT-004-usdm-futures-connector.md:27` | `um_perp` |
| `module/binance/client/tasks/TASK-BINANCE-CLIENT-005-coinm-futures-connector.md:27` | `cm_perp` |
| `module/binance/server/tasks/TASK-BINANCE-SERVER-013-taosx-storage.md:29` | `spot / futures_usdt / futures_coin` |
| `module/binance/server/tasks/TASK-BINANCE-SERVER-015-gin-market-api.md:44` | `spot / futures_usdt` |

[COMPUTED][HIGH] **Options 深度覆盖缺口**：Options 产品线在 depth 维度存在三重缺口，违反根 SPEC 对四产品线的对称承诺：

1. `module/binance/SPEC.md:484`-`495` natsx subject 表只定义 `binance.market.options.tick` 与 `binance.market.options.bar`，未定义 `binance.market.options.depth`，与 Spot/um_perp/cm_perp 三条产品线均含 depth subject 不对称。
2. `module/binance/client/tasks/TASK-BINANCE-CLIENT-006-options-connector.md:11`-`13` Scope 仅列 `option ticker / trade / kline/bar`，明确**不包含 depth/update events**，与 Spot/USDⓈ-M/COIN-M connector task 均含 `depth/update events where applicable` 不对称（`TASK-...-003-spot.md:14`、`-004-usdm.md:15`、`-005-coinm.md:15`）。
3. 然而根 SPEC `module/binance/SPEC.md:181`-`190`（FR-006a）、`:241`-`242`（FR-007 depth API）、`:705`（ossx 归档路径）均隐含 4 产品线统一覆盖。规格内部存在"产品线对称"与"Options 任务实际不覆盖 depth"的矛盾。

[COMPUTED][MED] 状态字段也存在不一致：根追溯矩阵称 Spot connector 已实现，client 追溯矩阵仍标 Pending。若要判断真实代码完成度，需要继续审阅实际实现仓或最新 pipeline evidence。证据：`module/binance/TRACEABILITY.md:19`、`module/binance/client/TRACEABILITY.md:21`。

[COMPUTED][LOW] 子规格版本漂移（次级风险）：`module/binance/client/TRACEABILITY.md:8` 引用 `module/binance/client/SPEC.md v2.0.0`，但 `module/binance/client/SPEC.md:6` 实际为 `v2.1.0`。不影响业务覆盖判断，但说明追溯矩阵的版本元数据未与子规格同步刷新。

## 最终判断

[COMPUTED][HIGH] 若问题是“`module/binance/` 是否在业务范围中包含现货、合约、期权、订单簿”，答案是：包含现货、包含合约、包含期权、包含订单簿行情（但 Options 的 depth 覆盖在任务/subject 层面存在缺口）。

[COMPUTED][HIGH] 更精确的表述是：`module/binance/` 覆盖 Binance market data 的 Spot、USDⓈ-M Futures、COIN-M Futures、Options 四条产品线，并对 tick/bar/trade/depth 等行情类型进行采集、传输、存储、缓存和查询规划；Options depth 在规格层假设覆盖，但 connector task 与 natsx subject 表实际未列入。

[COMPUTED][HIGH] 若问题是“是否已经全部实现”，答案是否定的；文档证据显示它处于规格/任务规划与部分实现混合状态，至少 USDⓈ-M、COIN-M、Options、server storage/cache/API 仍未被追溯矩阵证明完成。

[COMPUTED][HIGH] 本仓库（`ZoneCNH/ZoneCNH`）是文档枢纽，runtime 实现位于独立仓库 `github.com/ZoneCNH/binance`；本次已用本地 `/home/binance`、`/home/domain-exchange`、`/home/domain-market` 与 `/home/decimalx` 对 runtime 代码进行交叉核对。该核对证明本地代码已满足当前 C/S 边界、wire 合约、snake_case import、`domain_exchange`/`domain_market` 适配和基础测试门禁；它不证明所有产品线业务能力已全量实现。

## Runtime 核对结果

[COMPUTED][HIGH] 本地 runtime 核对已完成，结果如下：

| # | 核对事实 | 结果 | 证据 |
|---|----------|------|------|
| 1 | Spot connector / smoke client 基础代码是否可编译 | 通过 | `/home/binance` 执行 `go test ./...` 通过 |
| 2 | `domain_exchange.VenueAdapter` 接口是否被 `BinanceAdapter` 满足 | 通过 | `/home/binance/pkg/binancex` 测试通过；`ListExecutions` / `StreamExecutions` 已返回 `VenueExecution` |
| 3 | Boundary gate 是否能在本地真实运行 | 通过 | `/home/binance/scripts/boundary-gates.sh` 输出 10 passed, 0 failed |
| 4 | C/S 是否仍依赖旧 `internal/cs` 或同进程 adapter | 通过 | boundary gate §5、§6 通过；runtime 迁移为 `internal/wire` |
| 5 | `domain_market` 与 `domain_exchange` 是否适配当前 `decimalx` API | 通过 | `/home/domain-market` 与 `/home/domain-exchange` 执行 `go test ./...` 通过 |
| 6 | Binance runtime 所需基础设施包是否保持直接依赖 | 通过 | boundary gate §11 通过；`go mod tidy` 后直接依赖未被降为仅间接依赖 |

[COMPUTED][HIGH] 仍需单独处理的不是本地源码编译错误，而是发布链路风险：远端 `github.com/ZoneCNH/decimalx@v1.0.0` 与 `sum.golang.org` 记录存在校验和不一致。本地通过 `replace github.com/ZoneCNH/decimalx => ../decimalx` 可以完成开发与测试，但远端消费者在不使用本地 replace 时仍可能拉取失败；该问题需要通过 `decimalx` 仓库的 tag/release 与模块代理链路治理解决。

[COMPUTED][MED] 本次 runtime 核对不会消除上文列出的规格层问题：产品线命名漂移、Options depth 覆盖缺口、追溯矩阵状态不一致、子规格版本漂移仍然是文档/规格层待修项。

[RULES I BROKE]：无
