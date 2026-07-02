# assembly Goal

| 字段 | 值 |
| --- | --- |
| 模块 | `assembly` |
| 层级 | L3 中间件注入与装配层（binance ingest pipeline） |
| 仓库 | `github.com/ZoneCNH/runtime-patches/assembly` |
| 当前版本 | v0.1.0-patch |
| 目标版本 | v0.1.0-patch |
| 状态 | Patches 初始化 — 从 Go 源码反向提取，待 SPEC 创建 |
| 最后更新 | 2026-06-29 |

## 目标

`assembly` 为 binance ingest pipeline 提供中间件注入与依赖装配层。连接 binancex adapter 与 binance ingest server，将横切关注点（validator/idempotency/dispatch）注入为可组合中间件链。`ServerDeps` 收集所有依赖，`Assemble()` 按序应用中间件，`Build()` 一步完成装配与构造。

## 非目标

- 不定义中间件的具体行为（仅提供装饰器接口和装配逻辑）
- 不实现 validator/idempotency/dispatcher 的具体逻辑
- 不依赖外部中间件框架或 DI 容器
- 不引入第三方库

## v0.1.0 成功标准

- `ServerDeps` 收集全部 5 个依赖字段（Feed/Validator/Idempotency/Dispatcher/Config）
- `Validate()` 对 nil 依赖返回聚合错误（errors.Join）
- `Assemble()` 按序应用中间件链，nil 中间件安全跳过
- `Build()` 装配 + 构造一步完成，失败时返回 wrapped error
- `NopMiddleware` 透传不变，编译期满足 3 个 Middleware 接口
- 3 个 Middleware 接口（ValidatorMiddleware/IdempotencyMiddleware/DispatchMiddleware）编译期类型安全

## 依赖

- stdlib（errors, fmt）
- `github.com/ZoneCNH/runtime-patches/binance`（RequestValidator/IdempotencyStore/DownstreamDispatcher/IngestServer 类型）
- `github.com/ZoneCNH/runtime-patches/binancex`（MarketDataFeed 类型）

## 当前阻塞

| 优先级 | 阻塞项 | 处理方向 |
| --- | --- | --- |
| P0 | 缺少模块级 SPEC.md | 从 assembly.go 和 TRACEABILITY.md 提取创建 |
| P1 | 测试覆盖（assembly_test.go） | 补全 nil deps、顺序、NopMiddleware 测试 |
| P2 | 文档对齐（README/CHANGELOG） | 发布前补齐 |
