# postgresx

## 1. 模块定位
ZoneCNH 基座层 PostgreSQL 访问模块（Layer L2 基础设施适配器），围绕 `pgx/v5` 提供连接池、SQL 执行、事务、迁移、健康检查和错误归一化。Status=Approved，Module-Version v1.0.0（已发布，Spec v1.0.0，2026-06-13）。非 ORM，直接暴露 SQL 能力。

## 2. 生产职责
- FR-001：`Config` 校验 + `pgxpool` 连接池生命周期（`New`/`Open`/`Close` 幂等，初始 Ping 失败关闭池）。
- FR-002：`Exec`/`Query`/`QueryRow` SQL 执行，保留 context 语义。
- FR-003：`WithTx`/`WithTxOptions` 事务边界（nil 提交，error/ctx 取消/panic 回滚）。
- FR-004：`MigrationRunner.Up` 版本化迁移（升序执行、重复版本阻断）。
- FR-005：`HealthChecker`（Name/Check）与 `Stats` 池快照。
- FR-006：`MapError`/`IsRetryable` 错误归一化与可重试判断。
- FR-007：`WithLogger`/`WithMetrics`/`WithClock` 可插拔观测适配 + Secret 脱敏。

## 3. 边界定义
- 不读环境变量/配置文件/Secret 文件；Secret 只由调用方显式传入 `Config.Password`（SecretString）。
- 不依赖业务域、入口仓库、数据域仓库或 `x.go`（BR-001）。
- 不内置 `observex`/`resiliencx`/`configx` 运行时耦合；集成必须通过接口适配（BR-002）。
- 所有外部 I/O 入口接受 `context.Context`，尊重取消与超时（BR-004）。

## 4. 不负责什么
- 不做 ORM、Repository 生成器、SQL builder 或实体映射（SPEC §4）。
- 不做读写分离、集群管理、备份恢复、容量治理。
- 不接管 `kernel` 生命周期；调用方负责自身生命周期中调用 `New`/`Close`。
- 不承诺分页、排序、审计字段、租户隔离或批处理工具进入 v1.0 基线。

## 5. 架构位置
基座层（L2 存储扩展）。依赖方向：仅依赖 Go stdlib + `github.com/jackc/pgx/v5`（v5.9.2）+ kernel。被 `market_data`/`signal-engine`/`order_engine`/`risk_engine`/`backtest_engine` 等通过 `pkg/postgresx` 显式构造客户端消费。禁止反向依赖业务域。

## 6. 生命周期
- `New`/`Open`：校验 Config → 填充默认值 → 构造 pgxpool → 初始 Ping（失败则关闭池）。
- `Close(ctx)`：幂等关闭连接池；关闭后查询/事务入口返回 `ErrClosed`（FR-001）。
- 事务生命周期由 `WithTx` 的 `fn` 返回值驱动；panic 路径先回滚再重新抛出（FR-003）。
- `HealthChecker.Check` 输出 healthy/degraded/unhealthy + 耗时，幂等无副作用（FR-005）。

## 7. 标准目录结构
```text
postgresx/
├── go.mod / go.sum / README.md / CHANGELOG.md / VERSION_MATRIX.md / Makefile
├── pkg/postgresx/
│   ├── client.go       # Client + New/Open/Close/Ping/Stats
│   ├── config.go       # Config + DSN/RedactedDSN + defaults
│   ├── query.go        # Exec/Query/QueryRow + Queryer/Row/Rows
│   ├── tx.go           # WithTx/WithTxOptions + TxFunc/TxOptions
│   ├── migration.go    # MigrationRunner + Migration/MigrationSource
│   ├── health.go       # HealthChecker (Name + Check)
│   ├── errors.go       # MapError/IsRetryable + 错误常量
│   ├── metrics.go      # Logger/Metrics hooks
│   ├── options.go      # Option/WithLogger/WithMetrics/WithClock
│   └── *_test.go
├── internal/testutil/  testdata/  examples/  docs/
```

## 8. 配置规范
显式 `Config` 结构体（不读环境变量）。关键字段：Host、Port(5432)、Database、User、Password(SecretString 自动脱敏)、SSLMode(disable)、MaxOpenConns(10)、MinIdleConns(1)、MaxConnLifetime(1h)、MaxConnIdleTime(30m)、ConnectTimeout(5s)、HealthTimeout(2s)、ApplicationName。`Config.DSN()` 与 `Config.RedactedDSN()` 分别返回完整/脱敏连接串。

## 9. 错误模型
typed error + retryability 二元化。公共错误：`ErrClosed`/`ErrInvalidConfig`/`ErrMigrationDuplicate`/`ErrMigrationInvalid`。`MapError` 映射：context.Canceled→ErrCanceled、pgx.ErrNoRows→ErrNotFound、pgconn 认证→ErrAuth、约束冲突→ErrConstraint、连接断开→ErrConnection(可重试)。消息格式 `"postgresx: <operation>: <detail>"`。

## 10. 日志规范
模块只暴露 `WithLogger(logger Logger)` hook，不绑定具体后端；遵循 observex 全局规范。事件覆盖查询、事务、迁移、健康和池状态。SQL 参数不得进入默认日志字段；调用方自定义 logger 记录参数时责任在调用方侧（FR-007、SPEC §18）。

## 11. Metrics 规范
通过 `WithMetrics(metrics Metrics)` hook 注入；指标命名已由 TASK-PG-003 冻结为 dotted `postgresx.*`，后续变更必须同步代码/contract/SPEC/TRACEABILITY。指标字段不得包含明文 DSN、密码或 SQL 参数 Secret（BR-009）。

## 12. Tracing 规范
SPEC 未定义独立 Trace span 约定；通过 `WithLogger`/`WithMetrics` 适配点由调用方接入 observex tracer。遵循 observex 全局 span 规范（SPEC未细化）。

## 13. Reliability 规范
- 事务只在 `fn` 返回 nil 时提交；error、ctx 取消、panic 路径必须回滚（BR-006）。
- 迁移版本正整数且单调执行；重复/非正/空名称/空 SQL 阻断（BR-007）。
- 查询/事务 helper 不隐藏 context deadline，不引入无界 retry（SPEC §16）。
- 无模块内置 retry/circuit breaker；重试策略由上层 `resiliencx` 组合。

## 14. Security 规范
- Secret 只来自调用方显式配置，禁止读环境变量/文件（BR-002、SPEC §18）。
- 日志/错误/健康检查/指标字段必须用脱敏 DSN 或安全标签；错误归一化不得泄露认证材料。
- 健康检查幂等无副作用，只输出安全元数据（BR-008）。

## 15. Performance SLO
v1.x 性能预算（Deferred，SPEC §16 + NFR-001..005）：单次 Exec < 10ms、InsertBatch 100 行 < 50ms、单次 Query < 10ms、连接池获取 < 1ms、常驻内存（空闲）< 5MB。v1.0.0 未声明 benchmark SLO；新增性能声明须补可复现 benchmark 或 live PostgreSQL evidence。

## 16. 测试标准
TC-001..TC-009 覆盖 Config、SQL 执行、事务（含 panic 回滚）、Migration、Health/Stats、MapError、Logger/Metrics hooks、GOWORK=off 发布证据、契约一致性。验收 AC-PGX-001..007（ACCEPTANCE §2）。NFR-006 单测覆盖率 ≥ 80%、NFR-007 race 零检出、NFR-008/009/010 vet/lint/gitleaks 通过。

## 17. Chaos 标准
SPEC 未定义模块级 chaos 矩阵；依赖上层 `resiliencx` 与 kernel 生命周期处理连接断开、池耗尽、panic 等场景（遵循 README chaos 全局规范）。模块层验证：连接池耗尽阻塞等待→超时返回错误、事务 panic 回滚、Close 幂等。

## 18. Contract 标准
公开 API 以 `github.com/ZoneCNH/postgresx/pkg/postgresx` 为准：`New(ctx, cfg, opts...)`、`Client` 方法集（Ping/Close/Stats/Queryer/Exec/Query/QueryRow/WithTx/WithTxOptions）、`Queryer`/`Row`/`Rows`/`Tx`/`TxFunc`/`TxOptions` 接口、`Migration`/`MigrationSource`/`MigrationRunner`、`Option`（WithLogger/WithMetrics/WithClock）。v1.0.0 Public API 已冻结。

## 19. CI Gate
- `GOWORK=off VERSION=v1.0.0 make release-evidence-check` / `release-final-check` / `release-preflight`（含强制真实 PostgreSQL integration）。
- 覆盖 go vet、go test、go test -race、边界检查、contract check、secret scan、template alignment。
- 文档侧：`rg` 不再出现旧 DSN option/环境变量式 DSN/无参构造器；TRACEABILITY 覆盖 FR-001..007 与 BR-001..012；`git diff --check` 通过。

## 20. Release Gate
ACCEPTANCE §5 发布 DoD：SPEC 保持 23 节 semver、TRACEABILITY 覆盖 FR/BR/TC 并映射 TASK-PG-001..003、runtime release-evidence-check/final-check/preflight 通过、本仓库 `git diff --check` + 状态一致性 + postgresx 规格 lint + traceability 检查通过。v1.0.0 tag/GitHub release 已发布（commit 310a249e）。

## 21. Versioning
semver。v1.0.0 Public API 已冻结；v1.x 破坏性变更必须同步 SPEC/TRACEABILITY/Task/contracts/release evidence，不重新打开已关闭的 v1.0 阻断项。Release evidence 必须支持 `GOWORK=off`（BR-011）。Go baseline go 1.25.0、pgx v5.9.2。

## 22. 兼容性策略
下游只允许依赖已实现的 `pkg/postgresx` 入口。未来 v1.x 破坏性变更须同步全链文档；`x.go` 或业务模块接入前必须新增追溯证据，不能把潜在消费者计入完成度。Config Host 为空→`ErrInvalidConfig`、ctx 取消→尽快停止、Close 多次→幂等、查询空结果→ErrNotFound（SPEC §12）。

## 23. Failover 策略
连接断开/池耗尽→`ErrConnection`（可重试，调用方或 resiliencx 决定重试）；ctx 超时→`ErrTimeout`；Close 幂等。模块不内置自动重连或故障转移策略，由 pgxpool 内部行为 + 上层组合实现（SPEC §11、§12）。

## 24. Backpressure 策略
连接池耗尽时阻塞等待空闲连接，超时（ConnectTimeout/HealthTimeout）后返回错误。`MaxOpenConns`/`MinIdleConns` 默认 10/1，可由调用方覆盖。`Rows` 逐行迭代，调用方负责 `Close`，避免连接泄漏（BR-005、SPEC §12）。

## 25. 审计要求
`WithLogger`/`WithMetrics` 记录查询、事务、迁移、健康和池状态事件；迁移执行记录版本、名称和执行时间（FR-004）。审计字段不得包含明文 DSN/密码/SQL 参数（SPEC §17）。日志/错误归一化保留稳定 operation 名用于追溯。

## 26. 熵减规则
全局：禁止 util dumping、hidden abstraction、cyclic dependency。模块特有（BR-001/002/003）：不依赖业务域、不读环境变量、不实现 ORM/schema ownership/全局默认数据库；新增基座依赖必须先更新 goal/TRACEABILITY/根架构文档。

## 27. AI Coding Constraints
全局：AI 不允许新增未注册模块、绕过 contracts、动态扩展目录。模块特有：AI 不得引入业务域/入口仓库/数据域依赖，不得用环境变量式 DSN 配置或无参构造器（旧文档反模式），不得把潜在消费者计入完成度；版本/API/文档变更必须同步 SPEC/TRACEABILITY/Task/contract（BR-012）。

## 28. Forbidden Patterns
- 旧 DSN option、环境变量式 DSN 配置、无参构造器、旧事务入口（已从基线移除）。
- 业务域反向依赖、读环境变量/配置文件/Secret 文件。
- 全局可变状态、shared singleton chaos、runtime reflection abuse。
- 事务 panic 未回滚、迁移版本重复/非正/空名称/空 SQL。
- 日志/指标/健康检查暴露明文 DSN、密码或 SQL 参数。

## 29. Production Ready Checklist
- [x] Public API v1.0.0 已冻结（tag v1.0.0, commit 310a249e）
- [x] release-evidence-check / release-final-check / release-preflight（真实 PG integration）通过
- [x] FR-001..007、BR-001..012、TC-001..009 由 TRACEABILITY 闭合
- [x] 单测覆盖率 ≥ 80% / race / vet / lint / gitleaks 通过
- [ ] 下游真实接入证据（x.go/业务模块 import）—— OQ-001 跟踪中
- [ ] 生产 soak 数据积累 —— OQ-002 跟踪中
- [ ] Factory-grade 声明（BLK-006 unit coverage 52.4% + Docker integration skip 关闭前 factory=false）

## 30. Roadmap
- v1.0.0（已发布）：Config/连接池、SQL 执行、事务、迁移、健康检查、错误映射、观测 hook。
- v1.x：补可复现 benchmark（NFR-001..005 Deferred）、下游接入证据、生产 soak 数据。
- 后续 major：分页/排序/审计字段/批处理工具（如需求触发，需破坏性变更评估）。
