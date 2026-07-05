# 功能点清单

> **仓库**：`/home/workspace/binance`
> **方法**：逐项确认是否存在、实现位置、实现方式、是否有测试

## 项目定位说明

`/home/workspace/binance` 是 **Binance 行情数据采集 C/S 模块**（主功能），外加一个并存的**交易侧 VenueAdapter**（`pkg/binancex`）。因此 1-5（交易）与 6-17（行情/治理）分属两条独立链路。

## 完整功能清单

| # | 功能点 | 是否实现 | 实现文件:行号 | 实现方式 | 有测试 |
|---|--------|---------|--------------|---------|--------|
| 1 | **现货下单** | ✅ 是 | `pkg/binancex/adapter.go:135` `SubmitOrder` | 调用 `sdk.NewCreateOrderService()`（binance-connector-go Spot SDK），支持 LIMIT/MARKET/STOP-LIMIT、TIF、ClientOrderID、stopPrice；响应解析 ACK/RESULT/FULL 三种 `NewOrderResponseType` | ✅ `adapter_http_test.go:43-395`（Market/Limit/StopLimit/ClientOrderID/无价格/API错误/解析错误 7 组） |
| 2 | **合约下单** | ❌ 否（仅行情） | — | `binancex` 只持有一个 Spot `*sdk.Client`（`adapter.go:23,53`），`SubmitOrder` 走 Spot `/api/v3/order`。`GetCapabilities` 声明 `SupportsFutures:true`（:433）但**无合约下单实现**。合约仅体现在行情侧：`connectors/um_perp.go`、`cm_perp.go` 公共 WS 采集 + `history_rest.go` REST klines（`/fapi/v1/klines`、`/dapi/v1/klines`） | ❌ |
| 3 | **撤单** | ✅ 是 | `adapter.go:179` `CancelOrder`；`:214` `CancelOrders` | 单笔 `NewCancelOrderService().OrderId()`；批量为循环单笔撤，逐条返回 `CancelOrderResult{Cancelled,ErrorReason}`，单条失败不阻断 | ✅ `adapter_http_test.go:397-512` |
| 4 | **查询订单** | ✅ 是 | `adapter.go:196` `GetOrder`；`:516` `GetOrderByClientOrderID`；`:238` `ListExecutions` | GetOrder 按 orderId+symbol；GetOrderByClientOrderID 按 `OrigClientOrderId`；ListExecutions 通过 `NewGetOpenOrdersService` 推断活跃 symbol 后逐 symbol 调 `NewGetMyTradesService` | ✅ `adapter_http_test.go:513-1014` |
| 5 | **查询余额/账户/持仓** | ⚠️ 部分 | `adapter.go:84` `GetAccountInfo`；`:101` `GetBalances`；`:130` `GetPositions` | GetAccountInfo/GetBalances 走 `NewGetAccountService`，过滤零余额，free+locked=total；**GetPositions 固定返回空切片**（Spot 无持仓概念，合约持仓未实现） | ✅ `adapter_http_test.go:692-847`；`adapter_test.go:58` |
| 6 | **K线行情** | ✅ 是 | `internal/client/normalize.go:420` `parseKline`；`intervals.go:3`；`history_rest.go:64` | WS：解析 `<symbol>@kline_<iv>` 的 OHLCV+IsFinal+Interval → `NormalizedEvent.Bar`；REST：`/api/v3/klines`、`/fapi/v1/klines`、`/dapi/v1/klines` 分页+去重+重试；多周期订阅 | ✅ `normalize_coverage_test.go`、`history_rest_test.go` |
| 7 | **深度行情/订单簿** | ✅ 是 | `normalize.go:324` `parseDepth`；`normalize.go:202` `depthLevelFromStream`；`mapper.go:117` | 解析 `@depth20@100ms`（快照）与 `@depth@1000ms`（diff），保留全量档位，映射 `DepthBids/DepthAsks []BookLevel` → `domainmarket.Quote`；`test/depth/depth_test.go` 3178 行覆盖 9 个 FR | ✅ `test/depth/depth_test.go` |
| 8 | **WebSocket 实时推送** | ✅ 是 | 市场流：`internal/client/spot.go:370` `Start`/`:425` `collect`；用户流：`adapter.go:282` `StreamExecutions` | 市场流：组合流 `wss://host/stream?streams=...`，心跳 ping/pong、512KB 读限、指数退避重连、背压丢弃计数；用户流：gorilla/websocket 连 `/ws/{listenKey}`，解析 `executionReport` 仅处理 `x=TRADE` | ✅ `spot_stream_coverage_test.go`、`adapter_http_test.go:1180-1420` |
| 9 | **签名认证** | ✅ 是（SDK 内置） | `adapter.go:53` `sdk.NewClient(APIKey, SecretKey, baseURL)` | HMAC-SHA256 签名由 `binance-connector-go` SDK 内部完成，本仓不重复实现；`binancecfg` 提供 mainnet/testnet 端点选择；测试用 `httptest.Server` 校验请求签名 | ✅ `adapter_http_test.go` |
| 10 | **ListenKey 管理** | ✅ 是 | `adapter.go:284` 创建；`:339` `keepAliveListenKey`；`:313` 关闭时 DELETE | `NewCreateListenKeyService` 创建 → 连 WS；独立 goroutine 每 30min 调 `NewPingUserStream` PUT 续期；ctx 取消时发 CloseFrame 并 DELETE | ✅ `adapter_http_test.go:1231,1422-1500` |
| 11 | **行情接入** | ✅ 是 | `internal/client/spot.go`、`connectors/{spot,um_perp,cm_perp,options}.go`、`history_rest.go`、`exchangeinfo.go`、`catalog.go`、`normalize.go`、`mapper.go`、`publisher/publisher.go` | 四产品线 connector 统一走 `SpotConnector` + `ProductLineSpec`；exchangeInfo→Catalog 投影；normalize→`domainmarket.Tick/Quote/Bar`；幂等键；经 natsx 发布 | ✅ `connectors_test.go`、`m2_test.go`、`catalog_test.go` 等 |
| 12 | **数据存储** | ✅ 是 | TDengine：`storage/taos_writer.go`（749 行）；ClickHouse：`storage/olap/clickhouse_olap.go`；OSS：`storage/oss_archiver.go`；PG：`pg_catalog.go`、`pg_whitelist.go`、`pg_tx.go`；保留：`taos_retention.go`、`retention_policy.go`、`oss_rehydrate.go` | 窄接口注入，nil 优雅降级；事件按 EventType 路由 super table；ClickHouse 周期 ETL 聚合；OSS 按时间窗归档 + SHA256 完整性 | ✅ `taos_writer_test.go`、`clickhouse_olap_test.go`、`oss_archiver_test.go` 等 |
| 13 | **白名单** | ✅ 是 | `internal/server/whitelist/{service,rules,sync_job,publisher}.go`；`storage/pg_whitelist.go`；`pkg/whitelistclient/`；`assembly/whitelist_adapter.go` | 全量/增量查询（version-based，200/304）；`SyncJob` 定时同步→PG→NATS 版本号；`whitelistclient` 带本地缓存 | ✅ `service_test.go`、`sync_job_test.go` 等 |
| 14 | **幂等性** | ✅ 是 | client：`internal/client/idempotency.go`；server：`internal/server/idempotency.go` + `idempotency/redis_store.go` + `idempotency/pg_log.go` | client 生成跨重试稳定键（sha256）；server `CheckAndSet` 原子语义（首次接受/幂等重复/冲突三种返回）；maxSize 满则 RejectServerUnavailable | ✅ `idempotency_test.go` 等 |
| 15 | **限频/节流** | ⚠️ 是（已实现未接线） | `internal/client/throttle.go`（288 行） | weight-aware token bucket；80/20 split（coldStart/repair）；AIMD（成功加性增、429 乘性减×0.5）；Prometheus 指标。**但实际请求路径未调用 `Allow()`** | ✅ `throttle_test.go` |
| 16 | **重放/死信** | ✅ 是 | 死信：`internal/server/deadletter/deadletter.go`；重放：`internal/server/deadletter_replay.go`；桥：`replay_bridge.go`；再水化：`oss_rehydrate.go` | JetStream MaxDeliver 耗尽前写本地 JSONL；replay 走 dispatcher.Dispatch + replay ledger 防；gap 检测经 replay_bridge 入队 | ✅ `deadletter_test.go`、`reconcile_test.go` |
| 17 | **热重载/配置刷新** | ✅ 是 | client：`internal/client/admin.go:442` `reloadSymbols`、`catalog.go:266` `Reload`、`exchangeinfo_refresh.go`；server：`whitelist/sync_job.go:110`、`api/feature_flag.go` | `POST /api/v1/admin/symbols/reload` 替换本地 catalog→推进 stream generation→重建 WS URL（不重启）；周期性 exchangeInfo→catalog 投影 | ✅ `exchangeinfo_refresh_test.go`、`admin_test.go` |

## 关键发现

1. **合约下单（#2）是唯一未实现项**：交易适配器仅接 Spot SDK，无合约下单路径。`SupportsFutures:true` 是能力声明但未落地。合约仅存在于行情采集侧。
2. **持仓查询（#5）为占位实现**：`GetPositions` 固定返回空切片。
3. **签名（#9）由 SDK 承担**：本仓不重复 HMAC 逻辑，符合「不重复造轮子」原则。
4. **存储层最完整**：TDengine（热）+ ClickHouse（OLAP ETL）+ OSS（冷归档）+ PostgreSQL（catalog/whitelist/tx/audit）四套，全部带测试与降级。
5. **限频（#15）已实现未接线**：`ThrottleManager` 代码完整且有测试，但实际请求路径未调用 `Allow()`，是 P1 遗留风险。
6. **`test/depth/depth_test.go`（3178 行）** 是最大单一测试文件，覆盖 9 个 FR 的 happy/error/edge/integration/race 五维度。
