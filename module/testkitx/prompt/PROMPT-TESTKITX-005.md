# TASK-TESTKITX-005 开发 Prompt

> FakeClock + FakeBreaker 实现：可控时间 + 可控熔断状态
>
> 上游 Task：[TASK-TESTKITX-005.md](../tasks/TASK-TESTKITX-005.md)
> 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
> 规格：[SPEC.md](../SPEC.md) §7 FR-005、FR-006、§9.5、§9.6

---

## 任务

实现 `FakeClock`（可控制时间的时钟）和 `FakeBreaker`（可控制熔断状态的熔断器）。两个 fake 都必须是确定性的（不调用 `time.Now()` 或 `math.Rand()`）。

## 关联需求

| 类型 | 编号 | 出处 | 说明 |
|------|------|------|------|
| FR | FR-005 | SPEC.md §7 | FakeClock：可控制时间的时钟 |
| FR | FR-006 | SPEC.md §7 | FakeBreaker：可控制熔断状态 |
| BR | BR-001 | SPEC.md §8 | 编译期接口检查 |
| BR | BR-002 | SPEC.md §8 | fake 行为确定性，不引入 `time.Now()` 或 `math.Rand()` |
| AC | AC-005 | TRACEABILITY.md §5 | FakeClock Now() 返回可控时间 |
| AC | AC-006 | TRACEABILITY.md §5 | FakeBreaker 可控状态 |

## 文件清单

### 1. `fake_clock.go`

- `FakeClock` 结构体：内部 `time.Time` + `sync.Mutex`
- `FakeClock(at time.Time) *FakeClock` 工厂函数
- `Now() time.Time` 返回当前时钟时间
- `Advance(d time.Duration)` 推进时间
- `Set(t time.Time)` 设置时间
- `After(d time.Duration) <-chan time.Time`：立即触发的 channel

### 2. `fake_breaker.go`

- `FakeBreakerImpl` 结构体：内部 `CircuitState` + `sync.Mutex`
- `FakeBreaker(initial resiliencx.BreakerState) resiliencx.Breaker` 工厂函数
- 实现 `resiliencx.Breaker` 接口：`State`/`Execute`/`RecordSuccess`/`RecordFailure`
- `SetState(s resiliencx.BreakerState)` 设置熔断状态
- 编译期接口检查：`var _ resiliencx.Breaker = (*FakeBreakerImpl)(nil)`

### 3. `fake_clock_test.go`

- `TestFakeClock_Now`：Now() 返回初始时间
- `TestFakeClock_Advance`：Advance 后 Now() 推进
- `TestFakeClock_Set`：Set 后 Now() 返回新时间
- `TestFakeClock_Deterministic`：不依赖真实 time.Now

### 4. `fake_breaker_test.go`

- `TestFakeBreaker_SetState`：SetState(Open) 后 State() 返回 Open
- `TestFakeBreaker_Execute_Open`：Open 时 Execute 返回 ErrCircuitOpen
- `TestFakeBreaker_Execute_Closed`：Closed 时 Execute 正常执行
- `TestFakeBreaker_RecordSuccess`：RecordSuccess 后状态保持

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-005-01 | FR-005 | `go test -run TestFakeClock -v -count=1` | 全部通过 |
| AC-005-02 | FR-006 | `go test -run TestFakeBreaker -v -count=1` | 全部通过 |
| AC-005-03 | BR-001 | `go build ./...` | 编译通过（接口断言验证） |
| AC-005-04 | BR-002 | `go test -race -count=1 ./...` | 无 data race |

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./...` | 编译通过 |
| `go test -run "TestFakeClock|TestFakeBreaker" -v -count=1` | 全部测试通过 |
| `go test -race -count=1 ./...` | 无 data race |

## 禁止事项

- 不要在 FakeClock 中调用 `time.Now()`（使用内部 time.Time）
- 不要在 FakeClock 中使用 `time.Sleep`
- 不要在 FakeBreaker 中模拟真实的故障统计
- 不要遗漏任何 resiliencx.Breaker 接口方法

## 证据回填

完成后提交以下产物到 `docs/evidence/TASK-TESTKITX-005/`：

1. `go build ./...` 输出
2. `go test -run "TestFakeClock|TestFakeBreaker" -v -count=1` 输出
3. `go test -race -count=1 ./...` 输出
4. 新建文件清单（路径 + 行数）

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入指定目录
3. 更新 TASK-TESTKITX-005 状态为 completed
