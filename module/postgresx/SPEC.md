# postgresx 规格

- Status: Approved
- Spec-Version: v1.1.0
- Last-Updated: 2026-06-13
- Layer: 基座 · 存储扩展
- Version: v1.0.0
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `kernel`

> 公开投影 caveat：Status=Approved 与 100.0% 覆盖证据不等同于 factory-grade；机器事实层保持 factory=false。

---

## 1. 摘要

`postgresx` 是 ZoneCNH 基座层的 PostgreSQL 访问模块。当前实现围绕 `pgx/v5` 提供：

- 显式 `Config` 和 `New(ctx, cfg, opts...)` / `Open(ctx, cfg, opts...)` 入口。
- `Client` 结构体管理 `pgxpool.Pool` 生命周期，支持 `Ping`、`Close`、`Stats`、`Queryer`。
- `Exec`、`Query`、`QueryRow` 和调用方负责关闭的 `Rows` 抽象。
- `WithTx` / `WithTxOptions` 自动提交、回滚和 panic 回滚。
- `MigrationRunner` 执行版本化 SQL 迁移并记录已应用版本。
- `HealthChecker` 兼容的 `Name` / `Check` 健康检查。
- 本地错误归一化（ErrorKind 分类）、可重试判断、SecretString 脱敏、日志和指标 hook。

本模块不是 ORM，不读取环境变量或配置文件，不接管应用生命周期，不向上依赖业务仓库。

## 2. 问题与背景

多个模块需要 PostgreSQL 访问能力。如果各自封装，会造成：

- 连接池配置、超时和关闭语义不一致。
- 事务提交、回滚和 panic 路径遗漏。
- PostgreSQL 错误码无法统一映射到结构化错误模型。
- 迁移版本和执行记录分散，难以审计。
- 健康检查、连接池状态、查询耗时和失败指标缺少统一采集点。
- 连接串、密码或 SQL 参数存在日志泄露风险。

## 3. 目标

- 提供小而稳定的 PostgreSQL 客户端基线，直接暴露 SQL 能力而非 ORM。
- 统一连接池、配置默认值、生命周期和健康检查语义。
- 统一事务执行边界，保证 commit、rollback、context 取消和 panic 行为可测试。
- 统一迁移执行入口，保证版本单调、重复版本检测和已应用记录。
- 统一 PostgreSQL 错误映射与 retryability 判定。
- 提供日志与指标适配点，但不绑定具体可观测后端。
- 维持基座模块边界，不依赖业务域仓库或 `x.go` 入口。

## 4. 非目标

- 不做 ORM、Repository 生成器、SQL builder 或实体映射框架。
- 不做读写分离、数据库集群管理、备份恢复和容量治理。
- 不读取环境变量、Secret 文件或应用配置中心；调用方负责构造 `Config`。
- 不接管 `kernel` 生命周期；调用方负责在自身生命周期中调用 `New` 和 `Close`。
- 不内置 `observex`、`resiliencx`、`configx` 运行时耦合；如需集成必须通过接口适配。
- 不承诺分页、排序、审计字段、租户隔离或批处理工具进入当前 v1.0 基线。

## 5. 消费者

| 消费者 | 使用方式 | 当前约束 |
| ------ | -------- | -------- |
| `market_data` | 持久化历史行情和查询结果 | 可作为潜在下游，不形成反向依赖 |
| `signal-engine` | 存储因子计算结果和信号历史 | 通过 SQL 与事务接口调用 |
| `order_engine` | 存储订单历史和成交记录 | 事务边界由业务层决定 |
| `risk_engine` | 存储风控日志和阈值配置 | 需自行定义 schema |
| `backtest_engine` | 存储回测结果和参数 | 可复用迁移与查询接口 |
| 其他基座/业务模块 | 通过 `pkg/postgresx` 显式构造客户端 | 禁止引入业务反向依赖 |

## 6. 功能需求

### FR-001: Config 与连接池生命周期

WHEN 调用方提供 `Config` 并调用 `New(ctx, cfg, opts...)`
THEN 模块必须校验配置、填充默认值、构造 `pgxpool`，并在初始 `Ping` 失败时关闭池。

WHEN 调用方调用 `Close(ctx)`
THEN 模块必须幂等关闭连接池，关闭后查询和事务入口返回已关闭错误。

### FR-002: SQL 执行接口

WHEN 调用 `Exec`、`Query`、`QueryRow`
THEN 模块必须把调用转发到底层 `pgxpool`，保留 `context.Context` 取消和超时语义。

WHEN 调用 `Query` 返回 `Rows`
THEN 调用方必须负责 `Close`，模块必须提供 `Rows.Err()` 暴露迭代错误。

### FR-003: 事务边界

WHEN 调用 `WithTx(ctx, fn)` 或 `WithTxOptions(ctx, opts, fn)`
THEN 模块必须开启事务，`fn` 返回 nil 时提交，`fn` 返回 error 或 ctx 取消时回滚。

WHEN `fn` panic
THEN 模块必须先回滚，再重新抛出 panic，除非未来规格显式变更该契约。

### FR-004: 迁移执行

WHEN 调用 `MigrationRunner.Up(ctx, source)`
THEN 模块必须按版本升序执行未应用迁移，记录版本、名称和执行时间。

WHEN 迁移版本重复、版本非正、名称为空或 SQL 为空
THEN 模块必须拒绝执行并返回错误。

### FR-005: 健康检查与池状态

WHEN 调用 `Name()` 和 `Check(ctx)`
THEN 模块必须符合 `HealthChecker` 接口，输出 healthy/degraded/unhealthy 状态、耗时和安全元数据。

WHEN `Stats()` 被调用
THEN 模块必须返回连接池快照，不暴露密码、完整 DSN 或 SQL 参数。

### FR-006: 错误归一化与可重试判断

WHEN 底层返回 PostgreSQL 或 context 错误
THEN 模块必须通过 `MapError` 将底层错误归一化为结构化 Error，并通过 `IsRetryable` 暴露可重试语义。

### FR-007: 可观测适配与 Secret Hygiene

WHEN 调用方传入 `WithLogger` 或 `WithMetrics`
THEN 模块必须调用适配器记录查询、事务、健康和池状态，不绑定具体后端。

WHEN 构造或记录 DSN
THEN `Config.RedactedDSN()` 必须隐藏密码，日志和指标不得包含完整连接串或 SQL 参数值。

### Acceptance Criteria Registry

| AC 编号 | 对应 FR | 验收条件 |
| ------- | ------- | -------- |
| AC-PGX-001 | FR-001 | New 校验配置+填充默认值+构造 pgxpool；初始 Ping 失败时关闭池；Close 幂等关闭后查询/事务返回已关闭错误 |
| AC-PGX-002 | FR-002 | Exec/Query/QueryRow 转发底层 pgxpool 保留 context 取消/超时语义；Query 返回 Rows 时调用方负责 Close 且 Rows.Err() 暴露迭代错误 |
| AC-PGX-003 | FR-003 | WithTx fn 返回 nil 时提交；fn 返回 error 或 ctx 取消时回滚；fn panic 时先回滚再重新抛出 |
| AC-PGX-004 | FR-004 | MigrationRunner.Up 按版本升序执行未应用迁移并记录版本/名称/执行时间；版本重复/非正/名称空/SQL 空均拒绝返回错误 |
| AC-PGX-005 | FR-005 | Name/Check 符合 HealthChecker 接口输出 healthy/degraded/unhealthy+耗时+安全元数据；Stats 返回池快照不暴露密码/DSN/SQL 参数 |
| AC-PGX-006 | FR-006 | MapError 将 PostgreSQL/context 错误归一化为结构化 Error；IsRetryable 正确暴露可重试语义 |
| AC-PGX-007 | FR-007 | WithLogger/WithMetrics 适配器正确记录查询/事务/健康/池状态；Config.RedactedDSN() 隐藏密码；日志/指标不含完整连接串或 SQL 参数值 |

## 7. 行为约束
| 编号 | 规则 | 违反时 |
| --- | --- | --- |
| BR-001 | `postgresx` 不得依赖业务域仓库、入口仓库或具体应用模块。 | CI Gate：import check 检测到业务域依赖 → 阻断合并 |
| BR-002 | 模块不得读取环境变量、配置文件或 Secret 文件；调用方必须显式传入 `Config`。 | CI Gate：静态分析检测到环境变量/文件读取 → 阻断 |
| BR-003 | 模块不得实现 ORM、schema ownership 或全局默认数据库。 | 不符合模块边界——代码审查拒绝 |
| BR-004 | 所有外部 I/O 入口必须接受 `context.Context` 并尊重取消、超时。 | context 取消/超时不生效 → 测试失败 |
| BR-005 | `Rows` 生命周期由调用方关闭，模块必须保留 `Err()` 查询迭代错误。 | Rows 未关闭导致连接泄漏 → go test -race 检测 |
| BR-006 | 事务必须只在 `fn` 返回 nil 时提交；error、context 取消和 panic 路径必须回滚。 | panic 未回滚或 error 未回滚 → TC-003 测试失败 |
| BR-007 | 迁移版本必须为正整数且单调执行；重复版本和无效迁移必须阻断。 | 迁移阻断，返回错误含版本号和原因 |
| BR-008 | 健康检查必须幂等、无副作用，并只输出安全元数据。 | 暴露密码/DSN → CI Gate secret scan 阻断 |
| BR-009 | 指标适配必须不泄露敏感信息；代码与契约中的指标命名必须保持唯一且一致。 | 指标包含明文凭据 → CI Gate redaction check 阻断 |
| BR-010 | PostgreSQL 错误码必须稳定映射到结构化错误 kind 和 retryability。 | 错误映射缺失或错误 → TC-006 测试失败 |
| BR-011 | 发布证据必须支持 `GOWORK=off`，避免依赖本地 workspace 污染。 | GOWORK 依赖导致 CI 不可复现 → release gate 阻断 |
| BR-012 | `go.mod`、版本矩阵、公开 API 文档和模块规格必须在发布后持续保持一致。 | go.mod/版本矩阵/文档不一致 → CI Gate doc check 阻断 |

## 8. 接口契约

当前实现基线以 `github.com/ZoneCNH/postgresx/pkg/postgresx` 为准：

```go
func New(ctx context.Context, cfg Config, opts ...Option) (*Client, error)
func Open(ctx context.Context, cfg Config, opts ...Option) (*Client, error)

type Client struct {
    // manages a pgxpool.Pool; fields are internal to the package
}

func (c *Client) Ping(ctx context.Context) error
func (c *Client) Close(ctx context.Context) error
func (c *Client) Stats() PoolStats
func (c *Client) Queryer() Queryer
func (c *Client) Exec(ctx context.Context, sql string, args ...any) (CommandTag, error)
func (c *Client) Query(ctx context.Context, sql string, args ...any) (Rows, error)
func (c *Client) QueryRow(ctx context.Context, sql string, args ...any) Row
func (c *Client) WithTx(ctx context.Context, fn TxFunc) error
func (c *Client) WithTxOptions(ctx context.Context, opts TxOptions, fn TxFunc) error
```

### 8.1 Config

```go
type Config struct {
    Host            string
    Port            int
    Database        string
    User            string
    Password        SecretString
    SSLMode         string
    MaxOpenConns    int32
    MinIdleConns    int32
    MaxConnLifetime time.Duration
    MaxConnIdleTime time.Duration
    ConnectTimeout  time.Duration
    HealthTimeout   time.Duration
    ApplicationName string
}

func (c Config) DSN() string
func (c Config) RedactedDSN() string
```

默认值：port 5432、sslmode disable、max open 10、min idle 1、connection lifetime 1h、idle timeout 30m、connect timeout 5s、health timeout 2s。

### 8.2 Query Interfaces

```go
type Queryer interface {
    Exec(ctx context.Context, sql string, args ...any) (CommandTag, error)
    Query(ctx context.Context, sql string, args ...any) (Rows, error)
    QueryRow(ctx context.Context, sql string, args ...any) Row
}

type Row interface {
    Scan(dest ...any) error
}

type Rows interface {
    Next() bool
    Scan(dest ...any) error
    Close()
    Err() error
}
```

### 8.3 Transactions

```go
type Tx interface {
    Queryer
}

type TxFunc func(ctx context.Context, tx Tx) error

type TxOptions struct {
    IsolationLevel string
    ReadOnly       bool
}
```

### 8.4 Migrations

```go
type Migration struct {
    Version int64
    Name    string
    UpSQL   string
}

type MigrationSource interface {
    Migrations(ctx context.Context) ([]Migration, error)
}

func NewMigrationRunner(client *Client) *MigrationRunner
func (r *MigrationRunner) Up(ctx context.Context, source MigrationSource) error
func (r *MigrationRunner) Applied(ctx context.Context) ([]AppliedMigration, error)
```

### 8.5 Options

```go
type Option func(*options)

func WithLogger(logger Logger) Option
func WithMetrics(metrics Metrics) Option
func WithClock(clock Clock) Option
```

旧文档中提到的 DSN option、环境变量式 DSN 配置和无参构造器均不属于当前基线。

## 9. 数据模型
### 9.1 Client

`Client` 封装 `pgxpool.Pool`，管理连接池生命周期。

### 9.2 Config

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| Host | string | — | PostgreSQL 主机地址 |
| Port | int | 5432 | 端口 |
| Database | string | — | 数据库名 |
| User | string | — | 用户名 |
| Password | SecretString | — | 密码（自动脱敏） |
| SSLMode | string | disable | SSL 模式 |
| MaxOpenConns | int32 | 10 | 最大连接数 |
| MinIdleConns | int32 | 1 | 最小空闲连接 |
| MaxConnLifetime | Duration | 1h | 连接最大存活时间 |
| MaxConnIdleTime | Duration | 30m | 连接最大空闲时间 |
| ConnectTimeout | Duration | 5s | 连接超时 |
| HealthTimeout | Duration | 2s | 健康检查超时 |
| ApplicationName | string | — | 应用名称 |

### 9.3 公共错误

- `ErrClosed` — Client 已关闭
- `ErrInvalidConfig` — Config 校验失败
- `ErrMigrationDuplicate` — 迁移版本重复
- `ErrMigrationInvalid` — 迁移无效
- MapError 映射：context.Canceled→ErrCanceled, pgx.ErrNoRows→ErrNotFound, pgconn 认证→ErrAuth, 约束→ErrConstraint

## 10. 配置模式
`postgresx` 通过 `Config` 结构体接收显式配置，不读取环境变量或配置文件。

```yaml
postgresx:
  host: loopback.internal
  port: 5432
  database: app
  user: app
  password: ${POSTGRES_PASSWORD}  # SecretString 自动脱敏
  ssl_mode: disable
  max_open_conns: 10
  min_idle_conns: 1
  max_conn_lifetime: 1h
  max_conn_idle_time: 30m
  connect_timeout: 5s
  health_timeout: 2s
  application_name: postgresx
```

调用方通过 `New(ctx, cfg, opts...)` 传入。`Config.RedactedDSN()` 返回密码脱敏后的连接串。

## 11. 错误处理
| 错误 | 触发条件 | 处理方式 |
| --- | --- | --- |
| `ErrClosed` | Client 已关闭后调用 | 返回稳定错误，Close 幂等 |
| `ErrInvalidConfig` | Host/Port/Database 为空 | 不创建连接池，返回参数错误 |
| `ErrCanceled` | context 取消 | 返回 context 错误，事务回滚 |
| `ErrNotFound` | 查询无结果 (pgx.ErrNoRows) | 可处理状态，非系统错误 |
| `ErrTimeout` | context deadline 或连接超时 | 返回可识别超时错误 |
| `ErrAuth` | PostgreSQL 认证失败 | 不重试，返回认证错误 |
| `ErrConstraint` | 约束冲突（unique/foreign key） | 映射为 conflict kind |
| `ErrConnection` | 连接断开或池耗尽 | 可重试，返回连接错误 |

**错误映射**：`MapError(err)` 将 pgx/pgconn 错误归一化为结构化错误 kind + retryability。
**错误消息格式**：`"postgresx: <operation>: <detail>"`

## 12. 边界情况
| 场景 | 预期行为 |
| --- | --- |
| Config Host 为空 | New 返回 `ErrInvalidConfig`，不访问 PostgreSQL |
| context 已取消 | Exec/Query 不发起或尽快停止，返回 context 错误 |
| Close 多次调用 | 幂等返回 nil 或 closed 状态 |
| 事务 fn panic | 回滚事务后重新抛出 panic |
| 迁移版本重复 | MigrationRunner 阻断，返回错误含版本号 |
| 迁移版本非正 | 拒绝执行并返回错误 |
| 迁移名称为空 | 拒绝执行并返回错误 |
| 查询返回空结果 | 返回 ErrNotFound，非系统错误 |
| Rows 未关闭 | 调用方负责 Close；Err() 查询迭代错误 |
| 连接池耗尽 | 阻塞等待空闲连接，超时后返回错误 |
| DSN/密码 日志泄露 | RedactedDSN() 脱敏，日志不含明文凭据 |

## 13. 目录结构
```text
postgresx/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── VERSION_MATRIX.md
├── Makefile
├── pkg/
│   └── postgresx/
│       ├── client.go          # Client + New/Open/Close/Ping/Stats
│       ├── config.go          # Config + DSN/RedactedDSN + defaults
│       ├── query.go           # Exec/Query/QueryRow + Queryer/Row/Rows
│       ├── tx.go              # WithTx/WithTxOptions + TxFunc/TxOptions
│       ├── migration.go       # MigrationRunner + Migration/MigrationSource
│       ├── health.go          # HealthChecker (Name + Check)
│       ├── errors.go          # MapError/IsRetryable + 错误常量
│       ├── metrics.go         # Logger/Metrics hooks
│       ├── options.go         # Option/WithLogger/WithMetrics/WithClock
│       └── *_test.go
├── internal/
│   └── testutil/
├── testdata/
├── examples/
└── docs/
```

## 14. 依赖

| 依赖 | 用途 | 约束 |
| ---- | ---- | ---- |
| Go stdlib | context、time、errors、sync/atomic | 必须保持轻量 |
| `github.com/jackc/pgx/v5` | PostgreSQL driver、pool、tx、pgconn 错误码 | 当前基线 `v5.9.2` |

禁止新增业务模块依赖。新增基座依赖必须先更新 [goal.md](./goal.md)、[TRACEABILITY.md](./TRACEABILITY.md) 与根架构文档。

## 15. 测试

| Test Case | 覆盖范围 | 验收标准 |
| --------- | -------- | -------- |
| **TC-001:** | Config 默认值、校验、DSN 和 RedactedDSN | 默认值稳定，密码脱敏，无效配置返回错误 |
| **TC-002:** | Exec、Query、QueryRow、Rows 生命周期 | 参数绑定、扫描、Err、Close 行为符合 pgx 语义 |
| **TC-003:** | WithTx / WithTxOptions | commit、rollback、context 取消、panic 回滚和 read-only 选项可验证 |
| **TC-004:** | MigrationRunner | 升序执行、幂等跳过、重复版本和无效迁移阻断 |
| **TC-005:** | HealthChecker 与 Stats | healthy/degraded/unhealthy、超时和池状态安全输出 |
| **TC-006:** | MapError / IsRetryable | context、no rows、认证、约束、序列化、连接和停机错误映射稳定 |
| **TC-007:** | Logger / Metrics hooks | 查询、事务、健康和池指标触发且不泄露 Secret |
| **TC-008:** | 边界与发布证据 | `GOWORK=off` 下测试通过，无业务反向依赖 |
| **TC-009:** | 契约一致性 | `go.mod`、版本矩阵、公开 API 文档、指标契约和代码一致 |

## 16. 性能预算

- 连接池生命周期以 `pgxpool` 为核心，默认池参数必须可被调用方覆盖。
- 查询和事务 helper 不得隐藏 context deadline，也不得引入无界 retry。
- 迁移执行必须保持确定性顺序，并阻断重复版本，避免启动期重复执行。
- v1.x 如新增性能声明，必须补充可复现 benchmark 或 live PostgreSQL evidence。

## 17. 可观测性

- `postgresx` 只暴露 logger、metrics、clock 等 hook，不绑定具体观测后端。
- 必须覆盖连接池、查询、事务、迁移和健康检查事件；事件字段不得包含明文 DSN、密码或 SQL 参数 Secret。
- 指标名已由 TASK-PG-003 冻结为 dotted `postgresx.*` 命名，后续变更必须同步代码、contract、SPEC 与 TRACEABILITY。
- 健康检查实现必须保持 `HealthChecker` 接口兼容，并保留 context 取消语义。

## 18. 安全

- Secret 输入只能来自调用方显式配置，模块内不得读取环境变量、配置文件或 Secret 文件。
- 日志、错误、健康检查和指标字段必须使用脱敏后的 DSN 或安全标签。
- SQL 参数不得进入默认日志字段；如调用方自定义 logger 记录参数，责任边界必须在调用方侧。
- 错误归一化不能泄露认证材料、连接串或私有端点。

## 19. CI 门禁

当前实现仓库 `/home/postgresx` 已作为 v1.0.0 release 验证：

- `GOWORK=off VERSION=v1.0.0 make release-evidence-check`：通过。
- `GOWORK=off VERSION=v1.0.0 make release-final-check`：通过。
- `GOWORK=off VERSION=v1.0.0 make release-preflight` 在 `POSTGRESX_REQUIRE_INTEGRATION=1` 和注入的 dev PostgreSQL DSN/凭据下通过，覆盖 `go vet`、`go test`、`go test -race`、边界检查、contract check、secret scan、contract check、template alignment 与真实 PostgreSQL integration。
- Git tag / GitHub release：`v1.0.0`，对应提交 `310a249e`。

> Factory caveat：本节为 v1.0.0 release-scope 验证；BLK-006（unit coverage 52.4% + Docker integration skip）关闭前机器事实层保持 factory=false。
> 不宣告 factory-grade。

文档修复侧必须通过：

- `rg` 检查不再出现旧 DSN option、环境变量式 DSN 配置、无参构造器或旧事务入口。
- `TRACEABILITY.md` 必须包含 `Task` 列，并覆盖 FR-001..FR-007 与 BR-001..BR-012。
- `git diff --check` 必须通过。

## 20. 升级兼容性
- `/home/postgresx` 以 `v1.0.0` tag、GitHub release 和提交 `310a249e` 为当前发布基线。
- 下游模块只允许依赖已实现的 `pkg/postgresx` 入口：显式 `Config`、连接池生命周期、SQL 执行、事务、迁移、健康检查、错误映射和可观测 hook。
- 未来 v1.x 破坏性变更必须同步 SPEC、TRACEABILITY、Task、contracts 和 release evidence，不重新打开已关闭的 v1.0 阻断项。
- `x.go` 或业务模块接入前必须新增对应追溯证据，不能把潜在消费者计入完成度。

- 本仓库不承载数据库 schema 迁移文件；运行期迁移由 `/home/postgresx/pkg/postgresx/migration.go` 的 `MigrationRunner` 负责。
- 调用方必须显式传入迁移集合和 `Config`，`postgresx` 不读取环境变量、配置文件或 Secret 文件。
- 已应用迁移表、重复版本阻断、迁移顺序和失败回滚行为以 `/home/postgresx` 当前测试为准。
- 文档迁移只涉及 SPEC、TRACEABILITY、Goal、Task 与状态表同步，不迁移应用数据。

- 当前实现基线记录为 `go 1.25.0`、`github.com/jackc/pgx/v5 v5.9.2`、。
- v1.x Public API 已冻结；任何破坏性变更都必须同步 SPEC、TRACEABILITY、Task 和 `/home/postgresx` contract 文档。
- 基座边界保持不变：`postgresx` 可以依赖 `pgx`，不得依赖业务域、入口仓库或数据域仓库。
- Release evidence 必须支持 `GOWORK=off`，避免本地 workspace 掩盖模块依赖问题。

## 21. 发布 DoD

- SPEC 保持 23 节结构，`Spec-Version` 使用 semver，且不包含模糊状态词。
- `TRACEABILITY.md` 覆盖 FR-001..FR-007、BR-001..BR-012、TC-001..TC-008，并映射 TASK-PG-001..TASK-PG-003。
- `/home/postgresx` 中 `GOWORK=off VERSION=v1.0.0 make release-evidence-check`、`make release-final-check` 与强制 integration 的 `make release-preflight` 通过。
- 本仓库 `git diff --check`、状态一致性检查、postgresx 规格 lint 和 postgresx traceability 检查通过。
- TASK-PG-003 已关闭，v1.0.0 发布声明必须继续以 tag、release evidence、contract check 和真实 PostgreSQL integration 为依据。

## 22. 待解决问题
### Resolved

| 问题 | 决策 |
|------|------|
| 指标命名 | dotted `postgresx.*` (TASK-PG-003) |
| Go baseline | go 1.25.0 |
| Public API | v1.0.0 冻结 |

### Non-blocking

| ID | 问题 | 状态 |
|----|------|------|
| OQ-001 | 下游真实接入证据（x.go/业务模块 import） | 跟踪中 |
| OQ-002 | 生产 soak 数据积累 | 跟踪中 |

## 23. 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-13 | v1.0.0 | 初始版本 | ZoneCNH |

---

## Appendix A: 评分结论

| 维度 | 修复前 | 当前发布基线 | 主要依据 |
| ---- | ------ | ------------ | -------- |
| 代码实现证据 | 82/100 | 100/100 | `/home/postgresx` 已通过 release-evidence-check、release-final-check 与强制真实 PostgreSQL integration 的 release-preflight |
| 模块文档一致性 | 41/100 | 100/100 | SPEC、TRACEABILITY、goal、TASK-PG-003、Public API、metrics contract 与版本矩阵已对齐 |
| v1.0 可冻结度 | 48/100 | 100/100 | v1.0.0 tag/GitHub release 已发布，Public API、metrics contract 与 release evidence 已冻结 |
| 综合评分 | 61/100 | 100/100 | v1.0.0 发布范围闭合；下游实际接入和生产 soak 作为发布后成熟度证据继续跟踪 |

## Appendix B: Residual Risks

| 风险 | 影响 | 处置 |
| ---- | ---- | ---- |
| 下游接入证据缺口 | `x.go` 和业务模块尚未形成真实依赖证据 | 作为发布后接入跟踪项；下游接入时补充 import、测试或发布证据 |
| 生产 soak 不足 | 当前证据覆盖本地与真实 PostgreSQL integration，尚无长期生产运行数据 | 作为 v1.x 运维证据继续积累，不降低当前 release 判定 |

---

## Appendix C: 当前结论

`postgresx` 已完成 v1.0.0 release 收束：代码、Public API、metrics contract、版本矩阵、release evidence 和真实 PostgreSQL integration 已形成闭环。v1.0.0 发布范围综合评分为 `100/100`；下游真实接入和生产 soak 作为 v1.x/post-release 成熟度证据继续跟踪，不构成当前发布扣分。

## Appendix D: Acceptance Criteria Registry

| AC ID | FR 引用 | 验收标准 | 验证方式 |
|-------|---------|----------|----------|
| AC-PGX-001 | FR-001 | New 校验配置+填充默认值+构造 pgxpool；Ping 失败关闭池；Close 幂等 | unit test |
| AC-PGX-002 | FR-002 | Exec/Query/QueryRow 保留 context 语义；Rows.Err() 暴露迭代错误 | unit test |
| AC-PGX-003 | FR-003 | fn nil 提交；fn error/cancel 回滚；fn panic 回滚后重新抛出 | unit test |
| AC-PGX-004 | FR-004 | Up 按版本升序执行；重复版本/非正版本/空名称/空SQL 拒绝 | unit test |
| AC-PGX-005 | FR-005 | HealthChecker 接口正确；Stats 不暴露密码/DSN | unit test |
| AC-PGX-006 | FR-006 | MapError 归一化；IsRetryable 语义正确 | unit test |
| AC-PGX-007 | FR-007 | 适配器记录指标；RedactedDSN 隐藏密码；日志不含完整连接串 | unit test |
