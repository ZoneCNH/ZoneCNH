# TASK-ASM-003 NopMiddleware & Interface Compliance

## Objective

实现 `NopMiddleware` 透传中间件，含编译期接口合规断言。

## Scope

- `NopMiddleware`: 透传所有依赖不变
- 编译期断言：`var _ ValidatorMiddleware = (*NopMiddleware)(nil)`
- 同样断言 IdempotencyMiddleware 和 DispatchMiddleware

## Covers

- FR-ASM-005 (NopMiddleware)
- NFR-ASM-001 (compile-time interface compliance)

## Deliverables

- `NopMiddleware` 结构体 + Name() 方法
- `WrapValidator()`/`WrapIdempotency()`/`WrapDispatcher()` 透传实现
- 3 个 `var _` 编译期断言

## Acceptance Criteria

1. NopMiddleware.Name() → "nop"
2. WrapValidator(next) → next（不变）
3. WrapIdempotency(next) → next（不变）
4. WrapDispatcher(next) → next（不变）
5. `go build ./...` 编译通过（接口断言有效）
6. NopMiddleware 实现了全部 3 个 Middleware 接口

## Dependencies

- `runtime-patches/binance` (RequestValidator/IdempotencyStore/DownstreamDispatcher)
