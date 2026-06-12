# TASK-TESTKITX-004 开发 Prompt

> FakeTracer 实现：记录 spans 到内存供断言
>
> 上游 Task：[TASK-TESTKITX-004.md](../tasks/TASK-TESTKITX-004.md)
> 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
> 规格：[SPEC.md](../SPEC.md) §7 FR-004、§9.4

---

## 任务

实现 `FakeTracer`，记录 spans 到内存供测试断言。实现 `observex.Tracer` 接口，提供 `AssertSpanCount`/`AssertTraceID` 断言方法。

## 关联需求

| 类型 | 编号 | 出处 | 说明 |
|------|------|------|------|
| FR | FR-004 | SPEC.md §7 | FakeTracer：记录 spans 到内存 |
| BR | BR-001 | SPEC.md §8 | 编译期接口检查 `var _ observex.Tracer = (*FakeTracerImpl)(nil)` |
| AC | AC-004 | TRACEABILITY.md §5 | FakeTracer 实现 observex.Tracer 接口 |

## 文件清单

### 1. `fake_tracer.go`

- `SpanData` 结构体：Name、TraceID、SpanID、ParentSpanID、Attrs、Events、StartTime、EndTime
- `FakeTracerImpl` 结构体：内部 `[]SpanData` + `sync.Mutex`
- `FakeTracer() (*FakeTracerImpl, observex.Tracer)` 工厂函数
- 实现 `observex.Tracer` 接口：`Start`/`StartWithContext`
- `FakeSpan` 实现 `observex.Span` 接口：`End`/`AddEvent`/`SetAttributes`/`RecordError`
- `Spans() []SpanData` 返回所有记录的 span
- `AssertSpanCount(expected int)` 断言 span 数量
- `AssertTraceID propagated` 断言 trace_id 已传播
- 编译期接口检查：`var _ observex.Tracer = (*FakeTracerImpl)(nil)`

### 2. `fake_tracer_test.go`

- `TestFakeTracer_StartSpan`：Start 后 Spans() 包含该 span
- `TestFakeTracer_ChildSpan`：子 span 继承 trace_id
- `TestFakeTracer_AssertSpanCount`：断言 span 数量正确
- `TestFakeTracer_Concurrent`：并发写入无 data race

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-004-01 | FR-004 | `go test -run TestFakeTracer -v -count=1` | 全部通过 |
| AC-004-02 | BR-001 | `go build ./...` | 编译通过（接口断言验证） |
| AC-004-03 | FR-004 | `go test -race -run TestFakeTracer -count=1` | 无 data race |

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./...` | 编译通过 |
| `go test -run TestFakeTracer -v -count=1` | 全部测试通过 |
| `go test -race -run TestFakeTracer -count=1` | 无 data race |

## 禁止事项

- 不要使用 `time.Now()` 或 `math.Rand()`（确定性要求，BR-002）
- 不要在 fake_tracer 中导入业务域模块
- 不要遗漏任何 observex.Tracer 和 observex.Span 接口方法

## 证据回填

完成后提交以下产物到 `docs/evidence/TASK-TESTKITX-004/`：

1. `go build ./...` 输出
2. `go test -run TestFakeTracer -v -count=1` 输出
3. `go test -race -run TestFakeTracer -count=1` 输出
4. 新建文件清单（路径 + 行数）

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入指定目录
3. 更新 TASK-TESTKITX-004 状态为 completed
