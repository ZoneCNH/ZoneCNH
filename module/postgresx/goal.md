# postgresx Goal

| 字段 | 内容 |
| ---- | ---- |
| 模块名 | `postgresx` |
| 发布目标 | v1.0.0 |
| 当前实现基线 | v0.1.0 candidate |
| 所属层级 | 基座 · PostgreSQL 存储扩展 |
| 稳定目标 | Public API 待冻结；当前以 `/home/postgresx/pkg/postgresx` 为实现基线 |
| 最后更新 | 2026-06-12 |
| 文档状态 | 实现基线已对齐，v1.0 契约待冻结 |

## 1. Goal 定位

`postgresx` 的目标是为 ZoneCNH 模块提供一个小而稳定的 PostgreSQL 基座适配层：调用方显式传入配置，模块负责连接池、SQL 执行、事务、迁移、健康检查、错误归一化、Secret 脱敏和可观测 hook。

它的边界是 PostgreSQL 访问能力，不是 ORM、Repository 框架、应用生命周期容器或配置加载器。

## 2. 1.0 目标

- 稳定 `New(ctx, Config, ...Option)` / `Open(ctx, Config, ...Option)` 和 `Client` 方法契约。
- 稳定 `Config` 默认值、校验规则、DSN 构造和脱敏行为。
- 稳定 `Exec`、`Query`、`QueryRow`、`Rows`、`Row` 与 `Queryer` 抽象。
- 稳定 `WithTx` / `WithTxOptions` 的提交、回滚、context 取消和 panic 回滚语义。
- 稳定 `MigrationRunner` 的版本排序、幂等跳过和无效迁移阻断。
- 稳定 `foundationx.HealthChecker` 集成、池状态输出和安全元数据。
- 稳定 PostgreSQL 错误码到 `foundationx` 错误模型的映射。
- 稳定 logger/metrics 适配接口，冻结指标命名并确保不泄露 Secret。

## 3. 当前实现证据

`/home/postgresx` 当前实现已经包含：

- `pkg/postgresx/client.go`：`Client`、`New`、`Open`、`Ping`、`Close`、`Stats`、`Exec`、`Query`、`QueryRow`。
- `pkg/postgresx/config.go` 和 `dsn.go`：显式配置、默认值、DSN 和脱敏 DSN。
- `pkg/postgresx/tx.go`：`WithTx`、`WithTxOptions`、`TxOptions` 和 rollback/panic 处理。
- `pkg/postgresx/migration.go`：迁移排序、校验、执行和已应用记录。
- `pkg/postgresx/health.go`：`foundationx.HealthChecker` 兼容健康检查。
- `pkg/postgresx/errors.go`：context、no rows、认证、约束、序列化、连接类错误映射。
- `pkg/postgresx/options.go` 和 `metrics.go`：logger、metrics、clock 可插拔适配点。

team 审计已验证 `/home/postgresx`：

- `GOWORK=off go test ./...` 通过。
- `GOWORK=off go vet ./...` 通过。
- release evidence 中已有 `make ci`、race、secret scan、真实 PostgreSQL integration 与 migration 证据。

## 4. MUST / SHOULD / MAY

### MUST

- MUST 保持基座边界：不得依赖业务仓库、入口仓库或具体应用模块。
- MUST 由调用方显式传入 `Config`，模块不得自行读取环境变量、配置文件或 Secret 文件。
- MUST 所有外部 I/O 入口接受 `context.Context` 并尊重取消、超时。
- MUST 提供幂等 `Close`，关闭后拒绝查询和事务操作。
- MUST 事务只在 callback 返回 nil 时提交，其余路径回滚。
- MUST 迁移版本为正整数，重复版本、空名称、空 SQL 必须阻断。
- MUST 健康检查不泄露密码、完整 DSN 或 SQL 参数。
- MUST 在 v1.0 前统一指标名、Go 版本矩阵和公开 API 文档。

### SHOULD

- SHOULD 保持 API 小面，优先复用 `pgx` 和 `foundationx` 现有能力。
- SHOULD 对错误映射和 retryability 建立覆盖 PostgreSQL 常见 SQLSTATE 的测试。
- SHOULD 在发布证据中保留 `GOWORK=off`，避免本地 workspace 影响。

### MAY

- MAY 增加更多 metrics 标签，但不得加入高基数 SQL 文本或 Secret。
- MAY 为下游模块提供示例集成，但不得把下游依赖反向写入本模块。
- MAY 未来通过接口适配 `observex` 或 `resiliencx`，但不能形成硬运行时耦合。

## 5. 依赖关系与分层约束

| 类型 | 约束 |
| ---- | ---- |
| 必需依赖 | Go stdlib、`pgx/v5`、`foundationx` |
| 禁止依赖 | 业务域仓库、`x.go` 入口、具体服务模块 |
| 暂不硬依赖 | `kernel`、`configx`、`observex`、`resiliencx` |
| 下游关系 | 业务模块可以使用 `postgresx`，但 `postgresx` 不得反向依赖业务模块 |

## 6. 明确非目标

- 不替代 ORM 或业务 Repository。
- 不负责业务数据模型、索引、备份、容量和 DBA 流程。
- 不内置分页、排序、审计字段、租户隔离或批处理作为当前 v1.0 必交能力。
- 不默认拼接 SQL 或记录 SQL 参数。
- 不管理应用启动、停止或配置加载。

## 7. v1.0 发布阻断项

| 阻断项 | 当前状态 | 解除条件 |
| ------ | -------- | -------- |
| 指标命名未冻结 | 代码使用 underscore 名称，契约文档存在 dot 名称 | 选定唯一指标名并同步代码、contract、SPEC、TRACEABILITY |
| 版本矩阵漂移 | `go.mod` 与版本矩阵记录不一致 | 统一 Go baseline 并补充校验 |
| 公开 API 文档漂移 | contract 文档可能列出未实现符号 | 以代码为准重写 public API contract |
| 下游接入证据不足 | 尚未证明核心下游实际接入 | 作为非阻断风险记录，不提升为完成项 |

## 8. 验收标准

- `/home/postgresx` 中 `GOWORK=off go test ./...` 和 `GOWORK=off go vet ./...` 通过。
- 迁移、事务、健康检查、错误映射、Config 和 metrics hook 均有测试或 release evidence。
- `module/postgresx/TRACEABILITY.md` 覆盖全部 FR/BR，并映射到任务文档。
- `module/postgresx/SPEC.md` 不再包含旧 DSN option、无参构造器、旧健康检查入口或旧环境变量配置。
- `ARCHITECTURE.md` 中 `postgresx` 状态反映当前 v0.1.0 candidate，而不是“仅骨架”。

## 9. 当前结论

`postgresx` 已经具备 PostgreSQL 基座访问模块的核心实现，当前重点不是继续扩大能力面，而是冻结 v1.0 契约并清除文档漂移。综合评分为 82/100；剩余分数主要扣在指标名、版本矩阵和 public API contract 尚未完全一致。
