# Gate 体系

> 管线和双轴状态机定义见 [03-pipeline.md#完整管线](03-pipeline.md#1-完整管线)、[双轴状态机](03-pipeline.md#2-双轴状态机)。

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

通过标准: Task 原子化、有 DoD，Matrix 无孤儿行、无范围膨胀。
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
- [ ] 是否覆盖 Matrix 行？
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
- [ ] Matrix 全部关键项为 `Verified`，或为 `Dropped` 且有 `drop_reason`
- [ ] P0/P1 测试全部通过
- [ ] 无权限绕过风险
- [ ] 无数据破坏风险
- [ ] 有日志和监控
- [ ] 有 Feature Flag 或回滚方案
- [ ] 有灰度策略
- [ ] 有上线后指标观察计划

通过标准: Release 就绪，满足上线前全部检查项。
失败标准: 存在阻塞性风险或缺少回滚方案。

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
