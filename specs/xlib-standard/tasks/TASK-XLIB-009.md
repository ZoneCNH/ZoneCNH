# TASK-XLIB-009

> Goal Runtime：goalcli 命令、Harness Objects、Mode Router

---

```yaml
task_id: TASK-XLIB-009
module: xlib-standard
scope: "实现 Goal Runtime v3.1.1——goalcli 命令行工具、Harness Objects（8 核心对象）、Mode Router/Gate Registry/Command Registry/Blocking Policy"
spec_ref:
  - "specs/xlib-standard/SPEC.md#FR-040"
  - "specs/xlib-standard/SPEC.md#FR-041"
  - "specs/xlib-standard/SPEC.md#FR-042"
  - "specs/xlib-standard/SPEC.md#FR-043"
  - "specs/xlib-standard/SPEC.md#FR-044"
  - "specs/xlib-standard/SPEC.md#FR-045"
  - "specs/xlib-standard/SPEC.md#FR-046"
files:
  - "cmd/goalcli/main.go"
  - "cmd/goalcli/score.go"
  - "cmd/goalcli/harness-check.go"
  - "cmd/goalcli/evidence.go"
  - "goal-runtime/harness-objects.yaml"
acceptance_criteria:
  - "AC-G01: Goal Kernel 8 个核心对象模型正确创建和引用"
  - "AC-G02: Harness Runtime Mode Router/Gate Registry/Command Registry/Blocking Policy 正确加载"
  - "AC-I03: goalcli JSON 输出符合 goalcli-report.schema.json"
  - "AC-R03: Release Scorecard 返回 0~10.0 分，score < 9.8 阻断"
depends_on:
  - "TASK-XLIB-006"
  - "TASK-XLIB-007"
estimated_effort: "8h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description |
|---|---|
| FR-040 | Goal Kernel 8 核心对象 |
| FR-041 | goalcli JSON 输出 |
| FR-042 | goalcli 与 harness gate 集成 |
| FR-043 | Mode Router |
| FR-044 | Gate Registry |
| FR-045 | Command Registry + Blocking Policy |
| FR-046 | 28 个 PR 包 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | CI Gate | `goalcli harness-runtime-check` 通过 |
| — | CI Gate | `goalcli score --min 9.8` 通过 |
| — | Schema | JSON 输出符合 goalcli-report.schema.json |

## Implementation Plan

### Step 1: 定义 Harness Objects
- `goal-runtime/harness-objects.yaml`：8 个核心对象
  - Gate, GateResult, Evidence, Manifest
  - Scorecard, AdoptionStatus, DebtRule, DownstreamSync

### Step 2: 实现 goalcli 命令
- `cmd/goalcli/main.go`：入口、子命令注册
- `cmd/goalcli/score.go`：`goalcli score --min N` 命令
- `cmd/goalcli/harness-check.go`：`goalcli harness-runtime-check` 命令
- `cmd/goalcli/evidence.go`：`goalcli evidence` 命令

### Step 3: 实现 Mode Router
- Gate Registry：注册所有 gate
- Command Registry：注册所有 goalcli 命令
- Blocking Policy：P0 gate 失败阻断
- Mode Router：根据配置选择执行模式

### Step 4: 实现 JSON 输出
- 符合 goalcli-report.schema.json
- 包含：gates[], score, status, timestamp

### Step 5: 验证
- `goalcli harness-runtime-check` 通过
- `goalcli score --min 9.8` 通过
- JSON 输出符合 schema

### 风险评估

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| Harness Objects 定义不完整 | 中 | 高 | 从上游 analysis/runtime.md §2 提取 |
| Mode Router 实现复杂 | 中 | 中 | 简化为配置驱动的路由表 |
