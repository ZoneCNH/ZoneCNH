# redisx 完整规格

> 基座 · 存储扩展。Redis 客户端封装，提供统一的连接管理、序列化、健康检查和可观测集成。

最后更新：2026-06-07

---

## 1. Metadata

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-07
- Owner: ZoneCNH
- Layer: L1 存储扩展（基座）
- Version: v0.7.3
- Repository: [github.com/ZoneCNH/redisx](https://github.com/ZoneCNH/redisx)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md)

---

### 1.1 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-07 | v1.0.0 | 初始版本 | ZoneCNH |

## 2. Summary

`redisx` 封装 Redis 客户端，提供统一的连接管理、序列化/反序列化、健康检查和可观测集成。支持基本 KV 操作、Hash 操作、List 操作、Pub/Sub、Pipeline 批量操作和分布式锁。与 kernel 生命周期集成，保证连接池随应用启停。

---

## 3. Problem

70+ 模块中有多个需要使用 Redis（缓存、状态存储、分布式锁、Pub/Sub），各自封装会导致：

- 连接池配置不一致，部分模块创建过多连接
- 序列化方式不统一（JSON / msgpack / protobuf 混用）
- 健康检查各自为政，无法统一报告 Redis 可用性
- 可观测集成缺失，Redis 延迟和错误无法被 metrics 采集
- 分布式锁实现重复且存在安全隐患

---

## 4. Goals

- 提供统一的 Redis 客户端封装，覆盖 KV、Hash、List、Pub/Sub 操作
- Pipeline 批量操作支持，减少网络往返
- 分布式锁（供 schedulex 等模块使用）
- 统一序列化/反序列化（可配置 codec）
- 健康检查（PING）集成到 kernel 健康体系
- 可观测集成（metrics、tracing、logging）
- 与 kernel 生命周期集成（连接池随应用启停）

---

## 5. Non-goals

- 不做 Redis 集群管理（Sentinel / Cluster 由运维配置）
- 不做 Redis 数据结构抽象（直接暴露 Redis 命令）
- 不做缓存策略（业务层决定 TTL、淘汰策略）
- 不做 Redis 模块加载或脚本管理
- 不做配置解析（→ `configx`）

---

## 6. Consumers

| 消费者 | 使用方式 |
|--------|----------|
| `schedulex` | 通过 `Locker` 实现分布式任务锁 |
| `market-data` | 缓存最新行情快照 |
| `signal-engine` | 缓存因子计算中间结果 |
| `risk-engine` | 存储风控状态和阈值 |
| 业务域模块 | 通过 `Client` 接口进行 KV/Hash/List/PubSub 操作 |

---

## 7. Functional Requirements

### FR-001: Get

WHEN 调用 `Get(ctx, key)` 且 key 存在
THEN 返回对应的字符串值，error 为 nil

WHEN 调用 `Get(ctx, key)` 且 key 不存在
THEN 返回 `redis.Nil` 错误

WHEN 调用 `Get(ctx, key)` 且连接不可用
THEN 返回连接错误

### FR-002: Set

WHEN 调用 `Set(ctx, key, value, ttl)` 且 ttl > 0
THEN 设置 key-value 并设置过期时间，返回 nil

WHEN 调用 `Set(ctx, key, value, ttl)` 且 ttl = 0
THEN 设置 key-value，不设置过期时间，返回 nil

WHEN 调用 `Set(ctx, key, value, ttl)` 且 value 不可序列化
THEN 返回序列化错误

### FR-003: Del

WHEN 调用 `Del(ctx, keys...)` 且部分 key 存在
THEN 删除存在的 key，返回 nil（不报错）

WHEN 调用 `Del(ctx, keys...)` 且所有 key 不存在
THEN 返回 nil（幂等）

### FR-004: Exists

WHEN 调用 `Exists(ctx, keys...)` 且连接正常
THEN 返回存在的 key 数量（含 0）

WHEN 调用 `Exists(ctx, keys...)` 且连接不可用
THEN 返回连接错误

### FR-005: Expire

WHEN 调用 `Expire(ctx, key, ttl)` 且 key 存在
THEN 设置过期时间，返回 nil

WHEN 调用 `Expire(ctx, key, ttl)` 且 key 不存在
THEN 返回 nil（不报错）

### FR-006: HGet / HSet

WHEN 调用 `HGet(ctx, key, field)` 且 field 存在
THEN 返回字段值

WHEN 调用 `HGet(ctx, key, field)` 且 field 不存在
THEN 返回 `redis.Nil`

WHEN 调用 `HSet(ctx, key, values...)`
THEN 设置 hash 字段，返回 nil

### FR-007: LPush / LRange

WHEN 调用 `LPush(ctx, key, values...)`
THEN 将值插入列表头部，返回 nil

WHEN 调用 `LRange(ctx, key, start, stop)` 且列表存在
THEN 返回指定范围的元素

WHEN 调用 `LRange(ctx, key, start, stop)` 且列表不存在
THEN 返回空切片

### FR-008: Subscribe

WHEN 调用 `Subscribe(ctx, channels...)` 且连接正常
THEN 返回消息 channel，error 为 nil

WHEN 订阅后连接断开
THEN 自动重连，重连失败时通过 channel 发送错误

WHEN ctx 被取消
THEN 关闭订阅，释放资源

### FR-009: Pipeline

WHEN 调用 `Pipeline()` 获取 Pipeline 实例
THEN 返回新的 Pipeline

WHEN 调用 `pipeline.Exec(ctx)` 且所有命令成功
THEN 按顺序返回所有命令结果

WHEN 调用 `pipeline.Exec(ctx)` 且部分命令失败
THEN 返回已成功的命令结果和第一个错误

### FR-010: Locker.Acquire

WHEN 调用 `Acquire(ctx, key, ttl)` 且锁未被持有
THEN 获取锁成功，返回 true

WHEN 调用 `Acquire(ctx, key, ttl)` 且锁已被其他持有者持有
THEN 返回 false

WHEN 锁持有者崩溃（ttl 到期）
THEN 锁自动释放

### FR-011: Locker.Release

WHEN 调用 `Release(ctx, key)` 且当前持有者为调用方
THEN 释放锁，返回 nil

WHEN 调用 `Release(ctx, key)` 且当前持有者不是调用方
THEN 返回错误，不释放锁（防止误释放）

### FR-012: Health

WHEN 调用 `Health()` 且 Redis PING 成功
THEN 返回 HealthStatus{Ready: true, Live: true}

WHEN 调用 `Health()` 且 Redis 不可达
THEN 返回 HealthStatus{Ready: false, Live: false, Message: "..."}

---

## 8. Business Rules

### BR-001: 连接池大小

**约束**：连接池大小通过配置控制，默认值为 10。配置值必须 ≥ 1。

**违反时**：
- DESIGN-TIME：`pool_size` 配置值 < 1 时，`Validate()` 返回配置校验错误，模块初始化失败
- RUNTIME：连接池耗尽时，调用方等待至有空闲连接或超时返回 `ErrConnectionFailed`

### BR-002: 序列化 Codec

**约束**：序列化/反序列化使用可配置 Codec 接口，默认使用 JSON codec。

**违反时**：
- 未配置 codec 时自动使用 JSON 默认实现（不报错）
- codec 配置为不支持的类型时，`Validate()` 返回 `"unsupported codec: {name}"`
- 序列化失败时返回 `ErrCodecNotSet` 或序列化错误

### BR-003: Context 传播

**约束**：所有 Redis 操作必须接受 `context.Context`，支持超时和取消。

**违反时**：
- DESIGN-TIME：接口方法缺少 `context.Context` 参数导致编译失败（编译器强制）
- RUNTIME：ctx 超时时返回 `context.DeadlineExceeded`；ctx 取消时返回 `context.Canceled`

### BR-004: 分布式锁唯一持有者标识

**约束**：分布式锁必须使用唯一持有者标识（UUID），防止误释放。

**违反时**：
- 非持有者调用 `Release()` 返回 `ErrLockNotHeld`，不释放锁
- 持有者标识通过 Lua 脚本原子校验，不可绕过

### BR-005: 分布式锁 TTL

**约束**：分布式锁必须设置 TTL，防止持有者崩溃导致死锁。

**违反时**：
- `Acquire(ctx, key, ttl)` 签名强制 TTL 参数（编译器检查）
- TTL 到期后锁自动释放（Redis key 过期机制保障）

### BR-006: Pipeline 原子性

**约束**：Pipeline 单次网络往返发送所有入队命令。

**违反时**：
- Pipeline.Exec 返回时保证所有命令已发送到 Redis（单次网络往返）
- 连接断开时已入队命令丢失，返回连接错误
- 部分命令执行失败时，返回已成功命令的结果和第一个错误

### BR-007: Health 幂等性

**约束**：`Health()` 必须是幂等的、无副作用的。

**违反时**：
- 实现不得在 Health() 中修改任何 Redis 数据或连接状态
- 连续两次调用返回一致的健康状态（允许因网络变化导致的不同结果，但不允许因调用本身改变状态）
- 代码审查验证 Health() 中仅包含 PING 和只读操作

### BR-008: 自动重连

**约束**：连接断开时自动重连，重连策略（最大重试次数、重连间隔）可通过 Option 配置。

**违反时**：
- 重连失败次数达到 `MaxRetries` 上限时，后续操作直接返回 `ErrConnectionFailed` 而不阻塞
- 未配置重连策略时使用默认值（MaxRetries=3，间隔 1s 指数退避）

### BR-009: 错误消息安全

**约束**：错误消息不包含 key 的实际值，仅包含 key 名称或操作上下文。

**违反时**：
- 代码审查：任何 `fmt.Errorf` / `errors.New` 中使用 `%v` / `%s` 拼接 key 实际值的，标记为安全缺陷
- CI Gate：gitleaks 扫描错误消息格式串
- 错误消息格式统一为 `"redisx: <operation>: <detail>"`，`<detail>` 中禁止包含敏感数据

---

## 9. Interface Contract

```go
type Client interface {
    Get(ctx context.Context, key string) (string, error)
    Set(ctx context.Context, key string, value any, ttl time.Duration) error
    Del(ctx context.Context, keys ...string) error
    Exists(ctx context.Context, keys ...string) (int64, error)
    Expire(ctx context.Context, key string, ttl time.Duration) error
    HGet(ctx context.Context, key, field string) (string, error)
    HSet(ctx context.Context, key string, values ...any) error
    LPush(ctx context.Context, key string, values ...any) error
    LRange(ctx context.Context, key string, start, stop int64) ([]string, error)
    Subscribe(ctx context.Context, channels ...string) (<-chan Message, error)
    Pipeline() Pipeline
    Health() HealthStatus
    Close() error
}

type Pipeline interface {
    Get(key string) *StringCmd
    Set(key string, value any, ttl time.Duration) *StatusCmd
    Exec(ctx context.Context) ([]Cmder, error)
}

type Locker interface {
    Acquire(ctx context.Context, key string, ttl time.Duration) (bool, error)
    Release(ctx context.Context, key string) error
}

type Message struct {
    Channel   string
    Payload   []byte
    Pattern   string
    Timestamp time.Time
}

type HealthStatus struct {
    Ready   bool
    Live    bool
    Message string
}

func New(opts ...Option) Client
func NewLocker(client Client, opts ...LockerOption) Locker
```text

### 9.1 Option 模式

```go
type Option func(*config)

func WithAddr(addr string) Option
func WithPassword(password string) Option
func WithDB(db int) Option
func WithPoolSize(size int) Option
func WithCodec(codec Codec) Option
func WithHealthCheckInterval(d time.Duration) Option
func WithMaxRetries(n int) Option
func WithReadTimeout(d time.Duration) Option
func WithWriteTimeout(d time.Duration) Option
```text

### 9.2 用法示例

```go
// 创建客户端
client := redisx.New(
    redisx.WithAddr(os.Getenv("FOUNDATIONX_REDIS_ADDR")),
    redisx.WithPoolSize(20),
)

// 基本操作
client.Set(ctx, "user:1:name", "alice", 10*time.Minute)
name, err := client.Get(ctx, "user:1:name")

// Hash 操作
client.HSet(ctx, "user:1", "name", "alice", "age", "30")
name, _ = client.HGet(ctx, "user:1", "name")

// Pipeline 批量操作
pipe := client.Pipeline()
pipe.Set("key1", "val1", 0)
pipe.Set("key2", "val2", 0)
results, err := pipe.Exec(ctx)

// 分布式锁
locker := redisx.NewLocker(client)
if ok, _ := locker.Acquire(ctx, "task:cleanup", 30*time.Second); ok {
    defer locker.Release(ctx, "task:cleanup")
    // 执行受保护的操作
}

// Pub/Sub
ch, _ := client.Subscribe(ctx, "events:order")
for msg := range ch {
    fmt.Printf("received: %s\n", msg.Payload)
}
```text

---

## 10. Data Model

### 10.1 公共错误

```go
var (
    ErrConnectionFailed  = errors.New("redisx: connection failed")
    ErrLockNotHeld       = errors.New("redisx: lock not held by caller")
    ErrLockAcquireFailed = errors.New("redisx: lock acquire failed")
    ErrPipelineEmpty     = errors.New("redisx: pipeline is empty")
    ErrSubscribeFailed   = errors.New("redisx: subscribe failed")
    ErrCodecNotSet       = errors.New("redisx: codec not configured")
)
```text

### 10.2 Codec 接口

```go
type Codec interface {
    Marshal(v any) ([]byte, error)
    Unmarshal(data []byte, v any) error
}
```text


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

## 11. Config Schema

```yaml
redisx:
  addr: "${FOUNDATIONX_REDIS_ADDR}" # Redis 地址
  password_env: REDIS_PASSWORD # 密码通过环境变量注入
  db: 0                        # 数据库编号
  pool_size: 10                # 连接池大小
  min_idle_conns: 2            # 最小空闲连接数
  max_retries: 3               # 最大重试次数
  read_timeout: 3s             # 读超时
  write_timeout: 3s            # 写超时
  dial_timeout: 5s             # 连接超时
  health_check_interval: 10s   # 健康检查周期
  codec: json                  # 序列化方式：json / msgpack / protobuf
```text


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

## 12. Error Handling

| 错误 | 调用方处理 |
|------|-----------|
| `ErrConnectionFailed` | 检查 Redis 地址和网络，确认 Redis 服务运行中 |
| `redis.Nil` | key 不存在，不是错误，调用方应处理空值 |
| `ErrLockNotHeld` | 确认是否已 Acquire，或锁已过期 |
| `ErrLockAcquireFailed` | 锁被其他持有者持有，稍后重试或跳过 |
| `ErrPipelineEmpty` | Pipeline 无命令，检查调用逻辑 |
| `ErrSubscribeFailed` | 检查 subject 和连接状态 |
| 序列化错误 | 检查 value 类型是否与 codec 兼容 |

**错误消息格式：** `"redisx: <operation>: <detail>"`
**错误包装：** 使用 `%w` 保留底层错误链

---

## 13. Edge Cases

| 场景 | 预期行为 |
|------|----------|
| Redis 不可达时调用 Get/Set | 返回 ErrConnectionFailed |
| 连接池耗尽 | 等待直到有空闲连接或超时 |
| Subscribe 期间连接断开 | 自动重连，重连失败发送错误到 channel |
| Pipeline.Exec 时连接断开 | 返回错误，已入队命令丢失 |
| Acquire 后进程崩溃 | TTL 到期后锁自动释放 |
| Release 非自己持有的锁 | 返回 ErrLockNotHeld，不释放 |
| Set value 为 nil | 返回序列化错误 |
| LRange start > stop | 返回空切片 |
| Del 空 keys 列表 | 返回 nil |
| 并发调用 Close | 幂等，第二次调用无副作用 |

---

## 14. Directory Structure

```text
redisx/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go
├── redisx.go                   # Client 工厂
├── client.go                   # Client 接口实现
├── pipeline.go                 # Pipeline 接口实现
├── locker.go                   # Locker 接口实现
├── health.go                   # HealthStatus
├── options.go                  # Option 模式
├── errors.go                   # 公共错误变量
├── codec.go                    # Codec 接口及默认 JSON codec
├── internal/
│   ├── pool/                   # 连接池封装
│   └── codec/                  # 内部序列化工具
├── testdata/
│   └── redis.conf              # 测试用 Redis 配置
├── example_test.go
├── benchmark_test.go
└── integration_test.go         # //go:build integration
```text

---

## 15. Dependencies

### 15.1 go.mod

```text
module github.com/ZoneCNH/redisx

go 1.23
```text

### 15.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| stdlib | configx |
| kernel（L0 原语） | 所有业务域实现 |
| observex（interface-only） | 所有 L2.5 领域共享层 |
| redis 客户端库（go-redis） | |

---

## 16. Testing

### 16.0 测试矩阵（TC → FR 映射）

| TC 编号 | 对应 FR | 测试类型 | 场景 | 预期结果 |
|---------|---------|----------|------|----------|
| TC-001 | FR-001, FR-002, FR-003 | 单元 | 基本 KV 操作：Set → Get → Del | 值正确读写，删除幂等 |
| TC-002 | FR-010, FR-011, BR-004, BR-005 | 单元 | 分布式锁互斥获取与释放 | A Acquire 后 B Acquire 返回 false；Release 非持有者报错 |
| TC-003 | FR-009, BR-006 | 单元 | Pipeline 批量操作原子性 | 所有命令在单次 Exec 中正确执行 |
| TC-004 | FR-008, BR-008 | 集成 | Redis 短暂不可用后恢复 | 下一次操作自动重连成功 |
| TC-005 | FR-004, FR-005 | 单元 | Exists 与 Expire 操作 | Exists 正确返回 key 数量，TTL 更新成功 |
| TC-006 | FR-006, BR-002 | 单元 | Hash 字段读写 | HSet 后 HGet 返回正确值；默认 codec 为 JSON |
| TC-007 | FR-007 | 单元 | List LPush/LRange | 按插入逆序返回列表元素 |
| TC-008 | FR-008 | 单元 | Pub/Sub 消息投递 | subscriber 收到 publisher 发布的消息 |
| TC-009 | FR-012, BR-007 | 单元 | Health 检查 | 连接正常返回 healthy；异常返回 unhealthy；重复调用幂等 |

### 16.1 单元测试

| 测试场景 | 验证点 |
|----------|--------|
| Get 存在的 key | 返回正确值 |
| Get 不存在的 key | 返回 redis.Nil |
| Set 带 TTL | 正确设置值和过期时间 |
| Set 不带 TTL | 正确设置值，无过期 |
| Del 存在的 key | 删除成功 |
| Del 不存在的 key | 幂等，无错误 |
| HGet/HSet | Hash 字段读写正确 |
| LPush/LRange | List 操作正确 |
| Pipeline 批量操作 | 所有命令正确执行 |
| 分布式锁 Acquire/Release | 获取和释放正确 |
| 分布式锁防误释放 | 非持有者 Release 返回错误 |
| 健康检查 | PING 成功/失败正确反映 |
| Codec 序列化/反序列化 | JSON / msgpack 正确 |
| 并发安全 | -race 测试通过 |

### 16.2 Given/When/Then 用例

**TC-001: 基本 KV 操作**
Given Redis 连接正常
When Set("key", "value", 1m) 然后 Get("key")
Then 返回 "value"

**TC-002: 分布式锁互斥**
Given 两个客户端 A 和 B
When A.Acquire("lock", 10s) 成功
Then B.Acquire("lock", 10s) 返回 false

**TC-003: Pipeline 原子性**
Given 连接正常
When Pipeline 中 Set 3 个 key 然后 Exec
Then 所有 3 个 key 都被设置

**TC-004: 连接断开重连**
Given Redis 连接正常
When Redis 短暂不可用后恢复
Then 下一次操作自动重连成功

**TC-005: Exists 与 Expire**
Given key 已 Set 且设置 TTL
When 调用 Exists 和 Expire
Then Exists 返回 true，TTL 更新成功

**TC-006: Hash 读写**
Given Redis 连接正常
When HSet("hash", "field", "value") 后 HGet
Then 返回 "value"

**TC-007: List 操作**
Given Redis 连接正常
When LPush 两个元素后 LRange
Then 按约定顺序返回两个元素

**TC-008: Pub/Sub**
Given subscriber 已订阅 subject
When publisher 发布消息
Then subscriber 收到该消息

**TC-009: Health 检查**
Given Redis 连接正常
When 调用 Health
Then 返回 healthy；连接失败时返回 unhealthy

### 16.3 Benchmark

| 场景 | 目标 |
|------|------|
| 单次 Get/Set（本地 Redis） | < 1ms |
| Pipeline 100 命令 | < 5ms |
| 分布式锁 Acquire/Release | < 2ms |
| 序列化/反序列化（1KB JSON） | < 10μs |

### 16.4 集成测试

| 场景 | 验证点 |
|------|--------|
| 完整 KV 操作链 | Set → Get → Del → Exists |
| Pub/Sub 消息投递 | Subscribe → Publish → 收到消息 |
| Pipeline 批量操作 | 100 命令正确执行 |
| 分布式锁过期 | TTL 到期后锁自动释放 |
| 连接断开恢复 | 断开后自动重连 |



### 16.5 测试工具

| 工具 | 用途 |
|------|------|
| `testing` + `testify` | 单元测试框架与断言 |
| `testkitx` | 测试辅助工具（FakeClock、Mock 等） |
| `go tool cover` | 覆盖率统计 |
| `go test -race` | 竞态检测 |
| `golangci-lint` | 静态分析与 lint |

### 16.6 测试数据

| 文件 | 用途 |
|------|------|
| `testdata/redis.conf` | 集成测试用 Redis 服务配置（最小化配置，仅绑定 6379） |


---

## 17. Performance Budget

| 操作 | 目标 | 测量方式 |
|------|------|----------|
| 单次 Get/Set（本地 Redis） | < 1ms | benchmark test |
| Pipeline 100 命令 | < 5ms | benchmark test |
| 分布式锁 Acquire/Release | < 2ms | benchmark test |
| 常驻内存 | < 5MB | profiling |
| 连接池空闲连接 | ≤ pool_size | 配置约束 |

---

## 18. Observability

| 类型 | 名称 | 说明 |
|------|------|------|
| metric | `redisx.command.duration` | histogram，命令耗时 |
| metric | `redisx.command.errors` | counter，命令失败次数 |
| metric | `redisx.pool.size` | gauge，连接池大小 |
| metric | `redisx.pool.idle` | gauge，空闲连接数 |
| metric | `redisx.pipeline.commands` | histogram，Pipeline 命令数 |
| metric | `redisx.lock.acquire.count` | counter，锁获取次数 |
| metric | `redisx.lock.acquire.failed` | counter，锁获取失败次数 |
| log | `redisx.connected` | info，连接成功 |
| log | `redisx.disconnected` | warn，连接断开 |
| log | `redisx.reconnecting` | info，正在重连 |
| log | `redisx.lock.acquired` | debug，获取锁成功 |
| log | `redisx.lock.released` | debug，释放锁成功 |

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

## 19. Security

| 要求 | 实现方式 |
|------|----------|
| 密码不硬编码 | 通过环境变量或 secret manager 注入 |
| 密码不写日志 | 日志中对密码字段脱敏 |
| 错误消息不泄露 key 值 | 错误消息只包含 key 名，不包含实际值 |
| 锁释放校验 | 只有持有者才能释放锁（Lua 脚本原子校验） |

---

## 20. CI Gate

### 20.1 通用 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 任何测试失败或 data race |
| 覆盖率 | `mkdir -p .coverage && go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | 总覆盖率 < 80% |
| vet | `go vet ./...` | 任何 vet 错误 |
| lint | `golangci-lint run` | 任何 lint 错误 |
| 依赖检查 | `go mod tidy && git diff --exit-code go.mod go.sum` | go.mod 不整洁 |
| Secret 扫描 | `gitleaks detect --no-git` | 泄露 secret |
| Benchmark | `go test -bench=. -benchmem -count=3 ./...` | 结果附在 PR comment |

### 20.2 redisx 专属 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 集成测试 | `go test -tags=integration ./...` | Redis 不可达时 skip，不阻塞 |

---

## 21. Upgrade Compatibility

| 变更类型 | 版本升级 |
|----------|----------|
| Client 接口新增方法 | **minor**（实现需跟上） |
| Client 接口删除/修改方法 | **major** |
| Pipeline 接口变更 | **major** |
| Locker 接口变更 | **major** |
| Option 新增字段 | minor（带默认值） |
| 默认 codec 变更 | **minor**（注意序列化兼容性） |

### 21.1 Breaking Change 迁移指南

| 变更类型 | 迁移步骤 |
|----------|----------|
| Client 接口删除/修改方法 | 1) 在 `CHANGELOG.md` 标记 DEPRECATED；2) 保留旧方法一个 MINOR 版本，标记为 `// Deprecated:`；3) 下一 MAJOR 版本移除；4) 通知所有消费者模块更新引用 |
| Pipeline 接口变更 | 同 Client 接口流程 |
| Locker 接口变更 | 同 Client 接口流程 |
| 默认 codec 变更 | 1) MINOR 版本 bump；2) CHANGELOG 中说明序列化兼容性影响；3) 消费者可通过 `WithCodec()` 显式覆盖回旧 codec |

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

---

## 23. Open Questions

### Blocking（阻塞开发）

无。当前阶段无阻塞开发的未解决问题。

### Non-blocking（不阻塞开发）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-001 | 是否需要支持 Redis Cluster 模式（自动分片）？ | 待评估 | ZoneCNH |

### Future（未来考虑）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-002 | 分布式锁是否需要支持可重入（同一持有者多次 Acquire）？ | 待评估 | — |
| OQ-003 | 是否需要支持 Lua 脚本执行（EVAL）？ | 待评估 | — |
| OQ-004 | Pub/Sub 是否需要支持模式匹配订阅（PSUBSCRIBE）？ | 待评估 | — |
| OQ-005 | 是否需要支持 Redis Streams（替代简单 Pub/Sub）？ | 待评估 | — |

**OQ-001 说明**：Cluster 模式影响连接池管理、Pipeline 跨节点行为和 HA 策略。当前范围限定为单节点 Redis，如后续业务要求水平扩展，需重新进入 Spec Review 流程并重新评分。
