# PROMPT-TESTKITX-004

> FakeTracer 实现

```yaml
prompt_id: PROMPT-TESTKITX-004
task_ref: TASK-TESTKITX-004
spec_ref:
  - "module/testkitx/SPEC.md#FR-004 (FakeTracer)"
  - "module/testkitx/SPEC.md#9.4 (FakeTracerImpl 接口)"
  - "module/testkitx/SPEC.md#BR-001 (编译期接口检查)"
  - "module/testkitx/SPEC.md#BR-002 (确定性行为)"
  - "module/testkitx/SPEC.md#TC-004 (FakeTracer 编译期检查)"
task_files:
  - "fake_tracer.go"
  - "fake_tracer_test.go"
depends_on:
  - "TASK-TESTKITX-000"
```

---

## 任务

实现 FakeTracer —— 将 spans 记录到内存 slice 的 fake tracer，实现 `observex.Tracer` 接口，提供断言方法（`AssertSpanCount`、`AssertTraceID`、`Spans`）供测试验证 trace 输出。

## 关联需求

| 类型 | 编号 | 出处 | 说明 |
|------|------|------|------|
| FR | FR-004 | SPEC.md §7 | FakeTracer：记录 spans 到内存供断言 |
| BR | BR-001 | SPEC.md §8 | 编译期接口检查：`var _ observex.Tracer = (*FakeTracerImpl)(nil)` |
| BR | BR-002 | SPEC.md §8 | 行为确定性 |
| TC | TC-004 | SPEC.md §16.4 | FakeTracer 编译期检查 |

## 接口契约

必须实现 `observex.Tracer` 接口（参考 observex 模块定义）。

构造签名：

```go
func FakeTracer() (*FakeTracerImpl, observex.Tracer)
```

FakeTracerImpl 断言方法：

```go
type FakeTracerImpl struct { /* ... */ }

func (t *FakeTracerImpl) AssertSpanCount(expected int)
func (t *FakeTracerImpl) AssertTraceID()
func (t *FakeTracerImpl) Spans() []SpanData
```

FakeSpan（内部类型）：

```go
type SpanData struct {
    Name      string
    TraceID   string
    SpanID    string
    ParentID  string
    Attrs     map[string]any
    Events    []SpanEvent
    Ended     bool
}
```

行为规范（来自 SPEC FR-004）：

```gherkin
WHEN 调用 FakeTracer() 创建 tracer
THEN 返回 (*FakeTracerImpl, observex.Tracer)

WHEN 调用 fakeTracer.AssertSpanCount(expected)
THEN 断言 span 数量等于 expected

WHEN 调用 fakeTracer.AssertTraceID()
THEN 断言 trace_id 已传播
```

## 文件清单

### 1. `fake_tracer.go`

实现要点：
- 内部 `[]SpanData` 记录所有 span
- `sync.Mutex` 保护并发访问
- `Start(ctx, name)` 创建 FakeSpan，从 ctx 提取/生成 trace_id
- FakeSpan 实现 `observex.Span` 接口（SetAttributes、AddEvent、End 等）
- 编译期断言行：`var _ observex.Tracer = (*FakeTracerImpl)(nil)`

### 2. `fake_tracer_test.go`

测试场景：

| 测试用例 | 说明 |
|----------|------|
| `TestFakeTracer_StartSpan` | Start 后 Spans() 包含该 span |
| `TestFakeTracer_ChildSpan` | 子 span 继承 trace_id |
| `TestFakeTracer_AssertSpanCount` | 正确数量 → 不 fail |
| `TestFakeTracer_AssertTraceID` | trace_id 已传播 → 不 fail |
| `TestFakeTracer_Concurrent` | 并发安全 |

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-FT-01 | FR-004 | `go test -run TestFakeTracer -v -race ./...` | 全部通过 |
| AC-FT-02 | BR-001 | `go build ./...` | 编译通过 |
| AC-FT-03 | TC-004 | `go test -run TestContract_Tracer -v ./contract/...` | 接口检查通过 |

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./...` | 编译通过 |
| `go test -race -count=1 ./...` | 全部通过，无 data race |
| `go vet ./...` | 无警告 |
| `grep "var _ observex.Tracer" fake_tracer.go` | 找到编译期断言 |

## 禁止事项

- 不要在 fake tracer 中真正将 span 导出到外部系统
- 不要遗漏任何 observex.Tracer / observex.Span 接口方法
- 不要在并发访问 SpanData 时不加锁
- 子 span 的 trace_id 必须继承父 span

## 证据回填

完成后提交以下产物：

1. `go test -v -race ./...` 完整输出
2. `go build ./...` 输出
3. `grep "var _ observex.Tracer" fake_tracer.go` 输出
4. 文件变更清单：`git diff --stat HEAD`

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入 `docs/evidence/`
3. 更新 TASK-TESTKITX-004 状态为 completed
