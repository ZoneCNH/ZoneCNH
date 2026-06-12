# TASK-TESTKITX-009 开发 Prompt

> GoroutineLeakCheck 实现：goroutine 泄漏检测
>
> 上游 Task：[TASK-TESTKITX-009.md](../tasks/TASK-TESTKITX-009.md)
> 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
> 规格：[SPEC.md](../SPEC.md) §7 FR-010、§9.8

---

## 任务

实现 `GoroutineLeakCheck`，检测测试结束后是否有 goroutine 泄漏。在测试开始时记录 goroutine 数量，测试结束后比较，如有泄漏则报告 goroutine 堆栈。

## 关联需求

| 类型 | 编号 | 出处 | 说明 |
|------|------|------|------|
| FR | FR-010 | SPEC.md §7 | GoroutineLeakCheck：goroutine 泄漏检测 |
| AC | AC-010 | TRACEABILITY.md §5 | 测试后无新增 goroutine -> pass；有泄漏 -> fail + 堆栈 |

## 文件清单

### 1. `leakcheck.go`

- `GoroutineLeakCheck(t *testing.T)`：注册 `t.Cleanup` 钩子
  - 在调用时记录 `runtime.NumGoroutine()`
  - 在 `t.Cleanup` 中再次获取 goroutine 数量
  - 比较差值，如有新增则 `t.Errorf` 输出泄漏的 goroutine 堆栈
  - 允许少量差异（runtime 自身 goroutine）
- `ErrGoroutineLeak` 公共错误变量
- `GoroutineLeakCheckWithThreshold(t *testing.T, threshold int)`：可配置阈值

### 2. `leakcheck_test.go`

- `TestGoroutineLeakCheck_NoLeak`：无泄漏 -> 通过
- `TestGoroutineLeakCheck_WithLeak`：有泄漏 -> fail + 堆栈输出
- `TestGoroutineLeakCheck_Threshold`：阈值内差异 -> 通过

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-009-01 | FR-010 | `go test -run TestGoroutineLeakCheck -v -count=1` | 全部通过 |
| AC-009-02 | FR-010 | `go vet ./...` | 无警告 |

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./...` | 编译通过 |
| `go test -run TestGoroutineLeakCheck -v -count=1` | 全部测试通过 |
| `go vet ./...` | 无警告 |

## 禁止事项

- 不要在生产代码中调用 GoroutineLeakCheck（仅限于 test 文件）
- 不要在 GoroutineLeakCheck 中使用 `panic`（使用 t.Errorf）
- 不要硬编码阈值，使用参数化配置

## 证据回填

完成后提交以下产物到 `docs/evidence/TASK-TESTKITX-009/`：

1. `go build ./...` 输出
2. `go test -run TestGoroutineLeakCheck -v -count=1` 输出
3. `go vet ./...` 输出
4. 新建文件清单（路径 + 行数）

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入指定目录
3. 更新 TASK-TESTKITX-009 状态为 completed
