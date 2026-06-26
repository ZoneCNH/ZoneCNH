# module/binance SPEC

## 1. Metadata

- Status: Approved
- Spec-Version: v3.7.1
- Last-Updated: 2026-06-26 (v3.7.0→v3.7.1: 补齐 FR-012~030 共 19 条 WHEN/THEN/AND 行为规范——此前仅存在于 FR→AC 映射索引和 TC 矩阵的追溯锚点、缺少可读需求规格；新增 TC-043~049 至 §16 测试矩阵（闭合 TC 总数十进制缺口 61→65）；新增 BNC-017/BNC-018 至 §12 错误码表；新增 FR-031~036 Draft 交叉引用至 §7；FR-021 与运行时对齐——IndexPrice 作为 mark_price 事件字段承载而非独立 event_type；FR-019 MaxConcurrent 默认值对齐运行时 5→4；FR-025 限流拆分对齐运行时 cold_start/repair 命名；更新 Appendix D 弃用声明 FR/AC 计数 30→38/104→130；对齐 Runtime-Anchor `/home/binance@756fbc5`；审计覆盖 7 个依赖模块规范无冲突；新增 SPEC-Runtime 异步演进说明 + 修复 registry.yaml maturity_ref 引用断裂；**同日：新增 Appendix F（SLA 框架）+ Appendix G（DR 要求）+ NFR-028**，补齐 `report/binance/` 数据成熟度评估报告中识别的 spec 缺口）
- Owner: ZoneCNH
- Layer: 数据域 · 行情
- Runtime-Version: v0.2.0
- Runtime-HEAD: `756fbc5` (Plan008 全部 40 Task + fix/redis-username-taos-websocket；PR #145 合并)
- SPEC-Runtime 关系：**异步演进** — SPEC v3.7.1 覆盖全部 47 FR（含 13 Pending + 6 Draft），runtime HEAD 实现了其中 24/37 current FR（65%）。
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
| C7 | **Client 不落盘**——不直接写入 taosx/postgresx/redisx/clickhousex/ossx（见 §4.3.2 C-D1~C-D6）。 | BOUNDARY-GATES §7；SPEC §4.3.2。 |
| C8 | **Server 不直连交易所**——不发起 Binance REST/WS 连接，不持有交易所 API key（见 §4.3.3 S-D1~S-D7）。 | BOUNDARY-GATES §7；SPEC §4.3.3。 |

以上约束对任何标记为 "production" 的部署 **不可协商**。`cmd/binance-smoke` 本地 self-test 是 C1 的唯一例外（仅限开发验证）。**C7/C8 是最严格的数据边界约束——任何违反 C7（client 落盘）或 C8（server 直连交易所）的代码改动应被 CI gate 阻断。**

### 4.2 Production Readiness Gates

Plan008 的 `release_closeable=YES` 只表示 release gate 可关闭；它不自动把 FR 投影提升为全 Done。任何 production-level claim 必须同时满足下列门禁，并在 `TRACEABILITY.md` / `ACCEPTANCE.md` 绑定 runtime SHA、CI run 或可审计 evidence。

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

### 4.3 Data Scope & C/S Boundary — Client/Server Data Responsibilities

> 本节严格定义 client 和 server 各自的数据职责边界。**任何一条数据路径必须明确由 client 或 server 单方拥有**——不可存在"双方都可做"的灰色地带。违反本节边界的代码改动应被 CI gate 阻断。

#### 4.3.1 Data Classification（数据分类）

| 分类 | 定义 | 产生方 | 消费方 | 持久化 | 示例 |
|------|------|:------:|:------:|:------:|------|
| **实时行情** | 通过 WebSocket 持续推送的 tick/trade/bar/depth/funding_rate/mark_price | client | server | server→taosx | `BTCUSDT@ticker`、`ETHUSDT@depth20@100ms` |
| **历史行情** | 通过 REST 按需拉取的历史 klines/aggTrades | client | server | server→taosx | `GET /api/v3/klines?symbol=BTCUSDT&interval=1m` |
| **参考数据** | 交易所符号目录、合约规格、交易规则 | client | server | server→postgresx | `exchangeInfo` 全量 + 6h diff |
| **控制面数据** | stream 订阅状态、admin 操作、审计日志 | client+server | client+server | server→postgresx | `control.instruments.changed`、`admin.symbols.reload` |
| **运维数据** | metrics、logs、traces、alerts | client+server | 外部（Prometheus/Loki/Jaeger） | 外部（不持久化于模块内） | `binance_storage_bytes_total` |

#### 4.3.2 Client Data Boundary（client 数据边界）【硬】

| # | 规则 | 说明 |
|---|------|------|
| C-D1 | **client 不落盘** — 不直接写入 taosx/postgresx/redisx/clickhousex/ossx | 唯一例外：cursor 可写入 postgresx，但需经 natsx control subject 由 server 代理 |
| C-D2 | **实时数据**：connect→parse→normalize→`natsx.Publish()` → 等待 PubAck → 责任结束 | client 不关心 server 是否/何时消费；不缓存已发布消息（JetStream 持久化兜底） |
| C-D3 | **历史数据**：REST fetch→normalize→`natsx.Publish()` 进入 backfill subject | 与实时数据共用 normalize pipeline；使用独立 subject 标记为 `replay` 事件；不管理 cursor 持久化 |
| C-D4 | **参考数据**：exchangeInfo REST→parse→diff→`natsx.Publish(control.instruments.changed)` | 6h 定时 diff-only 刷新；全量仅在启动时拉取；不在 client 内存中持久保留 diff 历史 |
| C-D5 | **product_line 启停**：每条 product_line 的采集可独立启停，不影响其他线 | 由 server 通过 `control.symbols.changed` 控制；client 不自行决定采集范围 |
| C-D6 | **禁止行为**：client 不得暴露查询 API、不得广播到 kafkax、不得执行对账/归档/retention | 这些全部属于 server 职责 |

#### 4.3.3 Server Data Boundary（server 数据边界）【硬】

| # | 规则 | 说明 |
|---|------|------|
| S-D1 | **server 不直连交易所** — 不发起 Binance REST/WS 连接 | 所有交易所数据必须经 natsx 从 client 获取 |
| S-D2 | **实时数据接收入口**：`natsx.Subscribe(binance.market.*)` → validate→idempotency→store(taosx)+cache(redisx)→Ack | 仅 Ack 在所有写入成功后；失败 NakWithDelay |
| S-D3 | **历史数据接收入口**：`natsx.Subscribe(binance.market.*.replay)` → 与实时数据共享 validate+idempotency pipeline | `replay` 标记的事件：优先级低于实时（FR-025 80/20 split）；跳过 hot cache（不污染实时缓存） |
| S-D4 | **存储职责**：taosx（时序行情）、postgresx（元数据/审计/cursor）、redisx（热缓存/幂等/锁）、clickhousex（OLAP ETL）、ossx（归档） | 各存储层独立失败不影响其他层；postgresx 为 cursor/audit 的 persistence-of-record |
| S-D5 | **查询服务**：Gin REST API 面向 market_data 和下游消费者 | 实时查询走 redisx 热缓存（<5ms），历史查询走 taosx，分析查询走 clickhousex |
| S-D6 | **广播职责**：kafkax fanout 到 8 个分析域消费者 | topic = `binance.{product_line}.{event_type}.v1`；handoff 成功后 Ack |
| S-D7 | **禁止行为**：server 不得发起 Binance API 调用、不得管理 WebSocket 连接、不得持有交易所 API key | 这些全部属于 client 职责 |

#### 4.3.4 Historical Data Sync Rules（历史数据同步规则）【硬】

| 规则 | 值 | 说明 |
|------|-----|------|
| **ExchangeInfo 同步周期** | 6h（`FOUNDATIONX_BINANCE_EXCHANGE_INFO_REFRESH_INTERVAL`） | 启动时全量拉取，之后 diff-only；仅在发现变更时发布 `instruments.changed` |
| **Backfill 触发方式** | 按需（admin API `POST /api/v1/admin/backfill`）+ 自动（gap detection 触发） | 不自动全量回填；每次 backfill 创建 job_id 追踪 |
| **Reconciliation 周期** | 每日 04:00 UTC（FR-026） | 对账 taosx vs Binance REST klines；容差 0.01% |
| **Archive 周期** | 每日 02:00 UTC（FR-006d） | 扫描 cutoff 前数据→写入 OSS→ETag 校验→删热 |
| **Retention 清理周期** | 每日 03:00 UTC（FR-006e） | 与 archive 错开 1h；先验证归档完整性后删除 |
| **Cold rehydration** | 按需（admin API） | OSS→taosx 回热；24h TTL；202 job_id |

#### 4.3.5 Starting Time Point（起始时间点）【硬】

| 数据类型 | 起始点 | 规则 |
|---------|--------|------|
| **实时行情（WS）** | 进程启动时刻 `T0` | 无历史补偿——WS 数据从连接建立时刻开始，丢失的 tick/trade 通过 backfill 补齐（如有需要） |
| **历史 K 线（REST）** | 默认 `T0 - 30d`（可配 `FOUNDATIONX_BINANCE_BACKFILL_WINDOW`） | 首次 starting point 由 admin 指定；cursor 持久化于 postgresx |
| **ExchangeInfo** | 进程启动时刻 `T0` | 启动拉取全量；之后 6h diff |
| **Backfill cursor** | 首次 `POST /api/v1/admin/backfill` 指定的 `from_date` | cursor 持久化于 postgresx `backfill_cursors` 表；重启后从上次 cursor 恢复 |
| **Reconciliation** | 首次运行的 04:00 UTC | 对账范围：上一次 reconciliation 的 `checked_until` 到 `NOW() - 1h` |
| **Archive** | 首次运行的 02:00 UTC | 归档范围：taosx 中 `event_time < cutoff` 的数据（cutoff = NOW() - retention_period） |

#### 4.3.6 Client/Server 交互数据流字符图

```text
┌── CLIENT (交易所侧) ──────────────────────────────────┐
│                                                        │
│  Binance Exchange                                      │
│    │ WS (实时)  │ REST (历史/参考)                      │
│    ▼            ▼                                      │
│  connector   history_rest / exchangeinfo               │
│    │            │                                      │
│    ▼            ▼                                      │
│  parser → normalize → mapper                           │
│                  │                                     │
│                  ▼                                     │
│  ┌─ natsx.Publish ─────────────────────┐              │
│  │  binance.market.{pl}.{et}          │              │
│  │  binance.market.{pl}.{et}.replay   │              │
│  │  binance.control.instruments.      │              │
│  │    changed                         │              │
│  └────────────────────────────────────┘              │
│                                                        │
│  ❌ 禁止: 直连 postgresx/taosx/redisx/oss/clickhouse  │
│  ❌ 禁止: 暴露 REST API                                │
│  ❌ 禁止: kafkax fanout                                │
└────────────────────────────────────────────────────────┘
           │ natsx JetStream (唯一通信通道)
           ▼
┌── SERVER (内网侧) ────────────────────────────────────┐
│                                                        │
│  ┌─ natsx.Subscribe ────────────────────┐             │
│  │  binance.market.>                    │             │
│  │  binance.control.>                   │             │
│  └──────────────────────────────────────┘             │
│    │                                                    │
│    ▼                                                    │
│  validate → idempotency → processor                    │
│    │                                                    │
│    ├→ taosx (时序存储)                                   │
│    ├→ redisx (热缓存 + 幂等标记 + 分布式锁)              │
│    ├→ postgresx (元数据 + 审计 + cursor)                 │
│    ├→ clickhousex (OLAP ETL)                             │
│    └→ ossx (冷归档)                                      │
│    │                                                    │
│    ├→ Gin REST API :8080 (/api/v1/market/*)              │
│    └→ kafkax fanout (binance.{pl}.{et}.v1)               │
│                                                        │
│  ❌ 禁止: 直连 Binance Exchange                         │
│  ❌ 禁止: 持有交易所 API key                             │
└────────────────────────────────────────────────────────┘
```

> 此图与 §2 Summary 的数据流字符图互补——§2 是简化的单线图，本图显式标注了每端的禁止行为和数据分类路径。

---

### 4.4 Client/Server Boundary Contract — 不可协商的硬边界

> **本节是 `module/binance` 的架构宪法条款。** 以下 8 条约束定义了 client 和 server 之间不可逾越的分界线。任何违反本节约束的代码改动应被 CI gate 自动阻断，PR review 直接拒绝。

#### 核心原则

```
CLIENT = 交易所侧 · 只采集 · 只发布 · 不落盘 · 不查询 · 不广播
SERVER = 内网侧   · 只消费 · 只存储 · 只查询 · 只广播 · 不直连交易所

CLIENT ──(唯一通道: natsx JetStream)──→ SERVER
        ←(控制面: natsx control subjects)→
```

#### 包级别边界映射

| Go Package | 归属 | 允许 Import |
|-----------|:----:|------------|
| `cmd/binance-client/` | **CLIENT** | natsx, domain-market, domain-exchange, configx, binance-connector-go |
| `internal/client/` | **CLIENT** | 同上 + internal/wire |
| `internal/client/connectors/` | **CLIENT** | 同上 |
| `internal/client/publisher/` | **CLIENT** | **仅** natsx, domain-market, internal/wire |
| `cmd/binance-server/` | **SERVER** | natsx, domain-market, domain-exchange, redisx, postgresx, taosx, clickhousex, kafkax, ossx, gin, bootstrap, configx |
| `internal/server/` | **SERVER** | 同上 + internal/wire |
| `internal/server/storage/` | **SERVER** | 同上（完整 infra 访问） |
| `internal/server/api/` | **SERVER** | gin, redisx, taosx, clickhousex, postgresx |
| `internal/wire/` | **共享** | domain-market, domain-exchange（仅类型定义，无 infra 依赖） |
| `pkg/` | **共享** | 无限制（通用工具层） |

#### 8 条不可协商约束

| # | 约束 | 违规示例 | 阻断方式 |
|---|------|---------|---------|
| ⛔ C1 | **Client 不落盘**：`internal/client/` 禁止 import `redisx/postgresx/taosx/clickhousex/ossx` | `history_state_postgres.go` import postgresx ← **已知违规** | CI `rg` gate（BOUNDARY-GATES §15） |
| ⛔ C2 | **Server 不直连交易所**：`internal/server/` `cmd/binance-server/` 禁止 import `binance-connector-go` 或 `gorilla/websocket`（exchange-facing） | server 调用 `binance.NewSpotClient()` | CI `rg` gate（BOUNDARY-GATES §16） |
| ⛔ C3 | **通信仅经 natsx**：client↔server 全部消息（行情+控制+回填）必须经 natsx JetStream subject；禁止 gRPC/HTTP/共享内存 | `gRPC ingest server` 在 server 中监听 | CI wire-contract gate（BOUNDARY-GATES §8） |
| ⛔ C4 | **Client 不暴露查询 API**：`cmd/binance-client/` 仅暴露 admin `:8081`（/healthz /readyz）；禁止 `/api/v1/market/*` | client 暴露 `GET /api/v1/market/ticks` | CI API surface gate |
| ⛔ C5 | **Server 不持有交易所凭据**：`cmd/binance-server/` 禁止读取 `FOUNDATIONX_BINANCE_API_KEY/SECRET` | server 从 env 读取 Binance API key | CI secret gate |
| ⛔ C6 | **Client 不广播**：`internal/client/` 禁止 import `kafkax` | client 直接 kafkax.Send | CI `rg` gate |
| ⛔ C7 | **Server 不采集**：`internal/server/` 禁止 import `binance-connector-go` 或任何 exchange connector | server 发起 REST klines 请求 | CI `rg` gate（同 C2） |
| ⛔ C8 | **共享层无 infra**：`internal/wire/` `pkg/` 禁止 import 任何 Foundation 模块（natsx/redisx/kafkax/postgresx/taosx/clickhousex/ossx/gin） | wire 包依赖 postgresx | CI `rg` gate |

#### 违规后果

```
PR 提交 → CI boundary-gates.sh 扫描
  ├── 全部 15 gates PASS → ✅ PR 可合并
  └── 任一 gate FAIL → ❌ PR 阻断
        └── 修复方式：
            1. 删除违规 import / 移动代码到正确侧
            2. 重跑 boundary-gates.sh 验证
            3. 无法修复 → 提交 ADR 申请边界例外（需架构审查批准）
```

#### 已知违规与修复计划

| 违规 | 文件 | 计划 | 状态 |
|------|------|------|:----:|
| C1 违规 | `internal/client/history_state_postgres.go` import postgresx | Phase A: 移至 `internal/server/storage/` | ⬜ 待执行 |
| C1 违规（潜在） | `internal/client/history_lifecycle.go` 调用 history_state_postgres | Phase A: 随 history_state_postgres 一起迁移 | ⬜ 待执行 |
| C1 违规（潜在） | `internal/client/archive_manifest.go` 管理归档状态（应属 server） | Phase A: 移至 server | ⬜ 待执行 |
| C1 违规（潜在） | `internal/client/cron_reconcile.go` 对账逻辑（应属 server） | Phase A: 移至 server | ⬜ 待执行 |

> 以上 4 项违规的详细迁移方案见 `report/binance/structural-architecture-analysis-20260626.md` Phase A。

## 5. Non-goals

`module/binance` 明确不做以下事情。数据边界规则详见 §4.3.2（client 禁止行为 C-D6）和 §4.3.3（server 禁止行为 S-D7）。

| 不做 | 原因 |
|------|------|
| 定义 canonical domain model（ProductLine/InstrumentKey 等） | 由 `module/domain_market` 拥有 |
| 实现 strategy API / trading decision | 属于分析域和决策域 |
| 实现 order execution | 属于执行域 |
| 兼容旧 `binance-market` Provider | 已移除 |
| 作为跨 CEX 通用 ingestion server | 本模块仅处理 Binance |
| 同进程运行 client + server | **违反分布式约束（见 §4 Goals）** |
| 保留 `internal/cs` 同进程桥接包为运行时依赖 | **必须删除** |
| client 直连 postgresx/taosx/redisx/oss/clickhousex | **违反 C7（见 §4.3.2 C-D1）** |
| server 直连 Binance Exchange（REST/WS） | **违反 C8（见 §4.3.3 S-D1）** |

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

### FR-001: Product-Line Support

**功能描述**：模块必须支持 Binance 四种产品线的行情数据采集。**数据边界**：全部四产品线的实时行情（WS）和历史行情（REST）采集由 client 独占执行；server 仅通过 natsx 消费已发布事件，不直连交易所（§4.3.3 S-D1）。

**WHEN** 配置启用 Spot 产品线
**THEN** client 通过 Spot connector 采集 Binance spot market data（WS: tick/trade/bar/depth；REST: klines/aggTrades/exchangeInfo）
**AND** 采集的实时数据通过 `natsx.Publish(binance.market.spot.*)` 发布；历史回填数据通过 `natsx.Publish(binance.market.spot.*.replay)` 发布
**AND** server 通过 `natsx.Subscribe(binance.market.spot.*)` 消费实时数据，通过 `natsx.Subscribe(binance.market.spot.*.replay)` 消费回填数据

**WHEN** 配置启用 USDⓈ-M 产品线
**THEN** client 通过 USDⓈ-M connector 采集 USDT/USDC 保证金合约行情
**AND** subject 前缀为 `binance.market.um_perp.*`（永续）和 `binance.market.um_perp.*.replay`（回填）

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

**功能描述**：模块边界通过 CI gate 强制执行。**需求归类说明**：本条 FR 的行为主体是 CI pipeline（非模块运行时），语义上更接近 Business Rule。保留为 FR 以维持现有 TRACEABILITY FR→AC→TC→Task 追溯链连续性；其对应的 BR 条目为 BR-001~BR-009（见 §8 + `TRACEABILITY.md` §2）。

**WHEN** client 代码尝试 import server internal 包
**THEN** CI boundary gate §3 失败（对应 BR-002）

**WHEN** 任何代码 reintroduce `binance-market` 引用
**THEN** CI no-legacy gate §2 失败（对应 BR-001）

**WHEN** 模块内声明存储/query/strategy 所有权
**THEN** CI ownership gate §7 失败（对应 BR-006/BR-007）

**WHEN** 模块内定义本地 proto、gRPC ingest service 或独立 wire schema
**THEN** CI wire contract externality gate §8 失败（对应 BR-008）

**WHEN** runtime `go.mod` 缺失或错误归类边界依赖
**THEN** CI dependency compliance gate §11 失败（对应 BR-009）

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
**THEN** 计算 stream diff（new_streams、removed_streams、unchanged_streams）
**AND** 对新增 stream 发送 `SUBSCRIBE` 帧到对应 product_line 连接
**AND** 对移除 stream 发送 `UNSUBSCRIBE` 帧，不关闭 product_line 连接

**WHEN** WebSocket 连接意外断开
**THEN** 按指数退避重连（初始 1s，最大 60s），重连后自动恢复该连接上的所有活跃 subscription

**WHEN** product_line 连接池检测到连接被远端关闭（close frame）
**THEN** 清理该连接上的订阅状态，发起重连；重连期间该 product_line 的订阅标记为 `degraded`

**WHEN** `POST /api/v1/admin/streams` 请求运行时添加或移除订阅
**THEN** 更新 active stream registry，触发 stream diff，无需重启 client 进程
**AND** 变更记录写入 audit_log（FR-041）

> 注：Plan006/007 gap — stream 生命周期管理。AC-048~050 / TC-029。

### FR-013: Exchange Reliability Controls

**功能描述**：对 Binance 交易所 WebSocket/REST 连接实施可靠性控制，包括重试预算、速率限制和时钟偏差检测，防止客户端异常行为触发交易所限流或封禁。

**WHEN** WebSocket 或 REST 请求失败（connect timeout、read timeout、HTTP 5xx、WS close abnormal）
**THEN** 按重试预算（retry budget）执行指数退避重试
**AND** 每次重试消耗 budget token；budget 为 0 时暂停该 product_line 所有连接 60s 并告警

**WHEN** client 调用 Binance REST API（如 exchangeInfo、historical klines）
**THEN** 按 API weight 预算控制请求速率：每秒不超过配置的 `max_weight_per_second`
**AND** 收到 HTTP 429（rate limited）时自动降速 50%，5 分钟后逐步恢复

**WHEN** client 收到交易所事件
**THEN** 解析事件时间戳 `E`（event time），与本机时钟比对
**AND** 若偏差 `|event_time - local_time| > clock_skew_threshold`（默认 30s），记录 WARN 日志并上报 `binance_clock_skew_seconds` 指标

**WHEN** 连续 clock skew 超过阈值达 3 次
**THEN** 触发 ALERT；暂停该 product_line 消费；等待人工介入

> 注：Plan006/007 gap — exchange reliability controls。AC-051~053 / TC-030。

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
**AND** 无效窗口返回 `BNC-017`（ErrInvalidBackfillWindow）

**WHEN** backfill job 窗口通过校验
**THEN** 检查是否与已有 active/completed job 窗口重叠
**AND** 若重叠区间 > 0，拒绝创建并返回 `BNC-018`（ErrBackfillWindowOverlap）
**AND** 若通过，持久化 job 到 `postgresx`（`binance_backfill_jobs` 表），status = `pending`

**WHEN** backfill job 执行中且进程重启
**THEN** 从持久化 cursor 恢复：`cursor_event_time` 表示已回填到的时间点，重启后从 cursor 继续

**WHEN** backfill job 完成（cursor 到达 end）
**THEN** 更新 status = `completed`，记录 `completed_at`、`total_events`、`total_bytes`

> 注：Plan007 A1/G1 gap — 历史回填规划。AC-060~062 / TC-033。

### FR-017: Gap Detection and Replay

**功能描述**：自动检测实时数据流中的时间缺口，生成回放作业并保证幂等回放——同一缺口不重复生成作业，同一事件不重复写入。

**WHEN** gap detector 周期运行（默认每 5 分钟）
**THEN** 扫描 `taosx` 中每个 (product_line, symbol, event_type) 的事件时间戳序列
**AND** 检测相邻事件间隔 > 2× 预期间隔（tick 默认 2s × 2 = 4s，bar 默认 1m × 2 = 2m）的缺口

**WHEN** 缺口被检测到
**THEN** 生成 gap replay job：`{product_line, symbol, event_type, gap_start, gap_end}`
**AND** 通过 redisx `SetNX` 注册 job idempotency key（TTL = gap_end - gap_start + 1h），防止重复生成

**WHEN** gap replay job 执行
**THEN** 调用 Binance historical REST API 回填缺失区间
**AND** 每条回填事件通过 idempotency pipeline（FR-005）写入，保证不产生重复

**WHEN** gap replay job 完成
**THEN** 更新 job status = `completed`；记录 `gap_start`、`gap_end`、`replayed_events` 到 `binance_gap_replay_log` 表

**WHEN** 连续 3 个检测周期在同一 (product_line, symbol, event_type) 检测到缺口
**THEN** 触发 ALERT（可能为 upstream 数据源问题，非临时抖动）

> 注：Plan008 G2/G3 targets — 缺口检测与回放。AC-063~065 / TC-034。

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

**WHEN** release gate 检测到不一致（如 CHANGELOG 版本 ≠ release tag）
**THEN** release gate 失败，阻止发布

> 注：Plan007 G7/G8 gap — release evidence bundle。AC-081~083 / TC-040~041。

### FR-024: Runtime Config Hot Reload

**功能描述**：支持运行时 symbol catalog 热重载与 stream diff，无需重启 client/server 进程即可响应 symbol 上下架变更。当前覆盖：symbol catalog hot reload；全量 config hot reload（infra 连接、storage 装配等）经评估不推荐。

**WHEN** `POST /api/v1/admin/symbols/reload` 被调用
**THEN** 重新加载 symbol catalog（从 postgresx 或 exchangeInfo REST 拉取最新 symbol 列表）
**AND** 原子替换内存 catalog，计算与旧 catalog 的 diff（added_symbols、removed_symbols、unchanged_symbols）

**WHEN** catalog diff 检测到新增 symbol
**THEN** 在 active stream registry 中注册新 stream；对对应 product_line 连接发送 `SUBSCRIBE` 帧
**AND** 无需重启 client 进程

**WHEN** catalog diff 检测到移除 symbol
**THEN** 从 active stream registry 注销；发送 `UNSUBSCRIBE` 帧
**AND** 不移除历史数据，不关闭 product_line 连接

**WHEN** `POST /api/v1/admin/symbols/reload` 返回 HTTP 200
**THEN** response body 包含 reload 结果：`added_count`、`removed_count`、`unchanged_count`、`reload_duration_ms`
**AND** 变更记录写入 audit_log（FR-041）

**WHEN** catalog reload 失败（postgresx 或 exchangeInfo 不可达）
**THEN** 保留当前 catalog 不变；返回 HTTP 503 + 错误信息；记录 ERROR 日志

> 注：Plan007 A10 gap — runtime config hot reload。全量 config hot reload 经 FR-024 评估不推荐（infra 连接/存储装配热切换复杂度极高、收益低）。维持 symbol catalog hot reload（当前已 Partial 实现）。评估见 `module/binance/analysis/A10-FR024-HOT-RELOAD-EVAL.md`。AC-084~086 / TC-042。

### FR-025: Backfill Throttle & Priority

**功能描述**：对回填任务实施基于 token bucket 的加权限流，按优先级排序执行，确保实时数据流不受历史回填冲击。

**WHEN** backfill job 从 `queued` 进入 `running`
**THEN** 按 token bucket 算法控制回填请求速率：bucket 容量 = `backfill_rate_limit`（默认 20 req/s），refill rate = `backfill_rate_limit` tok/s
**AND** 每次 Binance REST API 调用消耗 1 token；token 不足时等待

**WHEN** 多个 backfill job 并发竞争 token
**THEN** 按权重分配 80/20 配额：cold_start（首次历史回填）占 80% token、repair（gap-fill + 每日对账）占 20% token
**AND** 同级内按 FIFO 顺序消费

**WHEN** backfill_token_bucket 连续 3 个 refill 周期 bucket 为空
**THEN** 递增 `binance_backfill_throttle_active_total` 指标，提示回填需求超过配置容量

**WHEN** 实时数据流（FR-004）的延迟 P99 超过阈值（默认 1s）
**THEN** 自动降低 backfill token refill rate 50%（实时优先）

> 注：Plan008 G2/G3 backfill throttle extension。AC-087~089 / TC-043。

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
**THEN** 返回该 job 的诊断字段：API call count、rate_limit_hit_count、retry_count、avg_latency_ms、token_bucket_wait_ms

> 注：Plan008 backfill observability extension。AC-096~098 / TC-046。

### FR-029: Data Quality & Freshness SLA

**功能描述**：定义端到端数据新鲜度 SLA 与质量监控，包括 event_time 到 persist/fanout 的延迟阈值、按 product_line 的 stale 告警策略和 schema drift 自动检测。

**WHEN** 实时 event 完成 storage 写入和 kafkax handoff
**THEN** 计算端到端延迟：`now() - event.event_time`
**AND** 暴露 Prometheus histogram `binance_e2e_latency_seconds{product_line, event_type}`

**WHEN** e2e latency 超过 stale 阈值
**THEN** spot/um/cm product_line：P50 > 30s → WARN、P99 > 60s → ALERT
**AND** options product_line：P50 > 60s → WARN、P99 > 120s → ALERT

**WHEN** freshness SLO 连续 3 个 scrape interval 不达标
**THEN** 触发 CRITICAL 告警 `BinanceDataFreshnessSLOBreach`；通知 on-call

**WHEN** schema drift detector 运行（默认每小时）
**THEN** 对比当前 taosx 超级表 schema 与 SPEC §11 DDL 契约
**AND** 检测新增/删除/类型变更列；差异记录到 `binance_schema_drift_log` 表
**AND** 若检测到 BREAKING 变更（列类型变更、列删除），触发 ALERT

**WHEN** 事件内容校验失败（如必填字段缺失、event_type 未知、数值越界）
**THEN** 记录到 `binance_data_quality_errors` 表（event_id、error_type、field、raw_value、timestamp）
**AND** 递增 Prometheus counter `binance_dq_errors_total{product_line, error_type}`

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

### FR-045: Alert Consumption Layer

**功能描述**：将 FR-014（metrics 暴露）和 FR-029（SLA 检测）的 L1 检测能力提升到 L2 告警——Prometheus metrics 必须有 alerting rules 消费并触发通知。闭合 `report/binance/data-maturity-assessment-20260625.md` 识别的"死信号"缺口。

**WHEN** 任何 FR-029 SLO 违约（stale > 阈值、gap_detected > 0、dlq_size > 0、coverage < 99.99%）
**THEN** Prometheus alerting rules 触发 Alertmanager 告警
**AND** Alertmanager 路由到 on-call 通知渠道（PagerDuty/webhook/Slack）
**AND** 告警含：SLO 名称、当前值、阈值、持续时长、受影响的 product_line

**WHEN** stale alert 触发（spot/um/cm 30s、options 60s）
**THEN** 自动触发 FR-017 gap detection，评估是否需要 backfill replay

**WHEN** alerting rule 本身不可达（Alertmanager down）
**THEN** binance-server `/readyz` 返回 503 + `alertmanager_unreachable` 原因

**WHEN** 任何新增 SLO 或修改现有阈值
**THEN** 同步更新 alerting rule 配置；PR 描述附新旧 rule diff

> 注：附录 F.3 的 10 项 SLO 各需至少 1 条 alerting rule。当前 metrics 已采集但无消费——这是 L1→L2 断裂的根因。

### FR-046: Graceful Shutdown

**功能描述**：client 和 server 进程在收到终止信号时执行优雅关闭，确保数据不丢失、consumer 位点不漂移。

**WHEN** `binance-client` 收到 SIGTERM/SIGINT
**THEN** 停止 WebSocket 连接（发送 close frame），flush 所有未发送的 natsx publish，等待 PubAck 或超时
**AND** 30s 超时后强制退出（exit code 0）；超时前完成的消息正常 Ack

**WHEN** `binance-server` 收到 SIGTERM/SIGINT
**THEN** 进入 drain 模式：natsx consumer 停止接收新消息，完成正在处理的消息（validate→store→fanout），flush kafkax producer buffer
**AND** `/healthz` 返回 503（就绪探针失败，k8s 停止路由流量）
**AND** `/readyz` 返回 shutting_down 状态

**WHEN** drain 超时（默认 60s）仍有未完成消息
**THEN** 记录 warn 日志（含未完成消息数和 idempotency keys）；强制退出（exit code 1）
**AND** JetStream durable consumer 重启后从上次 Ack 位置恢复（未 Ack 消息自动重投，FR-004 保障）

**WHEN** 关闭过程中 `redisx.DistLock` 持有 coordinator lease
**THEN** 释放锁（DEL key），防止 coordinator 选举延迟

> 注：AC-131~133 / TC-084~086。

### FR-047: Startup Configuration Validation

**功能描述**：server/client 启动时对全部必需配置做完整性检查，缺失或不可达时 fail-fast，避免部分启动后运行时崩溃。

**WHEN** `binance-server` 进程启动
**THEN** `validateStorageConfig()` 按序检查全部必需环境变量：
- `FOUNDATIONX_NATS_URL`（client+server 必需）
- `FOUNDATIONX_REDIS_PASSWORD`（server 必需）
- `FOUNDATIONX_POSTGRES_PASSWORD`（server 必需）
- `FOUNDATIONX_TAOS_PASSWORD`（server 必需）
- `FOUNDATIONX_CLICKHOUSE_PASSWORD`（server 必需）
- `FOUNDATIONX_KAFKA_PASSWORD`（server 必需，若 dispatcher=kafkax）
- `FOUNDATIONX_OSSX_BUCKET`（server 必需）
**AND** 缺失任一 → fail-fast 退出（exit code 1），stderr 列出所有缺失变量名

**WHEN** infra 连接测试失败（Dial timeout 5s）
**THEN** 指数退避重试 3 次（间隔 2s/4s/8s），仍失败则退出（exit code 2）
**AND** 日志记录失败原因（connection refused / timeout / auth error）

**WHEN** 非关键 infra 不可达（如 clickhousex 用于 OLAP 查询、非实时写入路径）
**THEN** server 可降级启动（log warn + `/readyz` 标记 `clickhousex_unreachable`），不阻塞实时 ingest path

**WHEN** `binance-client` 进程启动
**THEN** 验证 `FOUNDATIONX_NATS_URL`（必需）和 `FOUNDATIONX_BINANCE_API_KEY`（必需，除非 testnet 模式）
**AND** 缺失任一 → fail-fast 退出

> 注：AC-134~136 / TC-087~089。

> 注：FR-031~036 为 ExchangeInfo 同步规格草案（完整 WHEN/THEN 见 `specs/exchangeinfo-sync.md`）。当前 Status = Draft——需经 pipeline-arbiter 98 分门禁后翻转 Approved。**已知 spec-code 倒挂**：runtime `internal/client/exchangeinfo.go` / `exchangeinfo_refresh.go` / `exchangeinfo_option.go` 已部分实现 exchangeInfo 拉取逻辑，但 spec 侧仍为 Draft。FR-031~036 不计入当前 FR 状态投影（24 Done / 10 Partial / 13 Pending 的分母不含这 6 条）。阻塞根因：pipeline 四源评分瓶颈，非 FR 质量问题（FR-031~036 质量评级 ⭐⭐⭐⭐）。

### FR-031: ExchangeInfo Discovery (4 Product Lines)（Draft · 来源 `specs/exchangeinfo-sync.md`）

**功能描述**：client 实现四产品线 exchangeInfo 拉取与解析，修复 COIN-M/Options 的已知 API 陷阱。

**WHEN** client 进程启动且 `FOUNDATIONX_BINANCE_EXCHANGE_INFO_URL` 非空（或使用 mainnet 默认值）
**THEN** client 应分别拉取四产品线的 exchangeInfo endpoint，解析为 `CatalogEntry` 列表
**AND** 通过 `binance.control.instruments.changed` 发布给 server

**产品线 → endpoint 映射**（实测确认）：

| ProductLine | REST Endpoint | Status 字段 | Symbol 数组字段 | 备注 |
|-------------|--------------|------------|----------------|------|
| `spot` | `api.binance.com/api/v3/exchangeInfo` | `status`（`TRADING`） | `symbols` | 现有已实现 |
| `um_perp` | `fapi.binance.com/fapi/v1/exchangeInfo` | `status`（`TRADING`） | `symbols` | **新增** |
| `cm_perp` | `dapi.binance.com/dapi/v1/exchangeInfo` | **`contractStatus`**（`TRADING`） | `symbols` | **API 陷阱**：状态字段非 `status` |
| `options` | **`eapi.binance.com/eapi/v1/exchangeInfo`** | `status`（`TRADING`） | **`optionSymbols`** | **API 陷阱**：endpoint 非 `vapi`，数组非 `symbols` |

**API 陷阱文档化**（从 symbol-sync 实测得出）：COIN-M 用 `contractStatus`（非 `status`），误用返回 0 symbol；Options 用 `eapi.binance.com`（非 `vapi`），数据在 `optionSymbols` 数组（非 `symbols`）。

**扩展 CatalogEntry 字段**：新增 `ContractType`, `ExpiryDate`, `StrikePrice`, `OptionType`, `PricePrecision`, `QtyPrecision`, `MinQty`, `MaxQty`, `TickSize`, `Filters`(JSONB)

> 注：Draft，不计入 v3.7.0 基线投影。AC-131~134 / TC-066~068。

### FR-032: ExchangeInfo Persistence & Scheduled Refresh（Draft）

**功能描述**：server 消费 `instruments.changed` 落库 postgresx；client 每 6h 定时 diff-only 刷新。

**WHEN** server 消费 `binance.control.instruments.changed`
**THEN** 将 diff 中 Added/Updated 条目 upsert 进 postgresx `catalog_symbols`（扩展后 schema）
**AND** Removed 条目标记 `status='delisted'`（不物理删除，保留历史）

**WHEN** client 进程运行中
**THEN** 每 `FOUNDATIONX_BINANCE_EXCHANGE_INFO_REFRESH_INTERVAL`（默认 `6h`）重新拉取四产品线 exchangeInfo
**AND** 与本地 catalog 做 diff，**仅在发现变更时**发布 `instruments.changed`（diff-only，避免 PubAck 风暴）

**natsx control stream 声明**：当前 JetStream stream 仅声明 `binance.market.*.*`，`binance.control.*` 无对应 stream。server 启动时需 `AddStream` 声明 control stream（subject `binance.control.>`，retention=**LimitsPolicy**——非 WorkQueue，multi-server 广播语义）。

**diff 引擎**：`DiffCatalog(prev, next)` 基于复合键 `product_line:symbol`。`Updated` 判定收窄到采集决策字段（`status`/`sync_tier`/`base_asset`/`quote_asset`/`expiry_date`）；合约规格字段变化计为 `SpecUpdated`（单独标记，不触发 catalog reload）。

> 注：Draft。AC-135~138 + AC-112a~112c / TC-069~073。

### FR-033: Sync Tier Classification（Draft · 分类与字段，不含连接拓扑）

**功能描述**：定义 symbol 分级分类。连接拓扑部分见 FR-036。

**WHEN** 一个 symbol 被写入 `catalog_symbols`
**THEN** `sync_tier ∈ {L1_core, L2_extended, L3_full, disabled}`，默认 `disabled`（安全默认：未显式分级不同步）

| sync_tier | 意图流（spot/um/cm） | 意图流（options） | backfill 优先级 |
|-----------|---------------------|-------------------|----------------|
| `L1_core` | trade + bookTicker + kline_1m + depth20@100ms | optionTicker | P0 cold_start |
| `L2_extended` | trade + kline_1m + bookTicker | optionTicker | P1 cold_start |
| `L3_full` | trade + kline_1m | optionTicker | P2 cold_start |
| `disabled` | 无 | 无 | 不 backfill |

> options 仅有 `@optionTicker` 流，tier 差异化不体现在流类型，仅控制是否采集 + backfill 优先级。

**WHEN** admin 调用 `PATCH /api/v1/admin/symbols/{product_line}/{symbol}`
**THEN** `sync_tier` 可热更新，触发 stream drain/rebuild（复用 FR-024 + FR-036）

> 注：Draft。AC-139~142 / TC-074~076。连接拓扑拆分至 FR-036（第三轮审查）。

### FR-034: Selective Sync Whitelist（Draft）

**功能描述**：`product_lines` / `symbols.allow` / `symbols.deny` 三层过滤，优先级 deny>allow>tier。

**WHEN** client 启动或 admin reload 触发 catalog 刷新
**THEN** 最终采集决策按以下优先级裁决（deny 永远赢）：`deny → allow非空白名单 → status≠TRADING → product_lines未启用 → DB.sync_tier`

**配置字段**（`binancecfg.Config` 新增）：`ProductLines []string` / `SymbolsAllow []string` / `SymbolsDeny []string`，从 `FOUNDATIONX_BINANCE_*` 环境变量解析。

**WHEN** `POST /api/v1/admin/symbols/reload` 接受 `sync_tier`
**THEN** reload 后立即应用白名单过滤

> 注：Draft。AC-143~146 / TC-077~080。

### FR-035: Admin Surface Auth Hardening（Draft · FR-033/034 写操作的安全前置）

**功能描述**：client `AdminServer` 写操作鉴权加固。当前 `admin.go:58` 裸 `http.ServeMux` 无任何鉴权。

**WHEN** `AdminServer` 收到 `/api/v1/admin/*` 写请求（POST/PATCH/DELETE）
**THEN** 校验 `Authorization: Bearer <token>`（从 `FOUNDATIONX_BINANCE_ADMIN_TOKEN` 读取）
**AND** 空 token 时仅允许 localhost，拒绝远程写请求

**WHEN** `GET /healthz`、`GET /readyz`、`GET /api/v1/admin/streams`（只读）
**THEN** 不受鉴权影响，保持公开

**WHEN** 鉴权失败（401/403）
**THEN** 写入 `audit_log`（`action='admin_auth_denied'`、含 remote_addr 与 path）

> 注：Draft。AC-147~150 / TC-081~083。

### FR-036: Tier-Aware Connection Topology（Draft · 需前置 ADR）

**功能描述**：stream manager 按 `(productLine, tier)` 分组 WS 连接，不同 tier 用不同流组合。connector 架构从「1 线 1 连接」演进为「1 线 N tier 连接组」。

**WHEN** stream manager 为某 productLine 构建 WS 连接
**THEN** 按 sync_tier 分组，每组独立 WS 连接，不同 tier 的 symbol 不混入同一连接

**tier × productLine → 流组合映射**（`StreamsForProductLineTier`）：L1=trade+bookTicker+kline_1m+depth20@100ms；L2=trade+kline_1m+bookTicker；L3=trade+kline_1m。options 统一 `optionTicker`（按 symbol 数分批，单连接 1024 上限）。

**WHEN** tier 降级（L1→L3）
**THEN** 旧连接先 drain（NakWithDelay+DLQ）再 unsubscribe（BR-011）；升级异步不阻塞

**WHEN** 单组 symbol 数超限
**THEN** 拆分多连接（分批边界：spot L1=256 sym/conn，L3=512 sym/conn，options=1024 sym/conn）

> **FR-024 依赖风险**：增量 drain 依赖 FR-024 增量 diff（FR-024 当前 Partial 全量重连）。推荐方案：FR-036 自建 per-tier 增量 diff（解耦）。

> 注：Draft，建议前置 ADR。AC-151~154 / TC-074~076（与 FR-033 共享 TC）。

### FR-031~036 相关的业务规则（BR-010~BR-012，Draft）

| BR ID | 业务规则 | 验证方式 |
|-------|----------|----------|
| BR-010 | ExchangeInfo Diff-Only Publication：定时刷新须 diff 后发布，全量快照 24h 一次 | CI gate + 单元测试 |
| BR-011 | Tier Reassignment Safety：降级先 drain 再 unsubscribe，升级异步不阻塞 | 集成测试 |
| BR-012 | Options Expiry Batch Drain Smoothing：批量到期分批错峰（每批 20 个，间隔 2s） | 集成测试 |

> FR-031~036（Draft）和 FR-037~044（Current）已协调编号空间：Current 使用 AC-105~130 / TC-050~065，Draft 使用 AC-131~154 / TC-066~083。从 Draft 提升为 Active 时无需重新编号。完整设计讨论与 DB schema 扩展见 `specs/exchangeinfo-sync.md`。

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

### FR-038: taosx Data Retention Lifecycle（P0 · 来源 G6/S1/S2 · 规格见 FR-006e）

**功能描述**：对 taosx 热数据执行主动删除生命周期管理。与 FR-006d（OSS 归档）严格协同——先归档校验通过，后删热数据。**完整 WHEN/THEN 行为规范已定义于 FR-006e**（taosx Data Retention Lifecycle，FR-006 子条款），本条为 Plan008 要求的 P0 独立 FR 编号锚点，确保 G6 缺口在 TRACEABILITY 中有独立追溯行。

> 注：FR-006e（§7 FR-006 扩展）已定义 taosx retention 的完整行为规范（定时 DELETE + OSS ETag 前置校验 + 删除审计 + DB KEEP）。本条不重复 WHEN/THEN，引用 FR-006e 作为规范来源。详细验收标准见 AC-108~111 / TC-051~052。

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
| FR-024 Runtime Config Hot Reload | AC-084 ~ AC-086 | TC-042 | 管理端点 + 集成（catalog reload + stream diff + no-restart proof） |
| FR-025 Backfill Throttle & Priority | AC-087 ~ AC-089 | TC-043 | 单元 + 集成（token bucket weight 限流 + 80/20 配额 + 优先级排序） |
| FR-026 Daily Reconciliation Job | AC-090 ~ AC-092 | TC-044 | 集成（04:00 UTC 对账 + tolerance 阈值 + alerts 表写入） |
| FR-027 Cold Data Rehydration | AC-093 ~ AC-095 | TC-045 | 集成（OSS→taosx 回热 + 202 job_id + 24h TTL 过期） |
| FR-028 Backfill Progress API | AC-096 ~ AC-098 | TC-046 | httptest（jobs 列表 + coverage 时间戳 + 诊断字段） |
| FR-029 Data Quality & Freshness SLA | AC-099 ~ AC-101 | TC-047 | 集成 + metrics（freshness SLA + stale alert + schema drift） |
| FR-030 Options Chain Raw Field Pass-through | AC-102 ~ AC-104 | TC-048, TC-049 | 单元 + 契约测试（Options 原始字段透传，Greeks 归分析域） |
| FR-037 Release Safety Net | AC-105 ~ AC-107 | TC-050 | 集成 + CI（feature flag 开启/关闭 + canary 健康门禁 + 回滚验证） |
| FR-038 taosx Data Retention Lifecycle | AC-108 ~ AC-111 | TC-051, TC-052 | 集成（定时 DELETE + OSS ETag 前置校验 + 删除审计 + DB KEEP） |
| FR-039 Distributed Tracing (OpenTelemetry) | AC-112 ~ AC-114 | TC-053 | 集成（Span 埋点 + traceparent header 传播 NATS/Kafka + slog trace_id 关联） |
| FR-040 Resource Quota & Isolation | AC-115 ~ AC-118 | TC-054, TC-055 | 集成 + CI（Kafka quota + WS 连接池隔离 + API per-caller 限流 + CH 查询超时） |
| FR-041 Audit Log Completeness | AC-119 ~ AC-121 | TC-056, TC-057 | 单元 + CI（admin 写审计 + append-only REVOKE + 保留期验证 + OSS 归档） |
| FR-042 Schema Version Compatibility Policy | AC-122 ~ AC-124 | TC-058 | 单元 + CI（MAJOR terminal reject + MINOR 向后兼容 + 兼容矩阵校验） |
| FR-043 Cost Observability | AC-125 ~ AC-127 | TC-059 | 集成 + metrics（存储容量/带宽/分摊指标 + Prometheus 告警规则） |
| FR-044 Data Compliance & Destruction | AC-128 ~ AC-130 | TC-060, TC-061 | 单元 + 审计（数据分类标注 + 合规保留期 + 销毁证明 + 血缘文档） |
| FR-031~036（Draft） | AC-131 ~ AC-154 | TC-066 ~ TC-083 | 定义于 `specs/exchangeinfo-sync.md`；Draft 状态不计入当前基线投影 |

**AC 总数**：130（AC-001 ~ AC-130）· **TC 总数**：65（TC-001 ~ TC-065，全覆盖 FR-001~044，含 FR-012~030 的 TC-043~049 + FR-037~044 的 TC-050~065）· Draft 预留 AC-131~154 / TC-066~083 · **追溯登记覆盖率**：100%（FR→AC→TC 全链路已登记；实现通过率见 TRACEABILITY.md §6）

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
| `binance.product_lines` | `[]string` | `[]` | 启用的产品线（domain_market canonical：`spot`/`um_perp`/`cm_perp`/`options`）。**→ FR-034**（规格增补，见 [`specs/exchangeinfo-sync.md`](specs/exchangeinfo-sync.md) §6） |
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

#### 11.2.10 操作任务（Backfill / Reconciliation / Rehydration）

| 配置键 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `backfill.max_concurrent` | `int` | `4` | 全局并发回填任务上限（FR-019 Resource Cap） |
| `backfill.per_instrument_cap` | `int` | `10` | 单 instrument 并发回填上限 |
| `backfill.cold_start_priority` | `float` | `0.8` | cold_start 令牌桶权重（FR-025 Priority） |
| `backfill.repair_priority` | `float` | `0.2` | repair 令牌桶权重；cold_start+repair=1.0 |
| `backfill.token_rate` | `int` | `100` | 令牌桶填充速率（tokens/s） |
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
| `ErrSchemaVersionIncompatible` | server 收到未知 MAJOR SchemaVersion | terminal reject；写入告警日志 + metrics counter | `BNC-014` |
| `ErrDataRetentionDeleteFailed` | taosx retention 删除失败 | 保留热数据；写入 alerts 表；下周期重试 | `BNC-015` |
| `ErrAuditLogWriteFailed` | 审计日志写入失败 | 阻塞当前操作（审计失败不可静默）；告警 | `BNC-016` |
| `ErrInvalidBackfillWindow` | backfill job 窗口参数不合法（start ≥ end / 窗口过长 / 与实时数据重叠） | 拒绝创建 job；返回结构化错误含 reason | `BNC-017` |
| `ErrBackfillWindowOverlap` | 新 backfill job 窗口与已有 active/completed job 重叠 | 拒绝创建 job；返回重叠区间信息 | `BNC-018` |

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
    client/     # app/config/catalog/parser/spot/um_perp/cm_perp/options/normalize/mapper/idempotency/admin/observability（publisher 由 natsx FR-009 提供）
    server/     # app/config/validation/idempotency/storage/api/fanout/admin/observability（consumer 由 natsx FR-010 提供）
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
| TC-030 | FR-013 | 单元 + 集成 | retry budget、rate-limit 与 clock skew 控制 | 故障注入下 retry/backoff/clock skew 指标符合预算 |
| TC-031 | FR-014 | httptest + metrics | runtime stream state / lag / unhealthy reason | admin/metrics 同步暴露可审计状态 |
| TC-032 | FR-015 | httptest + 集成 | pause/resume/drain lifecycle | pause 后停止新增消费，resume 恢复，drain 有审计记录 |
| TC-033 | FR-016 | 单元 | backfill window、cursor 与 overlap validation | 无效窗口/重叠区间被拒绝，cursor 可恢复 |
| TC-034 | FR-017 | 集成 | gap detection and replay idempotency | gap 生成 replay job，重复 replay 不重复写入 |
| TC-035 | FR-018 | 单元 + 集成 | archive manifest、restore 与 retention delete | manifest 可校验，restore 可回放，retention delete 有保护 |
| TC-036 | FR-019 | 单元 | backfill resource cap and cancellation cursor | 全局/单 instrument 限额生效，取消后 cursor 可恢复 |
| TC-037 | FR-020 | 单元 + 集成 | funding_rate event mapping/storage/query/fanout | funding_rate 事件在 mapping、存储、API 与 fanout 中一致 |
| TC-038 | FR-021 | 单元 + 集成 | mark_price/index_price kind/topic/storage | mark/index price 不与 last/bid/ask 混淆 |
| TC-039 | FR-022 | 文档校验 | R2 governance matrix + stale alias checks | 4 product lines × 6 event types × 5 文档/checker anchors |
| TC-040 | FR-023 | 证据归档 | local/CI/live evidence bundle | local 与 remote CI/live 证据分层归档，不能互相替代 |
| TC-041 | FR-023 | release gate | release tag/changelog/evidence consistency | release tag、CHANGELOG、CI URL、evidence bundle 一致 |
| TC-042 | FR-024 | 集成 + httptest | `POST /api/v1/admin/symbols/reload` catalog reload | endpoint 验证通过，并证明 active stream add/remove 无进程重启 |
| TC-043 | FR-025 | 单元 + 集成 | token bucket weight 限流 | cold_start 占 80% / repair 占 20%；token 不足→等待，token bucket 空→指标递增 |
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

> [COMPUTED, HIGH] §17 原 P99 指标均为单环节延迟；FR-029 新增端到端 freshness SLA（event_time → persist/fanout）与 stale alert 阈值，覆盖单环节指标无法表达的"数据链路整体滞后"与"断流"两类数据质量风险。schema 漂移检测（字段增删/类型变更）由 CI gate 在 parser 单测层守门，不在此表。

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

`module/binance` 当前发布完成标准（覆盖 38 FR：FR-001~030 Current + FR-031~036 Draft + FR-037~044 Current）：

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
| OQ-004 | 是否需要 multi-region Binance endpoint 切换？ | 待评估（DR 要求见 Appendix G；natsx cluster 跨 AZ 已覆盖传输层，endpoint 层待评估） | binance owner |
| OQ-005 | Server 是否需要支持非 Binance 的 multi-exchange server？ | 已解决 — §5 Non-goals 明确"本模块仅处理 Binance"。多交易所由独立 cs_module 各自承担 | architecture |

### Future

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-006 | 是否需要 Binance 以外的 CEX 参照此 C/S 架构统一？ | 已解决 — okx/hyperliquid/coinglass/fred/treasury 已按 `arch_type: cs_module` 注册；C/S 模板提取见 `analysis/GOVERNANCE-TIER-PROPOSAL.md` + `structural-architecture-analysis-20260626.md` Phase C | architecture |
| OQ-007 | 是否需要压缩 `natsx` payload（特别是 depth snapshot）？ | 待评估（depth 20 档全量约 2KB/msg；4 PL × ~500 symbols × depth@100ms ≈ 40MB/s 未压缩；生产前需评估 natsx max_payload + Snappy/zstd 压缩） | performance |

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

## Appendix D: Acceptance Criteria Registry（v2.0.0 历史遗物，已冻结）

> **弃用声明**：本 Registry 是 v2.0.0 时期的验收口径快照，仅覆盖 FR-001~FR-011 共 18 条 AC（编号 AC-BNC-001 ~ AC-BNC-018）。当前模块已扩展至 38 FR（含 FR-031~036 Draft）/ 130 AC（AC-001 ~ AC-130），完整 AC 注册表单点维护于 `TRACEABILITY.md §5`，实现状态见 `ACCEPTANCE.md §2` 与 `TRACEABILITY.md §6`。
>
> **编号映射**：AC-BNC-001→AC-001、AC-BNC-002→AC-002、…、AC-BNC-018→AC-018（一一对应）。AC-019~AC-104 为 v2.1.0 后扩展，无对应 AC-BNC 编号。
>
> 以下内容为历史存档，Status 列的 `Approved` 仅表示需求已批准纳入规格，**不代表 runtime 实现已完成**。

| AC ID      | FR/BR Ref            | Criterion                                                                                                    | Verification                          | Status   |
| ---------- | -------------------- | ------------------------------------------------------------------------------------------------------------ | ------------------------------------- | -------- |
| AC-BNC-001 | FR-001               | Spot / USDⓈ-M / COIN-M / Options 四产品线 connector 均可独立启停，配置禁用时不订阅对应 stream                | TC-001, integration test              | Approved |
| AC-BNC-002 | FR-002               | parser 对 Spot `BTCUSDT` 与 USDⓈ-M `BTCUSDT` 输出不同 `InstrumentKey`，product_line/settlement/expiry 维度不碰撞 | TC-002, TC-003                        | Approved |
| AC-BNC-003 | FR-003               | client 调用 `js.Publish(subj, jsonPayload)` 成功后必须收到 JetStream PubAck；Stream=`BINANCE_MARKET` Retention=7d | TC-004, BOUNDARY-GATES.md §3-§4       | Approved |
| AC-BNC-004 | FR-004, BR-004       | server 仅在 redisx + taosx + postgresx + kafkax handoff 全部成功后调用 `msg.Ack()`，失败路径走 `NakWithDelay` | TC-006（非 boundary gate）            | Approved |
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

## Appendix F: Data Quality SLA Framework（SLA 框架）

> 来源：`report/binance/data-maturity-assessment-20260625.md`（2026-06-25 数据成熟度评估）。本附录将该报告的 4 维 SLA 模型 + 3 级成熟度模型 + 10 项 SLO 目标正式纳入 SPEC，作为 FR-029/FR-014/NFR-001~020 的统一度量框架。

### F.1 四维 SLA 模型

生产级行情数据系统的成熟度由四个正交维度决定。任一维不达标，系统不可声明"生产级"。

| 维度 | 定义 | 核心问题 | 对应 FR |
|------|------|----------|---------|
| **Freshness（时效性）** | `event_time → persist/fanout` 的端到端延迟 | "数据有多新？" | FR-029, FR-014 |
| **Completeness（完整性）** | 应采集的事件实际采集/持久化的比例 | "数据有没有丢？" | FR-004, FR-016~019, FR-026 |
| **Durability（持久性）** | 已持久化数据在故障/重启/过期后可恢复的程度 | "数据会不会没？" | FR-005, FR-006d, FR-018, FR-027 |
| **Consistency（一致性）** | 跨存储层（redis/taos/pg/ch）、跨时间窗口的数据是否自洽 | "数据对不对？" | FR-005 幂等, FR-026 对账, FR-030 字段 |

**因果链**：四维不是独立的——Freshness 下降 → 触发 stale alert → 应触发 Completeness 修复（backfill）→ Completeness 破缺（gap）→ 应触发 Consistency 对账（reconcile）→ Durability 不足（重启丢 cursor）→ 使 Completeness 永久受损。

### F.2 三级成熟度模型

| 级别 | 含义 | binance 实证锚点 |
|------|------|-----------------|
| **L1 检测** | 能发现违约，但无自动动作 | `quality.go` gap 检测、`sla_window.go` stale 计数 |
| **L2 告警** | 检测后主动告警（metrics → alerting rules → 通知/on-call） | `metrics.go` Prometheus gauge 已设，**alerting rules 消费层缺失** |
| **L3 自愈** | 检测后自动触发修复（replay/backfill/reconcile） | 全链路未实现（6 个 P0 缺口：stale→alert, gap→backfill, gap→replay, DLQ, retention, rehydrate） |

**当前成熟度**：L1 扎实（检测能力已大量铺设），L2 缺消费层（metrics 被采集但无 alerting rules 消费），L3 完全空白。参见 `report/binance/data-maturity-assessment-20260625.md` §2 因果链断裂图。

### F.3 SLO 目标（10 项）

| # | SLO | 目标 | SPEC 出处 | 状态 |
|---|-----|------|-----------|:----:|
| SLO-01 | Freshness P99（event→persist） | < 200ms | §17 NFR | ✅ |
| SLO-02 | Freshness P99（event→fanout） | < 300ms | §17 NFR | ✅ |
| SLO-03 | Stale alert 阈值 | spot/um/cm 30s, options 60s | §17 NFR | ⚠️ 计数✅, 告警❌ |
| SLO-04 | Gap 检测窗口 | MaxEventGap 2min | FR-029 | ⚠️ 检测✅, 修复❌ |
| SLO-05 | 幂等去重窗口 | 72h | FR-005 | ✅ |
| SLO-06 | natsx at-least-once | 0 丢失 | FR-004 | ✅ |
| SLO-07 | 覆盖率（不应丢的事件） | ≥ 99.99%（4 个 9） | 生产级要求 | ❌ 无度量 |
| SLO-08 | 历史数据可恢复性 | 重启后 cursor 不丢 | FR-016/019 | ❌ 纯内存 |
| SLO-09 | 对账容差 | 0.01% | FR-026 | ❌ 未真实执行 |
| SLO-10 | 冷数据可回热 | OSS→taosx rehydrate | FR-027 | ❌ 未接线 |

**告警消费层（"死信号"问题）**：runtime 已设置 Prometheus gauge（`SetGapRepairRequired`、stale 计数），但无 alerting rules 消费——这是 L1→L2 断裂的根因。生产级要求：每条 SLO 至少有一条 alerting rule，触发后通知 on-call（PagerDuty/webhook）。

---

## Appendix G: Disaster Recovery Requirements（灾难恢复）

> 来源：`report/binance/data-maturity-assessment-20260625.md` §1.4 横切生产级维度 + `report/binance/foundation-resilience-audit-20260625.md` §2 可靠性责任矩阵。

### G.1 RPO / RTO 定义

| 指标 | 定义 | 目标 | 当前状态 |
|------|------|------|:--------:|
| **RPO**（Recovery Point Objective） | 灾难时可接受的最大数据丢失窗口 | ≤ 1h（natsx stream 7d retention 兜底） | ❌ 无定义 |
| **RTO**（Recovery Time Objective） | 灾难后恢复完整服务的时间上限 | ≤ 4h（含 infra 重建 + 数据回灌 + 健康检查） | ❌ 无定义 |

### G.2 多可用区 / 多节点要求

| 组件 | 生产级要求 | 当前配置 | 差距 |
|------|-----------|:--------:|:----:|
| NATS JetStream | Cluster ≥ 3 节点, Replicas ≥ 3 | 单节点（dev 配置） | 🔴 |
| Redis | Sentinel（HA）或 Cluster（分片） + AOF 持久化 | 单实例 | 🔴 |
| PostgreSQL | 主从复制 + WAL 归档 + 定期 pg_dump | 单实例 | 🔴 |
| TDengine | 多副本（Replica ≥ 2）+ WAL 落盘 | 单节点 | 🔴 |
| ClickHouse | ReplicatedMergeTree + 多副本 | 单节点 | 🔴 |
| Kafka | Cluster ≥ 3 broker, topic replication ≥ 3 | 单 broker（dev 配置） | 🔴 |
| OSS | 云原生多 AZ 冗余（S3 等效） | 依赖 OSS 服务商 | ✅ |

### G.3 Backup / Restore 要求

| 数据层 | Backup 策略 | Restore 验证 |
|--------|------------|:------------:|
| postgresx（catalog + audit） | 每日 pg_dump + WAL 连续归档 | 季度 restore drill |
| taosx（时序行情） | natsx stream 7d retention 兜底 + OSS 归档 | backfill replay 可复现 |
| OSS（归档 parquet） | 云原生多 AZ（S3 等效） | ETag 校验（FR-006d 已实现） |
| redisx（缓存/幂等） | AOF 持久化（appendfsync everysec） | 非关键——缓存 miss 回退 taosx |

### G.4 相关 FR / NFR

- FR-006d（OSS 归档 + ETag 校验）— 已实现
- FR-018（Archive Manifest and Restore）— 已实现
- FR-027（Cold Data Rehydration）— Partial（代码存在，未接线）
- **NFR-028（DR Readiness）**— 新增：RPO/RTO 达标 + 多 AZ 部署 + restore drill ≥ 年 1 次
