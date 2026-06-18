# kafkax 规格

Status: Approved
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-14
- Layer: 基座 · 存储扩展
- Version: v1.1.0
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `kernel`

> 公开投影 caveat：Status=Review 与矩阵覆盖证据不等同于 factory-grade；四源评分通过前机器事实层保持 factory=false。

---

## 1. 摘要

`kafkax` 封装 Kafka 客户端，提供统一的生产者（同步发送和批量发送）、消费者（消费组、offset 管理）、序列化/反序列化、健康检查和可观测集成。与 kernel 生命周期集成，保证连接随应用启停。异步发送、事务、Schema Registry、手动 partition assign、深度失败重试/转储编排属于后续候选或非目标，不作为 1.0 候选基线。

---

## 2. 问题与背景

70+ 模块中有多个需要使用 Kafka（事件流、日志采集、跨域消息），各自封装会导致：

- Producer/Consumer 配置不一致，部分模块未正确处理重试和超时。
- 序列化方式不统一。
- 消费组管理混乱，offset 提交策略不一致。
- 健康检查缺失，Kafka 不可用时无法及时发现。
- 可观测集成缺失，生产/消费延迟、错误、重试和积压无法被统一采集。
- 错误和日志如果包含完整 payload 或敏感连接信息，会造成数据泄露风险。

---

## 3. 目标

- 提供统一的 `Producer` 封装，支持同步单条发送和批量发送。
- 提供统一的 `Consumer` 封装，支持消费组、轮询和手动 offset 管理。
- 提供稳定的 `Message` 数据模型与 `Codec` SPI。
- 提供生产重试、消费失败分类和调用方处理边界。
- 所有公开阻塞/外部依赖操作必须接受 `context.Context` 并返回 `error` 或可诊断状态。
- 健康检查集成到 kernel 健康体系。
- 可观测集成覆盖 metrics、tracing、logging。
- 与 kernel 生命周期集成。

---

## 4. 非目标

- 不做 Kafka 集群管理（由运维配置）
- 不做消息路由（业务层决定 topic）
- 不做 exactly-once / Kafka Transactions / outbox 编排（业务层按需实现）
- 不做 Schema Registry 集成
- 不做 Kafka Connect 集成
- 不做异步 Producer 回调 API
- 不做业务事件信封或业务 schema 规范
- 不做消费失败转储编排；消费失败重试、转储和告警策略留作后续候选
- 不做幂等存储 SPI；业务幂等由调用方实现
- 不做配置解析（→ `configx`）

---

## 5. 消费者

| 消费者 | 使用方式 |
|--------|----------|
| `market-data` | 通过 Producer 发布行情消息到 Kafka |
| `signal-engine` | 通过 Consumer 消费因子信号消息 |
| `order-engine` | 通过 Producer 发布订单相关消息 |
| `risk-engine` | 通过 Consumer 消费风控消息 |
| 业务域模块 | 通过 Producer/Consumer 进行跨域事件通信 |

---

## 6. 功能需求

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
THEN 加入消费组，开始接收消息，返回 nil

WHEN 调用 `Subscribe(ctx, topics)` 且 topics 为空
THEN 返回错误

WHEN 调用 `Subscribe(ctx, topics)` 且已订阅
THEN 返回错误（不允许重复订阅）

### FR-004: Consumer.Poll

WHEN 调用 `Poll(ctx)` 且有新消息  
THEN 返回 `*Message`，error 为 `nil`。

WHEN 调用 `Poll(ctx)` 且无新消息  
THEN 阻塞直到有消息或 `ctx` 超时/取消。

WHEN Consumer 未订阅就调用 `Poll(ctx)`  
THEN 返回 `ErrNotSubscribed` 或等价状态错误。

WHEN 反序列化失败或消息非法  
THEN 返回可分类错误；模块不得自动提交 offset，不得输出 payload，调用方决定重试、跳过、转储或关闭 consumer。

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
THEN 返回 HealthStatus{Ready: true, Live: true}

WHEN 调用 `Health(ctx)` 且 Kafka 不可达
THEN 返回 HealthStatus{Ready: false, Live: false, Message: "..."}

---

## 7. 行为约束

| 编号 | 规则 | 违反时 |
| --- | --- | --- |
| BR-001 | Producer 默认使用同步发送（acks=all），可通过配置切换 | 非法 acks 在构造或首次发送前返回配置错误；默认值不得静默降级 |
| BR-002 | Consumer 默认使用手动 offset 提交（at-least-once） | 自动提交不得作为默认值；发现默认自动提交视为发布阻断 |
| BR-003 | 所有运行时操作必须接受 `context.Context`，支持超时和取消 | 缺少 ctx 或忽略 ctx 取消视为接口阻断；ctx 取消必须返回 `ctx.Err()` 或包装错误 |
| BR-004 | Consumer 必须在 Close 时处理最终 offset/资源释放边界 | `Close(ctx)` 失败必须返回错误，不得吞掉提交或释放失败 |
| BR-005 | Producer 重试策略可配置，默认 3 次 | 负数或非法重试配置返回配置错误；最终失败返回包装错误并记录指标 |
| BR-006 | Consumer 轮询间隔可配置 | 非法轮询/心跳/批量参数返回配置错误，不得使用危险默认值 |
| BR-007 | Health(ctx) 必须是幂等的、无副作用的 | 健康检查不得改变订阅、offset 或连接生命周期；失败返回 unhealthy 和错误 |
| BR-008 | 错误消息不包含消息内容（防泄露敏感数据） | 错误和日志必须脱敏；发现 payload/凭据泄露视为安全阻断 |
| BR-009 | Consumer 不自动提交 offset（避免数据丢失） | 自动提交配置不得覆盖默认安全语义；未显式 Commit 不得提交 offset |

---

## 8. 接口契约

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

type HealthChecker interface {
    Health(ctx context.Context) (HealthStatus, error)
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

func NewProducer(opts ...ProducerOption) (Producer, error)
func NewConsumer(opts ...ConsumerOption) (Consumer, error)
```

### 8.1 Option 模式

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
```

### 8.2 用法示例

```go
// 创建 Producer
producer, err := kafkax.NewProducer(
    kafkax.WithBrokers([]string{os.Getenv("KAFKAX_BROKER")}),
    kafkax.WithProducerAcks("all"),
)
if err != nil {
    return err
}

// 发送消息
err = producer.Send(ctx, "orders", []byte("order-123"), orderJSON)

msgs := []kafkax.Message{
    {Topic: "orders", Key: []byte("o1"), Value: v1},
    {Topic: "orders", Key: []byte("o2"), Value: v2},
}
err = producer.SendBatch(ctx, msgs)

// 创建 Consumer
consumer, err := kafkax.NewConsumer(
    kafkax.WithConsumerBrokers([]string{os.Getenv("KAFKAX_BROKER")}),
    kafkax.WithGroupID("signal-engine"),
)
if err != nil {
    return err
}

// 订阅
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

## 9. 数据模型

### 9.1 Message

| 字段 | 类型 | 要求 |
|------|------|------|
| Topic | string | 生产和消费时必须非空 |
| Partition | int32 | 消费后必须为 Kafka 返回值；生产前可为零值 |
| Offset | int64 | 消费后必须有效；提交时必须非负 |
| Key | []byte | 可为空；用于 Kafka 分区与业务幂等 |
| Value | []byte | 生产时必须非 nil；日志和错误不得输出完整内容 |
| Headers | map[string][]byte | 可携带 trace context 与扩展元数据 |
| Timestamp | time.Time | Kafka 消息时间；生产时可由客户端填充 |

### 9.2 公共错误

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
)
```

### 9.3 Codec 接口

```go
type Codec interface {
    Marshal(v any) ([]byte, error)
    Unmarshal(data []byte, v any) error
}
```

---

## 10. 配置模式

```yaml
kafkax:
  brokers:                        # Kafka broker 地址列表
    - "${KAFKAX_BROKER}"
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
    max_attempts: 3               # 生产发送重试上限
  codec: json                     # 序列化方式：json / msgpack / protobuf
  health_check_interval: 10s      # 健康检查周期
```

---

## 11. 错误处理

| 错误 | 调用方处理 | 模块处理 |
|------|-----------|----------|
| `ErrConnectionFailed` | 检查 Kafka broker 地址和网络，确认 Kafka 服务运行中 | 记录连接失败日志和指标，可按策略重试 |
| `ErrAlreadySubscribed` | 不要重复调用 Subscribe | 返回状态错误，不改变已有订阅 |
| `ErrNotSubscribed` | 先调用 Subscribe 再 Poll | 返回状态错误，不进行轮询 |
| `ErrInvalidMessage` | 检查消息 topic、value、offset 是否有效 | 拒绝发送/提交；不可输出完整 value |
| `ErrEmptyTopics` | 传入至少一个 topic | 拒绝订阅 |
| `ErrEmptyBrokers` | 传入至少一个 broker 地址 | 初始化失败 |
| `ErrSendFailed` | 检查底层错误，优先排查网络连通性和 Kafka 服务状态 | 达到 retry 上限后返回包装错误 |
| `ErrCommitFailed` | 错误为临时提交失败时重试 Commit；不可恢复时关闭 Consumer | 记录 commit 失败日志和指标 |
| `ErrConfigInvalid` | 修复配置后重启 | 初始化失败，禁止使用隐式危险默认值 |

**错误消息格式：** `"kafkax: <operation>: <detail>"`，不得包含 message key/value 或业务 payload。
**错误包装：** 使用 `%w` 保留底层错误链；由 ctx 取消/超时导致的失败必须保留并返回 `ctx.Err()`。
**Retry / failure 边界：** v1.0 Producer 只提供可配置发送重试（默认 3 次）。Consumer handler 重试、转储和 poison-message 策略属于调用方或后续增强，不在本客户端 baseline 内自动执行。

---

## 12. 边界情况

| 场景 | 预期行为 |
|------|----------|
| Kafka 不可达时 Send | 返回 `ErrConnectionFailed` 或 `ErrSendFailed`，记录脱敏日志和指标 |
| SendBatch 空消息列表 | 返回 nil（幂等） |
| SendBatch 部分消息失败 | 返回第一个包装错误；已发送消息不回滚 |
| Codec Marshal / Unmarshal 失败 | 返回包装错误，不输出原始 payload |
| topic 为空或非法 | 返回 `ErrInvalidMessage` 或 `ErrEmptyTopics` |
| brokers 为空 | 构造函数返回 `ErrEmptyBrokers` |
| group id 为空 | Consumer 构造或 Subscribe 返回配置错误 |
| Subscribe 空 topics | 返回 `ErrEmptyTopics` |
| Poll 时 ctx 超时 | 返回 `ctx.Err()` |
| Consumer 未 Subscribe 就 Poll | 返回 `ErrNotSubscribed` |
| Consumer 重复 Subscribe | 返回 `ErrAlreadySubscribed` |
| Commit nil 消息或非法 offset | 返回 `ErrInvalidMessage` |
| Commit 在 rebalance 期间失败 | 返回 `ErrCommitFailed` 包装错误，由调用方决定重试 |
| Producer Close 后 Send | 返回 closed 状态错误，不发送消息 |
| Consumer Close 后 Poll | 返回 closed 状态错误，不拉取消息 |
| Close 重复调用 | 幂等返回 nil 或已关闭错误，但不得 panic |
| Close 期间仍有 Send / Poll | 尊重 ctx 取消并返回 closed/ctx 错误 |
| 消息超过 max_message_bytes | 返回 `ErrSendFailed`，不记录完整消息内容 |
| 资源耗尽或背压 | 返回包装错误并记录指标，不无限阻塞 |
| 消费组 rebalance | 重新分配 partition；未成功 Commit 的消息允许重新投递 |

---

## 13. 目录结构

```
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

## 14. 依赖

### 14.1 go.mod

```
module github.com/ZoneCNH/kafkax

go 1.23
```

### 14.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| stdlib | 所有业务域实现 |
| kernel（L0 原语） | 所有 L2.5 领域共享层 |
| observex（interface-only） | 业务 schema / 业务事件模型 |
| Kafka 客户端库（sarama / confluent-kafka-go） | 配置解析实现 |

---

## 15. 测试

### 15.1 单元测试

| 测试场景 | 验证点 |
|----------|--------|
| Producer.Send 成功 | 消息正确发送 |
| Producer.Send 失败 | 返回包装错误且不泄漏 payload |
| Producer.SendBatch 批量发送 | 所有消息正确发送 |
| Producer.SendBatch 空列表 | 返回 nil |
| Producer retry | 默认 3 次，超过后返回最终错误 |
| Consumer.Subscribe 成功 | 正确加入消费组 |
| Consumer.Subscribe 空 topics | 返回错误 |
| Consumer.Subscribe 重复调用 | 返回 ErrAlreadySubscribed |
| Consumer.Poll 有消息 | 返回消息 |
| Consumer.Poll 无消息 | 阻塞直到超时或新消息 |
| Consumer.Commit 成功 | offset 正确提交 |
| Consumer.Commit nil 消息 | 返回错误 |
| Consumer.Commit rebalance 失败 | 返回 ErrCommitFailed 包装错误 |
| Close 重复调用 | 不 panic，返回稳定结果 |
| Health 检查 | Kafka 可用/不可用正确反映 |
| Codec 序列化/反序列化 | JSON / msgpack 正确 |
| Codec 失败 | 返回包装错误且不泄露 payload |
| 配置校验 | 空 brokers、空 group id、非法重试/轮询参数返回错误 |
| 错误脱敏 | 错误和日志不包含 payload 或凭据 |
| 并发安全 | -race 测试通过 |

### 15.2 Given/When/Then 用例

**TC-001: 基本发送和消费**
Given Kafka 连接正常
When Producer.Send(ctx, "topic", key, value)
Then Consumer.Poll 收到该消息

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
Then 返回 healthy；broker 不可达时返回 unhealthy

**TC-006: Subscribe 参数校验**
Given Consumer 尚未订阅
When Subscribe(ctx, nil) 或重复 Subscribe(ctx, topics)
Then 返回 ErrEmptyTopics 或 ErrAlreadySubscribed，原订阅状态不被破坏。

**TC-007: Poll 超时和取消**
Given Consumer 已订阅但暂无新消息
When Poll(ctx) 的 ctx 超时或取消
Then 返回 context 错误，不提交 offset。

**TC-008: Commit 失败处理**
Given Consumer 已 Poll 到消息
When Commit(ctx, msg) 遇到 rebalance 或 broker 提交失败
Then 返回 ErrCommitFailed 包装错误，由调用方决定重试或关闭。

**TC-009: 配置校验**
Given brokers、group_id、重试或轮询参数非法
When NewProducer 或 NewConsumer 初始化
Then 返回 ErrConfigInvalid、ErrEmptyBrokers 或等价错误。

**TC-010: 自动提交默认关闭**
Given 未显式配置自动提交
When NewConsumer 创建 Consumer
Then enable_auto_commit 默认 false，未调用 Commit 不提交 offset。

**TC-011: context 传播**
Given 外部传入带超时和 trace 的 ctx
When Send、SendBatch、Subscribe、Poll、Commit、Close 或 Health 执行
Then 操作尊重取消/超时，并传播 trace context。

**TC-012: Close 语义**
Given Producer 或 Consumer 已创建
When Close(ctx) 被调用一次或多次
Then 资源释放结果稳定，失败返回可包装错误，不 panic。

**TC-013: 日志和错误脱敏**
Given message value、broker 连接串或凭据包含敏感内容
When Send、Poll、Commit 或 Health 失败
Then 错误、日志和 trace 标签不包含完整 payload 或敏感片段。

### 15.3 Benchmark

| 场景                        | 目标   |
| --------------------------- | ------ |
| 单条发送（本地 Kafka）      | < 5ms  |
| 批量发送 100 条             | < 20ms |
| 单条消费                    | < 5ms  |
| 序列化/反序列化（1KB JSON） | < 10μs |

### 15.4 集成测试

| 场景 | 验证点 |
|------|--------|
| 完整发送-消费链 | Send → Poll → Commit |
| 批量发送-消费 | SendBatch 100 条 → Poll 收到 100 条 |
| 消费组 rebalance | 多 Consumer 实例正确分配 partition |
| 连接断开恢复 | 断开后自动重连并恢复消费 |
| 消费失败边界 | 不可重试失败返回可分类错误；调用方可基于错误决定重试、转储或关闭 Consumer；未成功处理前不自动 commit |

---

## 16. 性能预算

| 操作                   | 目标      | 测量方式         |
| ---------------------- | --------- | ---------------- |
| 单条发送（本地 Kafka） | < 5ms     | benchmark test   |
| 批量发送 100 条        | < 20ms    | benchmark test   |
| 单条消费               | < 5ms     | benchmark test   |
| 常驻内存               | < 10MB    | profiling        |
| Consumer lag           | < 1000 条 | integration test |

---

## 17. 可观测性

| 类型 | 名称 | 说明 |
|------|------|------|
| metric | `kafkax.produce.duration` | histogram/timer，发送耗时，标签：topic,status |
| metric | `kafkax.produce.errors` | counter，发送失败次数，标签：topic,error |
| metric | `kafkax.produce.batch.size` | histogram，批量发送消息数 |
| metric | `kafkax.consume.duration` | histogram/timer，消费耗时，标签：topic,group,status |
| metric | `kafkax.consume.lag` | gauge，消费延迟（partition offset 差值） |
| metric | `kafkax.consume.messages` | counter，消费次数，标签：topic,group,status |
| metric | `kafkax.consume.errors` | counter，消费失败次数，标签：topic,group,error |
| metric | `kafkax.commit.errors` | counter，commit 失败次数，标签：topic,group,error |
| metric | `kafkax.retry.attempts` | counter，生产重试次数，标签：operation,reason |
| log | `kafkax.connected` | info，连接成功 |
| log | `kafkax.disconnected` | warn，连接断开 |
| log | `kafkax.rebalancing` | info，消费组 rebalance |
| log | `kafkax.send_failed` | error，发送失败详情（脱敏） |
| log | `kafkax.commit_failed` | error，commit 失败详情 |
| log | `kafkax.poll_failed` | error，轮询失败详情 |

### 17.1 Trace

- MUST 接收并传播上游 trace context，不得无故丢失 requestId / traceId。
- MUST 在消息 headers 中注入 trace context。
- MUST 在消费端从 headers 恢复 trace context，并创建 consumer span。
- SHOULD 为 Kafka 操作创建 span，并标注 peer、operation、status、errorCode。

---

## 18. 安全

| 要求 | 实现方式 |
|------|----------|
| SASL 认证支持 | 通过配置传入 SASL 凭证 |
| TLS 加密传输 | 通过配置启用 TLS |
| 凭证不写日志 | 日志中对 SASL 密码、token、accessKey、secretKey 和连接串脱敏 |
| 错误消息不泄露消息内容 | 错误消息只包含 topic、partition、offset、错误码和摘要，不包含完整 value |
| Header 最小化传播 | 只传播 trace context 和必要元数据，不传播无关用户敏感信息 |

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

### 19.2 kafkax 专属 Gate

| Gate     | 命令                              | 阻塞条件                    |
| -------- | --------------------------------- | --------------------------- |
| 集成测试 | `go test -tags=integration ./...` | Kafka 不可达时 skip，不阻塞 |
| 结构追溯 | `TRACEABILITY.md` 覆盖 FR-001..FR-006 与 BR-001..BR-009 且包含 Task 列 | 覆盖缺失 |
| 文档结构 | `SPEC.md` 无错误代码块闭合标记，无未分类阻塞 Open Questions | 结构缺陷存在 |

---

## 20. 升级兼容性

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

## 21. 发布 DoD

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

## 22. 待解决问题

### 22.1 1.0 候选基线非阻断确认

- `Health(ctx)` 返回错误时是否需要固定错误码枚举？当前候选基线只要求返回 `HealthStatus` 和包装错误。
- `Close(ctx)` 重复调用时返回 nil 还是已关闭错误？当前候选基线只要求不得 panic，且行为需在实现中固定。

### 22.2 后续候选能力（不阻断 1.0）

- 是否增加异步 Producer 回调 API？需要先定义背压、取消和错误语义。
- 是否增加 Kafka Transactions 封装？需要先定义跨 topic 原子写入和失败恢复边界。
- Consumer 是否支持 Assign 模式（手动指定 partition）？需要先定义与消费组模式的互斥规则。
- 是否支持 Schema Registry 集成（Avro/Protobuf schema 管理）？需要先定义依赖方向和兼容策略。
- 是否支持消费失败重试/转储编排？需要先定义 topic 命名、脱敏、重试上限和告警策略。

### 22.3 明确不属于 1.0 基线

- 业务事件模型、业务 schema 治理和业务幂等存储不由 `kafkax` 1.0 定义。
- Kafka 集群运维、Kafka Connect 和跨系统消息路由不由 `kafkax` 负责。

---

## 23. 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-07 | v1.0.0 | 初始版本 | ZoneCNH |
| 2026-06-12 | v1.0.0-candidate | 对齐 1.0 候选基线、BR 处理、接口上下文与追溯要求 | ZoneCNH |

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
