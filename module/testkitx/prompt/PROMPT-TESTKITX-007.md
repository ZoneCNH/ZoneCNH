# PROMPT-TESTKITX-007

> GoldenUpdate 实现

```yaml
prompt_id: PROMPT-TESTKITX-007
task_ref: TASK-TESTKITX-007
spec_ref:
  - "module/testkitx/SPEC.md#FR-008 (GoldenUpdate)"
  - "module/testkitx/SPEC.md#9.7 (辅助函数)"
  - "module/testkitx/SPEC.md#BR-004 (GOLDEN_UPDATE=1 环境变量控制)"
  - "module/testkitx/SPEC.md#BR-007 (golden 文件不泄露 secret)"
  - "module/testkitx/SPEC.md#TC-008 (GoldenUpdate)"
task_files:
  - "golden.go"
  - "golden_test.go"
depends_on:
  - "TASK-TESTKITX-000"
```

---

## 任务

实现 Golden 文件测试辅助功能。提供 `GoldenUpdate()` 环境变量检查，以及 golden file 比较/更新逻辑。`GOLDEN_UPDATE=1` 环境变量控制是否更新 golden 文件，CI 中禁止设置该环境变量。

## 关联需求

| 类型 | 编号 | 出处 | 说明 |
|------|------|------|------|
| FR | FR-008 | SPEC.md §7 | GoldenUpdate：环境变量控制的 golden file 更新 |
| BR | BR-004 | SPEC.md §8 | GoldenUpdate() 只在 GOLDEN_UPDATE=1 下返回 true |
| BR | BR-007 | SPEC.md §8 | golden 文件不泄露 secret |
| TC | TC-008 | SPEC.md §16.4 | GOLDEN_UPDATE=1 → 更新 golden file |

## 接口契约

```go
// GoldenUpdate 检查是否应更新 golden 文件
func GoldenUpdate() bool

// GoldenFile 返回 golden file 的完整路径
func GoldenFile(t *testing.T, name string) string

// GoldenCheck 比较实际输出与 golden file
// GOLDEN_UPDATE=1 时更新文件，否则断言一致
func GoldenCheck(t *testing.T, name string, got []byte)
```

行为规范（来自 SPEC FR-008 + BR-004）：

```gherkin
WHEN 环境变量 GOLDEN_UPDATE=1
THEN GoldenUpdate() 返回 true

WHEN 环境变量 GOLDEN_UPDATE 未设置
THEN GoldenUpdate() 返回 false
```

## 文件清单

### 1. `golden.go`

实现要点：
- `GoldenUpdate()` 检查 `os.Getenv("GOLDEN_UPDATE") == "1"`
- `GoldenFile(t, name)` 返回 `testdata/<name>.golden` 路径
- `GoldenCheck(t, name, got)` 读取 golden file 比较：
  - 若 `GOLDEN_UPDATE=1`：写入新内容
  - 否则：`bytes.Equal` 比较，不一致则 t.Errorf
  - 更新 golden file 时自动检查 secret 模式（gitleaks-compatible）
- 使用 `t.Helper()` 标记辅助函数

边界场景：
- golden file 不存在时：`GOLDEN_UPDATE=1` → 创建；否则 → fail
- 内容为空时：正常比较
- 路径遍历攻击防护：name 不能包含 `..`

### 2. `golden_test.go`

| 测试用例 | 说明 |
|----------|------|
| `TestGoldenUpdate_Default` | 未设置环境变量 → false |
| `TestGoldenUpdate_Enabled` | `GOLDEN_UPDATE=1` → true |
| `TestGoldenCheck_Match` | 内容匹配 → 通过 |
| `TestGoldenCheck_Mismatch` | 内容不匹配 → fail |
| `TestGoldenCheck_Update` | `GOLDEN_UPDATE=1` 时更新文件 |
| `TestGoldenCheck_NewFile` | golden file 不存在 + `GOLDEN_UPDATE=1` → 创建 |

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-GU-01 | FR-008 | `go test -run TestGolden -v ./...` | 全部通过 |
| AC-GU-02 | BR-004 | `GOLDEN_UPDATE=1 go test -run TestGoldenUpdate_Enabled -v ./...` | GoldenUpdate() = true |
| AC-GU-03 | BR-007 | `GOLDEN_UPDATE=1 go test -run TestGoldenCheck_Update -v ./... && gitleaks detect --no-git` | golden 文件无 secret |

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./...` | 编译通过 |
| `go test -run TestGolden -v ./...` | 全部通过 |
| `GOLDEN_UPDATE=0 go test -run TestGoldenUpdate_Default -v ./...` | GoldenUpdate() = false |
| `gitleaks detect --no-git` | 无 secret 泄露 |

## 禁止事项

- 不要在 CI 中设置 `GOLDEN_UPDATE=1`
- 不要在 golden file 中存储 secret 或 API key
- 不要使用相对路径读取 golden file（使用 `testdata/` 固定目录）
- 不要让 name 参数包含路径遍历字符（`../`）

## 证据回填

完成后提交以下产物：

1. `go test -v -race ./...` 完整输出
2. `go build ./...` 输出
3. `gitleaks detect --no-git` 输出
4. 文件变更清单：`git diff --stat HEAD`

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入 `docs/evidence/`
3. 更新 TASK-TESTKITX-007 状态为 completed
