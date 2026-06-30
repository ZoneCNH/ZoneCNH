# TASK-DEC-001 开发 Prompt

- 上游 Task：[tasks/](../tasks/)
- 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
- 权威 Spec：[SPEC.md](../SPEC.md)

## 任务

实现 decimalx 高精度数学库：Decimal 类型、算术/比较/序列化。

## 关联需求

FR-001~007（Decimal 构造/算术/比较/序列化/精度控制/性能基准）。

## 实现要点

1. 不可变 Decimal 类型（copy-on-write）
2. Add/Sub/Mul/Div 精确计算
3. JSON/Marshal/Unmarshal 序列化
4. 无第三方依赖（stdlib only）
