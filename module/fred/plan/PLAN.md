# fred 实施计划

## 目标

把 `/home/workspace/fred` 从当前 Go 骨架和旧零存储 adapter 口径，推进到数据域 · 宏观独立 C/S 服务：

- `fred-client`：采集、归一化、NATS ingest 发布
- `fred-server`：消费、幂等、持久化、查询 API、Kafka fanout

并满足共享基座组件、`domain_macro` 领域共享层、七类持久化介质、`sre/secrets/env/dev.md` 配置映射且不泄密。

## 约束

| ID | 约束 |
| -- | ---- |
| C-001 | 不在 `module/fred/` 或 `/home/workspace/fred` 提交任何 secret 值。 |
| C-002 | 不绕过共享基座组件直接实现配置、存储、消息队列或观测客户端。 |
| C-003 | `fred-client` 与 `fred-server` 必须保持独立服务边界。 |
| C-004 | `nats` 负责 ingest/control，`kafka` 负责 downstream durable event，不可混用。 |
| C-005 | `domain_macro` 是对外领域语义唯一出口，不暴露 provider DTO。 |
| C-006 | 每阶段完成后更新 [matrix/TRACEABILITY.md](../matrix/TRACEABILITY.md) 状态和验证证据。 |

## 阶段 0：规格冻结与差异盘点

| 项 | 内容 |
| -- | ---- |
| 输入 | [goal/goal.md](../goal/goal.md)、[spec/SPEC.md](../spec/SPEC.md)、[matrix/TRACEABILITY.md](../matrix/TRACEABILITY.md)、`/home/workspace/fred` 当前代码 |
| 任务 | 对齐 C/S 边界、持久化职责、配置来源、旧零存储差异 |
| 输出 | 规格冻结、差异清单、实施 task 拆分 |
| 验证 | `rg "Stores=None|零存储" /home/workspace/fred module/fred` 输出归档为迁移证据 |

## 阶段 1：根骨架与门禁

| 项 | 内容 |
| -- | ---- |
| 任务 | 建立 `cmd/fred-client`/`cmd/fred-server` 双入口，统一 bootstrap/configx/observex 初始化 |
| 任务 | 更新 boundary gates：允许目标存储适配器，禁止绕过基座的直接驱动实现 |
| 输出 | 双服务可启动，配置缺失 fail-fast，边界脚本对齐目标架构 |
| 验证 | `go test ./...`、配置 redaction 测试、`bash scripts/boundary-gates.sh` |

## 阶段 2：client 子模块实现

| 项 | 内容 |
| -- | ---- |
| 任务 | 实现 FRED collector：按 `spec/SPEC.md` §5.1 全端点矩阵完成拉取、分页、限流、重试、错误分类 |
| 任务 | 首次全量按默认起点 `1990-01-01` 分片回补，后续按游标增量并回拉最近 3 个月修订窗口 |
| 任务 | 实现 multi-series batch 拉取、D->M/M->Q 聚合视图，并保留 `realtime_start/realtime_end` 版本维度 |
| 任务 | FRED DTO → `domain_macro` 映射，写 OSS raw，发布 NATS ingest envelope |
| 输出 | `internal/client` + `pkg/fredx` 契约稳定，具备可重放采集输入 |
| 验证 | `go test ./internal/client/... ./pkg/fredx/...` |

## 阶段 3：server 子模块实现

| 介质/子系统 | 任务 |
| ---- | ---- |
| `nats` | durable consumer + admin control（reload/backfill/pause/resume） |
| `postgres` | series catalog、release calendar、category/tag/source 图谱、job checkpoint、idempotency ledger |
| `taos` | observation / vintage 时间序列写入和查询 |
| `Redis` | rate bucket、distributed lock、hot series cache、cursor |
| `clickhouse` | 分析宽表、校验表、可重建 materialized view |
| `kafka` | durable business events（含 schema/version/idempotency key） |

验证：对单个 series 运行 backfill，证明 raw、metadata、observation、cache、read model、events 均按职责写入。

## 阶段 4：API 与下游契约

| 项 | 内容 |
| -- | ---- |
| API | `GetSeries`、`GetCategories`、`GetTags`、`GetSources`、`GetReleaseCalendar`、`QueryObservations`、`QuerySeriesUpdates`、`GetCatalogCoverage`、`StartBackfill`、`GetJobStatus`、`ScanRevisions`、`ReloadConfig` |
| 下游 | 为 `macro_data`、`ms_brain` 提供契约化查询/事件接口和 fixture |
| 验证 | contract tests、handler tests、兼容性 fixture、no-lookahead 回归 |

## 阶段 5：集成验收与发布前闭环

| 项 | 内容 |
| -- | ---- |
| 测试 | 单元、契约、边界、集成、no-lookahead、回放一致性 |
| 调度 | 日频每日、周频每周、月频/季频发布后 24h 内同步；release calendar trigger 优先 |
| 文档 | 更新 traceability 状态、记录验证命令和证据 |
| 发布门禁 | 无 secret 泄露、旧零存储门禁已迁移、七类介质职责有测试证据 |

## 推荐任务拆分

| Task | 范围 | 依赖 |
| ---- | ---- | ---- |
| TASK-FRED-001 | 根骨架、边界门禁与配置映射 | 阶段 0 |
| TASK-FRED-CLIENT-001 | client 采集与 NATS 发布 | TASK-FRED-001 |
| TASK-FRED-CLIENT-002 | domain_macro 映射与 no-lookahead fixture | TASK-FRED-CLIENT-001 |
| TASK-FRED-SERVER-001 | server 持久化与事件管线 | TASK-FRED-CLIENT-001 |
| TASK-FRED-SERVER-002 | API 与 `ms_brain` 契约输出 | TASK-FRED-SERVER-001, TASK-FRED-CLIENT-002 |

## 完成判定

只有当 [matrix/TRACEABILITY.md](../matrix/TRACEABILITY.md) 中所有 FR / BR / AC / TC 从 `Planned` 更新为已验证状态，且 `/home/workspace/fred` 的测试、边界脚本和配置 redaction 检查通过，才能声明 `fred` 模块目标完成。
