# PLAN-TESTKITX-006

> Eventually + assert API 实现计划
>
> 对应 Task：`module/testkitx/tasks/TASK-TESTKITX-006.md`
> 对应 Spec：`module/testkitx/SPEC.md#FR-007`, `SPEC.md#9.7`, `SPEC.md#13`

---

## 1. Task 摘要

```yaml
task_id: TASK-TESTKITX-006
scope: "实现 Eventually 轮询断言函数和统一 assert API"
priority: P0
estimated_effort: "1h"
depends_on: [TASK-TESTKITX-000]
blocks: [TASK-TESTKITX-010]
```

---

## 2. 覆盖需求

| 需求     | 描述                      | AC                        |
| -------- | ------------------------- | ------------------------- |
| FR-007   | Eventually 轮询条件断言   | AC-007: 成功/超时两种场景 |
| BR-003   | 使用 testing.T 而非 panic | 失败时输出清晰诊断        |
| SPEC §13 | Edge Case: timeout=0      | 立即检查一次，不等待      |

---

## 3. 接口契约

```go
// SPEC §9.7
func Eventually(t *testing.T, fn func() bool, timeout, interval time.Duration)
```

默认值：timeout=5s, interval=100ms。推荐使用 Option 模式：

```go
func Eventually(t testing.TB, fn func() bool, opts ...EventuallyOption)

type EventuallyOption func(*eventuallyConfig)

func WithTimeout(d time.Duration) EventuallyOption
func WithInterval(d time.Duration) EventuallyOption
```

---

## 4. 实现步骤

### Step 1: 实现 assert API

**目标文件**：`assert.go`

**实现要点**：
- 统一的 assert 函数集，签名使用 `testing.TB`
- 提供常用断言：`Equal`, `NotEqual`, `Nil`, `NotNil`, `True`, `False`, `Error`, `NoError`, `Contains`, `NotContains`
- 失败时调用 `t.Helper()` 标记为辅助函数，使测试输出指向调用方

### Step 2: 实现 Eventually

**目标文件**：`eventually.go`

**实现要点**：
- 使用 `time.Ticker` 轮询（而非 `time.Sleep` 循环，更精确）
- 默认 timeout=5s, interval=100ms
- 支持 Option 模式配置 timeout 和 interval
- 超时时输出清晰诊断信息：
  - 实际等待时间
  - 轮询次数
  - 条件函数最后一次返回值
- 使用 `t.Helper()` 使失败输出指向调用方
- **不用 panic**，一切通过 `t.Errorf` / `t.Fatalf` 报告失败

**边界处理**：
- `timeout=0`：立即检查一次，不等待
- `interval >= timeout`：至少轮询一次
- fn 为 nil：立即 `t.Fatal`

### Step 3: 编写单元测试

**目标文件**：`eventually_test.go`

**测试用例**：

| 用例                            | 描述            | 验证点                     |
| ------------------------------- | --------------- | -------------------------- |
| TestEventually_ImmediateSuccess | 条件立即满足    | 不超时，通过               |
| TestEventually_DelayedSuccess   | 条件延迟满足    | 轮询后通过                 |
| TestEventually_Timeout          | 条件永不满足    | 超时失败                   |
| TestEventually_ZeroTimeout      | timeout=0       | 立即检查一次               |
| TestEventually_CustomInterval   | 自定义 interval | 按配置轮询                 |
| TestEventually_NilFunc          | fn 为 nil       | 立即失败                   |
| TestEventually_DiagnosticOutput | 超时诊断        | 输出包含等待时间和轮询次数 |

---

## 5. 验证汇总

```bash
go build ./...
go test -run TestEventually -race -count=1 -v ./...
```

**通过标准**：编译通过 + 全部测试通过 + 无 data race。

---

## 6. 风险与回滚

| 风险                   | 概率   | 影响   | 缓解                                             | 回滚             |
| ---------------------- | ------ | ------ | ------------------------------------------------ | ---------------- |
| 测试不稳定（flaky）    | Medium | Low    | 测试中使用短 timeout(100ms)；CI 中给足够 timeout | 调整测试 timeout |
| time.Ticker 未正确停止 | Low    | Medium | defer ticker.Stop()                              | 添加 defer       |

**回滚路径**：本 task 仅新增文件，回滚 = `rm assert.go eventually.go eventually_test.go`。
