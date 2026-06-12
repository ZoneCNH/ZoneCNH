# TASK-KERNEL-008 开发 Prompt

> 上游 Task：[TASK-KERNEL-008.md](./tasks/TASK-KERNEL-008.md)
> validx 子包：前置条件与不变量校验

---

## 任务

实现 `kernel/validx` 子包。提供前置条件/不变量校验助手，依赖 errx 子包返回结构化错误。

## 文件清单

### 1. `validx/validx.go`

- `Precondition(ok bool, op, message string) error`：ok==true 返回 nil，否则返回 ErrorKindValidation + SeverityWarning
- `Invariant(ok bool, op, message string) error`：ok==true 返回 nil，否则返回 ErrorKindInternal + SeverityError
- `RequireNonEmpty(op, name, value string) error`：封装 Precondition，消息 `"<name> must not be empty"`

### 2. `validx/validx_test.go`

覆盖：Precondition 通过/失败、Invariant 通过/失败、RequireNonEmpty 空/非空、返回 *errx.Error 类型验证、kind/severify 正确性。

### 3. `validx/example_test.go`

展示在函数入口使用 Precondition 校验参数、Invariant 校验内部状态。

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-012 | FR-008 | Precondition/Invariant 测试 | kind/op/message 正确 |
| AC-VALIDX-01 | FR-008 | Precondition(false) | ErrorKindValidation + Warning |
| AC-VALIDX-02 | FR-008 | Invariant(false) | ErrorKindInternal + Error |

## 禁止事项

- 不要 panic（始终返回 error）
- 不要在 Precondition/Invariant 中分配堆内存（内联友好）
- 不要依赖除 errx 外的 kernel 子包

## 证据回填

完成后提交到 `docs/evidence/2026-06-12/TASK-KERNEL-008/`：
1. `go test -race -count=1 ./validx/...` 输出
2. Benchmark 结果（内联验证）

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./validx/...` | 编译通过，零错误 |
| `go test -race -count=1 ./validx/...` | 全部测试通过，无 race |
| `go vet ./validx/...` | 无警告 |

## 完成后

1. 运行 `go vet ./validx/...` 确认无警告
2. 验证返回的 *errx.Error 可通过 IsKind/AsError 分类
3. 更新 TASK-KERNEL-008 状态为 completed
