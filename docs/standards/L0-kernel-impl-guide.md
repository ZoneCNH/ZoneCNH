# L0 原语层（kernel）实现规范

> **效力层级**：`CONSTITUTION.md` §1-§5、§7-§9 > 本文档 > `go-coding-standards.md`
> 本文档是 `go-coding-standards.md` 的 **L0 专属覆盖层**，仅描述 L0 特有约束。

---

## 1. 层定义与模块清单

**L0 是整个 FoundationX 的依赖根**，正确性要求最高。

| 属性 | 要求 |
|------|------|
| 外部依赖 | **stdlib only**，绝对禁止任何第三方包 |
| 测试覆盖率 | **100%**（CONSTITUTION §5.1 强制） |
| 竞态测试 | 必须通过 `-race` |
| 单包 API | 每个子包独立可用，互不绑定 |

当前 L0 模块：**`kernel`**，包含 12 个子包：

| 子包 | 职责 |
|------|------|
| `lifecycx` | 组件有序启动/逆序停止，失败自动回滚 |
| `errx` | 结构化错误（kind/severity/op/code/retryable） |
| `healthx` | 健康检查状态、探针接口、聚合规则 |
| `obsx` | Logger/Metrics/Tracer/Span 接口（无供应商绑定）+ Noop 实现 |
| `retryx` | 指数退避重试策略，可重试错误判断 |
| `shutdownx` | LIFO 关闭钩子管理，OS 信号绑定 |
| `syncx` | 上下文感知并发限制器（信号量）、WorkerGroup |
| `timex` | 可注入时钟接口（RealClock/FixedClock/FakeClock） |
| `validx` | 前置条件和不变量校验助手 |
| `versionx` | 构建版本元数据，兼容性判断 |
| `contextx` | 类型安全 context key/value，deadline 查询工具 |
| `contracttest` | L1 复用的契约测试助手（test-only） |

---

## 2. 零外部依赖原则

**kernel 的 go.mod 不得有任何 require 条目。**

```go
// go.mod 合法格式
module github.com/ZoneCNH/kernel

go 1.22
// 无 require 块
```

验证命令（CI 中输出非空则阻断）：

```bash
grep -c "require" go.mod   # 必须为 0
```

---

## 3. 子包设计规则

每个子包**不得 import 同模块其他子包**，必须能被单独引用。

```go
// Bad：lifecycx 内部依赖 errx
import "github.com/ZoneCNH/kernel/errx" // ❌

// Good：只依赖 stdlib
import "context"
import "sync"
```

---

## 4. 接口与可注入性

### 所有 I/O 边界必须抽象为接口，并提供 Noop 实现

```go
type Logger interface {
    Info(msg string, fields ...Field)
    Error(msg string, fields ...Field)
    With(fields ...Field) Logger
}

type NoopLogger struct{}

func (NoopLogger) Info(_ string, _ ...Field)  {}
func (NoopLogger) Error(_ string, _ ...Field) {}
func (NoopLogger) With(_ ...Field) Logger     { return NoopLogger{} }

// 编译期检查（CONSTITUTION §4.1 强制）
var _ Logger = NoopLogger{}
```

### 时钟必须可注入（timex）

```go
type Clock interface {
    Now() time.Time
    Since(t time.Time) time.Duration
    After(d time.Duration) <-chan time.Time
}

// 生产代码注入 RealClock；测试代码注入 FakeClock
type Worker struct{ clock timex.Clock }
```

### 生命周期接口（lifecycx）

```go
type Component interface {
    Start(ctx context.Context) error
    Stop(ctx context.Context) error
    Name() string
}
// 启动：注册顺序；停止：LIFO
```

---

## 5. 100% 测试覆盖要求

```bash
go test ./... -race -coverprofile=coverage.out -covermode=atomic
go tool cover -func=coverage.out | grep "^total"
# total 必须为 100.0%
```

### 测试命名（CONSTITUTION §5.3 强制）

```go
func TestErrx_WrapNilError_ReturnsNil(t *testing.T)                  {}
func TestLifecycx_StartFailure_RollbackInReverseOrder(t *testing.T)  {}
func TestTimex_FakeClock_AdvanceTriggersAfter(t *testing.T)           {}
```

### contracttest 使用模式

```go
//go:build test

func VerifyLogger(t *testing.T, factory func() obsx.Logger) {
    t.Helper()
    l := factory()
    l2 := l.With(obsx.String("k", "v"))
    if l2 == l {
        t.Error("With must return a new logger instance")
    }
}
```

---

## 6. 错误处理规范

```go
// 哨兵错误（CONSTITUTION §8.1）
var (
    ErrAlreadyStarted = errx.New(errx.KindConflict, "lifecycx: already started")
    ErrNotFound       = errx.New(errx.KindNotFound, "lifecycx: component not found")
)

// 包装：module: operation: context
return fmt.Errorf("lifecycx: start %s: %w", name, err)
```

**kernel 内部禁止 panic**，一律通过 error 返回链处理。

---

## 7. 并发安全要求

所有公共结构体必须并发安全，后台 goroutine 必须监听 `ctx.Done()` 不得泄漏。

```go
wg := syncx.NewWorkerGroup(ctx)
wg.Go(func(ctx context.Context) error {
    for {
        select {
        case <-ctx.Done(): return ctx.Err()
        case item := <-queue: process(item)
        }
    }
})
return wg.Wait()
```

---

## 8. 禁止事项

| 禁止 | 原因 |
|------|------|
| import 任何非 stdlib 包 | 零外部依赖原则（CONSTITUTION §3.4） |
| 子包之间相互 import | 破坏独立性 |
| `init()` 注册全局状态 | 阻碍测试隔离 |
| 全局变量（除哨兵错误外） | 引入隐式状态 |
| `time.Now()` 直接调用 | 必须注入 `timex.Clock` |
| `panic` | 必须通过 error 返回链 |
| `log.Print*` / `fmt.Print*` | 只定义接口 |
| 覆盖率低于 100% | CONSTITUTION §5.1 |

---

## 9. 常见实现模式

### Option 模式

```go
type Option func(*LifecycleManager)

func WithStopTimeout(d time.Duration) Option {
    return func(m *LifecycleManager) { m.stopTimeout = d }
}

func NewLifecycleManager(opts ...Option) *LifecycleManager {
    m := &LifecycleManager{
        stopTimeout: 30 * time.Second,
        clock:       timex.RealClock{},
        logger:      obsx.NoopLogger{},
    }
    for _, opt := range opts { opt(m) }
    return m
}
```

### 健康检查

```go
var _ healthx.HealthChecker = (*LifecycleManager)(nil)

func (m *LifecycleManager) HealthCheck(_ context.Context) healthx.HealthStatus {
    if !m.started.Load() {
        return healthx.HealthStatus{Status: healthx.Unhealthy, Message: "not started"}
    }
    return healthx.HealthStatus{Status: healthx.Healthy}
}
```

---

## 相关文档

| 文档 | 说明 |
|------|------|
| [`go-coding-standards.md`](./go-coding-standards.md) | 通用 Go 编码规范（基础层） |
| [`CONSTITUTION.md`](../../CONSTITUTION.md) §1-§5 | L0 宪法约束 |
| [`module/kernel/spec/SPEC.md`](../../module/kernel/spec/SPEC.md) | kernel 完整功能规格 |
