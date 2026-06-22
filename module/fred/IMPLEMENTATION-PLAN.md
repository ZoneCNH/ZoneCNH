# fred 实施计划

## 目标

把 `/home/fred` 从当前 Go 骨架和旧零存储 adapter 口径，推进到数据域 · 宏观独立 C/S 服务：共享基座组件、`domain_macro` 领域共享层、七类持久化介质、配置从 `sre/secrets/env/dev.md` 映射且不泄密。

## 约束

| ID | 约束 |
| -- | ---- |
| C-001 | 不在 `module/fred/` 或 `/home/fred` 提交任何 secret 值。 |
| C-002 | 不绕过共享基座组件直接实现配置、存储、消息队列或观测客户端。 |
| C-003 | `fred` 是独立服务；`macro_data` 是消费者或聚合器，不拥有 FRED provider 内部实现。 |
| C-004 | 旧 `Stores=None` 规则只能作为历史状态，不能阻止目标规格实现。 |
| C-005 | 每阶段完成后更新 [TRACEABILITY.md](TRACEABILITY.md) 状态和验证证据。 |

## 阶段 0：规格对齐

| 项 | 内容 |
| -- | ---- |
| 输入 | [goal.md](goal.md)、[SPEC.md](SPEC.md)、[TRACEABILITY.md](TRACEABILITY.md)、`/home/fred` 当前代码 |
| 任务 | 确认 C/S 边界、持久化职责、配置来源、旧零存储差异 |
| 输出 | 规格冻结、差异清单、实施 task 拆分 |
| 验证 | `rg "Stores=None|零存储" /home/fred module/fred` 输出被归档为迁移证据 |

## 阶段 1：配置与服务骨架

| 项 | 内容 |
| -- | ---- |
| 任务 | 用 `bootstrap` / `configx` 组装 `fred-server`，定义 dev 配置 key mapping，补齐 health/version/readiness |
| 任务 | 更新边界脚本：允许目标存储适配器，禁止绕过基座的直接驱动实现 |
| 输出 | `cmd/fred-server` 可启动，配置缺失时 fail fast |
| 验证 | `go test ./...`、配置 redaction 测试、`bash scripts/boundary-gates.sh` |

## 阶段 2：领域共享层映射

| 项 | 内容 |
| -- | ---- |
| 任务 | 读取并绑定 `domain_macro` 类型，定义 FRED DTO 到 MacroSeries / MacroObservation / MacroRelease / MacroRevision 的转换 |
| 任务 | 处理频率、单位、缺失值、时区、`released_at`、`available_at`、`vintage_at` |
| 输出 | 领域转换包和单元测试 |
| 验证 | `go test ./internal/client/... ./internal/domain/...`，no-lookahead fixture |

## 阶段 3：权威写入与读模型

| 介质 | 任务 |
| ---- | ---- |
| `oss` | raw response 归档、content hash、回放 manifest |
| `postgres` | series catalog、release calendar、job checkpoint、idempotency ledger |
| `taos` | observation / vintage 时间序列写入和查询 |
| `Redis` | rate bucket、distributed lock、hot series cache、cursor |
| `clickhouse` | 分析宽表、校验表、可重建 materialized view |

验证：对单个 series 运行 backfill，证明 raw、metadata、observation、cache、read model 均按职责写入。

## 阶段 4：事件与控制面

| 通道 | 任务 |
| ---- | ---- |
| `kafka` | 定义并发布 durable business events，接入 outbox / 幂等键 |
| `nats` | 定义 admin command、backfill trigger、reload signal、heartbeat |
| `contracts` | 为 API 和事件补齐版本、schema、兼容性检查 |

验证：重复 backfill 不产生重复副作用；Kafka 事件可重放，NATS command 不承担 durable business event 职责。

## 阶段 5：服务 API 与客户端

| 项 | 内容 |
| -- | ---- |
| API | `GetSeries`、`QueryObservations`、`StartBackfill`、`GetJobStatus`、`ScanRevisions`、`ReloadConfig` |
| Client | `pkg/fredx` 对外稳定 API，隐藏传输和服务端内部错误 |
| 验证 | client contract tests、server handler tests、兼容性 fixture |

## 阶段 6：验收与发布

| 项 | 内容 |
| -- | ---- |
| 测试 | 单元、契约、边界、集成、no-lookahead、回放一致性 |
| 文档 | 更新 traceability 状态、记录验证命令和证据 |
| 发布门禁 | 无 secret 泄露、旧零存储门禁已迁移、七类介质职责有测试证据 |

## 推荐任务拆分

| Task | 范围 | 依赖 |
| ---- | ---- | ---- |
| FRED-TASK-001 | 更新边界脚本与 bootstrap/configx 服务骨架 | 阶段 0 |
| FRED-TASK-002 | 实现 `domain_macro` 映射与 no-lookahead fixture | FRED-TASK-001 |
| FRED-TASK-003 | 实现 OSS/Postgres/TDengine 权威写入 | FRED-TASK-002 |
| FRED-TASK-004 | 实现 Redis/ClickHouse 读模型 | FRED-TASK-003 |
| FRED-TASK-005 | 实现 Kafka/NATS/contract 事件与控制面 | FRED-TASK-003 |
| FRED-TASK-006 | 补齐服务 API、client、端到端验收 | FRED-TASK-004, FRED-TASK-005 |

## 完成判定

只有当 [TRACEABILITY.md](TRACEABILITY.md) 中所有 FR / BR / AC / TC 从 `Planned` 更新为已验证状态，且 `/home/fred` 的测试、边界脚本和配置 redaction 检查通过，才能声明 `fred` 模块目标完成。
