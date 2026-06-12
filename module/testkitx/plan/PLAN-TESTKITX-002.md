# PLAN-TESTKITX-002

> FakeLogger 实现计划
>
> 对应 Task：`module/testkitx/tasks/TASK-TESTKITX-002.md`
> 对应 Spec：`module/testkitx/SPEC.md#FR-002`, `SPEC.md#9.2`, `SPEC.md#13`

---

## 1. Task 摘要

```yaml
task_id: TASK-TESTKITX-002
scope: "实现 FakeLogger，记录日志到内存供断言"
priority: P0
estimated_effort: "1h"
depends_on: [TASK-TESTKITX-000]
blocks: [TASK-TESTKITX-010]
```

---

## 2. 覆盖需求

| 需求 | 描述 | AC |
|------|------|-----|
| FR-002 | FakeLogger 记录日志到内存 | AC-002: AssertLogged/AssertNoErrors/Entries 可用 |
| BR-001 | 接口编译期检查 | `var _ observex.Logger = (*FakeLoggerImpl)(nil)` |
| NFR-001 | fake 初始化 < 1ms | benchmark 验证 |
| SPEC §13 | Edge Case: 并发写入 | 无 data race（`-race` 测试通过） |

---

## 3. 接口契约

```go
// SPEC §9.2
type FakeLoggerImpl struct{ /* ... */ }

func (l *FakeLoggerImpl) AssertLogged(level LogLevel, contains string)
func (l *FakeLoggerImpl) AssertNoErrors()
func (l *FakeLoggerImpl) Entries() []LogEntry
```

FakeLoggerImpl 必须实现 `observex.Logger` 接口的全部方法，包括：
- `Debug(msg string, fields ...Field)`
- `Info(msg string, fields ...Field)`
- `Warn(msg string, fields ...Field)`
- `Error(msg string, fields ...Field)`
- `With(fields ...Field) Logger`
- 其他 observex.Logger 定义的方法

**实现前必须阅读** `observex` 模块的 Logger 接口定义。

---

## 4. 实现步骤

### Step 1: 定义 LogEntry 和 LogLevel

**目标文件**：`fake_logger.go`

**实现要点**：
```go
type LogLevel int

const (
    LogLevelDebug LogLevel = iota
    LogLevelInfo
    LogLevelWarn
    LogLevelError
)

type LogEntry struct {
    Level  LogLevel
    Msg    string
    Fields map[string]any
}
```

### Step 2: 实现 FakeLoggerImpl 结构体

**目标文件**：`fake_logger.go`

**实现要点**：
- 内部存储：`[]LogEntry` 切片 + `sync.Mutex` 保护
- 实现 `observex.Logger` 接口的所有方法
- `Debug/Info/Warn/Error` 追加 LogEntry 到内部切片
- `With(fields)` 返回新实例（不可变性），继承已有 entries
- 编译期接口检查：`var _ observex.Logger = (*FakeLoggerImpl)(nil)`

**结构体设计**：
```go
type FakeLoggerImpl struct {
    mu      sync.Mutex
    entries []LogEntry
    fields  map[string]any  // With 携带的默认 fields
}
```

### Step 3: 实现断言方法

**实现要点**：

- `AssertLogged(level, contains)`：遍历 entries，检查是否有匹配 level 且 Msg 包含 contains 的条目。不匹配时调用 `t.Errorf`
- `AssertNoErrors()`：检查是否有 Error 级别条目，有则 `t.Errorf`
- `Entries() []LogEntry`：返回 entries 的副本（防止外部修改）

**签名使用 `testing.TB` 而非 `*testing.T`**，兼容 benchmark：
```go
func (l *FakeLoggerImpl) AssertLogged(t testing.TB, level LogLevel, contains string)
func (l *FakeLoggerImpl) AssertNoErrors(t testing.TB)
```

### Step 4: 编写单元测试

**目标文件**：`fake_logger_test.go`

**测试用例**：

| 用例 | 描述 | 验证点 |
|------|------|--------|
| TestFakeLogger_Info | Info 记录日志 | Entries() 包含该条目 |
| TestFakeLogger_AllLevels | Debug/Info/Warn/Error 全部记录 | Entries() 包含所有 level |
| TestFakeLogger_AssertLogged | 断言匹配 | 包含指定 level 和文本 → 通过 |
| TestFakeLogger_AssertNoErrors | 无错误断言 | 无 Error → 通过 |
| TestFakeLogger_With | With 不变性 | 原实例不受影响，新实例有额外 fields |
| TestFakeLogger_Concurrent | 并发安全 | `-race` 通过 |

---

## 5. 验证汇总

```bash
go build ./...
go test -run TestFakeLogger -race -count=1 -v ./...
```

**通过标准**：编译通过 + 全部测试通过 + 无 data race。

---

## 6. 风险与回滚

| 风险 | 概率 | 影响 | 缓解 | 回滚 |
|------|------|------|------|------|
| observex.Logger 接口方法不确定 | Medium | High | 先读 observex 接口定义 | 补全缺失方法 |
| With 实现导致数据竞争 | Low | Medium | 返回新实例，不共享切片 | 使用 copy 或深拷贝 |
| Entries() 外部修改内部状态 | Low | Low | 返回副本 | 返回副本 |

**回滚路径**：本 task 仅新增文件，回滚 = `rm fake_logger.go fake_logger_test.go`。
