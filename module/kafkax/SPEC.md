# kafkax 完整规格

> 基座 · 存储扩展。Kafka 客户端封装，提供统一的生产者、消费者、消息模型、序列化、健康检查和可观测集成。

最后更新：2026-06-12

---

## 1. Metadata

- Status: Draft（结构修复完成，等待四源评分与 arbiter；不得伪造 Approved）
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-12
- Owner: ZoneCNH
- Layer: 基座 · 存储扩展
- Version: v1.0.0-baseline-candidate
- Repository: [github.com/ZoneCNH/kafkax](https://github.com/ZoneCNH/kafkax)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md), [goal.md](./goal.md), [TRACEABILITY.md](./TRACEABILITY.md)

### 1.1 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-07 | v1.0.0-draft | 初始版本 | ZoneCNH |
| 2026-06-12 | v1.0.0-baseline-candidate | 对齐 goal/traceability，修复范围、接口、BR 违反处理和 Open Questions 分类 | OMX worker-1 |

## 2. Summary

`kafkax` 封装 Kafka 客户端，提供统一的 `Producer`、`Consumer`、`Message`、`Codec`、健康检查、重试/DLQ 边界和可观测集成。1.0 基线以现实可交付的同步发送、批量发送、消费组轮询、手动 offset 提交和错误/指标规范为准；异步 Producer、Kafka Transactions、Schema Registry 和业务事件信封属于未来演进或外部业务/contract 层能力。

---

## 3. Problem

70+ 模块中有多个需要使用 Kafka（事件流、日志采集、跨域消息），各自封装会导致：

- Producer/Consumer 配置不一致，部分模块未正确处理重试和超时。
- 序列化方式不统一。
- 消费组管理混乱，offset 提交策略不一致。
- 健康检查缺失，Kafka 不可用时无法及时发现。
- 可观测集成缺失，生产/消费延迟、错误、重试、DLQ 和积压无法被统一采集。
- 错误和日志如果包含完整 payload 或敏感连接信息，会造成数据泄露风险。

---

## 4. Goals

- 提供统一的 `Producer` 封装，支持同步单条发送和批量发送。
- 提供统一的 `Consumer` 封装，支持消费组、轮询和手动 offset 管理。
- 提供稳定的 `Message` 数据模型与 `Codec` SPI。
- 提供生产重试、消费失败分类、DLQ 发布边界和 poison message 处理规则。
- 所有公开阻塞/外部依赖操作必须接受 `context.Context` 并返回 `error` 或可诊断状态。
- 健康检查集成到 kernel 健康体系。
- 可观测集成覆盖 metrics、tracing、logging。
- 与 kernel 生命周期集成。

---

## 5. Non-goals

- 不做 Kafka 集群管理（由运维配置）。
- 不做业务消息路由或业务事件语义设计（业务层决定 topic、key、payload）。
- 不提供 1.0 稳定的 `EventEnvelope`/业务事件信封；如需业务信封，由业务或 contracts 层定义。
- 不做 exactly-once 默认承诺、Kafka Transactions 或 transactional outbox。
- 不做 Schema Registry 深度集成。
- 不做 Kafka Connect 集成。
- 不做配置解析实现（配置值由 `configx` 或应用注入）。
- 不隐藏 Kafka 的 topic、partition、consumer group 和 offset 语义。

---

## 6. Consumers

| 消费者 | 使用方式 |
|--------|----------|
| `market-data` | 通过 Producer 发布行情消息到 Kafka |
| `signal-engine` | 通过 Consumer 消费因子信号消息 |
| `order-engine` | 通过 Producer 发布订单相关消息 |
| `risk-engine` | 通过 Consumer 消费风控消息 |
| 业务域模块 | 通过 Producer/Consumer 进行跨域事件通信 |

---

## 7. Functional Requirements

### FR-001: Producer.Send

WHEN 调用 `Send(ctx, topic, key, value)` 且 Kafka 可用、消息有效  
THEN 消息发送成功，返回 `nil`。

WHEN 调用 `Send(ctx, topic, key, value)` 且 Kafka 不可用  
THEN 按 producer retry 策略重试，最终仍失败时返回可 `%w` 包装的发送错误。

WHEN 调用 `Send(ctx, topic, key, value)` 且 value 为 nil 或 topic 为空  
THEN 返回 `ErrInvalidMessage` 或等价输入错误，不发送消息。

WHEN `ctx` 被取消或超时  
THEN 停止等待，返回 `ctx.Err()` 或包装后的 context 错误。

### FR-002: Producer.SendBatch

WHEN 调用 `SendBatch(ctx, msgs)` 且所有消息有效  
THEN 批量发送所有消息，返回 `nil`。

WHEN 调用 `SendBatch(ctx, msgs)` 且部分消息发送失败  
THEN 返回第一个可诊断错误，已发送消息不伪造回滚。

WHEN 调用 `SendBatch(ctx, msgs)` 且 msgs 为空  
THEN 返回 `nil`。

WHEN `ctx` 被取消或超时  
THEN 停止批量发送等待，返回 `ctx.Err()` 或包装后的 context 错误。

### FR-003: Consumer.Subscribe

WHEN 调用 `Subscribe(ctx, topics)` 且连接正常  
THEN 加入消费组，开始接收消息，返回 `nil`。

WHEN 调用 `Subscribe(ctx, topics)` 且 topics 为空  
THEN 返回 `ErrEmptyTopics` 或等价输入错误。

WHEN 调用 `Subscribe(ctx, topics)` 且已订阅  
THEN 返回 `ErrAlreadySubscribed` 或等价状态错误。

WHEN `ctx` 被取消或超时  
THEN 返回 `ctx.Err()` 或包装后的 context 错误。

### FR-004: Consumer.Poll

WHEN 调用 `Poll(ctx)` 且有新消息  
THEN 返回 `*Message`，error 为 `nil`。

WHEN 调用 `Poll(ctx)` 且无新消息  
THEN 阻塞直到有消息或 `ctx` 超时/取消。

WHEN Consumer 未订阅就调用 `Poll(ctx)`  
THEN 返回 `ErrNotSubscribed` 或等价状态错误。

WHEN 反序列化失败或消息非法  
THEN 返回可分类错误；不可重试消息必须可进入 DLQ 处理路径。

### FR-005: Consumer.Commit

WHEN 调用 `Commit(ctx, msg)` 且消息有效  
THEN 提交 offset，返回 `nil`。

WHEN 调用 `Commit(ctx, msg)` 且消息无效（nil、空 topic 或非法 offset）  
THEN 返回 `ErrInvalidMessage` 或等价输入错误。

WHEN commit 失败  
THEN 返回 `ErrCommitFailed` 或包装后的底层错误，由调用方决定重试或关闭 consumer。

WHEN `ctx` 被取消或超时  
THEN 返回 `ctx.Err()` 或包装后的 context 错误。

### FR-006: Health

WHEN 调用 `Health(ctx)` 且 Kafka metadata 请求成功  
THEN 返回 `HealthStatus{Ready: true, Live: true}` 和 `nil` error。

WHEN 调用 `Health(ctx)` 且 Kafka 不可达  
THEN 返回 `HealthStatus{Ready: false, Live: false, Message: "..."}` 和可诊断 error。

WHEN `ctx` 被取消或超时  
THEN 返回 non-ready HealthStatus 和 `ctx.Err()` 或包装后的 context 错误。

---

## 8. Business Rules

| 编号 | 规则 | 违反时处理 |
|------|------|------------|
| BR-001 | Producer 默认使用同步发送（acks=all），可通过配置切换 | 初始化时校验配置；非法 acks 返回配置错误；运行时不得静默降级为低确认级别 |
| BR-002 | Consumer 默认使用手动 offset 提交（at-least-once） | 配置出现自动提交时必须显式拒绝或记录阻断错误，不得默认开启 auto commit |
| BR-003 | 所有公开阻塞/外部依赖操作必须接受 `context.Context`，支持超时和取消 | 接口或实现缺失 ctx 视为发布阻断；ctx 取消必须返回 ctx 错误或包装错误 |
| BR-004 | Consumer 必须在 `Close(ctx)` 时执行可控关闭流程并尽力提交已处理 offset | 关闭提交失败必须返回错误并记录 `kafkax.commit_failed`，不得吞错 |
| BR-005 | Producer 重试策略可配置，默认 3 次 | 配置非法时初始化失败；超过次数后返回最终错误并增加失败指标 |
| BR-006 | Consumer 轮询间隔、会话超时和心跳间隔可配置 | 配置非法时初始化失败；运行时不得使用未记录的隐式默认值 |
| BR-007 | `Health(ctx)` 必须是幂等的、无副作用的 | Health 不得发送/提交业务消息；副作用实现视为发布阻断 |
| BR-008 | 错误消息、日志和指标标签不得包含完整消息内容或敏感配置 | 发现泄漏时必须脱敏并补充测试；泄漏风险为发布阻断 |
| BR-009 | Consumer 不自动提交 offset（避免数据丢失） | 自动提交必须保持 disabled；检测到开启时拒绝启动或返回配置错误 |

---

## 9. Interface Contract

```go
type Producer interface {
    Send(ctx context.Context, topic string, key []byte, value []byte) error
    SendBatch(ctx context.Context, msgs []Message) error
    Close(ctx context.Context) error
}

type Consumer interface {
    Subscribe(ctx context.Context, topics []string) error
    Poll(ctx context.Context) (*Message, error)
    Commit(ctx context.Context, msg *Message) error
    Close(ctx context.Context) error
}

type Message struct {
    Topic     string
    Partition int32
    Offset    int64
    Key       []byte
    Value     []byte
    Headers   map[string][]byte
    Timestamp time.Time
}

type HealthStatus struct {
    Ready   bool
    Live    bool
    Message string
}

type DeadLetterFailure struct {
    ErrorCode string
    Reason    string
    RetryCount int
    Cause     error
}

type DeadLetterPublisher interface {
    Publish(ctx context.Context, original *Message, failure DeadLetterFailure) error
}

func NewProducer(ctx context.Context, opts ...ProducerOption) (Producer, error)
func NewConsumer(ctx context.Context, opts ...ConsumerOption) (Consumer, error)
func Health(ctx context.Context) (HealthStatus, error)
```

### 9.1 Option 模式

```go
// Producer 选项
type ProducerOption func(*producerConfig) error

func WithBrokers(brokers []string) ProducerOption
func WithProducerAcks(acks string) ProducerOption
func WithProducerRetries(n int) ProducerOption
func WithProducerBatchSize(size int) ProducerOption
func WithProducerLingerMs(ms int) ProducerOption
func WithProducerCodec(codec Codec) ProducerOption
func WithDeadLetterPublisher(publisher DeadLetterPublisher) ProducerOption

// Consumer 选项
type ConsumerOption func(*consumerConfig) error

func WithConsumerBrokers(brokers []string) ConsumerOption
func WithGroupID(groupID string) ConsumerOption
func WithAutoOffsetReset(reset string) ConsumerOption
func WithConsumerCodec(codec Codec) ConsumerOption
func WithConsumerPollInterval(interval time.Duration) ConsumerOption
func WithConsumerDLQPublisher(publisher DeadLetterPublisher) ConsumerOption
```

### 9.2 用法示例

```go
producer, err := kafkax.NewProducer(ctx,
    kafkax.WithBrokers([]string{os.Getenv("FOUNDATIONX_KAFKA_BROKER")}),
    kafkax.WithProducerAcks("all"),
)
if err != nil {
    return err
}
defer producer.Close(ctx)

err = producer.Send(ctx, "orders", []byte("order-123"), orderJSON)

msgs := []kafkax.Message{
    {Topic: "orders", Key: []byte("o1"), Value: v1},
    {Topic: "orders", Key: []byte("o2"), Value: v2},
}
err = producer.SendBatch(ctx, msgs)

consumer, err := kafkax.NewConsumer(ctx,
    kafkax.WithConsumerBrokers([]string{os.Getenv("FOUNDATIONX_KAFKA_BROKER")}),
    kafkax.WithGroupID("signal-engine"),
)
if err != nil {
    return err
}
defer consumer.Close(ctx)

if err := consumer.Subscribe(ctx, []string{"orders", "events"}); err != nil {
    return err
}

for {
    msg, err := consumer.Poll(ctx)
    if err != nil {
        return err
    }
    if err := processMessage(ctx, msg); err != nil {
        return err
    }
    if err := consumer.Commit(ctx, msg); err != nil {
        return err
    }
}
```

---

## 10. Data Model

### 10.1 Message

| 字段 | 类型 | 要求 |
|------|------|------|
| Topic | string | 生产和消费时必须非空 |
| Partition | int32 | 消费后必须为 Kafka 返回值；生产前可为零值 |
| Offset | int64 | 消费后必须有效；提交时必须非负 |
| Key | []byte | 可为空；用于 Kafka 分区与业务幂等 |
| Value | []byte | 生产时必须非 nil；日志和错误不得输出完整内容 |
| Headers | map[string][]byte | 可携带 trace context 与扩展元数据 |
| Timestamp | time.Time | Kafka 消息时间；生产时可由客户端填充 |

### 10.2 公共错误

```go
var (
    ErrConnectionFailed  = errors.New("kafkax: connection failed")
    ErrAlreadySubscribed = errors.New("kafkax: already subscribed")
    ErrNotSubscribed     = errors.New("kafkax: not subscribed")
    ErrInvalidMessage    = errors.New("kafkax: invalid message")
    ErrEmptyTopics       = errors.New("kafkax: empty topics")
    ErrEmptyBrokers      = errors.New("kafkax: empty brokers")
    ErrSendFailed        = errors.New("kafkax: send failed")
    ErrCommitFailed      = errors.New("kafkax: commit failed")
    ErrConfigInvalid     = errors.New("kafkax: invalid config")
    ErrDLQPublishFailed  = errors.New("kafkax: dlq publish failed")
)
```

### 10.3 Codec 接口

```go
type Codec interface {
    Marshal(v any) ([]byte, error)
    Unmarshal(data []byte, v any) error
}
```

---

## 11. Config Schema

```yaml
kafkax:
  brokers:                        # Kafka broker 地址列表
    - "${FOUNDATIONX_KAFKA_BROKER}"
  producer:
    acks: all                     # 确认模式：0, 1, all
    retries: 3                    # 重试次数
    batch_size: 16384             # 批量大小（字节）
    linger_ms: 5                  # 批量等待时间（毫秒）
    compression: snappy           # 压缩方式：none/gzip/snappy/lz4/zstd
    max_message_bytes: 1048576    # 单条消息最大字节数
    timeout: 30s                  # 发送超时
  consumer:
    group_id: ""                  # 消费组 ID，Consumer 必须配置
    auto_offset_reset: earliest   # 无 offset 时的起始位置：earliest/latest
    enable_auto_commit: false     # 必须禁用自动提交（手动 at-least-once）
    max_poll_records: 500         # 单次 Poll 最大记录数
    poll_interval: 100ms          # 轮询间隔
    session_timeout: 45s          # 会话超时
    heartbeat_interval: 15s       # 心跳间隔
  retry:
    max_attempts: 3               # 生产重试和可重试消费失败上限
  dlq:
    enabled: true                 # 是否启用 DLQ 发布边界
    suffix: .DLQ                  # 死信 Topic 后缀
  codec: json                     # 序列化方式：json / msgpack / protobuf
  health_check_interval: 10s      # 健康检查周期
```

---

## 12. Error Handling

| 错误 | 调用方处理 | 模块处理 |
|------|-----------|----------|
| `ErrConnectionFailed` | 检查 Kafka broker 地址和网络，确认 Kafka 服务运行中 | 记录连接失败日志和指标，可按策略重试 |
| `ErrAlreadySubscribed` | 不要重复调用 Subscribe | 返回状态错误，不改变已有订阅 |
| `ErrNotSubscribed` | 先调用 Subscribe 再 Poll | 返回状态错误，不进行轮询 |
| `ErrInvalidMessage` | 检查消息 topic、value、offset 是否有效 | 拒绝发送/提交；不可输出完整 value |
| `ErrEmptyTopics` | 传入至少一个 topic | 拒绝订阅 |
| `ErrEmptyBrokers` | 传入至少一个 broker 地址 | 初始化失败 |
| `ErrSendFailed` | 检查底层错误，优先排查网络连通性和 Kafka 服务状态 | 达到 retry 上限后返回包装错误 |
| `ErrCommitFailed` | 检查消息是否有效，必要时重试 Commit 或关闭 Consumer | 记录 commit 失败日志和指标 |
| `ErrConfigInvalid` | 修复配置后重启 | 初始化失败，禁止使用隐式危险默认值 |
| `ErrDLQPublishFailed` | 检查 DLQ topic、权限和网络 | 返回包装错误并增加 DLQ 失败指标 |

**错误消息格式：** `"kafkax: <operation>: <detail>"`  
**错误包装：** 使用 `%w` 保留底层错误链。  
**敏感信息：** 错误、日志和指标标签不得包含完整 payload、密码、token、accessKey、secretKey 或完整连接串。

---

## 13. Edge Cases

| 场景 | 预期行为 |
|------|----------|
| Kafka 不可达时 Send | 按 retry 策略重试，最终返回 ErrConnectionFailed 或 ErrSendFailed |
| SendBatch 空消息列表 | 返回 nil（幂等） |
| Subscribe 空 topics | 返回 ErrEmptyTopics |
| Poll 时 ctx 超时 | 返回 ctx.Err() 或包装后的 context 错误 |
| Consumer 未 Subscribe 就 Poll | 返回 ErrNotSubscribed |
| Consumer 重复 Subscribe | 返回 ErrAlreadySubscribed |
| Commit nil 消息 | 返回 ErrInvalidMessage |
| Producer Close 后 Send | 返回错误 |
| Consumer Close 后 Poll | 返回错误 |
| 消息超过 max_message_bytes | 返回 ErrSendFailed 或 ErrInvalidMessage，不输出完整 payload |
| 消费组 rebalance | 重新分配 partition；已处理消息依赖显式 Commit 保证 at-least-once |
| 反序列化失败 | 分类为不可重试，进入 DLQ 路径并保留原始元数据和错误摘要 |
| DLQ 发布失败 | 返回 ErrDLQPublishFailed 并记录指标，不吞错 |

---

## 14. Directory Structure

```text
kafkax/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go
├── kafkax.go                   # Producer / Consumer 工厂
├── producer.go                 # Producer 接口实现
├── consumer.go                 # Consumer 接口实现
├── health.go                   # HealthStatus / Health(ctx)
├── options.go                  # Option 模式
├── errors.go                   # 公共错误变量
├── codec.go                    # Codec 接口及默认 JSON codec
├── dlq.go                      # DeadLetterPublisher 边界
├── internal/
│   ├── codec/                  # 内部序列化工具
│   └── retry/                  # 重试策略
├── testdata/
│   └── docker-compose.yml      # 测试用 Kafka 配置
├── example_test.go
├── benchmark_test.go
└── integration_test.go         # //go:build integration
```

---

## 15. Dependencies

### 15.1 go.mod

```text
module github.com/ZoneCNH/kafkax

go 1.23
```

### 15.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| stdlib | 所有业务域实现 |
| kernel（L0 原语） | 所有 L2.5 领域共享层 |
| observex（interface-only） | 业务 schema / 业务 EventEnvelope |
| Kafka 客户端库（sarama / confluent-kafka-go） | 配置解析实现 |

---

## 16. Testing

### 16.1 单元测试

| 测试场景 | 验证点 |
|----------|--------|
| Producer.Send 成功 | 消息正确发送 |
| Producer.Send 失败 | 返回包装错误且不泄漏 payload |
| Producer.SendBatch 批量发送 | 所有消息正确发送 |
| Producer.SendBatch 空列表 | 返回 nil |
| Producer retry | 默认 3 次，超过后返回最终错误 |
| Consumer.Subscribe 成功 | 正确加入消费组 |
| Consumer.Subscribe 空 topics | 返回错误 |
| Consumer.Poll 有消息 | 返回消息 |
| Consumer.Poll 无消息 | 阻塞直到超时或新消息 |
| Consumer.Commit 成功 | offset 正确提交 |
| Consumer.Commit nil 消息 | 返回错误 |
| Consumer Close | 尽力提交已处理 offset，失败返回错误 |
| Health 检查 | Kafka 可用/不可用正确反映 |
| Codec 序列化/反序列化 | JSON / msgpack 正确 |
| DLQ 发布边界 | 保留原始元数据和失败摘要 |
| 并发安全 | -race 测试通过 |

### 16.2 Given/When/Then 用例

**TC-001: 基本发送和消费**  
Given Kafka 连接正常  
When Producer.Send("topic", key, value)  
Then Consumer.Poll 收到该消息。

**TC-002: 批量发送**  
Given Kafka 连接正常  
When SendBatch 发送 100 条消息  
Then Consumer 收到 100 条消息。

**TC-003: Consumer Commit**  
Given Consumer 已订阅并 Poll 到消息  
When Commit 该消息  
Then 重启后从该 offset 之后开始消费。

**TC-004: 重试与错误脱敏**  
Given Kafka 短暂不可用或消息非法  
When Send 重试 3 次或输入校验失败  
Then 第 3 次成功或返回最终错误，错误不包含完整 payload。

**TC-005: Health 检查**  
Given Kafka broker 可达  
When 调用 Health(ctx)  
Then 返回 healthy；broker 不可达时返回 unhealthy 和可诊断错误。

**TC-006: DLQ 路径**  
Given Consumer 收到不可反序列化消息或不可重试业务失败  
When 失败策略判定为 dead letter  
Then DLQ 发布保留原始 topic、partition、offset、key、headers、timestamp、errorCode、retryCount 和失败原因摘要。

### 16.3 Benchmark

| 场景 | 目标 |
|------|------|
| 单条发送（本地 Kafka） | < 5ms |
| 批量发送 100 条 | < 20ms |
| 单条消费 | < 5ms |
| 序列化/反序列化（1KB JSON） | < 10μs |

### 16.4 集成测试

| 场景 | 验证点 |
|------|--------|
| 完整发送-消费链 | Send → Poll → Commit |
| 批量发送-消费 | SendBatch 100 条 → Poll 收到 100 条 |
| 消费组 rebalance | 多 Consumer 实例正确分配 partition |
| 连接断开恢复 | 断开后自动重连并恢复消费 |
| DLQ 发布 | 不可重试失败进入 DLQ 且元数据完整 |

---

## 17. Performance Budget

| 操作 | 目标 | 测量方式 |
|------|------|----------|
| 单条发送（本地 Kafka） | < 5ms | benchmark test |
| 批量发送 100 条 | < 20ms | benchmark test |
| 单条消费 | < 5ms | benchmark test |
| 常驻内存 | < 10MB | profiling |
| Consumer lag | < 1000 条 | integration test |

---

## 18. Observability

| 类型 | 名称 | 说明 |
|------|------|------|
| metric | `kafkax_produce_total` | counter，发送次数，标签：topic,status |
| metric | `kafkax_produce_duration_ms` | histogram/timer，发送耗时，标签：topic,status |
| metric | `kafkax_produce_batch_size` | histogram，批量发送消息数 |
| metric | `kafkax_consume_total` | counter，消费次数，标签：topic,group,status |
| metric | `kafkax_consume_duration_ms` | histogram/timer，消费耗时 |
| metric | `kafkax_consumer_lag` | gauge，消费延迟（partition offset 差值） |
| metric | `kafkax_commit_total` | counter，commit 次数，标签：topic,group,status |
| metric | `kafkax_retry_total` | counter，重试次数，标签：operation,reason |
| metric | `kafkax_dlq_total` | counter，DLQ 发布次数，标签：topic,status,reason |
| log | `kafkax.connected` | info，连接成功 |
| log | `kafkax.disconnected` | warn，连接断开 |
| log | `kafkax.rebalancing` | info，消费组 rebalance |
| log | `kafkax.send_failed` | error，发送失败详情（脱敏） |
| log | `kafkax.commit_failed` | error，commit 失败详情 |
| log | `kafkax.dlq_failed` | error，DLQ 发布失败详情 |

### 18.1 Trace

- MUST 接收并传播上游 trace context，不得无故丢失 requestId / traceId。
- MUST 在消息 headers 中注入 trace context。
- MUST 在消费端从 headers 恢复 trace context，并创建 consumer span。
- SHOULD 为 Kafka 操作创建 span，并标注 peer、operation、status、errorCode。

---

## 19. Security

| 要求 | 实现方式 |
|------|----------|
| SASL 认证支持 | 通过配置传入 SASL 凭证 |
| TLS 加密传输 | 通过配置启用 TLS |
| 凭证不写日志 | 日志中对 SASL 密码、token、accessKey、secretKey 和连接串脱敏 |
| 错误消息不泄露消息内容 | 错误消息只包含 topic、partition、offset、错误码和摘要，不包含完整 value |
| Header 最小化传播 | 只传播 trace context 和必要元数据，不传播无关用户敏感信息 |

---

## 20. CI Gate

### 20.1 通用 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 任何测试失败或 data race |
| 覆盖率 | `mkdir -p .coverage && go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | 总覆盖率 < 80% |
| vet | `go vet ./...` | 任何 vet 错误 |
| lint | `golangci-lint run` | 任何 lint 错误 |
| 依赖检查 | `go mod tidy && git diff --exit-code go.mod go.sum` | go.mod 不整洁 |
| Secret 扫描 | `gitleaks detect --no-git` | 泄露 secret |
| Benchmark | `go test -bench=. -benchmem -count=3 ./...` | 结果附在 PR comment |

### 20.2 kafkax 专属 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 集成测试 | `go test -tags=integration ./...` | Kafka 不可达时 skip，不阻塞 |
| 结构追溯 | `TRACEABILITY.md` 覆盖 FR-001..FR-006 与 BR-001..BR-009 且包含 Task 列 | 覆盖缺失 |
| 文档结构 | `SPEC.md` 无错误代码块闭合标记，无未分类阻塞 Open Questions | 结构缺陷存在 |

---

## 21. Upgrade Compatibility

| 变更类型 | 版本升级 |
|----------|----------|
| Producer 接口新增方法 | **minor**（实现需跟上） |
| Producer 接口删除/修改方法 | **major** |
| Consumer 接口新增方法 | **minor**（实现需跟上） |
| Consumer 接口删除/修改方法 | **major** |
| Message 结构体变更 | **major**；追加可选字段可为 minor |
| Option 新增字段 | minor（带默认值） |
| 默认 codec 变更 | **minor**（注意序列化兼容性） |
| 指标名或标签语义变更 | **minor** 或 **major**，取决于兼容性影响 |

---

## 22. Release DoD

- [ ] 所有公共接口有 godoc 注释。
- [ ] 所有公共类型有示例代码。
- [ ] CHANGELOG.md 已更新。
- [ ] README.md 包含：模块定位、快速开始、配置说明、API 概览。
- [ ] 单元测试覆盖率 ≥ 80%。
- [ ] `-race` 测试通过。
- [ ] Benchmark 结果无 > 10% 回退。
- [ ] `go vet` 无警告。
- [ ] `golangci-lint` 无错误。
- [ ] Secret 扫描通过。
- [ ] 公共 API 无破坏性变更（或已 bump major）。
- [ ] 所有 Functional Requirements 有对应测试。
- [ ] 所有 Business Rules 有违反处理与对应测试或审查任务。
- [ ] 所有 Edge Cases 有对应测试。

---

## 23. Open Questions

### 23.1 非阻塞未来项（不影响 1.0 baseline candidate）

- 是否在 1.1+ 支持异步 Producer（回调通知发送结果）？
- 是否在未来支持 Kafka Transactions 或 transactional outbox？
- Consumer 是否需要支持 Assign 模式（手动指定 partition）？
- 是否在未来支持 Schema Registry 集成（Avro/Protobuf schema 管理）？
- 是否需要定义业务 `EventEnvelope` 适配层，或保持在 contracts/业务层？

### 23.2 1.0 待仲裁项

- 选择 `sarama` 还是 `confluent-kafka-go` 作为首个实现依赖。
- DLQ 发布失败时是否阻断 Consumer 关闭，还是记录并交给调用方重试。
- 指标标签基线是否需要加入 `client_id`，以及其基数上限。
