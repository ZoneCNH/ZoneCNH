# TASK-BINANCE-SERVER-010 natsx Consumer

> 版本：v2.0.0
> 替换：~~TASK-BINANCE-SERVER-001-grpc-ingest-server.md~~（已归档）

## Objective

实现 natsx JetStream Consumer，作为 `binance-server` 的唯一数据入口，通过**网络**订阅 client 发布的行情事件，触发后续处理管线。

## 分布式约束

- consumer 只做网络订阅，不感知 client 进程位置
- ManualAck：消息处理完成后（redisx + taosx + postgresx + kafkax handoff 全部成功）才 Ack
- 禁止导入 `internal/client/*` 或 `internal/cs`

## Scope

```text
internal/server/consumer/
  consumer.go        ← MarketConsumer 主实现
  consumer_test.go   ← mock JetStream 单测
```

## 接口设计

```go
// internal/server/consumer/consumer.go
package consumer

type MarketConsumer struct {
    js      nats.JetStreamContext
    handler IngestHandler   // processor.Pipeline
    cfg     ConsumerConfig
}

type ConsumerConfig struct {
    Stream   string        // "BINANCE_MARKET"
    Durable  string        // "binance-server"
    AckWait  time.Duration // 30s
    MaxDeliver int         // 5
}

// Start 启动 durable consumer，阻塞直到 ctx 取消。
func (c *MarketConsumer) Start(ctx context.Context) error {
    sub, err := c.js.Subscribe("binance.market.>", c.dispatch,
        nats.Durable(c.cfg.Durable),
        nats.ManualAck(),
        nats.AckWait(c.cfg.AckWait),
        nats.MaxDeliver(c.cfg.MaxDeliver),
        nats.Context(ctx),
    )
    if err != nil { return err }
    <-ctx.Done()
    return sub.Unsubscribe()
}

func (c *MarketConsumer) dispatch(msg *nats.Msg) {
    var env domainmarket.MarketFactEnvelope
    if err := json.Unmarshal(msg.Data, &env); err != nil {
        msg.Nak()  // 解析失败，重投
        return
    }
    if err := c.handler.Handle(context.Background(), &env); err != nil {
        msg.NakWithDelay(5 * time.Second)  // 处理失败，延迟重投
        return
    }
    msg.Ack()  // 全链路写入完成后才 Ack
}
```

## Functional Requirements

**FR-CON-001**: durable consumer 绑定名称 `binance-server`，进程重启后从上次 Ack 位置继续消费。

**FR-CON-002**: ManualAck — 消息经过 validation + idempotency + redisx + taosx + postgresx + kafkax handoff 全部成功后才 Ack。

**FR-CON-003**: 处理失败时 NakWithDelay（延迟重投），失败计数达 MaxDeliver 后消息进入死信。

**FR-CON-004**: consumer 不持有任何 client 接口，不导入 `internal/client` 或 `internal/cs`。

## Acceptance Criteria

| AC | 验证方式 |
|----|---------|
| durable consumer 重启恢复 | mock 验证 Subscribe 使用 Durable option |
| Ack 在 Handle 成功后调用 | mock handler 成功 → 验证 msg.Ack 被调用 |
| Nak 在 Handle 失败后调用 | mock handler 返回 error → 验证 msg.NakWithDelay |
| 无 client 依赖 | `go list -deps ./internal/server/...` 不含 internal/client |

## Non-scope

- 不做消息解析逻辑（由 processor 负责）
- 不做存储（由 storage/ 负责）
- 不做 API（由 api/ 负责）
