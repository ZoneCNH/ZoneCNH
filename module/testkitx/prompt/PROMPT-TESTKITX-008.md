# TASK-TESTKITX-008 开发 Prompt

> BoundaryCheck 实现：生产包 import 边界扫描
>
> 上游 Task：[TASK-TESTKITX-008.md](../tasks/TASK-TESTKITX-008.md)
> 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
> 规格：[SPEC.md](../SPEC.md) §7 FR-009、§9.8

---

## 任务

实现 `BoundaryCheck`，通过 `go list` 验证生产依赖图中不包含 testkitx。检测到边界违规时，报告完整的依赖路径。

## 关联需求

| 类型 | 编号 | 出处 | 说明 |
|------|------|------|------|
| FR | FR-009 | SPEC.md §7 | BoundaryCheck：生产包 import 边界扫描 |
| BR | BR-005 | SPEC.md §8 | 生产 import graph 中不能出现 testkitx |
| AC | AC-009 | TRACEABILITY.md §5 | 生产包依赖 testkitx -> fail + 路径；不依赖 -> pass |

## 文件清单

### 1. `boundary.go`

- `BoundaryCheck(t *testing.T, module string)`：检查指定模块的生产依赖中是否包含 testkitx
  - 内部执行 `go list -deps <module>/...` 并 grep testkitx
  - 如果在生产依赖路径中发现 testkitx，`t.Errorf` 报告完整依赖路径
  - 忽略 testkitx 自身的依赖（testkitx 依赖自己不算违规）
- `ErrBoundaryViolation` 公共错误变量

### 2. `boundary_test.go`

- `TestBoundaryCheck_Self`：检查 testkitx 自身 -> 通过（不报告违规）
- `TestBoundaryCheck_NoViolation`：检查不含 testkitx 的模块 -> 通过
- `TestBoundaryCheck_Violation`：检查含 testkitx 的模块 -> fail + 报告路径

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-008-01 | FR-009 | `go test -run TestBoundaryCheck -v -count=1` | 全部通过 |
| AC-008-02 | BR-005 | `go list -deps github.com/ZoneCNH/x.go/... 2>/dev/null \| grep testkitx` | 无输出（生产包不含 testkitx） |

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./...` | 编译通过 |
| `go test -run TestBoundaryCheck -v -count=1` | 全部测试通过 |
| `! go list -deps github.com/ZoneCNH/x.go/... 2>/dev/null \| grep testkitx` | 无 testkitx 在生产依赖中 |

## 禁止事项

- 不要在 BoundaryCheck 中硬编码模块路径
- 不要在生产代码中调用 BoundaryCheck（仅限于 test 文件）
- 不要用简单的字符串匹配代替 go list 依赖分析

## 证据回填

完成后提交以下产物到 `docs/evidence/TASK-TESTKITX-008/`：

1. `go build ./...` 输出
2. `go test -run TestBoundaryCheck -v -count=1` 输出
3. `go list -deps github.com/ZoneCNH/x.go/... 2>/dev/null | grep testkitx` 输出（应为空）
4. 新建文件清单（路径 + 行数）

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入指定目录
3. 更新 TASK-TESTKITX-008 状态为 completed
