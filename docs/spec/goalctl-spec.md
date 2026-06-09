# goalctl v1 完整规格

| 字段 | 值 |
| --- | --- |
| Spec ID | `SPEC-goalctl-v1` |
| 状态 | Draft, Implementation Ready |
| 版本 | `v1.0.0` |
| 日期 | 2026-06-09 |
| 权威来源 | `docs/goal/` 与 `.config/goal/schema/rules.yaml` |
| 输出位置 | `docs/spec/goalctl-spec.md` |

## 1. 目标

`goalctl` 是 Goal 驱动交付体系的仓库内命令行控制面。它把 `docs/goal/` 中的规范、`.config/goal/` 中的配置快照、矩阵、Gate 状态和证据文件变成可校验、可追溯、可审计的本地命令。

核心目标：

1. 对 Goal 管线的状态、Gate、Registry、Matrix、Evidence 做一致性校验。
2. 输出确定性的机器可读结果，便于 CI、agent team 和人工审查复用。
3. 严格遵守权威范围：只读取规范权威，不创造新的状态模型、Gate 语义、ID 格式或追溯关系。
4. 支持从 Goal 到 Release 的全链路追溯，目标矩阵覆盖率不低于 95%，G7 阶段测试覆盖率不低于 80%。
5. 所有写入默认关闭，只有显式 `--write` 才能修改仓库内控制文件，并且必须具备原子写入与备份。

## 2. 非目标

`goalctl` 不承担以下职责：

1. 不生成业务 Goal、Spec、Design、Plan 或 Task 的实质内容。
2. 不替代 agent、reviewer、arbiter 或 CI runner。
3. 不绕过 G0-G11 任何阻塞 Gate。
4. 不把临时运行缓存视为规范权威。
5. 不直接执行生产发布、远程部署、外部账户变更或凭证操作。
6. 不引入新的 Registry 文件、新的 Gate 编号或新的管线阶段。

## 3. 权威映射

`goalctl` 必须按下表读取权威。若多个来源冲突，以 `docs/goal/00-authority-map.md` 声明的 SSOT 范围为准。

| 子系统 | 权威来源 | `goalctl` 行为 |
| --- | --- | --- |
| 权威范围 | `docs/goal/00-authority-map.md` | 校验输入是否越权，拒绝把投影文件当作规范源 |
| 主流程 | `docs/goal/03-pipeline.md` | 识别固定 11 个主阶段 |
| 四轴状态 | `docs/goal/03-pipeline.md` 与 schema rules | 校验全局状态、当前阶段、阶段状态、工作步骤相互不混用 |
| Gate | `docs/goal/04-gates.md` | 校验 G0-G11、结果值、阻塞语义与证据要求 |
| 层级产物 | `docs/goal/05-layer-standards.md` | 校验 Goal、Spec、Design、Plan、Task、Prompt、Test、Review、Release、Retro 的结构范围 |
| ID 体系 | `docs/goal/07-id-system.md` | 校验 canonical ID，读取 legacy alias，写出 canonical ID |
| 运行原则 | `docs/goal/13-runtime-engine.md` | 校验变更等级、执行模式、证据结构和失败策略 |
| Registry | `docs/goal/15-registry.md` | 只把六个 registry YAML 文件作为 registry 权威 |
| CI | `docs/goal/16-ci-cd.md` 与 schema rules | 对齐 CI job 名称、检查项和失败语义 |
| Schema | `.config/goal/schema/rules.yaml` | 作为可执行规则镜像，用于命令校验 |

## 4. 领域模型

### 4.1 对象链路

`goalctl` 必须识别以下链路关系：

```text
Goal owns Spec
Spec contains Requirement
Requirement verified_by 验收项
Requirement implemented_by Design
Design executed_by Plan
Plan decomposes_to Task
Task instructed_by Prompt
Prompt drives Code
Code changes File
Code verified_by Test
Task proven_by Evidence
Evidence supports Review
Review unlocks Release
Release triggers Retrospective
Retrospective patches Prompt, Harness, Rules
```

### 4.2 主阶段

主流程固定为：

```text
Goal -> Spec -> Design -> Plan -> Tasks -> Prompt -> Code -> Test -> Review -> Release -> Retrospective
```

Matrix 是横切追溯产物，不是主流程阶段。任何命令不得把 Matrix 输出成 `current_phase`。

### 4.3 追溯链

命令必须能解释并校验以下追溯链：

```text
Goal -> Spec -> Requirement -> 验收项 -> Task -> Prompt -> Code -> Test -> Evidence
```

链路断点必须被标记为 `Blocked`、`Drifted`、`Stale` 或 `Unmapped`，不能静默忽略。

## 5. ID 与兼容策略

### 5.1 Canonical 优先

`goalctl` 写出 ID 时必须使用 canonical 格式。读取时可以接受旧字段名或旧别名，但输出必须回到 schema rules 定义的 canonical 字段。

### 5.2 不复用

ID 永不复用。废弃对象必须保留原 ID，并通过 `replaced_by` 指向新对象。命令不得把被废弃 ID 重写为另一个对象。

### 5.3 关键 ID 模式

`goalctl` 至少校验以下模式：

| 对象 | 模式 |
| --- | --- |
| Goal | `GOAL-YYYYMMDD-NNN` |
| Spec | `SPEC-<domain>-vN` |
| Requirement | `REQ-<spec-id>-NNN` |
| Design | `DESIGN-<domain>-vN` |
| ADR | `ADR-YYYYMMDD-NNN` |
| Plan | `PLAN-<goal-id>-vN` |
| Milestone | `MILE-<plan-id>-NNN` |
| Task | `TASK-<goal-id>-NNN` |
| Prompt | `PROMPT-<task-id>-NNN` |
| Test | `TEST-<task-id>-NNN` |
| Evidence | `EVID-<test-id>-NNN` |
| Risk | `RISK-<goal-id>-NNN` |
| Decision | `DEC-YYYYMMDD-NNN` |
| Review | `REV-<task-or-pr-id>-YYYYMMDD-NNN` |
| Release | `REL-YYYYMMDD-<domain>` |
| Retrospective | `RETRO-YYYYMMDD-NNN` |

验收项的精确 ID 模式在第 19 节列出，避免前文把验收语义和其他对象混写。

## 6. 文件范围

### 6.1 规范权威

`docs/goal/` 是规范 SSOT。`goalctl` 只能读取这些文档来解释体系语义，不能向其中写入运行状态。

### 6.2 控制面配置

`.config/goal/` 是控制面配置、schema 与可审查快照目录。命令可以读取以下目录：

| 路径 | 用途 |
| --- | --- |
| `.config/goal/schema/` | 可执行规则镜像 |
| `.config/goal/registry/` | Registry 六文件 |
| `.config/goal/matrix/` | 追溯矩阵 |
| `.config/goal/gates/` | Gate 状态 |
| `.config/goal/pipeline/` | 管线状态快照 |
| `.config/goal/evidence/` | 证据文件 |
| `.config/goal/prompts/` | Prompt 版本 |
| `.config/goal/runtime/` | 本地临时运行态与恢复缓存 |

### 6.3 运行缓存

本地 agent runtime state、日志与临时缓存不是规范权威。`goalctl` 可以读取它们用于诊断，但不得把它们写入 Registry、Matrix 或 Gate 状态，除非用户显式要求生成审计快照，且命令仍需遵守 `--write`。

## 7. 四轴状态模型

### 7.1 轴定义

| 轴 | 含义 | 写入者 |
| --- | --- | --- |
| `pipeline_state` | 全局管线状态 | runner 或 Gate arbiter |
| `current_phase` | 当前主阶段 | runner 或 Gate arbiter |
| `phase_status` | 当前阶段内部状态 | 阶段 runner、reviewer、arbiter |
| `workflow_step` | SOP、runtime 或 CI 步骤 | workflow runner 或 CI |

`workflow_step` 不得覆盖 `current_phase`，`phase_status` 不得伪装成 `pipeline_state`。

### 7.2 全局状态

正常状态：

```text
INIT
CONTEXT_READY
GOAL_READY
SPEC_READY
DESIGN_READY
PLAN_READY
TASKS_READY
EXECUTING
VERIFYING
REVIEWING
RELEASING
RETROSPECTING
DONE
```

失败状态：

```text
BLOCKED
FAILED
NEEDS_RESEARCH
NEEDS_DECISION
NEEDS_REPLAN
NEEDS_ROLLBACK
NEEDS_HUMAN_APPROVAL
INCONSISTENT_STATE
```

### 7.3 当前阶段

```text
GOAL
SPEC
DESIGN
PLAN
TASKS
PROMPT
CODE
TEST
REVIEW
RELEASE
RETROSPECTIVE
```

### 7.4 阶段状态

```text
NOT_STARTED
READY
IN_PROGRESS
IN_REVIEW
DONE
BLOCKED
SKIPPED
STALE
```

### 7.5 工作步骤

```text
context_restore
goal_define
spec_write
design_write
plan_write
task_split
prompt_build
code_execute
test_run
review_run
release_prepare
retro_write
matrix_update
evidence_collect
gate_check
```

## 8. 状态输出契约

所有状态类命令必须输出以下字段：

| 字段 | 说明 |
| --- | --- |
| `current_state` | 当前 `pipeline_state` |
| `next_state` | 推荐的下一全局状态 |
| `allowed_actions` | 当前允许的动作列表 |
| `blocked_by` | 阻塞对象；无阻塞时为空数组 |
| `required_gate` | 下一步必须通过的 Gate |
| `evidence_required` | 需要补齐的证据类型 |
| `recommended_next_action` | 下一条可执行动作 |

若状态文件缺失，命令返回 `INIT` 推断结果，并在 `warnings` 中说明缺失文件。若四轴互相冲突，返回 `INCONSISTENT_STATE`。

## 9. Registry 契约

### 9.1 六个权威文件

Registry 权威仅包含：

```text
.config/goal/registry/goals.yaml
.config/goal/registry/tasks.yaml
.config/goal/registry/issues.yaml
.config/goal/registry/releases.yaml
.config/goal/registry/risks.yaml
.config/goal/registry/decisions.yaml
```

任何其他文件不得被 `goalctl registry` 视为 registry authority。

### 9.2 Goal 对象

Goal canonical 必填字段：

```text
goal_id
document_version
title
status
owner
priority
success_criteria
```

允许的 Goal 状态：

```text
Draft
Active
Paused
Achieved
Abandoned
```

### 9.3 Issue 状态

正常状态：

```text
OPEN
TRIAGED
SPEC_READY
DESIGN_READY
TASKS_READY
IN_PROGRESS
IN_REVIEW
READY_FOR_RELEASE
DONE
```

失败状态复用管线失败状态。

### 9.4 Release、Risk、Decision 状态

Release：

```text
draft
ready_for_pr
in_review
approved
released
rejected
```

Risk：

```text
Open
Mitigated
Closed
Escalated
```

Decision：

```text
Proposed
Accepted
Rejected
Superseded
```

## 10. Matrix 契约

### 10.1 必填字段

每一行 Matrix 至少包含：

```text
source_id
target_id
relation
status
evidence_id
gate_id
owner
updated_at
```

`Dropped` 行还必须包含 `drop_reason`。

### 10.2 关系枚举

```text
decomposes_to
contains
accepted_by
planned_by
implemented_by
prompted_by
verified_by
evidenced_by
```

### 10.3 状态枚举

```text
Unmapped
Mapped
Linked
Verified
Dropped
Blocked
Changed
Drifted
Stale
```

终态只有 `Verified` 和 `Dropped`。`Verified` 必须绑定 `evidence_id`，`Dropped` 必须绑定 `drop_reason`。

### 10.4 覆盖要求

`goalctl matrix coverage` 必须校验：

1. 每个 Goal 至少映射一个 Spec。
2. 每个 Spec 至少映射一个 Task。
3. 每个 Task 至少有 Prompt 或执行证据。
4. 关键 Task 必须映射到代码文件。
5. 每个验收项必须映射测试。
6. 不允许无 Goal 的 Task。
7. 不允许关键需求无测试。
8. 发布前 Matrix 行必须全部为 `Verified` 或 `Dropped`，且覆盖率不低于 95%。

## 11. Gate 契约

### 11.1 Gate 文件

Gate 状态文件为：

```text
.config/goal/gates/state.yaml
```

### 11.2 Gate 结果

允许结果：

```text
PASS
PASS_WITH_RISK
FAIL
BLOCKED
```

`WAIVED` 不是允许值。遇到 waiver 语义时，命令必须按风险情况映射到 `PASS_WITH_RISK` 或 `BLOCKED`。

### 11.3 Gate 定义结构

每个 Gate 定义至少包含：

```text
gate_id
name
type
blocking
scope
inputs
checks
pass_criteria
fail_criteria
outputs
owner
```

### 11.4 G0-G11

| Gate | 名称 | 阻塞 | 核心检查 |
| --- | --- | --- | --- |
| G0 | Context Gate | 是 | 上下文恢复、环境一致、执行模式已定 |
| G1 | Goal Gate | 是 | SMART、用户、结果、指标、验收项、范围、非目标、约束 |
| G2 | Spec Gate | 是 | 语义完整、可测试、正常路径、失败路径、范围约束、安全、性能、非目标 |
| G3 | Design Gate | 是 | 模块映射、范围约束、可测试调用契约、无循环依赖、ADR |
| G4 | Plan Gate | 是 | 依赖顺序、高风险、检查点、回滚、解阻、增量计划 |
| G5 | Task Gate | 是 | 原子任务、输入输出、完成定义、依赖、独立验证、Matrix 覆盖 |
| G6 | Implementation Gate | 是 | Prompt 包含上下文、约束、输出、验收项、测试、禁止项；实现未越界 |
| G7 | Test Gate | 是 | 测试全部通过，覆盖率不低于 80% |
| G8 | Evidence Gate | 是 | 证据齐备，每个验收项有证据 |
| G9 | Review Gate | 是 | 符合 Task、Spec、Matrix、测试、错误、安全、性能，无无关功能 |
| G10 | Release Gate | 是 | Matrix 终态、P0/P1 测试、无权限绕过、无数据破坏、日志监控、灰度与回滚 |
| G11 | Retrospective Gate | 否 | 决策、问题、改进项与规则补丁已记录 |

## 12. Evidence 契约

Evidence 文件必须包含：

```text
Evidence ID
验收项 ID
Test ID
Task ID
Spec ID
Goal ID
Date
Status
Files Changed
Commands Run
Results
Logs
Diff Summary
Requirement Proof
Known Limitations
Risks
Rollback
```

允许状态：

```text
PASS
PARTIAL
FAIL
```

命令不得接受缺少命令输出、测试结果、文件列表或风险说明的完成声明。

## 13. 命令规格

### 13.1 全局语法

```text
goalctl [global-options] <command> [command-options]
```

全局选项：

| 选项 | 默认值 | 说明 |
| --- | --- | --- |
| `--root <path>` | 当前仓库 | 仓库根目录 |
| `--config <path>` | `.config/goal` | Goal 控制目录 |
| `--format <text|json|yaml>` | `text` | 输出格式 |
| `--strict` | false | 启用阻塞级校验 |
| `--audit` | false | 输出非阻塞风险 |
| `--write` | false | 允许写入 |
| `--dry-run` | true | 预演写入 |
| `--no-color` | false | 关闭颜色 |
| `--trace <id>` | empty | 输出某个对象的追溯链 |

### 13.2 `goalctl status`

用途：读取四轴状态并输出下一步建议。

```text
goalctl status [--format json] [--strict]
```

行为：

1. 读取 pipeline state、Gate state、Matrix summary。
2. 校验四轴是否互相冲突。
3. 输出第 8 节要求的状态字段。
4. 若 Gate 阻塞，`recommended_next_action` 必须指向最小修复动作。

### 13.3 `goalctl validate`

用途：运行核心校验。

```text
goalctl validate [--strict] [--audit] [--format json]
```

检查项：

1. schema 读取成功。
2. Registry 六文件存在且字段合法。
3. ID 格式合法。
4. Matrix 覆盖合法。
5. Gate 状态合法。
6. Evidence 结构合法。
7. Pipeline 四轴合法。
8. 权威范围未被违反。

### 13.4 `goalctl registry`

子命令：

```text
goalctl registry validate
goalctl registry list <goals|tasks|issues|releases|risks|decisions>
goalctl registry show <id>
goalctl registry orphans
```

行为：

1. 只读取第 9.1 节六个文件。
2. `show` 必须合并 legacy alias 后输出 canonical 字段。
3. `orphans` 输出无上游 Goal 或无 Matrix 关系的对象。

### 13.5 `goalctl matrix`

子命令：

```text
goalctl matrix check
goalctl matrix coverage
goalctl matrix trace <id>
goalctl matrix render [--format markdown|json]
```

行为：

1. `check` 校验字段、关系、状态、终态要求。
2. `coverage` 输出总覆盖率、关键链路覆盖率和阻塞行。
3. `trace` 从任意对象 ID 展开上下游链路。
4. `render` 生成审查报告；无 `--write` 时只输出到 stdout。

### 13.6 `goalctl gate`

子命令：

```text
goalctl gate check <G0..G11|all>
goalctl gate explain <G0..G11>
goalctl gate report [--format json]
```

行为：

1. `check` 读取 gate state、Matrix 和 Evidence，返回 PASS、PASS_WITH_RISK、FAIL 或 BLOCKED。
2. `explain` 输出 Gate 目的、输入、检查项、失败条件和下一动作。
3. `report` 输出所有 Gate 的结果、阻塞原因、证据缺口。

### 13.7 `goalctl pipeline`

子命令：

```text
goalctl pipeline status
goalctl pipeline next
goalctl pipeline transition <state> [--write]
```

行为：

1. `status` 等价于聚焦 pipeline 的 `goalctl status`。
2. `next` 输出可执行的下一状态，不写文件。
3. `transition` 默认 dry run；只有 `--write` 且 Gate 允许时才更新 pipeline state。
4. 写入时必须保留原文件备份并进行原子替换。

### 13.8 `goalctl evidence`

子命令：

```text
goalctl evidence check
goalctl evidence collect --task <task-id> --test <test-id> [--write]
goalctl evidence report <id>
```

行为：

1. `check` 校验必填字段、状态值、文件路径、命令记录与 Matrix 绑定。
2. `collect` 默认输出草案；只有 `--write` 才创建 evidence 文件。
3. `report` 输出证据支持的 Goal、Spec、Task、Test、Gate。

### 13.9 `goalctl report`

子命令：

```text
goalctl report trace <id>
goalctl report release-readiness
goalctl report acceptance
```

行为：

1. `trace` 输出对象链路和断点。
2. `release-readiness` 聚合 G7-G10、Matrix 终态和证据状态。
3. `acceptance` 输出每个验收项的测试和证据绑定情况。

### 13.10 `goalctl doctor`

用途：诊断配置、schema、路径、权限和投影漂移。

```text
goalctl doctor [--audit] [--format json]
```

`doctor` 不得写文件，除非未来版本增加显式修复命令并要求 `--write`。

### 13.11 `goalctl schema`

子命令：

```text
goalctl schema inspect
goalctl schema diff
```

行为：

1. `inspect` 输出 schema rules 中的枚举、必填字段和阈值。
2. `diff` 对比 schema rules 与文档权威；发现漂移时返回非零退出码。

### 13.12 `goalctl version`

输出命令版本、schema 版本、规则摘要 hash、仓库根路径和构建信息。

## 14. 输出格式

### 14.1 JSON envelope

JSON 输出必须使用统一 envelope：

```json
{
  "command": "goalctl validate",
  "status": "pass",
  "exit_code": 0,
  "root": "<repo-root>",
  "summary": {
    "checked": 0,
    "passed": 0,
    "failed": 0,
    "warnings": 0
  },
  "results": [],
  "warnings": [],
  "errors": [],
  "next_actions": []
}
```

### 14.2 文本输出

文本输出必须包含：

1. 当前结论。
2. 阻塞项。
3. 证据缺口。
4. 下一动作。

文本输出不得隐藏 JSON 中存在的错误。

## 15. 退出码与错误码

### 15.1 退出码

| 退出码 | 含义 |
| --- | --- |
| 0 | 通过 |
| 1 | 校验失败 |
| 2 | 使用方式错误 |
| 3 | 文件或路径缺失 |
| 4 | schema 不合法 |
| 5 | 权威范围违规 |
| 6 | Gate 阻塞 |
| 7 | Matrix 覆盖不足 |
| 8 | Evidence 不足 |
| 9 | 状态不一致 |
| 10 | 写入失败 |

### 15.2 错误码

| 错误码 | 含义 |
| --- | --- |
| `GOALCTL_SCHEMA_MISSING` | schema rules 缺失 |
| `GOALCTL_SCHEMA_INVALID` | schema rules 无法解析 |
| `GOALCTL_AUTHORITY_VIOLATION` | 读取或写入越过权威范围 |
| `GOALCTL_REGISTRY_MISSING` | Registry 六文件之一缺失 |
| `GOALCTL_REGISTRY_INVALID` | Registry 字段或状态非法 |
| `GOALCTL_ID_INVALID` | ID 格式非法 |
| `GOALCTL_STATE_INCONSISTENT` | 四轴状态冲突 |
| `GOALCTL_GATE_BLOCKED` | Gate 阻塞 |
| `GOALCTL_GATE_INVALID_RESULT` | Gate 结果值非法 |
| `GOALCTL_MATRIX_UNMAPPED` | Matrix 存在未映射关键链路 |
| `GOALCTL_MATRIX_COVERAGE_LOW` | Matrix 覆盖低于 95% |
| `GOALCTL_EVIDENCE_MISSING` | Evidence 缺失 |
| `GOALCTL_EVIDENCE_INVALID` | Evidence 字段或状态非法 |
| `GOALCTL_WRITE_REQUIRES_FLAG` | 写入缺少 `--write` |
| `GOALCTL_WRITE_FAILED` | 写入失败 |

## 16. 写入语义

`goalctl` 默认只读。任何写入必须满足：

1. 用户显式传入 `--write`。
2. dry run 结果已能完整展示将要修改的文件和字段。
3. 目标文件属于 `.config/goal/` 中允许写入的控制面目录。
4. 写入前创建同目录备份。
5. 写入采用临时文件加原子替换。
6. 写入后重新运行对应校验。
7. 写入失败时恢复原文件并返回 `GOALCTL_WRITE_FAILED`。

禁止写入：

1. 规范权威文档，除非该命令未来被明确设计为文档生成器。
2. Git metadata。
3. 凭证、密钥、账户文件。
4. 远程系统。

## 17. 变更等级与执行模式

`goalctl` 必须支持 CL0-CL5 变更等级识别：

| 等级 | 含义 | 推荐模式 |
| --- | --- | --- |
| CL0 | 文案、注释、无行为变化 | Lite |
| CL1 | 小型配置或低风险修复 | Lite |
| CL2 | 单模块行为变化 | Standard |
| CL3 | 跨模块行为变化 | Full |
| CL4 | 高风险、权限、数据或发布相关 | Full |
| CL5 | 架构、治理或递归规则变化 | Full |

模式映射：

| 模式 | 适用等级 | 要求 |
| --- | --- | --- |
| Lite | CL0/CL1 | 最小 Gate 与证据 |
| Standard | CL2 | 标准 Gate、Matrix、测试和 Evidence |
| Full | CL3-CL5 | 全链路 Gate、审查、发布和回顾 |

CL4 和 CL5 默认需要人工批准；命令不得自动放行。

## 18. 范围约束与失败处理

`goalctl` 必须处理以下范围约束与失败路径：

1. schema 文件不存在或无法解析。
2. Registry 六文件缺失、重复 ID 或状态非法。
3. Matrix 行缺少字段、关系非法、终态无证据或无 drop reason。
4. Gate state 包含未知 Gate、未知结果、waiver 值或缺失阻塞信息。
5. Pipeline 四轴互相冲突。
6. Evidence 文件缺失日志、测试结果、文件列表或风险说明。
7. ID 使用 legacy alias，命令读取后需标准化输出。
8. 变更等级与执行模式不匹配。
9. Release 前 Matrix 未达终态。
10. CI 只运行了部分检查。
11. 路径越过仓库根目录。
12. 写入过程中发生并发修改。
13. 非 UTF-8 文件或 YAML 解析失败。
14. 用户请求写入规范权威文档。

错误输出必须包含 `errors`、`blocked_by` 或 `next_actions` 中至少一个可行动字段。

## 19. Requirements and Acceptance Criteria / 验收标准

### 19.1 需求列表

| Requirement ID | 需求 | Acceptance Criteria ID | 验收项 |
| --- | --- | --- | --- |
| `REQ-SPEC-goalctl-v1-001` | `goalctl` 必须从 `docs/goal/` 与 schema rules 读取权威语义。 | `AC-REQ-SPEC-goalctl-v1-001-001` | 给定任意命令，输出必须声明使用的 authority source；当输入与 authority map 冲突时返回 `GOALCTL_AUTHORITY_VIOLATION`。 |
| `REQ-SPEC-goalctl-v1-002` | `goalctl` 必须保持 Matrix 为横切产物。 | `AC-REQ-SPEC-goalctl-v1-002-001` | `goalctl status` 和 `goalctl pipeline status` 不得把 Matrix 输出为 `current_phase`。 |
| `REQ-SPEC-goalctl-v1-003` | `goalctl` 必须校验四轴状态。 | `AC-REQ-SPEC-goalctl-v1-003-001` | 当 `pipeline_state`、`current_phase`、`phase_status`、`workflow_step` 冲突时，命令返回 `INCONSISTENT_STATE` 与退出码 9。 |
| `REQ-SPEC-goalctl-v1-004` | `goalctl` 必须支持固定主流程。 | `AC-REQ-SPEC-goalctl-v1-004-001` | 任意阶段命令只接受 11 个 canonical phase，未知 phase 必须失败。 |
| `REQ-SPEC-goalctl-v1-005` | `goalctl` 必须校验 canonical ID。 | `AC-REQ-SPEC-goalctl-v1-005-001` | `goalctl validate --strict` 对所有 ID 执行 schema regex 校验，并拒绝重复 ID。 |
| `REQ-SPEC-goalctl-v1-006` | 验收项 ID 必须使用 `AC-<req-id>-NNN` 格式。 | `AC-REQ-SPEC-goalctl-v1-006-001` | 任意不符合该格式的验收项引用必须返回 `GOALCTL_ID_INVALID`。 |
| `REQ-SPEC-goalctl-v1-007` | `goalctl` 必须只把六个 YAML 文件视为 Registry 权威。 | `AC-REQ-SPEC-goalctl-v1-007-001` | `goalctl registry validate` 不得读取六文件之外的 registry authority。 |
| `REQ-SPEC-goalctl-v1-008` | `goalctl` 必须校验 Goal canonical 必填字段。 | `AC-REQ-SPEC-goalctl-v1-008-001` | 缺少 `goal_id`、`document_version`、`title`、`status`、`owner`、`priority`、`success_criteria` 中任一字段时严格模式失败。 |
| `REQ-SPEC-goalctl-v1-009` | `goalctl` 必须校验 Matrix 必填字段、关系、状态和终态条件。 | `AC-REQ-SPEC-goalctl-v1-009-001` | `Verified` 行无 `evidence_id` 或 `Dropped` 行无 `drop_reason` 时返回退出码 7。 |
| `REQ-SPEC-goalctl-v1-010` | Matrix 覆盖率门槛必须不低于 95%。 | `AC-REQ-SPEC-goalctl-v1-010-001` | 覆盖率低于 95% 时 `goalctl matrix coverage --strict` 返回 `GOALCTL_MATRIX_COVERAGE_LOW`。 |
| `REQ-SPEC-goalctl-v1-011` | `goalctl` 必须校验 G0-G11 与 Gate 结果值。 | `AC-REQ-SPEC-goalctl-v1-011-001` | 未知 Gate、未知结果或 `WAIVED` 值必须失败，waiver 语义只能映射为 `PASS_WITH_RISK` 或 `BLOCKED`。 |
| `REQ-SPEC-goalctl-v1-012` | `goalctl` 必须校验 Evidence 必填字段。 | `AC-REQ-SPEC-goalctl-v1-012-001` | 缺少 Evidence ID、Acceptance Criteria ID、Test ID、Task ID、Spec ID、Goal ID、Date、Status、Files Changed、Commands Run 任一字段时严格模式失败。 |
| `REQ-SPEC-goalctl-v1-013` | `goalctl` 必须拒绝无证据的完成声明。 | `AC-REQ-SPEC-goalctl-v1-013-001` | 没有日志、测试结果、文件列表或风险说明时，Evidence 不能被判定为 PASS。 |
| `REQ-SPEC-goalctl-v1-014` | `goalctl` 必须提供统一 JSON envelope。 | `AC-REQ-SPEC-goalctl-v1-014-001` | 所有 `--format json` 输出都包含 `command`、`status`、`exit_code`、`summary`、`results`、`warnings`、`errors`、`next_actions`。 |
| `REQ-SPEC-goalctl-v1-015` | `goalctl` 必须默认只读。 | `AC-REQ-SPEC-goalctl-v1-015-001` | 任何写入命令缺少 `--write` 时返回 `GOALCTL_WRITE_REQUIRES_FLAG`，且不得修改文件。 |
| `REQ-SPEC-goalctl-v1-016` | `goalctl` 写入必须具备恢复能力。 | `AC-REQ-SPEC-goalctl-v1-016-001` | 写入前创建备份，写入后重新校验，失败时恢复原文件并返回 `GOALCTL_WRITE_FAILED`。 |
| `REQ-SPEC-goalctl-v1-017` | `goalctl` 必须识别 CL0-CL5 与 Lite、Standard、Full 模式。 | `AC-REQ-SPEC-goalctl-v1-017-001` | CL4 或 CL5 不得自动放行，必须输出人工批准需求。 |
| `REQ-SPEC-goalctl-v1-018` | `goalctl` 必须输出可行动的阻塞信息。 | `AC-REQ-SPEC-goalctl-v1-018-001` | 任意失败输出必须至少包含错误、阻塞对象或下一动作。 |
| `REQ-SPEC-goalctl-v1-019` | `goalctl` 必须和 CI 检查项对齐。 | `AC-REQ-SPEC-goalctl-v1-019-001` | `goalctl validate --strict` 至少覆盖 yaml-lint、registry-check、rule-drift-check、goal-validator、id-format-check、matrix-coverage、gate-check、orphan-check、agent-check、docs-check 的本地等价检查。 |
| `REQ-SPEC-goalctl-v1-020` | `goalctl` 必须提供 release readiness 报告。 | `AC-REQ-SPEC-goalctl-v1-020-001` | 报告必须聚合 G7-G10、Matrix 终态、Evidence 状态、阻塞风险和回滚字段。 |

### 19.2 通过条件

本规格可进入实现的条件：

1. 需求数量不少于 20 条。
2. 每条 Requirement 至少有一个 Acceptance Criteria。
3. 所有 Acceptance Criteria 都能映射到命令、校验或输出字段。
4. 规格没有定义 docs/goal 之外的新权威。
5. 规格没有要求写入临时 runtime state 作为规范权威。
6. `docs/goal/` 不因本规格整理而被修改。

## 20. 实现顺序

建议按以下顺序实现：

1. 规则读取：加载 schema rules、authority map 和控制目录。
2. 基础类型：ID、状态枚举、Gate 结果、Matrix 行、Evidence 文档。
3. 只读命令：`version`、`schema inspect`、`status`。
4. 校验命令：`validate`、`registry validate`、`matrix check`、`gate check`、`evidence check`。
5. 报告命令：`matrix trace`、`report trace`、`report release-readiness`。
6. 受控写入：`pipeline transition --write`、`evidence collect --write`。
7. CI 集成：把本地校验命令映射到 required jobs。
8. 回归测试：覆盖正常路径、范围约束、失败路径、写入恢复和 JSON envelope。

## 21. 验证命令

本规格整理完成后至少运行：

```text
bash docs/goal/tools/lint-goal.sh docs/spec/goalctl-spec.md
python3 docs/goal/tools/goal-validate.py --root . --mode audit --format text
python3 docs/goal/tools/goal-validate.py --root . --mode strict --format text
python3 docs/goal/tools/matrix-gen.py --check-only --matrix .config/goal/matrix/matrix.yaml
bash docs/goal/tools/gate-check.sh .
python3 docs/goal/tools/rule-drift-check.py --root .
git diff --check
```

若某项命令返回非零，执行者必须记录失败原因、阻断等级和下一步修复入口。

本规格的范围约束、失败路径、写入恢复和输出 envelope 构成 edge.case 与 error.handling 覆盖。
