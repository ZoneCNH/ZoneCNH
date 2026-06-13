# postgresx Goal

| 字段 | 内容 |
| ---- | ---- |
| 模块名 | `postgresx` |
| 发布目标 | v1.0.0 |
| 当前实现基线 | v1.0.0 release |
| 所属层级 | 基座 · PostgreSQL 存储扩展 |
| 稳定目标 | Public API、metrics contract、版本矩阵与 release evidence 已冻结 |
| 最后更新 | 2026-06-13 |
| 文档状态 | v1.0.0 已发布；v1.0 发布范围闭合，下游接入和生产 soak 作为 v1.x 成熟度证据跟踪 |

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

v1.0.0 发布收束已验证 `/home/postgresx`：

- `GOWORK=off VERSION=v1.0.0 make release-evidence-check` 通过。
- `GOWORK=off VERSION=v1.0.0 make release-final-check` 通过。
- `GOWORK=off VERSION=v1.0.0 make release-preflight` 在 `POSTGRESX_REQUIRE_INTEGRATION=1` 和注入的 dev PostgreSQL DSN/凭据下通过。
- Git tag / GitHub release：`v1.0.0`。

## 4. MUST / SHOULD / MAY

### MUST

- MUST 保持基座边界：不得依赖业务仓库、入口仓库或具体应用模块。
- MUST 由调用方显式传入 `Config`，模块不得自行读取环境变量、配置文件或 Secret 文件。
- MUST 所有外部 I/O 入口接受 `context.Context` 并尊重取消、超时。
- MUST 提供幂等 `Close`，关闭后拒绝查询和事务操作。
- MUST 事务只在 callback 返回 nil 时提交，其余路径回滚。
- MUST 迁移版本为正整数，重复版本、空名称、空 SQL 必须阻断。
- MUST 健康检查不泄露密码、完整 DSN 或 SQL 参数。
- MUST 保持已冻结的指标名、Go 版本矩阵和公开 API 文档一致。

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

## 7. v1.0 发布收束项与剩余风险

| 项目 | 当前状态 | 后续条件 |
| ---- | -------- | -------- |
| 指标命名 | 已冻结为 dotted `postgresx.*` contract | 指标变更必须同步代码、contract、SPEC、TRACEABILITY 和 release evidence |
| 版本矩阵 | `go.mod`、VERSION_MATRIX 与 release evidence 已统一到 go 1.25.0 | Go baseline 升级时同步所有发布门禁 |
| 公开 API 文档 | public API contract 已按 v1.0.0 代码面冻结 | 新增/删除公开符号必须补 contract 与 tests |
| 下游接入证据不足 | 尚未证明核心下游实际接入 | 作为非阻断风险记录，不降低 v1.0.0 发布评分 |
| 生产 soak 不足 | 尚无长期生产运行数据 | 作为 v1.x 运维证据继续积累 |

## 8. 验收标准

- `/home/postgresx` 中 `GOWORK=off VERSION=v1.0.0 make release-evidence-check`、`make release-final-check` 和强制 integration 的 `make release-preflight` 通过。
- 迁移、事务、健康检查、错误映射、Config 和 metrics hook 均有测试或 release evidence。
- `module/postgresx/TRACEABILITY.md` 覆盖全部 FR/BR，并映射到任务文档。
- `module/postgresx/SPEC.md` 不再包含旧 DSN option、无参构造器、旧健康检查入口或旧环境变量配置。
- `ARCHITECTURE.md` 中 `postgresx` 状态反映当前 v1.0.0 已发布基线。

## 9. 当前结论

`postgresx` 已完成 v1.0.0 发布收束，核心实现、契约文档、版本矩阵和发布证据已闭合。v1.0.0 发布范围综合评分为 100/100；下游实际接入和生产 soak 尚未形成证据，但作为 v1.x/post-release 成熟度跟踪项，不构成当前发布扣分。
