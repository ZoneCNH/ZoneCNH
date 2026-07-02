# kernel 发布版本 1.0 Goal 定位与实现标准

| 字段         | 内容                                           |
| ------------ | ---------------------------------------------- |
| 模块名       | `kernel`                                       |
| 发布版本     | 2.1.0                                          |
| 所属层级     | L0 原语层 / 最小稳定核心                       |
| 稳定级别     | Public API Stable；SPI Stable；Internal 可演进 |
| 文档状态     | 1.0 发布基线文档                               |
| 发布日期基准 | 2026-06-09                                     |
| 对齐 SPEC    | [SPEC.md](./SPEC.md) v2.0.0                    |

## 术语约定

本文档中的 **MUST / 必须** 表示 1.0 发布阻断项；**SHOULD / 应该** 表示 1.0 推荐项，允许带明确理由延期；**MAY / 可以** 表示可选能力，不影响 1.0 发布。

## 当前统一验收口径（2026-06-18）

`kernel` 已发布 v1.1.0（PR #24，tag v1.1.0）；代码侧发布门禁全绿。模块验收 / Factory 不以本地测试通过单独判定，必须同时满足：`.config/goal/evidence` 证据包登记并把 Goal Matrix kernel 边从 Dropped 改为 Verified、四源 98+ arbiter 归档通过、核心库包覆盖率按 `make coverage-threshold` 归档通过。**Factory 证据链已闭合（2026-06-18）：Goal Matrix 23 边全部 Verified（evidence_id=kernel-acceptance-20260618）、四源 arbiter 6 阶段 verdict gate=pass（claude=100/rules=100；codex/copilot forced_missing_source，与 configx 同构）、`make coverage-threshold` 通过（14 核心库包 100.0%）、BLK-011 已 resolved、evidence 包 kernel-acceptance-20260618 已归档，kernel 已移出 factory_blocking_modules（剩 bootstrap/ossx）。**

## 1.0 发布判定原则

1. **稳定优先**：公开 API、类型签名、错误码一旦进入 1.0，默认需要向后兼容。
2. **边界清晰**：kernel 只提供 stdlib-only 的 Go 基础原语，不能向上侵入业务，也不能横向替代 L1 模块。
3. **证据完整**：每个 MUST 能力都必须有单元测试、example_test.go 示例和 godoc 注释。
4. **子包独立**：12 个子包各自独立可用，互不强制绑定，消费者按需 import。
5. **可演进**：1.0 允许保留扩展点，但不得把未稳定能力包装成稳定承诺。

## 1. Goal 定位

`kernel` 是 Foundation L0 原语层，提供 12 个独立子包的轻量 Go 工具集：`lifecycx`（组件生命周期）、`errx`（结构化错误）、`healthx`（健康检查）、`obsx`（可观测抽象接口）、`retryx`（重试策略原语）、`shutdownx`（优雅停机）、`syncx`（并发控制）、`timex`（时钟抽象）、`validx`（前置条件校验）、`versionx`（版本信息）、`contextx`（类型安全上下文）、`contracttest`（契约测试辅助）。各子包独立按需引用，stdlib-only，零外部依赖。

### 1.1 为什么需要这个模块

- 不同模块若各自定义错误模型、健康检查、时钟抽象，会导致接口无法组合。
- L1 横切能力（configx / observex / resiliencx / schedulex）和存储扩展都需要一组稳定的 L0 原语作为公共语言。
- 底层原语必须小而稳定，否则一处变更会影响所有模块。
- 通过 obsx 接口定义实现供应商解耦：L1 模块提供具体实现，kernel 只定义契约。
- 业务语义进入 kernel 会破坏基座独立性，必须从 1.0 就建立边界。

### 1.2 1.0 要解决的问题

- 通过 `lifecycx` 统一组件有序启动/逆序停止，失败自动回滚。
- 通过 `errx` 统一结构化错误模型（ErrorKind/NewError/WrapError/IsKind/AsError）。
- 通过 `healthx` 统一健康检查与聚合（HealthStatus/HealthChecker/Aggregate）。
- 通过 `obsx` 提供无供应商绑定的 Logger/Metrics/Tracer/Span 接口 + Noop 实现 + SecretString 脱敏。
- 通过 `retryx` 提供重试策略配置原语（RetryPolicy/Delay/DelayWithJitter/ShouldRetry），运行时弹性执行属于 `resiliencx`。
- 通过 `timex` 提供可测试的 Clock 抽象（RealClock/FixedClock/FakeClock）。
- 通过 `validx` 统一前置条件/不变式校验（Precondition/Invariant/RequireNonEmpty）。
- 通过 `contextx` 提供类型安全的 context 工具（Key[T]/WithValue/Value/DeadlineRemaining）。
- 通过 `shutdownx` 管理优雅停机 Hook（LIFO 顺序）和 OS signal 处理（NotifyContext）。
- 通过 `syncx` 提供轻量并发控制原语（SemaphoreLimiter/WorkerGroup）。
- 通过 `versionx` 和 `contracttest` 支持版本信息/兼容性判断和契约测试辅助。
- 约束依赖方向：stdlib-only，零外部依赖。`obsx` 定义的可观测接口由 L1 模块实现。

### 1.3 目标用户

- 业务服务开发者（使用 errx / validx / contextx / syncx）
- 平台基础设施开发者（使用 lifecycx / shutdownx / healthx / obsx / retryx）
- SRE / 运维人员（通过 healthx.HealthChecker 查询健康状态）
- 测试工程师（使用 timex.FakeClock / contracttest / internal/testutil）

## 2. 1.0 发布目标

- MUST 提供 12 个独立子包，每个子包公开 API 稳定。
- MUST 提供 `errx.Error` 结构化错误模型（ErrorKind/NewError/WrapError/IsKind/AsError），支持 errors.Join 多错误链。
- MUST 提供 `obsx` 无供应商绑定的 Logger/Metrics/Tracer/Span 接口 + Noop 零值实现 + SecretString 脱敏。
- MUST 提供 `timex.Clock` 可注入时钟抽象（RealClock/FixedClock/FakeClock）。
- MUST 提供 `contextx.Key[T]` 类型安全 context 工具。
- MUST 保持 stdlib-only，零外部依赖。
- MUST 对 Public API 做兼容性承诺，1.x 内不得破坏签名和语义。

### 量化目标

| 指标                      | 基线   | 目标值                   | 验证方式                |
| ------------------------- | ------ | ------------------------ | ----------------------- |
| 核心库包单元测试覆盖率    | 0%     | ≥ 100%（分母排除 examples/scripts） | `make coverage-threshold` |
| errx.NewError 构造        | —      | < 100ns                  | Benchmark               |
| errx.IsKind 5 层链遍历    | —      | < 1μs                    | Benchmark               |
| healthx.Aggregate 10 元素 | —      | < 10μs                   | Benchmark               |
| retryx.Delay 计算         | —      | < 100ns                  | Benchmark               |
| 常驻内存（全子包导入）    | —      | < 5MB                    | Profiling               |
| stdlib-only               | —      | 0 外部依赖               | `go list -deps` CI gate |
| Public API 兼容性         | —      | 1.x 内零 breaking change | API snapshot CI gate    |

## 3. 核心场景

| 场景               | 说明                                             | 1.0 期望结果                                           |
| ------------------ | ------------------------------------------------ | ------------------------------------------------------ |
| 模块统一错误处理   | configx、redisx、kafkax 使用一致的 errx 错误模型 | 调用方可统一用 IsKind/AsError 分类处理错误             |
| 测试可控时间       | testkitx 或业务测试需要固定时间                  | 通过 timex.Clock 注入 FakeClock 得到可重复测试         |
| 类型安全上下文传递 | 调用链需要传递 typed key/value                   | 通过 contextx.Key[T] 零分配、类型安全存取              |
| 健康检查聚合       | x.go 需要聚合多个子模块健康状态                  | 通过 healthx.Aggregate 得到 healthy/degraded/unhealthy |
| 优雅停机           | x.go 需要管理多层资源的 LIFO 释放                | 通过 shutdownx.Manager 管理 Hook 注册和逆序执行        |
| 并发控制           | 业务模块需要限制外部 API 并发调用                | 通过 syncx.SemaphoreLimiter 上下文感知限流             |

## 4. 能力范围

| 能力域         | 子包         | 1.0 必须具备的能力                                                            | 验收方式                 |
| -------------- | ------------ | ----------------------------------------------------------------------------- | ------------------------ |
| 组件生命周期   | lifecycx     | Component 接口、Manager 有序启动/逆序停止、失败回滚、幂等 Stop                | 单元测试覆盖所有状态转换 |
| 结构化错误     | errx         | ErrorKind 12 分类、NewError/WrapError、IsKind 链遍历、AsError、With* 链式调用 | 错误链遍历测试通过       |
| 健康检查       | healthx      | HealthStatus 构造、IsHealthy 判断、Aggregate 聚合、Metadata 不可变            | 聚合逻辑测试通过         |
| 可观测抽象     | obsx         | Logger/Metrics/Tracer/Span 接口、Noop 实现、SecretString 脱敏、Sanitizer 接口 | Noop 无副作用测试通过    |
| 重试策略原语   | retryx       | RetryPolicy 校验、指数退避 Delay、Jitter、ShouldRetry 判断                    | 退避计算测试通过         |
| 优雅停机       | shutdownx    | Hook 接口、Manager LIFO 顺序、HookFunc 适配器、NotifyContext                  | LIFO 顺序测试通过        |
| 时钟抽象       | timex        | Clock 接口、RealClock/FixedClock/FakeClock、FakeClock.Advance                 | 确定性测试通过           |
| 前置条件校验   | validx       | Precondition/Invariant/RequireNonEmpty                                        | 返回值分类测试通过       |
| 版本信息       | versionx     | BuildInfo 构造、Compatibility 匹配逻辑                                        | 兼容性判断测试通过       |
| 类型安全上下文 | contextx     | Key[T] 唯一性、WithValue/Value 类型安全存取、DeadlineRemaining                | Key 唯一性测试通过       |
| 并发控制       | syncx        | SemaphoreLimiter Acquire/Release、WorkerGroup 错误收集                        | 并发安全测试通过         |
| 契约测试辅助   | contracttest | AssertJSONFields、AssertErrorKind、AssertHealthStatus                         | 断言行为测试通过         |

## 5. 职责边界

### 5.1 模块内职责

- 定义 Foundation 全体系可共享的 L0 基础原语。
- 提供轻量、稳定、无外部环境依赖的工具包子集。
- 提供面向测试的基础抽象（timex.Clock、contracttest）。
- 定义错误、健康检查、可观测接口的最小公共语义。

### 5.2 明确非目标

- 不做集中式应用框架（无 App/Module/Deps 抽象）。
- 不做 DI 容器。
- 不做配置解析（→ `configx`）。
- 不做日志/指标/追踪的具体实现（→ `observex`，kernel 只定义 `obsx` 接口）。
- 不做依赖图 / 拓扑排序 / 环检测。
- 不做模块间依赖注入。
- 不做存储、网络、业务 DTO。
- 不做服务发现或远程调用。
- `retryx` 提供重试策略配置原语（参数校验、延迟计算），不提供重试执行引擎、熔断、限流等运行时弹性机制，这些属于 `resiliencx`。

## 6. 依赖关系与分层约束

| 依赖类型     | 约束                                                                                                                                          |
| ------------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| 上游依赖     | 只允许依赖 Go 标准库（stdlib-only）。                                                                                                         |
| 下游依赖     | configx、observex、resiliencx、schedulex、testkitx、各类存储扩展、业务模块均可按需 import kernel 单个子包。                                   |
| 分层约束     | kernel 不得依赖任何 L1 模块或存储/消息扩展模块。                                                                                              |
| 内部交叉引用 | 允许 kernel 内部子包间引用（如 healthx→timex、retryx→errx、validx→errx、contextx→timex、contracttest→errx+healthx），仅限于 kernel 仓库内部。 |
| 契约依赖     | kernel 作为最底层原语层，豁免 contracts 登记要求；其公开 API 由 contracts 模块主动引用。                                                      |

## 7. 对外契约

### 7.1 公开能力面

| 契约                                  | 定位                 | 1.0 稳定承诺                                            |
| ------------------------------------- | -------------------- | ------------------------------------------------------- |
| errx.Error / ErrorKind                | 统一错误模型         | 错误分类字段稳定，可追加 ErrorKind 值但不得改变既有含义 |
| healthx.HealthStatus                  | 健康检查状态         | 字段语义稳定，可追加 Metadata key                       |
| obsx.Logger / Metrics / Tracer / Span | 可观测接口           | 接口方法签名稳定                                        |
| obsx.SecretString                     | 敏感数据脱敏         | String()/JSON() 始终返回 "***"                          |
| timex.Clock                           | 可替换时钟抽象       | 接口稳定，默认实现可优化                                |
| retryx.RetryPolicy                    | 重试策略配置         | 字段语义稳定                                            |
| contextx.Key[T]                       | 类型安全 context key | 接口稳定                                                |
| lifecycx.Component / Manager          | 组件生命周期         | 接口稳定                                                |
| shutdownx.Hook / Manager              | 优雅停机             | 接口稳定                                                |
| syncx.Limiter / WorkerGroup           | 并发控制             | 接口稳定                                                |
| versionx.BuildInfo / Compatibility    | 版本信息             | 字段语义稳定                                            |

### 7.2 1.0 核心接口基线

```text
errx.Error
  Kind: ErrorKind (config|validation|connection|unavailable|timeout|auth|
       conflict|rate_limit|canceled|not_found|already_exists|internal)
  Code: string
  Severity: Severity (info|warning|error|critical)
  Op: string
  Message: string
  Cause: error (Unwrap)
  Retryable: boolean
  Error() string
  WithRetryable(bool) / WithCode(string) / WithSeverity(Severity)

healthx.HealthStatus
  Name: string
  Status: HealthStatusValue (healthy|degraded|unhealthy)
  Message: string
  CheckedAt: time.Time
  LatencyMs: int64
  Metadata: map[string]string
  IsHealthy() bool
  WithMetadata(key, value) HealthStatus

obsx.Logger
  Debug/Info/Warn/Error(ctx, msg, ...Field)

obsx.Metrics
  Count(ctx, name, delta, ...Field)
  Observe(ctx, name, value, ...Field)

timex.Clock
  Now() time.Time

retryx.RetryPolicy
  MaxAttempts: int
  BaseDelay: time.Duration
  MaxDelay: time.Duration
  Validate() error
  Delay(attempt int) time.Duration
  DelayWithJitter(attempt int, ratio, fraction float64) time.Duration

contextx.Key[T]
  (sentinel-based, unique per NewKey call)

lifecycx.Component
  Name() string
  Start(ctx context.Context) error
  Stop(ctx context.Context) error

shutdownx.Hook
  Name() string
  Shutdown(ctx context.Context) error
```

## 8. 配置契约

kernel 本身不需要配置。各子包通过构造函数参数或结构体字段接收配置：

| 子包      | 配置方式                                                   |
| --------- | ---------------------------------------------------------- |
| lifecycx  | `NewManager(components...)` 构造函数参数                   |
| retryx    | `RetryPolicy{MaxAttempts, BaseDelay, MaxDelay}` 结构体字段 |
| shutdownx | `NewManager(hooks...)` 构造函数参数                        |
| syncx     | `NewSemaphoreLimiter(n)` 构造函数参数                      |
| versionx  | `NewBuildInfo(...)` 构造函数参数                           |

## 9. 可观测契约

### 9.1 日志

- kernel 子包不直接输出业务运行日志，避免污染调用方日志策略。
- kernel 通过 `obsx.Logger` 接口定义日志契约，具体实现由 L1 `observex` 或调用方提供。

### 9.2 指标

- kernel 子包不输出自身运行时指标。
- kernel 通过 `obsx.Metrics` 接口定义指标契约（Count/Observe），具体实现由 L1 提供。

### 9.3 Trace / 诊断事件

- kernel 子包不创建 span。
- kernel 通过 `obsx.Tracer` / `obsx.Span` 接口定义追踪契约。

## 10. 错误模型与失败策略

| 错误分类   | ErrorKind      | 典型原因                     | 1.0 处理策略                                      |
| ---------- | -------------- | ---------------------------- | ------------------------------------------------- |
| 参数非法   | validation     | 参数为空、格式错误、范围非法 | 返回 `*Error{Kind: validation}`                   |
| 配置错误   | config         | 配置缺失或非法               | 返回 `*Error{Kind: config}`                       |
| 连接失败   | connection     | 网络不可达                   | 返回 `*Error{Kind: connection, Retryable: true}`  |
| 服务不可用 | unavailable    | 上游服务不可用               | 返回 `*Error{Kind: unavailable, Retryable: true}` |
| 超时       | timeout        | 操作超时                     | 返回 `*Error{Kind: timeout}`                      |
| 认证失败   | auth           | 凭证无效                     | 返回 `*Error{Kind: auth}`                         |
| 并发冲突   | conflict       | 乐观锁冲突                   | 返回 `*Error{Kind: conflict, Retryable: true}`    |
| 限流       | rate_limit     | 请求频率超限                 | 返回 `*Error{Kind: rate_limit, Retryable: true}`  |
| 已取消     | canceled       | context 取消                 | 返回 `*Error{Kind: canceled}`                     |
| 未找到     | not_found      | 资源不存在                   | 返回 `*Error{Kind: not_found}`                    |
| 已存在     | already_exists | 资源重复创建                 | 返回 `*Error{Kind: already_exists}`               |
| 内部错误   | internal       | 不变量违反                   | 返回 `*Error{Kind: internal, Severity: error}`    |

## 11. 安全、稳定性与兼容性要求

- MUST 不在 errx.Error.Message 中强制包含敏感诊断；敏感数据通过 `obsx.SecretString` 自动脱敏。
- MUST 避免在基础模型中固化业务身份字段。
- SHOULD obsx.Sanitizer 实现者保证 Sanitize() 不泄露原始值。

## 12. 测试证据要求

| 测试类型     | 必须覆盖内容                                       | 发布门禁                  |
| ------------ | -------------------------------------------------- | ------------------------- |
| 单元测试     | 每个子包的核心逻辑（构造、状态转换、边界场景）     | MUST 通过，核心库包覆盖率 ≥ 100% |
| Example 测试 | 每个子包有 example_test.go                         | MUST 通过，输出稳定       |
| 并发测试     | syncx.SemaphoreLimiter、syncx.WorkerGroup 并发安全 | MUST 通过 `-race`         |
| 依赖检查     | stdlib-only gate                                   | MUST 通过 `go list -deps` |
| API 快照     | contracts/public_api/ 对比                         | MUST 通过                 |
| Golden 行为  | contracts/golden_behavior_test.go                  | MUST 通过                 |

## 13. 1.0 发布验收清单

- 12 子包 Public API 完成冻结并生成 godoc 注释。
- kernel 不依赖 configx、observex、resiliencx 等上层模块。
- 每个子包可被其他模块独立按需 import。
- 错误模型通过至少 3 个上层模块集成验证。
- 所有子包有 example_test.go 示例。

## 14. Definition of Done

- 公开 API、错误码完成冻结并记录兼容性说明。
- README、CHANGELOG、godoc 完成。
- MUST 能力均有自动化测试，CI 可重复执行。
- 所有子包 example_test.go 通过。
- 发布包不包含测试密钥、临时文件、个人环境路径。
- stdlib-only gate 通过。
- 公共 API 快照对比通过。
- Golden 行为测试通过。

## 15. 1.0 后演进方向

- 根据上层模块使用反馈微调接口（通过 minor version）。
- 根据 contracts 模块补充跨语言 schema 表达。
- 对核心路径（errx.IsKind、retryx.Delay）建立性能回归门禁。
- 基于实际使用模式评估是否需要新增子包。
