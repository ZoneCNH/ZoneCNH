# xlib_standard 上游 SSOT 索引

本文件是本地索引，不是可执行规格。上游事实以 `github.com/ZoneCNH/xlib-standard@93753b30e6d01fb4a9b096acaa0d7d53a2fb231c` 为准。

- Snapshot-Date: 2026-06-08
- Upstream-Commit: `93753b30e6d01fb4a9b096acaa0d7d53a2fb231c` (v0.6.5)
- Analysis-Version: v3.1.0

## 1. docs/standard/（27 个文件）

| #    | 上游文件                                        | 本地分析锚点                                                | 说明                 |
| ---: | ----------------------------------------------- | ----------------------------------------------------------- | -------------------- |
| 1    | `docs/standard/README.md`                       | `ANALYSIS.md` §1                                            | 标准目录入口         |
| 2    | `docs/standard/acceptance-matrix.md`            | `TRACEABILITY.md`                                           | 验收矩阵             |
| 3    | `docs/standard/agent-team-contract.md`          | `analysis/governance.md` §3.1                               | Agent 团队契约       |
| 4    | `docs/standard/ai-review-automation.md`         | `analysis/rules.md` §3.7                                    | AI review automation |
| 5    | `docs/standard/branch-governance.md`            | `analysis/governance.md` §3.1                               | 分支治理             |
| 6    | `docs/standard/conformance-profiles.md`         | `analysis/runtime.md` §3.7                                  | 符合性 profiles      |
| 7    | `docs/standard/debt-governance.md`              | `analysis/rules.md` §2.2 / §3.3                             | 技术债治理           |
| 8    | `docs/standard/docker-toolchain-standard.md`    | `analysis/template.md` §3.6 / `analysis/runtime.md` §3.8    | Docker 工具链标准    |
| 9    | `docs/standard/dod.md`                          | `analysis/runtime.md` §4                                    | DoD 标准             |
| 10   | `docs/standard/downstream-compatibility.md`     | `analysis/governance.md` §3.4 / §3.5                        | 下游兼容             |
| 11   | `docs/standard/downstream-registry.md`          | `analysis/governance.md` §3.2 / §3.4                        | 下游登记             |
| 12   | `docs/standard/evidence-protocol.md`            | `analysis/runtime.md` §3.5 / §4                             | 证据协议             |
| 13   | `docs/standard/goal-runtime.md`                 | `analysis/runtime.md` §3.4                                  | Goal runtime         |
| 14   | `docs/standard/goalcli-cli-contract.md`         | `analysis/runtime.md` §3.2 / §3.3                           | goalcli CLI 契约     |
| 15   | `docs/standard/goalcli-runtime.md`              | `analysis/runtime.md` §3.4                                  | goalcli runtime      |
| 16   | `docs/standard/harness-gates.md`                | `analysis/runtime.md` §3.1                                  | Harness gates        |
| 17   | `docs/standard/layer-governance-rules.md`       | `analysis/governance.md` §3.6                               | 层级治理规则         |
| 18   | `docs/standard/layering.md`                     | `analysis/governance.md` §3.6                               | 分层                 |
| 19   | `docs/standard/module-boundary.md`              | `analysis/template.md` §3.5 / `analysis/governance.md` §3.6 | 模块边界             |
| 20   | `docs/standard/release-standard.md`             | `analysis/runtime.md` §3.6 / §7                             | 发布标准             |
| 21   | `docs/standard/repository-roles.md`             | `analysis/governance.md` §3.5                               | 仓库角色             |
| 22   | `docs/standard/retrospective-and-patches.md`    | `TRACEABILITY.md`                                           | 复盘与补丁           |
| 23   | `docs/standard/security-and-secret-policy.md`   | `analysis/rules.md` §3.7 / `analysis/template.md` §4.2      | 安全与 secret        |
| 24   | `docs/standard/template-generation-contract.md` | `analysis/template.md` §3.2 / §3.5                          | 模板生成契约         |
| 25   | `docs/standard/truth-state.md`                  | `analysis/governance.md` §4.2                               | truth-state          |
| 26   | `docs/standard/versioning.md`                   | `analysis/runtime.md` §3.6                                  | 版本语义             |
| 27   | `docs/standard/xlib_standard.md`                | `ANALYSIS.md` §2 / §7                                       | xlib_standard 主标准 |

## 2. ADR（9 个 Accepted）

| #    | 上游文件                                               | 状态     | 核心决策                     |
| ---: | ------------------------------------------------------ | -------- | ---------------------------- |
| 1    | `docs/adr/ADR-20260602-001-xlib_standard-role.md`      | Accepted | xlib_standard 唯一主身份     |
| 2    | `docs/adr/ADR-20260602-002-kernel-rename.md`           | Accepted | 默认下游迁移到 kernel        |
| 3    | `docs/adr/ADR-20260602-003-core-gate.md`               | Accepted | Core Gate 五类检查           |
| 4    | `docs/adr/ADR-20260603-001-goalcli-runtime.md`         | Accepted | goalcli 唯一执行面           |
| 5    | `docs/adr/ADR-20260603-002-rules-registry.md`          | Accepted | Rule Registry SSOT           |
| 6    | `docs/adr/ADR-20260603-003-domain-rules.md`            | Accepted | 三个域规则文件               |
| 7    | `docs/adr/ADR-20260603-004-active-promotion-batch1.md` | Accepted | Registry active 提升 Batch 1 |
| 8    | `docs/adr/ADR-20260603-005-self-improving-check.md`    | Accepted | goalcli self-improving-check |
| 9    | `docs/adr/ADR-20260604-001-layer-governance.md`        | Accepted | 分层治理                     |

> 另有 `docs/adr/ADR-000-template.md` 与 `docs/adr/1.md`、`2.md`、`3.md` 历史规划文件，不计入正式 ADR。

## 3. harness.yaml gate 列表（上游裁决标准索引）

| section             | 数量   | 上游位置                                        | 说明                                       |
| ------------------- | -----: | ----------------------------------------------- | ------------------------------------------ |
| `required_gates`    | 44     | `.agent/harness/harness.yaml#required_gates`    | 只索引上游 gate 定义，本仓库不声明执行结果 |
| `extended_gates`    | 10     | `.agent/harness/harness.yaml#extended_gates`    | 只索引上游 gate 定义，本仓库不声明执行结果 |
| `final_gates`       | 6      | `.agent/harness/harness.yaml#final_gates`       | 只索引上游 gate 定义，本仓库不声明执行结果 |
| `goalcli_mva_gates` | 6      | `.agent/harness/harness.yaml#goalcli_mva_gates` | 只索引上游 gate 定义，本仓库不声明执行结果 |

## 4. 上游裁决标准位置

| 裁决标准               | 上游位置                                                                              | 本地处理                            |
| ---------------------- | ------------------------------------------------------------------------------------- | ----------------------------------- |
| DoD                    | `docs/standard/dod.md`                                                                | 不在 `ANALYSIS.md` 声明通过，仅索引 |
| Release / No-Go        | `docs/standard/release-standard.md`, `docs/release.md`, `.agent/harness/harness.yaml` | 不在本仓库维护裁决列表              |
| Evidence / truth-state | `docs/standard/evidence-protocol.md`, `docs/standard/truth-state.md`                  | 本地只保留事实边界和追溯锚点        |
| Remote governance      | `docs/standard/branch-governance.md`, GitHub API / ruleset export                     | 证据快照见 `REMOTE-EVIDENCE.md`     |
