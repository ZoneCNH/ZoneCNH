# TASK-KERNEL-001 开发 Prompt

> errx 子包：结构化错误模型
>
> 上游 Task：[TASK-KERNEL-001.md](./tasks/TASK-KERNEL-001.md)
> 追溯矩阵：[TRACEABILITY.md](./TRACEABILITY.md)
> 实现计划：[IMPLEMENTATION-PLAN.md](./IMPLEMENTATION-PLAN.md) §2 Phase 2

---

## 任务

实现 `kernel/errx` 子包。errx 是 kernel 12 子包中最基础的子包之一，提供结构化错误类型，stdlib-only，不依赖其他 kernel 子包。

## 关联需求

| 类型     | 编号   | 出处          | 说明                          |
| -------- | ------ | ------------- | ----------------------------- |
| FR       | FR-002 | SPEC.md §7    | 结构化错误模型                |
| BR       | BR-004 | SPEC.md §8    | Error 必须实现 error + Unwrap |
| BR       | BR-005 | SPEC.md §8    | IsKind 支持 errors.Join 多链  |
| TC       | TC-004 | SPEC.md §16.4 | 错误链遍历 GWT                |
| TC       | TC-005 | SPEC.md §16.4 | errors.Join 多链 GWT          |
| 接口     | §9.2   | SPEC.md       | errx 接口契约                 |
| 数据模型 | §10.1  | SPEC.md       | errx.Error 结构体定义         |

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

| AC         | 关联   | 验证命令                                          | 预期结果             |
| ---------- | ------ | ------------------------------------------------- | -------------------- |
| AC-003     | FR-002 | `go test -run TestError -count=1 ./errx/...`      | 全部通过             |
| AC-004     | FR-002 | `go test -run TestWalkErrors -count=1 ./errx/...` | 多错误链遍历正确     |
| AC-ERRX-01 | FR-002 | `go vet ./errx/...`                               | 12 ErrorKind 全可用  |
| AC-ERRX-02 | FR-002 | `go vet ./errx/...`                               | 4 Severity 全可用    |
| AC-ERRX-03 | FR-002 | `go test -run TestWith ./errx/...`                | With* 链式调用正确   |
| AC-ERRX-04 | BR-004 | `go test -run TestNil ./errx/...`                 | nil *Error 零值安全  |
| AC-ERRX-05 | BR-005 | `go test -run TestJoin ./errx/...`                | errors.Join 多链遍历 |
| AC-ERRX-06 | BR-005 | `go test -race -count=1 ./errx/...`               | -race 通过           |

## 验证命令

| 命令                                    | 判定标准                       |
| --------------------------------------- | ------------------------------ |
| `go build ./errx/...`                   | 编译通过，零错误               |
| `go test -race -count=1 ./errx/...`     | 全部测试通过，无 race          |
| `go vet ./errx/...`                     | 无警告                         |
| `go test -bench=. -benchmem ./errx/...` | NewError < 100ns, IsKind < 1μs |

## 禁止事项

- 不要依赖任何非 stdlib 包
- 不要依赖其他 kernel 子包
- Error.Cause 不要 JSON 序列化（`json:"-"`）
- nil *Error 的方法不要 panic
- 不要在 Error.Error() 中泄露敏感数据

## 证据回填

完成后提交以下产物到 `docs/evidence/2026-06-12/TASK-KERNEL-001/`：

1. `go build ./errx/...` 输出（编译通过）
2. `go test -race -count=1 ./errx/...` 输出（全部通过）
3. `go vet ./errx/...` 输出（无警告）
4. Benchmark 结果：`go test -bench=. -benchmem ./errx/...`
5. 覆盖率报告：`go test -coverprofile=coverage.out ./errx/... && go tool cover -func=coverage.out`
6. 新建/修改文件清单（路径 + 行数）

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入指定目录
3. 更新 TASK-KERNEL-001 状态为 completed
