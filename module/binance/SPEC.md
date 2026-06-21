# module/binance SPEC

## 1. Metadata

- Status: Draft → v2.0.0
- Spec-Version: v2.0.0
- Last-Updated: 2026-06-21
- Owner: ZoneCNH
- Layer: 数据域 · 行情
- Version: v0.1.0
- Repository: [github.com/ZoneCNH/binance](https://github.com/ZoneCNH/binance)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md), `module/domain_market`, `module/natsx`, `module/redisx`, `module/taosx`, `module/kafkax`, `module/ossx`, `module/postgresx`

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
    ├── kafkax            ← 跨域事件发布
    ├── ossx              ← 历史归档
    └── Gin :8080         ← REST API 供 market_data 调用
        ↓ HTTP
  market_data             ← 交易所中立的后续管线
```

`binance-client` 和 `binance-server` 可部署在不同机器/容器/可用区，通过 NATS Server 集群传递消息。`binance-market` 已移除。

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
- server 侧完整存储：taosx（时序）+ postgresx（元数据）+ redisx（缓存）+ ossx（归档）
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
| 下游分析域（signal/risk/backtest） | kafkax consumer group 消费 `binance.market.*` topic | Kafka |
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

**WHEN** JetStream PubAck 返回成功
**THEN** 消息已持久化到 NATS Stream（`BINANCE_MARKET`，Retention=7d），client 可继续下一条

**WHEN** JetStream 不可达或超时
**THEN** `Publish` 返回 error，调用方指数退避重试；不丢弃消息

**WHEN** server natsx consumer 收到消息（durable=`binance-server`）
**THEN** 反序列化 `MarketFactEnvelope`，进入 validation → idempotency → storage pipeline

### FR-004: At-Least-Once Delivery

**功能描述**：通过 JetStream durable consumer + ManualAck 保证 at-least-once 交付。无需本地 spool 或 checkpoint。

**WHEN** server 处理消息成功（redisx + taosx + kafkax 全部写入）
**THEN** 调用 `msg.Ack()`，consumer 推进消费位点

**WHEN** server 处理消息失败（任一写入报错）
**THEN** 调用 `msg.NakWithDelay(5s)`，JetStream 重投；达到 MaxDeliver(5) 后进入死信

**WHEN** server 进程重启
**THEN** durable consumer 从上次 Ack 位置自动恢复，无需外部 checkpoint 管理

### FR-005: Idempotent Acceptance

**功能描述**：server 每个 idempotency key 最多接受一次并 downstream dispatch 一次。

**WHEN** server 收到新 idempotency key 的有效 event
**THEN** 接受、durable 记录、ACK、dispatch downstream

**WHEN** server 收到已 accepted 的 idempotency key
**THEN** 返回 idempotent ACK，不再次 dispatch

**WHEN** server 收到已 accepted 的 idempotency key 但 payload 冲突
**THEN** 返回 terminal_conflict reject

### FR-006: Admin Surface

**功能描述**：client 和 server 各自暴露 Gin admin 端点。

**WHEN** 请求 `GET /healthz`
**THEN** 返回 process liveness 状态（200 或 503）

**WHEN** 请求 `GET /readyz`
**THEN** 返回模块就绪状态（200 或 503），不检查下游业务正确性

**WHEN** 请求 `GET /debug/*`
**THEN** 返回只读诊断信息，不暴露 secrets

**WHEN** 请求 `/admin/*` 变更操作
**THEN** 仅变更本地服务状态，不跨模块边界

### FR-007: Boundary Enforcement

**功能描述**：模块边界通过 CI gate 强制执行。

**WHEN** client 代码尝试 import server internal 包
**THEN** CI boundary gate 失败

**WHEN** 任何代码 reintroduce `binance-market` 引用
**THEN** CI no-legacy gate 失败

**WHEN** 模块内声明 storage/query/strategy 所有权
**THEN** CI ownership gate 失败

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

**规则**：server consumer 必须在 redisx + taosx + kafkax 全部写入成功后才调用 `msg.Ack()`。

**约束**：禁止在 validation 完成、idempotency 检查后、任何单一存储写入成功后提前 Ack。

**违反时**：处理中断会导致 JetStream 重投，redisx SetNX 幂等检查防止重复写入 taosx。

### BR-005: No Domain Ownership

**规则**：`module/binance` 不得定义 canonical domain semantics 的 source of truth。

**约束**：`ProductLine`、`InstrumentKey`、`InstrumentType`、`MarketScope`、`OptionType`、`PriceKind` 等 canonical enum 必须来自 `module/domain_market`。Binance 可定义 exchange-specific parsing/mapping，但输出必须是对 domain_market 类型的引用。

**违反时**：CI ownership gate 失败。

### BR-006: No Storage/Query/Strategy Ownership

**规则**：`module/binance` 不得拥有 storage engine、query API 或 strategy API。

**约束**：server downstream dispatch port 只做 handoff，不实现物理存储。禁止引入 `github.com/ZoneCNH/storage`、`github.com/ZoneCNH/strategy` 作为 owned dependency。

**违反时**：CI ownership gate 失败。

### BR-007: Wire Contract Externality

**规则**：`module/binance` 不得定义自己的 proto 文件或 wire schema。

**约束**：wire schema（JSON envelope）由 `module/domain_market` 的 `MarketFactEnvelope` 定义。禁止 `module/binance/proto/*` 和独立 canonical wire enum 定义。natsx subject 命名规范见 §9。

**违反时**：CI gate 失败。

### BR-008: Idempotency Key Stability

**规则**：client 生成的 idempotency key 必须在 retry 场景下稳定。

**约束**：key 必须基于 exchange + product_line + instrument_key + event_type + event_time/source_sequence 等确定性维度生成。bar 事件包含 interval/open_time，trade 包含 trade_id，depth 包含 sequence/update dimensions。

**违反时**：retry 时 server 无法识别重复，产生 duplicate downstream effect。

### BR-009: Admin Boundary

**规则**：client admin 仅可变更 client-local state，server admin 仅可变更 server-local state。

**约束**：禁止 client admin 变更 server state、server admin 变更 client connector state、admin 变更 downstream storage/strategy state。

**违反时**：操作被拒绝并返回错误。

---

## 9. Interface Contract

### natsx JetStream Interface (v2.0.0)

```go
// MarketDataService receives normalized upstream market_data ingestion requests.
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
| `binance.market.spot.depth` | 现货深度 |
| `binance.market.futures_usdt.tick` | U 本位合约成交 |
| `binance.market.futures_usdt.depth` | U 本位合约深度 |
| `binance.market.kline.1m` | 1 分钟 K 线 |

- Client 调用 `js.Publish(subj, jsonPayload)`，等待 PubAck 后返回（确保持久化）
- Server durable consumer 订阅 `binance.market.>`，ManualAck，处理完整链路后 Ack

### Downstream Dispatch Port

Server 通过 exchange-neutral downstream port 将 accepted events 分发给 `module/market_data`。该 port 的具体接口由 `module/market_data` SPEC v1.0.0 §4 定义（`Dispatch(ctx, AcceptedMarketEvent) → DispatchOutcome`，12 字段输入，8 种 reject reason，binance-native 6→8 映射规则 §4.4.1）；server 只做 handoff 适配。

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
received → validating → idempotency_check → storing → acked
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

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `binance.endpoints.rest` | `string` | `https://api.binance.com` | Binance REST API base URL |
| `binance.endpoints.ws` | `string` | `wss://stream.binance.com:9443` | Binance WebSocket base URL |
| `binance.product_lines` | `[]string` | `[]` | 启用的产品线：spot/um_perp/cm_perp/options（canonical domain_market ProductLine 值） |
| `binance.symbols.allow` | `[]string` | `[]` | 白名单 symbol（空=全部） |
| `binance.symbols.deny` | `[]string` | `[]` | 黑名单 symbol |
| `natsx.nats_url` | `string` | `nats://localhost:4222` | NATS JetStream 连接地址 |
| `natsx.stream` | `string` | `BINANCE_MARKET` | JetStream Stream 名称 |
| `natsx.durable` | `string` | `binance-server` | server durable consumer 名称（server 配置） |
| `natsx.ack_wait` | `duration` | `30s` | ManualAck 超时（server 配置） |
| `natsx.max_deliver` | `int` | `5` | 最大重投次数（server 配置） |
| `retry.max_attempts` | `int` | `5` | 最大重试次数 |
| `retry.backoff_initial` | `duration` | `1s` | 初始退避时间 |
| `retry.backoff_max` | `duration` | `60s` | 最大退避时间 |
| `admin.bind` | `string` | `:8080` | admin HTTP 绑定地址 |

> **Security**：API keys、secrets、signatures 从环境变量注入，不从配置文件读取。禁止在 logs 和 admin/debug 端点暴露。

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
| `ErrDispatchFailed` | downstream dispatch 失败 | 重试（指数退避），超过阈值告警 | `BNC-008` |

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
| Downstream dispatch 持续失败 | market_data 下游不可用 | 指数退避重试，超过阈值告警，不丢失已 accepted event |

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
    tasks/                         # Client task spec（12 个）
  server/                          # Server 子模块
    README.md
    SPEC.md
    TRACEABILITY.md
    IMPLEMENTATION-PLAN.md
    tasks/                         # Server task spec（8 个）
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
    server/     # app/config/ingest/validation/idempotency/ack/dispatch/admin/observability
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
| `gin-gonic/gin` | REST API（`/v1/market/*`），供 market_data 拉取 | server API |

### Forbidden Dependencies

| 禁止导入 | 原因 |
|----------|------|
| `module/binance/client/*` (在 server 中) | 违反 client/server 边界 |
| `module/binance/server/*` (在 client 中) | 违反 client/server 边界 |
| `github.com/ZoneCNH/binance-market` | legacy 模块已移除 |
| `github.com/ZoneCNH/storage` (as owned) | storage ownership 属于 market_data |
| `github.com/ZoneCNH/strategy` (as owned) | strategy ownership 属于分析/决策域 |

---

## 16. Testing

### Test Matrix

| TC 编号 | 对应 FR | 测试类型 | 场景 | 预期结果 |
|---------|---------|----------|------|----------|
| TC-001 | FR-001 | 集成 | 启用 Spot product line，连接 Binance testnet | connector 产生标有 ProductLine=Spot 的 normalized events |
| TC-002 | FR-002 | 单元 | parser 输入 Spot `BTCUSDT` 和 USDⓈ-M `BTCUSDT` | 两个不同的 InstrumentKey |
| TC-003 | FR-002 | 单元 | parser 输入 COIN-M `BTCUSD` | InstrumentKey 含 settlement_asset |
| TC-004 | FR-003 | 集成 | client 调用 `js.Publish(subj, payload)` | natsx 返回 PubAck，消息持久化到 JetStream stream |
| TC-005 | FR-004 | 集成 | 发送 event 后 kill client 进程，重启 | JetStream durable consumer 从上次 Ack 位置恢复；redisx SetNX 防重复写入 |
| TC-006 | FR-005 | 集成 | 发送同一 idempotency key 两次 | server 返回 idempotent ACK，downstream 仅 dispatch 一次 |
| TC-007 | FR-005 | 集成 | 发送同一 key 但不同 payload | server 返回 terminal_conflict reject |
| TC-008 | FR-006 | 单元 | GET /healthz | 返回 200 |
| TC-009 | FR-007 | CI | client 代码 import server internal | boundary gate 失败，CI exit 1 |

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
| Server idempotency check | 延迟 P99 | < 1ms | `go test -bench` |
| ACK lag (server receive → ACK send) | P99 | < 100ms | integration test |
| Client restart recovery | 时间 | < 10s | integration test |

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
| `binance_client_ack_lag_seconds` | histogram | ACK 延迟（send → ACK receive） |
| `binance_client_retry_total` | counter | 重试次数 |
| `binance_client_stream_reconnects_total` | counter | stream 重连次数 |
| `binance_server_streams_active` | gauge | 活跃 stream 数 |
| `binance_server_events_accepted_total` | counter | 接受的唯一事件数 |
| `binance_server_events_duplicate_total` | counter | 重复事件数 |
| `binance_server_events_rejected_total` | counter | 拒绝事件数（per reject_reason） |
| `binance_server_dispatch_latency_seconds` | histogram | downstream dispatch 延迟 |

### Logging

| 事件 | 级别 | 必要字段 |
|------|------|----------|
| Stream connected/disconnected | info | stream_id |
| Event accepted | debug | stream_id, product_line, instrument_key, idempotency_key |
| Event rejected | warn | stream_id, reject_reason, idempotency_key |
| Duplicate detected | debug | stream_id, idempotency_key |
| Dispatch failed | error | stream_id, instrument_key, error |
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
| `binance.server.dispatch` | downstream dispatch |

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
| Ownership | `BOUNDARY-GATES.md` §5 gate script | 零 storage/query/strategy 所有权声明 |
| Contracts only | `BOUNDARY-GATES.md` §6 gate script | 零 local proto 文件 |
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

`module/binance` v1.0.0 发布完成标准：

- [ ] `binance-market` references 已移除或隔离到 migration history（BR-001）
- [ ] `module/binance/client` 和 `module/binance/server` specs 完成并通过 spec-lint
- [ ] root/client/server TRACEABILITY.md 完成，所有需求可追溯
- [ ] client/server task sets 独立可执行
- [ ] Delivery semantics 明确为 at-least-once + idempotent acceptance（FR-004, FR-005）
- [ ] natsx JetStream ManualAck 全链路语义已定义且 testable（BR-004）
- [ ] ProductLine 和 InstrumentKey 碰撞 case 已文档化（FR-002, §10 Data Model）
- [ ] Boundary gates 可在 CI 执行（FR-007, BOUNDARY-GATES.md）
- [ ] Runtime mapping 未将 storage/query/strategy ownership 放在 Binance 内（BR-006）
- [ ] 所有 FR 实现完成，所有 AC 验证通过
- [ ] 覆盖率 ≥ 80%
- [ ] CI Gate 全部通过（通用 + 模块专属）
- [ ] Performance Budget 达标
- [ ] Integration test 演示 `client → server → downstream port` 完整数据流

---

## 23. Open Questions

### Resolved (was Blocking)

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-001 | `MarketDataService` proto 的 final wire 定义是否已在 `module/contracts` 中完成？ | 已确认 — contracts SPEC v1.2.0-spec §8.4 已定义 `MarketDataService` 接口（`Ingest(stream IngestRequest) (stream IngestResult, error)`）、`IngestRequest`（10 required + 2 optional 字段）、`IngestResult`（Ack/Reject 二选一）、`IngestAck`、`IngestReject` 和 `RejectCode`（10 码枚举：retryable / terminal_validation / terminal_conflict / unauthorized / rate_limited / server_unavailable / contract_violation / quality_rejected / ordering_violation / unsupported_channel，共 10 码） | contracts owner |
| OQ-002 | `module/market_data` 的 downstream dispatch port 接口是否已定义？ | 已确认 — market_data SPEC v1.0.0 §4 已定义 `DownstreamDispatchPort` 语义（`Dispatch(ctx, AcceptedMarketEvent) → DispatchOutcome`）、12 项输入字段（§4.2）、8 种 reject reason（§4.4）和 binance-native → market_data reject 映射规则（§4.4.1，6→8 映射表） | market_data owner |

### Non-blocking

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-003 | server idempotency store 的 backing storage 选型（in-memory / SQLite / Redis）？ | 待定 | binance owner |
| OQ-004 | 是否需要 multi-region Binance endpoint 切换？ | 待评估 | binance owner |
| OQ-005 | `MarketDataService` 是否需要支持非 Binance 的 multi-exchange server？ | 待评估 | architecture |

### Future

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-006 | 是否需要 Binance 以外的 CEX 参照此 C/S 架构统一？ | 待评估 | architecture |
| OQ-007 | 是否需要压缩 gRPC payload（特别是 depth snapshot）？ | 待评估 | performance |

---

## Appendix A: Architecture Decision Record

| 日期 | 决策 | 理由 |
|------|------|------|
| 2026-06-16 | 采用 client/server 双端架构 | SDK + Provider 模型职责不清，C/S 明确采集端和受理端边界 |
| 2026-06-16 | 移除 `binance-market` | 统一到 client/server，消除 ambiguous split |
| 2026-06-16 | gRPC bidirectional stream 作为传输协议 | client 需要 per-event ACK 以驱动 checkpoint |
| 2026-06-16 | At-least-once + idempotent acceptance 交付语义 | 不声称 exactly-once（client 端不可实现），但保证 downstream 无重复 |
| 2026-06-17 | **骨架首版采用自包含契约层 `internal/cs`**（ADR-skeleton-1） | 探查确认 contracts §8.4 的 `MarketDataService`/`IngestRequest`/`RejectCode` 在代码层尚未落地（仅 SPEC 文档 + 未应用 patches）。为不阻塞 binance 落地，首版在 binance 仓库内本地定义最小契约类型（IngestRequest/IngestResult/IngestAck/IngestReject/ProductLine/EventType/RejectCode 9 码）。contracts 落地后整体替换为 import |
| 2026-06-17 | **骨架首版用原生 Go 接口替代 gRPC**（ADR-skeleton-2） | 全项目零 gRPC 基础设施（无 protoc/proto/.pb.go）。client/server 经 `IngestClient` interface + `ingestAdapter` 直接调用。gRPC bidi stream 升级留后续，届时 cs 类型替换为 contracts 生成的 wire types |
| 2026-06-17 | **骨架首版 in-memory spool + idempotency**（ADR-skeleton-3） | 避免引入 SQLite/Redis 依赖。可靠性语义（状态机、CheckAndSet、durable ACK→checkpoint）已完整实现并测试，但进程重启数据丢失。SQLite spool + Redis idempotency 留后续迭代 |
| 2026-06-17 | **骨架首版仅 Spot 单产品线**（ADR-skeleton-4） | 聚焦端到端闭环可验证性。mapper 复用真实 `domainmarket.Tick/Quote/Bar`（已发布）。USDⓈ-M/COIN-M/Options connector 留后续；parser/connector 已为多产品线预留扩展位 |
| 2026-06-17 | **RejectCode 采用 9 码**（ADR-skeleton-5） | 对齐 `patches/contracts/ingestion.go` 实际定义的 9 个常量（retryable/terminal_validation/terminal_conflict/unauthorized/rate_limited/server_unavailable/contract_violation/quality_gate/ordering_violation），而非本 SPEC §9 文字描述的 10 码。以可运行代码为准；contracts 正式落地时统一码集 |
| 2026-06-17 | **`cmd/binance-smoke` 作为同进程冒烟特例**（ADR-skeleton-6） | binance-smoke 同进程 wire client+server 用于本地端到端验证，是边界纪律的有意特例（同时 import 双方）。生产路径用独立 `binance-client`/`binance-server` 进程经网络通信 |

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
    │  msg.Ack()        │  ← 全部写入成功后才 Ack
    ├──────────────────┤
    │  Gin REST API     │ ◄── gin-gonic/gin  /v1/market/*
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

## Appendix D: Upstream Contract Gate Closure

> 本节是 PR-007 运行时实现前的上游契约链闭合验证记录，原以 §0 形式置于文档前部，现按 23 节模板规整为附录 D。原内容完整保留，仅顶层标题变更。


在从 docs baseline 推进到运行时实现前，必须逐项验证以下上游契约链闭合条件：

| # | Gate | 验证 | 状态 |
|---|------|------|:----:|
| G0-1 | `module/natsx` JetStream stream `BINANCE_MARKET` + subject pattern `binance.market.{product_line}.{event_type}` + durable consumer 规范 | natsx SPEC + v2.0.0 RUNTIME-MAPPING.md | ✅ |
| G0-2 | `module/domain_market` `ProductLine`(4值)/`InstrumentKey`(12维)/`MarketFactEnvelope` canonical 类型 | domain_market SPEC v1.0.1 §10 | ✅ |
| G0-3 | `module/market_data` DownstreamDispatchPort + 12 输入字段 + 8 种 reject reason + §4.4.1 binance reject 映射 | market_data SPEC v1.0.0 §4 | ✅ |
| G0-4 | binance OQ-001（contracts wire 就绪？） | 已确认 (2026-06-17) | ✅ |
| G0-5 | binance OQ-002（market_data dispatch port 就绪？） | 已确认 (2026-06-17) | ✅ |
| G0-6 | BOUNDARY-GATES.md 全部 9 门禁有 CI 脚本 | 9/9 (2026-06-17) | ✅ |

> **6/6 通过** — 上游契约链闭合。本 SPEC 处于 Review 状态，可进入运行时实现阶段（PR-007）。实现时必须严格遵循 natsx JetStream subject 规范、domain_market §10 canonical semantics、Gin REST API `/v1/market/*` 契约。

---
