# TASK-CONFIGX-003

> 配置合并：默认值 → 文件 → 环境变量深度合并

---

```yaml
task_id: TASK-CONFIGX-003
module: configx
scope: "实现配置合并逻辑（默认值 → 文件 → 环境变量），支持点分路径自动创建中间节点"
spec_ref:
  - "module/configx/SPEC.md#BR-001"
  - "module/configx/SPEC.md#BR-003"
  - "module/configx/SPEC.md#§10.2"
files:
  - "merge.go"
  - "internal/merge/deep.go"
  - "merge_test.go"
acceptance_criteria:
  - "覆盖优先级：默认值 → 文件 → 环境变量 → 命令行参数"
  - "点分路径中间节点自动创建"
  - "深度合并不丢失已有键"
depends_on:
  - "TASK-CONFIGX-001"
  - "TASK-CONFIGX-002"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| BR-001 | 覆盖优先级：默认值 → 文件 → 环境变量 → 命令行 | 优先级正确 |
| BR-003 | 配置键使用点分路径 | `data.market.symbol` 正确访问 |
| §10.2 | 配置覆盖层次 | 4 层合并语义正确 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-001 | Unit | 覆盖优先级：默认值+文件覆盖，文件值优先 |
| — | Unit | 文件+环境变量覆盖：环境变量优先 |
| — | Unit | 点分路径中间节点：`a.b.c` 自动创建 `a` 和 `a.b` |
| — | Unit | 深度合并：嵌套 map 不丢失已有键 |
| — | Unit | 空值合并：某层为空不影响其他层 |
| — | Integration | 合并结果→供后续 Task 使用 |

## Non-scope

- 不做文件解析（→ TASK-002）
- 不做环境变量转换（→ TASK-004）
- 不做 schema 校验（→ TASK-005）

## Implementation Notes

- `internal/merge` 包实现深度合并算法，不依赖 configx 类型
- 合并顺序：`defaults` → `fileData` → `envOverrides`
- 环境变量转换在 `env.go` 中实现（FR-002），本 task 只负责合并逻辑
- 点分路径拆分用 `strings.Split(key, ".")`

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `internal/merge.DeepMerge`：递归合并两个 map，右侧覆盖左侧 | `internal/merge/deep.go` | `go test ./internal/merge/...` 通过 |
| 2 | 实现点分路径 `Set` 方法：拆分路径 → 自动创建中间节点 → 设置值 | `merge.go` | `go test ./... -run TestDotPath` 通过 |
| 3 | 实现 `mergeAll`：按优先级合并 defaults → fileData → envOverrides | `merge.go` | `go test ./... -run TestMergeAll` 通过 |
| 4 | 编写深度合并边界测试：嵌套 map、空值、类型冲突 | `merge_test.go` | 所有边界用例通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 深度合并丢失嵌套键 | Medium | High | 递归合并而非覆盖，用测试验证 |
| 点分路径与 map key 冲突 | Low | Medium | 统一使用点分路径，内部转为嵌套 map |
