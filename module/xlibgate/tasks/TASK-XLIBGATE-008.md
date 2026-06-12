# TASK-XLIBGATE-008

> 文档 + Release DoD

---

```yaml
task_id: TASK-XLIBGATE-008
module: xlibgate
scope: "创建 README、CHANGELOG，验证 Release DoD"
spec_ref:
  - "module/xlibgate/SPEC.md#BR-001"
  - "module/xlibgate/SPEC.md#NFR-007"
  - "module/xlibgate/SPEC.md#NFR-008"
  - "module/xlibgate/SPEC.md#NFR-010"
files:
  - "README.md"
  - "CHANGELOG.md"
acceptance_criteria:
  - "NFR-007: 测试覆盖率 >= 80%（go tool cover -func）"
  - "NFR-008: gitleaks detect --no-git 零命中"
  - "NFR-010: go list -deps 无 ZoneCNH 运行时依赖"
  - "BR-001: README 含模块定位、安装方式、使用示例、exit code 说明"
  - "BR-001: CHANGELOG 含所有 Task 的变更记录"
depends_on:
  - "TASK-XLIBGATE-000"
  - "TASK-XLIBGATE-001"
  - "TASK-XLIBGATE-002"
  - "TASK-XLIBGATE-003"
  - "TASK-XLIBGATE-004"
  - "TASK-XLIBGATE-005"
  - "TASK-XLIBGATE-006"
  - "TASK-XLIBGATE-007"
estimated_effort: "1h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| BR-001 | 标准化 exit code | README 含 exit code 文档 |
| NFR-007 | 测试覆盖率 >= 80% | `go tool cover -func` ≥ 80% |
| NFR-008 | 无硬编码密钥 | `gitleaks detect --no-git` 零命中 |
| NFR-010 | 无 Foundation 运行时依赖 | `go list -deps` 零命中 ZoneCNH 模块 |

## Non-scope

- 不实现自动化文档生成（手动编写 README 和 CHANGELOG）
- 不实现多语言文档
- 不实现 API 参考文档（xlibgate 是 CLI 工具，非库）
- 不实现 GitHub Pages 部署

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| NFR-007 | CI Gate | `go tool cover -func=.coverage/cover.out \| grep total \| awk '{print $3}' \| tr -d '%'` ≥ 80 |
| NFR-008 | CI Gate | `gitleaks detect --no-git` 零命中 |
| NFR-010 | CI Gate | `go list -deps ./... \| grep ZoneCNH` 零命中 |
| BR-001 | CI Gate | `xlibgate check all --config xlibgate.yaml` self-check 通过 |

## Implementation Notes

- README 展示 CLI 用法和 CI 集成示例
- Release DoD 全部勾选后方可标记 complete

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 创建 README.md | `README.md` | 人工 review |
| 2 | 创建 CHANGELOG.md | `CHANGELOG.md` | 格式正确 |
| 3 | 验证 Release DoD 全部条目 | — | NFR-007, NFR-008, NFR-010, BR-001 全部通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 覆盖率未达 80% | Medium | Medium | 补充测试 |
