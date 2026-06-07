# 基础模块可执行规格

> 本文是 `foundation-modules.md` 的执行层补充。
> 定位、边界、故障模式、性能预算见 `foundation-modules.md`。
> 契约签名、目录形态、依赖矩阵、CI、测试、发布检查清单见本文。

最后更新：2026-06-07

---

## 0. 分层前提

Foundation 第一阶段只固化 6 个基础模块：

```text
xlib-standard：标准事实源 / 模板 / Gate / Evidence，不进入业务运行时
    ↓
kernel：L0 原语层，stdlib-only
    ↓
configx / observex / resiliencx / schedulex：L1 运行时横切能力
    ↓
testkitx：L1 测试专用能力，只能 test-only 使用
    ↓
x.go：组合根，负责显式装配和生命周期 wiring
```text

硬约束：

- `kernel` 不是 App runtime，不负责模块注册、依赖图、配置注入或业务生命周期编排。
- `x.go` 是组合根；基础模块不得反向依赖 `x.go`。
- `configx`、`observex`、`resiliencx`、`schedulex` 可依赖 `kernel`，不得互相硬依赖。
- `resiliencx` 和 `schedulex` 的观测输出通过本地接口、事件或 adapter 完成，不形成核心 go.mod 依赖边。
- `testkitx` 不得出现在任何生产 import graph 中。

---

## 1. 模块契约

以下 Go 片段描述稳定外部契约形状。具体包名、泛型约束和错误类型可在实现时细化，但不得改变职责边界。

### 1.1 `kernel`

`kernel` 是 L0 标准库扩展，拥有最小、稳定、无外部依赖的基础原语。

```go
// errx
type ErrorKind string
type Severity string

type Error interface {
    error
    Kind() ErrorKind
    Severity() Severity
    Retryable() bool
    Unwrap() error
}

type ErrorMeta struct {
    Kind      ErrorKind `json:"kind"`
    Severity  Severity  `json:"severity"`
    Retryable bool      `json:"retryable"`
    Message   string    `json:"message"`
}

// timex
type Clock interface {
    Now() time.Time
    After(d time.Duration) <-chan time.Time
    Sleep(ctx context.Context, d time.Duration) error
}

// contextx
type Key[T any] struct {
    Name string
}

func WithValue[T any](ctx context.Context, key Key[T], value T) context.Context
func Value[T any](ctx context.Context, key Key[T]) (T, bool)

// lifecycx / shutdownx
type Component interface {
    Name() string
    Start(ctx context.Context) error
    Stop(ctx context.Context) error
}

type ShutdownGroup interface {
    Add(name string, fn func(context.Context) error)
    Run(ctx context.Context) error // LIFO
}

// healthx
type HealthState string

const (
    HealthStarting     HealthState = "starting"
    HealthReady        HealthState = "ready"
    HealthDegraded     HealthState = "degraded"
    HealthUnhealthy    HealthState = "unhealthy"
    HealthShuttingDown HealthState = "shutting_down"
)

type HealthReport struct {
    State   HealthState       `json:"state"`
    Message string            `json:"message,omitempty"`
    Checks  map[string]string `json:"checks,omitempty"`
}

// retryx
type Backoff interface {
    Next(attempt int) time.Duration
}

type RetryMarker interface {
    Retryable() bool
}
```text

约束：

- 只允许 Go 标准库。
- 不 import `configx`、`observex`、`resiliencx`、`schedulex`、`x.go` 或业务模块。
- 不启动隐藏后台 goroutine。
- 不持有全局可变单例。
- `retryx` 只包含 backoff、retry marker、轻量 retry loop；完整 timeout、circuit、bulkhead、rate limit、fallback 属于 `resiliencx`。
- `obsx` 只能放极简 no-vendor interface，不能替代 `observex`。

### 1.2 `configx`

`configx` 负责显式配置加载、合并、解码、校验、脱敏、来源追踪和 effective manifest。

```go
type Source interface {
    Name() string
    Load(ctx context.Context) (map[string]Value, error)
}

type Value struct {
    Raw         string
    Sensitive   bool
    Source      string
    SourceOrder int
}

type Loader interface {
    Load(ctx context.Context, sources ...Source) (Snapshot, error)
}

type Snapshot interface {
    Lookup(key string) (Value, bool)
    Decode(target any) error
    Provenance() map[string]Provenance
    Sanitized() map[string]any
    Manifest() Manifest
    Hash() string
}

type Provenance struct {
    Key       string `json:"key"`
    Source    string `json:"source"`
    Sensitive bool   `json:"sensitive"`
}

type Manifest struct {
    Hash       string                 `json:"hash"`
    Values     map[string]any         `json:"values"`
    Provenance map[string]Provenance  `json:"provenance"`
    Schema     map[string]FieldSchema `json:"schema,omitempty"`
}

type FieldSchema struct {
    Type      string `json:"type"`
    Required  bool   `json:"required"`
    Sensitive bool   `json:"sensitive"`
    Default   string `json:"default,omitempty"`
}

type Validator[T any] interface {
    Validate(ctx context.Context, cfg T) error
}
```text

约束：

- 所有 source 由调用方显式传入；不自动发现配置文件。
- 合并顺序必须可预测，推荐 `defaults < file < env < override`。
- provenance 是强制能力，每个 effective key 必须能说明来源和敏感性。
- manifest 必须是脱敏后的稳定输出，可用于 release/runtime evidence。
- 不创建全局 `Config` 单例。
- 不直接接 Vault、KMS、Kubernetes Secret、云 Secret Manager；真实 secret backend 应放部署 adapter 或未来 `secrectx`。
- 不在核心包启动 watch/reload goroutine。需要动态配置时必须作为显式子模块和独立契约。
- 不依赖 `observex`、`resiliencx`、`schedulex`、`x.go` 或业务模块。

### 1.3 `observex`

`observex` 负责 vendor-neutral 可观测性语义契约，而不是具体监控 SDK。

```go
type Field struct {
    Key       string
    Value     any
    Sensitive bool
}

type Logger interface {
    Debug(ctx context.Context, msg string, fields ...Field)
    Info(ctx context.Context, msg string, fields ...Field)
    Warn(ctx context.Context, msg string, fields ...Field)
    Error(ctx context.Context, msg string, err error, fields ...Field)
}

type Meter interface {
    Counter(name string, labels ...Label) Counter
    Gauge(name string, labels ...Label) Gauge
    Histogram(name string, labels ...Label) Histogram
    Timer(name string, labels ...Label) Timer
}

type Tracer interface {
    Start(ctx context.Context, name string, attrs ...Field) (context.Context, Span)
}

type Span interface {
    Add(fields ...Field)
    Error(err error)
    Finish()
}

type Label struct {
    Key   string
    Value string
}

type LabelPolicy interface {
    Validate(name string, labels []Label) error
}

type Redactor interface {
    Redact(fields ...Field) []Field
}
```text

约束：

- 核心包不硬绑定具体日志、指标、追踪供应商 SDK。
- 核心包不读取配置、不创建隐藏全局 logger/meter/tracer。
- 必须提供 noop implementation，未注入时安全运行。
- 必须提供 memory recorder，服务测试和 smoke。
- label policy 默认要求低基数、非敏感、lower snake case。
- 默认允许 label：`module`、`component`、`operation`、`status`、`error_kind`。
- 默认禁止 label：`order_id`、`user_id`、`account_id`、`api_key`、`secret`、`token`、`trace_id`。
- `symbol`、`exchange` 必须分级治理；未列入白名单前不得进入默认 metrics label。
- `errx.Kind` 可映射到 metric label 和 span status。

### 1.4 `resiliencx`

`resiliencx` 是 L1 operational resilience runtime。它处理不稳定外部依赖和任务执行的故障控制，不处理交易风控。

```go
type Policy struct {
    Timeout     TimeoutPolicy
    Retry       RetryPolicy
    Circuit     CircuitPolicy
    Bulkhead    BulkheadPolicy
    RateLimit   RateLimitPolicy
    Fallback    FallbackPolicy
    Budget      BudgetPolicy
    Classifier  ErrorClassifier
    Idempotency IdempotencyPolicy
    Observer    Observer
    Clock       kernelClock
}

type Executor interface {
    Do(ctx context.Context, op Operation) error
}

type Operation struct {
    Name       string
    Idempotent bool
    Run        func(context.Context) error
    Fallback   func(context.Context, error) error
}

type ErrorClassifier interface {
    Classify(error) Decision
}

type Decision struct {
    Retryable bool
    Kind      string
}

type Observer interface {
    OnEvent(ctx context.Context, event Event)
}

type Event struct {
    Policy    string        `json:"policy"`
    Operation string        `json:"operation"`
    Attempt   int           `json:"attempt"`
    Status    string        `json:"status"`
    ErrorKind string        `json:"error_kind,omitempty"`
    Duration  time.Duration `json:"duration"`
}
```text

组合顺序：

```text
deadline budget
  -> timeout
  -> bulkhead
  -> circuit
  -> rate limit
  -> retry
  -> fallback
```text

约束：

- 可依赖 `kernel`，不得依赖 `configx`、`observex`、`schedulex`、`x.go` 或业务模块。
- 观测输出只能通过 `Observer`/event/callback 或 adapter 完成。
- retry 必须受 `Idempotent` 或显式 idempotency policy 约束；下单类请求不得被默认重试。
- context cancellation 必须优先于 retry/backoff。
- circuit breaker、bulkhead、rate limiter 可有状态，但状态必须实例化在 policy/executor 中，不得使用隐藏全局状态。
- fake clock 必须覆盖 timeout/retry/circuit half-open 等确定性测试。

### 1.5 `schedulex`

`schedulex` 是确定性任务调度库，不是分布式任务平台。

```go
func NewScheduler(options Options) Scheduler

type Options struct {
    Clock          Clock
    EventSink      EventSink
    MaxConcurrency int
}

type Clock interface {
    Now() time.Time
    After(d time.Duration) <-chan time.Time
    Sleep(ctx context.Context, d time.Duration) error
}

type Scheduler interface {
    AddJob(job Job) error
    Start(ctx context.Context) error
    Shutdown(ctx context.Context) error
    Snapshot() Snapshot
}

type Job struct {
    Name      string
    Trigger   Trigger
    Handler   func(context.Context) error
    Misfire   MisfirePolicy
    Overlap   OverlapPolicy
    Jitter    JitterPolicy
    EventSink EventSink
    Locker    Locker
}

type Trigger interface {
    Next(after time.Time) (time.Time, bool)
}

type EventSink interface {
    OnJobRun(ctx context.Context, event JobRunEvent)
}

type JobRunEvent struct {
    JobName      string    `json:"job_name"`
    ScheduledAt  time.Time `json:"scheduled_at"`
    StartedAt    time.Time `json:"started_at"`
    FinishedAt   time.Time `json:"finished_at"`
    Status       string    `json:"status"`
    ErrorKind    string    `json:"error_kind,omitempty"`
    Attempt      int       `json:"attempt"`
}

type Locker interface {
    Acquire(ctx context.Context, key string, ttl time.Duration) (Lease, error)
}

type Lease interface {
    Release(ctx context.Context) error
    Renew(ctx context.Context, ttl time.Duration) error
}
```text

约束：

- 支持 `Once`、`Every`、五字段 `Cron`、`DailyAt`。
- 所有时间决策必须通过 injected clock 完成。
- misfire policy：`skip`、`run_once`、`catch_up`。
- overlap policy：`skip`、`queue_one`、`allow`。
- deterministic jitter 必须可复现。
- 核心包只声明 `Locker` 接口，不内置 Redis/Postgres 等实现。
- 不直接依赖 `resiliencx`；需要 retry/circuit/bulkhead 时由调用方包装 `Handler`。
- 不直接依赖 `observex`；通过 `EventSink` 输出事件。
- 不保证 exactly-once。

### 1.6 `testkitx`

`testkitx` 是测试专用能力库。

最小调用契约：

```go
type TestingT interface {
    Helper()
    Errorf(format string, args ...any)
    Fatalf(format string, args ...any)
}

type Clock interface {
    Now() time.Time
    Sleep(ctx context.Context, d time.Duration) error
}

// assertx
func Equal[T comparable](t TestingT, want, got T)
func NoError(t TestingT, err error)
func ErrorKind(t TestingT, err error, want string)
func Eventually(t TestingT, options EventuallyOptions, check func(context.Context) (bool, error))

type EventuallyOptions struct {
    Timeout  time.Duration
    Interval time.Duration
    Clock    Clock
}

// golden
type GoldenOptions struct {
    Path      string
    Update    bool
    Normalize func([]byte) ([]byte, error)
}

func AssertJSON(t TestingT, options GoldenOptions, got any)
func AssertBytes(t TestingT, options GoldenOptions, got []byte)

// contract
type Contract struct {
    Name    string
    Version string
    Schema  []byte
    Payload any
}

func Hash(contract Contract) (string, error)
func AssertHash(t TestingT, contract Contract, want string)

// fixture
type FixtureOptions struct {
    Env  map[string]string
    Home bool
}

type Fixture struct {
    Dir     string
    Home    string
    Env     map[string]string
    Cleanup func()
}

func NewFixture(t TestingT, options FixtureOptions) Fixture

// harness
type Command struct {
    Path    string
    Args    []string
    Env     map[string]string
    Dir     string
    Timeout time.Duration
}

type CommandResult struct {
    ExitCode  int
    Stdout    []byte
    Stderr    []byte
    EnvDigest string
    Duration  time.Duration
}

func RunCommand(t TestingT, command Command) CommandResult

// boundarytest
type BoundaryRule struct {
    Root          string
    ForbidImports []string
    IncludeTests  bool
}

func CheckImports(t TestingT, rule BoundaryRule)
```text

能力：

- `assertx`：稳定断言、错误断言、eventually。
- `golden`：JSON/bytes golden 对比，默认不更新。
- `contract`：contract hash、schema fingerprint。
- `fixture`：临时目录、HOME、module、env 隔离。
- `harness`：命令执行、stdout/stderr/env digest evidence。
- `clocktest`：fake clock / deterministic time。
- `obstest`：log/metric/trace recorder。
- `leaktest`：goroutine leak 检查。
- `boundarytest`：生产 import graph 扫描。
- `manifesttest`：release manifest fixture。

约束：

- 不作为 production dependency。
- 生产 Go 文件不得 import `testkitx`。
- 不读取真实生产环境变量、密钥或实盘路径。
- 不启动真实 Redis/Postgres/Kafka。
- 不替代下游 L2/L3 integration、chaos、soak 或真实外部系统测试。

---

## 2. 目录形态

### 2.1 `kernel`

```text
pkg/kernel/
  errx/
  timex/
  contextx/
  lifecycx/
  shutdownx/
  healthx/
  validx/
  syncx/
  versionx/
  retryx/
  obsx/
```text

### 2.2 `configx`

```text
pkg/configx/
  source/
    env/
    file/
    json/
    toml/
    yaml/
    map/
  decode/
  provenance/
  redact/
  manifest/
  schema/
  configx.go
```text

### 2.3 `observex`

```text
pkg/observex/
  logger.go
  metrics.go
  tracer.go
  field.go
  label.go
  redact.go
  health.go
  noop/
  recorder/
```text

供应商绑定只允许放在显式 adapter 包或下游仓库，不属于核心契约。

### 2.4 `resiliencx`

```text
pkg/resiliencx/
  timeout.go
  retry.go
  circuit.go
  bulkhead.go
  ratelimit.go
  fallback.go
  budget.go
  classifier.go
  idempotency.go
  event.go
  policy.go
```text

### 2.5 `schedulex`

```text
pkg/schedulex/
  scheduler.go
  job.go
  trigger/
    once.go
    every.go
    cron.go
    daily.go
  clock.go
  misfire.go
  overlap.go
  jitter.go
  event.go
  locker.go
  snapshot.go
```text

### 2.6 `testkitx`

```text
pkg/testkitx/
  assertx/
  golden/
  contract/
  fixture/
  harness/
  clocktest/
  obstest/
  leaktest/
  boundarytest/
  manifesttest/
```text

---

## 3. go.mod 依赖契约

Go baseline：`1.23`。

| 模块 | 允许依赖 | 禁止依赖 |
| --- | --- | --- |
| `kernel` | Go 标准库 | 任何第三方、任何 Foundation L1、`x.go`、业务模块 |
| `configx` | `kernel`、必要解析库 | `observex`、`resiliencx`、`schedulex`、`x.go`、业务模块 |
| `observex` | `kernel` | 供应商 SDK、`configx`、`resiliencx`、`schedulex`、`x.go`、业务模块 |
| `resiliencx` | `kernel` | `configx`、`observex`、`schedulex`、`x.go`、业务模块 |
| `schedulex` | `kernel` | `configx`、`observex`、`resiliencx`、`x.go`、业务模块 |
| `testkitx` | 测试期可依赖 5 个基础模块 | 被生产包依赖 |

`foundationx` 旧依赖只允许作为过渡兼容垫片存在；新增代码不得引入新的 `foundationx` import。

---

## 4. CI Gate

每个基础模块至少提供：

```text
make test
make race
make lint
make boundary
make contract
make secret-scan
make evidence
```text

基础规则：

- `kernel`：stdlib-only、no hidden goroutine、API snapshot、no global mutable singleton。
- `configx`：source precedence golden、provenance required、redaction golden、manifest hash stable。
- `observex`：label policy checker、redaction leak test、noop/recorder contract。
- `resiliencx`：deterministic retry、timeout cancellation、circuit half-open、bulkhead reject、idempotency guard、event golden。
- `schedulex`：trigger determinism、timezone/DST golden、misfire/overlap golden、lock contract test。
- `testkitx`：production import boundary scanner、golden/contract/harness evidence。

---

## 5. Release DoD

发布前必须产生：

- `go test ./...` 通过。
- `go test -race ./...` 对核心包通过。
- dependency matrix 检查通过。
- public API snapshot 或 contract hash 已更新。
- secret scan 通过。
- README、`foundation-modules.md`、本文档与 `FOUNDATION-DEPS.yaml` 无冲突。
- sanitized evidence manifest 包含版本、Go baseline、依赖摘要、测试摘要和配置/观测契约摘要。

---

## 6. 最小修复顺序

P0：

1. 修正 `resiliencx` 身份：从标准模板仓库叙事改为 operational resilience runtime。
2. 明确 `xlib-standard` 只做标准源、模板、gate、evidence。
3. 修正依赖矩阵：L1 模块只向下依赖 `kernel`，观测集成采用 interface-only。
4. 统一 Go baseline 到 `1.23`，或全体升级前保持兼容声明。
5. 建立 `make boundary` 和 `make contract` 的最小实现。

P1：

1. 为每个模块补最小 DoD 测试。
2. 为 `resiliencx` 增加 timeout/retry/circuit/bulkhead/rate/fallback/budget/classifier/idempotency/event。
3. 为 `schedulex` 增加 DST/misfire/overlap golden。
4. 为 `configx` 输出 sanitized manifest + hash。
5. 为 `observex` 固化 label/redaction/health contract。

P2：

1. 评估是否新建 `secrectx`。
2. 将稳定 gate 独立成 `xlibgate`，或保留在 `xlib-standard/scripts`。
3. 按真实需求增加 adapter 仓库，不污染核心模块。
