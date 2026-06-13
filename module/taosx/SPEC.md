# taosx 规格

## 元数据

| 字段 | 值 |
| --- | --- |
| Status | Approved |
| Spec-Version | v0.2.0 |
| Last-Updated | 2026-06-13 |
| Layer | L2 存储适配器 |
| Module-Version | v1.0.0 |
| Related | `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `kernel` |

## 1. 摘要

`taosx` 是 TDengine 的 L2 存储适配器契约模块。v1.0.0 交付 Go 侧可审计的适配器边界：配置归一化与脱敏、SQL 执行与查询契约、批量写入与 schemaless 写入契约、健康检查、可注入驱动端口和可选指标端口。

v1.0.0 保持 `pkg/taosx` 为公共运行时 API：默认驱动仍显式不可用，真实 TDengine 通过 `WithDriver` 注入或测试适配器接入。发布验证已使用官方 `taosWS` WebSocket driver 在本地 dev 环境执行真实 `SHOW DATABASES` 集成测试；核心包仍不内置连接池、STMT 批量写入实现或自动重试策略。

## 2. 目标

- 提供 `New(ctx, Config, ...Option) (Client, error)` 构造函数，创建可关闭的 TDengine 适配器客户端。
- 提供 `Config` 的默认值归一化、字段校验、敏感信息脱敏和 redacted DSN 表示。
- 提供 `Client`/`Driver` 端口，覆盖 `Exec`、`Query`、`WriteBatch`、`SchemalessWrite`、`Health` 和 `Close`。
- 提供 `Rows` 抽象，允许驱动实现按行扫描、返回列信息和关闭查询结果。
- 提供 `Metrics` 端口与 no-op 默认实现，让上层 observability 适配器可以在不引入直接依赖的前提下接入。
- 通过契约测试锁定校验、错误分类、指标回调、健康状态和关闭幂等性。
- 提供显式 opt-in 的 TDengine WebSocket 集成测试，验证官方 `taosWS` driver 可经 `WithDriver` 接入且失败输出不泄漏凭据。

## 3. 非目标

- 不把真实 TDengine 连接做成核心包默认行为；官方 `taosWS` 集成仅作为 env-gated 测试/适配器证据进入发布门禁。
- 不实现连接池、核心包内置生产驱动或凭据管理。
- 不实现 STMT 写入、自动建表、schema migration、流式订阅或业务级时序模型。
- 不在核心包内读取环境变量、配置文件或远程配置中心。
- 不直接依赖 `configx`、`observex`、`resiliencx` 等横切模块；这些能力由调用方在边界外组合。
- 不保证原始 SQL 的注入安全；`taosx` 只拒绝空 SQL，参数化和 SQL DSL 属于上层或具体驱动职责。

## 4. 功能需求

| ID | 需求 | 验收标准 |
| --- | --- | --- |
| FR-001 | `Config.Normalize` 必须补齐默认名称、驱动模式和超时时间。 | 空名称归一化为包名，空驱动模式归一化为 WebSocket，零值超时归一化为 5 秒；负超时由校验拒绝。 |
| FR-002 | `Config.Validate` 必须拒绝缺失名称、endpoint、database、非法驱动模式、负超时和负重试次数。 | 校验错误使用 `taosx.Config` 操作名，并不泄漏密码。 |
| FR-003 | `New` 必须校验 context、配置和 options，并允许默认不可用驱动。 | 无注入驱动时构造成功；运行操作返回可重试的 unavailable 错误。 |
| FR-004 | `Exec` 必须拒绝空 SQL statement，并把合法 statement 委托给注入驱动。 | 空 SQL 返回 validation error；驱动错误保留错误分类和操作名。 |
| FR-005 | `Query` 必须拒绝空查询，并返回驱动提供的 `Rows`。 | 查询结果可以读取列、扫描行、关闭；驱动错误时不伪造结果。 |
| FR-006 | `WriteBatch` 必须校验 database、table 和 points。 | 空 batch 是 validation error；驱动部分失败时返回 partial result 和错误。 |
| FR-007 | `SchemalessWrite` 必须校验 lines 与协议。 | 空 lines 或非法协议返回 validation error；成功路径记录写入行数指标。 |
| FR-008 | `Health` 必须调用 `Driver.Health(ctx)` 并把 nil/error 映射为 `HealthStatus`。 | 默认不可用驱动返回 degraded；状态包含 mode、database 和 redacted error；调用不 panic。 |
| FR-009 | `Close` 必须幂等并接受 context。 | 重复关闭返回 nil；关闭后操作返回 closed 错误。 |
| FR-010 | 指标端口必须可选。 | 未注入 metrics 时使用 no-op；注入后记录 request、duration、error、health、batch rows 等 `taosx_client_*` 指标。 |

## 5. 行为约束

| ID | 约束 | 说明 |
| --- | --- | --- |
| BR-001 | 直接 foundation 依赖只允许 `kernel`。 | 以 `module/FOUNDATION-DEPS.yaml` 为准；当前核心实现不需要额外 Zone 模块依赖。 |
| BR-002 | 所有外部操作必须接受 `context.Context`。 | 构造、执行、查询、写入、健康检查和关闭都受调用方上下文控制。 |
| BR-003 | 错误必须可分类且可脱敏。 | 操作名使用 `taosx.<Operation>`，日志/DSN/状态不得暴露密码。 |
| BR-004 | `MaxRetries` 是配置契约保留字段，不代表核心 client 自动重试。 | 重试策略应由驱动适配器或上层 resilience 组合实现。 |
| BR-005 | 默认驱动必须显式不可用。 | 避免误导用户以为默认构造能连接真实 TDengine。 |
| BR-006 | 真实集成测试必须显式 opt-in 且凭据脱敏。 | 只在 `TAOSX_INTEGRATION=1` 与 `integration` build tag 同时存在时运行；失败输出不得泄漏 DSN 或密码。 |

## 6. 公共 API 契约

```go
type Client interface {
	Exec(context.Context, Statement) (ExecResult, error)
	Query(context.Context, Query) (Rows, error)
	WriteBatch(context.Context, Batch) (WriteResult, error)
	SchemalessWrite(context.Context, SchemalessPayload) (WriteResult, error)
	Health(context.Context) HealthStatus
	Close(context.Context) error
}

type Driver interface {
	Exec(context.Context, Statement) (ExecResult, error)
	Query(context.Context, Query) (Rows, error)
	WriteBatch(context.Context, Batch) (WriteResult, error)
	SchemalessWrite(context.Context, SchemalessPayload) (WriteResult, error)
	Health(context.Context) error
	Close(context.Context) error
}

type Config struct {
	Name       string
	DriverMode DriverMode
	Endpoint   string
	Database   string
	Username   string
	Password   string
	Timeout    time.Duration
	MaxRetries int
	TLS        bool
}
```

## 7. 使用示例

```go
cfg := taosx.Config{
	Endpoint: "127.0.0.1:6041",
	Database: "market",
	Username: "root",
	Password: "taosdata",
}

client, err := taosx.New(ctx, cfg, taosx.WithDriver(driver))
if err != nil {
	return err
}
defer func() {
	_ = client.Close(context.Background())
}()

rows, err := client.Query(ctx, taosx.Query{SQL: "SELECT ts, price FROM ticks"})
if err != nil {
	return err
}
defer rows.Close()
```

## 8. 验证要求

- `go test ./pkg/taosx`
- `go test ./contracts`
- `go test ./examples/...`
- `go test ./...`
- `go test -race ./pkg/taosx ./contracts`
- `go test ./pkg/taosx ./contracts -cover`（`pkg/taosx` 覆盖率 92.6%）
- `./scripts/check_boundary.sh`
- `./scripts/check_contracts.sh`
- `./scripts/check_dependency_diff.sh`
- `TAOSX_INTEGRATION=1 go test -tags=integration ./pkg/taosx -run TestTDengineWebSocketIntegration -count=1`（使用本地 dev 配置注入环境变量，不输出凭据）
- `git diff --check`
- 边界检查必须确认核心包没有引入未批准的 Zone 模块依赖。
