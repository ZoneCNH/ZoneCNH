# TASK-OBSERVEX-010

> Label Policy：allowed/forbidden labels、命名规范

---

```yaml
task_id: TASK-OBSERVEX-010
module: observex
scope: "实现 label policy 模块，支持 allowed/forbidden labels 检查和指标命名规范校验"
spec_ref:
  - "module/observex/SPEC.md#FR-006"
  - "module/observex/SPEC.md#BR-002"
  - "module/observex/SPEC.md#BR-006"
files:
  - "label_policy.go"
  - "label_policy_test.go"
acceptance_criteria:
  - "AllowedLabels 中的 label 允许通过"
  - "ForbiddenLabels 中的 label 返回 ErrLabelForbidden"
  - "指标命名不符合 foundationx_<module>_<op>_<measure> 时返回错误"
  - "并发调用安全"
depends_on:
  - "TASK-OBSERVEX-000"
estimated_effort: "2h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-006 | Label Policy：Allowed 允许，Forbidden 拒绝 | 2 个 WHEN/THEN 场景 |
| BR-002 | Meter 必须控制 label 基数 | 高基数 label 被拒绝 |
| BR-006 | 指标命名必须符合 `foundationx_<module>_<op>_<measure>` | 命名校验 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-002 | Unit | Label Policy 拒绝高基数：ForbiddenLabels 中的 label 返回错误 |
| TC-007 | Unit | Metrics 命名规范：不符合规范的名称被拒绝 |
| — | Unit | AllowedLabels 中的 label 正常通过 |
| — | Unit | 并发调用安全 |

## Implementation Notes

- `LabelPolicy` 结构体包含 `AllowedLabels []string` 和 `ForbiddenLabels []string`
- `CheckLabel(label string) error` 检查单个 label 是否合规
- `ValidateMetricName(name string) error` 校验指标命名
- 命名正则：`^foundationx_[a-z][a-z0-9]*_[a-z0-9_]+_[a-z][a-z0-9_]*$`

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 定义 `LabelPolicy` 结构体和 `CheckLabel` 方法 | `label_policy.go` | `go build ./...` 通过 |
| 2 | 实现 `ValidateMetricName`：正则校验指标命名 | `label_policy.go` | TC-007 通过 |
| 3 | 编写完整测试：allowed/forbidden/命名规范 | `label_policy_test.go` | TC-002 通过 |
| 4 | 并发安全验证 | `label_policy_test.go` | `go test -race ./... -run TestLabel` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 命名正则过严/过松 | Medium | Medium | 对照 BR-006 规范精确构造 |
| forbidden 列表遗漏 | Low | Medium | 提供默认 forbidden 列表 |
