# kafkax 完整规格

> 基座 · 存储扩展。Kafka 客户端封装，提供统一的生产者、消费者、序列化和可观测集成。

最后更新：2026-06-07

---

## 1. Metadata

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-07
- Owner: ZoneCNH
- Layer: 基座 · 存储扩展
- Version: v0.7.3
- Repository: [github.com/ZoneCNH/kafkax](https://github.com/ZoneCNH/kafkax)
- Related: [CONSTITUTION.md](../CONSTITUTION.md), [ARCHITECTURE.md](../ARCHITECTURE.md)

---

### 1.1 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-07 | v1.0.0 | 初始版本 | ZoneCNH |

## 2. Summary

`kafkax` 封装 Kafka 客户端，提供统一的生产者（同步/异步发送）、消费者（消费组、offset 管理）、序列化/反序列化、健康检查和可观测集成。与 kernel 生命周期集成，保证连接随应用启停。

---

## 3. Problem

70+ 模块中有多个需要使用 Kafka（事件流、日志采集、跨域消息），各自封装会导致：

- Producer/Consumer 配置不一致，部分模块未正确处理重试和超时
- 序列化方式不统一
- 消费组管理混乱，offset 提交策略不一致
- 健康检查缺失，Kafka 不可用时无法及时发现
- 可观测集成缺失，生产/消费延迟和积压无法被 metrics 采集

---

## 4. Goals

- 提供统一的 Producer 封装，支持同步发送和批量发送
- 提供统一的 Consumer 封装，支持消费组和手动 offset 管理
- 统一序列化/反序列化（可配置 codec）
- 健康检查集成到 kernel 健康体系
- 可观测集成（metrics、tracing、logging）
- 与 kernel 生命周期集成

---

## 5. Non-goals

- 不做 Kafka 集群管理（由运维配置）
- 不做消息路由（业务层决定 topic）
- 不做 exactly-once 语义（Kafka 原生支持，业务层按需使用）
- 不做 Schema Registry 集成
- 不做 Kafka Connect 集成
- 不做配置解析（→ `configx`）

---

## 6. Consumers

| 消费者 | 使用方式 |
|--------|----------|
| `market-data` | 通过 Producer 发布行情事件到 Kafka |
| `signal-engine` | 通过 Consumer 消费因子信号事件 |
| `order-engine` | 通过 Producer 发布订单事件 |
| `risk-engine` | 通过 Consumer 消费风控事件 |
| 业务域模块 | 通过 Producer/Consumer 进行跨域事件通信 |

---

## 7. Functional Requirements

### FR-001: Producer.Send

WHEN 调用 `Send(ctx, topic, key, value)` 且 Kafka 可用
THEN 消息发送成功，返回 nil

WHEN 调用 `Send(ctx, topic, key, value)` 且 Kafka 不可用
THEN 返回发送错误

WHEN 调用 `Send(ctx, topic, key, value)` 且 value 为 nil
THEN 返回错误

### FR-002: Producer.SendBatch

WHEN 调用 `SendBatch(ctx, msgs)` 且所有消息有效
THEN 批量发送所有消息，返回 nil

WHEN 调用 `SendBatch(ctx, msgs)` 且部分消息发送失败
THEN 返回第一个错误，已发送的消息不回滚

WHEN 调用 `SendBatch(ctx, msgs)` 且 msgs 为空
THEN 返回 nil

### FR-003: Consumer.Subscribe

WHEN 调用 `Subscribe(topics)` 且连接正常
THEN 加入消费组，开始接收消息，返回 nil

WHEN 调用 `Subscribe(topics)` 且 topics 为空
THEN 返回错误

WHEN 调用 `Subscribe(topics)` 且已订阅
THEN 返回错误（不允许重复订阅）

### FR-004: Consumer.Poll

WHEN 调用 `Poll(ctx)` 且有新消息
THEN 返回消息，error 为 nil

WHEN 调用 `Poll(ctx)` 且无新消息
THEN 阻塞直到有消息或 ctx 超时

WHEN ctx 被取消
THEN 返回 ctx.Err()

### FR-005: Consumer.Commit

WHEN 调用 `Commit(ctx, msg)` 且消息有效
THEN 提交 offset，返回 nil

WHEN 调用 `Commit(ctx, msg)` 且消息无效（nil 或非法 offset）
THEN 返回错误

### FR-006: Health

WHEN 调用 `Health()` 且 Kafka metadata 请求成功
THEN 返回 HealthStatus{Ready: true, Live: true}

WHEN 调用 `Health()` 且 Kafka 不可达
THEN 返回 HealthStatus{Ready: false, Live: false, Message: "..."}

---

## 8. Business Rules

| 编号 | 规则 |
|------|------|
| BR-001 | Producer 默认使用同步发送（acks=all），可通过配置切换 |
| BR-002 | Consumer 默认使用手动 offset 提交（at-least-once） |
| BR-003 | 所有操作必须接受 `context.Context`，支持超时和取消 |
| BR-004 | Consumer 必须在 Close 时提交最终 offset |
| BR-005 | Producer 重试策略可配置，默认 3 次 |
| BR-006 | Consumer 轮询间隔可配置 |
| BR-007 | Health() 必须是幂等的、无副作用的 |
| BR-008 | 错误消息不包含消息内容（防泄露敏感数据） |
| BR-009 | Consumer 不自动提交 offset（避免数据丢失） |

---

## 9. Interface Contract

```go
type Producer interface {
    Send(ctx context.Context, topic string, key []byte, value []byte) error
    SendBatch(ctx context.Context, msgs []Message) error
    Close() error
}

type Consumer interface {
    Subscribe(topics []string) error
    Poll(ctx context.Context) (*Message, error)
    Commit(ctx context.Context, msg *Message) error
    Close() error
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

func NewProducer(opts ...ProducerOption) Producer
func NewConsumer(opts ...ConsumerOption) Consumer
```text

### 9.1 Option 模式

```go
// Producer 选项
type ProducerOption func(*producerConfig)

func WithBrokers(brokers []string) ProducerOption
func WithProducerAcks(acks int) ProducerOption
func WithProducerRetries(n int) ProducerOption
func WithProducerBatchSize(size int) ProducerOption
func WithProducerLingerMs(ms int) ProducerOption
func WithProducerCodec(codec Codec) ProducerOption

// Consumer 选项
type ConsumerOption func(*consumerConfig)

func WithConsumerBrokers(brokers []string) ConsumerOption
func WithGroupID(groupID string) ConsumerOption
func WithAutoOffsetReset(reset string) ConsumerOption
func WithConsumerCodec(codec Codec) ConsumerOption
```text

### 9.2 用法示例

```go
// 创建 Producer
producer := kafkax.NewProducer(
    kafkax.WithBrokers([]string{os.Getenv("FOUNDATIONX_KAFKA_BROKER")}),
    kafkax.WithProducerAcks(-1), // all
)

// 发送消息
err := producer.Send(ctx, "orders", []byte("order-123"), orderJSON)

// 批量发送
msgs := []kafkax.Message{
    {Topic: "orders", Key: []byte("o1"), Value: v1},
    {Topic: "orders", Key: []byte("o2"), Value: v2},
}
err = producer.SendBatch(ctx, msgs)

// 创建 Consumer
consumer := kafkax.NewConsumer(
    kafkax.WithConsumerBrokers([]string{os.Getenv("FOUNDATIONX_KAFKA_BROKER")}),
    kafkax.WithGroupID("signal-engine"),
)

// 订阅
consumer.Subscribe([]string{"orders", "events"})

// 消费循环
for {
    msg, err := consumer.Poll(ctx)
    if err != nil {
        break
    }
    processMessage(msg)
    consumer.Commit(ctx, msg)
}
```text

---

## 10. Data Model

### 10.1 公共错误

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
)
```text

### 10.2 Codec 接口

```go
type Codec interface {
    Marshal(v any) ([]byte, error)
    Unmarshal(data []byte, v any) error
}
```text

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
  consumer:
    group_id: ""                  # 消费组 ID
    auto_offset_reset: earliest   # 无 offset 时的起始位置：earliest/latest
    enable_auto_commit: false     # 禁用自动提交（手动 at-least-once）
    max_poll_records: 500         # 单次 Poll 最大记录数
    session_timeout: 30s          # 会话超时
    heartbeat_interval: 10s       # 心跳间隔
  codec: json                     # 序列化方式：json / msgpack / protobuf
  health_check_interval: 10s      # 健康检查周期
```text

---

## 12. Error Handling

| 错误 | 调用方处理 |
|------|-----------|
| `ErrConnectionFailed` | 检查 Kafka broker 地址和网络，确认 Kafka 服务运行中 |
| `ErrAlreadySubscribed` | 不要重复调用 Subscribe |
| `ErrNotSubscribed` | 先调用 Subscribe 再 Poll |
| `ErrInvalidMessage` | 检查消息 topic、key、value 是否有效 |
| `ErrEmptyTopics` | 传入至少一个 topic |
| `ErrEmptyBrokers` | 传入至少一个 broker 地址 |
| `ErrSendFailed` | 检查底层错误，优先排查网络连通性和 Kafka 服务状态 |
| `ErrCommitFailed` | 检查消息是否有效，重试 Commit |

**错误消息格式：** `"kafkax: <operation>: <detail>"`
**错误包装：** 使用 `%w` 保留底层错误链

---

## 13. Edge Cases

| 场景 | 预期行为 |
|------|----------|
| Kafka 不可达时 Send | 返回 ErrConnectionFailed 或 ErrSendFailed |
| SendBatch 空消息列表 | 返回 nil（幂等） |
| Subscribe 空 topics | 返回 ErrEmptyTopics |
| Poll 时 ctx 超时 | 返回 ctx.Err() |
| Consumer 未 Subscribe 就 Poll | 返回 ErrNotSubscribed |
| Consumer 重复 Subscribe | 返回 ErrAlreadySubscribed |
| Commit nil 消息 | 返回 ErrInvalidMessage |
| Producer Close 后 Send | 返回错误 |
| Consumer Close 后 Poll | 返回错误 |
| 消息超过 max_message_bytes | 返回 ErrSendFailed |
| 消费组 rebalance | 自动重新分配 partition，不丢失消息 |

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
├── health.go                   # HealthStatus
├── options.go                  # Option 模式
├── errors.go                   # 公共错误变量
├── codec.go                    # Codec 接口及默认 JSON codec
├── internal/
│   ├── codec/                  # 内部序列化工具
│   └── retry/                  # 重试策略
├── testdata/
│   └── docker-compose.yml      # 测试用 Kafka 配置
├── example_test.go
├── benchmark_test.go
└── integration_test.go         # //go:build integration
```text

---

## 15. Dependencies

### 15.1 go.mod

```text
module github.com/ZoneCNH/kafkax

go 1.23
```text

### 15.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| stdlib | configx |
| kernel（L0 原语） | 所有业务域实现 |
| observex（interface-only） | 所有 L2.5 领域共享层 |
| Kafka 客户端库（sarama / confluent-kafka-go） | |

---

## 16. Testing

### 16.1 单元测试

| 测试场景 | 验证点 |
|----------|--------|
| Producer.Send 成功 | 消息正确发送 |
| Producer.Send 失败 | 返回错误 |
| Producer.SendBatch 批量发送 | 所有消息正确发送 |
| Producer.SendBatch 空列表 | 返回 nil |
| Consumer.Subscribe 成功 | 正确加入消费组 |
| Consumer.Subscribe 空 topics | 返回错误 |
| Consumer.Poll 有消息 | 返回消息 |
| Consumer.Poll 无消息 | 阻塞直到超时或新消息 |
| Consumer.Commit 成功 | offset 正确提交 |
| Consumer.Commit nil 消息 | 返回错误 |
| Health 检查 | Kafka 可用/不可用正确反映 |
| Codec 序列化/反序列化 | JSON / msgpack 正确 |
| 并发安全 | -race 测试通过 |

### 16.2 Given/When/Then 用例

**TC-001: 基本发送和消费**
Given Kafka 连接正常
When Producer.Send("topic", key, value)
Then Consumer.Poll 收到该消息

**TC-002: 批量发送**
Given Kafka 连接正常
When SendBatch 发送 100 条消息
Then Consumer 收到 100 条消息

**TC-003: Consumer Commit**
Given Consumer 已订阅并 Poll 到消息
When Commit 该消息
Then 重启后从该 offset 之后开始消费

**TC-004: 重试**
Given Kafka 短暂不可用
When Send 重试 3 次
Then 第 3 次成功或返回最终错误

**TC-005: Health 检查**
Given Kafka broker 可达
When 调用 Health
Then 返回 healthy；broker 不可达时返回 unhealthy

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
| metric | `kafkax.produce.duration` | histogram，发送耗时 |
| metric | `kafkax.produce.errors` | counter，发送失败次数 |
| metric | `kafkax.produce.batch.size` | histogram，批量发送消息数 |
| metric | `kafkax.consume.duration` | histogram，消费耗时 |
| metric | `kafkax.consume.lag` | gauge，消费延迟（partition offset 差值） |
| metric | `kafkax.consume.messages` | counter，消费消息数 |
| metric | `kafkax.consume.errors` | counter，消费失败次数 |
| log | `kafkax.connected` | info，连接成功 |
| log | `kafkax.disconnected` | warn，连接断开 |
| log | `kafkax.rebalancing` | info，消费组 rebalance |
| log | `kafkax.send_failed` | error，发送失败详情 |
| log | `kafkax.commit_failed` | error，commit 失败详情 |

---

## 19. Security

| 要求 | 实现方式 |
|------|----------|
| SASL 认证支持 | 通过配置传入 SASL 凭证 |
| TLS 加密传输 | 通过配置启用 TLS |
| 凭证不写日志 | 日志中对 SASL 密码脱敏 |
| 错误消息不泄露消息内容 | 错误消息只包含 topic 和 offset，不包含 value |

---

## 20. CI Gate

### 20.1 通用 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 任何测试失败或 data race |
| 覆盖率 | `go test ./... -coverprofile=cover.out && go tool cover -func=cover.out` | 总覆盖率 < 80% |
| vet | `go vet ./...` | 任何 vet 错误 |
| lint | `golangci-lint run` | 任何 lint 错误 |
| 依赖检查 | `go mod tidy && git diff --exit-code go.mod go.sum` | go.mod 不整洁 |
| Secret 扫描 | `gitleaks detect --no-git` | 泄露 secret |
| Benchmark | `go test -bench=. -benchmem -count=3 ./...` | 结果附在 PR comment |

### 20.2 kafkax 专属 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 集成测试 | `go test -tags=integration ./...` | Kafka 不可达时 skip，不阻塞 |

---

## 21. Upgrade Compatibility

| 变更类型 | 版本升级 |
|----------|----------|
| Producer 接口新增方法 | **minor**（实现需跟上） |
| Producer 接口删除/修改方法 | **major** |
| Consumer 接口新增方法 | **minor**（实现需跟上） |
| Consumer 接口删除/修改方法 | **major** |
| Message 结构体变更 | **major** |
| Option 新增字段 | minor（带默认值） |
| 默认 codec 变更 | **minor**（注意序列化兼容性） |

---

## 22. Release DoD

- [ ] 所有公共接口有 godoc 注释
- [ ] 所有公共类型有示例代码
- [ ] CHANGELOG.md 已更新
- [ ] README.md 包含：模块定位、快速开始、配置说明、API 概览
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

## 23. Open Questions

- 是否需要支持异步 Producer（回调通知发送结果）？
- 是否需要支持 Kafka Transactions（跨 topic 原子写入）？
- Consumer 是否需要支持 Assign 模式（手动指定 partition）？
- 是否需要支持 Schema Registry 集成（Avro/Protobuf schema 管理）？
- 是否需要支持 Dead Letter Queue（消费失败消息的重试和转储）？
