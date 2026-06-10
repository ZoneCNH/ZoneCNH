# Delivery OS 架构

> **状态：愿景架构（Vision）** — 本文档描述目标形态，尚未完整实现。部分能力已通过 Goal Agent（`.claude/agents/goal-*.md`）和 `.config/goal/` 目录落地。

Delivery OS 是把 Goal 工作流从文档方法升级为可执行工程系统的架构。它的公式是：

```text
Delivery OS = Goal Management
            + Requirement Compiler
            + Execution Control
            + Evidence Validation
            + Recursive Learning
```

## 五个运行时

| Runtime             | 管理对象                         | 关键产物                                     |
| ------------------- | -------------------------------- | -------------------------------------------- |
| Intent Runtime      | 用户目标、业务边界、成功指标     | Goal、Spec、Non-goals、NFR                   |
| Control Runtime     | 追溯、策略、门禁、变更控制       | Matrix、Policy、Gate、CR                     |
| Execution Runtime   | 任务、计划、Prompt、允许修改范围 | Task、Plan、Prompt Pack、Allowed Files       |
| Evidence Runtime    | 测试、评审、发布、运行指标       | Test Report、Review、Release、Metrics Review |
| Improvement Runtime | 复盘、根因、工作流补丁、评分     | RCA、Improvement Backlog、Eval、Scorecard    |

这五层必须通过 ID 和矩阵连接。任何一层独立存在，都不能证明目标已交付。

## Workflow-as-Code

Workflow-as-Code 表示工作流资产应像代码一样版本化、检查和测试：

| 命令概念                   | 作用                                              |
| -------------------------- | ------------------------------------------------- |
| `workflow compile`         | 从 Goal/Spec/Matrix 编译任务、Prompt 和 Gate 要求 |
| `workflow lint`            | 检查缺字段、孤儿项、越界文件、不可测 AC           |
| `workflow test`            | 用历史样例回放工作流规则                          |
| `workflow prompt build`    | 生成带上下文、边界和验证命令的 Prompt Pack        |
| `workflow review pr`       | 检查 PR 是否满足追溯、测试和证据要求              |
| `workflow release check`   | 验证发布、回滚和指标观测条件                      |
| `workflow improve analyze` | 从失败证据生成改进候选                            |

这些命令不一定一开始就真实存在，但文档和自动化应逐步向这个接口收敛。

## Workflow Compiler

Workflow Compiler 的职责是把自然语言目标转换成可验证执行包：

| 检查     | 失败示例                             |
| -------- | ------------------------------------ |
| Schema   | Goal 缺成功指标，Spec 缺 NFR         |
| Trace    | AC 没有测试，Task 没有关联 FR        |
| Risk     | 涉及资金但没有回滚计划               |
| Scope    | Prompt 没有 allowed files 或越界依赖 |
| Evidence | Release 没有 metrics window          |
| State    | 未批准 Spec 直接进入 Code            |

Compiler 失败时应输出结构化错误，而不是让 Agent 猜测如何补齐。

## Prompt Compiler

Prompt Compiler 不只是拼接上下文。它应把控制面转换成执行约束：

| 输入               | 输出                               |
| ------------------ | ---------------------------------- |
| Goal/Spec          | 用户结果、边界、非目标、验收标准   |
| Matrix             | 需求到任务、测试、证据的映射       |
| Plan               | 顺序、依赖、风险、回滚点           |
| Repository Context | 相关文件、模式、接口、禁止修改范围 |
| Gates              | 必跑命令、通过条件、失败处理       |
| Risk Policy        | 安全、隐私、性能、资金和数据约束   |

生成的 Prompt Pack 至少包含任务目标、允许修改文件、禁止事项、测试命令、证据回填格式和停止条件。

## Matrix as Control Plane

矩阵是 Delivery OS 的控制平面，不只是需求追踪表。

| 视角             | 控制内容                                               |
| ---------------- | ------------------------------------------------------ |
| Product View     | Goal、BR、FR、AC、成功指标                             |
| Engineering View | Task、Code Area、Test、Owner、Dependency               |
| Evidence View    | Test Report、Review Finding、Release Evidence、Metric  |
| RSI View         | Failure Pattern、Root Cause、Workflow Patch、Scorecard |

矩阵应控制任务拆分、Prompt 生成、代码边界、测试选择、发布 Gate 和复盘输入。没有进入矩阵的要求，不应隐式进入代码。

## 契约层

Delivery OS 需要把关键边界写成契约：

| 契约                      | 关注点                                  |
| ------------------------- | --------------------------------------- |
| State Machine Contract    | Goal/Spec/Task/Release 状态流转是否合法 |
| API/Data Contract         | 接口、字段、兼容性、迁移                |
| Privacy/Security Contract | 权限、密钥、数据保留、审计              |
| Performance Contract      | 延迟、吞吐、资源、容量                  |
| Reliability Contract      | 回滚、降级、重试、幂等                  |
| Observability Contract    | 指标、日志、追踪、告警                  |

契约变化应触发矩阵和 Gate 更新，不能只改实现。

## 治理与安全机制

| 机制                          | 目的                                           |
| ----------------------------- | ---------------------------------------------- |
| Provenance                    | 记录每个证据和决策的来源                       |
| Snapshot                      | 固化发布时的 Goal/Spec/Matrix/Prompt/Test 状态 |
| Immutable Delivery Record     | 防止事后重写交付事实                           |
| Pre-mortem                    | 在实现前枚举失败路径                           |
| Red Team Review               | 对安全、隐私、资金、数据风险做对抗性审查       |
| Builder/Reviewer Separation   | 避免同一角色自证正确                           |
| Judge Agent                   | 汇总证据并判定是否通过 Gate                    |
| Model Routing                 | 把探索、执行、审查、验证交给合适能力层         |
| Context Budget                | 控制输入规模，防止关键约束被挤出上下文         |
| Rollback/Progressive Delivery | 降低发布风险                                   |

治理机制应服务交付速度和质量，不应变成无法解释的仪式。

## 发布演练

Release 不只是合并和部署。Delivery OS 应在发布前后验证上线、回滚和指标观测路径。

| 演练 | 目标 | 通过条件 |
|------|------|----------|
| Release Simulation | 在不影响真实用户的条件下演练发布路径 | 部署步骤、owner、证据和失败处理完整 |
| Rollback Drill | 证明可以恢复到安全状态 | 回滚目标、数据影响、验证命令和耗时明确 |
| Progressive Delivery Matrix | 定义分批发布和暂停条件 | 每个阶段都有指标窗口、告警和回退动作 |
| Metrics Window Check | 验证上线后观察窗口是否足够 | 指标口径、采样周期、owner、阈值明确 |
| Incident Handoff | 证明异常时有人接手 | 值班、升级路径和沟通模板明确 |

发布演练失败时，不应通过 Release Gate。演练产生的缺口进入 Metrics Gap Report 或 Improvement Backlog。

## 最小可行架构

仓库可以先用轻量目录实现 Delivery OS：

```text
docs/goal/
  README.md
  01-methodology.md
  ...
module/
  {module}/SPEC.md
  {module}/TRACEABILITY.md
  {module}/TASKS.md
  {module}/PLAN.md
.omc/state/
  pipeline/
  tasks.json
.omc/context/
  <task-context>.md
```

最小版本只需要做到：

- 每个 Goal 有 ID、AC、指标和非目标。
- Matrix 能追溯 FR/AC/Task/Test/Evidence。
- Task Prompt 有 allowed files、验证命令和停止条件。
- Release 有 rollback plan 和 metrics window。
- Metrics Gap 能进入下一轮 Goal 或 Improvement Backlog。

## 就绪检查

引入 Delivery OS 前，先回答：

1. 当前最大损失来自需求误解、实现缺陷、发布风险，还是目标未达成？
2. 哪些证据已经稳定存在，哪些仍靠聊天记录？
3. Matrix 是否真的控制任务、Prompt、测试和发布？
4. 指标失败后是否有标准处理路径？
5. 工作流改进是否有版本、验证和回滚？

这些问题回答清楚后，再逐步自动化；否则平台化会放大混乱。
