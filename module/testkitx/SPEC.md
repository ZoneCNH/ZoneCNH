# testkitx 规格

- Status: Approved
- Spec-Version: v1.1.0
- Last-Updated: 2026-06-18
- Layer: 基座 · 测试期证据
- Version: v1.0.0
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `kernel`

> 公开投影 caveat：Status=Approved 与追溯矩阵覆盖证据不等同于 factory-grade；四源评分通过前机器事实层保持 factory=false。本 SPEC 仅描述 testkitx 的**窄定位**（L0 测试期证据 / 单进程 `go test` 工具）；goal.md 中的集成测试环境、故障注入、发布期证据包等「宽测试平台」能力已由 [goal.md](./goal.md) 顶部声明收口。

---

## 1. 摘要

`testkitx` 是测试基础设施，提供 fake 实现、fixture 加载、golden 测试、contract 测试、边界扫描等工具，帮助各模块稳定验证边界、错误路径和集成行为。禁止进入生产依赖图。

**证据边界：testkitx 提供测试期证据（test-time evidence）。** testkitx 的证据产物——golden file（FR-008 GoldenUpdate）、contract test 结果（§16.3）、boundary check 输出（FR-009）、goroutine leak check 输出（FR-010）、manifest——全部在 `go test` 进程内生成，服务于开发和 CI 测试阶段。testkitx 不做证据收集、汇总或发布；这些职责属于 xlib-evidence。详细分工：

| 维度 | testkitx（测试期证据） | xlib-evidence（CI/发布期证据） |
|------|----------------------|------------------------------|
| 运行阶段 | `go test` 进程内 | CI pipeline |
| 证据类型 | golden/contract/boundary/leak/manifest | coverage/manifest/remote evidence/report |
| 角色 | 证据**生成者** | 证据**收集者与发布者** |
| manifest | 测试期 manifest（本次测试的 golden/contract/boundary 结果） | 发布期 manifest（汇总所有模块 coverage/gate/manifest） |

两者互补：testkitx 产出原始证据 → xlib-evidence 在 CI pipeline 中收集、验证、发布为统一报告。

---

## 2. 问题与背景

各模块测试中重复实现 fake、fixture、assert 逻辑，导致：

- 每个模块自行实现 FakeLogger、FakeMeter，行为不一致
- fixture 加载逻辑散落各处，路径硬编码
- golden 文件更新无统一开关，CI 误更新
- 生产包意外依赖 test 工具，二进制膨胀
- contract 测试缺失，fake 与真实实现偏差未被发现
- goroutine 泄漏检测缺失，测试间相互干扰

---

## 3. 目标

- 统一 fake 实现：FakeConfig / FakeLogger / FakeMeter / FakeTracer / FakeClock / FakeBreaker
- 编译期接口检查（`var _ Interface = (*FakeImpl)(nil)`）
- deterministic fake：不调用 `time.Now()` 或 `math.Rand()`
- fixture loader + golden helper
- production import boundary scanner
- goroutine leak checker
- contract test harness

---

## 4. 非目标

- 不进入生产二进制或生产依赖图（生产代码由各模块自身维护，testkitx 仅供 `go test` 使用；BR-005 + CI Gate `no-production-import` 强制执行）
- 不定义交易、行情、风控、订单、仓位等业务域模型（业务模型由 `contracts` 和各业务域模块负责，testkitx 的 fake 类型只镜像 L1 基础设施接口）
- 不承担各模块领域 fixture 的集中维护（领域 fixture 由各模块在自身 `testdata/` 下维护，testkitx 只提供 fixture loader 工具和 golden file 辅助函数）
- 不替代集成测试 (L2)、系统测试 (L3)、混沌工程和长稳测试（这些测试层由各模块自行组织或由 `xlib-harness` / `xlibgate` 在 CI 管线中协调，testkitx 只覆盖单元测试期的 fake、fixture、golden、contract、boundary 工具）

---

## 5. 消费者

| 消费者            | 使用方式                                      |
| ----------------- | --------------------------------------------- |
| `kernel` 测试     | 使用 FakeLogger / FakeMeter 验证模块生命周期  |
| `configx` 测试    | 使用 FakeConfig 提供测试配置                  |
| `observex` 测试   | 使用 FakeMeter/FakeTracer 验证遥测输出        |
| `resiliencx` 测试 | 使用 FakeClock 控制时间、FakeBreaker 模拟熔断 |
| `schedulex` 测试  | 使用 FakeClock 控制调度时间                   |
| 业务域模块测试    | 使用 fake + fixture + golden 验证业务逻辑     |

---

## 6. 功能需求

### FR-001: FakeConfig

WHEN 调用 `FakeConfig(values)` 创建配置
THEN 返回 `configx.Reader`，`Get(key)` 返回对应值

WHEN 调用 `FakeConfig(values)` 且 key 不存在
THEN 返回 nil

### FR-002: FakeLogger

WHEN 调用 `FakeLogger()` 创建 logger
THEN 返回 `(*FakeLoggerImpl, observex.Logger)`

WHEN 调用 `fakeLogger.AssertLogged(level, contains)`
THEN 断言指定 level 的日志包含指定文本

WHEN 调用 `fakeLogger.AssertNoErrors()`
THEN 断言没有 Error 级别日志

WHEN 调用 `fakeLogger.Entries()`
THEN 返回所有日志条目

### FR-003: FakeMeter

WHEN 调用 `FakeMeter()` 创建 meter
THEN 返回 `(*FakeMeterImpl, observex.Meter)`

WHEN 调用 `fakeMeter.AssertCounterValue(name, expected)`
THEN 断言计数器值等于 expected

WHEN 调用 `fakeMeter.AssertHistogramRecorded(name)`
THEN 断言直方图有记录

### FR-004: FakeTracer

WHEN 调用 `FakeTracer()` 创建 tracer
THEN 返回 `(*FakeTracerImpl, observex.Tracer)`

WHEN 调用 `fakeTracer.AssertSpanCount(expected)`
THEN 断言 span 数量等于 expected

WHEN 调用 `fakeTracer.AssertTraceID()`
THEN 断言 trace_id 已传播

### FR-005: FakeClock

WHEN 调用 `FakeClock(at)` 创建时钟
THEN 返回 `*FakeClock`，`Now()` 返回 at

WHEN 调用 `fakeClock.Advance(d)`
THEN `Now()` 返回 at + d

WHEN 调用 `fakeClock.Set(t)`
THEN `Now()` 返回 t

### FR-006: FakeBreaker

WHEN 调用 `FakeBreaker(initial)` 创建熔断器
THEN 返回 `resiliencx.Breaker`，状态为 initial

### FR-007: Eventually

WHEN 调用 `Eventually(t, fn, timeout, interval)` 且 fn 在 timeout 内返回 true
THEN 测试通过

WHEN 调用 `Eventually(t, fn, timeout, interval)` 且 fn 超时仍返回 false
THEN 测试失败，输出清晰诊断

### FR-008: GoldenUpdate

WHEN 环境变量 `GOLDEN_UPDATE=1`
THEN `GoldenUpdate()` 返回 true

WHEN 环境变量 `GOLDEN_UPDATE` 未设置
THEN `GoldenUpdate()` 返回 false

### FR-009: BoundaryCheck

WHEN 调用 `BoundaryCheck(t, module)` 且生产包依赖 testkitx
THEN 测试失败，报告依赖路径

WHEN 调用 `BoundaryCheck(t, module)` 且生产包不依赖 testkitx
THEN 测试通过

### FR-010: GoroutineLeakCheck

WHEN 调用 `GoroutineLeakCheck(t)` 且测试结束后有 goroutine 泄漏
THEN 测试失败，报告泄漏的 goroutine 堆栈

WHEN 调用 `GoroutineLeakCheck(t)` 且无泄漏
THEN 测试通过

### Acceptance Criteria

| AC 编号 | 对应 FR | 验收条件 |
| ------- | ------- | -------- |
| AC-TKX-001 | FR-001 | FakeConfig(values) 返回 configx.Reader；Get(key) 返回对应值；key 不存在返回 nil |
| AC-TKX-002 | FR-002 | FakeLogger() 返回 (*FakeLoggerImpl, observex.Logger)；AssertLogged 断言指定 level 包含文本；AssertNoErrors 断言无 Error 日志；Entries 返回全部条目 |
| AC-TKX-003 | FR-003 | FakeMeter() 返回 (*FakeMeterImpl, observex.Meter)；AssertCounterValue 断言计数器值；AssertHistogramRecorded 断言直方图有记录 |
| AC-TKX-004 | FR-004 | FakeTracer() 返回 (*FakeTracerImpl, observex.Tracer)；AssertSpanCount 断言 span 数量；AssertTraceID 断言 trace_id 已传播 |
| AC-TKX-005 | FR-005 | FakeClock(at) Now() 返回 at；Advance(d) 后 Now() 返回 at+d；Set(t) 后 Now() 返回 t |
| AC-TKX-006 | FR-006 | FakeBreaker(initial) 返回 resiliencx.Breaker，状态为 initial |
| AC-TKX-007 | FR-007 | Eventually 在 timeout 内 fn 返回 true 则测试通过；超时仍 false 则测试失败并输出诊断 |
| AC-TKX-008 | FR-008 | GOLDEN_UPDATE=1 时 GoldenUpdate() 返回 true；未设置时返回 false |
| AC-TKX-009 | FR-009 | BoundaryCheck 检测到生产包依赖 testkitx 时测试失败报告路径；无依赖时通过 |
| AC-TKX-010 | FR-010 | GoroutineLeakCheck 检测到泄漏时失败报告堆栈；无泄漏时通过 |

---

## 7. 行为约束

| 编号 | 规则 | 违反时 |
| --- | --- | --- |
|  BR-001  | 所有 fake 必须实现对应接口，编译期检查：`var _ observex.Logger = (*FakeLoggerImpl)(nil)` | 编译失败 — CI Gate contract test 阻断 |
|  BR-002  | fake 行为必须确定性，不引入 `time.Now()` 或 `math.Rand()` | 测试结果不稳定 — CI 中非确定性失败 |
|  BR-003  | Eventually 使用 `testing.T` 而非 `panic`，失败时输出清晰诊断 | panic 代替测试失败 — 调用栈无诊断信息 |
|  BR-004  | GoldenUpdate() 只在 `GOLDEN_UPDATE=1` 环境变量下返回 true | CI 中误更新 golden 文件 — CI Gate golden update guard 阻断 |
|  BR-005  | 生产 import graph 中不能出现 testkitx（go list 验证） | CI Gate no-production-import 阻断 |
|  BR-006  | testkitx 是唯一允许依赖所有 Foundation L1 模块的包（仅 go test） | 其他模块引入 — CI Gate boundary check 阻断 |
|  BR-007  | golden 文件不泄露 secret（更新时自动检查） | CI Gate gitleaks 阻断 |

---

## 8. 接口契约

### 8.1 Fake 实现

> 注：以下签名对齐运行时 `/home/testkitx/pkg/testkitx/fake/` 的实际导出。实现类型一律命名 `Fake*Impl`（clock 例外，类型名为 `FakeClock`）；构造函数的「带/不带 `Fake` 前缀」与运行时一致。

```go
// 构造函数均位于子包 testkitx/fake（运行时为 pkg/testkitx/fake）。
func FakeConfig(values map[string]any) fake.Reader          // 实现 configx.Reader 契约
func FakeLogger() *FakeLoggerImpl                           // 实现 observex.Logger
func FakeMeter() *FakeMeterImpl                             // 实现 observex.Meter
func FakeTracer() *FakeTracerImpl                           // 实现 observex.Tracer
func Clock(at time.Time) *FakeClock                         // 注意：构造函数名为 Clock，非 FakeClock
func FakeBreaker(initial fake.BreakerState) fake.Breaker    // 返回 Breaker 接口
```

> **已撤销的虚构 API**：早期 SPEC 列出的 `FakeExporter() / FakeExporterImpl` 在运行时**未实现**（全仓 grep `FakeExporter` 零匹配）。遥测导出的测试验证改由 fake logger / fake meter / fake tracer 的断言方法覆盖。原 §8.6 `FakeExporterImpl` 小节已删除。

### 8.2 FakeLoggerImpl

```go
type FakeLoggerImpl struct{ /* ... */ }

func (l *FakeLoggerImpl) AssertLogged(level LogLevel, contains string)
func (l *FakeLoggerImpl) AssertNoErrors()
func (l *FakeLoggerImpl) Entries() []LogEntry
```

### 8.3 FakeMeterImpl

```go
type FakeMeterImpl struct{ /* ... */ }

func (m *FakeMeterImpl) AssertCounterValue(name string, expected float64)
func (m *FakeMeterImpl) AssertHistogramRecorded(name string)
```

### 8.4 FakeTracerImpl

```go
type FakeTracerImpl struct{ /* ... */ }

func (t *FakeTracerImpl) AssertSpanCount(expected int)
func (t *FakeTracerImpl) AssertTraceID propagated
```

### 8.5 FakeClock

```go
type FakeClock struct{ /* ... */ }

func (c *FakeClock) Now() time.Time
func (c *FakeClock) Advance(d time.Duration)
func (c *FakeClock) Set(t time.Time)
```

### 8.6 ~~FakeExporterImpl~~（已撤销）

> 本节原定义的 `FakeExporterImpl` 在运行时未实现，已删除。参见 §8.1 的撤销说明。遥测断言改用 `FakeLoggerImpl.AssertLogged` / `FakeMeterImpl.AssertCounterValue` / `FakeTracerImpl.AssertSpanCount`。

### 8.7 辅助函数

```go
func Eventually(t *testing.T, fn func() bool, timeout, interval time.Duration)
func GoldenUpdate() bool // 环境变量 GOLDEN_UPDATE=1 时更新 golden 文件
```

### 8.8 边界扫描

```go
// BoundaryCheck 检查生产包是否依赖 testkitx
func BoundaryCheck(t *testing.T, module string)

// GoroutineLeakCheck 检查测试结束后是否有 goroutine 泄漏
func GoroutineLeakCheck(t *testing.T)
```

---

## 9. 数据模型

### 9.1 公共错误

```go
var (
    ErrBoundaryViolation = errors.New("testkitx: production dependency on testkitx")
    ErrGoroutineLeak     = errors.New("testkitx: goroutine leak detected")
    ErrGoldenMismatch    = errors.New("testkitx: golden file mismatch")
)
```

---

## 10. 配置模式

testkitx 不读取配置。行为通过环境变量控制：

```bash
GOLDEN_UPDATE=1    # 更新 golden 文件
```

---

## 11. 错误处理

| 错误                   | 调用方处理                      |
| ---------------------- | ------------------------------- |
| `ErrBoundaryViolation` | 移除生产代码对 testkitx 的依赖  |
| `ErrGoroutineLeak`     | 检查测试中的 goroutine 清理逻辑 |
| `ErrGoldenMismatch`    | 更新 golden 文件或修复代码输出  |

**错误消息格式：** `"testkitx: <operation>: <detail>"`

---

## 12. 边界情况

| 场景                        | 预期行为                              |
| --------------------------- | ------------------------------------- |
| FakeConfig 的 values 为 nil | 所有 Get 返回 nil                     |
| FakeLogger 并发写入         | 无 data race（-race 测试通过）        |
| FakeClock 未 Advance        | Now() 始终返回初始时间                |
| Eventually timeout = 0      | 立即检查一次，不等待                  |
| BoundaryCheck 检查自身      | 通过（testkitx 自身依赖自己不算违规） |
| GoldenUpdate 在 CI 中设置   | CI Gate 阻止（golden update guard）   |

---

## 13. 目录结构

```
testkitx/                              # 运行时仓库 github.com/ZoneCNH/testkitx
├── go.mod                             # module github.com/ZoneCNH/testkitx, go 1.23
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── Dockerfile, docker-compose.yml
├── .golangci.yml, .repo-contract.yaml
│
├── pkg/testkitx/                      # 主包：L1 测试 helper
│   ├── doc.go                         # 包文档
│   ├── client.go                      # Client + New(ctx,cfg,opts) / Close —— 测试编排入口
│   ├── config.go                      # Config / SanitizedConfig + Validate / Sanitize
│   ├── errors.go                      # ErrorKind / Error / NewError / WrapError / IsKind
│   ├── health.go                      # HealthStatus + (*Client).HealthCheck
│   ├── metrics.go                     # Metrics 接口 + NoopMetrics
│   ├── options.go                     # Option 函数式选项
│   ├── eventually.go                  # Eventually（FR-007）
│   └── version.go                     # ModuleName / Version 常量
│
├── pkg/testkitx/fake/                 # ★ Fake 实现（FR-001~006）—— 注意：子包，非顶层文件
│   ├── config.go                      # FakeConfig(values) Reader        —— FR-001
│   ├── logger.go                      # FakeLogger() *FakeLoggerImpl     —— FR-002
│   ├── meter.go                       # FakeMeter() *FakeMeterImpl       —— FR-003
│   ├── tracer.go                      # FakeTracer() *FakeTracerImpl     —— FR-004
│   ├── clock.go                       # Clock(at) *FakeClock              —— FR-005（构造函数名 Clock）
│   ├── breaker.go                     # FakeBreaker(initial) Breaker      —— FR-006
│   ├── contract_test.go               # fake 接口 contract test（见 §15.3）
│   └── *_test.go                      # 各 fake 单元测试
│
├── pkg/testkitx/golden/               # ★ FR-008 GoldenUpdate（注意：子包）
│   └── golden.go                      # GoldenUpdate() / Assert / AssertBytes / CheckBytes / AssertJSON / WriteGolden
│
├── pkg/testkitx/boundarytest/         # ★ FR-009 BoundaryCheck（注意：子包）
│   └── boundarytest.go                # BoundaryCheck(tt, module) / Scan / ScanProductionImports / Violation
│
├── pkg/testkitx/leaktest/             # ★ FR-010 GoroutineLeakCheck（注意：子包）
│   ├── leak_checker.go                # CheckLeak(t, ignorePatterns...) / IgnoreGoroutines
│   └── leaktest.go                    # GoroutineLeakCheck(tt) / Capture / Snapshot / RequireNoLeak
│
├── pkg/testkitx/fixture/              # fixture loader（goal 遗产，非 FR 主线）
├── pkg/testkitx/contract/             # fake 内部 contract hash helper（hash.go 等）
├── pkg/testkitx/manifesttest/         # manifest 测试辅助
├── pkg/testkitx/repotest/             # 仓库结构测试辅助
├── pkg/testkitx/obstest/              # 可观测 recorder
├── pkg/testkitx/harness/              # 命令运行 harness
├── pkg/testkitx/clocktest/            # 另一个 clock helper（与 fake/clock.go 并存）
├── pkg/testkitx/assertx/              # 泛型断言 Equal/NoError/Eventually/Contains
│
├── testkit/                           # 便利薄封装包（package testkit）
│
├── contract/                          # ⚠️ L2 provider 行为契约套件（非 fake 接口 contract test）
│   ├── common/                        # 通用契约：config/error/factory/lifecycle/observability/resilience/secret
│   ├── kv/  sql/  pubsub/             # provider Run* runner
│   ├── eventlog/  objectstore/
│   ├── columnstore/  timeseries/
│   └── provider_guard_test.go         # 验证 capability runner 不引入 provider 特定 import
│
├── contracts/                         # JSON schema（config/error/health/docker-toolchain/...）
├── requirex/                          # 断言原语（TestingT / Equal / NoError / Eventually / NoGoroutineLeak）
├── servicex/                          # 服务生命周期（Service / Compose / WaitUntil）—— goal 遗产
├── evidence/                          # 证据结构（Report/Case/Check/Marshal）—— goal 遗产
├── examples/                          # basic/ config/ health/ 示例
├── testdata/                          # fixtures/ 等测试数据
├── release/                           # docker/ + manifest/（latest.json + sha256）
└── docs/                              # adr/ + l2/
```

**关键说明：**

1. **运行时无顶层 `.go` 文件**；所有代码在 `pkg/testkitx/` 子包或根级独立包（`requirex`/`servicex`/`evidence`/`testkit`/`contract`/`contracts`）。
2. **Fake 实现在 `pkg/testkitx/fake/` 子包**（非 SPEC 早期版本的顶层 `fake_*.go`）。构造函数的命名遵循运行时实际：`Clock(at)` 不带 `Fake` 前缀，其余带。
3. **`contract/`（顶层，非 pkg）是 L2 provider 行为契约套件**，导出 `Run*` runner（如 `kv.RunBasic`、`sql.RunPool`），与 §15.3 的 **fake 接口 contract test**（位于 `pkg/testkitx/fake/contract_test.go`）是两回事，勿混淆。
4. **`FakeExporter` 未实现**（§8.1 已撤销）；遥测断言由 fake logger/meter/tracer 承接。
5. **`requirex`/`servicex`/`evidence`/`contract`(L2)/`contracts`(schema) 属 goal.md 宽平台遗产**，SPEC 仅描述 testkitx 窄定位（FR-001~010），这些包的存在不构成 SPEC 追溯对象，定位见 goal.md 定位声明。

---

## 14. 依赖

### 14.1 go.mod

```
module github.com/ZoneCNH/testkitx

go 1.23
```

### 14.2 依赖方向

| 可以依赖           | 禁止依赖       |
| ------------------ | -------------- |
| kernel（L0 原语）  | 所有业务域实现 |
| configx（test）    |                |
| observex（test）   |                |
| resiliencx（test） |                |
| schedulex（test）  |                |
| stdlib             |                |

### 14.3 特殊说明

testkitx 是唯一允许依赖所有 Foundation L1 模块的包，但仅在 `go test` 中使用。生产 import graph 中不能出现 testkitx。

### 14.4 循环依赖破环策略

testkitx 依赖 kernel/configx/observex/resiliencx/schedulex（§14.2），而这些 L1 模块的测试又依赖 testkitx（§5），构成潜在环。Go 对**编译期 import 环**零容忍，因此破环策略如下：

| 手段 | 适用场景 | 说明 |
| --- | --- | --- |
| **test-only 依赖不进编译图** | L1 模块在 `*_test.go` 或 `internal/` 下引用 testkitx | `go build` 不编译 `*_test.go`，生产 import graph 不含 testkitx，BR-005 / `no-production-import` gate 自动成立 |
| **separate test module** | 若 L1 模块的 test 依赖必须出现在 `go.mod` | 用独立 `go.mod`（如 `<module>_test`）隔离 test 依赖，主 module 的 `go.mod` 不出现 testkitx |
| **interface mirror，不反向 import** | fake 实现需要镜像 L1 接口签名 | fake 包**自己定义等价接口**（如 `fake.Reader` / `fake.Logger`），不 import L1 的具体类型，避免编译期环 |
| **CI gate 双向校验** | 防止误入环 | `no-production-import`（testkitx 不进生产图）+ `go mod graph` 无 cycle + `go vet` 无 import cycle 报错 |

当前运行时实现采用「test-only 依赖不进编译图 + interface mirror」组合：`pkg/testkitx/fake/` 自定义 `Reader`/`Logger`/`Meter`/`Tracer`/`Breaker` 接口，不直接 import L1 具体类型，从根上避免环。

---

## 15. 测试

### 15.1 单元测试

| 测试场景            | 验证点                                           |
| ------------------- | ------------------------------------------------ |
| FakeLogger 断言     | `AssertLogged` / `AssertNoErrors`                |
| FakeMeter 断言      | `AssertCounterValue` / `AssertHistogramRecorded` |
| FakeTracer 断言     | span count / trace_id 传播                       |
| FakeClock 确定性    | `Advance` 不调用 `time.Now`                      |
| FakeConfig 类型安全 | `GetString` / `GetInt` / `GetBool`               |
| Eventually 收敛     | 条件满足 → 不超时                                |
| Eventually 超时     | 条件不满足 → 测试失败                            |
| Golden 文件更新     | `GOLDEN_UPDATE=1` → 更新文件                     |
| BoundaryCheck       | 生产包不依赖 testkitx                            |
| GoroutineLeakCheck  | 测试结束后无 goroutine 泄漏                      |

### 15.2 编译期检查

| 场景                 | 验证点                                               |
| -------------------- | ---------------------------------------------------- |
| FakeLogger 接口实现  | `var _ observex.Logger = (*FakeLoggerImpl)(nil)`     |
| FakeMeter 接口实现   | `var _ observex.Meter = (*FakeMeterImpl)(nil)`       |
| FakeTracer 接口实现  | `var _ observex.Tracer = (*FakeTracerImpl)(nil)`     |
| FakeConfig 接口实现  | `var _ configx.Reader = (*FakeConfigImpl)(nil)`      |
| FakeBreaker 接口实现 | `var _ resiliencx.Breaker = (*FakeBreakerImpl)(nil)` |

### 15.3 Contract 测试

> 位置：`pkg/testkitx/fake/contract_test.go`（package `fake`）。注意运行时测试名统一带 `Fake` 前缀，与早期 SPEC 版本不同。此处的 contract test 指 **fake 接口契约**，与顶层 `contract/` 目录的 **L2 provider 行为契约套件**（§13）无关。

| Contract（运行时实际测试名）          | 验证内容                                     |
| ------------------------------------- | -------------------------------------------- |
| `TestContract_FakeMeter_Interface`    | FakeMeter 实现 observex.Meter 所有方法       |
| `TestContract_FakeTracer_Interface`   | FakeTracer 实现 observex.Tracer 所有方法     |
| `TestContract_FakeConfig_Reader`      | FakeConfig 实现 configx.Reader 所有方法      |
| `TestContract_FakeBreaker_Interface`  | FakeBreaker 实现 resiliencx.Breaker 所有方法 |
| `TestContract_FakeLogger_Concurrent`  | FakeLogger 并发安全（-race 通过）            |
| `TestContract_FakeConfig_Fingerprint` | FakeConfig fingerprint 稳定性                |

### 15.4 Given/When/Then 用例

**TC-001: FakeConfig 类型安全**
Given FakeConfig 设置 `symbol=BTCUSDT`
When 调用 GetString("symbol")
Then 返回 BTCUSDT 且类型断言成功

**TC-002: FakeLogger 编译期检查**
Given FakeLogger 实现 observex.Logger
When 编译 contract test
Then 接口断言通过

**TC-003: FakeMeter 编译期检查**
Given FakeMeter 实现 observex.Meter
When 编译 contract test
Then 接口断言通过

**TC-004: FakeTracer 编译期检查**
Given FakeTracer 实现 observex.Tracer
When 编译 contract test
Then 接口断言通过

**TC-005: FakeClock 确定性**
Given FakeClock 初始时间固定
When Advance(1s)
Then Now 返回初始时间加 1s

**TC-006: FakeBreaker 编译期检查**
Given FakeBreaker 实现 resiliencx.Breaker
When 编译 contract test
Then 接口断言通过

**TC-007: Eventually 收敛**
Given 条件在 3 次轮询后满足
When 调用 Eventually
Then Eventually 在超时前返回成功

**TC-008: GoldenUpdate**
Given GOLDEN_UPDATE=1
When golden 内容变化
Then golden 文件被更新

**TC-009: BoundaryCheck**
Given 生产包 import testkitx
When 运行 BoundaryCheck
Then 返回边界违规

**TC-010: GoroutineLeakCheck**
Given 测试后仍有新增 goroutine
When 运行 GoroutineLeakCheck
Then 报告泄漏并失败

### 15.5 Benchmark

| 场景        | 目标   |
| ----------- | ------ |
| fake 初始化 | < 1ms  |

---

## 16. 性能预算

| 操作        | 目标   | 测量方式                   |
| ----------- | ------ | -------------------------- |
| fake 初始化 | < 1ms  | benchmark test             |
| 常驻内存    | 不限   | 仅测试环境，不计入生产预算 |

---

## 17. 可观测性

testkitx 不 emit 生产可观测数据。它提供 fake logger / meter / tracer，用于在测试中断言被测模块的遥测输出（无独立的 FakeExporter，参见 §8.1 撤销说明）：

```go
logger, _ := testkitx.FakeLogger()   // 或 fake 子包构造
meter := testkitx.FakeMeter()
tracer := testkitx.FakeTracer()
// 测试中可以断言：
meter.AssertCounterValue("resiliencx.retry.attempts", 3)
logger.AssertLogged(observex.LevelError, "kernel.module.start_failed")
tracer.AssertSpanCount(3)
```

---

## 18. 安全

| 要求                     | 实现方式                                |
| ------------------------ | --------------------------------------- |
| 不进入生产二进制         | `go list` 验证生产依赖图不包含 testkitx |
| golden 文件不泄露 secret | golden 更新时自动检查 secret 模式       |

---

## 19. CI 门禁

### 19.1 通用 Gate

| Gate        | 命令                                                                                                               | 阻塞条件                 |
| ----------- | ------------------------------------------------------------------------------------------------------------------ | ------------------------ |
| 编译        | `go build ./...`                                                                                                   | 编译失败                 |
| 测试        | `go test ./... -race -count=1`                                                                                     | 任何测试失败或 data race |
| 覆盖率      | `mkdir -p .coverage && go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | 总覆盖率 < 80%           |
| vet         | `go vet ./...`                                                                                                     | 任何 vet 错误            |
| lint        | `golangci-lint run`                                                                                                | 任何 lint 错误           |
| 依赖检查    | `go mod tidy && git diff --exit-code go.mod go.sum`                                                                | go.mod 不整洁            |
| Secret 扫描 | `gitleaks detect --no-git`                                                                                         | 泄露 secret              |
| Benchmark   | `go test -bench=. -benchmem -count=3 ./...`                                                                        | 结果附在 PR comment      |

### 19.2 testkitx 专属 Gate

| Gate                 | 命令                                                     | 阻塞条件                |                     |
| -------------------- | -------------------------------------------------------- | ----------------------- |                     |
| no-production-import | `go list -deps github.com/ZoneCNH/x.go/... 2>/dev/null \ | grep testkitx`          | 生产包依赖 testkitx |
| contract tests       | `go test ./contract/... -race -count=1`                  | 任何 contract test 失败 |                     |
| golden update guard  | 检查 `GOLDEN_UPDATE` 不在 CI 中设置                      | CI 中误更新 golden 文件 |                     |

---

## 20. 升级兼容性

| 变更类型          | 版本升级                                    |
| ----------------- | ------------------------------------------- |
| Fake 接口行为变更 | **major**（所有使用 fake 的测试需同步更新） |
| 新增 fake 类型    | minor                                       |
| 新增 helper 函数  | patch / minor                               |
| 修复 bug          | **patch**                                   |

---

## 21. 发布 DoD

- [ ] 所有公共接口有 godoc 注释
- [ ] 所有公共类型有示例代码
- [ ] CHANGELOG.md 已更新
- [ ] README.md 包含：模块定位、快速开始、API 概览
- [ ] 单元测试覆盖率 ≥ 80%
- [ ] `-race` 测试通过
- [ ] Benchmark 结果无 > 10% 回退
- [ ] `go vet` 无警告
- [ ] `golangci-lint` 无错误
- [ ] 所有 contract test 通过
- [ ] no-production-import 检查通过
- [ ] Go baseline 与 Foundation 其他模块对齐（1.23）
- [ ] Secret 扫描通过
- [ ] 公共 API 无破坏性变更（或已 bump major）
- [ ] 所有 Functional Requirements 有对应测试
- [ ] 所有 Edge Cases 有对应测试

---

## 22. 待解决问题


### Non-blocking

| ID | 问题 | 状态 |
| --- | --- | --- |
| OQ-001 | 是否需要支持自定义 fake 行为（如 FakeLogger 的 level 过滤模拟）？ | 待评估 |
| OQ-002 | fixture loader 是否需要支持 YAML/TOML 格式（当前仅 JSON/golden）？ | 待评估 |
| OQ-003 | contract test 是否需要覆盖 schedulex.Scheduler 接口？ | 待评估 |
| OQ-004 | BoundaryCheck 是否需要支持白名单（允许特定测试包依赖 testkitx）？ | 待评估 |


## 23. 版本记录

| 日期       | 版本   | 变更内容   | 作者    |
| ---------- | ------ | ---------- | ------- |
| 2026-06-07 | v1.0.0 | 初始版本   | ZoneCNH |
