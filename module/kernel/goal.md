# kernel 发布版本 1.0 Goal 定位与实现标准

| 字段 | 内容 |
| --- | --- |
| 模块名 | `kernel` |
| 发布版本 | 1.0.0 |
| 所属层级 | L0 原语层 / 最小稳定核心 |
| 稳定级别 | Public API Stable；SPI Stable；Internal 可演进 |
| 文档状态 | 1.0 发布基线文档 |
| 发布日期基准 | 2026-06-09 |

## 术语约定

本文档中的 **MUST / 必须** 表示 1.0 发布阻断项；**SHOULD / 应该** 表示 1.0 推荐项，允许带明确理由延期；**MAY / 可以** 表示可选能力，不影响 1.0 发布。

## 1.0 发布判定原则

1. **稳定优先**：公开 API、配置项、错误码、指标名一旦进入 1.0，默认需要向后兼容。
2. **边界清晰**：模块只能解决自身层级的问题，不能向上侵入业务，也不能横向替代其他模块。
3. **证据完整**：每个 MUST 能力都必须有单元测试、关键路径集成测试或契约测试证明。
4. **可观测**：所有运行时模块必须输出最小可诊断信息，包括错误、耗时、调用量和关键状态。
5. **可演进**：1.0 允许保留扩展点，但不得把未稳定能力包装成稳定承诺。

## 1. Goal 定位

`kernel` 的 Goal 是提供 xlib 所有模块共享的最小稳定原语。它采用轻量工具包子集设计，包含 12 个独立子包：`lifecycx`（组件生命周期管理）、`errx`（结构化错误模型）、`healthx`（健康检查）、`obsx`（可观测抽象——Logger/Metrics/Tracer 接口）、`retryx`（重试策略配置原语）、`shutdownx`（优雅停机 Hook 管理）、`syncx`（并发控制——SemaphoreLimiter/WorkerGroup）、`timex`（Clock 抽象——RealClock/FixedClock/FakeClock）、`validx`（前置条件校验）、`versionx`（版本信息）、`contextx`（类型安全上下文——Key[T]/DeadlineRemaining）、`contracttest`（契约测试辅助）。各子包独立按需引用，stdlib-only，零外部依赖。它是其他模块共同依赖的核心，但不能演变成”大工具箱”。

### 1.1 为什么需要这个模块

- 不同模块若各自定义 Result、Error、Context、ID、Page，会导致接口无法组合。
- L1 横切能力和存储扩展都需要一组稳定底层类型作为公共语言。
- 底层原语必须小而稳定，否则一处变更会影响所有模块。
- 业务语义进入 kernel 会破坏基座独立性，必须从 1.0 就建立边界。

### 1.2 1.0 要解决的问题

- 通过 `lifecycx` 统一组件有序启动/逆序停止，失败自动回滚。
- 通过 `errx` 统一结构化错误模型（ErrorKind/NewError/WrapError/IsKind）。
- 通过 `healthx` 统一健康检查与聚合（HealthStatus/Probe/Aggregate）。
- 通过 `obsx` 提供无供应商绑定的 Logger/Metrics/Tracer/Span 接口 + Noop 实现。
- 通过 `retryx` 提供重试策略配置原语（RetryPolicy/Delay/DelayWithJitter），运行时弹性执行属于 `resiliencx`。
- 通过 `timex` 提供可测试的 Clock 抽象（RealClock/FixedClock/FakeClock）。
- 通过 `validx` 统一前置条件/不变式校验（Precondition/Invariant/RequireNonEmpty）。
- 通过 `contextx` 提供类型安全的 context 工具（Key[T]/WithValue/Value/DeadlineRemaining）。
- 通过 `shutdownx` 管理优雅停机 Hook 和 OS signal 处理。
- 通过 `syncx` 提供轻量并发控制原语（SemaphoreLimiter/WorkerGroup）。
- 通过 `versionx` 和 `contracttest` 支持版本信息与契约测试。
- 约束依赖方向：stdlib-only，零外部依赖。`obsx` 定义的可观测接口由 L1 模块实现。

### 1.3 目标用户

- 业务服务开发者
- 平台基础设施开发者
- SRE / 运维人员
- 测试工程师

## 2. 1.0 发布目标

- MUST 提供稳定的 `Result` / `XError` / `XContext` / `XCode` 基础模型。
- MUST 提供可替换的 `Clock`、`IdGenerator`、`RandomSource`、`TextCodec` 等基础抽象。
- MUST 提供分页、排序、范围、键值标签等通用模型。
- MUST 保持零业务语义和最小第三方依赖。
- MUST 对 Public API 做兼容性承诺，1.x 内不得破坏签名和语义。

### 量化目标

| 指标 | 基线 | 目标值 | 验证方式 |
|------|------|--------|----------|
| 单元测试覆盖率 | 0% | ≥ 90% | `go tool cover` |
| 50 模块注册 + 依赖图校验 | — | < 10ms | Benchmark |
| 冷启动（50 模块拓扑序启动） | — | < 100ms | Benchmark |
| 100 节点拓扑排序 | — | < 1ms | Benchmark |
| graceful shutdown | — | < 5s | Benchmark |
| stdlib-only | — | 0 外部依赖 | `go list -deps` CI gate |
| Public API 兼容性 | — | 1.x 内零 breaking change | CI gate |

## 3. 核心场景

| 场景 | 说明 | 1.0 期望结果 |
| --- | --- | --- |
| 模块统一返回 | configx、redisx、kafkax 需要使用一致错误与结果模型 | 调用方可以统一处理成功、失败、可重试、不可重试状态 |
| 测试可控时间 | testkitx 或业务测试需要固定时间 | 通过 Clock 注入得到可重复测试 |
| 上下文传递 | 调用链需要传递 requestId、tenantId、deadline | XContext 作为轻量载体，不绑定 observex 实现 |
| 分页查询 | postgresx、clickhousex 需要统一分页参数 | PageRequest / PageResult 语义一致 |

## 4. 能力范围

| 能力域 | 1.0 必须具备的能力 | 验收方式 |
| --- | --- | --- |
| 结果模型 | Result<T>、OptionalResult、成功/失败/空值语义、错误附着 | 单元测试覆盖所有状态转换 |
| 错误模型 | XError、XCode、错误分类、可重试标记、诊断信息、cause 链 | 错误兼容性测试通过 |
| 上下文模型 | XContext、deadline、cancellation、baggage、requestId、tenantId | 上下文传播测试通过 |
| 时间与 ID | Clock、Ticker、Duration、IdGenerator、Snowflake/UUID 适配抽象 | 确定性测试与并发测试通过 |
| 数据基础模型 | PageRequest、PageResult、Sort、Range、KeyValue、TagSet | 序列化/反序列化测试通过 |
| 校验基础 | ValidationResult、Violation、字段路径、严重级别 | 错误聚合测试通过 |
| 生命周期 | Startable、Stoppable、Closeable、HealthState 基础定义 | 模块初始化和关闭测试通过 |

## 5. 职责边界

### 5.1 模块内职责

- 定义 xlib 全体系可共享的基础类型。
- 提供轻量、稳定、无外部环境依赖的工具。
- 提供面向测试的基础抽象，例如 Clock 和 IdGenerator。
- 定义错误、结果、上下文的最小公共语义。

### 5.2 明确非目标

- 不提供日志、指标、Trace 的具体实现。
- 不实现配置中心、数据库、缓存、消息队列能力。
- 不包含业务身份、订单、设备、用户等领域模型。
- `retryx` 提供重试策略配置原语（参数校验、延迟计算），不提供重试执行引擎、熔断、限流等运行时弹性机制，这些属于 `resiliencx`。

## 6. 依赖关系与分层约束

| 依赖类型 | 约束 |
| --- | --- |
| 上游依赖 | 只允许依赖语言标准库和经过批准的极轻量基础库。 |
| 下游依赖 | configx、observex、resiliencx、schedulex、testkitx、各类扩展模块均可依赖 kernel。 |
| 分层约束 | kernel 不得依赖任何 L1 模块或存储/消息扩展模块。 |
| 契约依赖 | kernel 作为最底层原语层，豁免 contracts 登记要求；其公开 API 由 contracts 模块主动引用。 |

## 7. 对外契约

### 7.1 公开能力面

| 契约 | 定位 | 1.0 稳定承诺 |
| --- | --- | --- |
| Result | 统一返回模型 | 1.x 内状态语义稳定 |
| XError / XCode | 统一错误模型 | 错误分类字段稳定，可追加字段但不得改变既有含义 |
| XContext | 上下文传播模型 | 核心 key 稳定，baggage 允许扩展 |
| Clock / IdGenerator | 可替换基础抽象 | 接口稳定，默认实现可优化 |
| Page / Sort / Range | 数据访问基础模型 | 字段语义稳定 |

### 7.2 1.0 逻辑接口基线

```text
Result<T>
  isSuccess(): boolean
  value(): T
  error(): XError

XError
  code: XCode
  category: ErrorCategory
  retryable: boolean
  message: string
  diagnostic: map<string,string>
  cause?: Throwable

XContext
  requestId: string
  tenantId?: string
  deadline?: Instant
  baggage: map<string,string>
  cancelled(): boolean

Clock.now(): Instant
IdGenerator.nextId(scope): string

PageRequest
  page: int
  size: int
  sort?: Sort

PageResult<T>
  content: list<T>
  totalElements: long
  totalPages: int

Sort
  field: string
  direction: ASC | DESC

Range<T>
  start: T
  end: T
  startInclusive: boolean
  endInclusive: boolean

ValidationResult
  valid: boolean
  violations: list<Violation>

Violation
  field: string
  code: string
  message: string
  rejectedValue?: any
```

## 8. 配置契约

| 配置项 | 含义 | 默认值 / 要求 | 稳定性 |
| --- | --- | --- | --- |
| foundationx.kernel.enabled | kernel 总是启用，不建议暴露关闭开关 | true | Stable |
| foundationx.kernel.id.default-generator | 默认 ID 生成策略 | uuid 或平台默认 | Stable |
| foundationx.kernel.time.default-zone | 默认时区策略 | UTC，展示层自行转换 | Stable |

## 9. 可观测契约

### 9.1 日志

- kernel 默认不直接输出业务运行日志，避免污染调用方日志策略。
- MAY 在严重初始化失败时通过标准错误输出最小诊断，但推荐由上层模块负责观测。

### 9.2 指标

| 指标名 | 类型 | 标签 | 说明 |
| --- | --- | --- | --- |
| foundationx_kernel_operation_duration_ms | Timer | operation,status | 仅当上层启用观测桥接时记录基础工具耗时 |
| foundationx_kernel_error_count_total | Counter | code,category | 仅当上层启用观测桥接时记录错误创建统计 |

### 9.3 Trace / 诊断事件

- kernel 不创建 span。
- MUST 保证 XContext 可承载 traceId、requestId、deadline 等上层上下文信息。

## 10. 错误模型与失败策略

| 错误码 | 错误类别 | 典型原因 | 1.0 处理策略 |
| --- | --- | --- | --- |
| KERNEL_INVALID_ARGUMENT | 参数非法 | 参数为空、格式错误、范围非法 | 返回 ValidationResult 或 XError，不抛裸异常 |
| KERNEL_ILLEGAL_STATE | 状态非法 | 生命周期状态不允许当前操作 | 返回不可重试错误 |
| KERNEL_TIMEOUT | 超时 | 上下文 deadline 已过期 | 返回可识别超时错误，由上层决定是否重试 |
| KERNEL_CANCELLED | 已取消 | 上下文取消 | 快速停止后续操作 |

## 11. 安全、稳定性与兼容性要求

- MUST 不在 XError.message 中强制包含敏感诊断；敏感诊断只能进入受控 diagnostic 并支持脱敏。
- MUST 避免在基础模型中固化业务身份字段。
- SHOULD 对 baggage key 设定长度和字符限制，避免上下文膨胀。

## 12. 测试证据要求

| 测试类型 | 必须覆盖内容 | 发布门禁 |
| --- | --- | --- |
| 单元测试 | Result 状态、XError 分类、Context deadline/cancel、Page/Sort 序列化 | MUST 通过，覆盖率不低于模块标准 |
| 并发测试 | IdGenerator 唯一性、Context 并发读写安全策略 | MUST 通过 |
| 兼容性测试 | Public API 二进制/源码兼容扫描 | MUST 通过 |
| 无依赖测试 | 确认未引入 L1 或扩展模块依赖 | MUST 通过 |

## 13. 1.0 发布验收清单

- Public API 完成冻结并生成 API 文档。
- kernel 不依赖 configx、observex、resiliencx 等上层模块。
- 基础模型可被所有其他模块编译引用。
- 错误和上下文模型通过至少 3 个上层模块集成验证。

## 14. Definition of Done

- 公开 API、配置项、错误码、指标名完成冻结并记录兼容性说明。
- README、快速开始、配置参考、错误码参考、测试说明完成。
- MUST 能力均有自动化测试，CI 可重复执行。
- 示例工程或最小可运行样例通过。
- 发布包不包含测试密钥、临时文件、个人环境路径。

## 15. 1.0 后演进方向

- 增加更多语言绑定时保持同一语义模型。
- 根据 contracts 模块补充跨语言 schema 表达。
- 对基础模型做性能基准测试并建立回归门禁。
