# PROMPT-TESTKITX-008

> BoundaryCheck 实现

```yaml
prompt_id: PROMPT-TESTKITX-008
task_ref: TASK-TESTKITX-008
spec_ref:
  - "module/testkitx/SPEC.md#FR-009 (BoundaryCheck)"
  - "module/testkitx/SPEC.md#9.8 (边界扫描)"
  - "module/testkitx/SPEC.md#BR-005 (生产 import graph 不含 testkitx)"
  - "module/testkitx/SPEC.md#TC-009 (BoundaryCheck)"
  - "module/testkitx/SPEC.md#20.2 (testkitx 专属 CI Gate)"
matrix_ref:
  - "module/testkitx/TRACEABILITY.md"
task_files:
  - "boundary.go"
  - "boundary_test.go"
depends_on:
  - "TASK-TESTKITX-000"
```

---

## 任务

实现 BoundaryCheck —— 通过 `go list` 验证生产依赖图中不包含 testkitx。检测到边界违规时，报告完整的依赖路径。这是 testkitx 的安全 Gate：确保测试工具不泄露到生产二进制。

## 关联需求

| 类型   | 编号   | 出处          | 说明                                  |
| ------ | ------ | ------------- | ------------------------------------- |
| FR     | FR-009 | SPEC.md §7    | BoundaryCheck：生产包 import 边界扫描 |
| BR     | BR-005 | SPEC.md §8    | 生产 import graph 中不能出现 testkitx |
| TC     | TC-009 | SPEC.md §16.4 | 生产包依赖 testkitx → fail + 路径     |

## 接口契约

```go
var ErrBoundaryViolation = errors.New("testkitx: production dependency on testkitx")

// BoundaryCheck 检查生产包是否依赖 testkitx
// 内部执行 go list -deps 分析依赖图
func BoundaryCheck(t *testing.T, module string)
```

行为规范（来自 SPEC FR-009）：

```gherkin
WHEN 调用 BoundaryCheck(t, module) 且生产包依赖 testkitx
THEN 测试失败，使用 t.Errorf 报告完整依赖路径

WHEN 调用 BoundaryCheck(t, module) 且生产包不依赖 testkitx
THEN 测试通过

WHEN 调用 BoundaryCheck(t, module) 且 module 为 testkitx 自身
THEN 测试通过（testkitx 依赖自己不算违规）
```

## 文件清单

### 1. `boundary.go`

实现要点：
- `BoundaryCheck(t *testing.T, module string)` 执行 `go list -deps <module>/...`
- 过滤 testkitx 自身路径（`github.com/ZoneCNH/testkitx` 自身依赖不算违规）
- 检查生产包路径（排除 `_test` 后缀的测试包）
- 违规时 `t.Errorf` 报告完整的依赖路径链
- 使用 `os/exec` 调用 `go list`，设置超时（30s）
- `t.Helper()` 标记辅助函数

边界场景：
- `go list` 执行失败 → t.Fatalf 报告
- module 参数为空 → 使用当前模块
- 依赖图中包含 testkitx 但仅在 _test.go 中 → 通过

### 2. `boundary_test.go`

| 测试用例                            | 说明                            |
| ----------------------------------- | ------------------------------- |
| `TestBoundaryCheck_Self`            | 检查 testkitx 自身 → 通过       |
| `TestBoundaryCheck_NoViolation`     | 模拟不含 testkitx 的模块 → 通过 |
| `TestBoundaryCheck_DetectViolation` | 验证违规检测逻辑正确            |

## 验收标准

| AC       | 关联   | 验证命令                                                 | 预期结果       |        |
| -------- | ------ | -------------------------------------------------------- | -------------- |        |
| AC-BC-01 | FR-009 | `go test -run TestBoundaryCheck -v ./...`                | 全部通过       |        |
| AC-BC-02 | BR-005 | `go list -deps github.com/ZoneCNH/x.go/... 2>/dev/null \ | grep testkitx` | 无输出 |

## 验证命令

| 命令                                      | 判定标准   |
| ----------------------------------------- | ---------- |
| `go build ./...`                          | 编译通过   |
| `go test -run TestBoundaryCheck -v ./...` | 全部通过   |
| `go vet ./...`                            | 无警告     |

## 禁止事项

- 不要在 BoundaryCheck 中硬编码模块路径
- 不要在生产代码中调用 BoundaryCheck（仅限 test 文件）
- 不要用简单的字符串匹配代替 go list 依赖分析
- 不要跳过 testkitx 自身依赖的检测

## 证据回填

完成后提交以下产物：

1. `go test -v ./...` 完整输出
2. `go build ./...` 输出
3. `go list -deps github.com/ZoneCNH/x.go/... 2>/dev/null | grep testkitx` 输出（应为空）
4. 文件变更清单：`git diff --stat HEAD`

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入 `docs/evidence/`
3. 更新 TASK-TESTKITX-008 状态为 completed
