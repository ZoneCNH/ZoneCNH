# TASK-FRED-SERVER-001 Ingest Persistence Pipeline

## Objective

实现 `fred-server` ingest 主链：NATS 消费、幂等校验、checkpoint、多存储写入（含 category/tag/source 图谱）、Kafka durable event 和覆盖审计基础数据。

## Covers

- FR-S001 ~ FR-S007, FR-S010, FR-S011
- BR-S002, BR-S003, BR-S004, BR-S006

## Acceptance Criteria

1. envelope 消费后按顺序完成校验、持久化、事件发布、checkpoint 推进。
2. 重复 payload 不产生重复副作用。
3. Kafka durable event 与 NATS handoff/control 分层明确。
4. 六域覆盖审计所需数据可计算并可回放。

## Dependencies

- `postgresx`, `taosx`, `redisx`, `clickhousex`
- `kafkax`, `natsx`
