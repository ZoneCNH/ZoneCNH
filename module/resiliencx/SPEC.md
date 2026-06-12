# resiliencx 完整规格

> Foundation L1 运行时策略库。timeout/retry/circuit/bulkhead/rate limit/fallback。

最后更新：2026-06-12

---

## 1. Metadata

- Status: Approved
- Spec-Version: v1.0.1
- Last-Updated: 2026-06-12
- Owner: ZoneCNH
- Layer: L1 基础能力
- Version: v0.7.3
- Repository: [github.com/ZoneCNH/resiliencx](https://github.com/ZoneCNH/resiliencx)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md)

---

### 1.1 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|----------|------|
| 2026-06-12 | v1.0.1 | kernel 依赖修正、BR 违反后果补全、AC 标签显式化、Security 补强 | ZoneCNH |
| 2026-06-07 | v1.0.0 | 初始版本 | ZoneCNH |

## 2. Summary

`resiliencx` 是策略库，提供 timeout、retry、circuit breaker、bulkhead、rate limiter、fallback 等弹性原语。策略由业务模块在运行时组装，不提供 harness 或自动注入。

---

## 3. Problem

分布式系统中，网络调用、交易所接口、消息队列都会面对超时或失败场景。没有统一的弹性策略，会导致：

- 每个模块自行实现重试逻辑，代码重复且不一致
- 熔断器缺失，故障级联传播
- 限流策略缺失，交易所 API 被封禁
- 策略参数散落在各处配置中，无法统一调优

---

## 4. Goals

- 提供声明式弹性原语：timeout / retry / circuit breaker / bulkhead / rate limiter / fallback
- 支持策略组合（嵌套执行）
- 配置驱动，参数从 `configx.Reader` 读取
- 可观测（每个策略的执行结果可被 metrics 采集）
- 不引入框架（stdlib + 最少依赖）

---

## 5. Non-goals

- 不做应用生命周期管理（→ `kernel`）
- 不做日志实现（→ `observex`）
- 不做配置加载（→ `configx`）
- 不做定时调度（→ `schedulex`）
- 不做测试编排（→ `testkitx`）
- 不提供 harness 或自动注入（策略由业务模块自行组装）

---

## 6. Consumers

| 消费者 | 使用方式 |
|--------|----------|
| `market-data` | 对交易所 API 调用设置 timeout + retry + circuit breaker |
| `risk-engine` | 对下单接口设置 rate limiter + fallback |
| `signal-engine` | 对因子计算设置 timeout |
| `order-engine` | 对交易所 API 设置 bulkhead + retry |
| 业务域模块 | 按需组装策略，通过 `resiliencx.Policies` 传递 |

---

## 7. Functional Requirements

### FR-001: Timeout
> AC-001: timeout 正常完成 / 超时 / ctx 取消

WHEN 调用 `Timeout(ctx, duration, fn)` 且 fn 在 duration 内完成
THEN 返回 fn 的结果

WHEN 调用 `Timeout(ctx, duration, fn)` 且 fn 超过 duration
THEN 返回 `ErrTimeout`

WHEN ctx 在 fn 完成前被取消
THEN 返回 ctx.Err()

### FR-002: Retry
> AC-002: retry 首次成功 / 持续失败 / 达到上限 / ctx 取消

WHEN 调用 `Retry(ctx, policy, fn)` 且 fn 首次成功
THEN 返回结果，不重试

WHEN 调用 `Retry(ctx, policy, fn)` 且 fn 持续失败
THEN 按 policy 重试，直到达到 max_retries

WHEN 达到 max_retries 且仍失败
THEN 返回最后一次的错误

WHEN retry 期间 ctx 被取消
THEN 立即返回 ctx.Err()

### FR-003: CircuitBreaker
> AC-003: 三态转换正确 & AC-004: 并发安全

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
> AC-005: 并发控制 / 等待 / 超时

WHEN 调用 `bulkhead.Execute(fn)` 且并发数 < max_concurrent
THEN 执行 fn

WHEN 调用 `bulkhead.Execute(fn)` 且并发数已达 max_concurrent
THEN 等待直到有空位或 ctx 超时，超时返回 `ErrBulkheadFull`

### FR-005: RateLimiter
> AC-006: Allow/Wait 正确 & 并发安全

WHEN 调用 `limiter.Allow()` 且当前速率 < max_rate
THEN 返回 true

WHEN 调用 `limiter.Allow()` 且当前速率 >= max_rate
THEN 返回 false

WHEN 调用 `limiter.Wait(ctx)` 且需要等待
THEN 阻塞直到允许或 ctx 超时

### FR-006: Fallback
> AC-007: primary 成功 / 失败降级

WHEN 调用 `Fallback(primary, secondary)` 且 primary 成功
THEN 返回 primary 的结果

WHEN 调用 `Fallback(primary, secondary)` 且 primary 失败
THEN 执行 secondary，返回 secondary 的结果

---

## 8. Business Rules

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

## 9. Interface Contract

### 9.1 策略接口

```go
// Timeout
func Timeout(ctx context.Context, d time.Duration, fn func(ctx context.Context) error) error

// Retry
type RetryPolicy struct {
    MaxRetries  int
    InitialWait time.Duration
    MaxWait     time.Duration
    Multiplier  float64
}
func Retry(ctx context.Context, policy RetryPolicy, fn func(ctx context.Context) error) error

// CircuitBreaker
type CircuitBreaker interface {
    Execute(fn func() error) error
    State() CircuitState
}
type CircuitState int
const (
    CircuitClosed   CircuitState = iota
    CircuitOpen
    CircuitHalfOpen
)
func NewCircuitBreaker(opts ...CircuitOption) CircuitBreaker

// Bulkhead
type Bulkhead interface {
    Execute(fn func() error) error
    Available() int
}
func NewBulkhead(maxConcurrent int, opts ...BulkheadOption) Bulkhead

// RateLimiter
type RateLimiter interface {
    Allow() bool
    Wait(ctx context.Context) error
    Rate() float64
}
func NewRateLimiter(rate float64, burst int) RateLimiter

// Fallback
func Fallback(primary func() error, fallbacks ...func() error) error

// Policies 组合（传给模块的可选依赖）
type Policies struct {
    Timeout    time.Duration
    Retry      RetryPolicy
    Circuit    CircuitBreaker
    Bulkhead   Bulkhead
    RateLimit  RateLimiter
}
```text

### 9.2 用法示例

```go
// 策略组合：timeout + retry + circuit breaker
cb := resiliencx.NewCircuitBreaker(
    resiliencx.WithFailureThreshold(5),
    resiliencx.WithRecoveryTimeout(30*time.Second),
)

err := resiliencx.Timeout(ctx, 5*time.Second, func(ctx context.Context) error {
    return resiliencx.Retry(ctx, resiliencx.RetryPolicy{
        MaxRetries:  3,
        InitialWait: 100 * time.Millisecond,
        MaxWait:     2 * time.Second,
        Multiplier:  2.0,
    }, func(ctx context.Context) error {
        return cb.Execute(func() error {
            return exchangeClient.GetTicker(ctx, "BTCUSDT")
        })
    })
})
```text

---

## 10. Data Model

### 10.1 公共错误

```go
var (
    ErrTimeout       = errors.New("resiliencx: timeout")
    ErrCircuitOpen   = errors.New("resiliencx: circuit breaker open")
    ErrBulkheadFull  = errors.New("resiliencx: bulkhead full")
    ErrRateLimited   = errors.New("resiliencx: rate limited")
    ErrMaxRetries    = errors.New("resiliencx: max retries exceeded")
)
```text

### 10.2 配置结构

```go
type CircuitConfig struct {
    FailureThreshold int           `yaml:"failure_threshold"` // 连续失败次数触发熔断
    RecoveryTimeout  time.Duration `yaml:"recovery_timeout"`  // 熔断恢复超时
    HalfOpenMax      int           `yaml:"half_open_max"`     // Half-Open 状态最大试探次数
}

type BulkheadConfig struct {
    MaxConcurrent int           `yaml:"max_concurrent"` // 最大并发数
    MaxWait       time.Duration `yaml:"max_wait"`       // 最大等待时间
}
```text

---

## 11. Config Schema

```yaml
resiliencx:
  default_timeout: 5s
  default_retry:
    max_retries: 3
    initial_wait: 100ms
    max_wait: 2s
    multiplier: 2.0
  circuit_breaker:
    failure_threshold: 5
    recovery_timeout: 30s
    half_open_max: 1
  bulkhead:
    max_concurrent: 10
    max_wait: 5s
  rate_limiter:
    rate: 100        # requests per second
    burst: 200       # burst capacity
```text

---

## 12. Error Handling

| 错误 | 调用方处理 |
|------|-----------|
| `ErrTimeout` | 检查超时时间是否匹配 SLA，按需增加超时时间或优化下游 |
| `ErrCircuitOpen` | 等待 recovery_timeout 后重试，或使用 fallback |
| `ErrBulkheadFull` | 减少并发量或增加 max_concurrent |
| `ErrRateLimited` | 降低请求频率或增加 rate 配额 |
| `ErrMaxRetries` | 检查底层错误原因；永久性错误不得继续重试 |

**错误消息格式：** `"resiliencx: <strategy>: <detail>"`
**错误包装：** 使用 `%w` 保留底层错误链

---

## 13. Edge Cases

| 场景 | 预期行为 |
|------|----------|
| retry policy 的 max_retries=0 | 不重试，直接返回错误 |
| retry policy 的 multiplier=0 | 使用默认 multiplier=2.0 |
| circuit breaker 的 failure_threshold=0 | 第一次失败就熔断 |
| bulkhead 的 max_concurrent=0 | 返回配置错误 |
| rate limiter 的 rate=0 | 永远不允许（所有请求被限流） |
| 策略组合嵌套过深（>10 层） | 正常执行，无栈溢出 |
| 并发调用 circuit breaker 状态变更 | 需要加锁，保证并发安全 |
| ctx 在 retry 等待期间取消 | 立即返回，不继续重试 |
| fn panic | 被 catch，返回 panic 错误 |

---

## 14. Directory Structure

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

## 15. Dependencies

### 15.1 go.mod

```text
module github.com/ZoneCNH/resiliencx

go 1.23
```text

### 15.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| stdlib | observex |
| `configx`（读取策略配置） | schedulex |
| `kernel`（生命周期管理） | testkitx |
| | 所有业务域实现 |
| | 所有存储/中间件扩展 |

---

## 16. Testing

### 16.1 单元测试

| 测试场景 | 验证点 |
|----------|--------|
| timeout 未超时 | fn 正常返回 |
| timeout 超时 | 返回 ErrTimeout |
| retry 首次成功 | 不重试 |
| retry 持续失败 | 达到 max_retries 后返回最后一次错误 |
| retry 期间 ctx 取消 | 立即返回 |
| circuit breaker 正常 | Closed 状态，fn 正常执行 |
| circuit breaker 熔断 | Open 状态，立即返回 ErrCircuitOpen |
| circuit breaker 恢复 | Half-Open → Closed |
| bulkhead 并发控制 | 超过 max_concurrent 时等待或拒绝 |
| rate limiter 限流 | 超过 rate 时 Allow() 返回 false |
| fallback 主成功 | 不执行 secondary |
| fallback 主失败 | 执行 secondary |
| 策略组合 | timeout + retry + circuit breaker 正确嵌套 |
| 并发安全 | -race 测试通过 |

### 16.2 Given/When/Then 用例

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

### 16.3 Benchmark

| 场景 | 目标 |
|------|------|----------|
| 单次 timeout 调用（无超时） | < 100ns 额外开销 |
| 单次 retry 调用（无重试） | < 200ns 额外开销 |
| circuit breaker 状态检查 | < 50ns |
| rate limiter Allow() | < 100ns |
| 策略组合（5 层嵌套） | < 1μs 额外开销 |

### 16.4 集成测试

| 场景 | 验证点 |
|------|--------|
| 模拟交易所超时 | timeout 生效，retry 重试 |
| 模拟连续失败 | circuit breaker 熔断并恢复 |
| 高并发场景 | bulkhead + rate limiter 正确限流 |

---

## 17. Performance Budget

| 操作 | 目标 | 测量方式 |
|------|------|----------|----------|
| 单策略调用开销 | < 200ns | benchmark test |
| 5 层嵌套策略开销 | < 1μs | benchmark test |
| circuit breaker 状态检查 | < 50ns | benchmark test |
| 常驻内存（per circuit breaker） | < 1KB | profiling |

---

## 18. Observability

| 类型 | 名称 | 说明 |
|------|------|----------|------|
| metric | `resiliencx.timeout.count` | counter，超时次数 |
| metric | `resiliencx.retry.count` | counter，重试次数 |
| metric | `resiliencx.retry.success` | counter，重试后成功次数 |
| metric | `resiliencx.circuit.state` | gauge，熔断器状态（0=closed, 1=open, 2=half-open） |
| metric | `resiliencx.circuit.open.count` | counter，熔断器打开次数 |
| metric | `resiliencx.bulkhead.rejected` | counter，被拒绝的请求数 |
| metric | `resiliencx.ratelimit.rejected` | counter，被限流的请求数 |
| log | `resiliencx.circuit.state_change` | info，熔断器状态变更 |
| log | `resiliencx.retry.exhausted` | warn，重试耗尽 |

---

## 19. Security

| 要求 | 实现方式 |
|------|----------|
| 错误消息不泄露敏感数据 | 错误消息只包含策略名和错误类型，不包含请求内容 |
| rate limiter 防绕过 | 使用令牌桶算法，不依赖客户端行为 |
| 输入校验 | fn 参数非 nil 检查；max_retries/burst/max_concurrent 范围校验（≤10000） |
| 资源防护 | goroutine 创建受 bulkhead 限制，防止无界并发 |
| 配置脱敏 | 策略配置不含凭证，敏感参数通过环境变量注入 |
| panic 恢复 | fn 内部 panic 被 recover，记录日志并返回错误 |

---

## 20. CI Gate

### 20.1 通用 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 任何测试失败或 data race |
| 覆盖率 | `mkdir -p .coverage && go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | 总覆盖率 < 80% |
| vet | `go vet ./...` | 任何 vet 错误 |
| lint | `golangci-lint run` | 任何 lint 错误 |
| 依赖检查 | `go mod tidy && git diff --exit-code go.mod go.sum` | go.mod 不整洁 |
| Secret 扫描 | `gitleaks detect --no-git` | 泄露 secret |
| Benchmark | `go test -bench=. -benchmem -count=3 ./...` | 结果附在 PR comment |

### 20.2 resiliencx 专属 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|----------|
| 不依赖 kernel | `go list -deps ./... \| grep "kernel"` | 依赖 kernel |
| 不依赖 observex | `go list -deps ./... \| grep "observex"` | 依赖 observex |

---

## 21. Upgrade Compatibility

| 变更类型 | 版本升级 |
|----------|----------|
| 策略函数签名变更 | **major** |
| 新增可选策略 | minor |
| Policies 结构体新增字段 | minor |
| 默认参数变更 | **minor**（注意行为变化） |
| 新增配置字段 | minor |

---

## 22. Release DoD

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

## 23. Open Questions

- 是否需要支持自适应 retry（根据历史成功率动态调整策略）？
- 是否需要支持分布式 circuit breaker（多实例共享熔断状态）？
- rate limiter 是否需要支持多维度限流（per-endpoint, per-user）？
- 策略配置是否需要支持运行时动态更新？
