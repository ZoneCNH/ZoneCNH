# PROMPT-TESTKITX-002

> FakeLogger 实现

```yaml
prompt_id: PROMPT-TESTKITX-002
task_ref: TASK-TESTKITX-002
spec_ref:
  - "module/testkitx/SPEC.md#FR-002 (FakeLogger)"
  - "module/testkitx/SPEC.md#9.2 (FakeLoggerImpl 接口)"
  - "module/testkitx/SPEC.md#BR-001 (编译期接口检查)"
  - "module/testkitx/SPEC.md#BR-002 (确定性行为)"
  - "module/testkitx/SPEC.md#TC-002 (FakeLogger 编译期检查)"
task_files:
  - "fake_logger.go"
  - "fake_logger_test.go"
depends_on:
  - "TASK-TESTKITX-000"
```

---

## 任务

实现 FakeLogger —— 将日志记录到内存 slice 的 fake logger，实现 `observex.Logger` 接口，提供断言方法（`AssertLogged`、`AssertNoErrors`、`Entries`）供测试验证日志输出。

## 关联需求

| 类型 | 编号 | 出处 | 说明 |
|------|------|------|------|
| FR | FR-002 | SPEC.md §7 | FakeLogger：记录日志到内存供断言 |
| BR | BR-001 | SPEC.md §8 | 编译期接口检查：`var _ observex.Logger = (*FakeLoggerImpl)(nil)` |
| BR | BR-002 | SPEC.md §8 | 行为确定性，不引入 `time.Now()` 或 `math.Rand()` |
| TC | TC-002 | SPEC.md §16.4 | FakeLogger 编译期检查 |

## 接口契约

必须实现 `observex.Logger` 接口（参考 observex 模块定义）。

构造签名：

```go
func FakeLogger() (*FakeLoggerImpl, observex.Logger)
```

FakeLoggerImpl 断言方法：

```go
type FakeLoggerImpl struct { /* ... */ }

func (l *FakeLoggerImpl) AssertLogged(level LogLevel, contains string)
func (l *FakeLoggerImpl) AssertNoErrors()
func (l *FakeLoggerImpl) Entries() []LogEntry
```

LogEntry 结构（至少包含）：

```go
type LogEntry struct {
    Level   LogLevel
    Message string
    Fields  map[string]any
}
```

行为规范（来自 SPEC FR-002）：

```gherkin
WHEN 调用 FakeLogger() 创建 logger
THEN 返回 (*FakeLoggerImpl, observex.Logger)

WHEN 调用 fakeLogger.AssertLogged(level, contains)
THEN 断言指定 level 的日志包含指定文本

WHEN 调用 fakeLogger.AssertNoErrors()
THEN 断言没有 Error 级别日志

WHEN 调用 fakeLogger.Entries()
THEN 返回所有日志条目
```

## 文件清单

### 1. `fake_logger.go`

实现要点：
- 内部 `[]LogEntry` 记录所有日志
- `sync.Mutex` 保护并发写入
- 实现 `observex.Logger` 接口的所有方法（Debug/Info/Warn/Error + With）
- `With(fields)` 返回新实例（拷贝现有 entries 引用）
- 日志时间戳使用构造时的 fake 时间（确定性）
- 编译期断言行：`var _ observex.Logger = (*FakeLoggerImpl)(nil)`

边界场景：
- 并发写入不产生 data race（-race 测试通过）
- `AssertLogged` 找不到匹配时 fail（使用 t.Error）

### 2. `fake_logger_test.go`

测试场景：

| 测试用例 | 说明 |
|----------|------|
| `TestFakeLogger_Info` | Info 后 Entries() 包含该条目 |
| `TestFakeLogger_Error` | Error 后 Entries() 包含该条目 |
| `TestFakeLogger_With` | With 返回新实例，原实例不变 |
| `TestFakeLogger_AssertLogged` | 正确匹配 → 不 fail |
| `TestFakeLogger_AssertLogged_NotFound` | 不匹配 → fail |
| `TestFakeLogger_AssertNoErrors` | 无 Error 日志 → 不 fail |
| `TestFakeLogger_AssertNoErrors_Fail` | 有 Error 日志 → fail |
| `TestFakeLogger_Concurrent` | 并发写入安全 |
| `TestFakeLogger_Deterministic` | 不使用 time.Now() |

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-FL-01 | FR-002 | `go test -run TestFakeLogger -v -race ./...` | 全部通过 |
| AC-FL-02 | BR-001 | `go build ./...` | 编译通过（接口断言检查） |
| AC-FL-03 | BR-002 | `grep -E "time\.Now|math\.Rand" fake_logger.go` | 无匹配 |
| AC-FL-04 | TC-002 | `go test -run TestContract_Logger -v ./contract/...` | 接口检查通过 |

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./...` | 编译通过 |
| `go test -race -count=1 ./...` | 全部通过，无 data race |
| `go vet ./...` | 无警告 |
| `grep "var _ observex.Logger" fake_logger.go` | 找到编译期断言 |

## 禁止事项

- 不要在 fake logger 中调用 `time.Now()`（违反 BR-002，确定性）
- 不要在 fake logger 输出到 stdout/stderr
- 不要遗漏 Any observex.Logger 接口方法
- 不要用 `sync.Map` 替代 `sync.Mutex`（保持简单）
- With 方法不要修改原实例的 entries

## 证据回填

完成后提交以下产物：

1. `go test -v -race ./...` 完整输出
2. `go build ./...` 输出
3. `grep "var _ observex.Logger" fake_logger.go` 输出
4. 文件变更清单：`git diff --stat HEAD`

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入 `docs/evidence/`
3. 更新 TASK-TESTKITX-002 状态为 completed
