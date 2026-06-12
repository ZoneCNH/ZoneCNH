# PLAN-TESTKITX-005

> FakeClock + FakeBreaker 实现计划
>
> 对应 Task：`module/testkitx/tasks/TASK-TESTKITX-005.md`
> 对应 Spec：`module/testkitx/SPEC.md#FR-005`, `SPEC.md#FR-006`, `SPEC.md#9.5`, `SPEC.md#9.6`, `SPEC.md#13`

---

## 1. Task 摘要

```yaml
task_id: TASK-TESTKITX-005
scope: "实现 FakeClock（可控制时间）、FakeBreaker（可控制熔断状态）、FakeExporter（遥测验证）"
priority: P0
estimated_effort: "1h"
depends_on: [TASK-TESTKITX-000]
blocks: [TASK-TESTKITX-010]
```

---

## 2. 覆盖需求

| 需求 | 描述 | AC |
|------|------|-----|
| FR-005 | FakeClock：可控制时间 | AC-005: Now() 返回可控时间，Advance 推进 |
| FR-006 | FakeBreaker：可控制熔断状态 | AC-006: SetState 控制状态，Execute 受状态控制 |
| BR-001 | 接口编译期检查 | `var _ resiliencx.Breaker = (*FakeBreakerImpl)(nil)` |
| BR-002 | 确定性行为 | FakeClock 不调用 `time.Now()`，不使用 `math.Rand()` |
| NFR-001 | fake 初始化 < 1ms | benchmark 验证 |
| SPEC §13 | Edge Case: 未 Advance | Now() 始终返回初始时间 |

---

## 3. 接口契约

```go
// SPEC §9.5
type FakeClock struct{ /* ... */ }
func FakeClock(at time.Time) *FakeClock
func (c *FakeClock) Now() time.Time
func (c *FakeClock) Advance(d time.Duration)
func (c *FakeClock) Set(t time.Time)

// SPEC §9.6
type FakeExporterImpl struct{ /* ... */ }
func FakeExporter() *FakeExporterImpl
func (e *FakeExporterImpl) AssertSpanCount(expected int)
func (e *FakeExporterImpl) AssertMetricRecorded(name string)
func (e *FakeExporterImpl) AssertLogContains(contains string)
```

FakeBreaker 必须实现 `resiliencx.Breaker` 接口。FakeClock 不需要实现外部接口（独立类型）。

---

## 4. 实现步骤

### Step 1: 实现 FakeClock

**目标文件**：`fake_clock.go`

**实现要点**：
- 内部维护 `time.Time` + `sync.RWMutex`
- `Now()` 返回内部时间（**不调用** `time.Now()`）
- `Advance(d)` 内部时间推进 d
- `Set(t)` 内部时间设置为 t
- 可选实现：`After(d)` 返回 `<-chan time.Time`（用于 select 场景）

**确定性验证**：多次创建相同初始时间的 FakeClock，Now() 返回相同值。

### Step 2: 实现 FakeBreaker

**目标文件**：`fake_breaker.go`

**实现要点**：
- 内部维护 `resiliencx.BreakerState`（Closed/Open/HalfOpen）
- `Execute(fn)` 根据状态决定行为：Closed → 执行 fn，Open → 返回 ErrCircuitOpen
- `State()` 返回当前状态
- `SetState(s)` 设置状态
- 编译期接口检查：`var _ resiliencx.Breaker = (*FakeBreakerImpl)(nil)`

**实现前必须阅读** `resiliencx` 模块的 Breaker 接口定义。

### Step 3: 实现 FakeExporter

**目标文件**：`fake_exporter.go`

**实现要点**：
- 记录到内存的 span count、metric names、log entries
- 断言方法：`AssertSpanCount`、`AssertMetricRecorded`、`AssertLogContains`
- 不需要实现外部接口（独立 fake 类型）

### Step 4: 编写单元测试

**目标文件**：`fake_clock_test.go`, `fake_breaker_test.go`

**FakeClock 测试用例**：

| 用例 | 描述 | 验证点 |
|------|------|--------|
| TestFakeClock_Now | 初始时间 | Now() 返回构造时的时间 |
| TestFakeClock_Advance | 时间推进 | Advance(1s) 后 Now() 增加 1s |
| TestFakeClock_Set | 设置时间 | Set(t) 后 Now() 返回 t |
| TestFakeClock_Deterministic | 确定性 | 不调用 time.Now()（编译期 + -race 验证） |
| TestFakeClock_NoAdvance | 未 Advance | Now() 始终返回初始时间 |
| TestFakeClock_Concurrent | 并发安全 | `-race` 通过 |

**FakeBreaker 测试用例**：

| 用例 | 描述 | 验证点 |
|------|------|--------|
| TestFakeBreaker_Closed | Closed 状态 | Execute 执行 fn |
| TestFakeBreaker_Open | Open 状态 | Execute 返回 ErrCircuitOpen |
| TestFakeBreaker_SetState | 切换状态 | SetState(HalfOpen) 后 State() 返回 HalfOpen |
| TestFakeBreaker_Interface | 接口实现 | 编译期检查 |

---

## 5. 验证汇总

```bash
go build ./...
go test -run TestFakeClock -race -count=1 -v ./...
go test -run TestFakeBreaker -race -count=1 -v ./...
go test -run TestFakeExporter -race -count=1 -v ./...
```

**通过标准**：编译通过 + 全部测试通过 + 无 data race。

---

## 6. 风险与回滚

| 风险 | 概率 | 影响 | 缓解 | 回滚 |
|------|------|------|------|------|
| FakeClock 隐式调用 time.Now() | Low | High | 代码审查 + 确定性测试验证 | 替换为内部时间 |
| resiliencx.Breaker 接口不确定 | Medium | High | 先读 resiliencx 接口定义 | 补全缺失方法 |
| FakeClock After channel 实现复杂 | Low | Low | 可选实现，P1 优先级 | 移除 After 方法 |

**回滚路径**：本 task 仅新增文件，回滚 = `rm fake_clock.go fake_breaker.go fake_exporter.go fake_clock_test.go fake_breaker_test.go`。
