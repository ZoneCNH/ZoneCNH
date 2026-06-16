# TASK-MARKET-DATA-002 receiving-side validation

| 字段 | 值 |
| --- | --- |
| 状态 | Runtime Pending |
| 优先级 | P0 |
| 来源 | `module/market-data/SPEC.md` |
| 最后更新 | 2026-06-17 |

## 目标

在后续运行时阶段实现接收侧质量门禁、排序键检查和 outcome 可观测性，确保 Binance adapter 无法绕过 fail-closed 规则将脏数据交付下游。

> 当前任务文件是后续实现任务基线；SPEC v1.0.0 已 Approved，运行时实现待上游 Gate 通过后启动。

## 前置条件

- TASK-MARKET-DATA-001 已定义端口形态。
- `domain-market` `MarketEventEnvelope`、quality 与时间语义已冻结。

## 验收标准

> 以下 runtime checks 为后续实现门禁，不在本任务中声明已执行。

- stale、future、dirty quality 输入返回 DispatchReject。
- sourceSequence 倒退或不可恢复跳跃返回 DispatchReject。
- 临时背压或下游不可用返回 DispatchFailure，且 retryable=true。
- 指标维度覆盖 venue、productLine、channel、outcome、reason。
