# TASK-BINANCE-SERVER-013 taosx Storage

> 版本：v2.0.0

## Objective

利用 taosx 将规范化行情事件持久化到 TDengine，作为 Binance 模块的**主时序存储**，服务于 Gin REST API 的历史行情查询。

## Scope

```text
internal/server/storage/timeseries/
  timeseries.go       ← TimeSeriesStore 主实现
  timeseries_test.go
```

## 数据模型（TDengine 超表）

```sql
-- 行情主表（超表）
CREATE STABLE IF NOT EXISTS binance_tick (
    ts          TIMESTAMP,           -- exchange_time（毫秒精度）
    price       DOUBLE,
    quantity    DOUBLE,
    side        BINARY(4),           -- 'buy' / 'sell' / 'both'
    server_time TIMESTAMP
) TAGS (
    symbol      BINARY(32),
    product_line BINARY(16),         -- 'spot' / 'um_perp' / 'cm_perp' / 'options'
    event_type  BINARY(16)           -- 'tick' / 'trade' / 'bar' / 'depth' / 'funding_rate' / 'mark_price'
);

-- 订单簿快照（超表）
CREATE STABLE IF NOT EXISTS binance_depth (
    ts          TIMESTAMP,
    side        BINARY(4),
    price       DOUBLE,
    quantity    DOUBLE,
    last_update_id BIGINT
) TAGS (
    symbol      BINARY(32),
    product_line BINARY(16)
);
```

## 接口设计

```go
// internal/server/storage/timeseries/timeseries.go
package timeseries

type TimeSeriesStore struct {
    db taosx.Client
}

// WriteTick 将单条 MarketFactEnvelope 写入对应的子表。
// 子表名规则：{event_type}_{md5(symbol+product_line)[:8]}
func (s *TimeSeriesStore) WriteTick(ctx context.Context, env *domainmarket.MarketFactEnvelope) error {
    child := s.childTable(env)
    return s.db.WriteWithAutoCreate(ctx, "binance_market_ticks", child, env.ToTDRow(), env.Tags())
}

// WriteBatch 批量写入，提升写入吞吐。
func (s *TimeSeriesStore) WriteBatch(ctx context.Context, envs []*domainmarket.MarketFactEnvelope) error {
    // taosx.Client.WriteBatch 支持批量参数绑定
    rows := make([]taosx.Row, len(envs))
    for i, e := range envs { rows[i] = e.ToTDRow() }
    return s.db.WriteBatch(ctx, "binance_market_ticks", rows)
}

// QueryRange 按时间范围和 symbol 查询 tick 数据，供 Gin API 调用。
func (s *TimeSeriesStore) QueryRange(ctx context.Context, params QueryParams) ([]*domainmarket.MarketFactEnvelope, error)
```

## Functional Requirements

**FR-TS-001**: 写入时自动创建子表（AutoCreate），不需要预先建表。

**FR-TS-002**: `WriteBatch` 合并多条消息为一次网络往返（批量参数绑定），目标吞吐 ≥10万 TPS。

**FR-TS-003**: `QueryRange` 支持按 (symbol, product_line, start, end) 过滤，最大返回 10000 条。

**FR-TS-004**: taosx 不可达时返回 error，consumer 收到 error 后 NakWithDelay，不丢失消息。

## Acceptance Criteria

| AC | 验证方式 |
|----|---------|
| WriteTick 写入正确超表 | mock 验证 WriteWithAutoCreate 参数 |
| WriteBatch 合并写入 | mock 验证 WriteBatch 被调用（非循环 WriteTick）|
| QueryRange 时间过滤 | mock 验证 SQL WHERE 包含 start/end 参数 |
| 不可达返回 error | mock 注入连接失败，验证 error 传播 |

## Dependencies

| 依赖 | 版本 | 用途 |
|------|------|------|
| `github.com/ZoneCNH/taosx` | v1.0.0 | TDengine 写入/查询 |
| `github.com/ZoneCNH/domain_market` | v1.1.0 | MarketFactEnvelope.ToTDRow() |

## Non-scope

- 不做冷热分层（ossx 负责归档超过 90 天的数据，见 SERVER-016）
- 不做聚合计算（factor_engine 负责）
