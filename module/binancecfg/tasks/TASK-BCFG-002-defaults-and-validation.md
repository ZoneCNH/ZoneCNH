# TASK-BCFG-002 DefaultConfig & Validation

## Objective

实现 `DefaultConfig()` 生产安全默认值和 `Validate()` 配置校验。

## Scope

- `DefaultConfig()`: 返回保守生产默认值
- `Validate()`: 拒绝零值/负值关键参数，委托 `binancex.FeedConfig.Validate()`
- 默认 WS endpoint: `wss://stream.binance.com:9443/ws`

## Covers

- FR-BCFG-002 (DefaultConfig)
- FR-BCFG-003 (Validate)
- BR-BCFG-003 (reject zero/negative values)

## Deliverables

- `DefaultConfig()` 全部字段非零值
- `Validate()` 拒绝 MaxStreams <= 0, DrainTimeout <= 0, ShutdownTimeout <= 0
- `Validate()` 委托 `FeedConfig().Validate()`

## Acceptance Criteria

1. DefaultConfig 所有 duration 字段为正数
2. DefaultConfig WS endpoint 指向 Binance public stream
3. Validate(MaxStreams=0) → error 含 "MaxStreams"
4. Validate(DrainTimeout=0) → error 含 "DrainTimeout"
5. Validate(ShutdownTimeout=0) → error 含 "ShutdownTimeout"
6. Validate 委托 FeedConfig.Validate

## Dependencies

- TASK-BCFG-001 (Config loading)
- `runtime-patches/binancex` (FeedConfig.Validate)
