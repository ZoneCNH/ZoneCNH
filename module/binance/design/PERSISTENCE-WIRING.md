# module/binance PERSISTENCE-WIRING.md — Storage Assembly Contract

## Metadata

| Field | Value |
| --- | --- |
| Status | Active |
| Module-Version | v3.9.0 |
| Last-Updated | 2026-06-26 |
| Scope | `module/binance` 存储 writer 装配契约（G0 修复规范） |
| Spec-Impact | FR-005/006a-d/007/007a/010/011 从 Partial 推进到 Done 的装配基线 |
| Source | `cmd/binance-server/storage_env.go`（runtime HEAD `e549967`+） |

> [FRAME, HIGH] 本文档定义 binance-server 进程如何把存储 writer 从「代码存在」推进到「main 装配并真实落盘」。对应 G0（生产阻断项）。

## 1. Scope

[FRAME, HIGH] 本规范覆盖 5 个存储 infra（taosx/postgresx/redisx/clickhousex/ossx）在 `cmd/binance-server/main.go` 的装配契约：client 建连 → writer 构造 → ServerConfig 注入 → 幂等层替换 → lifecycle 收尾。

[FRAME, HIGH] 本规范不定义 writer 的内部实现（由 storage/cache/idempotency/olap 子包治理），不定义 infra client 的建连协议（由各 infra 仓治理）。

## 2. 装配契约

[COMPUTED, HIGH] 装配入口是 `storageFromEnv(ctx, bc *binancecfg.Config)`（storage_env.go），产出 `storageAssembly` 注入 ServerConfig：

| Writer | 构造函数 | 注入目标 | binancecfg 配置源 |
| --- | --- | --- | --- |
| TaosWriter | `storage.NewTaosWriter(client, {Database, EnsureStables:true})` | `ServerConfig.StorageWriter` | `bc.Taos` |
| PgCatalog | `storage.NewPgCatalog(pgClientAdapter{pgClient}, {AuditWrites:true})` | `ServerConfig.PostAcceptHooks` | `bc.Postgres` |
| HotCache | `cache.NewHotCache(redisClient, {})` | `ServerConfig.PostAcceptHooks` | `bc.Redis` |
| RedisStore | `idempotency.NewRedisStore(redisClient, WithDurableLog(pgLog), WithTTL(72h))` | `NewIngestServer` 第 2 参（替换 MemoryIdempotencyStore） | `bc.Redis` |
| OssArchiver | `storage.NewOssArchiver(ossStore, {KeyPrefix, Retention})` 经 `ossArchiveHook` batch 包装 | `ServerConfig.PostAcceptHooks` | `bc.OSS` |
| ClickHouse ETL | `olap.NewETL(chClient, stubAggSource{}, {Database, Interval:5m})` | 独立 goroutine `go etl.Run(ctx)` | `bc.ClickHouse` |

[COMPUTED, HIGH] Client 复用关系：`pgClient`（`*postgresx.Client`）同时供给 PgCatalog（经适配器）+ PostgresLog（满足 `postgresx.Queryer`）；`redisClient`（`*redisx.Client`）同时供给 HotCache + RedisStore。

## 3. Fail-Fast 契约（zbq/GitHub #80）

[FRAME, HIGH] 用户决策「全局严格」：生产路径 `cfg.StorageWriter == nil` 一律启动失败。

[COMPUTED, HIGH] fail-fast 边界：
- `validateStorageConfig(bc)` 在 Dial 前校验：`bc.Postgres.Password.IsZero()` 或 `bc.OSS.Bucket == ""` 立即报错
- smoke 模式（`XGO_BINANCE_SMOKE=1` 或 `MODE=test`）例外：返回 nil，走 RecordingSink + MemoryIdempotencyStore（供 cmd/binance-smoke 与测试）
- `StrictStorageWrite = true`：落库失败转 retryable reject（BNC-008），不静默跳过

[FRAME, HIGH] `internal/server/ingest.go:290` 的 `if s.storage == nil { return nil }` 守卫保留——单测路径直接构造 IngestServer 仍可 nil；生产路径经 storageFromEnv 不再传 nil。

## 4. SecretString 桥接

[COMPUTED, HIGH] binancecfg 用 `configx.SecretString`，各 infra client 类型不同。桥接规则（**严禁用 `.String()`——返回 `***` 遮蔽值**）：

| 目标类型 | 桥接方式 |
| --- | --- |
| 裸 string（taosx/redisx/clickhousex/ossx） | `bc.X.Password.Reveal()` |
| postgresx.SecretString | `postgresx.NewSecretString(bc.Postgres.Password.Reveal())` |

## 5. Evidence Gates

[FRAME, HIGH] G0 闭合的证据要求：

| Gate | 证据 |
| --- | --- |
| 装配存在 | `grep storageFromEnv cmd/binance-server/main.go` 命中 |
| Fail-fast | `storage_env_test.go` 覆盖 nil ctx / nil cfg / 缺密码 / 缺 bucket |
| 单测 | `go test ./cmd/binance-server/` 全绿 |
| 端到端落盘 | docker-compose 起 5 infra + 验证消息落 taosx（PENDING-LIVE-RUN，需真实 infra） |

## 6. 已知缺口（P2 跟踪）

[INFERRED, MED] ClickHouse ETL 的 `AggSource` 当前是 stub（FetchRecent 返回空）。真实实现需从 taosx 聚合 RawPoint，标注 TODO（FR-010 P2）。

## 7. Document Synchronization

[FRAME, HIGH] 本文档与 `SPEC.md` §11.2（infra 配置表）、`FEATURES.md` FR-005/006/007/010 状态、`TRACEABILITY.md` §1 追溯表同步。G0 闭合后这 9 行 FR 应从 Partial→Done。
