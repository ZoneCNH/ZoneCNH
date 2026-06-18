# redisx 规格

Status: Approved
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-19
- Layer: 基座 · 存储扩展
- Version: v1.0.3
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `kernel`

> 公开投影 caveat：Status=Approved 表示需求追溯已闭合；发布标签仍以 `/home/redisx` 的 clean-main `release-preflight` 为准。

---

## 1. 摘要

`redisx` 是 Redis 的标准化访问和治理封装。它提供统一 KeyBuilder、typed Options、连接生命周期、KV/TTL、cache-aside、Hash/List、Pub/Sub、Pipeline、token owner 分布式锁、Counter、fixed-window RateLimitHelper、JSON 默认 Codec、自定义 Codec SPI、Health、pool stats 和低基数观测 hooks。

`redisx` 的直接 Go 依赖边界是 Go 标准库、`github.com/ZoneCNH/kernel` 和 Redis 客户端库。`configx`、`observex`、`resiliencx`、`contracts` 只能作为外部配置投影、指标命名约定、上层 adapter 或文档约束出现，不能成为 `redisx` 生产代码的直接 import。

---

## 2. 问题与背景

多个模块需要 Redis 支撑缓存、锁、计数、限流、Pub/Sub 和状态存储。如果各模块各自封装，会产生以下问题：

- Key 命名、环境隔离、版本迁移和敏感信息脱敏不一致。
- TTL 默认值、jitter、null-cache 和防击穿策略缺失，容易产生缓存穿透、击穿和雪崩。
- 分布式锁实现容易缺失 token、lease、续期和 guarded release，导致误释放或死锁。
- Redis 错误、context 超时、连接池状态和慢操作缺少统一分类和可观测证据。
- 业务模块容易直接绑定 Redis 客户端细节，后续迁移或治理成本升高。

---

## 3. 目标

- 稳定 Redis 存储扩展的 1.0 公共能力边界，覆盖 Key、Options、KV/TTL、Cache、Hash/List、Pub/Sub、Pipeline、Locker、Counter/RateLimit、Codec 与 Health。

| 目标 | 发布要求 | 对应需求 |
| --- | --- | --- |
| Key 规范 | 提供可校验、可脱敏、可版本化的 KeyBuilder | FR-001 |
| 客户端生命周期 | 提供 typed Options、New、Close、连接池、超时、TLS 和 kernel 生命周期集成 | FR-002 |
| KV 与 TTL | 提供 Get/Set/Del/Exists/Expire/TTL 和默认 TTL 策略 | FR-003, FR-004 |
| Cache | 提供 cache-aside、null-cache、GetOrLoad、防击穿控制 | FR-005 |
| Redis 基础结构 | 提供 Hash/List、Pub/Sub、Pipeline 的最小稳定封装 | FR-006, FR-007, FR-008 |
| 分布式锁 | 提供 token owner、lease、renew、Lua guarded release | FR-009 |
| 计数限流 | 提供 Counter 和 fixed-window RateLimitHelper | FR-010 |
| 序列化 | 提供 JSON 默认 Codec 和自定义 Codec SPI | FR-011 |
| 健康观测 | 提供 Health、pool stats 和低基数 hooks | FR-012 |

---

## 4. 非目标

- 不封装 Redis 的全部命令集合，只稳定 1.0 明确列出的能力。
- 不管理 Redis Cluster、Sentinel、备份、扩缩容、认证轮换或运维拓扑。
- 不承诺跨 Redis 集群的强一致锁。
- 不解析配置文件，不直接 import `configx`。
- 不直接 import `observex`、`resiliencx` 或 `contracts`；观测和弹性只通过本地接口或上层 adapter 接入。
- 不鼓励业务绕过 KeyBuilder 直接拼接 Key。
- 不把缓存一致性事件系统内建到 `redisx`；与 `kafkax`、`natsx` 等联动由上层实现。

---

## 5. 消费者

| 消费者 | 使用方式 | 关键约束 |
| --- | --- | --- |
| `schedulex` | 通过 `Locker` 实现分布式任务锁 | 必须使用 token owner 和 TTL |
| `market-data` | 缓存最新行情快照和热点对象 | 必须使用 KeyBuilder、TTL、Codec |
| `signal-engine` | 缓存因子计算中间结果 | 禁止记录完整业务 Key |
| `risk-engine` | 存储风控状态、阈值和计数 | context 超时必须可控 |
| 业务域模块 | 使用 `Client`、`CacheClient`、`Counter`、`RateLimitHelper` | 不直接依赖 Redis 客户端细节 |
| 平台 adapter | 将外部配置、观测、弹性策略投影为 redisx Options/hooks | adapter 在模块外实现 |

---

## 6. 功能需求

| ID | Requirement Statement | Acceptance Criteria | Test Case | Task |
| --- | --- | --- | --- | --- |
| FR-001 | WHEN 调用 KeyBuilder 基于 namespace/env/service/version/entity/id/purpose 构造 Key；THEN 输出确定性 Key 和脱敏 pattern，并拒绝空 segment、非法字符、超长 segment、直接业务裸 Key。 | AC-001-1: KeyBuilder 覆盖合法 Key、非法 segment、版本化 Key 和脱敏 pattern。 | TC-001 | TASK-REDISX-001 |
| FR-002 | WHEN 调用 `New(ctx, Options)`；THEN 使用 typed Options 创建 Redis client、连接池、timeout、DB、TLS、Codec 和 kernel 生命周期 hook；WHEN 多次 `Close()`；THEN 幂等释放资源。 | AC-002-1: Options 校验、New、Close、pool 参数和生命周期 hook 有单元或契约测试。 | TC-002 | TASK-REDISX-000 |
| FR-003 | WHEN 调用 KV `Get`、`Set`、`Del`；THEN 所有调用尊重 context、Codec 和错误映射；missing key 返回 `ErrNotFound`，`Del` 对不存在 Key 幂等。 | AC-003-1: Get/Set/Del 覆盖存在、不存在、序列化失败、context 取消和删除幂等。 | TC-003 | TASK-REDISX-002 |
| FR-004 | WHEN 调用 `Exists`、`Expire`、`TTL` 或使用默认 TTL 策略；THEN 返回存在数量、更新 TTL、读取 TTL，并对未显式 TTL 的缓存写入应用默认 TTL 与 jitter。 | AC-004-1: Exists/Expire/TTL/default TTL/jitter 均有测试，不允许缓存写入无意永不过期。 | TC-004 | TASK-REDISX-002 |
| FR-005 | WHEN 调用 `CacheClient.GetOrLoad`、`Set`、`Invalidate`；THEN 支持 cache-aside、null-cache、防击穿单进程合并、TTL jitter 和 Codec 解码失败处理。 | AC-005-1: CacheClient 覆盖 hit、miss、loader error、null-cache、防击穿和 Codec 错误。 | TC-005 | TASK-REDISX-003 |
| FR-006 | WHEN 调用 Hash/List 最小封装；THEN `HGet/HSet`、`LPush/LRange` 提供稳定语义，missing field/key 返回可识别状态或空结果。 | AC-006-1: Hash/List 覆盖写入、读取、缺失、范围和 context 取消。 | TC-006 | TASK-REDISX-004 |
| FR-007 | WHEN 调用 `Publish` 或 `Subscribe`；THEN 发布返回订阅者数量，订阅尊重 context cancellation，重连失败通过错误事件返回并释放资源。 | AC-007-1: Pub/Sub 覆盖发布、接收、取消、连接失败和资源释放。 | TC-007 | TASK-REDISX-004 |
| FR-008 | WHEN 调用 Pipeline 添加命令并 `Exec(ctx)`；THEN 以单次网络往返提交非原子批量命令，按排队顺序返回结果，并暴露部分错误。 | AC-008-1: Pipeline 覆盖有序结果、部分错误、context 取消和非原子语义文档。 | TC-008 | TASK-REDISX-005 |
| FR-009 | WHEN 调用 `Locker.Acquire/Renew/Release`；THEN 使用 token owner、TTL、续期和 Lua guarded release，禁止释放其他 owner 的锁。 | AC-009-1: 锁竞争、TTL 到期、续期、误释放防护和 holder token 校验均通过。 | TC-009 | TASK-REDISX-006 |
| FR-010 | WHEN 调用 Counter 或 fixed-window RateLimitHelper；THEN 原子执行 incr/add/get/reset/allow，返回 remaining/resetAt，并保证窗口 TTL。 | AC-010-1: Counter 与 RateLimitHelper 覆盖原子计数、窗口过期、并发和剩余额度。 | TC-010 | TASK-REDISX-007 |
| FR-011 | WHEN 使用默认 Codec 或注入自定义 Codec；THEN 默认 JSON 稳定，Decode 接收目标类型，自定义 Codec 错误被分类且不泄露完整 Key。 | AC-011-1: 默认 JSON、自定义 Codec、Encode/Decode 错误和错误脱敏有测试。 | TC-011 | TASK-REDISX-000, TASK-REDISX-003 |
| FR-012 | WHEN 调用 `Health(ctx)`、读取 pool stats 或执行 Redis 操作；THEN 输出 PING 状态、pool active/idle、低基数指标/log hooks 和脱敏错误。 | AC-012-1: Health、pool stats、hook 事件、指标名和低基数标签约束有测试。 | TC-012 | TASK-REDISX-008, TASK-REDISX-009 |

---

## 7. 行为约束

| ID | Rule | Acceptance Criteria | Test Case | Task |
| --- | --- | --- | --- | --- |
| BR-001 | Key 必须包含 namespace/env/service/version/entity/id 或 purpose，禁止业务直接传入裸 Key。 | AC-BR-001: 裸 Key 和非法 segment 被拒绝。 | TC-001 | TASK-REDISX-001 |
| BR-002 | 配置只能通过 typed `Options` 注入；`redisx` 不读取文件、环境变量或配置中心。 | AC-BR-002: Options 默认值和校验路径不依赖配置包。 | TC-002 | TASK-REDISX-001 |
| BR-003 | 所有网络操作必须接受 `context.Context` 并尊重取消、deadline 和超时。 | AC-BR-003: 关键操作覆盖 context cancel/deadline 测试。 | TC-003, TC-006, TC-008, TC-010 | TASK-REDISX-002, TASK-REDISX-004, TASK-REDISX-005, TASK-REDISX-007 |
| BR-004 | 缓存写入必须有明确 TTL 策略；默认 TTL 不得为无意永不过期，并应支持 jitter。 | AC-BR-004: 默认 TTL、显式 no-expire 和 jitter 语义被区分。 | TC-004, TC-005, TC-010 | TASK-REDISX-002, TASK-REDISX-003, TASK-REDISX-007 |
| BR-005 | 分布式锁必须使用唯一 holder token、TTL、续期和释放校验。 | AC-BR-005: token mismatch 时 Release 不删除锁。 | TC-009 | TASK-REDISX-006 |
| BR-006 | Pipeline 是有序、非原子批量执行；部分失败必须返回有序结果和第一个错误。 | AC-BR-006: 文档和测试覆盖非原子与部分错误。 | TC-008 | TASK-REDISX-005 |
| BR-007 | 错误必须分类并脱敏；日志、metrics 和 trace 不得包含完整 Key、连接串或凭据。 | AC-BR-007: 错误包装和 hook payload 不包含敏感值。 | TC-002, TC-005, TC-009 | TASK-REDISX-000, TASK-REDISX-003, TASK-REDISX-006 |
| BR-008 | 重试、重连和熔断只能通过本地 hooks 或上层 adapter 接入，不直接依赖 `resiliencx`。 | AC-BR-008: hook 接口可表达 retry/reconnect/circuit 事件且无禁止依赖。 | TC-012 | TASK-REDISX-008 |
| BR-009 | 指标标签必须低基数，只允许 operation、status、error_code、client、key_pattern 等字段。 | AC-BR-009: hook/metric 测试拒绝完整 Key 标签。 | TC-012 | TASK-REDISX-008 |
| BR-010 | 生产代码直接依赖仅限 stdlib、`kernel` 和 Redis client library。 | AC-BR-010: 静态依赖守卫禁止直接 import `configx/observex/resiliencx/contracts`。 | TC-002, TC-012 | TASK-REDISX-000, TASK-REDISX-008 |

---

## 8. 非功能需求

| ID | Requirement | Acceptance Criteria | Test Case | Task |
| --- | --- | --- | --- | --- |
| NFR-001 | 单元与契约测试覆盖所有公开接口、错误分类和依赖边界。 | AC-NFR-001: `go test ./...`、接口编译测试、依赖守卫通过。 | TC-002, TC-011 | TASK-REDISX-000 |
| NFR-002 | 真实 Redis 集成测试覆盖成功路径、失败路径、并发路径和 context 取消。 | AC-NFR-002: 集成测试可用 `REDIS_ADDR` 或 test harness 开启，默认短测不阻塞。 | TC-003, TC-007, TC-009, TC-010 | TASK-REDISX-009 |
| NFR-003 | 性能基线必须记录 KV、Pipeline、Locker、RateLimit 的 benchmark 预算。 | AC-NFR-003: benchmark 结果记录在发布证据，超预算需说明。 | BenchmarkKV, BenchmarkPipeline, BenchmarkLocker, BenchmarkRateLimit | TASK-REDISX-009 |
| NFR-004 | README、配置投影说明、迁移说明和发布证据齐全。 | AC-NFR-004: README 示例、CHANGELOG、DoD 证据和 task 链接完整。 | Documentation evidence | TASK-REDISX-009 |

---

## 9. 接口契约

```go
type Options struct {
    Addr            string
    DB              int
    Username        string
    Password        string
    TLSConfig       *tls.Config
    PoolSize        int
    MinIdleConns    int
    DialTimeout     time.Duration
    ReadTimeout     time.Duration
    WriteTimeout    time.Duration
    DefaultTTL      time.Duration
    TTLJitter       time.Duration
    Namespace       string
    Environment     string
    Service         string
    KeyVersion      string
    Codec           Codec
    Hooks           []Hook
}

type KeyParts struct {
    Entity  string
    ID      string
    Purpose string
}

type KeyBuilder interface {
    Build(parts KeyParts) (Key, error)
    Pattern(parts KeyParts) (string, error)
}

type Key struct {
    Raw     string
    Pattern string
}

type Codec interface {
    Encode(value any) ([]byte, error)
    Decode(data []byte, out any) error
    Name() string
}

type Client interface {
    Get(ctx context.Context, key Key, out any) error
    Set(ctx context.Context, key Key, value any, ttl time.Duration) error
    Del(ctx context.Context, keys ...Key) (int64, error)
    Exists(ctx context.Context, keys ...Key) (int64, error)
    Expire(ctx context.Context, key Key, ttl time.Duration) error
    TTL(ctx context.Context, key Key) (time.Duration, error)
    HGet(ctx context.Context, key Key, field string, out any) error
    HSet(ctx context.Context, key Key, values map[string]any, ttl time.Duration) error
    LPush(ctx context.Context, key Key, values ...any) (int64, error)
    LRange(ctx context.Context, key Key, start, stop int64, out any) error
    Publish(ctx context.Context, channel string, message any) (int64, error)
    Subscribe(ctx context.Context, channels ...string) (Subscription, error)
    Pipeline() Pipeline
    Health(ctx context.Context) HealthStatus
    PoolStats() PoolStats
    Close() error
}

type CacheClient interface {
    GetOrLoad(ctx context.Context, key Key, out any, loader LoaderFunc, ttl time.Duration) error
    Set(ctx context.Context, key Key, value any, ttl time.Duration) error
    Invalidate(ctx context.Context, keys ...Key) error
}

type Pipeline interface {
    Get(key Key, out any)
    Set(key Key, value any, ttl time.Duration)
    Del(keys ...Key)
    Exec(ctx context.Context) ([]PipelineResult, error)
}

type Locker interface {
    Acquire(ctx context.Context, key Key, ttl time.Duration) (Lock, bool, error)
    Renew(ctx context.Context, lock Lock, ttl time.Duration) error
    Release(ctx context.Context, lock Lock) error
}

type Counter interface {
    Incr(ctx context.Context, key Key, ttl time.Duration) (int64, error)
    Add(ctx context.Context, key Key, delta int64, ttl time.Duration) (int64, error)
    Get(ctx context.Context, key Key) (int64, error)
    Reset(ctx context.Context, key Key) error
}

type RateLimitHelper interface {
    Allow(ctx context.Context, key Key, limit int64, window time.Duration) (RateLimitResult, error)
}
```

Constructor contract:

```go
func New(ctx context.Context, opts Options) (Client, error)
func NewCache(client Client, opts CacheOptions) CacheClient
func NewLocker(client Client, opts LockOptions) Locker
func NewCounter(client Client) Counter
func NewRateLimitHelper(counter Counter) RateLimitHelper
```

---

## 10. 数据模型

| 数据对象 | 字段 | 语义 |
| --- | --- | --- |
| `Key` | `Raw`, `Pattern` | `Raw` 仅用于 Redis 操作；`Pattern` 用于日志和指标 |
| `Options` | 连接、超时、pool、TTL、namespace、Codec、hooks | 唯一配置入口 |
| `Lock` | `Key`, `Token`, `ExpiresAt` | 锁 owner token 和 lease 状态 |
| `PipelineResult` | `Index`, `Operation`, `KeyPattern`, `Value`, `Error` | 有序返回结果和部分错误诊断 |
| `RateLimitResult` | `Allowed`, `Limit`, `Remaining`, `ResetAt` | fixed-window 限流结果 |
| `HealthStatus` | `Ready`, `Live`, `Message`, `PoolStats` | PING 和连接池健康 |
| `PoolStats` | `Hits`, `Misses`, `Timeouts`, `TotalConns`, `IdleConns`, `StaleConns` | 连接池快照 |
| `HookEvent` | `Operation`, `Status`, `ErrorCode`, `Duration`, `KeyPattern` | 低基数观测事件 |


### 10.3 字段说明

#### HealthStatus

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| Ready | `bool` | ✅ | 服务是否就绪（可接受请求） |
| Live | `bool` | ✅ | 服务是否存活（进程运行中） |
| Message | `string` | ❌ | 健康状态描述（异常时填充原因） |

#### Message (Pub/Sub)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| Channel | `string` | ✅ | 消息所属频道 |
| Payload | `[]byte` | ✅ | 消息载荷（原始字节） |
| Pattern | `string` | ❌ | 模式匹配订阅的匹配模式 |
| Timestamp | `time.Time` | ✅ | 消息接收时间戳 |

#### 公共错误变量

| 变量 | 类型 | 可重试 | 说明 |
|------|------|--------|------|
| `ErrConnectionFailed` | `error` | ✅ | Redis 连接失败 |
| `ErrLockNotHeld` | `error` | ❌ | 锁不由调用方持有 |
| `ErrLockAcquireFailed` | `error` | ✅ | 锁获取失败（被持有） |
| `ErrPipelineEmpty` | `error` | ❌ | Pipeline 无命令 |
| `ErrSubscribeFailed` | `error` | ✅ | 订阅失败 |
| `ErrCodecNotSet` | `error` | ❌ | Codec 未配置 |

---

## 11. 配置模式

`redisx` 不读取配置源，只接受 typed `Options`。上层可以把以下外部投影解码后传入：

| 外部投影 | `Options` 字段 | 默认值 / 要求 |
| --- | --- | --- |
| `foundationx.redis.addr` | `Addr` | 必填；日志必须脱敏 |
| `foundationx.redis.db` | `DB` | 默认 0 |
| `foundationx.redis.pool.size` | `PoolSize` | 默认 10 |
| `foundationx.redis.timeout.dial` | `DialTimeout` | 默认 500ms |
| `foundationx.redis.timeout.read` | `ReadTimeout` | 默认 500ms |
| `foundationx.redis.timeout.write` | `WriteTimeout` | 默认 500ms |
| `foundationx.redis.default_ttl` | `DefaultTTL` | 缓存写入必须明确 |
| `foundationx.redis.ttl_jitter` | `TTLJitter` | 默认 0，推荐开启 |
| `foundationx.redis.namespace` | `Namespace` | 必填 |
| `foundationx.redis.environment` | `Environment` | 必填 |
| `foundationx.redis.service` | `Service` | 必填 |
| `foundationx.redis.key_version` | `KeyVersion` | 默认 `v1` |
| `foundationx.redis.codec` | `Codec` | 默认 JSON |

约束：

- `redisx` 生产代码不得 import `configx`。
- 连接串、用户名、密码不得出现在日志、错误、metric label 或 trace tag 中。
- 配置校验失败必须在 `New(ctx, Options)` 返回可分类错误，不访问 Redis。


### 11.1 Go Config 结构体

```go
// Config redisx 模块配置
type Config struct {
    Addr               string        `mapstructure:"addr" yaml:"addr"`
    PasswordEnv        string        `mapstructure:"password_env" yaml:"password_env"`
    DB                 int           `mapstructure:"db" yaml:"db"`
    PoolSize           int           `mapstructure:"pool_size" yaml:"pool_size"`
    MinIdleConns       int           `mapstructure:"min_idle_conns" yaml:"min_idle_conns"`
    MaxRetries         int           `mapstructure:"max_retries" yaml:"max_retries"`
    ReadTimeout        time.Duration `mapstructure:"read_timeout" yaml:"read_timeout"`
    WriteTimeout       time.Duration `mapstructure:"write_timeout" yaml:"write_timeout"`
    DialTimeout        time.Duration `mapstructure:"dial_timeout" yaml:"dial_timeout"`
    HealthCheckInterval time.Duration `mapstructure:"health_check_interval" yaml:"health_check_interval"`
    Codec              string        `mapstructure:"codec" yaml:"codec"`
}

// Validate 校验配置合法性
func (c *Config) Validate() error {
    if c.Addr == "" {
        return errors.New("redisx: addr is required")
    }
    if c.PoolSize < 1 {
        return errors.New("redisx: pool_size must be >= 1")
    }
    if c.Codec != "" && c.Codec != "json" && c.Codec != "msgpack" && c.Codec != "protobuf" {
        return fmt.Errorf("redisx: unsupported codec: %s", c.Codec)
    }
    return nil
}

// DefaultConfig 返回默认配置
func DefaultConfig() Config {
    return Config{
        DB:                 0,
        PoolSize:           10,
        MinIdleConns:       2,
        MaxRetries:         3,
        ReadTimeout:        3 * time.Second,
        WriteTimeout:       3 * time.Second,
        DialTimeout:        5 * time.Second,
        HealthCheckInterval: 10 * time.Second,
        Codec:              "json",
    }
}
```

---

## 12. 错误处理

| 错误 | 场景 | 处理要求 |
| --- | --- | --- |
| `ErrInvalidOptions` | Options 缺失地址、namespace 或 timeout 非法 | 不访问 Redis，返回参数错误 |
| `ErrInvalidKey` | Key segment 空、过长、非法字符、裸 Key | 不访问 Redis，返回参数错误 |
| `ErrNotFound` | Redis nil、key 或 hash field 不存在 | 可处理状态，不记录为系统错误 |
| `ErrClosed` | Client 已关闭后继续调用 | 返回稳定错误，Close 幂等 |
| `ErrTimeout` | context deadline 或 Redis 超时 | 返回可识别超时错误 |
| `ErrSerialization` | Codec Encode/Decode 失败 | 不重试，错误脱敏 |
| `ErrDependency` | Redis 连接、认证、网络或命令失败 | 包装原始错误类型但不泄露敏感值 |
| `ErrLockNotHeld` | token mismatch、lease 丢失、释放非 owner 锁 | 不删除 Redis 锁 |
| `ErrRateLimited` | fixed-window 不允许通过 | 返回业务可处理状态 |

所有错误必须可用 `errors.Is` 或稳定 error code 判断。错误消息和 hook payload 只能使用 key pattern，不得包含完整 Key。

---

## 13. 边界情况

| Edge Case | 预期行为 |
| --- | --- |
| Options 地址为空 | `New` 返回 `ErrInvalidOptions`，不访问 Redis |
| Key segment 为空或含非法字符 | KeyBuilder 返回 `ErrInvalidKey` |
| Key 超长 | KeyBuilder 拒绝并返回脱敏错误 |
| `Get` missing key | 返回 `ErrNotFound`，不作为系统错误计数 |
| Codec Decode 目标类型错误 | 返回 `ErrSerialization`，不泄露完整 Key |
| context 已取消 | 不发起或尽快停止 Redis 操作，返回 context 错误 |
| `Close` 多次调用 | 幂等返回 nil 或稳定 closed 状态 |
| TTL 为 0 | 仅在显式允许 no-expire 的 API 路径中有效 |
| Pipeline 部分命令失败 | 返回有序结果和第一个错误 |
| Lock token mismatch | `Release` 不删除锁，返回 `ErrLockNotHeld` |
| Subscribe ctx 取消 | 关闭 subscription 并释放连接 |
| RateLimitHelper 并发冲突 | 原子计数，remaining 和 resetAt 一致 |
| Hook panic | hook 执行不得破坏 Redis 操作结果，应转换为内部诊断 |

---

## 14. 目录结构
```text
redisx/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go                      # 包级文档
├── redisx.go                    # New/Client 工厂
├── options.go                   # Options 结构体与校验
├── key.go                       # Key/KeyParts/KeyBuilder
├── key_test.go
├── client.go                    # Client 实现
├── client_test.go
├── cache.go                     # CacheClient 实现
├── cache_test.go
├── locker.go                    # Locker 实现（token owner + Lua）
├── locker_test.go
├── counter.go                   # Counter + RateLimitHelper 实现
├── counter_test.go
├── pipeline.go                  # Pipeline 实现
├── pipeline_test.go
├── codec.go                     # Codec 接口 + JSON 默认实现
├── codec_test.go
├── errors.go                    # 公共错误变量
├── health.go                    # Health/PoolStats
├── hooks.go                     # Hook 接口与事件定义
├── internal/
│   └── pubsub/                  # Pub/Sub 内部实现
├── testdata/
│   └── redis.conf
├── example_test.go
└── benchmark_test.go
```

## 15. 测试

| Test Case | 覆盖 | 类型 | 任务 |
| --- | --- | --- | --- |
| **TC-001:** | KeyBuilder 合法/非法 segment、版本、pattern | Unit | TASK-REDISX-001 |
| **TC-002:** | Options、New、Close、pool、lifecycle hook | Unit/Contract | TASK-REDISX-000 |
| **TC-003:** | Get/Set/Del、ErrNotFound、Codec、context | Unit/Integration | TASK-REDISX-002 |
| **TC-004:** | Exists/Expire/TTL/default TTL/jitter | Unit/Integration | TASK-REDISX-002 |
| **TC-005:** | Cache hit/miss/null-cache/GetOrLoad 防击穿 | Unit/Integration | TASK-REDISX-003 |
| **TC-006:** | Hash/List 写入、读取、缺失和取消 | Integration | TASK-REDISX-004 |
| **TC-007:** | Publish/Subscribe、取消、失败事件、资源释放 | Integration | TASK-REDISX-004 |
| **TC-008:** | Pipeline 有序结果、部分错误、非原子语义 | Integration | TASK-REDISX-005 |
| **TC-009:** | Lock acquire/renew/release、token mismatch、TTL | Concurrency/Integration | TASK-REDISX-006 |
| **TC-010:** | Counter、RateLimit、并发、窗口 TTL | Concurrency/Integration | TASK-REDISX-007 |
| **TC-011:** | JSON Codec、自定义 Codec、Encode/Decode 错误 | Unit | TASK-REDISX-000, TASK-REDISX-003 |
| **TC-012:** | Health、PoolStats、HookEvent、指标名 | Unit/Integration | TASK-REDISX-008, TASK-REDISX-009 |
| BR-001 guard | 裸 Key 和非法 segment 拒绝 | Unit | TASK-REDISX-001 |
| BR-002 guard | Options-only 配置入口 | Static/Unit | TASK-REDISX-001 |
| BR-003 guard | 网络操作 context cancel/deadline | Unit/Integration | TASK-REDISX-002, TASK-REDISX-004, TASK-REDISX-005, TASK-REDISX-007 |
| BR-004 guard | TTL 默认、显式无过期和 jitter | Unit/Integration | TASK-REDISX-002, TASK-REDISX-003, TASK-REDISX-007 |
| BR-005 guard | Lock token owner 和 release guard | Concurrency | TASK-REDISX-006 |
| BR-006 guard | Pipeline 部分失败与非原子语义 | Integration | TASK-REDISX-005 |
| BR-007 guard | 错误脱敏与分类 | Unit/Static | TASK-REDISX-000, TASK-REDISX-003, TASK-REDISX-006 |
| BR-008 guard | retry/reconnect/circuit 事件通过本地 hook 表达 | Unit | TASK-REDISX-008 |
| BR-009 guard | 指标低基数标签约束 | Unit/Static | TASK-REDISX-008 |
| BR-010 guard | 禁止直接依赖 configx/observex/resiliencx/contracts | Static | TASK-REDISX-000, TASK-REDISX-008 |
| NFR-001 evidence | 公开接口、错误、依赖边界编译和静态守卫 | Static/Unit | TASK-REDISX-000 |
| NFR-002 evidence | 真实 Redis 集成、失败路径、并发路径 | Integration | TASK-REDISX-009 |
| NFR-003 evidence | KV、Pipeline、Locker、RateLimit benchmark | Benchmark | TASK-REDISX-009 |
| NFR-004 evidence | README、CHANGELOG、发布 DoD 证据 | Documentation | TASK-REDISX-009 |



### 15.5 测试工具

| 工具 | 用途 |
|------|------|
| `testing` + `testify` | 单元测试框架与断言 |
| `testkitx` | 测试辅助工具（FakeClock、Mock 等） |
| `go tool cover` | 覆盖率统计 |
| `go test -race` | 竞态检测 |
| `golangci-lint` | 静态分析与 lint |

### 15.6 测试数据

| 文件 | 用途 |
|------|------|
| `testdata/redis.conf` | 集成测试用 Redis 服务配置（最小化配置，仅绑定 6379） |


---

## 16. 性能预算

| 场景 | 预算 | 验证 |
| --- | --- | --- |
| KeyBuilder | p95 < 5us，无堆外资源 | `BenchmarkKeyBuilder` |
| JSON Codec 小对象 | p95 < 500us，错误可分类 | `BenchmarkJSONCodec` |
| KV Get/Set 本地 Redis | p95 < 10ms，p99 < 30ms | `BenchmarkKV` |
| Pipeline 10 命令 | 相比串行至少减少 50% round-trip 时间 | `BenchmarkPipeline` |
| Locker Acquire/Release | p95 < 20ms，竞争路径无误释放 | `BenchmarkLocker` |
| RateLimitHelper | p95 < 10ms，并发下计数正确 | `BenchmarkRateLimit` |
| Hook 开销 | 空 hook p95 < 1us | `BenchmarkHook` |

性能预算作为发布证据。不同机器或 Redis 环境下超预算时，必须记录环境和原因，不得静默忽略。

---

## 17. 可观测性

`redisx` 通过本地 hooks 输出事件，上层 adapter 可以转接到日志、metrics 或 trace 系统。生产代码不得直接 import `observex`。

指标命名约定：

| 指标 | 类型 | 标签 |
| --- | --- | --- |
| `foundationx_redis_operation_seconds` | histogram | `operation`, `status`, `client`, `key_pattern` |
| `foundationx_redis_operation_total` | counter | `operation`, `status`, `error_code`, `client` |
| `foundationx_redis_errors_total` | counter | `operation`, `error_code`, `client` |
| `foundationx_redis_pool_active` | gauge | `client` |
| `foundationx_redis_pool_idle` | gauge | `client` |
| `foundationx_redis_lock_acquire_total` | counter | `status`, `client`, `key_pattern` |
| `foundationx_redis_ratelimit_allowed_total` | counter | `status`, `client`, `key_pattern` |

允许的低基数标签只有 `operation`、`status`、`error_code`、`client`、`key_pattern`。禁止使用完整 Key、Redis addr、用户名、payload、业务用户 ID 作为标签。

---

## 18. 安全

- 连接地址、用户名、密码、完整 Key、payload 内容不得写入日志、metric label 或 trace tag。
- `KeyBuilder.Pattern` 是观测唯一允许使用的 Key 表示。
- Lock token 必须使用不可预测随机值，不能由业务 ID 直接派生。
- Lua guarded release 必须先比较 token，再删除锁。
- Pub/Sub payload 不在 redisx 内记录，只记录 channel 和 payload size。
- README 与样例不得包含真实 Redis 凭据、内网地址或个人路径。

---

## 19. CI 门禁

最小门禁：

- `go test ./...`
- `go test -race ./...`
- `go test -run Integration ./...`，需要 Redis 时通过 `REDIS_ADDR` 或 test harness 显式开启。
- `go test -bench . ./... -run '^$'` 生成性能证据。
- 静态依赖守卫：生产代码不得 import `configx`、`observex`、`resiliencx`、`contracts` 或业务域模块。
- 文档守卫：`SPEC.md`、`TRACEABILITY.md`、task specs、`module/README.md` 的 FR、BR、NFR、Task ID 必须一致。
- `git diff --check`

---

## 20. 升级兼容性
1. 先发布 `Options`、`KeyBuilder`、`Codec`、错误模型和只读 Health，冻结公共契约。
2. 迁移下游缓存调用到 KeyBuilder 和 KV/TTL API，禁止继续裸 Key。
3. 迁移分布式锁到 token owner Locker，并保留旧锁 key 的 TTL 过渡窗口。
4. 迁移计数和限流到 Counter/RateLimitHelper，记录窗口 key pattern。
5. 接入上层配置投影和观测 adapter，但保持 `redisx` 内部无禁止依赖。
6. 发布前运行集成、race、benchmark 和依赖守卫，归档证据。

Rollback 策略：

- 公共 API 未冻结前允许回滚到旧封装。
- Key 版本升级必须通过 `KeyVersion` 产生新 Key namespace，不直接覆盖旧 Key。
- Lock 迁移必须等待旧锁 TTL 自然过期，禁止强删未知 owner 锁。

### Tracing

| Span 名 | 父 Span | 说明 |
|---------|---------|------|
| `redisx.command` | caller span | 单次 Redis 命令执行（含序列化/网络往返/反序列化） |
| `redisx.pipeline.exec` | `redisx.command` | Pipeline 批量执行（含所有入队命令） |
| `redisx.lock.acquire` | `redisx.command` | 分布式锁获取（含 Lua 脚本执行） |
| `redisx.lock.release` | `redisx.command` | 分布式锁释放 |

**Tracing 属性**：

| 属性名 | 类型 | 说明 |
|--------|------|------|
| `redisx.key` | string | 操作的 key 名称（不含值；已脱敏） |
| `redisx.command` | string | Redis 命令名（如 GET、SET、HSET） |
| `redisx.duration_ms` | float64 | 命令耗时（毫秒） |
| `redisx.pipeline.size` | int | Pipeline 中命令数量 |
| `redisx.lock.result` | string | 锁操作结果（acquired / failed / released） |

---

- Go module 路径为 `github.com/ZoneCNH/redisx`。
- Go 版本跟随仓库当前治理基线。
- 默认 Redis client library 为 `github.com/redis/go-redis/v9`；替换 Redis 客户端必须保持公共接口和错误语义兼容。
- 1.0 后 `Client`、`CacheClient`、`Locker`、`Counter`、`RateLimitHelper`、`KeyBuilder`、`Codec`、`HealthStatus` 为稳定契约。
- 新增 Redis 命令必须通过新 task spec 和追溯矩阵进入，不得扩大既有 task scope。

---

## 21. 发布 DoD

- `goal.md`、`SPEC.md`、`TRACEABILITY.md`、10 个 task spec 和 `module/README.md` 的 12 FR、10 BR、4 NFR、10 task 映射一致。
- 每个 FR 至少有 AC、TC、Task，且 task 文件存在。
- 每个 task spec 引用不超过 3 个 FR，文件 scope 不超过 5 个文件，并包含 Scope、Non-Scope、Test Plan、Done Evidence。
- 生产代码直接依赖仅限 stdlib、`kernel` 和 Redis client library。
- 所有公开接口、错误模型、配置投影、观测 hooks、性能预算和迁移策略均有测试或发布证据。
- `git diff --check` 通过。
- 四源结构评分和 `pipeline-arbiter` 通过后，才可将 Status 翻转为 Approved。

Open Questions: none blocking.

## 22. 待解决问题
### Current

无阻塞性问题。

### Future

| ID | 问题 | 状态 |
|----|------|------|
| OQ-001 | 是否需要支持 Redis Cluster 模式？ | 待评估 |
| OQ-002 | Pipeline 是否需要支持原子事务（MULTI/EXEC）？ | 待评估 |
| OQ-003 | 是否需要 Redis Stream 封装？ | 待评估 |

---

## 23. 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-06-12 | v1.0.0 | 对齐 12 FR、10 BR、4 NFR、10 个任务和依赖边界 | Codex |

---

## Appendix A: Risks & Mitigations

| 风险 | 影响 | 缓解 |
| --- | --- | --- |
| Redis 客户端行为泄漏到公共 API | 后续替换困难 | 公共接口只暴露 redisx 类型和稳定错误 |
| 业务绕过 KeyBuilder | Key 无法治理和脱敏 | Client API 接收 `Key` 而非裸 string |
| 锁误释放其他 owner 的锁 | 数据竞争或重复执行 | token owner + Lua guarded release |
| 缓存默认无 TTL | 内存无限增长 | 默认 TTL 策略和静态/单测守卫 |
| 指标标签高基数 | 观测系统成本失控 | 仅允许 key pattern 和固定标签 |
| 直接依赖治理模块 | 破坏 foundation deps | 依赖守卫和 task 非目标约束 |
| 集成测试依赖 Redis 环境 | CI 不稳定 | 短测默认跳过真实 Redis，集成由显式 env 开启 |

### Breaking Change 迁移指南

| 变更类型 | 迁移步骤 |
|----------|----------|
| Client 接口删除/修改方法 | 1) 在 `CHANGELOG.md` 标记 DEPRECATED；2) 保留旧方法一个 MINOR 版本，标记为 `// Deprecated:`；3) 下一 MAJOR 版本移除；4) 通知所有消费者模块更新引用 |
| Pipeline 接口变更 | 同 Client 接口流程 |
| Locker 接口变更 | 同 Client 接口流程 |
| 默认 codec 变更 | 1) MINOR 版本 bump；2) CHANGELOG 中说明序列化兼容性影响；3) 消费者可通过 `WithCodec()` 显式覆盖回旧 codec |
