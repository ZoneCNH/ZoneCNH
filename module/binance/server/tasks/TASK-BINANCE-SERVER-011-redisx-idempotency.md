# TASK-BINANCE-SERVER-011 redisx Idempotency

> 版本：v2.0.0

## Objective

利用 redisx 实现消息幂等检查，防止 JetStream 重投消息（网络抖动/重启）导致数据重复写入 taosx 和 postgresx。

## Scope

```text
internal/server/storage/idempotency.go
internal/server/storage/idempotency_test.go
```

## Key 设计

```
key:   binance:idempotency:{hash}
hash:  sha256(product_line + exchange_time.UnixNano + event_type + symbol) → hex[:16]
value: "1"
TTL:   24h（JetStream Stream 保留 7d，24h 内重投可被拦截）
```

## 接口设计

```go
// internal/server/storage/idempotency.go
package storage

type IdempotencyChecker struct {
    rdb redisx.Client
}

// IsDuplicate 返回 true 表示已处理过，调用方应 Ack 并跳过。
// 首次调用时会设置 key + TTL。
func (ic *IdempotencyChecker) IsDuplicate(ctx context.Context, env *domainmarket.MarketFactEnvelope) (bool, error) {
    h := ic.hash(env)
    key := "binance:idempotency:" + h
    ok, err := ic.rdb.SetNX(ctx, key, "1", 24*time.Hour)
    if err != nil { return false, err }
    return !ok, nil  // SetNX 返回 false 表示 key 已存在 → duplicate
}

func (ic *IdempotencyChecker) hash(env *domainmarket.MarketFactEnvelope) string {
    raw := fmt.Sprintf("%s:%d:%s:%s",
        env.ProductLine, env.ExchangeTime.UnixNano(),
        env.EventType, env.Symbol,
    )
    sum := sha256.Sum256([]byte(raw))
    return hex.EncodeToString(sum[:])[:16]
}
```

## Functional Requirements

**FR-IDEM-001**: 相同 (product_line, exchange_time, event_type, symbol) 的消息第二次到达时，`IsDuplicate` 返回 true。

**FR-IDEM-002**: key 过期时间设为 24h，过期后相同消息视为新消息。

**FR-IDEM-003**: Redis 不可达时返回 error，调用方 NakWithDelay（不丢弃，也不重复写入）。

**FR-IDEM-004**: SetNX 原子语义 — 在分布式环境中防止并发写入重复。

## Acceptance Criteria

| AC | 验证方式 |
|----|---------|
| 第一次返回 false（新消息） | mock SetNX 返回 true → IsDuplicate false |
| 第二次返回 true（重复） | mock SetNX 返回 false → IsDuplicate true |
| Redis 不可达返回 error | mock SetNX 返回 err → 传播 error |
| TTL 24h | 验证 SetNX 参数含 24h |

## Dependencies

| 依赖 | 版本 | 用途 |
|------|------|------|
| `github.com/ZoneCNH/redisx` | v1.0.0 | SetNX + TTL |
| `crypto/sha256` + `encoding/hex` | stdlib | hash 生成 |
