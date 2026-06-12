# TASK-KERNEL-002 开发 Prompt

> timex 子包：时钟抽象 — Clock 接口 + RealClock / FixedClock / FakeClock

---

## 任务

实现 `kernel/timex` 子包。timex 提供可注入的 Clock 接口及三种实现，纯 stdlib，不依赖其他 kernel 子包。

## 文件清单

### 1. `timex/timex.go`

- `Clock` 接口：`Now() time.Time` 单一方法
- `RealClock`：`NewRealClock()`，`Now()` 返回 `time.Now()`
- `FixedClock`：值类型，`NewFixedClock(now)`，`Now()` 始终返回构造时时间
- `FakeClock`：指针类型，`NewFakeClock(now)`，`Advance(d)` 推进内部时间，零值安全

### 2. `timex/timex_test.go`

覆盖：RealClock 使用系统时间、FixedClock 不可变、FakeClock Advance 累积、nil *FakeClock 零值安全、并发 Advance。

### 3. `timex/example_test.go`

展示 Clock 注入模式：生产用 RealClock，测试用 FakeClock。

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-011 | FR-007 | `go test -run TestFakeClock -count=1 ./timex/...` | Advance 后 Now 正确 |
| AC-TIMEX-01 | FR-007 | `go test -run TestFixedClock -count=1 ./timex/...` | 始终返回构造时间 |
| AC-TIMEX-02 | BR-012 | nil *FakeClock.Now() | 返回 time.Time{} |

## 禁止事项

- 不要依赖非 stdlib 包
- 不要依赖其他 kernel 子包
- FakeClock.Advance 不接受负 duration
- 不要使用 `time.Now()` 在 FixedClock/FakeClock 中

## 证据回填

完成后提交到 `docs/evidence/2026-06-12/TASK-KERNEL-002/`：
1. `go test -race -count=1 ./timex/...` 输出
2. `go vet ./timex/...` 输出
3. Benchmark 结果

## 完成后

1. 运行 `go test -race -count=1 ./timex/...` 确认通过
2. 运行 `go vet ./timex/...` 确认无警告
3. 更新 TASK-KERNEL-002 状态为 completed
