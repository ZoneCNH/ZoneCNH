# TASK-TESTKITX-006 开发 Prompt

> Eventually 实现：轮询条件直到满足或超时
>
> 上游 Task：[TASK-TESTKITX-006.md](../tasks/TASK-TESTKITX-006.md)
> 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
> 规格：[SPEC.md](../SPEC.md) §7 FR-007、§9.7

---

## 任务

实现 `Eventually` 断言函数，轮询条件直到满足或超时。使用 `testing.T` 报告失败（非 `panic`），失败时输出清晰诊断。

## 关联需求

| 类型 | 编号 | 出处 | 说明 |
|------|------|------|------|
| FR | FR-007 | SPEC.md §7 | Eventually：轮询条件 |
| BR | BR-003 | SPEC.md §8 | 使用 testing.T 而非 panic，失败输出清晰诊断 |
| AC | AC-007 | TRACEABILITY.md §5 | fn 在 timeout 内返回 true -> 通过；超时 -> fail + 诊断 |

## 文件清单

### 1. `eventually.go`

- `Eventually(t *testing.T, fn func() bool, opts ...EventuallyOption)` 轮询断言
- `WithTimeout(d time.Duration) EventuallyOption` 设置超时（默认 5s）
- `WithInterval(d time.Duration) EventuallyOption` 设置轮询间隔（默认 100ms）
- 使用 `time.Ticker` 轮询，超时后 `t.Errorf` 输出清晰诊断
- 诊断信息包含：超时时间、轮询次数、最后一次 fn 状态

### 2. `eventually_test.go`

- `TestEventually_ImmediatePass`：条件立即满足 -> 通过
- `TestEventually_DelayedPass`：条件延迟满足（within timeout）-> 通过
- `TestEventually_Timeout`：超时 -> fail（使用子测试捕获）
- `TestEventually_ZeroTimeout`：timeout=0 时立即检查一次
- `TestEventually_CustomInterval`：自定义轮询间隔生效

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-006-01 | FR-007 | `go test -run TestEventually -v -count=1` | 全部通过 |
| AC-006-02 | BR-003 | 代码审查 | 使用 t.Errorf 而非 panic |

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./...` | 编译通过 |
| `go test -run TestEventually -v -count=1` | 全部测试通过 |
| `go vet ./...` | 无警告 |

## 禁止事项

- 不要使用 `panic` 或 `t.Fatal` 报告超时（BR-003）
- 不要使用 `time.Sleep` 阻塞（使用 ticker）
- 不要在 fn 为 nil 时 panic（返回错误或诊断）

## 证据回填

完成后提交以下产物到 `docs/evidence/TASK-TESTKITX-006/`：

1. `go build ./...` 输出
2. `go test -run TestEventually -v -count=1` 输出
3. `go vet ./...` 输出
4. 新建文件清单（路径 + 行数）

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入指定目录
3. 更新 TASK-TESTKITX-006 状态为 completed
