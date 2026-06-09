# 权威映射

本文档只定义“哪里是权威、哪里是投影”。它不新增 Pipeline 状态、Gate 编号、ID 格式、Registry 子系统或业务对象状态。

## 1. 使用规则

- 修改状态、Gate、ID、Registry、Evidence 或 Matrix 口径时，先改权威文档，再同步投影。
- README、SOP、Runtime、CI、schema 和示例状态文件只能引用、校验或投影 SSOT，不得定义新的枚举。
- 对齐账本和分析报告只记录发现、差异和建议，不覆盖 SSOT。
- `.config/goal/` 是控制面配置、schema 与可审查快照目录；临时运行态和恢复缓存不得混入权威定义。

## 2. 权威表

| 主题 | 权威定义 | 可引用或投影位置 | 禁止事项 |
|------|----------|------------------|----------|
| 完整交付管线 | [`03-pipeline.md`](03-pipeline.md) | `README.md`、`12-operations.md`、`13-runtime-engine.md`、`16-ci-cd.md` | 在 SOP、Runtime、CI 或 schema 中新增主流程阶段 |
| Pipeline 状态与四轴状态模型 | [`03-pipeline.md`](03-pipeline.md#2-四轴状态模型) | `.config/goal/schema/rules.yaml`、`.config/goal/pipeline/state.yaml` | 把历史执行步骤令牌或控制令牌当成 `pipeline_state` |
| Matrix 横切口径 | [`05-layer-standards.md`](05-layer-standards.md#9-matrix-横切标准) | `.config/goal/matrix/`、校验脚本、报告 | 把 Matrix 放回主流程阶段 |
| Gate 编号与结果 | [`04-gates.md`](04-gates.md) | `.config/goal/gates/state.yaml`、CI 报告 | 把 `XG-CHK-*`、`H-CHK-*` 或适配器检查注册成 Goal Gate |
| ID 格式 | [`07-id-system.md`](07-id-system.md) | Registry、Matrix、Evidence、Prompt 包 | 在局部文档中定义新的 ID 前缀或格式 |
| Registry 边界 | [`15-registry.md`](15-registry.md)、[`.config/goal/README.md`](../../.config/goal/README.md) | `.config/goal/registry/` | 把 Matrix、Gate、Pipeline、Evidence、Prompt 目录并入 Registry 子系统 |
| Evidence 协议 | [`13-runtime-engine.md`](13-runtime-engine.md#4-evidence-收集) | `.config/goal/evidence/`、Release 记录 | 无测试、日志或审查证据时宣称 Done |
| 模块级 Goal 文档路径 | [`README.md`](README.md#与-docsspecmodule-和-docsgovernance-的同步边界)、[`module/README.md`](../../module/README.md#goal-文档索引) | `.config/goal/schema/rules.yaml`、`AGENTS.md`、模块索引 | 使用 `module/{module}/goal/`、`module/{module}/goal/1.md` 或 `goal/*.md` 作为模块 Goal 槽位 |
| 变更级别与执行模式 | [`13-runtime-engine.md`](13-runtime-engine.md) | Runtime 配置、SOP 执行记录 | 把 Lite/Standard/Full 或 RCA 动作当成 Pipeline 阶段 |
| CI 与 x.go 适配器 | [`16-ci-cd.md`](16-ci-cd.md) | `.github/workflows/`、x.go 检查报告 | 用 CI 阶段覆盖 Goal 管线状态 |
| 标准对齐分析 | [`24-standard-unification-analysis.md`](24-standard-unification-analysis.md)、`docs/report/goal/` | 修复计划、变更日志、审查记录 | 让分析报告覆盖正式规范 |
| 配置与运行态边界 | [`.config/goal/README.md`](../../.config/goal/README.md) | `.config/goal/schema/`、`.config/goal/runtime/`、`.omx/state/` | 把本地临时运行缓存提交为权威状态 |

## 3. 四轴状态模型

| 状态轴 | 含义 | 合法值来源 | 存储字段 |
|--------|------|------------|----------|
| `pipeline_state` | 全局状态机位置，决定是否可以进入下一阶段 | `03-pipeline.md` §2.1 与 §2.2 | `.config/goal/pipeline/state.yaml` 的 `pipeline_state` / `previous_pipeline_state` |
| `current_phase` | 当前业务层或制品层，例如 `GOAL`、`SPEC`、`DESIGN` | `03-pipeline.md` §1 主流程层级 | `.config/goal/pipeline/state.yaml` 的 `current_phase` |
| `phase_status` | 当前层的局部进度，例如 `IN_PROGRESS`、`IN_REVIEW`、`DONE` | `03-pipeline.md` §2 轴说明，schema 只做镜像校验 | `.config/goal/pipeline/state.yaml` 的 `phase_status` |
| `workflow_step` | SOP、Runtime 或 CI 的执行步骤投影 | `12-operations.md`、`13-runtime-engine.md`、`16-ci-cd.md` | Runtime 事件、审计日志、`.config/goal/pipeline/state.yaml` 示例字段 |

历史的一段式执行步骤字段以及暂停、取消等控制字段不是合法 `pipeline_state`。兼容旧记录时必须映射到四个轴，不能把旧字段继续写回 Pipeline 状态枚举。

`workflow_step` 是投影命名空间，不得复用 `pipeline_state` 枚举名。Review、Release、Retrospective 的执行动作分别使用 `REVIEW_EXECUTION`、`RELEASE_EXECUTION`、`RETROSPECTIVE_EXECUTION`。

## 4. 配置与运行态边界

| 目录 | 性质 | 可提交内容 |
|------|------|------------|
| `docs/goal/` | 方法论与规范权威 | SSOT、说明、SOP、Runtime/CI 规范、对齐账本 |
| `.config/goal/schema/` | 控制面校验配置 | 从 SSOT 镜像出的规则、schema 与兼容映射 |
| `.config/goal/registry/` | Registry 控制面 | 6 个 Registry 子系统文件 |
| `.config/goal/matrix/` | 追溯矩阵快照 | 可审查矩阵与链路校验结果 |
| `.config/goal/gates/` | Gate 状态快照 | Gate 结果、Attempt、异常说明 |
| `.config/goal/pipeline/` | Pipeline 状态快照 | 当前状态、历史迁移、审计字段 |
| `.config/goal/evidence/` | Evidence 快照 | 测试、日志、审查和发布证据 |
| `.config/goal/prompts/` | Prompt 包快照 | Context Package 与 Prompt 版本 |
| `.config/goal/runtime/` | 本地运行态 | 不提交临时锁、恢复缓存、进程状态 |
| `.omx/state/` / `.omx/logs/` | OMX 运行态 | 不作为 Goal 规范权威 |

## 5. 同步要求

1. 修改 `03-pipeline.md` 的状态枚举后，同步 `.config/goal/schema/rules.yaml` 与 `.config/goal/pipeline/state.yaml` 示例。
2. 修改 Gate、ID、Registry 或 Evidence 规则后，同步 schema、CI 校验和 README 索引。
3. 修改 SOP、Runtime 或 CI 阶段名时，只能新增或调整 `workflow_step`，不得新增 `pipeline_state`，且不得复用 `pipeline_state` 枚举名。
4. 修改模块级 Goal 文档命名规则时，同步 `module/README.md`、`.config/goal/schema/rules.yaml`、`AGENTS.md` 和变更日志。
5. 每次权威边界变更都必须记录到 `CHANGELOG.md`，并在 `todo.md` 或报告中保留验证证据。
