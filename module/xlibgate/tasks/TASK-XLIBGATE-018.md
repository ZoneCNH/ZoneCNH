# TASK-XLIBGATE-018

> trust fleet-status 实现

---

```yaml
task_id: TASK-XLIBGATE-018
module: xlibgate
scope: "实现 trust fleet-status 命令：20 模块舰队状态聚合 → .foundationx/status/index.json"
spec_ref:
  - "module/xlibgate/spec/SPEC.md#FR-019"
  - "module/xlibgate/spec/SPEC.md#TC-028"
  - "module/xlibgate/spec/SPEC.md#TC-029"
files:
  - "cmd/trust_fleet.go"
  - "scanner/trust/fleet.go"
acceptance_criteria:
  - "AC-018: 20 模块全成功 → exit 0, 生成完整 index.json"
  - "AC-018: 部分模块失败 → exit 1, 仍生成 index.json（标记 error 模块）"
  - "AC-018: 模块数不为 20 → exit 1, 含 warning"
  - "AC-018: .foundationx/status/ 不存在 → 自动创建"
  - "AC-018: --summary-only → 仅输出摘要 JSON"
depends_on:
  - "TASK-XLIBGATE-010"
estimated_effort: "3h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description                                                  |
| ----------- | ------------------------------------------------------------ |
| FR-019      | trust fleet-status：舰队状态聚合                             |
| TC-028      | 20 模块全成功 → exit 0                                       |
| TC-029      | 部分模块失败 → exit 1，仍生成 index.json                     |

## index.json 每模块包含

`identity`, `release`, `maturity`, `boundaries`, `blockers`, `evidence-index`

## Non-scope

- 不单独运行 trust identity/release-consistency/maturity 等子命令（fleet-status 内联聚合，不嵌套调用 CLI）
- 不推送 index.json 到远程

## Test Plan

| Test Case | Type        | Description                          |
| --------- | ----------- | ------------------------------------ |
| TC-028    | Integration | 20 模块全成功 → exit 0               |
| TC-029    | Integration | 2 模块 error → exit 1，index.json 仍生成 |
| —         | Unit        | --summary-only 输出摘要              |
| —         | Unit        | 自动创建 .foundationx/status/ 目录   |
