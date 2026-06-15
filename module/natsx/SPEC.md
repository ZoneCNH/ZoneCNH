# natsx 规格

- Status: Review
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-14
- Layer: 基座 · 存储扩展
- Module-Version: v1.0.0
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `kernel`

> 公开投影 caveat：Status=Review 与矩阵覆盖证据不等同于 factory-grade；四源评分通过前机器事实层保持 factory=false。

---

## 1. 摘要

Scope note: 本规格描述 `/home/ZoneCNH/module/natsx` 的 1.0 目标，不单独批准或覆盖 `/home/natsx` 仓库的发布身份。

`natsx` 封装 NATS 客户端，提供统一的发布/订阅（Core NATS）、请求/响应、JetStream（持久化消息、消费者组）和可观测集成。NATS 用于模块间的低延迟内部通信，JetStream 提供持久化保证。与 kernel 生命周期集成，保证连接随应用启停。

---

## 2. 问题与背景

70+ 模块之间需要低延迟的内部通信机制，各自封装 NATS 客户端会导致：

- 连接配置不一致，部分模块未正确处理重连
- Core NATS 和 JetStream 使用场景混淆
- subject 命名不规范，消息路由混乱
- 健康检查缺失，NATS 不可用时无法及时发现
- 可观测集成缺失，发布/消费延迟无法被 metrics 采集

---

## 3. 目标

- 提供统一的 NATS 客户端封装，覆盖 Core NATS 和 JetStream
- Core NATS：Publish / Subscribe / Request-Reply（低延迟，at-most-once）
- JetStream：Publish / Subscribe / AddStream / AddConsumer（持久化，at-least-once）
- 统一序列化/反序列化（可配置 codec）
- 自动重连和重连策略
- 健康检查集成到 kernel 健康体系
- 可观测集成（metrics、tracing、logging）
- 与 kernel 生命周期集成

---

## 4. 非目标

- 不做 NATS 集群管理（由运维配置）
- 不做消息路由（业务层决定 subject）
- 不做消息去重（应用层处理 idempotency key）
- 不做 NATS Leaf Node 或 Super-Cluster 配置
- 不做配置解析（→ `configx`）

---

## 5. 消费者

| 消费者          | 使用方式                                         |
| --------------- | ------------------------------------------------ |
| `market-data`   | 通过 Core NATS 实时发布行情数据（at-most-once）  |
| `signal-engine` | 通过 Core NATS 订阅因子信号                      |
| `order-engine`  | 通过 JetStream 发布订单事件（at-least-once）     |
| `risk-engine`   | 通过 JetStream 消费风控事件（持久化）            |
| `schedulerx`    | 通过 Request-Reply 实现分布式协调                |
| 业务域模块      | 按需选择 Core NATS（实时）或 JetStream（持久化） |

---

## 6. 功能需求

### FR-001: Publish（Core NATS）

WHEN 调用 `Publish(ctx, subject, data)` 且连接正常
THEN 消息发布成功，返回 nil

WHEN 调用 `Publish(ctx, subject, data)` 且连接不可用
THEN 返回发布错误

WHEN 调用 `Publish(ctx, subject, data)` 且 subject 为空
THEN 返回错误

### FR-002: Subscribe（Core NATS）

WHEN 调用 `Subscribe(ctx, subject, handler)` 且连接正常
THEN 注册订阅，返回 Subscription，error 为 nil

WHEN 收到消息时
THEN 调用 handler 处理消息

WHEN 调用 `Unsubscribe()` 时
THEN 取消订阅，不再接收消息

WHEN 调用 `Drain()` 时
THEN 处理完已接收的消息后关闭订阅

### FR-003: Request（Core NATS）

WHEN 调用 `Request(ctx, subject, data, timeout)` 且有 responder
THEN 返回响应数据，error 为 nil

WHEN 调用 `Request(ctx, subject, data, timeout)` 且无 responder
THEN 超时后返回错误

WHEN 调用 `Request(ctx, subject, data, timeout)` 且 ctx 被取消
THEN 返回 ctx.Err()

### FR-004: JetStreamClientX.Publish

WHEN 调用 `JetStreamClientX.Publish(ctx, subject, msg, opts...)` 且 stream 已创建
THEN 消息持久化成功，返回 PublishAck

WHEN 调用 `JetStreamClientX.Publish(ctx, subject, msg, opts...)` 且 stream 未创建
THEN 返回错误

### FR-005: JetStreamClientX.Subscribe

WHEN 调用 `JetStreamClientX.Subscribe(ctx, subject, handler, opts...)` 且 consumer 已创建
THEN 注册订阅，返回 Subscription

WHEN 消息被 ack 后
THEN 消费成功，offset 推进

WHEN 消息未 ack 且超过 max_deliver
THEN 消息进入 Dead Letter

### FR-006: JetStream.AddStream

WHEN 调用 `AddStream(ctx, cfg)` 且 stream 不存在
THEN 创建 stream，返回 nil

WHEN 调用 `AddStream(ctx, cfg)` 且 stream 已存在且配置兼容
THEN 返回 nil（幂等）

WHEN 调用 `AddStream(ctx, cfg)` 且 stream 已存在且配置冲突
THEN 返回错误

### FR-007: JetStream.AddConsumer

WHEN 调用 `AddConsumer(ctx, stream, cfg)` 且 consumer 不存在
THEN 创建 consumer，返回 nil

WHEN 调用 `AddConsumer(ctx, stream, cfg)` 且 consumer 已存在且配置兼容
THEN 返回 nil（幂等）

WHEN 调用 `AddConsumer(ctx, stream, cfg)` 且 consumer 已存在且配置冲突
THEN 返回错误

### FR-008: Health

WHEN 调用 `Health()` 且 NATS 连接正常
THEN 返回 HealthStatus{Ready: true, Live: true}

WHEN 调用 `Health()` 且 NATS 不可达
THEN 返回 HealthStatus{Ready: false, Live: false, Message: "..."}

WHEN JetStream 已启用且 JetStream 不可用
THEN 返回 HealthStatus{Ready: false, Live: true, Message: "jetstream unavailable"}

---

### 6.1 Acceptance Criteria Registry

| AC-ID | 功能 | 验收标准 | 验证方式 | 判定结果 |
|-------|---------|----------|----------|----------|
| AC-001 | Publish（Core NATS） | Publish 成功返回 nil；连接不可用时返回错误；空 subject 返回错误 | TC-001, unit test | ✅ Covered |
| AC-002 | Subscribe（Core NATS） | Subscribe 注册返回 Subscription；收到消息时调用 handler；Unsubscribe/Drain 后不再接收 | TC-001, unit test | ✅ Subscribe/queue/unsubscribe, subscription Drain, and client close covered |
| AC-003 | Request（Core NATS） | Request 有 responder 时返回响应；无 responder 时超时返回错误；ctx 取消时返回 ctx.Err() | TC-002, unit test | ✅ Responder/no-responder/timeout/cancel covered |
| AC-004 | JetStreamClientX.Publish | JetStreamClientX Publish 返回 PublishAck；stream 未创建时返回错误 | TC-003, unit test | ✅ Stream-present and missing-stream publish covered |
| AC-005 | JetStreamClientX.Subscribe | JetStreamClientX Subscribe 注册返回 Subscription；ack 后 offset 推进；超 max_deliver 进入 Dead Letter | TC-003, unit test | ✅ Pull, ack, nack redelivery, and max-deliveries advisory covered |
| AC-006 | JetStream.AddStream | AddStream 幂等创建；配置兼容时返回 nil；配置冲突时返回错误 | TC-003, unit test | ✅ AddStream create/idempotency/conflict covered |
| AC-007 | JetStream.AddConsumer | AddConsumer 幂等创建；配置兼容时返回 nil；配置冲突时返回错误 | TC-003, unit test | ✅ AddConsumer create/idempotency/conflict covered |
| AC-008 | Health | NATS 可用时 Health() 返回 Ready=true/Live=true；不可达时 Ready=false/Live=false；JetStream 不可用时 Ready=false/Live=true | TC-005, unit test | ✅ Healthy, disconnected, nil, canceled, closed, reconnect, and degraded health paths covered |


## 7. 行为约束

| 编号 | 规则 | 违反时 |
| --- | --- | --- |
| BR-001 | Core NATS 用于实时低延迟场景（at-most-once） | 误用 JetStream 处理实时消息 → 延迟超标、性能告警 |
| BR-002 | JetStream 用于需要持久化保证的场景（at-least-once） | 误用 Core NATS 处理持久化消息 → 消息丢失风险 |
| BR-003 | 所有操作必须接受 `context.Context`，支持超时和取消 | 编译失败：接口签名不含 ctx；或 ctx 取消不生效 → TC-001/TC-002 测试失败 |
| BR-004 | 订阅 handler 必须快速返回，长时间处理应异步化 | handler 阻塞 → Drain 超时 → 返回 ErrDrainTimeout |
| BR-005 | 自动重连策略可配置，默认指数退避 | 重连失败 → 返回 ErrConnectionFailed；CI Gate TC-004 失败 |
| BR-006 | Health() 必须是幂等的、无副作用的 | 多次调用产生副作用 → CI Gate 健康检查测试失败 |
| BR-007 | JetStream stream 和 consumer 创建应在应用启动时完成 | 运行时创建失败 → 返回 ErrStreamNotFound 或 ErrStreamExists（配置冲突） |
| BR-008 | 错误消息不包含消息内容（防泄露敏感数据） | 日志/错误含 payload → CI Gate secret scan 或 redaction check 阻断 |
| BR-009 | Subscription 必须在 Close/Drain 时正确释放资源 | 资源泄漏 → go test -race 检测；Drain 超时返回 ErrDrainTimeout |

---

## 8. 接口契约

公开 API 命名以 `goal.md` 的 1.0 逻辑接口基线为准：`NatsPubSubClient`、`NatsRequestClient`、`JetStreamClientX`、`NatsMessageEnvelope` 和 `SubjectBuilder`。实现可以保留内部适配器，但 Public API 不再暴露泛化的 `Client`/`JetStream` 命名作为 1.0 稳定契约。

Implementation repair note (2026-06-13): `/home/natsx/pkg/natsx` exposes the concrete repair APIs (`Client`, `Envelope`, `SubjectBuilder`, `JetStreamClient`) and contract-adjacent concrete types used by the repair slice. The historical interface names in this SPEC remain target-contract names; they are not claimed as exported API shims. Final interface factories remain governed by this contract.

```go
type NatsPubSubClient interface {
    Publish(ctx context.Context, subject string, msg NatsMessageEnvelope) (PublishResult, error)
    Subscribe(ctx context.Context, subject string, handler NatsMessageHandler, opts ...SubscribeOption) (Subscription, error)
}

type NatsRequestClient interface {
    Request(ctx context.Context, subject string, msg NatsMessageEnvelope, timeout time.Duration) (NatsMessageEnvelope, error)
    Reply(ctx context.Context, subject string, handler NatsMessageHandler) (Subscription, error)
}

type JetStreamClientX interface {
    Publish(ctx context.Context, stream string, subject string, msg NatsMessageEnvelope) (*PublishAck, error)
    Consume(ctx context.Context, stream string, consumer string, handler NatsMessageHandler) (ConsumerHandle, error)
    AddStream(ctx context.Context, cfg *StreamConfig) error
    AddConsumer(ctx context.Context, stream string, cfg *ConsumerConfig) error
}

type NatsMessageEnvelope struct {
    EventID       string
    MessageID     string
    SchemaVersion string
    TraceID       string
    Subject       string
    Headers       map[string][]string
    Payload       []byte
}

type SubjectBuilder interface {
    Build(domain, resource, action string, version int) (string, error)
    Parse(subject string) (SubjectParts, error)
}
```

Header / Trace 传播要求：`traceId`、`messageId`、`schemaVersion` 必须在 `NatsMessageEnvelope` 与 NATS Header 间双向映射；已有上游 Header 不得被无故丢弃，冲突字段以 Envelope 显式字段为准并记录诊断事件。

### 8.1 Option 模式

```go
type Option func(*config)

func WithServers(servers []string) Option
func WithClientName(name string) Option
func WithCredentials(path string) Option
func WithReconnectWait(d time.Duration) Option
func WithMaxReconnects(n int) Option
func WithJetStreamEnabled(enabled bool) Option
func WithCodec(codec Codec) Option
```

### 8.2 用法示例

```go
subjects := natsx.NewSubjectBuilder()
subject, _ := subjects.Build("market", "ticker", "updated", 1)

pubsub := natsx.NewPubSubClient(cfg)
msg := natsx.NatsMessageEnvelope{
    Subject:       subject,
    MessageID:     uuid.NewString(),
    TraceID:       traceIDFromContext(ctx),
    SchemaVersion: "ticker.v1",
    Headers:       map[string][]string{"source": []string{"market-data"}},
    Payload:       tickerJSON,
}

pubsub.Publish(ctx, subject, msg)

sub, _ := pubsub.Subscribe(ctx, "market.ticker.*.v1", func(ctx context.Context, msg natsx.NatsMessageEnvelope) error {
    return processTicker(msg.Payload)
})
defer sub.Unsubscribe()

requester := natsx.NewRequestClient(cfg)
resp, err := requester.Request(ctx, "config.service.get.v1", msg, 5*time.Second)

js := natsx.NewJetStreamClientX(cfg)
ack, _ := js.Publish(ctx, "ORDERS", "orders.created.v1", msg)
fmt.Printf("stored in stream %s, seq %d\n", ack.Stream, ack.Sequence)
```

---

## 9. 数据模型

### 9.1 公共错误

```go
var (
    ErrConnectionFailed  = errors.New("natsx: connection failed")
    ErrTimeout           = errors.New("natsx: request timeout")
    ErrNoResponders      = errors.New("natsx: no responders")
    ErrStreamExists      = errors.New("natsx: stream already exists with conflicting config")
    ErrConsumerExists    = errors.New("natsx: consumer already exists with conflicting config")
    ErrStreamNotFound    = errors.New("natsx: stream not found")
    ErrJetStreamDisabled = errors.New("natsx: jetstream is not enabled")
    ErrInvalidSubject    = errors.New("natsx: invalid subject")
    ErrDrainTimeout      = errors.New("natsx: drain timeout")
)
```

### 9.2 Codec 接口

```go
type Codec interface {
    Marshal(v any) ([]byte, error)
    Unmarshal(data []byte, v any) error
}
```

---

## 10. 配置模式

配置命名以 `foundationx.nats.*` 为稳定前缀，避免与其它消息模块冲突。环境变量使用 `FOUNDATIONX_NATS_*` 作为 canonical 输入，旧的 `NATS_*` 变量仅作为兼容回退；当两者同时存在时，`FOUNDATIONX_NATS_*` 必须优先生效。

```yaml
foundationx:
  nats:
    enabled: false
    servers: ["${FOUNDATIONX_NATS_SERVERS}"]
    client-name: "foundationx"
    credentials: ""
    request:
      timeout: 1s
    reconnect:
      wait: 2s
      max-attempts: -1
    ping:
      interval: 30s
      max-outstanding: 3
    drain-timeout: 30s
    serializer: json
    jetstream:
      enabled: false
      domain: ""
    health-check-interval: 10s
    tls:
      enabled: false
      ca-file: ""
```

Executable repair evidence (2026-06-13): `ConfigFromEnv` / `LoadConfigFromEnv` 支持以下后缀，canonical `FOUNDATIONX_NATS_*` 优先，legacy `NATS_*` fallback：`NAME`、`CLIENT_NAME`、`URL`、`SERVERS`、`TOKEN`、`USERNAME`、`PASSWORD`、`NKEY_SEED`、`CREDENTIALS_FILE`、`TIMEOUT`、`DRAIN_TIMEOUT`、`MAX_RECONNECTS`、`RECONNECT_WAIT`、`ENABLE_JETSTREAM`。配置解析错误不得打印 token、password、nkey seed 或 credentials file 内容。

---

## 11. 错误处理

| 错误                   | 调用方处理                                      |
| ---------------------- | ----------------------------------------------- |
| `ErrConnectionFailed`  | 检查 NATS 地址和网络，确认 NATS 服务运行中      |
| `ErrTimeout`           | 检查 subject 是否有 responder，考虑增加 timeout |
| `ErrNoResponders`      | 确认 responder 服务已启动并订阅了对应 subject   |
| `ErrStreamExists`      | 使用兼容配置或删除后重建                        |
| `ErrConsumerExists`    | 使用兼容配置或删除后重建                        |
| `ErrStreamNotFound`    | 先调用 AddStream 创建 stream                    |
| `ErrJetStreamDisabled` | 在配置中启用 JetStream                          |
| `ErrInvalidSubject`    | 检查 subject 格式（NATS subject 语法规则）      |
| `ErrDrainTimeout`      | 增加 drain_timeout 或检查 handler 是否阻塞      |

**错误消息格式：** `"natsx: <operation>: <detail>"`
**错误包装：** 使用 `%w` 保留底层错误链

---

## 12. 边界情况

| 场景 | 预期行为 |
|------|----------|
| NATS 不可达时 Publish | 返回 ErrConnectionFailed |
| 连接断开后自动重连 | 按 reconnect_wait 策略重连，重连期间消息丢失（Core NATS） |
| JetStream 连接断开后重连 | 重连后自动恢复消费，不丢失消息 |
| Subscribe 后连接断开 | 重连后自动恢复订阅（Core NATS） |
| Request 无 responder | 超时后返回 ErrNoResponders |
| handler panic | 被 catch，记录日志，不影响其他订阅 |
| Drain 超时 | 返回 ErrDrainTimeout |
| AddStream 重复调用且配置兼容 | 返回 nil（幂等） |
| AddStream 重复调用且配置冲突 | 返回 ErrStreamExists |
| AddConsumer 重复调用且配置兼容 | 返回 nil（幂等） |
| AddConsumer 重复调用且配置冲突 | 返回 ErrConsumerExists |
| JetStream disabled 时调用 JetStream 方法 | 返回 ErrJetStreamDisabled |
| Publish 空 subject | 返回 ErrInvalidSubject |

---

## 13. 目录结构

```text
natsx/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go
├── natsx.go                    # NatsPubSubClient / NatsRequestClient / JetStreamClientX 工厂
├── client.go                   # Core NATS 发布订阅与 Request 实现
├── jetstream.go                # JetStreamClientX 实现
├── subscription.go             # Subscription 接口实现
├── health.go                   # HealthStatus
├── options.go                  # Option 模式
├── errors.go                   # 公共错误变量
├── codec.go                    # Codec 接口及默认 JSON codec
├── msg.go                      # NatsMessageEnvelope 结构体
├── internal/
│   ├── codec/                  # 内部序列化工具
│   └── reconnect/              # 重连策略
├── testdata/
│   └── nats-server.conf        # 测试用 NATS 配置
├── example_test.go
├── benchmark_test.go
└── integration_test.go         # //go:build integration
```

---

## 14. 依赖

### 14.1 go.mod

```text
module github.com/ZoneCNH/natsx

go 1.23
```

### 14.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| stdlib | 所有业务域实现 |
| kernel（L0 原语） | 所有 L2.5 领域共享层 |
| configx（配置结构/绑定，natsx 不直接解析配置源） | kafkax / redisx / postgresx / taosx / ossx / clickhousex 等同层 L2 模块 |
| observex（interface-only） | x.go 应用层、策略层和运行时 |
| resiliencx（重试/退避策略，可选） | 隐式全局客户端和隐藏配置源 |
| NATS 客户端库（nats.go） | |

---

## 15. 测试

### 15.1 单元测试

| 测试场景 | 验证点 |
|----------|--------|
| Publish 成功 | 消息正确发布 |
| Subscribe 成功 | 注册订阅并收到消息 |
| Subscribe Unsubscribe | 取消后不再接收消息 |
| Subscribe Drain | 处理完已接收消息后关闭 |
| Request 成功 | 收到响应 |
| Request 超时 | 返回 ErrTimeout |
| JetStream Publish | 消息持久化 |
| JetStream Subscribe | 消费持久化消息 |
| AddStream 幂等 | 重复调用且配置兼容返回 nil |
| AddStream 冲突 | 返回 ErrStreamExists |
| AddConsumer 成功 | 创建 consumer |
| AddConsumer 幂等 | 重复调用且配置兼容返回 nil |
| AddConsumer 冲突 | 返回 ErrConsumerExists |
| Health 检查 | NATS 可用/不可用正确反映 |
| 自动重连 | 断开后自动重连 |
| Codec 序列化/反序列化 | JSON / msgpack 正确 |
| 并发安全 | -race 测试通过 |

### 15.2 Given/When/Then 用例

**TC-001: Core NATS Pub/Sub**
Given 连接正常
When Publish("subject", data)
Then Subscribe 的 handler 收到该消息

**TC-002: Request-Reply**
Given responder 订阅了 "config.get"
When Request("config.get", key, 5s)
Then 收到 responder 的响应

**TC-003: JetStream 持久化**
Given stream "ORDERS" 已创建
When JetStreamClientX.Publish("orders.new", msg)
Then JetStreamClientX.Subscribe 收到该消息
And 重启后仍能消费该消息

**TC-004: 自动重连**
Given NATS 连接正常
When NATS 短暂不可用后恢复
Then 自动重连成功，后续操作正常

**TC-005: Health 检查**
Given NATS 连接正常
When 调用 Health
Then 返回 healthy；连接断开时返回 unhealthy

**TC-011: Secret Redaction**
Given NATS 配置、错误或审计证据包含敏感字段
When natsx 输出日志、错误或发布证据
Then 输出 MUST NOT 包含 secret/token/password 明文

### 15.3 Benchmark

| 场景                        | 目标   |
| --------------------------- | ------ |
| 单条 Core NATS 发布         | < 1ms  |
| Request-Reply               | < 5ms  |
| JetStream 单条发布          | < 2ms  |
| JetStream 单条消费          | < 2ms  |
| 序列化/反序列化（1KB JSON） | < 10μs |

### 15.4 集成测试

| 场景               | 验证点                                     |
| ------------------ | ------------------------------------------ |
| 完整 Pub/Sub 链    | Publish → Subscribe handler 收到           |
| Request-Reply 链   | Request → Responder → 响应                 |
| JetStream 持久化链 | AddStream → Publish → Subscribe → 消费成功 |
| 自动重连           | 断开后重连并恢复订阅                       |
| Drain 订阅         | Drain 后正确释放资源                       |

---

## 16. 性能预算

| 操作                  | 目标    | 测量方式       |
| --------------------- | ------- | -------------- |
| 单条 Core NATS 发布   | < 1ms   | benchmark test |
| Request-Reply         | < 5ms   | benchmark test |
| JetStream 单条发布    | < 2ms   | benchmark test |
| JetStream 单条消费    | < 2ms   | benchmark test |
| 常驻内存              | < 5MB   | profiling      |
| 订阅 handler 调度延迟 | < 100μs | benchmark test |

Executable repair evidence (2026-06-13): embedded CI assertions now enforce generous smoke SLOs in `pkg/natsx/embedded_nats_test.go` (`Core Request <= 1500ms`, `JetStream Publish <= 2s`, `JetStream Fetch <= 4s`) and assert handler latency metric emission. These thresholds are CI stability guards, not replacements for the production benchmark targets above.

---

## 17. 可观测性

| 类型 | 名称 | 说明 |
|------|------|------|
| metric | `foundationx_nats_publish_total` | counter，按 subject/status 统计发布次数 |
| metric | `foundationx_nats_publish_duration_ms` | timer，发布耗时 |
| metric | `foundationx_nats_request_total` | counter，按 subject/status 统计请求次数 |
| metric | `foundationx_nats_request_duration_ms` | timer，Request-Reply 耗时 |
| metric | `foundationx_nats_consume_total` | counter，按 subject/consumer/status 统计消费次数 |
| metric | `foundationx_nats_redelivery_total` | counter，按 stream/consumer 统计重投递次数 |
| metric | `foundationx_nats_connection_state` | gauge，按 server/state 暴露连接状态 |
| log | `natsx.connected` | info，连接成功 |
| log | `natsx.disconnected` | warn，连接断开 |
| log | `natsx.reconnecting` | info，正在重连 |
| log | `natsx.reconnected` | info，重连成功 |
| log | `natsx.handler.panic` | error，handler panic 详情 |

Executable repair evidence (2026-06-13): `/home/natsx` commit `393d148` records canonical `foundationx_nats_*` metrics for client lifecycle, health, Core NATS publish/request/subscribe outcomes, JetStream outcomes, reconnects, and disconnects. Legacy `natsx_*` metric names are not part of the 1.0 contract. Secret-safety tests assert config/env validation errors and live-test evidence do not print payloads, credentials, tokens, or credential-bearing endpoints.

---

## 18. 安全

| 要求                   | 实现方式                            |
| ---------------------- | ----------------------------------- |
| 凭证不硬编码           | 通过凭证文件或环境变量注入          |
| TLS 加密传输           | 通过配置启用 TLS                    |
| 凭证不写日志           | 日志中对凭证路径脱敏                |
| 错误消息不泄露消息内容 | 错误消息只包含 subject，不包含 data |

Production TLS evidence is a release-blocking governance artifact, not a local-dev substitute. The repair-slice live integration may use redacted local/dev credentials to prove secret-safe loading, but release promotion requires an archived production TLS packet covering authorized endpoint provenance, good-CA success, bad-CA failure, mTLS evidence when applicable, SLO threshold results, secret-safe logs, artifact hashes, and release-governance/SRE signoff. The current required packet is recorded in `release/trust/foundation-maturity-evidence-matrix-20260615.md#blk-002-natsx-production-tls-closure-packet`; until that packet exists, `BLK-002` remains open.

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

### 19.2 natsx 专属 Gate

| Gate | 命令 | 阻塞条件 |
| ---- | ---- | -------- |
| package tests | `GOWORK=off go test ./pkg/natsx -count=1` | 任何测试失败 |
| vet | `GOWORK=off go vet ./pkg/natsx` | 任何 vet 错误 |
| live gate default | `GOWORK=off go test ./pkg/natsx -run TestLiveNATSIntegration -count=1` | gate unset 时应 skip/pass |
| live local integration | `NATSX_LIVE_INTEGRATION=1 FOUNDATIONX_NATS_URL=<redacted-local-or-dev-url> FOUNDATIONX_NATS_USERNAME=<redacted> FOUNDATIONX_NATS_PASSWORD=<redacted> GOWORK=off go test ./pkg/natsx -run TestLiveNATSIntegration -count=1 -v` | 仅允许显式授权的 dev/test 端点；凭据来自授权的 local/dev NATS config，测试输出不得打印凭据 |
| production TLS closure packet | `NATSX_LIVE_INTEGRATION=1 FOUNDATIONX_NATS_URL=<redacted-production-tls-url> FOUNDATIONX_NATS_CA_FILE=<authorized-ca-file> GOWORK=off go test ./pkg/natsx -run TestLiveNATSIntegration -count=1 -v` plus archived TLS profile/SLO/signoff evidence | 仅允许授权生产环境执行；必须归档 good CA、bad CA、mTLS（如适用）、SLO 阈值、脱敏日志、artifact hashes、SRE/release-governance signoff；缺失时 `BLK-002` 不得关闭 |

---

## 20. 升级兼容性

| 变更类型 | 版本升级 |
|----------|----------|
| NatsPubSubClient / NatsRequestClient 接口新增方法 | **minor**（实现需跟上） |
| NatsPubSubClient / NatsRequestClient 接口删除/修改方法 | **major** |
| JetStreamClientX 接口新增方法 | **minor**（实现需跟上） |
| JetStreamClientX 接口删除/修改方法 | **major** |
| Subscription 接口变更 | **major** |
| NatsMessageEnvelope 结构体变更 | **major** |
| StreamConfig / ConsumerConfig 变更 | **minor**（新增字段带默认值） |
| Option 新增字段 | minor（带默认值） |

---

## 21. 发布 DoD

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
- [ ] Production TLS closure packet archived and linked from release trust evidence before closing `BLK-002`

---

## 22. 待解决问题

- 是否需要支持 NATS Leaf Node 连接（跨集群通信）？
- JetStream 是否需要支持 KV Store（NATS 内置 KV 抽象）？
- 是否需要支持 Object Store（NATS 内置对象存储）？
- Core NATS 消息丢失是否可接受（at-most-once），还是需要全部走 JetStream？
- 是否需要支持消息压缩（per-message gzip/snappy）？


## 23. 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-13 | v1.0.0-draft | 对齐 natsx 全分修复证据：canonical metrics、secret-safe error/live evidence、redacted auth live test 与矩阵 20/20 repair-slice score | Codex |
| 2026-06-12 | v1.0.0-draft | 记录 natsx 生命周期/投递修复基线与剩余发布阻塞项 | Codex |
| 2026-06-07 | v1.0.0 | 初始版本 | ZoneCNH |