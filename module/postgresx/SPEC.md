# postgresx 完整规格

> 基座 · 存储扩展。PostgreSQL 客户端封装，提供统一的连接管理、查询、事务、迁移和可观测集成。

最后更新：2026-06-07

---

## 1. Metadata

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-07
- Owner: ZoneCNH
- Layer: 基座 · 存储扩展
- Version: v0.7.3
- Repository: [github.com/ZoneCNH/postgresx](https://github.com/ZoneCNH/postgresx)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md)

---

### 1.1 变更历史

| 日期       | 版本   | 变更内容   | 作者    |
| ---------- | ------ | ---------- | ------- |
| 2026-06-07 | v1.0.0 | 初始版本   | ZoneCNH |

## 2. Summary

`postgresx` 封装 PostgreSQL 客户端，提供统一的连接管理、参数化查询、事务管理、Schema 迁移、健康检查和可观测集成。与 kernel 生命周期集成，保证连接池随应用启停。不提供 ORM，直接暴露 SQL 接口。

---

## 3. Problem

70+ 模块中有多个需要使用 PostgreSQL（持久化存储、历史数据查询），各自封装会导致：

- 连接池配置不一致，部分模块创建过多连接
- SQL 拼接方式不统一，存在 SQL 注入风险
- 事务管理各自为政，回滚逻辑容易遗漏
- Schema 迁移工具不统一，版本管理混乱
- 健康检查缺失，数据库不可用时无法及时发现
- 可观测集成缺失，查询延迟和慢查询无法被 metrics 采集

---

## 4. Goals

- 提供统一的 PostgreSQL 客户端封装，覆盖 Query / QueryRow / Exec 操作
- 事务管理（自动 commit/rollback）
- Schema 迁移（版本化、幂等、可回滚）
- 参数化查询（防止 SQL 注入）
- 健康检查集成到 kernel 健康体系
- 可观测集成（metrics、tracing、logging）
- 与 kernel 生命周期集成

---

## 5. Non-goals

- 不做 ORM（直接暴露 SQL，业务层决定查询方式）
- 不做数据库集群管理（由运维配置）
- 不做数据模型定义（业务层决定 schema）
- 不做连接池底层实现（使用 pgx/pgpool 标准实现）
- 不做读写分离（业务层按需使用多个 Client 实例）
- 不做配置解析（→ `configx`）

---

## 6. Consumers

| 消费者            | 使用方式                                  |
| ----------------- | ----------------------------------------- |
| `market-data`     | 持久化行情历史数据                        |
| `signal-engine`   | 存储因子计算结果和信号历史                |
| `order-engine`    | 存储订单历史和成交记录                    |
| `risk-engine`     | 存储风控日志和阈值配置                    |
| `backtest-engine` | 存储回测结果和参数                        |
| 业务域模块        | 通过 `Client` 接口进行 SQL 查询和事务操作 |

---

## 7. Functional Requirements

### FR-001: Query

WHEN 调用 `Query(ctx, sql, args...)` 且 SQL 有效
THEN 返回 Rows 迭代器，error 为 nil

WHEN 调用 `Query(ctx, sql, args...)` 且 SQL 语法错误
THEN 返回数据库错误

WHEN 调用 `Query(ctx, sql, args...)` 且参数数量不匹配
THEN 返回参数绑定错误

WHEN 调用 `Query(ctx, sql, args...)` 且 ctx 超时
THEN 返回 ctx.Err()

### FR-002: QueryRow

WHEN 调用 `QueryRow(ctx, sql, args...)` 且有结果
THEN 返回 Row，调用 Scan 可获取数据

WHEN 调用 `QueryRow(ctx, sql, args...)` 且无结果
THEN 返回 Row，调用 Scan 返回 `ErrNoRows`

### FR-003: Exec

WHEN 调用 `Exec(ctx, sql, args...)` 且 SQL 有效
THEN 返回 Result（含 RowsAffected），error 为 nil

WHEN 调用 `Exec(ctx, sql, args...)` 且 SQL 语法错误
THEN 返回数据库错误

WHEN 调用 `Exec(ctx, sql, args...)` 且违反约束（UNIQUE、FK 等）
THEN 返回约束违反错误

### FR-004: Tx

WHEN 调用 `Tx(ctx, fn)` 且 fn 返回 nil
THEN 自动 commit，返回 nil

WHEN 调用 `Tx(ctx, fn)` 且 fn 返回 error
THEN 自动 rollback，返回 fn 的 error

WHEN 调用 `Tx(ctx, fn)` 且 fn panic
THEN 自动 rollback，返回 panic 错误

WHEN 调用 `Tx(ctx, fn)` 且 ctx 超时
THEN 自动 rollback，返回 ctx.Err()

### FR-005: Health

WHEN 调用 `Health()` 且数据库 PING 成功
THEN 返回 HealthStatus{Ready: true, Live: true}

WHEN 调用 `Health()` 且数据库不可达
THEN 返回 HealthStatus{Ready: false, Live: false, Message: "..."}

WHEN 连接池耗尽
THEN 返回 HealthStatus{Ready: false, Live: true, Message: "pool exhausted"}

### FR-006: Migration

WHEN 调用 `Migrate(ctx, migrations)` 且有新版本
THEN 按顺序执行迁移，返回 nil

WHEN 调用 `Migrate(ctx, migrations)` 且已是最新版本
THEN 返回 nil（幂等）

WHEN 迁移脚本执行失败
THEN 停止迁移，返回错误（不自动回滚，需手动修复）

---

## 8. Business Rules

| 编号   | 规则                                                        |
| ------ | ----------------------------------------------------------- |
| BR-001 | 所有查询必须使用参数化查询（`$1, $2, ...`），禁止字符串拼接 |
| BR-002 | 所有操作必须接受 `context.Context`，支持超时和取消          |
| BR-003 | 事务必须在 fn 返回后自动 commit 或 rollback                 |
| BR-004 | 事务内 panic 必须被 catch，自动 rollback                    |
| BR-005 | Rows 使用完毕后必须 Close（调用方负责）                     |
| BR-006 | Health() 必须是幂等的、无副作用的                           |
| BR-007 | 迁移脚本必须是幂等的（可重复执行）                          |
| BR-008 | 迁移版本号必须单调递增                                      |
| BR-009 | 错误消息不包含 SQL 参数值（防泄露敏感数据）                 |
| BR-010 | 连接池大小通过配置控制，默认 10                             |

---

## 9. Interface Contract

```go
type Client interface {
    Query(ctx context.Context, sql string, args ...any) (Rows, error)
    QueryRow(ctx context.Context, sql string, args ...any) Row
    Exec(ctx context.Context, sql string, args ...any) (Result, error)
    Tx(ctx context.Context, fn func(tx Tx) error) error
    Health() HealthStatus
    Close() error
}

type Tx interface {
    Query(ctx context.Context, sql string, args ...any) (Rows, error)
    QueryRow(ctx context.Context, sql string, args ...any) Row
    Exec(ctx context.Context, sql string, args ...any) (Result, error)
}

type Rows interface {
    Next() bool
    Scan(dest ...any) error
    Close() error
    Err() error
}

type Row interface {
    Scan(dest ...any) error
}

type Result interface {
    RowsAffected() int64
}

type HealthStatus struct {
    Ready   bool
    Live    bool
    Message string
}

func New(opts ...Option) Client
```text

### 9.1 Option 模式

```go
type Option func(*config)

func WithDSN(dsn string) Option
func WithMaxConns(n int) Option
func WithMinConns(n int) Option
func WithMaxConnLifetime(d time.Duration) Option
func WithMaxConnIdleTime(d time.Duration) Option
func WithHealthCheckPeriod(d time.Duration) Option
func WithConnectTimeout(d time.Duration) Option
func WithQueryTimeout(d time.Duration) Option
```text

### 9.2 用法示例

```go
// 创建客户端
client := postgresx.New(
    postgresx.WithDSN(os.Getenv("FOUNDATIONX_POSTGRES_DSN")),
    postgresx.WithMaxConns(20),
)
defer client.Close()

// 查询
rows, err := client.Query(ctx, "SELECT id, name FROM users WHERE active = $1", true)
if err != nil {
    return err
}
defer rows.Close()

for rows.Next() {
    var id int
    var name string
    rows.Scan(&id, &name)
}

// 单行查询
var count int
err = client.QueryRow(ctx, "SELECT COUNT(*) FROM orders WHERE status = $1", "filled").Scan(&count)

// 执行
result, err := client.Exec(ctx, "UPDATE users SET last_login = $1 WHERE id = $2", time.Now(), userID)
fmt.Printf("affected: %d\n", result.RowsAffected())

// 事务
err = client.Tx(ctx, func(tx postgresx.Tx) error {
    _, err := tx.Exec(ctx, "UPDATE accounts SET balance = balance - $1 WHERE id = $2", amount, fromID)
    if err != nil {
        return err // 自动 rollback
    }
    _, err = tx.Exec(ctx, "UPDATE accounts SET balance = balance + $1 WHERE id = $2", amount, toID)
    return err // nil → 自动 commit
})

// 迁移
migrations := []postgresx.Migration{
    {Version: 1, SQL: `CREATE TABLE users (id SERIAL PRIMARY KEY, name TEXT)`},
    {Version: 2, SQL: `ALTER TABLE users ADD COLUMN email TEXT`},
}
err = client.Migrate(ctx, migrations)
```text

---

## 10. Data Model

### 10.1 公共错误

```go
var (
    ErrConnectionFailed = errors.New("postgresx: connection failed")
    ErrNoRows           = errors.New("postgresx: no rows in result set")
    ErrPoolExhausted    = errors.New("postgresx: connection pool exhausted")
    ErrMigrationFailed  = errors.New("postgresx: migration failed")
    ErrInvalidDSN       = errors.New("postgresx: invalid DSN")
    ErrTxPanic          = errors.New("postgresx: transaction panic")
)
```text

### 10.2 Migration 结构

```go
type Migration struct {
    Version     int
    Description string
    SQL         string
    DownSQL     string // 回滚 SQL（可选）
}
```text

---

## 11. Config Schema

```yaml
postgresx:
  dsn: "${FOUNDATIONX_POSTGRES_DSN}"  # 连接字符串（推荐通过环境变量注入）
  max_conns: 20                # 最大连接数
  min_conns: 2                 # 最小空闲连接数
  max_conn_lifetime: 1h        # 连接最大存活时间
  max_conn_idle_time: 30m      # 连接最大空闲时间
  health_check_period: 1m      # 健康检查周期
  connect_timeout: 5s          # 连接超时
  query_timeout: 30s           # 默认查询超时
  migration_table: schema_migrations  # 迁移版本表名
```text

---

## 12. Error Handling

| 错误                  | 调用方处理                                  |
| --------------------- | ------------------------------------------- |
| `ErrConnectionFailed` | 检查 DSN 和网络，确认 PostgreSQL 服务运行中 |
| `ErrNoRows`           | 查询无结果，调用方应处理空值（不是异常）    |
| `ErrPoolExhausted`    | 增加 max_conns 或优化查询减少连接占用时间   |
| `ErrMigrationFailed`  | 检查迁移 SQL 和数据库状态，手动修复后重试   |
| `ErrInvalidDSN`       | 检查 DSN 格式                               |
| `ErrTxPanic`          | 检查事务 fn 中的 panic 原因                 |
| 约束违反错误          | 检查数据是否违反 UNIQUE / FK / CHECK 约束   |
| SQL 语法错误          | 检查 SQL 语句                               |

**错误消息格式：** `"postgresx: <operation>: <detail>"`
**错误包装：** 使用 `%w` 保留底层错误链
**安全要求：** 错误消息不包含 SQL 参数值

---

## 13. Edge Cases

| 场景                      | 预期行为                                                 |
| ------------------------- | -------------------------------------------------------- |
| PostgreSQL 不可达时 Query | 返回 ErrConnectionFailed                                 |
| 连接池耗尽                | 等待直到有空闲连接或超时，超时返回 ErrPoolExhausted      |
| QueryRow 无结果           | Scan 返回 ErrNoRows                                      |
| Tx fn panic               | 自动 rollback，返回 ErrTxPanic                           |
| Tx ctx 超时               | 自动 rollback，返回 ctx.Err()                            |
| Rows 未 Close             | 连接泄漏（应在 vet/lint 中检测）                         |
| Exec 影响 0 行            | 返回 Result{RowsAffected: 0}，不报错                     |
| 并发 Tx 操作同一行        | 遵循 PostgreSQL 锁机制（行锁或死锁检测）                 |
| 迁移脚本幂等性            | CREATE TABLE IF NOT EXISTS，ALTER TABLE 先检查列是否存在 |
| 空 SQL 字符串             | 返回 SQL 语法错误                                        |
| 参数数量不匹配            | 返回参数绑定错误                                         |
| 大结果集（>100 万行）     | 通过 Rows 迭代器逐行处理，不一次性加载                   |

---

## 14. Directory Structure

```text
postgresx/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go
├── postgresx.go                # Client 工厂
├── client.go                   # Client 接口实现
├── tx.go                       # Tx 接口实现
├── rows.go                     # Rows 接口实现
├── row.go                      # Row 接口实现
├── result.go                   # Result 接口实现
├── health.go                   # HealthStatus
├── options.go                  # Option 模式
├── errors.go                   # 公共错误变量
├── migrate/
│   ├── migrate.go              # 迁移引擎
│   └── embed.go                //go:embed 支持
├── internal/
│   ├── pool/                   # 连接池封装
│   └── trace/                  # 查询追踪
├── testdata/
│   ├── docker-compose.yml      # 测试用 PostgreSQL 配置
│   └── migrations/             # 测试用迁移脚本
├── example_test.go
├── benchmark_test.go
└── integration_test.go         # //go:build integration
```text

---

## 15. Dependencies

### 15.1 go.mod

```text
module github.com/ZoneCNH/postgresx

go 1.23
```text

### 15.2 依赖方向

| 可以依赖                   | 禁止依赖             |
| -------------------------- | -------------------- |
| stdlib                     | configx              |
| kernel（L0 原语）          | 所有业务域实现       |
| observex（interface-only） | 所有 L2.5 领域共享层 |
| PostgreSQL 驱动（pgx）     |                      |

---

## 16. Testing

### 16.1 单元测试

| 测试场景          | 验证点                   |
| ----------------- | ------------------------ |
| Query 成功        | 返回正确结果集           |
| Query SQL 错误    | 返回数据库错误           |
| QueryRow 有结果   | Scan 正确获取数据        |
| QueryRow 无结果   | Scan 返回 ErrNoRows      |
| Exec 成功         | RowsAffected 正确        |
| Exec 约束违反     | 返回约束错误             |
| Tx commit         | fn 返回 nil → commit     |
| Tx rollback       | fn 返回 error → rollback |
| Tx panic rollback | fn panic → rollback      |
| Health PING 成功  | 返回 Ready: true         |
| Health PING 失败  | 返回 Ready: false        |
| Migration 执行    | 迁移正确应用             |
| Migration 幂等    | 重复执行无副作用         |
| 连接池配置        | max/min conns 正确设置   |
| 并发安全          | -race 测试通过           |

### 16.2 Given/When/Then 用例

**TC-001: 基本 CRUD**
Given 数据库连接正常
When INSERT 一行然后 SELECT
Then 返回插入的数据

**TC-002: 事务原子性**
Given 两个 UPDATE 在同一事务中
When 第二个 UPDATE 失败
Then 第一个 UPDATE 被回滚

**TC-003: 事务 panic 回滚**
Given 事务 fn 中 panic
When 执行事务
Then 自动 rollback，返回 ErrTxPanic

**TC-004: 迁移版本管理**
Given 已应用版本 1 和 2
When 调用 Migrate
Then 只执行版本 3 及以后的迁移

**TC-005: Health 检查**
Given 数据库连接正常
When 调用 Health
Then 返回 healthy；连接失败时返回 unhealthy

### 16.3 Benchmark

| 场景                          | 目标   |
| ----------------------------- | ------ |
| 单次 Query（本地 PostgreSQL） | < 5ms  |
| 事务（5 条 SQL）              | < 10ms |
| QueryRow + Scan               | < 5ms  |
| 连接池获取连接                | < 1ms  |

### 16.4 集成测试

| 场景           | 验证点                            |
| -------------- | --------------------------------- |
| 完整 CRUD 链   | INSERT → SELECT → UPDATE → DELETE |
| 事务提交和回滚 | commit 和 rollback 正确执行       |
| 迁移执行       | 多版本迁移正确应用                |
| 并发事务       | 多个并发 Tx 不冲突                |
| 连接池压力     | 高并发下连接池正确管理            |

---

## 17. Performance Budget

| 操作                          | 目标        | 测量方式       |
| ----------------------------- | ----------- | -------------- |
| 单次 Query（本地 PostgreSQL） | < 5ms       | benchmark test |
| 事务（5 条 SQL）              | < 10ms      | benchmark test |
| 连接池获取连接                | < 1ms       | benchmark test |
| 常驻内存                      | < 10MB      | profiling      |
| 连接池空闲连接                | ≤ max_conns | 配置约束       |

---

## 18. Observability

| 类型   | 名称                           | 说明                             |
| ------ | ------------------------------ | -------------------------------- |
| metric | `postgresx.query.duration`     | histogram，查询耗时              |
| metric | `postgresx.query.errors`       | counter，查询失败次数            |
| metric | `postgresx.query.rows`         | histogram，查询返回行数          |
| metric | `postgresx.exec.duration`      | histogram，执行耗时              |
| metric | `postgresx.exec.rows_affected` | histogram，影响行数              |
| metric | `postgresx.tx.duration`        | histogram，事务耗时              |
| metric | `postgresx.tx.committed`       | counter，事务提交次数            |
| metric | `postgresx.tx.rollbacked`      | counter，事务回滚次数            |
| metric | `postgresx.pool.size`          | gauge，连接池大小                |
| metric | `postgresx.pool.idle`          | gauge，空闲连接数                |
| metric | `postgresx.pool.in_use`        | gauge，使用中连接数              |
| metric | `postgresx.migration.applied`  | counter，已应用迁移数            |
| log    | `postgresx.connected`          | info，连接成功                   |
| log    | `postgresx.disconnected`       | warn，连接断开                   |
| log    | `postgresx.slow_query`         | warn，慢查询（超过阈值）         |
| log    | `postgresx.migration.applied`  | info，迁移已应用，含版本号       |
| log    | `postgresx.tx.rollbacked`      | warn，事务回滚，含错误原因       |
| span   | `postgresx.query`              | 查询 span，含 SQL 和参数（脱敏） |

---

## 19. Security

| 要求             | 实现方式                                          |
| ---------------- | ------------------------------------------------- |
| 参数化查询       | 所有查询使用 `$1, $2, ...` 占位符，禁止字符串拼接 |
| DSN 不硬编码     | 通过环境变量或 secret manager 注入                |
| DSN 不写日志     | 日志中对密码字段脱敏                              |
| SQL 参数不写日志 | 日志中不包含查询参数值（防泄露敏感数据）          |
| 慢查询日志       | 只记录 SQL 模板，不记录参数值                     |
| 连接加密         | 支持 SSL/TLS 连接（通过 DSN 参数）                |

---

## 20. CI Gate

### 20.1 通用 Gate

| Gate        | 命令                                                                                                               | 阻塞条件                 |
| ----------- | ------------------------------------------------------------------------------------------------------------------ | ------------------------ |
| 编译        | `go build ./...`                                                                                                   | 编译失败                 |
| 测试        | `go test ./... -race -count=1`                                                                                     | 任何测试失败或 data race |
| 覆盖率      | `mkdir -p .coverage && go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | 总覆盖率 < 80%           |
| vet         | `go vet ./...`                                                                                                     | 任何 vet 错误            |
| lint        | `golangci-lint run`                                                                                                | 任何 lint 错误           |
| 依赖检查    | `go mod tidy && git diff --exit-code go.mod go.sum`                                                                | go.mod 不整洁            |
| Secret 扫描 | `gitleaks detect --no-git`                                                                                         | 泄露 secret              |
| Benchmark   | `go test -bench=. -benchmem -count=3 ./...`                                                                        | 结果附在 PR comment      |

### 20.2 postgresx 专属 Gate

| Gate         | 命令                              | 阻塞条件                         |                                       |                   |                    |
| ------------ | --------------------------------- | -------------------------------- |                                       |                   |                    |
| 集成测试     | `go test -tags=integration ./...` | PostgreSQL 不可达时 skip，不阻塞 |                                       |                   |                    |
| SQL 注入检查 | `grep -rn 'fmt.Sprintf.*SQL\      | Sprintf.*SELECT\                 | Sprintf.*INSERT' --include="*.go" . \ | grep -v _test.go` | 发现字符串拼接 SQL |

---

## 21. Upgrade Compatibility

| 变更类型                     | 版本升级                      |
| ---------------------------- | ----------------------------- |
| Client 接口新增方法          | **minor**（实现需跟上）       |
| Client 接口删除/修改方法     | **major**                     |
| Tx 接口变更                  | **major**                     |
| Rows / Row / Result 接口变更 | **major**                     |
| Migration 结构体变更         | **minor**（新增字段带默认值） |
| Option 新增字段              | minor（带默认值）             |
| 默认连接池参数变更           | **minor**（注意行为变化）     |

---

## 22. Release DoD

- [ ] 所有公共接口有 godoc 注释
- [ ] 所有公共类型有示例代码
- [ ] CHANGELOG.md 已更新
- [ ] README.md 包含：模块定位、快速开始、配置说明、API 概览
- [ ] 单元测试覆盖率 ≥ 80%
- [ ] `-race` 测试通过
- [ ] Benchmark 结果无 > 10% 回退
- [ ] `go vet` 无警告
- [ ] `golangci-lint` 无错误
- [ ] Secret 扫描通过
- [ ] 公共 API 无破坏性变更（或已 bump major）
- [ ] 所有 Functional Requirements 有对应测试
- [ ] 所有 Edge Cases 有对应测试
- [ ] SQL 注入检查通过

---

## 23. Open Questions

- 是否需要支持批量操作（Batch INSERT / COPY）？
- 是否需要支持只读副本路由（读写分离）？
- 迁移是否需要支持回滚（Down migration）？
- 是否需要支持存储过程 / 函数调用？
- 是否需要支持 LISTEN / NOTIFY（PostgreSQL 原生 Pub/Sub）？
- 连接池是否需要支持动态扩缩容（根据负载自动调整）？
