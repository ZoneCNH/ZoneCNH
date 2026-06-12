# PLAN-TESTKITX-009

> GoroutineLeakCheck 实现计划
>
> 对应 Task：`module/testkitx/tasks/TASK-TESTKITX-009.md`
> 对应 Spec：`module/testkitx/SPEC.md#FR-010`, `SPEC.md#9.8`, `SPEC.md#13`

---

## 1. Task 摘要

```yaml
task_id: TASK-TESTKITX-009
scope: "实现 GoroutineLeakCheck，检测测试中的 goroutine 泄漏"
priority: P1
estimated_effort: "1h"
depends_on: [TASK-TESTKITX-000]
blocks: [TASK-TESTKITX-010]
```

---

## 2. 覆盖需求

| 需求     | 描述                                  | AC                                          |
| -------- | ------------------------------------- | ------------------------------------------- |
| FR-010   | GoroutineLeakCheck goroutine 泄漏检测 | AC-010: 无泄漏 → pass；有泄漏 → fail + 堆栈 |
| SPEC §13 | Edge Case: 测试后无新增 goroutine     | 通过                                        |

---

## 3. 接口契约

```go
// SPEC §9.8
func GoroutineLeakCheck(t *testing.T)
```

---

## 4. 实现步骤

### Step 1: 实现 GoroutineLeakCheck

**目标文件**：`leak.go`

**实现要点**：
- 在 `t.Cleanup` 中注册检查函数（确保测试结束后自动执行）
- 记录测试开始时的 goroutine 数量：`runtime.NumGoroutine()`
- 测试结束后比较 goroutine 数量
- 差异 > 阈值（如 5）时报告泄漏
- 泄漏时输出 goroutine 堆栈：`runtime.Stack(buf, true)`（all goroutines）
- 使用 `t.Helper()` 标记

**实现细节**：
```go
func GoroutineLeakCheck(t testing.TB) {
    t.Helper()

    start := runtime.NumGoroutine()

    t.Cleanup(func() {
        // 等待短暂时间让 goroutine 有机会退出
        time.Sleep(100 * time.Millisecond)

        end := runtime.NumGoroutine()
        leaked := end - start

        if leaked > 5 { // 允许 5 个以内的 runtime goroutine 差异
            buf := make([]byte, 1<<20)
            n := runtime.Stack(buf, true)
            t.Errorf("testkitx: goroutine leak detected: %d goroutines leaked (start=%d, end=%d)\n\nGoroutine stacks:\n%s",
                leaked, start, end, buf[:n])
        }
    })
}
```

### Step 2: 处理误报

**实现要点****：
- 允许少量 runtime goroutine 差异（如 GC worker、finalizer 等）
- 阈值可配置：`GoroutineLeakCheckWithThreshold(t, threshold)`
- 过滤已知的 runtime goroutine 模式（可选优化）

### Step 3: 编写单元测试

**目标文件**：`leak_test.go`

**测试用例**：

| 用例                                      | 描述       | 验证点                  |
| ----------------------------------------- | ---------- | ----------------------- |
| TestGoroutineLeakCheck_NoLeak             | 无泄漏     | Cleanup 不报错          |
| TestGoroutineLeakCheck_LeakDetected       | 有泄漏     | Cleanup 报错 + 输出堆栈 |
| TestGoroutineLeakCheck_ThresholdRespected | 阈值内差异 | 不报错                  |

**注意**：泄漏场景测试需要启动一个不结束的 goroutine。需要在子测试中验证，避免影响其他测试。

---

## 5. 验证汇总

```bash
go build ./...
go test -run TestGoroutineLeakCheck -race -count=1 -v ./...
```

**通过标准**：编译通过 + 全部测试通过 + 无 data race。

---

## 6. 风险与回滚

| 风险                           | 概率   | 影响   | 缓解                        | 回滚         |
| ------------------------------ | ------ | ------ | --------------------------- | ------------ |
| 误报（runtime goroutine 波动） | Medium | Medium | 阈值 5 + 可配置             | 调整阈值     |
| 漏报（缓慢泄漏）               | Low    | Medium | 100ms 等待 + 可配置等待时间 | 增加等待时间 |
| Cleanup 中 panic               | Low    | Medium | 使用 recover 保护           | 添加 recover |

**回滚路径**：本 task 仅新增文件，回滚 = `rm leak.go leak_test.go`。
