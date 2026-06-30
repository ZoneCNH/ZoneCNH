# redisx 发布版本 1.0 Goal 定位与实现标准

| 字段 | 内容 |
| --- | --- |
| 模块名 | `redisx` |
| 发布版本 | 1.3.0 |
| 所属层级 | 基座 · 存储扩展 |
| 稳定级别 | Public API Stable；SPI Stable；Internal 可演进 |
| 文档状态 | 1.0 发布基线文档 |
| 发布日期基准 | 2026-06-30 |

## 术语约定

本文档中的 **MUST / 必须** 表示 1.0 发布阻断项；**SHOULD / 应该** 表示 1.0 推荐项，允许带明确理由延期；**MAY / 可以** 表示可选能力，不影响 1.0 发布。

## 1. Goal 定位

`redisx` 的 Goal 是提供 Redis 的标准化访问和治理封装，使缓存、分布式锁、计数器、限流辅助、轻量 Pub/Sub 和基础队列辅助能力具备统一接口、统一 Key 规范、统一序列化、统一 TTL 策略、统一错误模型和统一观测语义。它屏蔽客户端差异，但不隐藏 Redis 的核心语义和限制。

`redisx` 是存储扩展模块，不是通用治理运行时。按 `module/FOUNDATION-DEPS.yaml`，它的直接 Go 依赖边界是 `kernel` 与 Redis 客户端库；`configx`、`observex`、`resiliencx`、`contracts` 只能作为外部配置投影、指标命名约定或适配器约束，不能成为 `redisx` 代码中的直接 import。

## 2. 为什么需要这个模块

- Redis 在业务中使用广泛，但 Key 命名、TTL、序列化、锁实现和错误处理经常不一致。
- 缓存穿透、击穿、雪崩和无 TTL 写入需要统一的最低安全基线。
- 分布式锁若没有 token、lease、续期和释放校验，容易出现死锁、误释放和过期并发。
- Redis 调用必须纳入超时、错误分类、低基数指标和慢操作诊断，避免把完整 Key、连接串或凭据写入日志。

## 3. 1.0 发布目标

| 目标 | 发布要求 | 对应规格 |
| --- | --- | --- |
| Key 规范 | MUST 提供 KeyBuilder，强制 namespace/env/service/version/entity/id 结构与长度校验 | FR-001 |
| 客户端生命周期 | MUST 提供 typed Options、New/Close、连接池、超时、TLS 配置；不解析配置文件 | FR-002 |
| KV 与 TTL | MUST 提供 Get/Set/Del/Exists/Expire/TTL 默认策略和 TTL jitter | FR-003, FR-004 |
| Cache | MUST 提供 cache-aside、null-cache、get-or-load、防击穿 singleflight | FR-005 |
| Redis 基础结构 | MUST 提供 Hash/List、Pub/Sub、Pipeline 的最小稳定封装 | FR-006, FR-007, FR-008 |
| 分布式锁 | MUST 提供 token owner、lease、renew、Lua guarded release | FR-009 |
| 计数限流 | MUST 提供原子计数和 fixed-window rate limit helper | FR-010 |
| 序列化 | MUST 提供 JSON 默认 Codec 与自定义 Codec SPI | FR-011 |
| 健康与观测 | MUST 提供 PING health、连接池状态、低基数指标/日志 hooks | FR-012 |

## 4. 核心场景

| 场景 | 说明 | 1.0 期望结果 |
| --- | --- | --- |
| 缓存查询 | 业务读取热点对象 | cache-aside 模式统一封装，miss/load/set 可观测 |
| Key 隔离 | 多环境、多服务共享 Redis | KeyBuilder 输出稳定、可校验、可脱敏的 Key pattern |
| 分布式锁 | 多实例处理同一资源 | 基于 token 的锁避免误释放，lease 超时后自动释放 |
| 计数限流 | 短信发送或接口访问计数 | 原子自增和 TTL 统一处理，窗口到期自动清理 |
| 故障诊断 | Redis 短暂不可用或慢命令 | context 超时、错误分类、低基数指标和脱敏日志可定位问题 |

## 5. 能力范围

| 能力域 | 1.0 必须具备的能力 | 验收方式 |
| --- | --- | --- |
| Key 规范 | namespace、env、service、entity、id、purpose、version | KeyBuilder 单元测试和非法输入测试通过 |
| KV 操作 | get/set/delete/exists/expire/default TTL/TTL jitter | 真实 Redis 集成测试通过 |
| 缓存模式 | cache-aside、null-cache、防击穿 singleflight、Codec | 缓存场景和序列化测试通过 |
| 基础结构 | hash、list、publish、subscribe、pipeline | 集成测试和取消清理测试通过 |
| 分布式锁 | tryLock、lease、renew、unlock token check | 并发锁测试和误释放防护测试通过 |
| 计数器 | incr/add/get/reset、fixed-window rate limit | 原子性和 TTL 测试通过 |
| 治理观测 | typed options、错误码、超时、指标/日志 hooks | 契约测试和静态依赖守卫通过 |

## 6. 职责边界

### 6.1 模块内职责

- 提供 Redis 标准客户端封装和常见能力组件。
- 提供 Key 规范、序列化、TTL、连接池和 TLS 配置结构。
- 提供 Redis 错误模型、敏感信息脱敏和低基数观测 hook。
- 提供 Redis 集成测试、并发测试、失败路径测试和最小样例。

### 6.2 明确非目标

- 不封装 Redis 的全部命令集合。
- 不替代 Redis 集群运维、Sentinel/Cluster 拓扑管理、备份、扩缩容。
- 不承诺跨 Redis 集群的强一致锁。
- 不解析配置文件，不直接 import `configx`。
- 不直接 import `observex`、`resiliencx` 或 `contracts`；观测和弹性通过本地接口或上层 adapter 接入。
- 不鼓励业务绕过 KeyBuilder 直接拼接 Key。

## 7. 依赖关系与分层约束

| 依赖类型 | 约束 |
| --- | --- |
| 允许直接依赖 | Go 标准库、`github.com/ZoneCNH/kernel`、Redis 客户端库（默认 `github.com/redis/go-redis/v9`） |
| 禁止直接依赖 | 业务域模块、`configx`、`observex`、`resiliencx`、`contracts` |
| 配置关系 | `foundationx.redis.*` 是外部配置投影；`redisx` 只接受 typed `Options` |
| 观测关系 | `foundationx_redis_*` 是指标命名约定；指标/日志通过本地 hooks 输出 |
| 下游关系 | 业务缓存、`schedulex` LockProvider、限流辅助可依赖 `redisx` |

## 8. 对外契约

| 契约 | 定位 | 1.0 稳定承诺 |
| --- | --- | --- |
| `Client` | 基础 Redis 访问入口 | KV、Hash、List、Pub/Sub、Pipeline、Health、Close 语义稳定 |
| `CacheClient` | 缓存封装 | Get/Put/GetOrLoad/Evict、null-cache、防击穿语义稳定 |
| `Locker` | 分布式锁接口 | token/lease/renew/release 语义稳定 |
| `Counter` | 原子计数接口 | Incr/Add/Get/Reset 语义稳定 |
| `RateLimitHelper` | fixed-window 限流辅助 | allow/remaining/resetAt 语义稳定 |
| `KeyBuilder` | Key 构造器 | 命名规则、校验和脱敏 pattern 稳定 |
| `Codec` | 序列化扩展点 | Encode/Decode 语义稳定 |
| `HealthChecker` | 健康检查 | PING、pool stats、状态字段稳定 |

## 9. 配置与观测契约

`redisx` 不读取配置源。上层可以把 `foundationx.redis.*` 解码为 `redisx.Options` 后注入：

| 配置项 | 含义 | 默认值 / 要求 | 稳定性 |
| --- | --- | --- | --- |
| `foundationx.redis.enabled` | 是否启用 redisx | false，由业务显式启用 | Stable |
| `foundationx.redis.uri` | Redis 连接地址 | 必须配置，日志中脱敏 | Stable |
| `foundationx.redis.namespace` | Key 命名空间 | 应用名 + 环境 | Stable |
| `foundationx.redis.default_ttl` | 默认缓存 TTL | 不得默认为永不过期 | Stable |
| `foundationx.redis.timeout` | 调用超时 | 500ms | Stable |
| `foundationx.redis.pool.max_size` | 连接池大小 | 按环境配置 | Stable |
| `foundationx.redis.codec` | 序列化器 | json | Stable |
| `foundationx.redis.key_version` | Key 版本 | 1 | Stable |

指标名使用 `foundationx_redis_*` 前缀，标签只允许 `operation`、`status`、`error_code`、`client`、`key_pattern` 等低基数字段。日志、指标和 trace 只能记录 key pattern，不能记录完整敏感 Key 或连接串。

## 10. 错误模型与失败策略

| 错误类别 | 典型原因 | 1.0 处理策略 |
| --- | --- | --- |
| `ErrInvalidKey` | Key segment 为空、过长或字符非法 | 不访问 Redis，返回参数错误 |
| `ErrKeyNotFound` | Redis nil / key 不存在 | 作为可处理状态返回 |
| `ErrConnectionFailed` | 连接失败、认证失败、网络不可达 | 返回可识别连接错误，由上层策略决定重试/降级 |
| `ErrTimeout` | context deadline 或 Redis 超时 | 返回可识别超时错误 |
| `ErrSerializationFailed` | 编码或解码失败 | 不重试，返回数据格式错误 |
| `ErrLockNotAcquired` | 锁竞争失败 | 返回业务可处理状态 |
| `ErrLockOwnershipLost` | 续期或释放时 token 不匹配 | 不释放其他 owner 的锁，记录脱敏诊断 |
| `ErrPipelineFailed` | Pipeline 部分命令失败 | 返回有序结果和第一个错误 |

## 11. 发布验收原则

- 公开 API、配置投影、错误码、指标名完成冻结并记录兼容性说明。
- `SPEC.md`、`TRACEABILITY.md`、10 个 task spec 与 `module/README.md` 的 FR/task 数量一致。
- 所有 MUST 能力均有单元测试、集成测试或契约测试证据。
- 依赖守卫确认 `redisx` 没有直接 import 禁止依赖。
- 发布包不包含测试密钥、临时文件、个人环境路径或完整连接串样例。

## 12. 1.0 后演进方向

- 支持 Redis Cluster 拓扑感知增强，但不改变 1.0 最小接口。
- 提供更多数据结构封装，但保持最小 API。
- 支持缓存一致性事件与 `kafkax`/`natsx` 联动，由上层 adapter 实现。
