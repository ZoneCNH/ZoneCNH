# Tasks 评分 Rubric

> 评分对象：`module/{module}/tasks/TASK-*.md` 全集
> 总分：100。

## 维度（满分 100）

| 维度             | 满分   | 检查重点                                               |
| ---------------- | ------ | ------------------------------------------------------ |
| Task 模板符合度  | 12     | 遵循 `docs/governance/TASK-TEMPLATE.md` 结构，章节齐全 |
| 粒度合规         | 15     | ≤ 5 文件、≤ 3 FR、单模块、测试同体                     |
| spec_ref 闭合    | 15     | 每个 Task 显式引用 FR/BR ID，可回溯 Spec               |
| Scope/Non-scope  | 12     | 明确"做什么"与"不做什么"，禁止开放式描述               |
| 覆盖完整性       | 15     | 矩阵中所有 FR/BR 被至少一个 Task 覆盖                  |
| 依赖声明         | 10     | `Depends on` 字段明确，无循环依赖                      |
| 测试计划         | 10     | 每个 Task 有可执行 Test plan，引用 TC ID               |
| 优先级与文件清单 | 11     | P0/P1/P2 标注，Files likely to change 列出             |

## 阶段特定红线

- 任一 Task 无 spec_ref。
- 任一 Task 跨模块。
- 任一 Task 超 5 文件或 3 FR 上限。
- 实现与测试拆分到不同 Task。
- 存在矩阵未覆盖的 FR/BR。
- 存在循环依赖。
- Task 引入 Spec 外功能。

## 通过门禁

`composite_score = min(四源评分)` 且 `composite_score >= 98`、无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内 → 进入 Plan 阶段。
