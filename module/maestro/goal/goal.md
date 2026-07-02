# maestro Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v1.0.0 |
| Layer | 决策域 · 工作流编排 |
| Status | Review |
| Last-Updated | 2026-06-16 |
| Source | [SPEC.md](./SPEC.md) |

## 目标

- DAG 工作流定义：节点（Task）和边（依赖关系）
- 任务类型：Strategy（策略信号）、Risk（风控检查）、Order（订单提交）、Wait（等待）、Condition（条件分支）、Parallel（并行执行）
- 状态机：PENDING → RUNNING → SUCCEEDED / FAILED / CANCELLED
- 错误恢复：Retry（带退避）、Fallback（降级路径）、Rollback（回滚已执行节点）
- 断点恢复：工作流中断后从最后成功节点恢复
- 多租户：多个工作流实例并发执行，资源隔离
- 全链路可观测：每个节点的输入/输出/耗时/状态
---

## 成功标准

参见 [TRACEABILITY.md](./TRACEABILITY.md) §1 FR 追溯表。

## 范围内

参见 [SPEC.md](./SPEC.md) §5 Non-goals（取反即为范围内）。

## 范围外

参见 [SPEC.md](./SPEC.md) §4 非目标。
