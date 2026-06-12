# PLAN-TESTKITX-003

> FakeMeter 实现计划
>
> 对应 Task：`module/testkitx/tasks/TASK-TESTKITX-003.md`
> 对应 Spec：`module/testkitx/SPEC.md#FR-003`, `SPEC.md#9.3`

---

## 1. Task 摘要

```yaml
task_id: TASK-TESTKITX-003
scope: "实现 FakeMeter，记录 metrics 到内存供断言"
priority: P0
estimated_effort: "1h"
depends_on: [TASK-TESTKITX-000]
blocks: [TASK-TESTKITX-010]
```

---

## 2. 覆盖需求

| 需求 | 描述 | AC |
|------|------|-----|
| FR-003 | FakeMeter 记录 metrics 到内存 | AC-003: AssertCounterValue/AssertHistogramRecorded 可用 |
| BR-001 | 接口编译期检查 | `var _ observex.Meter = (*FakeMeterImpl)(nil)` |
| NFR-001 | fake 初始化 < 1ms | benchmark 验证 |

---

## 3. 接口契约

```go
// SPEC §9.3
type FakeMeterImpl struct{ /* ... */ }

func (m *FakeMeterImpl) AssertCounterValue(name string, expected float64)
func (m *FakeMeterImpl) AssertHistogramRecorded(name string)
```

FakeMeterImpl 必须实现 `observex.Meter` 接口的全部方法，包括 Counter/Histogram/Gauge 的创建和操作。

**实现前必须阅读** `observex` 模块的 Meter 接口定义。

---

## 4. 实现步骤

### Step 1: 实现内部指标类型

**目标文件**：`fake_meter.go`

**实现要点**：
- `fakeCounter`：内部 `float64` 累加值
- `fakeHistogram`：内部 `[]float64` 样本列表
- `fakeGauge`：内部 `float64` 当前值

### Step 2: 实现 FakeMeterImpl

**目标文件**：`fake_meter.go`

**实现要点**：
- 内部存储：`map[string]*fakeCounter` / `map[string]*fakeHistogram` / `map[string]*fakeGauge`
- `sync.RWMutex` 保护并发访问
- 创建 Counter/Histogram/Gauge 的方法返回内部 fake 类型
- 编译期接口检查：`var _ observex.Meter = (*FakeMeterImpl)(nil)`

### Step 3: 实现断言方法

**实现要点**：
- `AssertCounterValue(t testing.TB, name string, expected float64)`：比较计数器值
- `AssertHistogramRecorded(t testing.TB, name string)`：检查直方图是否有记录
- `AssertGaugeValue(t testing.TB, name string, expected float64)`：比较 gauge 值
- `CounterValue(name string) float64`：返回值（供外部断言）
- `HistogramValues(name string) []float64`：返回样本列表

### Step 4: 编写单元测试

**目标文件**：`fake_meter_test.go`

**测试用例**：

| 用例 | 描述 | 验证点 |
|------|------|--------|
| TestFakeMeter_Counter | Counter.Add | CounterValue 累加正确 |
| TestFakeMeter_Gauge | Gauge.Set | GaugeValue 返回设置值 |
| TestFakeMeter_Histogram | Histogram.Record | HistogramValues 包含样本 |
| TestFakeMeter_AssertCounterValue | 断言匹配 | 值相等 → 通过 |
| TestFakeMeter_AssertHistogramRecorded | 断言有记录 | 有样本 → 通过 |
| TestFakeMeter_Concurrent | 并发安全 | `-race` 通过 |

---

## 5. 验证汇总

```bash
go build ./...
go test -run TestFakeMeter -race -count=1 -v ./...
```

**通过标准**：编译通过 + 全部测试通过 + 无 data race。

---

## 6. 风险与回滚

| 风险 | 概率 | 影响 | 缓解 | 回滚 |
|------|------|------|------|------|
| observex.Meter 接口方法不确定 | Medium | High | 先读 observex 接口定义 | 补全缺失方法 |
| Counter/Histogram 语义理解偏差 | Low | Medium | 对照 OpenTelemetry metrics 规范 | 修正实现 |

**回滚路径**：本 task 仅新增文件，回滚 = `rm fake_meter.go fake_meter_test.go`。
