# TASK-BINANCE-CLIENT-014 natsx Publisher

> 版本：v2.0.0
> 替换：~~TASK-BINANCE-CLIENT-008-grpc-sender.md~~（已归档）

## Objective

实现 natsx JetStream 发布器，将 client 采集到的规范化行情事件通过**网络**发布到 NATS JetStream Stream，完成 client 侧的唯一输出职责。

## 分布式约束

- publisher 只做 `natsx.Publish(subject, payload)` — 网络调用，不感知 server 进程
- 不持有任何 server 接口或 server 内部类型
- `internal/cs` 包**禁止导入**

## Scope

```text
internal/client/publisher/
  publisher.go          ← MarketPublisher 主实现
  publisher_test.go     ← mock JetStream 单测
```

## 接口设计

```go
// internal/client/publisher/publisher.go
package publisher

type MarketPublisher struct {
    js      nats.JetStreamContext
    stream  string // "BINANCE_MARKET"
}

// Publish 将 envelope 序列化为 JSON 并同步发布到 JetStream。
// subject 格式：binance.market.{product_line}.{event_type}
// 返回前等待 JetStream PubAck（消息已持久化到 NATS）。
func (p *MarketPublisher) Publish(ctx context.Context, env *domainmarket.MarketFactEnvelope) error {
    subj := fmt.Sprintf("binance.market.%s.%s",
        strings.ToLower(string(env.ProductLine)),
        strings.ToLower(string(env.EventType)),
    )
    data, err := json.Marshal(env)
    if err != nil {
        return fmt.Errorf("publisher: marshal: %w", err)
    }
    _, err = p.js.Publish(subj, data, nats.Context(ctx))
    return err
}
```

## Functional Requirements

**FR-PUB-001**: WHEN mapper 输出 `MarketFactEnvelope` THEN publisher 序列化并同步发布到 JetStream，等待 PubAck 返回。

**FR-PUB-002**: WHEN JetStream PubAck 返回成功 THEN publisher 返回 nil，调用方不需要重试。

**FR-PUB-003**: WHEN JetStream 不可达或超时 THEN publisher 返回 error，由调用方决定重试策略（指数退避）。

**FR-PUB-004**: subject 格式必须为 `binance.market.{product_line}.{event_type}`，product_line 和 event_type 均小写。

**FR-PUB-005**: publisher 不持有 server 地址、server 接口或 `internal/cs` 包。

## Acceptance Criteria

| AC | 验证方式 |
|----|---------|
| PubAck 同步等待 | mock JetStream 注入，验证 Publish 在 ACK 前阻塞 |
| subject 格式正确 | 单测验证 `spot + tick → binance.market.spot.tick` |
| JetStream 不可达时返回 error | mock 注入 timeout，验证返回 err 且不 panic |
| 无 server 依赖 | `go list -deps ./internal/client/...` 不含 internal/server |
| 无 cs 包导入 | `grep -r '"github.com/ZoneCNH/binance/internal/cs"' internal/client/` 无结果 |

## Dependencies

| 依赖 | 版本 | 用途 |
|------|------|------|
| `github.com/ZoneCNH/natsx` | v1.0.0 | JetStream context |
| `github.com/ZoneCNH/domain_market` | v1.1.0 | MarketFactEnvelope |
| `encoding/json` | stdlib | 序列化 |

## Non-scope

- 不做 spool 或本地持久化（JetStream 替代）
- 不做 checkpoint 管理
- 不做 server 端幂等
- 不做批量发布（每条 envelope 独立 Publish）
