# testkitx

## 1. 模块定位
testkitx 是 FoundationX 测试基础设施（L0 测试期证据），提供 fake 实现、fixture 加载、golden 测试、contract 测试、boundary 扫描、goroutine leak 检测等工具，帮助各模块稳定验证边界、错误路径和集成行为。**禁止进入生产依赖图**（BR-005 + CI Gate no-production-import 强制）。窄定位：仅单进程 `go test` 工具；宽测试平台（集成环境、故障注入、发布期证据包）由 xlib-evidence 承接。

## 2. 生产职责
- FR-001 FakeConfig：内存配置源，实现 configx.Reader
- FR-002 FakeLogger：记录日志到内存，AssertLogged / AssertNoErrors / Entries
- FR-003 FakeMeter：记录 metrics 到内存，AssertCounterValue / AssertHistogramRecorded
- FR-004 FakeTracer：记录 spans 到内存，AssertSpanCount / AssertTraceID
- FR-005 FakeClock：可控制时间的时钟，Now / Advance / Set
- FR-006 FakeBreaker：可控制熔断状态，实现 resiliencx.Breaker
- FR-007 Eventually：轮询条件直到满足或超时
- FR-008 GoldenUpdate：GOLDEN_UPDATE=1 环境变量控制 golden file 更新
- FR-009 BoundaryCheck：生产包 import 边界扫描
- FR-010 GoroutineLeakCheck：测试结束后 goroutine 泄漏检测

## 3. 边界定义
- BR-001：所有 fake 必须实现对应接口，编译期检查 `var _ Interface = (*FakeImpl)(nil)`
- BR-002：fake 行为必须确定性，不引入 time.Now() 或 math.Rand()
- BR-003：Eventually 使用 testing.T 而非 panic，失败时输出清晰诊断
- BR-004：GoldenUpdate() 只在 GOLDEN_UPDATE=1 时返回 true
- BR-005：生产 import graph 中不能出现 testkitx（go list 验证）
- BR-006：testkitx 是唯一允许依赖所有 Foundation L1 模块的包（仅 go test）
- BR-007：golden 文件不泄露 secret

## 4. 不负责什么
- 不进入生产二进制或生产依赖图
- 不定义交易、行情、风控、订单、仓位等业务域模型（业务模型由 contracts 和业务域负责，fake 只镜像 L1 接口）
- 不承担各模块领域 fixture 集中维护（领域 fixture 由各模块自身 testdata/ 维护）
- 不替代集成测试 L2、系统测试 L3、混沌工程和长稳测试（由 xlib-harness / xlibgate 协调）
- 不做证据收集、汇总或发布（属于 xlib-evidence）

## 5. 架构位置
L0 测试期证据层（SPEC 标注「基座 · 测试期证据」/ FEATURES 标注 L0 测试工具）。可依赖 kernel、configx、observex、resiliencx、schedulex（全部仅 test）；禁止依赖所有业务域实现。是唯一允许依赖所有 Foundation L1 模块的包。消费者：kernel / configx / observex / resiliencx / schedulex 测试 + 业务域模块测试。

## 6. 生命周期
testkitx 无运行时生命周期（仅 `go test` 进程内使用）。fake 实例由测试函数创建并在测试结束随 GC 回收。BoundaryCheck 在测试启动时扫描生产 import graph；GoroutineLeakCheck 在测试结束后比对 goroutine 快照；GoldenUpdate 由环境变量在测试运行时决定写或比对。

## 7. 标准目录结构
```text
testkitx/                            # github.com/ZoneCNH/testkitx
├── pkg/testkitx/                    # 主包：client/config/errors/health/metrics/options/eventually
├── pkg/testkitx/fake/               # FR-001~006：config/logger/meter/tracer/clock/breaker
├── pkg/testkitx/golden/             # FR-008 GoldenUpdate / Assert / AssertJSON / WriteGolden
├── pkg/testkitx/boundarytest/       # FR-009 BoundaryCheck / Scan / ScanProductionImports
├── pkg/testkitx/leaktest/           # FR-010 GoroutineLeakCheck / CheckLeak / Snapshot
├── pkg/testkitx/{fixture,contract,manifesttest,repotest,obstest,harness,clocktest,assertx}
├── testkit/ / requirex/ / servicex/ / evidence/  # 便利封装与 goal 遗产
├── contract/                        # L2 provider 行为契约套件（kv/sql/pubsub/...）
├── contracts/                       # JSON schema
├── examples/ / testdata/ / release/ / docs/
```

## 8. 配置规范
testkitx 不读取配置。行为通过环境变量控制：`GOLDEN_UPDATE=1` 更新 golden 文件（未设置则比对模式）。fake 行为通过构造函数参数注入（FakeConfig(values map[string]any)、Clock(at time.Time)、FakeBreaker(initial BreakerState)），不依赖任何外部配置源。

## 9. 错误模型
sentinel errors：`ErrBoundaryViolation`（生产依赖 testkitx）、`ErrGoroutineLeak`（检测到 goroutine 泄漏）、`ErrGoldenMismatch`（golden 文件比对不匹配）。错误消息格式 `"testkitx: <operation>: <detail>"`。fake 实现自身的断言失败通过 testing.T.Errorf 输出诊断（BR-003 不用 panic），调用方根据错误类型决定移除生产依赖 / 清理 goroutine / 更新 golden。

## 10. 日志规范
testkitx 不 emit 生产日志。FakeLogger（`pkg/testkitx/fake/logger.go`）实现 observex.Logger，将 Debug/Info/Warn/Error 调用记录到内存 []LogEntry，测试通过 AssertLogged(level, contains)、AssertNoErrors()、Entries() 断言被测模块的日志输出。编译期接口检查：`var _ observex.Logger = (*FakeLoggerImpl)(nil)`（BR-001）。

## 11. Metrics
testkitx 不 emit 生产 metrics。FakeMeter（`pkg/testkitx/fake/meter.go`）实现 observex.Meter，将 Counter.Add / Histogram.Record / Gauge.Set 记录到内存，测试通过 AssertCounterValue(name, expected)、AssertHistogramRecorded(name) 断言被测模块的指标输出。编译期接口检查：`var _ observex.Meter = (*FakeMeterImpl)(nil)`（BR-001）。

## 12. Tracing
testkitx 不 emit 生产 trace。FakeTracer（`pkg/testkitx/fake/tracer.go`）实现 observex.Tracer，将 span 创建/结束记录到内存，测试通过 AssertSpanCount(expected)、AssertTraceID 断言 trace_id 已传播。编译期接口检查：`var _ observex.Tracer = (*FakeTracerImpl)(nil)`（BR-001）。注：FakeExporter 在运行时未实现（已撤销），遥测断言由 fake logger/meter/tracer 承接。

## 13. Reliability
testkitx 本身不提供韧性原语（那属 resiliencx），但其工具支持韧性测试：
- FakeClock：控制 resiliencx timeout/retry 的时间推进，不依赖真实时间（BR-002 确定性）
- FakeBreaker：模拟 resiliencx.Breaker 三态，控制熔断触发与恢复
- Eventually：轮询条件直到满足或超时，用于异步韧性场景断言（BR-003 失败输出诊断）
- GoroutineLeakCheck：验证 resiliencx 策略组合不泄漏 goroutine

## 14. Security
- 不进入生产二进制：`go list` 验证生产依赖图不包含 testkitx（BR-005 / NFR-004）
- golden 文件不泄露 secret：更新时自动检查 secret 模式（BR-007 / NFR-005），gitleaks 扫描通过
- fake 不引入 time.Now() / math.Rand()（BR-002 测试确定性）
- 循环依赖破环：fake 包自定义等价接口（fake.Reader/Logger/Meter/Tracer/Breaker），不反向 import L1 具体类型

## 15. Performance SLO
| 操作 | 目标 | 测量方式 |
|------|------|----------|
| fake 初始化 | < 1ms | benchmark test |
| 常驻内存 | 不限 | 仅测试环境，不计入生产预算 |

性能非 testkitx 核心关注点；目标仅保证 fake 初始化不拖慢测试套件。

## 16. 测试标准
- 单元测试覆盖率 ≥ 80%（NFR-002，实测 92.6%）
- -race 测试零 data race（NFR-003，FakeLogger 并发写入无竞争）
- contract test：`TestContract_Fake{Meter,Tracer,Config,Breaker,Logger}_*` 编译期接口检查（位置 `pkg/testkitx/fake/contract_test.go`）
- TC-001~010 覆盖 FakeConfig/Logger/Meter/Tracer/Clock/Breaker/Eventually/GoldenUpdate/BoundaryCheck/GoroutineLeakCheck
- Benchmark：fake 初始化 < 1ms

## 17. Chaos
testkitx 不直接做 chaos 注入（属 xlib-harness），但提供 chaos 测试支撑工具：
- GoroutineLeakCheck（FR-010）：测试后检测 goroutine 泄漏，报告堆栈
- BoundaryCheck（FR-009）：检测生产包意外依赖 testkitx
- FakeClock：注入可控时间，模拟超时/延迟场景
- FakeBreaker：注入熔断状态，模拟故障级联
- Eventually：异步 chaos 场景的条件轮询断言

## 18. Contract
Fake 构造函数（子包 `testkitx/fake`）：`FakeConfig(values) Reader` / `FakeLogger() *FakeLoggerImpl` / `FakeMeter() *FakeMeterImpl` / `FakeTracer() *FakeTracerImpl` / `Clock(at) *FakeClock`（注意构造函数名 Clock 非 FakeClock）/ `FakeBreaker(initial) Breaker`。辅助：`Eventually(t, fn, timeout, interval)` / `GoldenUpdate() bool`。Boundary：`BoundaryCheck(t, module)` / `GoroutineLeakCheck(t)`。所有 fake 编译期断言实现 L1 接口。

## 19. CI Gate
通用：`go build ./...`、`go test ./... -race -count=1`、覆盖率 < 80% 阻塞、`go vet ./...`、`golangci-lint run`、`go mod tidy && git diff --exit-code`、`gitleaks detect --no-git`、Benchmark 附 PR comment。testkitx 专属：`go list -deps github.com/ZoneCNH/x.go/... | grep testkitx` 阻塞（no-production-import）、`go test ./contract/... -race -count=1`（contract tests）、CI 中 GOLDEN_UPDATE 不设置（golden update guard）。

## 20. Release Gate
DoD 清单：公共接口有 godoc、CHANGELOG.md 更新、README 含定位/快速开始/API、覆盖率 ≥ 80%、-race 通过、Benchmark 无 > 10% 回退、vet/lint 零警告、所有 contract test 通过、no-production-import 检查通过、Go 1.23 baseline 对齐、Secret 扫描通过、API 无破坏性变更、所有 FR/EC 有对应测试。运行时验收已闭合（2026-06-18）：build/vet/test/race exit=0，覆盖率 92.6%，contract/golden/boundary/leak 全绿。

## 21. Versioning
semver。当前 Spec-Version v1.0.0 / Module-Version v1.0.0 / Runtime RC（factory=false 待四源评分达 98）。Fake 接口行为变更 → major（所有使用 fake 的测试需同步更新）；新增 fake 类型 → minor；新增 helper 函数 → patch/minor；bug 修复 → patch。fake 包通过 interface mirror 避免 L1 import 环，签名变更需同步 L1 接口。

## 22. 兼容性策略
- Fake 接口行为变更：major（所有使用 fake 的测试需同步更新）
- 新增 fake 类型：minor
- 新增 helper 函数：patch / minor
- 修复 bug：patch
- 边界情况 EC：FakeConfig values=nil（所有 Get 返回 nil）、FakeLogger 并发写入（-race 通过）、FakeClock 未 Advance（Now 始终返回初始时间）、Eventually timeout=0（立即检查一次）、BoundaryCheck 检查自身（通过）、GoldenUpdate 在 CI 设置（CI Gate 阻止）

## 23. Failover
testkitx 无生产 failover 职责（不进入生产图）。测试期降级：
- fake 未初始化：返回零值或 nil，不 panic
- golden 比对失败：返回 ErrGoldenMismatch，GOLDEN_UPDATE=1 可重生成
- BoundaryCheck 误报：testkitx 自身依赖自己不算违规
- GoroutineLeakCheck 误报：支持 IgnoreGoroutines / IgnorePatterns 过滤已知后台 goroutine

## 24. Backpressure
testkitx 无生产 backpressure 职责。测试期资源控制：
- GoroutineLeakCheck：检测测试未清理的 goroutine，防止测试间相互干扰
- fake 内存切片无上限（仅测试环境，不计入生产预算）
- Eventually：interval 控制轮询频率，timeout 控制总等待时长，防止测试卡死
- BoundaryCheck：扫描生产 import graph，防止 testkitx 泄漏到生产二进制

## 25. 审计要求
- 编译期接口审计：`var _ Interface = (*FakeImpl)(nil)` 确保 fake 与真实接口同步（BR-001）
- contract test 审计：TestContract_Fake_* 验证 fake 实现所有方法
- 生产边界审计：BoundaryCheck 扫描生产 import graph 报告依赖路径（FR-009）
- goroutine 审计：GoroutineLeakCheck 报告泄漏 goroutine 堆栈（FR-010）
- golden 文件审计：更新时检查 secret 泄漏（BR-007 / gitleaks CI Gate）

## 26. 熵减规则
全局 Entropy Rules + 模块特有禁项：
- 禁止 util dumping（fake/golden/boundarytest/leaktest 子包职责分离）
- 禁止 hidden abstraction（fake 编译期接口断言显式暴露契约）
- 禁止 cyclic dependency（fake 包 interface mirror 避免 L1 反向 import 环）
- 禁止 fake 引入非确定性（BR-002 禁 time.Now/math.Rand）
- 禁止 testkitx 进入生产图（BR-005）

## 27. AI Constraints
全局 AI Constraints + 模块特有约束：
- 不新增未注册 fake 类型（fake 子包固定 6 类）
- 不绕过 contracts（fake 必须编译期断言实现 L1 接口）
- 不动态扩展目录（fake/golden/boundarytest/leaktest 固定）
- 不在生产代码 import testkitx（BR-005）
- 不在 fake 中调用 time.Now() / math.Rand()（BR-002）
- 不用 panic 代替 testing.T 失败（BR-003）

## 28. Forbidden Patterns
- fake 不实现对应接口（违反 BR-001，contract test / go build 失败）
- fake 调用 time.Now() / math.Rand()（违反 BR-002，测试非确定性）
- Eventually 用 panic 代替 testing.T（违反 BR-003，无诊断信息）
- GoldenUpdate 在非 GOLDEN_UPDATE=1 时返回 true（违反 BR-004，CI 误更新）
- 生产代码 import testkitx（违反 BR-005，no-production-import gate 阻塞）
- 其他模块引入对 L1 的非 test 依赖（违反 BR-006，boundary check 阻塞）
- golden 文件泄露 secret（违反 BR-007，gitleaks gate 阻塞）
- 使用已撤销的 FakeExporter（运行时未实现）

## 29. Production Ready Checklist
- [x] observability ready（FakeLogger/FakeMeter/FakeTracer 提供测试期观测断言）
- [x] resilience ready（FakeClock/FakeBreaker 支持韧性测试，-race 零 data race）
- [x] replay ready（golden file 比对/更新可复验，contract test 固化接口契约）
- [x] audit ready（编译期接口断言 + BoundaryCheck + GoroutineLeakCheck 三重审计）
- [x] rollback ready（v1.0.0 RC，运行时验收通过）
- [x] 覆盖率 92.6%（门槛 80%）、build/vet/test/race exit=0、contract/golden/boundary/leak 全绿
- [ ] factory-grade（四源评分未达 98，机器事实层 factory=false，非阻塞项）

## 30. Roadmap
- OQ-001 评估自定义 fake 行为（如 FakeLogger 的 level 过滤模拟）
- OQ-002 评估 fixture loader 支持 YAML/TOML（当前仅 JSON/golden）
- OQ-003 评估 contract test 覆盖 schedulex.Scheduler 接口
- OQ-004 评估 BoundaryCheck 支持白名单（允许特定测试包依赖 testkitx）
- 四源评分通过后转 factory-grade
- 宽测试平台能力（集成环境、故障注入、发布期证据包）由 xlib-evidence 承接
