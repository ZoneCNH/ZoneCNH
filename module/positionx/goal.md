# positionx Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v0.1.0-draft |
| Layer | 执行域 · 仓位管理 |
| Status | Review |
| Last-Updated | 2026-06-16 |
| Source | [SPEC.md](./SPEC.md) |

## 目标

- 统一仓位视图：跨交易所、跨账户的净持仓
- 实时仓位更新：fill event → position update（< 10ms）
- 多维度 PnL：已实现/未实现、绝对值/百分比、含/不含手续费
- 仓位核对：交易所 API 持仓 vs 本地计算的差异报告
- 仓位快照：定时生成并推送至 observex 和 riskx
- 审计追踪：每次仓位变更记录原因（fill/transfer/adjustment）
---

## 成功标准

参见 [TRACEABILITY.md](./TRACEABILITY.md) §1 FR 追溯表。

## 范围内

参见 [SPEC.md](./SPEC.md) §5 Non-goals（取反即为范围内）。

## 范围外

参见 [SPEC.md](./SPEC.md) §4 非目标。
