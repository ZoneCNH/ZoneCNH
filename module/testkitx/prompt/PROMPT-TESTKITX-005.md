# PROMPT-TESTKITX-005

> FakeClock + FakeBreaker 实现

```yaml
prompt_id: PROMPT-TESTKITX-005
task_ref: TASK-TESTKITX-005
spec_ref:
  - "module/testkitx/SPEC.md#FR-005 (FakeClock)"
  - "module/testkitx/SPEC.md#FR-006 (FakeBreaker)"
  - "module/testkitx/SPEC.md#9.5 (FakeClock 接口)"
  - "module/testkitx/SPEC.md#BR-001 (编译期接口检查)"
  - "module/testkitx/SPEC.md#BR-002 (确定性行为)"
  - "module/testkitx/SPEC.md#TC-005 (FakeClock 确定性)"
  - "module/testkitx/SPEC.md#TC-006 (FakeBreaker 编译期检查)"
matrix_ref:
  - "module/testkitx/TRACEABILITY.md"
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

实现 FakeClock（可控制时间的时钟）和 FakeBreaker（可控制状态的熔断器）。

## 关联需求

| 类型   | 编号   | 出处          | 说明                        |
| ------ | ------ | ------------- | --------------------------- |
| FR     | FR-005 | SPEC.md §7    | FakeClock：可控制时间       |
| FR     | FR-006 | SPEC.md §7    | FakeBreaker：可控制熔断状态 |
| BR     | BR-001 | SPEC.md §8    | FakeBreaker 编译期接口检查  |
| BR     | BR-002 | SPEC.md §8    | 行为确定性                  |
| TC     | TC-005 | SPEC.md §16.4 | FakeClock 确定性            |
| TC     | TC-006 | SPEC.md §16.4 | FakeBreaker 编译期检查      |

## 接口契约

### FakeClock

```go
type FakeClock struct { /* ... */ }

func NewFakeClock(at time.Time) *FakeClock
func (c *FakeClock) Now() time.Time
func (c *FakeClock) Advance(d time.Duration)
func (c *FakeClock) Set(t time.Time)
```

行为规范（来自 SPEC FR-005）：

```gherkin
WHEN 调用 FakeClock(at) 创建时钟
THEN 返回 *FakeClock，Now() 返回 at

WHEN 调用 fakeClock.Advance(d)
THEN Now() 返回 at + d

WHEN 调用 fakeClock.Set(t)
THEN Now() 返回 t
```

### FakeBreaker

```go
type FakeBreaker struct { /* ... */ }

func NewFakeBreaker(initial resiliencx.BreakerState) *FakeBreaker
func (b *FakeBreaker) Execute(fn func() error) error
func (b *FakeBreaker) State() resiliencx.BreakerState
func (b *FakeBreaker) SetState(s resiliencx.BreakerState)
```

行为规范（来自 SPEC FR-006）：

```gherkin
WHEN 调用 FakeBreaker(initial) 创建熔断器
THEN 返回 *FakeBreaker，状态为 initial
```

## 文件清单

### 1. `fake_clock.go`

实现要点：
- 内部维护 `time.Time` 字段
- `sync.Mutex` 保护并发访问
- `Advance(d time.Duration)` 在现有时间基础上加 d
- `Set(t time.Time)` 设置绝对时间
- 不调用 `time.Now()`（确定性，违反 BR-002）

边界场景：
- FakeClock 未 Advance 时，Now() 始终返回初始时间

### 2. `fake_breaker.go`

实现要点：
- 内部维护 `BreakerState` 字段
- 实现 `resiliencx.Breaker` 接口
- `SetState(s)` 直接设置状态
- `Execute(fn)` 行为由状态决定：
  - Closed/HalfOpen → 调用 fn，成功返回 nil，失败传递错误
  - Open → 不调用 fn，返回 `ErrCircuitOpen`
- 编译期断言行：`var _ resiliencx.Breaker = (*FakeBreaker)(nil)`

### 3. `fake_clock_test.go`

测试场景：

| 测试用例                        | 说明                |
| ------------------------------- | ------------------- |
| `TestFakeClock_Now`             | 初始时间正确        |
| `TestFakeClock_Advance`         | Advance 后 Now() +d |
| `TestFakeClock_MultipleAdvance` | 多次 Advance 累加   |
| `TestFakeClock_Set`             | Set 绝对时间        |
| `TestFakeClock_Deterministic`   | 不使用 time.Now()   |
| `TestFakeClock_Concurrent`      | 并发安全            |

### 4. `fake_breaker_test.go`

测试场景：

| 测试用例                         | 说明                                  |
| -------------------------------- | ------------------------------------- |
| `TestFakeBreaker_Initial`        | 初始状态正确                          |
| `TestFakeBreaker_Closed_Execute` | Closed 状态 Execute 调用 fn           |
| `TestFakeBreaker_Open_Execute`   | Open 状态 Execute 返回 ErrCircuitOpen |
| `TestFakeBreaker_SetState`       | SetState 改变状态                     |
| `TestFakeBreaker_Interface`      | 编译期接口断言通过                    |

## 验收标准

| AC       | 关联   | 验证命令                                          | 预期结果       |
| -------- | ------ | ------------------------------------------------- | -------------- |
| AC-FC-01 | FR-005 | `go test -run TestFakeClock -v -race ./...`       | 全部通过       |
| AC-FB-01 | FR-006 | `go test -run TestFakeBreaker -v -race ./...`     | 全部通过       |
| AC-CK-02 | BR-002 | `grep -E "time\.Now" fake_clock.go`               | 无匹配         |
| AC-FB-02 | BR-001 | `grep "var _ resiliencx.Breaker" fake_breaker.go` | 找到编译期断言 |

## 验证命令

| 命令                                              | 判定标准               |
| ------------------------------------------------- | ---------------------- |
| `go build ./...`                                  | 编译通过               |
| `go test -race -count=1 ./...`                    | 全部通过，无 data race |
| `go vet ./...`                                    | 无警告                 |
| `grep "var _ resiliencx.Breaker" fake_breaker.go` | 找到编译期断言         |
| `grep -E "time\.Now" fake_clock.go`               | 无匹配（确定性）       |

## 禁止事项

- FakeClock 不要调用 `time.Now()`（违反 BR-002）
- FakeBreaker 不要真正调用外部服务或进行真实熔断逻辑
- 不要遗漏任何 resiliencx.Breaker 接口方法
- FakeBreaker.Open 状态 Execute 必须返回 error（不调用 fn）

## 证据回填

完成后提交以下产物：

1. `go test -v -race ./...` 完整输出
2. `go build ./...` 输出
3. 文件变更清单：`git diff --stat HEAD`

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入 `docs/evidence/`
3. 更新 TASK-TESTKITX-005 状态为 completed
