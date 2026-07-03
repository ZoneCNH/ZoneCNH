# ecb server SPEC

- Parent: [../SPEC.md](../SPEC.md)
- Service: `ecb-server`
- Status: Draft

## 职责

1. 消费 NATS ingest envelope，执行 schema 与幂等校验。
2. 写入 `taos/postgres/Redis/clickhouse` 并维护 checkpoint。
3. 发布 Kafka durable event 给下游消费者。
4. 提供查询 API、作业管理 API、admin 控制面 API。

## 输入/输出

| 类型 | 说明 |
| ---- | ---- |
| 输入 | NATS ingest envelope、admin command |
| 输出 | 多存储事实、Kafka 事件、查询结果、作业状态 |

## 禁止事项

- 不直连 provider 做采集。
- 不保存 secret 原值。
- 不把 Redis/ClickHouse 视为唯一权威源。

