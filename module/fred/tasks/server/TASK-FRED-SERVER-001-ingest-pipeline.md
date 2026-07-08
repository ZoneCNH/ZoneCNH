# TASK-FRED-SERVER-001 Ingest Persistence Pipeline

## Objective

实现 `fred-server` ingest 主链：NATS 消费、幂等校验、checkpoint 状态机、多存储写入（raw-first OSS 已由 client 完成，此处从 Postgres checkpoint 起）、Kafka durable event 发布，以及 category/tag/source 图谱持久化。

## Covers

- FR-004（backfill/incremental/revision scan + checkpoint 状态机，子规格: FR-S001, FR-S002, FR-S003）
- FR-007（TDengine observation 写入和查询，子规格: FR-S004）
- FR-008（Postgres metadata/idempotency/checkpoint，子规格: FR-S001~S003）
- FR-009（Redis cache/lock/rate bucket，子规格: FR-S005）
- FR-010（Kafka durable event stream，子规格: FR-S007）
- FR-011（NATS ingest handoff + control plane，server 消费侧，子规格: FR-S010）
- FR-012（ClickHouse analysis read model，子规格: FR-S006）
- BR-002（相同五元组写入幂等）
- BR-004（NATS/Kafka 职责分层，server 侧只发 Kafka）
- BR-005（Postgres checkpoint 成功推进前不得进入 completed）
- BR-006（Redis/ClickHouse 可重建）
- BR-007（OSS 路径含 hash，验证 raw-first 保证）
- BR-010（全量覆盖审计基础数据写入）

## Scope

- `internal/server/handlers.go`：NATS envelope 消费与分发
- `internal/server/bootstrap_store.go`：多存储初始化与写入顺序协调
- `internal/server/memstore.go` + `internal/store/ports.go`：存储接口与 fake
- Postgres：metadata/checkpoint 状态机（Created→InProgress→Completed，幂等键五元组）
- TDengine：observation 时序写入
- Redis：cache/lock/rate bucket（可重建层）
- ClickHouse：分析读模型（可重建层）
- Kafka：durable business event 发布（MacroObservationUpserted 等）
- 六域覆盖审计基础数据写入（series/release/category/tag/source/updates）

## Non-Scope

- Query API 和 Admin API（属 TASK-FRED-SERVER-002）
- ms_brain 集成契约（属 TASK-FRED-SERVER-002）
- fred-client 采集逻辑
- OSS raw 归档（由 fred-client 完成）

## Acceptance Criteria

1. envelope 消费后按严格顺序完成：Postgres checkpoint 推进 → TDengine 写入 → Redis 更新 → ClickHouse 写入 → Kafka event 发布（违反顺序视为 bug）。
2. 重复 payload（相同幂等键五元组）不产生重复副作用。
3. Kafka durable event 与 NATS handoff/control 分层明确，互不替代。
4. Redis 清空后可从 Postgres/TDengine 权威存储重建缓存（RedisRebuild 测试通过）。
5. 六域覆盖审计所需数据（series/release/category/tag/source/updates 六类计数）可从 Postgres/ClickHouse 计算并可回放。

## Verification Commands

```bash
# 幂等写入测试
cd /home/workspace/fred && go test ./internal/server/... -run Idempotency -count=1

# Redis 重建测试（本地 fake，不需要 dev secret）
cd /home/workspace/fred && go test ./internal/server/... -run RedisRebuild -count=1

# 存储接口单元测试
cd /home/workspace/fred && go test ./internal/store/... -count=1
cd /home/workspace/fred && go test ./internal/server/... -count=1

# 集成写入测试（需 dev secret，CI-gated）
cd /home/workspace/fred && FRED_DEV_CONFIG=/home/workspace/ZoneCNH/sre/secrets/env/dev.md \
  go test ./internal/integration/... -run PersistPipeline -count=1 -tags integration

# 全量覆盖审计基础数据（CI-gated）
cd /home/workspace/fred && FRED_DEV_CONFIG=/home/workspace/ZoneCNH/sre/secrets/env/dev.md \
  go test ./internal/integration/... -run FullCoverageAudit -count=1 -tags integration
```

## Dependencies

- `postgresx`（metadata/checkpoint）
- `taosx`（TDengine observation）
- `redisx`（cache/lock/rate bucket）
- `clickhousex`（分析读模型）
- `kafkax`（durable event）
- `natsx`（ingest handoff 消费）
