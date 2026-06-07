# testkitx 完整规格

> Foundation L1 test-only。fake/fixture/golden/contract/boundary 工具包。禁止生产导入。

最后更新：2026-06-07

---

## 1. 定位

`testkitx` 是测试基础设施，帮助各模块稳定验证边界、错误路径和集成行为。

### 核心职责

- fake clock / deterministic time
- fake config、logger、metrics、tracer
- fixture loader
- golden test helper
- contract test harness
- fault injection
- temporary environment
- async eventually/assert helper
- lifecycle test helper
- production import boundary scanner
- goroutine leak checker
- unified assert API
- unified fixture loader
- unified contract hash helper

### 明确不做

- 不进入生产依赖路径
- 不承载业务模型
- 不把领域 fixture 变成公共模型
- 不替代 L2/L3/chaos/soak 测试

---

## 2. 接口契约

### 2.1 Fake 实现

```go
func FakeConfig(values map[string]any) configx.Reader
func FakeLogger() (*FakeLoggerImpl, observex.Logger)
func FakeMeter() (*FakeMeterImpl, observex.Meter)
func FakeTracer() (*FakeTracerImpl, observex.Tracer)
func FakeClock(at time.Time) *FakeClock
func FakeBreaker(initial resiliencx.BreakerState) resiliencx.Breaker
func FakeExporter() *FakeExporterImpl
```

### 2.2 FakeLoggerImpl

```go
type FakeLoggerImpl struct{ /* ... */ }

func (l *FakeLoggerImpl) AssertLogged(level LogLevel, contains string)
func (l *FakeLoggerImpl) AssertNoErrors()
func (l *FakeLoggerImpl) Entries() []LogEntry
```

### 2.3 FakeMeterImpl

```go
type FakeMeterImpl struct{ /* ... */ }

func (m *FakeMeterImpl) AssertCounterValue(name string, expected float64)
func (m *FakeMeterImpl) AssertHistogramRecorded(name string)
```

### 2.4 FakeTracerImpl

```go
type FakeTracerImpl struct{ /* ... */ }

func (t *FakeTracerImpl) AssertSpanCount(expected int)
func (t *FakeTracerImpl) AssertTraceID propagated
```

### 2.5 FakeClock

```go
type FakeClock struct{ /* ... */ }

func (c *FakeClock) Now() time.Time
func (c *FakeClock) Advance(d time.Duration)
func (c *FakeClock) Set(t time.Time)
```

### 2.6 FakeExporterImpl

```go
type FakeExporterImpl struct{ /* ... */ }

func (e *FakeExporterImpl) AssertSpanCount(expected int)
func (e *FakeExporterImpl) AssertMetricRecorded(name string)
func (e *FakeExporterImpl) AssertLogContains(contains string)
```

### 2.7 辅助函数

```go
func Eventually(t *testing.T, fn func() bool, timeout, interval time.Duration)
func GoldenUpdate() bool // 环境变量 GOLDEN_UPDATE=1 时更新 golden 文件
```

### 2.8 边界扫描

```go
// BoundaryCheck 检查生产包是否依赖 testkitx
func BoundaryCheck(t *testing.T, module string)

// GoroutineLeakCheck 检查测试结束后是否有 goroutine 泄漏
func GoroutineLeakCheck(t *testing.T)
```

### 2.9 契约约束

- 所有 fake 必须实现对应接口，编译期检查：`var _ observex.Logger = (*FakeLoggerImpl)(nil)`
- fake 行为必须确定性，不引入 `time.Now()` 或 `math.Rand()`
- `Eventually` 使用 `testing.T` 而非 `panic`，失败时输出清晰诊断
- `GoldenUpdate()` 只在 `GOLDEN_UPDATE=1` 环境变量下返回 true

---

## 3. 目录结构

```
testkitx/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go
├── testkitx.go                 # 顶层导出
├── errors.go
├── fake_config.go              # FakeConfig
├── fake_logger.go              # FakeLoggerImpl
├── fake_meter.go               # FakeMeterImpl
├── fake_tracer.go              # FakeTracerImpl
├── fake_clock.go               # FakeClock
├── fake_breaker.go             # FakeBreaker
├── fake_exporter.go            # FakeExporterImpl
├── assert.go                   # 统一 assert API
├── eventually.go               # Eventually helper
├── golden.go                   # GoldenUpdate helper
├── fixture.go                  # fixture loader
├── boundary.go                 # production import boundary scanner
├── leak.go                     # goroutine leak checker
├── contract.go                 # contract test harness
├── hash.go                     # contract hash helper
├── internal/
│   └── spy/                    # spy 实现
├── contract/
│   ├── logger_test.go          # TestContract_Logger_Interface
│   ├── meter_test.go           # TestContract_Meter_Interface
│   ├── tracer_test.go          # TestContract_Tracer_Interface
│   ├── config_test.go          # TestContract_Config_Reader
│   ├── breaker_test.go         # TestContract_Breaker_Interface
│   ├── concurrent_test.go      # TestContract_Logger_Concurrent
│   ├── cardinality_test.go     # TestContract_Meter_LabelCardinality
│   └── fingerprint_test.go     # TestContract_Config_Fingerprint
├── testdata/
│   └── *.golden
├── example_test.go
└── benchmark_test.go
```

---

## 4. 依赖

### 4.1 go.mod

```
module github.com/ZoneCNH/testkitx

go 1.23
```

### 4.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| kernel（L0 原语） | 所有业务域实现 |
| configx（test） | |
| observex（test） | |
| resiliencx（test） | |
| schedulex（test） | |
| stdlib | |

### 4.3 特殊说明

testkitx 是唯一允许依赖所有 Foundation L1 模块的包，但仅在 `go test` 中使用。生产 import graph 中不能出现 testkitx。

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

### 5.2 testkitx 专属 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| no-production-import | `go list -deps github.com/ZoneCNH/x.go/... 2>/dev/null \| grep testkitx` | 生产包依赖 testkitx |
| contract tests | `go test ./contract/... -race -count=1` | 任何 contract test 失败 |
| golden update guard | 检查 `GOLDEN_UPDATE` 不在 CI 中设置 | CI 中误更新 golden 文件 |

---

## 6. 测试矩阵

### 6.1 单元测试

| 测试场景 | 验证点 |
|----------|--------|
| FakeLogger 断言 | `AssertLogged` / `AssertNoErrors` |
| FakeMeter 断言 | `AssertCounterValue` / `AssertHistogramRecorded` |
| FakeTracer 断言 | span count / trace_id 传播 |
| FakeClock 确定性 | `Advance` 不调用 `time.Now` |
| FakeConfig 类型安全 | `GetString` / `GetInt` / `GetBool` |
| Eventually 收敛 | 条件满足 → 不超时 |
| Eventually 超时 | 条件不满足 → 测试失败 |
| Golden 文件更新 | `GOLDEN_UPDATE=1` → 更新文件 |
| BoundaryCheck | 生产包不依赖 testkitx |
| GoroutineLeakCheck | 测试结束后无 goroutine 泄漏 |

### 6.2 编译期检查

| 场景 | 验证点 |
|------|--------|
| FakeLogger 接口实现 | `var _ observex.Logger = (*FakeLoggerImpl)(nil)` |
| FakeMeter 接口实现 | `var _ observex.Meter = (*FakeMeterImpl)(nil)` |
| FakeTracer 接口实现 | `var _ observex.Tracer = (*FakeTracerImpl)(nil)` |
| FakeConfig 接口实现 | `var _ configx.Reader = (*FakeConfigImpl)(nil)` |
| FakeBreaker 接口实现 | `var _ resiliencx.Breaker = (*FakeBreakerImpl)(nil)` |

### 6.3 Contract 测试

| Contract | 验证内容 |
|----------|----------|
| `TestContract_Logger_Interface` | FakeLogger 实现 observex.Logger 所有方法 |
| `TestContract_Meter_Interface` | FakeMeter 实现 observex.Meter 所有方法 |
| `TestContract_Tracer_Interface` | FakeTracer 实现 observex.Tracer 所有方法 |
| `TestContract_Config_Reader` | FakeConfig 实现 configx.Reader 所有方法 |
| `TestContract_Breaker_Interface` | FakeBreaker 实现 resiliencx.Breaker 所有方法 |
| `TestContract_Logger_Concurrent` | FakeLogger 并发安全（-race 通过） |
| `TestContract_Meter_LabelCardinality` | FakeMeter 拒绝高基数 label |
| `TestContract_Config_Fingerprint` | FakeConfig fingerprint 稳定性 |

### 6.4 Benchmark

| 场景 | 目标 |
|------|------|
| fake 初始化 | < 1ms |

---

## 7. 性能预算

| 操作 | 目标 | 测量方式 |
|------|------|----------|
| fake 初始化 | < 1ms | benchmark test |
| 常驻内存 | 不限 | 仅测试环境，不计入生产预算 |

---

## 8. 可观测输出

testkitx 不 emit 生产可观测数据。它提供 fake exporter 用于测试验证：

```go
exporter := testkitx.NewFakeExporter()
// 测试中可以断言：
exporter.AssertMetricRecorded("resiliencx.retry.attempts")
exporter.AssertLogContains("kernel.module.start_failed")
exporter.AssertSpanCount(3)
```

---

## 9. 故障模式

| 故障场景 | 降级行为 | 是否阻塞启动 |
|----------|----------|--------------|
| fake 行为与真实实现偏差 | **测试失败**：contract test 应捕获偏差 | N/A（仅测试） |

---

## 10. 安全要求

| 要求 | 实现方式 |
|------|----------|
| 不进入生产二进制 | `go list` 验证生产依赖图不包含 testkitx |
| golden 文件不泄露 secret | golden 更新时自动检查 secret 模式 |

---

## 11. Go baseline

testkitx 的 `go.mod` 必须与其他 Foundation 模块对齐到 Go 1.23。当前状态：Go 1.24，需要降级。

---

## 12. 升级兼容

| 变更类型 | 版本升级 |
|----------|----------|
| Fake 接口行为变更 | **major**（所有使用 fake 的测试需同步更新） |
| 新增 fake 类型 | minor |
| 新增 helper 函数 | patch / minor |
| 修复 bug | **patch** |

---

## 13. 发布 DoD

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
