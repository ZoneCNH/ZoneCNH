# PROMPT-FRED-SERVER-001 — TASK-FRED-SERVER-001 Ingest Persistence Pipeline

> 本文件为管线 S5 Prompt 阶段产物（Context Packet），供 task-executor 执行 TASK-FRED-SERVER-001 使用。
> 生成依据：`tasks/server/TASK-FRED-SERVER-001-ingest-pipeline.md`、`spec/SPEC.md`、`RULES.md`。

## 1. Task 目标与边界

**目标**：实现 `fred-server` ingest 主链——NATS 消费、幂等校验、checkpoint 状态机、多存储写入（raw-first OSS 已由 client 完成，此处从 Postgres checkpoint 起）、Kafka durable event 发布，以及 category/tag/source 图谱持久化。

**Scope（必须做）**
- `internal/server/handlers.go`：NATS envelope 消费与分发。
- `internal/server/bootstrap_store.go`：多存储初始化与写入顺序协调。
- `internal/server/memstore.go` + `internal/store/ports.go`：存储接口与 fake。
- Postgres：metadata/checkpoint 状态机（Created→InProgress→Completed，五元组幂等键）。
- TDengine：observation 时序写入。
- Redis：cache/lock/rate bucket（可重建层）。
- ClickHouse：分析读模型（可重建层）。
- Kafka：durable business event 发布（如 `MacroObservationUpserted`）。
- 六域覆盖审计基础数据写入（series/release/category/tag/source/updates）。

**Non-Scope（禁止做）**
- Query API 与 Admin API（属 TASK-FRED-SERVER-002）。
- ms_brain 集成契约（属 TASK-FRED-SERVER-002）。
- fred-client 采集逻辑；OSS raw 归档（由 fred-client 完成）。

## 2. 依赖与输入

- 规格：`module/fred/spec/SPEC.md`（§9 领域共享层、§10 持久化模型、§12 错误处理）
- 契约：`module/fred/design/DESIGN.md`、`module/fred/design/RUNTIME-MAPPING.md`
- 追溯矩阵：`module/fred/matrix/server/TRACEABILITY.md`（FR-S001~S007、S010、S011）
- 规则：`module/fred/RULES.md`（§1.2 存储分层、§4 幂等、§5 写入顺序、§3.2 no-lookahead）
- 运行时仓库：`/home/workspace/fred`，依赖 `postgresx`、`taosx`、`redisx`、`clickhousex`、`kafkax`、`natsx`

## 3. 实现要求

- **存储写入顺序（RULES §5，强制）**：严格按序
  1. Postgres checkpoint: Created → InProgress
  2. Postgres metadata 写入（幂等）
  3. TDengine observation 写入
  4. Redis cache 更新
  5. ClickHouse 写入
  6. Kafka durable event 发布
  7. Postgres checkpoint: InProgress → Completed
  任何步骤失败禁止继续下一步（仅允许 NATS 重试重消费）；Kafka 失败视为整体失败。
- **幂等键（RULES §4.1）**：五元组 `(series_id, vintage_at, observed_at, endpoint, job_id)`；相同五元组写入必须幂等，无重复副作用。
- **checkpoint 状态机（RULES §4.2）**：禁止跳过 InProgress 直接 Completed；InProgress 超时由 watchdog 重置为 Created。
- **存储分层（RULES §1.2）**：OSS raw 唯一原始副本（client 写）；Postgres/TDengine 权威；Redis/ClickHouse 可重建（清空后从权威重建）。
- **no-lookahead（RULES §3.2）**：写入 observation 必须填充四时间戳，`IsVisibleAt` 保证可见性语义。
- **nats / kafka 分层职责（强制声明）**：server 消费侧仅从 **NATS** 接收 ingest handoff + control plane；持久化成功后仅向 **Kafka** 发布 durable business event；二者职责严格分离，NATS 不替代 Kafka、Kafka 不替代 NATS。
- **domain_macro 出域唯一性（强制声明）**：对下游发布的 Kafka event 与后续 Query API 负载，必须转换为 `domain_macro` 标准类型（`MacroObservation` 等），**禁止**将 `pkg/fredx` FRED 原始 DTO 直接出域（RULES §3.1 G2）。

## 4. 验收命令

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

**期望输出**：写入顺序由测试强制（乱序视为失败）；重复五元组无副作用；Kafka event 与 NATS handoff 分层明确；Redis 清空后可由权威存储重建；六域审计计数可从 Postgres/ClickHouse 计算并可回放。

## 5. 风险与回滚策略

- **风险**：写入顺序错乱导致下游读到半成品；Kafka 发布早于 checkpoint Completed 破坏一致性；Redis/ClickHouse 重建路径未验证。
- **回滚**：权威层为 Postgres/TDengine/OSS，Redis/ClickHouse 可重建；如回归，revert 分支并触发 Redis/ClickHouse 重建即可，OSS raw 可重放全部 ingestion。
- **secret 红线**：仅引用 `sre/secrets/env/dev.md` 键名，禁止复制任何密钥值。
