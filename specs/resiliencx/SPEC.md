# resiliencx 完整规格

> Foundation L1 运行时策略库。timeout/retry/circuit/bulkhead/rate limit/fallback。

最后更新：2026-06-07

---

## 1. 定位

`resiliencx` 负责控制失败传播和副作用边界，让系统在外部依赖不稳定时保持可控。

### 核心职责

- timeout（PerAttemptTimeout + TotalTimeout）
- retry（max attempts、max elapsed、backoff、jitter）
- exponential backoff / jitter
- circuit breaker（closed/open/half-open 状态机）
- rate limiter（QPS、burst、按 key 限流）
- bulkhead（并发隔离、队列上限、快速拒绝）
- fallback（显式降级函数）
- retryable error classifier
- idempotency hint（非幂等操作默认禁止自动 retry）
- policy event sink
- context cancellation
- metrics / tracing hook

### 明确不做

- 不决定业务是否可重试
- 不吞掉错误
- 不写交易所或订单语义
- 不做交易风控（属于 `risk-engine`）
- 不做调度（属于 `schedulex`）

### 身份修复（P0）

当前 `resiliencx` README 描述的 Standard Source / Generator / Harness / Evidence Runtime 叙事必须迁回 `xlib-standard`。`resiliencx` 围绕 timeout、retry、circuit、bulkhead、rate limit、fallback 和 policy event 建模。

| 边界 | `kernel.retryx` | `resiliencx` |
|------|-----------------|--------------|
| 层级 | L0 primitive | L1 runtime policy |
| 主要职责 | backoff、retry marker、简单 retry loop | timeout、retry、circuit、bulkhead、rate、fallback |
| 观测 | 不负责完整 metrics | 输出 policy events，交给 `observex` 记录 |
| 状态 | 尽量无状态 | circuit breaker / limiter 可有状态 |
| 依赖 | stdlib only | 可依赖 `kernel`，观测通过接口注入 |
| 使用场景 | 基础库内部轻量重试 | 外部 API、交易所、数据源、消息、任务执行 |

---

## 2. 接口契约

### 2.1 Policy

```go
type Policy struct {
    Retry     *RetryPolicy
    Timeout   time.Duration
    Breaker   *BreakerPolicy
    RateLimit *RateLimitPolicy
    Bulkhead  *BulkheadPolicy
    Fallback  func(ctx context.Context, err error) error
}

type RetryPolicy struct {
    MaxAttempts   int
    InitialBackoff time.Duration
    MaxBackoff    time.Duration
    Multiplier    float64
    Jitter        float64
    Classifier    RetryClassifier
}

type RetryClassifier func(err error) bool // true = 可重试

type BreakerPolicy struct {
    FailureThreshold int
    SuccessThreshold int
    OpenDuration     time.Duration
}

type RateLimitPolicy struct {
    Rate  float64 // 每秒令牌数
    Burst int
    Key   string  // 按 key 限流
}

type BulkheadPolicy struct {
    MaxConcurrency int
    MaxWait        time.Duration
}
```

### 2.2 Executor

```go
type Executor interface {
    Execute(ctx context.Context, policy Policy, fn func(ctx context.Context) error) error
}
```

### 2.3 Breaker

```go
type BreakerState int

const (
    BreakerClosed   BreakerState = iota
    BreakerOpen
    BreakerHalfOpen
)

type Breaker interface {
    State() BreakerState
    Allow() bool
    Success()
    Failure()
    Reset()
}
```

### 2.4 Timeout 语义

```go
// PerAttemptTimeout: 每次重试的超时
// TotalTimeout: 整个操作（含所有重试）的超时
type TimeoutConfig struct {
    PerAttempt time.Duration
    Total      time.Duration
}
```

### 2.5 策略链执行顺序

```
context budget → rate limit → bulkhead → circuit breaker → timeout → retry loop → fallback → event sink
```

### 2.6 契约约束

- `Execute` 必须在 `ctx.Done()` 后立即返回，不继续执行副作用
- `RetryClassifier` 返回 `false` 时立即停止重试，不消耗后续 attempt
- `Breaker` 状态转换必须是原子的、并发安全的
- 默认 `MaxAttempts` 上限为 10，防止配置错误导致无限重试
- 非幂等操作默认禁止自动 retry（`idempotency hint`）
- `Fallback` 只在最终失败后调用，不掩盖中间成功

### 2.7 公共错误

```go
var (
    ErrTimeout        = errors.New("resiliencx: operation timeout")
    ErrRetryExhausted = errors.New("resiliencx: retry attempts exhausted")
    ErrCircuitOpen    = errors.New("resiliencx: circuit breaker is open")
    ErrRateLimited    = errors.New("resiliencx: rate limit exceeded")
    ErrBulkheadFull   = errors.New("resiliencx: bulkhead capacity exceeded")
    ErrNonIdempotent  = errors.New("resiliencx: non-idempotent operation cannot retry")
)
```

---

## 3. 目录结构

```
resiliencx/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go
├── resiliencx.go               # Executor / Policy 顶层导出
├── errors.go
├── options.go
├── policy.go                   # Policy 构造和验证
├── runner.go                   # 策略链执行器
├── operation.go                # 操作包装
├── timeout/
│   ├── timeout.go              # PerAttemptTimeout + TotalTimeout
│   └── timeout_test.go
├── retry/
│   ├── retry.go
│   ├── backoff.go              # exponential + jitter
│   └── retry_test.go
├── breaker/
│   ├── breaker.go              # closed/open/half-open 状态机
│   └── breaker_test.go
├── bulkhead/
│   ├── bulkhead.go             # 并发隔离、队列上限
│   └── bulkhead_test.go
├── ratelimit/
│   ├── ratelimit.go            # QPS、burst、按 key 限流
│   └── ratelimit_test.go
├── fallback/
│   ├── fallback.go             # 显式降级函数
│   └── fallback_test.go
├── classifier.go               # retryable / non-retryable / fatal
├── idempotency.go              # 非幂等操作禁止自动 retry
├── event.go                    # policy event sink
├── noop.go                     # 未配置时安全运行
├── internal/
│   ├── token/                  # 令牌桶实现
│   └── state/                  # 状态机实现
├── testdata/
│   └── *.golden
├── example_test.go
├── benchmark_test.go
└── integration_test.go
```

---

## 4. 依赖

### 4.1 go.mod

```
module github.com/ZoneCNH/resiliencx

go 1.23
```

### 4.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| kernel（L0 原语） | configx |
| observex（interface-only） | schedulex |
| stdlib | testkitx（仅 test） |
| | 所有业务域实现 |

---

## 5. CI Gate

### 5.1 通用 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 任何测试失败或 data race |
| 覆盖率 | `go test ./... -coverprofile=cover.out && go tool cover -func=cover.out` | 总覆盖率 < 80% |
| vet | `go vet ./...` | 任何 vet 错误 |
| lint | `golangci-lint run` | 任何 lint 错误 |
| 依赖检查 | `go mod tidy && git diff --exit-code go.mod go.sum` | go.mod 不整洁 |
| Secret 扫描 | `gitleaks detect --no-git` | 泄露 secret |
| Benchmark | `go test -bench=. -benchmem -count=3 ./...` | 结果附在 PR comment |

### 5.2 resiliencx 专属 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| identity check | `make identity-check` | README 中出现 Standard Source / Generator / Harness 叙事 |
| policy chain order | `go test -run TestPolicyChainOrder ./...` | 策略链执行顺序不符合规范 |

---

## 6. 测试矩阵

### 6.1 单元测试

| 测试场景 | 验证点 |
|----------|--------|
| retry 成功 | 第 2 次成功 → 总共调用 2 次 |
| retry 用尽 | 全部失败 → 返回最后一次错误 |
| classifier 拒绝 | 不可重试错误 → 立即返回 |
| backoff 递增 | delay 按 multiplier 递增 |
| jitter 范围 | delay 在 [base, base*(1+jitter)] 范围内 |
| circuit breaker 状态转换 | closed → open → half-open → closed |
| breaker 并发安全 | 100 goroutine 同时操作无 race |
| timeout (PerAttempt) | 每次尝试超时后 ctx cancelled |
| timeout (Total) | 整个操作超时后 ctx cancelled |
| context 取消 | parent cancel → 不继续重试 |
| rate limiter | 超过 rate → 请求被拒 |
| bulkhead | 超过 max_concurrency → 等待或拒绝 |
| fallback | 最终失败后调用 fallback |
| non-idempotent | 非幂等操作 → `ErrNonIdempotent` |
| noop executor | 未配置策略 → 直接执行 |
| policy event | 策略事件正确输出到 sink |

### 6.2 Benchmark

| 场景 | 目标 |
|------|------|
| retry 无重试开销 | < 500ns |
| breaker 检查 | < 100ns |
| rate limiter 令牌获取 | < 200ns |

### 6.3 集成测试

| 场景 | 验证点 |
|------|--------|
| retry + breaker 组合 | retry 用尽 → breaker 记录失败 → breaker open |
| schedulex + resiliencx | job 失败 → retry → breaker open → 后续 fail-fast |

---

## 7. 性能预算

| 操作 | 目标 | 测量方式 |
|------|------|----------|
| retry 包装开销（无重试时） | < 500ns | benchmark test |
| circuit breaker 状态检查 | < 100ns | benchmark test |
| rate limiter 令牌获取 | < 200ns | benchmark test |
| 常驻内存 | < 1MB | profiling |

---

## 8. 可观测输出

| 类型 | 名称 | 说明 |
|------|------|------|
| metric | `resiliencx.retry.attempts` | histogram，每次操作的重试次数 |
| metric | `resiliencx.retry.total` | counter，重试总次数，label: result(success/fail) |
| metric | `resiliencx.circuit.state` | gauge，circuit breaker 当前状态（0=closed, 1=open, 2=half-open） |
| metric | `resiliencx.circuit.transitions` | counter，状态转换次数，label: from→to |
| metric | `resiliencx.timeout.triggered` | counter，超时触发次数 |
| metric | `resiliencx.ratelimit.rejected` | counter，被限流拒绝的请求数 |
| metric | `resiliencx.bulkhead.rejected` | counter，被隔离拒绝的请求数 |
| log | `resiliencx.circuit.opened` | warn，circuit breaker 打开，含 failure count + component |
| log | `resiliencx.circuit.closed` | info，circuit breaker 恢复关闭 |
| log | `resiliencx.retry.exhausted` | error，重试次数用尽，含 operation + last error |
| span | `resiliencx.retry` | 包含重试逻辑的 span，attribute: attempt, delay |

---

## 9. 故障模式

| 故障场景 | 降级行为 | 是否阻塞启动 |
|----------|----------|--------------|
| circuit breaker 全开 | **快速失败**：调用方立即收到错误，不排队等待 | 否（运行时） |
| 内部 panic | **隔离**：不传播到调用方，记录 panic 信息和堆栈 | 否 |
| rate limiter 配置错误 | **保守默认**：max_attempts 上限 10，防止无限重试 | 否 |

---

## 10. 安全要求

| 要求 | 实现方式 |
|------|----------|
| 重试不放大攻击面 | 默认 max_attempts 上限（如 10），防止配置错误导致无限重试 |
| circuit breaker 不泄露内部状态 | 对外只暴露 open/closed/half-open，不暴露具体失败计数 |
| 非幂等操作保护 | 默认禁止自动 retry，需显式标记 `Idempotent: true` |

---

## 11. 配置 schema

```yaml
resiliencx:
  defaults:
    retry:
      max_attempts: 3
      initial_backoff: 100ms
      max_backoff: 10s
      multiplier: 2.0
      jitter: 0.1
    timeout:
      per_attempt: 5s
      total: 30s
    circuit_breaker:
      failure_threshold: 5
      success_threshold: 3
      open_duration: 30s
    rate_limiter:
      rate: 1000
      burst: 50
    bulkhead:
      max_concurrency: 100
      max_wait: 5s
```

---

## 12. 与 risk-engine 的边界

| 属于 `resiliencx` | 属于 `risk-engine` |
|-------------------|---------------------|
| timeout/retry/circuit/bulkhead/rate/fallback | 仓位大小、杠杆、订单拒绝 |
| 操作级容错 | 策略权限、暴露限制 |
| 外部依赖弹性 | 交易风控决策 |

---

## 13. 升级兼容

| 变更类型 | 版本升级 |
|----------|----------|
| Executor / Breaker interface 变更 | **major** |
| Policy 结构体字段变更 | **major** |
| 新增可选配置字段 | patch / minor |
| 新增必填配置字段 | **minor**（带默认值） |
| 修复 bug | **patch** |

---

## 14. 发布 DoD

- [ ] 所有公共接口有 godoc 注释
- [ ] 所有公共类型有示例代码
- [ ] CHANGELOG.md 已更新
- [ ] README.md 包含：模块定位、快速开始、配置说明、API 概览
- [ ] README 中无 Standard Source / Generator / Harness 叙事
- [ ] 单元测试覆盖率 ≥ 80%
- [ ] `-race` 测试通过
- [ ] Benchmark 结果无 > 10% 回退
- [ ] `go vet` 无警告
- [ ] `golangci-lint` 无错误
- [ ] identity check 通过
- [ ] policy chain order 测试通过
- [ ] Secret 扫描通过
- [ ] 公共 API 无破坏性变更（或已 bump major）
