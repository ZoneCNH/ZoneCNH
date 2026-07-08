# module/binance/client SPEC

## 1. Metadata

- Status: Approved
- Spec-Version: v4.0.1
- Last-Updated: 2026-06-28 (§14 目录结构修正 — 删除独立 go.mod/go.sum，改为 monorepo internal/client/ 布局，与 server/SPEC §14 对称)
- Last-Updated: 2026-06-26 (v3.9.0: 幂等键策略修正 — 按事件类型强制维度；depth key 固定 U/u updateId；trade key 强制 trade_id；bar key 强制 open_time+interval；tick key 使用 event_time+bid+ask。§17 性能预算扩展 — WS 吞吐、内存预算、延迟分解)
- Last-Updated: 2026-06-26 (v2.1.1→v3.8.0: 结构性修复 — 废除本地 FR/BR 编号，全部改为引用根 SPEC canonical FR/BR；§7 重构为根 FR 的 client 实现视图；端点策略合并为附录）
- Owner: ZoneCNH
- Layer: 数据域 · Binance 交易所接入
- Runtime-Version: v0.14.0
- Repository: [github.com/ZoneCNH/binance](https://github.com/ZoneCNH/binance)（client 端通过 `cmd/binance-client` + `internal/client` 提供）
- Go Module Path: `github.com/ZoneCNH/binance`（monorepo，client 端通过 `cmd/binance-client` + `internal/client` 提供）
- Related: [CONSTITUTION.md](../../../../CONSTITUTION.md), [ARCHITECTURE.md](../../../../ARCHITECTURE.md), [module/binance/spec/SPEC.md](../SPEC.md), [module/domain_market](../../../domain_market/), [module/natsx](../../../natsx/)

---

## 2. Summary

`module/binance/client` 是 Binance 交易所对向**行情采集器**，以**独立进程**运行。

**职责极简化**：仅采集 + 规范化 + 发布。不持有存储，不持有状态，不知道 server 的存在。

```text
[采集区 / 交易所侧]
  Binance Exchange (WS/REST)
        ↓
  binance-client（独立进程）
  catalog → parser → connectors(4条线) → normalize → mapper
                                                    ↓
                                    natsx.Publish(subj, json)
                                    跨网络发布到 NATS JetStream
                                    subject: binance.market.{line}.{type}.v1
```

client 完成发布即结束职责。持久化、幂等、存储、API 全部由 `binance-server` 负责。

---

## 3. Problem

量化交易系统需要从 Binance 采集行情数据。存在以下问题：

- **多产品线身份碰撞**：`BTCUSDT` 同时存在于 Spot 和 USDⓈ-M，裸 symbol 无法区分，导致数据路由错误
- **同进程耦合**：旧架构 client 通过 Go interface 直接调用 server，无法独立部署，无法容错
- **重试重复**：无跨重试稳定的幂等键，直接重发导致 server 重复处理
- **产品线不完整**：仅 Spot 有实现，USDⓈ-M/COIN-M/Options 缺失

---

## 4. Goals

- **独立进程部署**：`binance-client` 以独立二进制运行，与 server 无代码依赖
- 支持 Binance 全部 4 条产品线：Spot、USDⓈ-M Futures、COIN-M Futures、Options，每条可独立启停
- 提供产品线目录，包含足够字段生成规范身份标识
- 提供 Binance 符号解析器，区分 Spot/USDⓈ-M/COIN-M/Options 身份
- 将交易所原生事件规范化为 `domain_market.MarketFactEnvelope`
- 生成跨重试稳定的幂等键（放入 envelope Header，由 server 消费）
- **通过 natsx JetStream 发布事件**（网络通信，不依赖 server 进程）
  - subject 格式：`binance.market.{product_line}.{event_type}.v1`
  - 同步等待 JetStream Publish ACK（确认消息已持久化到 NATS）
- 提供 Gin admin 端点（:8081），仅操作本地状态：`/healthz /readyz`
- 所有可观测性通过 `observex` 集成

---

## 5. Non-goals

- **不做同进程 server 调用**（Go interface / cs 包 — 违反分布式约束）
- **不做 spool / checkpoint**（由 natsx JetStream 持久化替代）
- **不做 gRPC sender**（由 natsx publisher 替代）
- 不做 server 侧幂等接受或持久化（由 server 负责）
- 不做下游 dispatch（由 server 负责）
- 不做存储（redisx/postgresx/taosx/ossx 全部属于 server）
- 不做 REST API（由 server Gin 接口负责）
- 不做规范行情类型定义（由 `module/domain_market` 负责）
- 不部署、不内嵌 NATS Server / JetStream；只配置外部 `nats.url` 并发布事件
- 不做 `binance-market` 遗留模块兼容
- 不做交易下单

---

## 6. Consumers

| 消费者 | 通信方式 | 说明 |
|--------|---------|------|
| natsx JetStream | TCP 网络 | client 发布事件，NATS 持久化后由 server 消费 |

> **client 不直接与 server 交互**。两者通过 NATS JetStream 解耦，互不感知对方的进程位置。

---

## 7. Functional Requirements（Client 实现视图）

> **编号规则（v3.8.0 统一）**：本节以根 SPEC canonical FR 编号为标题，补充 client 特有的 WHEN/THEN 实现细节。不定义独立 FR 编号。完整 FR 定义见 [根 SPEC](../SPEC.md) §7。

### FR-001: Product-Line Support（client 实现）

**Client 实现范围**：维护四产品线 catalog + connector 管理 + catalog 热重载。根 SPEC FR-001 的 canonical 定义见 [SPEC.md](../SPEC.md) §7。

**WHEN** client 启动
**THEN** 加载产品线目录，包含 Spot、USDⓈ-M Futures、COIN-M Futures、Options 四条产品线
**AND** 每条产品线可独立配置启用/禁用

**WHEN** 触发 catalog reload
**THEN** 重新加载目录，不中断已启用产品线的活跃连接

**WHEN** 查询 catalog entry
**THEN** 返回包含 exchange、product_line、instrument_type、symbol、base_asset、quote_asset、margin_asset、settlement_asset、expiry、strike、option_type、contract_code、price precision、quantity precision、status 的完整条目

### FR-002: Instrument Identity（client 实现）

**Client 实现范围**：Binance symbol 解析器，输出 identity 组件供 mapper 使用。根 SPEC FR-002 的 canonical 定义见 [SPEC.md](../SPEC.md) §7。

**WHEN** 输入 Binance 原生 symbol 和 exchange metadata
**THEN** 解析器输出 identity 组件，可区分：Spot `BTCUSDT`、USDⓈ-M `BTCUSDT` Perpetual、COIN-M `BTCUSD` Perpetual、Option `BTC-YYYYMMDD-STRIKE-C/P`

**WHEN** 输入无法解析的 symbol
**THEN** 返回错误，不产生歧义的身份映射

### FR-003: natsx Communication（client 实现）

**Client 实现范围**：natsx JetStream publisher。根 SPEC FR-003 的 canonical 定义见 [SPEC.md](../SPEC.md) §7。Server 侧 consumer 见 Server SPEC。

**WHEN** 规范化事件生成幂等键后
**THEN** 构造 `domain_market.MarketFactEnvelope` JSON payload，调用 `js.Publish(subject, payload)` 同步发布
**AND** subject 格式：`binance.market.{product_line}.{event_type}.v1`

**WHEN** JetStream 返回 PubAck
**THEN** 投递视为成功；JetStream 已在 NATS 集群持久化该消息

**WHEN** PubAck 超时或 NATS 连接断开
**THEN** 内存队列（有界，backpressure 阈值可配置）暂存事件；指数退避重连后重发；重发消息由 server redisx SetNX 幂等过滤

**WHEN** 内存队列达到 backpressure 阈值
**THEN** 触发 `ErrNATSBackpressure`，告警，暂停新事件采集

### FR-004: At-Least-Once Delivery

> Client 侧不直接实现 FR-004（由 Server 侧 JetStream durable consumer + ManualAck 保证）。Client 职责：发布 + 等待 PubAck + 内存队列退避重试。

### FR-005: Idempotent Acceptance

> Client 职责：生成跨重试稳定的幂等键（见下方 FR-005 Key Generation）。Server 侧负责 SetNX 验收。根 SPEC FR-005 的 canonical 定义见 [SPEC.md](../SPEC.md) §7。

#### FR-005 Key Generation（client 实现）

**WHEN** 事件进入 publisher 前
**THEN** 生成幂等键，**按事件类型强制维度**（不使用"如可用"策略）：
  - **trade**：`{exchange}:{product_line}:{symbol}:trade:{trade_id}`。`trade_id` 为 Binance aggTrade `a` 字段（单调递增整数）。**禁止降级为仅 event_time**（同一毫秒内可能有多笔成交）
  - **bar**：`{exchange}:{product_line}:{symbol}:bar:{interval}:{open_time}`。`interval` 和 `open_time` 均为必填维度
  - **depth**：`{exchange}:{product_line}:{symbol}:depth:{U}:{u}`。`U` 为 firstUpdateId，`u` 为 lastUpdateId（Binance depth 增量窗口）。使用窗口首尾 updateId 而非"如可用"
  - **tick**（bookTicker）：`{exchange}:{product_line}:{symbol}:tick:{event_time}:{bid_price}:{ask_price}`。bookTicker 无 sequence ID，使用 event_time + 价位组合保证唯一性
  - **funding_rate**：`{exchange}:{product_line}:{symbol}:funding_rate:{funding_time}`
  - **mark_price**：`{exchange}:{product_line}:{symbol}:mark_price:{event_time}`

**WHEN** 不同 event type 需要不同 key 策略
**THEN** 按 event type 选择对应 key 策略

**WHEN** 同一事件重试
**THEN** 幂等键不变（跨重试稳定）

### FR-006a/6b/6c/6d: Storage

> Client 不持有存储。taosx/postgresx/redisx/ossx 全部属于 Server。

### FR-007: Gin Market API

> Client 不提供 Market API（由 Server Gin :8080 提供）。

### FR-008: kafkax Downstream Broadcast

> Client 不参与 kafkax dispatch（由 Server 负责）。

### FR-009: Boundary Enforcement（client 侧）

**Client 实现范围**：CI gate 强制 client 不得 import server internals。根 SPEC FR-009 的 canonical 定义见 [SPEC.md](../SPEC.md) §7。

**WHEN** client 代码尝试 import server internal 包
**THEN** CI boundary gate 失败（`go list -deps | grep 'binance/server'` 检测到违规 import）

**WHEN** client 代码尝试 import gRPC / sqlite3
**THEN** CI gate 失败（`grep -qE 'google.golang.org/grpc|go-sqlite3'` 检测到违规 import）

### FR-012: Stream Session Lifecycle（client 实现）

**Client 实现范围**：WebSocket stream 会话管理。根 SPEC FR-012 的 canonical 定义见 [SPEC.md](../SPEC.md) §7。详见根 SPEC WHEN/THEN。

### FR-013: Exchange Reliability Controls（client 实现）

**Client 实现范围**：retry budget、rate-limit、clock skew 检测。根 SPEC FR-013 的 canonical 定义见 [SPEC.md](../SPEC.md) §7。详见根 SPEC WHEN/THEN。

### FR-014: Runtime Stream Observability（client 实现）

**Client 实现范围**：admin API 暴露 stream 状态 + Prometheus metrics。根 SPEC FR-014 的 canonical 定义见 [SPEC.md](../SPEC.md) §7。详见根 SPEC WHEN/THEN。

### FR-015: Runtime Pause/Resume/Drain（client 实现）

**Client 实现范围**：admin 端点控制 stream 生命周期。根 SPEC FR-015 的 canonical 定义见 [SPEC.md](../SPEC.md) §7。详见根 SPEC WHEN/THEN。

### FR-016: Historical Backfill Planner（client 实现）

**Client 实现范围**：backfill job 创建、窗口校验、游标持久化。根 SPEC FR-016 的 canonical 定义见 [SPEC.md](../SPEC.md) §7。详见根 SPEC WHEN/THEN。

### FR-019: Backfill Resource Governance（client 实现）

**Client 实现范围**：并发上限、取消游标持久化。根 SPEC FR-019 的 canonical 定义见 [SPEC.md](../SPEC.md) §7。详见根 SPEC WHEN/THEN。

### FR-020: Funding Rate Event Support（client 实现）

**Client 实现范围**：funding_rate 事件的 mapping 与 publish。根 SPEC FR-020 的 canonical 定义见 [SPEC.md](../SPEC.md) §7。详见根 SPEC WHEN/THEN。

### FR-021: Mark and Index Price Support（client 实现）

**Client 实现范围**：mark_price 事件的 mapping 与 publish。IndexPrice 作为事件字段承载。根 SPEC FR-021 的 canonical 定义见 [SPEC.md](../SPEC.md) §7。详见根 SPEC WHEN/THEN。

### FR-024: Runtime Config Hot Reload（client 实现）

**Client 实现范围**：`POST /api/v1/admin/symbols/reload` 触发 catalog reload + full reconnect/no-restart 边界；按 tier 的增量 stream diff 归属 FR-036（ADR-004）。根 SPEC FR-024 的 canonical 定义见 [SPEC.md](../SPEC.md) §7。详见根 SPEC WHEN/THEN。

### FR-025: Backfill Throttle & Priority（client 实现）

**Client 实现范围**：分钟 weight 预算 + P0/P1/P2 三级优先级（P0 实时 30% / P1 repair 20% / P2 cold_start 50%）。根 SPEC FR-025 的 canonical 定义见 [SPEC.md](../SPEC.md) §7。详见根 SPEC WHEN/THEN。

### FR-030: Options Chain Raw Field Pass-through（client 实现）

**Client 实现范围**：Options 原始字段透传（Greeks 等）。根 SPEC FR-030 的 canonical 定义见 [SPEC.md](../SPEC.md) §7。详见根 SPEC WHEN/THEN。

**WHEN** client 收到 Binance Options WebSocket 事件
**THEN** 解析全部原始字段，不做字段裁剪
**AND** Options 特有字段（`delta`、`gamma`、`theta`、`vega`、`impliedVolatility`、`openInterest`、`strikePrice`、`optionType`、`expiryDate`、`underlying`）原样保留在 MarketFactEnvelope 的 `raw_fields` map 中

---

## 8. Business Rules（Client 实现约束）

> **编号规则（v3.8.0 统一）**：所有 BR 使用根 SPEC canonical 编号。本节仅列出 client 侧特有的实现约束，不定义独立 BR 编号。完整 BR 定义见 [根 SPEC](../SPEC.md) §8。

### BR-002: Client Must Not Import Server Internals（根 BR-002 的 client 侧约束）

**约束**：`module/binance/client` 的 Go import 图中不得出现 `module/binance/server` 的任何包。

**违反时**：CI gate 的 `boundary-check` 步骤（`go list -deps | grep 'binance/server'`）检测到违规 import，构建失败。PR 禁止合并。

### BR-004: natsx PubAck — 发布确认语义（根 BR-004 的 client 侧约束）

**约束**：client 必须调用 `js.Publish()` 并同步等待 `PubAck` 返回，确认消息已持久化到 JetStream，才视为发布成功。

**违反时**：若不等待 PubAck 直接返回，NATS 网络抖动时消息可能丢失，server 侧无法感知。

### BR-004a: natsx 发布状态机（根 BR-004 的 client 侧约束）

**约束**：publisher 内部状态机仅允许以下转换：

```text
pending → publishing → pub_acked
                     → pub_failed_retryable → pending（退避重试）
                     → pub_failed_terminal（NATS 拒绝或超过最大重试次数）
```

禁止 `pub_acked → publishing`（重复发布已确认事件）。

### BR-007: Wire Contract Externality（根 BR-007 的 client 侧约束）

**约束**：`module/binance/client` 的 Go import 图中不得出现 `storage/`、`query/`、`strategy/` 包。

**违反时**：同 BR-002，CI gate 检测到违规 import 后构建失败。

### BR-008: Idempotency Key Stability（根 BR-008 的 client 侧约束）

**约束**：client 生成的 idempotency key 必须在 retry 场景下稳定。key 基于 exchange + product_line + instrument_key + event_type + event_time/source_sequence 等确定性维度。

### BR-009: Admin Boundary（根 BR-009 的 client 侧约束）

**约束**：client admin 仅可变更 client-local state。禁止修改 server 状态、清理或伪造 JetStream PubAck / consumer state、暴露 secrets、触发交易动作。

---

## 9. Interface Contract

### 9.1 Connector Interface

```go
// Connector 产品线连接器接口
type Connector interface {
    // Start 启动连接并开始采集
    Start(ctx context.Context) (<-chan NormalizedEvent, error)
    // Stop 优雅关闭连接
    Stop(ctx context.Context) error
    // ProductLine 返回产品线标识
    ProductLine() string
}
```

### 9.2 Parser Interface

```go
// InstrumentParser Binance 符号解析器
type InstrumentParser interface {
    // Parse 解析 Binance 原生 symbol，返回规范身份组件
    Parse(ctx context.Context, rawSymbol string, metadata ExchangeMetadata) (*InstrumentIdentity, error)
}
```

### 9.3 Mapper Interface

```go
// CanonicalMapper 规范化事件到规范行情的映射器
type CanonicalMapper interface {
    // Map 将规范化事件转换为规范行情事件
    Map(ctx context.Context, event NormalizedEvent) (*domain_market.MarketEvent, error)
}
```

### 9.4 Publisher Interface

```go
// NATSPublisher natsx JetStream 发布器
type NATSPublisher interface {
    // Publish 发布事件到 JetStream，同步等待 PubAck
    Publish(ctx context.Context, subject string, envelope *domain_market.MarketFactEnvelope) error
    // Close 关闭 NATS 连接
    Close() error
}
```

### 9.5 IdempotencyKey Generator

```go
// IdempotencyKeyer 幂等键生成器
type IdempotencyKeyer interface {
    // Generate 为规范化事件生成跨重试稳定的幂等键
    Generate(event NormalizedEvent) (string, error)
}
```

---

## 10. Data Model

### 10.1 CatalogEntry

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| Exchange | `string` | ✅ | 交易所标识，固定 `"binance"` |
| ProductLine | `string` | ✅ | 产品线：`spot` / `um_perp` / `cm_perp` / `options` |
| InstrumentType | `string` | ✅ | 品种类型：`spot` / `perpetual` / `future` / `option` |
| Symbol | `string` | ✅ | Binance 原生 symbol |
| BaseAsset | `string` | ✅ | 基础资产 |
| QuoteAsset | `string` | ✅ | 计价资产 |
| MarginAsset | `string` | ❌ | 保证金资产（衍生品） |
| SettlementAsset | `string` | ❌ | 结算资产（衍生品） |
| Expiry | `*time.Time` | ❌ | 到期日（交割合约/期权） |
| Strike | `*decimal.Decimal` | ❌ | 行权价（期权） |
| OptionType | `string` | ❌ | 期权类型：`C` / `P` |
| ContractCode | `string` | ❌ | 合约代码 |
| PricePrecision | `int` | ✅ | 价格精度 |
| QuantityPrecision | `int` | ✅ | 数量精度 |
| Status | `string` | ✅ | 状态：`active` / `paused` / `delisted` |
| Tier | `int` | ❌ | **分级档位**（0=核心 / 1=主流 / 2=次主流 / 3=长尾 / 4=监控）。slot 预留，落地见 [ADR-005](../../design/ADR-005-symbol-tier-classification.md) §3 |
| SymbolPriority | `int` | ❌ | **同 Tier 内调度优先级**（0=最高）。命名消解见 [ADR-005](../../design/ADR-005-symbol-tier-classification.md) §2（与任务级 `LifecycleTask.Priority` 区分） |
| Collection | `string` | ❌ | **采集策略**：`full_stream` / `stream_no_depth` / `kline_only` / `rest_sample` / `rest_daily` / `disabled`。路由矩阵见 [ADR-005](../../design/ADR-005-symbol-tier-classification.md) §3.1 |
| QuoteVolumeUSD | `float64` | ❌ | **流动性信号**（分级判定依据）。依赖 ExchangeInfo decode 保留 `quoteVolume`，见 [ADR-005](../../design/ADR-005-symbol-tier-classification.md) §4.2 |

> **分级字段状态声明**：`Tier` / `SymbolPriority` / `Collection` / `QuoteVolumeUSD` 四字段为 **slot 预留**——当前 runtime（`/home/workspace/binance` `catalog.go:16-43`）尚未实现，对应运行时缺口 GAP-E24（`../../matrix/RUNTIME-GAP-MATRIX.md §2.2`）。落地实现需先完成 GAP-E6（catalog 全量化）+ GAP-E26（interval SSOT）前置。本 SPEC 开列字段槽位以提前锁定数据模型契约，避免落地时 CatalogEntry 二次重构。设计决策与三维度建模（Tier / Level / Priority 正交）权威来源为 [ADR-005](../../design/ADR-005-symbol-tier-classification.md)。

### 10.2 NormalizedEvent

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| ProductLine | `string` | ✅ | 产品线标识 |
| SourceStream | `string` | ✅ | 来源流名称 |
| RawSymbol | `string` | ✅ | Binance 原生 symbol |
| EventType | `string` | ✅ | 事件类型 |
| ExchangeEventTime | `time.Time` | ✅ | 交易所事件时间 |
| LocalReceiveTime | `time.Time` | ✅ | 本地接收时间 |
| RawPayload | `[]byte` | ❌ | 原始 payload 引用（compact 模式下为 nil） |
| CompactPayload | `[]byte` | ❌ | 紧凑 payload（raw 模式下为 nil） |
| SequenceID | `*int64` | ❌ | 序列号（如可用） |
| UpdateIDStart | `*int64` | ❌ | 更新 ID 起始（深度数据，如可用） |
| UpdateIDEnd | `*int64` | ❌ | 更新 ID 结束（深度数据，如可用） |

### 10.3 PublishRecord（发布记录，内存态）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| Subject | `string` | ✅ | natsx subject，格式 `binance.market.{line}.{type}.v1` |
| IdempotencyKey | `string` | ✅ | 幂等键（放入 Envelope Header） |
| Payload | `[]byte` | ✅ | JSON 序列化的 MarketFactEnvelope |
| State | `PublishState` | ✅ | 发布状态 |
| EnqueuedAt | `time.Time` | ✅ | 入队时间 |
| RetryCount | `int` | ✅ | 重试次数 |
| PubAckedAt | `*time.Time` | ❌ | PubAck 时间 |

### 10.4 PublishState

```go
type PublishState string

const (
    PublishPending        PublishState = "pending"
    PublishInFlight       PublishState = "publishing"
    PublishAcked          PublishState = "pub_acked"
    PublishFailedRetry    PublishState = "pub_failed_retryable"
    PublishFailedTerminal PublishState = "pub_failed_terminal"
)
```

---

## 11. Config Schema

> **Canonical source**：Client 完整配置见 [`SPEC.md`](../SPEC.md) §11.1 Client Config（`binance-client.yaml`）。以下仅列出 client 特有补充说明。

### Client 特有配置说明

| 配置键 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `binance.product_lines` | `[]string` | `["spot"]` | 启用的产品线列表。canonical 字段名见根 §11.1 |
| `binance.api_key_env` | `string` | `BINANCE_API_KEY` | API Key 环境变量名（敏感，不设默认值） |
| `binance.secret_key_env` | `string` | `BINANCE_SECRET_KEY` | Secret Key 环境变量名（敏感，不设默认值） |
| `publisher.publish_ack_timeout` | `duration` | `5s` | PubAck 等待超时（client 侧 publisher 行为参数） |
| `publisher.backpressure_queue_size` | `int` | `10000` | 内存队列最大事件数，达阈值时暂停采集 |
| `admin.bind` | `string` | `:8081` | Gin admin HTTP 绑定地址（/healthz /readyz） |

> **字段名规范**：所有 client 配置键使用 `binance.*` / `nats.*` / `publisher.*` / `retry.*` / `admin.*` 前缀，与根 §11.1 canonical 一致。禁止使用 `client.*` 前缀（历史遗留字段名，已废弃）。
>
> Client 不配置：redis / postgres / taos / clickhouse / kafka / oss / Gin API — 这些全部属于 server（根 §11.2）。

### 11.1 Symbol 分级配置（tiers，slot 预留）

> **状态**：本节为 **slot 预留**——当前 runtime `binanceFields`（`/home/workspace/binance` `pkg/binancecfg/config.go:249-269`）无任何 symbol 范围项，对应运行时缺口 GAP-E24（`../../matrix/RUNTIME-GAP-MATRIX.md §2.2`）。设计权威与完整 schema 见 [ADR-005](../../design/ADR-005-symbol-tier-classification.md) §4.4。

分级配置通过 `binance.tiers` 嵌套结构声明 per-product-line × per-tier 的采集范围（Level 边界）与采集策略（Tier 决策）：

| 配置键 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `binance.tiers.<product_line>.<tier>.max_symbols` | `int` | `0` | 该 Tier symbol 数量上限；`0` = 不限（T3 长尾 / T4 监控常用） |
| `binance.tiers.<product_line>.<tier>.collection` | `string` | 按 Tier 默认 | 采集策略：`full_stream` / `stream_no_depth` / `kline_only` / `rest_sample` / `rest_daily` / `disabled` |
| `binance.tiers.<product_line>.<tier>.symbols` | `[]string` | `[]` | 显式 symbol 列表（Level 边界，T0 人工维护蓝筹） |
| `binance.tiers.<product_line>.<tier>.filter.quote_asset` | `[]string` | `["USDT"]` | 计价资产筛选（自动选择边界） |
| `binance.tiers.<product_line>.<tier>.filter.min_volume_usd` | `float64` | `0` | 最低 24h 成交量阈值（流动性筛选，T2 常用） |

完整 YAML 示例与 `classifyTier` 三层降级算法（显式配置 → quoteVolume 流动性 → quoteAsset 兜底）见 [ADR-005](../../design/ADR-005-symbol-tier-classification.md) §4.4 / §5。

---

## 11a. Symbol 分级体系（设计引用）

> **设计权威**：[ADR-005 ExchangeInfo Symbol 采集分级体系架构裁决](../../design/ADR-005-symbol-tier-classification.md)
> **运行时状态**：slot 预留，未实现（GAP-E24，`../../matrix/RUNTIME-GAP-MATRIX.md §2.2`）

**用户架构指令**："ExchangeInfo symbol 采集的币种要分级别、分层级、分优先级，不是所有币种都采集。" 当前 runtime 在这三个维度上均为零支撑——4 条产品线把所有 TRADING（或未过期）symbol 100% 灌入 catalog，下游采集以 `Status == "active"` 为唯一谓词全量采集，无数量上限、流动性筛选或优先级分级（源码核验证据见 `report/binance/DEEP-ANALYSIS-20260704.md` §4）。

分级体系定义三个正交维度（详见 [ADR-005 §1](../../design/ADR-005-symbol-tier-classification.md)）：

| 维度 | 决定 | 数据模型字段 |
|------|------|--------------|
| **Tier（级别）** | 采集策略 + retention TTL | `CatalogEntry.Tier`（§10.1） |
| **Level（层级）** | 采集范围边界（产品线 × 数量 cap） | `binance.tiers.*.*` 配置（§11.1） |
| **Priority（优先级）** | 同 Tier 内调度次序 | `CatalogEntry.SymbolPriority`（§10.1） |

**五级分层**（T0 核心 / T1 主流 / T2 次主流 / T3 长尾 / T4 监控）、**采集策略路由矩阵**、**资源推算**（8000 stream → 940 stream）、**classifyTier 算法**、**缺口依赖链**（GAP-E6 → E26 → E24 → E25）均见 [ADR-005](../../design/ADR-005-symbol-tier-classification.md)。

**落地前置**：分级是 GAP-E6 catalog 全量化的硬前置——全量化后若不分级，资源账不可承受（spot 2000 symbol × 1m kline × 4 线，30 天 backfill ~103K 请求）。实现顺序见 [ADR-005 §9](../../design/ADR-005-symbol-tier-classification.md)。

---

## 12. Error Handling

| 错误 | 触发条件 | 处理方式 | 错误码 |
|------|----------|----------|--------|
| `ErrInvalidSymbol` | parser 无法解析 symbol | 记录 warn 日志，跳过该事件 | `BNC-CLIENT-4001` |
| `ErrProductLineDisabled` | 尝试操作未启用的产品线 | 返回错误，不启动 connector | `BNC-CLIENT-4002` |
| `ErrNATSConnect` | 无法连接 natsx JetStream | 指数退避重连；内存队列暂存事件 | `BNC-CLIENT-4003` |
| `ErrNATSPubAck` | PubAck 超时 | 重试发布；超过阈值触发告警 | `BNC-CLIENT-4004` |
| `ErrNATSBackpressure` | 内存队列达到阈值 | 暂停采集，触发告警；等待队列消化 | `BNC-CLIENT-4005` |
| `ErrCatalogReloadFailed` | catalog 重载失败 | 保留当前 catalog，记录 error 日志 | `BNC-CLIENT-4006` |
| `ErrIdentityCollision` | parser/mapper 检测到身份碰撞 | 拒绝事件，记录 error 日志 | `BNC-CLIENT-4007` |

**错误消息格式**：`"binance/client: <operation>: <detail>"`
**错误包装**：使用 `%w` 保留底层错误链
**禁止**：不在库中使用 `log.Fatal` 或 `os.Exit`

---

## 13. Edge Cases

| 场景 | 输入/状态 | 预期行为 |
|------|-----------|----------|
| 产品线身份碰撞 | `BTCUSDT` 同时出现在 Spot 和 USDⓈ-M | parser 结合 product_line 上下文产生不同 identity；mapper 验证无碰撞后才映射 |
| 重连不丢事件 | connector WebSocket 断开 | connector 自动重连；重连期间产生的事件暂存内存队列；队列满触发背压告警 |
| NATS 连接断开 | natsx 连接不可达 | publisher 退避重连；内存队列持续累积；重连后批量发布；重发由 server 幂等过滤 |
| 内存队列满 | 队列达到 backpressure_queue_size | 触发 `ErrNATSBackpressure`，暂停采集；等待队列消化后恢复 |
| 空 product_lines 配置 | `binance.product_lines` 为空 | client 启动但不启动任何 connector，admin 可操作 |
| 并发 connector 发布 | 多个 connector 同时写入内存队列 | channel-based 并发安全；单 goroutine drain 队列到 natsx |
| NATS PubAck 超时 | Publish 等待超过 `publish_ack_timeout` | 重试发布；超过 `max_publish_retry` 后触发 `ErrNATSPubAck` 告警 |
| 进程崩溃 | 任意时刻 SIGKILL | 内存队列未 PubAck 事件丢失；重启后从 WS 重新采集；server durable consumer 天然幂等 |
| catalog 热重载时活跃连接 | admin 触发 catalog reload | 已启用且仍在 catalog 中的产品线连接不中断；新增产品线启动 connector；移除产品线优雅关闭 |

---

## 14. Directory Structure

### Documentation（`module/binance/spec/client/`）

```text
module/binance/spec/client/
├── SPEC.md                  # 本文件
└── tasks/                   # Client task spec
```

### Runtime（`/home/workspace/binance` client 端目录）

> monorepo flat layout — 所有 client 逻辑以包级文件直接放在 `internal/client/` 下，仅 `connectors/`、`publisher/`、`testdata/` 为子目录。

```text
/home/workspace/binance/
├── cmd/
│   └── binance-client/
│       └── main.go                 # catalog → connectors → normalize → mapper → publisher 进程入口
└── internal/client/
    ├── doc.go                      # 包文档（wire 契约角色说明）
    ├── runtime.go                  # 顶层组装与生命周期入口
    ├── lifecycle.go                # 进程生命周期管理（启动/优雅关闭/drain）
    ├── stream_control.go           # stream 暂停/恢复/控制
    ├── catalog.go                  # 产品线目录实现
    ├── exchangeinfo.go             # ExchangeInfo catalog 基础
    ├── exchangeinfo_option.go      # Options ExchangeInfo 特化
    ├── exchangeinfo_refresh.go     # catalog 热重载
    ├── connector.go                # Connector 接口与公共逻辑
    ├── connectors/                 # 各产品线 connector 实现（spot / um_perp / cm_perp / options）
    ├── spot.go                     # spot 产品线特定逻辑
    ├── parser.go                   # Binance 符号解析器
    ├── product_line.go             # 产品线定义与配置
    ├── normalize.go                # 原始事件规范化
    ├── mapper.go                   # 规范化→规范行情映射
    ├── idempotency.go              # 幂等键生成（按事件类型强制维度）
    ├── publisher/                  # natsx JetStream publisher + 退避重试
    ├── queue.go                    # 内存有界队列（backpressure）
    ├── relay.go                    # 事件中继
    ├── admin.go                    # Gin admin 端点（/healthz /readyz）
    ├── http_ingest_endpoint.go     # smoke-only /ingest 端点（生产 404）
    ├── ingest_request.go           # ingest 请求类型
    ├── throttle.go                 # 限流与 weight 预算
    ├── resource_governance.go      # 并发上限与资源治理
    ├── cursor.go                   # 历史回填游标
    ├── history_fetcher.go          # 历史数据拉取
    ├── history_lifecycle.go        # 历史回填生命周期
    ├── history_rest.go             # 历史 REST 请求
    ├── cron_reconcile.go           # 定时对账
    ├── archive_manifest.go         # 归档清单
    ├── testdata/                   # 测试数据（spot/usdm/coinm/options raw JSON）
    └── *_test.go                   # 单元测试 + contract 测试 + benchmark
```

> **monorepo 边界约束**：`internal/client/*` 不得 import `internal/server/*`，对应 BR-002 + BOUNDARY-GATES §3 CI gate。`internal/client` 仅通过 `natsx` subject + `domain_market` envelope 与 server 解耦，禁止 `contracts` / gRPC / `internal/cs` bridge。

---

## 15. Dependencies

### 15.1 允许依赖

| 依赖 | 用途 | 来源 |
|------|------|------|
| stdlib | Go 标准库 | 标准库 |
| `module/domain_market` | 规范行情类型定义（MarketFactEnvelope） | FoundationX L2.5 |
| `module/domain_exchange` | 交易所领域值对象 | FoundationX L2.5 |
| `module/decimalx` | 高精度数值 | FoundationX L2.5 |
| `module/configx` | 配置管理 | FoundationX L1 |
| `module/observex` | 可观测性（metrics/tracing/logging） | FoundationX L1 |
| `module/natsx` | JetStream 发布（Publish + PubAck） | FoundationX 基座 |
| `github.com/gin-gonic/gin` | HTTP admin 框架 | 第三方 |

### 15.2 禁止依赖

| 禁止依赖 | 原因 |
|----------|------|
| `module/binance/server` | 违反 C/S 边界，client 不得引用 server 内部实现 |
| `module/contracts` / `google.golang.org/grpc` | v2.0.0 已删除 gRPC，通过 natsx 通信 |
| `github.com/mattn/go-sqlite3` | v2.0.0 已删除本地 spool |
| `storage/query/strategy` | 超出 client 职责范围，client 仅做采集与发布 |
| `module/market_data` | client 不直接对接 market_data，通过 server REST API 中转 |
| `module/factor_engine` 及所有分析域模块 | 跨域依赖 |
| `module/risk_engine` 及所有决策域模块 | 跨域依赖 |

### 15.3 依赖方向

```text
module/domain_market ← module/natsx
        ↑                    ↑
        │                    │
module/binance/client ────────┘
        │
        ↓ (natsx JetStream publish, subject: binance.market.*.*.v1)
NATS JetStream (BINANCE_MARKET stream)
        │
        ↓ (natsx JetStream consume)
module/binance/server
```

---

## 16. Testing

### 16.1 测试矩阵

| TC 编号 | 对应 FR | 测试类型 | 场景 | 预期结果 |
|---------|---------|----------|------|----------|
| TC-001 | FR-001 | 单元 | 加载包含 4 条产品线的 catalog | 4 条均加载，状态正确 |
| TC-002 | FR-002 | 单元 | 解析 `BTCUSDT` + `product_line=spot` | 返回 Spot 身份，非 USDⓈ-M |
| TC-003 | FR-002 | 单元 | 解析 `BTCUSDT` + `product_line=um_perp` | 返回 USDⓈ-M 永续身份 |
| TC-004 | FR-002 | 单元 | 解析 `BTC-240628-50000-C` | 返回 Options Call 身份 |
| TC-005 | FR-003 | 集成 | Spot connector 连接并接收事件 | 收到 NormalizedEvent，product_line=spot |
| TC-006 | FR-003 | 集成 | connector 断开后自动重连 | 连接恢复，事件流继续 |
| TC-007 | FR-004 | 单元 | 规范化原始 trade 事件 | 输出包含完整溯源字段 |
| TC-008 | FR-005 | 单元 | 映射规范化事件到 domain_market 类型 | 输出 `*domain_market.MarketEvent` |
| TC-009 | FR-006 | 单元 | 同一事件两次生成幂等键 | 两次 key 相同 |
| TC-010 | FR-006 | 单元 | 不同 event type 使用不同 key 策略 | key 格式符合各 type 预期 |
| TC-011 | FR-009 | 集成 | publisher 调用 `js.Publish`，NATS 返回 PubAck | 发布成功，状态 pub_acked |
| TC-012 | FR-009 | 单元 | PubAck 超时后重试 | 重试 `max_publish_retry` 次后触发告警 |
| TC-013 | FR-009 | 集成 | 内存队列满时暂停采集 | 触发 ErrNATSBackpressure，collector 暂停 |
| TC-014 | FR-010 | 单元 | `/healthz` 返回 200 | HTTP 200 |
| TC-015 | FR-010 | 单元 | admin pause 产品线 | connector 停止产生新事件 |

### 16.2 测试工具

- 框架：`testing` + `testify`
- Mock：natsx embedded test server（`nats-server -js`）
- 覆盖率：`go tool cover`
- 竞态：`go test -race`

### 16.3 测试数据

| 文件 | 用途 |
|------|------|
| `testdata/spot_raw.json` | Spot 原始事件样本 |
| `testdata/usdm_raw.json` | USDⓈ-M 原始事件样本 |
| `testdata/coinm_raw.json` | COIN-M 原始事件样本 |
| `testdata/options_raw.json` | Options 原始事件样本 |

---

## 17. Performance Budget

| 操作 | 指标 | 目标 | 测量方式 |
|------|------|------|----------|
| 事件规范化 | 延迟 P99 | < 1ms | `go test -bench` |
| 事件映射 | 延迟 P99 | < 500μs | `go test -bench` |
| 幂等键生成 | 延迟 P99 | < 100μs | `go test -bench` |
| natsx PubAck（单事件） | 延迟 P99 | < 10ms | integration benchmark |
| 内存队列 enqueue | 延迟 P99 | < 50μs | `go test -bench` |
| admin `/healthz` | 延迟 P99 | < 1ms | benchmark |
| 单 connector 采集 | 吞吐 | > 500 events/s | 集成 benchmark |
| client 内存稳态 | 内存 | < 128MB | `go test -benchmem` long-running test |
| client RSS memory（steady state） | RSS | ≤ 256MB (P99) | `/debug/vars` runtime.MemStats |
| WS message throughput（单 product_line） | 吞吐 | ≥ 10,000 msg/s (P99) | 集成 benchmark（FR-012） |
| Client E2E contribution（receive→publish） | 延迟 P95 | < 50ms（同区域部署） | 集成 benchmark（FR-029 延迟预算分解） |

> v3.9.0 新增 WS 吞吐量（≥10K msg/s）、RSS 内存上限（256MB）、端到端延迟预算分解（client<50ms）。原 128MB 为 `benchmem` 稳态指标，保留作为基准；RSS 256MB 为生产部署硬上限。

---

## 18. Observability

### 18.1 Metrics

| 指标名 | 类型 | 说明 |
|--------|------|------|
| `binance_client_raw_events_total` | counter | 原始事件接收总数（按 product_line） |
| `binance_client_events_normalized_total` | counter | 事件规范化总数 |
| `binance_client_events_mapped_total` | counter | 事件映射总数 |
| `binance_client_events_published_total` | counter | natsx 发布成功总数 |
| `binance_client_puback_latency_seconds` | histogram | PubAck 延迟分布 |
| `binance_client_publish_retry_total` | counter | 发布重试总次数 |
| `binance_client_queue_depth` | gauge | 内存队列当前深度（按 product_line） |
| `binance_client_stream_reconnects_total` | counter | 流重连总次数（按 product_line） |
| `binance_client_connector_errors_total` | counter | connector 错误总数（按 product_line） |
| `binance_client_throughput_events_per_second` | gauge | 每产品线吞吐量 |

### 18.2 Logging

| 事件 | 级别 | 字段 |
|------|------|------|
| connector started | info | product_line, stream_id |
| connector reconnecting | warn | product_line, stream_id, attempt |
| event normalized | debug | product_line, raw_symbol |
| event mapped | debug | product_line, instrument_key |
| natsx publish success | debug | subject, idempotency_key |
| natsx publish retry | warn | subject, attempt, error |
| natsx publish failed terminal | error | subject, idempotency_key, error |
| natsx backpressure triggered | error | queue_depth, threshold |
| identity collision detected | error | raw_symbol, product_lines |

### 18.3 Structured Log Fields

所有日志必须包含：product_line、stream_id。按级别可选包含：raw_symbol、instrument_key、idempotency_key、subject。

---

## 19. Security

- 不硬编码 Binance API Key、Secret Key、或任何凭证
- 不在日志中记录 API Key、Secret Key、或签名原文
- admin 端点不暴露 secrets
- admin 变更操作（pause/resume）仅允许本地访问（绑定 loopback interface）
- natsx 通信使用 TLS（`module/natsx` TLS policy 指导）
- catalog reload 的输入必须校验，防止注入非法 product_line 配置

---

## 20. CI Gate

### 20.1 通用 Gate（所有模块）

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

### 20.2 Client 专属 Gate

| Gate | 命令 | 通过条件 |
|------|------|----------|
| 边界检查（server） | `go list -deps ./... \| grep -q 'binance/server' && exit 1 \|\| exit 0` | 零匹配 |
| 边界检查（gRPC/spool） | `go list -deps ./... \| grep -qE 'google.golang.org/grpc\|go-sqlite3' && exit 1 \|\| exit 0` | 零匹配 |
| natsx 发布幂等测试 | `go test -run TestPublisherIdempotency ./...` | 全部通过 |
| 发布状态机测试 | `go test -run TestPublishStateMachine ./...` | 全部通过 |
| 幂等键稳定性测试 | `go test -run TestIdempotencyKeyStability ./...` | 全部通过 |

---

## 21. Upgrade Compatibility

| 变更类型 | 兼容性 | 迁移方式 |
|----------|--------|----------|
| 新增产品线 connector | 向后兼容 | 更新配置启用即可 |
| natsx subject 格式变更 | Breaking | 协调 client/server 版本升级，蓝绿部署 |
| natsx stream 名称变更 | Breaking | durable consumer name 版本化，消费端同步升级 |
| admin 端点路径变更 | Breaking | 更新监控和运维脚本 |
| 配置项新增 | 向后兼容 | 新配置有默认值，无需手动迁移 |
| 配置项删除/重命名 | Breaking | 提供迁移说明，旧配置项在过渡期标记 deprecated |

---

## 22. Release DoD

- [ ] 全部 4 条产品线 catalog 可加载
- [ ] parser 区分 Spot/USDⓈ-M/COIN-M/Options 身份
- [ ] 4 个 connector 均可产生规范化事件
- [ ] mapper 使用 domain_market 类型输出规范事件
- [ ] natsx publisher 同步等待 PubAck 后才视为发布成功
- [ ] 内存队列背压机制生效，队列满时暂停采集
- [ ] client 不 import server internals（CI 边界检查通过）
- [ ] client 不 import gRPC / sqlite3（CI 边界检查通过）
- [ ] client admin 仅操作本地状态
- [ ] 所有 FR 实现完成
- [ ] 所有 TC 编写并全部通过
- [ ] 覆盖率 ≥ 80%
- [ ] Performance Budget 全部达标
- [ ] CI Gate 全部通过
- [ ] 追溯矩阵更新完成
- [ ] spec 状态更新为 Implemented

---

## 23. Open Questions

### Blocking（阻塞开发）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-001 | `natsx` subject 与 payload schema 是否冻结？ | 已解决：以 root SPEC §9 `domain_market.MarketFactEnvelope` JSON + `binance.market.*.*.v1` subjects 为准 | ZoneCNH |

### Non-blocking（不阻塞开发）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-002 | 是否保留本地 spool/checkpoint？ | 已解决：不保留；PubAck + JetStream persistence 作为 publish delivery 证据，server durable consumer state 作为消费进度 | ZoneCNH |
| OQ-003 | connector 是否需要支持 Binance 多 endpoint 负载均衡？ | 已解决：v1 默认单 endpoint；多 endpoint 轮询/故障切换作为 v1.1 增强；通过配置 `endpoints[]` 启用（2026-06-17） | - |
| OQ-004 | admin 是否需要认证（即使仅绑定 loopback interface）？ | 已解决：v1 默认 loopback-only 无需认证；生产环境通过反向代理（nginx/Caddy）添加认证；v1.1 可考虑内置 API key（2026-06-17） | - |

### Future（未来考虑）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-005 | 是否需要支持 Binance WebSocket 多路复用（组合流）以减少连接数？ | 待评估 | - |
| OQ-006 | 是否需要支持 compressed payload 传输以降低 `natsx` / JetStream 带宽？ | 待评估 | - |
| OQ-007 | 是否需要支持 client 横向扩展（多实例分片采集不同产品线）？ | 待评估 | - |

---

## Appendix A: Mainnet-Only Endpoint Strategy（v3.8.0 合并）

> 来源：2026-06-26 从端点策略草案合并入本附录。原草案已于 v3.9.5 物理删除，历史可通过 `git log` 追溯。

### A.1 四产品线 Mainnet 端点清单

| 产品线 | WS StreamBase | REST Base | 常量名 |
| --- | --- | --- | --- |
| spot | `wss://stream.binance.com:9443` | `https://api.binance.com` | `MainnetSpotStreamBaseURL` / `MainnetRESTBaseURL` |
| USDⓈ-M Futures (um_perp) | `wss://fstream.binance.com` | `https://fapi.binance.com` | `UMPerpStreamBaseURL` |
| COIN-M Futures (cm_perp) | `wss://dstream.binance.com` | `https://dapi.binance.com` | `CMPerpStreamBaseURL` |
| Options | `wss://fstream.binance.com/public` | `https://vapi.binance.com` | `OptionsStreamBaseURL` |

### A.2 Mainnet-Only 策略

1. **release evidence 禁止 testnet**：所有证据文件必须基于 mainnet 端点
2. **集成测试用 mainnet**：`test/e2e/mainnet_live_test.go` gate `BINANCE_MAINNET_LIVE`
3. **testnet 代码保留为环境抽象**：`endpoints.go` 的 `Testnet*` 常量保留（开发/沙箱用），清除的是以 testnet 作为 release 证据的做法

### A.3 Evidence Gates

| Gate | 证据 |
| --- | --- |
| testnet evidence 清除 | `release/evidence/binance/` 无 testnet URL 残留 |
| mainnet 矩阵就绪 | `mainnet-coverage-matrix.txt` 存在 |
| 四线端点正确 | `endpoints.go` 常量与官方文档一致 |
