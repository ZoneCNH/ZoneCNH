# TASK-XLIBGATE-009

> l2 子命令组实现：validate-manifest / plan / check-contracts / check-evidence / release-check

---

```yaml
task_id: TASK-XLIBGATE-009
module: xlibgate
scope: "实现 l2 子命令组（FR-007~FR-011）：L2 发布就绪门禁"
spec_ref:
  - "module/xlibgate/SPEC.md#FR-007"
  - "module/xlibgate/SPEC.md#FR-008"
  - "module/xlibgate/SPEC.md#FR-009"
  - "module/xlibgate/SPEC.md#FR-010"
  - "module/xlibgate/SPEC.md#FR-011"
files:
  - "internal/l2/manifest/manifest.go"
  - "internal/l2/manifest/manifest_test.go"
  - "internal/l2/planner/planner.go"
  - "internal/l2/planner/planner_test.go"
  - "internal/l2/contracts/contracts.go"
  - "internal/l2/contracts/contracts_test.go"
  - "internal/l2/evidence/evidence.go"
  - "internal/l2/evidence/evidence_test.go"
  - "internal/l2/release/release.go"
  - "internal/l2/release/release_test.go"
  - "internal/l2/registry/registry.go"
acceptance_criteria:
  - "AC-010: manifest 有效时输出摘要（repo/layer/release_level/required_capabilities），exit 0；无效/Missing 时 exit 1"
  - "AC-011: registry 覆盖所有 required_capabilities 时生成 test-plan.json，exit 0；缺失能力时输出缺失列表，exit 1"
  - "AC-012: 所有必需契约测试通过时输出 passed/missing/failed 计数，exit 0；缺失或失败时输出详情，exit 1"
  - "AC-013: 所有必需证据文件存在时输出 present/missing 计数，exit 0；缺失时输出缺失列表，exit 1"
  - "AC-014: 全部门禁通过且综合评分 >= 80 时输出 status=pass，exit 0；硬失败时输出 fail 列表，exit 1"
depends_on:
  - "TASK-XLIBGATE-001"
estimated_effort: "4h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-007 | l2 validate-manifest：校验 .agent/l2-capabilities.yaml | AC-010 |
| FR-008 | l2 plan：从能力清单和 registry 生成 test-plan.json | AC-011 |
| FR-009 | l2 check-contracts：验证契约测试覆盖 | AC-012 |
| FR-010 | l2 check-evidence：验证 L2 evidence 文件存在 | AC-013 |
| FR-011 | l2 release-check：完整 L2 发布就绪判定 | AC-014 |

## Non-scope

- 不实现能力清单自动生成（只读取校验）
- 不执行实际契约测试（只验证结果文件）
- 不生成 evidence 文件（只校验存在性和格式）
- 不实现发布流程自动化（只判定就绪状态）
- 不实现跨模块 l2 门禁聚合

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-009 | Unit | manifest 有效→输出摘要 exit 0；Missing/YAML 解析失败→exit 1 |
| TC-010 | Unit | registry 全覆盖→生成 test-plan.json exit 0；缺失能力→exit 1 |
| TC-011 | Unit | 全部契约测试通过→输出计数 exit 0；缺失/失败→exit 1 |
| TC-012 | Unit | 全部 evidence 存在→输出计数 exit 0；缺失→exit 1 |
| TC-013 | Unit | 全部门禁通过且评分≥80→status=pass exit 0；硬失败>0→fail exit 1 |

## Implementation Notes

- `l2 validate-manifest` 解析 YAML 校验 repo/layer/release_level/required_capabilities 字段
- `l2 plan` 从 registry 解析覆盖矩阵，生成 test-plan.json（含 required_contract_tests）
- `l2 check-contracts` 读取 contract-test.json，比对 required_contract_tests 与实际结果
- `l2 check-evidence` 遍历 .agent/evidence/ 检查必需证据文件存在性
- `l2 release-check` 汇总门禁结果 + 综合评分，判定发布就绪（默认阈值 80）
- 各子命令支持 --output json（machine-readable）和 --output text（human-readable）
