# TASK-TESTKITX-003

> FakeMeter 实现

---

```yaml
task_id: TASK-TESTKITX-003
module: testkitx
scope: "实现 FakeMeter，记录 metrics 到内存供断言"
spec_ref:
  - "module/testkitx/SPEC.md#FR-003"
files:
  - "fake_meter.go"
  - "fake_meter_test.go"
acceptance_criteria:
  - "FakeMeter 实现 observex.Meter 接口"
  - "Counter/Histogram/Gauge 记录到内部 map"
  - "提供 CounterValue/HistogramValues/GaugeValue 断言方法"
depends_on:
  - "TASK-TESTKITX-000"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-003 | FakeMeter：记录 metrics 到内存 | 断言方法可用 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Unit | Counter.Add 后 CounterValue 正确 |
| — | Unit | Gauge.Set 后 GaugeValue 正确 |

## Implementation Notes

- 内部 `map[string]float64` 存储指标值
- Counter 累加、Gauge 覆盖、Histogram 记录样本列表

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `FakeMeter` 和 Counter/Histogram/Gauge 内部类型 | `fake_meter.go` | `go build ./...` 通过 |
| 2 | 实现断言方法：CounterValue/HistogramValues/GaugeValue | `fake_meter.go` | 全部测试通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Meter 接口不完整 | Low | Medium | 对照 observex.Meter 定义 |
