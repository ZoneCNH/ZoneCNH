# ecb-server 实施计划

- Last-Updated: 2026-07-04
- Parent Plan: [../PLAN.md](../PLAN.md)
- Spec: [../../spec/server/SPEC.md](../../spec/server/SPEC.md)

## 阶段拆分

1. P1 消费骨架：NATS consumer、schema 校验、幂等键校验。
2. P2 持久化主链：taos/postgres 写入、checkpoint/ledger。
3. P3 派生层：Redis 热缓存、ClickHouse 读模型。
4. P4 事件输出：Kafka durable events + outbox。
5. P5 API：查询/回补/admin 接口与审计日志。
6. P6 闭合：端到端回放、修订窗口、no-lookahead 验证。

