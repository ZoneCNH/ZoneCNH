# resiliencx 规格

- Status: Approved (contract-corrected)
- Spec-Version: v1.0.2
- Last-Updated: 2026-06-19
- Layer: L1 基础能力（与 `module/FOUNDATION-DEPS.yaml` 登记一致；ACCEPTANCE/FEATURES/goal 同步对齐为 L1）
- Version: v1.0.2
- Runtime-Version: v1.0.2（运行时代码仓库 `/home/resiliencx` tag `v1.0.2`，commit `1aaa0dc`）
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `kernel`

> 公开投影 caveat：Status=Approved 与 v1.0.2 发布通过不等同于 Foundation factory-grade；BLK-007 关闭前机器事实层保持 factory=false。
>
> **v1.0.2 契约纠正说明**：本版本依据运行时代码仓库（`github.com/ZoneCNH/resiliencx`）实测重写 §6/§8/§9/§10/§11/§12/§13/§16/§17/§18/§19，使 SSOT 与机器事实一致。v1.0.0/v1.0.1 中描述的包级 API（`resiliencx.Timeout` 等）与 sentinel error（`resiliencx.ErrTimeout` 等）在代码中**从未存在**，实际对外契约以本版本子包 API（`timeout.Do` / `retry.Do` / `circuit.New` / `bulkhead.New` / `ratelimit.New` / `fallback.Do`）为准；runtime tag `v1.0.2` / GitHub Release Check `27777166525` / release-check 与 release-final-check 均已通过。

---

## 1. 摘要

`resiliencx` 是策略库，提供 timeout、retry、circuit breaker、bulkhead、rate limiter、fallback 等弹性原语。六大策略以**独立子包**形式提供（`pkg/resiliencx/{timeout,retry,circuit,bulkhead,ratelimit,fallback}`），由业务模块在运行时通过函数嵌套（装饰器模式）组装，不提供 harness、自动注入或统一执行链（`ResilienceExecutor`/`PolicyChain` 为 v1.2+ 演进目标，见 goal.md §7）。

---

## 2. 问题与背景

分布式系统中，网络调用、交易所接口、消息队列都会面对超时或失败场景。没有统一的弹性策略，会导致：

- 每个模块自行实现重试逻辑，代码重复且不一致
- 熔断器缺失，故障级联传播
- 限流策略缺失，交易所 API 被封禁
- 策略参数散落在各处配置中，无法统一调优

---

## 3. 目标

- 提供弹性原语：timeout / retry / circuit breaker / bulkhead / rate limiter / fallback（子包级，按需 import）
- 支持策略组合（函数嵌套 / 装饰器模式）
- 参数可由外部配置驱动（消费者通过 `configx` 读取后传入构造函数；本库不自带配置解析）
- 可观测（通过本地 `Metrics` interface 与事件 `Sink` 暴露，由调用方注入 `observex` adapter）
- 不引入框架（纯 stdlib，`go mod graph` 无第三方包）

---

## 4. 非目标

- 不做应用生命周期管理（→ `kernel`）
- 不做日志实现（→ `observex`）
- 不做配置加载（→ `configx`）
- 不做定时调度（→ `schedulex`）
- 不做测试编排（→ `testkitx`）
- 不提供 harness、自动注入或统一执行链（策略由业务模块自行组装）

---

## 5. 消费者

| 消费者          | 使用方式                                                |
| --------------- | ------------------------------------------------------- |
| `market-data`   | 对交易所 API 调用设置 timeout + retry + circuit breaker |
| `risk-engine`   | 对下单接口设置 rate limiter + fallback                  |
| `signal-engine` | 对因子计算设置 timeout                                  |
| `order-engine`  | 对交易所 API 设置 bulkhead + retry                      |
| 业务域模块      | 按需 import 子包，通过函数嵌套组装策略                  |

---

## 6. 功能需求

### FR-001: Timeout
> AC-RES-001: timeout 正常完成 / 超时 / ctx 取消

WHEN 调用 `timeout.Do(ctx, duration, fn)` 且 fn 在 duration 内完成
THEN 返回 fn 的结果

WHEN 调用 `timeout.Do(ctx, duration, fn)` 且 fn 超过 duration
THEN 返回 `ctx.Err()`（即 `context.DeadlineExceeded`）

WHEN ctx 在 fn 完成前被取消
THEN 返回 ctx.Err()

### FR-002: Retry
> AC-RES-002: retry 首次成功 / 持续失败 / 达到上限 / ctx 取消

WHEN 调用 `retry.Do(ctx, policy, fn)` 且 fn 首次成功
THEN 返回 nil，不重试

WHEN 调用 `retry.Do(ctx, policy, fn)` 且 fn 持续失败
THEN 按 policy 指数退避重试，直到达到 `MaxAttempts`

WHEN 达到 `MaxAttempts` 且仍失败
THEN 返回最后一次 fn 的错误（不包装为 `ErrMaxRetries`）

WHEN retry 等待期间 ctx 被取消
THEN 立即返回 ctx.Err()

### FR-003: CircuitBreaker
> AC-RES-003: 三态转换正确 & AC-RES-004: 并发安全

WHEN 调用 `breaker.Do(fn)` 且 circuit 为 Closed 状态
THEN 执行 fn，成功重置失败计数，失败累加失败计数

WHEN **连续失败次数 >= threshold**（单条件，非失败率）
THEN circuit 转为 Open，后续调用立即返回 `circuit.ErrOpen`

WHEN circuit 为 Open 且 cooldown 已过
THEN circuit 转为 Half-Open，允许一次试探调用

WHEN 试探调用成功
THEN circuit 转为 Closed，失败计数清零

WHEN 试探调用失败
THEN circuit 保持 Open，重置 `lastFailTime`

WHEN Half-Open 已有试探在飞
THEN 并发调用返回 `circuit.ErrHalfOpen`

### FR-004: Bulkhead
> AC-RES-005: 并发控制 / 等待 / 超时

WHEN 调用 `bulkhead.Do(ctx, fn)` 且并发数 < max_concurrent
THEN 执行 fn

WHEN 调用 `bulkhead.Do(ctx, fn)` 且并发数已达 max_concurrent
THEN 阻塞等待槽位；ctx 超时/取消返回 `ctx.Err()`

WHEN 调用 `bulkhead.TryAcquire()` 且无空闲槽位
THEN 立即返回 `bulkhead.ErrFull`

### FR-005: RateLimiter
> AC-RES-006: Allow/Reserve 正确 & 并发安全

WHEN 调用 `limiter.Allow()` 且令牌 >= 1
THEN 扣减令牌，返回 true

WHEN 调用 `limiter.Allow()` 且令牌 < 1
THEN 返回 false（不阻塞）

WHEN 调用 `limiter.Reserve(n)` 且令牌不足
THEN 预扣令牌至 0，返回需等待的 `time.Duration`（由调用方决定是否 sleep）

### FR-006: Fallback
> AC-RES-007: primary 成功 / 失败降级

WHEN 调用 `fallback.Do(ctx, fn, fallbacks...)` 且 fn 成功
THEN 返回 nil，不执行 fallbacks

WHEN 调用 `fallback.Do(ctx, fn, fallbacks...)` 且 fn 失败
THEN 依次尝试 fallbacks，返回首个成功结果；全部失败返回最后一个错误

### Acceptance Criteria Registry

| AC 编号 | 对应 FR | 验收条件 |
| ------- | ------- | -------- |
| AC-RES-001 | FR-001 | Timeout 正常完成返回 fn 结果；超过 duration 返回 `context.DeadlineExceeded`；ctx 取消返回 ctx.Err() |
| AC-RES-002 | FR-002 | Retry 首次成功不重试；持续失败按 policy 重试至 MaxAttempts；达到上限返回最后一次错误；ctx 取消立即返回 |
| AC-RES-003 | FR-003 | CircuitBreaker Closed→Open→Half-Open→Closed 三态转换正确；连续失败 >= threshold 触发 Open |
| AC-RES-004 | FR-003 | CircuitBreaker 并发安全，多 goroutine 同时 Do 不 panic 不数据竞争 |
| AC-RES-005 | FR-004 | Bulkhead 并发数 < max_concurrent 时执行；达上限时 Do 等待或 ctx 取消；TryAcquire 返回 ErrFull |
| AC-RES-006 | FR-005 | RateLimiter.Allow 令牌充足返回 true，不足返回 false；Reserve 返回等待时长；并发安全 |
| AC-RES-007 | FR-006 | Fallback primary 成功返回 nil；primary 失败依次尝试 fallbacks 返回首个成功或最后错误 |

---

## 7. 行为约束

| 编号 | 规则 | 违反后果 |
|------|------|----------|
| BR-001 | 策略函数接受 `context.Context` 参数（`timeout`/`retry`/`bulkhead`/`fallback`；`circuit.Do`/`ratelimit` 为纯内存操作不接 ctx） | 策略无法被 context 取消，会导致 goroutine 泄漏 |
| BR-002 | 策略参数通过构造函数/Policy struct 传入，可由消费者从 `configx` 读取后注入；本库不硬编码、不自带配置解析 | 参数硬编码，无法统一调优 |
| BR-003 | 策略组合通过函数嵌套（装饰器模式）实现，外层包装内层 | 策略执行顺序不可控，行为不确定 |
| BR-004 | 熔断器状态必须并发安全（`sync.Mutex` 保护） | 并发竞争导致状态不一致，熔断误判 |
| BR-005 | 限流器必须并发安全（`sync.Mutex` 保护） | 令牌计数错误，限流失效 |
| BR-006 | 策略执行 metrics 通过**本地 `Metrics` interface**暴露，由调用方注入 `observex` adapter（运行时**未直接依赖** observex） | 弹性策略黑盒，故障不可观测 |
| BR-007 | 策略库纯 stdlib，`go mod graph` 无第三方包 | 引入框架依赖增加二进制体积和编译复杂度 |
| BR-008 | 策略必须可独立测试，不依赖外部服务 | 需要启动外部服务才能测试，CI 不可重复 |

---

## 8. 接口契约

> 以下 API 均为运行时代码仓库 `github.com/ZoneCNH/resiliencx` 实测签名（`pkg/resiliencx/`）。六大策略以独立子包形式提供，不通过包级聚合函数暴露。组合通过函数嵌套实现，v1.0 不提供统一执行链或 `Policies` 聚合 struct。

### 8.1 策略接口（子包级）

```go
// timeout 子包：函数调用超时控制
import "github.com/ZoneCNH/resiliencx/pkg/resiliencx/timeout"
func Do(ctx context.Context, d time.Duration, fn func(context.Context) error) error
// 超时返回 ctx.Err()（即 context.DeadlineExceeded）；ctx 超前取消返回 ctx.Err()。

// retry 子包：可配置指数退避重试
import "github.com/ZoneCNH/resiliencx/pkg/resiliencx/retry"
type Policy struct {
    MaxAttempts int           // 总尝试次数（1 = 不重试）；非旧文档误写的 MaxRetries
    InitialWait time.Duration
    MaxWait     time.Duration
    Multiplier  float64       // <= 0 时内部回退为默认值 2
}
func DefaultPolicy() Policy  // {MaxAttempts:3, InitialWait:100ms, MaxWait:5s, Multiplier:2}
func Do(ctx context.Context, p Policy, fn func(context.Context) error) error
// 耗尽后返回最后一次非 nil 错误；ctx 取消立即返回 ctx.Err()。

// circuit 子包：三态熔断器
import "github.com/ZoneCNH/resiliencx/pkg/resiliencx/circuit"
type State int
const (
    Closed   State = iota // 正常
    Open                  // 拒绝调用
    HalfOpen              // 允许单次试探
)
func New(threshold int, cooldown time.Duration) *Breaker
func (b *Breaker) Do(fn func() error) error   // 非 Execute
func (b *Breaker) State() State
func (b *Breaker) Reset()
// 仅以"连续失败次数 >= threshold"单条件熔断；未实现失败率维度（见 §22）。

// bulkhead 子包：信号量并发限制
import "github.com/ZoneCNH/resiliencx/pkg/resiliencx/bulkhead"
func New(maxConcurrent int) *Bulkhead
func (b *Bulkhead) Acquire(ctx context.Context) error
func (b *Bulkhead) TryAcquire() error
func (b *Bulkhead) Release()
func (b *Bulkhead) Do(ctx context.Context, fn func() error) error
func (b *Bulkhead) Available() int

// ratelimit 子包：令牌桶限流
import "github.com/ZoneCNH/resiliencx/pkg/resiliencx/ratelimit"
func New(rate float64, max float64) *Limiter   // max 即桶容量/burst
func (l *Limiter) Allow() bool                  // = AllowN(1)
func (l *Limiter) AllowN(n float64) bool
func (l *Limiter) Reserve(n float64) time.Duration  // 返回需等待时长，预扣令牌

// fallback 子包：主逻辑 + 降级链
import "github.com/ZoneCNH/resiliencx/pkg/resiliencx/fallback"
func Do(ctx context.Context, fn func(context.Context) error, fallbacks ...func(context.Context) error) error
// primary 成功返回 nil；全失败返回最后一个错误。
```

### 8.2 包根辅助能力

```go
import resiliencx "github.com/ZoneCNH/resiliencx/pkg/resiliencx"

// 错误分类（DefaultClassifier: Canceled→Fatal, DeadlineExceeded→Retryable, 其他→NonRetryable）
type RetryClass int  // Retryable | NonRetryable | Fatal
type Classifier func(err error) RetryClass
func DefaultClassifier() Classifier

// 结构化错误模型（ErrorKind: config/validation/connection/unavailable/timeout/auth/conflict/rate_limit/internal）
type Error struct { Kind ErrorKind; Op string; Message string; Cause error; Retryable bool }
func NewError(...) / WrapError(...) / IsKind(err, kind)

// 幂等守卫（防止非幂等操作被自动重试）
type IdempotencyGuard struct{}
func NewIdempotencyGuard() *IdempotencyGuard
func (g *IdempotencyGuard) Check(key string) error  // 已执行返回 ErrAlreadyExecuted
func (g *IdempotencyGuard) Mark(key string)

// 事件 Sink（策略事件回调，默认 NoopSink；测试用 SliceSink）
type Event struct { Type EventType; Time time.Time; Attempt int; Err error; Duration time.Duration; Metadata map[string]any }
type Sink interface { Emit(event Event) }

// 策略层全局配置（Option 模式）
type ResilienceConfig struct { Classifier Classifier; Sink Sink }
func NewResilienceConfig(opts ...ResilienceOption) ResilienceConfig

// 客户端生命周期（可选使用，非策略核心）
type Config struct { Name string; Timeout time.Duration; Secret string }
func New(ctx context.Context, cfg Config, opts ...Option) (*Client, error)
func (c *Client) Close(ctx context.Context) error
```

### 8.3 用法示例

```go
import (
    "context"
    "time"

    "github.com/ZoneCNH/resiliencx/pkg/resiliencx/timeout"
    "github.com/ZoneCNH/resiliencx/pkg/resiliencx/retry"
    "github.com/ZoneCNH/resiliencx/pkg/resiliencx/circuit"
)

// 策略组合：timeout + retry + circuit breaker（函数嵌套 / 装饰器模式）
cb := circuit.New(5, 30*time.Second) // 连续失败 5 次熔断，30 秒后半开

err := timeout.Do(ctx, 5*time.Second, func(ctx context.Context) error {
    return retry.Do(ctx, retry.Policy{
        MaxAttempts: 3,
        InitialWait: 100 * time.Millisecond,
        MaxWait:     2 * time.Second,
        Multiplier:  2.0,
    }, func(ctx context.Context) error {
        return cb.Do(func() error {
            return exchangeClient.GetTicker(ctx, "BTCUSDT")
        })
    })
})
```

---

## 9. 数据模型

### 9.1 实际 sentinel error（按子包分散定义）

> v1.0.0/v1.0.1 描述的包根聚合 sentinel（`resiliencx.ErrTimeout` 等 5 个）**在代码中不存在**。实际 sentinel 按子包就近定义，且不完整（见下表"缺失"行）。

| sentinel | 定义位置 | 触发场景 |
| -------- | -------- | -------- |
| `context.DeadlineExceeded` | stdlib | `timeout.Do` 超时（`ctx.Err()`），用 `errors.Is` 判定 |
| `circuit.ErrOpen` | `pkg/resiliencx/circuit/circuit.go:21` | 熔断器 Open 状态拒绝调用 |
| `circuit.ErrHalfOpen` | `pkg/resiliencx/circuit/circuit.go:22` | HalfOpen 已有试探在飞，拒绝并发试探 |
| `bulkhead.ErrFull` | `pkg/resiliencx/bulkhead/bulkhead.go:9` | `TryAcquire` 无空闲槽位 |
| `ctx.Err()` | stdlib | `bulkhead.Acquire`/`Do` 等待槽位时 ctx 取消 |
| `resiliencx.ErrAlreadyExecuted` | `pkg/resiliencx/idempotency.go:6` | 幂等守卫命中重复 key |
| **`ErrTimeout`**（专属） | — | **缺失**，超时复用 `context.DeadlineExceeded` |
| **`ErrCircuitOpen`**（包根） | — | **缺失**，使用子包 `circuit.ErrOpen` |
| **`ErrBulkheadFull`**（包根） | — | **缺失**，使用子包 `bulkhead.ErrFull` |
| **`ErrRateLimited`** | — | **缺失**，`ratelimit.Allow()` 仅返回 bool，无错误形态 |
| **`ErrMaxRetries`** | — | **缺失**，`retry.Do` 耗尽后返回最后一次 fn 错误，不包装 |

包根另有一套结构化 `Error` 类型（`ErrorKind` + `Retryable`），用于客户端生命周期管理（见 §8.2），与上述策略 sentinel 是**并行的两套错误模型**。

### 9.2 实际配置结构

> v1.0.0/v1.0.1 的 `CircuitConfig`/`BulkheadConfig`（带 yaml tag）**在代码中不存在**。运行时无 yaml 配置 struct；策略参数通过构造函数位置参数或 `retry.Policy` 字面量传入。

```go
// 实际存在的配置类型（包根 resiliencx）
type Config struct {
    Name    string        // 客户端名，必填
    Timeout time.Duration // 客户端默认超时，>=0
    Secret  string        // 可选，会被 Sanitize 脱敏
}
func (c Config) Validate() error
func (c Config) Sanitize() SanitizedConfig

// 策略参数：直接用构造函数参数或 Policy struct
circuit.New(threshold int, cooldown time.Duration)        // 无 yaml tag
bulkhead.New(maxConcurrent int)                           // 无 MaxWait（改为 ctx 控制）
ratelimit.New(rate float64, max float64)                  // max = burst/桶容量
retry.Policy{ MaxAttempts, InitialWait, MaxWait, Multiplier }
```

---

## 10. 配置模式（参考形态，非运行时已实现）

> 以下 yaml 表达了推荐的外部配置口径，对应 §9.2 的构造参数。当前运行时代码**不自带 yaml 解析**；消费者通过 `configx` 读取后传入构造函数。`max_retries` 在 yaml 层沿用旧名，映射到代码 `retry.Policy.MaxAttempts`（`MaxAttempts = max_retries + 1`）。

```yaml
resiliencx:
  default_timeout: 5s
  default_retry:
    max_retries: 3          # 映射 retry.Policy.MaxAttempts = 4
    initial_wait: 100ms
    max_wait: 2s
    multiplier: 2.0
  circuit_breaker:
    failure_threshold: 5    # circuit.New 第一个参数（连续失败次数）
    recovery_timeout: 30s   # circuit.New 第二个参数（cooldown）
    # half_open_max 未实现，HalfOpen 固定单次试探
  bulkhead:
    max_concurrent: 10      # bulkhead.New 参数
    # max_wait 未实现，等待由调用方 ctx 控制
  rate_limiter:
    rate: 100        # ratelimit.New 第一个参数（令牌/秒）
    burst: 200       # ratelimit.New 第二个参数 max（桶容量）
```

---

## 11. 错误处理

> 错误名以 §9.1 实际 sentinel 为准。

| 错误 | 调用方处理 |
| ---- | ---------- |
| `context.DeadlineExceeded`（来自 `timeout.Do`） | 检查超时是否匹配 SLA，按需增加时长或优化下游 |
| `circuit.ErrOpen` | 等待 cooldown 后重试，或使用 `fallback` |
| `circuit.ErrHalfOpen` | 已有试探在飞，退避后重试或走 fallback |
| `bulkhead.ErrFull`（来自 `TryAcquire`） | 减少并发量或增加 `max_concurrent` |
| `ctx.Err()`（来自 `bulkhead.Acquire`/`Do`） | 等待槽位时 ctx 超时/取消，检查上游 deadline |
| `ratelimit.Limiter.Allow()==false` | 降低请求频率或增加 `rate`/`max` 配额（无错误形态，仅 bool） |
| `retry.Do` 返回的最后一次 fn 错误 | 检查底层错误；永久性错误应经 `Classifier` 判为 `NonRetryable` 不再重试 |
| `resiliencx.ErrAlreadyExecuted` | 幂等守卫命中重复 key，调用方应跳过或返回业务幂等结果 |

**包根结构化错误格式**（`resiliencx.Error`）：`"<ErrorKind>: <Op>: <Message>"`，通过 `errors.As` 取出，`Retryable` 字段指导是否可重试。
**错误包装**：`resiliencx.WrapError` 通过 `Cause` 字段保留底层错误链，`Unwrap()` 返回 `Cause`。

---

## 12. 边界情况

> 下表"运行时实际"列如实反映代码行为；与原 SPEC 期望存在差异的标 ⚠️（P2 代码补强，见 §23）。

| 场景 | 运行时实际 | 目标 / 差距 |
| ---- | ---------- | ----------- |
| `retry.Policy{MaxAttempts:0}` | 循环不执行，fn 不被调用，**返回 nil** | ⚠️ 偏差：应返回错误而非 nil（P2） |
| `retry.Policy{Multiplier:<=0}` | 内部回退为默认值 2 | ✅ 符合预期 |
| `circuit.New(0, cooldown)`（threshold=0） | `failures(0) >= 0` 恒真，首次失败即熔断 | ✅ 符合"第一次失败就熔断" |
| `bulkhead.New(0)`（maxConcurrent=0） | `make(chan, 0)`，`Acquire` 永久阻塞（除非 ctx 取消），`TryAcquire` 返回 `ErrFull` | ⚠️ 偏差：SPEC 期望返回配置错误（P2） |
| `ratelimit.New(0, max)`（rate=0） | `refill` 不补充令牌，初始桶耗尽后 `Allow` 恒 false | ✅ 符合"永远不允许" |
| 策略组合嵌套过深（>10 层） | 函数嵌套，无显式深度限制 | ✅ 正常执行 |
| 并发调用 circuit breaker | `sync.Mutex` 保护状态变更 | ✅ 并发安全，`-race` 通过 |
| ctx 在 retry 等待期间取消 | `select` 命中 `<-ctx.Done()`，立即返回 `ctx.Err()` | ✅ 符合预期 |
| fn panic | `Compose` / `InstrumentStrategy` 捕获为 recovered-panic 错误，保留原 panic payload | ✅ 符合预期；`IsRecoveredPanic` 可识别 |
| `timeout.Do` 超时后 fn 仍在运行 | fn goroutine 继续执行至完成（潜在泄漏） | ⚠️ fn 收到带 deadline 的 ctx，需 fn 自身尊重 ctx |

---

## 13. 目录结构

> 实际为**子包化**布局，非 v1.0.1 描述的扁平结构。六大策略各自独立子包。

```text
resiliencx/                                  # github.com/ZoneCNH/resiliencx
├── go.mod                                   # 无外部依赖，纯 stdlib
├── go.sum                                   # 空
├── README.md
├── CHANGELOG.md
├── LICENSE
├── pkg/
│   └── resiliencx/
│       ├── doc.go                           # 包文档
│       ├── version.go
│       ├── options.go                       # 客户端 Option 模式
│       ├── config.go / config_test.go       # 客户端 Config（Name/Timeout/Secret）
│       ├── client.go / client_test.go       # 客户端生命周期 New/Close
│       ├── errors.go / errors_test.go       # 结构化 Error + ErrorKind
│       ├── classifier.go / *_test.go        # 错误分类 Retryable/NonRetryable/Fatal
│       ├── idempotency.go / *_test.go       # 幂等守卫
│       ├── event.go / *_test.go             # 策略事件 Sink
│       ├── resilience.go / *_test.go        # ResilienceConfig（Option 模式）
│       ├── metrics.go / *_test.go           # Metrics interface + NoopMetrics
│       ├── health.go / *_test.go            # 客户端健康检查
│       ├── noop.go / *_test.go              # NoopStrategy
│       ├── compose.go / compose_test.go     # 策略组合与 recovered panic
│       ├── benchmark_test.go                # Compose / InstrumentStrategy 基准
│       ├── testdata/
│       ├── timeout/{timeout.go, timeout_test.go}
│       ├── retry/{retry.go, retry_test.go}
│       ├── circuit/{circuit.go, circuit_test.go}
│       ├── bulkhead/{bulkhead.go, bulkhead_test.go}
│       ├── ratelimit/{ratelimit.go, ratelimit_test.go}
│       └── fallback/{fallback.go, fallback_test.go}
├── internal/                                # 内部工具（sanitize/validation/goalruntime 等）
├── contracts/                               # 契约定义
├── examples/                                # basic/config/health 示例
├── testkit/
└── scripts/
    └── run_integration_test.go
```

> **v1.0.2 文件状态**：`compose.go` / `compose_test.go` / `benchmark_test.go` / `scripts/run_integration_test.go` 已落地并纳入 release-check；`example_test.go` 仍未提供，但不阻断 v1.0.2 发布。`policies.go`、`internal/atomic/` 属于旧 v1.0.1 目标或 v1.2+ 演进项，不作为当前运行时契约。

---

## 14. 依赖

### 14.1 go.mod

```text
module github.com/ZoneCNH/resiliencx

go 1.23
```

> 实测 `go mod graph` 无任何第三方包；`go list -deps ./...` 不含 kernel/configx/observex。即运行时**实际依赖仅 stdlib**，比下表"可以依赖"更严格。

### 14.2 依赖方向

| 可以依赖（SPEC 许可） | 实际依赖 | 禁止依赖 |
| --------------------- | -------- | -------- |
| stdlib | ✅ stdlib | observex（运行时未依赖，通过 Metrics interface 解耦） |
| `configx`（读取策略配置，由消费者侧完成） | ❌ 未直接依赖 | schedulex |
| `kernel`（生命周期管理） | ❌ 未直接依赖 | testkitx |
| | | 所有业务域实现 |
| | | 所有存储/中间件扩展 |

---

## 15. 测试

### 15.1 单元测试（实际存在的测试函数）

| 子包 | 代表测试函数 | 验证点 |
| ---- | ------------ | ------ |
| timeout | `TestDo_CompletesBeforeDeadline` / `TestDo_ExceedsDeadline` / `TestDo_PropagatesError` | 正常/超时/错误传播 |
| retry | `TestDo_SucceedsFirstAttempt` / `TestDo_RetriesUntilSuccess` / `TestDo_ExhaustsAttempts` / `TestDo_RespectsContext` / `TestDo_DefaultMultiplier` / `TestDo_MaxWaitCap` | 首次成功/重试至成功/耗尽/ctx取消/默认乘数/MaxWait封顶 |
| circuit | `TestBreaker_ClosedToOpen` / `TestBreaker_OpenRejects` / `TestBreaker_OpenToHalfOpen` / `TestBreaker_HalfOpen_ProbeSuccess` / `TestBreaker_HalfOpen_ProbeFailure` / `TestBreaker_Reset` | 三态转换+并发试探 |
| bulkhead | `TestBulkhead_LimitsConcurrency` / `TestBulkhead_TryAcquire_Full` / `TestBulkhead_Acquire_CtxCancelled` / `TestBulkhead_Do_CtxCancelled` | 并发限制/拒绝/ctx取消 |
| ratelimit | `TestLimiter_AllowWithinBurst` / `TestLimiter_Refills` / `TestLimiter_AllowN_*` / `TestLimiter_Reserve_*` | 令牌桶/补充/批量/预约 |
| fallback | `TestDo_PrimarySucceeds` / `TestDo_FallbackSucceeds` / `TestDo_AllFail` / `TestDo_PrimaryFailsNoFallbacks` | 主成功/降级/全失败/无降级 |
| 包根 | `TestDefaultClassifier_*` / `TestIdempotencyGuard_*` / `TestSliceSink_*` / `TestNewErrorFormats*` | 分类器/幂等/事件/错误模型 |
| 并发安全 | 所有子包 `-race` 通过 | 无 data race |

### 15.2 Given/When/Then 用例

**TC-001: timeout + retry 组合**
Given timeout=1s，retry MaxAttempts=3
When fn 首次超时，第二次成功
Then 第一次超时后重试，第二次返回成功

**TC-002: circuit breaker 熔断**
Given threshold=3，cooldown=5s
When fn 连续失败 3 次
Then circuit 转为 Open
And 后续调用立即返回 `circuit.ErrOpen`

**TC-003: circuit breaker 恢复**
Given circuit 为 Open，cooldown 已过
When 试探调用成功
Then circuit 转为 Closed
And 后续调用正常执行

**TC-004: bulkhead 并发限制**
Given max_concurrent=2
When 3 个并发请求同时调用 `Do`
Then 前 2 个立即执行
And 第 3 个等待或 ctx 超时返回 `ctx.Err()`

**TC-005: rate limiter 限流**
Given rate=2/s，max(burst)=2
When 瞬时发起 3 次 `Allow`
Then 前 2 次通过，第 3 次返回 false

**TC-006: fallback 降级**
Given primary 返回错误，fallback 可用
When 调用 `fallback.Do`
Then 返回 fallback 的结果（nil）

**TC-008: 策略组合**（✅ `TestCompose` / `TestComposePanicRecovery` 自动化承载）
Given `Compose` 组合 timeout、retry、fallback 或测试策略
When 调用组合后的策略
Then 外层按声明顺序包装内层，整体返回最外层结果，并将 panic 转为 recovered-panic 错误

### 15.3 Benchmark

> v1.0.2 已实现 `pkg/resiliencx/benchmark_test.go`，`GOWORK=off go test -bench=Benchmark -benchmem ./pkg/resiliencx/...` 通过。

| 场景 | 实测 / 目标 |
| ---- | ----------- |
| `BenchmarkComposeOneStrategy` | 9.096 ns/op（目标 < 1μs） |
| `BenchmarkComposeFiveStrategies` | 20.44 ns/op（目标 < 1μs） |
| `BenchmarkInstrumentStrategy` | 664.0 ns/op（目标 < 1μs） |

### 15.4 集成测试

> v1.0.2 使用 `scripts/run_integration_test.go` 承载轻量集成检查；`GOWORK=off go run ./scripts/run_integration_test.go` 已纳入 release-check。

| 场景 | 验证点 |
| ---- | ------ |
| 模拟交易所超时 | timeout 生效，retry 重试 |
| 模拟连续失败 | circuit breaker 熔断并恢复 |
| 高并发场景 | bulkhead + rate limiter 正确限流 |

---

## 16. 性能预算

> v1.0.2 已有 benchmark 实测；当前预算均通过。内存 profiling 尚未作为发布阻断项。

| 操作 | 目标 | 测量方式 | 状态 |
| ---- | ---- | -------- | ---- |
| 单策略调用开销 | < 200ns | `BenchmarkComposeOneStrategy` | ✅ 9.096 ns/op |
| 5 层嵌套策略开销 | < 1μs | `BenchmarkComposeFiveStrategies` | ✅ 20.44 ns/op |
| 策略观测包装 | < 1μs | `BenchmarkInstrumentStrategy` | ✅ 664.0 ns/op |
| 常驻内存（per circuit breaker） | < 1KB | profiling | 非 v1.0.2 阻断项 |

---

## 17. 可观测性

> 运行时通过本地 `Metrics` interface（`pkg/resiliencx/metrics.go`）、事件 `Sink` 与 `InstrumentStrategy` 暴露可观测入口，由调用方注入 `observex` adapter。v1.0.2 不直接依赖 observex；策略级耗时/错误/panic 通过包装器上报，客户端生命周期 metric 常量仍保持 `client_*` 系列。

### 17.1 实际 metric 常量（`pkg/resiliencx/metrics.go`）

| 常量 | 名称 | 说明 |
| ---- | ---- | ---- |
| `MetricClientCreatedTotal` | `client_created_total` | 客户端创建计数 |
| `MetricClientClosedTotal` | `client_closed_total` | 客户端关闭计数 |
| `MetricClientErrorsTotal` | `client_errors_total` | 客户端错误计数 |
| `MetricClientHealthStatus` | `client_health_status` | 健康状态 gauge |
| `MetricClientHealthLatencyMS` | `client_health_latency_ms` | 健康检查延迟 |
| `MetricClientRequestsTotal` | `client_requests_total` | 请求计数 |
| `MetricClientRequestDurationSeconds` | `client_request_duration_seconds` | 请求耗时 |
| `MetricClientRetriesTotal` | `client_retries_total` | 重试计数 |
| `MetricClientInflight` | `client_inflight` | 在飞请求 gauge |

### 17.2 命名差异与 v1.0.2 收敛口径

| 来源 | 命名风格 | 覆盖维度 |
| ---- | -------- | -------- |
| SPEC v1.0.1 §17（旧） | `resiliencx.timeout.count` / `resiliencx.circuit.state` 等 | 旧命名，不作为 v1.0.2 运行时契约 |
| goal.md §9.2 | `resiliencx.calls.total` / `resiliencx.duration.ms` 等 | 统一执行链（v1.2+ 目标） |
| 代码 metrics.go + InstrumentStrategy（实际） | `client_*` 系列 + 注入式策略 metrics | 客户端生命周期与策略包装观测（**已实现**） |

> 治理结论：v1.0.2 的 BR-006/NFR-002 以 `Metrics` interface + `EventSink` + `InstrumentStrategy` 为发布契约；旧 `resiliencx.timeout.count` 等硬编码 metric 名不作为当前稳定 API。

---

## 18. 安全

| 要求 | 实现状态 | 说明 |
| ---- | -------- | ---- |
| 错误消息不泄露敏感数据 | ✅ | 错误消息只含策略名/错误类型；`Config.Sanitize` 脱敏 Secret |
| rate limiter 防绕过 | ✅ | 令牌桶算法，服务端控制 |
| 输入校验 | ✅ 部分 | `Config.Validate` 校验 Name/Timeout；策略参数范围校验（≤10000）**未实现** |
| 资源防护 | ✅ | goroutine 并发受 bulkhead 限制 |
| 配置脱敏 | ✅ | `sanitize.Secret` 脱敏；敏感参数建议环境变量注入 |
| panic 恢复 | ✅ | `Compose` / `InstrumentStrategy` 使用 recovered-panic 包装，`IsRecoveredPanic` 可识别；panic payload 不吞失 |

---

## 19. CI 门禁

### 19.1 通用 Gate（v1.0.2 实测基线）

| Gate | 命令 | 阻塞条件 | 实测状态 |
| ---- | ---- | -------- | -------- |
| 编译 | `go build ./...` | 编译失败 | ✅ 通过 |
| 测试 | `go test ./... -race -count=1` | 任何测试失败或 data race | ✅ 全绿，无 race |
| 覆盖率 | `go test ./... -coverprofile=cover.out && go tool cover -func=cover.out` | 总覆盖率 < 80% | ✅ release-check / release-final-check score=10.00 |
| vet | `go vet ./...` | 任何 vet 错误 | ✅ 无警告 |
| lint | `golangci-lint run` | 任何 lint 错误 | （由 ci-workflow.yaml 承载） |
| 依赖检查 | `go mod tidy && git diff --exit-code go.mod go.sum` | go.mod 不整洁 | ✅ 无外部依赖 |
| Secret 扫描 | `gitleaks detect --no-git` | 泄露 secret | （由 ci-workflow.yaml 承载） |
| Benchmark | `go test -bench=. -benchmem -count=3 ./...` | 结果附在 PR comment | ✅ Compose/InstrumentStrategy benchmark 通过 |
| Release Check | `GOWORK=off XLIB_CONTEXT=ci_pull_request make release-check` | 任一发布 gate 失败 | ✅ score=10.00，hash `d2556ba0605e0b4c24a8b3f82a50ef7ede47309282d038ece810905f006c6781` |
| Final Check | `GOWORK=off XLIB_CONTEXT=release_verify make release-final-check` | 任一最终发布 gate 失败 | ✅ score=10.00，hash `18ba39ad95d66126679b05d38d4221b6bb1f0e6401849bc5ffc1adbfe83e5a32` |
| GitHub Release Check | GitHub Actions run `27777166525` | release workflow 失败 | ✅ passed |

### 19.2 resiliencx 专属 Gate

| Gate | 命令 | 阻塞条件 | 实测状态 |
| ---- | ---- | -------- | -------- |
| 不依赖 kernel | `go list -deps ./... \| grep kernel` | 依赖 kernel | ✅ 无 kernel 依赖 |
| 不依赖 observex | `go list -deps ./... \| grep observex` | 依赖 observex | ✅ 无 observex 依赖 |

---

## 20. 升级兼容性

| 变更类型 | 版本升级 |
| -------- | -------- |
| 策略函数签名变更（子包级 `Do`/`New`） | **major** |
| 新增可选策略 | minor |
| `retry.Policy` 结构体新增字段 | minor |
| 默认参数变更 | **minor**（注意行为变化） |
| 新增配置字段 | minor |

> 注：v1.0.1 提到的 `Policies` 聚合 struct 在代码中不存在，相关兼容性条款移除。

---

## 21. 发布 DoD

- [x] 所有公共接口有 godoc 注释
- [ ] 所有公共类型有示例代码（`example_test.go` 未实现）
- [x] CHANGELOG.md 已更新
- [x] README.md 包含：模块定位、快速开始、API 概览
- [x] 单元测试覆盖率 ≥ 80%（release-check / release-final-check score=10.00）
- [x] `-race` 测试通过
- [x] Benchmark 结果无 > 10% 回退（Compose 9.096 ns/op；5 层 Compose 20.44 ns/op；InstrumentStrategy 664.0 ns/op）
- [x] `go vet` 无警告
- [x] 公共 API 与本 SPEC v1.0.2 契约一致
- [x] 所有 Functional Requirements 有对应测试
- [ ] 所有 Edge Cases 有对应测试（`retry.Policy{MaxAttempts:0}` / `bulkhead.New(0)` 等 P2 项未覆盖；panic recovery 已覆盖）

---

## 22. 待解决问题

- 是否需要支持自适应 retry（根据历史成功率动态调整策略）？
- 是否需要支持分布式 circuit breaker（多实例共享熔断状态）？
- rate limiter 是否需要支持多维度限流（per-endpoint, per-user）？
- 策略配置是否需要支持运行时动态更新？
- circuit breaker 是否需要补充"失败率"维度（当前仅连续失败次数）？
- 是否需要补充 `example_test.go`，把 README 快速开始固化为可编译示例？

---

## 23. 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| ---- | ---- | -------- | ---- |
| 2026-06-19 | v1.0.2 | **发布证据同步**：同步 runtime tag v1.0.2 / GitHub Release Check 27777166525 / release-check 和 release-final-check score=10.00；补齐 Compose、InstrumentStrategy、benchmark、integration runner 与 recovered panic 的已发布事实 | ZoneCNH |
| 2026-06-18 | v1.0.2 | **契约纠正**：依据运行时代码实测重写 §6/§8/§9/§10/§11/§12/§13/§14/§15/§16/§17/§18/§19/§20/§21；修正包级 API→子包 API、sentinel error 命名、目录结构、依赖边界、性能/benchmark 状态、metric 三套命名差异、安全 panic 项；记录 P2 代码补强项 | ZoneCNH |
| 2026-06-12 | v1.0.1 | kernel 依赖修正、BR 违反后果补全、AC 标签显式化、Security 补强 | ZoneCNH |
| 2026-06-07 | v1.0.0 | 初始版本 | ZoneCNH |
