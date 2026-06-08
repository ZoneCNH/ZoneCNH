# Plan 评分 Rubric

> 评分对象：`specs/{module}/IMPLEMENTATION-PLAN.md`
> 总分：100。

## 维度（满分 100）

| 维度 | 满分 | 检查重点 |
|------|------|----------|
| 执行顺序合理性 | 15 | 依赖拓扑正确（contracts → model → service → ui → integration → tests） |
| 依赖关系完整 | 12 | 每个 Task 的前置/阻塞清晰，无悬空依赖 |
| 文件范围 | 12 | 每个 Task 列出目标文件，不与其他 Task 重叠冲突 |
| 验证命令 | 15 | 每个 Task 提供可执行验证命令（lint/test/build） |
| 风险识别 | 13 | 高风险点清楚标注，含技术风险与 spec 模糊点 |
| 回滚策略 | 10 | 每个高风险 Task 有回滚或修复路径 |
| 估算与里程碑 | 8 | 任务规模或时间估算合理 |
| 与 Spec/Matrix 一致 | 15 | 不跳过 Task，不引入 Spec 外内容，不跨模块 |

## 阶段特定红线

- 计划中存在 Spec/Matrix 之外的 Task。
- 跳过前置依赖 Task。
- 计划跨模块。
- 高风险 Task 无回滚路径。
- 任一 Task 无验证命令。
- 文件范围互相冲突未协调。

## 通过门禁

`composite_score = min(三平台评分)` 且 `composite_score >= 98`、无红线、无低置信度、分差在阈值内 → 进入 Prompt 阶段。
