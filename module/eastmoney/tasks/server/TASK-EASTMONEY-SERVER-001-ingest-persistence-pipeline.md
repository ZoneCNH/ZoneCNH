# TASK-EASTMONEY-SERVER-001 Ingest + Persistence Pipeline

## Scope

- NATS ingest 消费与幂等校验
- `taos/postgres/Redis/clickhouse` 写入主链
- Kafka durable event 发布

## Non-scope

- client 采集调度逻辑
- API 网关与外部权限平台对接
