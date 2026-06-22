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
| `binance.spot.tick.v1` | symbol | 现货 Tick |
| `binance.spot.trade.v1` | symbol | 现货成交 |
| `binance.spot.bar.v1` | symbol | 现货 K 线 / bar |
| `binance.spot.depth.v1` | symbol | 现货深度 |
| `binance.spot.funding_rate.v1` | symbol | 现货资金费率 capability 事件 |
| `binance.spot.mark_price.v1` | symbol | 现货标记价格 capability 事件 |
| `binance.um_perp.tick.v1` | symbol | USDⓈ-M Tick |
| `binance.um_perp.trade.v1` | symbol | USDⓈ-M 成交 |
| `binance.um_perp.bar.v1` | symbol | USDⓈ-M K 线 / bar |
| `binance.um_perp.depth.v1` | symbol | USDⓈ-M 深度 |
| `binance.um_perp.funding_rate.v1` | symbol | USDⓈ-M 资金费率 |
| `binance.um_perp.mark_price.v1` | symbol | USDⓈ-M 标记价格 |
| `binance.cm_perp.tick.v1` | symbol | COIN-M Tick |
| `binance.cm_perp.trade.v1` | symbol | COIN-M 成交 |
| `binance.cm_perp.bar.v1` | symbol | COIN-M K 线 / bar |
| `binance.cm_perp.depth.v1` | symbol | COIN-M 深度 |
| `binance.cm_perp.funding_rate.v1` | symbol | COIN-M 资金费率 |
| `binance.cm_perp.mark_price.v1` | symbol | COIN-M 标记价格 |
| `binance.options.tick.v1` | symbol | Options Tick |
| `binance.options.trade.v1` | symbol | Options 成交 |
| `binance.options.bar.v1` | symbol | Options K 线 / bar |
| `binance.options.depth.v1` | symbol | Options 深度 |
| `binance.options.funding_rate.v1` | symbol | Options 资金费率 capability 事件 |
| `binance.options.mark_price.v1` | symbol | Options 标记价格 capability 事件 |

格式规律：`binance.{product_line}.{event_type}.v1`（Kafka topic 与 natsx subject 分离）

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
    topic := fmt.Sprintf("binance.%s.%s.v1",
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

**FR-DISP-001**: topic 名称格式使用 Kafka 合同：`binance.{product_line}.{event_type}.v1`。

**FR-DISP-002**: 使用 symbol 作为 Kafka partition key，相同 symbol 消息保证有序到达同一 partition。

**FR-DISP-003**: Kafka producer 异步发送（不等待消费者 offset commit），`Dispatch` 只等待 broker ACK。

**FR-DISP-004**: Kafka 不可达时返回 error；processor pipeline 可保留已完成的 taosx 写入，但未完成 kafkax handoff 前 consumer 不得 Ack。

## Acceptance Criteria

| AC | 验证方式 |
|----|---------|
| topic 名称正确 | mock 验证 `topic = binance.spot.tick.v1` |
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
