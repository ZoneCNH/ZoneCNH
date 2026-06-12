# PROMPT-TESTKITX-005

> FakeClock + FakeBreaker 实现

```yaml
prompt_id: PROMPT-TESTKITX-005
task_ref: TASK-TESTKITX-005
spec_ref:
  - "module/testkitx/SPEC.md#FR-005 (FakeClock)"
  - "module/testkitx/SPEC.md#FR-006 (FakeBreaker)"
  - "module/testkitx/SPEC.md#9.5 (FakeClock 接口)"
  - "module/testkitx/SPEC.md#9.6 (FakeBreaker 接口)"
  - "module/testkitx/SPEC.md#BR-001 (编译期接口检查)"
  - "module/testkitx/SPEC.md#BR-002 (确定性行为)"
  - "module/testkitx/SPEC.md#TC-005 (FakeClock 确定性)"
  - "module/testkitx/SPEC.md#TC-006 (FakeBreaker 编译期检查)"
task_files:
  - "fake_clock.go"
  - "fake_breaker.go"
  - "fake_clock_test.go"
  - "fake_breaker_test.go"
depends_on:
  - "TASK-TESTKITX-000"
```

---

## 任务

实现 FakeClock（可控制时间的时钟）和 FakeBreaker（可控制熔断状态的熔断器）。两个 fake 都必须是确定性的 —— 不使用 `time.Now()` 或 `math.Rand()`。

## 关联需求

| 类型 | 编号 | 出处 | 说明 |
|------|------|------|------|
| FR | FR-005 | SPEC.md §7 | FakeClock：可控制时间的时钟 |
| FR | FR-006 | SPEC.md §7 | FakeBreaker：可控制熔断状态 |
| BR | BR-001 | SPEC.md §8 | 编译期接口检查（FakeBreaker） |
| BR | BR-002 | SPEC.md §8 | 行为确定性 |
| TC | TC-005 | SPEC.md §16.4 | FakeClock 确定性 |
| TC | TC-006 | SPEC.md §16.4 | FakeBreaker 编译期检查 |

## 接口契约

### FakeClock

```go
type FakeClock struct { /* ... */ }

func FakeClock(at time.Time) *FakeClock
func (c *FakeClock) Now() time.Time
func (c *FakeClock) Advance(d time.Duration)
func (c *FakeClock) Set(t time.Time)
```

行为规范（来自 SPEC FR-005）：

```gherkin
WHEN 调用 FakeClock(at) 创建时钟
THEN Now() 返回 at

WHEN 调用 fakeClock.Advance(d)
THEN Now() 返回 at + d

WHEN 调用 fakeClock.Set(t)
THEN Now() 返回 t
```

### FakeBreaker

```go
func FakeBreaker(initial resiliencx.BreakerState) resiliencx.Breaker
```

行为规范（来自 SPEC FR-006）：

```gherkin
WHEN 调用 FakeBreaker(initial) 创建熔断器
THEN 返回 resiliencx.Breaker，状态为 initial
```

## 文件清单

### 1. `fake_clock.go`

实现要点：
- 内部维护 `time.Time` 而非调用 `time.Now()`
- `sync.Mutex` 保护并发访问
- `Advance(d)` 推进时间
- `Set(t)` 设置绝对时间
- `After(d)` 立即触发的 channel（基于内部时钟）

### 2. `fake_breaker.go`

实现要点：
- 内部 `CircuitState` + `sync.Mutex`
- 实现 `resiliencx.Breaker` 接口：`State`/`Execute`/`RecordSuccess`/`RecordFailure`
- `SetState(s resiliencx.BreakerState)` 设置熔断状态
- `Execute` 受状态控制：Open 时返回 ErrCircuitOpen
- 编译期断言行：`var _ resiliencx.Breaker = (*FakeBreakerImpl)(nil)`

### 3. `fake_clock_test.go`

| 测试用例 | 说明 |
|----------|------|
| `TestFakeClock_Now` | Now() 返回初始时间 |
| `TestFakeClock_Advance` | Advance 后 Now() 推进 |
| `TestFakeClock_Set` | Set 后 Now() 返回新时间 |
| `TestFakeClock_MultipleAdvance` | 多次 Advance 累加正确 |
| `TestFakeClock_Deterministic` | 不调用 time.Now() |
| `TestFakeClock_Concurrent` | 并发安全 |

### 4. `fake_breaker_test.go`

| 测试用例 | 说明 |
|----------|------|
| `TestFakeBreaker_SetState` | SetState(Open) 后 State() 返回 Open |
| `TestFakeBreaker_Execute_Open` | Open 时 Execute 返回 ErrCircuitOpen |
| `TestFakeBreaker_Execute_Closed` | Closed 时 Execute 正常执行 |
| `TestFakeBreaker_Execute_HalfOpen` | Half-Open 时 Execute 正常执行 |
| `TestFakeBreaker_RecordSuccess` | RecordSuccess 后状态保持 |

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-FC-01 | FR-005 | `go test -run TestFakeClock -v -race ./...` | 全部通过 |
| AC-FB-01 | FR-006 | `go test -run TestFakeBreaker -v -race ./...` | 全部通过 |
| AC-FB-02 | BR-001 | `go build ./...` | 编译通过（接口断言检查） |
| AC-FB-03 | BR-002 | `grep -E "time\.Now\|math\.Rand" fake_clock.go fake_breaker.go` | 无匹配 |

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./...` | 编译通过 |
| `go test -race -count=1 ./...` | 全部通过，无 data race |
| `go vet ./...` | 无警告 |
| `grep "var _ resiliencx.Breaker" fake_breaker.go` | 找到编译期断言 |

## 禁止事项

- 不要在 FakeClock 中调用 `time.Now()`（使用内部 time.Time）
- 不要在 FakeClock 中使用 `time.Sleep`
- 不要在 FakeBreaker 中模拟真实的故障统计
- 不要遗漏任何 resiliencx.Breaker 接口方法

## 证据回填

完成后提交以下产物：

1. `go test -v -race ./...` 完整输出
2. `go build ./...` 输出
3. `grep "var _ resiliencx.Breaker" fake_breaker.go` 输出
4. 文件变更清单：`git diff --stat HEAD`

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入 `docs/evidence/`
3. 更新 TASK-TESTKITX-005 状态为 completed
