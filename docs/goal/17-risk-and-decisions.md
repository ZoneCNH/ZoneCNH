# 17. 风险、决策与发布

> 本文档从 [16-ci-cd.md](16-ci-cd.md) 拆分而来，聚焦于 Risk Register、ADR、Release Manifest 和落地计划。

---

## 1. Risk Register

### 风险字段

```text
Risk ID:       RISK-xxx
Goal ID:       GOAL-xxx
Task ID:       TASK-xxx
Type:          [风险类型]
Description:   [描述]
Probability:   High / Medium / Low
Impact:        High / Medium / Low
Severity:      High / Medium / Low
Trigger:       [触发条件]
Mitigation:    [缓解方案]
Owner:         [负责人]
Status:        Open / Mitigated / Closed / Accepted
Linked Gates:  [G0-G11]
Linked Evidence:[EVID-xxx]
Release Blocking: true / false
Residual Risk: Low / Medium / High / Critical
Acceptance:    [accepted_by/date/reason，或 N/A]
Review Cadence: [per PR / before G10 / post-release]
```

### Risk Register 合格条件

- High/Critical 或 `release_blocking=true` 的风险 MUST 有 owner、mitigation、linked gate、linked evidence 和 residual risk。
- `release_blocking=true` 且 Status 不是 `Mitigated`、`Closed` 或明确 `Accepted` 的风险 MUST 阻断 G10。
- `Accepted` 风险 MUST 记录接受人、日期、原因和到期复查条件；不得用 `Accepted` 掩盖缺失的缓解方案。
- Release 前 MUST 生成 Risk Register 摘要，并被 Release Manifest 引用。
- 风险关闭 MUST 引用 Evidence；没有 Evidence 的风险只能从 `Open` 进入 `Mitigated` 待验证，不能直接 `Closed`。

### 风险类型

| 类型 | 说明 |
|------|------|
| Architecture Risk | 模块边界、依赖关系 |
| Implementation Risk | 实现正确性、复杂度 |
| Test Risk | 测试覆盖、测试质量 |
| Data Risk | 数据完整性、数据迁移 |
| Security Risk | 安全漏洞、权限问题 |
| Performance Risk | 性能瓶颈、资源消耗 |
| Compatibility Risk | 兼容性、版本冲突 |
| Release Risk | 发布流程、回滚能力 |
| Operation Risk | 运维复杂度、监控盲区 |

---

## 2. Decision Log（ADR）

架构变更、公共接口变更、存储变更必须写 Decision Log。

### 模板

```markdown
# Decision: [标题]

Date: YYYY-MM-DD
Status: Proposed / Accepted / Deprecated / Replaced

## Context
[为什么需要这个决策]

## Options
1. 方案 A
2. 方案 B
3. 方案 C

## Decision
[最终选择]

## Rationale
[为什么选择]

## Consequences
[影响]

## Rollback
[回滚方案]
```

---

## 3. Release Manifest

> **Release Manifest 范围**：本文档定义发布清单的结构和审批流程。制品版本号规范和变更管理流程见 [12-operations.md](12-operations.md)。

### PR 模板

```markdown
# PR: [Title]

## 1. Goal
Goal ID:
Related Issues:

## 2. Spec
Spec ID:
Spec Status:

## 3. Design
Design ID:
ADR:
Design Review:

## 4. Changes
- [变更 1]
- [变更 2]

## 5. Tasks Completed
- TASK-GOAL-20260608-001-001:
- TASK-GOAL-20260608-001-002:

## 6. Verification
Commands: [验证命令]
Results: [测试摘要]
Validation Summary: [通过/失败/跳过项、环境、commit、阻断项]

## 7. Evidence
Evidence Manifest: [证据路径]

## 8. Risks
Known risks: [已知风险]
Risk Register: [路径]
Mitigation: [缓解方案]
Residual risk: [Low / Medium / High / Critical]
Release blocking risks: none | [列表]

## 9. Rollback
Rollback plan: [回滚方案路径]
Rollback validation: [dry-run / 演练 / fallback evidence 路径]

## 10. Checklist
- [ ] Goal linked
- [ ] Issue linked
- [ ] Spec complete
- [ ] Design reviewed
- [ ] Tests passed
- [ ] Docs updated
- [ ] CHANGELOG updated
- [ ] Evidence attached
- [ ] Rollback plan exists
- [ ] Goal strict validation passed
- [ ] Matrix check-only passed
- [ ] Risk Register has no open release_blocking risk
- [ ] Validation summary exists
- [ ] Rollback validation evidence exists
```

### Release Manifest 字段

```yaml
release_id:
goal_id:
version:
status:
linked_issues:
commits:
tests:
docs_updated:
changelog:
rollback_plan:
evidence_manifest:
known_risks:
risk_register:
validation_summary:
release_gate:
  gate_id: G10
  verdict: PASS | FAIL | BLOCKED
  checked_at:
rollback_validation:
```

---

## 4. 落地计划

### 1 天计划（MVA 最小可行）

```text
- 建 docs/goal 与 .config/goal 目录结构
- 写 Goal
- 写 Task
- 写 DoD
- 跑一次完整执行循环（Goal → Task → Evidence → Review）
```

### 7 天计划

```text
- 建 Registry 系统（goals.yaml、tasks.yaml）
- 建 CI Check（至少 5 个，编号使用 `CI-CHK*`）
- 建 Evidence 目录结构
- 建 Traceability Matrix
- 建 Risk Register
- 建 Decision Log
- 完成 1 个 Issue 的完整闭环
```

### 30 天计划

```text
- 建完整 Gate 系统（G0-G11）
- 建 Agent Worktree 协议
- 建 AutoResearch 协议
- 建 Release Manifest 流程
- 建 Retrospective → Prompt Patch 闭环
- 建 CI/CD 全自动检查
- 完成 3 个 Issue 的完整闭环
- 产出第一份 Retrospective
```

### 最小可行版本（MVA）

```text
Goal → Task → DoD → Evidence → Review
```

这是最简闭环。有了这个基础，再逐步叠加 Spec、Design、Plan、Matrix、Gates、Registry。
