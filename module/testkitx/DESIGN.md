# testkitx 设计方案

> Design ID: DESIGN-testkitx-v1
> Source Spec: [SPEC.md](./SPEC.md) v1.1.0
> Source Goal: [goal.md](./goal.md) 1.0 发布基线（范围收窄：L0 测试期证据 / 单进程 `go test` 工具）
> 生成日期：2026-06-29
> 状态：已发布（对齐运行时仓库 `/home/testkitx`）

## 1. 架构概述

`testkitx` 是测试期证据层工具库，为 xlib 各模块提供统一的 fake 实现、fixture 加载、golden 测试、contract 测试、边界扫描和 goroutine leak 检测。禁止进入生产依赖图。

### 1.1 设计原则

1. **生产隔离**：所有代码使用 `_test.go` 或 `testbuild` tag，CI Gate `no-production-import` 强制执行。
2. **接口镜像**：fake 类型只镜像 L1 基础设施接口（`kernel.obsx` 的 Logger/Metrics/Tracer，`configx.Reader` 等），不做业务抽象。
3. **确定性**：fake 实现不依赖 `time.Now()` 或 `math.Rand()`，测试结果可复现。
4. **窄范围**：仅覆盖 L0 测试期证据——`go test` 进程内生成 golden/contract/boundary/leak 证据。证据收集/汇总/发布由 `xlib_evidence` 在 CI pipeline 中负责。
5. **单进程**：不启动外部依赖（Redis/Kafka/NATS），fake 类型全部在内存中运行。

### 1.2 与 goal.md 的版本映射

| 能力 | goal.md 原始定位 | 处置 |
|------|----------------|------|
| Fake 实现（FakeConfig/Logger/Meter/Tracer/Clock/Breaker） | testkitx L0 范围 | ✅ testkitx 实现 |
| Fixture loader + Golden helper | testkitx L0 范围 | ✅ testkitx 实现 |
| Contract test harness | testkitx L0 范围 | ✅ testkitx 实现 |
| Boundary scanner（生产 import 检查） | testkitx L0 范围 | ✅ testkitx 实现 |
| Goroutine leak checker | testkitx L0 范围 | ✅ testkitx 实现 |
| 容器化集成测试环境（Redis/Kafka/...） | 原 goal.md 宽平台 | ➡️ 迁移至 `xlib_harness` |
| FaultInjector 故障注入 | 原 goal.md 宽平台 | ➡️ 迁移至 `xlib_harness` |
| 证据收集、验证、发布为统一报告 | 原 goal.md 宽平台 | ➡️ 归属 `xlib_evidence` |

## 2. 核心组件设计

### 2.1 FakeConfig — 测试配置

```
FakeConfig(values map[string]any) → (configx.Reader, *FakeConfigImpl)
```

- 内存中存储，`Get(key)` 返回对应值
- 实现 `configx.Reader` 接口
- 确定性：不读文件/环境变量

### 2.2 FakeLogger — 测试日志

```
FakeLogger() → (*FakeLoggerImpl, observex.Logger)
```

- 捕获所有日志条目到内存
- 提供 `AssertLogged(level, contains)` / `AssertNoErrors()` / `Entries()` 断言
- 实现 `observex.Logger` 接口

### 2.3 FakeMeter — 测试指标

```
FakeMeter() → (*FakeMeterImpl, observex.Meter)
```

- 内存中记录 Counter/Gauge/Histogram
- 提供 `AssertCounterValue(name, expected)` / `AssertHistogramRecorded(name)` 断言
- 实现 `observex.Meter` 接口

### 2.4 FakeTracer — 测试追踪

```
FakeTracer() → (*FakeTracerImpl, observex.Tracer)
```

- 内存中记录 Span
- 提供 `AssertSpanCount(expected)` / `Spans()` 断言
- 实现 `observex.Tracer` 接口

### 2.5 FakeClock — 测试时钟

```
FakeClock(now time.Time) → *FakeClockImpl
```

- 可控时间推进：`Advance(d)` / `Set(t)`
- 实现 `kernel.Clock` 接口（来自 `kernel/timex`）
- 确定性：不会自动前进

### 2.6 FakeBreaker — 测试熔断器

```
FakeBreaker() → (*FakeBreakerImpl, resiliencx.Breaker)
```

- 手动控制 Open/Closed/HalfOpen 状态
- 提供 `SetState(s)` / `FailCount()` / `ResetCount()`
- 用于测试弹性策略集成行为

### 2.7 Fixture Loader

```
LoadFixture(t, path, target) error
LoadFixtureWithHook(t, path, target, hook) error
```

- 从 `testdata/` 加载 JSON/YAML fixture
- 可选 hook 用于动态字段注入（时间戳、ID 等）

### 2.8 Golden Helper

```
GoldenFile(t, name, content)
GoldenUpdate(t, name, content)
GoldenAssert(t, name, content)
```

- `GoldenFile`：写入 golden file
- `GoldenUpdate`：强制更新（`-update` flag）
- `GoldenAssert`：对比 golden file

### 2.9 Contract Test Harness

```
ContractTest[Interface any](t, name string, impl Interface, assertions ...ContractAssertion)
```

- 编译期接口检查：`var _ Interface = (*FakeImpl)(nil)`
- 验证 fake 实现与真实接口的契约一致性
- golden file 记录 contract test 结果

### 2.10 Production Import Boundary Scanner

```
CheckNoProductionImport(t, allowedPackages ...string)
```

- 扫描 `go build -tags production` 依赖图
- 检测生产二进制是否意外 import testkitx
- CI Gate 集成

### 2.11 Goroutine Leak Checker

```
LeakCheck(t) func()
```

- `go.uber.org/goleak` 包装
- 在 test cleanup 中检测泄漏

## 3. 内部依赖图

```
testkitx/
├── fake_config.go     → depends on configx.Reader
├── fake_logger.go     → depends on observex.Logger
├── fake_meter.go      → depends on observex.Meter
├── fake_tracer.go     → depends on observex.Tracer
├── fake_clock.go      → depends on kernel/timex.Clock
├── fake_breaker.go    → depends on resiliencx.Breaker
├── fixture.go         → stdlib only
├── golden.go          → stdlib only
├── contract.go        → stdlib + testing
├── boundary.go        → stdlib + go/build
├── leakcheck.go       → go.uber.org/goleak
└── doc.go             → package doc
```

- 所有依赖方向向内：testkitx → L1 接口（configx/observex/resiliencx），不反向
- fake 实现只依赖接口签名，不依赖具体实现

## 4. 关键架构决策（ADR）

### ADR-001: 窄范围 vs 宽平台

**决策**：testkitx 定位为 L0 测试期证据工具，集成测试环境、故障注入、证据发布能力分别迁移到独立模块。

**理由**：宽平台导致 testkitx 承担过多职责，与其他模块边界模糊；测试期证据与 CI/发布期证据是不同生命周期阶段；分离后每个模块可独立演进、独立版本。

### ADR-002: Fake 使用接口而非具体类型

**决策**：所有 fake 实现 L1 接口（如 `observex.Logger`），而非返回具体类型指针。断言方法通过返回的 `*FakeLoggerImpl` 暴露。

**理由**：消费者注入 fake 后代码与生产代码一致；断言能力不污染接口；编译期接口检查保证 fake 与真实实现的契约一致性。

### ADR-003: 确定性 fake

**决策**：fake 类型禁止调用 `time.Now()` 或 `math.Rand()`。

**理由**：测试必须可复现；FakeClock 提供显式时间控制；不确定的 fake 会导致 flaky test。

### ADR-004: Golden 文件使用 `-update` flag

**决策**：golden file 更新通过 `go test -update` flag 控制，默认只读对比。

**理由**：防止 CI 中意外覆盖 golden file；开发者显式 `-update` 更新预期值；避免 golden file 漂移。

## 5. 依赖关系

| 方向 | 模块 | 关系 |
|------|------|------|
| 消费 | configx | 使用 configx.Reader 接口定义 FakeConfig |
| 消费 | observex | 使用 observex.Logger/Meter/Tracer 接口定义 Fake |
| 消费 | kernel | 使用 kernel/timex.Clock 接口定义 FakeClock |
| 消费 | resiliencx | 使用 resiliencx.Breaker 接口定义 FakeBreaker |
| 被消费 | 所有模块测试 | 在 `_test.go` 中使用 fake 和 fixture 工具 |

## 6. 技术风险

| 风险 | 影响 | 缓解 |
|------|------|------|
| Fake 与真实实现偏差 | contract test 误通过 | 编译期接口检查 + contract test harness |
| 生产二进制误 import | 二进制膨胀 | CI Gate `no-production-import` + boundary scanner |
| Golden file 漂移 | CI 频繁失败 | `-update` flag 显式控制 + code review |
| Goroutine leak 积累 | 测试相互干扰 | leak checker + CI 集成 |

## 7. 设计约束

- **build tag**：所有文件使用 `//go:build testbuild` 或置于 `_test.go`
- **zero-allocation**：fake 实现零堆分配（除日志/span 捕获）
- **stdlib-only**：依赖链不引入第三方包（`goleak` 除外，仅在 test 依赖中）
- **不持久化**：fake 不写磁盘（golden file 通过 helper 显式管理）

## 8. Mock 策略

### 8.1 单元测试

- Fake 类型自测使用 table-driven test
- `contracttest` 验证接口实现完整性
- Golden file 验证 fake 行为一致性

### 8.2 集成测试

- testkitx 本身不需要集成测试（fake 全内存运行）
- 消费者的集成测试由 `xlib_harness` 在 CI 管线中协调

## 9. 可扩展性与演进

### 9.1 已知扩展路径

- 更多 fake 类型（如 FakeLocker for schedulex）
- fixture loader 支持更多格式（TOML/CSV）
- contract test 支持更多断言模式

### 9.2 设计不阻塞的演进方向

- xlib_evidence 的测试期证据收集适配器
- CI pipeline 的证据聚合与发布
