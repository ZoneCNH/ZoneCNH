# 质量门禁

> Gate 体系（G0-G11）的权威定义见 [04-gates.md#gate-类型](04-gates.md#1-gate-类型)。本文档聚焦各层的 DoR/DoD 质量标准和评分体系。

## 1. 各层质量标准

各 Gate 的具体检查项见 [04-gates.md §3](04-gates.md#3-必备-gates)。

---

## 2. Definition of Ready / Definition of Done

> 各层 DoR/DoD 的权威定义见 [06-dod.md#goal-dor--dod](06-dod.md#1-goal-dor--dod)。本文档不重复定义。

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

> Release 前检查清单（SSOT）见 [04-gates.md G10 Release Gate](04-gates.md#g10-release-gate)。

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
