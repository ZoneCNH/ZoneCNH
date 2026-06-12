# postgresx 发布版本 1.0 Goal 定位与实现标准

| 字段         | 内容                                           |
| ------------ | ---------------------------------------------- |
| 模块名       | `postgresx`                                    |
| 发布版本     | 1.0.0                                          |
| 所属层级     | 存储扩展层 / PostgreSQL 关系型核心存储         |
| 稳定级别     | Public API Stable；SPI Stable；Internal 可演进 |
| 文档状态     | 1.0 发布基线文档                               |
| 发布日期基准 | 2026-06-09                                     |

## 术语约定

本文档中的 **MUST / 必须** 表示 1.0 发布阻断项；**SHOULD / 应该** 表示 1.0 推荐项，允许带明确理由延期；**MAY / 可以** 表示可选能力，不影响 1.0 发布。

## 1.0 发布判定原则

1. **稳定优先**：公开 API、配置项、错误码、指标名一旦进入 1.0，默认需要向后兼容。
2. **边界清晰**：模块只能解决自身层级的问题，不能向上侵入业务，也不能横向替代其他模块。
3. **证据完整**：每个 MUST 能力都必须有单元测试、关键路径集成测试或契约测试证明。
4. **可观测**：所有运行时模块必须输出最小可诊断信息，包括错误、耗时、调用量和关键状态。
5. **可演进**：1.0 允许保留扩展点，但不得把未稳定能力包装成稳定承诺。

## 1. Goal 定位

`postgresx` 的 Goal 是提供 PostgreSQL 的统一数据访问和治理能力，覆盖数据源、连接池、事务、SQL 执行、查询封装、迁移、分页、审计字段、租户隔离、慢查询观测和错误映射。它作为关系型核心存储扩展，强调事务边界清晰、访问方式一致和生产可诊断。

### 1.1 为什么需要这个模块

- 关系型数据库是核心业务数据存储，访问层如果缺乏统一事务和错误模型，会产生严重一致性问题。
- 连接池、慢查询、迁移、审计字段和租户隔离需要标准化。
- 不同服务自行封装 SQL 会造成分页、排序、错误处理和观测不一致。
- PostgreSQL 错误码需要映射为 xlib 标准错误，便于上层治理。

### 1.2 1.0 要解决的问题

- 统一 DataSource、Connection、TransactionManager、SqlExecutor。
- 统一事务传播、超时、只读事务和回滚规则。
- 统一分页、排序、批处理和参数绑定。
- 统一迁移工具接入和启动期迁移策略。
- 统一审计字段、租户过滤和慢查询观测。

### 1.3 目标用户

- 业务服务开发者
- 平台基础设施开发者
- SRE / 运维人员
- 测试工程师

## 2. 1.0 发布目标

- MUST 提供 DataSource 管理、连接池配置和健康检查。
- MUST 提供事务管理，支持 required/requires-new/read-only 基础语义。
- MUST 提供参数化 SQL 执行，禁止字符串拼接注入风险。
- MUST 提供分页、排序、批处理、审计字段基础工具。
- MUST 输出慢查询、连接池、事务、错误指标。

## 3. 核心场景

| 场景       | 说明               | 1.0 期望结果                                             |
| ---------- | ------------------ | -------------------------------------------------------- |
| 事务写入   | 创建订单和订单明细 | 在同一事务内提交或回滚                                   |
| 分页查询   | 后台列表查询       | 统一 PageRequest/PageResult 和排序白名单                 |
| 数据库迁移 | 服务发布新增表结构 | 启动期或发布期执行迁移并记录版本                         |
| 慢查询排查 | 接口响应变慢       | 通过 sqlId、duration、rows、traceId 定位                 |
| 连接池管理 | 高并发下连接池耗尽 | 通过 pool.active、pool.wait、pool.timeout 指标监控和告警 |

## 4. 能力范围

| 能力域   | 1.0 必须具备的能力                          | 验收方式         |
| -------- | ------------------------------------------- | ---------------- |
| 数据源   | 连接池、超时、认证、健康检查                | 集成测试通过     |
| 事务     | 传播、隔离级别、只读、超时、回滚规则        | 事务测试通过     |
| SQL 执行 | 参数绑定、查询、更新、批处理、结果映射      | SQL 测试通过     |
| 分页排序 | PageRequest、排序白名单、总数策略           | 分页测试通过     |
| 迁移     | 迁移版本、校验、失败处理、checksum          | 迁移测试通过     |
| 审计租户 | createdAt/updatedAt/createdBy/tenantId 辅助 | 字段填充测试通过 |
| 观测     | 慢查询、连接池、事务、错误                  | 观测测试通过     |

## 5. 职责边界

### 5.1 模块内职责

- 提供 PostgreSQL 标准访问层和事务管理。
- 提供迁移、分页、批处理、审计字段和租户隔离辅助。
- 提供错误码映射和可观测接入。
- 提供与 resiliencx 的超时、重试边界集成。

### 5.2 明确非目标

- 不替代 ORM；可与 ORM 集成但不强制。
- 不负责业务数据模型设计。
- 不替代 DBA 的容量、索引和备份策略。
- 不鼓励把 PostgreSQL 当作消息队列滥用。

## 6. 依赖关系与分层约束

| 依赖类型 | 约束                                                                    |
| -------- | ----------------------------------------------------------------------- |
| 上游依赖 | 依赖 kernel、configx、observex、resiliencx。                            |
| 下游依赖 | 业务仓储层、schedulex TaskStore、contracts 元数据存储可使用 postgresx。 |
| 分层约束 | postgresx 不依赖具体业务 repository；只提供基础访问能力。               |

| 契约依赖 | MUST 向 contracts 登记 Public API 契约和错误码契约。 |
## 7. 对外契约

### 7.1 公开能力面

| 契约                  | 定位             | 1.0 稳定承诺                |
| --------------------- | ---------------- | --------------------------- |
| PostgresDataSource    | 数据源入口       | 连接获取和健康检查语义稳定  |
| TransactionManager    | 事务执行入口     | 提交/回滚/传播语义稳定      |
| SqlExecutor           | 参数化 SQL 执行  | query/update/batch 语义稳定 |
| MigrationRunner       | 迁移执行接口     | 版本和 checksum 语义稳定    |
| TenantContextProvider | 租户上下文扩展点 | tenantId 获取语义稳定       |

### 7.2 1.0 逻辑接口基线

```text
TransactionManager
  execute(TransactionOptions, callback): T

TransactionOptions
  propagation: REQUIRED | REQUIRES_NEW
  isolation
  readOnly
  timeout

SqlExecutor
  query(sqlId, sql, params, rowMapper): List<T>
  queryPage(sqlId, sql, params, pageRequest): PageResult<T>
  update(sqlId, sql, params): int
  batch(sqlId, sql, batchParams): BatchResult

AuditFields
  createdAt, updatedAt, createdBy, updatedBy, tenantId

PostgresDataSource
  getConnection(): Connection
  health(): HealthState

MigrationRunner
  migrate(): MigrationResult
  status(): list<MigrationInfo>
  validate(): ValidationResult

TenantContextProvider
  currentTenantId(): string
```

## 8. 配置契约

| 配置项                                    | 含义               | 默认值 / 要求             | 稳定性 |
| ----------------------------------------- | ------------------ | ------------------------- | ------ |
| foundationx.postgres.enabled              | 是否启用 postgresx | false，由业务显式启用     | Stable |
| foundationx.postgres.url                  | 数据库连接串       | 必须配置，日志脱敏        | Stable |
| foundationx.postgres.pool.max-size        | 连接池最大连接数   | 按环境配置                | Stable |
| foundationx.postgres.query.timeout        | 查询超时           | 3s                        | Stable |
| foundationx.postgres.transaction.timeout  | 事务超时           | 30s                       | Stable |
| foundationx.postgres.slow-query-threshold | 慢查询阈值         | 500ms                     | Stable |
| foundationx.postgres.migration.enabled    | 是否启用迁移       | false，生产建议发布期执行 | Stable |
| foundationx.postgres.tenant.enabled       | 是否启用租户辅助   | false                     | Stable |

## 9. 可观测契约

### 9.1 日志

- MUST 输出模块初始化结果、关键配置摘要和失败原因；敏感配置必须脱敏。
- MUST 在关键操作失败时输出 errorCode、operation、durationMs、traceId、resource。
- SHOULD 对慢操作输出 warn 级别日志，阈值由配置控制。
- MUST 慢查询日志包含 sqlId、durationMs、rows、connectionPool，不默认输出完整 SQL 参数。
- MUST 事务回滚日志包含 transactionId、reason、errorCode。

### 9.2 指标

| 指标名                                  | 类型    | 标签                   | 说明         |
| --------------------------------------- | ------- | ---------------------- | ------------ |
| foundationx_postgres_query_total        | Counter | sqlId,operation,status | SQL 执行次数 |
| foundationx_postgres_query_duration_ms  | Timer   | sqlId,operation,status | SQL 执行耗时 |
| foundationx_postgres_transactions_total | Counter | status,propagation     | 事务次数     |
| foundationx_postgres_pool_active        | Gauge   | datasource             | 活跃连接数   |
| foundationx_postgres_pool_pending       | Gauge   | datasource             | 等待连接数   |
| foundationx_postgres_migration_total    | Counter | version,status         | 迁移执行次数 |
| foundationx_postgres_errors_total       | Counter | sqlState,errorCode     | 数据库错误数 |

### 9.3 Trace / 诊断事件

- MUST 接收并传播上游 trace context，不得无故丢失 requestId / traceId。
- SHOULD 为外部依赖调用创建 span，并标注 peer、operation、status、errorCode。
- MAY 输出模块内部诊断事件，用于启动分析和运行期排障。
- MUST 标注 db.system=postgresql、db.operation、db.sql_id、db.rows。
- SHOULD 对事务创建 span 或事件，标注 commit/rollback。

## 10. 错误模型与失败策略

| 错误类别                      | 典型原因                       | 1.0 处理策略                   |
| ----------------------------- | ------------------------------ | ------------------------------ |
| POSTGRES_CONNECTION_FAILED    | 连接失败、认证失败、网络不可达 | 启动或健康检查失败，按策略处理 |
| POSTGRES_QUERY_TIMEOUT        | 查询超时                       | 取消查询并返回超时错误         |
| POSTGRES_CONSTRAINT_VIOLATION | 唯一键、外键、非空约束失败     | 映射为业务可识别数据冲突       |
| POSTGRES_TRANSACTION_FAILED   | 提交或回滚失败                 | 返回事务错误并记录诊断         |
| POSTGRES_MIGRATION_FAILED     | 迁移 checksum 不一致或执行失败 | 发布门禁阻断                   |

## 11. 安全、稳定性与兼容性要求

- MUST 对密码、token、accessKey、secretKey、连接串中的敏感片段做脱敏。
- MUST 保证公开 API 的异常不会泄漏内部凭据、主机隐私或完整连接串。
- MUST 为所有网络和外部依赖调用设置超时边界。
- SHOULD 支持最小权限原则，不要求业务使用高权限账号。
- MUST 支持 TLS 连接和认证配置。
- MUST 使用参数化 SQL，禁止默认拼接用户输入。
- MUST 对 SQL 参数日志脱敏。
- SHOULD 支持只读账号和读写数据源分离。

## 12. 测试证据要求

| 测试类型 | 必须覆盖内容                               | 发布门禁  |
| -------- | ------------------------------------------ | --------- |
| 单元测试 | 分页、排序、SQL 参数绑定、错误映射         | MUST 通过 |
| 集成测试 | 真实 PostgreSQL 查询、事务、批处理、连接池 | MUST 通过 |
| 迁移测试 | 版本迁移、checksum、失败回滚策略           | MUST 通过 |
| 并发测试 | 连接池耗尽、事务并发、死锁错误映射         | MUST 通过 |
| 安全测试 | SQL 注入防护、参数脱敏                     | MUST 通过 |

## 13. 1.0 发布验收清单

- 所有 SQL 执行必须有 sqlId 或等效可观测标识。
- 事务边界明确，异常回滚规则可预测。
- 慢查询可定位，连接池状态可观测。
- 迁移失败不能静默通过。

## 14. Definition of Done

- 公开 API、配置项、错误码、指标名完成冻结并记录兼容性说明。
- README、快速开始、配置参考、错误码参考、测试说明完成。
- MUST 能力均有自动化测试，CI 可重复执行。
- 示例工程或最小可运行样例通过。
- 发布包不包含测试密钥、临时文件、个人环境路径。

## 15. 1.0 后演进方向

- 支持读写分离和多数据源路由。
- 增强 schema diff 和迁移 dry-run。
- 提供 repository 生成器但保持可选。
