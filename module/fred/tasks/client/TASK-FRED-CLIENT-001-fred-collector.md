# TASK-FRED-CLIENT-001 fred Collector + NATS Publish

## Objective

实现 `fred-client` 采集主链：按 root SPEC §5.1 完成 FRED v1 全端点矩阵拉取、分页重试、raw-first 归档与 NATS ingest 发布。

## Covers

- FR-C001, FR-C002, FR-C003, FR-C005, FR-C006
- BR-C002, BR-C004

## Acceptance Criteria

1. collector 能覆盖 root SPEC §5.1 的 FRED v1 全端点矩阵。
2. raw-first 流程严格执行：先写 OSS raw，再发布 NATS envelope。
3. NATS 发布失败可重试且可追溯。
4. full sync 以默认 `1990-01-01` 为起点分片回补，并可输出覆盖快照与缺口分片。
5. 增量同步按游标执行，且每次回拉最近 3 个月覆盖修订数据。
6. 采集结果保留 `realtime_start/realtime_end` 版本维度，并支持批量采集与 D->M/M->Q 聚合视图。

## Dependencies

- `ossx`
- `natsx`
- `configx`, `resiliencx`, `observex`
