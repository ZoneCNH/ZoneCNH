# eastmoney server 子模块规格

- Status: Draft
- Spec-Version: v0.1.0
- Last-Updated: 2026-07-04

## 职责

`eastmoney-server` 负责消费 NATS ingest envelope、执行幂等与 no-lookahead 校验、写多存储、发布 Kafka durable event 并提供查询 API。

## 关键需求

| ID | WHEN | THEN |
| -- | ---- | ---- |
| S-FR-001 | 消费 ingest | 校验 schema、幂等键、时间语义。 |
| S-FR-002 | 校验通过 | 写 `taos/postgres/Redis/clickhouse`。 |
| S-FR-003 | 业务事实确认 | 发布 Kafka durable event。 |
| S-FR-004 | 接收查询 | 提供 observation/revision/catalog/job API。 |
| S-FR-005 | 执行回补 | 支持历史全量、增量同步和修订回拉。 |

## 边界

禁止直连 provider 采集；禁止写入 secret 值；禁止把 Redis/ClickHouse 作为唯一权威源。
