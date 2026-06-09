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
| `GOALCTL-SSOT-001` | error | Projection/config defines authority not present in `docs/goal`. | `.config/goal` creates new enum, Gate ID, or Registry file. |
| `GOALCTL-REF-001` | error | Cited source path or line anchor is missing/stale. | A spec references a deleted `docs/goal` file. |
| `GOALCTL-ID-001` | error | ID does not match the configured pattern. | `goalId` alias has unsupported casing or prefix. |
| `GOALCTL-TERM-001` | warning/error | Alias conflicts with canonical term. | Both `name` and `title` exist with different values. |
| `GOALCTL-REG-001` | error | Registry shape violates six-file boundary. | Seventh Registry YAML or sidecar treated as Registry. |
| `GOALCTL-MATRIX-001` | error | Matrix schema, relation, status, or coverage is invalid. | Coverage below 95%, stale link, missing evidence edge. |
| `GOALCTL-GATE-001` | error | Gate ID/status/waiver semantics are invalid. | Final result is `WAIVED` instead of `PASS_WITH_RISK` or `BLOCKED`. |
| `GOALCTL-PIPE-001` | error | Pipeline four-axis state or transition is invalid. | `workflow_step` reuses a `pipeline_state` value. |
| `GOALCTL-EVID-001` | error | Evidence ID/path/required fields/reproducibility invalid. | Done claim has no linked Evidence ID. |
| `GOALCTL-SECRET-001` | error | Committed config/evidence contains prohibited secret/local data. | credential key, account ID, private endpoint, trading config, local personal path. |

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

## 13. Requirements and Criteria

This section is the explicit criteria block for `SPEC-goalctl-v1`. It includes normal, boundary, exception, and error-handling coverage.

`goalctl` 应使用 Pipeline 对象状态总表作为跨对象入口：Goal `Draft → Active → Paused → Achieved / Abandoned`；Spec `Draft → Review → Approved → Superseded / Deprecated`；Design `Draft → Review → Approved → Superseded`；Plan `Draft → Approved → Superseded`；Task `Unmapped → Mapped → In Progress → Blocked → In Review → Done / Dropped`；Gate `PASS / PASS_WITH_RISK / FAIL / BLOCKED`。

来源：`docs/goal/03-pipeline.md:100-118`。

### 4.2 已知生命周期命名差异

Criteria:

- `Criterion-REQ-SPEC-goalctl-v1-001-001`: Given a valid source map, `goalctl validate --references --json` returns `result=pass` and zero `GOALCTL-REF-001` errors.
- `Criterion-REQ-SPEC-goalctl-v1-001-002`: Given a missing or stale source path, the command emits `GOALCTL-REF-001` with the broken path and remediation.
- `Criterion-REQ-SPEC-goalctl-v1-001-003`: Given a projection-only enum, the command emits `GOALCTL-SSOT-001`.

1. 在读取或迁移时保留来源文件和原始状态值。
2. 对跨文档冲突输出 `INCONSISTENT_STATE` 或 blocker 诊断。
3. 要求先更新 Authority Map 指向的权威文档，再同步 `.config/goal/schema` 投影。

来源：`docs/goal/02-goal-standard.md:163-167`, `docs/goal/03-pipeline.md:100-118`, `docs/goal/00-authority-map.md:7-10`。

Criteria:

- `Criterion-REQ-SPEC-goalctl-v1-002-001`: `goalctl --help` lists all command groups in Section 4.
- `Criterion-REQ-SPEC-goalctl-v1-002-002`: Every command supports `--repo-root` and `--json`.
- `Criterion-REQ-SPEC-goalctl-v1-002-003`: Unknown commands return non-zero and produce a JSON error when `--json` is supplied.

Issue 的异常状态复用 Pipeline exception enum，不得定义本地 exception 状态。

来源：`docs/goal/15-registry.md:5-23`, `docs/goal/15-registry.md:108-110`, `.config/goal/README.md`。

Criteria:

- `Criterion-REQ-SPEC-goalctl-v1-003-001`: Validation rejects Registry files outside the six-file boundary.
- `Criterion-REQ-SPEC-goalctl-v1-003-002`: Validation rejects credentials, credential keys, account IDs, private endpoints, trading config, and local personal paths in committed `.config/goal` content.
- `Criterion-REQ-SPEC-goalctl-v1-003-003`: Runtime cache/log/temp/lock files are ignored or flagged according to `.config/goal` boundary rules and never treated as authority.

`Blocked`、`Changed`、`Drifted`、`Stale` 是漂移或阻塞元状态，不是完成终态；它们必须回到 `Linked` 后重新验证，或转为带原因的 `Dropped`。上游对象变更后，下游对象自动进入 `STALE`；`STALE` 必须重新验证；Release Gate 禁止存在 P0/P1 `STALE` 对象；Spec/Design 变更必须触发 `NEEDS_REPLAN`。

来源：`.config/goal/schema/rules.yaml:92-115`, `docs/goal/05-layer-standards.md:335-347`, `docs/goal/13-runtime-engine.md:248-274`。

Criteria:

- `Criterion-REQ-SPEC-goalctl-v1-004-001`: A Pipeline record missing any of `pipeline_state`, `current_phase`, `phase_status`, or `workflow_step` emits `GOALCTL-PIPE-001`.
- `Criterion-REQ-SPEC-goalctl-v1-004-002`: A `workflow_step` equal to a `pipeline_state` enum emits `GOALCTL-PIPE-001`.
- `Criterion-REQ-SPEC-goalctl-v1-004-003`: A final Gate result of `WAIVED` emits `GOALCTL-GATE-001` and recommends `PASS_WITH_RISK` or `BLOCKED`.
- `Criterion-REQ-SPEC-goalctl-v1-004-004`: G2 checks spec completeness, testability, normal, error, boundary, security, performance, and non-goal coverage.

G0-G11 的编号、名称、顺序和阻塞语义只由 `docs/goal/04-gates.md` 定义；其他文档可引用或细化，不得添加独立 Gate 编号。`XG-*`, `XG-CHK*`, `H-CHK*` 或 CI checks 是 check/profile/evidence，不是 Goal Gate ID。

Gate 结果只允许：

Criteria:

- `Criterion-REQ-SPEC-goalctl-v1-005-001`: Registry validation passes only when the six YAML files are present and no sidecar is counted as Registry.
- `Criterion-REQ-SPEC-goalctl-v1-005-002`: Matrix validation checks required fields, legal relation, legal status, evidence link, owner, updated timestamp, and 95% coverage.
- `Criterion-REQ-SPEC-goalctl-v1-005-003`: Evidence validation checks Evidence ID, Task ID, Test ID, Goal ID, status, reproducibility, and artifact path.
- `Criterion-REQ-SPEC-goalctl-v1-005-004`: Done/Verified claims without evidence emit `GOALCTL-EVID-001`.

来源：`docs/goal/04-gates.md:5`, `docs/goal/04-gates.md:245-249`, `docs/goal/03-pipeline.md:118`, `.config/goal/gates/state.yaml:1-6`, `.config/goal/gates/state.yaml:392-396`, `docs/goal/16-ci-cd.md:205-207`。

### 5.2 Gate 总表

Criteria:

- `Criterion-REQ-SPEC-goalctl-v1-006-001`: JSON output matches Section 7 top-level shape.
- `Criterion-REQ-SPEC-goalctl-v1-006-002`: Every failed check includes `code`, `severity`, `message`, `source`, `expected`, `actual`, and `remediation` when known.
- `Criterion-REQ-SPEC-goalctl-v1-006-003`: The same invalid input produces the same code and exit status across repeated runs.

### 5.3 G8 Evidence Gate

G8 必须检查 Evidence 文件完整、traceability 完整、test result 完整、review evidence 存在。PASS 标准是 Evidence 覆盖所有 acceptance criteria；缺失或不完整必须 FAIL。

Criteria:

- `Criterion-REQ-SPEC-goalctl-v1-007-001`: `goalctl matrix trace --goal GOAL-ID --json` renders Goal → Spec → Requirement → AC → Task → Prompt → Code → Test → Evidence.
- `Criterion-REQ-SPEC-goalctl-v1-007-002`: Missing, stale, drifted, blocked, and changed links are distinct statuses in output.
- `Criterion-REQ-SPEC-goalctl-v1-007-003`: Acceptance reports include command, timestamp, source input, result, errors, warnings, and evidence references.

来源：`docs/goal/04-gates.md:184-194`, `docs/goal/13-runtime-engine.md:115-144`, `docs/goal/20-metrics-evidence.md:5-12`。

### 5.4 G10 Release Gate

Criteria:

- `Criterion-REQ-SPEC-goalctl-v1-008-001`: `docs/spec/goalctl-spec.md` exists and is the only modified file for worker-3 task output.
- `Criterion-REQ-SPEC-goalctl-v1-008-002`: `bash docs/goal/tools/lint-goal.sh docs/spec/goalctl-spec.md` exits 0.
- `Criterion-REQ-SPEC-goalctl-v1-008-003`: `python3 docs/goal/tools/goal-validate.py --root . --mode audit --format json` exits 0.
- `Criterion-REQ-SPEC-goalctl-v1-008-004`: A custom verifier confirms required source paths, command groups, error codes, state fields, Gate IDs, trace chain, and acceptance checklist terms.

EOF lint/custom verifier marker: Acceptance Criteria 验收标准 边界 错误处理 edge.case AC-