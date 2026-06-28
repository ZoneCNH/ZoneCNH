# TASK-ASM-002 Assemble & Build

## Objective

实现 `Assemble()` 中间件装配和 `Build()` 一步构造方法。

## Scope

- `Assemble()`: 按序应用中间件链到各依赖，返回组装后 ServerDeps
- `Build()`: 装配 + constructor 一步完成
- nil middleware 安全跳过
- 中间件顺序保持

## Covers

- FR-ASM-003 (Assemble)
- FR-ASM-004 (Build)
- BR-ASM-001 (middleware order preservation)
- BR-ASM-002 (nil middleware skip)

## Deliverables

- `Assemble()` 实现：遍历 middlewares，按类型分发到 WrapValidator/WrapIdempotency/WrapDispatcher
- `Build()` 实现：委托 Assemble + constructor
- 中间件链应用顺序测试

## Acceptance Criteria

1. Assemble(all valid, no middleware) → ServerDeps 不变
2. Assemble with ValidatorMiddleware → validator 被装饰
3. Assemble with nil middleware → 安全跳过，deps 不变
4. Assemble with invalid deps → 返回 wrapped error
5. Build(deps, constructor) → 返回 *IngestServer
6. Build with invalid deps → 返回 error
7. 多个 middleware 按 slice 顺序应用（先注册先装饰）

## Dependencies

- TASK-ASM-001 (ServerDeps)
- `runtime-patches/binance` (IngestServer, NewServer)
