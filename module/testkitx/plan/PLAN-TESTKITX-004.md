# PLAN-TESTKITX-004

> FakeTracer 实现计划
>
> 对应 Task：`module/testkitx/tasks/TASK-TESTKITX-004.md`
> 对应 Spec：`module/testkitx/SPEC.md#FR-004`, `SPEC.md#9.4`, `SPEC.md#16.3`

---

## 1. Task 摘要

```yaml
task_id: TASK-TESTKITX-004
scope: "实现 FakeTracer，记录 spans 到内存供断言，以及 contract test harness"
priority: P0
estimated_effort: "2h"
depends_on: [TASK-TESTKITX-000, TASK-TESTKITX-001, TASK-TESTKITX-002, TASK-TESTKITX-003, TASK-TESTKITX-005]
blocks: [TASK-TESTKITX-010]
```

---

## 2. 覆盖需求

| 需求       | 描述                         | AC                                               |
| ---------- | ---------------------------- | ------------------------------------------------ |
| FR-004     | FakeTracer 记录 spans 到内存 | AC-004: AssertSpanCount/AssertTraceID 可用       |
| BR-001     | 接口编译期检查               | `var _ observex.Tracer = (*FakeTracerImpl)(nil)` |
| NFR-001    | fake 初始化 < 1ms            | benchmark 验证                                   |
| SPEC §16.3 | Contract 测试                | 8 个 contract test 全部通过                      |

---

## 3. 接口契约

```go
// SPEC §9.4
type FakeTracerImpl struct{ /* ... */ }

func (t *FakeTracerImpl) AssertSpanCount(expected int)
func (t *FakeTracerImpl) AssertTraceID propagated
```

FakeTracerImpl 必须实现 `observex.Tracer` 接口，包括：
- `Start(ctx context.Context, name string, opts ...SpanOption) (context.Context, Span)`
- 其他 observex.Tracer 定义的方法

**实现前必须阅读** `observex` 模块的 Tracer 和 Span 接口定义。

---

## 4. 实现步骤

### Step 1: 定义 SpanData 和 FakeSpan

**目标文件**：`fake_tracer.go`

**实现要点**：
```go
type SpanData struct {
    Name       string
    TraceID    string
    SpanID     string
    ParentID   string
    StartTime  time.Time
    EndTime    time.Time
    Attributes map[string]any
    Events     []SpanEvent
    Ended      bool
}
```

### Step 2: 实现 FakeTracerImpl

**目标文件**：`fake_tracer.go`

**实现要点**：
- 内部存储：`[]*SpanData` + `sync.Mutex` 保护
- `Start()` 创建 FakeSpan，记录 span data
- 子 span 继承父 trace_id
- `Spans() []*SpanData` 返回所有记录的 span
- 编译期接口检查：`var _ observex.Tracer = (*FakeTracerImpl)(nil)`

### Step 3: 实现断言方法

**实现要点**：
- `AssertSpanCount(t testing.TB, expected int)`：比较 span 数量
- `AssertTraceID(t testing.TB)`：断言 trace_id 已传播（非空）

### Step 4: 实现 contract test harness

**目标文件**：`contract.go`

**实现要点**：
- `ContractTest` 接口或函数，提供统一的 contract 测试运行器
- 自动注册 contract 测试用例

### Step 5: 编写 contract 测试

**目标文件**：`contract/logger_test.go`, `contract/meter_test.go`, `contract/tracer_test.go`, `contract/config_test.go`, `contract/breaker_test.go`, `contract/concurrent_test.go`, `contract/cardinality_test.go`, `contract/fingerprint_test.go`

**测试用例**：

| Contract                            | 验证内容                                     |
| ----------------------------------- | -------------------------------------------- |
| TestContract_Logger_Interface       | FakeLogger 实现 observex.Logger 所有方法     |
| TestContract_Meter_Interface        | FakeMeter 实现 observex.Meter 所有方法       |
| TestContract_Tracer_Interface       | FakeTracer 实现 observex.Tracer 所有方法     |
| TestContract_Config_Reader          | FakeConfig 实现 configx.Reader 所有方法      |
| TestContract_Breaker_Interface      | FakeBreaker 实现 resiliencx.Breaker 所有方法 |
| TestContract_Logger_Concurrent      | FakeLogger 并发安全                          |
| TestContract_Meter_LabelCardinality | FakeMeter 拒绝高基数 label                   |
| TestContract_Config_Fingerprint     | FakeConfig fingerprint 稳定性                |

### Step 6: 编写单元测试

**目标文件**：`fake_tracer_test.go`

**测试用例**：

| 用例                           | 描述                  | 验证点               |
| ------------------------------ | --------------------- | -------------------- |
| TestFakeTracer_Start           | Start 创建 span       | Spans() 包含该 span  |
| TestFakeTracer_ChildSpan       | 子 span 继承 trace_id | 父子 trace_id 相同   |
| TestFakeTracer_AssertSpanCount | 断言 span 数          | 数量匹配 → 通过      |
| TestFakeTracer_AssertTraceID   | 断言 trace_id 传播    | trace_id 非空 → 通过 |
| TestFakeTracer_Concurrent      | 并发安全              | `-race` 通过         |

---

## 5. 验证汇总

```bash
go build ./...
go test -run TestFakeTracer -race -count=1 -v ./...
go test ./contract/... -race -count=1 -v
```

**通过标准**：编译通过 + 全部单元测试通过 + 全部 contract 测试通过 + 无 data race。

---

## 6. 风险与回滚

| 风险                            | 概率   | 影响   | 缓解                                                      | 回滚                      |
| ------------------------------- | ------ | ------ | --------------------------------------------------------- | ------------------------- |
| observex.Tracer/Span 接口不确定 | Medium | High   | 先读 observex 接口定义                                    | 补全缺失方法              |
| Contract 测试依赖其他 fake      | High   | Medium | contract 测试仅验证接口完整性，不依赖其他 fake 的实现细节 | 调整 import               |
| trace_id 生成非确定性           | Low    | Low    | 使用固定或可控的 trace_id 生成器                          | 使用 `FakeClock` 的时间戳 |

**回滚路径**：本 task 仅新增文件，回滚 = `rm fake_tracer.go fake_tracer_test.go contract.go contract/*_test.go`。
