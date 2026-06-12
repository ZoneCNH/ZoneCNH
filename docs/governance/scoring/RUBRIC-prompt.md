# Prompt 评分 Rubric

> 评分对象：`module/{module}/TASK-{MODULE}-{NNN}-PROMPT.md`
> 总分：100。每次评分对应一个 Task Prompt。

## 维度（满分 100）

| 维度                      | 满分   | 检查重点                                             |
| ------------------------- | ------ | ---------------------------------------------------- |
| 单 Task 聚焦              | 15     | Prompt 只服务一个 Task，无 scope 扩张                |
| 上下文引用完整            | 15     | 引用 Spec / Matrix / Task / Plan 路径与小节          |
| 可改文件范围              | 12     | 明确列出允许修改的文件路径                           |
| 禁止事项                  | 12     | 明确列出不可做的事（依赖、跨模块、重构等）           |
| 验收标准                  | 13     | 列出 AC ID 与可观察行为，可被 executor 自查          |
| 验证命令                  | 13     | 提供必跑命令（lint/test/build/race），含成功判定     |
| 证据回填要求              | 10     | 明确完成后需提交的产物（测试输出、覆盖率、文件清单） |
| Requirement/AC/TC ID 引用 | 10     | 显式引用 FR/AC/TC 编号                               |

## 阶段特定红线

- Prompt 服务多个 Task。
- Prompt 扩大 Task scope。
- 未引用 Requirement / AC / TC ID。
- 验证命令缺失或不可执行。
- 允许修改文件范围模糊（如"相关文件"）。
- 缺少证据回填要求。

## 通过门禁

`composite_score = min(四源评分)` 且 `composite_score >= 98`、无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内 → 进入 Code 阶段。
