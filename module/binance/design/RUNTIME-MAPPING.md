# module/binance RUNTIME MAPPING v3.9.0

> 版本：v3.9.0
> Module-Version: v3.9.0
> 更新日期：2026-06-26
> 替代：v1.0.0（gRPC + SQLite spool 架构）
> 参见：`DEEP-ANALYSIS.md`（架构决策全文）

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

### 当前证据口径（2026-06-24）

- [COMPUTED, HIGH] 当前远端 runtime 基线：`ZoneCNH/binance` `origin/main` merge commit `5a57a19aed3be5420135b8e05016da15faf094ed`（runtime PR #11），source commit `7873b795b13fc4b5a0fc4310300b6f196cca7532`。
- [COMPUTED, HIGH] 已归档本地证据：`/home/workspace/binance/release/evidence/binance/20260623/`；本地 evidence commit `71e2a6e8bb5591c43e8a2ebfff8c7645bf030786`（round 2 2026-06-23）。
- [COMPUTED, HIGH] 已证明范围：独立 `cmd/binance-client` 可启动 admin `:8081` self-test，并通过 `contracts` canonical 契约（经 `internal/ingestcodec` boundary）发送 HTTP JSON `/ingest` 到 `cmd/binance-server` handler；C/S 共享契约由 `contracts` canonical 承载（ADR-007）；runtime 不含 `internal/cs`；`scripts/boundary-gates.sh` 15/15 PASS；`go build/test/race/vet`、`golangci-lint` 与本地 smoke self-test PASS。
- [COMPUTED, HIGH] 2026-06-24 gated `natsx` integration 增量：真实本地 NATS JetStream 上已验证 accepted publish 非 duplicate PubAck、重复 publish duplicate PubAck、成功处理 Ack 后不重投、retryable reject immediate Nak 重投至 `MaxDeliver=5` 后停止；验证命令含 100 次重复 gated live-local loop。
- [COMPUTED, HIGH] 2026-06-24 kafkax fanout 本地增量：`internal/server/kafka_dispatch.go` 已构造 topic `binance.{product_line}.{event_type}.v1`、message key=symbol fallback event_id；`cmd/binance-server` 支持 `XGO_BINANCE_DISPATCHER=kafkax` 并启用 strict handoff；`internal/server/ingest.go` 已验证 dispatch 失败返回 retryable `BNC-008` 且不 durable/Ack；`plan006_task_4_7_repeat_checks=100` PASS。
- [COMPUTED, HIGH] 未证明范围：live Binance websocket、独立 client/server 进程端到端、`NakWithDelay(5s)`、dead-letter/parking/DLQ、`redisx/postgresx/taosx/ossx` 持久化、真实 Kafka broker fanout、`/api/v1` market/query API、release tag 与 release evidence。

---

## 2. 目标运行时目录树（非当前完成声明）

本节描述目标运行时形态；当前完成状态以“当前证据口径”与 `TRACEABILITY.md` 状态为准。

```text
github.com/ZoneCNH/binance/
  go.mod         (需升级: gin + ossx 新增; 5 infra 模块 indirect→direct)
  go.sum

  cmd/
    binance-client/          ← 独立采集器进程（v2.0.0 新增）
      main.go
    binance-server/          ← 接入 + 处理 + 存储服务端
      main.go
    binance-smoke/           ← 冒烟测试（目标 natsx embedded；当前证据为本地 self-test）
      main.go

  internal/
    client/                  ← 极简采集端（v2.0.0 大幅简化）
      app/                   ← 应用装配
      config/                ← 配置加载
      catalog/               ← 产品线目录：四条线可独立启停
      parser/                ← Binance 符号解析
      connectors/            ← 四产品线 connector（v2.0.0 整合）
        spot.go              ← 已有（保留）
        um_perp.go           ← 新增
        cm_perp.go           ← 新增
        options.go           ← 新增
        connector.go         ← 接口定义
      normalize/             ← 原生事件 → NormalizedEvent
      mapper/                ← NormalizedEvent → domain_market.MarketFactEnvelope
      # publisher 由 natsx FR-009 IngestPublisher 提供（域适配契约），binance 不自实现 JetStream 发布逻辑
      # 装配点：cmd/binance-client 注入 natsx.IngestPublisher 作为 wire.IngestEndpoint，替换 HTTP sender
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
      # consumer 由 natsx FR-010 IngestConsumer 提供（域适配契约，durable+ManualAck/DLQ/poison message）
      # binance server 不自实现 JetStream 消费逻辑，只声明依赖 natsx.IngestConsumer
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
          admin.go           ← /api/v1/admin/symbols/reload、stream
        middleware/
          auth.go            ← Bearer Token
          ratelimit.go       ← redisx 限流
      admin/                 ← 运维端点 :8082（/healthz /readyz）
      observability/

      # v2.0.0 删除:
      # ingest/  consumer/ 替代
      # ack/     JetStream ManualAck 替代

    cs/                      ← 历史目标/归档说明；当前 runtime PR #11 merge SHA 5a57a19 不含 internal/cs
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

| Command | 角色 | 监听端口 | 关键依赖 | 当前证据口径 |
|---------|------|---------|---------|--------------|
| `cmd/binance-client` | 采集器：连接 Binance WS/REST → 发布 natsx | admin :8081 | natsx, domain_market | Partial：PR #11 已证明独立命令、admin `:8081` self-test、HTTP `/ingest` 发送路径与 boundary gate；2026-06-24 gated JetStream PubAck duplicate 子集通过；尚无独立进程/live Binance 证据 |
| `cmd/binance-server` | 服务端：消费 natsx → 处理存储 → 提供 API | API :8080, admin :8082 | natsx, redisx, postgresx, taosx, kafkax, ossx, gin | Partial：PR #11 已证明 HTTP `/ingest` receiver boundary；2026-06-24 gated ManualAck/MaxDeliver immediate Nak 子集通过；2026-06-24 local kafkax adapter + strict handoff unit subset 通过；尚无独立进程、`NakWithDelay`、dead-letter、存储、真实 Kafka broker fanout、query 证据 |
| `cmd/binance-smoke` | 冒烟测试（目标 natsx embedded） | — | 同 server | PASS：本地 self-test；非分布式 runtime 证据 |

---

## 4. Client 组件映射

| Spec 功能域 | 运行时路径 | v2.0.0 状态 |
|------------|-----------|:-----------:|
| 产品线目录 | `internal/client/catalog/` | 保留 |
| 符号解析器 | `internal/client/parser/` | 保留 |
| Spot connector | `internal/client/connectors/spot.go` | 保留 |
| USDⓈ-M connector | `internal/client/connectors/um_perp.go` | ✨ 新增 |
| COIN-M connector | `internal/client/connectors/cm_perp.go` | ✨ 新增 |
| Options connector | `internal/client/connectors/options.go` | ✨ 新增 |
| 事件规范化 | `internal/client/normalize/` | 保留 |
| 规范映射 | `internal/client/mapper/` | 保留 |
| 幂等键生成 | 移入 `mapper/`（放入 envelope.Header） | 迁移 |
| natsx 发布器 | 由 natsx FR-009 IngestPublisher 提供（域适配契约） | 引用 natsx |
| Gin admin | `internal/client/admin/` | 保留精简 |
| ❌ SQLite spool | `internal/client/spool/` | **删除** |
| ❌ Checkpoint | `internal/client/checkpoint/` | **删除** |
| ❌ gRPC/cs sender | `internal/client/sender/` | **删除** |

---

## 5. Server 组件映射

| Spec 功能域 | 运行时路径 | v2.0.0 状态 |
|------------|-----------|:-----------:|
| natsx 消费入口 | 由 natsx FR-010 IngestConsumer 提供（域适配契约） | 引用 natsx |
| 请求校验 | `internal/server/validation/` | 保留 |
| 幂等（redisx 主） | `internal/server/idempotency/redis_store.go` | ✨ 重写 |
| 幂等日志（postgresx 备） | `internal/server/idempotency/pg_log.go` | ✨ 新增 |
| 处理管线 | `internal/server/processor/` | ✨ 新增 |
| 时序存储（taosx） | `internal/server/storage/taos_writer.go` | ✨ 新增 |
| 合约元数据（postgresx） | `internal/server/storage/pg_catalog.go` | ✨ 新增 |
| 历史归档（ossx） | `internal/server/storage/oss_archiver.go` | ✨ 新增 |
| 热缓存（redisx） | `internal/server/cache/` | ✨ 新增 |
| 跨域发布（kafkax） | `internal/server/kafka_dispatch.go`（目标分层可迁至 `internal/server/dispatch/`） | ✨ 新增（local adapter；真实 broker e2e pending） |
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
  binance.market.spot.tick.v1         binance.market.spot.trade.v1
  binance.market.spot.bar.v1          binance.market.spot.depth.v1
  binance.market.spot.funding_rate.v1 binance.market.spot.mark_price.v1
  binance.market.um_perp.tick.v1      binance.market.um_perp.trade.v1
  binance.market.um_perp.bar.v1       binance.market.um_perp.depth.v1
  binance.market.um_perp.funding_rate.v1  binance.market.um_perp.mark_price.v1
  binance.market.cm_perp.tick.v1      binance.market.cm_perp.trade.v1
  binance.market.cm_perp.bar.v1       binance.market.cm_perp.depth.v1
  binance.market.cm_perp.funding_rate.v1  binance.market.cm_perp.mark_price.v1
  binance.market.options.tick.v1      binance.market.options.trade.v1
  binance.market.options.bar.v1       binance.market.options.depth.v1
  binance.market.options.funding_rate.v1  binance.market.options.mark_price.v1

Server Consumer:
  Durable: binance-server  AckPolicy: explicit  AckWait: 30s  MaxDeliver: 5
```

---

## 8. kafkax Topic 规范

```
Topics:
  binance.spot.tick.v1         现货 tick
  binance.spot.trade.v1        现货逐笔成交
  binance.spot.bar.v1          现货 K 线
  binance.spot.depth.v1        现货深度
  binance.spot.funding_rate.v1 现货资金费率（占位，runtime 不采集）
  binance.spot.mark_price.v1   现货标记价格（占位，runtime 不采集）
  binance.um_perp.tick.v1      U 本位合约 tick
  binance.um_perp.trade.v1     U 本位合约逐笔成交
  binance.um_perp.bar.v1       U 本位合约 K 线
  binance.um_perp.depth.v1     U 本位合约深度
  binance.um_perp.funding_rate.v1  U 本位合约资金费率
  binance.um_perp.mark_price.v1    U 本位合约标记价格
  binance.cm_perp.tick.v1      币本位合约 tick
  binance.cm_perp.trade.v1     币本位合约逐笔成交
  binance.cm_perp.bar.v1       币本位合约 K 线
  binance.cm_perp.depth.v1     币本位合约深度
  binance.cm_perp.funding_rate.v1  币本位合约资金费率
  binance.cm_perp.mark_price.v1    币本位合约标记价格
  binance.options.tick.v1      期权 tick
  binance.options.trade.v1     期权逐笔成交
  binance.options.bar.v1       期权 K 线
  binance.options.depth.v1     期权深度
  binance.options.funding_rate.v1  期权资金费率（占位，runtime 不采集）
  binance.options.mark_price.v1    期权标记价格 / option mark

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
GET  /api/v1/market/funding-rate/:symbol  最新资金费率（redisx 热缓存）
GET  /api/v1/market/mark-price/:symbol    最新标记价格（redisx 热缓存）
GET  /api/v1/instruments                  合约列表（postgresx）
GET  /api/v1/instruments/:symbol          单个合约详情
GET  /api/v1/stats/streams                流统计
GET  /api/v1/stats/daily                  日统计
POST /api/v1/admin/symbols/reload         重载目录并应用 stream diff
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
| publisher tests | 归属 natsx 仓（FR-009 TC-010） | binance 仅装配侧集成测试，JetStream 发布逻辑由 natsx 验证 |
| consumer tests | 归属 natsx 仓（FR-010 TC-015） | binance 仅装配侧集成测试，durable+ManualAck 生命周期由 natsx 验证 |
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
