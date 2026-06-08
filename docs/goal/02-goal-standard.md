# Goal 标准

## 1. Goal 结构公式

> **在什么时间内 + 针对什么对象/场景 + 达成什么结果 + 用什么指标衡量 + 达到什么标准**

简化：

> **Goal = 目标动作 + 结果对象 + 衡量指标 + 目标值 + 截止时间**

| 结构要素 | 说明                         | 示例          |
| -------- | ---------------------------- | ------------- |
| 时间     | 什么时候完成                 | 2026 年 Q3 前 |
| 对象     | 针对什么业务/人群/场景       | 新用户注册    |
| 动作     | 要提升、降低、完成、建立什么 | 提升          |
| 指标     | 用什么衡量结果               | 注册转化率    |
| 基准值   | 当前水平是多少               | 12%           |
| 目标值   | 要达到多少                   | 18%           |

## 2. SMART 原则

| 标准       | 含义       | 判断问题                  |
| ---------- | ---------- | ------------------------- |
| Specific   | 具体       | 是否明确说明要做什么？    |
| Measurable | 可衡量     | 是否有指标和数值？        |
| Achievable | 可实现     | 是否现实可达？            |
| Relevant   | 相关       | 是否和业务/项目目标有关？ |
| Time-bound | 有时间限制 | 是否有明确截止时间？      |

## 3. 推荐模板

> 在【时间】前，通过/针对【对象或场景】，实现【结果】，以【指标】衡量，达到【目标值】。

## 4. Goal 标准结构

```text
Goal =
  Context 背景
  + Objective 目标结果
  + Scope 范围
  + Success Metrics 成功指标
  + Acceptance Criteria 验收标准
  + Constraints 约束
  + Non-goals 非目标
```

简化一句话：

> 在【背景/场景】下，为【用户/业务对象】实现【目标结果】，使【关键指标】达到【目标值】，并满足【约束/验收条件】。

## 5. Goal 模板

```text
# Goal: 【目标名称】

## 1. Context
【为什么要做】

## 2. Objective
【最终要达成什么结果】

## 3. Scope
### In Scope
- 【包含内容 1】
- 【包含内容 2】

### Out of Scope
- 【不包含内容 1】
- 【不包含内容 2】

## 4. Success Metrics
- 【指标 1】：从 X 到 Y
- 【指标 2】：达到某个阈值

## 5. Acceptance Criteria
- Given 【前置条件】
  When 【用户/系统行为】
  Then 【期望结果】

## 6. Constraints
- 技术约束：
- 时间约束：
- 成本约束：
- 安全/合规约束：

## 7. Non-goals
- 本次不包含……
- 本次不解决……

## 8. Priority
【P0 / P1 / P2】

## 9. Deadline
【截止时间】

## 10. Downstream Mapping
- Spec: 【对应 Spec 文档】
- Matrix: 【对应追踪矩阵】
- Tasks: 【对应任务列表】
```

## 6. Goal 好坏对比

**不合格：**

```text
提升用户体验。
```

问题：太模糊，没有指标、目标值和时间。

**合格：**

```text
在 2026 年 Q3 前，将 App 首页加载时间从 3 秒降低到 1.5 秒以内，
并将首页满意度评分提升到 4.5/5。
```

**不合格（写成了方案）：**

```text
实现 Redis 缓存。
```

**合格（结果导向）：**

```text
将商品详情页 P95 响应时间从 1200ms 降低到 500ms 以内，
提升高峰期访问稳定性。
```

Redis 可以是后续 Plan 或 Code 里的实现方案，而不是 Goal 本身。

## 7. Goal 的 6 个质量标准

| 标准          | 说明                            |
| ------------- | ------------------------------- |
| Outcome-based | 写结果，不写具体做法            |
| Measurable    | 有指标或验收标准                |
| Scoped        | 有明确范围                      |
| Traceable     | 能追踪到 Spec、Task、Code、Test |
| Constrained   | 有约束和边界                    |
| Testable      | 最终能被测试或验收              |

## 8. Goal 评分表

| 项目       | 分值 | 判断标准                       |
| ---------- | ---: | ------------------------------ |
| 背景清晰   |   10 | 是否说明为什么做               |
| 目标明确   |   20 | 是否是结果，而不是方案         |
| 指标可衡量 |   20 | 是否有成功指标                 |
| 范围清晰   |   15 | 是否有 In Scope / Out of Scope |
| 验收明确   |   20 | 是否能判断完成                 |
| 约束完整   |   10 | 是否说明限制条件               |
| 优先级明确 |    5 | 是否知道重要程度               |

满分 100。合格线：≥ 80 可以进入 Spec，60-79 需要补充，< 60 不建议进入下游。

## 9. Goal Lint 规则

> Goal Lint 规则（G-LINT-001~007 及模糊词检查）见 [10-lint-rules.md §1](10-lint-rules.md#1-goal-lint)。

## 10. Goal 状态机

```text
Draft → Reviewed → Approved → In Progress → Validated / Partially Validated / Failed → Deprecated
```

| 状态                | 含义           |
| ------------------- | -------------- |
| Draft               | 初稿           |
| Reviewed            | 已评审         |
| Approved            | 可以进入 Spec  |
| In Progress         | 下游正在实现   |
| Validated           | 上线后指标达成 |
| Partially Validated | 指标部分达成   |
| Failed              | 目标未达成     |
| Deprecated          | 目标废弃       |

## 11. Goal 最小字段

```text
id, name, context, objective, success_metrics,
scope_in, scope_out, constraints, acceptance_criteria,
owner, priority, status
```
