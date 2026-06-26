> [ARCHIVED 2026-06-22] DEEP-ANALYSIS.md 拆分产物。原 §4-§11 + 附录B：API/数据流/配置/部署/路线图/风险/差距总结。
>
> 活跃版本见 `SPEC.md`（规格）与 `RUNTIME-MAPPING.md`（runtime 映射）。

# 深度架构分析 — 运维与演进篇

> 分析日期：2026-06-21 | 状态：**已归档**

## 4. Gin Web API 设计

```
Base URL: http://{host}:8080/api/v1

Market Data Query:
  GET /market/ticks/:symbol        最新 Tick
  GET /market/ticks/:symbol/range  历史 Tick
  GET /market/bars/:symbol         最新 Bar
  GET /market/bars/:symbol/range   历史 Bar
  GET /market/depth/:symbol        最新深度
  GET /market/depth/:symbol/history 深度历史
  GET /market/trades/:symbol       最新成交

Instrument Query:
  GET /instruments                 全部合约列表
  GET /instruments?product_line=spot 按产品线过滤
  GET /instruments/:symbol         单个合约详情

Health & Admin:
  GET /health /health/readiness
  GET /stats/streams /stats/daily
  POST /admin/catalog/reload
  POST /admin/stream/pause/:line /resume/:line
  GET /admin/config
```

API 响应遵循 `contracts` 标准信封 `{success, data, error, meta}`。

## 5. 完整数据流

Tick 端到端时序：Binance WS(T+0) → client/spot(T+1ms) → parser(T+2ms) → normalize(T+3ms) → mapper(T+4ms) → natsx Publish(T+5ms, ACK) → JetStream(T+6ms) → server/consumer(T+7ms) → validate(T+8ms) → redisx SetNX(T+9ms) → processor enrich(T+10ms) → [并行] taosx WriteBatch(T+11ms) + redisx SET(T+12ms) + kafkax Send(T+13ms) → 存储完成(T+14ms) → market_data HTTP GET(T+15ms) → redisx GET 缓存命中(T+17ms) → 200 OK(T+18ms).

数据持久化矩阵：redisx(热缓存 60s TTL) | postgresx(元数据/审计主存储) | taosx(时序行情主存储) | kafkax(实时事件发布) | ossx(历史归档).

## 6. 目录结构变更

Client 简化：删除 spool/checkpoint/sender；新增 publisher/ (natsx)；connectors/ 合并 4 产品线。
Server 扩展：删除 ingest (gRPC)；新增 consumer/processor/storage/cache/dispatch/api/ 层。

## 7. 配置设计

binance-server.yaml：server(gin :8080)、nats(url/auth/consumer durable)、redis(addr/idempotency_ttl 72h/hot_cache_ttl 60s)、postgres(host/migration)、taos(endpoint/write_batch_size)、kafka(brokers/topic_pattern)、oss(endpoint/bucket/archive policy)、binance(endpoints rest+ws/product_lines)、observex(log_level/metrics_port).

## 8. 部署拓扑

Zone A (采集区): binance-client ×N → NATS Server (Cluster, JetStream).
Zone B (服务区): binance-server ×2+ (HA) → redis/pg/taos/kafka → market_data (HTTP) + 下游消费者 (Kafka).

## 9. SPEC 升级路线图

v1.0.1→v1.1.0: 4产品线+natsx替换gRPC | v1.1.0→v1.2.0: Server存储层 | v1.2.0→v2.0.0: kafkax+ossx+Gin API.
Phase 1(PR-A/B): natsx集成+补齐connector | Phase 2(PR-C/D/E): redisx+postgresx+taosx | Phase 3(PR-F/G): kafkax+ossx | Phase 4(PR-H/I/J): Gin API+集成测试+SPEC v2.0.

## 10. 风险与缓解

| 风险 | 级别 | 缓解 |
|------|:----:|------|
| natsx JetStream 单点故障 | HIGH | NATS Cluster ≥3节点；RAFT复制 |
| redisx idempotency 数据丢失 | MED | postgresx持久备份 |
| taosx 写入吞吐不足 | MED | SchemalessWrite+批量写入+连接池 |
| Client 无 spool → JetStream 不可用时丢数据 | HIGH | JetStream本地持久化+发布重试+内存缓冲 |
| Gin API 高频轮询 | MED | redisx热缓存+rate limit+WebSocket push候选 |
| ossx 归档延迟 | LOW | 异步归档+批量上传+监控积压 |
| 六模块启动顺序 | MED | health check依赖链+graceful degradation |

## 11. 开放问题

OQ-10: NATS独立部署或内嵌？→ 独立部署NATS Server Cluster.
OQ-11: taosx超级表schema最终版？→ 需与market_data域对齐.
OQ-12: Gin API需要WebSocket push？→ v2.1候选.
OQ-13: market_data认证？→ Bearer Token.
OQ-14: 保留smoke test同进程？→ 保留cmd/binance-smoke.
OQ-15: 多client natsx subject路由？→ 按product_line分区.

## 附录 B: 完整差距总结表

| 维度 | 文档 v1.0.1 | 实际代码 | 目标 v2.0.0 |
|------|------------|----------|------------|
| C/S 通信 | gRPC bidi stream | in-process cs interface | natsx JetStream |
| Client 持久化 | SQLite spool | in-memory Spool struct | JetStream替代 |
| Client 确认 | ACK-driven checkpoint | Checkpoint struct | JetStream ACK |
| Server 幂等 | in-memory | memoryIdempotencyStore | redisx SetNX+postgresx备份 |
| Server dispatch | downstream port | RecordingSink{} | kafkax Producer |
| Server 存储 | 无 | 无 | taosx+postgresx+ossx |
| Web API | Gin admin only | admin.go | Gin REST /api/v1/* |
| go.mod gin | 无 | 无 | 需新增 |
| go.mod ossx | 无 | 无 | 需新增 |
| cmd/binance-client | 无 | 无 | 需新增 |
| 产品线 | 仅 Spot | 仅 spot.go | 全 4 条 |
