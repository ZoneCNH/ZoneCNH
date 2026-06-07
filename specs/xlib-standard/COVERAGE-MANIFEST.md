# xlib-standard 覆盖清单

Status: Aligned-With SPEC.md v2.0.1
Generated-Date: 2026-06-07
Path-Update: 2026-06-08（改为占位符相对路径）
Last-Updated: 2026-06-08
Input-Count: 154

## 路径占位符

| 占位符 | 解析 |
|--------|------|
| `<upstream:xlib-standard>` | `github.com/ZoneCNH/xlib-standard` 仓库根（本地工作副本 `/home/xlib-standard`） |
| `<upstream:commit>`        | `93753b30e6d01fb4a9b096acaa0d7d53a2fb231c`（pinned 2026-06-08 04:59 +08:00） |
| `<upstream:tree>`          | `296e3b912c70f15434783aebcf35159f7000a01f`（HEAD^{tree}，同 commit） |
| `<external:Downloads>` | `<external-downloads>/`（上游仓库外的本地外部规划文档目录，非仓库 tracked） |

> **缺口已收敛**（2026-06-08 04:59）：upstream commit/tree sha 已固定；154 个文件已全部计算 sha256-prefix（16 hex chars，详见 §"文件级 sha256（pinned）"）。
> NG-34 / OQ-008 / R-011 在本机已可关闭，待 release-final-check 写入 `latest.json.coverage_pin` 后 release 阶段亦关闭。
>
> **固定程序**（pinning procedure，进入 `SPEC.md` Status: Approved 的前置条件）：
>
> 1. `cd <upstream:xlib-standard> && git rev-parse HEAD` → 写入 `<upstream:commit>` 槽位；
> 2. `git rev-parse HEAD^{tree}` → 写入 `<upstream:tree>` 槽位；
> 3. 对 154 个文件逐个 `sha256sum`，结果落到下方"文件级 sha256 表"；
> 4. 运行 `goalcli coverage-pin-check`，预期 exit 0；
> 5. 把 pin 结果写入 `release/manifest/latest.json.coverage_pin`，由 NG-34 校验。
>
> **复算命令**（任何 reviewer 可重放）：
>
> ```bash
> cd <upstream:xlib-standard> && bash scripts/recompute-coverage.sh
> ```
>
> 脚本输出 commit/tree sha + 154 文件 sha256 前缀，与下方表逐行比对。
> 外部 Downloads 路径通过 `EXTERNAL_DOWNLOADS` 环境变量传入（可选）。

## 覆盖摘要

| 输入范围 | 文件数 | 处理方式 |
| --- | ---: | --- |
| `<upstream:xlib-standard>/.worktree/*.md` | 12 | 作为历史计划、当前工作状态和覆盖审计证据纳入。 |
| `<upstream:xlib-standard>/docs/**` | 121 | 作为当前标准、领域补充、Evidence、L2、testing、release 和 migration 来源纳入。 |
| `<external:Downloads>/**` | 21 | 作为外部计划、v0.6/v1.0 清单、strict config 和 proof runtime 补充纳入。 |

总数：154 个文件。

## 可复现边界

本清单记录的是上游仓库 snapshot 下的输入集合，不是可移植 source bundle。原清单使用本机绝对路径（`<upstream-root>/...`），已于 2026-06-08 统一替换为占位符相对路径以提升可读性与可移植性。若迁移到其他机器或重新执行分析，必须提供同一 source pack、路径映射，或重新生成本清单。

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

- `<external:Downloads>/<runtime-state>/session-started.json`
- `<external:Downloads>/<runtime-state>/session-started.json`
- `<external:Downloads>/<runtime-state>/session-started.json`
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

## 文件级 sha256（pinned 2026-06-08 04:59 +08:00）

> 取 sha256sum 前 16 hex（64 bit）以保证表格可读。完整 sha256 由 `goalcli coverage-pin` 在 release 阶段写入 `latest.json.coverage_pin.files[].sha256`。

```text
fea18bcc5281f6a7  <upstream:xlib-standard>/docs/adr/1.md
a689f655e501569d  <upstream:xlib-standard>/docs/adr/2.md
9f8787a8627c1422  <upstream:xlib-standard>/docs/adr/3.md
5dae902b645cdea7  <upstream:xlib-standard>/docs/adr/ADR-000-template.md
1cd311695577f4f9  <upstream:xlib-standard>/docs/adr/ADR-20260602-001-xlib-standard-role.md
d3258e44c98af931  <upstream:xlib-standard>/docs/adr/ADR-20260602-002-kernel-rename.md
73c163eda6f9f024  <upstream:xlib-standard>/docs/adr/ADR-20260602-003-core-gate.md
136fcda678f7178f  <upstream:xlib-standard>/docs/adr/ADR-20260603-001-goalcli-runtime.md
ea5d485967a63ea4  <upstream:xlib-standard>/docs/adr/ADR-20260603-002-rules-registry.md
d82de408a1628b81  <upstream:xlib-standard>/docs/adr/ADR-20260603-003-domain-rules.md
a42ee60892eef795  <upstream:xlib-standard>/docs/adr/ADR-20260603-004-active-promotion-batch1.md
8a44357a77eb92ed  <upstream:xlib-standard>/docs/adr/ADR-20260603-005-self-improving-check.md
51dcb929bf2e9e1e  <upstream:xlib-standard>/docs/adr/ADR-20260604-001-layer-governance.md
f9ef9175731b7d54  <upstream:xlib-standard>/docs/api.md
4ef82ab596ac7eac  <upstream:xlib-standard>/docs/architecture/README.md
a844f0a70a728d7d  <upstream:xlib-standard>/docs/config.md
1204bdf88fd1dae7  <upstream:xlib-standard>/docs/design.md
c32a2987a5e60309  <upstream:xlib-standard>/docs/downstream-matrix.md
a11ded92df2f4d93  <upstream:xlib-standard>/docs/downstream-sync-policy.md
edf17e9775c60b7b  <upstream:xlib-standard>/docs/errors.md
012e6c3af5faf716  <upstream:xlib-standard>/docs/evidence/branch-governance-rea-131e4dc5/final-release-governance.md
c6b83bb8408cdb68  <upstream:xlib-standard>/docs/evidence/branch-governance-rea-131e4dc5/task-3-merge-risk.md
598a83fc0e8d8710  <upstream:xlib-standard>/docs/evidence/GOAL-20260606-001/EVID-TASK-GOAL-20260606-001-20260606-001.md
d82c9371f29cc856  <upstream:xlib-standard>/docs/evidence/GOAL-20260606-002/EVID-TASK-GOAL-20260606-002-20260606-001.md
ebb5461155d07f43  <upstream:xlib-standard>/docs/evidence/GOAL-20260606-002/PLAN-GOAL-20260606-002-v0.1.md
59fc8ee9a9d44aed  <upstream:xlib-standard>/docs/evidence/GOAL-20260606-AGENTS-ANALYSIS/EVID-TASK-GOAL-20260606-AGENTS-ANALYSIS-20260606-001.md
421a109f5104af93  <upstream:xlib-standard>/docs/evidence/GOAL-20260606-RULE-STRUCTURE-FIX/evidence.md
2d498c5ff3fe034c  <upstream:xlib-standard>/docs/evidence/GOAL-20260607-001/EVID-TASK-GOAL-20260607-001-001-20260607-001.md
74173fdc28739fcf  <upstream:xlib-standard>/docs/evidence/GOAL-20260607-001/harness-subagents.md
0290fadf2c7386a5  <upstream:xlib-standard>/docs/evidence/GOAL-20260607-001/merge-version-increment.md
a1c19e27a4e89196  <upstream:xlib-standard>/docs/evidence/GOAL-20260607-001/project-subagents.md
006b201c70867fc1  <upstream:xlib-standard>/docs/evidence/GOAL-20260607-001/subagents-supplement.md
d9fd16469420fe57  <upstream:xlib-standard>/docs/evidence/GOAL-20260607-AI-REVIEW-AUTOMATION/EVID-TASK-GOAL-20260607-AI-REVIEW-AUTOMATION-001-20260607-001.md
833b26e53fdca463  <upstream:xlib-standard>/docs/evidence/GOAL-20260607-DOCS-ALIGNMENT/EVID-TASK-GOAL-20260607-DOCS-ALIGNMENT-20260607-001.md
5ec7ffc74a42ea85  <upstream:xlib-standard>/docs/evidence/GOAL-20260607-RELEASE-VERSION-ALIGNMENT/EVID-TASK-GOAL-20260607-RELEASE-VERSION-ALIGNMENT-001-20260607-001.md
4de9dba642a477c6  <upstream:xlib-standard>/docs/generation.md
dd094999fdafabb8  <upstream:xlib-standard>/docs/goal/goal.md
472f5c5220089ba9  <upstream:xlib-standard>/docs/goal/todo.md
0f2253cd4743ee8e  <upstream:xlib-standard>/docs/independent-audit-20260602.md
311f08f64f5cffff  <upstream:xlib-standard>/docs/l2/00_index.md
4c4cd3f02773e2fb  <upstream:xlib-standard>/docs/l2/01_xlib-standard_execution_plan.md
e7751d608c0fabf7  <upstream:xlib-standard>/docs/l2/02_testkitx_execution_plan.md
bd0e5d9a5107164b  <upstream:xlib-standard>/docs/l2/03_xlibgate_execution_plan.md
b5406100cd8c83a6  <upstream:xlib-standard>/docs/l2/04_redisx_execution_plan.md
db27d45de90285fe  <upstream:xlib-standard>/docs/l2/05_postgresx_execution_plan.md
77a2395a1adcc8fe  <upstream:xlib-standard>/docs/l2/06_natsx_execution_plan.md
d98cbfc5eabe576b  <upstream:xlib-standard>/docs/l2/07_kafkax_execution_plan.md
e5e4ac41651c572e  <upstream:xlib-standard>/docs/l2/08_ossx_execution_plan.md
60a38e36a09d0931  <upstream:xlib-standard>/docs/l2/09_clickhousex_execution_plan.md
57bbff3e672604a0  <upstream:xlib-standard>/docs/l2/10_taosx_execution_plan.md
1a9f27ad7444551b  <upstream:xlib-standard>/docs/l2/11_xgo-market-data_adoption_plan.md
64d9ff4c5c7ce4ad  <upstream:xlib-standard>/docs/l2/12_xgo-macro-data_adoption_plan.md
42a87fd65e91a5b3  <upstream:xlib-standard>/docs/l2/13_engines_adoption_plan.md
d0ee48223a1547e6  <upstream:xlib-standard>/docs/l2/14_xgo_runtime_system_gate_plan.md
3b451fc9b3e246a2  <upstream:xlib-standard>/docs/migration/baselib-template-to-xlib-standard.md
888dbdcb9bc8376c  <upstream:xlib-standard>/docs/observability.md
d474248fe0916273  <upstream:xlib-standard>/docs/plans/goalcli-mutating-automation-guardrails.md
16ccfa2f8a17c459  <upstream:xlib-standard>/docs/plans/goalcli-v0.1.0-migration-index.md
fc52cf925ac2b78f  <upstream:xlib-standard>/docs/plans/goalcli-v0.1.0-roadmap.md
d1d164aeb4236941  <upstream:xlib-standard>/docs/plans/goalcli-v0.2.0-gap-ledger.md
1386b570344c1fa5  <upstream:xlib-standard>/docs/private-business-consumer-guide.md
aa4665be78af3123  <upstream:xlib-standard>/docs/project-analysis-20260602.md
14dbf80c82e13ea1  <upstream:xlib-standard>/docs/project-structural-analysis-20260604.md
f38c1fb8777bbda0  <upstream:xlib-standard>/docs/project-structural-analysis-20260605.md
73df9e58b3a1e7f2  <upstream:xlib-standard>/docs/quickstart.md
3cd41f676656340f  <upstream:xlib-standard>/docs/release.md
5e042beb293491e7  <upstream:xlib-standard>/docs/reports/rules-deep-analysis-20260605.md
315022f05a8a6300  <upstream:xlib-standard>/docs/review-20260606.md
7ba908d1bc41edf9  <upstream:xlib-standard>/docs/scorecard.md
d2bd9ebaf9d05c00  <upstream:xlib-standard>/docs/self-improving/docker-toolchain.md
16898e3ac0dd7f1e  <upstream:xlib-standard>/docs/self-improving/docker-toolchain-structural-report.md
37f99cdf3e03d49e  <upstream:xlib-standard>/docs/spec.md
0977d20d6a7cf5d1  <upstream:xlib-standard>/docs/standard/acceptance-matrix.md
e59cd6a268e465ac  <upstream:xlib-standard>/docs/standard/agent-team-contract.md
04b9b8a647793bf5  <upstream:xlib-standard>/docs/standard/ai-review-automation.md
58d66b6165cb4995  <upstream:xlib-standard>/docs/standard/branch-governance.md
f98c038880789643  <upstream:xlib-standard>/docs/standard/conformance-profiles.md
5b5d4e8732c6ee26  <upstream:xlib-standard>/docs/standard/debt-governance.md
b41b5172859b46c7  <upstream:xlib-standard>/docs/standard/docker-toolchain-standard.md
bea93de0ead64d97  <upstream:xlib-standard>/docs/standard/dod.md
8c9a0a0481904da2  <upstream:xlib-standard>/docs/standard/downstream-compatibility.md
1353c77a87a79c16  <upstream:xlib-standard>/docs/standard/downstream-registry.md
aafdffcccf5674f3  <upstream:xlib-standard>/docs/standard/evidence-protocol.md
00cd547509973088  <upstream:xlib-standard>/docs/standard/goalcli-cli-contract.md
cadb5e3565897cae  <upstream:xlib-standard>/docs/standard/goalcli-runtime.md
219abb09a82c67d6  <upstream:xlib-standard>/docs/standard/goal-runtime.md
fc0c953514f0ece4  <upstream:xlib-standard>/docs/standard/harness-gates.md
5d5cee89e7e33d3d  <upstream:xlib-standard>/docs/standard/layer-governance-rules.md
8740504313d83d51  <upstream:xlib-standard>/docs/standard/layering.md
574857e59477c555  <upstream:xlib-standard>/docs/standard/module-boundary.md
74b022160e0d8e66  <upstream:xlib-standard>/docs/standard/README.md
d79f5fed1d6510b8  <upstream:xlib-standard>/docs/standard/release-standard.md
b4176a439c7b770f  <upstream:xlib-standard>/docs/standard/repository-roles.md
1b810e7d86bed799  <upstream:xlib-standard>/docs/standard/retrospective-and-patches.md
22ef9396c1182269  <upstream:xlib-standard>/docs/standard/security-and-secret-policy.md
429b73cbf892d681  <upstream:xlib-standard>/docs/standard/template-generation-contract.md
269c1829a98e243d  <upstream:xlib-standard>/docs/standard/truth-state.md
b3f42b7b89aa016c  <upstream:xlib-standard>/docs/standard/versioning.md
ce1d6ffe267a4349  <upstream:xlib-standard>/docs/standard/xlib-standard.md
a1981a18ec1d5669  <upstream:xlib-standard>/docs/structural-issues-20260602.md
f7790a510c79730e  <upstream:xlib-standard>/docs/supply-chain.md
79c0221cb6791a13  <upstream:xlib-standard>/docs/testing/l2-adapter-testing-standard.md
5901fadeee261ce8  <upstream:xlib-standard>/docs/testing/l2-capability-manifest.md
cf4773b1c0952c89  <upstream:xlib-standard>/docs/testing/l2-compatibility-matrix.md
05eb329fef14c3b7  <upstream:xlib-standard>/docs/testing/l2-compliance-matrix.md
0229c3bc52a5c4b3  <upstream:xlib-standard>/docs/testing/l2-contract-pack-registry.md
8304d1773365dbaa  <upstream:xlib-standard>/docs/testing/l2-downstream-adoption.md
694e706b69b941e4  <upstream:xlib-standard>/docs/testing/l2-evidence-standard.md
02c710741cd0c0f2  <upstream:xlib-standard>/docs/testing/l2-release-gate.md
bdf4a1ecaaeb164d  <upstream:xlib-standard>/docs/testing/l2-rollout-playbook.md
9f752a33b90951dc  <upstream:xlib-standard>/docs/testing.md
1a7e42f754fb64f3  <upstream:xlib-standard>/docs/test-strategy.md
4b1fcd1ea0906e5d  <upstream:xlib-standard>/docs/troubleshooting.md
5a1953dd6e58d57a  <upstream:xlib-standard>/docs/v0.6.0/strict-config-root-omission-audit.md
47bc6d58cdb4cfe5  <upstream:xlib-standard>/docs/v0.6.0/strict-config-root-v4-closure-audit.md
f790b9d08f296f51  <upstream:xlib-standard>/docs/v0.6.0/xlib-standard-latest-v0.4.15-complete-optimization-20260605.md
e1201c17ca224e77  <upstream:xlib-standard>/docs/v0.6.0/xlib-standard-strict-config-root-goal-plan.md
0ec907050d3f327f  <upstream:xlib-standard>/docs/v0.6.0/xlib-standard-strict-config-root-goal-plan-v2-audited.md
f8866cee6522d288  <upstream:xlib-standard>/docs/v0.6.0/xlib-standard-strict-config-root-goal-plan-v3-final-executable.md
7889aa6980ff85b8  <upstream:xlib-standard>/docs/v0.6.0/xlib-standard-strict-config-root-goal-plan-v5-ultimate.md
3d69618bf99d3333  <upstream:xlib-standard>/docs/xgo-integration-boundary.md
4697b557b6dc462c  <upstream:xlib-standard>/.worktree/context.md
ba683a25201a0d93  <upstream:xlib-standard>/.worktree/debt.md
e2389a269c1ee640  <upstream:xlib-standard>/.worktree/git.md
1706542ce66dac7f  <upstream:xlib-standard>/.worktree/goalcli-v0.1.0-plan.md
8ab6a168757479eb  <upstream:xlib-standard>/.worktree/goal.md
f925456f67e2ba4f  <upstream:xlib-standard>/.worktree/goal-patch.md
38d59f1542ef529f  <upstream:xlib-standard>/.worktree/L.md
4fc2c25477680a75  <upstream:xlib-standard>/.worktree/main-现状分析.md
b25e9bdaa3022664  <upstream:xlib-standard>/.worktree/main.md
0571d4c18bcee530  <upstream:xlib-standard>/.worktree/stable.md
7c25f2b564223c24  <upstream:xlib-standard>/.worktree/todo.md
498f6108564fe646  <upstream:xlib-standard>/.worktree/v3.0.md
16a5d80c632de7ea  <external:Downloads>/session-started.json
7dc20ed88242c9c0  <external:Downloads>/session-started.json
bb24a50952bdee94  <external:Downloads>/session-started.json
bd5d623b4318d1b7  <external:Downloads>/seventh_review_addendum.md
c8da2a06fafca77b  <external:Downloads>/xlib-standard_downstream_sync_governance_full_execution_plan.md
092d895ab2591e91  <external:Downloads>/xlib-standard-latest-v0.4.15-complete-optimization-20260605.md
c0bf4be0960b8e00  <external:Downloads>/xlib-standard-strict-config-root-goal-plan.md
a4e497f12f324cc1  <external:Downloads>/xlib-standard-strict-config-root-goal-plan-v2-audited (1).md
a4e497f12f324cc1  <external:Downloads>/xlib-standard-strict-config-root-goal-plan-v2-audited.md
c26fe3703be1bf24  <external:Downloads>/xlib-standard-strict-config-root-goal-plan-v3-final-executable.md
560fb71ccf070d38  <external:Downloads>/xlib-standard-strict-config-root-goal-plan-v5-ultimate.md
0571d4c18bcee530  <external:Downloads>/xlib-standard-v1.0.0-config-goal.md
9a78fa79e501a237  <external:Downloads>/xlib-standard-v1.0.0-config-goal-v2-omission-checked.md
5945365fec2b6344  <external:Downloads>/xlib-standard-v1.0.0-delivery-checklist-cleaned-v2.md
f7a1763e636af2ce  <external:Downloads>/xlib-standard-v1.0.0-delivery-checklist-cleaned-v3.md
4c207e7b69116ad9  <external:Downloads>/xlib-standard-v1.0.0-delivery-checklist-cleaned-v4.md
19093d21794e8749  <external:Downloads>/xlib-standard-v1.0.0-delivery-checklist-cleaned-v5.md
ad3510ac14abce42  <external:Downloads>/xlib-standard-v1.0.0-delivery-checklist.md
5edaf6ab3e88ebc0  <external:Downloads>/xlib-standard-v1.0.0-delivery-checklist-reviewed.md
f85d76b561a4572a  <external:Downloads>/xlib_standard_v3_proof_runtime_goal_checked_v1_1.md
f8dffdcb010ad2b7  <external:Downloads>/xlib_standard_v3_proof_runtime_goal.md
```
