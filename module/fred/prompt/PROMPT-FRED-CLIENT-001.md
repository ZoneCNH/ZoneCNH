# PROMPT-FRED-CLIENT-001 — TASK-FRED-CLIENT-001 fred Collector + NATS Publish

> 本文件为管线 S5 Prompt 阶段产物（Context Packet），供 task-executor 执行 TASK-FRED-CLIENT-001 使用。
> 生成依据：`tasks/client/TASK-FRED-CLIENT-001-fred-collector.md`、`spec/SPEC.md`、`spec/SERIES-CATALOG.md`、`RULES.md`。

## 1. Task 目标与边界

**目标**：实现 `fred-client` 采集主链——按 root SPEC §5.1 完成 FRED v1 全端点矩阵拉取、分页重试、raw-first 归档与 NATS ingest 发布。

**Scope（必须做）**
- `internal/client/collector.go`：FRED v1 全端点矩阵六族（series/release/category/tag/source/update）拉取。
- `internal/client/scheduler.go`：周期调度与分片回补。
- `pkg/fredx/`：FRED API 客户端（分页、限流 30/120 req/min、退避重试）。
- raw-first OSS 归档路径（含 content_hash）。
- NATS ingest envelope 发布（含 schema version）。

**Non-Scope（禁止做）**
- `domain_macro` 归一化映射（属 TASK-FRED-CLIENT-002）。
- 写 taos/postgres/Redis/ClickHouse（属 fred-server）。
- 发布 Kafka downstream business events（属 fred-server）。
- 提供对外查询 API。

## 2. 依赖与输入

- 规格：`module/fred/spec/SPEC.md`（§5.1 端点矩阵、§10 持久化、§12 错误处理）
- 系列权威全集：`module/fred/spec/SERIES-CATALOG.md`（覆盖率分母 = FRED-native 序列，按 P0→P1→P2 推进）
- 命名规则：`module/fred/spec/SERIES-NAMING.md`
- 追溯矩阵：`module/fred/matrix/client/TRACEABILITY.md`（FR-C001~C006、C009）
- 规则：`module/fred/RULES.md`（§2 采集、§3 数据契约、§4 幂等、§5 写入顺序）
- 运行时仓库：`/home/workspace/fred`，依赖 `ossx`、`natsx`、`configx`、`resiliencx`、`observex`、`pkg/fredx`

## 3. 实现要求

- **全端点矩阵（RULES §2.1）**：必须覆盖六族全部端点；外部路由序列（`source_component` 标记）不计入 FRED API 采集覆盖率，但计入总覆盖审计。
- **raw-first（RULES §2.3）**：先写 OSS raw 路径（含 `content_hash`）成功，才允许发布 NATS envelope；OSS 路径格式 `{provider}/{endpoint}/{YYYY-MM-DD}/{job_id}/{content_hash}.json.gz`；违反顺序视为 bug 且必须有测试验证。
- **增量同步（RULES §2.4）**：携带 `realtime_start/realtime_end`；回拉最近 3 个月覆盖修订；游标存 Postgres checkpoint。
- **幂等键（RULES §4.1）**：五元组 `(series_id, vintage_at, observed_at, endpoint, job_id)`。
- **no-lookahead（RULES §3.2）**：时序填充 `observed_at/released_at/available_at/vintage_at` 四时间戳，`IsVisibleAt(t)` 保证 `t >= available_at`。
- **nats / kafka 分层职责（强制声明）**：client 侧**只发 NATS**（ingest handoff + control plane）；**严禁**在此 Task 发布 Kafka——Kafka durable business event 由 fred-server 在持久化后发布。
- **domain_macro 出域唯一性（强制声明）**：本 Task 处于采集层，**出域 NATS envelope 负载禁止承载 provider DTO**；归一化到 `domain_macro` 在 TASK-FRED-CLIENT-002 完成，此处 envelope 内部类型亦不得泄露 FRED 原始 DTO 到下游模块。

## 4. 验收命令

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

**期望输出**：collector 覆盖六族全部端点；raw-first 顺序由测试强制（先 OSS 后 NATS）；full sync 以 `1990-01-01` 为起点分片回补并输出覆盖快照/缺口分片；覆盖率分母 = SERIES-CATALOG FRED-native 序列。

## 5. 风险与回滚策略

- **风险**：端点矩阵遗漏导致覆盖率分母缺口；NATS 发布早于 OSS 写入破坏 raw-first 保证；限流超基线触发 429。
- **回滚**：client 为采集侧，写入仅 OSS（可重放）与 NATS（transient，可从 OSS 重放）；如回归，revert 分支并重跑全量回补即可，无不可逆副作用。
- **secret 红线**：仅引用 `sre/secrets/env/dev.md` 键名，禁止复制任何密钥值。
