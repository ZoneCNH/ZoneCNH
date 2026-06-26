# 权威映射

本文档只定义“哪里是权威、哪里是投影”。它不新增 Pipeline 状态、Gate 编号、ID 格式、Registry 子系统或业务对象状态。

## 0. 最高治理边界

- `CONSTITUTION.md` 是本仓库最高治理文件；当它与 `docs/goal/` 冲突时，执行者 MUST 服从 `CONSTITUTION.md`，并把差异记录为 Change Request。
- `docs/goal/` 是 Goal Delivery OS 方法论、流程、Gate、Evidence、Matrix 和 Agent 协作规则的 SSOT；它不得直接覆盖 Constitution、CI、agent 配置或 schema 投影等受保护资产。
- 未批准的 `change-requests/` 内容是 Hypothesis / 提案，MUST NOT 当成当前强规则。

## 1. 使用规则

- 修改状态、Gate、ID、Registry、Evidence 或 Matrix 口径时，先改权威文档，再同步投影。
- README、SOP、Runtime、CI、schema 和示例状态文件只能引用、校验或投影 SSOT，不得定义新的枚举。
- 对齐账本和分析报告只记录发现、差异和建议，不覆盖 SSOT。
- `.config/goal/` 是控制面配置、schema 与可审查快照目录；临时运行态和恢复缓存不得混入权威定义。
- `change-requests/` 只记录待审批提案，不是当前强规则源；Human Approval 前不得把提案内容写入受保护资产。

## 2. 权威表

| 主题                                       | 权威定义                                                                                           | 可引用或投影位置                                                                            | 禁止事项                                                                                |
| ------------------------------------------ | -------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| 最高治理与受保护资产边界                   | [`CONSTITUTION.md`](../../CONSTITUTION.md)、本文件                                                 | `docs/goal/change-requests/`、[`21-controlled-rsi.md`](21-controlled-rsi.md)                | 用 `docs/goal/` 直接覆盖 Constitution、CI、agent 或 schema 投影                         |
| 交付管线与四轴状态模型                     | [`03-pipeline.md`](03-pipeline.md)（完整管线见 §1、四轴状态模型见 §2）                             | `README.md`、`.config/goal/schema/rules.yaml`、`.config/goal/pipeline/state.yaml`           | 在 SOP、Runtime、CI 或 schema 中新增主流程阶段；把历史执行步骤令牌当成 `pipeline_state` |
| Matrix 横切口径                            | [`05-layer-standards.md`](05-layer-standards.md#9-matrix-横切标准)                                 | `.config/goal/matrix/`、校验脚本、报告                                                      | 把 Matrix 放回主流程阶段                                                                |
| Gate 编号与结果                            | [`04-gates.md`](04-gates.md)                                                                       | `.config/goal/gates/state.yaml`、CI 报告                                                    | 把 `XG-CHK-*`、`H-CHK-*` 或适配器检查注册成 Goal Gate                                   |
| ID 格式                                    | [`07-id-system.md`](07-id-system.md)                                                               | Registry、Matrix、Evidence、Prompt 包                                                       | 在局部文档中定义新的 ID 前缀或格式                                                      |
| Registry 边界                              | [`15-registry.md`](15-registry.md)、[`.config/goal/README.md`](../../.config/goal/README.md)       | `.config/goal/registry/`                                                                    | 把 Matrix、Gate、Pipeline、Evidence、Prompt 目录并入 Registry 子系统                    |
| Evidence 协议与执行模式                    | [`13-runtime-engine.md`](13-runtime-engine.md)（Evidence 收集见 §4、变更级别见 §变更级别）         | `.config/goal/evidence/`、Release 记录、Runtime 配置、SOP 执行记录                          | 无证据时宣称 Done；把 Lite/Standard/Full 或 RCA 动作当成 Pipeline 阶段                  |
| Evidence Bundle 与指标闭环                 | [`20-metrics-evidence.md`](20-metrics-evidence.md)                                                 | Release Manifest、Gate 报告、Metrics Review                                                 | 缺少 evidence bundle 时宣称 Review、Release 或 Done                                     |
| Risk / Decision / Release 记录             | [`17-risk-and-decisions.md`](17-risk-and-decisions.md)                                             | `.config/goal/registry/risks.yaml`、`.config/goal/registry/releases.yaml`、Release Manifest | 绕过 release-blocking risk、rollback plan 或 validation summary                         |
| Agent 协作协议                             | [`14-agent-protocols.md`](14-agent-protocols.md)、[`25-execution-guide.md`](25-execution-guide.md) | `.claude/agents/`、`.codex/agents/`、`.copilot/agents/`                                     | Agent 自批、自改 Gate、绕过 worktree 隔离或跳过 arbiter                                 |
| Controlled RSI                             | [`21-controlled-rsi.md`](21-controlled-rsi.md)                                                     | `change-requests/`、Improvement Backlog、Scorecard                                          | 自动放宽安全、隐私、资金、权限、数据保留、P0/P1 AC 或 Release Gate                      |
| 完整 RSI 标准（RSI-SG-001）                | [`26-rsi-full-standard.md`](26-rsi-full-standard.md)                                               | `21-controlled-rsi.md`                                                                      | 超出工程工作流边界的 RSI 扩展——模型/系统/组织/生态四层                                  |
| CI 与 x.go 适配器                          | [`16-ci-cd.md`](16-ci-cd.md)                                                                       | `.github/workflows/`、x.go 检查报告                                                         | 用 CI 阶段覆盖 Goal 管线状态                                                            |
| Goal 标准（SMART、结构、模板）             | [`02-goal-standard.md`](02-goal-standard.md)                                                       | `09-templates.md`、`.config/goal/schema/rules.yaml`、Goal Lint                              | 在模板或 Registry 中重新定义 Goal 结构要素或 SMART 原则                                 |
| DoR/DoD 分层完成标准                       | [`06-dod.md`](06-dod.md)                                                                           | `04-gates.md`、`08-quality-gates.md`、`05-layer-standards.md`                               | 在各层 Gate 中独立定义完成标准或绕过 DoD 退出 Gate                                      |
| 分层质量标准                               | [`08-quality-gates.md`](08-quality-gates.md)                                                       | `06-dod.md`、`04-gates.md`、`.config/goal/schema/rules.yaml`                                | 独立定义新的质量门禁枚举或绕过 DoR/DoD 评分                                             |
| 模板库（YAML/JSON 格式）                   | [`09-templates.md`](09-templates.md)                                                               | Goal/Spec/Task/Prompt 实际示例、`07-id-system.md`                                           | 在模板外定义新的 ID 前缀、结构格式或 Matrix edge 字段                                   |
| 自动化 Lint 规则（S-LINT/P-LINT）          | [`10-lint-rules.md`](10-lint-rules.md)                                                             | `.config/goal/schema/rules.yaml`、`lint-goal.sh`、CI checks                                 | 绕过 lint 规则或在本地覆盖 SSOT Lint 规则                                               |
| AI 协作（PromptOps、Context Package）      | [`11-ai-collaboration.md`](11-ai-collaboration.md)                                                 | `14-agent-protocols.md`、Prompt 包、`.claude/agents/`                                       | 绕过 Context Package 格式或跳过 Prompt 审查 Gate                                        |
| 工作流编译器（Workflow Compiler）          | [`goal-delivery.sh --compile`](tools/goal-delivery.sh)、[`deploy/roadmap.md`](deploy/roadmap.md)   | `.config/goal/prompts/`、Prompt Pack                                                        | 绕过 Compiler 直接手工编写无约束 Prompt                                                 |
| 状态机契约（State Machine Contract）       | [`schema/state-machine-contract.yaml`](schema/state-machine-contract.yaml)                         | `goal-validate.py --only contracts`                                                         | 在控制面使用 NOT_STARTED 作为 Gate 裁决；G6/G10 放行 PASS_WITH_RISK                     |
| API/Data 契约                              | [`schema/api-data-contract.yaml`](schema/api-data-contract.yaml)                                   | Spec、Design、Release Manifest                                                              | 公共 API 变更不触发 CL3+；存储迁移无 dry-run                                            |
| 安全/隐私契约                              | [`schema/security-contract.yaml`](schema/security-contract.yaml)                                   | Spec、Review、RSI                                                                           | RSI 自动放宽安全/隐私约束；生产数据入测试环境                                           |
| 运维契约（Perf/Reliability/Observability） | [`schema/ops-contract.yaml`](schema/ops-contract.yaml)                                             | Spec、Release Manifest、Metrics Review                                                      | 发布无 rollback plan；外部调用无超时/retry；无指标观察窗口                              |
| RSI 完整标准（拆分版）                     | [`rsi-standard/README.md`](rsi-standard/README.md)（30 章节）                                      | `26-rsi-full-standard.md`（索引）                                                           | 绕过 R0-R9 Gate 自动应用 RSI 补丁                                                       |
| 最小部署包                                 | [`deploy/README.md`](deploy/README.md)                                                             | 各仓库 `.config/goal/`                                                                      | 将部署包当作 SSOT 替代品                                                                |

## 3. 四轴状态模型

| 状态轴           | 含义                                                      | 合法值来源                                                | 存储字段                                                                           |
| ---------------- | --------------------------------------------------------- | --------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `pipeline_state` | 全局状态机位置，决定是否可以进入下一阶段                  | `03-pipeline.md` §2.1 与 §2.2                             | `.config/goal/pipeline/state.yaml` 的 `pipeline_state` / `previous_pipeline_state` |
| `current_phase`  | 当前业务层或制品层，例如 `GOAL`、`SPEC`、`DESIGN`         | `03-pipeline.md` §1 主流程层级                            | `.config/goal/pipeline/state.yaml` 的 `current_phase`                              |
| `phase_status`   | 当前层的局部进度，例如 `IN_PROGRESS`、`IN_REVIEW`、`DONE` | `03-pipeline.md` §2 轴说明，schema 只做镜像校验           | `.config/goal/pipeline/state.yaml` 的 `phase_status`                               |
| `workflow_step`  | SOP、Runtime 或 CI 的执行步骤投影                         | `12-operations.md`、`13-runtime-engine.md`、`16-ci-cd.md` | Runtime 事件、审计日志、`.config/goal/pipeline/state.yaml` 示例字段                |

历史的一段式执行步骤字段以及暂停、取消等控制字段不是合法 `pipeline_state`。兼容旧记录时必须映射到四个轴，不能把旧字段继续写回 Pipeline 状态枚举。

`workflow_step` 是投影命名空间，不得复用 `pipeline_state` 枚举名。Review、Release、Retrospective 的执行动作分别使用 `REVIEW_EXECUTION`、`RELEASE_EXECUTION`、`RETROSPECTIVE_EXECUTION`。

## 4. 配置与运行态边界

| 目录                         | 性质              | 可提交内容                                                 |
| ---------------------------- | ----------------- | ---------------------------------------------------------- |
| `docs/goal/`                 | 方法论与规范权威  | SSOT、说明、SOP、Runtime/CI 规范、对齐账本                 |
| `module/{module}/goal/`      | 模块 Goal 层      | 目标定义（goal.md）                                        |
| `module/{module}/spec/`      | 模块 Spec 层      | 需求规格（SPEC.md）                                        |
| `module/{module}/design/`    | 模块 Design 层    | 设计方案（DESIGN.md）                                      |
| `module/{module}/plan/`      | 模块 Plan 层      | 执行计划（PLAN.md）                                        |
| `module/{module}/tasks/`     | 模块 Tasks 层     | 任务清单                                                   |
| `module/{module}/prompt/`    | 模块 Prompt 层    | Context Package                                            |
| `module/{module}/schema/`    | 模块 Schema 层    | 模块级数据/API/契约 schema（投影）；跨模块 schema SSOT 见 `docs/goal/schema/` |
| `module/{module}/matrix/`    | 模块追溯视图      | 人类可读追溯表（投影）；canonical edge SSOT 见 `.config/goal/matrix/` |
| `module/{module}/gate/`      | 模块 Gate 层      | 模块级门禁定义与检查清单（投影）；Gate 状态 SSOT 见 `.config/goal/gates/` |
| `module/{module}/evidence/`  | 模块证据快照      | 模块级测试/验证证据；Gate 级 Evidence Bundle SSOT 见 `.config/goal/evidence/` |
| `module/{module}/registry/`  | 模块注册投影      | 模块本地 Goal/Task/Issue 投影；跨模块 Registry SSOT 见 `.config/goal/registry/` |
| `.config/goal/schema/`       | 控制面校验配置    | 从 SSOT 镜像出的规则、schema 与兼容映射                    |
| `.config/goal/registry/`     | Registry 控制面   | 6 个 Registry 子系统文件                                   |
| `.config/goal/matrix/`       | 追溯矩阵快照      | 可审查矩阵与链路校验结果                                   |
| `.config/goal/gates/`        | Gate 状态快照     | Gate 结果、Attempt、异常说明                               |
| `.config/goal/pipeline/`     | Pipeline 状态快照 | 当前状态、历史迁移、审计字段                               |
| `.config/goal/evidence/`     | Evidence 快照     | 测试、日志、审查和发布证据，Evidence Bundle ID/path        |
| `.config/goal/prompts/`      | Prompt 包快照     | Context Package、Prompt 版本、prompt-lint 结果             |
| `.config/goal/runtime/`      | 本地运行态        | 不提交临时锁、恢复缓存、进程状态                           |
| `.omx/state/` / `.omx/logs/` | OMX 运行态        | 不作为 Goal 规范权威                                       |
| `docs/goal/change-requests/` | 待审批变更提案    | 可提交提案、证据、验证命令和回滚计划；批准前不改变当前规则 |

## 5. 同步要求

1. 修改 `03-pipeline.md` 的状态枚举后，同步 `.config/goal/schema/rules.yaml` 与 `.config/goal/pipeline/state.yaml` 示例。
2. 修改 Gate、ID、Registry 或 Evidence 规则后，同步 schema、CI 校验和 README 索引。
3. 修改 SOP、Runtime 或 CI 阶段名时，只能新增或调整 `workflow_step`，不得新增 `pipeline_state`，且不得复用 `pipeline_state` 枚举名。
4. 修改模块级 Goal 文档命名规则时，同步 `module/README.md`、`.config/goal/schema/rules.yaml`、`AGENTS.md` 和变更日志。
5. 修改模块代码本地路径规则时，同步 `CONSTITUTION.md`、`ARCHITECTURE.md`、`AGENTS.md`、`module/README.md`、`.config/goal/schema/rules.yaml`、Code DoR/DoD、Code Lint 和变更日志。
6. 修改受保护资产时，先在 `docs/goal/change-requests/` 记录 evidence、impact、proposed patch、validation command、rollback plan 和 owner / approval requirement。
7. 每次权威边界变更都必须记录到 `CHANGELOG.md`，并在 Change Request、Evidence Bundle 或交付报告中保留验证证据。
