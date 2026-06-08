# xlib-standard 子分析：Go 参考模板与 Generator

本文件是本地分析，不是可执行规格。覆盖 Go Reference Template 与 Generator 两类职责。

- Snapshot-Date: 2026-06-08
- Upstream-Commit: `93753b30e6d01fb4a9b096acaa0d7d53a2fb231c` (v0.6.5)
- Analysis-Version: v3.1.0
- Parent: ../ANALYSIS.md

## 1. 分析边界

- Go API、ErrorKind、metrics、HealthCheck 与 Config 行为来自上游 `docs/api.md`、`docs/errors.md`、`docs/observability.md`、`docs/config.md`。
- Generator 入口以 `docs/generation.md` 与 `docs/standard/template-generation-contract.md` 为来源。
- 本仓库没有 `scripts/render_template.sh`，因此只记录要求和风险，不执行模板验收。
- 本分析只摘要模板与生成器契约；完整 FR WHEN/THEN 详见 `../FR-DETAIL.md`。

## 2. 覆盖职责（FR 摘要）

### 2.1 Go Reference Template

> 权威来源：`../FR-DETAIL.md` FR-009..FR-014。

| FR | 名称 | 优先级 | 说明 |
|----|------|--------|------|
| FR-009 | 公共 API 模板 | P0 | 模板渲染生成完整公共 API，go vet 通过 |
| FR-010 | 9 种 ErrorKind | P0 | IsKind 可识别 9 种错误，WrapError 穿透匹配 |
| FR-011 | 9 个最小 metrics | P0 | 操作触发指标递增，Prometheus 返回 9 个指标 |
| FR-012 | HealthCheck JSON schema | P0 | HealthCheck 返回符合 schema 的 JSON |
| FR-013 | 配置显式传入 | P0 | 禁止隐式读取 secret-store-path，Sanitize 屏蔽 |
| FR-014 | 配置 Validate 和 Sanitize | P0 | Validate 返回 ErrorKindValidation，Sanitize 返回脱敏副本 |

### 2.2 Generator

> 权威来源：`../FR-DETAIL.md` FR-015..FR-019。

| FR | 名称 | 优先级 | 说明 |
|----|------|--------|------|
| FR-015 | render_template.sh 渲染 | P0 | 3 个占位符全部替换，目录结构完整 |
| FR-016 | 渲染范围全覆盖 | P0 | 覆盖 6 类文件，缺失则非零退出码 |
| FR-017 | Repository Governance Pack | P0 | --enable-governance 生成完整治理文件集 |
| FR-018 | make integration | P0 | 临时渲染 3 个下游库，编译通过 gate 全过 |
| FR-019 | Docker Toolchain Runtime 模板继承 | P1 | Docker 模板继承，工具链版本一致 |

## 3. 参考接口与模板契约

### 3.1 公共 API

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

#### 3.1.1 Go 参考签名（Template Reference）

下方 fenced block 是 text/template 源（使用 Go template 占位符），不是可直接 `go vet` 的 Go 源文件。模板渲染产物才是 FR-009 / FR-015 中 `go vet ./...` 的目标。

```gotemplate
package {{.Package}}

import (
    "context"
    "time"
)

type Config struct {
    // 由各模块自行定义具体字段；上游规格只约束方法集。
}

func (c *Config) Validate() error
func (c *Config) Sanitize() Config

type {{.Module}}Client interface {
    Close(ctx context.Context) error
    HealthCheck(ctx context.Context) (HealthStatus, error)
}

func New(ctx context.Context, cfg Config) ({{.Module}}Client, error)

type HealthStatus struct {
    Name      string         `json:"name"`
    Status    string         `json:"status"`
    Message   string         `json:"message,omitempty"`
    CheckedAt time.Time      `json:"checked_at"`
    LatencyMs int64          `json:"latency_ms"`
    Metadata  map[string]any `json:"metadata,omitempty"`
}

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

func NewError(kind ErrorKind, msg string) error
func WrapError(kind ErrorKind, cause error, msg string) error
func IsKind(err error, kinds ...ErrorKind) bool
func Metrics() []MetricDescriptor
func Version() string
```

### 3.2 模板约束

- 模板渲染入口：`scripts/render_template.sh --module <name> --package <pkg>`，替换 `{{.Module}}` / `{{.Package}}` 占位符；渲染产物路径不得落在本仓库内，边界见 `../SNAPSHOT-BOUNDARY.md` B-01。
- 接口最小化：`Client` 仅 `Close` + `HealthCheck` 两方法；其余 API 作为包级独立函数 / 类型提供。
- 所有方法 / 函数第一参数使用 `context.Context`（构造、Close、HealthCheck），返回值含 `error`。
- `Config.Validate()` 与 `Config.Sanitize()` 统一为 pointer 接收器读取 + 返回值类型副本；Sanitize 必须 deep copy。
- 禁止暴露 `float64` 表达金额；基座统一使用 `decimalx`，详见仓库根 `ARCHITECTURE.md`。
- 模板生成后必须通过 `GOWORK=off go vet ./...`。
- 需要 Go ≥ 1.18；模块根 `go.mod` 必须声明与工具链一致的 Go 版本。

### 3.3 Config Schema

上游模块作为标准源/模板/Harness/Evidence Runtime，自身不暴露生产业务配置。下游生成库的 Config Schema 由模板渲染产出，并满足以下硬性约束：

- **显式传入**：所有配置必须经构造函数显式注入；禁止隐式读取 `<secret-store-path>` 或任何生产路径。
- **Validate**：所有 Config 必须实现 `Validate() error`，无效配置返回 ErrorKindValidation。
- **Sanitize**：所有 Config 必须实现 `Sanitize() Config`，输出可入日志/Evidence；屏蔽 token / secret / password / private_key / 连接凭据。
- **配置拓扑**：v1.0.0 目标拓扑收敛到 `.config/`，当前路径边界见 `../SNAPSHOT-BOUNDARY.md` B-01。
- **Schema 校验**：registry / release artifact 必须通过 schema validation；缺失即 fail-closed。

### 3.4 错误处理

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

- 公共错误必须使用 `Error`/`NewError`/`WrapError` 表达稳定 contract。
- 包装错误必须保留 cause，支持 `errors.Is`/`errors.As`。
- 调用方按 `IsKind(err, ErrorKind...)` 做分支判断，不依赖错误字符串。
- 错误可纳入 Evidence，但不得包含原始凭据。

### 3.5 Generator 目录边界

```text
xlib-standard/
├── cmd/goalcli/          # 唯一 Go runtime 执行面
├── scripts/              # render_template.sh 等 helper
├── docs/standard/        # 标准文档，清单见 ../INDEX.md
├── contracts/            # goalcli-report.schema.json 等
├── .agent/               # 控制面
├── .xlib/                # facts（v1.0.0 前与 .agent 并存）
├── .config/              # v1.0.0 目标数据面
└── .worktree/            # 当前工作上下文与历史规划
```

下游生成库的目录结构由模板渲染保证；上游 `docs/standard/template-generation-contract.md` 是具体生成契约入口。

### 3.6 Docker Toolchain Runtime

Docker 模板只提供可复现工具链运行环境，不创建第二套 gate 或第二套质量声明。工具链 parity、build context、secret 传递和 Action pin 规则同时受 `docs/standard/docker-toolchain-standard.md` 与 supply-chain 规则约束。

### 3.7 可观测性最小指标

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

metrics label 不能包含高基数字段、用户凭据或业务私有标识；只能记录脱敏配置。

## 4. 边界场景 / 失败语义

### 4.1 调用者视角边界（Caller-Side Edge Cases）

| EC ID | 场景 | 触发条件 | 预期行为 | 对应 TC | 对应 FR |
|-------|------|----------|----------|---------|---------|
| EC-001 | nil context | `New(nil, cfg)` / `Close(nil)` / `HealthCheck(nil)` | 返回 ErrorKindValidation；禁止 panic | xlib-TC-002 | FR-014 |
| EC-002 | canceled / expired context | 传入 canceled context | 立即返回 ErrorKindTimeout 或 ErrorKindUnavailable；不发起远端连接 | xlib-TC-003 | FR-013 / FR-014 |
| EC-003 | 多次 / 并发 Close | 同一 client `Close()` 调用 N 次 | 幂等；底层资源只释放一次；无 race | xlib-TC-004 / xlib-TC-008 | FR-009 |
| EC-004 | 并发 New / Close | N goroutine 同时创建和关闭 | 无 race；无 FD/goroutine 泄漏 | xlib-TC-008 | FR-009 |
| EC-005 | 资源耗尽 | 连接池 / FD / 内存达到上限 | 返回 ErrorKindUnavailable 或 ErrorKindRateLimit；不 OOM | xlib-TC-016 | FR-010 |
| EC-006 | Sanitize 嵌套 nil map | `Config{Nested: nil}` 调用 `Sanitize()` | 返回有效 Config 副本；不 panic | xlib-TC-006 | FR-014 |
| EC-007 | HealthCheck 超时 | 下游不可达且 timeout 极短 | 返回 unhealthy / degraded；不挂起 | xlib-TC-005 | FR-012 |
| EC-008 | Validate 在 nil receiver | `var c *Config; c.Validate()` | 返回 ErrorKindValidation；禁止 panic | xlib-TC-017 | FR-014 |
| EC-009 | Sanitize 修改返回值不影响原对象 | 修改 `cfg.Sanitize()` 返回值 | 原对象字段不变；map/slice 不共享底层 | xlib-TC-007 | FR-014 |
| EC-010 | 隐式 secret 路径读取 | 设置生产 HOME 后零值配置构造 | enforcer 拒绝隐式读取；返回 ErrorKindConfig | xlib-TC-009 | FR-013 |

### 4.2 xlibgate 硬性失败（7 种）

1. secret_leak
2. layer_violation
3. missing_required_contract
4. missing_required_evidence
5. race_detected
6. goroutine_leak
7. release_level_overclaimed

## 5. 与其他子分析的交叉引用

| 主题 | 位置 |
|------|------|
| 规则源、安全规则和 debt gate | `analysis/rules.md` §3 |
| Gate Result Envelope、goalcli 与 release manifest | `analysis/runtime.md` §3 |
| AdoptionStatus、truth-state 与远端治理 | `analysis/governance.md` §3、§4 |
| 上游标准文档索引 | `../INDEX.md` §1 |
| 模板/生成器现实边界 | `../SNAPSHOT-BOUNDARY.md` B-01、B-09 |

## 6. TC / EC 命名空间

本文件定义 EC-001..EC-010 作为模板边界场景入口；对应测试编号统一引用 `analysis/runtime.md` §6 的 `xlib-TC-001..xlib-TC-017`。
