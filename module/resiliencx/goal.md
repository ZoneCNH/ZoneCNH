# resiliencx 发布版本 1.0.2 Goal 定位与实现标准

| 字段         | 内容                                           |
| ------------ | ---------------------------------------------- |
| 模块名       | `resiliencx`                                   |
| 发布版本     | 1.0.2                                          |
| 所属层级     | L1 基础能力（弹性治理；与 SPEC §3 / FOUNDATION-DEPS.yaml 一致） |
| 稳定级别     | Public API Stable；SPI Stable；Internal 可演进 |
| 文档状态     | 已发布，与 SPEC.md v1.0.2 / runtime tag v1.0.2 对齐 |
| 运行时基线   | v1.0.2（`/home/resiliencx`，tag `v1.0.2`；release-check / release-final-check 通过） |
| 发布日期基准 | 2026-06-18                                     |

> **v1.0.2 发布同步**：本 goal 的能力范围与 v1.2+ 演进方向（§7、§15）保持不变；运行时对外 API 以子包形式提供（`timeout.Do`、`retry.Do`、`circuit.New`、`bulkhead.New`、`ratelimit.New`、`fallback.Do` 与根包 `Compose` / `InstrumentStrategy`）。运行时代码已发布 tag `v1.0.2` -> `1aaa0dc`，GitHub Release Check `27777166525` passed；本地 `release-check` 与 `release-final-check` 均通过。SPEC v1.0.2 已据此纠正 §8/§9 契约。

## 术语约定

本文档中的 **MUST / 必须** 表示 1.0 发布阻断项；**SHOULD / 应该** 表示 1.0 推荐项，允许带明确理由延期；**MAY / 可以** 表示可选能力，不影响 1.0 发布。

## 1.0 发布判定原则

1. **稳定优先**：公开 API、配置项、错误码、指标名一旦进入 1.0，默认需要向后兼容。
2. **边界清晰**：模块只能解决自身层级的问题，不能向上侵入业务，也不能横向替代其他模块。
3. **证据完整**：每个 MUST 能力都必须有单元测试、关键路径集成测试或契约测试证明。
4. **可观测**：所有运行时模块必须输出最小可诊断信息，包括错误、耗时、调用量和关键状态。
5. **可演进**：1.0 允许保留扩展点，但不得把未稳定能力包装成稳定承诺。

## 1. Goal 定位

`resiliencx` 的 Goal 是提供统一弹性治理能力，使服务在依赖异常、慢响应、流量突增、网络抖动和局部故障下保持可控、可降级、可恢复。它将超时、重试、熔断、限流、隔离、降级和失败分类抽象为可组合策略，并通过配置和观测统一治理。

### 1.1 为什么需要这个模块

- 外部依赖故障如果没有统一超时和隔离，会迅速放大为线程耗尽和级联失败。
- 重试、熔断、限流如果由各模块自行实现，会出现策略冲突和不可观测。
- 非幂等操作误重试会造成重复写入，必须有统一的安全约束。
- 弹性策略必须可配置、可观测、可测试，不能隐藏失败。

### 1.2 1.0 要解决的问题

- 统一 timeout、retry、circuit breaker、rate limiter、bulkhead、fallback。
- 统一错误分类和是否可重试判断。
- 统一策略组合顺序和策略命中观测。
- 为 Redis、Kafka、PostgreSQL、OSS 等模块提供一致治理能力。
- 支持按依赖、操作、租户、业务 key 配置策略。

### 1.3 目标用户

- 业务服务开发者
- 平台基础设施开发者
- SRE / 运维人员
- 测试工程师

## 2. 1.0 发布目标

- MUST 提供 TimeoutPolicy、RetryPolicy、CircuitBreakerPolicy、RateLimitPolicy、BulkheadPolicy、FallbackPolicy。
- MUST 提供策略注册表和按 operation 选择策略的能力。
- MUST 对非幂等操作默认禁止自动重试，除非调用方显式声明安全。
- MUST 输出策略命中、拒绝、熔断打开、降级等观测数据。
- MUST 支持配置驱动和编程式策略两种方式。

## 3. 核心场景

| 场景         | 说明                         | 1.0 期望结果                           |
| ------------ | ---------------------------- | -------------------------------------- |
| 数据库慢查询 | PostgreSQL 查询超过阈值      | 超时中断，记录错误和指标，避免线程堆积 |
| 缓存抖动     | Redis 短暂不可用             | 可重试读操作；写操作按幂等规则处理     |
| 下游故障     | 依赖连续失败                 | 熔断打开并走 fallback，定期半开探测    |
| 流量突增     | 某接口请求暴增               | 按 key 限流或舱壁隔离，保护核心资源    |
| 重试风暴     | 下游持续不可用但上层持续重试 | 超过总耗时上限后快速失败，熔断器打开   |

## 4. 能力范围

| 能力域   | 1.0 必须具备的能力                                             | 验收方式         |
| -------- | -------------------------------------------------------------- | ---------------- |
| 超时     | 同步/异步调用超时、deadline 继承、取消传播                     | 超时测试通过     |
| 重试     | 固定间隔、指数退避、jitter、最大次数、错误分类                 | 重试安全测试通过 |
| 熔断     | 关闭/打开/半开状态、滑动窗口、失败率阈值                       | 状态转换测试通过 |
| 限流     | 令牌桶、漏桶或固定窗口抽象、按 key 限流                        | 高并发测试通过   |
| 隔离     | 并发舱壁、队列长度、拒绝策略                                   | 资源隔离测试通过 |
| 降级     | fallback、默认值、缓存兜底、快速失败                           | 降级路径测试通过 |
| 策略编排 | 函数嵌套组合（装饰器模式）；v1.2+ 目标：PolicyChain 统一执行链 | 组合策略测试通过 |

## 5. 职责边界

### 5.1 模块内职责

- 提供弹性治理策略抽象和默认实现。
- 提供策略配置、选择、组合和执行。
- 提供错误分类和幂等性声明机制。
- 接入 observex 输出弹性治理观测。

### 5.2 明确非目标

- 不替代服务网格或 API 网关。
- 不掩盖业务错误，不把失败伪装成成功。
- 不默认对所有操作进行重试。
- 不负责业务 fallback 内容，只提供执行框架。

## 6. 依赖关系与分层约束

| 依赖类型 | 约束                                                                                       |
| -------- | ------------------------------------------------------------------------------------------ |
| 上游依赖 | 依赖 kernel（生命周期）；依赖 configx 获取策略配置。不依赖 observex、schedulex、testkitx。 |
| 下游依赖 | schedulex、redisx、kafkax、natsx、postgresx、taosx、ossx、clickhousex 可复用策略。         |
| 分层约束 | resiliencx 不依赖具体中间件客户端；通过通用执行器包装外部调用。                            |
| 契约依赖 | MUST 向 contracts 登记 Public API 契约和错误码契约。                                       |

## 7. 对外契约

> **版本分层说明**：以下 ResilienceExecutor、PolicyRegistry、OperationAttributes、PolicyChain、RejectPolicy、FallbackHandler、Permit 为 **v1.2+ 演进方向**。v1.0 对外契约以 SPEC.md §9 Interface Contract 为准。

### 7.1 公开能力面

| 契约               | 定位             | 1.0 现状（实际符号）                                        |
| ------------------ | ---------------- | ----------------------------------------------------------- |
| ResilienceExecutor | 统一策略执行入口 | v1.2+（v1.0: 各策略函数独立调用，通过函数嵌套组合）         |
| PolicyRegistry     | 策略注册和选择   | v1.2+（v1.0: 直接实例化策略对象）                           |
| RetryPolicy        | 重试策略         | v1.0 已实现（`retry.Policy` struct + `retry.Do` 函数）      |
| CircuitBreaker     | 熔断器状态机     | v1.0 已实现（`circuit.Breaker` struct，`circuit.New` 构造） |
| RateLimiter        | 限流抽象         | v1.0 已实现（`ratelimit.Limiter` struct，`ratelimit.New`）  |
| Bulkhead           | 并发舱壁         | v1.0 已实现（`bulkhead.Bulkhead` struct，`bulkhead.New`）   |
| FallbackHandler    | 降级处理器       | v1.2+（v1.0: `fallback.Do` 函数，primary + fallbacks 链）   |

### 7.2 1.2+ 逻辑接口基线（演进目标）

> 以下为 v1.2+ 统一执行链目标架构。v1.0 采用独立策略函数，通过函数嵌套（装饰器模式）实现组合。

```text
ResilienceExecutor
  execute(operationName, attributes, callable): Result<T>

OperationAttributes
  idempotent: boolean
  timeout: Duration
  resourceKey: string
  tenantId?: string

PolicyChain
  rateLimit -> bulkhead -> circuitBreaker -> timeout -> retry -> fallback

RetryPolicy
  maxAttempts
  backoff
  retryOn(error): boolean

CircuitBreaker
  state(): CLOSED | OPEN | HALF_OPEN
  onSuccess()
  onFailure(error)

RateLimiter
  acquire(): void
  tryAcquire(timeout): boolean

Bulkhead
  acquire(): Permit
  tryAcquire(timeout): boolean
  availablePermits(): int

Permit
  release(): void

FallbackHandler
  handle(error, attributes): Result<T>

RejectPolicy
  BLOCK | DROP | CALLER_RUNS
```

## 8. 配置契约

| 配置项                                       | 含义             | 默认值 / 要求 | 稳定性 |
| -------------------------------------------- | ---------------- | ------------- | ------ |
| resiliencx.enabled                           | 是否启用弹性治理 | true          | Stable |
| resiliencx.default_timeout                   | 默认超时         | 5s            | Stable |
| resiliencx.default_retry.max_retries         | 默认重试次数     | 0，默认不重试 | Stable |
| resiliencx.default_retry.initial_wait        | 默认退避         | 100ms         | Stable |
| resiliencx.circuit_breaker.failure_threshold | 熔断失败率阈值   | 5             | Stable |
| resiliencx.circuit_breaker.recovery_timeout  | 熔断恢复超时     | 30s           | Stable |
| resiliencx.bulkhead.max_concurrent           | 默认并发隔离数   | 10            | Stable |
| resiliencx.rate_limiter.rate                 | 每秒请求数限额   | disabled      | Stable |

## 9. 可观测契约

### 9.1 日志

- MUST 在超时、最终失败、熔断打开、限流拒绝、降级执行时输出结构化日志。
- MUST 记录 operation、policy、resourceKey、attempt、durationMs、errorCode、traceId。
- SHOULD 对每次重试输出 debug，最终失败输出 warn/error。

### 9.2 指标

| 指标名                    | 类型    | 标签                    | 说明              |
| ------------------------- | ------- | ----------------------- | ----------------- |
| resiliencx.calls.total    | Counter | operation,status,policy | 受治理调用总数    |
| resiliencx.duration.ms    | Timer   | operation,status        | 治理调用耗时      |
| resiliencx.retry.total    | Counter | operation,result        | 重试次数          |
| resiliencx.circuit.state  | Gauge   | operation,state         | 熔断状态          |
| resiliencx.rejected.total | Counter | operation,reason        | 限流/舱壁拒绝次数 |
| resiliencx.fallback.total | Counter | operation,status        | 降级执行次数      |

### 9.3 Trace / 诊断事件

- MUST 为受治理调用添加 resilience.policy、attempt、circuit.state 等 span 属性。
- MUST 在 retry 中保留同一父 span，并为每次 attempt 标注子事件。
- SHOULD 输出 CIRCUIT_OPENED、CIRCUIT_HALF_OPEN、RATE_LIMIT_REJECTED 诊断事件。

## 10. 错误模型与失败策略

> **版本分层**：v1.0 使用 SPEC.md §10 定义的 sentinel error 变量。以下统一错误分类体系为 v1.2+ 演进方向。

| 错误类别                   | 典型原因                     | 目标处理策略                   |
| -------------------------- | ---------------------------- | ------------------------------ |
| RESILIENCE_TIMEOUT         | 调用超过 timeout 或 deadline | 取消调用并返回可识别超时错误   |
| RESILIENCE_REJECTED        | 限流或舱壁拒绝               | 快速失败，不进入下游调用       |
| RESILIENCE_CIRCUIT_OPEN    | 熔断器打开                   | 执行 fallback 或快速失败       |
| RESILIENCE_RETRY_EXHAUSTED | 重试次数耗尽                 | 返回最后一次错误并记录尝试次数 |
| RESILIENCE_FALLBACK_FAILED | 降级逻辑自身失败             | 返回降级失败并保留原始错误     |

## 11. 安全、稳定性与兼容性要求

- MUST 对密码、token、accessKey、secretKey、连接串中的敏感片段做脱敏。
- MUST 保证公开 API 的异常不会泄漏内部凭据、主机隐私或完整连接串。
- MUST 为所有网络和外部依赖调用设置超时边界。
- SHOULD 支持最小权限原则，不要求业务使用高权限账号。
- MUST 避免策略 key 使用原始用户敏感输入；需要哈希或归一化。
- MUST 限制重试风暴，所有重试必须有最大次数和总耗时上限。

## 12. 测试证据要求

| 测试类型     | 必须覆盖内容                         | 发布门禁  |
| ------------ | ------------------------------------ | --------- |
| 单元测试     | 所有策略状态机、错误分类、幂等判断   | MUST 通过 |
| 组合测试     | 限流+熔断+超时+重试+fallback 的顺序  | MUST 通过 |
| 并发测试     | 舱壁、限流器、熔断状态并发安全       | MUST 通过 |
| 故障注入测试 | 使用 testkitx 注入超时、失败、慢响应 | MUST 通过 |
| 观测测试     | 指标、日志、Trace 属性完整           | MUST 通过 |

## 13. 1.0 发布验收清单

- 所有外部依赖模块可以通过 resiliencx 包装调用。
- 默认策略保守：有超时，无默认重试。
- 非幂等操作误重试有门禁防护。
- 策略命中情况可通过指标和日志定位。

## 14. Definition of Done

- 公开 API、配置项、错误码、指标名完成冻结并记录兼容性说明。
- README、快速开始、配置参考、错误码参考、测试说明完成。
- MUST 能力均有自动化测试，CI 可重复执行。
- 示例工程或最小可运行样例通过。
- 发布包不包含测试密钥、临时文件、个人环境路径。

## 15. 1.0 后演进方向

**v1.1 计划**：
- 自适应 retry：根据历史成功率动态调整退避策略。
- 多维度限流：per-endpoint、per-user 限流 key。
- 运行时配置动态更新。

**v1.2+ 目标架构**：
- ResilienceExecutor 统一执行入口 + PolicyRegistry 策略注册 + PolicyChain 声明式策略链。
- 统一错误分类体系 RESILIENCE_* + RejectPolicy (BLOCK/DROP/CALLER_RUNS)。
- 自适应限流（基于响应时间 P99 和错误率双信号源，与固定限流共存，自适应降级到固定阈值）。
- 支持策略灰度和动态调参。
- 与服务治理平台或网关策略联动。
