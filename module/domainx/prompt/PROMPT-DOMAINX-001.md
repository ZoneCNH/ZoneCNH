# PROMPT-DOMAINX-001

- Task：[../tasks/](../tasks/)
- Trace：[../TRACEABILITY.md](../TRACEABILITY.md)
- Spec：[../SPEC.md](../SPEC.md)

## 任务

实现 domainx 交易领域模型：Order/OrderState/Trade/Position/ExecutionReport/Portfolio。

## 关联需求

FR-001~008（Order/Trade/Position/ExecutionReport/Portfolio/序列化/不可变性）。

## 要点

1. 值对象不可变（私有字段+getter，无公开 setter）
2. OrderState 合法流转表
3. Position.avgPrice 加权均价更新
4. JSON snake_case + decimal 字符串 + RFC3339 时间
