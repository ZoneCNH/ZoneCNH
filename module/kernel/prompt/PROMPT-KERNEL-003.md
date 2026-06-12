# TASK-KERNEL-003 开发 Prompt

> obsx 子包：可观测抽象接口 + Noop 零值实现 + SecretString 脱敏

---

## 任务

实现 `kernel/obsx` 子包。obsx 定义无供应商绑定的可观测接口（Logger/Metrics/Tracer/Span），提供 Noop 零值实现和 SecretString 脱敏机制。纯 stdlib。

## 文件清单

### 1. `obsx/obsx.go`

- `Field` 类型：`{Key string, Value any}`
- `Logger` 接口：`Debug/Info/Warn/Error(ctx, msg, ...Field)`
- `Metrics` 接口：`Count(ctx, name, delta, ...Field)` / `Observe(ctx, name, value, ...Field)`
- `Tracer` 接口：`Start(ctx, name, ...Field) (context.Context, Span)`
- `Span` 接口：`End()` / `RecordError(error)` / `SetFields(...Field)`
- `NoopLogger` / `NoopMetrics` / `NoopTracer` / `NoopSpan`：空结构体，静默成功
- `Sanitizer` 接口：`Sanitize() string`
- `SecretString`：`String()/GoString()/MarshalJSON()` 返回 `"***"`，`Reveal()` 返回原始值

### 2. `obsx/obsx_test.go`

覆盖：Noop 零值不 panic、SecretString 四路径脱敏、Logger 四方法签名、Metrics 两方法签名。

### 3. `obsx/example_test.go`

展示注入 NoopLogger 进行测试、SecretString 脱敏使用。

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-006 | FR-004 | Noop* 所有方法调用 | 静默成功不 panic |
| AC-007 | FR-004 | SecretString.String()/JSON() | 返回 "***" |
| AC-OBSX-01 | FR-004 | Logger 四方法 | 编译验证签名 |
| AC-OBSX-05 | FR-004 | gob 编码 SecretString | 返回 "***" |

## 禁止事项

- 不要依赖非 stdlib 包
- 不要依赖其他 kernel 子包
- 不要在 Noop* 中产生任何副作用（日志/指标/span）
- SecretString 不要实现 `fmt.Formatter` 以绕过 String()

## 证据回填

完成后提交到 `docs/evidence/2026-06-12/TASK-KERNEL-003/`：
1. `go test -race -count=1 ./obsx/...` 输出
2. `go vet ./obsx/...` 输出
3. SecretString 脱敏验证（String/JSON/gob/GoString 四路径）

## 完成后

1. 运行 `go test -race -count=1 ./obsx/...` 确认通过
2. 验证 SecretString 无法通过反射绕过
3. 更新 TASK-KERNEL-003 状态为 completed
