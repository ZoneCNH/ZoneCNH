# TASK-TESTKITX-003

> FakeMeter 实现

---

```yaml
task_id: TASK-TESTKITX-003
module: testkitx
scope: "实现 FakeMeter，记录 metrics 到内存供断言"
non_scope: "不导出到外部 metrics 系统，不实现聚合"
spec_ref:
  - "module/testkitx/SPEC.md#FR-003"
files:
  - "fake_meter.go"
  - "fake_meter_test.go"
acceptance_criteria:
  - "AC-003: FakeMeter 实现 observex.Meter 接口"
  - "AC-003: Counter/Histogram/Gauge 记录到内部 map"
  - "AC-003: AssertCounterValue/AssertHistogramRecorded 可用"
depends_on:
  - "TASK-TESTKITX-000"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Non-scope

- 不涉及本 Task 范围外的功能

## Requirements Covered

| Requirement | Description                    | Acceptance Criteria |
| ----------- | ------------------------------ | ------------------- |
| FR-003      | FakeMeter：记录 metrics 到内存 | AC-003              |

## Test Plan

| Test Case | Type | Description                                      |
| --------- | ---- | ------------------------------------------------ |
| TC-003    | Unit | Counter.Add 后 AssertCounterValue 正确           |
| TC-003    | Unit | Histogram.Record 后 AssertHistogramRecorded 通过 |

## Implementation Notes

- 内部 `map[string]float64` 存储指标值
- Counter 累加、Gauge 覆盖、Histogram 记录样本列表

## Implementation Plan

| Step | Description                                           | Deliverables    | Verification          |
| ---- | ----------------------------------------------------- | --------------- | --------------------- |
| 1    | 实现 `FakeMeter` 和 Counter/Histogram/Gauge 内部类型  | `fake_meter.go` | `go build ./...` 通过 |
| 2    | 实现断言方法：CounterValue/HistogramValues/GaugeValue | `fake_meter.go` | 全部测试通过          |

### Risk Assessment

| Risk             | Probability | Impact | Mitigation               |
| ---------------- | ----------- | ------ | ------------------------ |
| Meter 接口不完整 | Low         | Medium | 对照 observex.Meter 定义 |
