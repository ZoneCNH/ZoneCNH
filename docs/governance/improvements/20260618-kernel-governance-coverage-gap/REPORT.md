# Kernel governance 覆盖缺口报告

> 范围：task-3 领导指令已收窄为“只做审查/文档覆盖缺口报告”。本文记录当前治理覆盖、缺口与最小后续动作；不修复源码/CI，不作为 Factory/GK-9/GK-10 通过证据。

## 1. 结论

当前 `docs/governance/` 已定义 Spec 生命周期、追溯矩阵、DoR/DoD 与 `docs/governance/` / `module/` 的目录边界，但对 ZoneCNH/kernel 运行态证据链仍存在五类缺口：

| 主题 | 当前覆盖 | 缺口 | 风险 |
| --- | --- | --- | --- |
| Canonical path | `docs/governance/README.md` 仅说明治理文档与模块产物边界 | 未定义 kernel governance evidence 工作区的规范占位符、禁止硬编码的路径模式与历史证据例外 | active docs 可继续出现本地绝对路径 |
| 运行态 / worktree / team state | `docs/governance/DEVELOPMENT-WORKFLOW.md`、`CONSTITUTION.md` 说明 workspace 与协作纪律 | 未把 `$OMX_TEAM_STATE_ROOT`、team task、worker worktree、claim token 生命周期落成可校验契约 | leader audit、worker 状态与仓库证据容易脱节 |
| ID / Status | `docs/governance/TRACEABILITY.md` 定义 FR/BR、Task、Status 与枚举；`traceability-check.sh` 校验枚举 | 未校验 task id 与 OMX task file、matrix、status report 的跨文件一致性 | “Done/Implemented” 可早于 task/evidence 闭环 |
| 证据晋级 | `docs/governance/LIFECYCLE.md` 要求 Approved -> Implemented 依赖全部 FR Done 与 DoD 证据 | 未定义从 worker 验证、evidence package、leader audit 到 Factory/GK gate 的晋级门槛 | 局部验证可能被误读为 Factory/GK pass |
| 最小治理 lint | `.github/ci/grep-guard.sh`、`spec-governance-check.sh`、`traceability-check.sh` 覆盖基础格式与部分敏感模式 | 未覆盖 stale kernel path、team/worktree 运行态契约、证据晋级闭环 | 发现过的治理漂移可重复进入 committed docs |

## 2. 已发现 stale path 引用

以下命令发现 committed docs 中仍有 stale `/home/ZoneCNH-kernel-governance-evidence` 引用：

```bash
rg -n --hidden "/home/ZoneCNH-kernel-governance-evidence" -S . --glob '!/.git/**' --glob '!AGENTS.md'
```

结果：

- `module/kernel/ACCEPTANCE.md:104` — 验证命令仍要求 `cd /home/ZoneCNH-kernel-governance-evidence`。
- `.config/goal/evidence/2026-06-18/TASK-KERNEL-BLK-011/EVID-KERNEL-BLK-011-EVIDENCE-PACKAGE-001.md:59` — Evidence workspace 记录为 stale absolute path。
- `.config/goal/evidence/2026-06-18/TASK-KERNEL-BLK-011/EVID-KERNEL-BLK-011-EVIDENCE-PACKAGE-001.md:162` — 验证命令仍要求 `cd /home/ZoneCNH-kernel-governance-evidence`。

本报告未直接修改这些引用，因为 leader 已将本 lane 收窄为报告-only。推荐后续将 active 指令中的本地路径统一替换为 repo-relative 或环境变量占位符，例如 `$KERNEL_GOVERNANCE_EVIDENCE_ROOT` / `<kernel-governance-evidence-root>`，并为历史归档证据定义显式例外。

## 3. 现有治理覆盖与可见 enforcement

- `docs/governance/README.md:41-45`：说明 `docs/governance/` 承载规则、模板、rubric、门禁协议，`module/{module}/` 承载模块级产物；跨平台 agent、CI、CODEOWNERS 应引用 `docs/governance/...`。
- `docs/governance/TRACEABILITY.md:39-68`：定义最小矩阵列、FR/BR 覆盖、AC/TC/Task/Status 规则。
- `docs/governance/TRACEABILITY.md:74-97`：定义 Status 语义与 `TRACEABILITY_STRICT=1 bash .github/ci/traceability-check.sh` 校验范围。
- `docs/governance/LIFECYCLE.md:15-17`、`38-45`、`127-129`、`152-155`：定义 Approved/Implemented 状态、合法流转、自动推进和标记 Implemented 的前置条件。
- `.github/ci/grep-guard.sh:18-20`、`122-133`：扫描 tracked/unignored Markdown 并检查本地绝对路径，但对 `.config/goal/`、`docs/governance/`、`module/` 有宽排除。
- `.github/ci/spec-governance-check.sh:57-86`：检查 SPEC/TRACEABILITY/goal 覆盖、Metadata、节编号、WHEN/Error Handling/Business Rules/AC、TRACEABILITY 列。
- `.github/ci/traceability-check.sh:207-238`：校验 Status 枚举。

## 4. 覆盖缺口明细

### 4.1 Canonical path 未落为可执行契约

`grep-guard.sh` 对 local absolute path 的排除列表包含 `.config/goal/` 与 `module/`，因此不会阻止本次发现的 stale refs。治理文档也未指定 kernel evidence workspace 的 canonical placeholder，导致不同 worker/leader 可写入不同本地路径。

最小后续 lint：新增 focused check，扫描 `module/`、`.config/goal/evidence/`、`docs/goal/`、`docs/spec/` 中的 `/home/ZoneCNH-kernel-governance-evidence`；仅允许明确标记为 historical archive 的路径说明。

### 4.2 运行态 / worktree / team state 缺少校验边界

当前 workflow 文档描述了开发流程，但没有把以下字段定义为文档/状态一致性契约：

- `$OMX_TEAM_STATE_ROOT/team/<team>/tasks/task-<id>.json`
- worker claim owner、claim token、leased_until
- worker worktree 与 leader cwd 的边界
- completion result 中的 verification/subagent evidence 字段

最小后续 lint：对 team-generated evidence package 或 task completion summary 检查 task id、worker id、status transition 与 verification block 是否存在；不要从 repo docs 反向推断 team runtime 为 gate pass。

### 4.3 ID / Status 只做局部枚举校验

`traceability-check.sh` 能防止非法 Status token，但未确认：

- Matrix 的 `Task` 是否对应真实 task spec 或 team task。
- `Done` 是否有对应 evidence package、验证命令与 leader audit。
- `SPEC.md Status: Implemented` 是否与所有 FR Done、DoD、Factory/GK evidence 同步。

最小后续 lint：新增 “promotion preflight” dry-run，只在文档计划中报告，不自动推进状态；检查 `Implemented` 候选是否具备 Matrix Done、DoD evidence、scorer/arbiter、rollback/gate validator、dirty checkout 状态等闭环证据。

### 4.4 证据晋级仍易被误读

`.config/goal/evidence/2026-06-18/TASK-KERNEL-BLK-011/EVID-KERNEL-BLK-011-EVIDENCE-PACKAGE-001.md` 已明确记录 validators 未完整运行、Factory/GK-9/GK-10 pass 未被证明。当前治理应继续区分：

1. worker 局部验证通过；
2. leader audit 收集到完整 team evidence；
3. governance scorer / arbiter / Factory / GK gate 通过。

本报告只达到第 1 类中的文档审查/验证，不声明第 2/3 类完成。

## 5. 建议的最小后续动作

1. 将 active committed docs 中 stale path 统一替换为 `$KERNEL_GOVERNANCE_EVIDENCE_ROOT` 或 repo-relative `<kernel-governance-evidence-root>`。
2. 新增 focused governance lint：扫描 active docs 的 stale kernel path、禁止未解释的 local absolute path，并对 historical archive 例外使用显式标记。
3. 在 `docs/governance/LIFECYCLE.md` 或独立 promotion protocol 中补充 evidence 晋级定义：worker verification ≠ leader audit ≠ Factory/GK pass。
4. 扩展 traceability/status 检查，至少 dry-run 报告 `Task`、`Status`、evidence package、DoD 与 promotion 状态的不一致。
5. 保持本报告为覆盖缺口证据，不纳入 Factory/GK gate pass 证明。

## 6. 审查与验证记录

- Repo search：`rg -n --hidden "/home/ZoneCNH-kernel-governance-evidence" -S . --glob '!/.git/**' --glob '!AGENTS.md'`。
- Subagent spawn evidence：1 个 read-only review probe，Carson / `019ed8a7-4b1a-72c1-9c8d-1ddf783d73c7`；已整合 stale path、CI gap、traceability/status、evidence promotion 与 team/worktree runtime 缺口。
- 本报告不声明 Factory/GK-9/GK-10 pass；不改变 active lint 或 source behavior。
