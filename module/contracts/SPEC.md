# contracts 规格

- Status: Docs Baseline Approved / Runtime Pending
- Spec-Version: v1.2.0
- Last-Updated: 2026-06-17
- Layer: 基座 · 跨域接口契约
- Version: v1.2.0-spec
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `kernel`, `transportx`

> 公开投影 caveat：Status=Approved 与 100.0% 覆盖证据不等同于 factory-grade；机器事实层保持 factory=false。

---

## 1. 摘要

`contracts` 定义跨域稳定契约——端口（接口）、事件协议和 DTO。它是域间通信的唯一合法通道，确保数据域、分析域、决策域和执行域之间的接口稳定、可演进。

---

## 2. 问题与背景

量化交易系统由多个领域组成（数据域、分析域、决策域、执行域），域间通信如果没有统一契约，会导致：

- 域间直接依赖具体实现，耦合度过高
- 接口定义散落在各域内部，变更时无法感知影响范围
- 事件协议不统一，消息格式混乱
- DTO 定义重复，同一数据在不同域中有不同表示
- 接口变更无版本管理，breaking change 无法检测

---

## 3. 目标

- 定义跨域稳定端口：`MarketDataProvider`、`MacroDataProvider` 等核心接口
- 定义事件协议：统一的 Event 接口和 Topic 常量
- 定义跨域 DTO：请求/响应/传输对象的标准格式
- 提供契约版本管理机制
- 提供 breaking change 检测能力
- 端口接口保持窄（3-5 个方法），降低实现方负担
- 事件 DTO 不可变（只读字段），保证消息安全性

---

## 4. 非目标

### 4.1 What contracts OWNS

`contracts` 的职责边界内包括：

- **DTO**：跨域数据传输对象（`MarketEvent`、`MacroPoint`、`Bar`、`SignalEvent`、`OrderEvent`、`ExecutionEvent`、`PositionEvent`、`RiskEvent`、`AlternativeEvent` 等）及其 JSON tag 和不可变性约束。
- **Event Envelope**：事件基础接口（`Event`），定义 `EventID()`、`EventType()`、`Timestamp()`、`Source()` 四个方法，以及 Topic 常量定义（点分命名，全局唯一）。
- **Command**：跨域命令对象的契约定义（如 `OrderCommand`、`RiskCommand`），提供统一的命令结构。
- **Query**：跨域查询对象的契约定义（如 `HistoryRequest`、`MacroHistoryRequest`），提供统一的查询结构。
- **Port Interface**：跨域稳定端口接口（`MarketDataProvider`、`MacroDataProvider` 等），定义方法签名、参数和返回值契约。
- **Error Code Registry**：公共错误变量注册表（`ErrInvalidSymbol`、`ErrInvalidIndicator` 等），统一错误消息格式（`"contracts: <desc>"`）。
- **Schema Versioning**：契约版本管理（`ContractVersion`、`VersionInfo`、`Change`），记录每次变更的类型、描述和影响范围。
- **Compatibility Policy**：破坏性变更检测规则和 semver 版本升级策略（major/minor 判定标准）。
- **Consumer-driven Contract Tests**：编译期接口检查（`var _ Interface = (*Impl)(nil)`）和 breaking change 测试。

### 4.2 What contracts MUST NOT own

`contracts` 明确不拥有的范围：

- **HTTP client**：不做 HTTP 请求封装，不管理连接池或 TLS 配置。
- **gRPC server**：不实现 gRPC 服务端注册、监听或 proto 编译。
- **NATS publisher**：不实现 NATS 消息发布、订阅管理或 JetStream 配置。
- **Kafka consumer**：不实现 Kafka 消费者组、offset 管理或 partition 分配。
- **Retry middleware**：不做重试策略、退避算法或熔断逻辑（→ `resiliencx`）。
- **Timeout transport**：不做传输层超时控制、deadline 传播或取消信号传递（→ `transportx`）。
- **Business workflow logic**：不承载任何业务工作流编排、状态机或决策逻辑。

### 4.3 Governance boundary

`contracts` 遵循 `xlib-standard` 的治理协议（Conventional Commits、semver、PR 模板、CI gate），但：

- **不是标准源**：`contracts` 不定义 xlib-standard 的编码规范、目录布局或工具链约定——这些由 `xlib-standard` 自身定义。
- **不是 generator**：`contracts` 不生成代码（不通过 protoc、go generate 或模板引擎产出任何文件）。
- **不是模板仓库**：`contracts` 不作为其他模块的脚手架或模板使用，每个模块从自身 SPEC 出发独立初始化。

**核心声明：`contracts` 不拥有传输实现，不绑定具体通信协议。** 它的唯一职责是定义跨域通信的"语言"（类型、接口、错误码和版本规则），而"怎么传"（传输协议、序列化格式选择、网络配置）由 `transportx` 和具体 adapter 负责。

### 4.4 明确的 Non-goals（已有）

- 不包含域内接口（留在各域内部）
- 不包含临时适配器
- 不包含通用工具函数（→ `x` 工具包）
- 不包含领域模型全集（领域值对象在 L2.5 领域共享层）
- 不承载业务逻辑实现
- 不做消息队列实现（→ `kafkax`）
- 不做存储实现（→ `redisx`、存储扩展）

---

## 5. 消费者

| 消费者             | 使用方式                                     |
| ------------------ | -------------------------------------------- |
| `market-data`      | 实现 `MarketDataProvider` 接口，发布行情事件；消费端实现 `DownstreamDispatchPort` 接收侧 |
| `module/binance`    | 通过 `MarketDataService.Ingest`（§8.4）摄入行情事件 |
| `macro-data`       | 实现 `MacroDataProvider` 接口，发布宏观事件  |
| `factor-engine`    | 消费 `MarketDataProvider` 获取行情数据       |
| `signal-engine`    | 消费因子数据，发布信号事件                   |
| `risk-engine`      | 消费信号和仓位数据，发布风险事件             |
| `order-engine`     | 消费信号事件，发布订单事件                   |
| `execution-engine` | 消费订单事件，发布执行事件                   |
| `x.go`             | 组装端口实现，注入到各域                     |

---

## 6. 功能需求

### FR-001: MarketDataProvider

WHEN 调用 `Subscribe(ctx, symbols)` 且 symbols 非空
THEN 返回一个 channel，持续推送 `MarketEvent`，直到 ctx 取消

WHEN 调用 `Subscribe(ctx, symbols)` 且 symbols 为空
THEN 返回错误，不订阅

WHEN 调用 `GetSnapshot(ctx, symbol)` 且 symbol 存在
THEN 返回该 symbol 的最新 `MarketSnapshot`

WHEN 调用 `GetSnapshot(ctx, symbol)` 且 symbol 不存在
THEN 返回错误

WHEN 调用 `GetHistory(ctx, req)` 且时间范围有效
THEN 返回指定时间范围内的 `[]Bar`

WHEN 调用 `GetHistory(ctx, req)` 且时间范围无效（start > end）
THEN 返回错误

### FR-002: MacroDataProvider

WHEN 调用 `GetLatest(ctx, indicator)` 且 indicator 存在
THEN 返回该指标的最新 `MacroPoint`

WHEN 调用 `GetLatest(ctx, indicator)` 且 indicator 不存在
THEN 返回错误

WHEN 调用 `GetHistory(ctx, req)` 且时间范围有效
THEN 返回指定时间范围内的 `[]MacroPoint`

WHEN 调用 `Subscribe(ctx, indicators)` 且 indicators 非空
THEN 返回一个 channel，持续推送 `MacroEvent`，直到 ctx 取消

### FR-003: Event 接口

WHEN 创建任何 Event 实现
THEN 必须实现 `EventID()`、`EventType()`、`Timestamp()`、`Source()` 四个方法
AND `EventID()` 返回全局唯一标识
AND `Timestamp()` 返回事件产生时间
AND `Source()` 返回事件来源标识

WHEN Event 的字段被创建后
THEN 不可修改（只读语义）

### FR-004: Topic 常量

WHEN 定义事件 Topic
THEN 使用 `contracts` 中定义的常量（如 `TopicMarketData`、`TopicSignal`）
AND Topic 名称全局唯一
AND Topic 名称使用点分命名（如 `market.data`、`signal.generated`）

WHEN 新增 Topic
THEN 必须在 `contracts` 中定义常量，不能在域内硬编码字符串

### FR-005: DTO 契约

WHEN 定义跨域 DTO
THEN 必须在 `contracts` 中定义
AND DTO 字段有 JSON tag
AND DTO 不可变（只读字段或 Builder 模式）

WHEN DTO 需要版本演进
THEN 新增字段使用 optional 语义（指针或默认值）
AND 不能删除或重命名已有字段

### FR-006: Breaking Change 检测

WHEN 端口接口的方法签名变更（增删方法、修改参数/返回值）
THEN 系统检测到破坏性变更
AND 阻止发布并要求版本升级

WHEN DTO 字段删除或类型变更
THEN 系统检测到破坏性变更
AND 阻止发布并要求版本升级

WHEN 新增可选字段（有默认值）
THEN 系统判定为非破坏性变更
AND 允许发布，版本为 minor 升级

### FR-007: Module Identity

WHEN downstream consumer reads `contracts` `README.md`
THEN the H1 heading MUST be `# contracts`
AND MUST NOT be `# xlib-standard`

WHEN module documentation references the `contracts` Go module path
THEN it MUST use `github.com/ZoneCNH/contracts`
AND MUST NOT use `github.com/ZoneCNH/xlib-standard`

WHEN `go.mod` declares the module name
THEN it MUST be `module github.com/ZoneCNH/contracts`

### FR-008: Binance C/S ingestion contract

WHEN exchange adapter (e.g. module/binance) sends normalized market data to the ingestion pipeline
THEN contracts MUST define `MarketDataService` interface with `Ingest(stream IngestRequest) (stream IngestResult, error)` method signature
AND MUST define `IngestRequest`, `IngestAck`, `IngestReject`, `IngestResult`, and `RejectCode` DTOs
AND all DTO fields MUST have snake_case JSON tags (BR-009)
AND `IngestResult` MUST carry exactly one of `Ack` or `Reject`
AND `RejectCode` MUST cover all documented failure scenarios (retryable, terminal_validation, terminal_conflict, unauthorized, rate_limited, server_unavailable, contract_violation, quality_rejected, ordering_violation, unsupported_channel)
AND `IngestRequest` fields `request_id`, `source`, `product_line`, `instrument_key`, `event_type`, `event_time`, `received_at`, `schema_version`, `payload`, and `source_metadata` MUST be required

---

## 7. 行为约束

| 编号   | 规则                                                           | 违反后果 |
| ------ | -------------------------------------------------------------- | -------- |
| BR-001 | 所有跨域 DTO 必须在 `contracts` 中定义                         | 编译失败：跨域 DTO 不在 contracts 中导致其他域无法 import |
| BR-002 | 新增契约必须说明消费方、生产方和稳定期                         | PR 审查不通过：缺少三方说明的契约变更被 CI Gate 阻断 |
| BR-003 | 契约变更是 breaking change → 需要版本升级                      | CI 阻断：breaking change 测试失败，阻止合并 |
| BR-004 | 端口接口保持窄（3-5 个方法）                                   | 审查不通过：接口方法数超出范围，增加实现方负担 |
| BR-005 | 事件 DTO 不可变（只读字段）                                    | 数据竞争风险：可变 DTO 在并发消费时产生非确定性行为 |
| BR-006 | Topic 常量全局唯一，使用点分命名                               | 消息路由冲突：重复或非标准命名的 Topic 导致消息错投 |
| BR-007 | 接口实现方必须有编译期检查（`var _ Interface = (*Impl)(nil)`） | 编译通过但运行时 panic：未实现接口的方法在运行时才能发现 |
| BR-008 | `contracts` 只依赖 L2.5 领域共享层和 stdlib                    | 循环依赖风险：contracts 若依赖 L1 运行时模块会形成依赖环 |
| BR-009 | DTO 的 JSON tag 必须使用 snake_case                            | 序列化不兼容：不同命名风格导致跨语言消费方解析失败 |
| BR-010 | 契约版本遵循 semver（breaking change → major）                 | 下游编译失败：版本号未正确反映变更级别，消费者无法评估升级风险 |

---

## 8. 接口契约

### 8.1 数据输入端口

```go
// MarketDataProvider 行情数据端口
type MarketDataProvider interface {
    Subscribe(ctx context.Context, symbols []string) (<-chan MarketEvent, error)
    GetSnapshot(ctx context.Context, symbol string) (*MarketSnapshot, error)
    GetHistory(ctx context.Context, req HistoryRequest) ([]Bar, error)
}

// MacroDataProvider 宏观数据端口
type MacroDataProvider interface {
    GetLatest(ctx context.Context, indicator string) (*MacroPoint, error)
    GetHistory(ctx context.Context, req MacroHistoryRequest) ([]MacroPoint, error)
    Subscribe(ctx context.Context, indicators []string) (<-chan MacroEvent, error)
}
```text

### 8.1b AlternativeDataProvider

```go
type AlternativeDataProvider interface {
    GetLatest(ctx context.Context, category, symbol string) (*AltDataPoint, error)
    GetHistory(ctx context.Context, req AltHistoryRequest) ([]AltDataPoint, error)
}
```text

### 8.2 事件协议

```go
// Event 事件基础接口
type Event interface {
    EventID() string
    EventType() string
    Timestamp() time.Time
    Source() string
}

// Topic 常量
const (
    TopicMarketData  = "market.data"
    TopicMacroData   = "macro.data"
    TopicAltData     = "alt.data"
    TopicSignal      = "signal.generated"
    TopicOrder       = "order.submitted"
    TopicExecution   = "execution.filled"
    TopicPosition    = "position.updated"
    TopicRisk        = "risk.alert"
    TopicAlternative = "alternative.data"
)
```text

### 8.3 核心 DTO

```go
// MarketEvent 行情事件
type MarketEvent struct {
    EventID   string          `json:"event_id"`
    Symbol    string          `json:"symbol"`
    Price     decimal.Decimal `json:"price"`
    Volume    decimal.Decimal `json:"volume"`
    Timestamp time.Time       `json:"timestamp"`
    Source    string          `json:"source"`
}

// MarketSnapshot 行情快照
type MarketSnapshot struct {
    Symbol    string          `json:"symbol"`
    Bid       decimal.Decimal `json:"bid"`
    Ask       decimal.Decimal `json:"ask"`
    Last      decimal.Decimal `json:"last"`
    Volume    decimal.Decimal `json:"volume"`
    Timestamp time.Time       `json:"timestamp"`
}

// Bar K线数据
type Bar struct {
    Symbol    string          `json:"symbol"`
    Open      decimal.Decimal `json:"open"`
    High      decimal.Decimal `json:"high"`
    Low       decimal.Decimal `json:"low"`
    Close     decimal.Decimal `json:"close"`
    Volume    decimal.Decimal `json:"volume"`
    Timestamp time.Time       `json:"timestamp"`
    Interval  string          `json:"interval"`
}

// HistoryRequest 历史数据请求
type HistoryRequest struct {
    Symbol   string    `json:"symbol"`
    Start    time.Time `json:"start"`
    End      time.Time `json:"end"`
    Interval string    `json:"interval"`
    Limit    int       `json:"limit,omitempty"`
}

// MacroPoint 宏观数据点
type MacroPoint struct {
    Indicator string          `json:"indicator"`
    Value     decimal.Decimal `json:"value"`
    Timestamp time.Time       `json:"timestamp"`
    Source    string          `json:"source"`
}

// MacroEvent 宏观事件
type MacroEvent struct {
    EventID   string      `json:"event_id"`
    Indicator string      `json:"indicator"`
    Point     MacroPoint  `json:"point"`
    Timestamp time.Time   `json:"timestamp"`
    Source    string      `json:"source"`
}

// MacroHistoryRequest 宏观历史请求
type MacroHistoryRequest struct {
    Indicator string    `json:"indicator"`
    Start     time.Time `json:"start"`
    End       time.Time `json:"end"`
    Limit     int       `json:"limit,omitempty"`
}
```text

---

### 8.4 Binance C/S ingestion wire contract

`MarketDataService` is a logical gRPC service contract for upstream exchange adapters. `contracts` owns the DTO shapes, method signatures, and wire semantics only. Transport binding (proto generation, gRPC server registration, TLS, deadlines, retries, persistence) remains outside this module per §4.2 and §4.3 governance boundaries.

> **命名约定（Naming Convention）**：本 §8.4 中所有 DTO 的 JSON tag 遵循 snake_case（BR-009）。domain-market 层使用 Go PascalCase struct 字段（无 JSON tag，BR-MKT-002）。market-data 接收侧使用 camelCase 文档字段名。以下映射表声明跨层命名等价关系，实现层负责转换：

| contracts (JSON tag) | domain-market (Go field) | market-data (doc field) | 语义 |
|---|---|---|---|
| `source` | `Venue` | `venue` | 交易所/来源场所标识 |
| `product_line` | `ProductLine` | `productLine` | canonical 产品线枚举 |
| `instrument_key` | `InstrumentKey` | `instrumentKey` | canonical 标的身份 |
| `event_type` | `EventType` | `eventType` | canonical 事件类型 |
| `event_time` | `EventTime` | `eventTime` | 交易所事件时间 |
| `received_at` | `ReceivedAt` | `receivedAt` | adapter 本地接收时间 |
| `schema_version` | — | `schemaVersion` | 契约 schema 版本 |
| `sequence` | — | `sourceSequence` | 来源序列号 |

```go
// MarketDataService receives normalized upstream market-data ingestion requests
// from exchange adapters (e.g. module/binance).
// Transport: gRPC bidirectional stream.
// Producer: module/binance client.
// Consumer: module/binance server → module/market-data downstream dispatch.
type MarketDataService interface {
    // Ingest accepts a stream of IngestRequest and returns per-request outcomes.
    Ingest(stream IngestRequest) (stream IngestResult, error)
}

// IngestRequest is an immutable item submitted by an exchange adapter.
// All fields are required unless marked optional.
type IngestRequest struct {
    // RequestID is a unique client-generated identifier for this request.
    // Server uses it for idempotency dedup and ACK correlation.
    RequestID string `json:"request_id"`

    // Source identifies the upstream producer (e.g. "binance").
    // Must not include secrets, host paths, or environment-specific tokens.
    Source string `json:"source"`

    // ProductLine is the canonical product line from domain-market.
    // Allowed values: "spot", "um_perp", "cm_perp", "option".
    ProductLine string `json:"product_line"`

    // InstrumentKey carries the canonical instrument identity as defined by domain-market.
    // Must include venue, product_line, instrument_type, symbol and
    // contract/option dimensions sufficient for collision-free identity.
    InstrumentKey json.RawMessage `json:"instrument_key"`

    // EventType is the canonical event type from domain-market.
    // Examples: "trade", "kline", "bookTicker", "depthUpdate", "markPrice",
    // "fundingRate", "openInterest", "longShortRatio".
    EventType string `json:"event_type"`

    // EventTime is the exchange-assigned event timestamp.
    // Must be non-zero. Server rejects events where EventTime is far in the future
    // or too stale relative to ReceivedAt.
    EventTime time.Time `json:"event_time"`

    // ReceivedAt is the adapter-local time when the event was received.
    // Used for latency calculation, stale-gate, and future-gate checks.
    ReceivedAt time.Time `json:"received_at"`

    // SchemaVersion identifies the IngestRequest schema version (semver).
    // Server uses it to detect mismatches before deserializing payload.
    SchemaVersion string `json:"schema_version"`

    // Payload carries the serialized canonical market fact.
    // Must deserialize to domain-market MarketFactEnvelope.
    Payload json.RawMessage `json:"payload"`

    // Sequence is an optional monotonic sequence number from the source stream.
    // When present, server uses it for gap and out-of-order detection.
    Sequence int64 `json:"sequence,omitempty"`

    // OrderingKey is an optional partition key for ordered processing.
    // Format: "{source}:{product_line}:{instrument}:{channel}".
    OrderingKey string `json:"ordering_key,omitempty"`

    // SourceMetadata carries adapter-specific metadata (stream_id, connector_version, etc.).
    // Must not contain secrets.
    SourceMetadata map[string]string `json:"source_metadata"`
}

// IngestResult is a terminal outcome for exactly one request_id.
// Exactly one of Ack or Reject is non-nil.
type IngestResult struct {
    RequestID string        `json:"request_id"`
    Ack       *IngestAck    `json:"ack,omitempty"`
    Reject    *IngestReject `json:"reject,omitempty"`
}

// IngestAck confirms the receiver accepted one request into the downstream dispatch boundary.
type IngestAck struct {
    RequestID      string `json:"request_id"`
    StreamID       string `json:"stream_id"`
    AcceptedCount  int32  `json:"accepted_count"`
    DuplicateCount int32  `json:"duplicate_count"`
    Durable        bool   `json:"durable"`
}

// IngestReject explains why one request was not accepted.
type IngestReject struct {
    RequestID    string     `json:"request_id"`
    RejectCode   RejectCode `json:"reject_code"`
    Reason       string     `json:"reason"`
    Retryable    bool       `json:"retryable"`
}

// RejectCode classifies rejection reasons for adapter retry policy decisions.
type RejectCode string

const (
    // RejectRetryable: temporary unavailability; caller should retry with backoff.
    RejectRetryable RejectCode = "retryable"

    // RejectTerminalValidation: request fails validation; retry won't help.
    RejectTerminalValidation RejectCode = "terminal_validation"

    // RejectTerminalConflict: duplicate request_id with conflicting payload; retry won't help.
    RejectTerminalConflict RejectCode = "terminal_conflict"

    // RejectUnauthorized: caller lacks credentials or permissions.
    RejectUnauthorized RejectCode = "unauthorized"

    // RejectRateLimited: caller exceeded rate limit; should back off.
    RejectRateLimited RejectCode = "rate_limited"

    // RejectServerUnavailable: server cannot accept due to internal state; retryable.
    RejectServerUnavailable RejectCode = "server_unavailable"

    // RejectContractViolation: request violates wire contract (missing fields, wrong enum, type mismatch).
    RejectContractViolation RejectCode = "contract_violation"

    // RejectQualityGate: event fails quality gate (stale, future, dirty, unreliable source).
    RejectQualityRejected RejectCode = "quality_rejected"

    // RejectOrderingViolation: sequence gap, reversal, or ordering_key mismatch detected.
    RejectOrderingViolation RejectCode = "ordering_violation"

	// RejectUnsupportedChannel: channel not in receiver support matrix.
	RejectUnsupportedChannel RejectCode = "unsupported_channel"
)
```

#### 8.4.1 字段约束表

| 字段 | 必填 | 说明 |
|---|---|---|
| `request_id` | 是 | 客户端生成的唯一标识；server 用于幂等去重和 ACK 关联 |
| `source` | 是 | 稳定上游生产方标识如 `"binance"`；不得包含密钥或主机路径 |
| `product_line` | 是 | domain-market ProductLine canonical 枚举值：`"spot"` / `"um_perp"` / `"cm_perp"` / `"option"` |
| `instrument_key` | 是 | domain-market InstrumentKey JSON 序列化；包含 venue/product_line/instrument_type/symbol 及合约/期权维度 |
| `event_type` | 是 | domain-market canonical event type |
| `event_time` | 是 | 交易所事件时间；不得为零值 |
| `received_at` | 是 | adapter 本地接收时间；用于延迟计算和时序门禁 |
| `schema_version` | 是 | semver 格式；server 先校验 schema 兼容性再解析 payload |
| `payload` | 是 | 必须可反序列化为 domain-market MarketFactEnvelope |
| `sequence` | 否 | 来源序列号；存在时 server 必须检测 gap 和乱序 |
| `ordering_key` | 否 | 分区内排序键；存在时 server 保证同 key 内顺序 |
| `source_metadata` | 是 | 至少包含 stream_id 和 connector_version |

#### 8.4.2 生产者/消费者

- **Producer**: `module/binance` client 及未来 exchange adapter
- **Consumer**: `module/binance` server → `module/market-data` downstream dispatch port
- **Stability**: v1.x DTO 字段名和 JSON tag 稳定；字段删除/重命名为 breaking change，需 major version bump

#### 8.4.3 与 MarketDataProvider 的关系

`MarketDataService`（§8.4）是 ingestion 入口契约，用于 adapter → server → market-data 的北向数据流。
`MarketDataProvider`（§8.1）是行情消费端口，用于 market-data → 策略/回测/因子引擎的南向数据流。
两者服务不同的消费者，不互相替代。

---

## 9. 数据模型

### 9.1 公共错误

```go
var (
    ErrInvalidSymbol     = errors.New("contracts: invalid symbol")
    ErrInvalidIndicator  = errors.New("contracts: invalid indicator")
    ErrInvalidTimeRange  = errors.New("contracts: invalid time range")
    ErrEmptySymbols      = errors.New("contracts: empty symbols list")
    ErrEmptyIndicators   = errors.New("contracts: empty indicators list")
    ErrSymbolNotFound    = errors.New("contracts: symbol not found")
    ErrIndicatorNotFound = errors.New("contracts: indicator not found")
)
```text

### 9.2 版本管理

```go
const (
    ContractVersion = "1.0.0"
)

// VersionInfo 契约版本信息
type VersionInfo struct {
    Version    string    `json:"version"`
    ReleasedAt time.Time `json:"released_at"`
    Changes    []Change  `json:"changes"`
}

type Change struct {
    Type        string `json:"type"`        // breaking, feature, fix
    Description string `json:"description"`
    Affected    string `json:"affected"`    // 受影响的接口/DTO
}
```text

### 9.3 事件 Topic 映射

```go
var TopicEventTypes = map[string]reflect.Type{
    TopicMarketData:  reflect.TypeOf(MarketEvent{}),
    TopicMacroData:   reflect.TypeOf(MacroEvent{}),
    TopicSignal:      reflect.TypeOf(SignalEvent{}),
    TopicOrder:       reflect.TypeOf(OrderEvent{}),
    TopicExecution:   reflect.TypeOf(ExecutionEvent{}),
    TopicPosition:    reflect.TypeOf(PositionEvent{}),
    TopicRisk:        reflect.TypeOf(RiskEvent{}),
    TopicAlternative: reflect.TypeOf(AlternativeEvent{}),
}
```text

---

## 10. 配置模式

`contracts` 自身不加载配置。它的 Go 类型定义是其他模块的编译时依赖。

事件序列化配置（供 `kafkax` 等使用）：

```yaml
events:
  serialization: json          # json / protobuf / avro
  compression: gzip            # none / gzip / snappy / lz4
  max_message_size: 1MB        # 单条消息最大大小
```text

---

## 11. 错误处理

| 错误                   | 调用方处理                             |
| ---------------------- | -------------------------------------- |
| `ErrInvalidSymbol`     | 检查 symbol 格式和是否在支持列表中     |
| `ErrInvalidIndicator`  | 检查 indicator 名称和是否在支持列表中  |
| `ErrInvalidTimeRange`  | 检查 start/end 时间，确保 start < end  |
| `ErrEmptySymbols`      | 传入至少一个 symbol                    |
| `ErrEmptyIndicators`   | 传入至少一个 indicator                 |
| `ErrSymbolNotFound`    | 确认 symbol 已订阅或在交易所支持列表中 |
| `ErrIndicatorNotFound` | 确认 indicator 名称正确                |

**错误消息格式：** `"contracts: <operation>: <detail>"`
**错误包装：** 使用 `%w` 保留底层错误链

---

## 12. 边界情况

| 场景                             | 预期行为                                     |
| -------------------------------- | -------------------------------------------- |
| Subscribe 传入重复 symbol        | 去重后订阅，不报错                           |
| Subscribe 传入无效 symbol        | 返回 `ErrInvalidSymbol`，不订阅任何 symbol   |
| GetHistory 时间范围过大（>1年）  | 正常返回，由实现方决定是否分页               |
| GetHistory 返回空结果            | 返回空 slice，不报错                         |
| Event channel 已满               | 实现方决定：阻塞或丢弃最旧消息               |
| Event channel 关闭后读取         | 返回零值，channel 关闭信号                   |
| DTO 字段为零值                   | 序列化为零值（如 `""`, `0`），不省略         |
| DTO 字段为 nil（指针类型）       | 序列化为 `null`                              |
| 并发 Subscribe + Unsubscribe     | 实现方需保证并发安全                         |
| breaking change 检测的 mock 实现 | 编译期检查 `var _ = Interface((*mock)(nil))` |

---

## 13. 目录结构

```text
contracts/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go                      # 包级文档
├── contracts.go                # 版本常量
├── market.go                   # 行情端口和 DTO（MarketDataProvider, MarketEvent, MarketSnapshot, Bar）
├── macro.go                    # 宏观端口和 DTO（MacroDataProvider, MacroPoint, MacroEvent）
├── signal.go                   # 信号 DTO（SignalEvent）
├── order.go                    # 订单 DTO（OrderEvent）
├── execution.go                # 执行 DTO（ExecutionEvent）
├── position.go                 # 仓位 DTO（PositionEvent）
├── risk.go                     # 风险 DTO（RiskEvent）
├── alternative.go              # 另类数据 DTO（AlternativeEvent）
├── events.go                   # 事件基础接口和 Topic 常量
├── ports.go                    # Provider / Consumer 端口汇总
├── errors.go                   # 公共错误变量
├── version.go                  # 版本管理和 breaking change 检测
├── internal/
│   └── validate/               # DTO 校验工具
├── testdata/
│   └── *.golden
├── example_test.go
├── benchmark_test.go
└── breaking_test.go            # breaking change 检测测试
```text

---

## 14. 依赖

### 14.1 go.mod

```text
module github.com/ZoneCNH/contracts

go 1.23
```text

### 14.2 依赖方向

| 可以依赖                                                                          | 禁止依赖                                                 |
| --------------------------------------------------------------------------------- | -------------------------------------------------------- |
| stdlib                                                                            | 所有业务域实现（market-data, signal-engine 等）          |
| L2.5 领域共享层（`decimalx`, `domain-market`, `domain-exchange`, `domain-macro`） | Foundation L1 运行时模块（kernel, configx, observex 等） |
|                                                                                   | 所有存储/中间件扩展（redisx, kafkax 等）                 |

### 14.3 特殊说明

`contracts` 处于依赖拓扑的上层，只被业务域模块 import，不 import 任何 L1 运行时模块。它通过 L2.5 领域共享层获取 `decimal.Decimal` 等领域值对象。

---

## 15. 测试

### 15.1 单元测试

| 测试场景            | 验证点                                                 |
| ------------------- | ------------------------------------------------------ |
| 端口编译期检查      | `var _ MarketDataProvider = (*mockImpl)(nil)` 编译通过 |
| DTO 序列化/反序列化 | JSON round-trip，字段值不变                            |
| 事件 topic 唯一性   | 无重复 topic 常量                                      |
| 事件接口完整性      | 所有 Event 实现满足 Event 接口                         |
| DTO 不可变性        | 创建后字段不可修改                                     |
| 错误格式            | 所有错误符合 `"contracts: <desc>"` 格式                |
| JSON tag            | 所有 DTO 字段有 snake_case JSON tag                    |

### 15.2 Given/When/Then 用例

**TC-001: MarketDataProvider 编译期检查**
Given 定义 mock 实现 `type mockMarket struct{}`
When 编译 `var _ MarketDataProvider = (*mockMarket)(nil)`
Then 编译通过（接口方法已实现）

**TC-002: DTO JSON round-trip**
Given 创建 `MarketEvent{Symbol: "BTCUSDT", Price: 50000}`
When JSON 序列化后反序列化
Then 字段值与原始对象一致

**TC-003: Breaking change 检测**
Given `MarketDataProvider` 接口有 3 个方法
When 删除 `GetHistory` 方法
Then `breaking_test.go` 中的编译期检查失败

**TC-004: Topic 唯一性**
Given 定义了 8 个 Topic 常量
When 检查是否有重复值
Then 无重复

**TC-005: Event 接口完整性**
Given 事件类型实现 Event
When 编译 contract test
Then Topic、Key、OccurredAt 和 Payload 方法均满足接口

**TC-006: 端口接口方法数**
Given 端口接口定义完成
When 运行接口规范检查
Then 每个端口接口包含 3-5 个业务方法

**TC-007: DTO 不可变性**
Given DTO 已创建
When 调用公开方法
Then 不暴露可变内部切片或 map

**TC-008: Module Identity**
Given `contracts` `README.md` 存在
When 读取 H1 标题和 `go.mod` module 声明
Then H1 为 `# contracts`（非 `# xlib-standard`）
AND `go.mod` 声明 `module github.com/ZoneCNH/contracts`

**TC-009: Binance C/S ingestion contract**
Given `MarketDataService`, `IngestRequest`, `IngestAck`, `IngestReject`, and `IngestResult` are defined
When contract tests serialize/deserialize representative Binance spot, USDⓈ-M perpetual, COIN-M perpetual, and options ingestion requests
Then all DTO fields are populated, JSON tags are stable, and reject codes cover all documented failure scenarios

### 15.3 Benchmark

| 场景              | 目标    |
| ----------------- | ------- |
| DTO JSON 序列化   | < 1μs   |
| DTO JSON 反序列化 | < 1μs   |
| Event 接口调用    | < 100ns |

### 15.4 集成测试

| 场景         | 验证点                                           |
| ------------ | ------------------------------------------------ |
| 跨域数据流   | market-data → contracts DTO → factor-engine      |
| 事件发布消费 | 生产方发布 MarketEvent → 消费方通过 channel 接收 |
| 版本兼容     | 新版本 DTO 可反序列化旧版本数据                  |

---

## 16. 性能预算

| 操作                 | 目标    | 测量方式                          |
| -------------------- | ------- | --------------------------------- |
| DTO JSON 序列化      | < 1μs   | benchmark test                    |
| DTO JSON 反序列化    | < 1μs   | benchmark test                    |
| Event 接口调用       | < 100ns | benchmark test                    |
| 编译期检查           | < 1s    | `go build`                        |
| breaking change 检测 | < 5s    | `go test -run TestBreakingChange` |

---

## 17. 可观测性

| 类型   | 名称                          | 说明                                   |
| ------ | ----------------------------- | -------------------------------------- |
| log    | `contracts.subscribe.started` | info，订阅开始，含 symbols/indicators  |
| log    | `contracts.subscribe.error`   | error，订阅失败，含 error              |
| log    | `contracts.event.published`   | debug，事件发布，含 topic 和 event_id  |
| metric | `contracts.event.count`       | counter，事件发布数量（按 topic 分组） |
| metric | `contracts.event.size`        | histogram，事件消息大小                |
| metric | `contracts.subscribe.active`  | gauge，活跃订阅数                      |

---

## 18. 安全

| 要求               | 实现方式                                  |
| ------------------ | ----------------------------------------- |
| DTO 不包含敏感数据 | DTO 只包含交易数据，不含密钥、密码        |
| 事件不泄露内部实现 | Event.Source() 使用标识符，不包含内部路径 |
| 序列化安全         | JSON 序列化不执行任意代码                 |

---

## 19. CI 门禁

### 19.1 通用 Gate

| Gate        | 命令                                                                                                               | 阻塞条件                 |
| ----------- | ------------------------------------------------------------------------------------------------------------------ | ------------------------ |
| 编译        | `go build ./...`                                                                                                   | 编译失败                 |
| 测试        | `go test ./... -race -count=1`                                                                                     | 任何测试失败或 data race |
| 覆盖率      | `mkdir -p .coverage && go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | 总覆盖率 < 80%           |
| vet         | `go vet ./...`                                                                                                     | 任何 vet 错误            |
| lint        | `golangci-lint run`                                                                                                | 任何 lint 错误           |
| 依赖检查    | `go mod tidy && git diff --exit-code go.mod go.sum`                                                                | go.mod 不整洁            |
| Secret 扫描 | `gitleaks detect --no-git`                                                                                         | 泄露 secret              |
| Benchmark   | `go test -bench=. -benchmem -count=3 ./...`                                                                        | 结果附在 PR comment      |

### 19.2 contracts 专属 Gate

| Gate            | 命令                                     | 阻塞条件                            |
| --------------- | ---------------------------------------- | ----------------------------------- |
| breaking change | `go test -run TestBreakingChange ./...`  | 接口/DTO 有破坏性变更但未 bump 版本 |
| 编译期检查      | `go test -run TestCompileCheck ./...`    | 端口接口编译期检查失败              |
| topic 唯一性    | `go test -run TestTopicUniqueness ./...` | Topic 常量有重复                    |
| 新增契约审查    | PR 必须说明消费方、生产方和稳定期        | 未说明                              |

---

## 20. 升级兼容性

| 变更类型                     | 版本升级                  |
| ---------------------------- | ------------------------- |
| 端口接口新增方法             | **major**（实现方需跟进） |
| 端口接口删除/修改方法        | **major**                 |
| DTO 新增可选字段（有默认值） | **minor**                 |
| DTO 删除/修改字段            | **major**                 |
| 新增 Topic 常量              | **minor**                 |
| 删除/重命名 Topic 常量       | **major**                 |
| 新增端口接口                 | **minor**                 |
| 新增 DTO 类型                | **minor**                 |
| Event 接口变更               | **major**                 |

---

## 21. 发布 DoD

- [ ] 所有端口接口有 godoc 注释
- [ ] 所有 DTO 有 JSON tag（snake_case）
- [ ] Binance C/S ingestion contract defined (§8.4)
- [ ] 所有 Event 实现满足 Event 接口
- [ ] CHANGELOG.md 已更新（含 breaking changes）
- [ ] breaking change 测试通过
- [ ] 编译期检查测试通过
- [ ] topic 唯一性测试通过
- [ ] 新增契约有消费方/生产方/稳定期说明
- [ ] README.md 包含：模块定位、端口概览、DTO 参考、版本策略
- [ ] 单元测试覆盖率 ≥ 80%
- [ ] `-race` 测试通过
- [ ] Benchmark 结果无 > 10% 回退
- [ ] `go vet` 无警告
- [ ] `golangci-lint` 无错误
- [ ] Secret 扫描通过
- [ ] 公共 API 无破坏性变更（或已 bump major）
- [ ] 所有 Functional Requirements 有对应测试
- [ ] 所有 Edge Cases 有对应测试

---

## 22. 待解决问题

- 端口接口是否需要支持批量操作（如 `Subscribe` 一次订阅多个 topic 的子集）？
- 是否需要支持请求-响应模式的 RPC 端口（除了事件推送）？
- DTO 是否需要支持 protobuf 序列化（除了 JSON）？
- 是否需要定义跨域的命令接口（如 `OrderCommand`、`RiskCommand`）？
- 事件版本是否需要包含在 Event 接口中（如 `EventVersion()`）？
- 是否需要支持事件 schema registry（集中管理事件格式演进）？



## 23. 变更历史

---

## Appendix A: Acceptance Criteria Registry

| AC ID | FR 引用 | 验收标准 | 验证方式 |
|-------|---------|----------|----------|
| AC-001 | FR-001 | 验收标准 TC-001 | unit test |
| AC-002 | FR-002 | 验收标准 TC-002 | unit test |
| AC-003 | FR-003 | 验收标准 TC-003 | unit test |
| AC-004 | FR-004 | 验收标准 TC-004 | unit test |
| AC-005 | FR-005 | 验收标准 TC-005 | unit test |
| AC-006 | FR-006 | 验收标准 TC-006 | unit test |
| AC-007 | FR-007 | 验收标准 TC-008 | unit test |
| AC-008 | FR-008 | 验收标准 TC-009 | unit test |

| 日期       | 版本   | 变更内容   | 作者    |
| ---------- | ------ | ---------- | ------- |
| 2026-06-07 | v1.0.0 | 初始版本   | ZoneCNH |
| 2026-06-14 | v1.0.1-spec | FR-006去测试化+BR违反后果列 | ZoneCNH |
| 2026-06-14 | v1.0.1 | TRACEABILITY §1-§7 完整重建（6 FR + 10 BR + 8 NFR + 7 TC + 15 AC），对齐文档同步，版本升至 v1.0.1-spec | ZoneCNH |
| 2026-06-14 | v1.1.0-spec | §5 边界声明重构（OWN/MUST NOT OWN/governance boundary）+ FR-007 Module Identity | ZoneCNH |
| 2026-06-17 | v1.2.0-spec | §8.4 Binance C/S ingestion wire contract（MarketDataService + IngestRequest + IngestAck + IngestReject + RejectCode），FR-008，TC-009，DoD 条目 | ZoneCNH |