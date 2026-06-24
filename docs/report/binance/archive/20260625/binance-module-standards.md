# Binance 模块开发与生产规范

> 制定日期：2026-06-25（Asia/Shanghai）
> 适用范围：`module/binance/` 规格文档与 `/home/binance` 运行时代码
> 判断：需要建立专门规范。[INFERRED, HIGH] 原因是 Binance 模块同时承载四产品线、多 endpoint、实时流、REST snapshot、JetStream、存储、Kafka、API 和发布证据，隐式约定已经导致文档漂移与 evidence 冲突。

## 目录

- [执行摘要](#执行摘要)
- [命名规范](#命名规范)
- [目录结构规范](#目录结构规范)
- [API 封装规范](#api-封装规范)
- [数据模型规范](#数据模型规范)
- [错误码与异常处理规范](#错误码与异常处理规范)
- [测试与文档规范](#测试与文档规范)
- [发布门禁规范](#发布门禁规范)

## 执行摘要

[INFERRED, HIGH] Binance 模块必须建立独立开发规范。生产风险集中在产品线命名、endpoint 路由、数据模型边界、错误降级、安全默认值、live evidence 和文档状态一致性。以下规范以“可审计、可复现、可回滚”为目标。

## 命名规范

### 产品线命名

| 概念           | 标准值    | 禁止写法                          | 说明                                                           |
| -------------- | --------- | --------------------------------- | -------------------------------------------------------------- |
| Spot           | `spot`    | `SPOT`、`cash`                    | [COMPUTED, HIGH] 与 `ProductLineSpot` 保持一致。               |
| USDⓈ-M Futures | `um_perp` | `usdm`、`u-future`、`um-perp`     | [COMPUTED, HIGH] 与 subject、topic、instrument key 保持一致。  |
| COIN-M Futures | `cm_perp` | `coinm`、`coin-future`、`cm-perp` | [COMPUTED, HIGH] 与 subject、topic、instrument key 保持一致。  |
| Options        | `options` | `option`、`vanilla`               | [COMPUTED, HIGH] 与 endpoint/catalog/stream planner 保持一致。 |

### Event type 命名

| Event         | 标准值         | 生产要求                                                               |
| ------------- | -------------- | ---------------------------------------------------------------------- |
| Trade         | `trade`        | 逐笔或聚合成交必须保留 raw event type。                                |
| Tick/Quote    | `tick`         | 当前 top-of-book quote 可用 `tick`，不得混用完整 order book。          |
| Bar           | `bar`          | interval 必须显式写入 event metadata。                                 |
| Depth         | `depth`        | 完整订单簿增量或快照必须用 `depth`，不得降级为 `tick`。                |
| Funding Rate  | `funding_rate` | 仅适用于合约产品线。                                                   |
| Mark Price    | `mark_price`   | 仅适用于合约与期权 mark 类数据。                                       |
| Option Ticker | `option_tick`  | Options ticker 必须进入 mapper/storage/fanout/API，不得停留在 parser。 |

### Subject、topic、key

- natsx subject：`binance.market.<product_line>.<event_type>`。[COMPUTED, HIGH]
- Kafka topic：`<topic_prefix>.<product_line>.<event_type>.<schema_version>`。[COMPUTED, HIGH]
- idempotency key：`<exchange>:<product_line>:<event_type>:<symbol>:<event_time>:<sequence_or_trade_id>`。[INFERRED, MED]
- release evidence 目录：`release/evidence/binance/<YYYYMMDD>/`，每个文件必须包含 commit、命令、环境、结果、失败原因或 PASS 证据。[INFERRED, HIGH]

## 目录结构规范

```text
/home/binance
├── internal/
│   ├── client/
│   │   ├── connectors/          # product-line constructor wrappers
│   │   ├── catalog/             # product-line exchangeInfo loaders when split out
│   │   ├── normalize*.go        # raw stream -> normalized event
│   │   ├── mapper.go            # normalized event -> domain/wire
│   │   ├── publisher/           # natsx PubAck publishing
│   │   ├── admin*.go            # collector control plane
│   │   └── history/             # backfill/replay adapters
│   ├── server/
│   │   ├── consumer/            # JetStream durable consumer
│   │   ├── ingest*.go           # validate/idempotency/ack/fanout flow
│   │   ├── idempotency/         # Redis-backed idempotency
│   │   ├── storage/             # taosx/postgresx/clickhousex/ossx adapters
│   │   ├── api/                 # Gin query/admin API
│   │   ├── cache/               # redisx hot cache
│   │   ├── metrics/             # Prometheus registry
│   │   └── controlplane/        # throttle/retry/budget controls
│   └── wire/                    # cross-process envelope contract
├── pkg/binancecfg/              # endpoints, modes, secrets, production profile
├── test/e2e/                    # mock + gated live e2e
└── release/evidence/binance/    # immutable release evidence
```

[INFERRED, MED] `SpotConfig`、`NewSpotConnector` 这类复用名应迁移到 `ProductLineConfig`、`NewMarketStreamConnector`。兼容别名最多保留一个 minor 版本，并在标准中标记废弃日期。

## API 封装规范

### REST API

1. [COMMON, HIGH] 所有 REST 调用必须接受 `context.Context`，并设置 request timeout、retry budget、rate weight、endpoint mode 和 product line。
2. [INFERRED, HIGH] 禁止在业务代码中拼接裸 URL；必须通过 `pkg/binancecfg` 或 product-line REST client 生成。
3. [COMMON, HIGH] 每个 REST response 必须保留 raw body 摘要、HTTP status、Binance error code、request id、rate-limit headers 和解析错误。
4. [COMPUTED, HIGH] depth REST snapshot 是 order book 正确性的必需输入；不得只消费 diff stream 后声明本地 order book 可用。
5. [INFERRED, HIGH] Futures/Options `exchangeInfo` 或 active contract catalog 必须与 Spot `exchangeInfo` 具有同等级别的 typed parser 与 tests。

### WebSocket API

1. [COMPUTED, HIGH] WebSocket 连接必须按产品线和 stream class 分组。
2. [COMPUTED, HIGH] USD-M 必须区分 `/public`、`/market`、`/private`；Options 必须遵守 200 streams per connection 上限。
3. [COMMON, HIGH] 每条连接必须有 24h rotation、ping/pong deadline、subscription message rate limit、reconnect backoff、resubscribe audit。
4. [INFERRED, HIGH] subscription planner 必须输出可审计计划：`product_line`、`endpoint`、`stream_class`、`symbols`、`streams`、`connection_id`、`rate_budget`。
5. [COMMON, HIGH] 收到无法识别 event 时不得静默丢弃；必须记录 metric、样本摘要和 reject/skip 原因。

### Query/Admin API

1. [INFERRED, HIGH] 生产 profile 下 API token 缺失必须 fail-closed。
2. [INFERRED, HIGH] rate-limit 后端缺失或错误不得默认放行外部请求；必须显式进入 degraded mode，并由配置决定是否只允许 localhost。
3. [COMPUTED, HIGH] API error response 应保持统一 envelope：`code`、`message`、`request_id`、`details`。
4. [INFERRED, MED] query API 必须按规格补齐 `ticks`、`bars`、`depth`、`trades`，并声明每个 endpoint 的 freshness SLA。

## 数据模型规范

### Canonical model

[COMPUTED, HIGH] `domain_market` 是市场数据 canonical model 的权威边界。Binance 模块不得发明与其冲突的交易对、合约、bar、quote、depth schema。

必填维度：

| 维度           | 要求                                                          |
| -------------- | ------------------------------------------------------------- |
| `exchange`     | 固定为 `binance`。                                            |
| `product_line` | `spot`、`um_perp`、`cm_perp`、`options`。                     |
| `symbol`       | 保留 Binance 原始 symbol，同时映射 canonical instrument key。 |
| `event_type`   | 使用标准 event type。                                         |
| `event_time`   | 来自交易所事件时间；ingest time 另存。                        |
| `raw`          | 保留原始 payload 或可追溯 raw reference。                     |
| `sequence`     | trade id、update id、bar open time、或可用于幂等的序列字段。  |

### Depth model

1. [COMPUTED, HIGH] depth event 必须保留 `firstUpdateID`、`finalUpdateID`、`previousUpdateID`、bids、asks、qty=0 删除语义。
2. [COMMON, HIGH] 本地 order book 必须通过 REST snapshot + diff stream 建立，且 `pu == previous u` 不满足时必须 restart。
3. [INFERRED, HIGH] 对外发布完整 depth 时必须标记 `snapshot`、`delta`、`reconstructed`、`gap_recovered` 状态。
4. [INFERRED, HIGH] top-of-book quote 不得冒充完整 depth。

### Options model

1. [INFERRED, HIGH] Options ticker 必须显式建模 Greeks、implied volatility、underlying、expiry、strike、side/type。
2. [INFERRED, HIGH] Options symbol catalog 必须从 active contracts 生成，禁止硬编码过期合约。
3. [INFERRED, HIGH] `option_tick` 必须有 mapper、wire schema、storage schema、Kafka topic 和 API 查询契约。

## 错误码与异常处理规范

### 错误分类

| 分类                  | 示例                                         | 处理                                                        |
| --------------------- | -------------------------------------------- | ----------------------------------------------------------- |
| `terminal_validation` | schema 缺字段、product_line 非法、时间戳越界 | reject，记录样本，不重试。                                  |
| `terminal_conflict`   | 同 idempotency key 不同 payload              | reject，报警，写审计。                                      |
| `retryable_exchange`  | WS disconnect、REST 429/5xx、ping timeout    | backoff retry，记录 endpoint 和 retry budget。              |
| `retryable_storage`   | Redis/TAOS/Postgres/ClickHouse 临时失败      | NakWithDelay 或 strict fail，超过 MaxDeliver 进 DLQ。       |
| `retryable_fanout`    | Kafka send timeout/broker unavailable        | 不得声明 fanout PASS，必须重试并进入 DLQ/evidence failure。 |
| `security_denied`     | token 缺失、签名失败、rate limit exceeded    | fail-closed，返回 401/403/429。                             |

### 错误码

[COMPUTED, HIGH] 当前已有 `BNC-001` 到 `BNC-013` 等错误码。新增错误码必须遵守：

- `BNC-0xx`：wire/schema/validation。
- `BNC-1xx`：exchange endpoint/reconnect/rate-limit。
- `BNC-2xx`：storage/cache/idempotency。
- `BNC-3xx`：fanout/Kafka/downstream。
- `BNC-4xx`：API auth/rate-limit/query。
- `BNC-5xx`：release/evidence/config/profile。

### 日志与敏感信息

1. [COMPUTED, HIGH] API key、secret、token 必须使用 secret wrapper；禁止直接日志输出。
2. [COMMON, HIGH] 日志可记录 endpoint class、product line、symbol、stream、request id、error code，但不得记录完整凭据、签名、私有 header。
3. [INFERRED, HIGH] 生产 incident 日志必须能关联：connection id、subscription plan、JetStream sequence、idempotency key、Kafka topic、storage adapter。

## 测试与文档规范

### 测试分层

| 层级               | 必测内容                                                                                                   | 发布要求                                    |
| ------------------ | ---------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| Unit               | product-line normalization、stream parser、mapper、depth continuity、error classification、auth/rate-limit | 每次 PR 必跑。                              |
| Mock E2E           | mock WS -> connector -> normalize -> mapper -> publisher -> consumer -> ingest -> API/Kafka/storage fake   | 每次 PR 必跑，不能手工跳过真实 serializer。 |
| Live Mainnet Gated | Spot、UM、CM、Options 每条产品线至少一个真实 event                                                         | release 前必跑，结果写 evidence。           |
| Infra Live Gated   | natsx、redisx、taosx、postgresx、clickhousex、kafkax、ossx                                                 | release 前必跑，必须包含 roundtrip。        |
| Security           | gitleaks、govulncheck、auth fail-closed、rate-limit fail-closed                                            | release 前必跑。                            |
| Performance        | parse/map/ingest/API latency、stream fanout throughput、reconnect recovery time                            | release 前必跑并生成 SLO report。           |

### 文档同步

1. [INFERRED, HIGH] `TRACEABILITY.md` 是状态主索引；README、ACCEPTANCE、RUNTIME-MAPPING、release evidence 不得给出相互冲突的 ready 状态。
2. [INFERRED, HIGH] 每次修改 release readiness 必须同时更新：目标、证据文件、命令、commit、结果、剩余 gap。
3. [INFERRED, MED] 文档中的“生产就绪”只能在所有 P0 release gates PASS 且无 evidence 冲突时使用。

## 发布门禁规范

发布前必须满足以下条件：

| Gate                      | 条件                                                               | 失败处理                         |
| ------------------------- | ------------------------------------------------------------------ | -------------------------------- |
| G1 Product Coverage       | Spot、UM、CM、Options 均有真实 mainnet event evidence              | 任一产品线缺失，禁止全量发布。   |
| G2 Endpoint Compliance    | Spot/Futures/Options endpoint 与官方文档一致，含 USD-M route split | 不一致时禁止启用相关 stream。    |
| G3 Order Book Correctness | snapshot+diff+gap restart 测试与 live evidence PASS                | depth/API/orderbook 不得发布。   |
| G4 Bus Reliability        | natsx PubAck、ManualAck、NakWithDelay、DLQ evidence PASS           | 禁止声明 durable pipeline。      |
| G5 Storage/Fanout         | storage roundtrip 与 Kafka send+consume roundtrip PASS             | 禁止声明存储或下游分发生产就绪。 |
| G6 API Security           | prod token/rate-limit fail-closed PASS                             | 禁止暴露外部 API。               |
| G7 Observability          | metrics、logs、alerts、SLO report、runbook PASS                    | 禁止无人值守生产运行。           |
| G8 Documentation          | readiness 状态无冲突，证据文件完整                                 | 禁止打 release-ready 标签。      |

[INFERRED, HIGH] 当前模块应先以这些 gate 重建 release readiness，而不是继续累加零散 PASS 文件。

[RULES I BROKE]：无
