# TASK-XLIB-011

> Release DoD：发布验收清单、Release Scorecard 集成、最终验证

---

```yaml
task_id: TASK-XLIB-011
module: xlib-standard
scope: "实现 Release DoD——发布验收清单自动化、Release Scorecard 集成、最终验证流程和文档收尾"
spec_ref:
  - "specs/xlib-standard/SPEC.md#22"
  - "specs/xlib-standard/SPEC.md#AC-R02"
  - "specs/xlib-standard/SPEC.md#AC-R03"
  - "specs/xlib-standard/SPEC.md#AC-R04"
files:
  - "pack/release-final-check.json"
  - "docs/standard/release-dod.md"
  - "Makefile"
acceptance_criteria:
  - "AC-R02: P0 Gate 失败阻断发布"
  - "AC-R03: Release Scorecard 返回 0~10.0 分，score < 9.8 阻断"
  - "AC-R04: dirty workspace 阻断 release"
  - "发布验收清单 11 项全部通过"
depends_on:
  - "TASK-XLIB-007"
  - "TASK-XLIB-008"
  - "TASK-XLIB-009"
  - "TASK-XLIB-010"
estimated_effort: "3h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description |
|---|---|
| §22 | Release DoD 发布验收清单 |
| AC-R02 | P0 Gate 失败阻断发布 |
| AC-R03 | Release Scorecard 阻断 |
| AC-R04 | dirty workspace 阻断 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | CI Gate | `make release-check` 通过 |
| — | Unit | P0 gate 失败时阻断 |
| — | Unit | score < 9.8 时阻断 |
| — | Unit | dirty workspace 时阻断 |

## Implementation Plan

### Step 1: 定义 Release DoD
- `docs/standard/release-dod.md`：发布验收清单
  - 11 项检查：P0 FR 完成、AC 通过、registry 验证、harness 注册、integration 通过、debt score、evidence 完整、manifest 验证、scorecard、追溯矩阵、spec 状态

### Step 2: 实现 release-final-check
- `pack/release-final-check.json`：最终检查 gate
- 检查所有 P0 gate 通过
- 检查 Release Scorecard >= 9.8
- 检查 dirty workspace
- 检查 Evidence Manifest 完整

### Step 3: 实现 Makefile target
- `make release-check`：执行发布验收
- 输出检查结果
- 任何检查失败时 exit code != 0

### Step 4: 文档收尾
- 更新 spec 状态为 Implemented
- 更新追溯矩阵 Status 列
- 生成 Release Notes

### Step 5: 验证
- `make release-check` 通过
- 11 项检查全部通过
- spec 状态更新为 Implemented

### 风险评估

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| 检查项遗漏 | 低 | 高 | 对照 SPEC.md §22 清单逐项核对 |
| 依赖其他 task 未完成 | 中 | 高 | 确保 007-010 全部完成后再执行 |
