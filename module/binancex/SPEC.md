# binancex 规格

- Spec-Version: v0.1.0
- Runtime-Version: v0.1.0-patch
- Status: Draft（从 patches/binancex/adapter.go 反向提取）
- Last-Updated: 2026-06-29
- Source: `patches/binancex/adapter.go`

## 1. 摘要

`binancex` 定义交易所 SDK 抽象层。从 `binance/server` 提取 feed/session 接口为 `MarketDataFeed`，使 ingest pipeline 依赖接口而非具体 SDK 实现。支持 mock-based 测试（无需真实 WebSocket）、多交易所 adapter 多态、传输层与 ingest 逻辑清晰分离。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | `MarketDataFeed` 接口（6 方法）、`FeedEvent` 结构体、`FeedConfig` 配置、`StreamSpec` 订阅描述、`DefaultFeedConfig()`、`Validate()` |
| Depends on | `runtime-patches/domain-market`（canonical InstrumentKey/EventType 类型） |
| Consumed by | `assembly`（ServerDeps.Feed）、`cmd`（组合根）、各交易所 adapter 实现 |
| Excludes | 具体交易所 SDK 实现、WebSocket 连接管理、market data 标准化逻辑、第三方交易所 SDK |

## 3. 术语

| 术语 | 定义 |
| --- | --- |
| MarketDataFeed | 交易所无关的行情消费接口，含 Connect/Close/Subscribe/Unsubscribe/Events/Errors |
| FeedEvent | 标准化行情事件，11 字段含 InstrumentKey/EventType/EventTime/ReceivedAt/Source/SchemaVersion/Payload/Sequence/OrderingKey |
| StreamSpec | 逻辑流订阅描述，含 InstrumentKey/Channel/Interval |
| FeedConfig | 传输层配置，9 字段含 Endpoint/ReconnectBackoff/ReadTimeout/PingInterval/EventBufferSize 等 |

## 4. MarketDataFeed 接口

```go
type MarketDataFeed interface {
    Connect(ctx context.Context) error
    Close() error
    Subscribe(ctx context.Context, specs []StreamSpec) error
    Unsubscribe(ctx context.Context, specs []StreamSpec) error
    Events() <-chan FeedEvent
    Errors() <-chan error
}
```

### 4.1 FeedEvent

```go
type FeedEvent struct {
    EventID       string
    InstrumentKey domainmarket.InstrumentKey
    EventType     domainmarket.EventType
    EventTime     time.Time
    ReceivedAt    time.Time
    Source        string
    SchemaVersion string
    Payload       any
    Sequence      int64
    OrderingKey   string
}
```

### 4.2 FeedConfig

```go
type FeedConfig struct {
    Endpoint             string
    ReconnectBackoff     time.Duration
    MaxReconnectBackoff  time.Duration
    MaxReconnectAttempts int
    ReadTimeout          time.Duration
    WriteTimeout         time.Duration
    PingInterval         time.Duration
    EventBufferSize      int
    ErrorBufferSize      int
}
```

## 5. 功能需求

| FR ID | Requirement |
| --- | --- |
| FR-BX-001 | MarketDataFeed — 交易所无关行情消费接口 |
| FR-BX-002 | FeedEvent — 标准化行情事件结构 |
| FR-BX-003 | FeedConfig — 传输层配置 |
| FR-BX-004 | StreamSpec — 逻辑流订阅描述 |
| FR-BX-005 | DefaultFeedConfig — 生产安全默认值 |
| FR-BX-006 | Validate — 拒绝空 Endpoint、非正 ReadTimeout/PingInterval/EventBufferSize |

## 6. 行为约束

| BR ID | Rule |
| --- | --- |
| BR-BX-001 | 交易所无关：同一接口用于 Binance/Bybit/OKX |
| BR-BX-002 | Events()/Errors() 返回只读 channel |
| BR-BX-003 | FeedConfig.Validate 拒绝非法值 |
| BR-BX-004 | 传输层与 ingest 逻辑清晰分离 |

## 7. 非功能需求

| NFR ID | Requirement |
| --- | --- |
| NFR-BX-001 | 接口设计支持 mock 实现，无需真实 WebSocket 即可测试 |
| NFR-BX-002 | 仅依赖 stdlib + runtime-patches/domain-market |

## 8. Acceptance Criteria Registry

见 [TRACEABILITY.md §5](./TRACEABILITY.md)

## 9. 后续实现门禁

- Interface Gate: MarketDataFeed 编译期通过接口合规检查
- Test Gate: `go test ./... -count=1` 通过
- Vet Gate: `go vet ./...` 零警告

## 变更历史

| 日期 | 变更 |
| --- | --- |
| 2026-06-29 | v0.1.0 Draft：从 patches/binancex/adapter.go 反向提取，初始化 SPEC |
