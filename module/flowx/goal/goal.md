# flowx Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v1.0.0 |
| Layer | 分析域 · 数据流管线引擎 |
| Status | Docs Baseline Published |
| Last-Updated | 2026-06-17 |
| Source | [SPEC.md](./SPEC.md) |

## 目标

- 定义 DAG 数据流管线（Source → Transform → Window → Sink）
- 定义窗口类型：Tumbling、Sliding、Session
- 定义数据路由规则（按 symbol、exchange、dataType 分流）
- 定义背压策略：Block、Drop、Spill
- 定义管线状态可观测（lag、throughput、error rate）
- 管线支持热更新（不丢数据的前提下切换拓扑）
---

## 成功标准

参见 [TRACEABILITY.md](./TRACEABILITY.md) §1 FR 追溯表。

## 范围内

参见 [SPEC.md](./SPEC.md) §5 Non-goals（取反即为范围内）。

## 范围外

参见 [SPEC.md](./SPEC.md) §4 非目标。
