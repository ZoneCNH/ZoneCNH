# resiliencx 规格

- Status: Approved (contract-corrected)
- Spec-Version: v1.0.2
- Last-Updated: 2026-06-18
- Layer: L1 基础能力（与 `module/FOUNDATION-DEPS.yaml` 登记一致；ACCEPTANCE/FEATURES/goal 同步对齐为 L1）
- Version: v1.0.0
- Runtime-Version: v0.4.9（运行时代码仓库 `/home/resiliencx` 实测基线）
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `kernel`

> 公开投影 caveat：Status=Approved 与运行时覆盖率 98.1% 不等同于 factory-grade；BLK-007 关闭前机器事实层保持 factory=false。
>
> **v1.0.2 契约纠正说明**：本版本依据运行时代码仓库（`github.com/ZoneCNH/resiliencx`）实测重写 §8/§9/§10/§13/§16/§17，使 SSOT 与机器事实一致。v1.0.0/v1.0.1 中描述的包级 API（`resiliencx.Timeout` 等）与 sentinel error（`resiliencx.ErrTimeout` 等）在代码中**从未存在**，实际对外契约以本版本子包 API（`timeout.Do` / `retry.Do` / `circuit.New` / `bulkhead.New` / `ratelimit.New` / `fallback.Do`）为准。原投影造成的下游集成风险见 §23 变更历史。

---

## 1. 摘要

`resiliencx` 是策略库，提供 timeout、retry、circuit breaker、bulkhead、rate limiter、fallback 等弹性原语。策略由业务模块在运行时组装，不提供 harness 或自动注入。

---

## 2. 问题与背景

分布式系统中，网络调用、交易所接口、消息队列都会面对超时或失败场景。没有统一的弹性策略，会导致：

- 每个模块自行实现重试逻辑，代码重复且不一致
- 熔断器缺失，故障级联传播
- 限流策略缺失，交易所 API 被封禁
- 策略参数散落在各处配置中，无法统一调优

---

## 3. 目标

- 提供声明式弹性原语：timeout / retry / circuit breaker / bulkhead / rate limiter / fallback
- 支持策略组合（嵌套执行）
- 配置驱动，参数从 `configx.Reader` 读取
- 可观测（每个策略的执行结果可被 metrics 采集）
- 不引入框架（stdlib + 最少依赖）

---

## 4. 非目标

- 不做应用生命周期管理（→ `kernel`）
- 不做日志实现（→ `observex`）
- 不做配置加载（→ `configx`）
- 不做定时调度（→ `schedulex`）
- 不做测试编排（→ `testkitx`）
- 不提供 harness 或自动注入（策略由业务模块自行组装）

---

## 5. 消费者

| 消费者          | 使用方式                                                |
| --------------- | ------------------------------------------------------- |
| `market-data`   | 对交易所 API 调用设置 timeout + retry + circuit breaker |
| `risk-engine`   | 对下单接口设置 rate limiter + fallback                  |
| `signal-engine` | 对因子计算设置 timeout                                  |
| `order-engine`  | 对交易所 API 设置 bulkhead + retry                      |
| 业务域模块      | 按需组装策略，通过 `resiliencx.Policies` 传递           |

---

## 6. 功能需求

### FR-001: Timeout
> AC-RES-001: timeout 正常完成 / 超时 / ctx 取消

WHEN 调用 `Timeout(ctx, duration, fn)` 且 fn 在 duration 内完成
THEN 返回 fn 的结果

WHEN 调用 `Timeout(ctx, duration, fn)` 且 fn 超过 duration
THEN 返回 `ErrTimeout`

WHEN ctx 在 fn 完成前被取消
THEN 返回 ctx.Err()

### FR-002: Retry
> AC-RES-002: retry 首次成功 / 持续失败 / 达到上限 / ctx 取消

WHEN 调用 `Retry(ctx, policy, fn)` 且 fn 首次成功
THEN 返回结果，不重试

WHEN 调用 `Retry(ctx, policy, fn)` 且 fn 持续失败
THEN 按 policy 重试，直到达到 max_retries

WHEN 达到 max_retries 且仍失败
THEN 返回最后一次的错误

WHEN retry 期间 ctx 被取消
THEN 立即返回 ctx.Err()

### FR-003: CircuitBreaker
> AC-RES-003: 三态转换正确 & AC-RES-004: 并发安全

WHEN 调用 `circuit.Execute(fn)` 且 circuit 为 Closed 状态
THEN 执行 fn，成功计数，失败计数

WHEN 失败率超过 threshold 且连续失败超过 min_failures
THEN circuit 转为 Open，后续调用立即返回 `ErrCircuitOpen`

WHEN circuit 为 Open 且 recovery_timeout 已过
THEN circuit 转为 Half-Open，允许一次试探调用

WHEN 试探调用成功
THEN circuit 转为 Closed

WHEN 试探调用失败
THEN circuit 保持 Open，重置 recovery_timeout

### FR-004: Bulkhead
> AC-RES-005: 并发控制 / 等待 / 超时

WHEN 调用 `bulkhead.Execute(fn)` 且并发数 < max_concurrent
THEN 执行 fn

WHEN 调用 `bulkhead.Execute(fn)` 且并发数已达 max_concurrent
THEN 等待直到有空位或 ctx 超时，超时返回 `ErrBulkheadFull`

### FR-005: RateLimiter
> AC-RES-006: Allow/Wait 正确 & 并发安全

WHEN 调用 `limiter.Allow()` 且当前速率 < max_rate
THEN 返回 true

WHEN 调用 `limiter.Allow()` 且当前速率 >= max_rate
THEN 返回 false

WHEN 调用 `limiter.Wait(ctx)` 且需要等待
THEN 阻塞直到允许或 ctx 超时

### FR-006: Fallback
> AC-RES-007: primary 成功 / 失败降级

WHEN 调用 `Fallback(primary, secondary)` 且 primary 成功
THEN 返回 primary 的结果

WHEN 调用 `Fallback(primary, secondary)` 且 primary 失败
THEN 执行 secondary，返回 secondary 的结果

### Acceptance Criteria Registry

| AC 编号 | 对应 FR | 验收条件 |
| ------- | ------- | -------- |
| AC-RES-001 | FR-001 | Timeout 正常完成返回 fn 结果；超过 duration 返回 ErrTimeout；ctx 取消返回 ctx.Err() |
| AC-RES-002 | FR-002 | Retry 首次成功不重试；持续失败按 policy 重试至 max_retries；达到上限返回最后一次错误；ctx 取消立即返回 |
| AC-RES-003 | FR-003 | CircuitBreaker Closed→Open→Half-Open→Closed 三态转换正确；失败率超 threshold + 连续失败超 min_failures 触发 Open |
| AC-RES-004 | FR-003 | CircuitBreaker 并发安全，多 goroutine 同时 Execute 不 panic 不数据竞争 |
| AC-RES-005 | FR-004 | Bulkhead 并发数 < max_concurrent 时执行；达上限时等待；ctx 超时返回 ErrBulkheadFull |
| AC-RES-006 | FR-005 | RateLimiter.Allow 速率 < max_rate 返回 true，>= 返回 false；Wait 阻塞至允许或 ctx 超时；并发安全 |
| AC-RES-007 | FR-006 | Fallback primary 成功返回 primary 结果；primary 失败执行 secondary 返回 secondary 结果 |

---

## 7. 行为约束

| 编号 | 规则 | 违反后果 |
|------|------|----------|
| BR-001 | 所有策略必须接受 `context.Context` 参数 | 策略无法被 context 取消，会导致 goroutine 泄漏 |
| BR-002 | 策略参数从 `configx.Reader` 读取，不硬编码 | 参数散落硬编码，无法统一调优和热更新 |
| BR-003 | 策略组合时，外层策略包装内层策略（装饰器模式） | 策略执行顺序不可控，行为不确定 |
| BR-004 | 熔断器状态必须并发安全 | 并发竞争导致状态不一致，熔断误判 |
| BR-005 | 限流器必须并发安全 | 令牌计数错误，限流失效 |
| BR-006 | 策略执行的 metrics 通过 `observex.Meter` 采集 | 弹性策略黑盒，故障不可观测、不可追溯 |
| BR-007 | 策略库不引入框架，使用 stdlib + 最少依赖 | 引入框架依赖增加二进制体积和编译复杂度 |
| BR-008 | 策略必须可独立测试，不依赖外部服务 | 需要启动外部服务才能测试，CI 不可重复 |

---

## 8. 接口契约

> 以下 API 均为运行时代码仓库 `github.com/ZoneCNH/resiliencx` 实测签名（`pkg/resiliencx/`）。六大策略以**独立子包**形式提供，按需 import，不通过包级聚合函数暴露。组合通过函数嵌套（装饰器模式）实现，v1.0 不提供统一执行链或 `Policies` 聚合 struct（见 goal.md §7，`ResilienceExecutor`/`PolicyChain` 为 v1.2+ 演进目标）。

### 8.1 策略接口（子包级）

```go
// timeout 子包：函数调用超时控制
import "github.com/ZoneCNH/resiliencx/pkg/resiliencx/timeout"
func Do(ctx context.Context, d time.Duration, fn func(context.Context) error) error
// 超时返回 ctx.Err()（即 context.DeadlineExceeded）；ctx 超前取消返回 ctx.Err()。

// retry 子包：可配置指数退避重试
import "github.com/ZoneCNH/resiliencx/pkg/resiliencx/retry"
type Policy struct {
    MaxAttempts int           // 总尝试次数（1 = 不重试）；注意非 v1.0.1 文档误写的 MaxRetries
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
// 仅以"连续失败次数 >= threshold"单条件熔断；未实现失败率维度（见 §22 待解决问题）。

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

### 8.2 包根辅助能力（非 SPEC §13 列出，但代码已实现）

```go
import resiliencx "github.com/ZoneCNH/resiliencx/pkg/resiliencx"

// 错误分类（DefaultClassifier: Canceled→Fatal, DeadlineExceeded→Retryable, 其他→NonRetryable）
type RetryClass int  // Retryable | NonRetryable | Fatal
type Classifier func(err error) RetryClass
func DefaultClassifier() Classifier

// 错误模型（ErrorKind: config/validation/connection/unavailable/timeout/auth/conflict/rate_limit/internal）
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
| `context.DeadlineExceeded` | stdlib | `timeout.Do` 超时（`ctx.Err()`），消费者用 `errors.Is(err, context.DeadlineExceeded)` |
| `circuit.ErrOpen` | `pkg/resiliencx/circuit/circuit.go:21` | 熔断器 Open 状态拒绝调用 |
| `circuit.ErrHalfOpen` | `pkg/resiliencx/circuit/circuit.go:22` | HalfOpen 已有试探在飞，拒绝并发试探 |
| `bulkhead.ErrFull` | `pkg/resiliencx/bulkhead/bulkhead.go:9` | `TryAcquire` 无空闲槽位 |
| `bulkhead` ctx 错误 | stdlib | `Acquire`/`Do` 等待槽位时 ctx 取消，返回 `ctx.Err()` |
| `resiliencx.ErrAlreadyExecuted` | `pkg/resiliencx/idempotency.go:6` | 幂等守卫命中重复 key |
| **`ErrTimeout`**（专属） | — | **缺失**，超时复用 `context.DeadlineExceeded` |
| **`ErrCircuitOpen`**（包根） | — | **缺失**，使用子包 `circuit.ErrOpen` |
| **`ErrBulkheadFull`**（包根） | — | **缺失**，使用子包 `bulkhead.ErrFull` |
| **`ErrRateLimited`** | — | **缺失**，`ratelimit.Limiter.Allow()` 仅返回 `bool`，无错误形态 |
| **`ErrMaxRetries`** | — | **缺失**，`retry.Do` 耗尽后返回最后一次 `fn` 错误，不包装 |

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

§10 的 yaml 配置模式属于**目标/参考形态**，运行时尚无对应 struct 解析；消费者需自行把 yaml 读入后构造上述参数。

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
    failure_threshold: 5    # circuit.New 的第一个参数（连续失败次数）
    recovery_timeout: 30s   # circuit.New 的第二个参数（cooldown）
    # half_open_max 未实现，HalfOpen 固定单次试探
  bulkhead:
    max_concurrent: 10
    max_wait: 5s
  rate_limiter:
    rate: 100        # requests per second
    burst: 200       # burst capacity
```text

---

## 11. 错误处理

| 错误              | 调用方处理                                           |
| ----------------- | ---------------------------------------------------- |
| `ErrTimeout`      | 检查超时时间是否匹配 SLA，按需增加超时时间或优化下游 |
| `ErrCircuitOpen`  | 等待 recovery_timeout 后重试，或使用 fallback        |
| `ErrBulkheadFull` | 减少并发量或增加 max_concurrent                      |
| `ErrRateLimited`  | 降低请求频率或增加 rate 配额                         |
| `ErrMaxRetries`   | 检查底层错误原因；永久性错误不得继续重试             |

**错误消息格式：** `"resiliencx: <strategy>: <detail>"`
**错误包装：** 使用 `%w` 保留底层错误链

---

## 12. 边界情况

| 场景                                   | 预期行为                     |
| -------------------------------------- | ---------------------------- |
| retry policy 的 max_retries=0          | 不重试，直接返回错误         |
| retry policy 的 multiplier=0           | 使用默认 multiplier=2.0      |
| circuit breaker 的 failure_threshold=0 | 第一次失败就熔断             |
| bulkhead 的 max_concurrent=0           | 返回配置错误                 |
| rate limiter 的 rate=0                 | 永远不允许（所有请求被限流） |
| 策略组合嵌套过深（>10 层）             | 正常执行，无栈溢出           |
| 并发调用 circuit breaker 状态变更      | 需要加锁，保证并发安全       |
| ctx 在 retry 等待期间取消              | 立即返回，不继续重试         |
| fn panic                               | 被 catch，返回 panic 错误    |

---

## 13. 目录结构

```text
resiliencx/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go
├── timeout.go              # Timeout 策略
├── retry.go                # Retry 策略
├── circuit.go              # CircuitBreaker 策略
├── bulkhead.go             # Bulkhead 策略
├── ratelimit.go            # RateLimiter 策略
├── fallback.go             # Fallback 策略
├── policies.go             # Policies 组合结构体
├── options.go              # Option 模式
├── errors.go               # 公共错误变量
├── internal/
│   └── atomic/             # 原子操作工具
├── testdata/
│   └── config.yaml
├── example_test.go
├── benchmark_test.go
└── integration_test.go
```text

---

## 14. 依赖

### 14.1 go.mod

```text
module github.com/ZoneCNH/resiliencx

go 1.23
```text

### 14.2 依赖方向

| 可以依赖                  | 禁止依赖            |
| ------------------------- | ------------------- |
| stdlib                    | observex            |
| `configx`（读取策略配置） | schedulex           |
| `kernel`（生命周期管理）  | testkitx            |
|                           | 所有业务域实现      |
|                           | 所有存储/中间件扩展 |

---

## 15. 测试

### 15.1 单元测试

| 测试场景             | 验证点                                     |
| -------------------- | ------------------------------------------ |
| timeout 未超时       | fn 正常返回                                |
| timeout 超时         | 返回 ErrTimeout                            |
| retry 首次成功       | 不重试                                     |
| retry 持续失败       | 达到 max_retries 后返回最后一次错误        |
| retry 期间 ctx 取消  | 立即返回                                   |
| circuit breaker 正常 | Closed 状态，fn 正常执行                   |
| circuit breaker 熔断 | Open 状态，立即返回 ErrCircuitOpen         |
| circuit breaker 恢复 | Half-Open → Closed                         |
| bulkhead 并发控制    | 超过 max_concurrent 时等待或拒绝           |
| rate limiter 限流    | 超过 rate 时 Allow() 返回 false            |
| fallback 主成功      | 不执行 secondary                           |
| fallback 主失败      | 执行 secondary                             |
| 策略组合             | timeout + retry + circuit breaker 正确嵌套 |
| 并发安全             | -race 测试通过                             |

### 15.2 Given/When/Then 用例

**TC-001: timeout + retry 组合**
Given timeout=1s，retry max_retries=3
When fn 首次超时，第二次成功
Then 第一次超时后重试，第二次返回成功

**TC-002: circuit breaker 熔断**
Given failure_threshold=3，recovery_timeout=5s
When fn 连续失败 3 次
Then circuit 转为 Open
And 后续调用立即返回 ErrCircuitOpen

**TC-003: circuit breaker 恢复**
Given circuit 为 Open，recovery_timeout 已过
When 试探调用成功
Then circuit 转为 Closed
And 后续调用正常执行

**TC-004: bulkhead 并发限制**
Given max_concurrent=2
When 3 个并发请求同时调用
Then 前 2 个立即执行
And 第 3 个等待或超时

**TC-005: rate limiter 限流**
Given rate=2/s，burst=2
When 瞬时发起 3 次 Allow
Then 前 2 次通过，第 3 次被拒绝或等待

**TC-006: fallback 降级**
Given primary 返回错误，secondary 可用
When 调用 Fallback
Then 返回 secondary 的结果并记录 primary 错误

**TC-008: 策略组合**
Given timeout、retry 与 fallback 以装饰器方式组合
When 调用组合后的策略
Then 外层策略按声明顺序包装内层策略，整体返回最外层结果

### 15.3 Benchmark

| 场景                        | 目标             |            |
| --------------------------- | ---------------- | ---------- |
| 单次 timeout 调用（无超时） | < 100ns 额外开销 |            |
| 单次 retry 调用（无重试）   | < 200ns 额外开销 |            |
| circuit breaker 状态检查    | < 50ns           |            |
| rate limiter Allow()        | < 100ns          |            |
| 策略组合（5 层嵌套）        | < 1μs 额外开销   |            |

### 15.4 集成测试

| 场景           | 验证点                           |
| -------------- | -------------------------------- |
| 模拟交易所超时 | timeout 生效，retry 重试         |
| 模拟连续失败   | circuit breaker 熔断并恢复       |
| 高并发场景     | bulkhead + rate limiter 正确限流 |

---

## 16. 性能预算

| 操作                            | 目标    | 测量方式       |            |
| ------------------------------- | ------- | -------------- | ---------- |
| 单策略调用开销                  | < 200ns | benchmark test |            |
| 5 层嵌套策略开销                | < 1μs   | benchmark test |            |
| circuit breaker 状态检查        | < 50ns  | benchmark test |            |
| 常驻内存（per circuit breaker） | < 1KB   | profiling      |            |

---

## 17. 可观测性

| 类型   | 名称                              | 说明                                               |        |
| ------ | --------------------------------- | -------------------------------------------------- | ------ |
| metric | `resiliencx.timeout.count`        | counter，超时次数                                  |        |
| metric | `resiliencx.retry.count`          | counter，重试次数                                  |        |
| metric | `resiliencx.retry.success`        | counter，重试后成功次数                            |        |
| metric | `resiliencx.circuit.state`        | gauge，熔断器状态（0=closed, 1=open, 2=half-open） |        |
| metric | `resiliencx.circuit.open.count`   | counter，熔断器打开次数                            |        |
| metric | `resiliencx.bulkhead.rejected`    | counter，被拒绝的请求数                            |        |
| metric | `resiliencx.ratelimit.rejected`   | counter，被限流的请求数                            |        |
| log    | `resiliencx.circuit.state_change` | info，熔断器状态变更                               |        |
| log    | `resiliencx.retry.exhausted`      | warn，重试耗尽                                     |        |

---

## 18. 安全

| 要求                   | 实现方式                                                                |
| ---------------------- | ----------------------------------------------------------------------- |
| 错误消息不泄露敏感数据 | 错误消息只包含策略名和错误类型，不包含请求内容                          |
| rate limiter 防绕过    | 使用令牌桶算法，不依赖客户端行为                                        |
| 输入校验               | fn 参数非 nil 检查；max_retries/burst/max_concurrent 范围校验（≤10000） |
| 资源防护               | goroutine 创建受 bulkhead 限制，防止无界并发                            |
| 配置脱敏               | 策略配置不含凭证，敏感参数通过环境变量注入                              |
| panic 恢复             | fn 内部 panic 被 recover，记录日志并返回错误                            |

---

## 19. CI 门禁

### 19.1 通用 Gate

| Gate        | 命令                                                                                                               | 阻塞条件                 |            |
| ----------- | ------------------------------------------------------------------------------------------------------------------ | ------------------------ | ---------- |
| 编译        | `go build ./...`                                                                                                   | 编译失败                 |            |
| 测试        | `go test ./... -race -count=1`                                                                                     | 任何测试失败或 data race |            |
| 覆盖率      | `mkdir -p .coverage && go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | 总覆盖率 < 80%           |            |
| vet         | `go vet ./...`                                                                                                     | 任何 vet 错误            |            |
| lint        | `golangci-lint run`                                                                                                | 任何 lint 错误           |            |
| 依赖检查    | `go mod tidy && git diff --exit-code go.mod go.sum`                                                                | go.mod 不整洁            |            |
| Secret 扫描 | `gitleaks detect --no-git`                                                                                         | 泄露 secret              |            |
| Benchmark   | `go test -bench=. -benchmem -count=3 ./...`                                                                        | 结果附在 PR comment      |            |

### 19.2 resiliencx 专属 Gate

| Gate            | 命令                   | 阻塞条件         |               |
| --------------- | ---------------------- | ---------------- | ------------- |
| 不依赖 kernel   | `go list -deps ./... \ | grep "kernel"`   | 依赖 kernel   |
| 不依赖 observex | `go list -deps ./... \ | grep "observex"` | 依赖 observex |

---

## 20. 升级兼容性

| 变更类型                | 版本升级                  |
| ----------------------- | ------------------------- |
| 策略函数签名变更        | **major**                 |
| 新增可选策略            | minor                     |
| Policies 结构体新增字段 | minor                     |
| 默认参数变更            | **minor**（注意行为变化） |
| 新增配置字段            | minor                     |

---

## 21. 发布 DoD

- [ ] 所有公共接口有 godoc 注释
- [ ] 所有公共类型有示例代码
- [ ] CHANGELOG.md 已更新
- [ ] README.md 包含：模块定位、快速开始、配置说明、API 概览
- [ ] 单元测试覆盖率 ≥ 80%
- [ ] `-race` 测试通过
- [ ] Benchmark 结果无 > 10% 回退
- [ ] `go vet` 无警告
- [ ] `golangci-lint` 无错误
- [ ] Secret 扫描通过
- [ ] 公共 API 无破坏性变更（或已 bump major）
- [ ] 所有 Functional Requirements 有对应测试
- [ ] 所有 Edge Cases 有对应测试

---

## 22. 待解决问题

- 是否需要支持自适应 retry（根据历史成功率动态调整策略）？
- 是否需要支持分布式 circuit breaker（多实例共享熔断状态）？
- rate limiter 是否需要支持多维度限流（per-endpoint, per-user）？
- 策略配置是否需要支持运行时动态更新？

---

## 23. 变更历史

| 日期       | 版本   | 变更内容                                                       | 作者       |
| ---------- | ------ | -------------------------------------------------------------- | ---------- |
| 2026-06-12 | v1.0.1 | kernel 依赖修正、BR 违反后果补全、AC 标签显式化、Security 补强 | ZoneCNH    |
| 2026-06-07 | v1.0.0 | 初始版本                                                       | ZoneCNH    |
