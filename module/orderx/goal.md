# orderx Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v1.0.0 |
| Layer | 执行域 · 订单引擎 |
| Status | Review |
| Last-Updated | 2026-06-16 |
| Source | [SPEC.md](./SPEC.md) |

## 目标

- 统一订单状态机：NEW → PENDING → PARTIAL → FILLED / CANCELLED / REJECTED / EXPIRED
- 订单路由：根据 symbol、exchange、liquidity 选择最优执行场所
- 智能路由（SOR）：大订单自动拆分为多个子订单
- 订单审计轨迹：每次状态变更记录完整上下文
- 撤单/改单统一接口：屏蔽交易所 API 差异
---

## 成功标准

参见 [TRACEABILITY.md](./TRACEABILITY.md) §1 FR 追溯表。

## 范围内

参见 [SPEC.md](./SPEC.md) §5 Non-goals（取反即为范围内）。

## 范围外

参见 [SPEC.md](./SPEC.md) §4 非目标。
