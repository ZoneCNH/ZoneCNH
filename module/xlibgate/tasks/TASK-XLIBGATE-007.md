# TASK-XLIBGATE-007

> 集成测试

---

```yaml
task_id: TASK-XLIBGATE-007
module: xlibgate
scope: "实现集成测试，端到端验证所有子命令"
spec_ref:
  - "module/xlibgate/SPEC.md#FR-001"
  - "module/xlibgate/SPEC.md#FR-002"
  - "module/xlibgate/SPEC.md#FR-003"
  - "module/xlibgate/SPEC.md#FR-004"
  - "module/xlibgate/SPEC.md#FR-005"
  - "module/xlibgate/SPEC.md#FR-006"
files:
  - "integration_test.go"
acceptance_criteria:
  - "AC-001: check imports 端到端测试通过（合规/违规/错误三种 exit code）"
  - "AC-002: check gomod 端到端测试通过"
  - "AC-003: check baseline 端到端测试通过"
  - "AC-004: check release 端到端测试通过"
  - "AC-005: check all 端到端聚合测试通过（部分失败继续）"
  - "AC-006: JSON/text 双格式输出验证通过"
depends_on:
  - "TASK-XLIBGATE-002"
  - "TASK-XLIBGATE-003"
  - "TASK-XLIBGATE-004"
  - "TASK-XLIBGATE-005"
  - "TASK-XLIBGATE-006"
estimated_effort: "2h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| TC-001~TC-008 | 全部测试场景的端到端验证 | 所有子命令 exit code 正确 |

## Non-scope

- 不实现性能/压力测试（benchmark 在 TASK-002~006 的 Test Plan 中）
- 不实现跨平台 CI matrix 测试（后续 CI 配置）
- 不实现模糊测试（fuzz testing）
- 不实现回归测试数据集的自动生成

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-001 | Integration | check imports 端到端：合规/违规/无配置三种场景 |
| TC-002 | Integration | check gomod 端到端：tidy/有diff/无go.mod 三种场景 |
| TC-003 | Integration | check baseline 端到端：一致/不匹配/无expected 三种场景 |
| TC-004 | Integration | check all 端到端：全部通过/部分失败/exiit code 正确 |
| TC-005 | Integration | check all 端到端：error 后继续执行其余检查 |
| TC-006 | Integration | check release 端到端：完整/缺失/格式无效 三种场景 |
| TC-007 | Integration | JSON 输出格式：status/checks[]/summary 字段完整性 |
| TC-008 | Integration | check all 含 gitleaks 扫描端到端验证 |

## Implementation Notes

- 使用 `os/exec` 调用编译后的二进制
- 测试各种 exit code 场景

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现集成测试 | `integration_test.go` | 全部 TC-001~TC-008 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 二进制编译依赖 | Low | Low | TestMain 中编译 |
