# TASK-KERNEL-013 开发 Prompt

> 上游 Task：[TASK-KERNEL-013.md](./tasks/TASK-KERNEL-013.md)
> internal/testutil：内部测试工具 — RequireEqual 泛型断言

---

## 任务

实现 `kernel/internal/testutil` 子包。提供仅供 kernel 内部使用的泛型测试断言，纯 stdlib。

## 文件清单

### 1. `internal/testutil/testutil.go`

- `RequireEqual[T comparable](t testing.TB, got T, want T)`：匹配通过，不匹配 Fatalf

### 2. `internal/testutil/testutil_test.go`

覆盖：匹配通过、不匹配 Fatalf、多类型（int/string/struct）泛型验证。

## 验收标准

| AC             | 关联   | 验证命令   | 预期结果   |
| -------------- | ------ | ---------- | ---------- |
| AC-TESTUTIL-01 | §9.13  | 匹配测试   | 通过       |
| AC-TESTUTIL-02 | §9.13  | 不匹配测试 | Fatalf     |

## 禁止事项

- 不要暴露给外部消费者（internal 包约束）
- 不要依赖 testify 等第三方断言库
- 不要在断言通过时产生任何输出

## 证据回填

完成后提交到 `docs/evidence/2026-06-12/TASK-KERNEL-013/`：
1. `go test -race -count=1 ./internal/testutil/...` 输出
2. Fatalf 输出验证

## 验证命令

| 命令                                             | 判定标准              |
| ------------------------------------------------ | --------------------- |
| `go build ./internal/testutil/...`               | 编译通过，零错误      |
| `go test -race -count=1 ./internal/testutil/...` | 全部测试通过，无 race |
| `go vet ./internal/testutil/...`                 | 无警告                |

## 完成后

1. 运行 `go vet ./internal/testutil/...` 确认无警告
2. 验证 internal 包外部不可导入
3. 更新 TASK-KERNEL-013 状态为 completed
