# TASK-TESTKITX-003 开发 Prompt

> FakeMeter 实现：记录 metrics 到内存供断言
>
> 上游 Task：[TASK-TESTKITX-003.md](../tasks/TASK-TESTKITX-003.md)
> 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
> 规格：[SPEC.md](../SPEC.md) §7 FR-003、§9.3

---

## 任务

实现 `FakeMeter`，记录 metrics 到内存供测试断言。实现 `observex.Meter` 接口，提供 `AssertCounterValue`/`AssertHistogramRecorded` 断言方法。

## 关联需求

| 类型 | 编号 | 出处 | 说明 |
|------|------|------|------|
| FR | FR-003 | SPEC.md §7 | FakeMeter：记录 metrics 到内存 |
| BR | BR-001 | SPEC.md §8 | 编译期接口检查 `var _ observex.Meter = (*FakeMeterImpl)(nil)` |
| AC | AC-003 | TRACEABILITY.md §5 | FakeMeter 实现 observex.Meter 接口 |

## 文件清单

### 1. `fake_meter.go`

- `FakeMeterImpl` 结构体：内部 `map[string]float64`（counter）、`map[string][]float64`（histogram）、`sync.RWMutex`
- `FakeMeter() (*FakeMeterImpl, observex.Meter)` 工厂函数
- 实现 `observex.Meter` 接口：`NewCounter`/`NewHistogram`/`NewGauge`
- `AssertCounterValue(name string, expected float64)` 断言计数器值
- `AssertHistogramRecorded(name string)` 断言直方图有记录
- 编译期接口检查：`var _ observex.Meter = (*FakeMeterImpl)(nil)`

### 2. `fake_meter_test.go`

- `TestFakeMeter_Counter`：Counter.Add 后 AssertCounterValue 正确
- `TestFakeMeter_Histogram`：Histogram.Record 后 AssertHistogramRecorded 通过
- `TestFakeMeter_Gauge`：Gauge.Set 后值正确
- `TestFakeMeter_Concurrent`：并发写入无 data race

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-003-01 | FR-003 | `go test -run TestFakeMeter -v -count=1` | 全部通过 |
| AC-003-02 | BR-001 | `go build ./...` | 编译通过（接口断言验证） |
| AC-003-03 | FR-003 | `go test -race -run TestFakeMeter -count=1` | 无 data race |

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./...` | 编译通过 |
| `go test -run TestFakeMeter -v -count=1` | 全部测试通过 |
| `go test -race -run TestFakeMeter -count=1` | 无 data race |

## 禁止事项

- 不要使用 `time.Now()` 或 `math.Rand()`（确定性要求，BR-002）
- 不要在 fake_meter 中导入业务域模块
- 不要遗漏任何 observex.Meter 接口方法

## 证据回填

完成后提交以下产物到 `docs/evidence/TASK-TESTKITX-003/`：

1. `go build ./...` 输出
2. `go test -run TestFakeMeter -v -count=1` 输出
3. `go test -race -run TestFakeMeter -count=1` 输出
4. 新建文件清单（路径 + 行数）

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入指定目录
3. 更新 TASK-TESTKITX-003 状态为 completed
