# eastmoney-server 实施计划

- Last-Updated: 2026-07-04
- Parent Plan: [../PLAN.md](../PLAN.md)
- Spec: [../../spec/server/SPEC.md](../../spec/server/SPEC.md)

## 阶段拆分

1. **P1 消费骨架**：NATS consumer、schema 校验、幂等键检查。
2. **P2 持久化主链**：`taos` 时序、`postgres` 账本/checkpoint、`Redis` 缓存。
3. **P3 事件与读模型**：Kafka durable event、`clickhouse` 分析读模型。
4. **P4 API 与回补**：query/admin API、历史全量与增量修订回拉。
5. **P5 集成闭环**：no-lookahead、重放、故障注入、边界门禁。

## 完成判定

- `matrix/server/TRACEABILITY.md` 覆盖项可追溯。
- S-TC-001~S-TC-005 全部通过。
- NATS/Kafka 分层与 checkpoint 顺序验证通过。
