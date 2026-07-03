# TASK-BEA-SERVER-001：七介质落地与事件管线

- Status: Planned
- Owner: bea-server
- Depends-On: TASK-BEA-CLIENT-001
- Source: `spec/SPEC.md` §6、`spec/ACCEPTANCE.md`

## 目标

建立 `bea-server` 消费、幂等、权威存储写入、事件发布和可重建派生层闭环。

## Scope

1. NATS ingest/control 消费与命令处理。
2. Postgres checkpoint 与 idempotency ledger。
3. taos 时序事实写入；Kafka durable event 发布。
4. Redis 缓存/锁/限流；ClickHouse 读模型写入。
5. OSS raw 回放与失败补偿路径。

## Non-Scope

- 不实现可视化仪表盘前端。
- 不实现跨 provider 融合决策。

## 验收

- 多存储部分失败不推进 checkpoint。
- 回放流程可恢复一致性。
- NATS/Kafka 分层验证通过。

