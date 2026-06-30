# assembly 规格

- Spec-Version: v0.1.0
- Runtime-Version: v0.1.0-patch
- Status: Draft（从 patches/assembly/assembly.go 反向提取）
- Last-Updated: 2026-06-30
- Source: `patches/assembly/assembly.go`

## 1. 摘要

`assembly` 为 binance ingest pipeline 提供中间件注入与依赖装配层。连接 binancex adapter 与 binance ingest server，将横切关注点注入为可组合中间件链。`ServerDeps` 收集所有依赖，`Assemble()` 按序应用中间件，`Build()` 一步完成装配与构造。`NopMiddleware` 提供透传实现和编译期接口合规断言。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | `ServerDeps` 依赖集合、`Assemble()` 中间件装配、`Build()` 装配+构造、`NopMiddleware` 透传、Middleware 接口定义（ValidatorMiddleware/IdempotencyMiddleware/DispatchMiddleware） |
| Depends on | `runtime-patches/binance`（RequestValidator/IdempotencyStore/DownstreamDispatcher/IngestServer 类型）、`runtime-patches/binancex`（MarketDataFeed 类型） |
| Consumed by | `cmd`（组合根入口） |
| Excludes | 中间件具体行为实现、validator/idempotency/dispatcher 逻辑、外部框架/DI 容器 |

## 3. 术语

| 术语 | 定义 |
| --- | --- |
| ServerDeps | 构造 ingest server 所需的全部依赖集合（Feed/Validator/Idempotency/Dispatcher/Config） |
| Middleware | 横切关注点接口，含 Name() 方法 |
| ValidatorMiddleware | 装饰 RequestValidator 的中间件接口 |
| IdempotencyMiddleware | 装饰 IdempotencyStore 的中间件接口 |
| DispatchMiddleware | 装饰 DownstreamDispatcher 的中间件接口 |
| Assemble | 将中间件链按序应用到各依赖，返回组装后的 ServerDeps |
| Build | Assemble + constructor 一步完成 |

## 4. 核心接口

### 4.1 ServerDeps

```go
type ServerDeps struct {
    Feed        binancex.MarketDataFeed
    Validator   binance.RequestValidator
    Idempotency binance.IdempotencyStore
    Dispatcher  binance.DownstreamDispatcher
    Config      binance.ServerConfig
}
```

### 4.2 Middleware 接口族

```go
type ValidatorMiddleware interface {
    Middleware
    WrapValidator(next binance.RequestValidator) binance.RequestValidator
}

type IdempotencyMiddleware interface {
    Middleware
    WrapIdempotency(next binance.IdempotencyStore) binance.IdempotencyStore
}

type DispatchMiddleware interface {
    Middleware
    WrapDispatcher(next binance.DownstreamDispatcher) binance.DownstreamDispatcher
}
```

## 5. 功能需求

| FR ID | Requirement |
| --- | --- |
| FR-ASM-001 | ServerDeps — 收集全部 5 个依赖字段 |
| FR-ASM-002 | Validate — 检查所有必需依赖非 nil，返回聚合错误 |
| FR-ASM-003 | Assemble — 按序应用中间件链到各依赖 |
| FR-ASM-004 | Build — 装配 deps + 构造 server 一步完成 |
| FR-ASM-005 | NopMiddleware — 透传所有依赖不变 |

## 6. 行为约束

| BR ID | Rule |
| --- | --- |
| BR-ASM-001 | 中间件链顺序保持：先注册先应用 |
| BR-ASM-002 | nil middleware 安全跳过，不 panic |
| BR-ASM-003 | ServerDeps.Validate 失败时 Assemble 返回 wrapped error |

## 7. 非功能需求

| NFR ID | Requirement |
| --- | --- |
| NFR-ASM-001 | NopMiddleware 编译期通过 3 个 Middleware 接口合规断言 |
| NFR-ASM-002 | 仅依赖 runtime-patches/binance + runtime-patches/binancex |

## 8. Acceptance Criteria Registry

见 [TRACEABILITY.md §5](./TRACEABILITY.md)

## 9. 后续实现门禁

- Compile Gate: `go build ./...` 零错误
- Test Gate: `go test ./... -count=1` 通过
- Vet Gate: `go vet ./...` 零警告

## 变更历史

| 日期 | 变更 |
| --- | --- |
| 2026-06-29 | v0.1.0 Draft：从 patches/assembly/assembly.go 反向提取，初始化 SPEC |
