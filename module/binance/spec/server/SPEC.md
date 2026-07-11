# module/binance/server SPEC

## 1. Metadata

| 字段 | 值 |
|------|-----|
| Module | `module/binance/server` |
| Status | Approved |
| Spec-Version | v4.1.0 |
| Last-Updated | 2026-07-10 (canonical event_type recovery + Runtime-Version v0.15.1 对齐) |
| Last-Updated | 2026-06-26 (v2.2.0→v3.8.0: 结构性修复 — 废除本地 FR/BR 编号，全部改为引用根 SPEC canonical FR/BR；§7 重构为根 FR 的 server 实现视图；删除内嵌 FR-025~028 改为根引用；SC→TC 测试编号统一) |
| Owner | ZoneCNH |
| Layer | 数据域 · 行情接入层 |
| Role | Binance 行情数据的处理 + 存储服务端（natsx 消费 + redisx + postgresx + taosx + clickhousex + kafkax + ossx + Gin REST API） |
| Port Interface | natsx JetStream subscription filter `binance.market.>`；实际消息 subject `binance.market.*.*.v1`；Gin REST HTTP `:8080` (提供给 market_data) |
| Language | Go |
| Runtime-Version | v0.15.1 |
| Repository | [github.com/xhyperium/binance](https://github.com/xhyperium/binance)（server/ 子目录） |
| Go Module Path | `github.com/xhyperium/binance`（monorepo，server 端通过 `cmd/binance-server` + `internal/server` 提供） |
| Related | [CONSTITUTION.md](../../../../CONSTITUTION.md), [ARCHITECTURE.md](../../../../ARCHITECTURE.md), [module/binance/spec/SPEC.md](../SPEC.md), [module/domain_market](../../../domain_market/), [module/natsx](../../../natsx/), [module/redisx](../../../redisx/), [module/taosx](../../../taosx/), [module/clickhousex](../../../clickhousex/), [module/kafkax](../../../kafkax/), [module/ossx](../../../ossx/), [module/postgresx](../../../postgresx/) |

---

## 2. Summary

`module/binance/server` 是 Binance 行情数据的**处理 + 存储服务端**，以**独立进程**运行。

**职责全集**：消费 → 校验 → 幂等 → 处理 → 存储 → 缓存 → 发布 → 归档 → 提供 API。

```text
[服务区 / 内网]
  binance-server（独立进程）

  natsx.Subscribe()             ← 跨网络消费 NATS JetStream
        ↓
  validation → idempotency(redisx SetNX)
        ↓
  processor(enrich/aggregate)
        ↓ ─────────────────────────────────────────┐
  taosx.WriteBatch()            时序存储             │
  postgresx.Upsert()            元数据              │
  redisx.SET(tick:*, 60s)       热缓存              │
  kafkax.Send()                 跨域事件发布         │
        ↓                                          │
  Gin REST API :8080            供 market_data 调用  │
  ossx.Upload()                 定时归档(async)  ←───┘
```

client 和 server **互不感知彼此的进程位置**。server 只知道 NATS subject，不知道 client 在哪里。

---

## 3. Problem

- **无法独立部署**：旧架构 server 通过 Go interface 接受 client 直调，必须同进程，无法横向扩展
- **数据质量无防护**：无校验层，畸形事件进入下游
- **重复投递无保护**：无幂等边界，client 重试导致重复处理
- **无存储能力**：server 不存储数据，全依赖外部 market_data，延迟高，耦合强
- **无对外 API**：market_data 无法主动查询，只能被动接收推送

---

## 4. Goals

- **独立进程部署**：`binance-server` 以独立二进制运行，支持多实例 HA
- 通过 **natsx JetStream** 消费 client 发布的事件（durable consumer + ManualAck）
- 执行完整信封校验
- **redisx** 实现幂等 SetNX（72h TTL），**postgresx** 持久备份幂等日志
- **taosx** 存储时序行情数据（tick/bar/depth），支持实时写入与历史查询
- **postgresx** 存储合约元数据（instrument catalog）和审计日志
- **redisx** 热缓存最新行情（60s TTL），加速 API 响应
- **kafkax** 发布已验收事件到 `binance.{product_line}.{event_type}.v1` topic，解耦下游消费者
- **ossx** 定时将过期行情从 taosx 归档到对象存储（parquet/json.gz）
- **Gin REST API**（:8080）供 `market_data` 主动查询：`/api/v1/market/*`
- 提供 Gin admin HTTP 端点（health、stats、drain）
- 提供完整的可观测性指标（accepted/rejected/duplicate counts、latency）

---

## 5. Non-goals

- 不做 Binance REST/WebSocket 适配（由 `module/binance/client` 负责）
- 不做 exchange connectivity（由 `module/binance/client` 负责）
- 不做 client-side spool/checkpoint 管理（v2.0.0 已删除，由 natsx JetStream 替代）
- 不做 canonical domain type 定义（由 `module/domain_market` 负责）
- 不做 proto/gRPC 定义（v2.0.0 已删除，通过 natsx 通信）
- 不做跨交易所通用采集/消费服务（本模块仅 Binance）
- 不做旧 `binance-market` 兼容
- 不做 strategy API / trading decision（由决策域负责）
- 不做 order execution（由执行域负责）

> **v2.0.0 归属变更**：`market_data` 不再拥有 Binance 行情存储。
> `binance/server` 拥有 taosx 时序存储 + postgresx 元数据 + ossx 归档。
> `market_data` 改为通过 Gin REST API 主动拉取 和 kafkax topic 消费。

---

## 6. Consumers

| 消费者 | 使用方式 |
|--------|----------|
| natsx JetStream | server 消费 subject `binance.market.>` 接收 client 发布的行情事件 |
| `module/market_data` | 通过 Gin REST `GET /api/v1/market/*` 主动拉取，或消费 kafkax topic `binance.{product_line}.{event_type}.v1` |
| 下游分析域 | 通过 kafkax consumer group 消费 `binance.spot.book_ticker.v1` 等 topic |
| `SRE / 运维` | 通过 Gin admin HTTP 端点查询流状态、触发排水 |

---

## 7. Functional Requirements（Server 实现视图）

> **编号规则（v3.8.0 统一）**：本节以根 SPEC canonical FR 编号为标题，补充 server 特有的 WHEN/THEN 实现细节。不定义独立 FR 编号。完整 FR 定义见 [根 SPEC](../SPEC.md) §7。FR-025~028 等根级 FR 的 server 侧实现锚点以引用形式标注。

> **职责分层声明（修复 GAP-E54）**：本 SPEC 是根 SPEC 全集（FR-001~FR-061）的 **server 进程投影**，**故意只列出 server 进程实现的 FR 子集**，不重复全部根 FR。根 SPEC 中未出现在本节的 FR 不属于 server 职责，其归属如下（**这些"缺失"是设计而非遗漏**）：
>
> | 归属进程 | 涉及根 FR（概要） | 说明 |
> |---------|------------------|------|
> | **client 采集** | FR-001/002（stream/kline 采集与归一化） | 行情订阅、normalize envelope，见 [Client SPEC](../client/SPEC.md) |
> | **catalog/identity** | FR-012/013/015/022/024/031/033/034/035/036/050/051 | ExchangeInfo catalog、InstrumentKey、delist、tier 分级——部分 client 侧采集、部分跨进程共享，server 仅在 FR-032 消费落地 |
> | **orderbook 状态机** | FR-052~FR-061 | Order Book Manager 全部在 client 侧进程（per-symbol 本地状态机、rebuild、TopN 订阅） |
> | **whitelist 同步** | FR-045~FR-049 | 白名单 sync job / review 队列 / consumer SDK，跨 client + server，server 侧落地见 FR-032/FR-006b |
> | **observability/smoke** | FR-016/037 | client metrics、`/ingest` smoke 开关 |
> | **release/ops/quality** | FR-014/019/023/030/037/039/040/041/042/043 | 优雅关闭、REST 查询、retention、admin、HA/DR、canary、soak/chaos——属部署/运维面，部分跨进程，server 侧锚点已在本节对应 FR（如 FR-005/FR-011）内体现 |
>
> **审计口径**：server SPEC FR 数（本节，约 36 条）≠ 根 SPEC FR 数（65 条）是**职责分层结果**。判定"FR 是否下沉"应检查「server 进程是否实际实现该 FR 的行为」，而非「本 SPEC 是否机械列出该 FR 编号」。

### Server 实现 FR 速查表

| 根 FR | 名称 | Server 侧职责 |
|-------|------|-------------|
| FR-003 | natsx Communication | durable consumer 订阅 + ManualAck |
| FR-004 | At-Least-Once Delivery | ManualAck policy + NakWithDelay + dead-letter |
| FR-005 | Idempotent Acceptance | redisx SetNX + payload hash 校验 |
| FR-006a | taosx Time-Series Storage | WriteBatch tick/bar/depth |
| FR-006b | postgresx Metadata Storage | UpsertSymbol ON CONFLICT |
| FR-006c | redisx Hot Cache | SET tick/depth TTL 缓存 |
| FR-006d | ossx Archival | ETag 校验后删除 taosx 热数据 |
| FR-006e | taosx Data Retention Lifecycle | 定时 DELETE + OSS ETag 前置校验 |
| FR-007 | Gin Market API | REST `/api/v1/market/*` |
| FR-007a | clickhousex Analytics API | `/api/v1/analytics/*` |
| FR-008 | kafkax Downstream Broadcast | topic `binance.{pl}.{et}.v1` fanout |
| FR-009 | Boundary Enforcement | CI gate 阻断跨界 import |
| FR-010 | clickhousex OLAP Storage | 5min ETL 聚合 |
| FR-011 | Distributed Coordinator Lock | redisx SetNX HA 选举 |
| FR-017 | Gap Detection and Replay | gap 检测 + replay job + 幂等回放 |
| FR-018 | Archive Manifest and Restore | manifest + restore + retention-delete guard |
| FR-020 | Funding Rate Event Support | taosx 存储 + postgresx 历史 + kafkax fanout |
| FR-021 | Mark and Index Price Support | taosx 独立超级表 + kafkax fanout |
| FR-025 | Backfill Throttle & Priority | 分钟 weight 预算 + P0/P1/P2 三级优先级 |
| FR-026 | Daily Reconciliation Job | 04:00 UTC 对账 + tolerance 比对 |
| FR-027 | Cold Data Rehydration | OSS→taosx 回热 + 202 job_id + 24h TTL |
| FR-028 | Backfill Progress API | jobs 列表 + coverage 时间戳 |
| FR-029 | Data Quality & Freshness SLA | e2e latency histogram + stale alert |
| FR-032 | ExchangeInfo Persistence | 消费 `instruments.changed` + UpsertInstruments |
| FR-038 | taosx Data Retention Lifecycle | DB KEEP + 定时 DELETE |
| FR-044 | Data Compliance & Destruction | data_classification + 合规保留期 + 销毁证明 |

---

### FR-003: natsx Communication（server 侧 Consumer）

根 SPEC FR-003 canonical 定义见 [SPEC.md](../SPEC.md) §7。Server 侧通过 durable consumer + ManualAck 消费，client 侧通过 publisher 发布。

**WHEN** server 启动且 natsx 连接就绪
**THEN** 创建 durable consumer（`durable=binance-server`），订阅 `binance.market.>`，ManualAck 模式

**WHEN** NATS 连接断开后重连
**THEN** durable consumer 自动从上次 Ack 位置恢复

**WHEN** consumer 处理超过 `ack_wait` 仍未 Ack
**THEN** JetStream 自动重投（NakWithDelay），consumer 重新处理；redisx SetNX 幂等过滤重复

**WHEN** server 正常关闭（SIGTERM）
**THEN** 完成当前处理中消息的 Ack 后关闭 consumer，不丢弃 in-flight 消息

### FR-004: At-Least-Once Delivery（server 侧）

根 SPEC FR-004 canonical 定义见 [SPEC.md](../SPEC.md) §7。

**WHEN** server 处理消息成功（redisx + taosx + postgresx + kafkax handoff 全完成）
**THEN** 调用 `msg.Ack()`

**WHEN** server 处理消息失败（任一写入报错）
**THEN** 调用 `msg.NakWithDelay(5s)`，JetStream 重投；达到 MaxDeliver(5) 后进入死信

### FR-005: Idempotent Acceptance + Envelope Validation（server 侧）

根 SPEC FR-005 canonical 定义见 [SPEC.md](../SPEC.md) §7。Client 侧 key 生成见 Client SPEC。

**WHEN** 收到 natsx 消息（`domain_market.MarketFactEnvelope` JSON）
**THEN** 校验 required 字段：product_line、instrument_key、event_type、event_time、idempotency_key、source_metadata
**AND** 产品线不在白名单、event type 未知、event time 无效（零值或未来超阈值）→ ManualNak terminal_validation

**WHEN** 校验通过且 idempotency key 未被接受过
**THEN** `redisx.SetNX(key, payloadHash, 72h)` 原子写入 → 进入存储

**WHEN** key 已存在且 payload hash 一致 → 幂等重复，跳过存储，直接 Ack
**WHEN** key 已存在但 payload hash 冲突 → ManualNak terminal_conflict

### FR-006a/6b/6c/6d/6e: Full-Stack Storage（server 侧）

根 SPEC FR-006a~006e canonical 定义见 [SPEC.md](../SPEC.md) §7。详见根 SPEC WHEN/THEN。Server 侧要点：

- **FR-006a taosx**：WriteBatch 写入 tick/bar/depth 到超级表子表；失败→NakWithDelay
- **FR-006b postgresx**：ON CONFLICT DO UPDATE 幂等 upsert；不可达→不 Ack
- **FR-006c redisx**：热缓存 SET(tick,60s)/SET(depth,5s)；失败→降级不阻塞
- **FR-006d ossx**：ETag 校验后删热数据；先写后删
- **FR-006e taosx Retention**：定时 DELETE + OSS ETag 前置校验 + DB KEEP 365 兜底

### FR-007: Gin Market API（server 侧）

根 SPEC FR-007 canonical 定义见 [SPEC.md](../SPEC.md) §7。详见根 SPEC WHEN/THEN。

### FR-007a: clickhousex Analytics API（server 侧）

根 SPEC FR-007a canonical 定义见 [SPEC.md](../SPEC.md) §7。详见根 SPEC WHEN/THEN。

### FR-008: kafkax Downstream Broadcast（server 侧）

根 SPEC FR-008 canonical 定义见 [SPEC.md](../SPEC.md) §7。

**WHEN** 全部存储写入成功
**THEN** `kafkax.Send(topic="binance.{pl}.{et}.v1", key=symbol)` → handoff 成功后 `msg.Ack()`

**WHEN** kafkax 不可达或失败
**THEN** 重试（最多 3 次，指数退避）；仍失败→NakWithDelay 或 dead-letter

### FR-009: Boundary Enforcement（server 侧）

根 SPEC FR-009 canonical 定义见 [SPEC.md](../SPEC.md) §7。Server 侧 CI gate：禁止 import `internal/client`、`internal/cs`、`module/contracts`、gRPC runtime。

### FR-010: clickhousex OLAP Storage（server 侧）

根 SPEC FR-010 canonical 定义见 [SPEC.md](../SPEC.md) §7。详见根 SPEC WHEN/THEN。

### FR-011: Distributed Coordinator Lock（server 侧）

根 SPEC FR-011 canonical 定义见 [SPEC.md](../SPEC.md) §7。

**WHEN** server 启动
**THEN** `redisx.SetNX(coordinator_lock, instance_id, 30s)` 竞选；成功→启动 ETL+归档；失败→standby 轮询

### 其他根级 FR 的 Server 侧实现锚点

| 根 FR | Server 侧职责 | 详见 |
|-------|-------------|------|
| FR-017 | Gap Detection and Replay | [SPEC.md](../SPEC.md) §7 |
| FR-018 | Archive Manifest and Restore | [SPEC.md](../SPEC.md) §7 |
| FR-025 | Backfill Throttle & Priority | [SPEC.md](../SPEC.md) §7 |
| FR-026 | Daily Reconciliation Job | [SPEC.md](../SPEC.md) §7 |
| FR-027 | Cold Data Rehydration | [SPEC.md](../SPEC.md) §7 |
| FR-028 | Backfill Progress API | [SPEC.md](../SPEC.md) §7 |
| FR-029 | Data Quality & Freshness SLA | [SPEC.md](../SPEC.md) §7 |
| FR-032 | ExchangeInfo Persistence & Scheduled Refresh | [SPEC.md](../SPEC.md) §7 |
| FR-038 | taosx Data Retention Lifecycle | [SPEC.md](../SPEC.md) §7 |
| FR-044 | Data Compliance & Destruction | [SPEC.md](../SPEC.md) §7 |

---

## 8. Business Rules（Server 实现约束）

> **编号规则（v3.8.0 统一）**：所有 BR 使用根 SPEC canonical 编号。本节仅列出 server 侧特有的实现约束，完整 BR 定义见 [根 SPEC](../SPEC.md) §8。

### BR-004: ManualAck 全链路写入后才 Ack（根 BR-004 的 server 侧约束）

**规则**: `msg.Ack()` 必须在 redisx SetNX + taosx + postgresx + `kafkax` handoff 全部成功后才调用。

**约束**: 禁止在校验通过、idempotency 检查后、任何单一存储写入成功时提前 Ack。

**违反时**: 进程崩溃后 JetStream 重投，redisx SetNX 幂等检查防止重复写入 taosx。

### BR-004a: redisx SetNX — 幂等唯一性（根 BR-004 的 server 侧约束）

**规则**: redisx `SetNX(key, payloadHash, TTL)` 必须原子执行，保证 at-most-once 存储语义。

**约束**: idempotency key TTL 默认 72h，可配置；多实例 server 共享同一 Redis 实例。

### BR-004b: ManualAck Only After Durable Processing（根 BR-004 的 server 侧约束）

**规则**: JetStream `msg.Ack()` 必须在 validation、idempotency、durable storage、`kafkax` handoff 全部完成后才能发送。

**约束**: 禁止在 idempotency check 通过但存储或 fanout 未完成时 Ack；失败路径使用 Nak / retry / dead-letter policy。

### BR-004c: Validation Failure → Terminal Reject（根 BR-004 的 server 侧约束）

**规则**: 终端校验失败（terminal_validation）不得进入幂等、存储或 `kafkax` fanout。

### BR-003: Server Must Not Import Client Internals（根 BR-003 的 server 侧约束）

**规则**: server 禁止 import `module/binance/client` 的任何 internal 包或类型。

**约束**: server 与 client 之间仅通过 `natsx` subject + `domain_market.MarketFactEnvelope` JSON 解耦；禁止 `contracts` / gRPC / `internal/cs` bridge。

**违反时**: 编译失败（依赖方向违反 ARCHITECTURE.md 数据域边界）。

### BR-009: Admin Surface Isolation（根 BR-009 的 server 侧约束）

**规则**: Admin 端点只能变更 server-local 状态，禁止修改 client connector、清理或伪造 JetStream consumer state、绕过 idempotency、暴露 secrets、触发交易操作。

---

## 9. Interface Contract

### 9.1 natsx JetStream Consumer

```text
Stream: BINANCE_MARKET
Subjects: binance.market.*.*.v1 (subscription filter: binance.market.>)
Durable: binance-server
Ack policy: ManualAck after validation + idempotency + storage + kafkax handoff
Payload: domain_market.MarketFactEnvelope JSON
```

server 不暴露 gRPC ingest；client 与 server 只通过 `natsx` subject 和 `domain_market.MarketFactEnvelope` JSON 解耦。

### 9.2 Server Output Surfaces

| Surface | 用途 |
|---------|------|
| `taosx` | tick / bar / depth 时序存储 |
| `postgresx` | instrument catalog、审计日志、幂等备份 |
| `redisx` | SetNX 幂等与最新行情热缓存 |
| `kafkax` | `binance.{product_line}.{event_type}.v1` topic fanout |
| `ossx` | 过期行情归档 |
| Gin REST `GET /api/v1/market/*` | `market_data` 主动查询 Binance-specific 行情 |

### 9.3 Gin Admin Routes

```text
GET  /healthz
GET  /readyz
GET  /debug/*
GET  /admin/stats
POST /admin/drain
```

---

## 10. Data Model

### MarketFactEnvelope / ProcessingResult / RejectReason

权威 payload 由 `module/domain_market` 定义。server 只消费 `domain_market.MarketFactEnvelope` JSON，不依赖 `contracts` proto 或 gRPC DTO。

| 类型 | server 侧语义 |
|------|-------------|
| `MarketFactEnvelope` | JetStream input payload；包含 source、product_line、instrument_key、event_type、event_time、received_at、schema_version、payload、sequence、ordering_key、source_metadata |
| `ProcessingResult` | server 内部处理结果；记录 accepted / duplicate / rejected / retryable、storage refs、fanout refs |
| `RejectReason` | 机器可读拒绝原因；用于日志、metrics、dead-letter metadata |

server 必须覆盖 `terminal_validation`、`terminal_conflict`、`retryable_storage`、`retryable_fanout`、`unsupported_product_line`、`quality_rejected` 路径。

---

## 11. Config Schema

> **Canonical source**：Server 完整配置见 [`SPEC.md`](../SPEC.md) §11.2 Server Config（`binance-server.yaml`），含 natsx consumer / redisx / postgresx / taosx / clickhousex / kafkax / ossx / Gin API / observability / backfill 共 10 个子节。以下仅列出 server 特有补充说明。

### Server 特有配置说明

| 配置键 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `nats.consumer.durable` | `string` | `binance-server` | durable consumer 名称；多实例追加 `-{instance_id}` |
| `nats.consumer.ack_wait` | `duration` | `30s` | ManualAck 超时；超时后 JetStream 自动重投，redisx SetNX 幂等检查防重复 |
| `nats.consumer.max_deliver` | `int` | `5` | 最大重投次数（超限进入死信） |
| `nats.consumer.filter_subject` | `string` | `binance.market.>` | 订阅 subject 通配符 |
| `idempotency.store` | `string` | `redis` | 幂等存储类型：redis / memory（测试） |
| `idempotency.ttl` | `duration` | `72h` | 幂等记录保留时间 |
| `storage.taos.database` | `string` | `market_binance` | taosx 时序库名 |
| `fanout.kafkax.topic_prefix` | `string` | `binance` | kafkax topic 前缀 |
| `fanout.retry_max` | `int` | `3` | kafkax 发布失败最大重试次数 |
| `validation.future_time_threshold` | `duration` | `5m` | 未来时间容忍阈值 |
| `api.bind` | `string` | `:8080` | Gin REST API 绑定地址 |
| `admin.bind` | `string` | `:8082` | Gin admin 绑定地址（/healthz /readyz /debug/pprof） |
| `observability.log.level` | `string` | `info` | 日志级别 |

> **字段名规范**：所有 server 配置键使用 `nats.*` / `redis.*` / `postgres.*` / `taos.*` / `clickhouse.*` / `kafka.*` / `oss.*` / `api.*` / `admin.*` / `observability.*` / `idempotency.*` / `storage.*` / `fanout.*` / `validation.*` 前缀，与根 §11.2 canonical 一致。完整配置项、默认值和生产 DDL 契约见根 §11.2。

---

## 12. Error Handling

| 错误 | 触发条件 | 处理方式 | Reject 分类 |
|------|----------|----------|-------------|
| Envelope validation failure | 缺少必填字段或字段无效 | 记录 reject metric，按 policy Ack / dead-letter，不进入幂等检查 | `terminal_validation` |
| Unsupported product_line | product_line 不在白名单 | 记录 reject metric，按 policy Ack / dead-letter | `terminal_validation` |
| Unknown event type | event_type 不在注册表 | 记录 reject metric，按 policy Ack / dead-letter | `terminal_validation` |
| Invalid event time | 零值或未来时间超阈值 | 记录 reject metric，按 policy Ack / dead-letter | `terminal_validation` |
| Idempotency conflict | key 已存在但 payload hash 不匹配 | terminal reject，不写 storage，不 fanout | `terminal_conflict` |
| Durable storage failure | `redisx` / `taosx` / `postgresx` / `ossx` 不可用或写入失败 | `msg.NakWithDelay`，不 Ack，不 finalization SetNX | `retryable_storage` |
| `kafkax` fanout failure | `kafkax` 不可达或发布失败 | retry-first，耗尽后 dead-letter / Nak per policy | `retryable_fanout` |
| NATS redelivery limit exceeded | message 超过最大重投次数 | dead-letter + alert | `retry_exhausted` |

**错误消息格式**: `"binance-server: <operation>: <detail>"`
**错误包装**: 使用 `%w` 保留底层错误链

---

## 13. Edge Cases

| 场景 | 输入/状态 | 预期行为 |
|------|-----------|----------|
| `natsx` reconnect | server 与 NATS 短暂断开后恢复 | durable consumer 从未 Ack message 继续处理；幂等检查避免重复 storage / fanout |
| Duplicate key + conflicting payload | idempotency key 已存在，payload hash 不同 | 记录 `terminal_conflict`；不写 storage；不 fanout；按 policy Ack / dead-letter |
| `kafkax` fanout 失败 | `kafkax` 发布超时或不可达 | retry-first；未完成 fanout 前不得 Ack；耗尽后 dead-letter + alert |
| Idempotency store 满 | Redis 内存或容量限制触发 | Nak / retryable_storage；告警触发 |
| 并发处理同一 key | 多个 delivery 同时处理相同 idempotency key | redisx SetNX 保证仅一个 delivery 获得 accept，另一个 duplicate 或 terminal_conflict |
| Payload 为空 | event_type 正确但 payload 为空 | 取决于 event type schema：若支持空 payload 则通过；否则返回 `terminal_validation` |
| Admin drain 时有活跃 delivery | drain 模式开启，仍有进行中的 message | 停止拉取新 message；等待已接收 message 完成或超时后 Nak |
| `/readyz` 依赖不可用 | NATS / Redis / taosx / kafkax 不可用 | `/readyz` 返回 503 |

---

## 14. Directory Structure

### Documentation (`module/binance/server/`)

```text
module/binance/server/
├── README.md
├── SPEC.md                  # 本文件
├── TRACEABILITY.md
├── IMPLEMENTATION-PLAN.md
└── tasks/                   # Server task spec（9 个）
```

### Runtime（monorepo `github.com/xhyperium/binance/`，server 端目录）

```text
github.com/xhyperium/binance/
├── go.mod
├── go.sum
├── cmd/
│   └── binance-server/main.go      # natsx consumer + storage/API/fanout 进程入口
└── internal/server/
    ├── app/                        # 顶层组装与生命周期
    ├── config/                     # configx 集成
    ├── consumer/                   # natsx durable consumer + message handler
    ├── validation/                 # MarketFactEnvelope 信封校验
    ├── idempotency/                # IdempotencyStore 接口 + memory/redis 实现 + check-and-set
    ├── ack/                        # JetStream Ack/Nak policy
    ├── storage/                    # redisx/taosx/postgresx/ossx persistence adapters
    ├── api/                        # Gin market data REST API
    ├── fanout/                     # kafkax publish path
    ├── admin/                      # Gin admin handler（healthz/readyz/debug/admin/stats/admin/drain）
    ├── observability/              # observex metrics/logging/tracing
    ├── errors.go                   # 公共错误变量
    └── *_test.go                   # 各子目录单元测试 + contract 测试
```

> **monorepo 边界约束**：`internal/server/*` 不得 import `internal/client/*`，对应 BR-003 + BOUNDARY-GATES §4 CI gate。`internal/server` 仅通过 `natsx` subject + `domain_market` envelope 与 client 解耦，禁止 `contracts` / gRPC / `internal/cs` bridge。

---

## 15. Dependencies

### 15.1 允许的依赖

| 依赖 | 用途 | 来源 |
|------|------|------|
| `module/natsx` | JetStream stream、consumer、ManualAck | FoundationX 基座 |
| `module/domain_market` | `MarketFactEnvelope` 与市场领域值对象 | L2.5 领域共享层 |
| `module/redisx` | SetNX 幂等、热缓存 | FoundationX 基座 |
| `module/taosx` | Binance-specific 时序行情存储 | FoundationX 基座 |
| `module/postgresx` | catalog、审计、幂等备份 | FoundationX 基座 |
| `module/ossx` | 归档存储 | FoundationX 基座 |
| `module/kafkax` | 下游 fanout | FoundationX 基座 |
| `github.com/gin-gonic/gin` | Admin HTTP server + Market REST API | 第三方 |
| `configx` | 配置管理 | FoundationX 基座 |
| `observex` | 可观测性集成 | FoundationX 基座 |

### 15.2 禁止的依赖

| 禁止依赖 | 原因 |
|----------|------|
| `module/binance/client` | client 与 server 之间仅通过 natsx/domain_market 通信，禁止 import client internals |
| 任何 exchange connector | exchange 连接由 client 负责，server 不应感知具体交易所 API |
| `module/contracts` 作为 ingest wire dependency | v2 runtime wire 已迁移到 natsx + domain_market，禁止恢复 proto/gRPC ingest |
| `google.golang.org/grpc` 作为 ingest runtime | server 不暴露 gRPC ingest |
| generic `market_data` storage / query platform ownership | Binance server 只拥有 Binance-specific storage/API/fanout，不拥有通用跨交易所平台语义 |
| strategy / risk engine | 决策域模块不应被数据域 server 感知 |

### 15.3 依赖方向

```text
domain_market + natsx
    ↓
binance/server
    ↓
redisx/taosx/postgresx/ossx/kafkax/Gin REST
    ↓
market_data consumers
```

server 不反向依赖 client，二者通过 `natsx` subject + `domain_market` envelope 解耦。

---

## 16. Testing

### 16.1 测试矩阵

> 正式 TC 编号以 `../../matrix/server/TRACEABILITY.md` §4 为准；本表使用 SPEC 场景 ID，避免与追溯矩阵的详细 TC ID 冲突。

| 场景 ID | 对应 FR/BR | 测试类型 | 场景 | 预期结果 |
|---------|------------|----------|------|----------|
| TC-001 | FR-003 | 集成 | natsx durable consumer 订阅 | consumer 绑定 stream/subject/durable 成功 |
| TC-002 | FR-004 | 集成 | 未 Ack message 后进程重启 | JetStream redelivery，server 重新处理 |
| TC-003 | FR-005 | 单元 | 缺少必填字段的 MarketFactEnvelope | 返回 terminal_validation reject，不写 storage/fanout |
| TC-004 | FR-005 | 单元 | 不支持的 product_line | 返回 terminal_validation reject |
| TC-005 | FR-005 | 集成 | 首次 idempotency key | 写入 redisx/taosx/postgresx，完成 kafkax handoff 后 Ack |
| TC-006 | FR-005 | 集成 | 重复 idempotency key（相同 payload） | Ack duplicate，不重复写 storage/fanout |
| TC-007 | FR-005 | 集成 | 重复 idempotency key（冲突 payload） | terminal_conflict reject |
| TC-008 | FR-006a/6b | 集成 | storage write 成功 | Ack 仅在 redisx + taosx + postgresx + kafkax handoff 完成后发送 |
| TC-009 | FR-006a/6b | 集成 | storage write 失败 | Nak，不 finalization SetNX，不 Ack |
| TC-010 | FR-008 | 集成 | kafkax fanout 失败 | retry-first，耗尽后 dead-letter |
| TC-011 | FR-007 | 集成 | GET /api/v1/market/ticks | 返回已持久化 Binance-specific 行情 |
| TC-012 | FR-009 | 静态 | server imports internal/client or internal/cs | CI boundary gate fails |
| TC-013 | FR-009 | 静态 | server imports module/contracts or gRPC ingest runtime | CI boundary gate fails |
| TC-014 | FR-009 | 静态 | go.mod missing direct gin/ossx/natsx/redisx/taosx/postgresx/kafkax dependency | CI dependency gate fails |
| TC-015 | BR-003 | 静态 | boundary scan | 无 client/gRPC/internal-cs import |

### 16.2 契约测试

server 必须通过 consumer contract tests：
- decode `MarketFactEnvelope` fixture
- subject routing 匹配实际消息 subject `binance.market.*.*.v1`（订阅过滤器为 `binance.market.>`）
- Ack only after injected storage/fanout success

### 16.3 测试工具

- 框架：`testing` + `testify`
- Mock：`natsx` / `redisx` / `taosx` / `kafkax` test doubles
- 覆盖率：`go test -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out`
- 竞态：`go test -race -count=1`

---

## 17. Performance Budget

| 操作 | 指标 | 目标 | 测量方式 |
|------|------|------|----------|
| Request validation | 延迟 P99 | < 1ms | benchmark test |
| Idempotency check (memory) | 延迟 P99 | < 0.5ms | benchmark test |
| Idempotency check (redis) | 延迟 P99 | < 5ms | benchmark test |
| Ack/Nak decision | 延迟 P99 | < 0.5ms | benchmark test |
| End-to-end ingest (validate + idempotency + storage + fanout + Ack) | 延迟 P99 | < 25ms | benchmark test |
| Consumer throughput | 吞吐 | ≥ 1000 events/s per instance | `go test -bench` |
| Server RSS memory（steady state，无 backfill） | RSS | ≤ 1GB (P99) | `/debug/vars` runtime.MemStats |
| Server RSS memory（含 backfill peak） | RSS | ≤ 4GB (P99) | `/debug/vars` runtime.MemStats |
| Server E2E contribution（consume→persist） | 延迟 P95 | < 100ms（同区域部署） | 集成 benchmark（FR-029 延迟预算分解） |

> v3.9.0 新增内存预算（1GB steady / 4GB peak）、端到端延迟预算分解（server<100ms P95）。

---

## 18. Observability

### 18.1 Metrics

| 指标名 | 类型 | 说明 |
|--------|------|------|
| `binance_server_consumer_lag` | gauge | durable consumer 未处理 message lag |
| `binance_server_consumed_total` | counter | 累计接收 JetStream message 数 |
| `binance_server_accepted_total` | counter | 累计验收 event 数 |
| `binance_server_duplicate_total` | counter | 累计重复 event 数 |
| `binance_server_rejected_total` | counter | 累计拒绝 event 数（按 reject_class 分组） |
| `binance_server_manual_ack_latency_ms` | histogram | ManualAck 决策端到端延迟 |
| `binance_server_kafkax_dispatch_latency_ms` | histogram | `kafkax` fanout 延迟 |
| `binance_server_kafkax_dispatch_failures_total` | counter | `kafkax` fanout 失败计数 |
| `binance_server_idempotency_store_size` | gauge | 幂等记录数 |

### 18.2 Logging

| 事件 | 级别 | 说明 |
|------|------|------|
| consumer started | info | 含 stream、subject、durable |
| consumer stopped | info | 含 accepted/rejected/duplicate 计数 |
| event accepted | debug | 含 subject、product_line、instrument_key、idempotency_key |
| event rejected | warn | 含 subject、idempotency_key、reject_class、reason |
| duplicate detected | info | 含 subject、idempotency_key |
| kafkax fanout failed | error | 含 subject、idempotency_key、topic、error |
| idempotency store near capacity | warn | 当前条目数 / max_entries |

### 18.3 Required Log Fields

每条 server 日志必须包含：`subject`、`product_line`（如适用）、`instrument_key`（如适用）、`idempotency_key`（如适用）、`processing_status`（如适用）、`reject_reason`（如适用）

---

## 19. Security

- 不硬编码 secret、API key、密码 — 全部从环境变量或 `configx` 读取
- 不在日志中记录敏感数据（secret、token、内部路径）
- Admin 端点不应暴露 secrets 或允许绕过 idempotency
- `natsx` 连接与 HTTP/admin 暴露面在生产环境必须使用 TLS/mTLS 或内网隔离
- 输入校验必须在所有处理之前完成
- 禁止 admin 端点触发交易操作
- 依赖扫描（`gitleaks detect --no-git`）为 CI 门禁

---

## 20. CI Gate

### 20.1 通用 Gate

| Gate | 命令 | 通过条件 |
|------|------|----------|
| 编译 | `go build ./...` | 零错误 |
| 测试 | `go test ./... -race -count=1` | 全部通过 |
| 覆盖率 | `mkdir -p .coverage && go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | ≥ 80% |
| Vet | `go vet ./...` | 零警告 |
| Lint | `golangci-lint run` | 零警告 |
| 依赖 | `go mod tidy && git diff --exit-code` | 无变更 |
| 安全 | `gitleaks detect --no-git` | 零泄露 |
| Benchmark | `go test -bench=. -benchmem` | 在预算内 |

### 20.2 模块专属 Gate

| Gate | 命令 | 通过条件 |
|------|------|----------|
| 契约测试 | `go test -run TestContract ./...` | 全部通过 |
| 无 client import | `go list -deps ./... | grep -q 'binance/client' && exit 1 || exit 0` | 零匹配 |
| 无 legacy ingest runtime | `rg "google.golang.org/grpc|module/contracts|internal/cs" internal/server cmd/binance-server && exit 1 || exit 0` | 零匹配 |
| admin 安全 | `go test -run TestAdminSecurity ./...` | 全部通过 |

---

## 21. Upgrade Compatibility

| 变更类型 | 兼容性 | 迁移方式 |
|----------|--------|----------|
| `MarketFactEnvelope` JSON 新增 optional 字段 | 向后兼容 | server 忽略未知字段或按 schema_version 处理 |
| `MarketFactEnvelope` JSON 删除/重命名字段 | Breaking | `domain_market` schema_version bump + client/server 同步升级 |
| `natsx` subject pattern 变更 | Breaking | 新旧 subject 并行迁移或 major bump |
| Gin REST response schema 变更 | Breaking | API version bump |
| `kafkax` topic contract 变更 | Breaking | topic version bump + downstream consumer migration |
| 新增 Idempotency store backend | 向后兼容 | 通过 config 切换 |
| 新增 admin endpoint | 向后兼容 | 无需迁移 |

遵循 semver：breaking change → major bump；新增功能 → minor bump；修复 → patch bump。

---

## 22. Release DoD

- [ ] 所有 FR-001 ~ FR-009 实现完成
- [ ] `natsx` durable consumer + ManualAck policy 实现完成
- [ ] `MarketFactEnvelope` 请求校验覆盖所有必填字段
- [ ] 幂等验收：首次 accept、重复 ACK、冲突 reject 全部正确
- [ ] durable acceptance 正确：Ack 仅在 storage + `kafkax` handoff 后发送
- [ ] storage/API/`kafkax` surfaces 全部实现
- [ ] Gin admin/API endpoints 全部可用（/healthz, /readyz, /admin/*, /api/v1/market/*）
- [ ] `../../matrix/server/TRACEABILITY.md` §4 的正式 TC 全部编写并通过
- [ ] 覆盖率 ≥ 80%
- [ ] CI Gate 全部通过
- [ ] Performance Budget 达标
- [ ] 不 import `module/binance/client`、`module/contracts`、gRPC runtime 或 `internal/cs`
- [ ] 不拥有 generic `market_data` / strategy 语义；仅实现 Binance-specific storage/API/fanout
- [ ] SPEC.md status 更新为 Implemented

---

## 23. Open Questions

### Blocking（阻塞开发）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-001 | idempotency store 首选实现：in-memory 还是 Redis？ | 已解决：`redisx` SetNX 为生产默认，TTL 72h；`IdempotencyStore` 接口保留 in-memory 实现仅用于本地开发/测试（2026-06-21） | ZoneCNH |
| OQ-002 | `kafkax` fanout 失败策略：retry-first 还是 rollback-first？ | 已解决：retry-first + dead-letter；未完成 storage + fanout 前不 Ack，不使用旧 DownstreamDispatchPort rollback 语义（2026-06-21） | ZoneCNH |
| OQ-003 | runtime wire 是否继续依赖 `module/contracts` proto？ | 已解决：不依赖。root SPEC §9 已选择 `natsx` + `domain_market.MarketFactEnvelope` JSON 作为 v2 wire（2026-06-21） | ZoneCNH |

### Non-blocking（不阻塞开发）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-004 | idempotency store 是否需要支持跨实例共享（Redis cluster）？ | 已解决 (2026-06-17)：见 §7 FR-005 Idempotency Store 后端选择 — Redis 为生产默认（含 Cluster/Sentinel HA 模式），server 应用层无感；多实例共享与跨重启持久化由 Redis 自身能力承担 | ZoneCNH |
| OQ-005 | admin endpoint 是否需要认证（API key / JWT）？ | 已解决 (2026-06-17)：见 §19 Security — v1 默认 loopback-only 无需认证；生产环境通过反向代理（nginx/Caddy）或 mTLS 添加认证；v1.1 可考虑内置 API key（沿用 client OQ-004 决策模式） | ZoneCNH |
| OQ-008 | NATS JetStream 是否由 client/server 内嵌部署？ | 已解决：不内嵌。NATS 是独立部署的平台/基础设施服务；server 只配置 `nats.url` 并创建 durable consumer（2026-06-22） | ZoneCNH |

### Future（未来考虑）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-006 | 是否需要支持批量 ingest（一个 request 含多个 event）以提高吞吐？ | 待评估 | — |
| OQ-007 | 是否需要扩展到非 Binance 交易所的 natsx consumer + storage/API 模板？ | 待评估 | — |

---

## Appendix A: Acceptance Criteria Registry

| AC ID | FR 引用 | 验收标准 | 验证方式 |
|-------|---------|----------|----------|
| AC-001 | FR-003 | `natsx` durable consumer 绑定成功，接收 `binance.market.*.*.v1` message | TC-001 |
| AC-002 | FR-005 | 必填字段缺失返回 terminal_validation reject | TC-003 |
| AC-003 | FR-005 | 首次 idempotency key 通过验收 | TC-005 |
| AC-004 | FR-005 | 重复 key 不产生重复 storage/fanout | TC-006 |
| AC-005 | FR-005 | 冲突 payload 返回 terminal_conflict | TC-007 |
| AC-006 | FR-006a/6b | durable storage 成功后进入 `kafkax` handoff；失败不 Ack | TC-008/TC-009 |
| AC-007 | FR-008 | `kafkax` handoff 成功后才 Ack；失败 retry-first，耗尽后 dead-letter/告警 | TC-010 |
| AC-008 | FR-007 | Gin API 返回已持久化 Binance-specific 行情 | TC-011 |
| AC-009 | FR-009 | server 源码无 `internal/client` / `internal/cs` / `module/contracts` / gRPC ingest runtime import | TC-012/TC-013 |
| AC-010 | FR-009 | go.mod direct deps 包含 gin/ossx/natsx/redisx/taosx/postgresx/kafkax | TC-014 |
| AC-011 | BR-003 | 同进程 cs 与 client internals boundary gate PASS | TC-015 |

## Appendix B: Change History

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-16 | v1.0.0 | 从 12 节格式迁移至 23 节标准格式 | ZoneCNH |
| 2026-06-17 | v1.0.1 | **Repository 字段 monorepo 对齐**：(1) 删除文档头部重复的简版 metadata 区块，全部字段并入 §1 Metadata 表格（消除 Status `Review` vs `Draft` 字段冲突）；(2) Repository 从 `github.com/xhyperium/binance-server`（不存在仓库，违反 CLAUDE.md 模块-仓库强制对应）改为 `github.com/xhyperium/binance`（server/ 子目录），与 root SPEC + RUNTIME-MAPPING + IMPLEMENTATION-PLAN 描述的 monorepo 路线一致；(3) Go Module Path 同步改为 `github.com/xhyperium/binance`（monorepo，server 端通过 `cmd/binance-server` + `internal/server` 提供）；(4) §14 Directory Structure 由独立 `binance-server/` 仓库布局重写为 monorepo `internal/server/` 子目录布局，与 RUNTIME-MAPPING §5 一致 | ZoneCNH |
