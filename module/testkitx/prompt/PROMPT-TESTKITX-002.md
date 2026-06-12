# TASK-TESTKITX-002 开发 Prompt

> FakeLogger 实现：记录日志到内存供断言
>
> 上游 Task：[TASK-TESTKITX-002.md](../tasks/TASK-TESTKITX-002.md)
> 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
> 规格：[SPEC.md](../SPEC.md) §7 FR-002、§9.2

---

## 任务

实现 `FakeLogger`，记录日志到内存供测试断言。实现 `observex.Logger` 接口，提供 `AssertLogged`/`AssertNoErrors`/`Entries` 断言方法，并发安全。

## 关联需求

| 类型 | 编号 | 出处 | 说明 |
|------|------|------|------|
| FR | FR-002 | SPEC.md §7 | FakeLogger：记录日志到内存 |
| BR | BR-001 | SPEC.md §8 | 编译期接口检查 `var _ observex.Logger = (*FakeLoggerImpl)(nil)` |
| AC | AC-002 | TRACEABILITY.md §5 | FakeLogger 实现 observex.Logger 接口 |

## 文件清单

### 1. `fake_logger.go`

- `LogEntry` 结构体：Level、Msg、Fields、Timestamp
- `FakeLoggerImpl` 结构体：内部 `[]LogEntry` + `sync.Mutex`
- `FakeLogger() (*FakeLoggerImpl, observex.Logger)` 工厂函数
- 实现 `observex.Logger` 接口：`Debug`/`Info`/`Warn`/`Error`/`With`/`WithFields`
- `Entries() []LogEntry` 返回所有日志条目
- `AssertLogged(level LogLevel, contains string)` 断言指定 level 日志包含文本
- `AssertNoErrors()` 断言无 Error 级别日志
- 编译期接口检查：`var _ observex.Logger = (*FakeLoggerImpl)(nil)`

### 2. `fake_logger_test.go`

- `TestFakeLogger_LogAndAssert`：Info 后 Entries() 包含该条目
- `TestFakeLogger_AssertLogged`：AssertLogged 按 level 和内容断言
- `TestFakeLogger_AssertNoErrors`：无 Error 时通过，有 Error 时失败
- `TestFakeLogger_With`：With 返回新实例，携带原始 fields
- `TestFakeLogger_Concurrent`：并发写入无 data race

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-002-01 | FR-002 | `go test -run TestFakeLogger -v -count=1` | 全部通过 |
| AC-002-02 | BR-001 | `go build ./...` | 编译通过（接口断言验证） |
| AC-002-03 | FR-002 | `go test -race -run TestFakeLogger -count=1` | 无 data race |

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./...` | 编译通过 |
| `go test -run TestFakeLogger -v -count=1` | 全部测试通过 |
| `go test -race -run TestFakeLogger -count=1` | 无 data race |

## 禁止事项

- 不要使用 `time.Now()` 或 `math.Rand()`（确定性要求，BR-002）
- 不要在 fake_logger 中导入业务域模块
- 不要遗漏任何 observex.Logger 接口方法
- 不要使用 `panic`，使用 `t.Errorf`（BR-003）

## 证据回填

完成后提交以下产物到 `docs/evidence/TASK-TESTKITX-002/`：

1. `go build ./...` 输出
2. `go test -run TestFakeLogger -v -count=1` 输出
3. `go test -race -run TestFakeLogger -count=1` 输出
4. 新建文件清单（路径 + 行数）

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入指定目录
3. 更新 TASK-TESTKITX-002 状态为 completed
