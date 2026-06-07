# xlib-standard 覆盖清单

Status: Aligned-With SPEC.md v2.0.1
Generated-Date: 2026-06-07
Path-Update: 2026-06-08（改为占位符相对路径）
Last-Updated: 2026-06-08
Input-Count: 154

## 路径占位符

| 占位符 | 解析 |
|--------|------|
| `<upstream:xlib-standard>` | `github.com/ZoneCNH/xlib-standard` 仓库根 |
| `<upstream:commit>`        | 上游 commit sha（**当前未固定，占位待补**，参见下方"可复现边界"） |
| `<upstream:tree>`          | 上游 tree sha（**当前未固定，占位待补**） |
| `<external:Downloads>` | 上游仓库外的本地外部规划文档目录（非仓库 tracked） |

> **当前缺口**：本清单未绑定 upstream commit sha 与逐文件 sha256；任何跨机器复现仍需补充 source pack 或 digest。这是已知结构缺口（已纳入 `SPEC.md` §23 OQ-008 / 附录 A R-011 跟踪，并由 §22.4 NG-34 在 release 阶段强制固定）。

## 覆盖摘要

| 输入范围 | 文件数 | 处理方式 |
| --- | ---: | --- |
| `<upstream:xlib-standard>/.worktree/*.md` | 12 | 作为历史计划、当前工作状态和覆盖审计证据纳入。 |
| `<upstream:xlib-standard>/docs/**` | 121 | 作为当前标准、领域补充、Evidence、L2、testing、release 和 migration 来源纳入。 |
| `<external:Downloads>/**` | 21 | 作为外部计划、v0.6/v1.0 清单、strict config 和 proof runtime 补充纳入。 |

总数：154 个文件。

## 可复现边界

本清单记录的是上游仓库 snapshot 下的输入集合，不是可移植 source bundle。原清单使用本机绝对路径（`/home/xlib-standard/...`），已于 2026-06-08 统一替换为占位符相对路径以提升可读性与可移植性。若迁移到其他机器或重新执行分析，必须提供同一 source pack、路径映射，或重新生成本清单。

本清单证明输入文件集合数量和路径稳定，不证明这些源文件内容在未来时间点保持不变。若需要内容级复现，必须补充 source digest、tree sha 或归档 artifact。

## `.worktree/*.md`

- `<upstream:xlib-standard>/.worktree/L.md`
- `<upstream:xlib-standard>/.worktree/context.md`
- `<upstream:xlib-standard>/.worktree/debt.md`
- `<upstream:xlib-standard>/.worktree/git.md`
- `<upstream:xlib-standard>/.worktree/goal-patch.md`
- `<upstream:xlib-standard>/.worktree/goal.md`
- `<upstream:xlib-standard>/.worktree/goalcli-v0.1.0-plan.md`
- `<upstream:xlib-standard>/.worktree/main-现状分析.md`
- `<upstream:xlib-standard>/.worktree/main.md`
- `<upstream:xlib-standard>/.worktree/stable.md`
- `<upstream:xlib-standard>/.worktree/todo.md`
- `<upstream:xlib-standard>/.worktree/v3.0.md`

## `<upstream:xlib-standard>/docs/**`

- `<upstream:xlib-standard>/docs/adr/1.md`
- `<upstream:xlib-standard>/docs/adr/2.md`
- `<upstream:xlib-standard>/docs/adr/3.md`
- `<upstream:xlib-standard>/docs/adr/ADR-000-template.md`
- `<upstream:xlib-standard>/docs/adr/ADR-20260602-001-xlib-standard-role.md`
- `<upstream:xlib-standard>/docs/adr/ADR-20260602-002-kernel-rename.md`
- `<upstream:xlib-standard>/docs/adr/ADR-20260602-003-core-gate.md`
- `<upstream:xlib-standard>/docs/adr/ADR-20260603-001-goalcli-runtime.md`
- `<upstream:xlib-standard>/docs/adr/ADR-20260603-002-rules-registry.md`
- `<upstream:xlib-standard>/docs/adr/ADR-20260603-003-domain-rules.md`
- `<upstream:xlib-standard>/docs/adr/ADR-20260603-004-active-promotion-batch1.md`
- `<upstream:xlib-standard>/docs/adr/ADR-20260603-005-self-improving-check.md`
- `<upstream:xlib-standard>/docs/adr/ADR-20260604-001-layer-governance.md`
- `<upstream:xlib-standard>/docs/api.md`
- `<upstream:xlib-standard>/docs/architecture/README.md`
- `<upstream:xlib-standard>/docs/config.md`
- `<upstream:xlib-standard>/docs/design.md`
- `<upstream:xlib-standard>/docs/downstream-matrix.md`
- `<upstream:xlib-standard>/docs/downstream-sync-policy.md`
- `<upstream:xlib-standard>/docs/errors.md`
- `<upstream:xlib-standard>/docs/evidence/GOAL-20260606-001/EVID-TASK-GOAL-20260606-001-20260606-001.md`
- `<upstream:xlib-standard>/docs/evidence/GOAL-20260606-002/EVID-TASK-GOAL-20260606-002-20260606-001.md`
- `<upstream:xlib-standard>/docs/evidence/GOAL-20260606-002/PLAN-GOAL-20260606-002-v0.1.md`
- `<upstream:xlib-standard>/docs/evidence/GOAL-20260606-AGENTS-ANALYSIS/EVID-TASK-GOAL-20260606-AGENTS-ANALYSIS-20260606-001.md`
- `<upstream:xlib-standard>/docs/evidence/GOAL-20260606-RULE-STRUCTURE-FIX/evidence.md`
- `<upstream:xlib-standard>/docs/evidence/GOAL-20260607-001/EVID-TASK-GOAL-20260607-001-001-20260607-001.md`
- `<upstream:xlib-standard>/docs/evidence/GOAL-20260607-001/harness-subagents.md`
- `<upstream:xlib-standard>/docs/evidence/GOAL-20260607-001/merge-version-increment.md`
- `<upstream:xlib-standard>/docs/evidence/GOAL-20260607-001/project-subagents.md`
- `<upstream:xlib-standard>/docs/evidence/GOAL-20260607-001/subagents-supplement.md`
- `<upstream:xlib-standard>/docs/evidence/GOAL-20260607-AI-REVIEW-AUTOMATION/EVID-TASK-GOAL-20260607-AI-REVIEW-AUTOMATION-001-20260607-001.md`
- `<upstream:xlib-standard>/docs/evidence/GOAL-20260607-DOCS-ALIGNMENT/EVID-TASK-GOAL-20260607-DOCS-ALIGNMENT-20260607-001.md`
- `<upstream:xlib-standard>/docs/evidence/GOAL-20260607-RELEASE-VERSION-ALIGNMENT/EVID-TASK-GOAL-20260607-RELEASE-VERSION-ALIGNMENT-001-20260607-001.md`
- `<upstream:xlib-standard>/docs/evidence/branch-governance-rea-131e4dc5/final-release-governance.md`
- `<upstream:xlib-standard>/docs/evidence/branch-governance-rea-131e4dc5/task-3-merge-risk.md`
- `<upstream:xlib-standard>/docs/generation.md`
- `<upstream:xlib-standard>/docs/goal/goal.md`
- `<upstream:xlib-standard>/docs/goal/todo.md`
- `<upstream:xlib-standard>/docs/independent-audit-20260602.md`
- `<upstream:xlib-standard>/docs/l2/00_index.md`
- `<upstream:xlib-standard>/docs/l2/01_xlib-standard_execution_plan.md`
- `<upstream:xlib-standard>/docs/l2/02_testkitx_execution_plan.md`
- `<upstream:xlib-standard>/docs/l2/03_xlibgate_execution_plan.md`
- `<upstream:xlib-standard>/docs/l2/04_redisx_execution_plan.md`
- `<upstream:xlib-standard>/docs/l2/05_postgresx_execution_plan.md`
- `<upstream:xlib-standard>/docs/l2/06_natsx_execution_plan.md`
- `<upstream:xlib-standard>/docs/l2/07_kafkax_execution_plan.md`
- `<upstream:xlib-standard>/docs/l2/08_ossx_execution_plan.md`
- `<upstream:xlib-standard>/docs/l2/09_clickhousex_execution_plan.md`
- `<upstream:xlib-standard>/docs/l2/10_taosx_execution_plan.md`
- `<upstream:xlib-standard>/docs/l2/11_xgo-market-data_adoption_plan.md`
- `<upstream:xlib-standard>/docs/l2/12_xgo-macro-data_adoption_plan.md`
- `<upstream:xlib-standard>/docs/l2/13_engines_adoption_plan.md`
- `<upstream:xlib-standard>/docs/l2/14_xgo_runtime_system_gate_plan.md`
- `<upstream:xlib-standard>/docs/migration/baselib-template-to-xlib-standard.md`
- `<upstream:xlib-standard>/docs/observability.md`
- `<upstream:xlib-standard>/docs/plans/goalcli-mutating-automation-guardrails.md`
- `<upstream:xlib-standard>/docs/plans/goalcli-v0.1.0-migration-index.md`
- `<upstream:xlib-standard>/docs/plans/goalcli-v0.1.0-roadmap.md`
- `<upstream:xlib-standard>/docs/plans/goalcli-v0.2.0-gap-ledger.md`
- `<upstream:xlib-standard>/docs/private-business-consumer-guide.md`
- `<upstream:xlib-standard>/docs/project-analysis-20260602.md`
- `<upstream:xlib-standard>/docs/project-structural-analysis-20260604.md`
- `<upstream:xlib-standard>/docs/project-structural-analysis-20260605.md`
- `<upstream:xlib-standard>/docs/quickstart.md`
- `<upstream:xlib-standard>/docs/release.md`
- `<upstream:xlib-standard>/docs/reports/rules-deep-analysis-20260605.md`
- `<upstream:xlib-standard>/docs/review-20260606.md`
- `<upstream:xlib-standard>/docs/scorecard.md`
- `<upstream:xlib-standard>/docs/self-improving/docker-toolchain-structural-report.md`
- `<upstream:xlib-standard>/docs/self-improving/docker-toolchain.md`
- `<upstream:xlib-standard>/docs/spec.md`
- `<upstream:xlib-standard>/docs/standard/README.md`
- `<upstream:xlib-standard>/docs/standard/acceptance-matrix.md`
- `<upstream:xlib-standard>/docs/standard/agent-team-contract.md`
- `<upstream:xlib-standard>/docs/standard/ai-review-automation.md`
- `<upstream:xlib-standard>/docs/standard/branch-governance.md`
- `<upstream:xlib-standard>/docs/standard/conformance-profiles.md`
- `<upstream:xlib-standard>/docs/standard/debt-governance.md`
- `<upstream:xlib-standard>/docs/standard/docker-toolchain-standard.md`
- `<upstream:xlib-standard>/docs/standard/dod.md`
- `<upstream:xlib-standard>/docs/standard/downstream-compatibility.md`
- `<upstream:xlib-standard>/docs/standard/downstream-registry.md`
- `<upstream:xlib-standard>/docs/standard/evidence-protocol.md`
- `<upstream:xlib-standard>/docs/standard/goal-runtime.md`
- `<upstream:xlib-standard>/docs/standard/goalcli-cli-contract.md`
- `<upstream:xlib-standard>/docs/standard/goalcli-runtime.md`
- `<upstream:xlib-standard>/docs/standard/harness-gates.md`
- `<upstream:xlib-standard>/docs/standard/layer-governance-rules.md`
- `<upstream:xlib-standard>/docs/standard/layering.md`
- `<upstream:xlib-standard>/docs/standard/module-boundary.md`
- `<upstream:xlib-standard>/docs/standard/release-standard.md`
- `<upstream:xlib-standard>/docs/standard/repository-roles.md`
- `<upstream:xlib-standard>/docs/standard/retrospective-and-patches.md`
- `<upstream:xlib-standard>/docs/standard/security-and-secret-policy.md`
- `<upstream:xlib-standard>/docs/standard/template-generation-contract.md`
- `<upstream:xlib-standard>/docs/standard/truth-state.md`
- `<upstream:xlib-standard>/docs/standard/versioning.md`
- `<upstream:xlib-standard>/docs/standard/xlib-standard.md`
- `<upstream:xlib-standard>/docs/structural-issues-20260602.md`
- `<upstream:xlib-standard>/docs/supply-chain.md`
- `<upstream:xlib-standard>/docs/test-strategy.md`
- `<upstream:xlib-standard>/docs/testing.md`
- `<upstream:xlib-standard>/docs/testing/l2-adapter-testing-standard.md`
- `<upstream:xlib-standard>/docs/testing/l2-capability-manifest.md`
- `<upstream:xlib-standard>/docs/testing/l2-compatibility-matrix.md`
- `<upstream:xlib-standard>/docs/testing/l2-compliance-matrix.md`
- `<upstream:xlib-standard>/docs/testing/l2-contract-pack-registry.md`
- `<upstream:xlib-standard>/docs/testing/l2-downstream-adoption.md`
- `<upstream:xlib-standard>/docs/testing/l2-evidence-standard.md`
- `<upstream:xlib-standard>/docs/testing/l2-release-gate.md`
- `<upstream:xlib-standard>/docs/testing/l2-rollout-playbook.md`
- `<upstream:xlib-standard>/docs/troubleshooting.md`
- `<upstream:xlib-standard>/docs/v0.6.0/strict-config-root-omission-audit.md`
- `<upstream:xlib-standard>/docs/v0.6.0/strict-config-root-v4-closure-audit.md`
- `<upstream:xlib-standard>/docs/v0.6.0/xlib-standard-latest-v0.4.15-complete-optimization-20260605.md`
- `<upstream:xlib-standard>/docs/v0.6.0/xlib-standard-strict-config-root-goal-plan-v2-audited.md`
- `<upstream:xlib-standard>/docs/v0.6.0/xlib-standard-strict-config-root-goal-plan-v3-final-executable.md`
- `<upstream:xlib-standard>/docs/v0.6.0/xlib-standard-strict-config-root-goal-plan-v5-ultimate.md`
- `<upstream:xlib-standard>/docs/v0.6.0/xlib-standard-strict-config-root-goal-plan.md`
- `<upstream:xlib-standard>/docs/xgo-integration-boundary.md`

## `<external:Downloads>/**`

- `<external:Downloads>/.omc/state/sessions/8f79f61c-b905-43ee-ac14-793222c63d3b/session-started.json`
- `<external:Downloads>/.omc/state/sessions/99d6ec5a-4516-4cb7-b155-ae16afb484ef/session-started.json`
- `<external:Downloads>/.omc/state/sessions/fba51ec5-f66f-401c-8921-81d5eee0bbd1/session-started.json`
- `<external:Downloads>/seventh_review_addendum.md`
- `<external:Downloads>/xlib-standard-latest-v0.4.15-complete-optimization-20260605.md`
- `<external:Downloads>/xlib-standard-strict-config-root-goal-plan-v2-audited (1).md`
- `<external:Downloads>/xlib-standard-strict-config-root-goal-plan-v2-audited.md`
- `<external:Downloads>/xlib-standard-strict-config-root-goal-plan-v3-final-executable.md`
- `<external:Downloads>/xlib-standard-strict-config-root-goal-plan-v5-ultimate.md`
- `<external:Downloads>/xlib-standard-strict-config-root-goal-plan.md`
- `<external:Downloads>/xlib-standard-v1.0.0-config-goal-v2-omission-checked.md`
- `<external:Downloads>/xlib-standard-v1.0.0-config-goal.md`
- `<external:Downloads>/xlib-standard-v1.0.0-delivery-checklist-cleaned-v2.md`
- `<external:Downloads>/xlib-standard-v1.0.0-delivery-checklist-cleaned-v3.md`
- `<external:Downloads>/xlib-standard-v1.0.0-delivery-checklist-cleaned-v4.md`
- `<external:Downloads>/xlib-standard-v1.0.0-delivery-checklist-cleaned-v5.md`
- `<external:Downloads>/xlib-standard-v1.0.0-delivery-checklist-reviewed.md`
- `<external:Downloads>/xlib-standard-v1.0.0-delivery-checklist.md`
- `<external:Downloads>/xlib-standard_downstream_sync_governance_full_execution_plan.md`
- `<external:Downloads>/xlib_standard_v3_proof_runtime_goal.md`
- `<external:Downloads>/xlib_standard_v3_proof_runtime_goal_checked_v1_1.md`

## 校验说明

`1000-pass` 覆盖校验只证明输入文件集合数量和清单稳定，不声称对同一语义进行了 1000 次独立人工审查。语义合成由 agent team 分片分析、主线程证据收敛、`TRACEABILITY.md` 和 `CONFLICT-LEDGER.md` 共同约束。
