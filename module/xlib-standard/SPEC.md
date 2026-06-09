# xlib-standard 完整规格

> Go 基础库模板标准源。定义标准、提供可编译参考模板、生成独立基础库、用最小 gate 验证。

最后更新：2026-06-09

---

## 1. Metadata

- Status: Draft
- Spec ID: SPEC-XLIB-STD-001
- Spec-Version: v2.0.0
- Last-Updated: 2026-06-09
- Owner: ZoneCNH
- Layer: 基座（标准与门禁）
- Version: v1.0.0
- Repository: [github.com/ZoneCNH/xlib-standard](https://github.com/ZoneCNH/xlib-standard)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md), [goal.md](./goal.md)

### 1.2 Constitution 合规

本模块遵守 [CONSTITUTION.md](../../CONSTITUTION.md) 全部条款：

| 条款 | 合规要求 | 本模块实现 |
|------|----------|-----------|
| §1 基座依赖 | 依赖 kernel/configx/observex | go.mod 声明 |
| §3 contracts 接口 | 跨域交互通过 contracts | pkg/templatex 实现 |
| §5 错误规范 | ErrorKind 8 种 | errors.go 实现 |
| §6 可观测 | Metrics/Health | metrics.go + health.go |
| §7 配置规范 | Validate/Sanitize | config.go 实现 |
| §8 测试规范 | ≥80% 覆盖率 | _test.go 全覆盖 |
| §13 边界约束 | 不越界实现 | Non-goals 明确 |

| 字段 | 说明 |
|------|------|
| `Status` | 规格生命周期状态：Draft |
| `Spec-Version` | 规格文档版本号（与代码 Version 解耦） |
| `Last-Updated` | 规格最后修改日期 |
| `Owner` | 规格负责人 |
| `Layer` | 基座 · 标准与门禁（不被任何运行时模块依赖） |
| `Version` | 目标发布版本 v1.0.0 |
| `Repository` | 上游仓库链接 |
| `Related` | 相关文档链接 |

### 1.1 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-09 | v2.0.0 | 极简重写：从 52 FR 收敛至 14 FR，删除 Goal Runtime / Evidence Runtime / Debt Governance | ZoneCNH |
| 2026-06-08 | v1.0.0 | 初始版本（基于 ANALYSIS.md v3.1.0） | ZoneCNH |

---

## 2. Summary

`xlib-standard` 是 Go 基础库模板标准源。它定义基础库的最小公共 API 标准，提供可编译的参考模板，通过生成器创建独立 Go module，并用 9 个最小 gate 验证模板和生成库的质量。

---

## 3. Problem

FoundationX 由 70+ 个 Go 模块组成，缺乏统一模板标准会导致：

1. **API 不一致**：各基础库的 Config/Client/Error/Health/Metrics 接口形态各异，下游集成成本高。
2. **重复骨架代码**：每个新基础库从零编写 go.mod、errors.go、health.go、metrics.go 等骨架，重复 200+ 行。
3. **质量基线缺失**：无统一 gate，各库的 lint/test/contract 校验标准不一。
4. **身份漂移**：旧名 `baselib-template` 和 `foundationx` 导致文档和 import 路径混乱。

---

## 4. Goals

| 编号 | 目标 | 对应 FR |
|------|------|---------|
| G-1 | 定义基础库最小公共 API 标准（Config、Client、Error、Health、Metrics、Version） | FR-001..FR-006 |
| G-2 | 提供可编译的 Go 参考模板，覆盖全部公共 API | FR-007, FR-008 |
| G-3 | 提供模板生成器，从标准模板创建独立 Go module | FR-009, FR-010 |
| G-4 | 定义最小 gate 集（9 个），验证模板和生成库 | FR-011, FR-012 |
| G-5 | 提供 release manifest，记录版本和 gate 结果 | FR-013, FR-014 |

---

## 5. Non-goals

- **不做运行时代码**：不实现真实 provider runtime，不承载业务逻辑（由 kernel、configx、redisx 等模块实现）。
- **不做 Goal Runtime**：可执行目标文档以 goal.md 形式存在，不实现 goalcli 二进制或 .agent 运行时。
- **不做 Evidence Runtime**：不实现证据收集、验证、存储的运行时系统。
- **不做 Debt Governance**：不实现技术债治理规则检查器。
- **不做下游矩阵**：不追踪下游模块的采纳状态或兼容性矩阵。
- **不做二进制分发**：本仓库不包含 release artifact 或下游实现源码。
- **不做 Docker 运行时**：不提供 Dockerfile 或容器编排。
- **不做 L2 模板**：不为 redisx/kafkax/natsx 等 L2 适配器提供专用模板。

---

## 6. Consumers

| 消费者 | 领域 / 层级 | 使用方式 |
|--------|-------------|----------|
| `kernel` | 基座 / L0 | 使用生成器创建基础库骨架 |
| `configx` | 基座 / L1 | 使用生成器创建基础库骨架 |
| `observex` | 基座 / L1（横切） | 使用生成器创建基础库骨架 |
| `resiliencx` | 基座 / L1 | 使用生成器创建基础库骨架 |
| `schedulex` | 基座 / L1 | 使用生成器创建基础库骨架 |
| `redisx` | 基座 / L2 | 使用生成器创建基础库骨架 |
| `kafkax` | 基座 / L2 | 使用生成器创建基础库骨架 |
| `postgresx` | 基座 / L2 | 使用生成器创建基础库骨架 |
| `new-module` | 任意 | 使用生成器创建新基础库 |

---

## 7. Functional Requirements

> 14 条 FR 按 5 个职责组组织。

### 7.1 Standard Source（FR-001..FR-006）

#### FR-001: Config 标准 [P0]

**功能描述**：定义基础库 Config 的最小接口。

**WHEN** 调用方创建 Config 并调用 Validate()
**THEN** 必填字段缺失或值非法时返回 ErrorKindValidation 错误，列出所有不合法字段

**WHEN** 调用方调用 Sanitize()
**THEN** 返回新副本，secret/token/password/key/credential/dsn/url 字段被替换为 `***`

**WHEN** 配置中存在 secret 类字段
**THEN** 不得隐式读取环境变量或文件，必须由调用方显式传入

#### FR-002: Error 标准 [P0]

**功能描述**：定义 8 种 ErrorKind 和错误包装接口。

**WHEN** 调用方使用 `IsKind(err, ErrorKind...)` 做分支判断
**THEN** 8 种 ErrorKind（validation/config/connection/auth/timeout/unavailable/closed/internal）全部可识别

**WHEN** 错误被 WrapError 包装
**THEN** errors.Is/errors.As 能穿透包装层匹配原始 ErrorKind

#### FR-003: Health 标准 [P0]

**功能描述**：定义 HealthCheck 的返回格式和状态语义。

**WHEN** HealthCheck() 被调用
**THEN** 返回的 JSON 符合 contracts/health.schema.json，包含 name/status/message/checked_at/latency_ms/metadata 字段

**WHEN** status 为 unhealthy
**THEN** message 字段必须包含人类可读的故障原因

**WHEN** nil context 或 canceled context 传入
**THEN** 返回 unhealthy 状态

#### FR-004: Metrics 标准 [P0]

**功能描述**：定义 5 个最小 P0 指标。

**WHEN** 客户端创建、关闭、请求、健康检查等操作发生
**THEN** 对应 counter/gauge/histogram 指标自动递增或记录

**WHEN** 指标被注册
**THEN** 只使用 op/kind/status 三个 label，禁止 user_id/request_id/trace_id 等高基数 label

#### FR-005: Client 标准 [P0]

**功能描述**：定义 Client 的最小生命周期接口。

**WHEN** 调用方调用 New(ctx, cfg, opts...)
**THEN** ctx 为 nil 或 canceled 时返回错误，cfg 无效时返回错误，成功时返回 *Client

**WHEN** 调用方调用 Close(ctx)
**THEN** 释放所有资源，幂等（多次调用不 panic）

**WHEN** 调用方调用 HealthCheck(ctx)
**THEN** 返回当前健康状态

#### FR-006: Version 标准 [P1]

**功能描述**：定义版本信息接口。

**WHEN** 调用方查询版本信息
**THEN** 返回 module path、version、commit、build time

---

### 7.2 Go Reference Template（FR-007..FR-008）

#### FR-007: 公共 API 模板 [P0]

**功能描述**：参考模板必须覆盖全部公共 API。

**WHEN** 模板渲染完成
**THEN** 生成的 Go 代码包含 Config/Validate/Sanitize/New/Close/HealthCheck/Error/Metrics/Version 全部公共 API

**WHEN** 生成的代码执行 `go vet`
**THEN** 无警告，所有导出符号有文档注释

#### FR-008: 模板可编译 [P0]

**功能描述**：模板本身必须可编译可测试。

**WHEN** 在模板目录执行 `GOWORK=off go test ./...`
**THEN** 全部通过

**WHEN** 在模板目录执行 `GOWORK=off go test -race ./...`
**THEN** 无竞态

---

### 7.3 Generator（FR-009..FR-010）

#### FR-009: render_template.sh 渲染 [P0]

**功能描述**：模板渲染脚本创建独立 Go module。

**WHEN** 执行 `scripts/render_template.sh --module-path <path> --package-name <pkg> --out <dir> [--module-name <name>]`
**THEN** 创建独立 Go module，所有占位符替换为实际值，目录结构完整

**WHEN** 渲染目标目录已存在且非空
**THEN** 拒绝写入，返回错误

**WHEN** 渲染完成
**THEN** 在生成目录执行 `GOWORK=off go test ./...` 验证

#### FR-010: 生成库无模板残留 [P0]

**功能描述**：生成的库不得包含模板特有内容。

**WHEN** 生成库创建完成
**THEN** 不包含 `templatex`、`xlib-standard`、`foundationx`、`baselib-template` 残留

---

### 7.4 Harness Gates（FR-011..FR-012）

#### FR-011: 9 个最小 gate [P0]

**功能描述**：定义验证模板和生成库的最小 gate 集。

**WHEN** 执行 `GOWORK=off make ci`
**THEN** 9 个 gate（fmt/vet/lint/test/race/contracts/boundary/render-smoke/security）全部通过

#### FR-012: boundary gate 检查 [P0]

**功能描述**：boundary gate 阻止非法引用。

**WHEN** 代码中出现 x.go/internal、/home/k8s/secrets/env、foundationx、baselib-template、templatex、xlib-standard 残留
**THEN** boundary gate 失败并报告违规路径

---

### 7.5 Release（FR-013..FR-014）

#### FR-013: release manifest [P0]

**功能描述**：release manifest 记录版本和 gate 结果。

**WHEN** 执行 `GOWORK=off make release-check`
**THEN** 生成 release/manifest/latest.json 和 latest.json.sha256

**WHEN** manifest 被加载
**THEN** 包含 module_path/package_name/version/commit/tree_sha/go_version/contracts_sha256/gates/generated_at 字段

#### FR-014: release final check [P0]

**功能描述**：最终发布前的完整性校验。

**WHEN** 执行 `GOWORK=off make release-final-check`
**THEN** 所有 gate 通过 + manifest 生成 + checksum 校验通过

---

## 8. Business Rules

### BR-001: 配置显式传入

所有配置必须由调用方显式传入，不得隐式读取环境变量、文件或内置生产 endpoint。

**约束**：Config 结构体不得包含 `os.Getenv` 调用。
**违反时**：代码审查阻断。

### BR-002: 错误消息格式

错误消息格式为 `"package: operation: detail"`。

**约束**：所有公共错误使用 `errors.New` 创建，使用 `%w` 保留错误链。
**违反时**：lint 失败。

### BR-003: Metrics label 低基数

P0 指标只使用 op/kind/status 三个 label，禁止高基数 label。

**约束**：contracts/metrics.json 中 forbidden_labels 列表不可缩减。
**违反时**：contracts gate 失败。

### BR-004: 模板占位符完整性

模板中所有占位符必须在渲染时全部替换。

**约束**：渲染后不得出现 `{{.ModulePath}}`、`{{.Module}}`、`{{.Package}}` 占位符。
**违反时**：render-smoke gate 失败。

### BR-005: 生成库独立性

生成的库必须是独立 Go module，不依赖 xlib-standard。

**约束**：生成库的 go.mod 不得 require xlib-standard。
**违反时**：boundary gate 失败。

### BR-006: 不在库中 log.Fatal

基础库不得使用 `log.Fatal` 或 `os.Exit`，错误必须返回给调用方。

**约束**：源码中不得出现 `log.Fatal`、`os.Exit`、`panic`（测试除外）。
**违反时**：lint 或 vet 失败。

### BR-007: Sanitize 脱敏范围

Sanitize 必须脱敏 secret/token/password/key/credential/dsn/url 字段。

**约束**：Sanitize 输出中不得出现明文敏感字段。
**违反时**：测试失败。

---

## 9. Interface Contract

### 9.1 Client 接口

```go
// Client 基础库客户端的最小接口。
type Client interface {
    // Close 释放所有资源，幂等。
    Close(ctx context.Context) error
    // HealthCheck 返回当前健康状态。
    HealthCheck(ctx context.Context) HealthStatus
}
```

### 9.2 构造函数

```go
// New 创建客户端实例。ctx nil 或 canceled 时返回错误。
func New(ctx context.Context, cfg Config, opts ...Option) (*Client, error)
```

### 9.3 Config 接口

```go
// Config 基础库配置的最小接口。
type Config interface {
    // Validate 校验配置合法性。
    Validate() error
    // Sanitize 返回脱敏后的副本。
    Sanitize() SanitizedConfig
}
```

### 9.4 Error 接口

```go
// Error 基础库错误类型。
type Error struct {
    Kind    ErrorKind
    Op      string
    Message string
    Err     error
}

func NewError(kind ErrorKind, op, message string, err error) *Error
func WrapError(err error, op string) error
func IsKind(err error, kinds ...ErrorKind) bool
```

### 9.5 HealthStatus

```go
// HealthStatus 健康检查结果。
type HealthStatus struct {
    Name      string            `json:"name"`
    Status    string            `json:"status"`    // healthy | degraded | unhealthy
    Message   string            `json:"message"`
    CheckedAt time.Time         `json:"checked_at"`
    LatencyMs int64             `json:"latency_ms"`
    Metadata  map[string]string `json:"metadata,omitempty"`
}
```

---

## 10. Data Model

### 10.1 ErrorKind

| ErrorKind | 说明 | retryable |
|-----------|------|-----------|
| `validation` | 输入校验失败 | false |
| `config` | 配置错误 | false |
| `connection` | 连接失败 | true |
| `auth` | 认证/授权失败 | false |
| `timeout` | 超时 | true |
| `unavailable` | 服务不可用 | true |
| `closed` | 客户端已关闭 | false |
| `internal` | 内部错误 | false |

### 10.2 Health Status 枚举

| Status | 说明 |
|--------|------|
| `healthy` | 正常运行 |
| `degraded` | 部分功能受限（仅作为具体库扩展） |
| `unhealthy` | 不可用 |

### 10.3 SanitizedConfig

SanitizedConfig 是 Config 的脱敏副本，所有敏感字段替换为 `***`。

---

## 11. Config Schema

### 11.1 标准配置项

| 配置项 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| `Name` | `string` | ✅ | 客户端名称，用于日志和指标 |
| `Timeout` | `time.Duration` | ❌ | 操作超时，默认 30s |

### 11.2 配置约束

- 所有配置显式传入，不得读取环境变量或文件
- 不得内置生产 endpoint
- Validate 检查必填字段和非法值（如负数 timeout）
- Sanitize 脱敏 secret/token/password/key/credential/dsn/url

---

## 12. Error Handling

### 12.1 公共错误变量

| 变量名 | ErrorKind | 说明 |
|--------|-----------|------|
| `ErrValidation` | validation | 输入校验失败 |
| `ErrConfig` | config | 配置错误 |
| `ErrConnection` | connection | 连接失败 |
| `ErrAuth` | auth | 认证/授权失败 |
| `ErrTimeout` | timeout | 超时 |
| `ErrUnavailable` | unavailable | 服务不可用 |
| `ErrClosed` | closed | 客户端已关闭 |
| `ErrInternal` | internal | 内部错误 |

### 12.2 错误处理原则

- 公共错误定义在 `errors.go`
- 错误消息格式：`"package: operation: detail"`
- 使用 `%w` 保留错误链
- 不在库中使用 `log.Fatal` 或 `os.Exit`
- errors.Is/errors.As 能穿透 WrapError 匹配原始 ErrorKind

### 12.3 错误契约

错误 JSON 格式遵循 `contracts/errors.schema.json`：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `kind` | string | ✅ | 8 种 ErrorKind 之一 |
| `op` | string | ✅ | 操作名，minLength: 1 |
| `message` | string | ✅ | 人类可读消息 |
| `retryable` | boolean | ✅ | 是否可重试 |

---

## 13. Edge Cases

| 场景 | 输入/状态 | 预期行为 |
|------|-----------|----------|
| nil context | New(nil, cfg) | 返回错误，ErrorKind = validation |
| canceled context | New(canceledCtx, cfg) | 返回错误，ErrorKind = timeout |
| 无效配置 | New(ctx, invalidCfg) | 返回 ErrorKindValidation，列出不合法字段 |
| 幂等 Close | Close 后再 Close | 不 panic，返回 nil 或 ErrClosed |
| 零值 Client | 零值 Client.HealthCheck() | 返回 unhealthy |
| 超时 | context deadline exceeded | ErrorKind = timeout |
| 并发 Close | 多 goroutine 同时 Close | 不 panic，不竞态 |
| Sanitize 输出 | 包含 secret 字段 | 输出中 secret 替换为 `***` |

---

## 14. Directory Structure

### 14.1 xlib-standard 仓库结构

```text
.
├── .github/
├── contracts/
│   ├── errors.schema.json
│   ├── health.schema.json
│   └── metrics.json
├── docs/
│   ├── standard.md
│   ├── api.md
│   ├── config.md
│   ├── errors.md
│   ├── health.md
│   ├── metrics.md
│   ├── testing.md
│   ├── generation.md
│   └── release.md
├── examples/
│   └── basic/main.go
├── pkg/
│   └── templatex/
│       ├── doc.go
│       ├── config.go / config_test.go
│       ├── errors.go / errors_test.go
│       ├── metrics.go / metrics_test.go
│       ├── client.go / client_test.go
│       └── health.go / health_test.go
├── scripts/
│   ├── render_template.sh
│   ├── check_rendered_template.sh
│   ├── check_boundary.sh
│   ├── check_contracts.sh
│   ├── check_security.sh
│   ├── release_check.sh
│   └── release_final_check.sh
├── testkit/
│   ├── metrics.go
│   └── assertions.go
├── .gitignore
├── .golangci.yml
├── CHANGELOG.md
├── LICENSE
├── Makefile
├── README.md
├── go.mod
└── go.sum
```

### 14.2 生成库结构

```text
{module}/
├── doc.go
├── config.go / config_test.go
├── errors.go / errors_test.go
├── metrics.go / metrics_test.go
├── client.go / client_test.go
├── health.go / health_test.go
├── go.mod
├── go.sum
└── README.md
```

---

## 15. Dependencies

### 15.1 xlib-standard 直接依赖

| 依赖 | 版本 | 用途 | 来源 |
|------|------|------|------|
| `go` | 1.24+ | 语言版本 | 标准库 |

### 15.2 生成库依赖

生成的库为 stdlib-only，零外部依赖。仅使用标准库的 `context`、`errors`、`time`、`fmt`、`sync` 包。

---

## 16. Testing

### 16.1 测试矩阵

| TC 编号 | 对应 FR | 测试类型 | 场景 | 预期结果 |
|---------|---------|----------|------|----------|
| TC-001 | FR-001 | 单元 | Config.Validate 必填字段缺失 | 返回 ErrorKindValidation |
| TC-002 | FR-001 | 单元 | Config.Validate 负数 timeout | 返回 ErrorKindValidation |
| TC-003 | FR-001 | 单元 | Config.Sanitize 脱敏 | secret 替换为 `***` |
| TC-004 | FR-002 | 单元 | NewError 创建 | Error 字段正确 |
| TC-005 | FR-002 | 单元 | WrapError 包装 | errors.Is 可穿透 |
| TC-006 | FR-002 | 单元 | IsKind 匹配 | 返回 true |
| TC-007 | FR-002 | 单元 | context.DeadlineExceeded | ErrorKind = timeout |
| TC-008 | FR-002 | 单元 | closed error | ErrorKind = closed |
| TC-009 | FR-003 | 单元 | HealthCheck nil context | 返回 unhealthy |
| TC-010 | FR-003 | 单元 | HealthCheck 健康客户端 | 返回 healthy |
| TC-011 | FR-004 | 单元 | NoopMetrics 不 panic | 无异常 |
| TC-012 | FR-004 | 单元 | 指标名匹配 contract | 5 个 P0 指标名一致 |
| TC-013 | FR-004 | 单元 | label 低基数 | 只有 op/kind/status |
| TC-014 | FR-005 | 单元 | New nil context | 返回错误 |
| TC-015 | FR-005 | 单元 | New canceled context | 返回错误 |
| TC-016 | FR-005 | 单元 | New 无效 config | 返回错误 |
| TC-017 | FR-005 | 单元 | New 正常创建 | 返回 *Client |
| TC-018 | FR-005 | 单元 | Close 幂等 | 多次调用不 panic |
| TC-019 | FR-007 | 集成 | 模板 go vet | 零警告 |
| TC-020 | FR-008 | 集成 | 模板 go test | 全部通过 |
| TC-021 | FR-009 | 集成 | render_template.sh 渲染 | 输出目录结构完整 |
| TC-022 | FR-010 | 集成 | 生成库无残留 | grep 无 templatex/xlib-standard |
| TC-023 | FR-011 | 集成 | make ci | 9 个 gate 全通过 |
| TC-024 | FR-013 | 集成 | release manifest 生成 | 字段完整 |

### 16.2 测试工具

- 框架：`testing`（stdlib）
- 覆盖率：`go tool cover`
- 竞态：`go test -race`

### 16.3 禁止测试依赖

真实 PostgreSQL / Redis / Kafka / NATS / OSS / ClickHouse / 生产网络 / 生产密钥 / x.go / 业务仓库

---

## 17. Performance Budget

| 操作 | 指标 | 目标 | 测量方式 |
|------|------|------|----------|
| New() | 延迟 P99 | < 1ms | `go test -bench` |
| Close() | 延迟 P99 | < 10ms | `go test -bench` |
| HealthCheck() | 延迟 P99 | < 5ms | `go test -bench` |
| render_template.sh | 执行时间 | < 30s | shell time |
| make ci | 执行时间 | < 120s | shell time |

---

## 18. Observability

### 18.1 Metrics

| 指标名 | 类型 | Label | 说明 |
|--------|------|-------|------|
| `client_created_total` | counter | [] | 客户端创建计数 |
| `client_closed_total` | counter | [] | 客户端关闭计数 |
| `client_errors_total` | counter | [op, kind] | 错误计数 |
| `client_health_status` | gauge | [status] | 健康状态 |
| `client_health_latency_ms` | histogram | [status] | 健康检查延迟 |

### 18.2 禁止 Labels

user_id, request_id, trace_id, span_id, order_id, tenant_id, account_id, email, phone, token, secret, password, dsn, url, endpoint

---

## 19. Security

- 不硬编码 secret、API key、密码、私钥
- 不在日志中记录敏感数据
- Sanitize 脱敏所有 secret/token/password/key/credential/dsn/url 字段
- check_security.sh 检查：AWS access key 形式密钥、私钥块、password/secret/token 明文赋值
- 不内置生产 endpoint

---

## 20. CI Gate

### 20.1 最小 Gate 集（9 个）

| Gate | 命令 | 通过条件 |
|------|------|----------|
| fmt | `go fmt ./...` | 零变更 |
| vet | `GOWORK=off go vet ./...` | 零警告 |
| lint | `golangci-lint run ./...` | 零警告 |
| test | `GOWORK=off go test ./...` | 全部通过 |
| race | `GOWORK=off go test -race ./...` | 无竞态 |
| contracts | `./scripts/check_contracts.sh` | contract 文件存在且 JSON 合法 |
| boundary | `./scripts/check_boundary.sh` | 无非法引用残留 |
| render-smoke | `./scripts/check_rendered_template.sh` | 渲染后模板可编译 |
| security | `./scripts/check_security.sh` | 无密钥泄露 |

### 20.2 CI 配置

```yaml
name: ci
on:
  pull_request:
  push:
    branches: [main]
permissions:
  contents: read
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
          cache: true
      - run: go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.1.6
      - run: GOWORK=off make ci
      - run: GOWORK=off make release-check
```

---

## 21. Upgrade Compatibility

| 变更类型 | 兼容性 | 迁移方式 |
|----------|--------|----------|
| 新增 ErrorKind | 向后兼容 | 无需迁移 |
| 删除 ErrorKind | Breaking | 更新所有 IsKind 调用 |
| 新增 Metrics label | 向后兼容 | 无需迁移 |
| 删除 Metrics label | Breaking | 更新所有指标注册 |
| Generator 参数变更 | Breaking | 更新调用脚本 |
| 新增 Config 字段（可选） | 向后兼容 | 无需迁移 |
| 新增 Config 字段（必填） | Breaking | 更新所有调用方 |

### 21.1 v1.0.0 Breaking Changes

- Generator 参数：`--module`/`--name`/`--package` → `--module-path`/`--package-name`/`--module-name`
- ErrorKind：删除 `conflict` 和 `rate_limit`（从 9 种减至 8 种）
- Metrics：从 9 个减至 5 个 P0 指标

---

## 22. Release DoD

- [ ] 所有 14 条 FR 实现完成
- [ ] 所有 24 个 TC 编写并全部通过
- [ ] 覆盖率 ≥ 80%
- [ ] 9 个 CI Gate 全部通过
- [ ] 生成库验收通过（render → test → grep 无残留）
- [ ] release manifest 生成且 checksum 校验通过
- [ ] 追溯矩阵更新完成
- [ ] spec 状态更新为 Implemented

---

## 23. Lifecycle

### 23.1 生命周期状态

| 状态 | 含义 | 进入条件 | 退出条件 |
|------|------|----------|----------|
| Draft | 初始起草 | 创建 | 评审通过 |
| Active | 生效中 | 评审通过 | 废弃 |
| Deprecated | 废弃 | 标记废弃 | 删除 |

### 23.2 变更策略

- Breaking change 需要主版本号升级
- 新增 FR 需要对应 TC 和 AC
- 删除 FR 需要更新 TRACEABILITY.md

---

## 24. Open Questions

### Blocking（阻塞开发）

无。

### Non-blocking（不阻塞开发）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-001 | 是否需要提供 L2 适配器专用模板？ | 已决定：v1.0.0 不做 | ZoneCNH |

### Future（未来考虑）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-002 | 是否引入 Goal Runtime（goalcli 二进制）？ | 待评估 | - |
| OQ-003 | 是否引入 Evidence Runtime？ | 待评估 | - |
| OQ-004 | 是否支持多语言模板（非 Go）？ | 待评估 | - |

---

## Appendix A: 关键数字

| 指标 | 值 |
|------|------|
| FR 数量 | 14 |
| BR 数量 | 7 |
| TC 数量 | 24 |
| ErrorKind 数量 | 8 |
| P0 Metrics 数量 | 5 |
| CI Gate 数量 | 9 |
| 目标消费者数 | 9 |
