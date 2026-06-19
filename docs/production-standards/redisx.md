# redisx

## 1. 模块定位
Redis 标准化访问和治理封装。提供统一 KeyBuilder、typed Options、连接生命周期、KV/TTL、cache-aside、Hash/List、Pub/Sub、Pipeline、token owner 分布式锁、Counter、fixed-window RateLimitHelper、JSON 默认 Codec、自定义 Codec SPI、Health、pool stats 和低基数观测 hooks。Status=Approved、Layer=基座·存储扩展、Version=v1.1.0（已发布）。直接 Go 依赖边界：stdlib、kernel、Redis 客户端库；configx/observex/resiliencx/contracts 只能作为外部投影/上层 adapter，不得成为生产代码直接 import。

## 2. 生产职责
- KeyBuilder 命名空间隔离（FR-001）：namespace/env/service/version/entity/id/purpose 构造 + 脱敏 pattern
- typed Options + New/Close 连接生命周期（FR-002）：连接池、timeout、DB、TLS、Codec、kernel hook
- KV Get/Set/Del + Exists/Expire/TTL + 默认 TTL 策略（FR-003/004）
- CacheClient cache-aside/null-cache/防击穿（FR-005）
- Hash/List、Pub/Sub、Pipeline 有序非原子批量（FR-006/007/008）
- token owner 分布式锁 + Counter/RateLimitHelper（FR-009/010）
- JSON 默认 Codec + 自定义 Codec SPI + Health/PoolStats/hooks（FR-011/012）

## 3. 边界定义
- 生产代码直接依赖仅限 stdlib、kernel、Redis client library（BR-010，静态依赖守卫）
- 禁止直接 import configx/observex/resiliencx/contracts（只能作为外部投影/上层 adapter）
- 配置只能通过 typed Options 注入，redisx 不读取文件/env/配置中心（BR-002）
- 所有网络操作必须接受 `context.Context` 并尊重取消/deadline/超时（BR-003）
- Key 必须通过 KeyBuilder 构造，禁止业务裸 Key（BR-001）

## 4. 不负责什么
- 不封装 Redis 全部命令，只稳定 1.0 列出的 12 项能力
- 不管理 Redis Cluster/Sentinel/备份/扩缩容/认证轮换/运维拓扑
- 不承诺跨 Redis 集群的强一致锁
- 不解析配置文件，不直接 import configx
- 不直接 import observex/resiliencx/contracts（观测和弹性通过本地 hook 或上层 adapter）
- 不把缓存一致性事件系统内建（与 kafkax/natsx 联动由上层实现）

## 5. 架构位置
L2 基础设施适配器（存储扩展），位于基座层。消费者：schedulex（Locker 分布式任务锁）、market-data（行情快照缓存）、signal-engine（因子中间结果缓存）、risk-engine（风控状态/阈值/计数）、业务域模块（Client/CacheClient/Counter/RateLimitHelper）、平台 adapter（外部配置/观测/弹性投影为 redisx Options/hooks）。go.mod：`github.com/ZoneCNH/redisx`，go 1.23，默认 client `github.com/redis/go-redis/v9`。

## 6. 生命周期
- `New(ctx, Options)` 创建 Client，集成 kernel 生命周期 hook（FR-002）
- `Close()` 多次调用幂等释放资源（返回 nil 或稳定 closed 状态）
- Health 周期检查（`HealthCheckInterval: 10s`），输出 PING 状态 + PoolStats
- 所有网络操作尊重 ctx 取消/deadline，不发起或尽快停止 Redis 操作
- Subscribe ctx 取消：关闭 subscription 并释放连接
- Hook panic 不破坏 Redis 操作结果，转换为内部诊断

## 7. 标准目录结构
```text
redisx/
├── go.mod / go.sum / README.md / CHANGELOG.md / LICENSE / doc.go
├── redisx.go          # New/Client 工厂
├── options.go         # Options 结构体与校验
├── key.go             # Key/KeyParts/KeyBuilder
├── client.go          # Client 实现
├── cache.go           # CacheClient 实现
├── locker.go          # Locker 实现（token owner + Lua）
├── counter.go         # Counter + RateLimitHelper 实现
├── pipeline.go        # Pipeline 实现
├── codec.go           # Codec 接口 + JSON 默认实现
├── errors.go          # 公共错误变量
├── health.go          # Health/PoolStats
├── hooks.go           # Hook 接口与事件定义
├── internal/pubsub/   # Pub/Sub 内部实现
├── testdata/redis.conf
├── example_test.go / benchmark_test.go
└── 各 *_test.go
```

## 8. 配置规范
redisx 不读配置源，只接受 typed Options。外部投影 `foundationx.redis.*` → Options：
| 投影 | 字段 | 默认 |
|------|------|------|
| `addr` | Addr | 必填（脱敏） |
| `db` | DB | 0 |
| `pool.size` | PoolSize | 10 |
| `timeout.dial/read/write` | Dial/Read/WriteTimeout | 500ms |
| `default_ttl` | DefaultTTL | 缓存写入必须明确 |
| `ttl_jitter` | TTLJitter | 0，推荐开启 |
| `namespace/environment/service` | Namespace/Environment/Service | 必填 |
| `key_version` | KeyVersion | v1 |
| `codec` | Codec | JSON |

Go Config 结构体含 `Validate()`：addr 必填、pool_size>=1、codec ∈ {json,msgpack,protobuf}。连接串/用户名/密码不得出现在日志/错误/metric label/trace tag。

## 9. 错误模型
typed errors 可用 `errors.Is` 判断：`ErrInvalidOptions / ErrInvalidKey / ErrNotFound / ErrClosed / ErrTimeout / ErrSerialization / ErrDependency / ErrLockNotHeld / ErrLockAcquireFailed / ErrRateLimited / ErrPipelineEmpty / ErrSubscribeFailed / ErrCodecNotSet / ErrConnectionFailed`。错误消息和 hook payload 只用 key pattern，不得含完整 Key/连接串/凭据（BR-007）。配置校验失败在 `New` 返回可分类错误，不访问 Redis。

## 10. 日志规范
通过本地 hooks 输出事件（HookEvent: Operation/Status/ErrorCode/Duration/KeyPattern），上层 adapter 转接到日志/metrics/trace。生产代码不直接 import observex。日志只允许 key pattern，禁止完整 Key、Redis addr、用户名、payload、业务用户 ID。Pub/Sub payload 不在 redisx 内记录，只记录 channel 和 payload size。

## 11. Metrics
指标命名约定（低基数标签）：
| 指标 | 类型 | 标签 |
|------|------|------|
| `foundationx_redis_operation_seconds` | histogram | operation,status,client,key_pattern |
| `foundationx_redis_operation_total` | counter | operation,status,error_code,client |
| `foundationx_redis_errors_total` | counter | operation,error_code,client |
| `foundationx_redis_pool_active` / `pool_idle` | gauge | client |
| `foundationx_redis_lock_acquire_total` | counter | status,client,key_pattern |
| `foundationx_redis_ratelimit_allowed_total` | counter | status,client,key_pattern |

允许标签只有 operation/status/error_code/client/key_pattern（BR-009）。禁止完整 Key/addr/用户名/payload 作标签。

## 12. Tracing
| Span | 父 Span | 说明 |
|------|---------|------|
| `redisx.command` | caller | 单次 Redis 命令执行（序列化/网络/反序列化） |
| `redisx.pipeline.exec` | `redisx.command` | Pipeline 批量执行 |
| `redisx.lock.acquire` / `lock.release` | `redisx.command` | 分布式锁获取/释放（含 Lua） |

属性：`redisx.key`（脱敏 key 名）、`redisx.command`（GET/SET/HSET 等）、`redisx.duration_ms`、`redisx.pipeline.size`、`redisx.lock.result`（acquired/failed/released）。

## 13. Reliability
- retry/reconnect/circuit：只能通过本地 hooks 或上层 adapter 接入，不直接依赖 resiliencx（BR-008）
- timeout：Dial/Read/Write 默认 500ms，ctx deadline 返回 `ErrTimeout`
- backpressure：PoolSize 默认 10，MinIdleConns 2，MaxRetries 3
- 分布式锁：token owner + TTL + Renew + Lua guarded release（先比较 token 再删除，BR-005）
- Counter/RateLimit：原子执行 incr/add/get/reset/allow，返回 remaining/resetAt，保证窗口 TTL
- Pipeline 部分失败：返回有序结果和第一个错误（非原子，BR-006）

## 14. Security
- 连接地址/用户名/密码/完整 Key/payload 不得写入日志/metric label/trace tag
- `KeyBuilder.Pattern` 是观测唯一允许的 Key 表示
- Lock token 必须使用不可预测随机值，不能由业务 ID 直接派生
- Lua guarded release 必须先比较 token 再删除锁
- Pub/Sub payload 不在 redisx 内记录，只记录 channel 和 payload size
- README 与样例不得包含真实 Redis 凭据/内网地址/个人路径
- v1.1.0 Security check passed，公开文档仅保留配置路径与 `REDISX_REDIS_*` 键名

## 15. Performance SLO
| 场景 | 预算 | 验证 |
|------|------|------|
| KeyBuilder | p95 < 5μs | BenchmarkKeyBuilder |
| JSON Codec 小对象 | p95 < 500μs | BenchmarkJSONCodec |
| KV Get/Set 本地 Redis | p95 < 10ms，p99 < 30ms | BenchmarkKV |
| Pipeline 10 命令 | 比串行减少 ≥ 50% round-trip | BenchmarkPipeline |
| Locker Acquire/Release | p95 < 20ms | BenchmarkLocker |
| RateLimitHelper | p95 < 10ms | BenchmarkRateLimit |
| Hook 开销（空 hook） | p95 < 1μs | BenchmarkHook |

超预算必须记录环境和原因，不得静默忽略。

## 16. 测试标准
12 个 TC（TC-001..TC-012）+ 10 个 BR guard + 4 个 NFR evidence。TC-001 KeyBuilder、TC-002 Options/New/Close/hook、TC-003 KV、TC-004 TTL/jitter、TC-005 Cache 防击穿、TC-006 Hash/List、TC-007 Pub/Sub、TC-008 Pipeline、TC-009 Locker 并发、TC-010 Counter/RateLimit、TC-011 Codec、TC-012 Health/PoolStats。v1.1.0 实测：8 个 Redis 运行时/API 可发布包覆盖率 100.0%，总覆盖率 100.0%，race-clean。

## 17. Chaos
SPEC 未定义独立 chaos 矩阵。边界情况表覆盖等效维度：Options 地址空返回 `ErrInvalidOptions`、Key 非法字符/超长拒绝、Get missing key 返回 `ErrNotFound`、Codec Decode 类型错误返回 `ErrSerialization`、ctx 取消尽快停止 Redis 操作、Close 多次幂等、TTL=0 仅显式 no-expire 路径有效、Pipeline 部分失败、Lock token mismatch 不删除锁、Subscribe ctx 取消释放连接、RateLimit 并发原子计数、Hook panic 不破坏操作结果。

## 18. Contract
```go
func New(ctx context.Context, opts Options) (Client, error)
func NewCache(client Client, opts CacheOptions) CacheClient
func NewLocker(client Client, opts LockOptions) Locker
func NewCounter(client Client) Counter
func NewRateLimitHelper(counter Counter) RateLimitHelper
```
核心接口：`Client`（Get/Set/Del/Exists/Expire/TTL/HGet/HSet/LPush/LRange/Publish/Subscribe/Pipeline/Health/PoolStats/Close）、`CacheClient`（GetOrLoad/Set/Invalidate）、`Pipeline`（Get/Set/Del/Exec）、`Locker`（Acquire/Renew/Release）、`Counter`（Incr/Add/Get/Reset）、`RateLimitHelper`（Allow）、`KeyBuilder`（Build/Pattern）、`Codec`（Encode/Decode/Name）。1.0 后这些为稳定契约。

## 19. CI Gate
最小门禁：`go test ./...`、`go test -race ./...`、`go test -run Integration ./...`（REDIS_ADDR 显式开启）、`go test -bench . ./... -run '^$'` 生成性能证据、静态依赖守卫（禁止 import configx/observex/resiliencx/contracts/业务域）、文档守卫（SPEC/TRACEABILITY/task/module README 的 FR/BR/NFR/Task ID 一致）、`git diff --check`。v1.1.0 完整 gate：`make fmt vet lint test race coverage-check`、`make l2-check`（release_ready=true, score=100, target=L2-T2）、`make test-contract && make contracts && make score-check`、`make docs-check`、`make security`（强制 govulncheck + secret check）。

## 20. Release Gate
- [x] FEATURES/ACCEPTANCE 与 SPEC/TRACEABILITY 登记一致（v1.1.0）
- [x] go test/race/vet/coverage 通过（Redis 运行时/API 可发布包 100.0%）
- [x] 真实 Redis 集成测试通过（REDISX_REDIS_* 配置，证据只记录键名）
- [x] L2-T2 契约门禁 release_ready=true, score=100
- [x] Security check + govulncheck + secret check 通过
- [x] Docker Contract / Integration / L2 Gates / Release workflow 全 success
- [x] 版本标签 + CHANGELOG + GitHub Release 一致（v1.1.0，Release workflow run 27802471873，PR#19 合入 main）

## 21. Versioning
semver。Client/CacheClient/Locker/Counter/RateLimitHelper/KeyBuilder/Codec/HealthStatus 为稳定契约（1.0 后）。接口删除/修改方法：CHANGELOG 标记 DEPRECATED → 保留旧方法一个 MINOR（`// Deprecated:`）→ 下一 MAJOR 移除 → 通知消费者。默认 codec 变更：MINOR bump + 说明序列化兼容性 + 消费者可通过 `WithCodec()` 覆盖。Key 版本升级通过 `KeyVersion` 产生新 namespace，不直接覆盖旧 Key。当前 v1.1.0，只升不降。

## 22. 兼容性策略
- Key 必须含 namespace/env/service/version/entity/id 或 purpose（BR-001）
- 缓存写入必须有明确 TTL 策略，默认 TTL 不得无意永不过期，支持 jitter（BR-004）
- Lock 迁移必须等待旧锁 TTL 自然过期，禁止强删未知 owner 锁
- Pipeline 有序非原子，部分失败返回有序结果和第一个错误（BR-006）
- Key 版本升级产生新 namespace，不覆盖旧 Key
- 替换 Redis 客户端必须保持公共接口和错误语义兼容

## 23. Failover
- Options 地址空：`New` 返回 `ErrInvalidOptions`，不访问 Redis
- Redis 连接失败：返回 `ErrConnectionFailed`/`ErrDependency`，包装原始错误但不泄露敏感值
- context 已取消：不发起或尽快停止 Redis 操作，返回 context 错误
- Close 多次调用：幂等返回 nil 或稳定 closed 状态
- Subscribe 重连失败：通过错误事件返回并释放资源
- Lock token mismatch：Release 不删除锁，返回 `ErrLockNotHeld`（防误释放）
- Hook panic：转换为内部诊断，不破坏 Redis 操作结果

## 24. Backpressure
- 连接池：PoolSize 默认 10、MinIdleConns 2，PoolStats 暴露 Hits/Misses/Timeouts/TotalConns/IdleConns/StaleConns
- CacheClient 防击穿：单进程合并（single-flight），避免缓存穿透/击穿/雪崩
- null-cache：miss 时写入短 TTL 空值，防止穿透
- TTL jitter：避免大量 Key 同时过期雪崩
- Pipeline：单次网络往返提交批量命令，减少 round-trip
- RateLimitHelper：fixed-window 原子计数，超限返回 `ErrRateLimited`（业务可处理状态）

## 25. 审计要求
所有关键操作可追踪：KV/Cache/Hash/List/Pub/Sub/Pipeline/Locker/Counter/RateLimit 通过低基数 metrics（`foundationx_redis_*`）+ trace span（`redisx.command` 等）+ 本地 hooks 形成证据链。错误脱敏（BR-007），只用 key pattern。Lock token 不可预测随机值 + Lua guarded release（先比较 token 再删除）。Pub/Sub payload 不记录，只记录 channel + payload size。Health 幂等输出 PING + PoolStats。

## 26. 熵减规则
全局：禁止 util dumping、hidden abstraction、cyclic dependency。模块特有：Client API 接收 `Key` 而非裸 string（强制 KeyBuilder）；配置唯一入口 typed Options；观测通过本地 hooks（不 import observex）；错误集中在 errors.go 可用 `errors.Is` 判断；指标只允许 5 个低基数标签；生产依赖边界静态守卫（stdlib/kernel/Redis client only）。

## 27. AI Constraints
全局：AI 不允许新增未注册模块、绕过 contracts、动态扩展目录。模块特有：AI 修改 redisx 必须保持 FR-001..012 / BR-001..010 行为约束，不得让生产代码 import configx/observex/resiliencx/contracts、不得读取配置源（只接受 typed Options）、不得在日志/metric/trace 输出完整 Key/连接串/凭据/payload、不得用业务 ID 派生 lock token、不得绕过 KeyBuilder 直接拼接 Key、不得让缓存写入无意永不过期；新增 Redis 命令必须通过新 task spec 和追溯矩阵进入，不得扩大既有 task scope。

## 28. Forbidden Patterns
- 业务直接传入裸 Key（BR-001，KeyBuilder 拒绝）
- 读取配置文件/env/配置中心（BR-002，只能 typed Options）
- 网络操作无 ctx 或忽略 ctx 取消（BR-003）
- 缓存写入无明确 TTL 或无意永不过期（BR-004）
- 释放非 owner 的锁（BR-005，token mismatch 不删除）
- 把 Pipeline 当原子事务用（BR-006，非原子）
- 日志/metric/trace 含完整 Key/连接串/凭据（BR-007）
- 直接依赖 resiliencx 做重试/重连/熔断（BR-008，只能本地 hook）
- 指标用完整 Key/addr/用户名/payload 作标签（BR-009）
- 生产代码 import configx/observex/resiliencx/contracts（BR-010，依赖守卫阻断）
- 用业务 ID 派生 lock token；Lua release 不先比较 token

## 29. Production Ready Checklist
- [x] observability ready（foundationx_redis_* metrics 7 项 + trace span 4 类 + 本地 hooks + 低基数标签）
- [x] resilience ready（token owner 锁、ctx 传播、PoolSize/MaxRetries、Cache 防击穿、RateLimit 原子计数）
- [x] audit ready（错误脱敏 BR-007、key pattern only、Lock token 随机 + Lua guarded release）
- [x] rollback ready（semver + DEPRECATED 迁移窗口 + KeyVersion 新 namespace + 锁 TTL 自然过期）
- [x] coverage ready（Redis 运行时/API 可发布包 100.0%，总 100.0%，race/vet/lint/secret/govulncheck 全通过）
- [x] release ready（L2-T2 score=100，Release workflow run 27802471873，GitHub Release v1.1.0 published）

## 30. Roadmap
- v1.0.0（已发布）：12 FR、10 BR、4 NFR、10 task，KeyBuilder/Options/KV/Cache/Hash-List/Pub-Sub/Pipeline/Locker/Counter-RateLimit/Codec/Health
- v1.1.0（已发布，PR#19）：版本/manifest/发布文档对齐，覆盖率 100.0%，真实 Redis 集成测试，L2-T2 score=100，Release workflow 发布正式 GitHub Release
- 待评估（OQ）：Redis Cluster 模式支持、Pipeline MULTI/EXEC 原子事务、Redis Stream 封装
