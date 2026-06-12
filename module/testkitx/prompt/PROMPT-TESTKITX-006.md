# PROMPT-TESTKITX-006

> Eventually 实现

```yaml
prompt_id: PROMPT-TESTKITX-006
task_ref: TASK-TESTKITX-006
spec_ref:
  - "module/testkitx/SPEC.md#FR-007 (Eventually)"
  - "module/testkitx/SPEC.md#9.7 (辅助函数)"
  - "module/testkitx/SPEC.md#BR-003 (使用 testing.T 而非 panic)"
  - "module/testkitx/SPEC.md#TC-007 (Eventually 收敛)"
matrix_ref:
  - "module/testkitx/TRACEABILITY.md"
task_files:
  - "eventually.go"
  - "eventually_test.go"
depends_on:
  - "TASK-TESTKITX-000"
```

---

## 任务

实现 Eventually 断言函数 —— 轮询条件直到满足或超时。使用 `testing.T` 报告失败（非 `panic`），失败时输出清晰诊断（超时时间、轮询次数、最后状态）。

## 关联需求

| 类型   | 编号   | 出处          | 说明                                          |
| ------ | ------ | ------------- | --------------------------------------------- |
| FR     | FR-007 | SPEC.md §7    | Eventually：轮询条件直到满足或超时            |
| BR     | BR-003 | SPEC.md §8    | 使用 testing.T 而非 panic，失败时输出清晰诊断 |
| TC     | TC-007 | SPEC.md §16.4 | Eventually 收敛/超时两种场景                  |

## 接口契约

```go
// EventuallyOption 配置选项
type EventuallyOption func(*eventuallyConfig)

// Eventually 轮询 fn 直到返回 true 或超时
func Eventually(t *testing.T, fn func() bool, opts ...EventuallyOption)

// WithTimeout 设置超时（默认 5s）
func WithTimeout(d time.Duration) EventuallyOption

// WithInterval 设置轮询间隔（默认 100ms）
func WithInterval(d time.Duration) EventuallyOption
```

行为规范（来自 SPEC FR-007 + BR-003）：

```gherkin
WHEN 调用 Eventually(t, fn, timeout, interval) 且 fn 在 timeout 内返回 true
THEN 测试通过

WHEN 调用 Eventually(t, fn, timeout, interval) 且 fn 超时仍返回 false
THEN 测试失败，使用 t.Errorf 输出清晰诊断
```

## 文件清单

### 1. `eventually.go`

实现要点：
- 默认 timeout = 5s，默认 interval = 100ms
- 使用 `time.Ticker` 轮询（每次 tick 检查 fn）
- 使用 `select` + `time.After` 处理超时
- 失败诊断包含：超时时间、总轮询次数
- fn 为 nil 时不 panic，使用 t.Errorf 报告

边界场景：
- `timeout = 0`：立即检查一次，不等待
- fn 快速返回：不等待完整超时

### 2. `eventually_test.go`

| 测试用例                        | 说明                             |
| ------------------------------- | -------------------------------- |
| `TestEventually_ImmediatePass`  | fn 首次调用返回 true → 立即通过  |
| `TestEventually_DelayedPass`    | fn 在 3 次轮询后返回 true → 通过 |
| `TestEventually_Timeout`        | fn 始终返回 false → 超时 fail    |
| `TestEventually_ZeroTimeout`    | timeout=0 → 立即检查一次         |
| `TestEventually_CustomInterval` | WithInterval 自定义间隔生效      |
| `TestEventually_CustomTimeout`  | WithTimeout 自定义超时生效       |

## 验收标准

| AC       | 关联   | 验证命令                                     | 预期结果              |
| -------- | ------ | -------------------------------------------- | --------------------- |
| AC-EV-01 | FR-007 | `go test -run TestEventually -v -race ./...` | 全部通过              |
| AC-EV-02 | BR-003 | `grep -c "t\.Errorf" eventually.go`          | >= 1（使用 t.Errorf） |
| AC-EV-03 | BR-003 | `grep -c "panic" eventually.go`              | = 0（不使用 panic）   |

## 验证命令

| 命令                           | 判定标准   |
| ------------------------------ | ---------- |
| `go build ./...`               | 编译通过   |
| `go test -race -count=1 ./...` | 全部通过   |
| `go vet ./...`                 | 无警告     |

## 禁止事项

- 不要使用 `panic` 或 `t.Fatal` 报告超时（违反 BR-003）
- 不要使用 `time.Sleep` 循环（使用 ticker + select）
- fn 为 nil 时不要 panic（使用 t.Errorf）

## 证据回填

完成后提交以下产物：

1. `go test -v -race ./...` 完整输出
2. `go build ./...` 输出
3. `go vet ./...` 输出
4. 文件变更清单：`git diff --stat HEAD`

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入 `docs/evidence/`
3. 更新 TASK-TESTKITX-006 状态为 completed
