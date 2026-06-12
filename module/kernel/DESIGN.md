# kernel 设计方案

> Design ID: DESIGN-kernel-v2
> Source Spec: [SPEC.md](./SPEC.md) v2.0.0
> 生成日期：2026-06-12
> 替换：DESIGN-kernel-v1（基于已废弃的 SPEC v1.1.0 集中式 App/Module/Deps 架构）

---

## 1. 架构概述

kernel 是 Foundation L0 原语层，采用 **12 子包轻量工具集** 设计。每个子包独立可用、互不强制绑定，消费者按需 import 单个子包。全仓 stdlib-only，零外部依赖。

```text
┌──────────────────────────────────────────────────────────────┐
│                        调用方（按需 import）                    │
│  configx   observex   resiliencx   schedulex   redisx  ...   │
└────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬────────┘
     │     │     │     │     │     │     │     │     │
     ▼     ▼     ▼     ▼     ▼     ▼     ▼     ▼     ▼
┌──────────────────────────────────────────────────────────────┐
│                     kernel (L0 原语层)                        │
│                                                              │
│  lifecycx   errx    healthx    obsx    retryx   shutdownx    │
│  ─────────  ──────  ────────   ────    ──────   ─────────    │
│  生命周期    结构化   健康检查   可观测   重试策略   优雅停机     │
│            错误              抽象接口  原语                  │
│                                                              │
│  syncx      timex    validx   versionx  contextx contracttest│
│  ─────      ─────    ──────   ────────  ──────── ─────────── │
│  并发控制    时钟     前置条件   版本信息   类型安全   契约测试   │
│            抽象     校验               上下文    辅助         │
│                                                              │
│  internal/testutil/        contracts/ (API 快照 + golden)     │
└──────────────────────────────────────────────────────────────┘
     │     │     │     │     │     │
     └─────┴─────┴─────┴─────┴─────┴──→ stdlib only
```

### 1.1 设计原则

1. **子包独立**：每个子包只解决一个明确定义的横切关注点，无强制耦合。
2. **stdlib-only**：kernel 整体不 import 任何非标准库包（内部交叉引用除外）。
3. **接口先行**：obsx 定义可观测接口，不绑定任何供应商实现。
4. **零值安全**：所有公开类型零值可用或无副作用（NoopLogger、nil *FakeClock 等）。
5. **不可变优先**：healthx.HealthStatus 使用 WithMetadata 返回新值；lifecycx/shutdownx 返回防御性拷贝。

---

## 2. 子包设计

### 2.1 lifecycx — 组件生命周期管理

**职责**：管理一组 Component 的有序启动和逆序停止。

**核心类型**：
- `Component` 接口：Name() + Start(ctx) + Stop(ctx)
- `Manager`：持有 components 切片，Start 按序启动、失败自动回滚，Stop 逆序幂等

**设计决策**：
- 启动顺序 = 注册顺序（`NewManager(components...)` 的顺序），不引入拓扑排序。
- 启动失败时对已启动组件逆序回滚，回滚错误通过 `errors.Join` 聚合。
- 未 started 时 Stop 幂等返回 nil — 调用方无需额外状态判断。
- 所有返回值是防御性拷贝，防止外部修改内部状态。

### 2.2 errx — 结构化错误

**职责**：提供带分类/严重级别/操作名/可重试标记的结构化错误类型。

**核心类型**：
- `ErrorKind`（12 个预定义值：config, validation, connection, unavailable, timeout, auth, conflict, rate_limit, canceled, not_found, already_exists, internal）
- `Severity`（4 级：info, warning, error, critical）
- `Error` 结构体：Kind + Code + Severity + Op + Message + Cause + Retryable
- `NewError` / `WrapError` 构造函数
- `IsKind` / `AsError` / `ShouldRetry` 遍历函数

**设计决策**：
- Error 实现 `Unwrap() error` 接口，Cause 通过 Unwrap 暴露。
- `WithRetryable`/`WithCode`/`WithSeverity` 返回同一指针（构造期链式调用）。
- `IsKind` 支持 `errors.Join` 多错误链遍历（`Unwrap() []error`）。
- nil *Error 的所有方法安全返回零值。

### 2.3 healthx — 健康检查

**职责**：定义健康检查状态值类型和聚合规则。

**核心类型**：
- `HealthStatusValue`（healthy / degraded / unhealthy）
- `HealthStatus` 结构体：Name + Status + Message + CheckedAt + LatencyMs + Metadata
- `HealthChecker` 接口
- `Aggregate` / `AggregateWithClock` 聚合函数

**设计决策**：
- HealthStatus 是值类型（不可变模式：`WithMetadata` 返回新值）。
- Aggregate 优先级：unhealthy > degraded > healthy。
- Metadata nil 时 JSON 序列化为 `{}` 而非 `null`。
- AggregateWithClock 接受 timex.Clock，nil 时回退到 RealClock。

### 2.4 obsx — 可观测抽象

**职责**：定义无供应商绑定的可观测接口 + Noop 零值实现 + SecretString 脱敏。

**核心类型**：
- `Logger` 接口：Debug/Info/Warn/Error(ctx, msg, ...Field)
- `Metrics` 接口：Count(ctx, name, delta, ...Field) / Observe(ctx, name, value, ...Field)
- `Tracer` 接口：Start(ctx, name, ...Field) → (context.Context, Span)
- `Span` 接口：End() / RecordError(error) / SetFields(...Field)
- `NoopLogger` / `NoopMetrics` / `NoopTracer` / `NoopSpan` 零值实现
- `SecretString`：String()/GoString()/JSON 均返回 "***"，仅 Reveal() 可访问原始值
- `Sanitizer` 接口：Sanitize() string

**设计决策**：
- 所有接口最小化（Logger 只有 4 个方法，Metrics 只有 2 个）。
- Noop 实现是零值结构体，所有方法静默成功 — 消费者无需 nil 检查。
- SecretString 通过 fmt.Stringer + json.Marshaler + gob.GobEncoder 三层保护。
- Field 使用 `[]Field` 而非 `...any`，保证编译期键值对配对。

### 2.5 retryx — 重试策略原语

**职责**：提供重试策略配置的校验和延迟计算，不包含重试执行引擎。

**核心类型**：
- `RetryPolicy`：MaxAttempts + BaseDelay + MaxDelay
- `Validate()` 方法
- `Delay(attempt)` / `DelayWithJitter(attempt, ratio, fraction)` 方法
- `ShouldRetry(err)` 函数

**设计决策**：
- 重试策略是纯配置原语，运行时重试循环由 `resiliencx` 实现。
- Delay 使用指数退避：`BaseDelay * 2^(attempt-1)`，受 MaxDelay 约束。
- 溢出保护：达到 maxDuration/2 时停止加倍。
- Jitter fraction 自动钳位到 [-1, 1]。
- ShouldRetry 遍历 errx 错误链检查 Retryable 标记。

### 2.6 shutdownx — 优雅停机

**职责**：管理 LIFO 顺序的关闭钩子和 OS 信号处理。

**核心类型**：
- `Hook` 接口：Name() + Shutdown(ctx)
- `HookFunc` 适配器
- `Manager`：Register(hook) + Shutdown(ctx) + Hooks()
- `NotifyContext(parent, signals...)` 函数

**设计决策**：
- LIFO 顺序：后注册的 Hook 先执行（符合资源释放惯例）。
- Manager 内部加锁保护并发 Register。
- Shutdown 时对 hooks 做快照，快照后 Register 的 hook 不执行。
- NotifyContext 封装 signal.NotifyContext。

### 2.7 timex — 时钟抽象

**职责**：提供可注入的 Clock 接口及三种实现。

**核心类型**：
- `Clock` 接口：Now() time.Time
- `RealClock`：系统时钟（`time.Now()`）
- `FixedClock`：固定时间（不可变）
- `FakeClock`：可控时间（Advance(d) 推进）

**设计决策**：
- 接口极简（单一方法），降低实现成本。
- FixedClock 是值类型，不可变。
- FakeClock 是指针类型，零值安全（nil *FakeClock.Now() 返回零时间）。
- FakeClock.Advance 只前进不后退。

### 2.8 validx — 前置条件校验

**职责**：提供前置条件和不变量校验助手。

**核心函数**：
- `Precondition(ok, op, message)` → 失败返回 ErrorKindValidation + Warning
- `Invariant(ok, op, message)` → 失败返回 ErrorKindInternal + Error
- `RequireNonEmpty(op, name, value)` → 封装 Precondition

**设计决策**：
- 返回 `*errx.Error` 而非裸 error，便于调用方分类处理。
- Precondition 表示调用方输入非法（SeverityWarning），Invariant 表示内部状态异常（SeverityError）。
- 不引入断言宏/panic 行为 — Go 惯例是返回 error。

### 2.9 versionx — 版本信息

**职责**：提供构建版本元数据和兼容性判断。

**核心类型**：
- `BuildInfo`：Module + Version + Commit + BuildTime + GoVersion
- `Compatibility`：Module + Major
- `VersionInfo = BuildInfo`（Deprecated 类型别名）

**设计决策**：
- BuildInfo 通过 ldflags 在构建时注入。
- Compatibility.Major 为空时仅校验 Module 匹配。
- CompatibleWith 返回 bool，不返回 error。

### 2.10 contextx — 类型安全上下文

**职责**：提供泛型类型安全的 context key/value 存取。

**核心类型**：
- `Key[T]`：基于 sentinel 指针的唯一 key
- `WithValue[T](ctx, key, value)` → context.Context
- `Value[T](ctx, key)` → (T, bool)

**工具函数**：
- `HasDeadline(ctx)` / `DeadlineRemaining(ctx, clock)` / `IsDone(ctx)` / `CancelCause(ctx)`

**设计决策**：
- Key 通过 sentinel 指针实现唯一性（同名字不同 NewKey 调用不冲突）。
- Value 返回 `(T, bool)` 而非 `(T, error)`，零分配。
- 零值 Key 使用 panic（防止未初始化错误）。
- DeadlineRemaining 依赖 timex.Clock 实现可测试性。

### 2.11 syncx — 并发控制

**职责**：提供上下文感知的并发限制器和 WorkerGroup。

**核心类型**：
- `Limiter` 接口：Acquire(ctx) + Release()
- `SemaphoreLimiter`：信号量实现
- `WorkerGroup`：goroutine 组管理，首个错误触发 cancel

**设计决策**：
- SemaphoreLimiter n<=0 时默认容量为 1。
- double-release 静默忽略 — 简化调用方清理路径。
- WorkerGroup 通过 context 派生，任一 worker 出错 → cancel 传播。
- WorkerGroup 已 closed 后 TryGo 返回 false（静默忽略）。

### 2.12 contracttest — 契约测试辅助

**职责**：为 L1 包提供可复用的契约测试断言。

**核心函数**：
- `AssertJSONFields(t, value, fields...)`
- `AssertErrorKind(t, err, wantKind)`
- `AssertHealthStatus(t, got, wantStatus)`

**设计决策**：
- 依赖 `testing.TB` 接口（兼容 *testing.T 和 *testing.B）。
- 断言失败调用 `t.Fatalf`（不继续执行）。
- 依赖 errx + healthx（kernel 内部交叉引用）。

---

## 3. 内部依赖图

```text
stdlib
  ├── errx      (纯 stdlib)
  ├── timex     (纯 stdlib)
  ├── obsx      (纯 stdlib)
  ├── syncx     (纯 stdlib)
  ├── lifecycx  (纯 stdlib)
  ├── shutdownx (纯 stdlib)
  ├── versionx  (纯 stdlib)
  ├── validx    → errx
  ├── retryx    → errx
  ├── contextx  → stdlib, timex
  ├── healthx   → stdlib, timex
  └── contracttest → stdlib, errx, healthx
```

**依赖方向规则**：
- 所有子包最终收敛到 stdlib。
- 交叉引用仅限于 kernel 仓库内部。
- 任何子包不得 import 第三方依赖。

---

## 4. 关键架构决策（ADR）

### ADR-001: 12 子包 vs 单包

- **决策**：拆分为 12 个独立子包，每个子包只解决一个横切关注点。
- **理由**：消费者按需 import，避免单包强制耦合。Go 的包级粒度天然适合此模式。
- **后果**：跨子包引用需要显式 import（如 contracttest → errx + healthx），但 kernel 内部交叉引用是允许的。

### ADR-002: obsx 接口最小化

- **决策**：Logger 只有 4 个方法，Metrics 只有 2 个方法，Tracer 只有 1 个方法。
- **理由**：接口越小，实现成本越低，越容易由 L1 模块适配到具体 SDK。
- **后果**：未来可扩展方法（通过新增接口，不破坏现有接口）。

### ADR-003: retryx 与 resiliencx 边界

- **决策**：retryx 只提供策略配置原语（校验、延迟计算、ShouldRetry），不提供重试执行引擎。
- **理由**：重试执行涉及熔断、限流、退避状态机等运行时弹性机制，属于 resiliencx 的职责。
- **后果**：调用方需自行实现重试循环（或使用 resiliencx 提供的执行器）。

### ADR-004: SecretString 脱敏

- **决策**：SecretString 实现 fmt.Stringer、json.Marshaler、gob.GobEncoder，所有公开方法返回 "***"。
- **理由**：防止 API key、密码等敏感数据意外泄露到日志/JSON 输出。
- **后果**：调用方需显式调用 Reveal() 才能访问原始值，强迫安全意识。

### ADR-005: 零值安全

- **决策**：所有公开类型的零值必须可用或无副作用。
- **理由**：Go 的零值初始化是语言惯例，违反会导致意外的 nil panic。
- **后果**：NoopLogger 等使用空结构体；nil *FakeClock 返回零时间；nil *Error 方法返回 nil/零值。

### ADR-006: 不可变数据模式

- **决策**：healthx.HealthStatus.WithMetadata 返回新值；lifecycx.Manager.Components()、shutdownx.Manager.Hooks() 返回防御性拷贝。
- **理由**：防止外部修改内部状态，符合 Go 的值语义惯例。
- **后果**：每次调用产生一次拷贝，但数据量极小（Components/Hooks 通常 < 10 个）。

---

## 5. 依赖关系

```text
kernel (L0)
├── stdlib only
├── 无外部依赖
├── 内部交叉引用（kernel 仓库内）：
│   ├── validx → errx
│   ├── retryx → errx
│   ├── healthx → timex
│   ├── contextx → timex
│   └── contracttest → errx, healthx
└── 被以下模块按需 import：
    ├── configx (L1) — errx, timex, obsx, validx
    ├── observex (L1) — errx, obsx, healthx
    ├── resiliencx (L1) — errx, retryx, timex
    ├── schedulex (L1) — errx, timex, syncx
    ├── testkitx (L1) — 全子包
    ├── 存储扩展 — errx, timex, obsx, contextx
    └── 业务域模块 — errx, validx, contextx, syncx
```

---

## 6. 技术风险

| 风险                        | 概率   | 影响     | 缓解                                       |
| --------------------------- | ------ | -------- | ------------------------------------------ |
| errx.IsKind 多错误链性能    | Low    | Medium   | Benchmark 覆盖 5 层链遍历 < 1μs            |
| FakeClock 并发安全          | Medium | High     | `-race` 测试 + mutex 保护内部状态          |
| SecretString 反射绕过       | Low    | High     | 覆盖 String()/GoString()/JSON/gob 四条路径 |
| WorkerGroup cancel 传播竞争 | Medium | High     | 充分测试并发 cancel 场景                   |
| stdlib-only 被破坏          | Low    | Critical | CI gate + `go list -deps`                  |
| 接口变更影响下游            | Medium | Major    | SemVer 管理，接口变更 bump major           |

---

## 7. 设计约束

- stdlib-only，零外部依赖（BR-009）。
- 各子包独立可用，互不强制绑定。
- obsx 接口类型定义在 kernel 内，L1 提供具体实现。
- 不包含业务语义（Non-goal）。
- 不实现日志/指标/追踪的具体实现（Non-goal）。
- 公开 API 1.x 内向后兼容。

---

## 8. Mock 策略

### 8.1 单元测试

- **timex**：使用 FakeClock 替代真实时钟。
- **obsx**：使用 NoopLogger/NoopMetrics/NoopTracer 替代真实实现。
- **lifecycx**：使用 stub Component 实现（可控返回值）。
- **errx**：构造各类 Error 组合验证 IsKind/AsError 遍历逻辑。
- **syncx**：`-race` 测试验证并发安全性。

### 8.2 契约测试

- contracts/ 目录提供独立于实现的 API 快照和 golden 行为测试。
- consumers/xgo/ 验证最小导入路径可用。

---

## 9. 可扩展性与演进

### 9.1 已知扩展路径

| 扩展方向            | 当前设计支撑                                   | 演进方式                                             |
| ------------------- | ---------------------------------------------- | ---------------------------------------------------- |
| 新增 ErrorKind 值   | ErrorKind 是 string 类型，消费者用 switch 匹配 | minor version 追加新值                               |
| obsx 接口扩展       | 接口方法最小化                                 | 新增独立接口（如 `LoggerWithContext`），不改现有接口 |
| 新增子包            | 子包间无强制耦合                               | 直接在 kernel 仓库新增子目录                         |
| retryx 新增退避策略 | RetryPolicy 为纯数据                           | 新增策略函数，不改结构体                             |

### 9.2 设计不阻塞的演进方向

- obsx 接口可以通过适配器模式适配任何第三方 SDK。
- timex.Clock 可以扩展 Timer/Ticker 抽象（通过新增接口）。
- contextx.Key[T] 的泛型设计天然支持任意类型。
- SemaphoreLimiter 和 WorkerGroup 可以通过实现 Limiter 接口替换。
