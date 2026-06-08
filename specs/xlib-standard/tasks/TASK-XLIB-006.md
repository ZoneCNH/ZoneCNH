# TASK-XLIB-006

> Harness Gate：harness.yaml 66 gates、Makefile 注册、gate 分类

---

```yaml
task_id: TASK-XLIB-006
module: xlib-standard
scope: "创建 harness.yaml 66 个 gate 条目（required 44 + extended 10 + final 6 + goalcli_mva 6），全部在 Makefile 中注册"
spec_ref:
  - "specs/xlib-standard/SPEC.md#FR-020"
  - "specs/xlib-standard/SPEC.md#FR-021"
  - "specs/xlib-standard/SPEC.md#FR-022"
  - "specs/xlib-standard/SPEC.md#FR-023"
  - "specs/xlib-standard/SPEC.md#FR-024"
  - "specs/xlib-standard/SPEC.md#FR-025"
files:
  - "harness.yaml"
  - "Makefile"
  - "pack/fmt.json"
  - "pack/vet.json"
  - "pack/lint.json"
acceptance_criteria:
  - "AC-T02: harness.yaml 66 个 gate 条目全部在 Makefile 中注册"
  - "AC-R02: P0 Gate 失败阻断发布"
  - "FR-020 WHEN harness.yaml 被加载 THEN 所有 gate 条目可执行"
  - "FR-022 WHEN P0 gate 失败 THEN 阻断发布"
depends_on:
  - "TASK-XLIB-001"
estimated_effort: "6h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description |
|---|---|
| FR-020 | harness.yaml 66 gates |
| FR-021 | Makefile gate 注册 |
| FR-022 | P0 gate 失败阻断发布 |
| FR-023 | gate 执行结果记录到 Evidence |
| FR-024 | Release Scorecard（0~10.0 分） |
| FR-025 | gate 超时处理 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | CI Gate | `goalcli harness-runtime-check` 通过 |
| — | Unit | 66 gates 全部在 Makefile 中注册 |
| — | Unit | P0 gate 失败时 exit code != 0 |

## Implementation Plan

### Step 1: 创建 harness.yaml
- 66 个 gate 条目，分为 4 组：
  - `required_gates`（44）：fmt, vet, lint, test, race, build, security-scan 等
  - `extended_gates`（10）：complexity, duplication, coverage 等
  - `final_gates`（6）：release-final-check, evidence-integrity, scorecard 等
  - `goalcli_mva_gates`（6）：MVA 生命周期 gate
- 每个 gate 定义：name, type, command, timeout, blocking, category

### Step 2: 创建 pack/ gate 定义
- `pack/fmt.json`：格式化检查 gate
- `pack/vet.json`：go vet 检查 gate
- `pack/lint.json`：lint 检查 gate
- 每个 pack 文件包含：name, command, expected_exit_code, timeout

### Step 3: 实现 Makefile targets
- 66 个 gate target（每个对应一个 make 目标）
- `make gate`：执行所有 required gates
- `make gate-extended`：执行 extended gates
- `make gate-final`：执行 final gates

### Step 4: 验证
- `goalcli harness-runtime-check` 通过
- 66 gates 全部在 Makefile 中注册
- P0 gate 失败时 exit code != 0

### 风险评估

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| gate 条目遗漏 | 中 | 高 | 对照上游 harness.yaml 逐条核对 |
| Makefile target 冲突 | 低 | 中 | 使用统一前缀 `gate-` |
