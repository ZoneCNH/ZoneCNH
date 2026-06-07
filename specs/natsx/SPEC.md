# natsx 完整规格

> 基座 · 存储扩展。NATS 内部通信封装。当前 80% 完成。

最后更新：2026-06-07

---

## 1. 定位

`natsx` 封装 NATS 客户端，提供统一的发布/订阅、请求/响应、JetStream 和可观测集成。

### 核心职责

- Publish / Subscribe
- Request / Reply
- JetStream（持久化消息、消费者组）
- 统一序列化/反序列化
- 健康检查
- 可观测集成（metrics、tracing、logging）
- 与 kernel 生命周期集成

### 明确不做

- 不做 NATS 集群管理
- 不做消息路由（业务层决定 subject）
- 不做消息去重（应用层处理）

---

## 2. 接口契约

```go
type Client interface {
    Publish(ctx context.Context, subject string, data []byte) error
    Subscribe(ctx context.Context, subject string, handler MsgHandler) (Subscription, error)
    Request(ctx context.Context, subject string, data []byte, timeout time.Duration) ([]byte, error)
    JetStream() JetStream
    Health() HealthStatus
    Close() error
}

type MsgHandler func(msg *Msg)

type Subscription interface {
    Unsubscribe() error
    Drain() error
}

type JetStream interface {
    Publish(ctx context.Context, subject string, data []byte, opts ...PublishOpt) (*PublishAck, error)
    Subscribe(ctx context.Context, subject string, handler MsgHandler, opts ...SubOpt) (Subscription, error)
    AddStream(ctx context.Context, cfg *StreamConfig) error
    AddConsumer(ctx context.Context, stream string, cfg *ConsumerConfig) error
}

type Msg struct {
    Subject   string
    Reply     string
    Data      []byte
    Headers   map[string][]byte
    Timestamp time.Time
}
```

---

## 3. 目录结构

```
natsx/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go
├── natsx.go                    # Client 工厂
├── client.go
├── jetstream.go
├── subscription.go
├── health.go
├── options.go
├── errors.go
├── internal/
│   ├── codec/
│   └── reconnect/
├── testdata/
├── example_test.go
├── benchmark_test.go
└── integration_test.go
```

---

## 4. 依赖

| 可以依赖 | 禁止依赖 |
|----------|----------|
| kernel（L0 原语） | configx |
| observex（interface-only） | 所有业务域 |
| NATS 客户端库 | |
| stdlib | |

---

## 5. CI Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 测试失败 |
| 覆盖率 | ≥ 80% | 覆盖率不足 |
| 集成测试 | `go test -tags=integration ./...` | NATS 不可达时 skip |

---

## 6. 测试矩阵

| 测试场景 | 验证点 |
|----------|--------|
| Publish/Subscribe | 消息正确投递 |
| Request/Reply | 请求-响应匹配 |
| JetStream 持久化 | 消息持久化和消费 |
| 重连 | 断开后自动重连 |
| 健康检查 | 连接状态正确反映 |

---

## 7. 性能预算

| 操作 | 目标 |
|------|------|
| 单条发布 | < 1ms |
| 请求-响应 | < 5ms |

---

## 8. 可观测输出

| 类型 | 名称 | 说明 |
|------|------|------|
| metric | `natsx.publish.duration` | histogram，发布耗时 |
| metric | `natsx.publish.errors` | counter，发布失败次数 |
| metric | `natsx.subscribe.messages` | counter，消费消息数 |
| log | `natsx.connected` | info，连接成功 |
| log | `natsx.reconnected` | warn，重连成功 |

---

## 9. 发布 DoD

- [ ] 所有公共接口有 godoc 注释
- [ ] 测试覆盖率 ≥ 80%
- [ ] 集成测试可选跳过（无 NATS 时）
- [ ] CHANGELOG.md 已更新
