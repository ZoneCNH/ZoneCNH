# resiliencx 设计方案

> Design ID: DESIGN-resiliencx-v1
> Source Spec: [SPEC.md](./SPEC.md) v1.1.0
> Source Goal: [goal.md](./goal.md) v1.0.2 发布基线
> 生成日期：2026-06-29
> 状态：已发布（对齐运行时仓库 `/home/resiliencx`，tag v1.0.2，commit `1aaa0dc`）

## 1. 架构概述

`resiliencx` 是弹性治理策略库，提供 timeout、retry、circuit breaker、bulkhead、rate limiter、fallback 六大弹性原语。以**独立子包**形式提供（`pkg/resiliencx/{timeout,retry,circuit,bulkhead,ratelimit,fallback}`），由业务模块通过函数嵌套（装饰器模式）组装。不提供 harness、自动注入或统一执行链。

### 1.1 设计原则

1. **子包独立**：六大策略各为独立子包，按需 import，互不强制绑定。
2. **装饰器组合**：策略通过函数嵌套组装（如 `timeout.Do(ctx, dur, retry.Do(ctx, policy, fn))`），不引入框架。
3. **纯 stdlib**：零外部依赖（`go mod graph` 无第三方包），仅依赖 stdlib + kernel。
4. **可观测内置**：每个策略通过本地 `Metrics` interface 与事件 `Sink` 暴露运行数据，由调用方注入 `observex` adapter。
5. **配置外置**：策略参数由消费者通过 `configx` 读取后传入构造函数，本库不自带配置解析。

### 1.2 与 goal.md 的版本映射

| 能力 | goal.md MUST | 运行时状态 (v1.0.2) |
|------|------------|-------------------|
| timeout.Do | ✅ MUST | ✅ 已交付（`pkg/resiliencx/timeout/`） |
| retry.Do | ✅ MUST | ✅ 已交付（`pkg/resiliencx/retry/`） |
| circuit breaker（三态 + HalfOpen 并发控制） | ✅ MUST | ✅ 已交付（`pkg/resiliencx/circuit/`） |
| bulkhead | ✅ MUST | ✅ 已交付（`pkg/resiliencx/bulkhead/`） |
| rate limiter | ✅ MUST | ✅ 已交付（`pkg/resiliencx/ratelimit/`） |
| fallback | ✅ MUST | ✅ 已交付（`pkg/resiliencx/fallback/`） |
| 策略组合（Compose / InstrumentStrategy） | ✅ MUST | ✅ 已交付（根包 `compose.go`） |
| 统一执行链 (ResilienceExecutor/PolicyChain) | MAY v1.2+ | 🔜 推迟到 v1.2+ |

## 2. 核心组件设计

### 2.1 Timeout — 超时控制

```go
// pkg/resiliencx/timeout/timeout.go
func Do(ctx context.Context, duration time.Duration, fn func(context.Context) error) error
```

- fn 在 duration 内完成 → 返回 fn 结果
- fn 超过 duration → 返回 `context.DeadlineExceeded`
- ctx 提前取消 → 返回 ctx.Err()

### 2.2 Retry — 重试策略

```go
// pkg/resiliencx/retry/retry.go
type Policy struct {
    MaxAttempts int
    Backoff     BackoffFunc
    MaxDelay    time.Duration
}
func Do(ctx context.Context, policy Policy, fn func(context.Context) error) error
```

- 指数退避 + jitter
- MaxAttempts 达到后返回最后一次错误
- ctx 取消时立即中止
- 非幂等操作由调用方在 fn 内自行保护

### 2.3 CircuitBreaker — 熔断器

```go
// pkg/resiliencx/circuit/circuit.go
type Breaker struct { ... }
func New(threshold int, cooldown time.Duration) *Breaker
func (b *Breaker) Do(fn func() error) error
```

- 三态模型：Closed → Open → HalfOpen → Closed
- Closed：正常执行，连续失败 >= threshold 转为 Open
- Open：立即返回 `ErrOpen`，cooldown 后转为 HalfOpen
- HalfOpen：允许一次试探调用，成功转 Closed，失败保持 Open
- HalfOpen 并发保护：已有试探在飞时返回 `ErrHalfOpen`

### 2.4 Bulkhead — 并发隔离

```go
// pkg/resiliencx/bulkhead/bulkhead.go
type Bulkhead struct { ... }
func New(maxConcurrent int, maxWait time.Duration) *Bulkhead
func (b *Bulkhead) Do(ctx context.Context, fn func(context.Context) error) error
```

- 限制并发调用数
- 等待槽位释放（受 maxWait 控制）
- 超时返回 `ErrBulkheadFull`

### 2.5 RateLimiter — 限流

```go
// pkg/resiliencx/ratelimit/ratelimit.go
type RateLimiter struct { ... }
func New(rate int, per time.Duration) *RateLimiter
func (r *RateLimiter) Wait(ctx context.Context) error
```

- token bucket 算法
- `Wait` 阻塞到 token 可用或 ctx 取消
- 返回 `ErrRateLimited` 当 ctx 取消

### 2.6 Fallback — 降级

```go
// pkg/resiliencx/fallback/fallback.go
func Do(ctx context.Context, primary func(context.Context) error, fallback func(context.Context, error) error) error
```

- primary 失败时调用 fallback
- fallback 接收 primary 的错误用于决策
- 不嵌套多层 fallback（保持简单）

### 2.7 策略组合（根包）

```go
// pkg/resiliencx/compose.go
func Compose(fn func(context.Context) error, strategies ...Strategy) func(context.Context) error
func InstrumentStrategy(name string, s Strategy, m Metrics) Strategy
```

- `Compose` 按调用顺序层层包装
- `InstrumentStrategy` 为策略附加指标
- 典型用法：`timeout.Do(ctx, dur, retry.Do(ctx, policy, fn))`

## 3. 内部依赖图

```
resiliencx/
├── pkg/resiliencx/
│   ├── timeout/timeout.go       → stdlib only
│   ├── retry/retry.go           → stdlib only
│   ├── circuit/circuit.go       → stdlib only
│   ├── bulkhead/bulkhead.go     → stdlib only
│   ├── ratelimit/ratelimit.go   → stdlib only
│   ├── fallback/fallback.go     → stdlib only
│   └── compose.go              → 根包组合逻辑
├── go.mod                       → module github.com/ZoneCNH/resiliencx
└── go.sum
```

- 每个子包独立，无横向依赖
- 根包 `compose.go` 组合各子包（装饰器模式）

## 4. 关键架构决策（ADR）

### ADR-001: 子包独立 vs 单包导出

**决策**：六大策略各自为独立子包（`timeout.Do`/`retry.Do`/`circuit.New` 等），不通过根包统一导出。

**理由**：消费者按需 import，避免导入不需要的策略；子包独立版本可以独立演进；二进制体积更小（Go 编译器可 tree-shake 未使用的子包）。

### ADR-002: 装饰器模式 vs 框架模式

**决策**：策略通过函数嵌套（装饰器）组装，不提供 `ResilienceExecutor` 或 `PolicyChain` 统一执行链。

**理由**：函数嵌套是 Go 惯用模式，零学习成本；不需要 DSL 或配置驱动；调用方完全控制策略顺序和参数；v1.2+ 可在此基础上提供 Compose helper。

### ADR-003: stdlib-only 依赖策略

**决策**：zero external dependencies (`go mod graph` 无第三方包)。

**理由**：xlib 各模块的稳定性和可审计性要求最小依赖攻击面；elastic 库（如 `go-resiliency`）引入了不必要的抽象层和额外依赖；stdlib 已足够实现全部六种策略。

### ADR-004: 可观测通过接口注入

**决策**：每个策略暴露本地 `Metrics` interface，由调用方注入 `observex` adapter，不直接依赖 observex。

**理由**：避免循环依赖（observex 可能消费 resiliencx）；测试时可用 noop metrics；消费者自由选择观测后端。

### ADR-005: 非幂等操作不强制禁止重试

**决策**：retry 库不标记操作是否为幂等，由调用方在 fn 内自行保护。

**理由**：幂等性判断需要业务上下文（如交易 ID），库层无法可靠判断；调用方可通过 wrapper 实现幂等保护（如去重表）；避免过度设计。

## 5. 依赖关系

| 方向 | 模块 | 关系 |
|------|------|------|
| 消费 | kernel | 使用 kernel/contextx 和 kernel/errx |
| 被消费 | 所有业务模块 | 通过子包 import 使用弹性策略 |
| 被消费 | observex | 通过 Metrics interface 注入观测 |
| 被消费 | configx | 消费者通过 configx 读取策略参数后传入 |

## 6. 技术风险

| 风险 | 影响 | 缓解 |
|------|------|------|
| circuit breaker 并发竞争 | 状态不一致 | 内部使用 sync.Mutex；HalfOpen 并发保护 |
| retry 指数退避雪崩 | 集群重试同步 | jitter 随机化退避间隔 |
| bulkhead 槽位泄漏 | goroutine 泄漏 | ctx 取消时释放槽位；带超时保护 |
| rate limiter 配置错误 | 生产限流过严 | token bucket 可调参数；fail-open 可选 |

## 7. 设计约束

- **stdlib-only**：`go mod graph` 不得出现第三方包
- **context 传播**：所有 Do 函数接受 `context.Context`，尊重取消
- **goroutine 安全**：所有策略内部状态受 `sync.Mutex` 保护
- **零值安全**：零值 policy 不 panic（使用合理的默认值）

## 8. Mock 策略

### 8.1 单元测试

- 每个子包独立测试（table-driven）
- 使用 `FakeClock`（来自 testkitx）控制时间相关测试
- circuit breaker 使用并发测试（`go test -race`）

### 8.2 集成测试

- 跨策略组合测试（`Compose` 正确性）
- xlib_harness 中编排集成测试场景

## 9. 可扩展性与演进

### 9.1 v1.2+ 规划

- `Compose` helper 自动推导策略顺序
- 策略注册表（按 operation 选择策略）
- 配置驱动策略（从 configx 读取策略参数）

### 9.2 设计不阻塞的演进方向

- 自适应限流（基于延迟反馈调整 rate）
- 分布式熔断（多实例共享 circuit state）
- 策略效果回测（历史数据验证策略参数）
