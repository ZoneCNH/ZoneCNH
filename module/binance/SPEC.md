# module/binance SPEC

## 1. Metadata

- Status: Approved
- Spec-Version: v3.1.0
- Last-Updated: 2026-06-22
- Owner: ZoneCNH
- Layer: 数据域 · 行情
- Version: v0.1.0
- Repository: [github.com/ZoneCNH/binance](https://github.com/ZoneCNH/binance)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md), `module/domain_market`, `module/natsx`, `module/redisx`, `module/taosx`, `module/kafkax`, `module/ossx`, `module/postgresx`, `module/clickhousex`

> 子模块规格：`module/binance/client/SPEC.md`、`module/binance/server/SPEC.md`

---

## 2. Summary

`module/binance` 是 Binance 专属 Market Data **分布式** C/S Module，定义 Binance 行情数据从交易所采集到 ZoneCNH 内部存储与对外服务的完整边界。

**核心架构约束：client 和 server 是独立进程，分开部署，通过 natsx JetStream 网络通信，禁止同进程调用。**

```text
[采集区 / 交易所侧]
  Binance Exchange (WS/REST)
    ↓
  binance-client          ← 交易所侧采集器（独立进程）
    ↓ natsx.Publish()     ← 网络消息发布，subject: binance.market.*
  ──────────── NATS JetStream (TCP 网络) ────────────
    ↓ natsx.Subscribe()   ← 网络消息消费
[服务区 / 内网]
  binance-server          ← 处理 + 存储 + API（独立进程）
    ├── redisx            ← 幂等 + 热缓存
    ├── postgresx         ← 元数据 + 审计
    ├── taosx             ← 时序行情存储
    ├── clickhousex       ← OLAP 分析查询
    ├── kafkax            ← 跨域事件发布
    ├── ossx              ← 历史归档
    └── Gin :8080         ← REST API 供 market_data 调用
        ↓ HTTP
  market_data             ← 交易所中立的后续管线
```

`binance-client` 和 `binance-server` 可部署在不同机器/容器/可用区，通过 NATS Server 集群传递消息。`binance-market` 已移除。NATS JetStream 是独立部署的平台/基础设施服务，不由 `binance-client` 或 `binance-server` 内嵌启动；两个进程只通过配置连接地址使用它。

---

## 3. Problem

Binance 行情集成面临以下问题：

1. **旧 SDK 模型职责不清**：`binance` SDK 和 `binance-market` Provider 并存，采集、转换、持久化边界模糊。
2. **同进程耦合**：当前 `internal/cs` 包将 client 和 server 绑定在同一进程（Go interface 直调），无法独立部署，无网络容错。
3. **身份碰撞风险**：Spot `BTCUSDT`、USDⓈ-M `BTCUSDT`、COIN-M `BTCUSD` 和 Options 合约无 product_line 区分。
4. **可靠性无保障**：at-least-once delivery + 幂等接受的端到端语义未定义，进程重启或故障时数据丢失或重复。
5. **无存储能力**：server 端无法独立存储行情数据，必须依赖外部 market_data 模块。
6. **无对外 API**：market_data 无法主动查询 Binance 行情，缺少服务化接口。

---

## 4. Goals

- **分布式 C/S 架构**：client 和 server 为独立进程，可独立部署在不同机器/容器，通过 natsx JetStream 网络通信
- 支持 Binance 四产品线：Spot、USDⓈ-M Futures、COIN-M Futures、Options
- **natsx JetStream** 作为 client→server 唯一通信通道，保证 at-least-once delivery + 持久化
- 明确 NATS JetStream 部署边界：基础设施独立部署，client/server 仅配置连接地址
- server 侧完整存储：taosx（时序）+ postgresx（元数据）+ redisx（缓存）+ clickhousex（OLAP 分析）+ ossx（归档）
- server 侧 **kafkax** 跨域事件发布，解耦下游消费者
- server 侧 **Gin REST API** 供 market_data 主动查询
- 定义 canonical instrument identity，覆盖四产品线碰撞场景
- 定义 enforceable boundary gates：禁止跨进程代码导入，CI 拦截
- 移除 `binance-market` + `internal/cs` 同进程桥接包

---

## 5. Non-goals

`module/binance` 明确不做以下事情：

| 不做 | 原因 |
|------|------|
| 定义 canonical domain model（ProductLine/InstrumentKey 等） | 由 `module/domain_market` 拥有 |
| 实现 strategy API / trading decision | 属于分析域和决策域 |
| 实现 order execution | 属于执行域 |
| 兼容旧 `binance-market` Provider | 已移除 |
| 作为跨 CEX 通用 ingestion server | 本模块仅处理 Binance |
| 同进程运行 client + server | **违反分布式约束（见 §0）** |
| 保留 `internal/cs` 同进程桥接包为运行时依赖 | **必须删除** |

---

## 6. Consumers

| 消费者 | 使用方式 | 通信协议 |
|--------|----------|---------|
| `module/market_data` | HTTP `GET /api/v1/market/*` 主动拉取，或 kafkax topic 消费 | HTTP REST / Kafka |
| 下游分析域（signal/risk/backtest） | kafkax consumer group 消费 `binance.{product_line}.{event_type}.v1` topic | Kafka |
| `module/binance/server` | natsx subscribe `binance.market.>` 消费 client 发布的事件 | NATS JetStream |
| Operator / SRE | client :8081 / server :8082 Gin admin 端点 | HTTP |
| CI Pipeline | BOUNDARY-GATES.md gate 脚本执行边界检查 | — |

---

## 7. Functional Requirements

### FR-001: Product-Line Support

**功能描述**：模块必须支持 Binance 四种产品线的行情数据采集。

**WHEN** 配置启用 Spot 产品线
**THEN** client 可通过 Spot connector 采集 Binance spot market data

**WHEN** 配置启用 USDⓈ-M 产品线
**THEN** client 可通过 USDⓈ-M connector 采集 USDT/USDC 保证金合约行情

**WHEN** 配置启用 COIN-M 产品线
**THEN** client 可通过 COIN-M connector 采集币本位合约行情

**WHEN** 配置启用 Options 产品线
**THEN** client 可通过 Options connector 采集期权行情

### FR-002: Instrument Identity

**功能描述**：模块生成的 canonical instrument identity 必须在四条产品线间不发生碰撞。

**WHEN** parser 解析 Spot `BTCUSDT` 和 USDⓈ-M `BTCUSDT`
**THEN** 两者产生不同的 `InstrumentKey`（通过 `product_line` 维度区分）

**WHEN** parser 解析 COIN-M `BTCUSD`
**THEN** identity 包含 settlement_asset 维度

**WHEN** parser 解析 Options 合约
**THEN** identity 包含 expiry、strike、option_type 三个维度

### FR-003: natsx Communication

**功能描述**：client 和 server 通过 natsx JetStream **网络**通信，禁止共享进程或内存，可在不同机器独立部署。

**WHEN** client 有 canonical event 待发送
**THEN** 调用 `js.Publish("binance.market.{product_line}.{event_type}", jsonPayload)` 并等待 JetStream PubAck

**WHEN** 部署 `binance-client` / `binance-server`
**THEN** 二者 SHALL 仅配置外部 NATS JetStream 连接地址，不负责启动、打包或内嵌 NATS Server

**WHEN** JetStream PubAck 返回成功
**THEN** 消息已持久化到 NATS Stream（`BINANCE_MARKET`，Retention=7d），client 可继续下一条

**WHEN** JetStream 不可达或超时
**THEN** `Publish` 返回 error，调用方指数退避重试；不丢弃消息

**WHEN** server natsx consumer 收到消息（durable=`binance-server`）
**THEN** 反序列化 `MarketFactEnvelope`，进入 validation → idempotency → storage pipeline

### FR-004: At-Least-Once Delivery

**功能描述**：通过 JetStream durable consumer + ManualAck 保证 at-least-once 交付。无需本地 spool 或 checkpoint。

**WHEN** server 处理消息成功（redisx + taosx + postgresx + kafkax handoff 全完成）
**THEN** 调用 `msg.Ack()`，consumer 推进消费位点

**WHEN** server 处理消息失败（任一写入报错）
**THEN** 调用 `msg.NakWithDelay(5s)`，JetStream 重投；达到 MaxDeliver(5) 后进入死信

**WHEN** server 进程重启
**THEN** durable consumer 从上次 Ack 位置自动恢复，无需外部 checkpoint 管理

### FR-005: Idempotent Acceptance

**功能描述**：server 每个 idempotency key 最多完成一次 storage acceptance 与 `kafkax` fanout handoff。

**WHEN** server 收到新 idempotency key 的有效 event
**THEN** 接受、durable 记录并进入 storage/fanout pipeline；仅在 storage + `kafkax` handoff 成功后 ACK

**WHEN** server 收到已 accepted 的 idempotency key
**THEN** 返回 idempotent ACK，不再次写入 storage 或 fanout

**WHEN** server 收到已 accepted 的 idempotency key 但 payload 冲突
**THEN** 返回 terminal_conflict reject

### FR-006: Full-Stack Storage

**功能描述**：server 持有 Binance-specific persistence，通过 Foundation adapter 写入四个存储层。每个存储层独立失败不影响其他层。

#### FR-006a: taosx Time-Series Storage

**WHEN** event 通过 validation 与 idempotency
**THEN** 调用 `taosx.WriteBatch(ctx, points)` 写入 tick/bar/depth 数据到对应超级表子表
**AND** 写入使用 product_line + symbol 作为子表名，自动建表

**WHEN** taosx WriteBatch 失败
**THEN** 返回 error；不调用 `msg.Ack()`；调用 `msg.NakWithDelay(5s)` 并告警

**WHEN** 查询历史 tick/bar
**THEN** 通过 `taosx.Query(ctx, sql)` 按 symbol + time range 查询，返回 `Rows` 迭代器

#### FR-006b: postgresx Metadata Storage

**WHEN** 收到新 instrument symbol
**THEN** 调用 `postgresx.Exec(ctx, upsertSQL)` 幂等写入 `binance_instruments` 表（ON CONFLICT DO UPDATE）

**WHEN** postgresx 不可达
**THEN** 返回 error；不 Ack；重试（指数退避）

#### FR-006c: redisx Hot Cache

**WHEN** event 写入 taosx 成功
**THEN** 调用 `redisx.SET(ctx, "tick:{product_line}:{symbol}", json, 60s)` 更新最新行情热缓存
**AND** 调用 `redisx.SET(ctx, "depth:{product_line}:{symbol}", json, 5s)` 更新深度快照缓存

**WHEN** redisx 缓存写入失败
**THEN** 记录 warn 日志；继续后续管线（缓存失败不阻塞存储——降级到 taosx 直查）

#### FR-006d: ossx Archival

**WHEN** archiver 扫描到超过 retention cutoff 的数据
**THEN** 按 `binance/{product_line}/{symbol}/{YYYY}/{MM}/{DD}/{event_type}.parquet` 写入 `ossx`

**WHEN** `ossx` ETag 校验通过
**THEN** 删除对应 `taosx` 热数据分片

**WHEN** `ossx` 写入或校验失败
**THEN** 保留 `taosx` 热数据并告警；不得删除源数据

### FR-007: Gin Market API

**功能描述**：server 暴露 Gin REST market API，供 `market_data` 主动拉取 Binance-specific facts。实时查询走 redisx 热缓存，历史查询走 taosx 时序存储，分析查询走 clickhousex。

**WHEN** 请求 `GET /api/v1/market/ticks/:symbol`
**THEN** 优先从 `redisx` 热缓存返回（<5ms）；cache miss 回退 `taosx` 查询

**WHEN** 请求 `GET /api/v1/market/ticks/:symbol/range`
**THEN** 从 `taosx` 查询 tick time range，支持 symbol、product_line、start/end time、limit 过滤

**WHEN** 请求 `GET /api/v1/market/bars/:symbol`
**THEN** 优先从 `redisx` 热缓存返回最新 bar；cache miss 回退 `taosx`

**WHEN** 请求 `GET /api/v1/market/bars/:symbol/range`
**THEN** 从 `taosx` 查询 bar time range

**WHEN** 请求 `GET /api/v1/market/depth/:symbol`
**THEN** 从 `redisx` 最新快照返回（5s TTL）；cache miss 回退 `taosx`

**WHEN** 请求 `GET /api/v1/market/trades/:symbol`
**THEN** 从 `taosx` 查询最近的 trade 记录

**WHEN** 请求 `GET /api/v1/instruments`
**THEN** 从 `postgresx` 查询合约目录，支持 product_line + status 过滤

**WHEN** 请求 `GET /api/v1/instruments/:symbol`
**THEN** 从 `postgresx` 查询单个合约详情

**WHEN** API key 无效或请求超限
**THEN** 返回 401 或 429，不访问下游 storage

**WHEN** 请求 `GET /api/v1/stats/streams`
**THEN** 返回各产品线 stream 状态（connected / disconnected / lag）

**WHEN** 请求 `GET /api/v1/stats/daily`
**THEN** 返回当日采集统计（tick 数、bar 数、去重率、错误率）

#### FR-007a: clickhousex Analytics API

**WHEN** 请求 `GET /api/v1/analytics/vwap`
**THEN** 从 `clickhousex` 查询跨符号 VWAP 排名（参数：product_line, window=1h/4h/24h, top_n）

**WHEN** 请求 `GET /api/v1/analytics/top-movers`
**THEN** 从 `clickhousex` 查询涨幅/跌幅 top N（参数：product_line, metric=price_change_pct, window=5m/1h/24h, top_n）

**WHEN** 请求 `GET /api/v1/analytics/correlation`
**THEN** 从 `clickhousex` 查询两个 symbol 的 Pearson 相关系数（参数：symbol_a, symbol_b, product_line, window=1h/4h/24h）

**WHEN** 请求 `GET /api/v1/analytics/volume-profile`
**THEN** 从 `clickhousex` 查询某 symbol 在时间窗口内的成交量分布

### FR-008: kafkax Downstream Broadcast

**功能描述**：server 在 storage 成功后通过 `kafkax` 将 accepted facts 广播给下游消费者。

**WHEN** storage writes 全部成功且 `msg.Ack()` 尚未调用
**THEN** 调用 `kafkax.Send(topic="binance.{product_line}.{event_type}.v1", key=symbol, payload=MarketFactEnvelope)`

**WHEN** `kafkax` handoff 成功
**THEN** 调用 `msg.Ack()`

**WHEN** `kafkax` 不可达或 handoff 失败
**THEN** 返回 error，调用 `msg.NakWithDelay(...)` 或进入 dead-letter/告警路径；handoff 完成前不得 Ack

### FR-009: Boundary Enforcement

**功能描述**：模块边界通过 CI gate 强制执行。

**WHEN** client 代码尝试 import server internal 包
**THEN** CI boundary gate 失败

**WHEN** 任何代码 reintroduce `binance-market` 引用
**THEN** CI no-legacy gate 失败

**WHEN** 模块内声明存储/query/strategy 所有权
**THEN** CI ownership gate 失败

**WHEN** 模块内定义本地 proto、gRPC ingest service 或独立 wire schema
**THEN** CI wire contract externality gate 失败

### FR-010: clickhousex OLAP Storage

**功能描述**：server 将 taosx 热数据通过定时 ETL 聚合写入 clickhousex，为 analytics API 和下游分析模块提供 OLAP 查询能力。clickhousex 与 taosx 互补——taosx 负责高频时序写入，clickhousex 负责跨符号聚合、多维分析、因子回看。

**WHEN** ETL scheduler 触发（默认每 5 分钟）
**THEN** 从 `taosx` 查询最近 5 分钟的 tick/bar 数据
**AND** 预计算 1m OHLCV、5m VWAP、15m 统计聚合
**AND** 调用 `clickhousex.InsertBatch(ctx, table, cols, rows)` 批量写入

**WHEN** clickhousex InsertBatch 失败
**THEN** 记录 error 日志并告警；跳过本批次（ETL 失败不阻塞 taosx 热路径）；下个 ETL 周期自动重试

**WHEN** 查询 `GET /api/v1/analytics/*`
**THEN** 调用 `clickhousex.Query(ctx, sql, args...)` 执行 OLAP 查询，返回聚合结果

**WHEN** clickhousex 不可达
**THEN** analytics API 返回 503 + 错误信息 "analytics temporarily unavailable"；实时 API（ticks/bars/depth）不受影响

**WHEN** `market_binance` 业务库不存在
**THEN** 启动时通过 `clickhousex.Exec(ctx, ddl)` 自动建库建表

### FR-011: Distributed Coordinator Lock

**功能描述**：server 多实例 HA 部署时，通过 redisx 分布式锁确保 coordinator 任务（ETL 调度、归档调度）同一时刻只有一个实例执行。

**WHEN** server 实例启动且需要竞选 coordinator
**THEN** 调用 `redisx.SetNX(ctx, "lock:binance:coordinator", instanceID, 30s)` 尝试获取锁

**WHEN** 获取锁成功
**THEN** 启动 ETL scheduler + 归档 scheduler；每 10s 续期 lease（`redisx.Expire`）

**WHEN** 获取锁失败
**THEN** 进入 standby 模式；每 5s 轮询重试；当持锁实例释放或过期时自动接管

**WHEN** 持锁实例 lease 续期失败（redisx 不可达）
**THEN** 立即停止 ETL + 归档任务；重新进入竞选状态

**WHEN** 持锁实例正常关闭
**THEN** 调用 `redisx.Del(ctx, "lock:binance:coordinator")` 主动释放锁

---

### FR → AC 映射索引

> 本表显式锚定 SPEC.md 内的 FR 与 `TRACEABILITY.md §5 AC 注册表` 的映射，消除"SPEC 内 grep AC- 为 0"的单点漂移风险。AC 详细描述见 `TRACEABILITY.md §5`，TC 覆盖见 `TRACEABILITY.md §4`。

| FR | AC 范围 | 主 TC | 验证机制 |
|---|---|---|---|
| FR-001 Product-Line Support | AC-001 ~ AC-003 | TC-001 | 集成（Binance testnet 四产品线） |
| FR-002 Instrument Identity | AC-004 ~ AC-006 | TC-002, TC-003 | 单元（product_line identity 跨产品线不碰撞） |
| FR-003 natsx Communication | AC-007 ~ AC-010 | TC-004, TC-005 | 集成 + CI gate（独立进程接收 + 跨界检查） |
| FR-004 At-Least-Once Delivery | AC-011 ~ AC-013 | TC-006 | 集成（JetStream ManualAck：成功→Ack，失败→NakWithDelay） |
| FR-005 Idempotent Acceptance | AC-014 ~ AC-016 | TC-007, TC-008 | 单元（SetNX 首次→新消息；重复→跳过） |
| FR-006a taosx Time-Series | AC-017 ~ AC-018 | TC-009, TC-011 | 单元 + 集成（WriteBatch + QueryRange） |
| FR-006b postgresx Metadata | AC-019 ~ AC-020 | TC-010 | 单元（UpsertSymbol 幂等 ON CONFLICT） |
| FR-006c redisx Hot Cache | AC-036 ~ AC-037 | TC-023 | 单元（SET TTL + PUT 失败降级） |
| FR-006d ossx Archival | AC-026 ~ AC-028 | TC-016, TC-017 | 单元（ETag 校验后删 + 路径格式） |
| FR-007 Gin Market API | AC-021 ~ AC-025 | TC-012 ~ TC-015 | httptest（redisx hit + taosx fallback + 401 + 429） |
| FR-007a clickhousex Analytics | AC-038 ~ AC-040 | TC-024 | httptest（vwap + top-movers + correlation） |
| FR-008 kafkax Broadcast | AC-029 ~ AC-031 | TC-018, TC-019 | 单元（topic + partition key + 不可达不 Ack） |
| FR-009 Boundary Enforcement | AC-032 ~ AC-035 | TC-020 ~ TC-022 | CI gate（cs 包 / no-legacy / go.mod 合规） |
| FR-010 clickhousex OLAP | AC-041 ~ AC-044 | TC-025, TC-026 | 集成（ETL: taosx → clickhousex + 503 降级） |
| FR-011 Distributed Lock | AC-045 ~ AC-047 | TC-027, TC-028 | 单元（SetNX 锁 + lease 续期失败停止 + Del 释放） |
| FR-012 Stream Session Lifecycle | AC-048 ~ AC-050 | TC-029 | 集成（active stream registry + no-restart add/remove） |
| FR-013 Exchange Reliability Controls | AC-051 ~ AC-053 | TC-030 | 单元 + 集成（retry budget + rate-limit + clock skew） |
| FR-014 Runtime Stream Observability | AC-054 ~ AC-056 | TC-031 | httptest + metrics（stream state + lag + unhealthy reason） |
| FR-015 Runtime Pause/Resume/Drain | AC-057 ~ AC-059 | TC-032 | httptest + 集成（pause/resume/drain + audit） |
| FR-016 Historical Backfill Planner | AC-060 ~ AC-062 | TC-033 | 单元（window validation + cursor + overlap rejection） |
| FR-017 Gap Detection and Replay | AC-063 ~ AC-065 | TC-034 | 集成（gap detect + replay jobs + idempotency） |
| FR-018 Archive Manifest and Restore | AC-066 ~ AC-068 | TC-035 | 单元 + 集成（manifest + restore + retention delete） |
| FR-019 Backfill Resource Governance | AC-069 ~ AC-071 | TC-036 | 单元（global/per-instrument caps + cancellation cursor） |
| FR-020 Funding Rate Event Support | AC-072 ~ AC-074 | TC-037 | 单元 + 集成（funding_rate mapping + storage/query/fanout） |
| FR-021 Mark and Index Price Support | AC-075 ~ AC-077 | TC-038 | 单元 + 集成（mark/index price kind + topics/storage） |
| FR-022 Event-Type Governance Matrix | AC-078 ~ AC-080 | TC-039 | 文档校验（R2 120-cell matrix + stale checks） |
| FR-023 Release Evidence Bundle | AC-081 ~ AC-083 | TC-040, TC-041 | 证据归档（local/CI/live/release evidence separation） |
| FR-024 Runtime Config Hot Reload | AC-084 ~ AC-086 | TC-042 | 管理端点 + 集成（catalog reload + stream diff + no-restart proof） |

**AC 总数**：86（AC-001 ~ AC-086）· **TC 总数**：42（TC-001 ~ TC-042）· **覆盖率**：100%（FR→AC→TC 全链路登记；新增 FR-012~FR-024 默认 Pending）

> AC 完整描述（验收标准文本）单点维护于 `TRACEABILITY.md §5`。本表只做 SPEC ↔ Traceability 双向锚点，遵循 `~/.claude/rules/ecc/matrix-scoring-rules.md §R1 跨表走查` 原则。

---

## 8. Business Rules

### BR-001: No binance-market

**规则**：禁止在 active architecture 中引用 `binance-market`。

**约束**：`module/binance-market`、`github.com/ZoneCNH/binance-market`、`docs/services/binance-market-client-svc.md` 不得出现在 active documentation（除 `CHANGELOG.md` 和 `docs/migrations/` 外）。

**违反时**：CI gate 失败，PR 不可合并。

### BR-002: Client Must Not Import Server Internals

**规则**：client 不得 import server internal 包。

**约束**：
- `module/binance/client` → 禁止 import `module/binance/server/*`
- Runtime: `internal/client` 与 `cmd/binance-client` → 禁止 import `internal/server/*`
- 允许：client → `module/natsx`（JetStream publisher）、`module/domain_market` 语义类型、shared config/observability

**违反时**：CI boundary gate（`BOUNDARY-GATES.md` §3）失败。

### BR-003: Server Must Not Import Client Internals

**规则**：server 不得 import client internal 包。

**约束**：
- `module/binance/server` → 禁止 import `module/binance/client/*`
- Runtime: `internal/server` 与 `cmd/binance-server` → 禁止 import `internal/client/*`
- 特别禁止：server → spot/usdm/coinm/options connector、`internal/cs` 包
- 允许：server → `module/domain_market` 语义类型、`module/natsx`、`module/redisx`、`module/taosx`、shared config/observability

**违反时**：CI boundary gate（`BOUNDARY-GATES.md` §4）失败。

### BR-004: natsx ManualAck — 全链路写入后才 Ack

**规则**：server consumer 必须在 redisx + taosx + postgresx + kafkax handoff 全完成后才调用 `msg.Ack()`。

**约束**：禁止在 validation 完成、idempotency 检查后、任何单一存储写入成功后、或 `kafkax` handoff 完成前提前 Ack。

**违反时**：处理中断会导致 JetStream 重投，redisx SetNX 幂等检查防止重复写入 taosx。

### BR-005: No Domain Ownership

**规则**：`module/binance` 不得定义 canonical domain semantics 的 source of truth。

**约束**：`ProductLine`、`InstrumentKey`、`InstrumentType`、`MarketScope`、`OptionType`、`PriceKind` 等 canonical enum 必须来自 `module/domain_market`。Binance 可定义 exchange-specific parsing/mapping，但输出必须是对 domain_market 类型的引用。

**违反时**：CI ownership gate 失败。

### BR-006: No Generic Market Data / Strategy Ownership

**规则**：`module/binance` 可拥有服务 Binance facts 所需的 Binance-specific storage、query API 与 fanout。

**约束**：它不得拥有 generic cross-exchange market_data semantics、generic market_data platform ownership 或 strategy API。禁止引入 `github.com/ZoneCNH/strategy` 作为 owned dependency；generic storage platform ownership 不在 Binance 内。

**违反时**：CI ownership gate 失败。

### BR-007: Wire Contract Externality

**规则**：`module/binance` 不得定义自己的 proto 文件或 wire schema。

**约束**：wire schema（JSON envelope）由 `module/domain_market` 的 `MarketFactEnvelope` 定义。禁止 `module/binance/proto/*` 和独立 canonical wire enum 定义。natsx subject 命名规范见 §9。

**违反时**：CI gate 失败。

### BR-008: Idempotency Key Stability

**规则**：client 生成的 idempotency key 必须在 retry 场景下稳定。

**约束**：key 必须基于 exchange + product_line + instrument_key + event_type + event_time/source_sequence 等确定性维度生成。bar 事件包含 interval/open_time，trade 包含 trade_id，depth 包含 sequence/update dimensions。

**违反时**：retry 时 server 无法识别重复，产生 duplicate storage/fanout effect。

### BR-009: Admin Boundary

**规则**：client admin 仅可变更 client-local state，server admin 仅可变更 server-local state。

**约束**：禁止 client admin 变更 server state、server admin 变更 client connector state、admin 变更非 Binance-owned downstream storage/strategy state。

**违反时**：操作被拒绝并返回错误。

---

## 9. Interface Contract

### natsx JetStream Interface (v2.0.0)

```go
// MarketFactEnvelope is published by client through natsx JetStream.
// natsx JetStream subject 格式（v2.0.0，替代 gRPC MarketDataService）
// Subject: binance.market.{product_line}.{event_type}
// Stream:  BINANCE_MARKET (Retention=7d, Storage=file)
// Client:  js.Publish(subj, json) → PubAck（同步等待）
// Server:  js.Subscribe("binance.market.>", handler, Durable("binance-server"), ManualAck())

// Wire payload: domain_market.MarketFactEnvelope（JSON）
type MarketFactEnvelope struct {
	ProductLine  ProductLine   `json:"product_line"`
	EventType    EventType     `json:"event_type"`
	Symbol       string        `json:"symbol"`
	ExchangeTime time.Time     `json:"exchange_time"`
	ServerTime   time.Time     `json:"server_time"`
	// ... 其他字段见 module/domain_market/SPEC.md §10
}
```

**subject 规范**：

| Subject | 说明 |
|---------|------|
| `binance.market.spot.tick` | 现货成交 |
| `binance.market.spot.bar` | 现货 K 线 |
| `binance.market.spot.depth` | 现货深度 |
| `binance.market.spot.trade` | 现货逐笔成交 |
| `binance.market.um_perp.tick` | U 本位合约成交 |
| `binance.market.um_perp.bar` | U 本位合约 K 线 |
| `binance.market.um_perp.depth` | U 本位合约深度 |
| `binance.market.um_perp.trade` | U 本位合约逐笔成交 |
| `binance.market.cm_perp.tick` | 币本位合约成交 |
| `binance.market.cm_perp.bar` | 币本位合约 K 线 |
| `binance.market.cm_perp.depth` | 币本位合约深度 |
| `binance.market.cm_perp.trade` | 币本位合约逐笔成交 |
| `binance.market.options.tick` | 期权成交 |
| `binance.market.options.bar` | 期权 K 线 |
| `binance.market.options.depth` | 期权深度（Binance EOptions `<symbol>@depth1000` WebSocket stream） |
| `binance.market.options.trade` | 期权逐笔成交 |

- Client 调用 `js.Publish(subj, jsonPayload)`，等待 PubAck 后返回（确保持久化）
- Server durable consumer 订阅 `binance.market.>`，ManualAck，处理完整链路后 Ack

### Server Storage / Fanout / API Surface

Server persists Binance-specific facts through `taosx`（时序）、`clickhousex`（OLAP 分析）、`postgresx`（元数据）、`redisx`（缓存/幂等/锁）adapters, publishes accepted facts through `kafkax` topic `binance.{product_line}.{event_type}.v1`, and exposes Gin REST `GET /api/v1/market/*` for market_data pull access. `market_data` consumes Binance facts through these surfaces; it does not own Binance persistence.

---

## 10. Data Model

### Canonical Event Concepts (owned by module/domain_market)

| Concept | Purpose | Owned By |
|---------|---------|----------|
| `InstrumentKey` | Unique instrument identity across product lines | domain_market |
| `ProductLine` | Spot / USDⓈ-M / COIN-M / Options | domain_market |
| `InstrumentType` | Perpetual / Futures / Option / Spot | domain_market |
| `OptionType` | Call / Put | domain_market |
| `PriceKind` | Bid / Ask / Last / Mark / Index | domain_market |
| `MarketScope` | Exchange-native liquidity scope | domain_market |
| `MarketFactEnvelope` | Canonical event wrapper | domain_market |
| `decision_time` | Exchange event time for strategy feed | domain_market |

### Instrument Identity Dimensions

Minimum dimensions for collision-free identity across Binance product lines:

| Dimension | Spot | USDⓈ-M | COIN-M | Options |
|-----------|:----:|:-------:|:------:|:-------:|
| exchange | ✅ | ✅ | ✅ | ✅ |
| product_line | ✅ | ✅ | ✅ | ✅ |
| instrument_type | ✅ | ✅ | ✅ | ✅ |
| base_asset | ✅ | ✅ | ✅ | ✅ |
| quote_asset | ✅ | — | — | — |
| margin_asset | — | ✅ | ✅ | — |
| settlement_asset | — | — | ✅ | — |
| contract_code | — | ✅ | ✅ | — |
| expiry | — | ✅ | ✅ | ✅ |
| strike | — | — | — | ✅ |
| option_type | — | — | — | ✅ |

### natsx Publish State Machine

```text
pending → publishing → pub_acked
                     → pub_failed_retryable → pending (retry with backoff)
                     → pub_failed_terminal
```

### natsx Consumer Processing State

```text
received → validating → idempotency_check → storing → kafkax_dispatch → acked
                                                     → nak_retry (ManualNak, redelivered by JetStream)
```

### Reject Classification

```text
retryable
terminal_validation
terminal_conflict
unauthorized
rate_limited
server_unavailable
```

---

## 11. Config Schema

> 配置按部署单元分层：§11.1 client 端（仅需 NATS + Binance），§11.2 server 端（全栈 7 模块 + Gin）。
> Secrets 一律从环境变量注入，配置文件仅存非敏感键名与默认值。
> 环境变量前缀：client=`BINANCE_CLIENT_`，server=`BINANCE_SERVER_`。基础设施凭据使用各模块规范前缀。
> `nats.url` 指向外部 NATS JetStream 服务；部署 NATS 集群属于平台/运维边界，不属于 client/server 二进制。
> Dev 非敏感 NATS 配置与 `sre/secrets/env/dev.md` §NATS 对齐：client URL=`nats://127.0.0.1:4222`，monitor=`http://127.0.0.1:8222`，JetStream enabled，server_name=`nats-dev-01`。认证明文只能经环境变量注入。

### 11.1 Client Config（`binance-client.yaml`）

| 配置键 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `binance.rest_url` | `string` | `https://api.binance.com` | Binance REST API base URL |
| `binance.ws_url` | `string` | `wss://stream.binance.com:9443` | Binance WebSocket base URL |
| `binance.product_lines` | `[]string` | `[]` | 启用的产品线（domain_market canonical：`spot`/`um_perp`/`cm_perp`/`options`） |
| `binance.symbols.allow` | `[]string` | `[]` | 白名单 symbol（空=全部） |
| `binance.symbols.deny` | `[]string` | `[]` | 黑名单 symbol |
| `binance.api_key_env` | `string` | `BINANCE_API_KEY` | 读取 API Key 的环境变量名 |
| `binance.secret_key_env` | `string` | `BINANCE_SECRET_KEY` | 读取 Secret Key 的环境变量名 |
| `nats.url` | `string` | `nats://127.0.0.1:4222` | 外部 NATS JetStream 连接地址 |
| `nats.stream` | `string` | `BINANCE_MARKET` | JetStream Stream 名称 |
| `nats.auth.user` | `string` | `admin` | NATS 用户名 |
| `nats.auth.password_env` | `string` | `FOUNDATIONX_NATS_PASSWORD` | NATS 密码环境变量名；旧 `NATS_PASSWORD` 仅作为兼容输入 |
| `publisher.batch_size` | `int` | `256` | 批量发布大小（0=逐条发布） |
| `publisher.flush_interval` | `duration` | `100ms` | 批量刷新间隔 |
| `retry.max_attempts` | `int` | `5` | natsx Publish 最大重试次数 |
| `retry.backoff_initial` | `duration` | `1s` | 初始退避时间 |
| `retry.backoff_max` | `duration` | `60s` | 最大退避时间 |
| `admin.bind` | `string` | `:8081` | Gin admin HTTP 绑定地址（/healthz /readyz） |

> Client 不配置：redis / postgres / taos / clickhouse / kafka / oss / Gin API — 这些全部属于 server。

### 11.2 Server Config（`binance-server.yaml`）

#### 11.2.1 natsx Consumer（server 消费端）

| 配置键 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `nats.url` | `string` | `nats://127.0.0.1:4222` | 外部 NATS JetStream 连接地址 |
| `nats.stream` | `string` | `BINANCE_MARKET` | JetStream Stream 名称 |
| `nats.auth.user` | `string` | `admin` | NATS 用户名 |
| `nats.auth.password_env` | `string` | `FOUNDATIONX_NATS_PASSWORD` | NATS 密码环境变量名；旧 `NATS_PASSWORD` 仅作为兼容输入 |
| `nats.consumer.durable` | `string` | `binance-server` | durable consumer 名称 |
| `nats.consumer.ack_wait` | `duration` | `30s` | ManualAck 超时 |
| `nats.consumer.max_deliver` | `int` | `5` | 最大重投次数（超限进入死信） |
| `nats.consumer.filter_subject` | `string` | `binance.market.>` | 订阅 subject 通配符 |

#### 11.2.2 redisx

| 配置键 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `redis.addr` | `string` | `127.0.0.1:6379` | Redis 地址 |
| `redis.username` | `string` | `admin` | Redis 用户名 |
| `redis.password_env` | `string` | `REDIS_PASSWORD` | Redis 密码环境变量名 |
| `redis.db` | `int` | `0` | Redis DB 编号 |
| `redis.pool_size` | `int` | `32` | 连接池大小 |
| `redis.idempotency.ttl` | `duration` | `72h` | 幂等 key TTL（覆盖 JetStream 7d 重投窗口） |
| `redis.cache.tick_ttl` | `duration` | `60s` | 最新 tick 热缓存 TTL |
| `redis.cache.depth_ttl` | `duration` | `5s` | 深度快照缓存 TTL |
| `redis.lock.ttl` | `duration` | `30s` | 分布式协调锁 lease TTL |
| `redis.ratelimit.window` | `duration` | `1s` | API 限流窗口 |
| `redis.ratelimit.max_req` | `int` | `100` | 每窗口最大请求数 |

#### 11.2.3 postgresx

| 配置键 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `postgres.host` | `string` | `127.0.0.1` | PostgreSQL 主机 |
| `postgres.port` | `int` | `5432` | PostgreSQL 端口 |
| `postgres.database` | `string` | `market_binance` | 数据库名 |
| `postgres.username` | `string` | `market_binance` | 数据库用户名 |
| `postgres.password_env` | `string` | `PG_PASSWORD` | 数据库密码环境变量名 |
| `postgres.sslmode` | `string` | `disable` | SSL 模式（dev=disable，prod=require） |
| `postgres.pool_max` | `int` | `20` | 最大连接数 |
| `postgres.migrations_dir` | `string` | `migrations/` | 迁移脚本目录 |
| `postgres.migrations_table` | `string` | `binance_schema_migrations` | 迁移版本记录表 |

> 数据库 `market_binance` 已存在（PG per-provider 独立数据库）。表（binance_instruments / binance_idempotency_log / binance_admin_audit / binance_stream_sessions）由 migrations/ 目录管理。

#### 11.2.4 taosx

| 配置键 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `taos.endpoint` | `string` | `127.0.0.1:6030` | TDengine Native 端点 |
| `taos.database` | `string` | `market_binance` | TDengine 数据库名 |
| `taos.username` | `string` | `market_binance` | TDengine 用户名 |
| `taos.password_env` | `string` | `TAOS_PASSWORD` | TDengine 密码环境变量名 |
| `taos.write.batch_size` | `int` | `1000` | 批量写入行数 |
| `taos.write.flush_interval` | `duration` | `200ms` | 批量写入刷新间隔 |
| `taos.retention.ticks` | `duration` | `720h` | Tick 热数据保留（30d） |
| `taos.retention.bars` | `duration` | `8760h` | Bar 热数据保留（365d） |
| `taos.retention.depth` | `duration` | `72h` | Depth 热数据保留（3d） |

> 数据库 `market_binance` 已存在（TDengine per-provider 独立数据库）。超表（binance_ticks / binance_bars / binance_depth）由 taosx SchemalessWrite 自动创建子表。

#### 11.2.5 clickhousex（OLAP 分析存储）

| 配置键 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `clickhouse.host` | `string` | `127.0.0.1` | ClickHouse 主机 |
| `clickhouse.port` | `int` | `9000` | ClickHouse Native 端口 |
| `clickhouse.database` | `string` | `market_binance` | ClickHouse 数据库名 |
| `clickhouse.username` | `string` | `default` | ClickHouse 用户名 |
| `clickhouse.password_env` | `string` | `CLICKHOUSE_PASSWORD` | ClickHouse 密码环境变量名 |
| `clickhouse.pool_max` | `int` | `16` | 连接池大小 |
| `clickhouse.etl.interval` | `duration` | `5m` | taosx→clickhousex ETL 间隔 |
| `clickhouse.etl.batch_rows` | `int` | `50000` | ETL 每批行数 |
| `clickhouse.etl.aggregations` | `[]string` | `["1m_ohlcv","5m_vwap","15m_stats"]` | 预计算聚合类型 |

> ClickHouse v26.5.2.39 已部署（host=xhypers，port=9000/8123）。`market_binance` 业务库待建表（通过 clickhousex.Exec DDL）。clickhousex 是 taosx 的 OLAP 互补层：taosx 负责高频时序写入，clickhousex 负责跨符号聚合、多维分析、因子回看查询。

#### 11.2.6 kafkax

| 配置键 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `kafka.brokers` | `[]string` | `["127.0.0.1:9092"]` | Kafka broker 列表 |
| `kafka.auth.mechanism` | `string` | `SASL_PLAINTEXT` | 认证机制 |
| `kafka.auth.username` | `string` | `admin` | Kafka 用户名 |
| `kafka.auth.password_env` | `string` | `KAFKA_PASSWORD` | Kafka 密码环境变量名 |
| `kafka.topic_prefix` | `string` | `binance` | topic 前缀；实际 topic = `binance.{product_line}.{event_type}.v1` |
| `kafka.compression` | `string` | `snappy` | 消息压缩算法 |
| `kafka.retry.max` | `int` | `3` | 发送失败最大重试次数 |
| `kafka.required_acks` | `string` | `all` | 生产者 ACK 级别 |

#### 11.2.7 ossx

| 配置键 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `oss.endpoint` | `string` | `oss-ap-northeast-1.aliyuncs.com` | OSS 地域端点 |
| `oss.bucket` | `string` | `x-go` | OSS Bucket 名称 |
| `oss.path_prefix` | `string` | `binance/market` | 归档路径前缀 |
| `oss.access_key_id_env` | `string` | `OSS_ACCESS_KEY_ID` | AccessKey ID 环境变量名 |
| `oss.access_key_secret_env` | `string` | `OSS_ACCESS_KEY_SECRET` | AccessKey Secret 环境变量名 |
| `oss.archiver.schedule` | `string` | `0 3 * * *` | 归档 cron（默认每日 03:00 UTC） |
| `oss.archiver.ticks_cutoff` | `duration` | `720h` | Ticks 热→冷截止（30d） |
| `oss.archiver.bars_cutoff` | `duration` | `2160h` | Bars 热→冷截止（90d） |
| `oss.archiver.verify_etag` | `bool` | `true` | 上传后 ETag 校验后再删热数据 |

> OSS region=ap-northeast-1（东京），bucket=`x-go`。归档格式：`{prefix}/{product_line}/{symbol}/{YYYY}/{MM}/{DD}/{event_type}.parquet`

#### 11.2.8 Gin REST API

| 配置键 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `api.bind` | `string` | `:8080` | Gin API 绑定地址 |
| `api.auth_token_env` | `string` | `BINANCE_API_TOKEN` | Bearer Token 环境变量名 |
| `api.read_timeout` | `duration` | `30s` | HTTP 读超时 |
| `api.write_timeout` | `duration` | `30s` | HTTP 写超时 |
| `api.max_body_bytes` | `int` | `1048576` | 最大请求体（1MB） |
| `api.cors_allowed_origins` | `[]string` | `[]` | CORS 允许源（空=同源） |
| `admin.bind` | `string` | `:8082` | Gin admin 绑定地址（/healthz /readyz /debug/pprof） |

#### 11.2.9 Observability（server + client 共用）

| 配置键 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `observability.metrics.bind` | `string` | `:9090` | Prometheus metrics 绑定地址 |
| `observability.tracing.sample_rate` | `float` | `0.1` | Trace 采样率（0.0~1.0） |
| `observability.log.level` | `string` | `info` | 日志级别（debug/info/warn/error） |
| `observability.log.format` | `string` | `json` | 日志格式（json/text） |

### 11.3 环境变量清单（Secrets）

> **Security**：所有密码/Token/API Key/Secret 仅通过环境变量注入。配置文件不包含明文凭据。禁止在 logs 和 admin/debug 端点暴露。CI gitleaks 门禁强制执行。

| 环境变量 | 消费方 | 来源（dev） | 说明 |
|---------|--------|------------|------|
| `BINANCE_API_KEY` | client | Binance 交易所 API 管理页 | Binance REST/WS API Key |
| `BINANCE_SECRET_KEY` | client | Binance 交易所 API 管理页 | Binance REST/WS Secret Key |
| `FOUNDATIONX_NATS_PASSWORD` | client + server | `sre/secrets/env/dev.md` §NATS | NATS 认证密码；`NATS_PASSWORD` 仅为兼容旧前缀 |
| `REDIS_PASSWORD` | server | `sre/secrets/env/dev.md` §Redis | Redis 认证密码 |
| `PG_PASSWORD` | server | `sre/secrets/env/dev.md` §PostgreSQL `market_binance` | PostgreSQL 认证密码 |
| `TAOS_PASSWORD` | server | `sre/secrets/env/dev.md` §TDengine `market_binance` | TDengine 认证密码 |
| `CLICKHOUSE_PASSWORD` | server | `sre/secrets/env/dev.md` §ClickHouse | ClickHouse 认证密码 |
| `KAFKA_PASSWORD` | server | `sre/secrets/env/dev.md` §Kafka | Kafka SASL 认证密码 |
| `OSS_ACCESS_KEY_ID` | server | `sre/secrets/env/dev.md` §OSS | 阿里云 OSS AccessKey ID |
| `OSS_ACCESS_KEY_SECRET` | server | `sre/secrets/env/dev.md` §OSS | 阿里云 OSS AccessKey Secret |
| `BINANCE_API_TOKEN` | server（Gin API） | 运维生成 | Gin REST API Bearer Token |

> **凭据来源**：`sre/secrets/env/dev.md`（本地开发环境）。生产环境使用 HashiCorp Vault / GitHub Secrets，不引用本文件。

---

## 12. Error Handling

| 错误 | 触发条件 | 处理方式 | 错误码 |
|------|----------|----------|--------|
| `ErrProductLineDisabled` | 配置未启用的 product line 被请求 | 记录日志，跳过该 product line | `BNC-001` |
| `ErrInvalidSymbol` | parser 无法解析 Binance symbol | 结构化错误返回，记录原始 symbol | `BNC-002` |
| `ErrNATSConnect` | 无法连接 natsx JetStream | 指数退避重试；client 积压在内存队列（有界） | `BNC-003` |
| `ErrNATSPubAck` | JetStream PubAck 超时 | 重试发布；超过阈值触发告警 | `BNC-004` |
| `ErrNATSConsumer` | durable consumer 订阅失败 | 进程重启自动恢复；告警 | `BNC-005` |
| `ErrDuplicateConflict` | server 收到同一 key 但 payload 不同的 event | terminal reject，记录冲突详情 | `BNC-006` |
| `ErrValidation` | server 收到缺少必需字段的 event | terminal reject，含 machine-readable reason | `BNC-007` |
| `ErrKafkaxDispatchFailed` | `kafkax` fanout handoff 失败 | 重试（指数退避）；不 Ack；超过阈值进入 dead-letter/告警路径 | `BNC-008` |
| `ErrRedisUnavailable` | redisx 幂等检查或缓存不可达 | 幂等检查失败 → NakWithDelay；缓存失败 → 降级到 taosx 直查 | `BNC-009` |
| `ErrTaosxWriteFailed` | taosx WriteBatch 写入失败 | NakWithDelay(5s)；MaxDeliver 超过后进入死信 | `BNC-010` |
| `ErrPostgresUnavailable` | postgresx catalog 查询或 upsert 不可达 | 指数退避重试；超过阈值告警 | `BNC-011` |
| `ErrOssUploadFailed` | ossx 归档上传失败 | 保留 taosx 热数据；告警；下个调度周期自动重试 | `BNC-012` |
| `ErrClickhouseUnavailable` | clickhousex ETL 写入或 analytics 查询不可达 | analytics API 返回 503；ETL 跳过本批次；实时 API 不受影响 | `BNC-013` |

---

## 13. Edge Cases

| 场景 | 输入/状态 | 预期行为 |
|------|-----------|----------|
| 产品线身份碰撞 | Spot `BTCUSDT` 和 USDⓈ-M `BTCUSDT` 同时采集 | parser 产生不同 `InstrumentKey`，product_line 维度区分 |
| Client 进程重启 | natsx client 重连 | JetStream PubAck 语义保证，重发消息由 server redisx SetNX 幂等过滤 |
| natsx stream 断连 | server consumer 不可达 | JetStream 重投（NakWithDelay），consumer 重连后自动恢复 |
| Server 崩溃后重启 | consumer 进度未 Ack | durable consumer 从上次 Ack 位置恢复，redisx SetNX 防重复写入 |
| natsx 积压 | stream 积压超过 retention 窗口 | 告警；消息在 7d Retention 内不丢失；超时消息进入死信 |
| Idempotency key 冲突 | 同一 key 但不同 payload 到达 server | server 返回 `terminal_conflict` reject |
| 无效 symbol | parser 收到未知 format 的 symbol | 返回结构化 `ErrInvalidSymbol`，不产生 canonical event |
| 产品线禁用 | 配置中 product line 未启用 | connector 不订阅该 product line 的 stream |
| `kafkax` fanout 持续失败 | `kafkax` 不可用 | 指数退避重试，超过阈值告警，不丢失已 accepted event |

---

## 14. Directory Structure

### Documentation (`module/binance/`)

```text
module/binance/
  goal.md                          # 模块 Goal 文档
  README.md                        # 模块索引
  SPEC.md                          # 本文件 — 模块完整规格
  TRACEABILITY.md                  # 需求追溯矩阵
  IMPLEMENTATION-PLAN.md           # 实现计划（PR 序列）
  BOUNDARY-GATES.md                # CI 边界门禁定义
  RUNTIME-MAPPING.md               # 规格到 runtime 仓库映射
  tasks/                           # Root 层 task spec
    TASK-BINANCE-ROOT-000-*.md
    ...
  client/                          # Client 子模块
    README.md
    SPEC.md
    TRACEABILITY.md
    IMPLEMENTATION-PLAN.md
    tasks/                         # Client task spec（14 个）
  server/                          # Server 子模块
    README.md
    SPEC.md
    TRACEABILITY.md
    IMPLEMENTATION-PLAN.md
    tasks/                         # Server task spec（17 个）
```

### Runtime (`github.com/ZoneCNH/binance/`)

```text
github.com/ZoneCNH/binance/
  go.mod
  cmd/
    binance-client/main.go
    binance-server/main.go
  internal/
    client/     # app/config/catalog/parser/spot/um_perp/cm_perp/options/normalize/mapper/idempotency/publisher/admin/observability
    server/     # app/config/consumer/validation/idempotency/storage/api/fanout/admin/observability
  pkg/
    config/
    observability/
    version/
  test/
    contract/
    integration/
    fixtures/
```

---

## 15. Dependencies

### Allowed Dependencies

| 依赖 | 用途 | 消费方 |
|------|------|--------|
| `module/domain_market` | canonical 语义类型（InstrumentKey/ProductLine/MarketFactEnvelope 等） | client mapper, server validation |
| `module/natsx` | JetStream publish/subscribe（分布式消息通道） | client publisher, server consumer |
| `module/redisx` | SetNX 幂等去重、server-side cache | server idempotency |
| `module/postgresx` | 品种目录元数据持久化 | server catalog |
| `module/taosx` | 时序行情数据存储 | server storage |
| `module/kafkax` | 下游事件分发 | server dispatch |
| `module/ossx` | 归档 / cold-tier snapshot | server archiver |
| `module/clickhousex` | OLAP 分析查询（跨符号聚合、多维分析、因子回看） | server storage（ETL 写入 + analytics API 查询） |
| `gin-gonic/gin` | REST API（`/api/v1/market/*`），供 market_data 拉取 | server API |

### Forbidden Dependencies

| 禁止导入 | 原因 |
|----------|------|
| `module/binance/client/*` (在 server 中) | 违反 client/server 边界 |
| `module/binance/server/*` (在 client 中) | 违反 client/server 边界 |
| `github.com/ZoneCNH/binance-market` | legacy 模块已移除 |
| `github.com/ZoneCNH/storage` (as owned generic platform) | generic cross-exchange storage ownership 不属于 Binance；Binance-specific persistence 通过 Foundation adapters |
| `github.com/ZoneCNH/strategy` (as owned) | strategy ownership 属于分析/决策域 |

---

## 16. Testing

### Test Matrix

| TC 编号 | 对应 FR | 测试类型 | 场景 | 预期结果 |
|---------|---------|----------|------|----------|
| TC-001 | FR-001 | 集成 | 启用 Spot product line，连接 Binance testnet | connector 产生 ProductLine=Spot 的 MarketFactEnvelope |
| TC-002 | FR-002 | 单元 | parser 输入 Spot `BTCUSDT` 和 USDⓈ-M `BTCUSDT` | 生成不同 InstrumentKey |
| TC-003 | FR-002 | 单元 | parser 输入跨 product_line 同 symbol | product_line / settlement / expiry 等维度不碰撞 |
| TC-004 | FR-003 | 集成 | client 调用 `js.Publish(subj, jsonPayload)` | natsx 返回 PubAck，消息持久化到 JetStream stream |
| TC-005 | FR-003 | CI | client/server 独立进程边界检查 | 无同进程 bridge、无跨 internal import |
| TC-006 | FR-004 | 集成 | 处理成功与失败两条消息 | 成功仅在 storage + kafkax handoff 后 Ack；失败 NakWithDelay |
| TC-007 | FR-005 | 单元 | Redis SetNX 首次成功 | 继续 storage/fanout pipeline |
| TC-008 | FR-005 | 单元 | Redis 不可达 | 返回 error，consumer NakWithDelay，不 Ack |
| TC-009 | FR-006 | 单元 | `taosx` WriteTick / WriteBatch | 子表与 batch 写入成功 |
| TC-010 | FR-006 | 单元 | `postgresx` UpsertSymbol | 幂等 upsert，无重复 catalog 记录 |
| TC-011 | FR-006 | 集成 | `taosx` QueryRange | 按 symbol + time range 返回正确结果 |
| TC-012 | FR-007 | httptest | `GET /api/v1/market/ticks` | 返回 `taosx` 查询结果 |
| TC-013 | FR-007 | httptest | `GET /api/v1/market/depth/{instrument_key}` | redisx cache hit 返回最新快照 |
| TC-014 | FR-007 | httptest | 无效 API key | 返回 401 |
| TC-015 | FR-007 | httptest | 请求超过限流 | 返回 429 + Retry-After |
| TC-016 | FR-008 | 单元 | 超 retention 数据归档 | 先写 `ossx`，ETag 校验通过后删 `taosx` |
| TC-017 | FR-008 | 单元 | 生成归档路径 | 路径符合 `binance/{product_line}/{symbol}/{YYYY}/{MM}/{DD}/{event_type}.parquet` |
| TC-018 | FR-008 | 单元 | kafkax topic 与 partition key | topic 为 `binance.{product_line}.{event_type}.v1`，key 为 symbol |
| TC-019 | FR-008 | 单元 | `kafkax` 不可达 | 返回 error，未完成 handoff 前不 Ack |
| TC-020 | FR-009 | CI | server import `internal/client` 或 `internal/cs` | boundary gate 失败 |
| TC-021 | FR-009 | CI | reintroduce `binance-market` 引用 | no-legacy gate 失败 |
| TC-022 | FR-009 | CI | go.mod 依赖合规检查 | natsx/redisx/kafkax/postgresx/taosx/clickhousex/ossx/gin 均为 direct |
| TC-023 | FR-006c | 单元 | redisx 热缓存写入 | redisx SET(tick:{line}:{symbol}, json, 60s) 成功；失败→warn 降级，主管线不阻塞 |
| TC-024 | FR-007a | httptest | clickhousex analytics API | GET /api/v1/analytics/vwap + top-movers + correlation；clickhousex 不可达→503 |
| TC-025 | FR-010 | 集成 | clickhousex ETL | taosx Query → 聚合 → InsertBatch（1m_ohlcv/5m_vwap/15m_stats）写入成功 |
| TC-026 | FR-010 | 单元 | clickhousex 不可达→ETL 降级 | InsertBatch 失败→error 日志 + 跳过本批次；实时 ticks API 正常 |
| TC-027 | FR-011 | 单元 | coordinator 分布式锁获取 | redisx SetNX 成功→启动 scheduler；失败→standby 每 5s 轮询 |
| TC-028 | FR-011 | 单元 | lease 续期失败与主动释放 | Expire 失败→停止 ETL+归档；正常关闭→Del 主动释放锁 |
| TC-029 | FR-012 | 集成 | active stream registry 增删订阅 | 不重启 client 进程即可应用 stream diff |
| TC-030 | FR-013 | 单元 + 集成 | retry budget、rate-limit 与 clock skew 控制 | 故障注入下 retry/backoff/clock skew 指标符合预算 |
| TC-031 | FR-014 | httptest + metrics | runtime stream state / lag / unhealthy reason | admin/metrics 同步暴露可审计状态 |
| TC-032 | FR-015 | httptest + 集成 | pause/resume/drain lifecycle | pause 后停止新增消费，resume 恢复，drain 有审计记录 |
| TC-033 | FR-016 | 单元 | backfill window、cursor 与 overlap validation | 无效窗口/重叠区间被拒绝，cursor 可恢复 |
| TC-034 | FR-017 | 集成 | gap detection and replay idempotency | gap 生成 replay job，重复 replay 不重复写入 |
| TC-035 | FR-018 | 单元 + 集成 | archive manifest、restore 与 retention delete | manifest 可校验，restore 可回放，retention delete 有保护 |
| TC-036 | FR-019 | 单元 | backfill resource cap and cancellation cursor | 全局/单 instrument 限额生效，取消后 cursor 可恢复 |
| TC-037 | FR-020 | 单元 + 集成 | funding_rate event mapping/storage/query/fanout | funding_rate 事件在 mapping、存储、API 与 fanout 中一致 |
| TC-038 | FR-021 | 单元 + 集成 | mark_price/index_price kind/topic/storage | mark/index price 不与 last/bid/ask 混淆 |
| TC-039 | FR-022 | 文档校验 | R2 governance matrix + stale alias checks | 24 FR/event-product-governance cells 覆盖 5 个文档/checker 锚点 |
| TC-040 | FR-023 | 证据归档 | local/CI/live evidence bundle | local 与 remote CI/live 证据分层归档，不能互相替代 |
| TC-041 | FR-023 | release gate | release tag/changelog/evidence consistency | release tag、CHANGELOG、CI URL、evidence bundle 一致 |
| TC-042 | FR-024 | 集成 + httptest | `POST /api/v1/admin/symbols/reload` catalog reload | endpoint 验证通过，并证明 active stream add/remove 无进程重启 |

### Test Tools

- 框架：`testing` + `testify`
- Mock：natsx embedded test server（`nats-server -js`），redisx mock
- 覆盖率：`go test -cover`
- 竞态：`go test -race`

---

## 17. Performance Budget

| 操作 | 指标 | 目标 | 测量方式 |
|------|------|------|----------|
| Client event normalization | 延迟 P99 | < 1ms | `go test -bench` |
| Canonical mapping | 延迟 P99 | < 100μs | `go test -bench` |
| natsx PubAck (单 event) | 延迟 P99 | < 10ms | integration test |
| Server consumer process (validate→store) | 延迟 P99 | < 50ms | integration test |
| Server validation | 延迟 P99 | < 100μs | `go test -bench` |
| redisx idempotency check (SetNX) | 延迟 P99 | < 1ms | `go test -bench` |
| redisx hot cache read (GET) | 延迟 P99 | < 0.5ms | `go test -bench` |
| taosx WriteBatch (1000 rows) | 延迟 P99 | < 20ms | integration test |
| taosx WriteBatch | 吞吐量 | ≥ 100,000 TPS | `go test -bench` |
| postgresx UpsertSymbol | 延迟 P99 | < 5ms | `go test -bench` |
| clickhousex InsertBatch (50000 rows) | 延迟 P99 | < 500ms | integration test |
| clickhousex analytics Query | 延迟 P99 | < 2s | integration test |
| kafkax Send (async) | 延迟 P99 | < 5ms | integration test |
| ossx Upload (100MB parquet) | 吞吐量 | ≥ 50 MB/s | integration test |
| ACK lag (server receive → ACK send) | P99 | < 100ms | integration test |
| Client restart recovery | 时间 | < 10s | integration test |
| Gin API /api/v1/market/ticks (redisx hit) | 延迟 P99 | < 5ms | httptest benchmark |
| Gin API /api/v1/market/depth (redisx hit) | 延迟 P99 | < 1ms | httptest benchmark |
| Gin API /api/v1/analytics/vwap (clickhousex) | 延迟 P99 | < 2s | httptest benchmark |
| Gin API /api/v1/instruments (postgresx) | 延迟 P99 | < 20ms | httptest benchmark |

---

## 18. Observability

### Metrics

| 指标名 | 类型 | 说明 |
|--------|------|------|
| `binance_client_raw_events_total` | counter | 收到的原始事件数（per product_line） |
| `binance_client_events_normalized_total` | counter | 规范化后的事件数 |
| `binance_client_events_mapped_total` | counter | 映射为 canonical 的事件数 |
| `binance_client_events_published_total` | counter | natsx JetStream 发布成功的事件数 |
| `binance_client_puback_latency_seconds` | histogram | PubAck 延迟 |
| `binance_client_puback_lag_seconds` | histogram | PubAck 延迟（publish → PubAck receive） |
| `binance_client_retry_total` | counter | 重试次数 |
| `binance_client_stream_reconnects_total` | counter | stream 重连次数 |
| `binance_server_consumer_lag` | gauge | JetStream durable consumer backlog |
| `binance_server_events_accepted_total` | counter | 接受的唯一事件数 |
| `binance_server_events_duplicate_total` | counter | 重复事件数 |
| `binance_server_events_rejected_total` | counter | 拒绝事件数（per reject_reason） |
| `binance_server_kafkax_dispatch_latency_seconds` | histogram | `kafkax` fanout handoff 延迟 |

### Logging

| 事件 | 级别 | 必要字段 |
|------|------|----------|
| Consumer started/stopped | info | durable, subject |
| Event accepted | debug | stream_id, product_line, instrument_key, idempotency_key |
| Event rejected | warn | stream_id, reject_reason, idempotency_key |
| Duplicate detected | debug | stream_id, idempotency_key |
| Fanout failed | error | stream_id, instrument_key, kafkax_topic, error |
| natsx stream reconnect | info | stream_id, subject |
| natsx consumer redelivery | warn | subject, deliver_count |

### Tracing

| Span 名 | 说明 |
|---------|------|
| `binance.client.normalize` | 原始事件规范化 |
| `binance.client.map` | 映射为 canonical event |
| `binance.client.publish` | natsx JetStream 发布 |
| `binance.client.puback_wait` | 等待 PubAck |
| `binance.server.validate` | server 端验证 |
| `binance.server.idempotency_check` | 幂等性检查 |
| `binance.server.kafkax_dispatch` | `kafkax` fanout handoff |

---

## 19. Security

- 禁止硬编码 API key、secret、signature
- 所有 secret 从环境变量注入，不在 config 文件中存储
- `/debug/*` 和 `/admin/*` 端点不得暴露 secrets、API keys、签名或私有配置
- Admin 端点在暴露于非本地可信网络时必须使用认证
- 日志中禁止记录 API key、secret、signature、完整 payload（仅记录 metadata）
- Client/server 间 natsx 通信使用 TLS（`module/natsx` TLS policy 指导）
- 输入校验：所有收到的 exchange-native payload 在进入 parser 前验证基本结构
- Idempotency store 不暴露外部查询接口

---

## 20. CI Gate

### 通用 Gate

| Gate | 命令 | 通过条件 |
|------|------|----------|
| 编译 | `go build ./...` | 零错误 |
| 测试 | `go test ./... -race -count=1` | 全部通过 |
| 覆盖率 | `go test ./... -coverprofile=coverage.out && go tool cover -func=coverage.out` | ≥ 80% |
| Vet | `go vet ./...` | 零警告 |
| Lint | `golangci-lint run` | 零警告 |
| 安全 | `gitleaks detect --no-git` | 零泄露 |

### Module-Specific Gates

| Gate | 命令 | 通过条件 |
|------|------|----------|
| No legacy binance-market | `BOUNDARY-GATES.md` §2 gate script | 零 forbidden 引用 |
| Client/server boundary | `BOUNDARY-GATES.md` §3-§4 gate scripts | 零跨边界 import |
| Ownership | `BOUNDARY-GATES.md` §5 gate script | 零 generic market_data/strategy 所有权声明；Binance-specific persistence/API/fanout 明确归属 server |
| No local legacy proto/gRPC | `BOUNDARY-GATES.md` §6 gate script | 零 local proto 文件；ingest runtime 不依赖 gRPC wire contract |
| Domain-market source | `BOUNDARY-GATES.md` §7 gate script | 零独立 canonical enum 定义 |
| Admin boundary | `BOUNDARY-GATES.md` §8 gate script | 零跨模块 admin mutation |
| natsx ManualAck 全链路 | `BOUNDARY-GATES.md` §9 gate script | 零 partial-write Ack |

---

## 21. Upgrade Compatibility

| 变更类型 | 兼容性 | 迁移方式 |
|----------|--------|----------|
| 新增 product line | 向后兼容 | 添加 connector + parser rule + catalog entry |
| `MarketFactEnvelope` JSON schema 变更 | 取决于 domain_market 兼容策略 | 升级 domain_market 版本，更新 client mapper 和 server consumer |
| Canonical domain type 变更 | 取决于 domain_market 兼容策略 | 更新 mapper，regenerate 测试 fixtures |
| natsx stream schema 变更 | 需协调 client/server 升级 | 蓝绿部署；consumer durable name 版本化 |
| Admin endpoint 新增 | 向后兼容 | 无迁移需求 |
| 移除 `binance-market` references | Breaking（新模块无此 legacy） | `docs/migrations/remove-binance-market.md` |

---

## 22. Release DoD

`module/binance` v2.0.0 发布完成标准：

- [ ] `binance-market` references 已移除或隔离到 migration history（BR-001）
- [ ] `module/binance/client` 和 `module/binance/server` specs 完成并通过 spec-lint
- [ ] root/client/server TRACEABILITY.md 完成，所有需求可追溯
- [ ] client/server task sets 独立可执行
- [ ] Delivery semantics 明确为 at-least-once + idempotent acceptance（FR-004, FR-005）
- [ ] natsx JetStream ManualAck 全链路语义已定义且 testable（BR-004）
- [ ] ProductLine 和 InstrumentKey 碰撞 case 已文档化（FR-002, §10 Data Model）
- [ ] Boundary gates 可在 CI 执行（FR-009, BOUNDARY-GATES.md）
- [ ] Runtime mapping 未将 generic market_data/strategy ownership 放在 Binance 内（BR-006）
- [ ] 所有 FR 实现完成，所有 AC 验证通过
- [ ] 覆盖率 ≥ 80%
- [ ] CI Gate 全部通过（通用 + 模块专属）
- [ ] Performance Budget 达标
- [ ] Integration test 演示 `client → natsx → server → storage/API/kafkax` 完整数据流

---

## 23. Open Questions

### Resolved (was Blocking)

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-001 | `natsx` subject + `domain_market` envelope final wire 是否已确认？ | 已确认 — 以本 SPEC §9 `MarketFactEnvelope` JSON 与 `binance.market.*` subjects 为准 | binance owner |
| OQ-002 | `market_data` integration mode 是否已确认？ | 已确认 — Gin REST pull + `kafkax` fanout；不再使用 DownstreamDispatchPort | binance / market_data owner |

### Non-blocking

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-003 | server idempotency store 的 backing storage 选型（in-memory / SQLite / Redis）？ | 已解决 — Redisx SetNX 为 production default；memory 仅允许 local test | binance owner |
| OQ-004 | 是否需要 multi-region Binance endpoint 切换？ | 待评估 | binance owner |
| OQ-005 | `Binance server` 是否需要支持非 Binance 的 multi-exchange server？ | 待评估 | architecture |

### Future

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-006 | 是否需要 Binance 以外的 CEX 参照此 C/S 架构统一？ | 待评估 | architecture |
| OQ-007 | 是否需要压缩 `natsx` payload（特别是 depth snapshot）？ | 待评估 | performance |

---

## Appendix A: Architecture Decision Record

| 日期 | 决策 | 理由 |
|------|------|------|
| 2026-06-16 | 采用 client/server 双端架构 | SDK + Provider 模型职责不清，C/S 明确采集端和受理端边界 |
| 2026-06-16 | 移除 `binance-market` | 统一到 client/server，消除 ambiguous split |
| 2026-06-21 | v2.0.0 uses `natsx` JetStream instead of gRPC bidi stream | PubAck + durable consumer remove client spool/checkpoint and decouple processes |
| 2026-06-21 | v2.0.0 deletes `internal/cs` as runtime dependency | Same-process bridge blocks independent deployability |
| 2026-06-21 | Server owns Binance-specific storage/API and fanout through Foundation adapters | `market_data` consumes via Gin REST/`kafkax`; generic semantics remain outside Binance |

## Appendix B: Reference — Removed Legacy Module

`binance-market` 不再存在。以下路径禁止用于新开发：

```text
module/binance-market
github.com/ZoneCNH/binance-market
docs/services/binance-market-client-svc.md
```

允许的历史性提及：

```text
docs/migrations/remove-binance-market.md
CHANGELOG.md
```

## Appendix C: Data Flow Diagram

```text
Binance Exchange (REST/WebSocket)
  │
  ├─ Spot connector ─────────────┐
  ├─ USDⓈ-M connector ──────────┤
  ├─ COIN-M connector ───────────┤
  └─ Options connector ──────────┘
           │
           ▼
    ┌──────────────────┐
    │  Product-Line     │
    │  Catalog          │
    ├──────────────────┤
    │  Instrument       │
    │  Parser           │
    ├──────────────────┤
    │  Raw Event        │
    │  Normalizer       │
    ├──────────────────┤
    │  Canonical        │
    │  Mapper           │ ◄── module/domain_market
    ├──────────────────┤
    │  Idempotency Key  │
    │  Generator        │
    ├──────────────────┤
    │  natsx Publisher  │ ◄── module/natsx (JetStream)
    └────────┬─────────┘
             │  binance.market.{product_line}.{event_type}  (JetStream BINANCE_MARKET)
             ▼
    ┌──────────────────┐
    │  natsx Consumer   │ ◄── module/natsx durable=binance-server, ManualAck
    │  (Server)         │
    ├──────────────────┤
    │  Validation       │
    ├──────────────────┤
    │  redisx SetNX     │ ◄── module/redisx (idempotency)
    │  Idempotency      │
    ├──────────────────┤
    │  taosx Storage    │ ◄── module/taosx (time-series)
    ├──────────────────┤
    │  postgresx        │ ◄── module/postgresx (catalog)
    ├──────────────────┤
    │  kafkax Dispatch  │ ◄── module/kafkax (downstream fanout)
    ├──────────────────┤
    │  msg.Ack()        │  ← storage + kafkax handoff 成功后才 Ack
    ├──────────────────┤
    │  Gin REST API     │ ◄── gin-gonic/gin  /api/v1/market/*
    └────────┬─────────┘
             │  HTTP (market_data 主动拉取)
             ▼
    ┌──────────────────┐
    │  module/          │
    │  market_data      │
    │  (exchange-neutral│
    │   pipeline)       │
    └──────────────────┘
```

## Appendix D: Acceptance Criteria Registry

> 验收口径：本 Registry 锚定到 §7 Functional Requirements 与 §16 Testing TC 矩阵，每条 AC 必须能由一条 TC 或 CI Gate 直接验证。`Status` 字段对齐 §1 Metadata 的 Status=Approved。

| AC ID      | FR/BR Ref            | Criterion                                                                                                    | Verification                          | Status   |
| ---------- | -------------------- | ------------------------------------------------------------------------------------------------------------ | ------------------------------------- | -------- |
| AC-BNC-001 | FR-001               | Spot / USDⓈ-M / COIN-M / Options 四产品线 connector 均可独立启停，配置禁用时不订阅对应 stream                | TC-001, integration test              | Approved |
| AC-BNC-002 | FR-002               | parser 对 Spot `BTCUSDT` 与 USDⓈ-M `BTCUSDT` 输出不同 `InstrumentKey`，product_line/settlement/expiry 维度不碰撞 | TC-002, TC-003                        | Approved |
| AC-BNC-003 | FR-003               | client 调用 `js.Publish(subj, jsonPayload)` 成功后必须收到 JetStream PubAck；Stream=`BINANCE_MARKET` Retention=7d | TC-004, BOUNDARY-GATES.md §3-§4       | Approved |
| AC-BNC-004 | FR-004, BR-004       | server 仅在 redisx + taosx + postgresx + kafkax handoff 全部成功后调用 `msg.Ack()`，失败路径走 `NakWithDelay` | TC-006, BOUNDARY-GATES.md §9          | Approved |
| AC-BNC-005 | FR-005, BR-008       | redisx SetNX 首次成功进入 storage/fanout；重复 key 同 payload 返回 idempotent ACK；payload 冲突返回 terminal_conflict | TC-007, TC-008                        | Approved |
| AC-BNC-006 | FR-006a              | taosx WriteBatch 写入 tick/bar/depth 到对应超级表子表；失败时不 Ack 并 NakWithDelay(5s)                       | TC-009, TC-011                        | Approved |
| AC-BNC-007 | FR-006b              | postgresx 通过 `ON CONFLICT DO UPDATE` 幂等 upsert `binance_instruments` 表，不可达时返回 error              | TC-010                                | Approved |
| AC-BNC-008 | FR-006c              | redisx 热缓存 SET(tick, 60s) / SET(depth, 5s) 成功；失败时降级到 taosx 直查，不阻塞主管线                    | TC-023                                | Approved |
| AC-BNC-009 | FR-006d, FR-008      | ossx 归档路径 `binance/{product_line}/{symbol}/{YYYY}/{MM}/{DD}/{event_type}.parquet`；ETag 校验通过才删 taosx 热数据 | TC-016, TC-017                        | Approved |
| AC-BNC-010 | FR-007               | `GET /api/v1/market/{ticks,bars,depth,trades}/:symbol` 走 redisx 热缓存优先，cache miss 回退 taosx；无效 token 返回 401，超限返回 429 | TC-012, TC-013, TC-014, TC-015        | Approved |
| AC-BNC-011 | FR-007a, FR-010      | clickhousex analytics API（vwap/top-movers/correlation/volume-profile）通过 OLAP 查询返回结果；不可达返回 503，实时 API 不受影响 | TC-024, TC-025, TC-026                | Approved |
| AC-BNC-012 | FR-008               | server storage 全部成功后 kafkax Send 到 `binance.{product_line}.{event_type}.v1`，key=symbol；handoff 完成前不得 Ack | TC-018, TC-019                        | Approved |
| AC-BNC-013 | FR-009, BR-002, BR-003 | CI boundary gate 拦截 client→server internal import / server→client internal import / `internal/cs` 引用 / `binance-market` 引用 | TC-020, TC-021, TC-022                | Approved |
| AC-BNC-014 | FR-010               | ETL scheduler 每 5 分钟从 taosx 聚合 1m_ohlcv/5m_vwap/15m_stats 写入 clickhousex；失败时跳过本批次不阻塞热路径 | TC-025, TC-026                        | Approved |
| AC-BNC-015 | FR-011               | redisx SetNX 分布式锁竞选 coordinator；成功者启动 ETL+归档，每 10s 续期 lease；失败时主动 Del 或 lease 过期由 standby 接管 | TC-027, TC-028                        | Approved |
| AC-BNC-016 | BR-005, BR-006, BR-007 | 模块不定义 canonical domain enum、不引入 `github.com/ZoneCNH/strategy`、不定义本地 proto/wire schema       | CI ownership/wire-contract gate       | Approved |
| AC-BNC-017 | §19 Security         | 配置文件无明文凭据；所有 Secret 通过环境变量注入；日志/admin 端点不暴露 API Key/Signature；gitleaks 零命中    | CI gitleaks gate                      | Approved |
| AC-BNC-018 | §17 Performance      | natsx PubAck P99 < 10ms、server consumer process P99 < 50ms、Gin /api/v1/market/ticks (redisx hit) P99 < 5ms | `go test -bench` + httptest benchmark | Approved |

> Coverage：18 条 AC 覆盖 FR-001..FR-011（11/11）+ BR-002/BR-003/BR-004/BR-005/BR-006/BR-007/BR-008（7/9，其余 BR-001/BR-009 已由 §16 TC + §19 Admin Boundary 覆盖）+ §17/§19 NFR。

---

## Appendix E: Upstream Contract Gate Closure

> 本节是 PR-007 运行时实现前的上游契约链闭合验证记录，原以 §0 形式置于文档前部，现按 23 节模板规整为附录 D。原内容完整保留，仅顶层标题变更。


在从 docs baseline 推进到运行时实现前，必须逐项验证以下上游契约链闭合条件：

| # | Gate | 验证 | 状态 |
|---|------|------|:----:|
| G0-1 | `module/natsx` JetStream stream `BINANCE_MARKET` + subject pattern `binance.market.{product_line}.{event_type}` + durable consumer 规范 | natsx SPEC + v2.0.0 RUNTIME-MAPPING.md | ✅ |
| G0-2 | `module/domain_market` `ProductLine`(4值)/`InstrumentKey`(12维)/`MarketFactEnvelope` canonical 类型 | domain_market SPEC v1.0.1 §10 | ✅ |
| G0-3 | `redisx`/`taosx`/`postgresx`/`ossx`/`kafkax`/Gin ownership chain ready | server SPEC §7/§9 + v2.0.0 RUNTIME-MAPPING.md | ✅ |
| G0-4 | binance OQ-001（`natsx` + `domain_market` envelope ready?） | 已确认：本 SPEC §9 | ✅ |
| G0-5 | market_data consumption via REST/`kafkax` ready | 已确认：本 SPEC §9.2 | ✅ |
| G0-6 | BOUNDARY-GATES.md 全部 9 门禁有 CI 脚本 | 9/9 (2026-06-17) | ✅ |

> **6/6 通过** — 上游契约链闭合。本 SPEC 处于 Review 状态，可进入运行时实现阶段（PR-007）。实现时必须严格遵循 natsx JetStream subject 规范、domain_market §10 canonical semantics、Gin REST API `/api/v1/market/*` 契约。

---
