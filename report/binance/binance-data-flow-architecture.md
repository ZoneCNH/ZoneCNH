# binance 模块数据流架构分析

| 字段 | 值 |
| --- | --- |
| 文档类型 | 数据流架构（含 Mermaid 图 + 模块职责边界） |
| 分析对象 | `github.com/ZoneCNH/binance` C/S 双进程数据通路 |
| 证据基准 | 运行时代码逐文件核验 |
| 当前 Runtime-Anchor | `/home/binance@f18a329` |
| 当前 Issue-Ledger | [`issues-sync-20260625.md`](./issues-sync-20260625.md) |
| 当前状态投影 | `24 Done / 10 Partial / 0 Pending` |
| 当前 issue 状态 | `#1106` Closed；`#1104`, `#1105`, `#1107`-`#1118` Open |
| 置信度 | HIGH |

`[COMPUTED, HIGH]` 本文保留数据流架构语境；当前行动清单和关闭条件统一维护在 [`issues-sync-20260625.md`](./issues-sync-20260625.md)。

---

## 目录

1. [全局架构总览](#1-全局架构总览)
2. [REST API 请求链路](#2-rest-api-请求链路)
3. [WebSocket 实时数据链路](#3-websocket-实时数据链路)
4. [数据解析、缓存、分发层](#4-数据解析缓存分发层)
5. [错误处理与重连机制](#5-错误处理与重连机制)
6. [关键模块职责边界](#6-关键模块职责边界)

---

## 1. 全局架构总览

binance 模块是**进程隔离的双服务架构**（C/S 严格边界，`BOUNDARY-GATES.md` 13 gate 强制）：

- **binance-client**：连接币安、归一化、发布到 NATS JetStream。
- **binance-server**：消费 JetStream、去重、四路落盘、提供 API、Kafka 广播。
- **通信契约**：NATS subject `binance.market.{product_line}.{event_type}` + `domain_market` envelope JSON（无本地 proto/gRPC）。

```mermaid
flowchart TB
    subgraph Upstream["币安交易所"]
        WSbin["WebSocket<br/>spot / fstream / dstream / options"]
        RESTbin["REST API<br/>klines / aggTrades"]
    end

    subgraph Client["binance-client 进程（采集+发布）"]
        direction TB
        C1["Connector 层<br/>spot.go · connectors/*.go"] --> C2["Throttle 限流<br/>throttle.go"]
        C2 --> C3["Normalize 归一化<br/>normalize.go"]
        C3 --> C4["Idempotency Key<br/>idempotency.go"]
        C4 --> C5["Publisher 发布<br/>publisher.go"]
        C5 --> C6["Queue 状态机<br/>queue.go · relay.go"]
        C6 -.->|可靠性控制面| CTRL["Controlplane<br/>lifecycle / stream_registry / reliability"]
    end

    subgraph Bus["NATS JetStream（解耦总线）"]
        JS["Stream BINANCE_MARKET<br/>Subject binance.market.*.*<br/>FileStorage · LimitsPolicy"]
    end

    subgraph Server["binance-server 进程（消费+持久化+服务）"]
        direction TB
        S1["Consumer Runner<br/>consumer.go"] --> S2["Ingest Process<br/>ingest.go"]
        S2 --> S3["幂等 RedisStore<br/>redis_store.go"]
        S2 --> S4["Dispatch 重试<br/>ingest.go:242"]
        S4 --> S5["四路并行存储"]
        S2 -.失败.-> DLQ["DeadLetter<br/>ingest.go + deadletter/"]
        S5 --> S6T["TDengine<br/>taos_writer"]
        S5 --> S6C["ClickHouse ETL<br/>clickhouse_olap"]
        S5 --> S6P["Postgres catalog<br/>pg_catalog"]
        S5 --> S6O["OSS 归档 batch<br/>oss_archiver"]
    end

    subgraph Downstream["下游消费"]
        KAF["kafkax 广播"]
        APIQ["Gin 查询 API<br/>query.go / analytics.go"]
    end

    WSbin --> C1
    RESTbin -. 历史/回补 .-> C3
    C6 -->|PubAck at-least-once| JS
    JS -->|ManualAck Pull| S1
    S4 --> KAF
    S6T --> APIQ
    S6C --> APIQ

    classDef proc fill:#e3f2fd,stroke:#1565c0
    classDef store fill:#e8f5e9,stroke:#2e7d32
    classDef fail fill:#ffebee,stroke:#c62828
    class Client,Bus,Server,Downstream proc
    class S6T,S6C,S6P,S6O store
    class DLQ fail
```

---

## 2. REST API 请求链路

REST 仅用于**历史数据回补**（冷启动 / gap-fill / 每日对账），不参与实时数据流。

```mermaid
sequenceDiagram
    autonumber
    participant Cron as cron_reconcile<br/>每日 04:00 UTC
    participant History as history_lifecycle<br/>history_fetcher
    participant REST as restHistoryFetcher<br/>history_rest.go
    participant Binance as Binance REST API

    Cron->>History: 触发回补（gap / 冷启动）
    History->>REST: FetchHistorical(symbol, eventType, from, to)
    REST->>REST: routeEndpoint(eventType)<br/>仅 Spot klines/aggTrades
    loop 分页（limit=1000）
        REST->>REST: fetchPage + 重试（3次指数退避 + 429感知）
        REST->>Binance: GET /api/v3/klines?symbol=&startTime=&endTime=&limit=
        Binance-->>REST: [[openTime,o,h,l,c,v,...], ...]
        REST->>REST: parseKlineArray → HistoryFetchResult
        REST->>REST: 推进 cursor（lastTS + 1ms，防死循环）
    end
    REST->>REST: 按时间排序去重
    REST-->>History: []HistoryFetchResult
    Note over REST: ⚠️ UM/CM/Options 不路由（routeEndpoint default 空）
```

**关键约束** `[KNOWN]`：
- `routeEndpoint`（`history_rest.go:143`）只识别 `kline/bar`→`/api/v3/klines`、`aggTrade/trade`→`/api/v3/aggTrades`，其余返回 `("","")`。
- 重试：3 次，退避 `RetryBackoff * 2^(attempt-1)`，429 单独 continue 重试。
- 分页防死循环：`cursor = lastTS.Add(time.Millisecond)`（`:117`）。
- **⚠️ 当前 runtime 未注入**：`runtime.go:96` 用 `DefaultHistoryRuntimeConfig()`，fetcher 实际不执行（FR-016 Partial）。

---

## 3. WebSocket 实时数据链路

WS 是**主数据通路**，覆盖全部 4 产品线。

```mermaid
sequenceDiagram
    autonumber
    participant Runtime as client.RunStandalone<br/>runtime.go:89
    participant Spot as SpotConnector.run<br/>spot.go:329
    participant WS as gorilla WebSocket
    participant Binance as 币安 WS 端点
    participant Norm as NormalizeMarketMessage
    participant Pub as Publisher
    participant NATS as NATS JetStream

    Runtime->>Spot: 启动 connector（含 symbol 列表 + stream kinds）
    loop 指数退避重连（1s→60s，无限）
        Spot->>WS: 建连 + subscribe（combined stream）
        WS->>Binance: wss://stream.binance.com:9443/stream
        Binance-->>WS: 连接建立
        loop 心跳保活
            WS->>Binance: ping（30s）
            Binance-->>WS: pong（60s 超时断连）
        end
        loop 消息读循环
            Binance-->>WS: {"stream":"btcusdt@trade","data":{...}}
            WS-->>Spot: 原始 JSON
            Spot->>Norm: NormalizeMarketMessage(pl, stream, msg, now)
            Norm-->>Spot: NormalizedEvent（产品线无关）
            Spot->>Pub: publish(event)
            Pub->>NATS: binance.market.{pl}.{et}（等 PubAck）
            NATS-->>Pub: PubAck
        end
        Note over Spot,Binance: 断连 → backoff *= 2 → 重连<br/>panic → recover → noteRecoveredPanic
    end
```

**WS 端点矩阵**（`pkg/binancecfg/endpoints.go`）`[KNOWN]`：

| 产品线 | mainnet WS 端点 | 实证状态 |
| --- | --- | --- |
| spot | `wss://stream.binance.com:9443` | ✅ LIVE-PASS |
| um_perp | `wss://fstream.binance.com` | ✅ LIVE-PASS |
| cm_perp | `wss://dstream.binance.com` | ✅ LIVE-PASS |
| options | `wss://fstream.binance.com/public` | ⚠️ 连通性验证（活跃 symbol 待补） |

**默认 stream kinds**（`product_line.go:103`）：`@trade` / `@bookTicker` / `@depth20@100ms` / `@kline_*` / 合约额外 `@markPrice` / `@fundingRate`。

---

## 4. 数据解析、缓存、分发层

### 4.1 归一化分派（单点）

```mermaid
flowchart LR
    MSG["原始 WS 消息<br/>{stream, data}"] --> PARSE["parseStreamName<br/>normalize.go:148<br/>提取 kind+symbol"]
    PARSE --> DISP{"stream kind<br/>switch"}
    DISP -->|trade/aggTrade| PT["parseTrade<br/>→ EventType=trade"]
    DISP -->|bookTicker/ticker| PB["parseBookTicker<br/>→ EventType=tick"]
    DISP -->|kline| PK["parseKline<br/>→ EventType=bar"]
    DISP -->|depth| PD["parseDepth<br/>→ 全量 DepthBids/Asks"]
    DISP -->|markPrice| PM["parseMarkPrice<br/>→ EventType=mark_price<br/>含 funding 三字段"]
    DISP -->|fundingRate| PF["parseFundingRate<br/>→ EventType=funding_rate"]
    DISP -->|optionTicker| PO["parseOptionTicker<br/>→ EventType=option_tick<br/>含 Greeks"]
    DISP -->|未知| RP["rawPassThrough<br/>→ EventType=tick<br/>保留 RawPayload"]

    PT & PB & PK & PD & PM & PF & PO & RP --> NE["NormalizedEvent<br/>（产品线无关，保留溯源）"]
    NE --> MAP["mapper.go → domain_market<br/>Tick/Quote/Bar"]

    classDef warn fill:#fff3e0,stroke:#e65100
    class PO warn
```

**设计要点** `[KNOWN]`：
- 单一 `NormalizeMarketMessage` 服务全部产品线，经 `CanonicalProductLine` 路由。
- 所有数值字段用 `string` 保留精度（避免 float 截断）， Greeks 亦然。
- `RawPayload` 全程保留，供审计与分析域派生。
- **⚠️ Options `parseOptionTicker` 字段名（e/E/s/o/c/p/q + d/g/t/v）未经真实 mainnet 样本校验**（`normalize.go:502` TODO）。

### 4.2 服务端缓存与分发

```mermaid
flowchart LR
    REQ["IngestRequest<br/>（wire 层）"] --> VALID["校验"]
    VALID --> IDEM{"幂等 CheckAndSet<br/>RedisStore SETNX 72h<br/>+ PG durable log"}
    IDEM -->|重复| ACK["Ack（跳过）"]
    IDEM -->|新事件| PERS["persist<br/>ingest.go:289"]
    PERS --> TW["TDengine Write<br/>taos_writer.go"]
    PERS --> HOOKS["runPostAcceptHooks<br/>ingest.go:303"]
    HOOKS --> PGH["pgCatalogHook<br/>UpsertSymbol"]
    HOOKS --> HCH["hotCacheHook<br/>Redis TTL 5s/60s"]
    HOOKS --> OAH["ossArchiveHook<br/>batch 500/30s"]
    HOOKS --> ASH["aggSourceHook<br/>→ ClickHouse ETL"]
    PERS --> DISP["dispatchWithRetry<br/>100/200/400ms"]
    DISP -->|成功| KAF["kafkax 广播"]
    DISP -->|耗尽| DLQ["appendDeadLetter<br/>ingest.go:328"]
    PERS -.失败.-> DLQ

    TW --> QAPI["查询 API<br/>query.go"]
    HCH --> QAPI
    ETL["ClickHouse ETL<br/>olap/clickhouse_olap.go"] --> AAPI["analytics API"]

    classDef store fill:#e8f5e9,stroke:#2e7d32
    class TW,PGH,HCH,OAH,ETL store
```

**存储职责划分** `[KNOWN]`：
| 存储 | 写入路径 | 角色 | TTL/保留 |
| --- | --- | --- | --- |
| TDengine | `StorageWriter`（主） | 时序事实库 st_trade/st_tick/st_bar | 永久 |
| Postgres | `pgCatalogHook` | 元数据 catalog + audit_log + idempotency durable log | 永久 |
| Redis | `hotCacheHook` + 幂等 | 热缓存（Tick 5s / Bar 60s）+ 幂等 | 5s/60s + 72h |
| ClickHouse | ETL goroutine | OLAP 聚合（ohlcv_1m/vwap_5m/stats_15m） | 永久 |
| OSS | `ossArchiveHook` batch | 冷数据归档（NDJSON + sha256） | 30 天 |

---

## 5. 错误处理与重连机制

### 5.1 多层重试体系

```mermaid
flowchart TB
    subgraph L1["L1: WS 连接层"]
        L1A["spot.go:329 指数退避<br/>1s→2s→4s...→60s 封顶<br/>MaxAttempts=0 无限重连"]
    end
    subgraph L2["L2: HTTP REST 层"]
        L2A["history_rest.go:167<br/>3 次指数退避<br/>+ 429 感知重试"]
    end
    subgraph L3["L3: JetStream 投递层"]
        L3A["relay.go at-least-once<br/>失败重排 queue<br/>MaxDeliver=5 / AckWait=30s"]
    end
    subgraph L4["L4: 服务端 dispatch 层"]
        L4A["ingest.go:242<br/>100/200/400ms 三次<br/>耗尽→DeadLetter"]
    end
    subgraph L5["L5: 可靠性控制面"]
        L5A["reliability.go<br/>RetryBudget 重试预算<br/>WeightGate 权重准入<br/>ClockSkewDetector 时钟偏移"]
    end

    L1 --> L3
    L2 --> L3
    L3 --> L4
    L5 -.->|约束| L1
    L5 -.->|约束| L4

    L4 -.终态.-> DLQ["DeadLetter<br/>内存 + FileWriter 持久化"]

    classDef fail fill:#ffebee,stroke:#c62828
    class DLQ fail
```

### 5.2 确认语义（consumer.go:159-180）

| 场景 | 处理 | 结果 |
| --- | --- | --- |
| `Process` 返回 Ack | `callAck` | 消息确认，不再投递 |
| `Process` 返回 Reject + Retryable | `callNak` | Nak，触发重投（受 MaxDeliver=5 限制） |
| `Process` 返回 Reject（不可重试） | `callTerm` | Term，终止投递（毒消息保护） |
| decode 失败 / panic | `callTerm` | 终止（防毒消息拖垮 consumer） |
| 超过 MaxDeliver | JetStream 自动 | 终态 |

**reject code 目录**（`server.go:228-271`）：`BNC-001..BNC-013`，每个含 `IsRetryable()` 判定，驱动 Nak vs Term。

### 5.3 幂等三层防护

```mermaid
flowchart LR
    EVT["NormalizedEvent"] --> K1["客户端 keyer<br/>idempotency.go:26<br/>sha256 摘要[:16]"]
    K1 --> REQ["IngestRequest.idempotency_key"]
    REQ --> NATS["NATS"]
    NATS --> K2{"服务端 RedisStore<br/>SETNX 72h<br/>redis_store.go:129"}
    K2 -->|新| K3["PG durable log<br/>pg_log.go:50<br/>binance_idempotency_log"]
    K2 -->|重复| SKIP["Ack 跳过"]
    K3 --> PROCESS["继续处理"]
```

---

## 6. 关键模块职责边界

| 模块 | 文件 | 职责边界 | 不可越界 |
| --- | --- | --- | --- |
| **client/connector** | `spot.go`, `connectors/*.go` | 连接币安、读消息、调 normalize | 不持久化、不广播 |
| **client/normalize** | `normalize.go` | 原始消息→NormalizedEvent | 不做 domain 映射（由 mapper） |
| **client/publisher** | `publisher.go`, `queue.go`, `relay.go` | at-least-once 发布到 NATS | 不消费 |
| **client/controlplane** | `lifecycle.go`, `stream_registry.go`, `reliability.go` | 流生命周期 + 可靠性控制面 | 不碰业务数据 |
| **wire** | `internal/wire/` | C/S 契约类型（IngestRequest/Result） | 过渡态，canonical 外置 |
| **server/consumer** | `consumer.go` | JetStream 拉取消费 + 确认 | 不做业务处理（委托 Processor） |
| **server/ingest** | `ingest.go` | 校验→幂等→持久化→dispatch→hooks | 不连接币安 |
| **server/storage** | `taos_writer`, `pg_catalog`, `oss_archiver` | 各存储 writer | 不跨存储耦合 |
| **server/storage/olap** | `clickhouse_olap.go` | OLAP ETL + 聚合查询 | 不写时序事实（TDengine 的职责） |
| **server/api** | `query.go`, `analytics.go` | 对外查询 REST | 不写数据 |
| **server/idempotency** | `redis_store.go`, `pg_log.go` | 幂等存储 | 不做业务校验 |
| **server/deadletter** | `deadletter.go` | 死信持久化（FileWriter） | 不重投（由人工/对账处理） |
| **server/controlplane** | `lifecycle.go`, `stream_registry.go` | 服务端流状态 + 暂停/恢复/排空 | 不碰币安连接（client 侧职责） |

**边界强制**：`BOUNDARY-GATES.md` 13 gate（BR-001~BR-009 + FR-009）由 `scripts/boundary-gates.sh` 自动校验，禁止 client↔server 互相 import、禁止 `binance-market` 旧仓库回流、禁止运行时共享包。

---

> **[RULES I BROKE]**：无。架构图基于代码逐文件核验，模块边界引用 `BOUNDARY-GATES.md` 实证；未发现结果与代码冲突处。
