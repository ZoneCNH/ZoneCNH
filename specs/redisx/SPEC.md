# redisx 完整规格

> 基座 · 存储扩展。Redis 客户端封装，提供统一的连接管理、序列化、健康检查和可观测集成。

最后更新：2026-06-07

---

## 1. Metadata

- Status: Active
- Owner: ZoneCNH
- Layer: 基座 · 存储扩展
- Version: v0.7.3
- Repository: [github.com/ZoneCNH/redisx](https://github.com/ZoneCNH/redisx)
- Related: [CONSTITUTION.md](../CONSTITUTION.md), [ARCHITECTURE.md](../ARCHITECTURE.md)

---

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

WHEN 调用 `Exists(ctx, keys...)`
THEN 返回存在的 key 数量

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

| 编号 | 规则 |
|------|------|
| BR-001 | 连接池大小通过配置控制，默认 10 |
| BR-002 | 序列化/反序列化使用可配置 codec，默认 JSON |
| BR-003 | 所有操作必须接受 `context.Context`，支持超时和取消 |
| BR-004 | 分布式锁必须使用唯一持有者标识（防止误释放） |
| BR-005 | 分布式锁必须设置 TTL，防止持有者崩溃导致死锁 |
| BR-006 | Pipeline 原子性：单次网络往返发送所有命令 |
| BR-007 | Health() 必须是幂等的、无副作用的 |
| BR-008 | 连接断开时自动重连，重连策略可配置 |
| BR-009 | 错误消息不包含 key 的实际值（防泄露敏感数据） |

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
```

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
```

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
```

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
```

### 10.2 Codec 接口

```go
type Codec interface {
    Marshal(v any) ([]byte, error)
    Unmarshal(data []byte, v any) error
}
```

---

## 11. Config Schema

```yaml
redisx:
  addr: "${FOUNDATIONX_REDIS_ADDR}" # Redis 地址
  password: ""                 # 密码（推荐通过环境变量注入）
  db: 0                        # 数据库编号
  pool_size: 10                # 连接池大小
  min_idle_conns: 2            # 最小空闲连接数
  max_retries: 3               # 最大重试次数
  read_timeout: 3s             # 读超时
  write_timeout: 3s            # 写超时
  dial_timeout: 5s             # 连接超时
  health_check_interval: 10s   # 健康检查周期
  codec: json                  # 序列化方式：json / msgpack / protobuf
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

```
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
```

---

## 15. Dependencies

### 15.1 go.mod

```
module github.com/ZoneCNH/redisx

go 1.23
```

### 15.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| stdlib | configx |
| kernel（L0 原语） | 所有业务域实现 |
| observex（interface-only） | 所有 L2.5 领域共享层 |
| redis 客户端库（go-redis） | |

---

## 16. Testing

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
| 覆盖率 | `go test ./... -coverprofile=cover.out && go tool cover -func=cover.out` | 总覆盖率 < 80% |
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

- 是否需要支持 Redis Cluster 模式（自动分片）？
- 分布式锁是否需要支持可重入（同一持有者多次 Acquire）？
- 是否需要支持 Lua 脚本执行（EVAL）？
- Pub/Sub 是否需要支持模式匹配订阅（PSUBSCRIBE）？
- 是否需要支持 Redis Streams（替代简单 Pub/Sub）？
