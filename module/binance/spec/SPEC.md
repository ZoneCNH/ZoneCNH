# module/binance SPEC

## 1. Metadata

- Status: Approved
- Spec-Version: v3.9.0
- Last-Updated: 2026-06-28 (v3.8.0→v3.9.0: 内容正确性大修 — FR-013 限流模型从「每秒 weight」修正为「每分钟滑动窗口 weight」+ HTTP 418/429 细化退避 + 退避参数补全 + clock skew 单调性/drift rate 检测；FR-017 缺口检测从统一时间间隔法重写为按事件类型分策略（trade_id 序列 / updateId 序列 / bar open_time 序列 / tick 事件驱动）；FR-025 回填限流改为分钟 weight 模型 + P0/P1/P2 三级优先级；FR-029 增加延迟预算分解 + FutureTolerance/clock_skew 独立关系；FR-012 增加 WS ping/pong keepalive + 24h staggered reconnect；FR-016 增加 REST limit 策略 + 左闭右开语义；FR-031 增加 contractType→instrument_subtype 映射；FR-032 增加 symbol 生命周期 + SpecUpdated 轻量 reload；FR-023 增加 evidence 交叉校验规则；FR-036 增加 WS 连接数上限 + stagger；§11 Config Schema 数值修正；§17 Performance Budget 扩展；client 幂等键策略修正；三表状态模型统一为双态模型（Code-Done / Evidence-Done）；2026-06-28 全量 E2E 证据闭合后同步日期)
- Owner: ZoneCNH
- Layer: 数据域 · 行情
- Runtime-Version: v0.2.0
- Runtime-HEAD: `2efc44a` (2026-06-28 full E2E evidence closure；7 external deps live PASS + 4 product lines mainnet live PASS + 14/14 boundary gates PASS)
- Repository: [github.com/ZoneCNH/binance](https://github.com/ZoneCNH/binance)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md), `module/domain_market`, `module/natsx`, `module/redisx`, `module/taosx`, `module/kafkax`, `module/ossx`, `module/postgresx`, `module/clickhousex`

> 子模块规格：`module/binance/client/SPEC.md`、`module/binance/server/SPEC.md`
>
> [COMPUTED, HIGH] 2026-06-28 全量 E2E 证据闭合：GitHub #1267-#1279 全部 `CLOSED`，Beads `ZoneCNH-xzcr*` 全部 `CLOSED`。历史 blocker ledger 记录在 [`../evidence/2026-06-27/review/ISSUE-BLOCKERS-1268-1279.md`](../evidence/2026-06-27/review/ISSUE-BLOCKERS-1268-1279.md)（已被 2026-06-28 闭合推翻）。M1-M4 evidence remains governed by [`../../../docs/governance/CORE-LOOP-MILESTONES.md`](../../../docs/governance/CORE-LOOP-MILESTONES.md).

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

### 4.1 Runtime Distributed Architecture Constraints

以下分布式约束是 **可执行** 的——由 CI boundary gates 验证，任何 runtime 部署不得违反：

| # | 约束 | 强制方式 |
|---|------|---------|
| C1 | Client 和 Server 是 **独立进程**——禁止同进程 wiring、Go interface 直调或共享 in-process state。 | BOUNDARY-GATES §6；`cmd/binance-smoke` 是仅有的本地 self-test 例外。 |
| C2 | Client → Server 通信 **仅通过 natsx JetStream**——禁止 gRPC、HTTP、共享内存或 Go interface 跨边界调用。 | BOUNDARY-GATES §6；SPEC §2 dataflow diagram。 |
| C3 | NATS JetStream 是 **独立部署的基础设施**——`binance-client` 和 `binance-server` 均不内嵌或启动 NATS server。两个进程仅通过配置地址连接。 | SPEC §4；SPEC §2 deployment note。 |
| C4 | `internal/cs`（旧 in-process C/S bridge）**不能**作为任何 client、server 或 cmd package 的 runtime 依赖存在。 | BOUNDARY-GATES §5。 |
| C5 | Client 不得 import server internals (`internal/server`)；Server 不得 import client internals (`internal/client`)。 | BOUNDARY-GATES §3, §4。 |
| C6 | 共享 wire contract 位于 `internal/wire`——canonical 市场语义属于 `domain_market`。 | BOUNDARY-GATES §8。 |

以上约束对任何标记为 "production" 的部署 **不可协商**。`cmd/binance-smoke` 本地 self-test 是 C1 的唯一例外（仅限开发验证）。

### 4.2 Production Readiness Gates

Plan008 historical closeout 只表示当时 release gate 可关闭；它不自动把 FR 投影提升为全 Done。2026-06-27 runtime evidence package `/home/binance/release/evidence/binance/20260627-agent-audit-2/` 记录 `release_closeable=NO`，因为 live websocket、JetStream ack/manualack、external durable storage/fanout/query、remote GitHub Actions 与 release tag 证据未捕获。**2026-06-28 全量 E2E 证据闭合后，上述所有证据均已捕获，release_closeable=YES。** 任何 production-level claim 必须同时满足下列门禁，并在 `TRACEABILITY.md` / `ACCEPTANCE.md` 绑定 runtime SHA、CI run 或可审计 evidence。

| Gate | 生产约束 | 最小证据 |
|------|----------|----------|
| PRG-001 | ClickHouse production DDL 必须使用 `ReplicatedMergeTree`；若采用单节点例外，必须在 release notes 记录原因；market fact / analytics 表必须配置 TTL。 | DDL diff、migration/test output、TTL 验证。 |
| PRG-002 | `kafkax` fanout failure 必须有 retry topic 或 DLQ topic contract；NATS Ack 只能发生在 durable handoff 之后。 | topic/ACL contract、failure-injection evidence、broker e2e 或等价 gated test。 |
| PRG-003 | 新的 production-affecting feature 默认关闭；全量 rollout 前必须完成 feature flag、canary health gate 和 rollback runbook。FR-031~036 全量上线依赖本 gate。 | flag default、canary `/readyz`/error-rate evidence、rollback drill 或 runbook。 |
| PRG-004 | Kafka consumer group、product-line WebSocket 与 API caller 必须有 quota/isolation；单一产品线或调用方故障不得拖垮其他线。 | quota config、resource limit、failure isolation test。 |
| PRG-005 | client→NATS→server→Kafka 必须传播 trace context；未交付时必须在 release notes 标记 Deferred，不能隐式声明可观测性闭合。 | OpenTelemetry span/log evidence 或 explicit deferral。 |
| PRG-006 | 审计日志必须 append-only；NATS、Redis、Postgres、Kafka 的 HA/DR/RPO/RTO 必须有部署文档。 | append-only test、HA/DR/RPO/RTO 文档链接。 |
| PRG-007 | 容量/成本指标、数据分类/保留/销毁证明、credential rotation、stale/gap/DLQ/reconcile runbook 必须可审计。 | metrics/rules/runbook/evidence 链接。 |

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
| 同进程运行 client + server | **违反分布式约束（见 §4 Goals）** |
| 保留 `internal/cs` 同进程桥接包为运行时依赖 | **必须删除** |

---

## 6. Consumers

| 消费者 | 使用方式 | 通信协议 |
|--------|----------|---------|
| `module/market_data` | HTTP `GET /api/v1/market/*` 主动拉取，或 kafkax topic 消费 | HTTP REST / Kafka |
| 下游分析域（signal/risk/backtest） | kafkax consumer group 消费 `binance.{product_line}.{event_type}.v1` topic | Kafka |
| `module/binance/server` | natsx subscribe `binance.market.>` 消费 client 发布的事件 | NATS JetStream |
| Operator / SRE | client :8081 / server :8082 Gin admin 端点 | HTTP |
| Admin API（FR-034~035） | `PATCH /api/v1/admin/symbols/` sync tier 热更新、`POST /api/v1/admin/deadletter/replay` DLQ 重投 | HTTP REST |
| CI Pipeline | BOUNDARY-GATES.md gate 脚本执行边界检查 | — |

---

## 7. Functional Requirements

> **编号规则（v3.8.0 统一）**：所有 FR/BR 使用根 SPEC 单一 canonical 编号空间。Client/Server 子规格通过引用根 FR/BR 编号表达实现归属，不再使用独立本地编号。`(C)` = Client 实现，`(S)` = Server 实现，`(C+S)` = 双方协同。

### FR→部署单元归属矩阵

| FR | 名称 | 归属 | Client 子规格 | Server 子规格 |
|----|------|------|-------------|--------------|
| FR-001 | Product-Line Support | C+S | §7 FR-001 | — |
| FR-002 | Instrument Identity | C+S | §7 FR-002 | — |
| FR-003 | natsx Communication | C+S | §7 FR-009 | §7 FR-003 |
| FR-004 | At-Least-Once Delivery | S | — | §7 FR-004 |
| FR-005 | Idempotent Acceptance | S | FR-006 (key gen) | §7 FR-005 |
| FR-006a | taosx Time-Series Storage | S | — | §7 FR-006a |
| FR-006b | postgresx Metadata Storage | S | — | §7 FR-006b |
| FR-006c | redisx Hot Cache | S | — | §7 FR-006c |
| FR-006d | ossx Archival | S | — | §7 FR-006d |
| FR-006e | taosx Data Retention Lifecycle | S | — | §7 FR-006e |
| FR-007 | Gin Market API | S | — | §7 FR-007 |
| FR-007a | clickhousex Analytics API | S | — | §7 FR-007a |
| FR-008 | kafkax Downstream Broadcast | S | — | §7 FR-008 |
| FR-009 | Boundary Enforcement | C+S | §7 FR-009 | §7 FR-009 |
| FR-010 | clickhousex OLAP Storage | S | — | §7 FR-010 |
| FR-011 | Distributed Coordinator Lock | S | — | §7 FR-011 |
| FR-012 | Stream Session Lifecycle | C | §7 FR-012 | — |
| FR-013 | Exchange Reliability Controls | C | §7 FR-013 | — |
| FR-014 | Runtime Stream Observability | C+S | §7 FR-014 | §7 FR-014 |
| FR-015 | Runtime Pause/Resume/Drain | C+S | §7 FR-015 | §7 FR-015 |
| FR-016 | Historical Backfill Planner | C+S | §7 FR-016 | §7 FR-016 |
| FR-017 | Gap Detection and Replay | S | — | §7 FR-017 |
| FR-018 | Archive Manifest and Restore | S | — | §7 FR-018 |
| FR-019 | Backfill Resource Governance | C | §7 FR-019 | — |
| FR-020 | Funding Rate Event Support | C+S | §7 FR-020 | §7 FR-020 |
| FR-021 | Mark and Index Price Support | C+S | §7 FR-021 | §7 FR-021 |
| FR-022 | Event-Type Governance Matrix | C+S | — | — |
| FR-023 | Release Evidence Bundle | C+S | — | — |
| FR-024 | Runtime Config Hot Reload | C+S | §7 FR-024 | — |
| FR-025 | Backfill Throttle & Priority | C+S | §7 FR-025 | §7 FR-025 |
| FR-026 | Daily Reconciliation Job | S | — | §7 FR-026 |
| FR-027 | Cold Data Rehydration | S | — | §7 FR-027 |
| FR-028 | Backfill Progress API | S | — | §7 FR-028 |
| FR-029 | Data Quality & Freshness SLA | C+S | — | §7 FR-029 |
| FR-030 | Options Chain Raw Field Pass-through | C+S | §7 FR-030 | — |
| FR-031 | ExchangeInfo Discovery (4 Product Lines) | C | — | — |
| FR-032 | ExchangeInfo Persistence & Scheduled Refresh | C+S | — | — |
| FR-033 | Sync Tier Classification | C+S | — | — |
| FR-034 | Selective Sync Whitelist | C | — | — |
| FR-035 | Admin Surface Auth Hardening | C | — | — |
| FR-036 | Tier-Aware Connection Topology | C | — | — |
| FR-037 | Release Safety Net | C+S | — | — |
| FR-038 | taosx Data Retention Lifecycle | S | — | — |
| FR-039 | Distributed Tracing (OpenTelemetry) | C+S | — | — |
| FR-040 | Resource Quota & Isolation | C+S | — | — |
| FR-041 | Audit Log Completeness | C+S | — | — |
| FR-042 | Schema Version Compatibility Policy | C+S | — | — |
| FR-043 | Cost Observability | C+S | — | — |
| FR-044 | Data Compliance & Destruction | S | — | — |

> Client 子规格详见 `client/SPEC.md`，Server 子规格详见 `server/SPEC.md`。子规格中的 §7 以根 FR 编号为 canonical 标题，补充该 FR 在子模块内的 WHEN/THEN 实现细节。

---

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

**WHEN** parser 解析 USDⓈ-M / COIN-M 交割合约（如 `BTCUSDT_240329`、`BTCUSD_240628`）
**THEN** identity 包含 `instrument_subtype=delivery` 维度与非零 `expiry`，与同 product_line 的永续合约（`instrument_subtype=perpetual`、`expiry=null`）产出不同 `InstrumentKey`，且共享 `binance.market.{product_line}.{event_type}` subject，不拆分 subject 订阅

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
**THEN** 调用 `redisx.SET(ctx, "binance:tick:{product_line}:{symbol}", json, 60s)` 更新最新行情热缓存
**AND** 调用 `redisx.SET(ctx, "binance:depth:{product_line}:{symbol}", json, 5s)` 更新深度快照缓存

**WHEN** redisx 缓存写入失败
**THEN** 记录 warn 日志；继续后续管线（缓存失败不阻塞存储——降级到 taosx 直查）

#### FR-006d: ossx Archival

**WHEN** archiver 扫描到超过 retention cutoff 的数据
**THEN** 按 `binance/{product_line}/{symbol}/{YYYY}/{MM}/{DD}/{event_type}.parquet` 写入 `ossx`

**WHEN** `ossx` ETag 校验通过
**THEN** 删除对应 `taosx` 热数据分片

**WHEN** `ossx` 写入或校验失败
**THEN** 保留 `taosx` 热数据并告警；不得删除源数据

#### FR-006e: taosx Data Retention Lifecycle

**功能描述**：对 taosx 热数据执行主动删除生命周期管理。与 FR-006d（OSS 归档）协同——先归档校验通过，后删热数据。对应 Plan008 G6 缺口 + S1/S2 标准化要求。

**WHEN** retention scheduler 触发（默认每日 03:00 UTC，与 OSS 归档错开 1h）
**THEN** 扫描 `taosx` 中超过 retention cutoff 的 tick（30d）、trade（30d）、depth（3d）、bar（90d）
**AND** 逐批校验对应数据已在 OSS 归档且 ETag/ChecksumHex 通过（FR-006d）
**AND** 调用 `taosx.DeleteRange(ctx, table, before)` 删除已验证的热数据分片

**WHEN** OSS 归档未完成或 ETag 校验未通过
**THEN** 跳过该批次删除；保留 taosx 热数据；写入 `binance_reconciliation_alerts` 表告警

**WHEN** taosx DeleteRange 失败
**THEN** 记录 error 日志；写入 alerts 表；下个调度周期自动重试

**WHEN** taosx DB 级 KEEP 配置缺失
**THEN** 启动时通过 `ALTER DATABASE market_binance KEEP 365` 确保 DB 级保留策略（DDL 层兜底）

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

### FR-012: Stream Session Lifecycle

**功能描述**：管理 Binance WebSocket stream 会话的完整生命周期，包括 stream 注册、订阅增删和连接重建，支持运行时动态变更订阅集而不重启 client 进程。

**WHEN** client 启动
**THEN** 从 symbol catalog 加载当前活跃 stream 列表，注册到 active stream registry
**AND** 对每个 product_line 建立 WebSocket 连接并订阅对应 stream

**WHEN** symbol catalog 变更（FR-024 hot reload 触发）
**THEN** 重新加载目标订阅集，并通过 full reconnect/no-restart 边界刷新对应 product_line 连接
**AND** 无需重启 client/server 进程

**WHEN** WebSocket 连接意外断开
**THEN** 按指数退避重连（初始 1s，最大 60s），重连后自动恢复该连接上的所有活跃 subscription

**WHEN** product_line 连接池检测到连接被远端关闭（close frame）
**THEN** 清理该连接上的订阅状态，发起重连；重连期间该 product_line 的订阅标记为 `degraded`

**WHEN** WebSocket 连接处于 active 状态
**THEN** 每 3 分钟期望收到 Binance 服务器 ping 帧，回复 pong 帧
**AND** 若 30s 内未收到 ping → 判定连接僵死 → 主动断开并触发重连
**AND** 递增 `binance_ws_ping_timeout_total` 指标

**WHEN** Binance WebSocket 连接持续存活超过 23h
**THEN** 主动发起 staggered reconnect（在 [0, 30min] 窗口内随机选择重连时间点，避免所有连接同步断连风暴）
**AND** 重连前先建立新连接并完成 SUBSCRIBE，再关闭旧连接（先建后断）

**WHEN** `POST /api/v1/admin/streams` 请求运行时添加或移除订阅
**THEN** 更新 active stream registry，触发 stream diff，无需重启 client 进程
**AND** 变更记录写入 audit_log（FR-041）

> 注：v3.9.0 补充 WS ping/pong keepalive 策略与 24h staggered reconnect。Binance WS 连接约 24h 强制断连，若所有连接同步建立则同步断开产生连接风暴。先建后断（make-before-break）确保订阅连续性。

> 注：Plan006/007 gap — stream 生命周期管理。AC-048~050 / TC-029。

### FR-013: Exchange Reliability Controls

**功能描述**：对 Binance 交易所 WebSocket/REST 连接实施可靠性控制，包括重试预算（含完整指数退避参数）、分钟滑动窗口 weight 限流（对齐 Binance `X-MBX-USED-WEIGHT-1M` 真实机制）、HTTP 429/418 差异化处理、以及含单调性+drift rate 的时钟偏差检测，防止客户端异常行为触发交易所限流或 IP 封禁。

**WHEN** WebSocket 或 REST 请求失败
**THEN** 按重试预算（retry budget）执行指数退避重试，参数如下：
  - `base_delay`: 1s（首次重试等待）
  - `max_delay`: 120s（退避上限）
  - `multiplier`: 2.0（指数因子）
  - `jitter`: ±10%（防 thundering herd）
  - `retry_budget`: 10 tokens（初始预算），refill rate: 1 token/30s
**AND** 每次重试消耗 1 budget token；budget 为 0 时暂停该 product_line 所有连接 60s 并告警
**AND** 以下错误**不可重试**（直接标记 terminal failure）：
  - HTTP 400 Bad Request / 401 Unauthorized / 403 Forbidden / 404 Not Found
  - WebSocket close code 4000-4999（不可恢复协议错误）

**WHEN** client 调用 Binance REST API（如 exchangeInfo、historical klines）
**THEN** 按分钟滑动窗口 weight 预算控制请求速率：每分钟累计 weight 不超过 `max_weight_per_minute`（默认 1200，对齐 Binance 无 API key 的 IP weight 限制）
**AND** 每次 API 调用后解析 HTTP response header：
  - `X-MBX-USED-WEIGHT-1M`：当前分钟窗口已消耗 weight，用于动态感知实际消耗
  - `X-MBX-ORDER-COUNT-1M`：当前分钟订单数（如使用 order 相关 API）
**AND** weight 余额不足时等待至下一个分钟窗口
**AND** 收到 HTTP 429（rate limited）时：
  - 解析 `Retry-After` header（秒数）作为**最小**等待时间
  - 降速至当前速率的 50%（multiplicative decrease）
  - 恢复策略为 AIMD（Additive Increase/Multiplicative Decrease）：每次正常响应后提升 10% 速率，每 30s 最多提升一次
**AND** 收到 HTTP 418（IP banned）时：
  - 触发熔断（circuit breaker）：暂停该 product_line **所有**连接 15 分钟
  - 递增 `binance_ip_ban_total` 指标
  - 发送 CRITICAL 告警（可能需切换出口 IP 或等待手动解封）
  - 熔断恢复后从 10% 速率开始试探

**WHEN** client 收到交易所事件
**THEN** 解析事件时间戳 `E`（event time），与本机时钟比对
**AND** 若偏差 `|event_time - local_time| > clock_skew_threshold`（默认 30s），记录 WARN 日志并上报 `binance_clock_skew_seconds` 指标
**AND** 对同一 product_line 的事件时间戳执行**单调性检测**：若 `event_time < last_event_time`（时钟回拨），立即触发 ALERT_CLOCK_REGRESSION 并暂停该 product_line 消费
**AND** 执行 **drift rate 检测**：若 5 分钟内 clock skew 变化率 > 100ms/min，记录 WARN_CLOCK_DRIFT（NTP 异常或硬件时钟漂移）

**WHEN** 连续 3 分钟 clock skew 超过阈值（而非连续 3 次事件，容忍 NTP 瞬时跳变）
**THEN** 触发 ALERT；暂停该 product_line 消费；等待人工介入

> 注：Plan006/007 gap — exchange reliability controls。AC-051~053 / TC-030。
> [COMPUTED, HIGH] v3.9.0 将限流模型从「每秒 weight」修正为 Binance 实际的「分钟滑动窗口 weight」（`X-MBX-USED-WEIGHT-1M` header），并将退避参数从隐式补全为显式可配置参数表。HTTP 429/418 处理从通用降速细化为差异化策略（429 AIMD 恢复 + 418 熔断）。clock skew 从简单阈值检测增强为单调性+drift rate+时间窗口三重检测。

### FR-014: Runtime Stream Observability

**功能描述**：通过 admin API 和 Prometheus metrics 暴露运行时 stream 状态、消费 lag 和异常原因，支持运维可观测性和故障诊断。

**WHEN** `GET /api/v1/stats/streams` 被调用
**THEN** 返回每个 product_line 的 stream 状态：`connected` / `disconnected` / `degraded` / `paused`

**WHEN** `GET /api/v1/stats/streams/:product_line` 被调用
**THEN** 返回该 product_line 下每条 stream 的详细信息：symbol、event_type、lag（毫秒）、last_event_time、unhealthy_reason（如有）

**WHEN** consumer lag 超过阈值（默认 spot/um/cm 30s，options 60s）
**THEN** 在响应中标记 `unhealthy_reason: "lag_exceeded"` 并递增 Prometheus counter `binance_stream_unhealthy_total`

**WHEN** stream 连接断开
**THEN** 在响应中标记 `unhealthy_reason: "disconnected"` 并记录断开时间戳 `disconnected_at`

**WHEN** `Prometheus /metrics` 被 scrape
**THEN** 暴露以下 stream 指标：`binance_stream_state{product_line,state}` (gauge)、`binance_stream_lag_seconds{product_line,symbol,event_type}` (gauge)、`binance_stream_events_total{product_line,event_type}` (counter)、`binance_stream_reconnects_total{product_line}` (counter)

> 注：Plan006/007 gap — runtime observability。AC-054~056 / TC-031。

### FR-015: Runtime Pause/Resume/Drain

**功能描述**：提供运行时的 stream 暂停、恢复和优雅排空能力，支持运维操作（如交易所维护窗口、数据修复）期间的受控数据流管理，所有操作均生成审计记录。

**WHEN** `POST /api/v1/admin/streams/pause` 被调用（body 含 `product_line` 和可选的 `symbol`、`event_type`）
**THEN** 暂停匹配的 stream 消费：consumer 停止 ACK，暂停写入 storage/fanout 管线
**AND** 记录 pause 事件到 audit_log（actor、timestamp、scope、reason）

**WHEN** stream 处于 paused 状态且 `POST /api/v1/admin/streams/resume` 被调用
**THEN** 恢复消费，consumer 从上次 ACK 位置继续
**AND** 记录 resume 事件到 audit_log

**WHEN** `POST /api/v1/admin/streams/drain` 被调用（body 指定 scope）
**THEN** 进入 drain 模式：停止新消息接收，排空已缓冲消息（完成 storage/fanout），排空后自动进入 `paused` 状态
**AND** 记录 drain 事件到 audit_log，含排空期间处理的消息数量

**WHEN** drain 超时（默认 30s）仍有未排空消息
**THEN** 记录剩余消息数量到 WARN 日志；强制转入 `paused` 状态；生成 drain_timeout 告警

> 注：Plan007 G2/G3 gap — runtime lifecycle control。对应 SPEC §9 Depth subscription tiers。AC-057~059 / TC-032。

### FR-016: Historical Backfill Planner

**功能描述**：对历史数据回填窗口进行规划与验证，包括时间窗口合法性校验、回填游标持久化和区间重叠拒绝，确保回填任务不产生重复数据且可从中断点恢复。

**WHEN** backfill job 被创建（指定 product_line、symbol、event_type、time window `[start, end]`）
**THEN** 校验窗口合法性：`start < end`、`end < now - buffer`（buffer 默认 5min，避免与实时数据重叠）、window span ≤ max_span（默认 7d）
**AND** `start` 和 `end` 按 Binance REST `startTime`/`endTime` 左闭右开语义处理（`[start, end)`）
**AND** 无效窗口返回 `BNC-017`（ErrInvalidBackfillWindow）

**WHEN** backfill job 执行 REST 回填请求
**THEN** 单次请求 `limit` 按 event_type 与 product_line 选择正确值（详见下方 §按 event_type 的回填策略表），减少分页次数
**AND** 根据返回条数判断是否到达窗口末尾：返回条数 < limit → 最后一批 → 更新 cursor = end
**AND** exchangeInfo 定时刷新（FR-031）消耗的 weight 纳入全局限流预算（FR-025），每次刷新预留 weight=20×4product_lines=80 weight/min

**WHEN** backfill job 窗口通过校验
**THEN** 检查是否与已有 active/completed job 窗口重叠
**AND** 若重叠区间 > 0，拒绝创建并返回 `BNC-018`（ErrBackfillWindowOverlap）
**AND** 若通过，持久化 job 到 `postgresx`（`binance_backfill_jobs` 表），status = `pending`

**WHEN** backfill job 执行中且进程重启
**THEN** 从持久化 cursor 恢复：`cursor_event_time` 表示已回填到的时间点，重启后从 cursor 继续

**WHEN** backfill job 完成（cursor 到达 end）
**THEN** 更新 status = `completed`，记录 `completed_at`、`total_events`、`total_bytes`

> **起步时间探测策略（冷启动）**：当 symbol 无历史数据时，使用二分查找探测首根有效 K 线：
> - 下界 = symbol 上市时间，优先从 exchangeInfo `onboardDate` 获取
> - 上界 = 当前时间
> - 二分逼近第一根 volume > 0 的 K 线
> - 探测结果持久化到 `catalog_symbols.first_kline_time`，避免重复探测
> - 若 exchangeInfo 未提供 `onboardDate`，使用可配置保守下界（配置键 `backfill.cold_start_fallback_time`，默认值：spot=2017-07-01, um_perp=2019-09-01, cm_perp=2019-09-01, options=2024-01-01）

#### 按 event_type 的回填策略与起始时间

**WHEN** 冷启动回填被触发（新 symbol `Added` 且 `status=TRADING`，或 admin 手动触发）
**THEN** 按 event_type 分别确定回填策略与起始时间：

| event_type | 可回填 | 起始时间来源 | REST Endpoint | 分页策略 | 说明 |
|-----------|:------:|------------|--------------|---------|------|
| **bar**（K线） | ✅ | `catalog_symbols.first_kline_time`（二分探测） | `/api/v3/klines` `/fapi/v1/klines` `/dapi/v1/klines` | `startTime`/`endTime` + `limit`（spot=1000, futures=1500） | 确定性时间驱动，序列法无假阳性 |
| **trade**（成交） | ✅ | `first_kline_time` 对齐（trade 无独立上市时间，使用 kline 起始） | `/api/v3/aggTrades` `/fapi/v1/aggTrades` `/dapi/v1/aggTrades` | **优先 `fromId` 按 trade_id 分页**（单调递增整数，比 startTime 精确）；冷启动首请求用 `startTime=first_kline_time` 获取首批 trade_id，后续用 `fromId=last_trade_id+1` | `fromId` 分页避免时间窗口内遗漏；startTime 仅用于首请求 |
| **funding_rate** | ✅ | `first_kline_time`（衍生品上线后才有 funding） | `/fapi/v1/fundingRate` `/dapi/v1/fundingRate` | `startTime`/`endTime` + `limit=1000` | 每 8h 一条，回填量小；仅 um_perp/cm_perp 适用 |
| **mark_price** | ✅ | `first_kline_time` | `/fapi/v1/premiumIndexKlines` `/dapi/v1/premiumIndexKlines` | `startTime`/`endTime` + `limit=1500` | premiumIndexKlines 提供 historical mark price |
| **depth**（深度） | ❌ | — | — | — | **不可回填**。depth 是增量更新（U/u updateId 序列），REST 只有全量快照（`GET /api/v3/depth`），无法重建历史增量序列。历史 depth 缺口仅由 FR-017 gap detection 触发快照刷新，不生成 backfill job |
| **tick**（bookTicker） | ❌ | — | — | — | **不可回填**。bookTicker 无 REST historical endpoint，只有实时 WS 推送。历史 tick 缺口不生成 backfill job，仅记录 `binance_tick_gaps` 指标（FR-017） |

**WHEN** depth 或 tick 的 backfill job 被请求创建
**THEN** 拒绝创建并返回 `BNC-019`（ErrBackfillUnsupportedEventType）

**WHEN** 冷启动回填的 event_type 范围需要确定
**THEN** 按 sync_tier 决定冷启动回填的 event_type 集合：
- `L1_core`：bar + trade + funding_rate + mark_price（全量回填）
- `L2_extended`：bar + trade + funding_rate + mark_price
- `L3_full`：bar + trade（不含 funding_rate/mark_price，减少冷启动量）
- `disabled`：不回填
**AND** depth 和 tick 始终不回填（无论 tier）

#### 冷启动→实时切换

**WHEN** 冷启动 backfill job 完成（cursor 到达 `end = now - buffer`）
**THEN** 标记该 (product_line, symbol, event_type) 的 `cold_start_completed = true`
**AND** 若该 symbol 所有可回填 event_type 均完成冷启动 → 标记 symbol `cold_start_completed = true`
**AND** symbol 进入纯实时采集模式（WS 事件经 FR-005 幂等写入，backfill scheduler 不再为该 symbol 创建新 job）
**AND** 若在冷启动期间实时 WS 已在采集（冷启动与实时并行），则冷启动 cursor 到达实时 ingest 的 `latest_event_time` 时提前结束 backfill（避免重叠写入，幂等层兜底）

**WHEN** 冷启动期间实时 WS 事件到达
**THEN** 实时事件正常经 FR-005 幂等写入（不暂停实时采集等待 backfill 完成）
**AND** backfill job 的 `end` 设为 `now - 5min`（buffer），与实时窗口不重叠
**AND** 幂等层（redisx SetNX）保证 backfill 与实时写入同一事件时仅写入一次

#### 探测 weight 预算

**WHEN** `first_kline_time` 二分探测执行
**THEN** 探测的 REST 调用 weight 从 FR-025 `backfill_weight_budget_per_minute` 的 **P2 cold_start** 配额中扣除
**AND** 单次探测最多消耗 `log2((now - lower_bound) / kline_interval)` 次 REST 调用（默认 ≤20 次，spot 1m kline 从 2017-07 至今约 log2(9年/1min) ≈ 22 次）
**AND** 探测 weight 超出单次预算时暂停探测，等待下个分钟窗口继续（探测可中断恢复）

> **REST 分页参数差异**：spot klines limit=1000，futures (um/cm) klines limit=1500。回填 planner 需按 product_line 选择正确的 limit 值，参见 NAMING.md §1 产品线差异表。

> 注：Plan007 A1/G1 gap — 历史回填规划。AC-060~062 / TC-033。

### FR-017: Gap Detection and Replay

**功能描述**：自动检测实时数据流中的数据缺口，**按事件类型使用不同的检测策略**（而非统一时间间隔法），区分真实漏收（`GAP_DATA_MISSING`）与交易所无数据（`GAP_NO_DATA`，如停盘期/低流动性），生成回放作业并保证幂等回放。

**WHEN** gap detector 周期运行（默认每 5 分钟）
**THEN** 按事件类型选择检测策略：

  - **trade**：校验 `trade_id`（Binance aggTrade `a` 字段）序列连续性。`trade_id` 为单调递增整数，若 `trade_id_n - trade_id_{n-1} > 1`，区间 `(trade_id_{n-1}+1, trade_id_n-1)` 为缺口。**禁止用时间间隔检测 trade 缺口**（低流动性 symbol 可能长时间无交易，产生假缺口）。

  - **bar**：校验 `open_time` 序列 = `{start, start+interval, start+2×interval, ..., end}`。缺口 = 期望序列中缺失的 `open_time`。bar 为确定性时间驱动事件，序列法无假阳性。

  - **depth**：校验 `U`（firstUpdateId）和 `u`（lastUpdateId）序列连续性。若新事件的 `U` ≠ 上一事件的 `u + 1`，updateId 出现跳跃 → 快照过期 → 触发 depth snapshot refresh（重新拉取 `GET /api/v3/depth` 全量快照），而非生成 gap replay job。**禁止用时间间隔检测 depth 缺口**（depth 由订单簿变化驱动，无变化时不推送）。

  - **tick**（bookTicker）：记录 `E`（event time）单调性审计。tick 为事件驱动（最佳买卖价变化才推送），时间间隔不可靠。仅记录缺失事件时间戳到 `binance_tick_gaps` 指标，**不触发 ALERT**。

  - **funding_rate**：校验 `fundingTime` 序列覆盖所有结算周期（每 8h）。缺口 = 缺失的结算时间点。

  - **mark_price**：校验 `E` event_time 间隔。若相邻 mark_price 事件间隔 > 10s（正常为 3s），记录缺口。

**WHEN** 缺口被检测到
**THEN** 通过 exchangeInfo `status` 字段判定缺口原因：
  - symbol `status = TRADING` 且 REST 补拉返回非空 → `GAP_DATA_MISSING`（真实漏收，生成 replay job）
  - symbol `status = BREAK/HALT` 或 REST 补拉返回空结果（volume=0 且 `result` 为空数组）→ `GAP_NO_DATA`（停盘期或低流动性，**不生成 replay job**，仅记录审计日志）
**AND** 仅 `GAP_DATA_MISSING` 生成 gap replay job：`{product_line, symbol, event_type, gap_start, gap_end}`
**AND** 通过 redisx `SetNX` 注册 job idempotency key（TTL = gap_end - gap_start + 1h），防止重复生成

**WHEN** gap replay job 执行
**THEN** 调用 Binance historical REST API 回填缺失区间
**AND** 每条回填事件通过 idempotency pipeline（FR-005）写入，保证不产生重复

**WHEN** gap replay job 完成
**THEN** 更新 job status = `completed`；记录 `gap_start`、`gap_end`、`replayed_events`、`gap_type`（MISSING/NO_DATA）到 `binance_gap_replay_log` 表

**WHEN** 连续 3 个检测周期在同一 (product_line, symbol, event_type) 检测到 `GAP_DATA_MISSING`
**THEN** 触发 ALERT（可能为 upstream 数据源问题，非临时抖动）

> 注：Plan008 G2/G3 targets — 缺口检测与回放。AC-063~065 / TC-034。
> [COMPUTED, HIGH] v3.9.0 将缺口检测从统一「时间间隔 > 2× 预期间隔」重写为按事件类型的差异化策略。核心依据：trade 由交易驱动（泊松过程，trade_id 单调递增）、bar 由时间驱动（确定性间隔，open_time 序列）、depth 由订单簿变化驱动（U/u updateId 序列）、tick 由最佳买卖价变化驱动（事件驱动，无固定间隔）。若不区分事件类型，低流动性 symbol 会产生大量假缺口（trade/tick），而真实的 depth updateId 跳跃会被漏检。

### FR-018: Archive Manifest and Restore

**功能描述**：为 OSS 归档数据生成可校验的 manifest，支持从归档恢复重放到 taosx，并通过 retention-delete guard 防止未校验归档被误删。

**WHEN** archiver 完成一个归档批次（按 `{product_line}/{symbol}/{YYYY}/{MM}/{DD}` 分区）
**THEN** 生成 archive manifest JSON：`binance/{product_line}/{symbol}/{YYYY}/{MM}/{DD}/manifest.json`
**AND** manifest 包含：`partition_key`、`event_type`、`file_count`、`total_rows`、`total_bytes`、`ETag` 列表、`checksum_hex` (SHA-256)、`archived_at`

**WHEN** restore 操作被触发（指定 product_line、symbol、date range）
**THEN** 从 OSS 读取对应 manifest 文件，校验 ETag 与 checksum_hex
**AND** 校验通过后从 parquet 文件回放数据到 taosx（通过 WriteBatch）
**AND** 回放过程受 idempotency（FR-005）保护

**WHEN** retention-delete guard 检测到归档 manifest 缺失或 ETag/checksum 不匹配
**THEN** 拒绝删除 taosx 热数据；写入 alerts 表；跳过该批次

**WHEN** manifest 的 checksum_hex 与归档时不一致（数据腐败检测）
**THEN** 标记 manifest status = `corrupted`；触发 CRITICAL 告警；保留该分区所有 OSS 对象

> 注：Plan007/008 gap — archive manifest & restore。AC-066~068 / TC-035。

### FR-019: Backfill Resource Governance

**功能描述**：对回填任务实施资源治理，包括全局并发上限、单 instrument 上限和取消时游标持久化，防止回填风暴耗尽系统资源。

**WHEN** 新 backfill job 尝试启动
**THEN** 检查全局并发 backfill job 数是否超过 `max_concurrent_backfill_jobs`（默认 4）
**AND** 若已满，job 进入 `queued` 状态，等待 slot 释放

**WHEN** 同一 (product_line, symbol) 已有 N 个 running backfill job
**THEN** 若 N ≥ `max_backfill_per_instrument`（默认 2），新 job 进入 `queued` 状态

**WHEN** backfill job 被取消（`POST /api/v1/admin/backfill/cancel`）
**THEN** 持久化当前 cursor_event_time 到 `postgresx`
**AND** 设置 job status = `cancelled`；释放并发 slot

**WHEN** 资源配额配置变更（如调整 `max_concurrent_backfill_jobs`）
**THEN** 新配额对新 job 立即生效；已 running job 不受影响

> 注：Plan007/008 gap — backfill resource governance。AC-069~071 / TC-036。

### FR-020: Funding Rate Event Support

**功能描述**：支持 Binance 资金费率事件（funding_rate）的完整处理链路：事件映射、标准化存储、API 查询和 kafkax 下游分发，与 tick/trade/bar/depth 事件类型平级。

**WHEN** client 收到 Binance WebSocket `markPriceUpdate` 事件（含 `r` funding rate 字段）或 REST `GET /fapi/v1/premiumIndex` / `GET /dapi/v1/premiumIndex`
**THEN** 提取 `fundingRate`、`fundingTime`、`nextFundingTime`、`markPrice`、`indexPrice` 字段
**AND** 映射为 `event_type = "funding_rate"` 的 MarketFactEnvelope

**WHEN** server 收到 `event_type = "funding_rate"` 的 event
**THEN** 写入 taosx 超级表 `binance_funding_rate`（子表 `{product_line}_{symbol}`）、postgresx `binance_funding_rate_history` 表（用于策略查询）
**AND** 通过 kafkax 广播 topic `binance.{product_line}.funding_rate.v1` 给下游分析/决策域消费者

**WHEN** `GET /api/v1/market/funding-rate/:symbol` 被调用
**THEN** 从 postgresx 查询该 symbol 的最新 funding rate + 历史记录

**WHEN** UmPerp / CmPerp 的 funding_rate 事件缺失超过 8h（默认 funding interval 的 1 个周期 + 缓冲）
**THEN** 触发 `binance_funding_rate_stale` 告警

> 注：Plan007 gap — funding_rate 事件支持。AC-072~074 / TC-037。

### FR-021: Mark and Index Price Support

**功能描述**：支持 Binance 标记价格（mark_price）和指数价格（index_price），在 `mark_price` 事件中统一承载，与 tick（`last`/`bid`/`ask`）价格语义严格区分，避免混淆。IndexPrice 作为 `mark_price` 事件的字段保留，不拆分为独立事件类型——Binance `markPriceUpdate` 流同时携带 mark/index/funding 三字段，全量保留于规范视图中。

**WHEN** client 收到 Binance WebSocket `markPriceUpdate` 事件（UM/CM product_line）
**THEN** 提取 `markPrice`、`indexPrice`、`settlementPrice` 字段
**AND** 映射为单一 `event_type = "mark_price"` 的 MarketFactEnvelope，IndexPrice 作为事件字段承载
**AND** event kind 字段设为 `kind = "mark_price"`，与 tick（`last`/`bid`/`ask`）严格区分

**WHEN** server 收到 `event_type = "mark_price"` 的 event
**THEN** 写入 taosx 超级表 `binance_mark_price`（含 `mark_price`、`index_price`、`settlement_price` 列，不与 tick 超级表混写）
**AND** 通过 kafkax 广播 topic `binance.{product_line}.mark_price.v1` 给下游分析/决策域消费者

**WHEN** `GET /api/v1/market/mark-price/:symbol` 被调用
**THEN** 从 taosx `binance_mark_price` 超级表查询该 symbol 的最新 mark_price 值

**WHEN** `GET /api/v1/market/index-price/:symbol` 被调用
**THEN** 从 taosx `binance_mark_price` 超级表查询该 symbol 的最新 index_price 字段值

**WHEN** mark_price 与 last_price 偏差超过阈值（默认 5%）
**THEN** 记录 WARN 日志并递增 `binance_mark_price_divergence_total` 指标（用于潜在清算风险监控）

> 注：Plan007 gap — mark/index price 支持。运行时对齐：`normalize.go parseMarkPrice` 单一 `mark_price` 事件携带 IndexPrice 字段，`mapper.go mapMarkPrice` 全量保留三字段。AC-075~077 / TC-038。

### FR-022: Event-Type Governance Matrix

**功能描述**：建立并维护 event type 治理矩阵，覆盖 4 产品线 × 6 事件类型（tick, trade, depth, bar, funding_rate, mark_price/index_price）× 5 个文档/校验锚点，防止事件类型别名残留和文档漂移。

**WHEN** 新增或修改 event type
**THEN** 更新 governance matrix（R2 matrix：event_type × product_line × applicability）
**AND** 验证至少 5 个锚点一致性：SPEC.md §7 FR 定义、TRACEABILITY.md §1 FR 表、`internal/domain/event_type.go` 常量定义、client connector 的 event mapping、natsx subject 注册

**WHEN** CI boundary gate 运行
**THEN** 执行 stale alias check：grep 全仓找到已废弃的 event type 名称（如 `aggTrade` → 已统一为 `trade`），若存在残留引用 → CI gate 失败

**WHEN** 新增 product_line 支持
**THEN** 更新 event-type governance matrix 中该 product_line 列（至少 4 种 event type 适用），并在 5 个锚点文档中同步

**WHEN** matrix 一致性检查脚本运行（`make event-matrix-check`）
**THEN** 输出 120-cell 矩阵（4 product_lines × ~6 event_types × 5 anchors = 120 cells），不一致 cell 标记为 FAIL

> 注：SPEC G4 缺口 — event-type governance matrix。AC-078~080 / TC-039。

### FR-023: Release Evidence Bundle

**功能描述**：每次 release 生成分层证据包（local / CI / live），确保 release tag、CHANGELOG 和 evidence 三者一致可审计。

**WHEN** 执行 `make evidence`（本地）
**THEN** 运行 `go test ./... -count=1` + `make vet` + `make lint` + `make govulncheck` + `make cover`
**AND** 输出到 `evidence/local/{release_tag}/`，含 test_results.json、vet_output.txt、lint_output.txt、vuln_report.txt、coverage.html

**WHEN** CI workflow 运行
**THEN** 生成 CI evidence：`evidence/ci/{run_id}/`，含 workflow run URL、test/race/cover/lint/vet/govulncheck 各 job 结果、boundary gate 结果
**AND** CI evidence 独立于 local evidence，不可互相替代

**WHEN** release 发布（GitHub Release `v{major}.{minor}.{patch}`）
**THEN** 组装 live evidence：`evidence/live/{release_tag}/`，含 release tag、CHANGELOG.md 片段、CI evidence 引用（run ID + URL）、local evidence SHA
**AND** release gate 校验三者一致性（release tag ↔ CHANGELOG ↔ evidence SHA）

**WHEN** release gate 执行 local vs CI vs live evidence 交叉校验
**THEN** 校验规则：
  - (1) runtime SHA 三者一致（±0 commits）
  - (2) test count 偏差 ≤ 5%（CI 与 local 的 `go test` 用例数差异）
  - (3) boundary gate pass/fail 结果一致（全部 13/13 PASS）
  - (4) 若 CI evidence 不可用（workflow log 过期/被清理）→ 至少需要 local + live 2/3 一致
**AND** 任一校验失败 → release gate HARD-FAIL，阻止发布
**AND** 交叉校验结果写入 `evidence/live/{release_tag}/cross-validation.json`

**WHEN** release gate 检测到不一致（如 CHANGELOG 版本 ≠ release tag）
**THEN** release gate 失败，阻止发布

> 注：Plan007 G7/G8 gap — release evidence bundle。AC-081~083 / TC-040~041。
> 注：v3.9.0 增加 local/CI/live evidence 交叉校验规则（4 项），防止 evidence 过期或局部不一致时发布。

### FR-024: Runtime Config Hot Reload

**功能描述**：支持运行时 symbol catalog 热重载与 full reconnect/no-restart 边界，无需重启 client/server 进程即可响应 symbol 上下架变更。当前覆盖：symbol catalog hot reload；全量 config hot reload（infra 连接、storage 装配等）经评估不推荐。按 tier 的增量 stream add/remove diff 归属 FR-036（ADR-004）。

**WHEN** `POST /api/v1/admin/symbols/reload` 被调用
**THEN** 重新加载 symbol catalog（从 postgresx 或 exchangeInfo REST 拉取最新 symbol 列表）
**AND** 原子替换内存 catalog，计算与旧 catalog 的 diff（added_symbols、removed_symbols、unchanged_symbols）

**WHEN** catalog diff 检测到新增 symbol
**THEN** 重新构建目标 symbol catalog 并通过 full reconnect/no-restart 边界刷新对应 product_line 连接
**AND** 无需重启 client/server 进程

**WHEN** catalog diff 检测到移除 symbol
**THEN** 从目标 catalog 中移除该 symbol，并通过 full reconnect/no-restart 边界刷新对应 product_line 连接
**AND** 不移除历史数据

**WHEN** `POST /api/v1/admin/symbols/reload` 返回 HTTP 200
**THEN** response body 包含 reload 结果：`added_count`、`removed_count`、`unchanged_count`、`reload_duration_ms`
**AND** 变更记录写入 audit_log（FR-041）

**WHEN** catalog reload 失败（postgresx 或 exchangeInfo 不可达）
**THEN** 保留当前 catalog 不变；返回 HTTP 503 + 错误信息；记录 ERROR 日志

> 注：Plan007 A10 gap — runtime config hot reload。全量 config hot reload 经 FR-024 评估不推荐（infra 连接/存储装配热切换复杂度极高、收益低）。维持 symbol catalog hot reload（当前已 Partial 实现）和 full reconnect/no-restart 边界；FR-036 按 ADR-004 自建增量 stream add/remove diff，不依赖 FR-024 升级。评估见 `module/binance/A10-FR024-HOT-RELOAD-EVAL.md`。AC-084~086 / TC-042。

### FR-025: Backfill Throttle & Priority

**功能描述**：对回填任务实施基于分钟 weight 预算的加权限流，按三级优先级（P0 实时 > P1 repair > P2 cold_start）调度执行，确保实时数据流和缺口修复不受首次历史回填冲击。

**WHEN** backfill job 从 `queued` 进入 `running`
**THEN** 按分钟 weight 预算控制回填请求速率：每分钟累计 weight 不超过 `backfill_weight_budget_per_minute`（默认 800，留出 400 weight/min 给实时 WS/REST 开销）
**AND** 每次 Binance REST API 调用消耗对应 endpoint 的 weight（klines weight=2, aggTrades weight=2, exchangeInfo weight=20）
**AND** weight 余额通过 `X-MBX-USED-WEIGHT-1M` header 动态校验；余额不足时等待至下个分钟窗口

**WHEN** 多个 backfill job 并发竞争 weight 预算
**THEN** 按三级优先级调度（高优先级可抢占低优先级未使用的 weight）：
  - **P0 实时**（30% 预留）：exchangeInfo 定时刷新、gap detection 触发的 REST 补拉、WebSocket 降级 REST 轮询。P0 未使用的 weight 可被 P1/P2 借用
  - **P1 repair**（20%）：gap-fill replay jobs、每日对账触发的补拉。实时延迟超阈值时 P1 不受影响
  - **P2 cold_start**（50%）：首次历史回填。实时延迟超阈值时 P2 refill rate 自动降为 0
**AND** 同级内按 FIFO 顺序消费

**WHEN** `binance_backfill_weight_used` 连续 3 分钟达到 budget 的 95%
**THEN** 递增 `binance_backfill_throttle_active_total` 指标，提示回填需求超过配置容量

**WHEN** 实时数据流（FR-004）的延迟 P99 超过阈值（默认 1s）
**THEN** 自动将 P2 cold_start weight refill rate 降为 0（暂停非紧急回填，保障实时链路）
**AND** P1 repair 不受影响（缺口修复仍可进行）
**AND** 实时延迟恢复到阈值以下 5 分钟后，P2 以 50% budget 逐步恢复

> 注：Plan008 G2/G3 backfill throttle extension。AC-087~089 / TC-043。
> [COMPUTED, HIGH] v3.9.0 将回填限流从「20 req/s token bucket」改为分钟 weight 预算模型（`backfill_weight_budget_per_minute: 800`），并对齐 Binance endpoint weight 体系（klines=2, aggTrades=2, exchangeInfo=20）。优先级从 80/20 二维改为 P0/P1/P2 三级，实时链路预留 30% weight 且可借用给低优先级。P2 在实时延迟超阈值时降为 0（不影响 P1 repair）。

### FR-026: Daily Reconciliation Job

**功能描述**：每日 04:00 UTC 执行数据对账作业，比对 Binance 交易所官方数据与本地存储的数据量，检测数据缺失或异常。

**WHEN** cron scheduler 触发 daily reconciliation（默认 04:00 UTC）
**THEN** 对每个活跃 symbol，比对以下维度：(1) tick 数量（event_type=tick，当日 00:00-当前）；(2) trade 数量；(3) 预期 bar 数量（24h × 60 / interval_minutes）

**WHEN** reconciliation 比对完成
**THEN** 计算差异率：`|local_count - expected_count| / expected_count`
**AND** 若差异率 > tolerance 阈值（默认 tick 5%、trade 5%、bar 1%），写入 `binance_reconciliation_alerts` 表（symbol、metric、expected、actual、diff_pct、checked_at）

**WHEN** reconciliation job 执行失败（如交易所 API 不可达）
**THEN** 记录 ERROR 日志；2h 后自动重试；连续 3 次失败触发 ALERT

**WHEN** reconciliation alerts 表有新增记录
**THEN** 生成 reconciliation report（每个 product_line 的差异摘要），通过 metric `binance_reconciliation_diff_ratio` 暴露

> 注：Plan008 G5 gap — daily reconciliation。AC-090~092 / TC-044。

### FR-027: Cold Data Rehydration

**功能描述**：支持从 OSS 冷存储将历史数据回热到 taosx 热存储，通过专用的 202 job_id 追踪，回热数据设有 24h TTL 自动过期。

**WHEN** cold data rehydration 请求被创建（指定 product_line、symbol、date range）
**THEN** 生成 `job_id = 202` 前缀的 rehydration job（如 `202_btcusdt_20260601_20260607`）
**AND** 写入 `binance_rehydration_jobs` 表，status = `pending`

**WHEN** rehydration job 执行
**THEN** 从 OSS 读取指定 date range 的 parquet 文件，校验 manifest 完整性（FR-018）
**AND** 通过 `taosx.WriteBatch` 写入 taosx 的 `binance_rehydrated` 超级表
**AND** 写入时附加 `rehydration_job_id` tag 和 `rehydrated_at` 时间戳

**WHEN** rehydration 数据写入 taosx 成功
**THEN** 设置 24h TTL（通过 taosx `TTL` 属性或定时 cleanup job）
**AND** 24h 后自动删除回热数据（避免长期占用热存储）

**WHEN** rehydration job 失败
**THEN** 记录失败 stage + error message 到 job 记录；支持手动重试（`POST /api/v1/admin/rehydrate/{job_id}/retry`）

> 注：Plan008 G9 gap — cold data rehydration。AC-093~095 / TC-045。

### FR-028: Backfill Progress API

**功能描述**：提供回填任务进度查询 API，包括作业列表、覆盖时间戳和诊断字段，支持运维和下游消费者了解历史数据完整性。

**WHEN** `GET /api/v1/admin/backfill/jobs` 被调用
**THEN** 返回回填 job 列表（支持 `?status=running|completed|failed|cancelled|queued`、`?product_line=`、`?symbol=` 过滤）
**AND** 每个 job 包含：`job_id`、`product_line`、`symbol`、`event_type`、`window_start`、`window_end`、`cursor_event_time`、`status`、`total_events`、`error_message`（如有）、`created_at`、`updated_at`

**WHEN** `GET /api/v1/admin/backfill/coverage` 被调用
**THEN** 返回每个 (product_line, symbol, event_type) 的覆盖时间戳：`earliest_event_time`、`latest_event_time`、`backfill_in_progress` (bool)、`gaps_count`
**AND** 覆盖信息从 taosx 和 `binance_backfill_jobs` 表联合推导

**WHEN** `GET /api/v1/admin/backfill/jobs/:job_id/diagnostics` 被调用
**THEN** 返回该 job 的诊断字段：API call count、rate_limit_hit_count、retry_count、avg_latency_ms、weight_budget_wait_ms

> 注：Plan008 backfill observability extension。AC-096~098 / TC-046。

### FR-029: Data Quality & Freshness SLA

**功能描述**：定义端到端数据新鲜度 SLA 与质量监控，包括 event_time 到 persist/fanout 的延迟阈值、按 product_line 的 stale 告警策略和 schema drift 自动检测。

**WHEN** 实时 event 完成 storage 写入和 kafkax handoff
**THEN** 计算端到端延迟：`now() - event.event_time`
**AND** 暴露 Prometheus histogram `binance_e2e_latency_seconds{product_line, event_type}`

**WHEN** e2e latency 超过 stale 阈值
**THEN** spot/um/cm product_line：P50 > 30s → WARN、P99 > 60s → ALERT
**AND** options product_line：P50 > 60s → WARN、P99 > 120s → ALERT
**AND** 对外承诺（SLA）：spot trade/bookTicker freshness P95 ≤ 500ms / P99 ≤ 2s；um/cm_perp trade P95 ≤ 500ms / P99 ≤ 2s；kline P95 ≤ 1 interval / P99 ≤ 2 interval；depth P95 ≤ 200ms / P99 ≤ 1s。Freshness = `LocalReceiveTime − EventTime`

**WHEN** 单 symbol 5min 无事件
**THEN** 触发该 symbol stale 告警；`stream_active` 突降 → 流中断告警；`binance_event_stale_total` rate > 1% → 数据延迟告警

**WHEN** freshness SLO 连续 3 个 scrape interval 不达标
**THEN** 触发 CRITICAL 告警 `BinanceDataFreshnessSLOBreach`；通知 on-call

**WHEN** e2e latency 分层诊断
**THEN** 端到端延迟预算分解（P95，同区域部署）：
  - Client: receive→normalize→map→publish < 50ms
  - NATS JetStream: publish→deliver < 10ms
  - Server: consume→validate→idempotency→store→fanout < 100ms
**AND** 部署跨区域时各段预算按网络延迟比例调整（不作为 SLA 承诺）

**WHEN** `binance_e2e_latency_seconds` histogram 暴露
**THEN** bucket 定义：`[0.01, 0.05, 0.1, 0.2, 0.5, 1, 2, 5, 10, 30, 60]`（覆盖 10ms-60s）
**AND** 每个 bucket 带 `product_line`、`event_type`、`stage`（client/nats/server）标签

> 注：v3.9.0 增加端到端延迟预算分层（client <50ms / NATS <10ms / server <100ms P95）和 histogram bucket 定义。`FutureTolerance=5s`（FR-029 §3 DATA-QUALITY-SLA 中定义）与 `clock_skew_threshold=30s`（FR-013）独立运作：FutureTolerance 触发 WARN（数据质量问题，可能因交易所时钟漂移），clock_skew_threshold 触发 ALERT+暂停消费（本地时钟可能异常）。两者不互相抑制。

**WHEN** schema drift detector 运行（默认每小时）
**THEN** 对比当前 taosx 超级表 schema 与 SPEC §11 DDL 契约
**AND** 检测新增/删除/类型变更列；差异记录到 `binance_schema_drift_log` 表
**AND** 若检测到 BREAKING 变更（列类型变更、列删除），触发 ALERT

**WHEN** 事件内容校验失败（如必填字段缺失、event_type 未知、数值越界）
**THEN** 记录到 `binance_data_quality_errors` 表（event_id、error_type、field、raw_value、timestamp）
**AND** 递增 Prometheus counter `binance_dq_errors_total{product_line, error_type}`

**WHEN** 事件通过 envelope 校验后、写入 storage 前
**THEN** 执行 per-event-type 字段级校验（校验失败**不阻塞 pipeline**，标记+指标，非拒绝）：

| event_type | 校验规则 | error_type（违反时） |
|-----------|---------|---------------------|
| **bar**（K 线） | `low ≤ open ≤ high` AND `low ≤ close ≤ high` AND `volume ≥ 0` AND `quote_volume ≥ 0` | `field_validation_ohlc` / `field_validation_volume` |
| **trade**（成交） | `price > 0` AND `quantity > 0` AND `trade_id` 单调递增（仅同一 symbol 内） | `field_validation_price` / `field_validation_qty` / `field_validation_trade_id` |
| **depth**（深度） | 每个档位 `bid_price < ask_price`（最近 bid 和最近 ask 比较）AND `quantity > 0` | `field_validation_depth_cross` / `field_validation_depth_qty` |
| **tick**（bookTicker） | `bid_price < ask_price` AND `bid_qty ≥ 0` AND `ask_qty ≥ 0` | `field_validation_tick_cross` / `field_validation_tick_qty` |
| **funding_rate** | `-1.0 ≤ rate ≤ 1.0`（通常 `|rate| < 0.05`；极端行情放宽至 ±1.0） | `field_validation_funding_rate` |
| **mark_price** | `price > 0` AND `|mark_price - last_price| / last_price ≤ 0.05`（偏离 > 5%→WARN，不拒绝） | `field_validation_mark_price` |
| **全部** | 时间戳非零值、非未来（超过 `FutureTolerance=5s`→标记 `field_validation_future_ts`） | `field_validation_future_ts` |

**AND** 校验失败事件仍写入 taosx（保留原始值），同时写入 `binance_data_quality_errors`（额外标记 `retained=true`）
**AND** 同一 `(symbol, event_type, field)` 错误率 > 1% 时触发 WARN 告警

> 注：v3.9.0 补充 per-event-type 字段级校验规则。校验为软约束（标记+告警，非拒绝），确保异常数据可追溯但不阻塞 pipeline。OHLC 关系、bid/ask 交叉、funding_rate 范围等为交易所数据的基本完整性检查。trade_id 单调性在 FR-017 gap detection 中已有序列检测，此处补充为字段级单事件校验。

> 注：Plan008 G1/G4/S8 gap — data quality & freshness SLA。AC-099~101 / TC-047。

### FR-030: Options Chain Raw Field Pass-through

**功能描述**：对 Binance Options 合约的原始字段实施透传策略——Options 特有的 Greeks 风险指标（delta、gamma、theta、vega、impliedVolatility）和其他链上字段原样保留并存入存储，由下游分析域负责衍生计算和解释。

**WHEN** client 收到 Binance Options WebSocket 事件（如 `option_ticker`、`option_depth`、`option_trade`）
**THEN** 解析全部原始字段，不做字段裁剪
**AND** Options 特有字段（`delta`、`gamma`、`theta`、`vega`、`impliedVolatility`、`openInterest`、`strikePrice`、`optionType`、`expiryDate`、`underlying`）原样保留在 MarketFactEnvelope 的 `raw_fields` map 中

**WHEN** server 写入 Options event 到 taosx
**THEN** `raw_fields` 以 JSONB 列存储到超级表 `binance_options_tick` / `binance_options_depth`
**AND** 标准字段（symbol、price、volume、event_time 等）按统一定义存储

**WHEN** `GET /api/v1/market/options/:symbol/greeks` 被调用
**THEN** 从 taosx 读取 `raw_fields` JSONB 列，提取 Greeks 字段返回
**AND** 不在此 API 层做 Greeks 衍生计算（衍生计算归分析域 `strategyx` / `factorx` 负责）

**WHEN** `raw_fields` 中 Options 特有字段结构变更（Binance API 升级）
**THEN** 透传层不做字段映射转换，新字段自动出现在 `raw_fields` 中
**AND** 通过 schema drift detection（FR-029）记录字段变更，通知分析域消费者

> 注：Plan007 A7 gap — Options raw field pass-through。Greeks 归分析域负责，透传层不做衍生计算。AC-102~104 / TC-048~049。

### FR-031: ExchangeInfo Discovery (4 Product Lines)

**功能描述**：Client 负责四产品线 exchangeInfo 发现，通过 REST 拉取 Binance 官方 symbol 目录并发布给 Server。

**WHEN** client 进程启动且 exchangeInfo 功能启用
**THEN** client 应分别拉取四产品线的 exchangeInfo endpoint，解析为 `CatalogEntry` 列表，并通过 `binance.control.instruments.changed` 发布给 server

**产品线 → endpoint 映射**：

| ProductLine | REST Endpoint | Status 字段 | Symbol 数组字段 | 备注 |
|-------------|--------------|------------|----------------|------|
| `spot` | `api.binance.com/api/v3/exchangeInfo` | `status`（`TRADING`） | `symbols` | 已有实现 |
| `um_perp` | `fapi.binance.com/fapi/v1/exchangeInfo` | `status`（`TRADING`） | `symbols` | **新增** |
| `cm_perp` | `dapi.binance.com/dapi/v1/exchangeInfo` | **`contractStatus`**（`TRADING`） | `symbols` | **API 陷阱**：字段名非 `status` |
| `options` | **`eapi.binance.com/eapi/v1/exchangeInfo`** | `status`（`TRADING`） | **`optionSymbols`** | **API 陷阱**：endpoint 非 `vapi`，数组非 `symbols` |

**WHEN** client 解析 exchangeInfo
**THEN** 每个 CatalogEntry 应提取：ProductLine、InstrumentType、InstrumentSubtype、Symbol、InstrumentKey、BaseAsset、QuoteAsset、Status、ContractType、ExpiryDate、StrikePrice、OptionType、PricePrecision、QtyPrecision、MinQty、MaxQty、TickSize、Filters(raw JSONB)
**AND** UM/CM futures 解析 `contractType` 字段映射到 `instrument_subtype`：
  - `PERPETUAL` → `perpetual`
  - `CURRENT_QUARTER` / `NEXT_QUARTER` → `delivery`
  - 未知值 → `delivery`（保守默认）
**AND** COIN-M 解析器正确读取 `contractStatus` 字段（非 `status`）
**AND** Options 解析器正确读取 `optionSymbols` 数组（非 `symbols`），endpoint 为 `eapi.binance.com`，并提取 `quoteAsset`（稳定币如 USDT）作为 Options Instrument Identity 的额外维度

**WHEN** 四产品线发现完成
**THEN** 结果通过 `binance.control.instruments.changed` 发布，payload 为 `InstrumentsChangedPayload{ ProductLine, SnapshotID, Added[], Removed[], Updated[] }`
**AND** client 等待 natsx PubAck

### FR-032: ExchangeInfo Persistence & Scheduled Refresh

**功能描述**：Server 消费 `instruments.changed` 并落库；Client 定时刷新并 diff-only 发布。

**WHEN** server 消费 `binance.control.instruments.changed`
**THEN** server 应将 diff 中的 Added/Updated 条目 upsert 进 postgresx `catalog_symbols`，Removed 条目标记 `status='delisted'`（不物理删除，保留历史）
**AND** `catalog_exchange_info_snapshots` 表记录每次刷新的 `snapshot_id`（ULID）、`product_line`、`symbol_count`、`diff_summary(JSONB)`、`refreshed_at`

**WHEN** client 进程运行中
**THEN** client 每 `FOUNDATIONX_BINANCE_EXCHANGE_INFO_REFRESH_INTERVAL`（默认 `6h`）重新拉取四产品线 exchangeInfo，与本地 catalog 做 diff
**AND** **仅在发现变更时**发布 `instruments.changed`（diff-only，避免无效 PubAck 风暴）
**AND** diff 为空时**不发布** natsx 消息（`added==0 && removed==0 && updated==0` → skip publish）

**WHEN** server 启动
**THEN** 通过 `AddStream` 声明 control stream，subject 涵盖 `binance.control.>`，storage=File，**retention=LimitsPolicy**（非 WorkQueue，multi-server 广播语义）

**WHEN** diff 引擎 `DiffCatalog(prev, next []CatalogEntry)` 运行
**THEN** 基于复合键 `product_line:symbol` 计算三类变更
**AND** `Updated` 判定收窄到采集决策字段：仅当 `status`/`sync_tier`/`base_asset`/`quote_asset`/`expiry_date` 变化时计为 Updated，触发 catalog reload
**AND** `filters`(JSONB) 中 `tickSize`/`stepSize`/`minQty`/`maxQty` 变更计为 `SpecUpdated_LightReload`：触发轻量 reload（更新 DB 字段 + redisx hot cache 失效，不重建 WS 连接）
**AND** 其余 `filters`/`min_qty`/`tick_size` 等合约规格字段变化计为 `SpecUpdated`（仅更新 DB 字段，不触发任何 reload）

**WHEN** exchangeInfo 刷新检测到 symbol status 变更
**THEN** 按生命周期规则处理：
  - `TRADING` → `BREAK`/`HALT`：暂停该 symbol 的 gap detection 告警、暂停对账差异告警、维持历史数据；若 status 持续 BREAK/HALT 超过 `inactive_threshold`（默认 7d）→ 关闭 WS 订阅
  - `BREAK`/`HALT` → `TRADING`：恢复 gap detection 和对账（从恢复时刻开始，不回补停盘期间）
  - 任意状态 → `DELISTED`：停止 WS 订阅、停止 REST 补拉、标记 `status='delisted'` 保留历史数据（不物理删除）、移除 gap detection 覆盖范围；DELISTED 持续超过 30d → 归档到 OSS 冷存储并从 active catalog 移除
  - 新 symbol（`Added`）且 `status=TRADING`：自动纳入采集（按 sync_tier 规则），触发冷启动回填（event_type 范围按 FR-016 §冷启动回填 event_type 集合，depth/tick 不回填）

**WHEN** client 收到 `instruments.changed` 后
**THEN** 优先调用 `Catalog.Reload(fullNext)` 原子替换（非逐条 Add），确保 stream manager 看到一致快照
**AND** `life.SyncCatalog` 在 Reload 之后调用以刷新 lifecycle 投影

### FR-033: Sync Tier Classification

**功能描述**：对 symbol 进行 sync_tier 分级（分类层，不含连接拓扑——连接拓扑见 FR-036）。

**WHEN** 一个 symbol 被写入 `catalog_symbols`
**THEN** 它应被赋予 `sync_tier ∈ {L1_core, L2_extended, L3_full, disabled}`，默认 `disabled`（安全默认：未显式分级不同步）

| sync_tier | 意图流类型（spot/um/cm） | 意图流类型（options） | backfill 优先级 | 适用场景 |
|-----------|------------------------|---------------------|----------------|---------|
| `L1_core` | trade + bookTicker + kline_1m + depth20@100ms | optionTicker（全量 Greeks） | P0 cold_start | 主流高流动性（BTC/ETH/...） |
| `L2_extended` | trade + kline_1m + bookTicker | optionTicker | P1 cold_start | 中等流动性 top-N |
| `L3_full` | trade + kline_1m | optionTicker | P2 cold_start | 长尾低流动性 |
| `disabled` | 无 | 无 | 不 backfill | 未分级 / 已 deny |

> options 仅有 `@optionTicker` 流（含 Greeks delta/gamma/theta/vega），没有 depth/bookTicker/kline 流。因此 options 的 tier 差异化不体现在流类型，而体现在「该 options symbol 是否采集」+ backfill 优先级。

**WHEN** 查询 tier 内 symbol
**THEN** `Catalog` 新增 `SymbolsByTier(productLine, tier string) []CatalogEntry` 方法
**AND** 保留现有 `ActiveSymbols(productLine)` 不变（向后兼容）

**WHEN** 新增 symbol
**THEN** 默认 `sync_tier='disabled'`，必须显式分级（手动或 API）才进入采集

**WHEN** admin API `PATCH /api/v1/admin/symbols/{product_line}/{symbol}` 被调用
**THEN** 支持热更新 `sync_tier`，触发 stream drain/rebuild（FR-024 负责 catalog reload；FR-036 按 ADR-004 自建增量 diff 并调整连接拓扑）

### FR-034: Selective Sync Whitelist

**功能描述**：通过 product_lines / symbols.allow / symbols.deny 配置实现选择性同步。

**WHEN** client 启动或 admin reload 触发 catalog 刷新
**THEN** 最终采集决策按以下优先级裁决（deny 永远赢）：

```
finalDecision(product_line, symbol) =
  if (symbol ∈ config.symbols.deny)                       → disabled   # deny 永远赢
  elif (config.symbols.allow != [] && symbol ∉ allow)     → disabled   # allow 非空时是白名单
  elif (symbol.status != 'TRADING' && status != 'active') → disabled   # 非 TRADING 不采
  elif (product_line ∉ config.product_lines)              → disabled   # 产品线未启用
  else                                                    → DB.sync_tier
```

**配置字段**（落地 §11.1）：

| Env Var | Config 字段 | 默认 | 语义 |
|---------|------------|------|------|
| `FOUNDATIONX_BINANCE_PRODUCT_LINES` | `ProductLines []string` | `[]`（=全部四线） | 启用的产品线，空=全部 |
| `FOUNDATIONX_BINANCE_SYMBOLS_ALLOW` | `SymbolsAllow []string` | `[]` | 白名单 symbol，空=tier 内全部 |
| `FOUNDATIONX_BINANCE_SYMBOLS_DENY` | `SymbolsDeny []string` | `[]` | 黑名单 symbol（deny 永远赢） |

**WHEN** `POST /api/v1/admin/symbols/reload` 被调用
**THEN** 接受新字段 `sync_tier`，reload 后立即应用白名单过滤

### FR-035: Admin Surface Auth Hardening

**功能描述**：对 client admin 写操作端点实施 Bearer token 鉴权。

**WHEN** client `AdminServer` 收到 `/api/v1/admin/*` 写请求（POST/PATCH/DELETE）
**THEN** 应校验 `Authorization: Bearer <token>`，token 从 `FOUNDATIONX_BINANCE_ADMIN_TOKEN` 读取
**AND** 空 token 时**仅允许 localhost**（`127.0.0.1`/`::1`），拒绝远程写请求
**AND** 正确 token 放行、错误 token 返回 401、缺失 token 远程→403
**AND** `GET /healthz`、`GET /readyz`、`GET /api/v1/admin/streams`（只读）不受鉴权影响
**AND** 所有鉴权失败（401/403）写入 `audit_log`（action='admin_auth_denied'）

### FR-036: Tier-Aware Connection Topology

**功能描述**：Stream manager 按 (productLine, tier) 分组建立独立 WS 连接，不同 tier 的 symbol 不混入同一连接。

> **ADR-004 裁决**：FR-036 自建增量 stream add/remove diff，不依赖 FR-024 升级。FR-024 保持 catalog reload + full reconnect/no-restart 边界；tier 升降级由 FR-036 stream manager 维护 activeStreams/desiredStreams 并执行 drain/unsubscribe。

**WHEN** client 的 stream manager 为某 productLine 构建 WS 连接
**THEN** 应按 sync_tier 分组，每组使用该 tier 对应的流组合建立独立 WS 连接（或连接池）

**tier × productLine → 流组合映射**（`StreamsForProductLineTier`）：

| productLine | tier | 流组合 | 连接分组 |
|-------------|------|--------|---------|
| spot/um_perp/cm_perp | L1_core | trade + bookTicker + kline_1m + depth20@100ms | conn_group_L1 |
| spot/um_perp/cm_perp | L2_extended | trade + kline_1m + bookTicker | conn_group_L2 |
| spot/um_perp/cm_perp | L3_full | trade + kline_1m | conn_group_L3 |
| options | L1_core / L2_extended / L3_full | optionTicker（统一流） | conn_group_opt（按 symbol 数分批） |
| 任意 | disabled | 无 | 不连接 |

> options 仅有 `@optionTicker` 单一流类型，tier 差异化仅控制「是否采集」+ backfill 优先级。

**WHEN** tier 降级（L1→L3）
**THEN** 旧连接先 drain（FR-004 NakWithDelay + DLQ）再 unsubscribe
**AND** tier 升级（L3→L1）时新连接异步建立不阻塞现有采集

**WHEN** 连接分批（绕过单连接 1024 stream 上限）
**THEN** 当某 `(productLine, tier)` 组的 symbol 数超过 `floor(1024 / len(streams))` 时，拆分为多个 WS 连接
**AND** 每个 product_line 的 WS 连接总数不超过 `max_ws_connections_per_product_line`（默认 10）
**AND** 新连接建立采用 stagger 策略：随机延迟 [0, 30s] 后建立，避免瞬间大量 TCP 握手触发 Binance connection rate limit
**AND** 连接建立后递增 `binance_ws_connections_active{product_line}` gauge

**WHEN** options 每周五批量到期
**THEN** `Removed` 列表的 stream drain 必须**分批错峰**执行（≤20/批，≥2s 间隔），按 `expiry_date` 排序最早到期优先 drain

> FR-031~036 原定义于 `deprecated/SPEC-exchangeinfo-sync.md`（Draft），v3.8.0 合并入根 SPEC。原文件已移至 `spec/deprecated/`。

### FR-037: Release Safety Net（P0 · 来源 S26）

**功能描述**：建立发布安全网机制，确保新功能灰度上线、异常自动回滚。覆盖 feature flag、canary 部署、健康门禁和回滚 runbook。

**WHEN** 新功能（如 FR-031~036 架构变更）准备上线
**THEN** 通过环境变量 `XGO_BINANCE_FEATURE_{name}=on/off` 控制运行时开关，默认关闭
**AND** 仅在 feature flag 开启 + canary 实例验证通过后才全量推送

**WHEN** canary 实例部署完成
**THEN** 部署工作流自动检查 `/readyz` + 错误率（5xx ratio < 1%）+ 延迟（P99 < 基线 × 1.5）
**AND** 任意检查不达标 → 自动回滚（`kubectl rollout undo` 或等价机制）

**WHEN** 回滚触发
**THEN** 记录回滚事件到审计日志（FR-041）；通知 on-call；保留回滚前 artifact 至少 72h

**WHEN** 未配置 feature flag 的新代码路径被调用
**THEN** 默认关闭；返回 "feature not enabled" 而非静默执行

### FR-038: taosx Data Retention Lifecycle（P0 · 来源 G6/S1/S2）

**功能描述**：对 taosx 热数据执行主动删除生命周期管理。与 FR-006d（OSS 归档）严格协同——先归档校验通过，后删热数据。FR-006e 已在 §7 FR-006 扩展中定义（taosx Data Retention Lifecycle），本条为 Plan008 要求的 P0 独立 FR 完整规格。

> 注：FR-006e 的完整 WHEN/THEN 规格已在 FR-006d 之后定义。本条 FR-038 是对应追溯矩阵的独立编号锚点，避免 G6 缺口在 TRACEABILITY 中无独立 FR 行。详细验收标准见 AC-108~111 / TC-051~052。

### FR-039: Distributed Tracing — OpenTelemetry（P1 · 来源 S28）

**功能描述**：引入 OpenTelemetry SDK，为 client→NATS→server→Kafka 全链路提供分布式追踪能力，补全可观测性三支柱（metrics + logs + traces）。

**WHEN** client 收到原始 Binance 事件
**THEN** 创建 root span `binance.client.normalize` 并注入 trace context（`traceparent` header）
**AND** 后续 normalize → map → publish 各阶段创建 child span

**WHEN** client 调用 `js.Publish(subj, payload)`
**THEN** 通过 NATS header 传播 `traceparent`（W3C Trace Context 格式）

**WHEN** server consumer 收到消息
**THEN** 从 NATS header 提取 `traceparent`，创建 `binance.server.consume` span
**AND** validate → idempotency → store → kafkax dispatch 各阶段创建 child span

**WHEN** kafkax.Send 被调用
**THEN** 通过 Kafka header 传播 `traceparent` + `binance-trace-id`，供下游分析域消费者串联

**WHEN** 追踪采样
**THEN** 通过 `observability.tracing.sample_rate`（默认 0.1）控制；`/debug/pprof` 和 admin 端点强制 100% 采样

**WHEN** slog 日志输出
**THEN** 自动注入 `trace_id` 和 `span_id` 结构化字段，与 Span 关联

### FR-040: Resource Quota & Isolation（P1 · 来源 S29）

**功能描述**：在多消费者/多产品线场景下实现资源隔离，防止单消费者/单产品线故障拖垮全局。

**WHEN** 多个分析域 consumer group（signal/risk/backtest/market_regime）消费 Kafka
**THEN** 为每个 consumer group 配置独立配额（max.poll.records + max.partition.fetch.bytes）
**AND** 单 group 超配额时限流而非抢占其他 group 资源

**WHEN** client 同时连接四产品线
**THEN** 每个产品线使用独立 WS 连接池（spot/um/cm/options 各 3 连接）
**AND** 单产品线连接异常（如 options 到期峰值）不影响其他产品线采集
**AND** 各产品线独立 retry budget，互不抢占

**WHEN** 请求 Gin REST API（`GET /api/v1/analytics/*`）
**THEN** 通过 redisx 实现 per-caller（API key）限流，而非全局 1000 req/min
**AND** ClickHouse 查询设 `max_execution_time`（默认 30s）+ `max_concurrent_queries`（默认 4）

### FR-041: Audit Log Completeness（P1 · 来源 S30/S33）

**功能描述**：将所有 admin 写操作、数据生命周期事件纳入不可篡改的审计日志，满足金融数据合规审计要求。

**WHEN** 调用 `POST /api/v1/admin/*` 写操作（symbol reload、backfill trigger、retention override 等）
**THEN** 记录审计事件到 `binance_admin_audit` 表（actor、action、before、after、timestamp、client_ip）
**AND** 鉴权通过后才允许执行（FR-035 admin auth hardening）

**WHEN** 数据生命周期事件发生（retention 删除、reconcile 差异 >0.01%、rehydrate 触发、DLQ 入队）
**THEN** 写入 `binance_lifecycle_audit` 表（event_type、affected_range、row_count、trigger、timestamp）

**WHEN** audit_log 表创建
**THEN** 设 `REVOKE UPDATE, DELETE ON audit_log FROM public`（append-only）
**AND** 审计日志保留期 ≥ 1 年；超期归档 OSS（`binance/audit/{YYYY}/{MM}/audit.parquet`）

### FR-042: Schema Version Compatibility Policy（P1 · 来源 S27）

**功能描述**：定义 `SchemaVersion` 语义化规则与兼容策略，确保 client/server 升级时数据格式向后兼容。

**WHEN** `SchemaVersion` 字段被定义
**THEN** 采用 `MAJOR.MINOR` 格式（如 `v1.0`）
**AND** MAJOR 变更 = 破坏性（字段删除/重命名/类型变更）；MINOR 变更 = 向后兼容（新增字段，旧 consumer 忽略）

**WHEN** server 收到未知 MAJOR 版本的 `SchemaVersion`
**THEN** 执行 terminal reject（返回 `BNC-014 ErrSchemaVersionIncompatible`），不尝试解析
**AND** 写入告警日志 + metrics counter `binance_server_schema_reject_total`

**WHEN** server 收到已知 MAJOR + 更高 MINOR 版本
**THEN** 忽略未知字段（向后兼容），正常处理

**WHEN** 新增 MINOR 版本字段
**THEN** 在 `postgresx` 的 `binance_schema_versions` 表登记（version、fields_added、compatible_since、deprecated_at）

### FR-043: Cost Observability（P2 · 来源 S31）

**功能描述**：对 infra 资源成本进行可观测性度量，支持 per-product-line 分摊与预算告警。

**WHEN** 存储层写入数据（taosx/clickhousex/ossx/postgresx/redisx）
**THEN** 暴露 Prometheus 指标：`binance_storage_bytes_total{store,product_line}` + `binance_storage_bytes_per_hour{store,product_line}`

**WHEN** 带宽消耗（NATS/Kafka/Binance WS）
**THEN** 暴露 `binance_bandwidth_bytes_total{direction,product_line}` 指标

**WHEN** 存储容量或带宽超过预算阈值
**THEN** 触发 Prometheus AlertManager 告警 → on-call 通知

### FR-044: Data Compliance & Destruction（P2 · 来源 S32）

**功能描述**：确保数据分类、合规保留与可证明销毁，满足数据治理合规要求。

**WHEN** 数据首次写入
**THEN** 按以下分类标注 `data_classification`：`market_public`（公开行情）、`market_derived`（衍生指标）、`operational`（运维数据）、`audit`（审计日志）

**WHEN** 合规保留期到达（`market_public` 7y / `market_derived` 3y / `operational` 1y / `audit` 7y）
**THEN** 执行不可逆销毁（OSS 对象删除 + taosx DROP STABLE + postgresx DELETE）
**AND** 生成销毁证明（`certificate_of_destruction` JSON，含 date、data_class、row_count、byte_count、executor）

**WHEN** 销毁操作执行
**THEN** 写入 audit_log（FR-041）；销毁证明归档 OSS `binance/certificates/{YYYY}/`

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
| FR-024 Runtime Config Hot Reload | AC-084 ~ AC-086 | TC-042 | 管理端点 + 集成（catalog reload + full reconnect/no-restart proof） |
| FR-025 Backfill Throttle & Priority | AC-087 ~ AC-089 | TC-043 | 单元 + 集成（分钟 weight 预算 + P0/P1/P2 三级优先级 + 实时延迟自适应降速） |
| FR-026 Daily Reconciliation Job | AC-090 ~ AC-092 | TC-044 | 集成（04:00 UTC 对账 + tolerance 阈值 + alerts 表写入） |
| FR-027 Cold Data Rehydration | AC-093 ~ AC-095 | TC-045 | 集成（OSS→taosx 回热 + 202 job_id + 24h TTL 过期） |
| FR-028 Backfill Progress API | AC-096 ~ AC-098 | TC-046 | httptest（jobs 列表 + coverage 时间戳 + 诊断字段） |
| FR-029 Data Quality & Freshness SLA | AC-099 ~ AC-101 | TC-047 | 集成 + metrics（freshness SLA + stale alert + schema drift） |
| FR-030 Options Chain Raw Field Pass-through | AC-102 ~ AC-104 | TC-048, TC-049 | 单元 + 契约测试（Options 原始字段透传，Greeks 归分析域） |
| FR-031 ExchangeInfo Discovery (4 PL) | AC-131 ~ AC-134 | TC-066, TC-067 | 集成 + 契约（四产品线 exchangeInfo + API 陷阱 + JSON schema） |
| FR-032 ExchangeInfo Persistence & Refresh | AC-135 ~ AC-138, AC-112a-c | TC-068, TC-069, TC-075~077 | 集成 + 单元（upsert + diff-only + control stream + Reload/SyncCatalog 顺序） |
| FR-033 Sync Tier Classification | AC-139, AC-141~142 | TC-070, TC-071 | 单元 + 集成（SymbolsByTier + admin PATCH + 默认 disabled） |
| FR-034 Selective Sync Whitelist | AC-143 ~ AC-146 | TC-072, TC-073 | 单元 + 集成（deny 永远赢 + product_lines 先过滤 + admin reload 集成） |
| FR-035 Admin Auth Hardening | AC-147 ~ AC-150 | TC-078 | 集成（Bearer 鉴权 + loopback fallback + audit_log） |
| FR-036 Tier-Aware Connection Topology | AC-151 ~ AC-154 | TC-079 ~ TC-083 | 单元 + 集成（StreamsForProductLineTier 按 PL 分化 + 分组连接 + 升降级 drain + 分批 + options 到期峰值） |
| FR-037 Release Safety Net | AC-105 ~ AC-107 | TC-050 | 集成 + CI（feature flag 开启/关闭 + canary 健康门禁 + 回滚验证） |
| FR-038 taosx Data Retention Lifecycle | AC-108 ~ AC-111 | TC-051, TC-052 | 集成（定时 DELETE + OSS ETag 前置校验 + 删除审计 + DB KEEP） |
| FR-039 Distributed Tracing (OpenTelemetry) | AC-112 ~ AC-114 | TC-053 | 集成（Span 埋点 + traceparent header 传播 NATS/Kafka + slog trace_id 关联） |
| FR-040 Resource Quota & Isolation | AC-115 ~ AC-118 | TC-054, TC-055 | 集成 + CI（Kafka quota + WS 连接池隔离 + API per-caller 限流 + CH 查询超时） |
| FR-041 Audit Log Completeness | AC-119 ~ AC-121 | TC-056, TC-057 | 单元 + CI（admin 写审计 + append-only REVOKE + 保留期验证 + OSS 归档） |
| FR-042 Schema Version Compatibility Policy | AC-122 ~ AC-124 | TC-058 | 单元 + CI（MAJOR terminal reject + MINOR 向后兼容 + 兼容矩阵校验） |
| FR-043 Cost Observability | AC-125 ~ AC-127 | TC-059 | 集成 + metrics（存储容量/带宽/分摊指标 + Prometheus 告警规则） |
| FR-044 Data Compliance & Destruction | AC-128 ~ AC-130 | TC-060, TC-061 | 单元 + 审计（数据分类标注 + 合规保留期 + 销毁证明 + 血缘文档） |
**AC 总数**：154（AC-001 ~ AC-154）· **TC 总数**：83（TC-001 ~ TC-083，全覆盖 FR-001~044）· **追溯登记覆盖率**：100%（FR→AC→TC 全链路已登记；实现通过率见 TRACEABILITY.md §6）

> AC 完整描述（验收标准文本）单点维护于 `TRACEABILITY.md §5`。本表只做 SPEC ↔ Traceability 双向锚点，遵循 `~/.claude/rules/ecc/matrix-scoring-rules.md §R1 跨表走查` 原则。

---

## 8. Business Rules

> **BR 编号规则（v3.8.0 统一）**：所有 BR 使用根 SPEC 单一 canonical 编号空间。下表提供 Root↔Client↔Server 三列映射。

### BR 三列映射表

| Root BR | 规则摘要 | Client 视角 | Server 视角 |
|---------|---------|------------|-------------|
| BR-001 | No binance-market | 同 root | 同 root |
| BR-002 | Client Must Not Import Server Internals | client 侧 CI gate `go list -deps \| grep 'binance/server'` | — |
| BR-003 | Server Must Not Import Client Internals | — | server 侧 CI gate `go list -deps \| grep 'binance/client'` |
| BR-004 | natsx ManualAck — 全链路写入后才 Ack | client 侧：等待 PubAck | server 侧：redisx+taosx+pg+kafkax 全成功→Ack |
| BR-005 | No Domain Ownership | 同 root | 同 root |
| BR-006 | No Generic Market Data / Strategy Ownership | 同 root | server 仅拥有 Binance-specific persistence |
| BR-007 | Wire Contract Externality | 同 root | 同 root |
| BR-008 | Idempotency Key Stability | client 侧：key 生成策略 | server 侧：key 消费校验 |
| BR-009 | Admin Boundary | client admin 仅变 client-local state | server admin 仅变 server-local state |
| BR-010 | ExchangeInfo Diff-Only Publication | client 侧：diff 为空时 skip publish | server 侧：24h full snapshot 兜底 |
| BR-011 | Tier Reassignment Safety | client 侧：降级先 drain 再 unsubscribe | — |
| BR-012 | Options Expiry Batch Drain Smoothing | client 侧：分批错峰 drain ≤20/批 | — |

> Client 子规格 §8 仅保留 client 侧特有的实现约束，不再定义独立 BR 编号。Server 子规格同理。

---

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

### BR-010: ExchangeInfo Diff-Only Publication

**规则**：client 定时刷新 exchangeInfo 时，**必须**先与本地 catalog 做集合 diff（基于 `product_line:symbol` 复合键），仅在 `added ∪ removed ∪ updated` 非空时发布 `instruments.changed`。

**约束**：全量快照每 24h 强制发布一次（作为对账基准，即使 diff 为空）。

**违反时**：CI gate `no-full-snapshot-spam` 检测。

### BR-011: Tier Reassignment Safety

**规则**：`sync_tier` 从高（L1_core）降到低（L3_full/disabled）时，对应 stream 的活跃连接应先 drain 再 unsubscribe（复用 FR-004 NakWithDelay + DLQ 语义，确保 in-flight 事件不丢）。从低升到高时，新 stream 异步建立，不阻塞现有采集。

**违反时**：集成测试检测 drain→DLQ→unsubscribe 顺序违反。

### BR-012: Options Expiry Batch Drain Smoothing

**规则**：options 每周五批量到期时，`Removed` 列表的 stream drain 必须**分批错峰**执行（如每批 20 个，间隔 2s），而非一次性全部 unsubscribe。drain 队列按 `expiry_date` 排序，最早到期的优先 drain。

**违反时**：集成测试检测连接管理器过载或批大小/间隔违反。

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
| `binance.market.spot.funding_rate` | 现货资金费率占位（治理矩阵保留；runtime 不采集） |
| `binance.market.spot.mark_price` | 现货标记价格占位（治理矩阵保留；runtime 不采集） |
| `binance.market.um_perp.funding_rate` | U 本位合约资金费率 |
| `binance.market.um_perp.mark_price` | U 本位合约标记价格 |
| `binance.market.cm_perp.funding_rate` | 币本位合约资金费率 |
| `binance.market.cm_perp.mark_price` | 币本位合约标记价格 |
| `binance.market.options.funding_rate` | 期权资金费率占位（治理矩阵保留；runtime 不采集） |
| `binance.market.options.mark_price` | 期权标记价格 / option mark |

#### Depth 订阅档位（FR-015）

| product_line | 档位 | 说明 |
|---|---|---|
| `spot` / `um_perp` / `cm_perp` | `@depth20@100ms`（快照）+ `@depth@1000ms`（增量） | snapshot 与 incremental 用 `update_id` 拼合 |
| `options` | `@depth1000` | 沿用现有 EOptions depth stream |

> [COMPUTED, HIGH] snapshot 与 incremental 通过 `update_id` 单调递增校验拼合；`update_id` 回退或不连续触发 gap 检测（FR-017）。

#### Control Subjects

| Subject | 触发 | 消费方 |
|---|---|---|
| `binance.control.instruments.changed` | client 6h 刷新 exchangeInfo 发现目录变更 | server | **→ FR-032 AC-112a**：runtime 当前 stream 仅声明 `binance.market.*.*`（`consumer.go:18`），本 subject 需 server 启动时 `AddStream("binance.control.>")` 声明，**retention=LimitsPolicy**（非 WorkQueue，multi-server 广播语义） |
| `binance.control.symbols.changed` | `POST /api/v1/admin/symbols/reload` | client |

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
| `InstrumentSubtype` | Perpetual / Delivery（仅 um_perp / cm_perp 适用） | domain_market |
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
| instrument_subtype | — | ✅ | ✅ | — |
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
> 环境变量前缀：统一使用 `XGO_BINANCE_`（`configx` 约定，见 `module/bootstrap/SPEC.md`）。基础设施凭据使用各模块规范前缀。
> `nats.url` 指向外部 NATS JetStream 服务；部署 NATS 集群属于平台/运维边界，不属于 client/server 二进制。
> Dev 非敏感 NATS 配置与 `sre/secrets/env/dev.md` §NATS 对齐：client URL=`nats://127.0.0.1:4222`，monitor=`http://127.0.0.1:8222`，JetStream enabled，server_name=`nats-dev-01`。认证明文只能经环境变量注入。

### 11.1 Client Config（`binance-client.yaml`）

| 配置键 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `binance.rest_url` | `string` | `https://api.binance.com` | Binance REST API base URL |
| `binance.ws_url` | `string` | `wss://stream.binance.com:9443` | Binance WebSocket base URL |
| `binance.product_lines` | `[]string` | `["spot"]` | 启用的产品线（domain_market canonical：`spot`/`um_perp`/`cm_perp`/`options`）。**→ FR-034**（详见 §7 FR-034） |
| `binance.symbols.allow` | `[]string` | `[]` | 白名单 symbol（空=全部）。**→ FR-034** |
| `binance.symbols.deny` | `[]string` | `[]` | 黑名单 symbol（deny 永远赢）。**→ FR-034** |
| `binance.api_key_env` | `string` | `BINANCE_API_KEY` | 读取 API Key 的环境变量名 |
| `binance.secret_key_env` | `string` | `BINANCE_SECRET_KEY` | 读取 Secret Key 的环境变量名 |
| `nats.url` | `string` | `nats://127.0.0.1:4222` | 外部 NATS JetStream 连接地址 |
| `nats.stream` | `string` | `BINANCE_MARKET` | JetStream Stream 名称 |
| `nats.auth.user` | `string` | `admin` | NATS 用户名 |
| `nats.auth.password_env` | `string` | `FOUNDATIONX_NATS_PASSWORD` | NATS 密码环境变量名；旧 `NATS_PASSWORD` 仅作为兼容输入 |
| `publisher.batch_size` | `int` | `256` | 批量发布大小（0=逐条发布） |
| `publisher.flush_interval` | `duration` | `100ms` | 批量刷新间隔 |
| `publisher.publish_ack_timeout` | `duration` | `5s` | PubAck 等待超时 |
| `publisher.backpressure_queue_size` | `int` | `10000` | 内存队列最大事件数（达阈值时暂停采集） |
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
| `nats.consumer.durable` | `string` | `binance-server` | durable consumer 名称；多实例部署时需追加 `-{instance_id}` 避免 consumer 名称冲突（instance_id 从 `INSTANCE_ID` 环境变量读取） |
| `nats.consumer.ack_wait` | `duration` | `30s` | ManualAck 超时；超时后 JetStream 自动重投，server 侧 idempotency check（FR-005 redisx SetNX）防止重复写入。最坏情况链路（kafkax broker 不可达等待超时）30s 安全边界充足 |
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
| `redis.idempotency.ttl` | `duration` | `72h` | 幂等 key TTL（MaxDeliver=5 × NakWithDelay=5s = 最长 25s 完成所有重投；72h 提供极大安全边界，同时控制 Redis 内存占用） |
| `redis.cache.tick_ttl` | `duration` | `60s` | 最新 tick 热缓存 TTL |
| `redis.cache.depth_ttl` | `duration` | `5s` | 深度快照缓存 TTL |
| `redis.lock.ttl` | `duration` | `30s` | 分布式协调锁 lease TTL |
| `redis.ratelimit.window` | `duration` | `10s` | API 限流滑动窗口（建议使用 sliding window log 算法防边界突发） |
| `redis.ratelimit.max_req` | `int` | `100` | 每窗口最大请求数（等效 10 QPS 但允许短时突发） |

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

> 数据库 `market_binance` 已存在（TDengine per-provider 独立数据库）。超表（binance_tick / binance_bar / binance_depth / binance_trade / binance_funding_rate / binance_mark_price）由 taosx SchemalessWrite 自动创建子表。

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

> **生产 DDL 契约（P0 · 来源 S3/S4）**：生产部署必须满足以下 ClickHouse DDL 要求：
> - **引擎**：三张业务表（`binance_tick_olap`、`binance_bar_olap`、`binance_trade_olap`）必须使用 `ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/market_binance/{table}', '{replica}')`（S3）
> - **TTL**：每表含 `TTL bucket + INTERVAL 730 DAY` 过期表达式（S4）
> - **分区**：`PARTITION BY toYYYYMM(bucket)` + `ORDER BY (product_line, symbol, bucket)`
> - **幂等**：ETL 写入使用 `ReplacingMergeTree` 或先删后写，确保 ETL 重试不产生重复行（S14）
> - **验证**：启动时通过 `SELECT engine FROM system.tables WHERE database='market_binance'` 校验引擎类型；不符合则 fail-fast 并记录错误日志

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

> **DLQ/Retry Topic 模式（P0 · 来源 S6）**：生产部署必须建立死信队列：
> - **DLQ Topic**：`binance.{product_line}.{event_type}.v1.dlq` — 消费重试耗尽（MaxDeliver=5）后消息路由至此
> - **Retry Topic**：`binance.{product_line}.{event_type}.v1.retry` — 临时重试消息（NakWithDelay 使用原 topic redelivery，不使用独立 retry topic）
> - **DLQ 保留策略**：`retention.ms=2592000000`（30 天），`cleanup.policy=delete`
> - **DLQ 消费**：admin endpoint `POST /api/v1/admin/deadletter/replay` 读取 JSONL 重投（FR-004/FR-041 审计）

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
| `oss.archiver.bars_cutoff` | `duration` | `8760h` | Bars 热→冷截止（365d，对齐 taosx retention） |
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

#### 11.2.10 操作任务（Backfill / Reconciliation / Rehydration）

| 配置键 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `backfill.max_concurrent` | `int` | `4` | 全局并发回填任务上限（FR-019 Resource Cap） |
| `backfill.per_instrument_cap` | `int` | `10` | 单 instrument 并发回填上限 |
| `backfill.weight_budget_per_minute` | `int` | `800` | 回填分钟 weight 预算（FR-025，留 400 weight/min 给实时请求，总计对齐 `max_weight_per_minute=1200`） |
| `backfill.p0_reserved_ratio` | `float` | `0.3` | P0 实时预留比例（FR-025 三级优先级） |
| `backfill.p1_repair_ratio` | `float` | `0.2` | P1 repair 比例 |
| `backfill.p2_cold_start_ratio` | `float` | `0.5` | P2 cold_start 比例；p0+p1+p2=1.0 |
| `backfill.cold_start_fallback_time` | `map[string]string` | `{"spot":"2017-07-01","um_perp":"2019-09-01","cm_perp":"2019-09-01","options":"2024-01-01"}` | exchangeInfo 未提供 `onboardDate` 时的保守下界（FR-016 冷启动探测） |
| `backfill.cold_start_buffer` | `duration` | `5m` | 冷启动 backfill `end = now - buffer`，避免与实时数据重叠 |
| `backfill.probe_max_rest_calls` | `int` | `25` | `first_kline_time` 二分探测最大 REST 调用次数（超出则暂停等待下个分钟窗口） |
| `reconciliation.schedule` | `string` | `0 4 * * *` | 对账 cron 表达式（FR-026，默认 04:00 UTC） |
| `reconciliation.tolerance_pct` | `float` | `0.01` | 对账差异容忍百分比（超出写入 alerts 表） |
| `rehydration.ttl` | `duration` | `24h` | 冷数据回热 OSS 签名 URL TTL（FR-027） |
| `rehydration.oss_bucket` | `string` | `` | 回热源 OSS bucket（默认使用 ossx bucket） |

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

### 12.1 统一错误码字典

> 三表合一（root BNC-001~018 + client BNC-CLIENT-4001~4007 + server RejectReason）。`所属模块` 列标注错误来源；`可重试` 列标注退避策略是否适用。

| Code | 错误名 | 触发条件 | 所属模块 | 处理方式 | 可重试 |
|------|--------|----------|----------|----------|:----:|
| `BNC-001` | `ErrProductLineDisabled` | 配置未启用的 product line 被请求 | client | 记录日志，跳过该 product line | — |
| `BNC-002` | `ErrInvalidSymbol` | parser 无法解析 Binance symbol | client | 结构化错误返回，记录原始 symbol | — |
| `BNC-003` | `ErrNATSConnect` | 无法连接 natsx JetStream | client+server | 指数退避重试；client 积压在内存队列（有界） | ✅ |
| `BNC-004` | `ErrNATSPubAck` | JetStream PubAck 超时 | client | 重试发布；超过阈值触发告警 | ✅ |
| `BNC-005` | `ErrNATSConsumer` | durable consumer 订阅失败 | server | 进程重启自动恢复；告警 | ✅ |
| `BNC-006` | `ErrDuplicateConflict` | server 收到同一 key 但 payload 不同的 event | server | terminal reject，记录冲突详情 | ❌ |
| `BNC-007` | `ErrValidation` | server 收到缺少必需字段的 event | server | terminal reject，含 machine-readable reason | ❌ |
| `BNC-008` | `ErrKafkaxDispatchFailed` | kafkax fanout handoff 失败 | server | 重试（指数退避）；不 Ack；超过阈值进入 dead-letter/告警路径 | ✅ |
| `BNC-009` | `ErrRedisUnavailable` | redisx 幂等检查或缓存不可达 | server | 幂等检查失败 → NakWithDelay；缓存失败 → 降级到 taosx 直查 | ✅ |
| `BNC-010` | `ErrTaosxWriteFailed` | taosx WriteBatch 写入失败 | server | NakWithDelay(5s)；MaxDeliver 超过后进入死信 | ✅ |
| `BNC-011` | `ErrPostgresUnavailable` | postgresx catalog 查询或 upsert 不可达 | server | 指数退避重试；超过阈值告警 | ✅ |
| `BNC-012` | `ErrOssUploadFailed` | ossx 归档上传失败 | server | 保留 taosx 热数据；告警；下个调度周期自动重试 | ✅ |
| `BNC-013` | `ErrClickhouseUnavailable` | clickhousex ETL 写入或 analytics 查询不可达 | server | analytics API 返回 503；ETL 跳过本批次；实时 API 不受影响 | ✅ |
| `BNC-014` | `ErrSchemaVersionIncompatible` | server 收到未知 MAJOR SchemaVersion | server | terminal reject；写入告警日志 + metrics counter | ❌ |
| `BNC-015` | `ErrDataRetentionDeleteFailed` | taosx retention 删除失败 | server | 保留热数据；写入 alerts 表；下周期重试 | ✅ |
| `BNC-016` | `ErrAuditLogWriteFailed` | 审计日志写入失败 | server | 阻塞当前操作（审计失败不可静默）；告警 | ❌ |
| `BNC-017` | `ErrInvalidBackfillWindow` | backfill job 窗口参数不合法 | server | 拒绝创建 job；返回结构化错误含 reason | — |
| `BNC-018` | `ErrBackfillWindowOverlap` | 新 backfill job 窗口与已有 job 重叠 | server | 拒绝创建 job；返回重叠区间信息 | — |
| `BNC-019` | `ErrBackfillUnsupportedEventType` | 请求为 depth/tick 创建 backfill job（不可回填事件类型） | server | 拒绝创建 job；返回结构化错误含 unsupported event_type | — |
| `BNC-CLIENT-4001` | `ErrInvalidSymbol` | parser 无法解析 symbol（client 侧） | client | Warn log, skip event | — |
| `BNC-CLIENT-4002` | `ErrProductLineDisabled` | 尝试操作未启用的 product line（client 侧） | client | Return error, don't start connector | — |
| `BNC-CLIENT-4003` | `ErrNATSConnect` | 无法连接 natsx JetStream（client 侧） | client | Exponential backoff reconnect; queue events in memory | ✅ |
| `BNC-CLIENT-4004` | `ErrNATSPubAck` | PubAck timeout（client 侧） | client | Retry publish; alert on threshold | ✅ |
| `BNC-CLIENT-4005` | `ErrNATSBackpressure` | 内存队列达阈值 | client | Pause collection; trigger alert; wait for drain | — |
| `BNC-CLIENT-4006` | `ErrCatalogReloadFailed` | Catalog reload 失败 | client | Keep current catalog; log error | ✅ |
| `BNC-CLIENT-4007` | `ErrIdentityCollision` | Parser/mapper 检测到 identity 碰撞 | client | Reject event; log error | ❌ |

### 12.2 RejectReason 分类（server 侧）

| RejectReason | 语义 | 对应错误码 |
|-------------|------|-----------|
| `terminal_validation` | Envelope 校验失败（必填字段缺失/产品线不存在/event_type 未知/event_time 无效） | BNC-007 |
| `terminal_conflict` | 幂等键冲突（key 存在但 payload hash 不同） | BNC-006 |
| `retryable_storage` | redisx/taosx/postgresx/ossx 不可达 | BNC-009 / BNC-010 / BNC-011 / BNC-012 |
| `retryable_fanout` | kafkax 不可达或 publish 失败 | BNC-008 |
| `retry_exhausted` | NATS 重投超限（MaxDeliver=5 耗尽） | — |

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
| 回填请求与在途回填重叠 | 同一 product_line:time_range 已存在活跃 cold_start/repair | server 拒绝重复回填，返回 `ErrBackfillOverlap`，不创建重复 job |
| Stream drain 超时 | drain 期间超过 DrainTimeout 仍有未确认消息 | 记录告警，强制 unsubscribe，剩余消息进入 DLQ |
| 冷数据 rehydration TTL 过期 | OSS 归档键超过 24h TTL | 返回 `ErrRehydrationExpired`，要求重新发起回填请求 |
| Schema 版本漂移检测 | server DDL 与 SPEC §11 声明的 schema 不一致 | `check-version-drift.sh` 在 CI 中检测漂移，CI FAIL 阻断 PR |
| 对账差异超出 tolerance | Daily Reconciliation Job 检测到 `count` 或 `checksum` 差异 > tolerance | 写入 `alerts` 表，触发 Prometheus 告警，保留差异行供人工对账 |

---

## 14. Directory Structure

### Documentation (`module/binance/`)

```text
module/binance/
  goal/goal.md                    # 模块 Goal 文档
  README.md                       # 模块索引
  spec/
    SPEC.md                       # 本文件 — 模块完整规格（canonical FR/BR）
    client/SPEC.md                # Client 子模块规格（以根 FR 编号引用）
    server/SPEC.md                # Server 子模块规格（以根 FR 编号引用）
    ACCEPTANCE.md                 # 验收清单
    FEATURES.md                   # 功能实现投影
    NAMING.md                     # 命名 SSOT
  matrix/
    TRACEABILITY.md               # 需求追溯矩阵（根）
    client/TRACEABILITY.md        # Client 追溯矩阵
    server/TRACEABILITY.md        # Server 追溯矩阵
  design/                         # 设计文档
  plan/                           # 执行计划
  tasks/                          # Task spec
  prompt/                         # Context Package
  gate/                           # 边界门禁
  evidence/                       # 交付证据

  # 已退役文件（仅保留历史参考，不作为活跃规范）
  spec/deprecated/SPEC-exchangeinfo-sync.md   # DEPRECATED — FR-031~036 已合并入根 SPEC §7
  spec/deprecated/DATA-LIFECYCLE.md           # DEPRECATED — FR-012~030 已合并入根 SPEC §7
  spec/deprecated/DATA-QUALITY-SLA.md         # DEPRECATED — 已合并入 FR-029
  spec/deprecated/ENDPOINTS.md                # DEPRECATED — 已迁移至 client/SPEC.md 附录 A
```

### Runtime (`github.com/ZoneCNH/binance/`)

> Runtime 目录结构详见 Client SPEC §14 和 Server SPEC §14。
>
> 简要概览：
> - `cmd/binance-client/main.go` — client 进程入口
> - `cmd/binance-server/main.go` — server 进程入口
> - `internal/client/` — client 源码
> - `internal/server/` — server 源码
> - `internal/wire/` — 共享 wire contract（ADR-002）

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
| TC-013 | FR-007 | httptest | `GET /api/v1/market/depth/:symbol` | redisx cache hit 返回最新快照 |
| TC-014 | FR-007 | httptest | 无效 API key | 返回 401 |
| TC-015 | FR-007 | httptest | 请求超过限流 | 返回 429 + Retry-After |
| TC-016 | FR-006d | 单元 | 超 retention 数据归档 | 先写 `ossx`，ETag 校验通过后删 `taosx` |
| TC-017 | FR-006d | 单元 | 生成归档路径 | 路径符合 `binance/{product_line}/{symbol}/{YYYY}/{MM}/{DD}/{event_type}.parquet` |
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
| TC-030 | FR-013 | 单元 + 集成 | retry budget（base=1s/max=120s/jitter=±10%）+ rate-limit（分钟 weight 滑动窗口 + 429/418 差异化）+ clock skew（单调性+drift rate+时间窗口） | 故障注入下退避序列符合预算；429→AIMD 恢复；418→熔断 15min；clock skew 单调回拨→ALERT |
| TC-031 | FR-014 | httptest + metrics | runtime stream state / lag / unhealthy reason | admin/metrics 同步暴露可审计状态 |
| TC-032 | FR-015 | httptest + 集成 | pause/resume/drain lifecycle | pause 后停止新增消费，resume 恢复，drain 有审计记录 |
| TC-033 | FR-016 | 单元 | backfill window、cursor 与 overlap validation | 无效窗口/重叠区间被拒绝，cursor 可恢复 |
| TC-034 | FR-017 | 集成 | 按事件类型的缺口检测（trade→trade_id 序列、bar→open_time 序列、depth→U/u updateId 序列）+ GAP_DATA_MISSING vs GAP_NO_DATA 区分 + idempotency | 各类型缺口正确检测（trade_id 跳跃/bar 缺失/updateId 断裂）；停盘期标记 NO_DATA 不触发 replay；replay job 幂等执行 |
| TC-035 | FR-018 | 单元 + 集成 | archive manifest、restore 与 retention delete | manifest 可校验，restore 可回放，retention delete 有保护 |
| TC-036 | FR-019 | 单元 | backfill resource cap and cancellation cursor | 全局/单 instrument 限额生效，取消后 cursor 可恢复 |
| TC-037 | FR-020 | 单元 + 集成 | funding_rate event mapping/storage/query/fanout | funding_rate 事件在 mapping、存储、API 与 fanout 中一致 |
| TC-038 | FR-021 | 单元 + 集成 | mark_price/index_price kind/topic/storage | mark/index price 不与 last/bid/ask 混淆 |
| TC-039 | FR-022 | 文档校验 | R2 governance matrix + stale alias checks | 4 product lines × 6 event types × 5 文档/checker anchors |
| TC-040 | FR-023 | 证据归档 | local/CI/live evidence bundle | local 与 remote CI/live 证据分层归档，不能互相替代 |
| TC-041 | FR-023 | release gate | release tag/changelog/evidence consistency | release tag、CHANGELOG、CI URL、evidence bundle 一致 |
| TC-042 | FR-024 | 集成 + httptest | `POST /api/v1/admin/symbols/reload` catalog reload | endpoint 验证通过，并证明 active stream add/remove 无进程重启 |
| TC-043 | FR-025 | 单元 + 集成 | 分钟 weight 预算 + 三级优先级（P0/P1/P2） | P0 实时 30% / P1 repair 20% / P2 cold_start 50%；实时延迟超阈值→P2 降为 0；weight 预算 95%→指标递增 |
| TC-044 | FR-026 | 集成 | 04:00 UTC 对账 | taosx vs Binance klines；差异 > tolerance 阈值→alerts 表写入；连续失败→ALERT |
| TC-045 | FR-027 | 集成 | OSS→taosx 回热 | 202 job_id 创建；24h TTL 过期后自动删除；manifest 校验失败→拒绝回热 |
| TC-046 | FR-028 | httptest | `GET /api/v1/admin/backfill/*` | jobs 列表返回含 job_id/window/cursor/status；coverage 含 earliest/latest/gaps |
| TC-047 | FR-029 | 集成 + metrics | freshness SLA + stale alert | e2e latency histogram 有值；spot/um/cm P99>60s→ALERT；schema drift BREAKING→ALERT |
| TC-048 | FR-030 | 单元 | Options raw_fields pass-through | tick/depth raw_fields JSONB 含 delta/gamma/theta/vega/IV/oi/strike/type/expiry/underlying |
| TC-049 | FR-030 | 契约测试 | Greeks 不在此层计算 | `GET /api/v1/market/options/:symbol/greeks` 仅从 raw_fields 提取；不调用 strategyx/factorx |
| TC-050 | FR-037 | 集成 + CI | feature flag 开启与关闭 | `XGO_BINANCE_FEATURE_xxx=on` → 代码路径激活；`=off` → 返回 "feature not enabled" |
| TC-051 | FR-038 | 单元 | taosx retention 删除逻辑 | 过期 tick(>30d) 在 OSS ETag 校验通过后被 DeleteRange 删除 |
| TC-052 | FR-038 | 集成 | OSS 未归档时删除被阻止 | OSS ETag 缺失 → 跳过删除 → alerts 表有记录 |
| TC-053 | FR-039 | 集成 | OpenTelemetry trace context 传播 | NATS msg header 含 `traceparent`；Kafka record header 含 `traceparent` + `binance-trace-id` |
| TC-054 | FR-040 | 单元 | per-consumer-group Kafka quota | 单 group 超 quota 时限流，其他 group 不受影响 |
| TC-055 | FR-040 | 集成 | per-product-line WS 连接池隔离 | spot 连接断开不影响 um/cm/options 采集 |
| TC-056 | FR-041 | 单元 | admin 写操作审计 | `POST /api/v1/admin/symbols/reload` → audit_log INSERT（actor/action/before/after） |
| TC-057 | FR-041 | CI | audit_log append-only | 验证 `REVOKE UPDATE, DELETE ON audit_log FROM public` 生效 |
| TC-058 | FR-042 | 单元 | MAJOR 版本 terminal reject | SchemaVersion `v2.0`（未知 MAJOR）→ `BNC-014` reject |
| TC-059 | FR-043 | 集成 + metrics | 存储容量指标 | Prometheus `binance_storage_bytes_total{store,product_line}` 有值 |
| TC-060 | FR-044 | 单元 | 数据合规分类 | 写入时 `data_classification` 字段非空且合法 |
| TC-061 | FR-044 | 审计 | 销毁证明生成 | `certificate_of_destruction` JSON 含 date/data_class/row_count/byte_count/executor |
| TC-062 | FR-037 | CI | 健康门禁自动化 | canary → `/readyz` 检查 + 错误率 <1% → promote；失败 → rollback |
| TC-063 | FR-039 | 单元 | slog trace_id 关联 | 日志行 JSON 含 `trace_id` + `span_id` 字段 |
| TC-064 | FR-040 | 单元 | ClickHouse 查询超时 | `max_execution_time=30s` 超限 → 503 "query timeout" |
| TC-065 | FR-041 | 单元 | 数据生命周期审计 | retention delete 后 `binance_lifecycle_audit` 表有新行 |

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
| End-to-end freshness (event_time → taosx persist) | 延迟 P99 | < 200ms | integration test（FR-029） |
| End-to-end freshness (event_time → kafkax fanout) | 延迟 P99 | < 300ms | integration test（FR-029） |
| Stale alert threshold (无新事件) | 超时 | spot/um_perp/cm_perp 30s，options 60s | observability alert（FR-029） |
| OpenTelemetry tracing overhead | 延迟增加 | < 5% | `go test -bench` 对比 trace on/off |
| ClickHouse analytics query timeout | 超时 | 30s | integration test（FR-040） |
| OSS cold data rehydrate throughput | 吞吐量 | ≥ 10 MB/s per symbol | integration test（FR-027） |
| taosx retention DELETE batch（1000 rows） | 延迟 P99 | < 100ms | integration test（FR-038） |
| Schema version check（reject path） | 延迟 P99 | < 10μs | `go test -bench`（FR-042） |
| Client WS message throughput（单 product_line） | 吞吐量 | ≥ 10,000 msg/s (P99) | integration test（FR-012） |
| Client RSS memory（steady state） | 内存 | ≤ 256MB (P99) | `/debug/vars` runtime.MemStats |
| Server RSS memory（steady state，无 backfill） | 内存 | ≤ 1GB (P99) | `/debug/vars` runtime.MemStats |
| Server RSS memory（含 backfill peak） | 内存 | ≤ 4GB (P99) | `/debug/vars` runtime.MemStats |
| E2E latency budget（P95，同区域；FR-029） | 延迟分解 | client <50ms + NATS <10ms + server <100ms | 各段独立 histogram |

> [COMPUTED, HIGH] §17 原 P99 指标均为单环节延迟；FR-029 新增端到端 freshness SLA（event_time → persist/fanout）与 stale alert 阈值，覆盖单环节指标无法表达的"数据链路整体滞后"与"断流"两类数据质量风险。schema 漂移检测（字段增删/类型变更）由 CI gate 在 parser 单测层守门，不在此表。
> [COMPUTED, HIGH] v3.9.0 新增 WS 吞吐（≥10K msg/s）、内存预算（client 256MB / server 1-4GB RSS）、端到端延迟预算分解（client<50ms+NATS<10ms+server<100ms P95），覆盖原表缺失的吞吐/内存/跨段延迟三个维度。

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

> **OpenTelemetry 集成要求（P1 · 来源 S28/FR-039）**：生产部署必须引入 OpenTelemetry SDK (`go.opentelemetry.io/otel`)，在以下关键路径创建 Span，并通过 W3C Trace Context (`traceparent` header) 跨进程传播。

| Span 名 | 说明 | 进程 |
|---------|------|------|
| `binance.client.normalize` | 原始事件规范化 | client |
| `binance.client.map` | 映射为 canonical event | client |
| `binance.client.publish` | natsx JetStream 发布 | client |
| `binance.client.puback_wait` | 等待 PubAck | client |
| `binance.server.consume` | natsx consumer 收到消息 | server |
| `binance.server.validate` | server 端验证 | server |
| `binance.server.idempotency_check` | 幂等性检查 | server |
| `binance.server.store` | 存储写入（taosx/pg/redis/ch） | server |
| `binance.server.kafkax_dispatch` | `kafkax` fanout handoff | server |
| `binance.server.ack` | msg.Ack() | server |

**Trace Context 传播规范**：
- Client → Server（NATS）：`traceparent` 注入 NATS message header
- Server → Downstream（Kafka）：`traceparent` + `binance-trace-id` 注入 Kafka record header
- 采样率：通过 `observability.tracing.sample_rate` 配置（默认 0.1）；`/debug/pprof` 和 admin 端点强制 100%
- 日志关联：slog 自动注入 `trace_id` + `span_id` 结构化字段

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
- **审计日志完整性（FR-041）**：所有 `POST /api/v1/admin/*` 写操作必须记录审计（actor/action/before/after/timestamp/client_ip）；数据生命周期事件（retention 删除/reconcile 差异/rehydrate 触发/DLQ 入队）必须写入 `binance_lifecycle_audit` 表；`audit_log` 表设 `REVOKE UPDATE, DELETE` 实现 append-only；审计日志保留期 ≥ 1 年，超期归档 OSS
- **凭证轮转（S35）**：所有 infra 凭据（PG/Redis/Kafka/NATS/TDengine/ClickHouse/OSS API Key/Binance API Key）必须定义轮转 runbook，含轮转周期（建议 90d）、轮转步骤、验证方法；轮转操作本身须记录到 audit_log
- **数据合规销毁（FR-044）**：按 `data_classification` 字段分类（market_public/market_derived/operational/audit）；合规保留期到达后执行不可逆销毁并生成 `certificate_of_destruction`

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
| Client/server import boundary | `BOUNDARY-GATES.md` §3-§4 gate scripts | 零跨边界 import |
| No `internal/cs` runtime dependency | `BOUNDARY-GATES.md` §5 gate script | 零 `internal/cs` runtime import；合法共享契约为 `internal/wire` |
| No same-process C/S communication | `BOUNDARY-GATES.md` §6 gate script | 零生产同进程 C/S wiring；`cmd/binance-smoke` 仅作 smoke/self-test 例外 |
| Binance-specific storage ownership | `BOUNDARY-GATES.md` §7 gate script | 零 generic market_data/strategy 所有权声明；Binance-specific persistence/API/fanout 明确归属 server |
| Wire contract externality | `BOUNDARY-GATES.md` §8 gate script | 零 local `.proto`/gRPC ingest schema；当前 runtime 允许 HTTP JSON `/ingest` + `internal/wire` skeleton |
| Domain-market source | `BOUNDARY-GATES.md` §9 gate script | 零独立 canonical enum 定义 |
| Admin boundary | `BOUNDARY-GATES.md` §10 gate script | 零跨模块 admin mutation；server admin surface 保持在 server 边界内 |
| go.mod dependency compliance | `BOUNDARY-GATES.md` §11 gate script | 边界 direct dependency 集合保持合规 |

### 部署与发布 Gate（FR-037）

| Gate | 命令/检查 | 通过条件 |
|------|----------|----------|
| Feature flag consistency | `grep -r "XGO_BINANCE_FEATURE_" cmd/ internal/` | 所有 feature flag 有对应 env var 文档 + 默认 off |
| Deployment health check | canary 后自动 `curl /readyz` + `curl /metrics` | `/readyz` 200 + 错误率 < 1% + P99 延迟 < 基线 × 1.5 |
| Rollback verification | `kubectl rollout undo deployment/binance-server --to-revision=N` | rollback 后 `/readyz` 200 + 无数据丢失 |
| Schema version gate | `grep SchemaVersion internal/wire/types.go` | MAJOR bump 必须有 ADR + 兼容矩阵更新 + 双端协调计划 |

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

### SchemaVersion 语义化策略（FR-042）

| 规则 | 定义 |
|------|------|
| **格式** | `MAJOR.MINOR`（如 `v1.0`、`v2.3`） |
| **MAJOR 变更** | 字段删除、字段重命名、字段类型变更、wire 格式变更 —— **破坏性**，需蓝绿协调 + ADR |
| **MINOR 变更** | 新增可选字段（旧 consumer 忽略） —— **向后兼容**，可独立升级 |
| **Terminal Reject** | server 收到未知 MAJOR → `BNC-014 ErrSchemaVersionIncompatible`，不尝试解析 |
| **兼容矩阵** | 在 `postgresx` 的 `binance_schema_versions` 表登记：version、fields_added、compatible_since、deprecated_at |
| **升级顺序** | 先升级所有 consumer（server + 下游分析域）支持新 MAJOR → 再升级 producer（client）→ 最后废弃旧 MAJOR |

---

## 22. Release DoD

`module/binance` 当前发布完成标准（覆盖 44 FR：FR-001~044，全部 Active）：

- [x] `binance-market` references 已移除或隔离到 migration history（BR-001）
- [x] `module/binance/client` 和 `module/binance/server` specs 完成并通过 spec-lint（即 `docs/governance/scoring/RUBRIC-spec.md` 结构评分门禁）
- [x] root/client/server TRACEABILITY.md 完成，所有需求可追溯
- [x] client/server task sets 独立可执行
- [x] Delivery semantics 明确为 at-least-once + idempotent acceptance（FR-004, FR-005）
- [x] natsx JetStream ManualAck 全链路语义已定义且 testable（BR-004）
- [x] ProductLine 和 InstrumentKey 碰撞 case 已文档化（FR-002, §10 Data Model）
- [x] Boundary gates 可在 CI 执行（FR-009, BOUNDARY-GATES.md）
- [x] Runtime mapping 未将 generic market_data/strategy ownership 放在 Binance 内（BR-006）
- [ ] 所有 FR 实现完成，所有 AC 验证通过
- [ ] 覆盖率 ≥ 80%
- [ ] CI Gate 全部通过（通用 + 模块专属）
- [ ] Performance Budget 达标
- [ ] Integration test 演示 `client → natsx → server → storage/API/kafkax` 完整数据流

> **完整 DoD 状态**：以上为本规格定义的发布完成标准。逐项验收状态（Done/Not Done）以 `ACCEPTANCE.md §5 Release Definition of Done` 为准，该文件额外包含 `FEATURES.md` 存在、`ACCEPTANCE.md` 自身存在等检查项。§23 Open Questions 中的已关闭问题不构成 DoD 门禁。

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

### Appendix C.2: Complete Data Flow Diagram v2

[COMPUTED][HIGH] v1 仅画热路径（real-time ingest）与四事件（tick/trade/bar/depth）。v2 补全温路径（OLAP ETL）、冷路径（归档）、读路径（API cache），并反映 6 事件类型（+funding_rate/mark_price）与 instrument_subtype identity。

```text
┌─────────────────────────────── Binance Exchange (REST/WS) ───────────────────────────────┐
│  Spot / USDⓈ-M(perp+delivery) / COIN-M(perp+delivery) / Options                          │
│  events: tick · trade · bar · depth · funding_rate · mark_price                          │
└───────────────────────────────────────┬─────────────────────────────────────────────────┘
                                        │ ▼ HOT PATH (real-time, P99 < 50ms)
                   ┌────────────────────┴───────────────────┐
                   │  CLIENT (binance-client)               │
                   │  connector → catalog → parser          │
                   │  → normalizer → canonical mapper       │  ◄── module/domain_market
                   │    (instrument_subtype ∈ InstrumentKey)│      (InstrumentSubtype: perpetual/delivery)
                   │  → idempotency key → natsx publisher   │  ◄── module/natsx (JetStream PubAck)
                   └────────────────────┬───────────────────┘
                                        │ binance.market.{product_line}.{event_type}
                                        │ Stream=BINANCE_MARKET, Retention=7d, at-least-once
                                        ▼
                   ┌────────────────────┴───────────────────┐
                   │  SERVER (binance-server, ManualAck)     │
                   │  validation → redisx SetNX idempotency  │  ◄── module/redisx
                   │  → taosx WriteBatch (hot store)         │  ◄── module/taosx
                   │  → postgresx upsert (instrument catalog)│  ◄── module/postgresx
                   │  → kafkax Send (downstream fanout)      │  ◄── module/kafkax
                   │  → msg.Ack()  ← 仅 storage+kafkax 全成功 │      topic=binance.{pl}.{et}.v1
                   └──────┬─────────────────┬────────────────┘
                          │                 │
          ┌───────────────▼───┐    ┌────────▼─────────────────────────────────┐
          │  kafkax fanout     │    │  WARM PATH (OLAP ETL, 每 5min)            │
          │  → module/         │    │  coordinator lease (redisx SetNX, 10s)    │  ◄── FR-011
          │  market_data       │    │  → taosx 聚合 1m_ohlcv/5m_vwap/15m_stats  │  ◄── FR-010
          │  (exchange-neutral)│    │  → clickhousex WriteBatch (analytics)     │  ◄── module/clickhousex
          └────────────────────┘    └────────┬──────────────────────────────────┘
                                              │
                                     ┌────────▼─────────────────────────────────┐
                                     │  COLD PATH (archive, daily)               │
                                     │  ossx parquet                             │  ◄── module/ossx
                                     │  binance/{pl}/{symbol}/{YYYY}/{MM}/{DD}/  │  ◄── FR-008
                                     │    {event_type}.parquet                   │
                                     │  ETag 校验通过 → 删 taosx 热数据           │
                                     └──────────────────────────────────────────┘

┌─────────────────────────────── READ PATH (HTTP API) ─────────────────────────────────────┐
│  GET /api/v1/market/{ticks,bars,depth,trades,funding_rates,mark_prices}/:symbol           │
│      │                                                                                     │
│      ▼                                                                                     │
│  redisx hot cache (tick/bar 60s, depth 5s)  ◄── module/redisx    hit → 200 (P99 < 5ms)    │
│      │ miss                                                                                │
│      ▼                                                                                     │
│  taosx 直查 (hot store)                    ◄── module/taosx       miss → 200              │
│                                                                                            │
│  OLAP analytics (vwap/top-movers/correlation/volume-profile)                               │
│      → clickhousex query                  ◄── module/clickhousex 不可达 → 503 (不阻塞实时) │
└───────────────────────────────────────────────────────────────────────────────────────────┘
```

[KNOWN][HIGH] 路径分层：
- **HOT**：client→natsx→server→taosx/kafkax，实时 ingest，P99 < 50ms（FR-001~008）
- **WARM**：taosx→clickhousex ETL，5min 聚合，coordinator lease 互斥（FR-010/FR-011）
- **COLD**：taosx→ossx parquet 归档，daily，ETag 校验后删热数据（FR-008）
- **READ**：Gin API→redisx→taosx 三级读 + clickhousex OLAP 独立支路（FR-007/FR-007a）

[COMPUTED][HIGH] instrument_subtype（perpetual/delivery）在 v2 图中由 canonical mapper 注入 InstrumentKey，贯穿 taosx tag / postgresx catalog / kafkax payload / ossx path 元数据，但不进入 natsx subject——与 NAMING §1.1 承载规则一致。

## Appendix D: Acceptance Criteria Registry（已迁移）

> **v2.0.0 历史遗物已迁移至 [`docs/migrations/ac-bnc-legacy-mapping.md`](../../../docs/migrations/ac-bnc-legacy-mapping.md)。** AC-BNC-001~018 与 AC-001~018 一一对应；完整 AC 注册表维护于 [module/binance/matrix/TRACEABILITY.md §5](../matrix/TRACEABILITY.md#5-ac--tc-完整映射)，实现状态见 [module/binance/spec/ACCEPTANCE.md §2](ACCEPTANCE.md#2-功能验收矩阵) 与 [module/binance/matrix/TRACEABILITY.md §6](../matrix/TRACEABILITY.md#6-覆盖率仪表盘)。

---

## Appendix E: Upstream Contract Gate Closure

> 本节是 PR-007 运行时实现前的上游契约链闭合验证记录，原以 §0 形式置于文档前部，现按 23 节模板规整为附录 E。原内容完整保留，仅顶层标题变更。


在从 docs baseline 推进到运行时实现前，必须逐项验证以下上游契约链闭合条件：

| # | Gate | 验证 | 状态 |
|---|------|------|:----:|
| G0-1 | `module/natsx` JetStream stream `BINANCE_MARKET` + subject pattern `binance.market.{product_line}.{event_type}` + durable consumer 规范 | natsx SPEC + v2.0.0 RUNTIME-MAPPING.md | ✅ |
| G0-2 | `module/domain_market` `ProductLine`(4值)/`InstrumentKey`(12维)/`MarketFactEnvelope` canonical 类型 | domain_market SPEC v1.0.1 §10 | ✅ |
| G0-3 | `redisx`/`taosx`/`postgresx`/`ossx`/`kafkax`/Gin ownership chain ready | server SPEC §7/§9 + v2.0.0 RUNTIME-MAPPING.md | ✅ |
| G0-4 | binance OQ-001（`natsx` + `domain_market` envelope ready?） | 已确认：本 SPEC §9 | ✅ |
| G0-5 | market_data consumption via REST/`kafkax` ready | 已确认：本 SPEC §9.2 | ✅ |
| G0-6 | BOUNDARY-GATES.md 全部 10 道 runtime 门禁有可执行脚本 | 10/10 (2026-06-23 round 2, evidence commit `71e2a6e8bb5591c43e8a2ebfff8c7645bf030786`) | ✅ |

> **6/6 通过** — 上游契约链闭合。本 SPEC 处于 Approved 状态，可进入运行时实现阶段（PR-007）。实现时必须严格遵循 natsx JetStream subject 规范、domain_market §10 canonical semantics、Gin REST API `/api/v1/market/*` 契约。

---
