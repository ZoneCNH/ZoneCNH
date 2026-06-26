> [ARCHIVED 2026-06-22] 本文档是 DEEP-ANALYSIS.md 的拆分产物。原 §3：六模块集成详案（natsx / redisx / postgresx / taosx / kafkax / ossx），保留作历史参考。
>
> 活跃版本见 `module/binance/SPEC.md` 与 `module/binance/RUNTIME-MAPPING.md`。

# module/binance 深度架构分析 — 集成篇

> 分析日期：2026-06-21
> 状态：**已归档** — 六模块集成详案（natsx / redisx / postgresx / taosx / kafkax / ossx）

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
│    binance.spot.tick.v1       (现货逐笔)       │
│    binance.spot.bar.v1        (现货K线)        │
│    binance.spot.depth.v1      (现货深度)       │
│    binance.um_perp.trade.v1   (U本位成交)      │
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
    topic := fmt.Sprintf("binance.%s.%s.v1", event.ProductLine, event.EventType)
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
