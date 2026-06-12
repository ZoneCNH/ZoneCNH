# kernel 完整规格

> Foundation L0 原语层。轻量工具包子集，stdlib-only，零外部依赖。

最后更新：2026-06-12

---

## 1. Metadata

- Status: Approved
- Spec-Version: v2.0.0
- Last-Updated: 2026-06-12
- Owner: ZoneCNH
- Layer: L0 原语
- Version: v1.0.0
- Repository: [github.com/ZoneCNH/kernel](https://github.com/ZoneCNH/kernel)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md)

---

### 1.1 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-12 | v2.0.0 | 全部重写：基于实际代码，从集中式 App/Module/Deps 框架改为 12 子包轻量工具集 | ZoneCNH |
| 2026-06-08 | v1.1.0 | 对抗性审查修复：重写 §9.1 Deps 为 kernel 内接口；修正 §18 metric 命名；§22 覆盖率提至 90%；补充 FR-001/FR-002/FR-003 WHEN/THEN；BR-004~BR-009 补充违反处理；§16 补充 AC/TC 追溯链；§13 扩充至 18 条；§19 增加安全要求；§23 分类整理；FR-005 返回 GraphView；Health() 增加 ctx | ZoneCNH |
| 2026-06-07 | v1.0.0 | 初始版本 | ZoneCNH |

## 2. Summary

`kernel` 是轻量工具包子集，为 Foundation L1 模块提供 stdlib-only 的 Go 基础原语。包含 12 个独立子包：`lifecycx`（组件生命周期）、`errx`（结构化错误）、`healthx`（健康检查）、`obsx`（可观测抽象）、`retryx`（重试策略）、`shutdownx`（优雅停机）、`syncx`（并发控制）、`timex`（时钟抽象）、`validx`（前置条件校验）、`versionx`（版本信息）、`contextx`（类型安全上下文）、`contracttest`（契约测试辅助）。各子包独立按需引用，互不绑定。

---

## 3. Problem

Foundation 各模块需要统一的生命周期管理、错误分类、健康检查、可观测抽象、重试策略、优雅停机、并发控制等横切关注点。这些能力应在 L0 层提供，不引入任何外部依赖（stdlib-only），且各子包应独立可用，避免强制耦合。

---

## 4. Goals

- `lifecycx`：组件有序启动/逆序停止管理器，失败自动回滚
- `errx`：结构化错误类型（kind/severity/op/code/retryable），支持错误链遍历
- `healthx`：健康检查状态、探针接口、聚合规则
- `obsx`：无供应商绑定的 Logger/Metrics/Tracer/Span 接口，Noop 实现，敏感数据脱敏
- `retryx`：指数退避重试策略，可重试错误判断
- `shutdownx`：LIFO 关闭钩子管理，OS 信号绑定
- `syncx`：上下文感知并发限制器（信号量），WorkerGroup
- `timex`：可注入时钟接口（RealClock / FixedClock / FakeClock）
- `validx`：前置条件和不变量校验助手
- `versionx`：构建版本元数据，兼容性判断
- `contextx`：类型安全 context key/value，deadline 查询工具
- `contracttest`：L1 包复用的契约测试助手
- stdlib-only，零外部依赖

---

## 5. Non-goals

- 不做集中式应用框架（无 App/Module/Deps 抽象）
- 不做 DI 容器
- 不做配置解析（→ `configx`）
- 不做日志/指标/追踪的具体实现（→ `observex`，kernel 只定义接口）
- 不做依赖图 / 拓扑排序 / 环检测
- 不做模块间依赖注入
- 不做存储、网络、业务 DTO
- 不做服务发现或远程调用

---

## 6. Consumers

| 消费者 | 使用方式 |
|--------|----------|
| L1 运行时模块（configx, observex, resiliencx 等） | 按需 import 单个子包，如 `errx`、`obsx`、`retryx` |
| 业务域模块 | 按需 import `validx`、`contextx`、`syncx` 等 |
| 组合根（x.go） | 使用 `lifecycx.Manager` 编排组件生命周期，使用 `shutdownx.Manager` 管理停机 |
| 运维/监控 | 通过 `healthx.HealthChecker` 查询健康状态 |
| 测试代码 | 使用 `timex.FakeClock`、`contracttest` 等测试工具 |

---

## 7. Functional Requirements

### FR-001: lifecycx — 组件生命周期管理

WHEN 调用 `Manager.Start(ctx)` 且所有 Component 启动成功
THEN 按注册顺序依次启动所有 Component，返回 nil

WHEN 调用 `Manager.Start(ctx)` 且第 k 个 Component 的 Start 返回错误
THEN 逆序 Stop 已启动的前 k-1 个 Component，返回 `errors.Join(第k个错误, 所有回滚错误...)`

WHEN 调用 `Manager.Stop(ctx)` 且 Manager 已 started
THEN 按注册逆序依次调用所有 Component 的 Stop，设置 started=false，返回 `errors.Join(所有失败...)`

WHEN 调用 `Manager.Stop(ctx)` 且 Manager 未 started
THEN 返回 nil（幂等）

WHEN 调用 `NewManager(components...)`
THEN 返回 Manager，内部持有 components 的防御性拷贝

WHEN 调用 `Manager.Components()`
THEN 返回当前注册 Component 的防御性拷贝

### FR-002: errx — 结构化错误

WHEN 调用 `NewError(kind, op, message)`
THEN 返回 `*Error{Kind: kind, Op: op, Message: message}`，Cause 为 nil

WHEN 调用 `WrapError(kind, op, message, cause)`
THEN 返回 `*Error` 包含 kind/op/message/cause，Cause 可通过 Unwrap 访问

WHEN 调用 `IsKind(err, kind)` 且错误链中存在匹配的 ErrorKind
THEN 返回 true，支持 errors.Join 多错误链遍历

WHEN 调用 `IsKind(err, kind)` 且错误链中无匹配
THEN 返回 false

WHEN 调用 `AsError(err)` 且错误链中存在 `*Error`
THEN 返回 `(*Error, true)`

WHEN 调用 `AsError(err)` 且错误链中不存在 `*Error`
THEN 返回 `(nil, false)`

WHEN 调用 `(*Error).WithRetryable(true)` 或 `(*Error).WithCode("...")` 或 `(*Error).WithSeverity(...)`
THEN 返回同一指针，修改对应字段（构造期链式调用）

WHEN 调用 `(*Error).Error()`
THEN 返回格式化字符串，格式依 Code 和 Op 是否存在而变化

**ErrorKind 预定义值：** config, validation, connection, unavailable, timeout, auth, conflict, rate_limit, canceled, not_found, already_exists, internal

**Severity 预定义值：** info, warning, error, critical

### FR-003: healthx — 健康检查

WHEN 调用 `HealthChecker.Check(ctx)`
THEN 返回 `HealthStatus`，含 Name/Status/Message/CheckedAt/LatencyMs/Metadata

WHEN 调用 `NewHealthStatus(name, status, message, checkedAt, latencyMs)`
THEN 返回 `HealthStatus`，Metadata 初始化为空 map

WHEN 调用 `HealthStatus.WithMetadata(key, value)`
THEN 返回新 HealthStatus（不可变），含新增 metadata 键值对

WHEN 调用 `HealthStatus.IsHealthy()`
THEN 当 Status == "healthy" 时返回 true

WHEN 调用 `Aggregate(name, statuses...)` 且全部 healthy
THEN 返回 status="healthy" 的聚合结果，Metadata 含各子状态

WHEN 调用 `Aggregate(name, statuses...)` 且任一 unhealthy
THEN 返回 status="unhealthy"，message="unhealthy"

WHEN 调用 `Aggregate(name, statuses...)` 且无 unhealthy 但有 degraded
THEN 返回 status="degraded"，message="degraded"

WHEN JSON 序列化 HealthStatus 且 Metadata 为 nil
THEN 序列化为 `{}` 而非 `null`

### FR-004: obsx — 可观测抽象

WHEN 使用 `Logger` 接口
THEN 提供 `Debug/Info/Warn/Error(ctx, msg, ...Field)` 四个方法，Field 为键值对

WHEN 使用 `Metrics` 接口
THEN 提供 `Count(ctx, name, delta, ...Field)` 和 `Observe(ctx, name, value, ...Field)` 两个方法

WHEN 使用 `Tracer` 接口
THEN `Start(ctx, name, ...Field)` 返回 `(context.Context, Span)`

WHEN 使用 `Span` 接口
THEN 提供 `End()`、`RecordError(error)`、`SetFields(...Field)` 三个方法

WHEN 使用 `NoopLogger` / `NoopMetrics` / `NoopTracer`
THEN 所有方法静默成功，不触发任何副作用

WHEN 调用 `NewSecretString(value)`
THEN 返回 SecretString，String()/GoString()/MarshalJSON() 返回 `"***"`，Reveal() 返回原始值

WHEN 调用 `SecretString.Sanitize()`
THEN 返回脱敏字符串

WHEN `Sanitizer` 接口被实现
THEN `Sanitize()` 返回脱敏后的安全表示

### FR-005: retryx — 重试策略

WHEN 调用 `DefaultRetryPolicy()`
THEN 返回 `RetryPolicy{MaxAttempts: 3, BaseDelay: 100ms, MaxDelay: 2s}`

WHEN 调用 `RetryPolicy.Validate()` 且字段合法
THEN 返回 nil

WHEN 调用 `RetryPolicy.Validate()` 且 MaxAttempts <= 0
THEN 返回 ErrorKindValidation 错误

WHEN 调用 `RetryPolicy.Validate()` 且 BaseDelay < 0 或 MaxDelay < 0
THEN 返回 ErrorKindValidation 错误

WHEN 调用 `RetryPolicy.Validate()` 且 BaseDelay > MaxDelay > 0
THEN 返回 ErrorKindValidation 错误

WHEN 调用 `RetryPolicy.Delay(attempt)` 其中 attempt=1
THEN 返回 BaseDelay

WHEN 调用 `RetryPolicy.Delay(attempt)` 其中 attempt>1
THEN 返回指数退避延迟，受 MaxDelay 上限约束，防溢出

WHEN 调用 `RetryPolicy.DelayWithJitter(attempt, ratio, fraction)`
THEN 在 Delay 基础上叠加 jitter（±ratio * fraction），受 MaxDelay 约束

WHEN 调用 `ShouldRetry(err)` 且错误链中存在 `*Error{Retryable: true}`
THEN 返回 true

WHEN 调用 `ShouldRetry(err)` 且错误链中无 retryable 标记
THEN 返回 false

### FR-006: shutdownx — 优雅停机

WHEN 调用 `Manager.Shutdown(ctx)`
THEN 按注册逆序（LIFO）执行所有 Hook 的 Shutdown，返回 `errors.Join(所有失败...)`

WHEN 调用 `Manager.Register(hook)`
THEN hook 追加到列表末尾（并发安全），关机时最后注册的先执行

WHEN 调用 `Manager.Hooks()`
THEN 返回已注册 Hook 的防御性拷贝

WHEN 调用 `NewManager(hooks...)`
THEN 返回 Manager，内部持有 hooks 的防御性拷贝

WHEN 使用 `HookFunc{NameValue: "foo", Fn: fn}`
THEN Name() 返回 "foo"，Shutdown(ctx) 调用 fn(ctx)

WHEN 调用 `NotifyContext(parent, signals...)`
THEN 返回 context 在收到任一指定信号时取消，cancel 函数释放信号资源

### FR-007: timex — 时钟抽象

WHEN 使用 `Clock` 接口
THEN 提供 `Now() time.Time` 方法

WHEN 使用 `RealClock`
THEN `Now()` 返回 `time.Now()`（系统时钟）

WHEN 使用 `FixedClock{now: t}`
THEN `Now()` 始终返回 t（不可变）

WHEN 使用 `FakeClock`
THEN `Now()` 返回当前内部时间，`Advance(d)` 推进内部时间 d

### FR-008: validx — 前置条件校验

WHEN 调用 `Precondition(ok, op, message)` 且 ok == true
THEN 返回 nil

WHEN 调用 `Precondition(ok, op, message)` 且 ok == false
THEN 返回 ErrorKindValidation + SeverityWarning 的 *Error

WHEN 调用 `Invariant(ok, op, message)` 且 ok == true
THEN 返回 nil

WHEN 调用 `Invariant(ok, op, message)` 且 ok == false
THEN 返回 ErrorKindInternal + SeverityError 的 *Error

WHEN 调用 `RequireNonEmpty(op, name, value)` 且 value 为空
THEN 返回 Precondition 错误，消息为 "<name> must not be empty"

WHEN 调用 `RequireNonEmpty(op, name, value)` 且 value 非空
THEN 返回 nil

### FR-009: versionx — 版本信息

WHEN 调用 `NewBuildInfo(module, version, commit, buildTime, goVersion)`
THEN 返回 `BuildInfo` 含全部字段

WHEN 调用 `Compatibility.CompatibleWith(info)` 且 Module 匹配，Major 匹配
THEN 返回 true

WHEN 调用 `Compatibility.CompatibleWith(info)` 且 Module 不匹配
THEN 返回 false

WHEN `Compatibility.Major` 为空
THEN `CompatibleWith` 仅校验 Module，忽略版本

WHEN 使用 `VersionInfo`
THEN 等同于 `BuildInfo`（类型别名，已 deprecated）

### FR-010: contextx — 类型安全上下文

WHEN 调用 `NewKey[T](name)`
THEN 返回基于 sentinel 指针的唯一 Key[T]（同名字不同实例不冲突）

WHEN 调用 `WithValue(ctx, key, value)`
THEN 返回包含类型安全键值对的派生 context

WHEN 调用 `Value[T](ctx, key)` 且值存在且类型匹配
THEN 返回 `(value, true)`

WHEN 调用 `Value[T](ctx, key)` 且值不存在或类型不匹配
THEN 返回 `(zero, false)`

WHEN 使用零值 Key[T] 调用 contextKey()
THEN panic("contextx: zero Key; create keys with NewKey")

WHEN 调用 `HasDeadline(ctx)` 且 ctx 有 deadline
THEN 返回 true

WHEN 调用 `DeadlineRemaining(ctx, clock)` 且 deadline 存在
THEN 返回剩余时间和 true

WHEN 调用 `DeadlineRemaining(ctx, clock)` 且 deadline 不存在
THEN 返回 (0, false)

WHEN 调用 `IsDone(ctx)` 且 ctx 已 cancel/超时
THEN 返回 true

WHEN 调用 `CancelCause(ctx)`
THEN 返回 `context.Cause(ctx)`

### FR-011: syncx — 并发控制

WHEN 调用 `NewSemaphoreLimiter(n)` 且 n > 0
THEN 返回容量为 n 的信号量限制器

WHEN 调用 `NewSemaphoreLimiter(n)` 且 n <= 0
THEN 使用默认容量 1

WHEN 调用 `SemaphoreLimiter.Acquire(ctx)` 且信号量有空位
THEN 立即返回 nil

WHEN 调用 `SemaphoreLimiter.Acquire(ctx)` 且信号量已满
THEN 阻塞等待，直到有空位或 ctx 取消

WHEN 调用 `SemaphoreLimiter.Release()`
THEN 释放一个许可，double-release 静默忽略

WHEN 使用 `WorkerGroup.Go(fn)` / `TryGo(fn)`
THEN 启动 worker goroutine，首个错误触发 cancel，Wait() 收集所有错误

WHEN WorkerGroup 已 closed 后调用 `TryGo(fn)`
THEN 返回 false（静默忽略）

### FR-012: contracttest — 契约测试

WHEN 调用 `AssertJSONFields(t, value, fields...)` 且所有字段存在
THEN 测试通过

WHEN 调用 `AssertJSONFields(t, value, fields...)` 且某字段缺失
THEN 测试失败并报告缺失字段

WHEN 调用 `AssertErrorKind(t, err, kind)` 且 err 的 ErrorKind 匹配
THEN 测试通过

WHEN 调用 `AssertErrorKind(t, err, kind)` 且不匹配
THEN 测试失败

WHEN 调用 `AssertHealthStatus(t, got, want)` 且 status 匹配
THEN 测试通过

---

## 8. Business Rules

| 编号 | 规则 | 违反时 |
|------|------|--------|
| BR-001 | lifecycx: 启动顺序为注册顺序，停止顺序为启动逆序 | 代码逻辑保证，违反即为 bug |
| BR-002 | lifecycx: 启动失败必须回滚已启动的 Component | 未回滚导致资源泄漏 |
| BR-003 | lifecycx: 未 started 时 Stop 必须幂等返回 nil | 非幂等导致调用方需额外状态判断 |
| BR-004 | errx: Error 必须实现 error、Unwrap 接口 | 否则 errors.Is/As 不可用 |
| BR-005 | errx: IsKind/ShouldRetry 必须支持 errors.Join 多错误链 | 否则组合错误丢失分类能力 |
| BR-006 | obsx: 所有接口必须有 Noop 零值实现 | 否则消费者被迫依赖具体 SDK |
| BR-007 | healthx: Metadata nil 时必须序列化为 {} 而非 null | 否则 JSON 契约不一致 |
| BR-008 | shutdownx: Hook 按 LIFO 顺序执行（后注册先执行） | 否则资源释放顺序错误 |
| BR-009 | kernel 不 import 任何非 stdlib 包 | CI stdlib-only gate 阻断（healthx→timex、errx→stdlib 等 kernel 内部交叉引用除外） |
| BR-010 | contextx: Key 必须通过 NewKey 创建，零值 Key 使用 panic | 防止因忘记初始化导致的键冲突 |
| BR-011 | syncx: SemaphoreLimiter double-release 静默忽略 | 设计选择，简化调用方清理路径 |
| BR-012 | timex: FakeClock 零值接收者安全（返回零时间） | 防止测试中的 nil panic |

---

## 9. Interface Contract

### 9.1 lifecycx

```go
type Starter interface {
    Start(ctx context.Context) error
}

type Stopper interface {
    Stop(ctx context.Context) error
}

type Component interface {
    Name() string
    Starter
    Stopper
}

type Manager struct { /* unexported */ }

func NewManager(components ...Component) *Manager
func (m *Manager) Components() []Component
func (m *Manager) Start(ctx context.Context) error
func (m *Manager) Stop(ctx context.Context) error
```

### 9.2 errx

```go
type ErrorKind string

const (
    ErrorKindConfig       ErrorKind = "config"
    ErrorKindValidation   ErrorKind = "validation"
    ErrorKindConnection   ErrorKind = "connection"
    ErrorKindUnavailable  ErrorKind = "unavailable"
    ErrorKindTimeout      ErrorKind = "timeout"
    ErrorKindAuth         ErrorKind = "auth"
    ErrorKindConflict     ErrorKind = "conflict"
    ErrorKindRateLimit    ErrorKind = "rate_limit"
    ErrorKindCanceled     ErrorKind = "canceled"
    ErrorKindNotFound     ErrorKind = "not_found"
    ErrorKindAlreadyExist ErrorKind = "already_exists"
    ErrorKindInternal     ErrorKind = "internal"
)

type Severity string

const (
    SeverityInfo     Severity = "info"
    SeverityWarning  Severity = "warning"
    SeverityError    Severity = "error"
    SeverityCritical Severity = "critical"
)

type Error struct {
    Kind      ErrorKind `json:"kind"`
    Code      string    `json:"code,omitempty"`
    Severity  Severity  `json:"severity,omitempty"`
    Op        string    `json:"op,omitempty"`
    Message   string    `json:"message"`
    Cause     error     `json:"-"`
    Retryable bool      `json:"retryable"`
}

func NewError(kind ErrorKind, op string, message string) *Error
func WrapError(kind ErrorKind, op string, message string, cause error) *Error
func (e *Error) Error() string
func (e *Error) Unwrap() error
func (e *Error) WithRetryable(retryable bool) *Error
func (e *Error) WithCode(code string) *Error
func (e *Error) WithSeverity(severity Severity) *Error
func IsKind(err error, kind ErrorKind) bool
func AsError(err error) (*Error, bool)
```

### 9.3 healthx

```go
type HealthStatusValue string

const (
    HealthHealthy   HealthStatusValue = "healthy"
    HealthDegraded  HealthStatusValue = "degraded"
    HealthUnhealthy HealthStatusValue = "unhealthy"
)

type HealthStatus struct {
    Name      string            `json:"name"`
    Status    HealthStatusValue `json:"status"`
    Message   string            `json:"message"`
    CheckedAt time.Time         `json:"checked_at"`
    LatencyMs int64             `json:"latency_ms"`
    Metadata  map[string]string `json:"metadata"`
}

type HealthChecker interface {
    Name() string
    Check(ctx context.Context) HealthStatus
}

func NewHealthStatus(name string, status HealthStatusValue, message string, checkedAt time.Time, latencyMs int64) HealthStatus
func (s HealthStatus) WithMetadata(key string, value string) HealthStatus
func (s HealthStatus) IsHealthy() bool
func Aggregate(name string, statuses ...HealthStatus) HealthStatus
func AggregateWithClock(name string, clock timex.Clock, statuses ...HealthStatus) HealthStatus
```

### 9.4 obsx

```go
type Field struct {
    Key   string
    Value any
}

type Logger interface {
    Debug(context.Context, string, ...Field)
    Info(context.Context, string, ...Field)
    Warn(context.Context, string, ...Field)
    Error(context.Context, string, ...Field)
}

type Metrics interface {
    Count(context.Context, string, int64, ...Field)
    Observe(context.Context, string, float64, ...Field)
}

type Tracer interface {
    Start(context.Context, string, ...Field) (context.Context, Span)
}

type Span interface {
    End()
    RecordError(error)
    SetFields(...Field)
}

type NoopLogger struct{}
type NoopMetrics struct{}
type NoopTracer struct{}
type NoopSpan struct{}

type Sanitizer interface{ Sanitize() string }

type SecretString string

func NewSecretString(value string) SecretString
func (s SecretString) String() string
func (s SecretString) Sanitize() string
func (s SecretString) Reveal() string
```

### 9.5 retryx

```go
type RetryPolicy struct {
    MaxAttempts int
    BaseDelay   time.Duration
    MaxDelay    time.Duration
}

func DefaultRetryPolicy() RetryPolicy
func (p RetryPolicy) Validate() error
func (p RetryPolicy) Delay(attempt int) time.Duration
func (p RetryPolicy) DelayWithJitter(attempt int, ratio float64, fraction float64) time.Duration
func ShouldRetry(err error) bool
```

### 9.6 shutdownx

```go
type Hook interface {
    Name() string
    Shutdown(ctx context.Context) error
}

type HookFunc struct {
    NameValue string
    Fn        func(context.Context) error
}

func (h HookFunc) Name() string
func (h HookFunc) Shutdown(ctx context.Context) error

type Manager struct { /* unexported */ }

func NewManager(hooks ...Hook) *Manager
func (m *Manager) Register(hook Hook)
func (m *Manager) Shutdown(ctx context.Context) error
func (m *Manager) Hooks() []Hook

func NotifyContext(parent context.Context, signals ...os.Signal) (context.Context, context.CancelFunc)
```

### 9.7 timex

```go
type Clock interface{ Now() time.Time }

type RealClock struct{}
func NewRealClock() RealClock
func (RealClock) Now() time.Time

type FixedClock struct{ /* unexported */ }
func NewFixedClock(now time.Time) FixedClock
func (c FixedClock) Now() time.Time

type FakeClock struct{ /* unexported */ }
func NewFakeClock(now time.Time) *FakeClock
func (c *FakeClock) Now() time.Time
func (c *FakeClock) Advance(d time.Duration)
```

### 9.8 validx

```go
func Precondition(ok bool, op string, message string) error
func Invariant(ok bool, op string, message string) error
func RequireNonEmpty(op string, name string, value string) error
```

### 9.9 versionx

```go
type BuildInfo struct {
    Module    string `json:"module"`
    Version   string `json:"version"`
    Commit    string `json:"commit"`
    BuildTime string `json:"build_time"`
    GoVersion string `json:"go_version"`
}

type VersionInfo = BuildInfo // Deprecated

func NewBuildInfo(module, version, commit, buildTime, goVersion string) BuildInfo

type Compatibility struct {
    Module string
    Major  string
}

func (c Compatibility) CompatibleWith(info BuildInfo) bool
```

### 9.10 contextx

```go
type Key[T any] struct { /* unexported */ }

func NewKey[T any](name string) Key[T]
func WithValue[T any](ctx context.Context, key Key[T], value T) context.Context
func Value[T any](ctx context.Context, key Key[T]) (T, bool)
func HasDeadline(ctx context.Context) bool
func DeadlineRemaining(ctx context.Context, clock timex.Clock) (time.Duration, bool)
func IsDone(ctx context.Context) bool
func CancelCause(ctx context.Context) error
```

### 9.11 syncx

```go
type Limiter interface {
    Acquire(context.Context) error
    Release()
}

type SemaphoreLimiter struct { /* unexported */ }

func NewSemaphoreLimiter(n int) *SemaphoreLimiter
func (l *SemaphoreLimiter) Acquire(ctx context.Context) error
func (l *SemaphoreLimiter) Release()
func (l *SemaphoreLimiter) TryRelease() bool

type WorkerGroup struct { /* unexported */ }

func NewWorkerGroup(ctx context.Context) *WorkerGroup
func (g *WorkerGroup) Go(fn func(context.Context) error)
func (g *WorkerGroup) TryGo(fn func(context.Context) error) bool
func (g *WorkerGroup) Wait() error
```

### 9.12 contracttest

```go
func AssertJSONFields(t testing.TB, value any, fields ...string)
func AssertErrorKind(t testing.TB, got error, want errx.ErrorKind)
func AssertHealthStatus(t testing.TB, got healthx.HealthStatus, want healthx.HealthStatusValue)
```

### 9.13 internal/testutil

```go
func RequireEqual[T comparable](t testing.TB, got T, want T)
```

---

## 10. Data Model

### 10.1 errx.Error

```go
type Error struct {
    Kind      ErrorKind `json:"kind"`             // 错误分类
    Code      string    `json:"code,omitempty"`    // 稳定机器可读码
    Severity  Severity  `json:"severity,omitempty"` // 运维影响级别
    Op        string    `json:"op,omitempty"`      // 操作名
    Message   string    `json:"message"`           // 人类可读描述
    Cause     error     `json:"-"`                 // 底层错误（不序列化）
    Retryable bool      `json:"retryable"`         // 是否可重试
}
```

### 10.2 healthx.HealthStatus

```go
type HealthStatus struct {
    Name      string            `json:"name"`
    Status    HealthStatusValue `json:"status"`   // healthy / degraded / unhealthy
    Message   string            `json:"message"`
    CheckedAt time.Time         `json:"checked_at"`
    LatencyMs int64             `json:"latency_ms"`
    Metadata  map[string]string `json:"metadata"`
}
```

### 10.3 retryx.RetryPolicy

```go
type RetryPolicy struct {
    MaxAttempts int           // 最大尝试次数（必须 > 0）
    BaseDelay   time.Duration // 初始退避延迟
    MaxDelay    time.Duration // 退避上限（0 表示无显式上限，但 Delay 仍有溢出保护）
}
```

### 10.4 versionx.BuildInfo

```go
type BuildInfo struct {
    Module    string `json:"module"`
    Version   string `json:"version"`
    Commit    string `json:"commit"`
    BuildTime string `json:"build_time"`
    GoVersion string `json:"go_version"`
}
```

### 10.5 versionx.Compatibility

```go
type Compatibility struct {
    Module string  // 期望的 module 路径（空 = 不校验）
    Major  string  // 期望的主版本号（空 = 不校验）
}
```

---

## 11. Config Schema

kernel 本身不需要配置。各子包通过构造函数参数或 Option 模式接收配置：

| 子包 | 配置方式 |
|------|----------|
| lifecycx | `NewManager(components...)` 构造函数参数 |
| retryx | `RetryPolicy{MaxAttempts, BaseDelay, MaxDelay}` 结构体字段 |
| shutdownx | `NewManager(hooks...)` 构造函数参数 |
| syncx | `NewSemaphoreLimiter(n)` 构造函数参数 |
| versionx | `NewBuildInfo(...)` 构造函数参数 |

---

## 12. Error Handling

| 错误来源 | 调用方处理 |
|----------|-----------|
| lifecycx: Start 失败 | 检查 `errors.Join` 返回的组合错误，已启动组件已自动回滚 |
| lifecycx: Stop 失败 | 检查 `errors.Join` 返回的组合错误，后续组件已继续停止 |
| errx: NewError/WrapError | 返回构造的 *Error，调用方使用 IsKind/AsError 分类处理 |
| errx: IsKind | 遍历错误链，返回 bool，用于路由决策 |
| retryx: ShouldRetry | 遍历错误链检查 Retryable 标记，用于重试循环条件 |
| retryx: Validate 失败 | 返回 ErrorKindValidation 错误，配置阶段发现 |
| validx: Precondition 失败 | 返回 ErrorKindValidation + SeverityWarning，调用方检查返回值 |
| validx: Invariant 失败 | 返回 ErrorKindInternal + SeverityError，调用方检查返回值 |
| syncx: Acquire 超时 | 返回 ctx.Err()，调用方处理 context 取消 |
| syncx: WorkerGroup 首个错误 | 触发 cancel，Wait() 收集所有错误 |
| shutdownx: Shutdown 失败 | 返回 `errors.Join` 聚合错误，含 hook 名称 |

**错误消息格式：** `"<kind>: <op>: <message>"` 或 `"<kind>/<code>: <op>: <message>"`
**错误包装：** errx.Error 实现 Unwrap 接口，支持 `errors.Is`/`errors.As` 和 `errors.Join` 多错误链

---

## 13. Edge Cases

| 场景 | 预期行为 |
|------|----------|
| lifecycx: Manager 无 Component | Start 立即返回 nil，Stop 返回 nil |
| lifecycx: 单 Component 无依赖 | 正常启动和停止 |
| lifecycx: 启动失败回滚中 Stop 也失败 | errors.Join 聚合所有错误（原错误 + 回滚错误） |
| lifecycx: Stop 在 Start 之前调用 | 返回 nil（幂等） |
| errx: nil *Error 调用 Error() | 返回 "" |
| errx: nil *Error 调用 WithRetryable/WithCode/WithSeverity | 返回 nil |
| errx: IsKind/ShouldRetry 参数为 nil | 返回 false |
| errx: errors.Join 多个 errx.Error | walkErrors 遍历所有分支 |
| healthx: Aggregate 无 statuses | 返回 name="", status="healthy", message="ok" |
| healthx: Metadata nil 时 MarshalJSON | 序列化为 {} |
| healthx: AggregateWithClock clock 为 nil | 回退到 RealClock |
| obsx: NoopLogger/NoopMetrics/NoopTracer | 所有方法静默成功 |
| obsx: SecretString 空值 | String() 返回 "" |
| retryx: Delay attempt <= 0 | 返回 0 |
| retryx: Delay BaseDelay <= 0 | 返回 0 |
| retryx: Delay 溢出保护 | 在达到 maxDuration 一半时停止加倍，设 maxDuration |
| retryx: DelayWithJitter fraction < -1 或 > 1 | 钳位到 [-1, 1] |
| retryx: DelayWithJitter 结果 < 0 | 返回 0 |
| shutdownx: Shutdown 时无 Hook | 返回 nil |
| shutdownx: 并发 Register + Shutdown | Manager 加锁保护，Register 在 Shutdown 快照后追加的 hook 不执行 |
| syncx: SemaphoreLimiter n<=0 | 默认容量为 1 |
| syncx: SemaphoreLimiter double-release | 静默忽略 |
| syncx: WorkerGroup closed 后 TryGo | 返回 false |
| syncx: WorkerGroup 无错误 | Wait() 返回 nil |
| timex: nil *FakeClock 调用 Now() | 返回 time.Time{}（零值安全） |
| timex: nil *FakeClock 调用 Advance() | 静默忽略 |
| versionx: Compatibility.Major 为空 | CompatibleWith 仅校验 Module |
| versionx: NewKey 同名同类型两次调用 | 获得不同 Key（sentinel 指针唯一） |
| contextx: 零值 Key 调用 contextKey() | panic |
| contextx: Value 类型不匹配 | 返回 (zero, false) |
| contextx: DeadlineRemaining 已过期 | 返回 (0, true) |
| validx: RequireNonEmpty 空值 | 返回 Precondition 错误 |

---

## 14. Directory Structure

```text
kernel/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── Makefile
├── LICENSE
│
├── lifecycx/              # 组件生命周期管理
│   ├── lifecycx.go
│   ├── lifecycx_test.go
│   └── example_test.go
│
├── errx/                  # 结构化错误
│   ├── errx.go
│   ├── errx_test.go
│   └── example_test.go
│
├── healthx/               # 健康检查
│   ├── healthx.go
│   ├── healthx_test.go
│   └── example_test.go
│
├── obsx/                  # 可观测抽象
│   ├── obsx.go
│   ├── obsx_test.go
│   └── example_test.go
│
├── retryx/                # 重试策略
│   ├── retryx.go
│   ├── retryx_test.go
│   └── example_test.go
│
├── shutdownx/             # 优雅停机
│   ├── shutdownx.go
│   ├── shutdownx_test.go
│   └── example_test.go
│
├── syncx/                 # 并发控制
│   ├── syncx.go
│   ├── syncx_test.go
│   └── example_test.go
│
├── timex/                 # 时钟抽象
│   ├── timex.go
│   ├── timex_test.go
│   └── example_test.go
│
├── validx/                # 前置条件校验
│   ├── validx.go
│   ├── validx_test.go
│   └── example_test.go
│
├── versionx/              # 版本信息
│   ├── versionx.go
│   ├── versionx_test.go
│   └── example_test.go
│
├── contextx/              # 类型安全上下文
│   ├── contextx.go
│   ├── contextx_test.go
│   └── example_test.go
│
├── contracttest/          # 契约测试辅助
│   ├── contracttest.go
│   ├── contracttest_test.go
│   └── example_test.go
│
├── internal/
│   └── testutil/          # 内部测试工具
│       ├── testutil.go
│       └── testutil_test.go
│
├── contracts/             # 契约验证层（API 快照、golden 行为、消费者导入测试）
│   ├── contracts_test.go
│   ├── api_docs_test.go
│   ├── golden_behavior_test.go
│   ├── release_docs_ci_test.go
│   ├── public_api/
│   ├── golden/
│   ├── examples/
│   └── consumers/
│       └── xgo/
│           └── minimal_import_test.go
│
├── examples/              # 可运行示例（每个子包对应一个示例目录）
│   ├── lifecycle/
│   ├── error_kind/
│   ├── health_checker/
│   ├── observability/
│   ├── retry_policy/
│   ├── shutdown/
│   ├── sync_group/
│   ├── clock/
│   ├── validation/
│   ├── version_info/
│   ├── context/
│   └── contract_helper/
│
├── docs/                  # 项目文档
│   ├── adr/
│   ├── design/
│   ├── governance/
│   ├── spec/
│   ├── standard/
│   └── evidence/
│
├── scripts/               # CI/发布脚本
│   └── ci/
│       └── internal/
│           └── apisnapshot/
│
└── release/               # 发布产物
    ├── manifest/
    ├── dependency/
    └── standard-sync/
```

---

## 15. Dependencies

### 15.1 go.mod

```text
module github.com/ZoneCNH/kernel

go 1.23
```

### 15.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| stdlib only | 所有 Foundation L1 模块（configx, observex, resiliencx, schedulex, testkitx 等） |
| kernel 内部子包间交叉引用（如 healthx→timex, retryx→errx, validx→errx, contextx→timex, contracttest→errx+healthx） | 所有业务域实现 |
| | 所有 L2.5 领域共享层 |
| | 所有存储/中间件扩展 |

### 15.3 内部依赖图

```text
errx      → stdlib
timex     → stdlib
validx    → errx
retryx    → errx
contextx  → stdlib, timex
healthx   → stdlib, timex
obsx      → stdlib
syncx     → stdlib
lifecycx  → stdlib
shutdownx → stdlib
versionx  → stdlib
contracttest → stdlib, errx, healthx
```

### 15.4 特殊说明

kernel 是 stdlib-only 的 L0 原语层。各子包独立可用，互不强制绑定。内部交叉引用（如 `healthx`→`timex`、`retryx`→`errx`、`contracttest`→`errx`+`healthx`）仅限于 kernel 仓库内部，不引入任何第三方依赖。上层模块可按需引入单个子包：

```go
import (
    "github.com/ZoneCNH/kernel/errx"
    "github.com/ZoneCNH/kernel/timex"
)
```

---

## 16. Testing

### 16.1 单元测试覆盖

| 子包 | 测试文件 | 覆盖重点 |
|------|----------|----------|
| lifecycx | lifecycx_test.go | Start 顺序、Stop 逆序、失败回滚、幂等性 |
| errx | errx_test.go | Error 构造、Unwrap、IsKind 遍历、AsError、链式 With* |
| healthx | healthx_test.go | Status 判断、Aggregate 聚合、Metadata 不可变性 |
| obsx | obsx_test.go | Noop 实现、SecretString 脱敏、JSON 序列化 |
| retryx | retryx_test.go | Delay 指数退避、Jitter 范围、Validate 校验 |
| shutdownx | shutdownx_test.go | LIFO 顺序、并发安全、NotifyContext |
| syncx | syncx_test.go | Acquire/Release、WorkerGroup 错误收集 |
| timex | timex_test.go | FakeClock Advance、FixedClock 不可变 |
| validx | validx_test.go | Precondition/Invariant 返回值、RequireNonEmpty |
| versionx | versionx_test.go | CompatibleWith 匹配逻辑 |
| contextx | contextx_test.go | Key 唯一性、类型安全 Value、deadline 查询 |
| contracttest | contracttest_test.go | JSON 字段断言、ErrorKind 断言 |
| internal/testutil | testutil_test.go | RequireEqual 泛型断言 |

### 16.2 验收标准（AC）

| AC 编号 | 对应 FR | 验收条件 |
|---------|---------|----------|
| AC-001 | FR-001 | lifecycx Manager.Start 按序启动，失败回滚，Manager.Stop 幂等 |
| AC-002 | FR-001 | lifecycx 启动失败时 errors.Join 包含所有已启动 Component 的 Stop 错误 |
| AC-003 | FR-002 | errx NewError/WrapError 字段完整，Error() 格式正确 |
| AC-004 | FR-002 | errx Unwrap/IsKind/AsError 全链路正确，errors.Join 多错误链通过 IsKind |
| AC-005 | FR-003 | healthx HealthStatus 构造、IsHealthy、Aggregate 逻辑正确 |
| AC-006 | FR-004 | obsx NoopLogger/NoopMetrics/NoopTracer/NoopSpan 所有方法静默成功不 panic |
| AC-007 | FR-004 | obsx SecretString 所有公开方法返回 "***"，仅 Reveal() 可访问原始值 |
| AC-008 | FR-005 | retryx Delay 指数退避 + Jitter + 溢出保护 |
| AC-009 | FR-006 | shutdownx Manager.Shutdown Hook LIFO 顺序，并发安全 |
| AC-010 | FR-006 | shutdownx NotifyContext 正确捕获 OS signal 并传播 cancel |
| AC-011 | FR-007 | timex FakeClock Advance 后 Now 返回正确时间，RealClock 使用 time.Now |
| AC-012 | FR-008 | validx Precondition/Invariant/RequireNonEmpty 返回正确的 *Error（kind/op/message） |
| AC-013 | FR-009 | versionx Compatibility.CompatibleWith 模块/版本匹配正确 |
| AC-014 | FR-010 | contextx Key 唯一性，类型安全存取，零值 Key panic |
| AC-015 | FR-011 | syncx SemaphoreLimiter Acquire/Release 并发安全 |
| AC-016 | FR-011 | syncx WorkerGroup 错误收集 + context 取消传播 |
| AC-017 | FR-012 | contracttest 断言函数在匹配/不匹配时行为正确 |
| AC-018 | BR-009 | stdlib-only gate：`go list -deps` 无非 stdlib 依赖 |

### 16.3 Given/When/Then 用例

| TC | Type | Scenario | Expected |
|-----|------|----------|----------|
| TC-001 | Unit | lifecycx 正常启动停止 | A.Start → B.Start → B.Stop → A.Stop |
| TC-002 | Unit | lifecycx 启动失败回滚 | B.Start 失败 → A.Stop 回滚 → errors.Join |
| TC-003 | Unit | lifecycx 未启动时 Stop | 返回 nil |
| TC-004 | Unit | errx 错误链遍历 | IsKind(KindTimeout) 穿透 wrap 链返回 true |
| TC-005 | Unit | errx errors.Join 多链 | IsKind 匹配 Join 中任一条错误链 |
| TC-006 | Unit | retryx 指数退避 | Delay(3) ≈ 400ms（BaseDelay×2³⁻¹） |
| TC-007 | Unit | healthx Aggregate | 多 HealthStatus Aggregate 后 Status 正确 |
| TC-008 | Unit | shutdownx LIFO 顺序 | 最后注册的 Hook 先执行 |
| TC-009 | Unit | obsx SecretString 脱敏 | String()/JSON() 返回 "***" |
| TC-010 | Unit | contextx Key 唯一性 | 不同 Key[T] 的 contextKey 不冲突 |
| TC-011 | Unit | validx 前置条件 | Precondition 失败返回 *Error（kind=validation） |
| TC-012 | CI | stdlib-only gate | go list -deps 无 kernel 外依赖 |
| TC-013 | Unit | syncx SemaphoreLimiter | Acquire 获取许可，Release 释放 |
| TC-014 | Unit | syncx WorkerGroup | 任一 worker 出错 → 收集错误 + cancel 传播 |
| TC-015 | Unit | timex FakeClock | Advance(d) 后 Now() 前进 d |
| TC-016 | Unit | shutdownx NotifyContext | SIGTERM → cancel 传播 |
| TC-017 | Unit | versionx Compatibility | CompatibleWith 模块/版本匹配正确 |
| TC-018 | Unit | contracttest | 断言匹配通过，不匹配时 Fatalf |

### 16.4 详细 Given/When/Then（全 18 用例）

**TC-001: lifecycx 正常启动停止**
Given 注册 Component A、B（按 A, B 顺序）
When 调用 Manager.Start(ctx)
Then A.Start 先于 B.Start 被调用
When 调用 Manager.Stop(ctx)
Then B.Stop 先于 A.Stop 被调用

**TC-002: lifecycx 启动失败回滚**
Given 注册 Component A、B，B.Start 返回错误
When 调用 Manager.Start(ctx)
Then A.Start 被调用，B.Start 被调用并返回错误
Then A.Stop 被调用（回滚）
Then Manager.Start 返回 errors.Join

**TC-004: errx 错误链遍历**
Given err1 = WrapError(KindTimeout, "op1", "msg1", stdErr)
And err2 = WrapError(KindConnection, "op2", "msg2", err1)
When 调用 IsKind(err2, ErrorKindTimeout)
Then 返回 true

**TC-009: obsx SecretString 脱敏**
Given s = NewSecretString("sk-abc123")
When 调用 s.String() 或 json.Marshal(s)
Then 返回 "***"（非原始值）
When 调用 s.Reveal()
Then 返回 "sk-abc123"

**TC-003: lifecycx 未启动时 Stop 幂等**
Given Manager 已创建但未 Start
When 调用 Manager.Stop(ctx)
Then 返回 nil（幂等）

**TC-005: errx errors.Join 多错误链**
Given e1 = NewError(KindTimeout, "op1", "timeout")
And e2 = NewError(KindConnection, "op2", "conn refused")
And joined = errors.Join(e1, e2)
When 调用 IsKind(joined, ErrorKindTimeout)
Then 返回 true
When 调用 IsKind(joined, ErrorKindConnection)
Then 返回 true

**TC-006: retryx 指数退避**
Given policy = RetryPolicy{MaxAttempts: 3, BaseDelay: 100ms, MaxDelay: 2s}
When 调用 policy.Delay(1)
Then 返回 100ms
When 调用 policy.Delay(3)
Then 返回 ≈ 400ms（BaseDelay × 2²）

**TC-007: healthx Aggregate 聚合**
Given h1 = HealthStatus{Status: "healthy"}, h2 = HealthStatus{Status: "degraded"}, h3 = HealthStatus{Status: "unhealthy"}
When 调用 Aggregate("all", h1, h2)
Then 返回 Status="degraded"
When 调用 Aggregate("all", h1, h2, h3)
Then 返回 Status="unhealthy"

**TC-008: shutdownx LIFO 顺序**
Given Hook A (先注册), Hook B (后注册)
When 调用 Manager.Shutdown(ctx)
Then B.Shutdown 先于 A.Shutdown 被调用

**TC-010: contextx Key 唯一性**
Given k1 = NewKey[string]("id"), k2 = NewKey[string]("id")
Then k1 != k2（不同 sentinel 指针）
When ctx = WithValue(bg, k1, "v1"); ctx = WithValue(ctx, k2, "v2")
Then Value[string](ctx, k1) 返回 ("v1", true)
Then Value[string](ctx, k2) 返回 ("v2", true)

**TC-011: validx 前置条件**
Given op = "GetUser", name = "id", value = ""
When 调用 RequireNonEmpty(op, name, value)
Then 返回 *Error{Kind: validation, Severity: warning, Message: "id must not be empty"}

**TC-012: stdlib-only gate (CI)**
Given kernel 仓库已构建
When 运行 `go list -deps ./... | grep -v "^std" | grep -v "kernel$"`
Then 无输出（零外部依赖）

**TC-013: syncx SemaphoreLimiter**
Given lim = NewSemaphoreLimiter(2)
When lim.Acquire(ctx) 调用 3 次（前两次立即返回）
Then 第三次阻塞，直到 Release() 释放一个许可

**TC-014: syncx WorkerGroup 错误收集**
Given wg = NewWorkerGroup(ctx)
When wg.Go(fn1), wg.Go(fn2) 且 fn2 返回错误
Then wg.Wait() 收集 fn2 错误，ctx 被 cancel

**TC-015: timex FakeClock**
Given clock = NewFakeClock(time.Unix(0, 0))
When clock.Advance(10 * time.Second)
Then clock.Now() 返回 time.Unix(10, 0)

**TC-016: shutdownx NotifyContext**
Given ctx = NotifyContext(parent, syscall.SIGTERM)
When 进程收到 SIGTERM
Then ctx.Done() 被关闭

**TC-017: versionx Compatibility**
Given info = BuildInfo{Module: "github.com/ZoneCNH/kernel", Version: "1.2.3"}
And compat = Compatibility{Module: "github.com/ZoneCNH/kernel", Major: "1"}
When 调用 compat.CompatibleWith(info)
Then 返回 true

**TC-018: contracttest 断言**
Given err = NewError(ErrorKindTimeout, "op", "timeout")
When 调用 AssertErrorKind(t, err, ErrorKindTimeout)
Then 测试通过（不调用 Fatalf）
When 调用 AssertErrorKind(t, err, ErrorKindConnection)
Then 测试失败（Fatalf）
## 17. Performance Budget

| 操作 | 目标 | 测量方式 |
|------|------|----------|
| errx.NewError 构造 | < 100ns | benchmark test |
| errx.IsKind 5 层链遍历 | < 1μs | benchmark test |
| healthx.Aggregate 10 元素 | < 10μs | benchmark test |
| retryx.Delay 计算 | < 100ns | benchmark test |
| 常驻内存（全子包导入） | < 5MB | profiling |

---

## 18. Observability

kernel 本身通过 `obsx` 子包定义可观测接口，不触发具体观测行为。上层模块使用 `obsx` 接口消费日志/指标/追踪能力，kernel 子包在关键路径可接受 `obsx.Logger` 等接口用于内部日志。

| 类型 | 说明 |
|------|------|
| obsx.Logger | 日志接口（Debug/Info/Warn/Error），含 context 和 Field 键值对 |
| obsx.Metrics | 指标接口（Count/Observe），含 context 和 Field 标签 |
| obsx.Tracer | 追踪接口（Start 返回 context + Span） |
| obsx.Span | 跨度接口（End/RecordError/SetFields） |
| obsx.Sanitizer | 脱敏接口，实现 Sanitize() 返回安全表示 |
| obsx.SecretString | 敏感字符串，所有公开方法返回 `"***"`，仅 Reveal() 可访问 |

---

## 19. Security

| 要求 | 实现方式 |
|------|----------|
| 敏感数据不泄露到日志 | `obsx.SecretString` 自动脱敏，String()/GoString()/JSON 均返回 "***" |
| 错误消息不含原始凭证 | `errx.Error` 只含 kind/op/message，不泄露原始配置 |
| 无硬编码密钥 | 全仓搜索通过，所有 SecretString 由调用方通过 `NewSecretString` 构造 |
| Sanitizer 接口约束 | 实现者必须保证 `Sanitize()` 不泄露原始值 |

---

## 20. CI Gate

### 20.1 通用 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 任何测试失败或 data race |
| 覆盖率 | `go test ./... -coverprofile=coverage.out && go tool cover -func=coverage.out` | 总覆盖率 < 90% |
| vet | `go vet ./...` | 任何 vet 错误 |
| lint | `golangci-lint run` | 任何 lint 错误 |
| 依赖检查 | `go mod tidy && git diff --exit-code go.mod go.sum` | go.mod 不整洁 |
| Secret 扫描 | `gitleaks detect --no-git` | 泄露 secret |
| Benchmark | `go test -bench=. -benchmem -count=3 ./...` | 结果附在 PR comment |

### 20.2 kernel 专属 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| stdlib-only | `go list -deps ./... \| grep -v "^std" \| grep -v "^github.com/ZoneCNH/kernel$"` | 任何非 stdlib 依赖 |
| public-api-snapshot | contracts 中的 API 快照对比 | 公共 API 签名变更未更新快照 |
| golden-behavior | contracts/golden_behavior_test.go | 契约行为发生变化 |

---

## 21. Upgrade Compatibility

| 变更类型 | 版本升级 |
|----------|----------|
| 任何子包公开接口删除/签名变更 | **major** |
| 新增子包公开类型/函数 | patch / minor |
| ErrorKind 新增值 | minor |
| 修复 bug | **patch** |
| 内部实现重构（公开接口不变） | patch |

---

## 22. Release DoD

- [ ] 所有子包公开类型/函数有 godoc 注释
- [ ] 每个子包有 example_test.go 示例
- [ ] CHANGELOG.md 已更新
- [ ] README.md 包含：模块定位、子包清单、验证命令
- [ ] 单元测试覆盖率 ≥ 90%
- [ ] `-race` 测试通过
- [ ] Benchmark 结果无 > 10% 回退
- [ ] `go vet` 无警告
- [ ] `golangci-lint` 无错误
- [ ] stdlib-only 检查通过
- [ ] Secret 扫描通过
- [ ] 公共 API 快照对比通过（contracts/public_api/）
- [ ] Golden 行为测试通过（contracts/golden/）
- [ ] 消费者导入测试通过（contracts/consumers/）
- [ ] `make release-preflight VERSION=vX.Y.Z` 通过
- [ ] 发布 manifest 已生成（release/manifest/）
- [ ] 所有 Functional Requirements 有对应测试

---

## 23. Open Questions

### Resolved（已解决）

- 是否需要集中式 App/Module 框架？ → **v2.0.0 决策：不做。kernel 是轻量工具包子集，各子包独立按需引用。集中式生命周期编排由 x.go 组合根负责。**
- errx 是否需要支持 errors.Join 多错误链？ → **已实现。walkErrors 支持 Unwrap() []error。**
- healthx 是否需要聚合规则？ → **已实现。Aggregate/AggregateWithClock 支持 healthy/degraded/unhealthy 优先级聚合。**

### Non-blocking（不阻塞开发）

- 是否需要为每个子包添加 structured logging 调用？（当前子包内部不使用日志，由调用方负责）→ **保持现状，子包保持纯逻辑无副作用。**
- 是否需要新增 `configx` 子包？（当前 kernel 不包含配置解析，见 §5 Non-goals）→ **不纳入 kernel，由独立的 configx 模块负责。**
