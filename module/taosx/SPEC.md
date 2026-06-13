# taosx 完整规格

> 基座 · TDengine L2 存储适配器。当前规格批准可注入驱动的 Go 契约边界；真实 TDengine 通过显式 driver 注入和 opt-in 集成测试验证，不作为核心包默认连接行为。

最后更新：2026-06-13

---

## 1. Metadata

- Status: Approved
- Governance-Status: 已仲裁；v1.0.0 发布文档已合入 main，当前补齐 23 节规格结构以满足文档门禁
- Spec-Version: v0.2.0
- Last-Updated: 2026-06-13
- Layer: L2 存储适配器
- Module-Version: v1.0.0
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `kernel`

---

## 2. Summary

`taosx` 是 TDengine 的 L2 存储适配器契约模块。v1.0.0 交付 Go 侧可审计的适配器边界：配置归一化与脱敏、SQL 执行与查询契约、批量写入与 schemaless 写入契约、健康检查、可注入驱动端口和可选指标端口。

v1.0.0 保持 `pkg/taosx` 为公共运行时 API：默认驱动仍显式不可用，真实 TDengine 通过 `WithDriver` 注入或测试适配器接入。发布验证已使用官方 `taosWS` WebSocket driver 在本地 dev 环境执行真实 `SHOW DATABASES` 集成测试；核心包仍不内置连接池、STMT 批量写入实现或自动重试策略。

---

## 3. Goals

- 提供 `New(ctx, Config, ...Option) (Client, error)` 构造函数，创建可关闭的 TDengine 适配器客户端。
- 提供 `Config.Normalize`、`Config.Validate`、`Config.RedactedDSN` 和敏感字段脱敏。
- 提供 `Client`、`Driver`、`Rows`、`Metrics` 端口，覆盖执行、查询、写入、健康和关闭。
- 允许真实 TDengine driver 通过 `WithDriver` 注入，而不是让核心包直接持有生产 driver 依赖。
- 用契约测试锁定校验、错误分类、健康状态、指标回调、关闭幂等性和凭据脱敏。
- 提供显式 opt-in 的 TDengine WebSocket 集成测试，验证官方 `taosWS` driver 可经 `WithDriver` 接入且失败输出不泄漏凭据。
- 保持 foundation 依赖边界，只允许直接依赖 `kernel`。

---

## 4. Non-goals

- 不把真实 TDengine 连接做成核心包默认行为；官方 `taosWS` 集成仅作为 env-gated 测试/适配器证据进入发布门禁。
- 不实现连接池、核心包内置生产驱动或凭据管理。
- 不实现 STMT 写入、自动建表、schema migration、流式订阅或业务级时序模型。
- 不读取环境变量、配置文件或远程配置中心。
- 不直接依赖 `configx`、`observex`、`resiliencx` 或其它横切模块。
- 不保证原始 SQL 的注入安全；参数化和 SQL DSL 属于上层或具体 driver 职责。

---

## 5. Consumers

- `market-data` 使用 `taosx` 写入行情 tick、bar 和聚合指标。
- `factor-engine` 使用 `taosx` 查询时序特征和回测样本。
- 运维检查工具使用 `Health` 与 `RedactedDSN` 输出安全诊断。
- 测试套件使用 fake driver 验证调用链，不依赖真实 TDengine 实例。
- 发布验证通过本地 dev 配置显式运行官方 `taosWS` 集成测试，不进入默认 `go test ./...` 路径。

---

## 6. Problem Statement

当前数据域需要一个稳定、可测、可替换的 TDengine 适配器边界。若业务代码直接绑定具体 driver、连接串和错误结构，后续迁移 driver mode、加 TLS、接入指标和统一错误分类都会扩散到调用方。`taosx` 将这些约束收敛到 foundation 模块，先交付接口和行为契约，再允许独立适配器或调用方注入真实 driver。

---

## 7. Functional Requirements

### FR-001: Config normalization

WHEN 调用 `Config.Normalize()` 且名称、driver mode 或 timeout 为空
THEN 补齐默认名称、WebSocket driver mode 和 5 秒 timeout

### FR-002: Config validation

WHEN 调用 `Config.Validate()` 且 endpoint、database、driver mode、timeout 或 retry 配置非法
THEN 返回 `taosx.Config` 操作名的 validation error，且错误文本不包含 password

### FR-003: Client construction

WHEN 调用 `New(ctx, cfg, opts...)` 且配置合法
THEN 返回实现 `Client` 的对象，并应用注入的 `Driver` 与 `Metrics`

### FR-004: Default unavailable driver

WHEN 未注入真实 `Driver` 且调用外部操作
THEN 返回 classified unavailable error，不伪造成功结果

### FR-005: Exec

WHEN 调用 `Exec(ctx, Statement{SQL: ...})` 且 SQL 非空
THEN 委托给 driver 并返回 `ExecResult`

### FR-006: Query

WHEN 调用 `Query(ctx, Query{SQL: ...})` 且 SQL 非空
THEN 返回 driver 提供的 `Rows`，调用方可以读取 columns、scan 和 close

### FR-007: WriteBatch

WHEN 调用 `WriteBatch(ctx, batch)` 且 database、table、points 合法
THEN 委托给 driver 并返回写入行数、耗时和 partial 标记

### FR-008: SchemalessWrite

WHEN 调用 `SchemalessWrite(ctx, payload)` 且 lines 与 protocol 合法
THEN 委托给 driver 并记录 schemaless 写入指标

### FR-009: Health and Close

WHEN 调用 `Health(ctx)` 或 `Close(ctx)`
THEN health 映射 driver 状态，close 幂等，关闭后操作返回 closed error

### FR-010: Metrics

WHEN 注入 `Metrics` 端口且执行任一外部操作
THEN 记录 request、duration、error、health 和 batch rows 指标；未注入时使用 no-op

### FR-011: Official taosWS integration

WHEN `TAOSX_INTEGRATION=1`、`integration` build tag 和真实 dev 配置同时存在
THEN 官方 `taosWS` WebSocket driver 通过 `WithDriver` 执行 `SHOW DATABASES`，且失败输出只展示脱敏 endpoint/database，不泄漏 DSN、username 或 password

---

## 8. Business Rules

- BR-001: 直接 foundation 依赖只允许 `kernel`，禁止在核心包内引入其它 ZoneCNH 模块。
- BR-002: 所有外部操作必须接受 `context.Context`。
- BR-003: 错误必须可分类并携带稳定操作名。
- BR-004: `MaxRetries` 是配置契约保留字段，不代表核心 client 自动重试。
- BR-005: 默认 driver 必须显式不可用，避免误导调用方。
- BR-006: 日志、错误、健康状态和 DSN 表示不得暴露 password。
- BR-007: 真实集成测试必须显式 opt-in，不得进入默认测试路径；失败输出不得包含 DSN、用户名或密码。

---

## 9. Interface Contract

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

type Metrics interface {
	RecordRequest(operation string, err error)
	RecordDuration(operation string, duration time.Duration)
	RecordRows(operation string, rows int)
}
```

---

## 10. Data Model

- `Config`: name、driver mode、endpoint、database、username、password、timeout、max retries、TLS。
- `Statement`: SQL 与参数列表。
- `Query`: SQL、参数列表和扫描 hint。
- `Batch`: database、table、points 与写入选项。
- `SchemalessPayload`: protocol、precision、lines。
- `HealthStatus`: live、ready、mode、database、message。
- `ExecResult` / `WriteResult`: affected rows、duration、partial 标记和 driver metadata。

---

## 11. Config Schema

```yaml
taosx:
  name: market-taos
  driver-mode: websocket
  endpoint: taos.example.internal:6041
  database: market
  username: root
  password: "<redacted>"
  timeout: 5s
  max-retries: 0
  tls: true
```

配置键由调用方映射到 `Config`。核心包不读取环境变量，也不输出原始 password。

---

## 12. Error Handling

- validation error 用于空 SQL、缺失 endpoint、缺失 database、非法 driver mode、负 timeout、负 retry、空 batch 和非法 protocol。
- unavailable error 用于默认 driver 或底层连接不可用。
- closed error 用于 client 关闭后的外部操作。
- driver error 保留分类，包装时添加 `taosx.<Operation>`。
- partial write error 必须保留已写入行数和 partial 标记。
- 所有错误输出都要通过 redaction，禁止泄露 password。

---

## 13. Edge Cases

- `New(nil, cfg)` 返回 validation error。
- `Close(ctx)` 重复调用返回 nil。
- `Health(ctx)` 在 driver 为 nil 或已关闭时返回 degraded。
- `Rows.Close()` 可以重复调用且不得 panic。
- `WriteBatch` 遇到空 points 返回 validation error。
- `SchemalessWrite` 遇到空 lines 返回 validation error。
- context canceled 优先返回调用方 context error。
- 未设置 `TAOSX_INTEGRATION=1` 时，真实 TDengine 集成测试必须跳过。

---

## 14. Directory Structure

```text
pkg/taosx/
  batch.go
  client.go
  config.go
  driver.go
  errors.go
  health.go
  integration_tdengine_test.go
  metrics.go
  rows.go
  schemaless.go
  sql.go
  types.go
contracts/
  config.schema.json
  health.schema.json
  metrics.contract.yaml
  public_api.snapshot
docs/
  api.md
  config.md
  errors.md
  testing.md
examples/
  basic/
```

---

## 15. Dependencies

- 允许：Go standard library、`kernel` 的错误分类或上下文契约。
- 禁止：`configx`、`observex`、`resiliencx`、`postgresx`、`redisx`、`clickhousex`、业务仓库。
- 官方 `taosWS` driver 只允许出现在 opt-in 集成测试或独立 adapter/调用方注入层，不能成为核心包默认运行路径。
- 依赖边界以 `module/FOUNDATION-DEPS.yaml` 与 `/home/taosx/go.mod` 为准。

---

## 16. Testing

**TC-001: Config normalization**
Given 空 name、driver mode 和 timeout
When 调用 Normalize
Then 返回默认 name、WebSocket mode 和 5 秒 timeout

**TC-002: Config validation**
Given 缺失 endpoint 或负 timeout
When 调用 Validate
Then 返回 validation error 且不泄露 password

**TC-003: Client construction**
Given 合法 config 和 fake driver
When 调用 New
Then 返回 client 并保留注入 driver

**TC-004: Default unavailable driver**
Given 未注入 driver 的 client
When 调用 Exec
Then 返回 unavailable error

**TC-005: Exec and Query**
Given fake driver
When 调用 Exec 与 Query
Then SQL 被委托，Rows 可读取并关闭

**TC-006: WriteBatch**
Given 合法 batch
When 调用 WriteBatch
Then 返回写入结果；空 points 返回 validation error

**TC-007: SchemalessWrite**
Given 合法 schemaless payload
When 调用 SchemalessWrite
Then 返回写入结果；空 lines 返回 validation error

**TC-008: Health and Close**
Given fake driver 和 client
When 调用 Health、Close、重复 Close
Then health 映射 driver 状态，Close 幂等，关闭后操作返回 closed error

**TC-009: Redaction**
Given config 含 password
When 输出 RedactedDSN、错误或 health message
Then password 被替换为 redacted 标记

**TC-010: Metrics**
Given 注入 metrics recorder
When 执行 Exec、Query、WriteBatch、SchemalessWrite、Health
Then request、duration、error、rows 指标被记录

**TC-011: Official taosWS integration**
Given `TAOSX_INTEGRATION=1`、`integration` build tag 和真实 dev 配置
When 运行 `TestTDengineWebSocketIntegration`
Then 通过官方 WebSocket driver 执行 `SHOW DATABASES`，并确保测试输出不包含 DSN、用户名或密码

---

## 17. Observability

- 指标名使用 `taosx_client_*` 前缀。
- 指标标签包含 operation、driver mode、status，不包含 SQL 明文或 password。
- 健康状态输出 name、mode、database、ready、live 和 redacted message。
- 结构化日志由调用方注入，核心包只提供安全字段。
- 集成测试失败输出只允许出现脱敏 endpoint/database 和稳定错误分类。

---

## 18. Security

- password 只能保存在 `Config` 内存字段，不得进入错误文本、DSN、日志或健康状态。
- TLS 只作为配置契约字段表达，真实握手由注入 driver 实现。
- SQL 注入防护由调用方参数化查询或具体 driver 负责。
- 测试必须覆盖 redaction 和 secret-free error。
- 真实 dev 凭据只能通过外部环境变量注入，不得写入仓库文档、测试快照或 CI 输出。

---

## 19. Performance

- 核心 client 不做网络 IO 外的重型处理。
- `Normalize`、`Validate` 和 redaction 为 O(1) 字段处理。
- `WriteBatch` 不复制 point payload，除非 driver adapter 需要。
- 指标 no-op 路径不得引入分配热点。
- 性能预算由真实 driver adapter 的 benchmark 提供证据。

---

## 20. Migration / Compatibility

- v1.0.0 冻结公共接口形状、错误分类、配置脱敏和驱动注入边界。
- 未来真实 driver adapter 必须实现本规格的 `Driver` 端口。
- 若 TDengine driver mode 增加，必须先扩展 `DriverMode` 枚举和 validation 测试。
- 与其它存储模块的能力差异通过 README 状态表说明，不在核心包内桥接。
- 如果未来把 retry、连接池或 STMT 写入纳入核心包，必须新增 FR、BR、测试和依赖边界说明。

---

## 21. Rollout

- 阶段 1: 合入契约、fake driver 测试和文档追溯。
- 阶段 2: 加入官方 `taosWS` env-gated 集成测试，验证真实 driver 注入链路。
- 阶段 3: 在独立 adapter 或调用方中接入真实 TDengine driver。
- 阶段 4: 对接 `market-data` 的非生产环境写入链路。
- 阶段 5: 补齐 benchmark、SLO 和生产发布证据后扩展运行时能力。

---

## 22. Open Questions

- 是否需要单独的 WebSocket adapter 仓库承载真实 driver 依赖。
- 是否需要统一 time precision 类型以覆盖 TDengine schemaless 协议。
- 是否需要把 query scan helper 放入 `testkitx` 而不是 `taosx`。
- 是否需要将 `MaxRetries` 从核心 Config 移到 adapter 层配置。
- 是否要把官方 `taosWS` 集成测试迁移到独立 nightly workflow，避免默认 PR 门禁依赖外部数据库。

---

## 23. Release Evidence

- 当前状态: Approved，v1.0.0 发布文档与实现证据已对齐。
- 文档证据: `module/taosx/SPEC.md`、`module/taosx/TRACEABILITY.md`。
- 本地验证: `go test ./pkg/taosx`、`go test ./contracts`、`go test ./examples/...`、`go test ./...`。
- 强化验证: `go test -race ./pkg/taosx ./contracts`、`go test ./pkg/taosx ./contracts -cover`（`pkg/taosx` 覆盖率 92.6%）。
- 边界验证: `./scripts/check_boundary.sh`、`./scripts/check_contracts.sh`、`./scripts/check_dependency_diff.sh`。
- 集成验证: `TAOSX_INTEGRATION=1 go test -tags=integration ./pkg/taosx -run TestTDengineWebSocketIntegration -count=1`（使用本地 dev 配置注入环境变量，不输出凭据）。
- 文档门禁: `git diff --check`、`.github/ci/spec-lint.sh`、`.github/ci/spec-drift-guard.sh`、`bash .github/ci/traceability-check.sh`。
