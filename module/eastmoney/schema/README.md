# eastmoney 契约与 schema 说明

## 数据契约

1. 领域模型：`domain_macro`。
2. 事件字段最小集：`provider/dataset/series/period/observed_at/released_at/available_at/vintage_at/value/idempotency_key`。
3. 事件版本：`*.v1` 后缀强制。

## 传输契约

1. NATS：ingest/control plane。
2. Kafka：durable business event。
3. API：observation、revision、catalog、job status、admin trigger。

## 存储契约

1. `taos`：时间序列事实。
2. `postgres`：目录、日历、checkpoint、幂等账本。
3. `Redis`：缓存/锁/限流/短游标。
4. `clickhouse`：分析读模型与质量审计。
5. `oss`：raw 与审计快照。
