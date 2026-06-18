# configx 规格

- Status: Approved
- Spec-Version: v1.1.0
- Last-Updated: 2026-06-18
- Layer: L1 基础能力
- Version: v1.1.0
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `kernel`

> v1.1.0（2026-06-18 发布）完整交付 goal.md §文首状态戳列出的 v1.0 路线 5 项 MUST：ArgsSource、RemoteSource SPI、Bind()、ConfigSnapshot/ChangeEvent/Watch/Rollback、配置文档自动生成。本 SPEC 通过 TRACEABILITY.md v3.1 追加 FR-014~018、BR-012、NFR-007、TC-010~014、AC-006~010 完整登记 v1.1 新能力；现有 FR-001~013/BR-001~011 保持不变以维持向后兼容。

> 公开投影 caveat：Status=Approved 与 96.5% 覆盖证据不等同于 factory-grade；机器事实层保持 factory=false。

---

## 1. 摘要

`configx` 提供显式、可审计的 Go 配置管理原语。调用方显式选择每种配置源和加载路径。库不执行隐式发现、不创建全局状态、不注册单例、不强依赖任何驱动包或 x.go 模块。

核心能力：多源加载（文件/环境变量/map）、LastWins 合并策略、StrictDecode（未知字段/重复 key/类型错误 fail-fast）、SecretString 自动脱敏、SecretPolicy 可配置密钥检测、Provenance 来源追踪、EffectiveConfigHash（SHA-256）、SanitizedManifest 安全快照、HealthCheck、Metrics。

---

## 2. 问题与背景

70+ 模块各自加载配置，格式不统一、覆盖优先级不明确、缺少验证，导致：

- 同一配置在不同模块中 key 名不同
- 环境变量和文件冲突时行为不确定
- 配置错误在运行时才发现，定位困难
- 敏感值（密码/token）会泄露到日志和错误消息中

---

## 3. 目标

- 显式配置加载：调用方选择每种 Source，无隐式发现
- LastWins 合并策略：后加载的源覆盖先加载的同名 key
- StrictDecode：未知字段、重复 key、类型错误 fail-fast
- SecretString 自动脱敏：所有格式化输出（String/JSON/GoString/TextMarshal）自动替换为 `***`
- SecretPolicy 可配置：默认匹配 password/token/secret/_key/credential/auth，支持 CustomMatcher 扩展
- Provenance 追踪：每个 key 记录 source、priority、override 链路
- EffectiveConfigHash：SHA-256 指纹，排除 volatile 字段
- 并发安全：Client 和 Loader 均使用 sync.RWMutex 保护
- 无全局状态：无进程级 config singleton

---

## 4. 非目标

- 不做隐式配置发现（无 auto-scan、无约定目录）
- 不做远程配置中心产品（K8s ConfigMap 可通过文件挂载）
- 不做敏感信息加密存储（→ 环境变量或 secret manager）
- 不做跨服务配置同步
- 不做运行时配置热更新（Watch 特性）
- 不做配置文档自动生成

---

## 5. 消费者

| 消费者                                           | 使用方式                                          |
| ------------------------------------------------ | ------------------------------------------------- |
| L1 运行时模块（observex, resiliencx, schedulex） | 通过 `configx.New(ctx, cfg, opts...)` 创建 Client |
| 业务域模块                                       | 通过 Client 或直接使用 Loader/Source API          |
| `x.go` 组合根                                    | 创建 Config 实例，注入到各模块                    |
| 存储扩展（redisx, kafkax 等）                    | 通过 Loader + FileSource/EnvSource 加载连接配置   |

---

## 6. 功能需求

### FR-001: Client 创建与生命周期

WHEN 调用 `configx.New(ctx, cfg, opts...)` 且 ctx 有效、cfg.Validate() 通过
THEN 返回初始化的 `*Client`，metrics 计数器 `client_created_total` +1

WHEN 调用 `configx.New(ctx, cfg, opts...)` 且 ctx 为 nil
THEN 返回 validation error，metrics 记录错误

WHEN 调用 `client.Close(ctx)` 且 ctx 有效
THEN 标记 client 为已关闭，metrics 计数器 `client_closed_total` +1

### FR-002: Loader + Source 模式

WHEN 调用 `NewLoader(opts...).AddSource(src).Load(ctx)`
THEN 按添加顺序加载所有 Source，LastWins 合并，返回 `LoadResult`

WHEN 调用 `NewLoader(WithFailFast(true))` 且某个 Source 加载失败
THEN 立即返回错误，不继续加载后续 Source

WHEN 调用 `NewLoader(WithMergeStrategy(LastWins))`
THEN 后加载的 Source 的同名 key 覆盖先加载的值

### FR-003: FileSource — YAML / TOML / JSON / .env

WHEN 调用 `NewYAMLFileSource(path)` 并 Load
THEN 解析 YAML 文件，返回 key-value Map

WHEN 调用 `NewTOMLFileSource(path)` 并 Load
THEN 解析 TOML 文件，返回 key-value Map

WHEN 调用 `NewJSONFileSource(path)` 并 Load
THEN 解析 JSON 文件，返回 key-value Map

WHEN 调用 `NewEnvFileSource(path)` 并 Load
THEN 解析 .env 格式文件，返回 key-value Map

### FR-004: EnvSource — 环境变量

WHEN 调用 `NewEnvSource(prefix, keys)` 并 Load
THEN 读取指定 keys 的环境变量值（prefix_KEYNAME），返回 Map

WHEN 调用 `NewAllEnvSource(prefix)` 并 Load
THEN 读取所有 prefix_ 前缀的环境变量，返回 Map

### FR-005: MapSource — 字符串 map

WHEN 调用 `NewMapSource(name, map[string]string{...})` 并 Load
THEN 将 map 转换为配置 Map，source name 用于 provenance

### FR-006: StrictDecode

WHEN 调用 `StrictDecode(data, &target)` 且 JSON 包含未知字段
THEN 返回错误（默认拒绝未知字段）

WHEN 调用 `StrictDecode(data, &target, WithAllowUnknownFields())`
THEN 忽略未知字段，正常解码

WHEN 调用 `StrictDecode(data, &target, WithMaxDepth(n))` 且嵌套深度超过 n
THEN 返回深度超限错误

### FR-007: SecretString 自动脱敏

WHEN 对 SecretString 调用 `.String()` / `.GoString()` / `json.Marshal()` / `MarshalText()`
THEN 返回 `"***"`，不泄露原始值

WHEN 调试时需要原始值
THEN 显式调用 `.Reveal()` 返回原始字符串

### FR-008: SecretPolicy 密钥检测

WHEN 调用 `DefaultSecretPolicy().IsSecret(key)` 且 key 匹配默认模式
THEN 返回 true（默认模式：secret/password/passwd/token/_key/credential/auth）

WHEN 创建 `SecretPolicy{CustomMatcher: fn}` 且 fn 返回 true
THEN IsSecret 返回 true（CustomMatcher 与 Pattern 匹配并行）

### FR-009: Provenance 来源追踪

WHEN 配置加载完成后调用 `Provenance.Snapshot()`（或 `Get(key)` 查单个 key）
THEN 每个 key 返回其 Source、Priority、OverrideEntry 链路

WHEN 同一个 key 被多个 Source 覆盖
THEN OverrideEntry 记录每次覆盖的 Source、OldValue、NewValue

### FR-010: EffectiveConfigHash

WHEN 调用 `EffectiveConfigHash(cfg)` 且 cfg 为 LoadResult
THEN 返回 SHA-256 hex digest（按 key 排序，排除 volatile 字段）

WHEN 相同配置值两次调用
THEN 返回相同的 hash（可复现）

### FR-011: SanitizedManifest

WHEN 调用 `SanitizedManifest(cfg)` 且 cfg 包含敏感字段
THEN 敏感字段值替换为 `"***"`，非敏感字段保留原值

WHEN cfg 为 nil
THEN 返回 nil

### FR-012: HealthCheck

WHEN 调用 `client.HealthCheck(ctx)`
THEN 返回 HealthStatus{Status: healthy/degraded/unhealthy, CheckedAt, LatencyMs}

### FR-013: Metrics

WHEN 创建 Client 或执行操作
THEN 通过 Metrics 接口输出 counter/histogram/gauge（8 个标准指标名）

WHEN 未配置 Metrics
THEN 使用 NoopMetrics（零开销空实现）

---

## 7. 行为约束

| 编号 | 规则 | 违反时 |
| --- | --- | --- |
| BR-001 | 合并策略：LastWins — 后加载的 Source 覆盖先加载的同名 key | 合并覆盖排序错误视为 bug |
| BR-002 | Config.Name 必须非空（Validate 时检查） | 返回 `*Error{Kind: validation}`，Op=`Config.Validate`，Message 含字段 name |
| BR-003 | Config.Timeout 必须 ≥ 0（负数拒绝） | 返回 `*Error{Kind: validation}`，Op=`Config.Validate`，Message 含字段 timeout |
| BR-004 | 配置加载显式：调用方必须显式 AddSource 每个 Source，无隐式文件扫描/约定目录发现 | `TestNoImplicitConfigDiscovery` 单测验证——任何隐式发现路径即测试失败 |
| BR-005 | SecretString 在所有格式化输出中自动脱敏（String/JSON/GoString/Text） | TC-003 验证——任何格式化输出出现原始值即测试失败 |
| BR-006 | SecretPolicy 默认匹配 7 种模式，支持 CustomMatcher 扩展 | TC-005 验证——自定义匹配器不生效即测试失败 |
| BR-007 | StrictDecode 默认拒绝未知字段和重复 key | 返回解码错误，包含未知字段名——TC-002 验证 |
| BR-008 | 公共错误使用 `*Error` 结构体 + `ErrorKind` 枚举（不使用 sentinel var），`Error()` 输出含 Kind 语义前缀 | `errors.As(err, &*Error{})` 可提取 Kind/Op/Cause——单测验证 |
| BR-009 | 无全局状态：无包级 `var Client` / 无进程级 config singleton / 无 init() 副作用 | 源码静态检查：`grep -nE "var .*(Client|config|Config)\b" pkg/configx/*.go` 无可变包级单例；单测 `TestNoImplicitConfigDiscovery` 覆盖 |
| BR-010 | Release 制品通过全部 CI Gate（编译/测试/覆盖率/vet/lint/secret） | CI Gate 任一失败阻断发布 |
| BR-011 | context.Context 必须非 nil 且未过期（所有公开 API 强制检查） | 返回 `*Error`（ctx nil→validation，超时→timeout）——TC-008 验证 |

> **注（BR-004 / BR-009 修订）**：此前两行均引用虚构的 `NoGlobalStateGate CI 门禁`，该门禁在运行时仓库无对应 CI 步骤。已拆分语义：BR-004 聚焦「显式 AddSource」由 `TestNoImplicitConfigDiscovery` 验证；BR-009 聚焦「无可变包级单例」由源码静态检查验证。若未来引入真实 NoGlobalStateGate analyzer，可在此登记。
>
> **注（BR-008 修订）**：此前要求「错误变量使用 `configx:` 字面前缀」，但运行时 `errors.go` 实际采用 `ErrorKind` 枚举 + `*Error` 结构，`Error()` 输出形如 `"validation: configx.New: ..."`，前缀是 Kind 名而非 `configx:` 字面量。本条已按运行时事实重述。

---


### Acceptance Criteria Registry

| AC     | 所属 FR/BR                 | Task        | 验收条件摘要                                    |
| ------ | -------------------------- | ----------- | ----------------------------------------------- |
| AC-001 | FR-002~005, BR-001         | 002/003/004 | Loader+Source 正确加载合并，LastWins 语义       |
| AC-002 | FR-006, BR-007             | 005         | StrictDecode 拒绝未知字段/重复key/类型错误      |
| AC-003 | FR-007/008/011, BR-005/006 | 010         | SecretString + SecretPolicy + SanitizedManifest |
| AC-004 | FR-009/010/012             | 006         | Provenance + Hash + HealthCheck                 |
| AC-005 | FR-001/013, BR-008~011     | 000/001/009 | Client 生命周期 + Metrics + CI Gate             |
## 8. 接口契约

### 8.1 Client — 配置客户端

```go
type Client struct { /* 内部字段 */ }

func New(ctx context.Context, cfg Config, opts ...Option) (*Client, error)
func (c *Client) Close(ctx context.Context) error
func (c *Client) HealthCheck(ctx context.Context) HealthStatus
```

### 8.2 Config — 客户端配置

```go
type Config struct {
    Name    string        // 必填，客户端名称
    Timeout time.Duration // 必须 ≥ 0
    Secret  string        // 可选，敏感凭证（自动脱敏）
}

func (c Config) Validate() error
func (c Config) Sanitize() SanitizedConfig
```

### 8.3 Loader + Source — 配置加载

```go
type Source interface {
    Name() string
    Kind() string
    Load(ctx context.Context) (Map, error)
}

type Loader struct { /* 内部字段 */ }

func NewLoader(opts ...LoaderOption) *Loader
func (l *Loader) AddSource(src Source) *Loader
func (l *Loader) Load(ctx context.Context) (LoadResult, error)
```

### 8.4 内置 Source

```go
func NewYAMLFileSource(path string, opts ...SourceOption) Source
func NewTOMLFileSource(path string, opts ...SourceOption) Source
func NewJSONFileSource(path string, opts ...SourceOption) Source
func NewEnvFileSource(path string, opts ...SourceOption) Source
func NewEnvSource(prefix string, keys []string, opts ...SourceOption) Source
func NewAllEnvSource(prefix string, opts ...SourceOption) Source
func NewMapSource(name string, values map[string]string, opts ...SourceOption) Source
```

### 8.5 便捷函数

```go
func LoadEnv(ctx context.Context, prefix string, keys []string) (LoadResult, error)
func LoadAllEnv(ctx context.Context, prefix string) (LoadResult, error)
func LoadEnvFile(ctx context.Context, path string) (LoadResult, error)
func LoadJSONFile(ctx context.Context, path string) (LoadResult, error)
func LoadMap(ctx context.Context, name string, values map[string]string) (LoadResult, error)
```

### 8.6 Option 模式

```go
type Option func(*options)
func WithMetrics(metrics Metrics) Option

type LoaderOption func(*loaderOptions)
func WithMergeStrategy(strategy MergeStrategy) LoaderOption
func WithFailFast(failFast bool) LoaderOption

type StrictOption func(*strictOptions)
func WithAllowUnknownFields() StrictOption
func WithMaxDepth(n int) StrictOption

type SourceOption func(*sourceOptions)
func WithSourceName(name string) SourceOption
```

---

## 9. 数据模型

### 9.1 核心类型

```go
type Value struct {
    Key        string
    Value      string
    Secret     bool
    Source     string
    LoadedAt   time.Time
    Overridden bool
}

type Map map[string]Value

type LoadResult struct {
    Values   Map
    Sources  []SourceReport
    LoadedAt time.Time
}

type SourceReport struct {
    Name      string
    Kind      string
    Path      string
    Loaded    bool
    Error     string
    LoadedAt  time.Time
    ValueKeys []string
}
```

### 9.2 SecretString

```go
type SecretString string

func NewSecretString(value string) SecretString
func (s SecretString) String() string    // → "***"
func (s SecretString) Reveal() string    // → 原始值
func (s SecretString) Sanitize() any     // → "***"
func (s SecretString) GoString() string  // → "***"
func (s SecretString) MarshalText() ([]byte, error)   // → "***"
func (s SecretString) MarshalJSON() ([]byte, error)   // → "\"***\""
```

### 9.3 SecretPolicy

```go
type SecretPolicy struct {
    Patterns      []string           // 默认: secret/password/passwd/token/_key/credential/auth
    CustomMatcher func(key string) bool
}

func DefaultSecretPolicy() *SecretPolicy
func (sp *SecretPolicy) IsSecret(key string) bool
```

### 9.4 Provenance

```go
type Provenance struct { /* 内部 map，sync.RWMutex 保护 */ }

func NewProvenance() *Provenance
func (p *Provenance) Record(key, source string, priority int)
func (p *Provenance) RecordOverride(key, newSource string, priority int, oldValue, newValue string)
func (p *Provenance) Get(key string) (ProvenanceEntry, bool)
func (p *Provenance) Snapshot() map[string]ProvenanceEntry  // 全量拷贝，按 key
func (p *Provenance) Keys() []string                         // 排序后的 key 列表
func (p *Provenance) Reset()
```

> **实现提示**：`Loader.Load()` 返回的 `LoadResult` 当前**不自动内嵌** Provenance；调用方如需来源链路，需自行持有一个 `*Provenance` 并在加载后调用 `Record/RecordOverride`。把 Provenance 接入 LoadResult 属于待办增强（与 FR-009「每个 key 自动记录来源」的完整闭合相关）。

### 9.5 公共错误

configx **不使用** sentinel `ErrXxx` 变量，而是采用 `ErrorKind` 枚举 + `*Error` 结构体模式，支持 `errors.As` / `errors.Is` 标准库语义。

```go
type ErrorKind string

const (
    ErrorKindConfig        ErrorKind = "config"
    ErrorKindValidation    ErrorKind = "validation"
    ErrorKindConnection    ErrorKind = "connection"
    ErrorKindUnavailable   ErrorKind = "unavailable"
    ErrorKindTimeout       ErrorKind = "timeout"
    ErrorKindAuth          ErrorKind = "auth"
    ErrorKindConflict      ErrorKind = "conflict"
    ErrorKindRateLimit     ErrorKind = "rate_limit"
    ErrorKindCanceled      ErrorKind = "canceled"
    ErrorKindNotFound      ErrorKind = "not_found"
    ErrorKindAlreadyExists ErrorKind = "already_exists"
    ErrorKindInternal      ErrorKind = "internal"
)

type Error struct {
    Kind      ErrorKind
    Op        string   // 操作名，如 "configx.New"
    Message   string
    Cause     error
    Retryable bool
}

// 构造与判别 API
func NewError(kind ErrorKind, op string, message string, retryable bool) *Error
func WrapError(kind ErrorKind, op string, message string, retryable bool, cause error) *Error
func (e *Error) Error() string   // 输出 "<kind>: <op>: <message>"
func (e *Error) Unwrap() error   // 返回 Cause，支持 errors.Unwrap 链
func IsKind(err error, kind ErrorKind) bool  // 类型安全的 Kind 判别
```

**典型使用：**

```go
client, err := configx.New(ctx, cfg)
var e *configx.Error
if errors.As(err, &e) {
    switch e.Kind {
    case configx.ErrorKindValidation:
        // 配置非法，检查字段
    case configx.ErrorKindTimeout, configx.ErrorKindUnavailable:
        // ctx 超时或取消，可重试（e.Retryable == true）
    }
}
if configx.IsKind(err, configx.ErrorKindValidation) {
    // 等价的类型安全判别
}
```

---

## 10. 配置模式

configx 自身的 Client 配置：

```yaml
config:
  name: my-service          # 必填，客户端名称
  timeout: 30s              # 必须 ≥ 0
  secret: ${CONFIGX_SECRET} # 可选，自动脱敏
```

---

## 11. 错误处理

configx 错误统一为 `*Error`（见 §9.5）。调用方通过 `errors.As` 或 `IsKind` 判别 `ErrorKind` 后选择处理策略：

| ErrorKind              | 典型触发场景                                   | 调用方处理                                       |
| ---------------------- | ---------------------------------------------- | ------------------------------------------------ |
| `validation`           | Config.Name 空、Timeout<0、ctx nil、Decode 失败 | 检查具体字段路径，修复配置后重试（不可重试）     |
| `timeout`              | ctx.DeadlineExceeded                            | 检查上游超时设置，可重试（Retryable=true）       |
| `unavailable`          | ctx.Canceled、Source 不可达                     | 检查 ctx 取消原因或重试加载                      |
| `config`               | 配置文件格式非法、StrictDecode 拒绝未知字段     | 检查文件格式和内容，修复后重试                   |
| `not_found`            | key 不存在                                      | 检查 key 拼写或补充 Source                        |
| `internal`             | 未分类错误（兜底 Kind）                         | 记录日志并上报，联系维护者                       |

**错误消息格式：** `"<kind>: <op>: <message>"`（如 `"validation: configx.New: name is required"`）
**Validation 错误：** `Op` 含操作名（如 `Config.Validate`），`Message` 含字段与原因
**上下文错误：** ctx nil → `validation`；ctx 超时 → `timeout`（Retryable=true）；ctx 取消 → `unavailable`
**Retryable 字段：** 调用方可读取 `e.Retryable` 决定是否重试，无需硬编码 Kind 列表

---

## 12. 边界情况

| 场景                              | 预期行为                        |
| --------------------------------- | ------------------------------- |
| 空配置文件                        | 返回空 Map，不报错              |
| 配置文件只有注释                  | 返回空 Map                      |
| 环境变量值为空字符串              | 视为设置空值（非未设置）        |
| 点分路径的中间节点不存在          | 自动创建中间节点                |
| 并发 Load + HealthCheck           | sync.RWMutex 保护，并发安全     |
| 超大配置文件（>10MB）             | 正常解析                        |
| 配置文件读取超时（NFS/网络挂载）  | ctx 超时后返回错误              |
| 配置加载失败的调用方重试          | Load 失败后状态不变，可安全重试 |
| 并发 Load 竞态                    | Loader.mu 保护，线程安全        |
| nil Client 调用 Close/HealthCheck | 返回 validation error，不 panic |

---

## 13. 目录结构

```text
configx/
├── go.mod                     # module github.com/ZoneCNH/configx, go 1.23
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── Makefile
├── .golangci.yml              # 8 linter: govet/ineffassign/staticcheck/errcheck/gosec/unconvert/unparam/misspell
├── pkg/
│   └── configx/
│       ├── doc.go             # package doc
│       ├── client.go          # Client (New, Close)
│       ├── config.go          # Config, SanitizedConfig
│       ├── core.go            # SecretString, LoadEnv/LoadAllEnv/LoadEnvFile/LoadJSONFile/LoadMap
│       ├── loader.go          # Loader, LoaderOption
│       ├── source.go          # Source interface, SourceOption
│       ├── source_file.go     # YAML/TOML/JSON/Env file sources
│       ├── source_env.go      # EnvSource, AllEnvSource
│       ├── source_map.go      # MapSource
│       ├── merge.go           # MergeStrategy, LastWins
│       ├── strict.go          # StrictDecode, StrictOption
│       ├── secret.go          # secret sanitization
│       ├── secretpolicy.go    # SecretPolicy, DefaultSecretPatterns
│       ├── provenance.go      # Provenance, ProvenanceEntry, OverrideEntry
│       ├── hash.go            # EffectiveConfigHash, canonicalJSON
│       ├── manifest.go        # SanitizedManifest, isSensitiveFieldName
│       ├── result.go          # Value, Map, LoadResult, SourceReport
│       ├── validation.go      # Validator
│       ├── health.go          # HealthCheck, HealthStatus
│       ├── metrics.go         # Metrics interface, NoopMetrics, metric names
│       ├── options.go         # Option, WithMetrics
│       ├── errors.go          # 公共错误变量
│       └── version.go         # Version = "v0.1.3"
├── internal/
│   ├── runtime/               # 内部运行时辅助
│   └── tools/                 # 内部工具
├── examples/
│   └── error-handling/        # 5 种错误处理模式示例
├── testdata/                  # 测试 fixtures
├── testkit/                   # 测试辅助
├── contracts/                 # API 契约
├── docs/                      # ADR 文档（3 篇）
├── scripts/                   # CI/发布脚本
└── release/                   # 发布配置
```

---

## 14. 依赖

### 14.1 go.mod

```text
module github.com/ZoneCNH/configx

go 1.23

require (
    github.com/pelletier/go-toml/v2 v2.3.1
    gopkg.in/yaml.v3 v3.0.1
)
```

### 14.2 依赖方向

| 可以依赖                          | 禁止依赖                                  |
| --------------------------------- | ----------------------------------------- |
| stdlib                            | observex, resiliencx, schedulex, testkitx |
| `gopkg.in/yaml.v3`                | 所有业务域实现                            |
| `github.com/pelletier/go-toml/v2` | `kernel`（foundationx exit 已完成）       |
| —                                 | 所有存储/中间件扩展                       |

---

## 15. 测试

### 15.1 测试统计

| 指标       | 数值                     |
| ---------- | ------------------------ |
| 测试覆盖率 | **97.1%**                |
| 测试包数   | 8 packages               |
| 测试函数   | 93+                      |
| Benchmark  | 6（core_bench_test.go）  |
| Race 检测  | `go test -race` 全部通过 |

### 15.2 测试类型

| 类型            | 覆盖内容        | 文件                        |
| --------------- | --------------- | --------------------------- |
| 单元测试        | 所有公共 API    | `*_test.go` (12 files)      |
| Boost 测试      | 覆盖率提升专项  | `*_boost_test.go` (7 files) |
| Fuzz 测试       | 随机输入安全    | `config_fuzz_test.go`       |
| Property 测试   | 不变量验证      | `config_property_test.go`   |
| Golden 测试     | 回归快照        | `health_golden_test.go`     |
| Precedence 测试 | 优先级/覆盖链路 | `precedence_test.go`        |
| Benchmark       | Load/Get 性能   | `core_bench_test.go`        |

### 15.3 Given/When/Then 用例

**TC-001: LastWins 合并**
Given Source A 设置 `key=value1`，Source B 设置 `key=value2`
When `NewLoader().AddSource(A).AddSource(B).Load(ctx)`
Then `LoadResult.Values["key"].Value` 返回 `"value2"`

**TC-002: StrictDecode 拒绝未知字段**
Given JSON `{"name": "test", "unknown_field": true}`，target struct 只有 `Name`
When `StrictDecode(data, &target)`
Then 返回错误，包含未知字段名

**TC-003: SecretString 脱敏**
Given `s := NewSecretString("secret123")`
When `fmt.Print(s)` / `json.Marshal(s)` / `s.GoString()`
Then 全部输出 `"***"`，不包含 `"secret123"`

**TC-004: Reveal 获取原始值**
Given `s := NewSecretString("secret123")`
When `s.Reveal()`
Then 返回 `"secret123"`

**TC-005: SecretPolicy 自定义匹配**
Given `sp := &SecretPolicy{CustomMatcher: func(k string) bool { return strings.HasPrefix(k, "private_") }}`
When `sp.IsSecret("private_key")`
Then 返回 true

**TC-006: EffectiveConfigHash 可复现**
Given 相同的 LoadResult
When 两次调用 `EffectiveConfigHash(result)`
Then 返回相同的 SHA-256 hex string

**TC-007: HealthCheck**
Given 已初始化的 Client
When `client.HealthCheck(ctx)`
Then Status = healthy, LatencyMs > 0

**TC-008: nil context 拒绝**
Given `configx.New(nil, cfg)`
When ctx 为 nil
Then 返回 validation error，metrics 记录错误

**TC-009: Release DoD 门禁**
Given 所有实现完成
When 运行 `go test -race -count=1 ./...` + `golangci-lint run` + `gitleaks detect --no-git`
Then 全部通过，覆盖率 ≥ 97%

---

## 16. 性能预算

| 操作                      | 目标       | 测量方式       |
| ------------------------- | ---------- | -------------- |
| 配置加载（1000 个 key）   | < 50ms     | benchmark test |
| Get 单次调用              | < 100ns    | benchmark test |
| 并发 Get（100 goroutine） | 无显著退化 | benchmark test |
| 常驻内存                  | < 5MB      | profiling      |

---

## 17. 可观测性

### 17.1 Metrics

| 指标名                            | 类型      | 说明             |
| --------------------------------- | --------- | ---------------- |
| `client_created_total`            | Counter   | Client 创建次数  |
| `client_closed_total`             | Counter   | Client 关闭次数  |
| `client_errors_total`             | Counter   | Client 错误次数  |
| `client_health_status`            | Gauge     | 健康状态         |
| `client_health_latency_ms`        | Gauge     | 健康检查延迟     |
| `client_requests_total`           | Counter   | 请求总数         |
| `client_request_duration_seconds` | Histogram | 请求耗时         |
| `client_retries_total`            | Counter   | 重试次数         |
| `client_inflight`                 | Gauge     | 正在处理的请求数 |

### 17.2 Metrics 接口

```go
type Metrics interface {
    IncCounter(name string, labels map[string]string)
    ObserveHistogram(name string, value float64, labels map[string]string)
    SetGauge(name string, value float64, labels map[string]string)
}

type NoopMetrics struct{}  // 零开销空实现
```

---

## 18. 安全

| 要求                | 实现方式                                                                                              |
| ------------------- | ----------------------------------------------------------------------------------------------------- |
| 敏感配置不写日志    | SecretString 在所有格式化输出中自动脱敏（`***`）；SanitizedManifest 安全快照                          |
| SecretPolicy 可配置 | 默认 7 种模式 + CustomMatcher 扩展；`isSensitiveFieldName` 覆盖 Key/Pass/Credential/Auth/Private 后缀 |
| 配置文件权限检查    | 启动时检查文件权限（Unix: 不允许 other 可写），过宽则 warning                                         |
| 环境变量不泄露      | 错误消息中不包含环境变量值                                                                            |
| 依赖安全扫描        | CI 运行 `govulncheck ./...` 扫描已知漏洞                                                              |
| 静态凭证扫描        | CI Gate `gitleaks detect --no-git` 阻塞任何硬编码凭证                                                 |
| 不可信输入校验      | StrictDecode 默认拒绝未知字段；所有 Source 输入通过 schema 校验                                       |
| 无全局状态          | 源码无可变包级单例 / 无 init() 副作用；`TestNoImplicitConfigDiscovery` 单测 + 源码静态检查覆盖          |

---

## 19. CI 门禁

### 19.1 通用 Gate

| Gate        | 命令                                                  | 阻塞条件                   |
| ----------- | ----------------------------------------------------- | -------------------------- |
| 编译        | `GOWORK=off go build ./...`                           | 编译失败                   |
| 测试        | `GOWORK=off go test ./... -race -count=1`             | 任何测试失败或 data race   |
| 覆盖率      | `GOWORK=off go test ./... -coverprofile=coverage.out` | 覆盖率 < 80%               |
| vet         | `GOWORK=off go vet ./...`                             | 任何 vet 错误              |
| lint        | `golangci-lint run ./...`                             | 任何 lint 错误（8 linter） |
| 依赖检查    | `go mod tidy && git diff --exit-code go.mod go.sum`   | go.mod 不整洁              |
| Secret 扫描 | `gitleaks detect --no-git`                            | 泄露 secret                |
| 漏洞扫描    | `govulncheck ./...`                                   | 高危 CVE                   |

### 19.2 configx 专属 Gate

| Gate          | 命令                                                              | 阻塞条件                    |
| ------------- | ----------------------------------------------------------------- | --------------------------- |
| 不依赖 kernel | `go list -deps ./... \| grep "kernel"`                            | 依赖 kernel                 |
| 无全局状态    | 源码静态检查：无可变包级 `var Client` / 无 init() 副作用          | 引入进程级 config singleton |
| 显式加载      | `TestNoImplicitConfigDiscovery` 单测                              | 出现隐式配置发现路径        |

---

## 20. 升级兼容性

| 变更类型                   | 版本升级              |
| -------------------------- | --------------------- |
| 新增 Source 类型           | **minor**             |
| 新增 Option / LoaderOption | **minor**             |
| Source 接口变更            | **major**             |
| Config 新增必填字段        | **minor**（带默认值） |
| SecretPolicy 模式变更      | **minor**             |
| Metrics 指标名变更         | **major**             |

---

## 21. 发布 DoD

- [x] 所有公共接口有 godoc 注释
- [x] 所有公共类型有示例代码（examples/error-handling/）
- [x] CHANGELOG.md 已更新
- [x] README.md 包含：模块定位、快速开始、配置说明、API 概览
- [x] 单元测试覆盖率 ≥ 97%
- [x] `-race` 测试通过
- [x] Benchmark 结果无 > 10% 回退
- [x] `go vet` 无警告
- [x] `golangci-lint` 无错误（8 linter）
- [x] Secret 扫描通过（gitleaks）
- [x] 漏洞扫描通过（govulncheck）
- [x] 公共 API 无破坏性变更（或已 bump major）
- [x] 所有 Functional Requirements 有对应测试
- [x] 所有 Edge Cases 有对应测试

---

## 22. 待解决问题

### Blocking（阻塞开发）

无。当前无阻塞性问题。

### Non-blocking（不阻塞开发）

无。

### Future（未来考虑）

| ID     | 问题                                           | 状态   | 负责人   |
| ------ | ---------------------------------------------- | ------ | -------- |
| OQ-001 | 是否需要支持运行时配置热更新（Watch 特性）？   | 待评估 | ZoneCNH  |
| OQ-002 | 是否需要支持配置版本管理（记录每次配置变更）？ | 待评估 | ZoneCNH  |
| OQ-003 | 是否需要支持远程配置源（etcd/consul/vault）？  | 待评估 | ZoneCNH  |
| OQ-004 | 是否需要支持配置模板（引用其他 key 的值）？    | 待评估 | ZoneCNH  |

---



## 23. 变更历史

---

## Appendix A: Lifecycle

| 阶段   | 触发方法                 | 状态变更                                              | 错误处理                                     |
| ------ | ------------------------ | ----------------------------------------------------- | -------------------------------------------- |
| 创建   | `New(ctx, cfg, opts...)` | 校验 cfg → 初始化 Client → metrics+1                  | ctx nil 或 Validate 失败 → 返回 error        |
| 加载   | `loader.Load(ctx)`       | 按序加载所有 Source → LastWins 合并 → 返回 LoadResult | Source 失败且 failFast=true → 立即返回 error |
| 运行   | Client 就绪              | 并发安全，可调用 HealthCheck                          | 操作失败 → metrics 记录                      |
| 关闭   | `client.Close(ctx)`      | 标记 closed=true → metrics+1                          | ctx nil → 返回 error                         |

---

| 日期       | 版本   | 变更内容                                                                                                                  | 作者    |
| ---------- | ------ | ------------------------------------------------------------------------------------------------------------------------- | ------- |
| 2026-06-12 | v1.1.0 | 完整重写：基于实际 v1.0.0 代码（97.1% 覆盖率），对齐 Client/Loader/Source/SecretString/Provenance/StrictDecode 等真实 API | ZoneCNH |
| 2026-06-12 | v1.0.2 | 版本号对齐；Non-goals 澄清；移除过时 kernel 依赖声明                                                                      | ZoneCNH |
| 2026-06-12 | v1.0.1 | 对齐修复：移除过时 kernel.Deps；Status Draft→Approved                                                                     | ZoneCNH |
| 2026-06-07 | v1.0.0 | 初始版本                                                                                                                  | ZoneCNH |