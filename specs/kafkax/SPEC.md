# kafkax 完整规格

> 基座 · 存储扩展。Kafka 客户端封装。当前仅骨架。

最后更新：2026-06-07

---

## 1. 定位

`kafkax` 封装 Kafka 客户端，提供统一的生产者、消费者、序列化和可观测集成。

### 核心职责

- Producer（同步/异步发送）
- Consumer（消费组、offset 管理）
- 统一序列化/反序列化
- 健康检查
- 可观测集成（metrics、tracing、logging）
- 与 kernel 生命周期集成

### 明确不做

- 不做 Kafka 集群管理
- 不做消息路由（业务层决定 topic）
- 不做 exactly-once 语义（Kafka 原生支持）

---

## 2. 接口契约

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
```

---

## 3. 目录结构

```
kafkax/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go
├── kafkax.go                   # Producer / Consumer 工厂
├── producer.go
├── consumer.go
├── health.go
├── options.go
├── errors.go
├── internal/
│   ├── codec/
│   └── retry/
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
| Kafka 客户端库 | |
| stdlib | |

---

## 5. CI Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 测试失败 |
| 覆盖率 | ≥ 80% | 覆盖率不足 |
| 集成测试 | `go test -tags=integration ./...` | Kafka 不可达时 skip |

---

## 6. 测试矩阵

| 测试场景 | 验证点 |
|----------|--------|
| Producer 发送 | 消息成功发送到 topic |
| Consumer 消费 | 正确消费并 commit |
| 批量发送 | SendBatch 原子性 |
| 连接失败 | Kafka 不可达 → 返回错误 |
| 健康检查 | metadata 请求成功/失败 |

---

## 7. 性能预算

| 操作 | 目标 |
|------|------|
| 单条发送 | < 5ms |
| 批量发送 100 条 | < 20ms |

---

## 8. 可观测输出

| 类型 | 名称 | 说明 |
|------|------|------|
| metric | `kafkax.produce.duration` | histogram，发送耗时 |
| metric | `kafkax.produce.errors` | counter，发送失败次数 |
| metric | `kafkax.consume.lag` | gauge，消费延迟 |
| log | `kafkax.connected` | info，连接成功 |

---

## 9. 发布 DoD

- [ ] 所有公共接口有 godoc 注释
- [ ] 测试覆盖率 ≥ 80%
- [ ] 集成测试可选跳过（无 Kafka 时）
- [ ] CHANGELOG.md 已更新
