# Foundation v1 可验收规格

> 本文定义 Foundation v1 的验收目标、模块身份、边界、一致性修复、CI gate、issue 拆分和最小闭环。
> 定位与边界 → `foundation-modules.md`
> 契约签名/目录/CI/测试/发布 → `FOUNDATION-SPEC.md`
> **验收标准与路线图 → 本文**

最后更新：2026-06-14

> **范围说明（2026-06-14）**：本文是 Foundation v1 的**初始规划文档**，当时仅覆盖 6 个核心模块（kernel、configx、observex、testkitx、resiliencx、schedulex）。Foundation 此后已扩展至 17 个模块，涵盖门禁（xlib-standard、xlibgate）、存储扩展（redisx、kafkax、natsx、postgresx、taosx、ossx、clickhousex）、契约与传输（contracts、transportx）和领域共享（domainx）。**模块规格、状态和追踪矩阵的权威索引见 [`module/README.md`](./README.md)**；本文的第 2 节"六个模块的产品需求级定义"和第 8 节"模块最终关系"仅反映 v1 收敛期的初始范围，不反映当前完整模块集合。

---

## 1. Foundation v1 验收目标

一句话：

> **任意一个上层服务，不写重复基础设施代码，只靠这 6 个模块，就能完成配置加载、观测注入、生命周期管理、弹性外部调用、确定性调度、测试证据和优雅关闭。**

### 上层 `x.go` 应该只做

```text
load config
→ validate config
→ initialize observability
→ create lifecycle manager
→ wrap external clients with resilience policy
→ register scheduled jobs
→ start components
→ expose health
→ graceful shutdown
→ emit release/runtime evidence
```text

### 上层 `x.go` 不应该重新实现

```text
配置合并
secret 脱敏
logger/metrics/tracer 抽象
retry/backoff/circuit/bulkhead
cron/misfire/overlap
fake clock
golden test
import boundary check
release manifest
```text

---

## 2. 六个模块的产品需求级定义

### 2.1 kernel — 所有基础库的最小原语底座

定位：

> **提供跨项目共享的 L0 原语，不提供任何业务能力、不绑定任何外部后端、不启动任何隐藏 runtime。**

`kernel` 是 Go L0 标准库扩展，只使用 Go 标准库，不引入业务领域、存储、网络框架或可观测性供应商依赖。包清单覆盖 error、time、lifecycle、retry、health、obs、validation、sync、version、context、shutdown 等基础原语。

#### 应冻结的核心契约

| 契约        | 最小要求                                                                      |
| ----------- | ----------------------------------------------------------------------------- |
| `errx`      | `Kind`、`Severity`、`Retryable`、`Temporary`、`Operation`、`Cause`、JSON 输出 |
| `timex`     | `Clock` interface、real clock、fixed clock、manual/advance clock              |
| `contextx`  | typed key，禁止 string key 污染                                               |
| `lifecycx`  | component start/stop 顺序、失败回滚、状态机                                   |
| `shutdownx` | LIFO hooks、signal handling、timeout shutdown                                 |
| `healthx`   | `Healthy/Degraded/Unhealthy/Starting/ShuttingDown` 状态                       |
| `retryx`    | backoff、jitter、retry marker，但不做完整 resilience runtime                  |
| `validx`    | precondition、invariant、struct validation helper                             |
| `syncx`     | worker group、limiter、safe goroutine primitive                               |
| `versionx`  | module/build/version compatibility                                            |

#### 关键边界 — 拒绝这些 PR

```text
拒绝配置文件解析
拒绝 Prometheus/OpenTelemetry/Zap 绑定
拒绝 Redis/Postgres/Kafka/HTTP client
拒绝交易领域模型
拒绝后台 goroutine runtime
拒绝全局 logger/config/client
拒绝业务 event/DTO
```text

#### kernel 下一步（4 件事）

1. **API freeze 文件**

   ```text
   contracts/public_api/kernel_v0.schema.json
   contracts/public_api/errx.json
   contracts/public_api/healthx.json
   contracts/public_api/lifecycx.json
   ```text

2. **primitive admission gate**
   每个新增包必须通过 L0 审查：
   - 是否 stdlib-only？
   - 是否无业务语义？
   - 是否无后端绑定？
   - 是否无隐藏 goroutine？
   - 是否上层 3 个以上模块真实需要？

3. **`retryx` 限界**
   `kernel.retryx` 只能做 backoff/retry marker。完整 retry/circuit/bulkhead/rate limit 放到 `resiliencx`。

4. **`obsx` 限界**
   `kernel.obsx` 只能给 L0 包自用极简 no-op interface。完整 observability owner 是 `observex`。

---

### 2.2 configx — 配置事实与脱敏证据 owner

定位：

> **显式配置加载、合并、解码、校验和脱敏库。**

`configx` 支持 env、env file、JSON、TOML、YAML、map source，支持 last-wins 合并、struct decode、validation hooks 和安全脱敏。不创建全局配置状态，不自动发现配置源，不依赖 `x.go`。

#### 应该回答的问题

```text
这个服务最终使用了什么配置？
每个配置来自哪里？
哪个 source 覆盖了哪个 source？
哪些字段是 secret？
哪些字段被脱敏后可以进入日志/health/manifest？
当前 effective config 是否可复现？
```text

#### 应补的核心能力

| 能力                  | 为什么重要                                    |
| --------------------- | --------------------------------------------- |
| `Provenance`          | 每个 key 记录 source、priority、override 链路 |
| `EffectiveConfigHash` | release/runtime evidence 可复现               |
| `SanitizedManifest`   | 安全进入日志、health、CI artifact             |
| `Schema`              | 机器可读配置契约，便于 review 和 drift check  |
| `StrictDecode`        | 未识别字段、重复字段、类型错误可 fail-fast    |
| `SecretPolicy`        | 统一 secret key 识别规则                      |
| `ValidationReport`    | 不只返回 error，也返回字段级证据              |
| `NoGlobalStateGate`   | 防止后续引入进程级 config singleton           |

#### 建议 API 形态

```go
type Source interface {
    Name() string
    Load(ctx context.Context) (map[string]Value, error)
}

type Value struct {
    Raw          string
    Source       string
    Sensitive    bool
    OverriddenBy []string
}

type LoadResult struct {
    Values  map[string]Value
    Sources []SourceReport
}

func (r LoadResult) Sanitize() SanitizedResult
func (r LoadResult) Hash() string
func Decode[T any](r LoadResult, target *T, opts ...DecodeOption) error
func SchemaOf[T any]() Schema
```text

#### 不要做的事

`configx` 不应该升级成 secret manager。Vault、KMS、Kubernetes Secret、AWS Secrets Manager、GCP Secret Manager 这些真实后端应由未来的 `secrectx` 或 deployment adapter 处理。`configx` 只接受 source，负责 decode、validate、sanitize、evidence。

---

### 2.3 observex — 可观测性语义 owner，不是监控后端

定位：

> **L1 vendor-neutral 可观测性契约库，统一日志、指标、追踪、健康检查、上下文字段、脱敏、label policy、测试记录器和 release evidence。**

`observex` 不绑定 Prometheus、OpenTelemetry、Zap、Logrus 或业务 provider。

#### 真正应该拥有的东西

不是某个 logger 实现，而是**观测语义标准**：

| 契约             | 说明                                 |
| ---------------- | ------------------------------------ |
| `Logger`         | structured log interface             |
| `Metrics`        | counter/gauge/histogram/timer        |
| `Tracer`         | span lifecycle                       |
| `Field`          | 统一字段模型                         |
| `Redactor`       | secret/PII 脱敏                      |
| `LabelPolicy`    | metrics label 白名单、低基数、非敏感 |
| `ContextFields`  | trace id、request id、correlation id |
| `HealthJSON`     | health 输出 schema                   |
| `MemoryRecorder` | 测试与 smoke 的 canonical recorder   |
| `Noop*`          | 未注入时安全运行                     |

#### 必须补的 gate

```text
指标名是否符合规范
label 是否低基数
label 是否包含 secret/account/order_id
日志字段是否经过 redaction
health JSON 是否泄漏配置 secret
trace attribute 是否含高基数字段
errx.Kind 是否映射成统一 error_kind
```text

建议增加：

```makefile
make observability-contract-check
make label-policy-check
make redaction-leak-check
make health-json-contract-check
```text

#### 指标命名规范

基础库指标统一成：

```text
foundationx_<module>_<operation>_<measure>
```text

示例：

```text
foundationx_configx_load_duration_seconds
foundationx_configx_decode_errors_total
foundationx_resiliencx_circuit_state
foundationx_schedulex_job_runs_total
foundationx_schedulex_job_duration_seconds
```text

**label 允许列表：**

```text
module
component
operation
status
error_kind
policy
job
```text

**label 谨慎使用：**

```text
symbol
exchange
provider
```text

**label 默认禁止：**

```text
api_key
account_id
order_id
trace_id
request_id
raw_error
config_value
secret_path
```text

---

### 2.4 testkitx — 测试证据 owner

定位：

> **L1 测试专用能力库，为基础库提供 assert、golden、contract hash、fixture、command harness、fake clock、observability recorder、goroutine leak、production import boundary、manifest fixture 等能力。生产包不得 import。**

#### 应该成为所有基础库的统一测试底座

每个 Foundation repo 都应该能复用：

```text
assertx
golden
contract
fixture
harness
clocktest
obstest
leaktest
boundarytest
manifesttest
repotest
```text

#### 最关键的边界 gate

```text
生产 Go 文件不得 import testkitx
testkitx 不得读取真实 secret
testkitx 不得连接真实 Redis/Postgres/Kafka
testkitx 不得改写 golden，除非 TESTKITX_UPDATE_GOLDEN=1
testkitx 不得成为下游 production dependency
```text

#### 下游统一 Make target

所有基础库都应该有：

```bash
make test
make race
make contract
make golden
make boundary
make leak
make evidence
```text

其中 `make boundary` 必须检查 `pkg/`、`internal/`、`cmd/` 这些生产路径不能出现 `testkitx` 导入。

---

### 2.5 resiliencx — 必须从"标准源副本"改回"弹性容错库"

> **⚠️ 当前最不稳定的模块。**

当前 README 写的是 Standard Source、Go Reference Template、Generator、Harness、Evidence Runtime，这和 `xlib-standard` 的职责高度重合，而不是真正的弹性容错运行时库。

#### 身份重定义

```text
xlib-standard = 标准源 / 模板 / generator / harness / evidence
resiliencx    = runtime resilience policy library
```text

#### 应该解决的问题

```text
外部依赖不稳定怎么办？
交易所 API 慢怎么办？
行情 provider 临时失败怎么办？
Kafka publish timeout 怎么处理？
定时任务调用第三方 API 被限流怎么办？
哪些错误可以 retry，哪些错误绝对不能 retry？
下单类操作是否允许 retry？
同一个 provider 挂了是否要熔断？
```text

#### 最小公共 API

```go
type Policy struct {
    Timeout     TimeoutPolicy
    Retry       RetryPolicy
    Circuit     CircuitPolicy
    Bulkhead    BulkheadPolicy
    RateLimit   RateLimitPolicy
    Fallback    FallbackPolicy
    Idempotency IdempotencyPolicy
}

type Runner interface {
    Do(ctx context.Context, op Operation, fn func(context.Context) error) error
}

type Operation struct {
    Name        string
    Component   string
    Idempotent  bool
    TimeoutHint time.Duration
}

type Event struct {
    Time       time.Time
    Operation  string
    Policy     string
    Action     string // allow/retry/reject/open/close/fallback/timeout
    Attempt    int
    ErrorKind  string
    Duration   time.Duration
}
```text

#### 必备策略

| 策略              | 最小行为                                    |
| ----------------- | ------------------------------------------- |
| Timeout           | 单次操作 deadline                           |
| Retry             | max attempts、max elapsed、backoff、jitter  |
| Circuit breaker   | closed/open/half-open                       |
| Bulkhead          | 并发隔离、队列上限、快速拒绝                |
| Rate limit        | QPS、burst、按 key 限流                     |
| Fallback          | 显式降级函数                                |
| Budget            | 剩余 deadline 传播                          |
| Classifier        | 错误分类：retryable / non-retryable / fatal |
| Idempotency guard | 非幂等操作默认禁止自动 retry                |

#### 和交易风控严格分开

```text
resiliencx = operational resilience
risk-engine = trading risk
```text

`resiliencx` **可以**判断：

- provider timeout
- too many requests
- temporary network error
- circuit open
- bulkhead full

`resiliencx` **绝不能**判断：

- 仓位是否过大
- 杠杆是否过高
- 订单是否应该拒绝
- 策略是否允许开仓
- 组合暴露是否超限

#### v0.1 目标目录

```text
pkg/resiliencx/
  policy.go
  runner.go
  operation.go
  timeout.go
  retry.go
  backoff.go
  circuit.go
  bulkhead.go
  ratelimit.go
  fallback.go
  classifier.go
  idempotency.go
  event.go
  options.go
  noop.go

contracts/
  policy.schema.json
  event.schema.json
  error_classifier.schema.json

docs/
  identity.md
  boundary.md
  api.md
  policy-chain.md
  idempotency.md
  observability.md
  testing.md
```text

#### 策略链默认执行顺序

```text
context budget
→ rate limit
→ bulkhead
→ circuit breaker
→ timeout
→ retry loop
→ fallback
→ event sink
```text

**两种 timeout 语义：**

```text
PerAttemptTimeout：每次尝试单独 timeout
TotalTimeout：整个 operation 总 timeout
```text

**交易所下单类操作默认：**

```text
Idempotent=false
Retry disabled unless explicit idempotency key exists
```text

---

### 2.6 schedulex — 确定性调度，不是分布式任务平台

定位：

> **L1 deterministic scheduler，只依赖 Go 标准库，支持 Once、Every、五字段 Cron、DailyAt、Clock 注入、misfire、overlap、Locker interface、EventSink。不内置 Redis/Postgres 锁后端。**

#### 应该解决的问题

```text
什么时候运行任务？
服务暂停后错过任务怎么办？
上一轮任务没跑完下一轮来了怎么办？
多个实例是否允许同时跑？
如何用 fake clock 做确定性测试？
任务事件如何输出给 observex？
```text

#### 最小公共 API

```go
type Scheduler interface {
    AddJob(job Job, trigger Trigger, opts ...JobOption) error
    Start(ctx context.Context) error
    Shutdown(ctx context.Context) error
    Snapshot() Snapshot
}

type Job interface {
    Name() string
    Run(ctx context.Context) error
}

type Trigger interface {
    Next(after time.Time) (time.Time, bool)
}

type EventSink interface {
    Emit(ctx context.Context, event JobEvent)
}
```text

#### 必须补齐的测试

| 测试                | 为什么                                               |
| ------------------- | ---------------------------------------------------- |
| trigger determinism | 相同 clock、相同 trigger 必须得到相同 next time      |
| timezone/DST golden | DailyAt/Cron 避免时区、夏令时漂移                    |
| misfire contract    | skip/run_once/catch_up 行为固定                      |
| overlap contract    | skip/queue_one/allow 行为固定                        |
| lock contract       | Redis/Postgres adapter 未来必须满足同一个 lease 语义 |
| leak test           | Scheduler shutdown 后不能泄漏 goroutine              |
| race test           | AddJob/Start/Shutdown/Snapshot 并发安全              |

#### 和 resiliencx 的关系

`schedulex` 不应该直接依赖 `resiliencx`。正确关系：

```text
x.go 或上层 job wrapper:
  schedulex job
    → resiliencx runner
      → external provider call
```text

```go
job := schedulex.JobFunc{
    NameValue: "fetch-market-data",
    RunFunc: func(ctx context.Context) error {
        return resilience.Do(ctx, op, func(ctx context.Context) error {
            return provider.Fetch(ctx)
        })
    },
}
```text

`schedulex` 保持纯调度，`resiliencx` 负责容错策略。

---

## 3. 一致性修复

### 3.1 Go baseline 不统一

当前状态：

```text
kernel / configx / observex / resiliencx / schedulex → Go 1.23
testkitx → Go 1.24
```text

`testkitx` 会被大量下游测试依赖；如果它要求更高的 Go 版本，会把下游测试工具链抬高。

**建议：**

```text
方案 A（推荐短期）：全部统一到 Go 1.23
方案 B（中期）：全部统一到 Go 1.24
```text

短期用方案 A，等全仓库和 CI 都确认后，再统一升级到 Go 1.24。

### 3.2 foundationx compatibility 依赖要退出

当前状态：

```text
configx go.mod → github.com/ZoneCNH/foundationx v0.0.0（本地 replace）
observex go.mod → github.com/ZoneCNH/foundationx v0.1.0
```text

如果 Foundation 底座已收敛到 `kernel`，这些 compatibility 依赖应迁移或明确生命周期。

**建议 ADR：**

```text
ADR-Foundation-Compatibility-Exit

Decision:
  foundationx compatibility is transitional.
  New L0 primitives must live in kernel.
  configx/observex must migrate SecretString/ErrorKind/HealthStatus
  to kernel or local explicit contracts.

Deadline:
  remove foundationx dependency before configx v0.3 / observex v0.4.
```text

---

## 4. 需要补充的三个关键项

### 4.1 xlibgate — 机器化边界执行器（优先级：高）

`xlib-standard` 承担标准源、模板、generator、harness、evidence 等角色。下一步需要一个轻量 gate 执行器，把标准从文档变成机器检查。

**xlibgate 应该检查：**

```text
go.mod module path 是否正确
Go version 是否符合 baseline
是否有禁止依赖
是否有 x.go 反向依赖
是否有 production import testkitx
是否有 secret 泄漏
是否有 high-cardinality metric label
是否有 release manifest
是否有 public API snapshot
是否有 docs drift
是否有 contracts drift
```text

可以先不新建 repo，先放在 `xlib-standard/cmd/xlibgate`，稳定后再独立。

### 4.2 secrectx — 中期补，不要塞进 configx

短期不必马上做，但边界要先写。`configx` 不应该对接 Vault/KMS/Kubernetes Secret，否则会从"配置加载库"膨胀成"安全平台"。

**未来 secrectx 定位：**

```text
secret provider interface
secret lease metadata
rotation metadata
redaction integration
local dev secret source
```text

`configx` 仍然只消费 source，不拥有 secret backend。

### 4.3 foundation-example — 最小闭环样例仓库

比继续新建业务模块更重要。做一个很小的 repo 或 example：

```text
foundation-example/
  cmd/demo/
  internal/app/
  configs/
  tests/
```text

**必须演示：**

```text
configx 加载 env + yaml + override
observex 注入 memory logger/metrics/tracer
kernel lifecycx 管理 start/stop
resiliencx 包裹一个 fake external API
schedulex 每 1s 调度一次 job
testkitx fake clock + golden + boundary + leak
release manifest 生成
```text

只要这个 example 跑通，Foundation v1 才算真正闭环。

---

## 5. 不建议现在补的模块

| 模块         | 当前建议 | 原因                                                               |
| ------------ | -------- | ------------------------------------------------------------------ |
| `appx/runx`  | 暂不建   | 容易和 `x.go` composition root 重叠                                |
| `ratelimitx` | 不单独建 | 先放进 `resiliencx`                                                |
| `lockx`      | 暂不建   | `schedulex` 只要 `Locker` interface，Redis/Postgres 实现放 adapter |
| `eventx`     | 暂缓     | 先修真正的 `contracts`，不要重复定义 event envelope                |
| `httpx`      | 后期     | 外部 API SDK 需要，但不是 Foundation v1 必需                       |
| `cachex`     | 后期     | 容易和 redisx/memcachex 重叠                                       |
| `secrectx`   | 中期     | 重要，但不要先污染 `configx`                                       |

---

## 6. Issue / PR 拆分

### P0：身份和边界修复

#### Issue 1：resiliencx identity reset

```text
标题：Redefine resiliencx as runtime resilience policy library

验收：
- README 不再把 Standard Source / Generator / Harness 作为主身份
- 明确 xlib-standard 是标准源
- 新增 docs/identity.md、docs/boundary.md
- 新增 policy/retry/circuit/bulkhead/ratelimit/fallback 最小 API
- 删除或迁移模板叙事
```text

#### Issue 2：Foundation dependency matrix

```text
标题：Add machine-readable Foundation dependency matrix

验收：
- 新增 FOUNDATION_DEPENDENCY_MATRIX.md
- 新增 foundation-deps.yaml
- CI 检查 import graph
- kernel stdlib-only
- testkitx production import 禁止
- 基础库不得依赖 x.go
```text

#### Issue 3：Go baseline alignment

```text
标题：Align Foundation Go baseline

验收：
- 6 个模块 Go version 一致
- CI matrix 使用相同 Go version
- README/AGENTS/Release docs 同步
```text

#### Issue 4：foundationx compatibility exit plan

```text
标题：Define and start foundationx compatibility exit

验收：
- ADR 写清 compatibility 生命周期
- configx/observex 列出依赖 kernel 替代方案
- 不再新增 foundationx usage
```text

### P1：每个模块补最小 v1 能力

#### kernel

```text
- public API snapshot
- primitive admission check
- stdlib-only check
- no hidden goroutine check
- retryx/obsx boundary docs
```text

#### configx

```text
- provenance per key
- effective config hash
- sanitized manifest
- strict decode
- schema generation
- secret leak golden
```text

#### observex

```text
- label policy checker
- redaction leak checker
- metrics contract
- health JSON schema
- memory recorder contract
- errx.Kind mapping
```text

#### testkitx

```text
- production import boundary scanner stable API
- fake clock deterministic examples
- golden update guard
- release manifest fixture
- goroutine leak checker hardening
```text

#### resiliencx

```text
- timeout
- retry
- circuit breaker
- bulkhead
- rate limiter
- fallback
- idempotency guard
- policy event sink
- fake-clock tests
```text

#### schedulex

```text
- DST/timezone golden
- misfire contract
- overlap contract
- lock interface contract
- event sink schema
- shutdown leak/race tests
```text

### P2：Foundation example 闭环

```text
标题：Add foundation-example vertical smoke

验收：
- demo app can start and shutdown
- loads config with configx
- emits logs/metrics/traces via observex memory recorder
- runs scheduled job with schedulex fake clock
- wraps fake external call with resiliencx
- lifecycle managed by kernel
- tested with testkitx
- produces release manifest
```text

---

## 7. 统一 CI Gate

每个基础库同一组 gate，区别只在 profile：

```bash
make fmt
make vet
make lint
make test
make race
make boundary
make contracts
make docs-check
make secret-scan
make evidence
make release-check
make release-final-check
```text

### 各模块 profile-specific gate

```makefile
# kernel
make stdlib-only-check
make primitive-check
make no-global-state-check

# configx
make source-precedence-golden
make config-hash-check
make secret-redaction-golden

# observex
make label-policy-check
make redaction-leak-check
make metrics-contract-check

# testkitx
make production-import-scan-fixture
make golden-update-guard-check
make leaktest-selfcheck

# resiliencx
make retry-determinism-check
make circuit-contract-check
make idempotency-guard-check
make bulkhead-race-check

# schedulex
make trigger-determinism-check
make timezone-dst-golden-check
make misfire-contract-check
make lock-interface-check
```text

---

## 8. 模块最终关系

```text
xlib-standard
  标准源 / 模板 / generator / harness / evidence
  不作为普通运行时依赖

kernel
  L0 primitive
  stdlib-only

configx
  L1 config owner
  depends on kernel only, plus explicit parser deps

observex
  L1 observability contract owner
  depends on kernel
  no provider SDK

resiliencx
  L1 operational resilience owner
  depends on kernel
  accepts observex interfaces/events by option
  no business risk logic

schedulex
  L1 deterministic scheduler
  depends on kernel or stdlib only
  no direct resiliencx dependency

testkitx
  L1 test-only evidence owner
  may test all above
  forbidden in production import graph

x.go
  composition root
  consumes all above
  owns wiring only
```text

---

## 9. Foundation v1 是否够？

够做 Foundation v1。前提是不要把它们做散。它们必须共同完成一条基础闭环：

```text
configx 产生配置事实
observex 产生观测语义
kernel 管生命周期、错误、时间、健康、关闭
resiliencx 保护不稳定外部调用
schedulex 管确定性任务
testkitx 验证以上所有行为
xlib-standard/xlibgate 负责标准和机器执法
```text

### 真正需要补的（按优先级）

```text
1. resiliencx 身份修复
2. Go baseline 统一
3. foundationx compatibility 退出计划
4. import boundary 机器化
5. config provenance/hash
6. observability label/redaction gate
7. schedulex DST/misfire/lock contract
8. foundation-example 最小闭环
```text

> **现在不要再横向扩基础模块。先把这 6 个做成"可证明、可组合、可被 x.go 消费"的 Foundation v1。尤其先修 `resiliencx`，否则 Foundation 层会同时存在两个"标准源/模板仓库"，但缺一个真正的弹性容错运行时。**

---

## 附录：文件清单

| 文件                              | 用途                                                                 |
| --------------------------------- | -------------------------------------------------------------------- |
| `module/foundation-modules.md`    | 定位、边界、故障模式、性能预算、配置依赖、可观测输出、安全、升级兼容 |
| `module/FOUNDATION-SPEC.md`       | 契约签名、目录形态、CI gate、测试矩阵、发布 DoD、Issue/PR 模板       |
| `module/FOUNDATION-V1.md`（本文） | v1 验收目标、模块身份、一致性修复、路线图、issue 拆分、最小闭环      |
