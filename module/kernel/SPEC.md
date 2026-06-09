# kernel 完整规格

> Foundation L0 原语层。stdlib-only，不依赖任何 Foundation L1 模块。

最后更新：2026-06-08

---

## 1. Metadata

- Status: Approved
- Spec-Version: v1.1.0
- Last-Updated: 2026-06-08
- Owner: ZoneCNH
- Layer: L0 原语
- Version: v0.7.3
- Repository: [github.com/ZoneCNH/kernel](https://github.com/ZoneCNH/kernel)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md)

---

### 1.1 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-08 | v1.1.0 | 对抗性审查修复：重写 §9.1 Deps 为 kernel 内接口；修正 §18 metric 命名；§22 覆盖率提至 90%；补充 FR-001/FR-002/FR-003 WHEN/THEN；BR-004~BR-009 补充违反处理；§16 补充 AC/TC 追溯链；§13 扩充至 18 条；§19 增加安全要求；§23 分类整理；FR-005 返回 GraphView；Health() 增加 ctx | ZoneCNH |
| 2026-06-07 | v1.0.0 | 初始版本 | ZoneCNH |

## 2. Summary

`kernel` 是应用的运行时骨架，负责把模块组织成一个可启动、可停止、可观测、可验证的应用。stdlib-only，零外部依赖。

---

## 3. Problem

量化交易系统由 70+ 个模块组成，每个模块有自己的启动顺序、依赖关系和生命周期。没有统一的生命周期管理，会导致：

- 模块启动顺序靠人工协调，容易出错
- 循环依赖在运行时才发现
- 优雅停机无法保证反序释放资源
- 健康检查各自为政，无法统一报告

---

## 4. Goals

- 提供 `App` / `Module` / `Lifecycle` 抽象，统一模块生命周期
- 自动检测循环依赖，启动前 fail-fast
- 按拓扑序启动、反序停止
- 统一 readiness / liveness / health 状态
- 处理启动失败、停止超时、panic
- stdlib-only，零外部依赖

---

## 5. Non-goals

- 不做配置解析细节（→ `configx`）
- 不做日志实现（→ `observex`）
- 不做重试策略（→ `resiliencx`）
- 不放交易、行情、风控、订单逻辑
- 不做存储、网络、业务 DTO
- 不做服务发现或远程调用

---

## 6. Consumers

| 消费者 | 使用方式 |
|--------|----------|
| `x.go`（组合根） | 创建 App，Register 所有模块，调用 Run |
| L1 运行时模块 | 实现 Module 接口，被 kernel 管理生命周期 |
| 业务域模块 | 实现 Module 接口，通过 Deps 接收 L1 能力 |
| 运维/监控 | 通过 Health(ctx) 查询模块状态 |

---

## 7. Functional Requirements

### FR-001: Register

WHEN 调用 `Register(m Module)` 且模块名未注册
THEN 模块加入注册表，返回 nil

WHEN 调用 `Register(m Module)` 且模块名已注册
THEN 返回 `ErrAlreadyRegistered`，注册表不变

WHEN 调用 `Register(nil)`
THEN 返回错误，注册表不变

WHEN 调用 `Register(m)` 且 App 已启动（Run 已完成）
THEN 返回 `ErrAlreadyStarted`，注册表不变

### FR-002: Run

WHEN 调用 `Run(ctx)` 且依赖图无环
THEN 按拓扑序依次调用每个模块的 `Init` → `Start`，返回 nil

WHEN 调用 `Run(ctx)` 且依赖图有环
THEN 返回 `ErrCycleDetected`，不启动任何模块

WHEN 启动过程中某模块 `Init` 失败
THEN 已 Init 的模块被 Stop，返回该模块的错误（fail-fast）

WHEN 启动过程中某模块 `Start` 失败
THEN 已 Start 的模块被 Stop，返回该模块的错误（fail-fast）

WHEN ctx 在启动过程中被取消
THEN 中断启动，已启动的模块被 Stop

WHEN 调用 `Run(ctx)` 且 App 已在运行中
THEN 返回 `ErrAlreadyRunning`

WHEN 调用 `Run(ctx)` 且 App 已 Shutdown
THEN 返回 `ErrAlreadyStopped`

### FR-003: Shutdown

WHEN 调用 `Shutdown(ctx)`
THEN 按启动反序调用每个模块的 `Stop`

WHEN 某模块 `Stop` 超过 deadline
THEN 强制跳过该模块，继续停止后续模块，返回 `ErrShutdownTimeout`

WHEN ctx 在停机过程中被取消
THEN 立即返回，记录未完成模块

WHEN 调用 `Shutdown(ctx)` 且 App 未运行（未调用 Run 或已 Shutdown）
THEN 返回 nil（幂等）

WHEN 调用 `Shutdown(ctx)` 且 Shutdown 正在进行中
THEN 返回 `ErrShutdownInProgress`

### FR-004: ModuleHealth

WHEN 调用 `ModuleHealth(name)` 且模块已注册且处于 Running 状态
THEN 返回该模块的 `HealthStatus`（Ready/Live/Message 由模块实现决定）

WHEN 调用 `ModuleHealth(name)` 且模块未注册
THEN 返回 `ErrModuleNotFound`

WHEN 调用 `ModuleHealth(name)` 且 App 尚未 Run
THEN 返回 `HealthStatus{Ready: false, Live: false}`

WHEN 调用 `ModuleHealth(name)` 且模块处于 Error 状态（启动失败）
THEN 返回 `HealthStatus{Ready: false, Live: false, Message: "<错误信息>"}`

WHEN 调用 `ModuleHealth(name)` 且模块 Health 方法 panic
THEN 返回 `HealthStatus{Ready: false, Live: false, Message: "health check panic"}`，panic 不传播

### FR-005: DependencyGraph

WHEN 调用 `DependencyGraph()`
THEN 返回当前依赖图的只读视图（`GraphView`），包含节点列表、边列表和拓扑序

---

## 8. Business Rules

| 编号 | 规则 | 违反时 |
|------|------|--------|
| BR-001 | 依赖图不允许环（检测到即 fail-fast） | 返回 `ErrCycleDetected`，不启动任何模块 |
| BR-002 | 启动顺序必须是拓扑序（依赖先于被依赖者） | 拓扑排序算法保证，违反则为算法 bug |
| BR-003 | 停止顺序必须是启动反序（被依赖者先于依赖者停止） | 反序遍历保证，违反则为算法 bug |
| BR-004 | Init 失败的模块不能进入 Start | 已 Init 的模块被 Stop，返回 `ErrStartupFailed` |
| BR-005 | Health(ctx) 必须是幂等的、无副作用的 | 模块实现不合规，kernel 返回 HealthStatus 零值（Ready=false, Live=false），调用方应检查模块实现 |
| BR-006 | Stop 超时后 force shutdown，记录未完成模块 | 如果未记录未完成模块，运维无法排查 |
| BR-007 | panic 必须被 catch，不传播到调用方 | catch 失败时返回 `ErrStartupFailed` 或 `ErrShutdownFailed` |
| BR-008 | kernel 不 import 任何非 stdlib 包 | CI stdlib-only gate 阻断 |
| BR-009 | Deps 中的接口类型由消费方组装时注入，kernel 不知道具体实现 | 编译失败 |

---

## 9. Interface Contract

### 9.1 Module / App / Lifecycle

```go
// Module 是被 kernel 管理生命周期的模块接口。
type Module interface {
    Name() string
    Init(ctx context.Context, deps Deps) error
    Start(ctx context.Context) error
    Stop(ctx context.Context) error
    Health(ctx context.Context) HealthStatus
}

// --- kernel 内定义的最小接口（替代 L1 包类型引用） ---

// Logger 是日志输出的最小接口。
// args 参数为 key-value 对，如 Info("started", "module", name, "duration", d)
type Logger interface {
    Info(msg string, args ...any)
    Warn(msg string, args ...any)
    Error(msg string, args ...any)
    Debug(msg string, args ...any)
}

// Meter 是指标采集的最小接口。
type Meter interface {
    Counter(name string) Counter
    Histogram(name string) Histogram
    Gauge(name string) Gauge
}

// Counter 是单调递增计数器。
type Counter interface {
    Incr(delta int64, labels ...string)
}

// Histogram 是直方图度量。
type Histogram interface {
    Observe(value float64, labels ...string)
}

// Gauge 是可增可减的度量。
type Gauge interface {
    Set(value float64, labels ...string)
}

// Tracer 是分布式追踪的最小接口。
type Tracer interface {
    Start(ctx context.Context, name string) (context.Context, Span)
}

// Span 是追踪跨度。
type Span interface {
    End()
    SetError(err error)
}

// ConfigReader 是配置读取的最小接口。
type ConfigReader interface {
    // Get 返回原始值，仅用于扩展场景。
    // 优先使用 GetString/GetInt/GetBool/GetDuration 等类型安全方法。
    Get(key string) any
    GetString(key string) string
    GetInt(key string) int
    GetBool(key string) bool
    GetDuration(key string) time.Duration
}

// Scheduler 是定时任务调度的最小接口。
type Scheduler interface {
    Schedule(name string, cron string, fn func(ctx context.Context)) error
    Cancel(name string) error
}

// ResilientPolicy 是弹性策略的最小接口。
type ResilientPolicy interface {
    Execute(ctx context.Context, fn func(ctx context.Context) error) error
}

// Deps 是模块 Init 时注入的依赖集合。
// 所有字段类型均为 kernel 内定义的接口，L1 包提供实现。
type Deps struct {
    Config    ConfigReader
    Logger    Logger
    Meter     Meter
    Tracer    Tracer
    Resilient ResilientPolicy
    Scheduler Scheduler
}

// HealthStatus 是模块健康状态。
type HealthStatus struct {
    Ready   bool
    Live    bool
    Message string
}

// GraphView 是依赖图的只读视图。
type GraphView interface {
    Nodes() []string
    Edges() [][2]string // [from, to]
    TopologicalOrder() []string // 构建时已验证无环，不返回 error
}

// App 是应用生命周期管理接口。
type App interface {
    Register(m Module) error
    Run(ctx context.Context) error
    Shutdown(ctx context.Context) error
    ModuleHealth(name string) HealthStatus
    DependencyGraph() GraphView // 返回只读视图，TopologicalOrder() 已保证无环
}
```text

### 9.2 用法示例

kernel 通过 `Deps` 结构体注入 L1 能力。组合根（`x.go`）负责创建 L1 实现（如 `configx.NewReader()`、`observex.NewLogger()`），在模块 `Init` 时通过 `Deps` 字段注入。kernel 本身不知道任何 L1 实现。

```go
// 组合根注入 L1 实现
app := kernel.New(
    kernel.WithStartupTimeout(30 * time.Second),
    kernel.WithShutdownTimeout(15 * time.Second),
)

// 注册模块（Init 时通过 Deps 注入 L1 能力）
app.Register(&marketDataModule{})
app.Register(&strategyModule{})

// 启动（自动拓扑序）
if err := app.Run(ctx); err != nil {
    log.Fatal(err)
}

// 停机（自动反序）
app.Shutdown(ctx)
```text

---

## 10. Data Model

### 10.1 公共错误

```go
var (
    ErrCycleDetected       = errors.New("kernel: dependency cycle detected")
    ErrModuleNotFound      = errors.New("kernel: module not found")
    ErrAlreadyRegistered   = errors.New("kernel: module already registered")
    ErrStartupFailed       = errors.New("kernel: startup failed")
    ErrShutdownTimeout     = errors.New("kernel: shutdown timeout")
    ErrNilModule           = errors.New("kernel: nil module")
    ErrAlreadyRunning      = errors.New("kernel: app already running")
    ErrAlreadyStopped      = errors.New("kernel: app already stopped")
    ErrAlreadyStarted      = errors.New("kernel: app already started, register not allowed")
    ErrShutdownInProgress  = errors.New("kernel: shutdown in progress")
)
```text

### 10.2 模块状态

```go
type ModuleState int

const (
    StateRegistered ModuleState = iota  // 已注册，未启动
    StateStarting                        // 正在启动
    StateRunning                         // 运行中
    StateStopping                        // 正在停止
    StateStopped                         // 已停止
    StateError                           // 启动/运行出错
)
```text

---

## 11. Config Schema

kernel 通过 `ConfigReader` 接口接收以下配置（见 §9.1）：

```yaml
kernel:
  startup_timeout: 30s        # 模块启动超时
  shutdown_timeout: 15s       # 优雅停机超时
  health_check_interval: 10s  # 健康检查周期
  modules: []                 # 显式模块列表（可选，默认自动发现）
```text

---

## 12. Error Handling

| 错误 | 调用方处理 |
|------|-----------|
| `ErrCycleDetected` | 修复依赖关系，不能重试 |
| `ErrAlreadyRegistered` | 检查模块名是否重复，不能重试 |
| `ErrNilModule` | 传入有效模块，不能重试 |
| `ErrStartupFailed` | 检查失败模块的 Init/Start 日志，修复后重试 |
| `ErrShutdownTimeout` | 检查哪些模块 Stop 超时，考虑增加 shutdown_timeout |
| `ErrModuleNotFound` | 检查模块名拼写，确认已 Register |
| `ErrAlreadyRunning` | App 已在运行中，不能重复调用 Run |
| `ErrAlreadyStopped` | App 已停止，需重新创建 App 实例 |
| `ErrAlreadyStarted` | App 已启动，不能在运行中 Register 新模块 |
| `ErrShutdownInProgress` | Shutdown 正在进行中，等待完成即可 |

**错误消息格式：** `"kernel: <operation>: <detail>"`
**错误包装：** 使用 `%w` 保留底层错误链

---

## 13. Edge Cases

| 场景 | 预期行为 |
|------|----------|
| 空 App（无模块注册） | Run 立即返回 nil |
| 单模块无依赖 | 正常启动和停止 |
| 自引用依赖（A→A） | 视为环，`ErrCycleDetected` |
| 并发 Register | 需要加锁，保证并发安全 |
| 并发 Run | 第二次调用返回 `ErrAlreadyRunning` |
| Run 后再 Register | 返回 `ErrAlreadyStarted`（已启动不允许新增） |
| 模块 Start panic | catch panic，返回 `ErrStartupFailed` |
| 模块 Stop panic | catch panic，记录日志，继续停止后续模块 |
| ctx 在 Init 期间取消 | 中断 Init，已 Init 的模块被 Stop |
| 100+ 模块 | 拓扑排序 < 1ms |
| Shutdown() 被调用两次 | 幂等，第二次返回 nil |
| Shutdown() 在 Run() 之前调用 | 返回 nil |
| Register() 在 Shutdown() 完成后调用 | 返回 `ErrAlreadyStopped` |
| 依赖链深度 >100 | 正常处理，拓扑排序性能 <1ms |
| ModuleHealth() 在 Run() 尚未调用时 | 返回 `HealthStatus{Ready: false, Live: false}` |
| 模块 Init 内部调用 Register | 返回 `ErrAlreadyStarted`（不允许） |
| 模块 Start 耗时 >startup_timeout | 单模块超时被 Stop，fail-fast |
| Shutdown 过程中某模块 Stop panic | catch panic，记录日志，继续停止后续模块 |
| `Run()` 和 `Shutdown()` 并发调用 | 需加锁，一个完成后另一个才能执行 |
| 模块 `Init` 内部调用 `Shutdown()` | 避免死锁，Init 内不应阻塞等待 Shutdown |
| ctx 超时 < 模块 Init 耗时 | Init 被 ctx 中断，返回 ctx.Err()，已 Init 模块被 Stop |

---

## 14. Directory Structure

```text
kernel/
├── go.mod                      # stdlib-only，无外部依赖
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go                      # 包级文档
├── kernel.go                   # App / Module / Deps 顶层导出
├── registry.go                 # 模块注册表
├── graph.go                    # 依赖图（拓扑排序、环检测）
├── lifecycle.go                # 启动 / 停止 / 健康检查
├── shutdown.go                 # 优雅停机（signal handling、deadline）
├── health.go                   # HealthStatus
├── errors.go                   # 公共错误变量
├── options.go                  # Option 模式配置
├── internal/
│   ├── dag/                    # DAG 实现（拓扑排序、环检测）
│   └── signal/                 # OS signal 处理
├── testdata/
│   └── *.golden
├── example_test.go
├── benchmark_test.go
└── integration_test.go         # //go:build integration
```text

---

## 15. Dependencies

### 15.1 go.mod

```text
module github.com/ZoneCNH/kernel

go 1.23
```text

### 15.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| stdlib only | configx, observex, resiliencx, schedulex, testkitx |
| | 所有业务域实现 |
| | 所有 L2.5 领域共享层 |
| | 所有存储/中间件扩展 |

### 15.3 特殊说明

kernel 是 stdlib-only 的 L0 原语层。`Deps` 中的所有字段类型均为 kernel 包内定义的最小接口（`ConfigReader`、`Logger`、`Meter`、`Tracer`、`ResilientPolicy`、`Scheduler`），不引用任何 L1 包。L1 包（如 `configx`、`observex`）提供这些接口的实现，由组合根 `x.go` 在组装时注入。这种设计保证 kernel 的 import graph 只包含 stdlib，符合 CONSTITUTION 第三条 L0 层级约束。

---

## 16. Testing

### 16.1 单元测试

| 测试场景 | 验证点 |
|----------|--------|
| 循环依赖检测 | `Register(A→B→A)` 返回 `ErrCycleDetected` |
| 拓扑序启动 | `Run` 按依赖序调用 `Init` → `Start` |
| 反序停止 | `Shutdown` 按启动反序调用 `Stop` |
| 启动失败 fail-fast | 模块 A 启动失败 → B 不启动 → App 返回错误 |
| 停止超时 force | 模块 Stop 超时 → deadline 后强制返回 |
| 健康检查 | `Health(ctx)` 幂等、无副作用 |
| context 取消 | parent ctx cancel → 所有模块收到通知 |
| 重复注册 | 同一模块名注册两次 → `ErrAlreadyRegistered` |
| 模块未找到 | `ModuleHealth("unknown")` → `ErrModuleNotFound` |
| panic 隔离 | 模块 Start panic → 被 catch → App 返回错误 |

### 16.2 验收标准（AC）

| AC 编号 | 对应 FR | 验收条件 | 覆盖 TC |
|---------|---------|----------|---------|
| AC-001 | FR-001 | Register nil/重复/新模块行为正确 | TC-008, TC-015 |
| AC-002 | FR-002 | Run 按拓扑序启动，失败回滚 | TC-001, TC-002, TC-003, TC-006 |
| AC-003 | FR-003 | Shutdown 按反序停止，幂等 | TC-001, TC-004, TC-011, TC-012 |
| AC-004 | BR-004 | 当模块 Init 失败时，该模块不会收到 Start 调用 | TC-018 |
| AC-005 | BR-005 | ModuleHealth 多次调用返回相同结果，不触发任何副作用 | TC-009, TC-013 |
| AC-006 | FR-005 | DependencyGraph 返回正确的 GraphView | TC-010 |
| AC-007 | BR-007 | 模块 Start/Stop panic 时，panic 被捕获并转换为错误 | TC-006, TC-016, TC-017 |
| AC-008 | BR-009 | kernel 包内无 L1 包的 import 语句 | TC-019 |

### 16.3 Given/When/Then 用例

**TC-001: 正常启动和停止**
Given 注册模块 A（无依赖）
When 调用 Run
Then A.Init 被调用，然后 A.Start 被调用
When 调用 Shutdown
Then A.Stop 被调用

**TC-002: 循环依赖**
Given 注册模块 A 依赖 B，B 依赖 A
When 调用 Run
Then 返回 ErrCycleDetected
And 无模块被启动

**TC-003: 启动失败回滚**
Given 注册模块 A（无依赖）和 B（依赖 A）
When A.Start 成功，B.Start 失败
Then A.Stop 被调用
And 返回 B 的错误

**TC-004: 停止超时**
Given 模块 A.Stop 需要 10s，shutdown_timeout = 1s
When 调用 Shutdown
Then 1s 后强制返回 ErrShutdownTimeout

**TC-005: context 取消**
Given parent context 已 cancel
When 调用 Run
Then 已启动模块收到 cancel 并退出

**TC-006: panic 隔离**
Given 模块 A.Start panic
When 调用 Run
Then panic 被转换为错误并触发已启动模块回滚

**TC-007: 模块未找到**
Given 未注册模块 unknown
When 调用 ModuleHealth("unknown")
Then 返回 ErrModuleNotFound

**TC-008: 重复注册**
Given 模块 A 已注册
When 再次注册同名模块
Then 返回 ErrAlreadyRegistered

**TC-009: 模块健康查询**
Given 模块 A 处于 Running
When 调用 ModuleHealth("A")
Then 返回 A 的健康状态且不触发副作用

**TC-010: 依赖图输出**
Given 注册 A -> B 依赖关系
When 导出依赖图
Then 输出包含 A、B 和 A depends-on B

**TC-011: Shutdown 幂等**
Given App 已成功 Shutdown
When 再次调用 Shutdown
Then 返回 nil，无模块被重复 Stop

**TC-012: Shutdown before Run**
Given App 已注册模块但未调用 Run
When 调用 Shutdown
Then 返回 nil，无模块被调用

**TC-013: Health before Run**
Given App 已注册模块但未调用 Run
When 调用 ModuleHealth("A")
Then 返回 HealthStatus{Ready: false, Live: false}

**TC-014: 深依赖链（50+ 层）**
Given 注册 50 个模块形成线性链 A1→A2→...→A50
When 调用 Run
Then 按 A1, A2, ..., A50 顺序启动，拓扑排序 <1ms

**TC-015: 并发 Register 安全**
Given 多个 goroutine 同时 Register 不同模块
When 并发调用 Register
Then 无 data race，所有模块正确注册

**TC-016: Init panic 隔离**
Given 模块 A.Init panic
When 调用 Run
Then panic 被捕获，返回 ErrStartupFailed，不传播到调用方

**TC-017: Stop panic 隔离**
Given 模块 A.Stop panic
When 调用 Shutdown
Then panic 被捕获，记录日志，后续模块继续被 Stop

**TC-018: Init 失败不进入 Start**
Given 模块 A.Init 返回错误
When 调用 Run
Then A.Start 不被调用，A.Stop 被调用（清理已 Init 资源）

**TC-019: stdlib-only gate**
Given kernel 包已编译
When 运行 `go list -deps ./... | grep -v "^std" | grep -v "^github.com/ZoneCNH/kernel$"`
Then 无输出（无非 stdlib 依赖）

### 16.4 Benchmark

| 场景 | 目标 |
|------|------|
| 50 模块注册 + 依赖图校验 | < 10ms |
| 冷启动（不含业务模块） | < 100ms |
| 依赖图拓扑排序（100 节点） | < 1ms |

### 16.5 集成测试

| 场景 | 验证点 |
|------|--------|
| 完整启动-运行-停止 | App.Run → 模块全部 Running → signal → Shutdown → 全部 Stopped |
| 启动失败回滚 | 部分模块 Init 成功、Start 失败 → 已 Init 的模块被 Stop |

---

## 17. Performance Budget

| 操作 | 目标 | 测量方式 |
|------|------|----------|
| 冷启动（不含业务模块） | < 100ms | benchmark test |
| 模块注册 + 依赖图校验 | < 10ms / 50 模块 | benchmark test |
| graceful shutdown（无阻塞模块） | < 5s | integration test |
| 常驻内存 | < 2MB | profiling |

---

## 18. Observability

| 类型 | 名称 | 说明 |
|------|------|------|
| metric | `foundationx_kernel_module_start_duration_ms` | histogram，模块启动耗时（毫秒） |
| metric | `foundationx_kernel_module_stop_duration_ms` | histogram，模块停止耗时（毫秒） |
| metric | `foundationx_kernel_module_status` | gauge，模块运行状态（0=stopped, 1=starting, 2=running, 3=stopping, 4=error） |
| log | `kernel.module.starting` | info，模块开始启动，含 module name |
| log | `kernel.module.started` | info，模块启动完成，含 duration |
| log | `kernel.module.start_failed` | error，模块启动失败，含 error + module name |
| log | `kernel.shutdown.initiated` | info，收到停机信号 |
| log | `kernel.shutdown.completed` | info，停机完成，含 duration |
| log | `kernel.dependency.cycle` | error，检测到循环依赖，含 cycle path |
| span | `foundationx_kernel_startup` | 根 span，包含所有模块启动子 span |
| span | `foundationx_kernel_shutdown` | 根 span，包含所有模块停止子 span |

---

## 19. Security

| 要求 | 实现方式 |
|------|----------|
| 启动错误不泄露配置细节 | 错误消息包含模块名和错误类型，不包含配置值 |
| shutdown 不泄露内部状态 | 错误消息只包含超时模块名，不包含内部堆栈 |
| 模块不应通过 Deps 接口访问非自身命名空间的配置 | ConfigReader.Get 应限定在模块自身配置路径下，由组合根注入时约束 |

---

## 20. CI Gate

### 20.1 通用 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 任何测试失败或 data race |
| 覆盖率 | `go test ./... -coverprofile=cover.out && go tool cover -func=cover.out` | 总覆盖率 < 90% |
| vet | `go vet ./...` | 任何 vet 错误 |
| lint | `golangci-lint run` | 任何 lint 错误 |
| 依赖检查 | `go mod tidy && git diff --exit-code go.mod go.sum` | go.mod 不整洁 |
| Secret 扫描 | `gitleaks detect --no-git` | 泄露 secret |
| Benchmark | `go test -bench=. -benchmem -count=3 ./...` | 结果附在 PR comment |

### 20.2 kernel 专属 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| stdlib-only | `go list -deps ./... \| grep -v "^std" \| grep -v "^github.com/ZoneCNH/kernel$"` | 任何非 stdlib 依赖 |
| no-hidden-goroutine | `grep -rn "go func" --include="*.go" . \| grep -v _test.go \| grep -v internal/` | 非 internal 包启动 goroutine |

---

## 21. Upgrade Compatibility

| 变更类型 | 版本升级 |
|----------|----------|
| Module interface 变更 | **major**（所有依赖模块需同步更新） |
| 新增可选配置字段 | patch / minor |
| 新增必填配置字段 | **minor**（带默认值） |
| 修复 bug | **patch** |

---

## 22. Release DoD

- [ ] 所有公共接口有 godoc 注释
- [ ] 所有公共类型有示例代码
- [ ] CHANGELOG.md 已更新
- [ ] README.md 包含：模块定位、快速开始、配置说明、API 概览
- [ ] 单元测试覆盖率 ≥ 90%
- [ ] `-race` 测试通过
- [ ] Benchmark 结果无 > 10% 回退
- [ ] `go vet` 无警告
- [ ] `golangci-lint` 无错误
- [ ] stdlib-only 检查通过
- [ ] Secret 扫描通过
- [ ] 公共 API 无破坏性变更（或已 bump major）
- [ ] 所有 Functional Requirements 有对应测试（通过追溯矩阵 STATUS 列验证）
- [ ] 所有 Edge Cases 有对应测试（通过 §16.3 TC 覆盖验证）

---

## 23. Open Questions

### Blocking（阻塞开发）

- 是否需要支持模块间依赖注入（除了通过 Deps 结构体）？→ **决策：仅通过 Deps 注入，不支持模块间直接依赖注入**

### Non-blocking（不阻塞开发）

- 模块是否需要支持动态注册（运行时新增模块）？当前设计只允许启动前注册。→ **决策：MVP 不支持，保持启动前注册**
- health check 是否需要支持自定义检查间隔（per-module）？→ **决策：MVP 使用全局间隔，未来可扩展**
