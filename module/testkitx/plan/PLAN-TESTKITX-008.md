# PLAN-TESTKITX-008

> BoundaryCheck 实现计划
>
> 对应 Task：`module/testkitx/tasks/TASK-TESTKITX-008.md`
> 对应 Spec：`module/testkitx/SPEC.md#FR-009`, `SPEC.md#9.8`, `SPEC.md#13`

---

## 1. Task 摘要

```yaml
task_id: TASK-TESTKITX-008
scope: "实现 BoundaryCheck，生产包 import 边界扫描（go list 验证）"
priority: P1
estimated_effort: "1h"
depends_on: [TASK-TESTKITX-000]
blocks: [TASK-TESTKITX-010]
```

---

## 2. 覆盖需求

| 需求 | 描述 | AC |
|------|------|-----|
| FR-009 | BoundaryCheck 生产边界扫描 | AC-009: 依赖 testkitx → fail + 依赖路径；不依赖 → pass |
| BR-005 | 生产 import 不含 testkitx | go list 验证 |
| NFR-004 | 不进入生产二进制 | no-production-import CI gate |
| SPEC §13 | Edge Case: 检查自身 | testkitx 自身依赖自己不算违规 |

---

## 3. 接口契约

```go
// SPEC §9.8
func BoundaryCheck(t *testing.T, module string)
```

---

## 4. 实现步骤

### Step 1: 实现 BoundaryCheck

**目标文件**：`boundary.go`

**实现要点**：
- 使用 `go list` 命令检查生产依赖图
- 核心逻辑：
  ```go
  // 获取 module 的生产依赖（排除 test 依赖）
  // go list -deps -test=false <module>/...
  // 检查输出中是否包含 testkitx
  ```
- 如果生产依赖包含 testkitx：
  - `t.Errorf` 输出依赖路径
  - 返回 `ErrBoundaryViolation`
- 如果自身是 `github.com/ZoneCNH/testkitx`，跳过检查（Edge Case）
- 使用 `go list -json` 获取结构化依赖信息，解析 ImportPath

**实现细节**：
```go
func BoundaryCheck(t testing.TB, module string) {
    t.Helper()

    // 自身检查豁免
    if module == "github.com/ZoneCNH/testkitx" {
        return
    }

    cmd := exec.Command("go", "list", "-deps", "-test=false", module+"/...")
    output, err := cmd.Output()
    if err != nil {
        t.Fatalf("BoundaryCheck: go list failed: %v", err)
    }

    for _, line := range strings.Split(string(output), "\n") {
        if strings.Contains(line, "github.com/ZoneCNH/testkitx") {
            t.Errorf("testkitx: production dependency violation: %s depends on testkitx\n  import path: %s",
                module, line)
        }
    }
}
```

### Step 2: 编写单元测试

**目标文件**：`boundary_test.go`

**测试用例**：

| 用例 | 描述 | 验证点 |
|------|------|--------|
| TestBoundaryCheck_Self | 检查自身 | 通过（豁免） |
| TestBoundaryCheck_NoViolation | 不依赖 testkitx 的包 | 通过 |
| TestBoundaryCheck_Violation | 依赖 testkitx 的包 | 失败 + 输出依赖路径 |

**注意**：由于测试环境本身就是 testkitx 仓库，违规场景的测试需要构造模拟环境。可以使用 mock `go list` 输出或创建临时 go module 进行集成测试。

---

## 5. 验证汇总

```bash
go build ./...
go test -run TestBoundaryCheck -race -count=1 -v ./...
```

**通过标准**：编译通过 + 全部测试通过 + 无 data race。

**CI 验证**（PR 合并后）：
```bash
# 在生产包（如 x.go）中运行
go list -deps github.com/ZoneCNH/x.go/... | grep testkitx
# 期望：无输出（无依赖）
```

---

## 6. 风险与回滚

| 风险 | 概率 | 影响 | 缓解 | 回滚 |
|------|------|------|------|------|
| go list 命令在测试环境不可用 | Low | Medium | 检查 go 二进制存在 + Skip 降级 | Skip 测试 |
| 违规场景测试难以构造 | Medium | Low | 使用临时 go module 或 mock | 使用集成测试覆盖 |
| Edge Case 豁免逻辑遗漏 | Low | Medium | 明确处理自身依赖 | 修正豁免条件 |

**回滚路径**：本 task 仅新增文件，回滚 = `rm boundary.go boundary_test.go`。
