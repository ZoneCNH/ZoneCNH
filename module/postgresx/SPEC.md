# postgresx 完整规格

> 基座 · PostgreSQL 存储扩展。以 `pgxpool` 为核心，提供显式配置、连接池生命周期、SQL 执行、事务、迁移、健康检查、错误归一化与可观测适配点。

最后更新：2026-06-13

---

## 1. Metadata

- Status: Implemented
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-13
- Owner: ZoneCNH
- Layer: 基座 · 存储扩展
- Implementation-Baseline: v1.0.0 release (tag `v1.0.0`, commit `310a249e`)
- Go-Baseline: `go 1.25.0`
- Runtime Dependencies: `github.com/ZoneCNH/foundationx v0.1.1`, `github.com/jackc/pgx/v5 v5.9.2`
- Repository: [github.com/ZoneCNH/postgresx](https://github.com/ZoneCNH/postgresx)
- Related: [goal.md](./goal.md), [TRACEABILITY.md](./TRACEABILITY.md), [ARCHITECTURE.md](../../ARCHITECTURE.md)

---

## 2. 评分结论

| 维度 | 修复前 | 当前发布基线 | 主要依据 |
| ---- | ------ | ------------ | -------- |
| 代码实现证据 | 82/100 | 98/100 | `/home/postgresx` 已通过 release-evidence-check、release-final-check 与强制真实 PostgreSQL integration 的 release-preflight |
| 模块文档一致性 | 41/100 | 98/100 | SPEC、TRACEABILITY、goal、TASK-PG-003、Public API、metrics contract 与版本矩阵已对齐 |
| v1.0 可冻结度 | 48/100 | 98/100 | v1.0.0 tag/GitHub release 已发布，Public API、metrics contract 与 release evidence 已冻结 |
| 综合评分 | 61/100 | 98/100 | 仅保留下游实际接入和生产 soak 的非阻断风险 |

## 3. Summary

`postgresx` 是 ZoneCNH 基座层的 PostgreSQL 访问模块。当前实现围绕 `pgx/v5` 提供：

- 显式 `Config` 和 `New(ctx, cfg, opts...)` / `Open(ctx, cfg, opts...)` 入口。
- `Client` 结构体管理 `pgxpool.Pool` 生命周期，支持 `Ping`、`Close`、`Stats`、`Queryer`。
- `Exec`、`Query`、`QueryRow` 和调用方负责关闭的 `Rows` 抽象。
- `WithTx` / `WithTxOptions` 自动提交、回滚和 panic 回滚。
- `MigrationRunner` 执行版本化 SQL 迁移并记录已应用版本。
- `foundationx.HealthChecker` 兼容的 `Name` / `Check` 健康检查。
- `foundationx` 错误归一化、可重试判断、SecretString 脱敏、日志和指标 hook。

本模块不是 ORM，不读取环境变量或配置文件，不接管应用生命周期，不向上依赖业务仓库。

## 4. Problem

多个模块需要 PostgreSQL 访问能力。如果各自封装，会造成：

- 连接池配置、超时和关闭语义不一致。
- 事务提交、回滚和 panic 路径遗漏。
- PostgreSQL 错误码无法统一映射到 `foundationx` 错误模型。
- 迁移版本和执行记录分散，难以审计。
- 健康检查、连接池状态、查询耗时和失败指标缺少统一采集点。
- 连接串、密码或 SQL 参数存在日志泄露风险。

## 5. Goals

- 提供小而稳定的 PostgreSQL 客户端基线，直接暴露 SQL 能力而非 ORM。
- 统一连接池、配置默认值、生命周期和健康检查语义。
- 统一事务执行边界，保证 commit、rollback、context 取消和 panic 行为可测试。
- 统一迁移执行入口，保证版本单调、重复版本检测和已应用记录。
- 统一 PostgreSQL 错误映射与 retryability 判定。
- 提供日志与指标适配点，但不绑定具体可观测后端。
- 维持基座模块边界，不依赖业务域仓库或 `x.go` 入口。

## 6. Non-Goals

- 不做 ORM、Repository 生成器、SQL builder 或实体映射框架。
- 不做读写分离、数据库集群管理、备份恢复和容量治理。
- 不读取环境变量、Secret 文件或应用配置中心；调用方负责构造 `Config`。
- 不接管 `kernel` 生命周期；调用方负责在自身生命周期中调用 `New` 和 `Close`。
- 不内置 `observex`、`resiliencx`、`configx` 运行时耦合；如需集成必须通过接口适配。
- 不承诺分页、排序、审计字段、租户隔离或批处理工具进入当前 v1.0 基线。

## 7. Consumers

| 消费者 | 使用方式 | 当前约束 |
| ------ | -------- | -------- |
| `market-data` | 持久化历史行情和查询结果 | 可作为潜在下游，不形成反向依赖 |
| `signal-engine` | 存储因子计算结果和信号历史 | 通过 SQL 与事务接口调用 |
| `order-engine` | 存储订单历史和成交记录 | 事务边界由业务层决定 |
| `risk-engine` | 存储风控日志和阈值配置 | 需自行定义 schema |
| `backtest-engine` | 存储回测结果和参数 | 可复用迁移与查询接口 |
| 其他基座/业务模块 | 通过 `pkg/postgresx` 显式构造客户端 | 禁止引入业务反向依赖 |

## 8. Functional Requirements

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
THEN 模块必须符合 `foundationx.HealthChecker`，输出 healthy/degraded/unhealthy 状态、耗时和安全元数据。

WHEN `Stats()` 被调用
THEN 模块必须返回连接池快照，不暴露密码、完整 DSN 或 SQL 参数。

### FR-006: 错误归一化与可重试判断

WHEN 底层返回 PostgreSQL 或 context 错误
THEN 模块必须通过 `MapError` 映射为 `foundationx` 错误，并通过 `IsRetryable` 暴露可重试语义。

### FR-007: 可观测适配与 Secret Hygiene

WHEN 调用方传入 `WithLogger` 或 `WithMetrics`
THEN 模块必须调用适配器记录查询、事务、健康和池状态，不绑定具体后端。

WHEN 构造或记录 DSN
THEN `Config.RedactedDSN()` 必须隐藏密码，日志和指标不得包含完整连接串或 SQL 参数值。

## 9. Business Rules

| 编号 | 规则 |
| ---- | ---- |
| BR-001 | `postgresx` 不得依赖业务域仓库、入口仓库或具体应用模块。 |
| BR-002 | 模块不得读取环境变量、配置文件或 Secret 文件；调用方必须显式传入 `Config`。 |
| BR-003 | 模块不得实现 ORM、schema ownership 或全局默认数据库。 |
| BR-004 | 所有外部 I/O 入口必须接受 `context.Context` 并尊重取消、超时。 |
| BR-005 | `Rows` 生命周期由调用方关闭，模块必须保留 `Err()` 查询迭代错误。 |
| BR-006 | 事务必须只在 `fn` 返回 nil 时提交；error、context 取消和 panic 路径必须回滚。 |
| BR-007 | 迁移版本必须为正整数且单调执行；重复版本和无效迁移必须阻断。 |
| BR-008 | 健康检查必须幂等、无副作用，并只输出安全元数据。 |
| BR-009 | 指标适配必须不泄露敏感信息；代码与契约中的指标命名必须保持唯一且一致。 |
| BR-010 | PostgreSQL 错误码必须稳定映射到 `foundationx` 错误 kind 和 retryability。 |
| BR-011 | 发布证据必须支持 `GOWORK=off`，避免依赖本地 workspace 污染。 |
| BR-012 | `go.mod`、版本矩阵、公开 API 文档和模块规格必须在发布后持续保持一致。 |

## 10. Interface Contract

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

### 10.1 Config

```go
type Config struct {
    Host            string
    Port            int
    Database        string
    User            string
    Password        foundationx.SecretString
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

### 10.2 Query Interfaces

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

### 10.3 Transactions

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

### 10.4 Migrations

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

### 10.5 Options

```go
type Option func(*options)

func WithLogger(logger Logger) Option
func WithMetrics(metrics Metrics) Option
func WithClock(clock Clock) Option
```

旧文档中提到的 DSN option、环境变量式 DSN 配置和无参构造器均不属于当前基线。

## 11. Dependencies

| 依赖 | 用途 | 约束 |
| ---- | ---- | ---- |
| Go stdlib | context、time、errors、sync/atomic | 必须保持轻量 |
| `github.com/jackc/pgx/v5` | PostgreSQL driver、pool、tx、pgconn 错误码 | 当前基线 `v5.9.2` |
| `github.com/ZoneCNH/foundationx` | SecretString、HealthChecker、Error model | 当前基线 `v0.1.1` |

禁止新增业务模块依赖。新增基座依赖必须先更新 [goal.md](./goal.md)、[TRACEABILITY.md](./TRACEABILITY.md) 与根架构文档。

## 12. Test Cases

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

## 13. Verification Gates

当前实现仓库 `/home/postgresx` 已作为 v1.0.0 release 验证：

- `GOWORK=off VERSION=v1.0.0 make release-evidence-check`：通过。
- `GOWORK=off VERSION=v1.0.0 make release-final-check`：通过。
- `GOWORK=off VERSION=v1.0.0 make release-preflight` 在 `POSTGRESX_REQUIRE_INTEGRATION=1` 和注入的 dev PostgreSQL DSN/凭据下通过，覆盖 `go vet`、`go test`、`go test -race`、边界检查、contract check、secret scan、foundationx API check、template alignment 与真实 PostgreSQL integration。
- Git tag / GitHub release：`v1.0.0`，对应提交 `310a249e`。

文档修复侧必须通过：

- `rg` 检查不再出现旧 DSN option、环境变量式 DSN 配置、无参构造器或旧事务入口。
- `TRACEABILITY.md` 必须包含 `Task` 列，并覆盖 FR-001..FR-007 与 BR-001..BR-012。
- `git diff --check` 必须通过。

## 14. Residual Risks

| 风险 | 影响 | 处置 |
| ---- | ---- | ---- |
| 下游接入证据缺口 | `x.go` 和业务模块尚未形成真实依赖证据 | 作为发布后接入跟踪项；下游接入时补充 import、测试或发布证据 |
| 生产 soak 不足 | 当前证据覆盖本地与真实 PostgreSQL integration，尚无长期生产运行数据 | 作为 v1.x 运维证据继续积累，不降低当前 release 判定 |

---

## 15. 当前结论

`postgresx` 已完成 v1.0.0 release 收束：代码、Public API、metrics contract、版本矩阵、release evidence 和真实 PostgreSQL integration 已形成闭环。综合评分为 `98/100`；剩余扣分来自下游真实接入和生产 soak 尚未形成证据。

## 16. Rollout Plan

- `/home/postgresx` 以 `v1.0.0` tag、GitHub release 和提交 `310a249e` 为当前发布基线。
- 下游模块只允许依赖已实现的 `pkg/postgresx` 入口：显式 `Config`、连接池生命周期、SQL 执行、事务、迁移、健康检查、错误映射和可观测 hook。
- 未来 v1.x 破坏性变更必须同步 SPEC、TRACEABILITY、Task、contracts 和 release evidence，不重新打开已关闭的 v1.0 阻断项。
- `x.go` 或业务模块接入前必须新增对应追溯证据，不能把潜在消费者计入完成度。

## 17. Migration Plan

- 本仓库不承载数据库 schema 迁移文件；运行期迁移由 `/home/postgresx/pkg/postgresx/migration.go` 的 `MigrationRunner` 负责。
- 调用方必须显式传入迁移集合和 `Config`，`postgresx` 不读取环境变量、配置文件或 Secret 文件。
- 已应用迁移表、重复版本阻断、迁移顺序和失败回滚行为以 `/home/postgresx` 当前测试为准。
- 文档迁移只涉及 SPEC、TRACEABILITY、Goal、Task 与状态表同步，不迁移应用数据。

## 18. Observability

- `postgresx` 只暴露 logger、metrics、clock 等 hook，不绑定具体观测后端。
- 必须覆盖连接池、查询、事务、迁移和健康检查事件；事件字段不得包含明文 DSN、密码或 SQL 参数 Secret。
- 指标名已由 TASK-PG-003 冻结为 dotted `postgresx.*` 命名，后续变更必须同步代码、contract、SPEC 与 TRACEABILITY。
- 健康检查实现必须保持 `foundationx.HealthChecker` 兼容，并保留 context 取消语义。

## 19. Security

- Secret 输入只能来自调用方显式配置，模块内不得读取环境变量、配置文件或 Secret 文件。
- 日志、错误、健康检查和指标字段必须使用脱敏后的 DSN 或安全标签。
- SQL 参数不得进入默认日志字段；如调用方自定义 logger 记录参数，责任边界必须在调用方侧。
- 错误归一化不能泄露认证材料、连接串或私有端点。

## 20. Performance

- 连接池生命周期以 `pgxpool` 为核心，默认池参数必须可被调用方覆盖。
- 查询和事务 helper 不得隐藏 context deadline，也不得引入无界 retry。
- 迁移执行必须保持确定性顺序，并阻断重复版本，避免启动期重复执行。
- v1.x 如新增性能声明，必须补充可复现 benchmark 或 live PostgreSQL evidence。

## 21. Compatibility

- 当前实现基线记录为 `go 1.25.0`、`github.com/jackc/pgx/v5 v5.9.2`、`github.com/ZoneCNH/foundationx v0.1.1`。
- v1.x Public API 已冻结；任何破坏性变更都必须同步 SPEC、TRACEABILITY、Task 和 `/home/postgresx` contract 文档。
- 基座边界保持不变：`postgresx` 可以依赖 `foundationx` 和 `pgx`，不得依赖业务域、入口仓库或数据域仓库。
- Release evidence 必须支持 `GOWORK=off`，避免本地 workspace 掩盖模块依赖问题。

## 22. Open Questions

| 问题 | 当前决策 | 关闭条件 |
| ---- | -------- | -------- |
| 指标命名 | 已由 TASK-PG-003 关闭，代码、contract、SPEC、TRACEABILITY 采用 dotted `postgresx.*` 命名 | 后续变更必须同步 release evidence |
| Go baseline | `/home/postgresx/go.mod`、VERSION_MATRIX 与 release evidence 已统一到 go 1.25.0 | 升级 Go baseline 时同步版本矩阵和 release gates |
| Public API contract | 已按代码和测试冻结为 v1.0.0 contract | 新增/删除公开符号必须更新 contract 与 tests |
| 下游接入 | 仅标记为潜在消费者 | 出现真实 import、测试或发布证据 |

## 23. Definition of Done

- SPEC 保持 23 节结构，`Spec-Version` 使用 semver，且不包含模糊状态词。
- `TRACEABILITY.md` 覆盖 FR-001..FR-007、BR-001..BR-012、TC-001..TC-008，并映射 TASK-PG-001..TASK-PG-003。
- `/home/postgresx` 中 `GOWORK=off VERSION=v1.0.0 make release-evidence-check`、`make release-final-check` 与强制 integration 的 `make release-preflight` 通过。
- 本仓库 `git diff --check`、状态一致性检查、postgresx 规格 lint 和 postgresx traceability 检查通过。
- TASK-PG-003 已关闭，v1.0.0 发布声明必须继续以 tag、release evidence、contract check 和真实 PostgreSQL integration 为依据。
