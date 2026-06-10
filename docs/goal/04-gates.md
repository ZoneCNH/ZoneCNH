# Gate 体系

> 管线和四轴状态模型定义见 [03-pipeline.md#完整管线](03-pipeline.md#1-完整管线)、[四轴状态模型](03-pipeline.md#2-四轴状态模型)。

本文档定义 Goal 驱动交付体系的 **Gate 体系（G0-G11）**，并作为 Gate 编号、名称、顺序和阻塞语义的权威来源。其他文档只能引用或细化这些 Gate，不得新增独立 Gate 编号。

---

## 1. Gate 类型

| 类型 | 说明 |
|------|------|
| Semantic Gate | 需要 Agent/Reviewer 语义判断 |
| Executable Gate | 可以通过命令、脚本、CI 自动判断 |
| Hybrid Gate | 先脚本检查，再人工或 Agent 解释风险 |

## 2. Gate 结构

```yaml
gate_id:
  name:
  type: semantic | executable | hybrid
  blocking: true | false
  scope:
  inputs:
  checks:
  pass_criteria:
  fail_criteria:
  outputs:
  owner:
```

### 2.1 Gate 执行矩阵

下表是 G0-G11 的最小可执行口径。单个 Gate 的详细检查项以后文为准；执行者不得只凭阶段名称跳过输入、输出、阻断条件或证据。

| Gate | 必备输入 | 必备输出 | 硬阻断条件 | 证据要求 |
|------|----------|----------|------------|----------|
| G0 Context | Goal / Spec / Design / Plan / Task 上下文、branch、commit、运行态快照 | 可继续执行的上下文状态 | 关键上下文缺失；环境或分支状态无法解释 | 恢复记录、branch / commit、已加载文档清单 |
| G1 Goal | Draft Goal、owner、成功指标、non-goals、约束 | Approved / Rejected Goal verdict | 缺 owner、成功指标、验收标准、边界或 non-goals | Goal review 记录、指标和边界说明 |
| G2 Spec | Approved Goal、Spec、AC、NFR、风险和约束 | Approved / Rejected Spec verdict | 需求不可测试；P0/P1 AC 缺失；安全、异常或边界路径缺失 | Spec review 记录、AC / NFR 清单、风险记录 |
| G3 Design | Approved Spec、架构边界、模块映射、风险 | Approved / Rejected Design verdict | 需求无模块映射；接口不可测试；循环依赖；关键决策无记录 | Design review、ADR 或等价决策记录、风险缓解记录 |
| G4 Plan | Approved Design、依赖关系、验证目标、rollback 约束 | Approved / Rejected Plan verdict | 执行顺序不满足依赖；无验证点；无 rollback 或 checkpoint | Plan review、依赖顺序、验证命令、rollback/checkpoint 说明 |
| G5 Task / Matrix | Approved Plan、Task specs、Matrix edges | 原子任务和 Matrix coverage verdict | Task 不可独立完成；release-critical edge 无 owner / gate / evidence；orphan edge 未解释 | Task DoR、Matrix check-only、coverage / orphan 检查 |
| G6 Implementation | Approved Task、Prompt / Context Package、allowed files、禁止范围 | 有界 diff 或阻断 verdict | Prompt 缺上下文或验证命令；实现越界；共享 writer 冲突 | Prompt review、allowed files、diff、越界检查记录 |
| G7 Test | Code diff、Test Plan、环境、命令 | PASS / FAIL 测试结果 | P0/P1 测试缺失或失败；失败证据被删除；环境不可复现 | 命令、环境、测试输出、失败证据 |
| G8 Evidence | 测试、review、Matrix、Risk、commit/artifact | Evidence Bundle verdict | 缺 command、environment、commit/artifact、owner、AC 映射或失败记录 | Evidence Bundle ID / path、结果摘要、保留策略 |
| G9 Review | Code diff、Evidence Bundle、Matrix、Risk | Review PASS / FAIL verdict | 未解决 P0/P1 finding；scope creep；安全、性能或边界问题未闭环 | reviewer、finding、resolution、risk acceptance 记录 |
| G10 Release | strict validator、Matrix check-only、Evidence Bundle、Release Manifest、Risk Register、rollback validation | Release PASS / FAIL verdict | 缺 Release Manifest、Risk Register、Evidence Bundle、validation summary 或 rollback validation；存在 open release_blocking risk | G10 verdict、Release Manifest、Risk Register、validation summary、rollback validation |
| G11 Retrospective | Release 结果、metrics、incident / rollback 记录、review findings | Retrospective report 和改进 backlog | 复盘事实缺失；改进项无 owner 或无验证方式 | Metrics Review、Gap Report、RSI backlog、后续 owner |

## 3. 必备 Gates

| Gate | 名称 | 类型 | 检查内容 |
|------|------|------|----------|
| G0 | Context Gate | Hybrid | 上下文恢复完整 |
| G1 | Goal Gate | Semantic | Goal 符合 SMART 标准 |
| G2 | Spec Gate | Semantic | Spec 完整且可测试 |
| G3 | Design Gate | Semantic | Design 可映射到模块 |
| G4 | Plan Gate | Semantic | Plan 体现依赖顺序 |
| G5 | Task Gate | Executable | Task 原子化且有 DoD |
| G6 | Implementation Gate | Executable | 实现未越界 |
| G7 | Test Gate | Executable | 测试通过 |
| G8 | Evidence Gate | Executable | Evidence 完整 |
| G9 | Review Gate | Semantic | Review 通过 |
| G10 | Release Gate | Hybrid | Release 就绪 |
| G11 | Retrospective Gate | Semantic | 复盘完成 |

### G0 Context Gate

类型: Hybrid
阻塞: true

检查项:
- [ ] 上下文恢复完整（Goal、Spec、Design、Plan 等关键文档已加载）
- [ ] 环境状态与上次中断时一致

通过标准: 所有必要上下文就绪，可继续管线。
失败标准: 缺少关键上下文，需重新加载。

### G1 Goal Gate

类型: Semantic
阻塞: true

检查项:
- [ ] 是否说明了业务背景？
- [ ] 是否说明了目标用户？
- [ ] 是否是结果导向，而不是实现方案？
- [ ] 是否有成功指标？
- [ ] 是否有验收标准？
- [ ] 是否有范围边界？
- [ ] 是否写明 Non-goals？
- [ ] 是否有约束条件？

通过标准: Goal 符合 SMART 标准，具备业务背景、成功指标和验收标准。
失败标准: 缺少业务背景、成功指标或验收标准。

### G2 Spec Gate

类型: Semantic
阻塞: true

检查项:
- [ ] 每条需求是否可实现？
- [ ] 每条需求是否可测试？
- [ ] 是否覆盖正常路径？
- [ ] 是否覆盖异常路径？
- [ ] 是否覆盖边界条件？
- [ ] 是否有安全要求？
- [ ] 是否有性能要求？
- [ ] 是否写明不做什么？

通过标准: Spec 完整且可测试，覆盖正常/异常/边界路径。
失败标准: 需求不可测试、缺少异常或边界覆盖。

### G3 Design Gate

类型: Semantic
阻塞: true

检查项:
- [ ] 每个需求是否映射到模块？
- [ ] 模块边界是否清晰？
- [ ] 接口是否可测试？
- [ ] 是否避免循环依赖？
- [ ] 关键决策是否有 ADR 或等价记录？

通过标准: 设计可映射到模块，接口清晰，无循环依赖。
失败标准: 需求无模块映射、存在循环依赖、关键决策无记录。

### G4 Plan Gate

类型: Semantic
阻塞: true

检查项:
- [ ] 是否先做基础能力？
- [ ] 是否先处理高风险任务？
- [ ] 是否有阶段性验证点？
- [ ] 是否有回滚方案？
- [ ] 是否避免阻塞依赖？
- [ ] 是否能增量交付？

通过标准: Plan 体现依赖顺序，先基础后上层，有验证点和回滚方案。
失败标准: 依赖顺序不合理、无验证点、无回滚方案。

### G5 Task Gate

类型: Executable
阻塞: true

Task Review 检查项:
- [ ] Task 是否足够小？
- [ ] Task 是否有明确输入？
- [ ] Task 是否有明确输出？
- [ ] Task 是否有完成标准？
- [ ] Task 是否有依赖关系？
- [ ] Task 是否能独立验证？

Matrix Review 检查项（覆盖检查）:
- [ ] 每个 Goal 是否有 Spec 覆盖？
- [ ] 每个 Spec 是否有 Task 覆盖？
- [ ] 每个验收标准是否有 Test 覆盖计划？
- [ ] 是否存在无来源 Task？
- [ ] 是否存在无测试关键需求？
- [ ] 是否存在重复任务？
- [ ] 是否存在范围膨胀？

通过标准: Task 原子化、有 DoD，Matrix 无孤儿 edge、无范围膨胀；关键 edge 已绑定 owner 与 evidence 计划。
失败标准: Task 不可独立验证、Matrix 存在覆盖缺口或范围膨胀。

### G6 Implementation Gate

类型: Executable
阻塞: true

Prompt Review 检查项:
- [ ] 是否包含 Goal？
- [ ] 是否包含 Task？
- [ ] 是否包含上下文？
- [ ] 是否包含约束？
- [ ] 是否包含输出格式？
- [ ] 是否包含验收标准？
- [ ] 是否包含测试要求？
- [ ] 是否写明禁止事项？

通过标准: 实现未越界，Prompt 包含完整上下文和约束。
失败标准: Prompt 缺少关键要素或实现超出 Task 范围。

### G7 Test Gate

类型: Executable
阻塞: true

检查项:
- [ ] 所有测试通过
- [ ] 覆盖率满足要求（≥ 80%）

通过标准: 测试全部通过且覆盖率达标。
失败标准: 存在失败测试或覆盖率不足。

### G8 Evidence Gate

类型: Executable
阻塞: true

检查项:
- [ ] Evidence 文件完整
- [ ] 每项验收标准有对应证据

通过标准: Evidence 完整，覆盖所有验收标准。
失败标准: Evidence 缺失或不完整。

### G9 Review Gate

类型: Semantic
阻塞: true

检查项:
- [ ] 是否实现了对应 Task？
- [ ] 是否满足 Spec？
- [ ] 是否覆盖 Matrix edge？
- [ ] 是否有测试？
- [ ] 是否处理异常情况？
- [ ] 是否满足安全要求？
- [ ] 是否满足性能要求？
- [ ] 是否没有引入无关功能？

通过标准: Review 通过，代码满足目标和 Spec 要求。
失败标准: 未实现 Task、不满足 Spec、引入无关功能。

### G10 Release Gate

类型: Hybrid
阻塞: true

检查项:
- [ ] `goal-validator` strict 通过，且 Matrix `check-only` 无阻断错误
- [ ] Matrix 全部 release-critical edge 为 `Verified`，或为 `Dropped` 且有 `drop_reason`
- [ ] P0/P1 测试全部通过，并有 Evidence Bundle 记录命令、环境、commit 和结果
- [ ] Release Manifest 已创建，包含 `release_id`、`goal_id`、commit/artifact、`validation_summary`、`evidence_manifest`、`risk_register`、`rollback_plan`
- [ ] Risk Register 无未解除（`Open` / `Escalated`）的 `release_blocking` 风险；所有 High/Critical residual risk 均有 owner、mitigation、接受记录或阻断结论
- [ ] 无权限绕过风险
- [ ] 无数据破坏风险
- [ ] 有日志和监控
- [ ] 有 Feature Flag 或回滚方案，且回滚路径有验证记录、dry-run 记录或可审查 fallback evidence
- [ ] 有灰度策略
- [ ] 有上线后指标观察计划

通过标准: Release 就绪；strict validator、Matrix、Evidence Bundle、Risk Register、Release Manifest 和 rollback validation 可共同证明 G10 PASS。
失败标准: G10 未 PASS、存在未解除（`Open` / `Escalated`）的 `release_blocking` 风险、缺少 Evidence Bundle / Release Manifest / rollback plan / validation summary，或存在未处理的权限、数据、安全、资金、隐私阻断风险。

### G11 Retrospective Gate

类型: Semantic
阻塞: false

检查项:
- [ ] 复盘文档已编写
- [ ] 关键决策已记录
- [ ] 改进项已识别

通过标准: 复盘完成，改进项已记录。
失败标准: 复盘未完成。

## 4. Gate 结果

```text
PASS           — 通过
PASS_WITH_RISK — 通过但有风险，需进入 Risk Register
FAIL           — 不通过，需修复
BLOCKED        — 被阻塞，需解决依赖
```

`result.verdict` 只能使用以上四个裁决值。`NOT_STARTED` 和 `IN_PROGRESS` 只属于生命周期或运行态快照，不是 Gate 结果裁决。

提交到控制面的 canonical Gate（`G0`-`G11`）必须处于终态裁决，且 `status` 必须与 `result.verdict` 一致。补充性模块快照或临时运行态可以记录生命周期状态，但不能把生命周期状态写入 `result.verdict`。

当 Gate 记录同时包含数值型 `result.score` 和 `result.threshold` 时，`PASS` 必须满足 `score >= threshold`。低于阈值的记录只能裁决为 `PASS_WITH_RISK`、`FAIL` 或 `BLOCKED`，并保留对应风险或阻塞说明。
