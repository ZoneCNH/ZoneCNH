# Goal Rubric

> 适用阶段：G1 Goal Gate
> 评分对象：`module/{module}/goal/goal.md` 或 `.config/goal/registry/goals.yaml` 中的 Goal 条目
> 权威标准：`docs/goal/02-goal-standard.md`、`docs/goal/04-gates.md` G1

## 维度表

| # | 维度 | 满分 | 检查项 |
|---|------|------|--------|
| 1 | SMART 合规 | 25 | Specific（具体）、Measurable（可衡量）、Achievable（可实现）、Relevant（相关）、Time-bound（有时限）各 5 分 |
| 2 | 业务背景 | 15 | 是否说明业务背景（5）、目标用户（5）、结果导向而非实现方案（5） |
| 3 | 成功指标 | 20 | 是否有可验证的成功指标（10）、指标有目标值（5）、指标有截止时间（5） |
| 4 | 验收标准 | 15 | 是否有验收标准（5）、P0/P1 AC 可测试（5）、覆盖正常/异常路径（5） |
| 5 | 范围边界 | 15 | 是否写明 Non-goals（5）、Non-goals 有理由（5）、约束条件明确（5） |
| 6 | 可追溯性 | 10 | Source Goal 可追溯到 Spec/Task（5）、Registry 已注册（5） |
| | **合计** | **100** | |

## 扣分规则

| 规则 ID | 触发条件 | 扣分 | 严重度 |
|---------|----------|------|--------|
| G-R-001 | 缺少业务背景 | -5 | MEDIUM |
| G-R-002 | 缺少目标用户 | -5 | MEDIUM |
| G-R-003 | 目标是实现方案而非结果 | -10 | HIGH |
| G-R-004 | 缺少成功指标 | -10 | HIGH |
| G-R-005 | 成功指标不可验证 | -5 | HIGH |
| G-R-006 | 缺少验收标准 | -10 | HIGH |
| G-R-007 | P0/P1 AC 不可测试 | -5 | HIGH |
| G-R-008 | 缺少 Non-goals | -5 | MEDIUM |
| G-R-009 | Non-goals 无理由 | -5 | MEDIUM |
| G-R-010 | 缺少约束条件 | -5 | MEDIUM |
| G-R-011 | Goal 未在 Registry 注册 | -5 | MEDIUM |
| G-R-012 | 缺少截止时间 | -5 | MEDIUM |

## 红线（redline = true，直接 FAIL）

| 红线 ID | 触发条件 |
|---------|----------|
| G-RL-001 | Goal 不符合任何 SMART 维度 |
| G-RL-002 | 缺少成功指标且缺少验收标准 |
| G-RL-003 | Goal 是实现方案描述而非业务目标 |

## 阈值映射

| 分数 | G1 裁决 |
|------|---------|
| ≥ 90 | PASS |
| 85-89 | PASS_WITH_RISK（需 risk 元数据） |
| < 85 | FAIL |
