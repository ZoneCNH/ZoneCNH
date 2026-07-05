# module/binance DESIGN

- Design-ID: DESIGN-binance-v1
- Source-Goal: module/binance/goal/goal.md
- Source-Spec: module/binance/spec/SPEC.md
- Status: Implemented
- Last-Updated: 2026-06-30

## 1. Modules

```text
module/binance
├── client/   ← Binance 交易所侧采集器（独立进程）
└── server/   ← 内网处理 + 存储 + API（独立进程）
```

| Module | Role | Runtime-Repo |
|--------|------|-------------|
| binance-client | 连接 Binance，解析交易所原生数据，映射到 domain_market envelope，通过 natsx JetStream 发布 | /home/workspace/binance/cmd/binance-client/ |
| binance-server | 订阅 natsx JetStream，校验与去重，写入存储，提供 Gin REST API，通过 kafkax 广播 | /home/workspace/binance/cmd/binance-server/ |

## 2. Interfaces

| Interface | Type | Provider | Consumer |
|-----------|------|----------|----------|
| natsx JetStream (BINANCE_MARKET) | Async Pub/Sub | binance-client | binance-server |
| Gin REST :8080 | Sync HTTP | binance-server | market_data / downstream |
| kafkax topics | Async Pub/Sub | binance-server | external consumers |
| redisx SetNX | Sync KV | redisx | binance-server (idempotency) |
| taosx WriteBatch | Sync TSDB | binance-server | taosx |
| postgresx upsert | Sync SQL | binance-server | postgresx |
| clickhousex ETL | Batch OLAP | binance-server | clickhousex |
| ossx PutObject | Sync Object | binance-server | ossx |

## 3. Data Flow

```text
Binance Exchange (WS/REST)
  → binance-client catalog → parser → normalize → mapper
  → natsx.Publish(subject: binance.market.*.*.v1)
  → natsx JetStream
  → binance-server consumer → validation → idempotency (redisx)
  → processor → [taosx | postgresx | redisx cache | kafkax | ossx]
  → Gin REST API → market_data
```

## 4. Dependencies

| Dependency | Direction | Constraint |
|------------|-----------|------------|
| domain_market | client+server → domain_market | Canonical types only; no domain logic in binance |
| natsx | client+server → natsx | JetStream pub/sub; NATS is external service |
| redisx | server → redisx | SetNX idempotency + hot cache |
| postgresx | server → postgresx | Metadata + audit |
| taosx | server → taosx | Time-series storage |
| clickhousex | server → clickhousex | OLAP analytics |
| kafkax | server → kafkax | Downstream broadcast |
| ossx | server → ossx | Cold storage archive |

## 5. ADR

| ADR | Decision | Status |
|-----|----------|--------|
| ADR-001 | 占位声明：早期架构决策已并入 SPEC §1-§6（wire 边界/产品线/catalog 基础模型），编号保留不回溯（见 [ADR-001-placeholder.md](ADR-001-placeholder.md)） | Accepted（占位） |
| ADR-002 | Wire boundary: natsx subject + domain_market envelope JSON; no local proto/gRPC ingest schema | Superseded by ADR-007 |
| ADR-003 | Order book rebuild exclusion | Accepted |
| ADR-004 | FR-024 vs FR-036 architecture decision | Accepted |
| ADR-005 | Symbol 采集分级体系：CatalogEntry 加 Tier/SymbolPriority/Collection/QuoteVolumeUSD 字段 + classifyTier 三层降级 + 白名单 MVP（见 [ADR-005](ADR-005-symbol-tier-classification.md)、[TIER-DESIGN-DETAILS](TIER-DESIGN-DETAILS.md)） | Proposed |
| ADR-007 | internal/wire 迁移到 contracts canonical（方案 C：canonical 富化 + boundary codec），删除 internal/wire，新增 internal/ingestcodec（见 [ADR-007](ADR-007-wire-to-contracts-migration.md)） | Accepted |

## 6. Risks

| Risk | Level | Mitigation |
|------|-------|------------|
| client/server 耦合回流 | Medium | boundary-gates.sh CI 检查 |
| 跨产品线身份碰撞 | High | product_line prefix in instrument identity |
| JetStream 消息丢失 | High | durable consumer + ManualAck + NakWithDelay |
| 存储装配断层 | Medium | main.go production readiness gates (PRG-001~007) |
