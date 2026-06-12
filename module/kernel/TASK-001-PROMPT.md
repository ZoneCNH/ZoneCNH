# TASK-KERNEL-001 开发 Prompt

> errx 子包：结构化错误模型

---

## 任务

实现 `kernel/errx` 子包。errx 是 kernel 12 子包中最基础的子包之一，提供结构化错误类型，stdlib-only，不依赖其他 kernel 子包。

## 文件清单

### 1. `errx/errx.go`

核心内容：

- `ErrorKind`（string 类型）：12 个预定义值（config, validation, connection, unavailable, timeout, auth, conflict, rate_limit, canceled, not_found, already_exists, internal）
- `Severity`（string 类型）：4 个预定义值（info, warning, error, critical）
- `Error` 结构体：Kind + Code + Severity + Op + Message + Cause + Retryable，实现 `error` 和 `Unwrap()` 接口
- `NewError(kind, op, message)` — 创建新错误
- `WrapError(kind, op, message, cause)` — 包装底层错误
- `IsKind(err, kind)` — 遍历错误链检查 ErrorKind
- `AsError(err)` — 提取 `*Error`
- `(*Error).WithRetryable(bool)` / `WithCode(string)` / `WithSeverity(Severity)` — 链式调用
- `walkErrors` — 内部函数，支持 `Unwrap() []error`（errors.Join 多链）

### 2. `errx/errx_test.go`

覆盖所有 WHEN/THEN 场景：构造、Unwrap、IsKind 单链/多链、AsError、nil 安全、链式 With*、Error() 格式化。

### 3. `errx/example_test.go`

展示 Error 构造、WrapError 链、IsKind 判断的示例。

## 验收标准

| AC | 关联 FR | 验证命令 | 预期结果 |
|----|---------|----------|----------|
| AC-003 | FR-002 | `go test -run TestError -count=1 ./errx/...` | 全部通过 |
| AC-004 | FR-002 | `go test -run TestWalkErrors -count=1 ./errx/...` | 多错误链遍历正确 |

## 禁止事项

- 不要依赖任何非 stdlib 包
- 不要依赖其他 kernel 子包
- Error.Cause 不要 JSON 序列化（`json:"-"`）
- nil *Error 的方法不要 panic

## 完成后

1. 运行 `go test -race -count=1 ./errx/...` 确认通过
2. 运行 `go vet ./errx/...` 确认无警告
3. 将 task 状态更新为 completed
