# TASK-XLIB-005

> 生成器：render_template.sh 模板渲染、排除项、integration 测试

---

```yaml
task_id: TASK-XLIB-005
module: xlib-standard
scope: "实现 render_template.sh 模板渲染脚本——从 Go 参考模板生成下游模块代码，支持排除项和 dry-run 模式"
spec_ref:
  - "specs/xlib-standard/SPEC.md#FR-015"
  - "specs/xlib-standard/SPEC.md#FR-016"
  - "specs/xlib-standard/SPEC.md#FR-017"
  - "specs/xlib-standard/SPEC.md#FR-018"
  - "specs/xlib-standard/SPEC.md#FR-019"
files:
  - "render_template.sh"
  - "template/exclude.yaml"
  - "Makefile"
acceptance_criteria:
  - "AC-I02: `make integration` 渲染 kernel/configx/redisx 三个下游库，编译通过"
  - "FR-015 WHEN render_template.sh 执行 THEN 从 template/ 生成目标文件"
  - "FR-018 WHEN `make integration` 执行 THEN 3 个下游库编译通过且 gate 全过"
depends_on:
  - "TASK-XLIB-004"
estimated_effort: "4h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description |
|---|---|
| FR-015 | render_template.sh 模板渲染 |
| FR-016 | 排除项配置 |
| FR-017 | dry-run 模式 |
| FR-018 | integration 测试（3 个下游库） |
| FR-019 | 渲染产物 go vet 通过 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | CI Gate | `make integration` 通过 |
| — | CI Gate | 渲染产物 `go vet ./...` 零警告 |
| — | Unit | dry-run 模式不写入文件 |

## Implementation Plan

### Step 1: 实现 render_template.sh
- 读取 `template/go/` 下所有 Go 源文件
- 应用模板变量替换（模块名、包名等）
- 输出到目标目录
- 支持 `--dry-run` 模式（只输出不写入）

### Step 2: 创建排除项配置
- `template/exclude.yaml`：排除文件列表和排除模式
- 支持 glob 匹配

### Step 3: 实现 Makefile targets
- `make render`：执行模板渲染
- `make integration`：渲染 kernel/configx/redisx 三个下游库
- `make integration-test`：渲染后编译验证

### Step 4: 验证
- `make integration` 渲染 3 个下游库，编译通过
- 渲染产物 `go vet ./...` 零警告
- dry-run 模式不写入文件

### 风险评估

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| 模板变量遗漏 | 中 | 高 | 对照上游 render_template.sh 核对 |
| 排除项配置不完整 | 低 | 中 | 从上游 template/exclude.yaml 提取 |
