# PROMPT-TESTKITX-009

> GoroutineLeakCheck 实现

```yaml
prompt_id: PROMPT-TESTKITX-009
task_ref: TASK-TESTKITX-009
spec_ref:
  - "module/testkitx/SPEC.md#FR-010 (GoroutineLeakCheck)"
  - "module/testkitx/SPEC.md#9.8 (边界扫描)"
  - "module/testkitx/SPEC.md#TC-010 (GoroutineLeakCheck)"
task_files:
  - "leakcheck.go"
  - "leakcheck_test.go"
depends_on:
  - "TASK-TESTKITX-000"
```

---

## 任务

实现 GoroutineLeakCheck —— 在测试中检测 goroutine 泄漏。在测试开始时记录 goroutine 数量，通过 `t.Cleanup` 在测试结束后比较。如有泄漏，报告泄漏的 goroutine 堆栈。

## 关联需求

| 类型 | 编号 | 出处 | 说明 |
|------|------|------|------|
| FR | FR-010 | SPEC.md §7 | GoroutineLeakCheck：goroutine 泄漏检测 |
| TC | TC-010 | SPEC.md §16.4 | 测试后无新增 goroutine → pass；有泄漏 → fail + 堆栈 |

## 接口契约

```go
var ErrGoroutineLeak = errors.New("testkitx: goroutine leak detected")

// GoroutineLeakCheck 注册 t.Cleanup 钩子检测 goroutine 泄漏
// 在调用时记录 goroutine 数，在 Cleanup 中比较差值
func GoroutineLeakCheck(t *testing.T)

// GoroutineLeakCheckWithThreshold 允许指定差异阈值
func GoroutineLeakCheckWithThreshold(t *testing.T, threshold int)
```

行为规范（来自 SPEC FR-010）：

```gherkin
WHEN 调用 GoroutineLeakCheck(t) 且测试结束后有 goroutine 泄漏
THEN 测试失败（t.Errorf），报告泄漏的 goroutine 堆栈

WHEN 调用 GoroutineLeakCheck(t) 且无泄漏
THEN 测试通过
```

## 文件清单

### 1. `leakcheck.go`

实现要点：
- `GoroutineLeakCheck(t *testing.T)` 注册 `t.Cleanup` 钩子
- 调用时 `before := runtime.NumGoroutine()`
- Cleanup 时 `after := runtime.NumGoroutine()`
- 差值 `after - before > 0` → `t.Errorf` 输出泄漏 goroutine 堆栈
- 使用 `runtime.Stack(buf, true)` 获取所有 goroutine 堆栈
- 默认阈值 = 0（不允许任何泄漏）
- `t.Helper()` 标记辅助函数

边界场景：
- runtime 自身 goroutine 的差异处理（允许少量差异，默认阈值 0）
- 在子测试中使用
- 并发安全（从多个 goroutine 调用 Cleanup 钩子）

### 2. `leakcheck_test.go`

| 测试用例 | 说明 |
|----------|------|
| `TestGoroutineLeakCheck_NoLeak` | 无泄漏 → 通过 |
| `TestGoroutineLeakCheck_WithLeak` | 有泄漏 → fail + 堆栈 |
| `TestGoroutineLeakCheck_Threshold` | 阈值内差异 → 通过 |
| `TestGoroutineLeakCheck_Subtest` | 子测试中正确检测 |

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-GL-01 | FR-010 | `go test -run TestGoroutineLeakCheck -v -race ./...` | 全部通过 |
| AC-GL-02 | FR-010 | `go test -run TestGoroutineLeakCheck_WithLeak -v ./...` | 检测到泄漏，输出堆栈 |

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./...` | 编译通过 |
| `go test -race -count=1 ./...` | 全部通过 |
| `go vet ./...` | 无警告 |

## 禁止事项

- 不要在生产代码中调用 GoroutineLeakCheck（仅限 test 文件）
- 不要在 GoroutineLeakCheck 中使用 `panic`（使用 t.Errorf）
- 不要硬编码阈值（使用参数化配置）
- 不要在 Cleanup 钩子中启动新的 goroutine

## 证据回填

完成后提交以下产物：

1. `go test -v -race ./...` 完整输出
2. `go build ./...` 输出
3. `go vet ./...` 输出
4. 文件变更清单：`git diff --stat HEAD`

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入 `docs/evidence/`
3. 更新 TASK-TESTKITX-009 状态为 completed
