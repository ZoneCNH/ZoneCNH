# PROMPT-ORDX-001
- Task：[../tasks/](../tasks/) | Trace：[../TRACEABILITY.md](../TRACEABILITY.md) | Spec：[../SPEC.md](../SPEC.md)
## 任务
实现 orderx 订单抽象层：Order 生命周期管理、多交易所订单适配、执行报告处理。
## 要点
1. Order 状态机（domainx OrderState 流转）
2. 多交易所适配（抽象交易所差异）
3. ExecutionReport 映射与错误分类
