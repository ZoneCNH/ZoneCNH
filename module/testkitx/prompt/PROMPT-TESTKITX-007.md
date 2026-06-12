# TASK-TESTKITX-007 开发 Prompt

> GoldenUpdate 实现：环境变量控制的 golden file 更新
>
> 上游 Task：[TASK-TESTKITX-007.md](../tasks/TASK-TESTKITX-007.md)
> 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
> 规格：[SPEC.md](../SPEC.md) §7 FR-008、§9.7

---

## 任务

实现 Golden 文件测试辅助功能。提供 `GoldenUpdate()` 环境变量检查，以及 golden file 比较/更新逻辑。必须在 CI 中阻止 golden 文件误更新。

## 关联需求

| 类型 | 编号 | 出处 | 说明 |
|------|------|------|------|
| FR | FR-008 | SPEC.md §7 | GoldenUpdate：环境变量控制 |
| BR | BR-004 | SPEC.md §8 | GoldenUpdate() 只在 GOLDEN_UPDATE=1 下返回 true |
| BR | BR-007 | SPEC.md §8 | golden 文件不泄露 secret |
| AC | AC-008 | TRACEABILITY.md §5 | GOLDEN_UPDATE=1 -> true；未设置 -> false |

## 文件清单

### 1. `golden.go`

- `GoldenUpdate() bool`：检查环境变量 `GOLDEN_UPDATE=1`
- `GoldenCheck(t *testing.T, name string, got []byte)`：比较实际输出与 golden file
  - 读取 `testdata/<name>.golden`
  - 如果 `GOLDEN_UPDATE=1`，写入新内容
  - 否则断言内容一致
- `GoldenFile(t *testing.T, name string) string`：返回 golden file 路径

### 2. `golden_test.go`

- `TestGoldenUpdate_Default`：未设置环境变量 -> GoldenUpdate() 返回 false
- `TestGoldenUpdate_Enabled`：`GOLDEN_UPDATE=1` -> GoldenUpdate() 返回 true
- `TestGoldenCheck_Match`：内容匹配 -> 通过
- `TestGoldenCheck_Mismatch`：内容不匹配 -> fail
- `TestGoldenCheck_Update`：`GOLDEN_UPDATE=1` 时更新文件

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-007-01 | FR-008 | `go test -run TestGoldenUpdate -v -count=1` | 全部通过 |
| AC-007-02 | BR-004 | `GOLDEN_UPDATE=0 go test -run TestGoldenUpdate` | GoldenUpdate() 返回 false |
| AC-007-03 | BR-007 | `gitleaks detect --no-git` | 无 secret 泄露 |

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./...` | 编译通过 |
| `go test -run TestGolden -v -count=1` | 全部测试通过 |
| `GOLDEN_UPDATE=0 go test -run TestGoldenUpdate -v -count=1` | GoldenUpdate() = false |
| `gitleaks detect --no-git` | 无 secret 泄露 |

## 禁止事项

- 不要在 CI 中设置 `GOLDEN_UPDATE=1`
- 不要在 golden file 中存储 secret 或密钥
- 不要使用相对路径读取 golden file（使用 `testdata/` 固定目录）

## 证据回填

完成后提交以下产物到 `docs/evidence/TASK-TESTKITX-007/`：

1. `go build ./...` 输出
2. `go test -run TestGolden -v -count=1` 输出
3. `gitleaks detect --no-git` 输出
4. 新建文件清单（路径 + 行数）

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入指定目录
3. 更新 TASK-TESTKITX-007 状态为 completed
