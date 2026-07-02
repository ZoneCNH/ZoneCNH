# strategyx Goal

## 元数据

| 字段 | 值 |
| --- | --- |
| Target | v1.0.0 |
| Layer | 决策域 · 策略工厂 |
| Status | Review |
| Last-Updated | 2026-06-16 |
| Source | [SPEC.md](./SPEC.md) |

## 目标

- 统一策略接口：所有策略实现相同的 Strategy 接口
- 策略注册表：按名称发现和加载策略
- 参数管理：可配置参数 + 运行时热更新
- 版本管理：策略变更可追溯、可回滚
- 信号输出：标准化信号格式（symbol, side, qty, confidence, reason）
- 策略组合：多策略信号合并、冲突解决、资金分配
---

## 成功标准

参见 [TRACEABILITY.md](./TRACEABILITY.md) §1 FR 追溯表。

## 范围内

参见 [SPEC.md](./SPEC.md) §5 Non-goals（取反即为范围内）。

## 范围外

参见 [SPEC.md](./SPEC.md) §4 非目标。
