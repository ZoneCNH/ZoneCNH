# taosx Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v1.0.1 |
| Layer | L2 存储适配器 |
| Source of truth | `/home/taosx/pkg/taosx` |
| Last-Updated | 2026-06-13 |

## 目标

`taosx` 的 v1.0.1 目标是在保持 v1.0.0 公共 API 与驱动注入边界不变的前提下，交付一个可审计、可测试、可替换驱动实现的 TDengine L2 存储适配器契约，并用真实 TDengine WebSocket 集成测试证明官方 `taosWS` driver 可通过 `WithDriver` 接入。模块应让上层系统用稳定 Go API 组合 TDengine 写入、查询、健康检查和指标采集，而不是在核心包中内置连接池、STMT 写入、自动重试或横切运行时；v1.0.1 同时闭合 batch rows / schemaless lines 指标语义和 `pkg/taosx` 100.0% 覆盖证据。

## 成功标准

- `pkg/taosx` 暴露 `Client`、`Driver`、`Config`、`Statement`、`Query`、`Batch`、`SchemalessPayload`、`Rows` 和 `Metrics` 等核心契约。
- `Config` 明确包含 `Name`、`DriverMode`、`Endpoint`、`Database`、`Username`、`Password`、`Timeout`、`MaxRetries`、`TLS` 字段，并支持默认值归一化、校验、脱敏快照和 redacted DSN。
- `New(ctx, cfg, opts...)` 在配置有效时可创建 client；未注入 driver 时操作返回明确、可重试的 unavailable 错误。
- `Client` API 仅承诺 `Exec`、`Query`、`WriteBatch`、`SchemalessWrite`、`Health`、`Close`。
- `Driver` 通过 `WithDriver` 注入；`Driver.Health(ctx) error` 由 client 转换成面向调用方的 `HealthStatus`。
- `WriteBatch` 校验 database、table、timestamp、fields 和 points；空 batch 是 validation error，不是 no-op。
- `SchemalessWrite` 校验协议、精度和 lines；空 lines 是 validation error。
- 错误可分类、可重试性明确，日志、DSN 和健康信息不得泄漏密码。
- 指标名称保持 `taosx_client_*` 前缀，且 metrics 是接口注入能力，不形成对观测模块的直接依赖。
- `Close` 幂等；关闭后业务操作返回 closed 错误。
- 中心依赖契约保持 `taosx: [kernel]`，不得声明直接依赖 `configx`、`observex` 或 `resiliencx`。
- v1.0.1 发布前必须通过官方 `taosWS` WebSocket driver 的 env-gated 集成测试，且测试失败输出不得泄漏 DSN 或密码。

## 范围内

- TDengine 连接配置的结构化表示与脱敏输出。
- SQL statement/query 的空值校验和驱动委托。
- batch 与 schemaless payload 的边界校验和结果契约。
- 健康检查状态模型：client 返回 `HealthStatus`，driver 只返回 health error。
- no-op metrics 默认实现与可注入 metrics 接口。
- 默认 unavailable driver，防止误认为零配置可连接真实 TDengine。
- 基于官方 `taosWS` 的显式 opt-in TDengine WebSocket 集成测试证据。

## 范围外

- 核心包默认真实驱动、内置凭据管理、连接池、STMT 写入、自动重试和退避。
- 自动建表、schema migration、订阅、流式查询和业务级时序模型。
- 直接读取配置中心、环境变量或密钥管理系统。
- 直接依赖 `configx`、`observex`、`resiliencx` 等横切模块。
- 对原始 SQL 做参数绑定或注入防护；核心包只拒绝空 SQL，参数化由上层或具体 driver adapter 负责。

## 公共契约快照

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

## 依赖边界

`module/FOUNDATION-DEPS.yaml` 规定 `taosx` 的直接 foundation 依赖只允许 `kernel`。当前实现应优先保持核心包零 Zone 横切依赖；未来如果确需使用 `kernel` 能力，必须先更新契约与追溯矩阵。配置加载、observability、retry/resilience 等能力通过调用方适配器、接口注入或上层编排组合。

## 验证基线

- `/home/taosx/pkg/taosx/config.go` 与 `contracts/config.schema.json` 锁定 `Config` 字段、默认值和校验。
- `/home/taosx/pkg/taosx/client.go`、`batch.go`、`schemaless.go`、`health.go` 锁定 client/driver 行为。
- `/home/taosx/pkg/taosx/*_test.go`、`/home/taosx/contracts/contracts_test.go`、`/home/taosx/examples/*/*_test.go` 提供回归证据。
- `go test ./...`、`go test -race ./pkg/taosx ./contracts`、`go test ./pkg/taosx -coverprofile=/tmp/taosx.cover` 和 `go tool cover -func=/tmp/taosx.cover`（`pkg/taosx` total 100.0%）是实现仓的完整默认验证。
- `TAOSX_INTEGRATION=1 go test -tags=integration ./pkg/taosx -run TestTDengineWebSocketIntegration -count=1` 使用本地 dev 配置注入真实 TDengine 连接参数，且不输出凭据。
- 中心仓文档修改至少通过 `git diff --check` 和契约文本漂移检查。

## 评分基线

v1.0.1 评分同时看契约准确性、边界诚实、测试锁定行为、真实 TDengine 集成证据和文档一致性。未显式 opt-in 的默认测试可不连接 TDengine；但发布评分必须包含 `integration` tag 实测。任何文档声称内置连接池、STMT、自动重试、真实默认驱动、直接依赖 `configx`/`observex`/`resiliencx`，或把空 batch 描述为 no-op，均视为 contract drift。
