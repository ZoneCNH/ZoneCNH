# TASK-ASM-001 ServerDeps & Validation

## Objective

实现 `ServerDeps` 依赖集合和 `Validate()` 方法，确保所有必需依赖非 nil。

## Scope

- `ServerDeps`: 收集全部 5 个依赖字段
- `Validate()`: 检查 Feed/Validator/Idempotency/Dispatcher 非 nil
- 错误聚合：`errors.Join` 汇总所有 nil 依赖

## Covers

- FR-ASM-001 (ServerDeps)
- FR-ASM-002 (Validate)
- BR-ASM-003 (validation failure → wrapped error)

## Deliverables

- `ServerDeps` 结构体含 Feed/Validator/Idempotency/Dispatcher/Config
- `Validate()` 返回 errors.Join 聚合错误
- `assembly_test.go` 中 nil deps 测试

## Acceptance Criteria

1. ServerDeps 含全部 5 个字段
2. Validate(all non-nil) → nil
3. Validate(Feed=nil) → error 含 "Feed"
4. Validate(Validator=nil) → error 含 "Validator"
5. Validate(Idempotency=nil) → error 含 "Idempotency"
6. Validate(Dispatcher=nil) → error 含 "Dispatcher"
7. Validate(all nil) → error 含所有 4 个字段名

## Dependencies

- `runtime-patches/binance` (types)
- `runtime-patches/binancex` (MarketDataFeed)
