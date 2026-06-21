# TASK-BINANCE-SERVER-014 kafkax Dispatch

> 版本：v2.0.0

## Objective

利用 kafkax 将处理后的规范化行情事件向下游**广播**，供 factor_engine、risk_engine 等其他域异步消费，实现跨域解耦。

## 分布式约束

- kafkax 是从 binance server **出发**的单向广播，不是 client → server 的通道
- factor_engine 等消费者通过 Kafka consumer group 自行拉取，不感知 binance server 进程

## Scope

```text
internal/server/dispatch/
  dispatcher.go      ← MarketDispatcher 主实现
  dispatcher_test.go
```

## Topic 规范

| Topic | Key | 用途 |
|-------|-----|------|
| `binance.market.spot.tick` | symbol | 现货成交 |
| `binance.market.spot.depth` | symbol | 现货深度 |
| `binance.market.futures_usdt.tick` | symbol | U 本位合约成交 |
| `binance.market.futures_usdt.depth` | symbol | U 本位合约深度 |
| `binance.market.kline.1m` | symbol | 1 分钟 K 线 |

格式规律：`binance.market.{product_line}.{event_type}`（与 natsx subject 一致）

## 接口设计

```go
// internal/server/dispatch/dispatcher.go
package dispatch

type MarketDispatcher struct {
    producer kafkax.Producer
}

// Dispatch 将 envelope 发布到对应 topic，使用 symbol 作为 partition key。
// 使用 Kafka producer 异步发送（无需等待消费者 Ack）。
func (d *MarketDispatcher) Dispatch(ctx context.Context, env *domainmarket.MarketFactEnvelope) error {
    topic := fmt.Sprintf("binance.market.%s.%s",
        strings.ToLower(string(env.ProductLine)),
        strings.ToLower(string(env.EventType)),
    )
    msg := &kafkax.Message{
        Topic: topic,
        Key:   []byte(env.Symbol),
        Value: mustMarshal(env),
    }
    return d.producer.Send(ctx, msg)
}
```

## Functional Requirements

**FR-DISP-001**: topic 名称格式与 natsx subject 保持一致：`binance.market.{product_line}.{event_type}`。

**FR-DISP-002**: 使用 symbol 作为 Kafka partition key，相同 symbol 消息保证有序到达同一 partition。

**FR-DISP-003**: Kafka producer 异步发送（不等待消费者 offset commit），`Dispatch` 只等待 broker ACK。

**FR-DISP-004**: Kafka 不可达时返回 error，由 processor pipeline 决定是否降级（仍写入 taosx，仅告警）。

## Acceptance Criteria

| AC | 验证方式 |
|----|---------|
| topic 名称正确 | mock 验证 `topic = binance.market.spot.tick` |
| partition key = symbol | mock 验证 `Key = []byte(env.Symbol)` |
| Kafka 不可达返回 error | mock 注入错误，验证 error 传播 |
| 异步发送（不阻塞消费端）| 单测验证 Dispatch 不等待消费者 offset |

## Dependencies

| 依赖 | 版本 | 用途 |
|------|------|------|
| `github.com/ZoneCNH/kafkax` | v1.0.0 | Kafka producer |
| `github.com/ZoneCNH/domain_market` | v1.1.0 | MarketFactEnvelope |

## Non-scope

- 不做消费者实现（factor_engine 等各自负责）
- 不做消息压缩配置（kafkax 默认 snappy）
- 不做幂等发布（Kafka 幂等由 kafkax producer 配置 enable.idempotence=true 完成）
