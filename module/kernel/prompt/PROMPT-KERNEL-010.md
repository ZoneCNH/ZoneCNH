# TASK-KERNEL-010 开发 Prompt

> 上游 Task：[TASK-KERNEL-010.md](./tasks/TASK-KERNEL-010.md)
> contextx 子包：类型安全上下文工具

---

## 任务

实现 `kernel/contextx` 子包。提供泛型类型安全的 context key/value 存取和 deadline 查询工具，依赖 timex 子包。

## 文件清单

### 1. `contextx/contextx.go`

- `Key[T]` 类型：基于 sentinel 指针的唯一 key（未导出字段）
- `NewKey[T](name string) Key[T]`：同名字不同调用返回不同 Key
- `WithValue[T](ctx, key, value) context.Context`
- `Value[T](ctx, key) (T, bool)`：类型匹配返回 (value, true)，否则 (zero, false)
- `contextKey()` 内部方法：零值 Key panic
- `HasDeadline(ctx) bool`、`DeadlineRemaining(ctx, clock) (time.Duration, bool)`
- `IsDone(ctx) bool`、`CancelCause(ctx) error`

### 2. `contextx/contextx_test.go`

覆盖：Key 唯一性、Value 类型安全存取/不匹配、零值 Key panic、DeadlineRemaining 存在/不存在/已过期。

### 3. `contextx/example_test.go`

展示 Key 创建、WithValue/Value 类型安全存取、DeadlineRemaining 查询。

## 验收标准

| AC             | 关联   | 验证命令         | 预期结果             |
| -------------- | ------ | ---------------- | -------------------- |
| AC-014         | FR-010 | Key 唯一性测试   | 同名字不同实例不冲突 |
| AC-CONTEXTX-02 | FR-010 | Value 类型不匹配 | 返回 (zero, false)   |
| AC-CONTEXTX-03 | BR-010 | 零值 Key         | panic                |

## 禁止事项

- 不要使用 `context.WithValue` 裸 API（必须通过 Key[T]）
- Key 不要导出内部字段（防止外部构造零值）
- Value 不要在类型不匹配时返回 partial 值

## 证据回填

完成后提交到 `docs/evidence/2026-06-12/TASK-KERNEL-010/`：
1. `go test -race -count=1 ./contextx/...` 输出
2. Key 唯一性验证（多 goroutine 并发 NewKey 不冲突）

## 验证命令

| 命令                                    | 判定标准              |
| --------------------------------------- | --------------------- |
| `go build ./contextx/...`               | 编译通过，零错误      |
| `go test -race -count=1 ./contextx/...` | 全部测试通过，无 race |
| `go vet ./contextx/...`                 | 无警告                |

## 完成后

1. 运行 `go vet ./contextx/...` 确认无警告
2. 验证泛型类型安全在编译期生效
3. 更新 TASK-KERNEL-010 状态为 completed
