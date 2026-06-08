# xlib-standard 子分析：Go 参考模板与 Generator

本文件是本地分析，不是可执行规格。覆盖 Go Reference Template 与 Generator 两类职责。

## 1. 分析边界

- Go API、ErrorKind、metrics、HealthCheck 与 Config 行为来自上游 `docs/api.md`、`docs/errors.md`、`docs/observability.md`、`docs/config.md`。
- Generator 入口以 `docs/generation.md` 与 `docs/standard/template-generation-contract.md` 为来源。
- 本仓库没有 `scripts/render_template.sh`，因此只记录要求和风险，不执行模板验收。

### 7.2 Go 参考模板（Go Reference Template）

| FR | 名称 | 优先级 | 说明 |
|----|------|--------|------|
| FR-009 | 公共 API 模板 | P0 | 模板渲染生成完整公共 API，go vet 通过 |
| FR-010 | 9 种 ErrorKind | P0 | IsKind 可识别 9 种错误，WrapError 穿透匹配 |
| FR-011 | 9 个最小 metrics | P0 | 操作触发指标递增，Prometheus 返回 9 个指标 |
| FR-012 | HealthCheck JSON schema | P0 | HealthCheck 返回符合 schema 的 JSON |
| FR-013 | 配置显式传入 | P0 | 禁止隐式读取 secret-store-path，Sanitize 屏蔽 |
| FR-014 | 配置 Validate 和 Sanitize | P0 | Validate 返回 ErrorKindValidation，Sanitize 返回脱敏副本 |

### 7.3 Generator

| FR | 名称 | 优先级 | 说明 |
|----|------|--------|------|
| FR-015 | render\_template.sh 渲染 | P0 | 3 个占位符全部替换，目录结构完整 |
| FR-016 | 渲染范围全覆盖 | P0 | 覆盖 6 类文件，缺失则非零退出码 |
| FR-017 | Repository Governance Pack | P0 | \-\-enable-governance 生成完整治理文件集 |
| FR-018 | make integration | P0 | 临时渲染 3 个下游库，编译通过 gate 全过 |
| FR-019 | Docker Toolchain Runtime 模板继承 | P1 | Docker 模板继承，工具链版本一致 |

## 10. 接口契约（Interface Contract）

### 10.1 公共 API

| API | 说明 | 契约 |
|-----|------|------|
| `Config` | 配置结构体 | 必须支持 Validate 和 Sanitize |
| `Validate` | 验证配置 | 拒绝无效配置，返回 ErrorKindValidation |
| `Sanitize` | 脱敏配置 | 屏蔽 token/secret/password/key |
| `New` | 创建客户端 | 拒绝 nil/canceled/expired context |
| `Close` | 关闭客户端 | 必须幂等 |
| `HealthCheck` | 健康检查 | 返回 healthy/degraded/unhealthy |
| `Error` / `NewError` / `WrapError` | 错误构造 | 支持 errors.Is/errors.As |
| `Metrics` | 指标注册 | 9 个最小指标 |
| `Version` | 版本信息 | 返回模块版本 |

#### 10.1.1 Go 参考签名（Template Reference）

> **格式说明**：下方 fenced block 是 **text/template 源**（使用 Go template 占位符 `{{.Module}}` / `{{.Package}}`），不是可直接 `go vet` 的 Go 源文件。模板渲染产物（替换占位符后的 `.go` 文件）才是 §7 FR-009 / FR-015 中 `go vet ./...` 的目标。

```gotemplate
package {{.Package}}

import (
    "context"
    "time"
)

// Config 是模块对外配置结构体，所有字段必须可序列化且无生产 secret 默认值。
// 必须由调用方显式构造，禁止隐式读取生产路径（详见 §7 FR-013、§20）。
type Config struct {
    // 由各模块自行定义具体字段；本规格只约束方法集。
}

// Validate 校验配置；无效时必须返回 ErrorKindValidation 包装的 error
// （详见 §13.1 / FR-014）。
func (c *Config) Validate() error

// Sanitize 返回脱敏后的 Config 深拷贝（值类型），可安全写入日志、Evidence、Manifest。
// 必须屏蔽 token / secret / password / private_key / 连接凭据（XS-CORE-008）。
// 实现必须深拷贝所有引用类型字段（map/slice/pointer），不得共享底层数组。
func (c *Config) Sanitize() Config

// {{.Module}}Client 是公共客户端接口；本规格只约束最小方法集（Close + HealthCheck）。
// 其余 §10.1 表中声明的 API（Metrics / Version / Error 系列）按下方"独立函数 / 包级 API"
// 提供；模块特有方法由各下游 SPEC §10 自行扩展。
type {{.Module}}Client interface {
    // Close 释放资源，必须幂等（多次调用不报错）。
    Close(ctx context.Context) error

    // HealthCheck 返回当前健康状态。
    HealthCheck(ctx context.Context) (HealthStatus, error)
}

// New 构造客户端；context 不可为 nil/canceled/expired。
func New(ctx context.Context, cfg Config) ({{.Module}}Client, error)

// HealthStatus 与 §10.5 JSON Schema 对齐。
type HealthStatus struct {
    Name      string                 `json:"name"`
    Status    string                 `json:"status"` // healthy | degraded | unhealthy
    Message   string                 `json:"message,omitempty"`
    CheckedAt time.Time              `json:"checked_at"`
    LatencyMs int64                  `json:"latency_ms"`
    Metadata  map[string]any         `json:"metadata,omitempty"`
}

// ErrorKind 是 9 类错误枚举（详见 §13.1）。
type ErrorKind string

const (
    ErrorKindConfig      ErrorKind = "config"
    ErrorKindValidation  ErrorKind = "validation"
    ErrorKindConnection  ErrorKind = "connection"
    ErrorKindUnavailable ErrorKind = "unavailable"
    ErrorKindTimeout     ErrorKind = "timeout"
    ErrorKindAuth        ErrorKind = "auth"
    ErrorKindConflict    ErrorKind = "conflict"
    ErrorKindRateLimit   ErrorKind = "rate_limit"
    ErrorKindInternal    ErrorKind = "internal"
)

// 包级独立 API（不属于 Client 接口）：
//   NewError / WrapError / IsKind 构成稳定错误 contract，详见 §13.2。
//   Metrics 返回需注册到 observex 的 9 个最小指标定义（详见 §19.1）。
//   Version 返回模块语义化版本字符串（如 "v0.6.3"）。
func NewError(kind ErrorKind, msg string) error
func WrapError(kind ErrorKind, cause error, msg string) error
func IsKind(err error, kinds ...ErrorKind) bool
func Metrics() []MetricDescriptor
func Version() string
```

**约束**：

- 模板渲染入口：`scripts/render_template.sh --module <name> --package <pkg>`，替换 `{{.Module}}` / `{{.Package}}` 占位符；渲染产物路径不得落在本仓库内（详见 §7 FR-015 / §23.6.4）。
- 接口最小化（`Client` 仅 `Close` + `HealthCheck` 两方法）；其余 §10.1 表中的 API 作为**包级独立函数 / 类型**（`New / Validate / Sanitize / NewError / Metrics / Version`），不强制塞入 Client 接口。
- 所有方法 / 函数第一参数 `context.Context`（构造、Close、HealthCheck），返回值含 `error`。
- 接收器一致性：`Config.Validate()` 与 `Config.Sanitize()` 统一为 **pointer 接收器读取 + 返回值类型副本**；Sanitize 必须做 deep copy（不得共享 map/slice 底层数组）。
- 禁止暴露 `float64` 表达金额（基座统一使用 `decimalx`，详见 ARCHITECTURE.md）。
- 模板生成后必须通过 `GOWORK=off go vet ./...`（FR-009 / FR-015）。
- 需要 Go ≥ 1.18（`map[string]any` 别名）；模块根 `go.mod` 必须声明 `go 1.23` 与 `.tool-versions` 一致（§1 元信息）。

### 10.2 Gate Result Envelope

```json
{
  "schema_version": "1.0",
  "goal_id": "GOAL-...",
  "gate_id": "...",
  "status": "passed|failed|planned|gap",
  "exit_code": 0,
  "timestamp": "2026-06-07T...",
  "evidence_path": "..."
}
```

### 10.3 Exit Code 契约

| 退出码 | 含义 |
|--------|------|
| 0 | passed |
| 1 | failed/planned/gap |
| 2 | 非法参数 |
| 3-9 | 保留 |

### 10.4 goalcli CLI Contract

| 字段 | 要求 |
|------|------|
| 输出格式 | JSON report 符合 goalcli-report.schema.json |
| status=passed | 返回 0 |
| status=failed/planned/gap | 返回 1 |
| --verify/--strict | 遇到 planned/gap 必须阻断 |
| P0 commands | 68 个必须实现 |
| P1 commands | 26 个必须实现 |
| P2 commands | 12 个必须实现 |
| 14 个 surface | 必须同批同步 |

> 注：v0.2.0 gap ledger 中有 5 个命令处于 pending 状态（score-gate、proof-replay、depth-report、conformance-check、standard-impact-report），待后续 PR 实现。

### 10.5 HealthCheck JSON Schema

```json
{
  "name": "string",
  "status": "healthy|degraded|unhealthy",
  "message": "string",
  "checked_at": "2026-06-07T...",
  "latency_ms": 0,
  "metadata": {}
}
```

---

## 12. Config Schema（配置 Schema）

> 本模块作为标准源/模板/Harness/Evidence Runtime，自身不暴露生产业务配置。下游生成库的 Config Schema 由 `scripts/render_template.sh` 渲染产出，并满足以下硬性约束：

- **显式传入**：所有配置必须经构造函数显式注入；禁止隐式读取 ``<secret-store-path>`` 或任何生产路径（详见 §7 FR-013、§20 安全）。
- **Validate**：所有 Config 必须实现 `Validate() error`，无效配置返回 `ErrorKindValidation`（详见 §7 FR-014）。
- **Sanitize**：所有 Config 必须实现 `Sanitize() Config`，输出可入日志/Evidence；屏蔽 `token / secret / password / private_key / 连接凭据`（XS-CORE-008）。
- **配置拓扑**：v1.0.0 目标拓扑收敛到 `.config/` 18 个命名空间，见 §11.8 与 §22 迁移。
- **Schema 校验**：registry / release artifact 必须通过 schema validation；缺失即 fail-closed（详见上游 schema validation 规则）。

完整字段表见各下游模块自身 ANALYSIS.md 的 §11；本规格只定义 schema 约束。

---

## 13. 错误处理（Error Handling）

### 13.1 ErrorKind（9 种）

| ErrorKind | Retryable | 说明 |
|-----------|-----------|------|
| config | 否 | 配置错误 |
| validation | 否 | 验证失败 |
| connection | 视场景 | 连接错误 |
| unavailable | 视场景 | 服务不可用 |
| timeout | 是 | 超时 |
| auth | 否 | 认证失败 |
| conflict | 否 | 冲突 |
| rate_limit | 是 | 限流 |
| internal | 否 | 内部错误 |

### 13.2 错误规则

- 公共错误必须使用 `Error`/`NewError`/`WrapError` 表达稳定 contract
- 包装错误必须保留 cause，支持 `errors.Is`/`errors.As`
- 调用方按 `IsKind(err, ErrorKind...)` 做分支判断，不依赖错误字符串
- 错误可纳入 Evidence，但不得包含原始凭据

### 13.3 xlibgate 硬性失败（7 种）

1. secret_leak
2. layer_violation
3. missing_required_contract
4. missing_required_evidence
5. race_detected
6. goroutine_leak
7. release_level_overclaimed

---

### 14.1 调用者视角边界（Caller-Side Edge Cases）

> 下游模块在自身 §14 沿用并扩展。本表为 Go 参考模板的最小集，对应 §10.1.1 接口签名。

| EC ID | 场景 | 触发条件 | 预期行为 | 对应 TC | 对应 FR |
|-------|------|----------|----------|---------|---------|
| EC-001 | nil context | `New(nil, cfg)` / `Close(nil)` / `HealthCheck(nil)` | 返回 `ErrorKindValidation`；禁止 panic | xlib-TC-002 | FR-014 |
| EC-002 | canceled / expired context | 传入 `ctx, _ := context.WithCancel(...); cancel(); New(ctx, cfg)` | 立即返回 `ErrorKindTimeout` 或 `ErrorKindUnavailable`；不发起远端连接 | xlib-TC-003 | FR-013 / FR-014 |
| EC-003 | 多次 / 并发 Close | 同一 client `Close()` 调用 N 次（N≥2），允许并发 | 幂等：每次返回 nil；底层资源只释放一次；无 race | xlib-TC-004 / xlib-TC-008 | FR-009 |
| EC-004 | 并发 New / Close | N goroutine 同时 `New(ctx, cfg)` 然后 `Close(ctx)` | 无 race（`go test -race` 通过）；无 FD/goroutine 泄漏（XS-CORE-011） | xlib-TC-008 | FR-009 |
| EC-005 | 资源耗尽 | 连接池 / FD / 内存达到上限 | 返回 `ErrorKindUnavailable` 或 `ErrorKindRateLimit`；保留 cause；不 OOM | xlib-TC-016 | FR-010 |
| EC-006 | Sanitize 嵌套 nil map | `Config{Nested: nil}` 调用 `Sanitize()` | 返回有效 Config 副本；不 panic；nil 字段保持 nil | xlib-TC-006 | FR-014 |
| EC-007 | HealthCheck 超时 | 下游不可达，传入 `timeoutCtx` (timeout=1ms) | 返回 `status=unhealthy / degraded`；`latency_ms ≤ timeout+epsilon`；不挂起 | xlib-TC-005 | FR-012 |
| EC-008 | Validate 在 nil receiver | `var c *Config; c.Validate()` | 返回 `ErrorKindValidation`；禁止 panic（防御性检查） | xlib-TC-017 | FR-014 |
| EC-009 | Sanitize 修改返回值不影响原对象 | `s := cfg.Sanitize(); s.X = ...` | 原 `cfg` 字段不变；map/slice 不共享底层 | xlib-TC-007 | FR-014 / XS-CORE-008 |
| EC-010 | 隐式 secret 路径读取 | 设置 `$HOME=/home/k8s` 后调用 `New(ctx, Config{})` 试图读取生产 secret | enforcer 拒绝隐式读取；返回 `ErrorKindConfig`；详见 §20.1 XS-CORE-016 | xlib-TC-009 | FR-013 |

## 15. Directory Structure（目录结构）

> xlib-standard 自身目录结构以上游 `github.com/ZoneCNH/xlib-standard` 仓库为权威；本规格只声明顶层约束：

```text
xlib-standard/
├── cmd/goalcli/          # 唯一 Go runtime 执行面
├── scripts/              # render_template.sh 等 helper
├── docs/
│   ├── standard/         # 27 个标准文档（详见 §C.1）
│   ├── adr/              # 9 个正式 ADR + 1 模板 + 3 历史（详见 §C.2）
│   ├── l2/               # L2 适配器执行计划
│   ├── testing/          # L2 测试与 evidence 标准
│   └── evidence/         # Evidence 协议补充
├── contracts/            # goalcli-report.schema.json 等
├── .agent/               # 控制面（registries / policies / inbox / evidence ledger）
├── .xlib/                # facts（v1.0.0 前与 .agent 并存）
├── .config/              # v1.0.0 目标数据面（18 命名空间，详见 §11.8）
└── .worktree/            # 当前工作上下文与历史规划
```

下游生成库的目录结构由模板渲染保证（详见 §7 FR-015~017）。

---

### 18.4 模板渲染性能

- `scripts/render_template.sh` 单次渲染 < 10 秒
- `make integration`（渲染 3 个临时下游库）< 2 分钟
- 并行渲染时文件锁必须互斥

---

## 19. 可观测性（Observability）

### 19.1 最小指标（9 个）

| 指标 | 类型 | 说明 |
|------|------|------|
| client_created_total | counter | 客户端创建 |
| client_closed_total | counter | 客户端关闭 |
| client_errors_total | counter | 错误计数 |
| client_health_status | gauge | 健康状态 |
| client_health_latency_ms | histogram | 健康检查延迟 |
| client_requests_total | counter | 请求计数 |
| client_request_duration_seconds | histogram | 请求延迟 |
| client_retries_total | counter | 重试计数 |
| client_inflight | gauge | 进行中请求 |

### 19.2 Metrics 规则

- metrics label 不能包含高基数字段、用户凭据或业务私有标识（XS-CORE-009）
- 只能记录脱敏配置，不得记录原始凭据

---

## 10. TC 命名空间说明

本分析中的测试用例统一使用 `xlib-TC-001..xlib-TC-017`。下游模块复用时必须改成 `<module>-TC-NNN`，并标注继承自 `xlib-standard`。
