# PLAN-TESTKITX-000

> 项目骨架实现计划
>
> 对应 Task：`module/testkitx/tasks/TASK-TESTKITX-000.md`
> 对应 Spec：`module/testkitx/SPEC.md#15` (Dependencies), `SPEC.md#10` (Data Model), `SPEC.md#14` (Directory Structure)

---

## 1. Task 摘要

```yaml
task_id: TASK-TESTKITX-000
scope: "创建 go.mod、doc.go、errors.go、testkitx.go，定义包结构和公共错误"
priority: P0
estimated_effort: "0.5h"
depends_on: []
blocks: [TASK-TESTKITX-001 ~ 009]
```

---

## 2. 覆盖需求

| 需求     | 描述                                      | AC                                                        |
| -------- | ----------------------------------------- | --------------------------------------------------------- |
| SPEC §15 | go.mod 依赖声明                           | 仅必要依赖，`go mod tidy` 无变化                          |
| SPEC §10 | 公共错误定义                              | ErrBoundaryViolation, ErrGoroutineLeak, ErrGoldenMismatch |
| SPEC §14 | 目录结构                                  | 创建模块根目录骨架                                        |
| BR-006   | testkitx 可依赖所有 L1 模块（仅 go test） | go.mod 依赖列表合规                                       |

---

## 3. 实现步骤

### Step 1: 创建 go.mod

**目标文件**：`go.mod`

**内容要点**：
- module 路径：`github.com/ZoneCNH/testkitx`
- Go 版本：`go 1.23`（与 Foundation 基线对齐）
- 依赖项（仅 go test 使用）：
  - `github.com/ZoneCNH/configx`（FakeConfig 需实现 `configx.Reader` 接口）
  - `github.com/ZoneCNH/observex`（FakeLogger/Meter/Tracer/Exporter 需实现接口）
  - `github.com/ZoneCNH/resiliencx`（FakeBreaker 需实现 `resiliencx.Breaker` 接口）

**验证**：
```bash
go mod tidy && git diff --exit-code go.mod go.sum
```

### Step 2: 创建 doc.go

**目标文件**：`doc.go`

**内容要点**：
- 包注释：描述 testkitx 定位、用途、禁止生产导入
- `package testkitx`

**验证**：
```bash
go build ./...
```

### Step 3: 创建 errors.go

**目标文件**：`errors.go`

**内容要点**：
```go
package testkitx

import "errors"

var (
    ErrBoundaryViolation = errors.New("testkitx: production dependency on testkitx")
    ErrGoroutineLeak     = errors.New("testkitx: goroutine leak detected")
    ErrGoldenMismatch    = errors.New("testkitx: golden file mismatch")
)
```

错误消息格式统一为 `"testkitx: <operation>: <detail>"`

**验证**：
```bash
go build ./...
```

### Step 4: 创建 testkitx.go

**目标文件**：`testkitx.go`

**内容要点**：
- 顶层导出聚合文件（当前为空壳，后续 task 在此添加类型导出）
- `package testkitx`

**验证**：
```bash
go build ./...
```

---

## 4. 测试策略

| 测试类型   | 内容              | 验证命令                                            |
| ---------- | ----------------- | --------------------------------------------------- |
| 编译检查   | 包可编译          | `go build ./...`                                    |
| 依赖整洁   | go.mod 无多余依赖 | `go mod tidy && git diff --exit-code go.mod go.sum` |

本 task 不包含单元测试——错误定义无逻辑，仅需编译验证。

---

## 5. 验证汇总

```bash
# 创建文件后执行
go mod tidy
go build ./...
git diff --exit-code go.mod go.sum
```

**通过标准**：三条命令全部返回 0。

---

## 6. 风险与回滚

| 风险            | 概率   | 影响   | 缓解                                 | 回滚                                 |
| --------------- | ------ | ------ | ------------------------------------ | ------------------------------------ |
| 依赖版本不兼容  | Low    | High   | 使用 Foundation 其他模块已锁定的版本 | `git checkout -- go.mod go.sum` 还原 |
| go.mod 循环依赖 | Low    | High   | 仅依赖接口包，不依赖实现包           | 移除可疑依赖后 `go mod tidy`         |

**回滚路径**：本 task 仅创建新文件，无修改。回滚 = `rm go.mod doc.go errors.go testkitx.go`。
