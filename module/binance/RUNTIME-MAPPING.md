# module/binance RUNTIME MAPPING v2.2.3

> 版本：v2.2.3
> 更新日期：2026-06-23
> 替代：v1.0.0（gRPC + SQLite spool 架构）
> 参见：`SPEC.md` §4.1、`NAMING.md`、`DEEP-ANALYSIS.md`（架构决策全文）

---

## 1. 目的

本文件将 `module/binance` 规格映射到 `github.com/ZoneCNH/binance` 运行时仓库的目录结构。

### 架构版本对比

| 维度 | v1.0.0 | v2.0.0 |
|------|--------|--------|
| C/S 通信 | in-process cs interface | **natsx JetStream** |
| Client 职责 | 采集 + spool + checkpoint + send | **仅采集 + natsx publish** |
| Server 职责 | validate + idempotency + ACK + dispatch | **validate + process + store + cache + API + dispatch + archive** |
| 存储 | 无 | **taosx + postgresx + redisx + ossx** |
| Web API | Gin admin only | **Gin REST /api/v1/** |

---

## 2. 目标运行时目录树

```text
github.com/ZoneCNH/binance/
  go.mod         (需升级: gin + ossx 新增; 5 infra 模块 indirect→direct)
  go.sum

  cmd/
    binance-client/          ← 独立采集器进程（v2.0.0 新增）
      main.go
    binance-server/          ← 接入 + 处理 + 存储服务端
      main.go
    binance-smoke/           ← 冒烟测试（改为 natsx embedded）
      main.go

  internal/
    client/                  ← 极简采集端（v2.0.0 大幅简化）
      app/                   ← 应用装配
      config/                ← 配置加载
      catalog/               ← 产品线目录：四条线可独立启停
      parser/                ← Binance 符号解析
      connectors/            ← 四产品线 connector（v2.0.0 整合）
        spot.go              ← 已有（保留）
        usdm.go              ← 新增
        coinm.go             ← 新增
        options.go           ← 新增
        connector.go         ← 接口定义
      normalize/             ← 原生事件 → NormalizedEvent
      mapper/                ← NormalizedEvent → domain_market.MarketFactEnvelope
      publisher/             ← natsx JetStream 发布器（新增，替换 sender）
        publisher.go
        publisher_test.go
      admin/                 ← Gin admin :8081（/healthz /readyz）
      observability/

      # v2.0.0 删除:
      # spool/        JetStream 持久化替代
      # checkpoint/   JetStream ACK 替代
      # sender/       publisher/ 替代
      # idempotency/  key 生成移入 mapper

    server/                  ← 富服务端：处理 + 存储 + 缓存 + API + 归档
      app/                   ← 应用装配（大幅扩展）
      config/                ← 配置（nats/redis/pg/taos/kafka/oss/gin）
      consumer/              ← natsx JetStream 消费（新增，替换 ingest）
        consumer.go          ← durable consumer + ManualAck
        consumer_test.go
      validation/            ← 请求校验（保留）
      idempotency/           ← 幂等处理（重写: redisx 主 + postgresx 备）
        redis_store.go       ← SetNX + 72h TTL
        pg_log.go            ← 持久备份
        idempotency_test.go
      processor/             ← 处理管线（新增）
        processor.go         ← validate→idempotency→enrich→store+cache+dispatch
        enricher.go
      storage/               ← 存储层（新增）
        taos_writer.go       ← 时序行情写入（tick/bar/depth）
        pg_catalog.go        ← 合约元数据 CRUD
        oss_archiver.go      ← 定时归档 taosx→ossx
        storage_test.go
      cache/                 ← redisx 缓存层（新增）
        hot_cache.go         ← tick/bar 热缓存 60s TTL
        rate_limiter.go      ← 100 req/s per endpoint
        dist_lock.go         ← coordinator 分布式锁 30s lease
        cache_test.go
      dispatch/              ← kafkax 事件发布（重写）
        kafka_dispatcher.go
        dispatcher_test.go
      api/                   ← Gin REST API（新增，面向 market_data）
        router.go
        handler/
          market.go          ← /api/v1/market/ticks、bars、depth、trades
          instrument.go      ← /api/v1/instruments
          stats.go           ← /api/v1/stats/streams、daily
          admin.go           ← /api/v1/admin/catalog、stream
        middleware/
          auth.go            ← Bearer Token
          ratelimit.go       ← redisx 限流
      admin/                 ← 运维端点 :8082（/healthz /readyz）
      observability/

      # v2.0.0 删除:
      # ingest/  consumer/ 替代
      # ack/     JetStream ManualAck 替代

    cs/                      ← ⚠️ 归档（首版骨架，不再是运行时通信契约）
      types.go
      doc.go

  pkg/
    config/
    observability/
    version/

  test/
    contract/                ← natsx wire format 契约测试
    integration/             ← 全链路：client→natsx→server→taosx
    fixtures/

  migrations/                ← PostgreSQL 迁移脚本（新增）
    001_init_catalog.sql
    002_init_idempotency_log.sql
    003_init_audit.sql
    004_init_stream_sessions.sql

  configs/
    binance-client.yaml.example
    binance-server.yaml.example
```

---

## 3. Command 映射

| Command | 角色 | 监听端口 | 关键依赖 |
|---------|------|---------|---------|
| `cmd/binance-client` | 采集器：连接 Binance WS/REST → 发布 natsx | admin :8081 | natsx, domain_market |
| `cmd/binance-server` | 服务端：消费 natsx → 处理存储 → 提供 API | API :8080, admin :8082 | natsx, redisx, postgresx, taosx, kafkax, ossx, gin |
| `cmd/binance-smoke` | 冒烟测试（natsx embedded） | — | 同 server |

---

## 4. Client 组件映射

| Spec 功能域 | 运行时路径 | v2.0.0 状态 |
|------------|-----------|:-----------:|
| 产品线目录 | `internal/client/catalog/` | 保留 |
| 符号解析器 | `internal/client/parser/` | 保留 |
| Spot connector | `internal/client/connectors/spot.go` | 保留 |
| USDⓈ-M connector | `internal/client/connectors/usdm.go` | ✨ 新增 |
| COIN-M connector | `internal/client/connectors/coinm.go` | ✨ 新增 |
| Options connector | `internal/client/connectors/options.go` | ✨ 新增 |
| 事件规范化 | `internal/client/normalize/` | 保留 |
| 规范映射 | `internal/client/mapper/` | 保留 |
| 幂等键生成 | 移入 `mapper/`（放入 envelope.Header） | 迁移 |
| natsx 发布器 | `internal/client/publisher/` | ✨ 新增 |
| Gin admin | `internal/client/admin/` | 保留精简 |
| ❌ SQLite spool | `internal/client/spool/` | **删除** |
| ❌ Checkpoint | `internal/client/checkpoint/` | **删除** |
| ❌ gRPC/cs sender | `internal/client/sender/` | **删除** |

---

## 5. Server 组件映射

| Spec 功能域 | 运行时路径 | v2.0.0 状态 |
|------------|-----------|:-----------:|
| natsx 消费入口 | `internal/server/consumer/` | ✨ 新增 |
| 请求校验 | `internal/server/validation/` | 保留 |
| 幂等（redisx 主） | `internal/server/idempotency/redis_store.go` | ✨ 重写 |
| 幂等日志（postgresx 备） | `internal/server/idempotency/pg_log.go` | ✨ 新增 |
| 处理管线 | `internal/server/processor/` | ✨ 新增 |
| 时序存储（taosx） | `internal/server/storage/taos_writer.go` | ✨ 新增 |
| 合约元数据（postgresx） | `internal/server/storage/pg_catalog.go` | ✨ 新增 |
| 历史归档（ossx） | `internal/server/storage/oss_archiver.go` | ✨ 新增 |
| 热缓存（redisx） | `internal/server/cache/` | ✨ 新增 |
| 跨域发布（kafkax） | `internal/server/dispatch/` | ✨ 重写 |
| Gin REST API | `internal/server/api/` | ✨ 新增 |
| Gin admin | `internal/server/admin/` | 保留精简 |
| ❌ gRPC ingest | `internal/server/ingest/` | **删除** |
| ❌ gRPC ACK | `internal/server/ack/` | **删除** |

---

## 6. 七模块依赖声明

| 模块 | 使用方 | 用途 | go.mod 变更 |
|------|--------|------|:-----------:|
| `natsx` | client + server | C/S 通信总线 JetStream | indirect → **direct** |
| `redisx` | server | 幂等 + 热缓存 + 锁 + 限流 | indirect → **direct** |
| `postgresx` | server | 元数据 + 幂等日志 + 审计 | indirect → **direct** |
| `taosx` | server | 时序行情存储 | indirect → **direct** |
| `clickhousex` | server | OLAP 分析查询（跨符号聚合、多维分析、因子回看） | **缺失 → 新增** |
| `kafkax` | server | 跨域事件发布 | indirect → **direct** |
| `ossx` | server | 历史数据归档 | **缺失 → 新增** |
| `gin-gonic/gin` | server | REST API | **缺失 → 新增** |

---

## 7. natsx Subject 规范

```
Stream: BINANCE_MARKET
Retention: 7d  Storage: file  Replicas: 1 (生产升 3)

Subjects:
  binance.market.spot.tick         binance.market.spot.kline
  binance.market.spot.depth        binance.market.spot.trade
  binance.market.um_perp.tick      binance.market.um_perp.kline
  binance.market.um_perp.depth     binance.market.um_perp.trade
  binance.market.cm_perp.tick      binance.market.cm_perp.kline
  binance.market.cm_perp.depth     binance.market.cm_perp.trade
  binance.market.options.tick      binance.market.options.kline
  binance.market.options.depth     binance.market.options.trade

Server Consumer:
  Durable: binance-server  AckPolicy: explicit  AckWait: 30s  MaxDeliver: 5
```

---

## 8. kafkax Topic 规范

```
Topic format:
  binance.{product_line}.{event_type}.v1

Topics:
  binance.spot.tick.v1       binance.spot.kline.v1
  binance.spot.depth.v1      binance.spot.trade.v1
  binance.um_perp.tick.v1    binance.um_perp.kline.v1
  binance.um_perp.depth.v1   binance.um_perp.trade.v1
  binance.cm_perp.tick.v1    binance.cm_perp.kline.v1
  binance.cm_perp.depth.v1   binance.cm_perp.trade.v1
  binance.options.tick.v1    binance.options.kline.v1
  binance.options.depth.v1   binance.options.trade.v1

Consumer Groups:
  signal_engine  risk_engine  backtestx  market_regime
```

---

## 9. Gin REST API 端点（面向 market_data）

```
Base: http://{server}:8080

GET  /health                              健康（无 auth）
GET  /health/readiness                    就绪（无 auth）
GET  /api/v1/market/ticks/:symbol         最新 Tick（redisx 热缓存）
GET  /api/v1/market/ticks/:symbol/range   历史 Tick（taosx 查询）
GET  /api/v1/market/bars/:symbol          最新 Bar
GET  /api/v1/market/bars/:symbol/range    历史 Bar（taosx）
GET  /api/v1/market/depth/:symbol         最新深度（redisx 5s TTL）
GET  /api/v1/market/trades/:symbol        最新成交
GET  /api/v1/instruments                  合约列表（postgresx）
GET  /api/v1/instruments/:symbol          单个合约详情
GET  /api/v1/stats/streams                流统计
GET  /api/v1/stats/daily                  日统计
POST /api/v1/admin/catalog/reload         重载目录
POST /api/v1/admin/stream/pause/:line     暂停产品线
POST /api/v1/admin/stream/resume/:line    恢复产品线
GET  /api/v1/admin/config                 查看配置
```

---

## 10. 禁止导入规则

```
Client 禁止:  server/*, redisx, postgresx, taosx, kafkax, ossx, gin（存储/API 属于 server）
Server 禁止:  client/*
双端禁止:     binance-market, storage (owned), strategy (owned)
```

---

## 11. 测试映射

| 测试类型 | 路径 | 目的 |
|---------|------|------|
| connector tests | `internal/client/connectors/*_test.go` | Binance 原生输入 |
| publisher tests | `internal/client/publisher/publisher_test.go` | natsx 发布（mock JS） |
| consumer tests | `internal/server/consumer/consumer_test.go` | natsx 消费生命周期 |
| idempotency tests | `internal/server/idempotency/*_test.go` | redisx 幂等语义 |
| storage tests | `internal/server/storage/*_test.go` | taos/pg/oss 写入 |
| api tests | `internal/server/api/*_test.go` | Gin 路由 + handler |
| contract tests | `test/contract/` | natsx wire format |
| integration tests | `test/integration/` | client→natsx→server→taosx |

---

## 12. 运行时验收标准

- `binance-client` 独立启动，无 server 内部依赖
- `binance-server` 独立启动，无 client 内部依赖
- client 发布 natsx → server 消费 → taosx 写入 → redisx 缓存 → kafkax 发布
- redisx `idem:{key}` SET NX 确保重复消息仅处理一次
- `GET /api/v1/market/ticks/BTCUSDT` 返回 redisx 缓存数据（< 5ms）
- market_data HTTP 客户端可通过 `/api/v1/instruments` 发现全部合约
- go.mod 无 infra 模块 `// indirect` 污染
- 边界门禁脚本 CI 通过（无跨边界导入）
