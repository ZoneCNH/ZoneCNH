# TASK-FRED-CLIENT-001 fred Collector + NATS Publish

## Objective

实现 `fred-client` 采集主链：按 root SPEC §5.1 完成 FRED v1 全端点矩阵拉取、分页重试、raw-first 归档与 NATS ingest 发布。

## Covers

- FR-003（全端点矩阵采集 + 分页限流重试，子规格: FR-C001, FR-C002）
- FR-006（raw-first OSS 归档，子规格: FR-C003）
- FR-011（NATS ingest handoff，子规格: FR-C005, FR-C006）
- FR-016（全量覆盖快照与缺口分片，子规格: FR-C009）
- BR-002（幂等键）
- BR-004（NATS/Kafka 分层，client 侧只发 NATS）
- BR-007（OSS 路径含 provider/endpoint/date/job_id/content_hash）
- BR-010（全端点矩阵交叉校验，覆盖率分母=SERIES-CATALOG FRED-native 序列）

## Scope

- `internal/client/collector.go`：全端点矩阵拉取
- `internal/client/scheduler.go`：周期任务调度与分片回补
- `pkg/fredx/`：FRED API 客户端（分页、限流 30/120 req/min、退避重试）
- raw-first OSS 归档路径（含 hash）
- NATS ingest envelope 发布（含 schema version）

## Non-Scope

- domain_macro 归一化映射（属 TASK-FRED-CLIENT-002）
- 不写 taos/postgres/Redis/ClickHouse（属 fred-server）
- 不发布 Kafka downstream business events（属 fred-server）
- 不提供对外查询 API

## Acceptance Criteria

1. collector 覆盖 root SPEC §5.1 的 FRED v1 全端点矩阵（series/release/category/tag/source/update 六族）。
2. raw-first 流程严格执行：先写 OSS raw（路径含 hash），再发布 NATS envelope。
3. NATS 发布失败可重试且可追溯（重试状态持久化）。
4. full sync 以默认 `1990-01-01` 为起点分片回补，输出覆盖快照与缺口分片；采集范围以 `spec/SERIES-CATALOG.md` 为权威全集，按 P0→P1→P2 顺序推进，覆盖率分母=目录 FRED-native 序列（不含外部路由序列）。
5. 增量同步按游标执行，回拉最近 3 个月覆盖修订数据，保留 `realtime_start/realtime_end`。

## Verification Commands

```bash
# 单元测试
cd /home/workspace/fred && go test ./internal/client/... -count=1
cd /home/workspace/fred && go test ./pkg/fredx/... -count=1

# 全量覆盖快照测试
cd /home/workspace/fred && go test ./internal/client/... -run FullCoverageSnapshot -count=1

# 限流/分页/重试专项
cd /home/workspace/fred && go test ./pkg/fredx/... -run RateLimit -v -count=1

# raw-first 归档路径验证
cd /home/workspace/fred && go test ./internal/client/... -run RawArchive -count=1
```

## Dependencies

- `ossx`（raw-first 归档）
- `natsx`（ingest envelope 发布）
- `configx`, `resiliencx`, `observex`
- `pkg/fredx`（FRED API 客户端）
