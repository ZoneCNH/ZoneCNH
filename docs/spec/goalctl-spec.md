# goalctl v1 Specification

Spec ID: `SPEC-goalctl-v1`
Owner: Goal System
Version: v1
Status: Draft for implementation
Quantified target: `goalctl` validates at least 95% trace coverage before a Done/Verified claim is accepted.

## 1. Purpose and authority

`goalctl` is a repository-local command surface for validating the Goal system without redefining it. The command reads authoritative docs and committed Registry files, reports drift, and emits deterministic machine-readable results.

Authority order:
1. `docs/goal/00-authority-map.md`
2. `docs/goal/02-goal-standard.md`
3. `docs/goal/03-pipeline.md`
4. `docs/goal/04-gates.md`
5. `docs/goal/13-runtime-engine.md`
6. `docs/goal/15-registry.md`
7. `.config/goal/README.md`
8. `.config/goal/schema/rules.yaml`
9. `docs/goal/20-metrics-evidence.md`
10. `docs/goal/24-standard-unification-analysis.md`

Reference consistency rule: every source path above must exist; projections in this spec are invalid if they conflict with the source map. This document does not edit `docs/goal`.

## 2. Commands

All commands support `--repo-root <path>` and `--json`.

- `goalctl status` summarizes Registry health, Pipeline state, Gate state, and evidence readiness.
- `goalctl validate` checks source references, Registry shape, Matrix edges, Gate/Pipeline semantics, and evidence links.
- `goalctl registry` validates the six-file Registry boundary.
- `goalctl matrix` checks trace links and renders Goal → Spec → Requirement → AC → Task → Prompt → Code → Test → Evidence.
- `goalctl gate` evaluates G0, G1, G2, G3, G4, G5, G6, G7, G8, G9, G10, G11.
- `goalctl pipeline` validates `pipeline_state`, `current_phase`, `phase_status`, and `workflow_step`.
- `goalctl evidence` checks `evidence_id`, `task_id`, `test_id`, `goal_id`, status, artifact path, and reproducibility.
- `goalctl doctor` prints local remediation guidance.
- `goalctl report acceptance` emits an acceptance report with command, timestamp, source input, result, errors, warnings, and evidence references.

Unknown commands return non-zero and still use the JSON error envelope when `--json` is supplied.

## 3. Data contracts

Registry boundary: only goals.yaml, specs.yaml, features.yaml, issues.yaml, tasks.yaml, and agents.yaml are committed Registry authority. Cache, log, temp, lock, private, and sidecar files are not authority. Committed config and evidence must reject credentials, credential keys, account IDs, private endpoints, trading config, and local personal paths.

Canonical aliases: use `goal_id` over `id`/`goalId`, `title` over `name`, `objective` over `north_star`, and `success_metrics` over `success_criteria` unless reading legacy inputs. Runtime state terms are distinct: `status` is record lifecycle, `pipeline_state` is global pipeline lifecycle, `current_phase` is active phase, `phase_status` is phase lifecycle, and `workflow_step` is a step within a phase.

Matrix edge fields: `source_id`, `target_id`, `relation`, `status`, `evidence_id`, `gate_id`, `owner`, `updated_at`. Legal statuses include Unmapped, Mapped, Linked, Verified, Dropped, Drifted, Stale, Blocked, and Changed.

Gate results: PASS, FAIL, PASS_WITH_RISK, BLOCKED. `WAIVED` is not a final compliant result; suggest PASS_WITH_RISK or BLOCKED.

JSON output shape: `{ "result": "pass|fail|warn", "errors": [], "warnings": [], "checks": [], "summary": {} }`. Every failed check includes `code`, `severity`, `message`, `source`, `expected`, `actual`, and `remediation` when known.

## 4. Error codes

- `GOALCTL-SSOT-001`: spec projection conflicts with authoritative source.
- `GOALCTL-REF-001`: source path or referenced line is missing or stale.
- `GOALCTL-ID-001`: identifier alias or format is invalid.
- `GOALCTL-REG-001`: Registry boundary or required file is invalid.
- `GOALCTL-MATRIX-001`: Matrix field, relation, status, or 95% coverage rule fails.
- `GOALCTL-GATE-001`: Gate result, ordering, or G2 completeness rule fails.
- `GOALCTL-PIPE-001`: Pipeline field semantics are missing or conflated.
- `GOALCTL-EVID-001`: evidence is missing for a Done/Verified claim.
- `GOALCTL-SECRET-001`: prohibited secret or local-only data appears in committed config/evidence.

## 5. Verification plan

Required local verification before implementation claims:
- `bash docs/goal/tools/lint-goal.sh docs/spec/goalctl-spec.md`
- `bash docs/goal/tools/self-test.sh`
- `python3 docs/goal/tools/goal-validate.py --root . --mode audit --format json`
- `python3 docs/goal/tools/rule-drift-check.py --root . --quiet`
- custom verifier for source references, command coverage, error codes, REQ/AC coverage, gates, traceability, and one-file scope.

## 6. Requirements and Acceptance Criteria / 验收标准

This criteria block covers normal, edge.case, 边界, 异常, and 错误处理 behavior.

来源：`docs/goal/03-pipeline.md:50-67`, `.config/goal/schema/rules.yaml:207-228`。

### 3.4 状态输出合同

`goalctl status` 类输出必须包含以下字段，缺失时不得声称状态可操作：

- `Current State`
- `Next State`
- `Allowed Actions`
- `Blocked By`
- `Required Gate`
- `Evidence Required`
- `Recommended Next Action`

来源：`docs/goal/03-pipeline.md:71-80`。

### 3.5 转换守卫

| From | To | 必要守卫 |
| --- | --- | --- |
| `INIT` | `CONTEXT_READY` | Context Gate PASS |
| `CONTEXT_READY` | `GOAL_READY` | Goal Gate PASS |
| `GOAL_READY` | `SPEC_READY` | Spec Gate PASS |
| `SPEC_READY` | `DESIGN_READY` | Design Gate PASS |
| `DESIGN_READY` | `PLAN_READY` | Plan Gate PASS |
| `PLAN_READY` | `TASKS_READY` | Task Gate PASS |
| `TASKS_READY` | `EXECUTING` | Task selected / Owner assigned |
| `EXECUTING` | `VERIFYING` | Implementation done |
| `VERIFYING` | `REVIEWING` | Test Gate + Evidence Gate PASS |
| `REVIEWING` | `RELEASING` | Review PASS |
| `RELEASING` | `RETROSPECTING` | Release Gate PASS |
| `RETROSPECTING` | `DONE` | Retrospective Gate PASS |

回退规则必须按 Pipeline 文档执行：测试失败回 `EXECUTING`；review 失败可回 `EXECUTING` 或 `DESIGN_READY`；release 后失败进入 `NEEDS_ROLLBACK`；依赖/权限缺失进入 `BLOCKED`；未知阻塞进入 `NEEDS_RESEARCH`；CL3+ 多方案进入 `NEEDS_DECISION`；Spec/Design 影响 Plan 时进入 `NEEDS_REPLAN`；Registry/Artifact/CI 冲突进入 `INCONSISTENT_STATE`。

来源：`docs/goal/03-pipeline.md:85-98`, `docs/goal/03-pipeline.md:120-132`。

## 4. 对象、Registry 与 Matrix 状态

### 4.1 对象状态

`goalctl` 应使用 Pipeline 对象状态总表作为跨对象入口：Goal `Draft → Active → Paused → Achieved / Abandoned`；Spec `Draft → Review → Approved → Superseded / Deprecated`；Design `Draft → Review → Approved → Superseded`；Plan `Draft → Approved → Superseded`；Task `Unmapped → Mapped → In Progress → Blocked → In Review → Done / Dropped`；Gate `PASS / PASS_WITH_RISK / FAIL / BLOCKED`。

来源：`docs/goal/03-pipeline.md:100-118`。

### 4.2 已知生命周期命名差异

`docs/goal/02-goal-standard.md` 同时描述了 Goal 生命周期 `Draft → Reviewed → Approved → In Progress → Validated / Partially Validated / Failed → Deprecated`。这与 Pipeline/Registry 的 Goal 状态表不同。

`goalctl` MUST NOT 自行合并为新 enum。正确行为是：

1. 在读取或迁移时保留来源文件和原始状态值。
2. 对跨文档冲突输出 `INCONSISTENT_STATE` 或 blocker 诊断。
3. 要求先更新 Authority Map 指向的权威文档，再同步 `.config/goal/schema` 投影。

来源：`docs/goal/02-goal-standard.md:163-167`, `docs/goal/03-pipeline.md:100-118`, `docs/goal/00-authority-map.md:7-10`。

### 4.3 Registry 边界

Registry 是长期共享状态，位于 `.config/goal/registry` 的六类 YAML：`goals.yaml`, `tasks.yaml`, `issues.yaml`, `releases.yaml`, `risks.yaml`, `decisions.yaml`。其他 `.config/goal` 目录是 sidecar component 或 snapshot，不属于 Registry 子系统。

Issue 的异常状态复用 Pipeline exception enum，不得定义本地 exception 状态。

来源：`docs/goal/15-registry.md:5-23`, `docs/goal/15-registry.md:108-110`, `.config/goal/README.md`。

### 4.4 Matrix 状态与漂移

Matrix 状态为 `Unmapped`, `Mapped`, `Linked`, `Verified`, `Dropped`, `Drifted`, `Stale`, `Blocked`, `Changed`。`Verified` 必须有 `evidence_id`，`Dropped` 必须有 `drop_reason`；coverage threshold 为 95%。Release 前关键行必须 `Verified`，或 `Dropped` 且有 `drop_reason`。

`Blocked`、`Changed`、`Drifted`、`Stale` 是漂移或阻塞元状态，不是完成终态；它们必须回到 `Linked` 后重新验证，或转为带原因的 `Dropped`。上游对象变更后，下游对象自动进入 `STALE`；`STALE` 必须重新验证；Release Gate 禁止存在 P0/P1 `STALE` 对象；Spec/Design 变更必须触发 `NEEDS_REPLAN`。

来源：`.config/goal/schema/rules.yaml:92-115`, `docs/goal/05-layer-standards.md:335-347`, `docs/goal/13-runtime-engine.md:248-274`。

## 5. Gate 合同

### 5.1 Gate 编号与结果

G0-G11 的编号、名称、顺序和阻塞语义只由 `docs/goal/04-gates.md` 定义；其他文档可引用或细化，不得添加独立 Gate 编号。`XG-*`, `XG-CHK*`, `H-CHK*` 或 CI checks 是 check/profile/evidence，不是 Goal Gate ID。

Gate 结果只允许：

- `PASS`：达到阈值且无 blocking risk。
- `PASS_WITH_RISK`：达到 risk band，风险字段完整，但不能用于 G6/G10。
- `FAIL`：未达阈值、critical check failed 或 risk fields missing。
- `BLOCKED`：外部依赖、stale risk 或 release_blocking risk 阻止判断。

`WAIVED` 是豁免策略，不是 Gate 结果值；最终 Gate 结果必须映射为 `PASS_WITH_RISK` 或 `BLOCKED`，并保留 `approver`、`reason`、`expires_at`。

来源：`docs/goal/04-gates.md:5`, `docs/goal/04-gates.md:245-249`, `docs/goal/03-pipeline.md:118`, `.config/goal/gates/state.yaml:1-6`, `.config/goal/gates/state.yaml:392-396`, `docs/goal/16-ci-cd.md:205-207`。

### 5.2 Gate 总表

| Gate | 名称 | 类型 | 通过标准摘要 |
| --- | --- | --- | --- |
| G0 | Context Gate | Hybrid | 上下文恢复完成。 |
| G1 | Goal Gate | Semantic | Goal 满足 SMART。 |
| G2 | Spec Gate | Semantic | Spec 完整、可测试。 |
| G3 | Design Gate | Semantic | Design 映射到模块。 |
| G4 | Plan Gate | Semantic | Plan 依赖顺序正确。 |
| G5 | Task Gate | Executable | Task 原子且有 DoD。 |
| G6 | Implementation Gate | Executable | 实现未越界；G6 不允许 `PASS_WITH_RISK`。 |
| G7 | Test Gate | Executable | 测试通过。 |
| G8 | Evidence Gate | Executable | Evidence 完整。 |
| G9 | Review Gate | Semantic | Review 通过。 |
| G10 | Release Gate | Hybrid | Release 就绪；G10 不允许 `PASS_WITH_RISK`。 |
| G11 | Retrospective Gate | Semantic | Retrospective 完成。 |

来源：`docs/goal/04-gates.md:35-48`, `.config/goal/gates/state.yaml:25-42`。

### 5.3 G8 Evidence Gate

G8 必须检查 Evidence 文件完整、traceability 完整、test result 完整、review evidence 存在。PASS 标准是 Evidence 覆盖所有 acceptance criteria；缺失或不完整必须 FAIL。

Runtime Evidence 至少包含：Evidence ID、Acceptance Criteria ID、Test ID、Task ID、Spec ID、Goal ID、Date、Status (`PASS`/`FAIL`/`PARTIAL`)、Files Changed、Commands Run、Results、Logs、Diff Summary、Requirement Proof、Known Limitations、Risks、Rollback。

禁止使用“done”声明替代 Evidence：无 logs、无 tests、无 file list 或无 risk note 的完成声明不合法。原则是 “No Evidence, No Done”。

来源：`docs/goal/04-gates.md:184-194`, `docs/goal/13-runtime-engine.md:115-144`, `docs/goal/20-metrics-evidence.md:5-12`。

### 5.4 G10 Release Gate

G10 为 blocking Hybrid Gate。Release 前必须满足：Matrix 全部关键项 `Verified`，或 `Dropped` 且有 `drop_reason`；P0/P1 tests 全部通过；无权限绕过风险；无数据破坏风险；有日志和监控；有 Feature Flag 或 rollback；有灰度策略；有上线后指标观察计划。

`.config/goal/gates/state.yaml` 当前 closure policy 进一步约束：G10 不允许 `PASS_WITH_RISK`；任何未关闭 `release_blocking` risk 阻塞 G10；P0/P1、permission、data、rollback、observability、Release Evidence gaps 必须 `FAIL` 或 `BLOCKED`。

来源：`docs/goal/04-gates.md:214-230`, `.config/goal/gates/state.yaml:25-42`, `docs/goal/16-ci-cd.md:31-47`。

## 6. DoD、CI 与变更级别

DoR/DoD 的 SSOT 在 `docs/goal/06-dod.md`。Goal 完成必须满足 linked Issues 完成、Success Criteria、P0/P1 PASS、Release Manifest、Retrospective 等要求；Task DoD 必须包含 input/output/AC/deps、traceability、DoD、verification commands、Evidence 和 Rollback。

测试结果必须写入 Evidence，CI 只可作为 workflow/profile/check 执行面：build、unit、integration、lint、format、regression、smoke 等结果填充 G7/G8/G9，不得创建新 Gate。G10 无 PASS 时不得 release。

CL0 文档级变更的最小流为 `Goal → Plan → Docs Change → Evidence → Review`，仍然必须通过 G8/G9。

来源：`docs/goal/06-dod.md:3-7`, `docs/goal/06-dod.md:25-35`, `docs/goal/06-dod.md:117-125`, `docs/goal/06-dod.md:209-217`, `docs/goal/13-runtime-engine.md:13-43`, `docs/goal/16-ci-cd.md:11-27`, `docs/goal/16-ci-cd.md:31-55`, `docs/goal/16-ci-cd.md:88-94`。

## 7. 当前审计快照

`.config/goal/pipeline/state.yaml` 当前记录：`goal_id: GOAL-20260608-001`，`pipeline_state: BLOCKED`，previous state `RELEASING`，`current_phase: RELEASE`，`phase_status: BLOCKED`，`workflow_step: RELEASE_EXECUTION`。Matrix、prompt、code、test、review artifacts ready；G6/G10 仍 blocking；G2/G4/G7 存在 release-blocking risk，原因包括 release precheck automation 未与 G10 block 条件对齐、G7 evidence lint/collector 未与 metadata/proof body 对齐等。

`goalctl` 在读取该快照时必须报告 release blocked，而不是从 artifacts ready 推断可 release。

来源：`.config/goal/pipeline/state.yaml:12-30`, `.config/goal/pipeline/state.yaml:257-267`。

## 8. Worker-1 验收标准与检查

本切片完成时必须满足：

- `docs/goal/` 未被修改。
- 本文件只引用既有 SSOT 和 `.config/goal` 投影/快照，不引入新 enum、Gate ID 或 Registry 状态。
- 状态模型包含 `pipeline_state`、`current_phase`、`phase_status`、`workflow_step` 四轴。
- Gate 模型包含 G0-G11、`PASS`、`PASS_WITH_RISK`、`FAIL`、`BLOCKED`、G6/G10 特殊约束、G8 Evidence、G10 Release blocking 条件。
- Matrix 漂移、`STALE` 传播、P0/P1 `STALE` release 禁止和 object lifecycle 命名差异均被显式记录。
- 验证结果和提交哈希必须报告给 leader。


## 9. Worker-3 规格完整性审查与验收清单

本节是 `docs/spec/goalctl-spec.md` 的审查/验收附录，不定义新的 Goal 状态、Gate、Registry、Matrix 或 Evidence 权威值。若本节与 `docs/goal/` 或 `.config/goal/schema/rules.yaml` 冲突，`docs/goal/` 与 schema 投影优先，本节必须修正。

### 9.1 完整性范围

最终完整规格必须同时覆盖三类切片，缺失任一切片时不得声称 goalctl 规格完成：

1. 权威规则与状态/Gate：Authority Map、四轴 pipeline state、Registry/Matrix 状态、G0-G11、G8/G10 阻塞语义。
2. CLI、配置、运行时、证据与错误模型：命令输入输出、`.config/goal` control-plane 边界、runtime state 边界、Evidence 写入/校验、错误码与 release blocked 诊断。
3. 审查与验收：引用一致性、SSOT/schema 一致性、`docs/goal/` 未修改、lint/validate/gate/matrix/regression/e2e 命令证据。

来源：`docs/goal/00-authority-map.md:5-10`, `docs/goal/00-authority-map.md:41-64`, `.config/goal/README.md:31-62`, `docs/goal/23-workflow-governance-checks.md:33-55`。

### 9.2 引用一致性规则

所有反引号中的文件引用必须满足：文件存在；若包含 `:line` 或 `:start-end`，行号必须可解析；引用内容必须支持相邻规范性陈述。若行号漂移、文件缺失或 `.config/goal` snapshot 与 `docs/goal/` SSOT 不一致，审查结果必须记录为阻塞事项并刷新引用后再合并。

`.config/goal` 只能作为可提交 control-plane 配置、schema 投影或审计快照；不得从 snapshot 反向定义新状态、Gate ID、Registry 文件或 Matrix/Evidence 字段。`Registry` 边界必须保持为固定六个业务索引文件：`goals.yaml`, `tasks.yaml`, `issues.yaml`, `releases.yaml`, `risks.yaml`, `decisions.yaml`。

来源：`.config/goal/README.md:3-18`, `.config/goal/README.md:31-49`, `.config/goal/schema/rules.yaml:49-57`, `docs/goal/15-registry.md:5-23`。

### 9.3 审查发现必须覆盖的风险

审查报告必须至少检查以下风险，并把通过/失败证据写给 leader：

- SSOT 漂移：spec 是否复制或改写了 `docs/goal/` 状态机、Gate 结果、Matrix 状态、Evidence 字段或 Registry 边界。
- Matrix 漂移：`drop_reason` 对 `Dropped` 必需，`Drifted`/`Stale` 是有效非终态，P0/P1 `STALE` 不得 release。
- Evidence 漂移：G8 Evidence 最小字段必须包含 `Acceptance Criteria ID` 与 `Spec ID`，不能只用“done”声明替代。
- Gate 放宽：不得降低 Gate 阈值、扩大豁免范围、跳过 reviewer 分离，G6/G10 不允许 `PASS_WITH_RISK`。
- Artifact Drift：Goal 规则可以引用模块制品，但模块/CLI/spec 不能改写 Goal 状态机。

来源：`.config/goal/schema/rules.yaml:100-168`, `docs/goal/04-gates.md:184-230`, `docs/goal/23-workflow-governance-checks.md:57-67`, `docs/goal/23-workflow-governance-checks.md:69-79`。

### 9.4 最终验收清单

最终向 leader 汇报前，必须提供以下 PASS/FAIL 证据；FAIL 时停止宣称完成并报告 blocker：

- PASS/FAIL `git diff --exit-code -- docs/goal`：证明未修改 `docs/goal/`。
- PASS/FAIL 引用解析脚本：检查本文件所有 `path:line` / `path:start-end` 引用存在且行号有效。
- PASS/FAIL Registry consistency：`docs/spec/goalctl-spec.md`、`docs/goal/15-registry.md`、`.config/goal/README.md`、`.config/goal/schema/rules.yaml` 必须一致列出 `tasks.yaml` 且不得出现不存在的 `maturity.yaml`。
- PASS/FAIL Spec lint：`./docs/goal/tools/lint-goal.sh docs/spec/goalctl-spec.md`。
- PASS/FAIL Typecheck/equivalent：对仓库内 Python 验证工具执行 `python3 -m py_compile docs/goal/tools/goal-validate.py docs/goal/tools/matrix-gen.py docs/goal/tools/rule-drift-check.py`；若无 TS/package 工程，报告不适用原因。
- PASS/FAIL Regression checks：`python3 docs/goal/tools/rule-drift-check.py --root . --quiet`, `python3 docs/goal/tools/goal-validate.py --root . --mode audit --format text`, `python3 docs/goal/tools/goal-validate.py --root . --mode strict --format text`, `./docs/goal/tools/self-test.sh`。
- PASS/FAIL End-to-end release guard：`./docs/goal/tools/gate-check.sh .` 与 `python3 docs/goal/tools/matrix-gen.py --check-only --matrix .config/goal/matrix/matrix.yaml` 必须证明当前 blocked/release constraints 未被文档更改绕过。
- PASS/FAIL `git diff --check`：无空白/格式回归。

来源：`docs/goal/10-lint-rules.md:29-55`, `docs/goal/10-lint-rules.md:59-83`, `docs/goal/16-ci-cd.md:11-55`, `docs/goal/23-workflow-governance-checks.md:46-55`。

### 9.5 Acceptance Criteria 与边界/错误处理

本节的 Acceptance Criteria 仅用于 Worker-3 对本规格文件的审查结论，不新增权威 Goal AC 编号或持久化状态：

- AC-W3-REF：本文件所有规范性来源引用均指向存在的 `docs/goal/` 或 `.config/goal/` 文件；带行号引用可解析，且引用内容支撑相邻陈述。
- AC-W3-REG：Registry 边界与 `docs/goal/15-registry.md`、`.config/goal/README.md`、`.config/goal/schema/rules.yaml` 一致，必须包含 `tasks.yaml`，不得把不存在的 `maturity.yaml` 当作 Registry 文件。
- AC-W3-EVIDENCE：G8 与 Runtime Evidence 字段必须覆盖 Acceptance Criteria ID、Spec ID、Test ID、Task ID、Goal ID、Status、commands/logs/results、limitations/risks/rollback。
- AC-W3-SCOPE：审查补充只修改 `docs/spec/goalctl-spec.md`，`docs/goal/` 保持零 diff。
- AC-W3-VERIFY：最终报告必须包含 lint、引用解析、Registry consistency、typecheck/equivalent、regression、end-to-end guard 与 whitespace 检查的 PASS/FAIL 结果。

边界场景与错误处理：

- 若文件存在但行号漂移，审查结论必须标记为 `INVALID_REFERENCE` blocker，刷新引用后才能合并。
- 若 `.config/goal` snapshot/schema 与 `docs/goal/` SSOT 冲突，审查结论必须标记为 `INCONSISTENT_STATE` blocker，并以 `docs/goal/` 与 schema 投影为准修正规格。
- 若 `docs/goal/` 出现任何 diff，审查结论必须标记为 scope violation，停止完成上报并回滚该范围外改动。
- 若验证工具自身不可运行、schema 不可读或输出非零，审查结论必须记录 `VALIDATION_TOOL_FAILED`，并附命令、退出码与最小复现输出。
