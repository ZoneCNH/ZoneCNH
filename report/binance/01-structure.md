# 代码结构分析

> **仓库**：`/home/workspace/binance`（`github.com/ZoneCNH/binance`）
> **Go 版本**：1.25.0 / toolchain go1.26.4

## 1. 模块划分

### 1.1 cmd 入口层

| 目录                 | 职责                                           | 文件数 | 代码行数 |
| -------------------- | ---------------------------------------------- | ------ | -------- |
| `cmd/binance-client` | 采集进程：连接 Binance WS → 规范化 → NATS 投递 | 1      | 279      |
| `cmd/binance-server` | 摄取进程：assembly 组装 → 验收/幂等/分发       | 1      | 276      |
| `cmd/binance-smoke`  | 同进程冒烟：wire client+server（有意边界特例） | 1      | 255      |
| `cmd/http-probe`     | HTTP 探针工具                                  | 1      | 35       |

### 1.2 pkg 公共包层

| 目录                  | 职责                                          | 文件数 | 代码行数 |
| --------------------- | --------------------------------------------- | ------ | -------- |
| `pkg/binancex`        | Binance VenueAdapter 适配器（交易/账户/行情） | 4      | 617      |
| `pkg/binancecfg`      | 运行时配置加载（configx，8 个 infra 前缀）    | 3      | 550      |
| `pkg/whitelistclient` | 白名单查询客户端（带缓存）                    | 2      | 516      |

### 1.3 internal/client 采集端

| 目录                         | 职责                                                                   | 文件数 | 代码行数 |
| ---------------------------- | ---------------------------------------------------------------------- | ------ | -------- |
| `internal/client`            | 行情采集核心：connector/parser/normalizer/queue/cursor/relay/lifecycle | 36     | 8,503    |
| `internal/client/connectors` | 产品线连接器：spot/um_perp/cm_perp/options                             | 4      | 32       |
| `internal/client/publisher`  | 事件发布器                                                             | 1      | 113      |

### 1.4 internal/ingestcodec 边界契约

| 目录                   | 职责                                                                     | 文件数 | 代码行数 |
| ---------------------- | ------------------------------------------------------------------------ | ------ | -------- |
| `internal/ingestcodec` | client↔server 线路契约：RejectCode(BNC-001..019)、aliases、InstrumentKey | 4      | 192      |

### 1.5 internal/server 摄取服务端

| 目录                                 | 职责                                                                    | 文件数 | 代码行数 |
| ------------------------------------ | ----------------------------------------------------------------------- | ------ | -------- |
| `internal/server`                    | server 核心：ingest/idempotency/dispatch/quality/reconcile/admin        | 19     | 3,677    |
| `internal/server/api`                | HTTP API：market query + analytics + whitelist handler                  | 4      | 921      |
| `internal/server/assembly`           | 组装层：assemble/dispatcher/storage/hooks/olap_source/whitelist_adapter | 7      | 1,884    |
| `internal/server/cache`              | 热缓存 + 分布式锁                                                       | 2      | 429      |
| `internal/server/catalogdiff`        | 目录差异订阅                                                            | 1      | 194      |
| `internal/server/completeness`       | 完整性扫描                                                              | 1      | 173      |
| `internal/server/consumer`           | NATS 消费者                                                             | 1      | 404      |
| `internal/server/controlplane`       | 控制面：lifecycle/reliability/stream_registry                           | 3      | 1,117    |
| `internal/server/coverage`           | 覆盖率：scanner/store/subscriber                                        | 3      | 429      |
| `internal/server/deadletter`         | 死信处理                                                                | 1      | 172      |
| `internal/server/idempotency`        | 幂等：redis_store + pg_log                                              | 2      | 442      |
| `internal/server/metrics`            | 指标：metrics/audit/cost                                                | 3      | 754      |
| `internal/server/reconcile`          | 对账器                                                                  | 1      | 208      |
| `internal/server/storage`            | 存储：taos_writer/pg_catalog/pg_whitelist/oss_archiver/retention        | 10     | 2,315    |
| `internal/server/storage/olap`       | ClickHouse OLAP 存储                                                    | 1      | 656      |
| `internal/server/storage/taosdriver` | TDengine 驱动封装                                                       | 1      | 353      |
| `internal/server/whitelist`          | 白名单：service/rules/publisher/sync_job                                | 4      | 678      |

## 2. 依赖关系

### 2.1 外部直接依赖（go.mod）

| 依赖                           | 版本    | 用途                   |
| ------------------------------ | ------- | ---------------------- |
| `binance/binance-connector-go` | v0.8.0  | Binance REST SDK       |
| `gorilla/websocket`            | v1.5.3  | WebSocket 连接         |
| `gin-gonic/gin`                | v1.12.0 | HTTP API 框架          |
| `nats-io/nats.go`              | v1.52.0 | NATS JetStream 消息    |
| `prometheus/client_golang`     | v1.23.2 | Prometheus 指标        |
| `taosdata/driver-go/v3`        | v3.8.0  | TDengine 驱动          |
| `golang-migrate/migrate/v4`    | v4.19.1 | DB 迁移                |
| `go.opentelemetry.io/otel`     | v1.44.0 | OpenTelemetry 链路追踪 |
| `DATA-DOG/go-sqlmock`          | v1.5.2  | SQL mock 测试          |

### 2.2 ZoneCNH 基座依赖

| 基座模块          | 版本   | 角色                              |
| ----------------- | ------ | --------------------------------- |
| `bootstrap`       | v0.2.2 | 进程启动框架                      |
| `configx`         | v1.1.0 | 配置加载（SecretString 掩码）     |
| `contracts`       | v0.5.1 | 跨域契约（RejectCode canonical）  |
| `decimalx`        | v1.0.0 | 精度计算                          |
| `domain-exchange` | v1.0.0 | 交易所域模型（VenueAdapter 接口） |
| `domain-market`   | v1.1.0 | 行情域模型                        |
| `domainx`         | v1.0.1 | 通用域（Position/Trade）          |
| `kafkax`          | v1.1.2 | Kafka 客户端                      |
| `natsx`           | v1.0.5 | NATS 客户端                       |
| `ossx`            | v1.2.1 | OSS 对象存储                      |
| `postgresx`       | v1.1.2 | PostgreSQL 客户端                 |
| `redisx`          | v1.0.1 | Redis 客户端                      |
| `resiliencx`      | v1.0.2 | 弹性容错                          |
| `taosx`           | v1.0.3 | TDengine 客户端                   |
| `clickhousex`     | v1.0.9 | ClickHouse 客户端                 |

### 2.3 内部包依赖方向

```
cmd/binance-client  → internal/client + pkg/binancecfg + pkg/binancex
cmd/binance-server  → internal/server/assembly + pkg/binancecfg + pkg/binancex
cmd/binance-smoke   → internal/client + internal/server（有意边界特例）

ingestcodec (18次被引) ← 全仓最高扇入，client/server 共享边界契约
internal/server (14)   ← assembly/api/admin 依赖
pkg/binancecfg (13)    ← client/runtime 等依赖配置
internal/server/metrics (11)
internal/client (6)
internal/server/whitelist (5)
```

**关键纪律**：

- `internal/client/doc.go:9` 明确声明"本包不得 import internal/server/\*\*"
- client 与 server 仅通过 `ingestcodec` 边界契约 + relay 投递通信
- `assembly` 是 server 组装根，聚合所有 server 子包

## 3. 对外接口

### 3.1 BinanceAdapter 方法表（pkg/binancex/adapter.go）

| 方法                      | 行号 | 签名摘要                                                        | 职责                            |
| ------------------------- | ---- | --------------------------------------------------------------- | ------------------------------- |
| `NewBinance`              | :39  | `(cfg Config) *BinanceAdapter`                                  | 工厂：按 Config 创建 SDK client |
| `NewBinanceAdapter`       | :67  | `(client *sdk.Client) *BinanceAdapter`                          | 工厂：注入已有 SDK client       |
| `Venue`                   | :74  | `() string`                                                     | 返回 "binance"                  |
| `HealthCheck`             | :79  | `(ctx, cred) error`                                             | ping 连通性检查                 |
| `GetAccountInfo`          | :84  | `(ctx, cred) (*VenueAccountInfo, error)`                        | 账户信息                        |
| `GetBalances`             | :101 | `(ctx, cred) ([]*VenueBalance, error)`                          | 账户余额                        |
| `GetPositions`            | :130 | `(ctx, cred) ([]domain.Position, error)`                        | 持仓（占位，返回空）            |
| `SubmitOrder`             | :135 | `(ctx, cred, req) (*VenueOrderResponse, error)`                 | 现货下单                        |
| `CancelOrder`             | :179 | `(ctx, cred, venueOrderID, symbol) error`                       | 撤单                            |
| `GetOrder`                | :196 | `(ctx, cred, venueOrderID, symbol) (*VenueOrderStatus, error)`  | 查单                            |
| `CancelOrders`            | :214 | `(ctx, cred, reqs) ([]*CancelOrderResult, error)`               | 批量撤单                        |
| `ListExecutions`          | :238 | `(ctx, cred, startTime) ([]domain.Trade, error)`                | 成交流水                        |
| `StreamExecutions`        | :282 | `(ctx, cred, handler) error`                                    | WS 成交流                       |
| `GetCapabilities`         | :429 | `(ctx) *VenueCapabilities`                                      | 能力声明                        |
| `GetOrderByClientOrderID` | :516 | `(ctx, cred, clientOrderID, symbol) (*VenueOrderStatus, error)` | 按 clientOrderID 查单           |

### 3.2 HTTP API 端点表

**Market Query API**（`internal/server/api/query.go:160-167`，挂载 `/api/v1`，需 auth + rateLimit）

| 方法 | 路径                                     | handler              |
| ---- | ---------------------------------------- | -------------------- |
| GET  | `/api/v1/market/:pl/:symbol/latest`      | handleMarketLatest   |
| GET  | `/api/v1/market/:pl/:symbol/:kind/range` | handleMarketRange    |
| GET  | `/api/v1/instrument/:pl`                 | handleInstrumentList |
| GET  | `/api/v1/stats`                          | handleStats          |

**Analytics API**（`internal/server/api/analytics.go:81-85`）

| 方法 | 路径                               | handler             |
| ---- | ---------------------------------- | ------------------- |
| GET  | `/api/v1/analytics/vwap`           | handleVWAP          |
| GET  | `/api/v1/analytics/top-movers`     | handleTopMovers     |
| GET  | `/api/v1/analytics/correlation`    | handleCorrelation   |
| GET  | `/api/v1/analytics/volume-profile` | handleVolumeProfile |

**Whitelist 内部 API**（`internal/server/api/whitelist_handler.go:25-26`）

| 方法 | 路径                          | handler       |
| ---- | ----------------------------- | ------------- |
| GET  | `/internal/whitelist`         | handleGet     |
| POST | `/internal/whitelist/refresh` | handleRefresh |

### 3.3 cmd 入口表

| 二进制           | 入口                         | main 行号 | 职责       |
| ---------------- | ---------------------------- | --------- | ---------- |
| `binance-client` | `cmd/binance-client/main.go` | :113      | 采集进程   |
| `binance-server` | `cmd/binance-server/main.go` | :70       | 摄取进程   |
| `binance-smoke`  | `cmd/binance-smoke/main.go`  | :86       | 同进程冒烟 |
| `http-probe`     | `cmd/http-probe/main.go`     | :11       | HTTP 探针  |
