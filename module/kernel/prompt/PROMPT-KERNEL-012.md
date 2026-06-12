# TASK-KERNEL-012 开发 Prompt

> 上游 Task：[TASK-KERNEL-012.md](./tasks/TASK-KERNEL-012.md)
> contracttest 子包：契约测试辅助断言

---

## 任务

实现 `kernel/contracttest` 子包。为 L1 包提供可复用的契约测试断言，依赖 errx 和 healthx 子包。

## 文件清单

### 1. `contracttest/contracttest.go`

- `AssertJSONFields(t testing.TB, value any, fields ...string)`：字段存在通过，缺失 Fatalf
- `AssertErrorKind(t testing.TB, got error, want errx.ErrorKind)`：匹配通过，不匹配 Fatalf
- `AssertHealthStatus(t testing.TB, got healthx.HealthStatus, want healthx.HealthStatusValue)`：status 匹配通过

### 2. `contracttest/contracttest_test.go`

覆盖：JSON 字段存在/缺失、ErrorKind 匹配/不匹配、HealthStatus 匹配/不匹配。

### 3. `contracttest/example_test.go`

展示三个断言函数的典型用法。

## 验收标准

| AC      | 关联   | 验证命令                                                          | 预期结果                             |
| ------- | ------ | ----------------------------------------------------------------- | ------------------------------------ |
| AC-017a | FR-012 | `go test -run TestAssertJSONFields -count=1 ./contracttest/...`   | JSON 字段存在通过，缺失 Fatalf       |
| AC-017b | FR-012 | `go test -run TestAssertErrorKind -count=1 ./contracttest/...`    | ErrorKind 匹配通过，不匹配 Fatalf    |
| AC-017c | FR-012 | `go test -run TestAssertHealthStatus -count=1 ./contracttest/...` | HealthStatus 匹配通过，不匹配 Fatalf |

## 禁止事项

- 不要依赖非 stdlib/testify 等第三方断言库
- 不要在断言通过时产生任何输出
- 断言失败必须用 Fatalf（不继续执行）

## 证据回填

完成后提交到 `docs/evidence/2026-06-12/TASK-KERNEL-012/`：
1. `go test -race -count=1 ./contracttest/...` 输出
2. 断言失败场景截图（Fatalf 输出）

## 验证命令

| 命令                                        | 判定标准              |
| ------------------------------------------- | --------------------- |
| `go build ./contracttest/...`               | 编译通过，零错误      |
| `go test -race -count=1 ./contracttest/...` | 全部测试通过，无 race |
| `go vet ./contracttest/...`                 | 无警告                |

## 完成后

1. 运行 `go vet ./contracttest/...` 确认无警告
2. 验证 testing.TB 接口兼容 *testing.T 和 *testing.B
3. 更新 TASK-KERNEL-012 状态为 completed
