# TASK-BCFG-003 Type Conversions

## Objective

实现 `ServerConfig()` 和 `FeedConfig()` 转换方法，将统一 Config 映射为下游类型。

## Scope

- `ServerConfig()`: Config → binance.ServerConfig (5 字段)
- `FeedConfig()`: Config → binancex.FeedConfig (9 字段)
- 字段一一映射无遗漏

## Covers

- FR-BCFG-004 (ServerConfig conversion)
- FR-BCFG-005 (FeedConfig conversion)

## Deliverables

- `ServerConfig()`: StaleThreshold/FutureTolerance/IdempotencyTTL/MaxStreams/DrainTimeout
- `FeedConfig()`: WSEndpoint/ReconnectBackoff/MaxReconnectBackoff/MaxReconnectAttempts/ReadTimeout/PingInterval/EventBufferSize + 默认 WriteTimeout/ErrorBufferSize

## Acceptance Criteria

1. ServerConfig 5 字段完整映射
2. FeedConfig 9 字段完整映射（含 WriteTimeout/ErrorBufferSize 默认值）
3. 转换后字段值与 Config 源字段一致
4. 双向一致性: Config → ServerConfig → 字段值 = Config 对应字段

## Dependencies

- TASK-BCFG-001 (Config loading)
- `runtime-patches/binance` (ServerConfig)
- `runtime-patches/binancex` (FeedConfig)
