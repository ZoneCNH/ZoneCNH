# goalctl 规格：Goal 权威规则、状态与 Gate（worker-1 切片）

## 1. 范围

本文是 `goalctl` 规格的 worker-1 切片，只固化 `docs/goal/` 与 `.config/goal/` 中已经存在的权威规则、状态模型、Gate 语义和当前审计快照。CLI 命令形态、配置加载、运行时错误处理和 Evidence 采集实现由其他切片补充。

`goalctl` MUST NOT 修改或反向定义 `docs/goal/`。当机器可读配置与权威文档冲突时，`goalctl` 必须报告冲突并阻止静默规范化。

## 2. 权威与投影合同

| 主题 | goalctl 要求 | 权威来源 |
| --- | --- | --- |
| SSOT 边界 | `docs/goal/` 是方法论与规格权威；README、SOP、Runtime、CI、schema 和 examples 只能引用、验证或投影 SSOT，不得新增状态、Gate、ID、Registry、Evidence 或 Matrix 枚举。 | `docs/goal/00-authority-map.md:3`, `docs/goal/00-authority-map.md:7-10` |
| 机器投影 | `.config/goal/schema` 是机器可读投影；`.config/goal/{registry,matrix,gates,pipeline,evidence,prompts}` 是审计快照；`.config/goal/runtime`、`.omx/state`、log 不是 Goal 权威。 | `docs/goal/00-authority-map.md:41-54`, `.config/goal/schema/rules.yaml:1-3` |
| 权威表 | pipeline、四轴状态、Matrix、Gate、ID、Registry、Evidence、CI/x.go 和 config/runtime 边界都必须按 Authority Map 指向的文件解析。 | `docs/goal/00-authority-map.md:16-26` |
| 同步约束 | 修改权威规则后必须同步 schema、snapshots、examples 和 CI 校验；未同步时必须产生 drift/blocker，而不是推进 Gate。 | `docs/goal/00-authority-map.md:58-61` |


### 2.1 边界场景与错误处理

`goalctl` 遇到权威冲突、未知状态、非法 Gate ID、缺失 Evidence、P0/P1 `STALE`、release-blocking risk 或投影漂移时，必须输出 blocker/diagnostic 并拒绝推进对应 Gate；不得以默认值、隐式转换或局部配置覆盖 SSOT。

## 3. Pipeline 与四轴状态模型

### 3.1 Pipeline 主链路

标准链路是：

```text
Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective
```

Matrix 是横切追踪工件，不是 pipeline layer，也不是 from/to 状态。`goalctl` 在生成或校验状态时不得把 Matrix 写入 `current_phase` 或 `pipeline_state`。

来源：`docs/goal/03-pipeline.md:11-13`, `docs/goal/03-pipeline.md:31`。

### 3.2 四轴状态

| 轴 | 含义 | 合法值 / 来源 | 写入者约束 |
| --- | --- | --- | --- |
| `pipeline_state` | 全局状态机位置。 | `INIT`, `CONTEXT_READY`, `GOAL_READY`, `SPEC_READY`, `DESIGN_READY`, `PLAN_READY`, `TASKS_READY`, `EXECUTING`, `VERIFYING`, `REVIEWING`, `RELEASING`, `RETROSPECTING`, `DONE`, plus exception states. | pipeline runner / Gate arbiter；旧式单段 step/control token 不是合法 `pipeline_state`。 |
| `current_phase` | 当前工作阶段。 | `GOAL`, `SPEC`, `DESIGN`, `PLAN`, `TASKS`, `PROMPT`, `CODE`, `TEST`, `REVIEW`, `RELEASE`, `RETROSPECTIVE`。 | 由 pipeline 进展决定；Matrix 不得写入。 |
| `phase_status` | 当前阶段内状态。 | `NOT_STARTED`, `IN_PROGRESS`, `IN_REVIEW`, `READY`, `DONE`, `BLOCKED`, `SKIPPED`, `STALE`。 | 当前阶段 owner / Gate arbiter。 |
| `workflow_step` | SOP/runtime/CI/profile 执行步。 | 从 `.config/goal/schema/rules.yaml` 投影，例如 `RELEASE_EXECUTION`。 | operator/runtime/CI；不得覆盖 `current_phase` 或 `pipeline_state`。 |

来源：`docs/goal/00-authority-map.md:28-39`, `docs/goal/03-pipeline.md:35-46`, `.config/goal/schema/rules.yaml:200-270`。

### 3.3 Pipeline 状态值

正常流：

```text
INIT → CONTEXT_READY → GOAL_READY → SPEC_READY → DESIGN_READY → PLAN_READY → TASKS_READY → EXECUTING → VERIFYING → REVIEWING → RELEASING → RETROSPECTING → DONE
```

异常状态：`BLOCKED`, `FAILED`, `NEEDS_RESEARCH`, `NEEDS_DECISION`, `NEEDS_REPLAN`, `NEEDS_ROLLBACK`, `NEEDS_HUMAN_APPROVAL`, `INCONSISTENT_STATE`。

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

Registry 是长期共享状态，位于 `.config/goal/registry` 的六类 YAML：`goals.yaml`, `issues.yaml`, `decisions.yaml`, `risks.yaml`, `releases.yaml`, `maturity.yaml`。其他 `.config/goal` 目录是 sidecar component 或 snapshot，不属于 Registry 子系统。

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

Runtime Evidence 至少包含：Evidence ID、Task ID、Test ID、Goal ID、Date、Status (`PASS`/`FAIL`/`PARTIAL`)、Files Changed、Commands Run、Results、Logs、Diff Summary、Requirement Proof、Known Limitations、Risks、Rollback。

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
