> [ARCHIVED 2026-06-22] 本文档为 v2.0.0 重构前的深度分析（2026-06-21），已被 SPEC v2.2.0 + TRACEABILITY v2.2.0 覆盖。保留作历史参考，不作为当前规格输入。

# module/binance 深度架构分析

> 分析日期：2026-06-21
> 分析范围：当前 SPEC v1.0.1 + 实际代码状态 → 目标全栈架构（redisx + kafkax + natsx + postgresx + taosx + ossx + Gin）
> 状态：**已归档** — 分布式约束与代码实态审计已迁移为指针，当前规范以 SPEC v2.2.3 和迁移说明为准

---

## 0. 分布式架构约束（已迁移）

> [COMPUTED] HIGH：本节的规范内容已迁移到 `module/binance/SPEC.md` §4.1；历史迁移说明与旧审计依据见 `docs/migrations/binance-v2-upgrade.md`。
>
> 本归档文件不再承载分布式约束的权威正文，避免与当前 SPEC 形成第二 SSOT。

## 1. 当前架构评估

### 1.1 现状概览

```
Binance Exchange (WS/REST)
    │
    ▼
┌──────────────────────────────────────────────┐
│  binance/client (采集器)                       │
│  catalog → parser → normalize → mapper        │
│  → idempotency key → SQLite spool             │
│  → checkpoint → gRPC sender                   │
└──────────────────┬───────────────────────────┘
                   │ contracts.MarketDataService
                   │ gRPC bidi stream
                   ▼
┌──────────────────────────────────────────────┐
│  binance/server (接入受理)                     │
│  ingest → validation → idempotent acceptance  │
│  → ACK/Reject → downstream dispatch           │
└──────────────────┬───────────────────────────┘
                   │ downstream dispatch port
                   ▼
┌──────────────────────────────────────────────┐
│  market_data (交易所中立管线)                   │
└──────────────────────────────────────────────┘
```

### 1.2 当前架构特征

| 维度 | 现状 | 评估 |
|------|------|------|
| Client-Server 通信 | gRPC bidi stream (contracts-defined) | 强类型，但需 protoc + proto 生成 |
| Client 持久化 | SQLite spool + checkpoint | 单机可靠，但无分布式容灾 |
| Server 幂等 | in-memory map (骨架首版) | 进程重启丢失，不可生产 |
| Server 存储 | 无 — 纯 handoff 到 market_data | 不符合"服务端存储"目标 |
| Web 接口 | Gin admin (/healthz, /readyz, /debug/*) | 仅运维面，无业务 API |
| 基础设施依赖 | 仅 bootstrap + domain_market + domain_exchange | 6 个目标模块全为 indirect / 未使用 |
| 产品线覆盖 | 仅 Spot (骨架)，其余 3 条待实现 | 4 条全需补全 |

### 1.3 与目标的差距

> 用户目标：**完整使用 redisx + kafkax + natsx + postgresx + taosx + ossx，客户端只做采集同步，服务端处理存储，提供 Gin web 接口给 market_data 调用**

| # | 目标要求 | 当前状态 | GAP |
|---|---------|---------|-----|
| G1 | 使用 natsx 做 client→server 通信 | gRPC bidi stream | **需替换** |
| G2 | 使用 redisx 做缓存/锁/幂等 | 无 (in-memory) | **需新增** |
| G3 | 使用 kafkax 做事件发布 | 无 (直接 dispatch port) | **需新增** |
| G4 | 使用 postgresx 做元数据/配置存储 | 无 (SQLite spool) | **需新增** |
| G5 | 使用 taosx 做时序行情存储 | 无 (不存储) | **需新增** |
| G6 | 使用 ossx 做历史归档 | 无 | **需新增** |
| G7 | 服务端做处理 + 存储 | 仅验证+幂等+转发 | **需重构** |
| G8 | 提供 Gin web API 给 market_data | 仅 admin 端点 | **需新增** |
| G9 | Client 仅采集+同步 | 含 spool/checkpoint/sender 全套 | **需简化** |

**结论：当前 SPEC v1.0.1 到目标状态是一次重大架构升级，涉及通信层替换、存储层新建、API 层新建、Client 职责大幅简化。建议升级到 SPEC v2.0.0。**

---

## 2. 目标架构设计

### 2.1 全景架构图

```
                          Binance Exchange
                    REST API ─┴─ WebSocket Streams
                              │
        ┌─────────────────────┼─────────────────────┐
        │  Spot       USDⓈ-M      COIN-M     Options │
        ▼            ▼            ▼           ▼
┌──────────────────────────────────────────────────────────┐
│  binance/client  ── 采集 + 同步（极简）                     │
│                                                          │
│  catalog ─► parser ─► normalize ─► mapper                │
│                                  │                       │
│                           natsx Publisher                │
│                      (JetStream at-least-once)            │
│                                                          │
│  observex (metrics/logs/traces)                           │
│  Gin admin (:8081) — /healthz /readyz                    │
└──────────────────────────┬───────────────────────────────┘
                           │ natsx JetStream
                           │ subject: binance.market.{product_line}.{event_type}
                           ▼
┌──────────────────────────────────────────────────────────┐
│  binance/server  ── 处理 + 存储（富服务端）                  │
│                                                          │
│  ┌─ natsx Consumer (JetStream) ──┐                       │
│  │  validation + idempotency     │                       │
│  │  (redisx: idempotency store)  │                       │
│  └──────────────┬────────────────┘                       │
│                 ▼                                        │
│  ┌─ Processing Pipeline ─────────┐                       │
│  │  enrich / aggregate / derive  │                       │
│  │  (redisx: hot cache)          │                       │
│  └──────────────┬────────────────┘                       │
│                 │                                        │
│     ┌───────────┼───────────┬───────────┐               │
│     ▼           ▼           ▼           ▼               │
│  postgresx   taosx      kafkax       ossx               │
│  (元数据)    (行情TS)    (事件流)     (归档)             │
│                                                          │
│  ┌─ Gin Web API (:8080) ─────────────────┐              │
│  │  GET  /api/v1/market/ticks/:symbol    │              │
│  │  GET  /api/v1/market/bars/:symbol     │              │
│  │  GET  /api/v1/market/depth/:symbol    │              │
│  │  GET  /api/v1/instruments             │              │
│  │  GET  /api/v1/health                  │              │
│  │  POST /api/v1/admin/reload-catalog    │              │
│  └───────────────────────────────────────┘              │
│                                                          │
│  observex (metrics/logs/traces)                           │
└──────────┬──────────┬──────────┬────────────────────────┘
           │          │          │
    Gin REST API  kafkax     observex
    (market_data  (事件通知)  (统一可观测)
     主动查询)
           │          │
           ▼          ▼
     market_data   下游消费者
     (HTTP调用)    (Kafka消费)
```

### 2.2 关键架构决策

| # | 决策 | 理由 | 替代方案 |
|---|------|------|---------|
| AD-1 | **natsx JetStream 替代 gRPC** | 无需 protoc 工具链；天然 at-least-once + 持久化；运维简单；与 ZoneCNH 基座一致 | gRPC (类型安全但需 proto 生成)；Kafka (过重，适合跨域不适合 C/S 直连) |
| AD-2 | **Client 不再持有 spool/checkpoint** | JetStream 提供持久化和重投，client 无需自己管理投递状态 | 保留 spool 做双保险 (增加复杂度) |
| AD-3 | **Server 负责全量存储** | 满足"服务端处理+存储"需求；market_data 从 owner 变为 consumer | Server 仍只做 handoff (不满足目标) |
| AD-4 | **redisx 做幂等存储 + 热缓存** | 高性能 KV；支持 TTL 自动过期；分布式场景可扩展 | postgresx (重，但持久)；in-memory (不持久) |
| AD-5 | **taosx 做时序行情主存储** | TDengine 超级表模型天然适合按产品线分表；写入吞吐 10万+/s | clickhousex (OLAP 强但写入弱)；postgresx (不适合高频写入) |
| AD-6 | **postgresx 做元数据/配置存储** | 关系型适合 catalog、配置、审计日志 | 纯文件配置 (缺少查询能力) |
| AD-7 | **kafkax 做跨域事件发布** | 解耦 server 与下游消费者；支持多消费者组独立消费 | natsx JetStream (也可，但 kafkax 是大数据生态标准) |
| AD-8 | **ossx 做历史数据归档** | 对象存储成本低；适合冷数据长期保存 | 本地文件 (不可扩展) |
| AD-9 | **Gin REST API 面向 market_data** | 标准 HTTP，无客户端依赖；market_data 可主动拉取 | gRPC (需生成客户端)；GraphQL (过度) |

---

## 3. 六模块集成详案

### 3.1 natsx — Client ↔ Server 通信总线

**角色**：取代 gRPC，作为 client→server 的唯一数据传输通道。

```
Publisher (Client)                    Consumer (Server)
─────────────────                    ─────────────────
natsx.Publish(ctx, subj, data)       natsx.Subscribe(subj, handler)
       │                                      │
       ▼                                      ▼
┌───────────────── JetStream ────────────────────┐
│  Stream: BINANCE_MARKET                        │
│  Subjects:                                     │
│    binance.market.spot.tick                    │
│    binance.market.spot.bar                     │
│    binance.market.spot.depth                   │
│    binance.market.spot.trade                   │
│    binance.market.um_perp.tick                 │
│    binance.market.um_perp.bar                  │
│    binance.market.um_perp.depth                │
│    binance.market.cm_perp.tick                 │
│    binance.market.cm_perp.bar                  │
│    binance.market.options.tick                 │
│    binance.market.options.bar                  │
│  Retention: 7 days (足够重启恢复)               │
│  Storage: file (本地持久化)                     │
│  Replicas: 1 (生产可升 3)                       │
└────────────────────────────────────────────────┘
```

**Client 侧 (Publisher)**：
```go
// internal/client/publisher/publisher.go
type MarketPublisher struct {
    js   natsx.JetStreamContext
    subj string
}

func (p *MarketPublisher) Publish(ctx context.Context, event *domainmarket.MarketFactEnvelope) error {
    data, _ := json.Marshal(event)
    // JetStream Publish: 同步等待 ACK，确保消息已持久化
    _, err := p.js.Publish(p.subj, data)
    return err
}
```

**Server 侧 (Consumer)**：
```go
// internal/server/consumer/consumer.go
type MarketConsumer struct {
    js      natsx.JetStreamContext
    handler IngestHandler
}

func (c *MarketConsumer) Start(ctx context.Context) error {
    // JetStream Subscribe with durable consumer
    sub, err := c.js.Subscribe("binance.market.>", c.handler.Handle,
        natsx.Durable("binance-server"),
        natsx.ManualAck(),
    )
    return err
}
```

**Client 简化对照**：
| 组件 | 当前 (gRPC 架构) | 目标 (natsx 架构) | 变化 |
|------|-----------------|-------------------|------|
| spool/ | SQLite spool | **删除** — JetStream 提供持久化 | 简化 |
| checkpoint/ | ACK-driven checkpoint | **删除** — JetStream ACK 即确认 | 简化 |
| sender/ | gRPC bidi stream sender | **替换为** publisher/ (natsx) | 替换 |
| idempotency/ | Key 生成逻辑 | **保留** — 生成 key 放入 event header | 保留 |

### 3.2 redisx — 幂等存储 + 热缓存 + 分布式锁

**角色**：Server 侧的三合一高速存储层。

```
┌─────────────────────────────────────────┐
│              redisx                      │
│                                          │
│  ┌─ Idempotency Store ─────────────┐    │
│  │ Key: idem:{event_key}            │    │
│  │ Value: {accepted_at, stream_id}  │    │
│  │ TTL: 72h (覆盖 JetStream 重投窗口) │    │
│  │ Op: SET NX (原子性保证)           │    │
│  └──────────────────────────────────┘    │
│                                          │
│  ┌─ Hot Cache (最新行情) ───────────┐    │
│  │ Key: tick:{product_line}:{symbol} │    │
│  │ Value: JSON{price, volume, ts}   │    │
│  │ TTL: 60s (自动过期)               │    │
│  │ Op: SET (覆盖写)                   │    │
│  └──────────────────────────────────┘    │
│                                          │
│  ┌─ Distributed Lock ──────────────┐    │
│  │ Key: lock:binance:coordinator     │    │
│  │ Token: {instance_id}              │    │
│  │ TTL: 30s (lease + auto-renew)     │    │
│  │ Op: Lock/Unlock/Extend            │    │
│  └──────────────────────────────────┘    │
│                                          │
│  ┌─ Rate Limiter ──────────────────┐    │
│  │ Key: rate:api:{endpoint}:{ip}     │    │
│  │ Window: fixed 1s                  │    │
│  │ Limit: 100 req/s per endpoint     │    │
│  └──────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

**idempotency store 实现**：
```go
// internal/server/idempotency/redis_store.go
type RedisIdempotencyStore struct {
    client *redisx.Client
}

func (s *RedisIdempotencyStore) TryAccept(ctx context.Context, key string, payloadHash string) (AcceptResult, error) {
    // SET NX: 原子性 — 只有第一个写入成功
    ok, err := s.client.SetNX(ctx, "idem:"+key, payloadHash, 72*time.Hour)
    if err != nil {
        return AcceptResult{}, err
    }
    if ok {
        return AcceptResult{Status: Accepted}, nil
    }
    // 已存在 — 检查 payload 是否一致
    existing, _ := s.client.Get(ctx, "idem:"+key)
    if existing == payloadHash {
        return AcceptResult{Status: Duplicate}, nil
    }
    return AcceptResult{Status: Conflict}, nil
}
```

### 3.3 postgresx — 元数据 + 配置 + 审计

**角色**：Server 侧的关系型数据存储。

```
┌─────────────────────────────────────────┐
│            postgresx                      │
│                                           │
│  ┌─ Instrument Catalog ─────────────┐    │
│  │ Table: binance_instruments         │    │
│  │ Columns:                           │    │
│  │   id (PK), symbol, product_line,   │    │
│  │   base_asset, quote_asset,         │    │
│  │   margin_asset, settlement_asset,  │    │
│  │   expiry, strike, option_type,     │    │
│  │   contract_code, status,           │    │
│  │   price_precision, qty_precision,  │    │
│  │   created_at, updated_at           │    │
│  └────────────────────────────────────┘    │
│                                           │
│  ┌─ Idempotency Log (持久备份) ──────┐    │
│  │ Table: binance_idempotency_log     │    │
│  │ Columns:                           │    │
│  │   idempotency_key (PK),            │    │
│  │   status, payload_hash,            │    │
│  │   stream_id, accepted_at           │    │
│  │ (redisx 主存储的持久备份)           │    │
│  └────────────────────────────────────┘    │
│                                           │
│  ┌─ Admin / Audit ──────────────────┐    │
│  │ Table: binance_admin_audit        │    │
│  │ Table: binance_stream_sessions    │    │
│  │ Table: binance_daily_stats        │    │
│  └────────────────────────────────────┘    │
│                                           │
│  ┌─ Migration Runner ───────────────┐    │
│  │ migrations/                        │    │
│  │   001_init_catalog.sql             │    │
│  │   002_init_idempotency_log.sql     │    │
│  │   003_init_audit.sql               │    │
│  └────────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

**迁移策略**：
```sql
-- migrations/001_init_catalog.sql
CREATE TABLE IF NOT EXISTS binance_instruments (
    id              BIGSERIAL PRIMARY KEY,
    symbol          TEXT NOT NULL,
    product_line    TEXT NOT NULL CHECK (product_line IN ('spot','um_perp','cm_perp','options')),
    base_asset      TEXT NOT NULL,
    quote_asset     TEXT,
    margin_asset    TEXT,
    settlement_asset TEXT,
    expiry          BIGINT,
    strike          NUMERIC,
    option_type     TEXT CHECK (option_type IN ('call','put')),
    contract_code   TEXT,
    status          TEXT NOT NULL DEFAULT 'active',
    price_precision INT NOT NULL DEFAULT 8,
    qty_precision   INT NOT NULL DEFAULT 8,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(symbol, product_line)
);

CREATE INDEX idx_instruments_product_line ON binance_instruments(product_line);
CREATE INDEX idx_instruments_status ON binance_instruments(status);
```

### 3.4 taosx — 时序行情主存储

**角色**：Server 侧高频行情数据的时序存储引擎。

```
┌─────────────────────────────────────────────┐
│              taosx (TDengine)                 │
│                                              │
│  ┌─ Super Table: binance_ticks ─────────┐   │
│  │  Tags: product_line, symbol, exchange  │   │
│  │  Columns:                              │   │
│  │    ts TIMESTAMP,                       │   │
│  │    price DOUBLE,                       │   │
│  │    volume DOUBLE,                      │   │
│  │    bid DOUBLE, ask DOUBLE,             │   │
│  │    bid_qty DOUBLE, ask_qty DOUBLE,     │   │
│  │    is_best BOOL                        │   │
│  │  Child Tables: t_{product_line}_{symbol}│   │
│  └────────────────────────────────────────┘   │
│                                              │
│  ┌─ Super Table: binance_bars ──────────┐   │
│  │  Tags: product_line, symbol, interval  │   │
│  │  Columns:                              │   │
│  │    ts TIMESTAMP,                       │   │
│  │    open DOUBLE, high DOUBLE,           │   │
│  │    low DOUBLE, close DOUBLE,           │   │
│  │    volume DOUBLE, trades INT           │   │
│  └────────────────────────────────────────┘   │
│                                              │
│  ┌─ Super Table: binance_depth ────────┐    │
│  │  Tags: product_line, symbol           │   │
│  │  Columns:                              │   │
│  │    ts TIMESTAMP,                       │   │
│  │    side ENUM('bid','ask'),             │   │
│  │    level INT,                          │   │
│  │    price DOUBLE, qty DOUBLE            │   │
│  └────────────────────────────────────────┘   │
│                                              │
│  Write: SchemalessWrite / WriteBatch         │
│  Query: Gin API → taosx.Query               │
│  Retention: 30d (ticks), 365d (bars)        │
└─────────────────────────────────────────────┘
```

**写入策略**：
```go
// internal/server/storage/taos_writer.go
type TaosMarketWriter struct {
    client *taosx.Client
}

func (w *TaosMarketWriter) WriteTick(ctx context.Context, tick *domainmarket.MarketFactEnvelope) error {
    point := taosx.NewPoint("binance_ticks",
        taosx.Tags{
            "product_line": tick.ProductLine,
            "symbol":       tick.InstrumentKey.Symbol,
            "exchange":     "binance",
        },
        taosx.Columns{
            "ts":      tick.EventTime,
            "price":   tick.Payload.Price,
            "volume":  tick.Payload.Volume,
            "bid":     tick.Payload.Bid,
            "ask":     tick.Payload.Ask,
            "bid_qty": tick.Payload.BidQty,
            "ask_qty": tick.Payload.AskQty,
        },
    )
    return w.client.WriteBatch(ctx, []taosx.Point{point})
}
```

### 3.5 kafkax — 跨域事件发布

**角色**：Server 侧将已接受的行情事件发布到 Kafka，供下游模块（signal-engine、risk-engine、backtestx 等）消费。

```
Producer (binance/server)           Consumers
─────────────────────────           ─────────
kafkax.Producer.Send()             kafkax.Consumer.Poll()
       │                                    │
       ▼                                    ▼
┌────────────────── Kafka ──────────────────────┐
│  Topics:                                      │
│    binance.market.ticks    (实时逐笔)          │
│    binance.market.bars     (K线)               │
│    binance.market.depth    (深度)              │
│    binance.market.events   (行情事件/状态变更)  │
│                                                │
│  Partitions: 按 symbol hash 分区               │
│  Retention: 7 days                             │
│  Compression: snappy                           │
│                                                │
│  Consumer Groups:                              │
│    signal-engine  (因子计算)                    │
│    risk-engine    (风控)                        │
│    backtestx      (回测)                       │
│    market_regime  (市场状态)                    │
└────────────────────────────────────────────────┘
```

**发布策略**（关键：natsx → kafkax 的衔接点）：
```go
// internal/server/dispatch/kafka_dispatcher.go
type KafkaDispatcher struct {
    producer *kafkax.Producer
}

func (d *KafkaDispatcher) Dispatch(ctx context.Context, event *AcceptedEvent) error {
    // server 接受事件后 → 同时写 taosx + kafkax
    topic := fmt.Sprintf("binance.market.%s", event.EventType)
    key := fmt.Sprintf("%s:%s", event.ProductLine, event.Symbol)
    value, _ := json.Marshal(event)

    return d.producer.Send(ctx, topic, key, value)
}
```

### 3.6 ossx — 历史数据归档

**角色**：Server 侧定期将过期行情数据从 taosx 归档到对象存储。

```
┌─────────────────────────────────────────────┐
│              ossx (Aliyun OSS)                │
│                                              │
│  Bucket: zonecnh-binance-market-archive      │
│                                              │
│  ┌─ Daily Archive ─────────────────────┐    │
│  │  Path:                                 │    │
│  │  /{date}/{product_line}/{event_type}/  │    │
│  │    {symbol}/                           │    │
│  │    2026/06/21/spot/tick/BTCUSDT.parquet│   │
│  │    2026/06/21/um_perp/bar/BTCUSDT.parquet│ │
│  └──────────────────────────────────────┘    │
│                                              │
│  ┌─ Depth Snapshots ───────────────────┐    │
│  │  Path: /snapshots/{date}/              │    │
│  │    depth_{symbol}_{ts}.json.gz         │    │
│  └──────────────────────────────────────┘    │
│                                              │
│  Archive Policy:                             │
│    Ticks: 7d taosx → 30d parquet → archive   │
│    Bars:  30d taosx → permanent archive      │
│    Depth: 3d taosx → monthly snapshot        │
└─────────────────────────────────────────────┘
```

**归档调度**：
```go
// internal/server/archiver/oss_archiver.go
type OssArchiver struct {
    store  *ossx.BlobStore
    taos   *taosx.Client
}

func (a *OssArchiver) ArchiveDaily(ctx context.Context, date time.Time) error {
    // 1. Query taosx for data older than retention
    // 2. Convert to Parquet/JSON.gz
    // 3. Upload to ossx via MultipartStarter
    // 4. Verify upload integrity
    // 5. (可选) Clean taosx expired data
    return nil
}
```

---

## 4. Gin Web API 设计

### 4.1 API 全景

```
Base URL: http://{host}:8080/api/v1

┌─────────────────────────────────────────────────────────────┐
│                     REST API Endpoints                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Market Data Query (面向 market_data)                        │
│  ─────────────────────────────────────                       │
│  GET    /market/ticks/:symbol         最新 Tick               │
│  GET    /market/ticks/:symbol/range   历史 Tick (时间范围)     │
│  GET    /market/bars/:symbol          最新 Bar                │
│  GET    /market/bars/:symbol/range    历史 Bar                │
│  GET    /market/depth/:symbol         最新深度                │
│  GET    /market/depth/:symbol/history 深度历史                │
│  GET    /market/trades/:symbol        最新成交                │
│                                                              │
│  Instrument Query (产品线 & 合约查询)                         │
│  ─────────────────────────────────────                       │
│  GET    /instruments                  全部合约列表             │
│  GET    /instruments?product_line=spot 按产品线过滤            │
│  GET    /instruments/:symbol          单个合约详情             │
│                                                              │
│  Health & Status                                            │
│  ─────────────────────────────────────                       │
│  GET    /health                       健康检查                 │
│  GET    /health/readiness             就绪检查                 │
│  GET    /stats/streams                流统计                   │
│  GET    /stats/daily                  日统计                   │
│                                                              │
│  Admin (运维管理)                                            │
│  ─────────────────────────────────────                       │
│  POST   /admin/catalog/reload         重载产品线目录            │
│  POST   /admin/stream/pause/:line     暂停产品线               │
│  POST   /admin/stream/resume/:line    恢复产品线               │
│  GET    /admin/config                 查看配置                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 API 响应格式

遵循 `contracts` 模块的标准 API 信封：

```json
{
  "success": true,
  "data": {
    "symbol": "BTCUSDT",
    "product_line": "spot",
    "price": "87654.32",
    "volume": "1.2345",
    "timestamp": "2026-06-21T12:00:00Z"
  },
  "error": null,
  "meta": {
    "source": "binance",
    "latency_ms": 2
  }
}
```

### 4.3 Gin 路由注册

```go
// internal/server/api/router.go
func NewRouter(deps ServerDeps) *gin.Engine {
    r := gin.New()
    r.Use(gin.Recovery())
    r.Use(deps.Observability.GinMiddleware()) // observex tracing/logging

    // Health (no auth)
    r.GET("/health", deps.HealthHandler.Health)
    r.GET("/health/readiness", deps.HealthHandler.Readiness)

    v1 := r.Group("/api/v1")
    v1.Use(deps.AuthMiddleware.BearerToken()) // simple token auth
    {
        market := v1.Group("/market")
        {
            market.GET("/ticks/:symbol", deps.MarketHandler.LatestTick)
            market.GET("/ticks/:symbol/range", deps.MarketHandler.TickRange)
            market.GET("/bars/:symbol", deps.MarketHandler.LatestBar)
            market.GET("/bars/:symbol/range", deps.MarketHandler.BarRange)
            market.GET("/depth/:symbol", deps.MarketHandler.LatestDepth)
            market.GET("/depth/:symbol/history", deps.MarketHandler.DepthHistory)
            market.GET("/trades/:symbol", deps.MarketHandler.LatestTrades)
        }

        instr := v1.Group("/instruments")
        {
            instr.GET("", deps.InstrumentHandler.List)
            instr.GET("/:symbol", deps.InstrumentHandler.Get)
        }

        stats := v1.Group("/stats")
        {
            stats.GET("/streams", deps.StatsHandler.Streams)
            stats.GET("/daily", deps.StatsHandler.Daily)
        }

        admin := v1.Group("/admin")
        {
            admin.POST("/catalog/reload", deps.AdminHandler.ReloadCatalog)
            admin.POST("/stream/pause/:line", deps.AdminHandler.PauseStream)
            admin.POST("/stream/resume/:line", deps.AdminHandler.ResumeStream)
            admin.GET("/config", deps.AdminHandler.GetConfig)
        }
    }
    return r
}
```

### 4.4 market_data 调用场景

| 场景 | API | 频率 | 说明 |
|------|-----|------|------|
| 获取最新价 | `GET /market/ticks/:symbol` | 按需/轮询 | market_data 需要某 symbol 最新价时调用 |
| 历史回放 | `GET /market/bars/:symbol/range` | 按需 | 回测系统需要历史 K 线时调用 |
| 深度快照 | `GET /market/depth/:symbol` | 1 req/s | 实时深度数据 |
| 合约发现 | `GET /instruments` | 启动时 + 定时 | 同步可用合约列表 |

---

## 5. 完整数据流

### 5.1 Tick 事件全链路（端到端时序）

```
Time  │  Component        │  Action
──────┼───────────────────┼──────────────────────────────────────
T+0   │  Binance WS       │  推送 {"e":"24hrTicker","s":"BTCUSDT",...}
T+1ms │  client/spot      │  WebSocket read → raw event
T+2ms │  client/parser    │  解析 symbol → InstrumentKey
T+3ms │  client/normalize │  标准化 → TickerEvent{...}
T+4ms │  client/mapper    │  映射 → domainmarket.Tick{Price, Volume, ...}
T+5ms │  client/publisher │  natsx.Publish("binance.market.spot.tick", json)
      │                    │  → JetStream ACK (持久化确认)
T+5ms │  client 完成      │  【Client 职责到此结束】
──────┼───────────────────┼──────────────────────────────────────
T+6ms │  natsx JetStream  │  消息持久化到 Stream BINANCE_MARKET
T+7ms │  server/consumer  │  natsx.Subscribe → 收到消息
T+8ms │  server/validate  │  校验 envelope 完整性
T+9ms │  server/idempotency│ redisx.SetNX("idem:{key}") → Accepted
T+10ms│  server/processor  │  enrich: 补充衍生字段
      │                    │  aggregate: 累积 Volume 等
──────┼───────────────────┼──────────────────────────────────────
      │  [并行写入]        │
T+11ms│  server/storage    │  taosx.WriteBatch → binance_ticks
T+12ms│  server/cache      │  redisx.SET("tick:spot:BTCUSDT", json, 60s)
T+13ms│  server/dispatch   │  kafkax.Send("binance.market.ticks", key, value)
──────┼───────────────────┼──────────────────────────────────────
T+14ms│  【存储完成】       │  事件已持久化到 taosx + kafkax
──────┼───────────────────┼──────────────────────────────────────
T+15ms│  market_data       │  HTTP GET /api/v1/market/ticks/BTCUSDT
T+17ms│  server/api        │  redisx.GET("tick:spot:BTCUSDT") → 命中缓存
T+18ms│  → market_data     │  200 OK {price: "87654.32", ...}
```

### 5.2 数据持久化矩阵

| 数据类型 | redisx | postgresx | taosx | kafkax | ossx |
|---------|:------:|:---------:|:-----:|:------:|:----:|
| 最新 Tick (热) | ✅ 60s TTL | — | ✅ 实时写 | ✅ 实时发 | — |
| 历史 Tick (7d) | — | — | ✅ 查询 | — | — |
| 历史 Tick (30d+) | — | — | — | — | ✅ 归档 |
| Bar (实时) | ✅ 60s TTL | — | ✅ 实时写 | ✅ 实时发 | — |
| Bar (历史) | — | — | ✅ 查询 | — | ✅ 归档 |
| Depth 快照 | ✅ 5s TTL | — | ✅ 实时写 | ✅ 实时发 | ✅ 快照 |
| 合约元数据 | ✅ 10min TTL | ✅ 主存储 | — | — | — |
| 幂等记录 | ✅ 72h TTL | ✅ 持久备份 | — | — | — |
| 审计日志 | — | ✅ 主存储 | — | — | — |
| 流统计 | — | ✅ 主存储 | — | — | — |

---

## 6. 目录结构变更

### 6.1 Client 简化

```diff
  github.com/ZoneCNH/binance/
    cmd/
      binance-client/main.go
    internal/
      client/
        app/          # 应用装配
        config/       # 配置加载
        catalog/      # 产品线目录 (保留)
        parser/       # 符号解析 (保留)
-       spot/         # → connectors/spot
-       usdm/         # → connectors/usdm
-       coinm/        # → connectors/coinm
-       options/      # → connectors/options
+       connectors/   # 产品线 connector (合并)
+         spot.go
+         usdm.go
+         coinm.go
+         options.go
        normalize/    # 事件规范化 (保留)
        mapper/       # 规范映射 (保留)
-       spool/        # 删除 — JetStream 替代
-       checkpoint/   # 删除 — JetStream 替代
-       sender/       # 删除 — 替换为 publisher
+       publisher/    # natsx 发布器 (新增)
        admin/        # Gin admin (精简)
        observability/# observex 集成
```

### 6.2 Server 扩展

```diff
    internal/
      server/
        app/           # 应用装配 (扩展)
        config/        # 配置加载 (扩展)
-       ingest/        # gRPC ingest → natsx consumer
+       consumer/      # natsx JetStream 消费 (新增)
        validation/    # 请求校验 (保留)
        idempotency/   # 幂等处理 (重写: redisx + postgresx)
-       ack/           # gRPC ACK → 删除
-       dispatch/      # downstream port → kafkax dispatch
+       processor/     # 处理管线 (新增: enrich/aggregate/derive)
+       storage/       # 存储层 (新增)
+         taos_writer.go    # taosx 写入
+         pg_catalog.go     # postgresx 元数据
+         oss_archiver.go   # ossx 归档
+       cache/         # redisx 缓存层 (新增)
+       dispatch/      # kafkax 事件发布 (重写)
+       api/           # Gin web API (新增)
+         router.go
+         handler/
+           market.go
+           instrument.go
+           stats.go
+           admin.go
+         middleware/
+           auth.go
+           ratelimit.go
        admin/         # client 侧 admin (精简)
        observability/ # observex 集成
```

---

## 7. 配置设计

```yaml
# binance-server.yaml
server:
  gin:
    bind: ":8080"
    mode: release  # debug | release | test
    auth_token: "${BINANCE_API_TOKEN}"

nats:
  url: "nats://127.0.0.1:4222"
  stream: "BINANCE_MARKET"
  auth:
    user: "admin"
    password_env: "FOUNDATIONX_NATS_PASSWORD"
  consumer:
    durable: "binance-server"
    ack_wait: 30s
    max_deliver: 5

redis:
  addr: "localhost:6379"
  db: 0
  password: "${REDIS_PASSWORD}"
  pool_size: 20
  idempotency_ttl: 72h
  hot_cache_ttl: 60s

postgres:
  host: "localhost"
  port: 5432
  database: "binance"
  user: "binance"
  password: "${PG_PASSWORD}"
  pool_max: 20
  migration: true

taos:
  endpoint: "localhost:6041"
  database: "binance_market"
  driver: "websocket"
  write_batch_size: 1000
  write_flush_interval: 100ms
  tick_retention: "30d"
  bar_retention: "365d"

kafka:
  brokers: ["localhost:9092"]
  producer:
    acks: "all"
    compression: "snappy"
    max_retries: 3
  topics:
    ticks: "binance.market.ticks"
    bars: "binance.market.bars"
    depth: "binance.market.depth"

oss:
  endpoint: "oss-cn-hangzhou.aliyuncs.com"
  bucket: "zonecnh-binance-market-archive"
  access_key_id: "${OSS_AK}"
  access_key_secret: "${OSS_SK}"
  archive:
    tick_after_days: 7
    bar_after_days: 30
    depth_snapshot_interval: "1h"

binance:
  endpoints:
    rest: "https://api.binance.com"
    ws: "wss://stream.binance.com:9443"
  product_lines: ["spot", "um_perp", "cm_perp", "options"]
  symbols:
    allow: []
    deny: []

observex:
  log_level: "info"
  metrics_port: ":9090"
  trace_exporter: "otlp"
```

---

## 8. 部署拓扑

```
┌─────────────────────────────────────────────────────────────┐
│                    Deployment Topology                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Zone A (采集区)                                              │
│  ┌──────────────┐   ┌──────────────┐                        │
│  │binance-client │   │binance-client │  (可横向扩展)           │
│  │  (spot+um)   │   │ (cm+options) │                        │
│  └──────┬───────┘   └──────┬───────┘                        │
│         │                  │                                 │
│         └────────┬─────────┘                                 │
│                  │ natsx                                     │
│                  ▼                                           │
│  ┌──────────────────────────────┐                            │
│  │     NATS Server (Cluster)    │                            │
│  │     JetStream + WebSocket    │                            │
│  └──────────────┬───────────────┘                            │
│                  │                                            │
├──────────────────┼───────────────────────────────────────────┤
│  Zone B (服务区)  │                                            │
│                  ▼                                            │
│  ┌──────────────────────────────┐                            │
│  │     binance-server (2+)      │  (HA: 至少 2 实例)          │
│  │  consumer + processor + API  │                            │
│  └──┬───────┬───────┬──────┬───┘                            │
│     │       │       │      │                                  │
│     ▼       ▼       ▼      ▼                                  │
│  ┌─────┐┌─────┐┌──────┐┌──────┐                              │
│  │redis││pg   ││taos  ││kafka │                              │
│  │     ││     ││      ││      │                              │
│  └─────┘└─────┘└──────┘└──┬───┘                              │
│                            │                                  │
│  ┌─────────────────────────┘                                 │
│  │  kafkax → signal-engine / risk-engine / backtestx         │
│  │                                                            │
│  ┌──────────────────────────────┐                            │
│  │  market_data (HTTP client)    │                            │
│  │  → GET /api/v1/market/ticks/*│                            │
│  └──────────────────────────────┘                            │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 9. SPEC 升级路线图

### 9.1 版本规划

| 版本 | 范围 | 预计变更 |
|------|------|---------|
| v1.0.1 → v1.1.0 | 补齐 4 产品线 + natsx 替换 gRPC | Client 简化，通信层替换 |
| v1.1.0 → v1.2.0 | Server 存储层：taosx + redisx + postgresx | 新增存储能力 |
| v1.2.0 → v2.0.0 | kafkax + ossx + Gin API | 完整目标架构 |

### 9.2 PR 序列建议

```
Phase 1: 基础设施就绪
  PR-A: natsx 集成 — 替换 gRPC client→server 通信
  PR-B: 补齐 4 产品线 connector (USDⓈ-M / COIN-M / Options)

Phase 2: 存储层
  PR-C: redisx 集成 — 幂等存储 + 热缓存 + 限流
  PR-D: postgresx 集成 — 元数据存储 + migration
  PR-E: taosx 集成 — 时序行情写入 + 查询

Phase 3: 事件与归档
  PR-F: kafkax 集成 — 跨域事件发布
  PR-G: ossx 集成 — 历史数据归档

Phase 4: Web API
  PR-H: Gin REST API — market_data 查询接口
  PR-I: 全链路集成测试 + 性能验证
  PR-J: SPEC v2.0.0 更新 + 架构文档同步
```

### 9.3 受影响的文档

| 文档 | 变更类型 | 说明 |
|------|---------|------|
| `module/binance/SPEC.md` | MAJOR 重写 | v1.0.1 → v2.0.0 |
| `module/binance/client/SPEC.md` | MAJOR 简化 | 删除 spool/checkpoint/sender，新增 publisher |
| `module/binance/server/SPEC.md` | MAJOR 扩展 | 新增 storage/cache/api/dispatch 层 |
| `module/binance/IMPLEMENTATION-PLAN.md` | 重写 | 新 PR 序列 |
| `module/binance/RUNTIME-MAPPING.md` | 重写 | 新目录结构 |
| `module/binance/BOUNDARY-GATES.md` | 扩展 | 新增 infra 模块边界门禁 |
| `ARCHITECTURE.md` | 更新 | binance 架构描述变更 |
| `STATUS.md` | 更新 | 版本号 + 进度 |
| `module/README.md` | 更新 | C/S 模块描述模板 |

---

## 10. 风险与缓解

| 风险 | 级别 | 缓解措施 |
|------|:----:|---------|
| natsx JetStream 单点故障 | HIGH | NATS Cluster 部署 (≥3 节点)；JetStream RAFT 复制 |
| redisx idempotency store 数据丢失 | MED | postgresx 持久备份；重启后从 postgresx 重建 |
| taosx 写入吞吐不足 | MED | SchemalessWrite + 批量写入 + 连接池 |
| Client 无本地 spool 导致 JetStream 不可用时丢数据 | HIGH | JetStream 本地持久化 + 发布重试 + 客户端侧内存缓冲 |
| Gin API 被 market_data 高频轮询打爆 | MED | redisx 热缓存 + rate limit + 考虑 WebSocket push 补充 |
| ossx 归档延迟导致数据堆积 | LOW | 异步归档 + 定时批量上传 + 监控积压 |
| 六模块依赖导致启动顺序复杂 | MED | health check 依赖链 + graceful degradation |

---

## 11. 开放问题

| ID | 问题 | 建议 |
|----|------|------|
| OQ-10 | natsx JetStream 需要独立部署还是内嵌？ | 建议独立部署 NATS Server，生产用 Cluster |
| OQ-11 | taosx 超级表 schema 是否为最终版？ | 需要与 market_data 域对齐字段规范 |
| OQ-12 | Gin API 是否需要 WebSocket push 补充轮询？ | v2.1 候选，先 HTTP REST 起步 |
| OQ-13 | market_data 调用 binance API 的认证方式？ | Bearer Token (env: BINANCE_API_TOKEN) |
| OQ-14 | 是否保留 smoke test 同进程模式？ | 保留 cmd/binance-smoke，改为 natsx embedded |
| OQ-15 | 多 client 实例的 natsx subject 路由策略？ | 按 product_line 分区 subject，每个 client 发布自己的 product line |

---

## 附录 A: 与旧架构的对比总结

| 维度 | 旧架构 (v1.0.1) | 新架构 (v2.0.0) |
|------|----------------|-----------------|
| C/S 通信 | gRPC bidi stream | natsx JetStream |
| Client 职责 | 采集 + spool + checkpoint + send | **仅采集 + natsx publish** |
| Server 职责 | validate + idempotency + ACK + dispatch | validate + idempotency + **process + store + cache + API + dispatch + archive** |
| 幂等存储 | in-memory / SQLite | redisx (主) + postgresx (备) |
| 行情存储 | 无 (handoff 给 market_data) | taosx (时序主存储) |
| 元数据存储 | 无 | postgresx |
| 事件发布 | direct dispatch port | kafkax |
| 历史归档 | 无 | ossx |
| Web API | Gin admin only | Gin REST API (面向 market_data) |
| 可观测 | observex (已规划) | observex (全覆盖) |
| 产品线 | 仅 Spot (骨架) | 完整 4 产品线 |

---

## 12. 当前代码实态审计（已迁移）

> [COMPUTED] HIGH：2026-06-21 代码实态审计已迁移到 `docs/migrations/binance-v2-upgrade.md` 作为历史证据索引。
>
> 当前 runtime 状态只能由 fresh `/home/binance` 命令输出证明；不要从本归档节推断 release readiness。

## 附录 B: 完整差距总结表（含代码实态）

| 维度 | 文档 v1.0.1 | 实际代码 | 目标 v2.0.0 |
|------|------------|----------|------------|
| C/S 通信 | gRPC bidi stream (文档) | in-process cs interface (代码) | natsx JetStream (目标) |
| Client 持久化 | SQLite spool (文档) | in-memory Spool struct (代码) | 无 — JetStream 替代 (目标) |
| Client 确认 | ACK-driven checkpoint (文档) | Checkpoint struct (代码) | 无 — JetStream ACK (目标) |
| Server 幂等 | in-memory (骨架说明) | memoryIdempotencyStore (代码) | redisx SetNX + postgresx 备份 (目标) |
| Server dispatch | downstream port (文档) | RecordingSink{} (代码) | kafkax Producer (目标) |
| Server 存储 | 无 (non-goal) | 无 | taosx + postgresx + ossx (目标) |
| Web API | Gin admin only | admin.go (管理端点) | Gin REST /api/v1/* (目标) |
| go.mod gin | 无 | 无 | 需新增 |
| go.mod ossx | 无 | 无 | 需新增 |
| cmd/binance-client | 无 | 无 | 需新增 |
| 产品线 | 仅 Spot | 仅 spot.go | 全 4 条 |
