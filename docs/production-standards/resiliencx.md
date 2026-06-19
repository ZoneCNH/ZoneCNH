# resiliencx

## 1. 模块定位
resiliencx 是 FoundationX 弹性策略库（L3 Reliability 层），提供 timeout、retry、circuit breaker、bulkhead、rate limiter、fallback 六大韧性原语。六大策略以独立子包形式提供（`pkg/resiliencx/{timeout,retry,circuit,bulkhead,ratelimit,fallback}`），由业务模块在运行时通过函数嵌套（装饰器模式）组装。当前 Spec-Version v1.0.2、Runtime Tag v1.0.2（commit 1aaa0dc，已发布）。

## 2. 生产职责
- FR-001 Timeout：`timeout.Do(ctx, duration, fn)`，超时返回 ctx.Err()
- FR-002 Retry：`retry.Do(ctx, policy, fn)`，指数退避重试至 MaxAttempts
- FR-003 CircuitBreaker：`circuit.New(threshold, cooldown)`，三态转换 Closed→Open→HalfOpen
- FR-004 Bulkhead：`bulkhead.New(max)`，信号量并发限制，Acquire / TryAcquire / Do
- FR-005 RateLimiter：`ratelimit.New(rate, max)`，令牌桶 Allow / AllowN / Reserve
- FR-006 Fallback：`fallback.Do(ctx, fn, fallbacks...)`，主逻辑失败降级链

## 3. 边界定义
- BR-001：策略函数接受 context.Context（timeout/retry/bulkhead/fallback；circuit/ratelimit 纯内存不接 ctx）
- BR-002：策略参数通过构造函数 / Policy struct 传入，可由 configx 注入；不自带配置解析
- BR-003：策略组合用函数嵌套（装饰器模式），外层包装内层
- BR-007：纯 stdlib，`go mod graph` 无第三方包

## 4. 不负责什么
- 不做应用生命周期管理（→ kernel）
- 不做日志实现（→ observex）
- 不做配置加载（→ configx）
- 不做定时调度（→ schedulex）
- 不做测试编排（→ testkitx）
- 不提供 harness、自动注入或统一执行链（ResilienceExecutor / PolicyChain 为 v1.2+ 演进目标）

## 5. 架构位置
L3 Reliability 层（SPEC §3 标注 L1 基础能力，与 FOUNDATION-DEPS.yaml 一致）。实际依赖仅 stdlib（比 SPEC 许可更严格）；SPEC 许可依赖 kernel / configx，但运行时 go list -deps 不含 kernel / configx / observex。消费者：market-data（timeout+retry+circuit）、risk-engine（rate limiter+fallback）、signal-engine（timeout）、order-engine（bulkhead+retry）、业务域模块按需 import 子包。

## 6. 生命周期
- 策略本身无 bootstrap/init/running/draining 状态机，是无状态/单实例原语
- 客户端生命周期可选：`resiliencx.New(ctx, Config, opts...) → *Client` + `Close(ctx)`
- circuit breaker 状态：Closed（正常执行）→ Open（连续失败 ≥ threshold，返回 circuit.ErrOpen）→ HalfOpen（cooldown 过后单次试探）→ Closed（试探成功）
- bulkhead 槽位：Acquire 等待 / TryAcquire 立即返回 ErrFull / Release 释放

## 7. 标准目录结构
```text
resiliencx/                          # github.com/ZoneCNH/resiliencx
├── pkg/resiliencx/
│   ├── doc.go / version.go / options.go / config.go / client.go
│   ├── errors.go / classifier.go / idempotency.go / event.go
│   ├── resilience.go / metrics.go / health.go / noop.go
│   ├── compose.go / compose_test.go / benchmark_test.go
│   ├── timeout/{timeout.go, timeout_test.go}
│   ├── retry/{retry.go, retry_test.go}
│   ├── circuit/{circuit.go, circuit_test.go}
│   ├── bulkhead/{bulkhead.go, bulkhead_test.go}
│   ├── ratelimit/{ratelimit.go, ratelimit_test.go}
│   └── fallback/{fallback.go, fallback_test.go}
├── internal/ / contracts/ / examples/ / testkit/ / scripts/run_integration_test.go
```

## 8. 配置规范
运行时不自带 yaml 解析。策略参数通过构造函数位置参数或 Policy struct 传入，消费者通过 configx 读取后注入。参考 yaml 形态：default_timeout=5s、default_retry{max_retries:3→MaxAttempts=4, initial_wait:100ms, max_wait:2s, multiplier:2.0}、circuit_breaker{failure_threshold:5, recovery_timeout:30s}、bulkhead{max_concurrent:10}、rate_limiter{rate:100, burst:200}。客户端 Config{Name, Timeout, Secret} 带 Validate / Sanitize。

## 9. 错误模型
sentinel error 按子包分散定义（非包根聚合）：
- `context.DeadlineExceeded`（timeout.Do 超时，用 errors.Is 判定）
- `circuit.ErrOpen`（Open 状态拒绝）、`circuit.ErrHalfOpen`（试探在飞拒绝并发）
- `bulkhead.ErrFull`（TryAcquire 无槽位）
- `resiliencx.ErrAlreadyExecuted`（幂等守卫命中）
- 包根结构化 Error{Kind, Op, Message, Cause, Retryable}，ErrorKind=config/validation/connection/unavailable/timeout/auth/conflict/rate_limit/internal，格式 `<ErrorKind>: <Op>: <Message>`
- retry.Do 耗尽返回最后一次 fn 错误（不包装 ErrMaxRetries）

## 10. 日志规范
resiliencx 本身不实现日志（BR：→ observex）。策略执行通过本地 Metrics interface + EventSink 暴露事件，由调用方注入 observex adapter（运行时不直接依赖 observex）。Event{Type, Time, Attempt, Err, Duration, Metadata} 通过 Sink.Emit 上报；默认 NoopSink，测试用 SliceSink。DefaultClassifier：Canceled→Fatal、DeadlineExceeded→Retryable、其他→NonRetryable。

## 11. Metrics
v1.0.2 实际 metric 常量（`pkg/resiliencx/metrics.go`，client_ 前缀）：`client_created_total`、`client_closed_total`、`client_errors_total`、`client_health_status`(gauge)、`client_health_latency_ms`、`client_requests_total`、`client_request_duration_seconds`、`client_retries_total`、`client_inflight`(gauge)。旧 SPEC §17 的 `resiliencx.timeout.count` / `resiliencx.circuit.state` 等硬编码名不作为 v1.0.2 稳定契约；goal.md §9.2 的 `resiliencx.calls.total` 为 v1.2+ 统一执行链目标。

## 12. Tracing
resiliencx 不直接实现 tracing。策略观测通过 InstrumentStrategy 包装器上报 span 事件（由调用方注入 observex.Tracer adapter）。recovered panic 事件携带原 panic payload，`IsRecoveredPanic(err)` 可识别。tracing context 跨 goroutine 传播由 observex.Tracer 负责，resiliencx 仅消费 ctx 做 timeout/cancel。

## 13. Reliability
本模块即 Reliability 原语库（L3 重点）：
- **retry**：指数退避 MaxAttempts / InitialWait / MaxWait / Multiplier，ctx 取消立即返回
- **timeout**：ctx.Err() 即 context.DeadlineExceeded，fn 需自身尊重 ctx（超时后 fn goroutine 继续执行至完成）
- **circuit breaker**：连续失败 ≥ threshold 触发 Open，cooldown 后 HalfOpen 单次试探，sync.Mutex 并发安全（BR-004）
- **bulkhead**：信号量 max_concurrent，达上限阻塞或 TryAcquire 返回 ErrFull
- **rate limiter**：令牌桶 rate/burst，sync.Mutex 并发安全（BR-005），Allow 非阻塞 / Reserve 预扣返回等待时长
- **fallback**：primary 失败依次尝试 fallbacks

## 14. Security
- 错误消息不泄露敏感数据：只含策略名/错误类型，Config.Sanitize 脱敏 Secret
- rate limiter 防绕过：令牌桶算法服务端控制
- 输入校验：Config.Validate 校验 Name/Timeout；策略参数范围校验（≤10000）部分未实现
- 资源防护：goroutine 并发受 bulkhead 限制
- 配置脱敏：sanitize.Secret 脱敏；敏感参数建议环境变量注入
- panic 恢复：Compose / InstrumentStrategy 使用 recovered-panic 包装，payload 不吞失

## 15. Performance SLO
| 操作 | 目标 | 实测 |
|------|------|------|
| 单策略调用开销 | < 200ns | 9.096 ns/op（BenchmarkComposeOneStrategy） |
| 5 层嵌套策略开销 | < 1μs | 20.44 ns/op（BenchmarkComposeFiveStrategies） |
| 策略观测包装 | < 1μs | 664.0 ns/op（BenchmarkInstrumentStrategy） |
| 常驻内存（per circuit breaker） | < 1KB | 非 v1.0.2 阻断项（profiling 未落地） |

## 16. 测试标准
- 单元测试覆盖率 ≥ 80%（release-check score=10.00）
- -race 测试零 data race（所有子包 sync.Mutex 保护）
- go vet 零警告
- TC-001 timeout+retry 组合、TC-002 circuit 熔断、TC-003 circuit 恢复、TC-004 bulkhead 并发限制、TC-005 rate limiter 限流、TC-006 fallback 降级、TC-008 策略组合 TestCompose / TestComposePanicRecovery
- 集成测试 `scripts/run_integration_test.go`：模拟交易所超时、连续失败熔断恢复、高并发 bulkhead+rate limiter
- Benchmark：Compose 9.096 ns/op、5 层 20.44 ns/op、InstrumentStrategy 664.0 ns/op

## 17. Chaos
resiliencx 本身是 chaos 防护工具，其测试模拟各类故障注入：
- 超时注入：timeout.Do 验证 fn 超过 duration 返回 DeadlineExceeded
- 持续失败注入：circuit breaker 连续失败 ≥ threshold 触发熔断
- 高并发压力：bulkhead + rate limiter 验证限流正确
- panic 注入：Compose / InstrumentStrategy 捕获 fn panic 为 recovered-panic 错误（IsRecoveredPanic 可识别）
- ctx 取消注入：retry 等待期间 ctx 取消立即返回 ctx.Err()

## 18. Contract
子包 API（实测签名）：`timeout.Do(ctx, d, fn)` / `retry.Do(ctx, Policy, fn)` / `circuit.New(threshold, cooldown) → *Breaker{Do(fn), State(), Reset()}` / `bulkhead.New(max) → *Bulkhead{Acquire(ctx), TryAcquire(), Release(), Do(ctx, fn), Available()}` / `ratelimit.New(rate, max) → *Limiter{Allow(), AllowN(n), Reserve(n)}` / `fallback.Do(ctx, fn, fallbacks...)`。包根辅助：DefaultClassifier、Error/NewError/WrapError/IsKind、IdempotencyGuard、Event/Sink、ResilienceConfig、Client。

## 19. CI Gate
通用：`go build ./...`、`go test ./... -race -count=1`、覆盖率 < 80% 阻塞、`go vet ./...`、`go mod tidy && git diff --exit-code`（无外部依赖）、Benchmark 附 PR comment。专属：`go list -deps ./... | grep kernel` 阻塞（不依赖 kernel）、`go list -deps ./... | grep observex` 阻塞（不依赖 observex）。Release：`make release-check` score=10.00、`make release-final-check` score=10.00、GitHub Release Check 27777166525 passed。

## 20. Release Gate
DoD 清单：公共接口有 godoc、CHANGELOG.md 更新、README 含定位/快速开始/API、覆盖率 ≥ 80%、-race 通过、Benchmark 无 > 10% 回退、vet 零警告、公共 API 与 SPEC v1.0.2 契约一致、所有 FR 有对应测试。v1.0.2 已发布，release-check + release-final-check score=10.00。未完成项：example_test.go 未实现（由 README + examples 承载）、部分 Edge Cases（MaxAttempts:0 / bulkhead.New(0)）P2 项未覆盖。

## 21. Versioning
semver。当前 Spec-Version / Module-Version / Runtime Tag 三轴对齐于 v1.0.2。策略函数签名变更（子包级 Do/New）→ major；新增可选策略 / retry.Policy 新增字段 / 新增配置字段 → minor；默认参数变更 → minor（注意行为变化）；bug 修复 → patch。v1.0.1 描述的 Policies 聚合 struct 在代码中不存在，相关兼容性条款已移除。

## 22. 兼容性策略
- 子包级策略函数签名变更：major
- 新增可选策略：minor
- retry.Policy 结构体新增字段：minor
- 默认参数变更：minor（注意行为变化）
- 新增配置字段：minor
- 边界情况 EC 全部有定义：MaxAttempts:0（循环不执行返回 nil，⚠️P2）、Multiplier:≤0（回退默认 2）、threshold=0（首次失败即熔断）、maxConcurrent=0（Acquire 永久阻塞）、rate=0（恒 false）、嵌套 >10 层（正常执行）、ctx 取消（立即返回）、fn panic（recovered-panic 包装）

## 23. Failover
- primary 失败 → fallback.Do 依次尝试 fallbacks，返回首个成功或最后错误（FR-006）
- circuit Open → 调用方等待 cooldown 后重试或走 fallback
- circuit HalfOpen 试探在飞 → 并发调用返回 ErrHalfOpen，退避后重试
- exporter / 下游不可达不在 resiliencx 职责，由调用方通过 timeout + circuit + fallback 组合实现 failover

## 24. Backpressure
- bulkhead：信号量 max_concurrent 限制并发，达上限阻塞等待或 TryAcquire 返回 ErrFull（FR-004）
- rate limiter：令牌桶 rate/burst，Allow 令牌不足返回 false（非阻塞），Reserve 预扣返回等待时长（FR-005）
- retry：MaxWait 封顶退避时长，Multiplier 指数退避防止重试风暴
- bounded queue 通过 bulkhead + rate limiter 组合实现 overload protection

## 25. 审计要求
- 策略执行事件审计：Event{Type, Time, Attempt, Err, Duration, Metadata} 通过 Sink.Emit 上报，测试用 SliceSink 捕获
- 幂等守卫审计：IdempotencyGuard.Check / Mark 防止非幂等操作被自动重试，命中返回 ErrAlreadyExecuted
- panic 审计：Compose / InstrumentStrategy 捕获 panic 为 recovered-panic 错误，IsRecoveredPanic 可识别，payload 不吞失
- 依赖边界审计：go mod graph 无第三方包（BR-007），go list 无 kernel/observex 依赖（专属 CI Gate）

## 26. 熵减规则
全局 Entropy Rules + 模块特有禁项：
- 禁止 util dumping（六大策略独立子包，职责分离）
- 禁止 hidden abstraction（策略组合显式函数嵌套，无隐式执行链）
- 禁止 cyclic dependency（fake 包通过 interface mirror 避免反向 import 环）
- 禁止引入框架依赖（BR-007 纯 stdlib）
- 禁止策略硬编码参数（BR-002 参数由构造函数传入）

## 27. AI Constraints
全局 AI Constraints + 模块特有约束：
- 不新增未注册模块（六大策略子包固定）
- 不绕过 contracts（必须通过子包 Do/New API）
- 不动态扩展目录（timeout/retry/circuit/bulkhead/ratelimit/fallback 固定）
- 不直接依赖 observex（BR：通过 Metrics interface 解耦）
- 不自带配置解析（BR-002：由消费者 configx 注入）
- 不引入第三方包（BR-007）

## 28. Forbidden Patterns
- 策略参数硬编码（违反 BR-002，无法统一调优）
- 策略组合非函数嵌套（违反 BR-003，执行顺序不可控）
- circuit breaker 无 sync.Mutex 保护（违反 BR-004，并发竞争状态不一致）
- rate limiter 无 sync.Mutex 保护（违反 BR-005，令牌计数错误）
- 引入第三方框架依赖（违反 BR-007）
- 策略依赖外部服务才能测试（违反 BR-008）
- 提供统一执行链 ResilienceExecutor / PolicyChain（v1.2+ 演进目标，v1.0 禁止）

## 29. Production Ready Checklist
- [x] observability ready（Metrics interface + EventSink + InstrumentStrategy，注入式观测）
- [x] resilience ready（六大策略全实现，-race 零 data race）
- [x] replay ready（SliceSink 捕获事件可回放，integration test 可重复）
- [x] audit ready（Event/Sink 上报、IdempotencyGuard、recovered-panic 审计）
- [x] rollback ready（v1.0.2 已发布，runtime tag 三轴对齐）
- [x] release-check + release-final-check score=10.00、GitHub Release Check passed
- [ ] factory-grade（BLK-007 关闭前机器事实层保持 factory=false，非 v1.0.2 阻塞项）

## 30. Roadmap
- v1.2+ 统一执行链：ResilienceExecutor / PolicyChain / Policies 聚合 struct（goal.md §7）
- v1.2+ 统一 metric 命名：`resiliencx.calls.total` / `resiliencx.duration.ms`（goal.md §9.2）
- 自适应 retry（根据历史成功率动态调整策略）
- 分布式 circuit breaker（多实例共享熔断状态）
- 多维度限流（per-endpoint, per-user）
- 策略配置运行时动态更新
- circuit breaker 失败率维度（当前仅连续失败次数）
- 补充 example_test.go 固化 README 快速开始
- P2 代码补强：MaxAttempts:0 返回错误、bulkhead.New(0) 返回配置错误
