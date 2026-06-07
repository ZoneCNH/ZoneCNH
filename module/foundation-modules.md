# 基础模块定位与边界

最后更新：2026-06-07

本文固化 Foundation 第一阶段 6 个基础模块的定位、边界、交互、故障模式和建设顺序。执行层规格见 `FOUNDATION-SPEC.md`，机器依赖矩阵见 `FOUNDATION-DEPS.yaml`。

## 总体分层

```text
xlib-standard：标准事实源 / 模板 / Gate / Evidence，不进入业务运行时
    ↓
kernel：L0 原语层，stdlib-only
    ↓
configx / observex / resiliencx / schedulex：L1 运行时横切能力
    ↓
testkitx：L1 测试专用能力，只能 test-only 使用
    ↓
x.go：组合根，负责显式装配和生命周期 wiring
```

基础模块只提供工程能力，不承载交易语义。

| 原则 | 说明 |
| --- | --- |
| 单向依赖 | L1 基础模块最多依赖 `kernel`；基础模块不得反向依赖入口层或业务域 |
| 能力与业务分离 | 基础模块提供配置、观测、弹性、调度、测试和原语，不判断行情、信号、风控或订单 |
| 显式装配 | `x.go` 负责把基础能力和业务模块组合起来；基础模块不创建隐藏全局客户端 |
| 接口集成 | 跨 L1 能力通过本地接口、事件或 adapter 集成，不形成核心 go.mod 硬依赖 |
| 测试证据 | 每个模块都要有 contract、golden、boundary 和 failure case |
| 低基数与脱敏 | 观测、配置 manifest 和测试证据默认不得泄露 secret 或高基数字段 |

## 模块总表

| 模块 | 一句话定位 | 拥有 | 不拥有 |
| --- | --- | --- | --- |
| `kernel` | L0 标准库扩展 | error、time、context、lifecycle、shutdown、health、validation、sync、version、retry primitive | 配置解析、观测供应商、存储、网络、App runtime、业务模型 |
| `configx` | 显式配置加载与脱敏 | source、merge、decode、validate、redaction、provenance、manifest、hash | secret backend、全局配置中心、自动发现、核心 watch/reload、业务配置结构体 |
| `observex` | vendor-neutral 可观测性契约 | logger、metrics、tracer、field、redactor、label policy、health schema、noop、recorder | 具体监控 SDK 硬依赖、告警策略、业务监控规则、配置读取、全局客户端 |
| `testkitx` | 测试专用证据库 | assert、golden、contract、fixture、harness、fake clock、recorder、leak、boundary | 生产依赖、真实外部系统、业务 integration/chaos/soak 总入口 |
| `resiliencx` | operational resilience runtime | timeout、retry、circuit、bulkhead、rate limit、fallback、budget、classifier、idempotency、event | 交易风控、订单风险、交易所 SDK、调度、存储后端、业务补偿 |
| `schedulex` | deterministic scheduler | trigger、clock、misfire、overlap、jitter、EventSink、Locker interface、snapshot | 分布式锁实现、队列、exactly-once、retry/circuit、业务任务语义 |

## `kernel`

`kernel` 是所有基础库可共享的 L0 原语层，只使用 Go 标准库。它不应该演变成应用框架，也不负责模块注册、依赖图或业务生命周期编排。

必需能力：

- `errx`：错误种类、严重级别、是否可重试、JSON 契约。
- `timex`：真实时钟、固定时钟、可推进时钟。
- `contextx`：类型安全 context key。
- `lifecycx`：最小组件启动、停止和失败回滚原语。
- `shutdownx`：LIFO 关闭钩子、graceful shutdown。
- `healthx`：startup、ready、degraded、unhealthy、shutting_down 基础状态。
- `validx`：前置条件、不变量、结构校验基础。
- `syncx`：worker group、并发限制、fan-in/fan-out 小原语。
- `versionx`：build info、module version、兼容性判断。
- `retryx`：backoff、retry marker、轻量 retry loop。

边界：

- 不导入 `configx`、`observex`、`resiliencx`、`schedulex`、`testkitx`、`x.go` 或业务模块。
- 不启动隐藏后台 goroutine。
- 不持有全局可变单例。
- `retryx` 只放 L0 primitive；完整 timeout、circuit、bulkhead、rate limit、fallback 属于 `resiliencx`。
- `obsx` 只能是极简 no-vendor interface，不能替代 `observex`。

验收：

- `go.mod` 只保留标准库。
- 生产代码没有隐藏 goroutine 或跨模块反向 import。
- API snapshot 能证明公开 primitive 稳定。
- fake clock、shutdown LIFO、health 聚合、错误 JSON 和 retry marker 有确定测试。

## `configx`

`configx` 负责显式配置加载、合并、解码、校验、脱敏、来源追踪和 effective manifest。它不是全局配置中心，也不是 secret platform。

必需能力：

- source：env、env file、JSON、TOML、YAML、map。
- 合并顺序：推荐 `defaults < file < env < override`。
- provenance：每个 effective key 必须记录来源和敏感性。
- decode：tag-based decode 到调用方 struct。
- validate hook：调用方注册校验函数。
- redaction：token、password、secret、key 等字段脱敏。
- sanitized manifest：给日志、health、release/runtime evidence 使用。
- config hash：输出 effective config hash。
- schema：字段、类型、默认值、是否敏感的机器可读描述。

边界：

- 所有 source 和路径由调用方显式传入，不自动发现。
- 不创建全局 `Config` 单例。
- 不直接接 Vault、KMS、Kubernetes Secret 或云 Secret Manager。
- 不在核心包启动 watch/reload goroutine；动态配置必须是显式子模块和独立契约。
- 不替业务模块定义配置结构体。
- 不依赖 `observex`、`resiliencx`、`schedulex`、`x.go` 或业务模块。

验收：

- source precedence 有 golden 测试。
- secret redaction 覆盖日志、错误、health、manifest。
- provenance 是强制输出，而不是可选调试信息。
- 相同输入产生稳定 manifest hash。

## `observex`

`observex` 是 vendor-neutral 可观测性契约库。它统一 Foundation 内部如何表达 logs、metrics、traces、health、字段、脱敏和 label policy，但不实现监控平台。

必需能力：

- `Logger`、`Meter`、`Tracer`、`Span` interface。
- 统一 `Field`、`Label` 和 context propagation。
- `Redactor` 和敏感字段策略。
- `LabelPolicy`：低基数、非敏感、lower snake case。
- health JSON schema。
- noop implementation。
- memory recorder，服务测试和 smoke。
- contract schema：指标名、日志字段、trace 字段、health 字段锁定。

边界：

- 核心包不硬绑定具体日志、指标或追踪供应商 SDK。
- 不读取配置文件。
- 不创建隐藏全局 logger、meter 或 tracer。
- 不做 alert routing。
- 不做业务监控规则。
- 不判断风控、信号、订单是否异常。

观测语义：

- 指标命名：`foundationx_<module>_<operation>_<measure>`。
- 默认允许 label：`module`、`component`、`operation`、`status`、`error_kind`。
- 默认禁止 label：`order_id`、`user_id`、`account_id`、`api_key`、`secret`、`token`、`trace_id`。
- `symbol`、`exchange` 必须分级治理；未列入白名单前不得进入默认 metrics label。
- `errx.Kind` 可映射到 metric label 和 span status。

验收：

- label policy checker 能拦截高基数和敏感 label。
- redaction leak test 覆盖日志、health、manifest 和 recorder。
- noop 未注入时安全运行。
- memory recorder 可用于 smoke 和 contract 测试。

## `testkitx`

`testkitx` 是测试专用能力库，不能进入生产 import graph。它的价值是让基础库和下游模块用统一证据验证边界、契约和错误路径。

必需能力：

- `assertx`：稳定断言、错误断言、eventually。
- `golden`：JSON/bytes golden 对比，默认不更新。
- `contract`：contract hash、schema fingerprint。
- `fixture`：临时目录、HOME、module、env 隔离。
- `harness`：命令执行、stdout/stderr/env digest evidence。
- `clocktest`：fake clock / deterministic time。
- `obstest`：log/metric/trace recorder。
- `leaktest`：goroutine leak 检查。
- `boundarytest`：禁止测试库进入生产 import graph。
- `manifesttest`：release manifest fixture。

边界：

- 生产包不得 import `testkitx`。
- 不读取真实生产环境变量或密钥。
- 不启动真实 Redis、Postgres、Kafka 或交易所连接。
- 不替代业务模块自己的 L2/L3 integration、chaos、soak 或 benchmark infra。

验收：

- 下游仓库可复用 `make boundary-testkit`。
- `go list` 或 import graph 能证明生产包没有 `testkitx`。
- fake clock 覆盖 timeout、retry、schedule 等时间相关逻辑。
- golden/contract/harness evidence 可被 release gate 消费。

## `resiliencx`

`resiliencx` 必须从“标准源/模板/generator/harness”叙事修回真实弹性容错库。标准事实源属于 `xlib-standard`；`resiliencx` 只负责 operational resilience。

定位：

```text
resiliencx = operational resilience
risk-engine = trading risk
```

必需能力：

- timeout：单次调用超时。
- deadline budget：多级调用共享剩余时间预算。
- retry：指数退避、jitter、最大次数、最大耗时。
- circuit breaker：closed、open、half-open。
- bulkhead：并发隔离、队列限制。
- rate limiter：QPS、burst、按 key 限流。
- fallback：失败后的安全降级。
- hedging：慢请求副本，后期再加。
- error classifier：哪些错误可重试，哪些错误直接 fail。
- idempotency hint：是否允许 retry，尤其下单类请求必须显式声明。
- policy chain：建议顺序为 `budget -> timeout -> bulkhead -> circuit -> rate limit -> retry -> fallback`。
- event hook：policy event 输出给调用方或 adapter。
- fake clock：确定性测试。

边界：

- 不做交易风控、仓位控制或 order risk decision。
- 不知道 strategy、symbol、account 的业务含义。
- 不直接 import exchange SDK。
- 不直接 import Redis、Postgres、Kafka 作为强依赖。
- 不替代 `kernel.retryx` 的基础 backoff 原语。
- 不替代 `schedulex` 的任务调度。
- 观测通过本地 `Observer`、policy event 或 adapter 接入，不硬 import `observex`。

和 `kernel.retryx` 的边界：

| 项目 | `kernel.retryx` | `resiliencx` |
| --- | --- | --- |
| 层级 | L0 primitive | L1 runtime policy |
| 主要职责 | backoff、retry marker、简单 retry loop | timeout、retry、circuit、bulkhead、rate、fallback |
| 观测 | 不负责完整 metrics | 输出 policy events |
| 状态 | 尽量无状态 | breaker、limiter、bulkhead 可有状态 |
| 依赖 | stdlib only | 可依赖 `kernel`，观测通过接口注入 |
| 使用场景 | 基础库内部轻量重试 | 外部 API、交易所、数据源、消息、任务执行 |

P0 修复：

- README 删除 Standard Source、Go Reference Template、Generator、Harness、Evidence Runtime 主身份。
- 增加 `docs/resilience.md`。
- 增加 `timeout.go`、`retry.go`、`circuit.go`、`bulkhead.go`、`ratelimit.go`、`fallback.go`、`policy.go`、`event.go`、`classifier.go`。
- 增加 `resilience_event.schema.json` 和 `policy_config.schema.json`。
- 增加 deterministic retry、circuit half-open、bulkhead reject、timeout cancellation、idempotency guard、observability event golden 测试。

## `schedulex`

`schedulex` 是确定性任务调度库。它负责何时触发任务、如何处理错过执行和重叠执行，不负责任务内部的业务含义或容错策略。

必需能力：

- trigger：Once、Every、Cron、DailyAt。
- clock injection：所有调度决策通过 clock 注入。
- scheduler runtime：AddJob、Start、Shutdown、Snapshot。
- misfire policy：skip、run_once、catch_up。
- overlap policy：skip、queue_one、allow。
- max concurrency：全局和 job 级并发控制。
- deterministic jitter：避免所有任务同时打外部 API。
- EventSink：job started、finished、failed、skipped。
- Locker interface：只声明分布式锁合同。
- Snapshot：当前任务、下次触发、运行状态。

边界：

- 不内置 Redis 或 Postgres 分布式锁实现。
- 不保证 exactly-once。
- 不做消息队列。
- 不做业务任务注册中心。
- 不理解 market、factor、risk、order 业务语义。
- 不替代 `x.go` 的 wiring。
- 不直接依赖 `resiliencx`；任务需要 retry/circuit 时由调用方包装 job handler。
- 不直接依赖 `observex`；观测通过本地 `EventSink` 或 adapter 完成。

验收：

- trigger determinism 覆盖 Once、Every、Cron、DailyAt。
- timezone/DST golden 防止每日任务漂移。
- misfire/overlap golden 固化 skip、run_once、catch_up、queue_one 行为。
- lock contract test 约束 lease、renew、release 语义。
- shutdown 不启动新任务，并按策略等待或取消正在执行的任务。

`JobRunEvent` 建议契约：

```go
type JobRunEvent struct {
    JobName      string
    ScheduledAt time.Time
    StartedAt   time.Time
    FinishedAt  time.Time
    Status      string // success / failed / skipped / misfired / overlapped
    ErrorKind   string
    Attempt     int
}
```

## 依赖与集成矩阵

| From \ To | kernel | configx | observex | testkitx | resiliencx | schedulex | x.go | business |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| kernel | - | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| configx | ✅ | - | ❌ | test-only | ❌ | ❌ | ❌ | ❌ |
| observex | ✅ | ❌ | - | test-only | ❌ | ❌ | ❌ | ❌ |
| resiliencx | ✅ | ❌ | interface-only | test-only | - | ❌ | ❌ | ❌ |
| schedulex | ✅ | ❌ | interface-only | test-only | ❌ | - | ❌ | ❌ |
| testkitx | ✅ test | ✅ test | ✅ test | - | ✅ test | ✅ test | ❌ prod | ❌ prod |
| x.go | ✅ | ✅ | ✅ | ❌ prod | ✅ | ✅ | - | ✅ |

最小组合形态：

```text
x.go
  -> configx.Load(explicit sources)
  -> observex.NewNoop 或供应商 adapter
  -> resiliencx.New(policy, observer adapter)
  -> schedulex.New(clock, event sink adapter)
  -> business providers / engines
```

基础模块暴露 typed options；`x.go` 负责从 `configx` 的 typed config 生成 options 并显式传入。

## 配置与选项边界

基础模块不应为了读取自身配置而互相 import。推荐配置树由 `x.go` 读取后分发：

```yaml
foundation:
  configx:
    sources: [defaults, file, env, override]
  observex:
    labels: [module, component, operation, status, error_kind]
  resiliencx:
    default_timeout: 2s
    retry:
      max_attempts: 3
      require_idempotency: true
  schedulex:
    timezone: UTC
    misfire: run_once
    overlap: skip
```

约束：

- `configx` 只负责 decode、validate、manifest，不替其他模块持有全局状态。
- `observex`、`resiliencx`、`schedulex` 只接收 typed options。
- secret backend 不属于 `configx` 核心；后续需要时单独做 `secrectx` 或部署层 adapter。

## 观测输出策略

`observex` 拥有语义标准，其他模块只输出事件或调用本地接口。

| 来源模块 | 输出 | 进入观测的方式 |
| --- | --- | --- |
| `configx` | sanitized manifest、config hash、load/validate event | `x.go` 或 adapter 记录 |
| `resiliencx` | policy event、attempt、state transition、reject、fallback | 本地 `Observer` 转接到 `observex` |
| `schedulex` | `JobRunEvent`、misfire、overlap、lock event | 本地 `EventSink` 转接到 `observex` |
| `kernel` | error meta、health report、lifecycle state | 上层显式记录 |

默认指标 label 仅允许 `module`、`component`、`operation`、`status`、`error_kind`。高基数和敏感字段必须进入日志 body 或 trace attribute 前先通过 redaction 和白名单治理，不得直接进入 metrics label。

## 故障模式与防线

| 模块 | 典型故障模式 | 防线 |
| --- | --- | --- |
| `kernel` | 隐藏 goroutine、全局可变状态、反向依赖 | stdlib-only gate、goroutine scan、API snapshot |
| `configx` | source precedence 不稳定、secret 泄露、缺 provenance | precedence golden、redaction leak test、manifest hash |
| `observex` | 高基数 label、敏感字段入 metrics、供应商锁定 | label checker、redaction test、no-hard-vendor gate |
| `testkitx` | 进入生产 import graph、fixture 泄露环境 | boundary scanner、env isolation、production import gate |
| `resiliencx` | 非幂等请求被重试、breaker 抖动、bulkhead 饥饿 | idempotency guard、fake-clock tests、state transition golden |
| `schedulex` | DST 漂移、misfire 语义不稳定、overlap 失控、lock lease 歧义 | timezone/DST golden、misfire/overlap golden、lock contract |

## 性能预算

| 模块 | 预算方向 |
| --- | --- |
| `kernel` | primitive 尽量零分配；不得因全局锁影响上层热路径 |
| `configx` | 启动期加载可做完整校验；运行期 snapshot 读取应稳定且无隐藏 IO |
| `observex` | noop 路径近似零成本；label 校验和 redaction 可在边界执行 |
| `testkitx` | 测试路径可更重，但必须 deterministic 且避免 flake |
| `resiliencx` | 每次 policy execution 额外开销有界；fake clock 测试状态机 |
| `schedulex` | trigger 计算确定且可预测；大 job 集合需要 snapshot 和选择策略测试 |

## 建设顺序

P0：

1. 修正 `resiliencx` 身份：从标准模板叙事改成真实弹性容错库。
2. 明确 `xlib-standard` 只做标准源、模板、gate、evidence。
3. `configx`、`observex` 从 `foundationx` 迁移到 `kernel`，或写清兼容期。
4. 统一 Go baseline：全部 Go 1.23，等 CI 通过后再整体升级。
5. 将 `FOUNDATION-DEPS.yaml` 的依赖矩阵接入 CI。

P1：

- `kernel`：stdlib-only gate、primitive API snapshot、no hidden global state。
- `configx`：source precedence golden、secret redaction golden、provenance evidence、config hash。
- `observex`：metrics/log/trace schema contract、label policy checker、redaction leak test。
- `testkitx`：production import boundary scanner、golden/contract/harness evidence。
- `resiliencx`：timeout/retry/circuit/bulkhead/rate/fallback、idempotency guard、policy event contract。
- `schedulex`：trigger determinism、timezone/DST golden、misfire/overlap contract、lock interface contract。

P2：

- 视真实需求新增 `secrectx`，不要塞进 `configx`。
- 将依赖边界、go.mod、Go version、release evidence、secret scan 规则沉淀到 `xlibgate` 或 `xlib-standard/scripts`。
- 暂不单独拆 `ratelimitx`、`lockx`、`servicex/appx`，避免和 `resiliencx`、`schedulex`、`x.go` 重叠。

结论：第一阶段 6 个模块已经能形成 Foundation 最小闭环；当前优先级不是扩模块，而是修正 `resiliencx` 身份、统一依赖边界和 Go baseline，并把这些规则机器化。
