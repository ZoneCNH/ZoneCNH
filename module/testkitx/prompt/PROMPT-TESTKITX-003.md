# PROMPT-TESTKITX-003

> FakeMeter 实现

```yaml
prompt_id: PROMPT-TESTKITX-003
task_ref: TASK-TESTKITX-003
spec_ref:
  - "module/testkitx/SPEC.md#FR-003 (FakeMeter)"
  - "module/testkitx/SPEC.md#9.3 (FakeMeterImpl 接口)"
  - "module/testkitx/SPEC.md#BR-001 (编译期接口检查)"
  - "module/testkitx/SPEC.md#BR-002 (确定性行为)"
  - "module/testkitx/SPEC.md#TC-003 (FakeMeter 编译期检查)"
matrix_ref:
  - "module/testkitx/TRACEABILITY.md"
task_files:
  - "fake_meter.go"
  - "fake_meter_test.go"
depends_on:
  - "TASK-TESTKITX-000"
```

---

## 任务

实现 FakeMeter —— 将 metrics 记录到内存 map 的 fake meter，实现 `observex.Meter` 接口，提供断言方法（`AssertCounterValue`、`AssertHistogramRecorded`）供测试验证 metrics 输出。

## 关联需求

| 类型   | 编号   | 出处          | 说明                                                           |
| ------ | ------ | ------------- | -------------------------------------------------------------- |
| FR     | FR-003 | SPEC.md §7    | FakeMeter：记录 metrics 到内存供断言                           |
| BR     | BR-001 | SPEC.md §8    | 编译期接口检查：`var _ observex.Meter = (*FakeMeterImpl)(nil)` |
| BR     | BR-002 | SPEC.md §8    | 行为确定性                                                     |
| TC     | TC-003 | SPEC.md §16.4 | FakeMeter 编译期检查                                           |

## 接口契约

必须实现 `observex.Meter` 接口（参考 observex 模块定义）。

构造签名：

```go
func FakeMeter() (*FakeMeterImpl, observex.Meter)
```

FakeMeterImpl 断言方法：

```go
type FakeMeterImpl struct { /* ... */ }

func (m *FakeMeterImpl) AssertCounterValue(name string, expected float64)
func (m *FakeMeterImpl) AssertHistogramRecorded(name string)
func (m *FakeMeterImpl) CounterValue(name string) float64
func (m *FakeMeterImpl) HistogramValues(name string) []float64
func (m *FakeMeterImpl) GaugeValue(name string) float64
```

行为规范（来自 SPEC FR-003）：

```gherkin
WHEN 调用 FakeMeter() 创建 meter
THEN 返回 (*FakeMeterImpl, observex.Meter)

WHEN 调用 fakeMeter.AssertCounterValue(name, expected)
THEN 断言计数器值等于 expected

WHEN 调用 fakeMeter.AssertHistogramRecorded(name)
THEN 断言直方图有记录
```

## 文件清单

### 1. `fake_meter.go`

实现要点：
- Counter：内部 `map[string]float64` 累加值
- Gauge：内部 `map[string]float64` 覆盖值
- Histogram：内部 `map[string][]float64` 记录样本列表
- `sync.Mutex` 保护并发访问
- 实现 `observex.Meter` 接口的所有方法
- 编译期断言行：`var _ observex.Meter = (*FakeMeterImpl)(nil)`

### 2. `fake_meter_test.go`

测试场景：

| 测试用例                                | 说明                                     |
| --------------------------------------- | ---------------------------------------- |
| `TestFakeMeter_Counter`                 | Counter.Add 后 CounterValue 正确         |
| `TestFakeMeter_Counter_Accumulate`      | 多次 Add 累加正确                        |
| `TestFakeMeter_Gauge`                   | Gauge.Set 后 GaugeValue 正确             |
| `TestFakeMeter_Gauge_Overwrite`         | 多次 Set 覆盖正确                        |
| `TestFakeMeter_Histogram`               | Histogram.Record 后 HistogramValues 正确 |
| `TestFakeMeter_AssertCounterValue`      | 正确值 → 不 fail                         |
| `TestFakeMeter_AssertHistogramRecorded` | 有记录 → 不 fail                         |
| `TestFakeMeter_Concurrent`              | 并发安全                                 |

## 验收标准

| AC       | 关联   | 验证命令                                            | 预期结果                   |        |
| -------- | ------ | --------------------------------------------------- | -------------------------- |        |
| AC-FM-01 | FR-003 | `go test -run TestFakeMeter -v -race ./...`         | 全部通过                   |        |
| AC-FM-02 | BR-001 | `go build ./...`                                    | 编译通过                   |        |
| AC-FM-03 | BR-002 | `grep -E "time\.Now                                 | math\.Rand" fake_meter.go` | 无匹配 |
| AC-FM-04 | TC-003 | `go test -run TestContract_Meter -v ./contract/...` | 接口检查通过               |        |

## 验证命令

| 命令                                        | 判定标准               |
| ------------------------------------------- | ---------------------- |
| `go build ./...`                            | 编译通过               |
| `go test -race -count=1 ./...`              | 全部通过，无 data race |
| `go vet ./...`                              | 无警告                 |
| `grep "var _ observex.Meter" fake_meter.go` | 找到编译期断言         |

## 禁止事项

- 不要在 fake meter 中使用真实的时间戳
- 不要遗漏任何 observex.Meter 接口方法
- 不要在 Counter/Gauge/Histogram 上出现并发不安全访问
- 不要在缺失指标时 panic（返回零值即可）

## 证据回填

完成后提交以下产物：

1. `go test -v -race ./...` 完整输出
2. `go build ./...` 输出
3. `grep "var _ observex.Meter" fake_meter.go` 输出
4. 文件变更清单：`git diff --stat HEAD`

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入 `docs/evidence/`
3. 更新 TASK-TESTKITX-003 状态为 completed
