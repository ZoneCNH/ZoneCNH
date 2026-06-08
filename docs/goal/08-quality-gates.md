# 质量门禁

> Gate 体系（G0-G11）的权威定义见 [04-gates.md](04-gates.md)。本文档聚焦各层的 DoR/DoD 质量标准和评分体系。

## 1. 各层质量标准

在每一层设置 Gate，防止问题流到下一层。对应 Gate 编号见 [04-gates.md](04-gates.md)。

### Goal Review（对应 G1: Goal Gate）

进入 Spec 前，检查 Goal 是否合格。

```text
- 是否说明了业务背景？
- 是否说明了目标用户？
- 是否是结果导向，而不是实现方案？
- 是否有成功指标？
- 是否有验收标准？
- 是否有范围边界？
- 是否写明 Non-goals？
- 是否有约束条件？
```

### Spec Review（对应 G2: Spec Gate）

进入 Matrix 前，检查 Spec 是否足够清晰。

```text
- 每条需求是否可实现？
- 每条需求是否可测试？
- 是否覆盖正常路径？
- 是否覆盖异常路径？
- 是否覆盖边界条件？
- 是否有安全要求？
- 是否有性能要求？
- 是否写明不做什么？
```

### Matrix Review（对应 G5: Task Gate 一部分）

进入 Tasks 前，检查覆盖关系。

```text
- 每个 Goal 是否有 Spec 覆盖？
- 每个 Spec 是否有 Task 覆盖？
- 每个验收标准是否有 Test 覆盖？
- 是否存在无来源 Task？
- 是否存在无测试关键需求？
- 是否存在重复任务？
- 是否存在范围膨胀？
```

### Task Review（对应 G5: Task Gate）

进入 Plan 前，检查任务是否可执行。

```text
- Task 是否足够小？
- Task 是否有明确输入？
- Task 是否有明确输出？
- Task 是否有完成标准？
- Task 是否有依赖关系？
- Task 是否能独立验证？
```

### Plan Review（对应 G4: Plan Gate）

进入 Prompt 前，检查执行顺序是否合理。

```text
- 是否先做基础能力？
- 是否先处理高风险任务？
- 是否有阶段性验证点？
- 是否有回滚方案？
- 是否避免阻塞依赖？
- 是否能增量交付？
```

### Prompt Review（对应 G6: Implementation Gate 一部分）

进入 Code 前，检查 Prompt 是否足够明确。

```text
- 是否包含 Goal？
- 是否包含 Task？
- 是否包含上下文？
- 是否包含约束？
- 是否包含输出格式？
- 是否包含验收标准？
- 是否包含测试要求？
- 是否写明禁止事项？
```

### Code Review（对应 G9: Review Gate）

最终交付前，检查代码是否真的满足目标。

```text
- 是否实现了对应 Task？
- 是否满足 Spec？
- 是否覆盖 Matrix 行？
- 是否有测试？
- 是否处理异常情况？
- 是否满足安全要求？
- 是否满足性能要求？
- 是否没有引入无关功能？
```

---

## 2. Definition of Ready / Definition of Done

> 各层 DoR/DoD 的权威定义见 [06-dod.md](06-dod.md)。本文档不重复定义。

---

## 3. 评分体系

### Goal 评分（满分 100）

> Goal 评分标准见 [02-goal-standard.md §8](02-goal-standard.md#8-goal-评分表)。

### Spec 评分（满分 100）

| 项目 | 分值 |
|------|-----:|
| 需求原子化 | 20 |
| 正常路径完整 | 15 |
| 异常路径完整 | 15 |
| 边界条件完整 | 15 |
| 安全/权限要求明确 | 15 |
| 性能/数据要求明确 | 10 |
| 验收标准可测试 | 10 |

### Prompt 评分（满分 100）

| 项目 | 分值 |
|------|-----:|
| 有明确任务来源 | 15 |
| 上下文充分 | 15 |
| 需求完整 | 20 |
| 约束明确 | 15 |
| 输出格式明确 | 10 |
| 测试要求明确 | 15 |
| 禁止事项明确 | 10 |

Prompt 低于 80 分，通常会导致 AI 输出不稳定。

---

## 4. 孤儿检查（Orphan Check）

| 类型 | 含义 | 说明 |
|------|------|------|
| Orphan Goal | 有 Goal，没有 Spec | 目标没有被需求化 |
| Orphan Spec | 有 Spec，没有 Goal | 需求没有业务价值来源 |
| Orphan Task | 有 Task，找不到 Spec/Goal | 可能是范围膨胀 |
| Orphan Code | 有代码，找不到 Task | 可能是未授权实现或过度设计 |
| Orphan Test | 有测试，找不到验收标准 | 测试可能在验证非目标行为 |

---

## 5. 质量指标

| 指标 | 推荐目标 |
|------|----------|
| Traceability Coverage | ≥ 95% |
| Acceptance Criteria Test Coverage | ≥ 90% |
| Orphan Task Rate | 0% |
| Orphan Code Rate | 0% |
| Critical Requirement Test Coverage | 100% |
| Prompt Rework Rate | 越低越好 |
| Post-release Critical Defects | 0 |

---

## 6. Release 前检查

```text
- Matrix 全部关键项为 Done
- P0/P1 测试全部通过
- 无权限绕过风险
- 无数据破坏风险
- 有日志和监控
- 有 Feature Flag 或回滚方案
- 有灰度策略
- 有上线后指标观察计划
```

---

## 7. 上线后 Goal 验证

真正的终点是验证 Goal 是否达成。

```text
Goal: GOAL-20260608-002 订单 CSV 导出

Expected Metrics:
- 报表整理时间 <= 5 分钟
- 单次 100,000 行导出 <= 30 秒
- 导出成功率 >= 98%

Observed Metrics:
- 报表整理时间: 6 分钟
- 单次 100,000 行导出: 24 秒
- 导出成功率: 97.2%

Result: 部分达成。
Gap: 导出成功率未达到 98%。
Follow-up: 新增重试机制作为 GOAL-20260615-001。
```
