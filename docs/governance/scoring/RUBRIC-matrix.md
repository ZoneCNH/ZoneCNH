# Matrix 评分 Rubric

> 评分对象：`module/{module}/TRACEABILITY.md`
> 总分：100。

## 维度（满分 100）

| 维度         | 满分   | 检查重点                                                    |
| ------------ | ------ | ----------------------------------------------------------- |
| 表结构完整性 | 15     | 列齐全（FR/Desc/AC/TC/Task/Status），表头规范，状态标记合法 |
| FR 覆盖闭合  | 20     | Spec 中每条 FR/BR 在矩阵中存在，无遗漏                      |
| AC 闭合      | 15     | 每条 FR 至少 1 个 AC，每个 AC 可验证                        |
| TC 闭合      | 15     | 每条 AC 至少 1 个 TC，TC 编号唯一                           |
| 反向追溯     | 10     | 每个 TC 映射回 ≥1 个 FR/BR，无野生 TC                       |
| Task 映射    | 10     | 每条 FR 已分配 Task 或显式标记未分配                        |
| BR/NFR 覆盖  | 8      | BR 有违反后果验证，NFR 有度量验证手段                       |
| 编号一致性   | 7      | 编号格式统一，无重复、无跳号未说明                          |

## 阶段特定红线

- TRACEABILITY.md 缺失或为空。
- 存在无 AC 的 FR（盲区）。
- 存在无 TC 的 AC（验证缺失）。
- 存在无 FR 支撑的 TC（范围蔓延）。
- 矩阵 FR 集合与 SPEC.md FR 集合不一致。
- 引用了不存在的 Task ID。

## 通过门禁

`composite_score = min(四源评分)` 且 `composite_score >= 98`、无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内 → 进入 Tasks 阶段。
