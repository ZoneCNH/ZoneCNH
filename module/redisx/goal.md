# redisx 发布版本 1.0 Goal 定位与实现标准

| 字段         | 内容                                           |
| ------------ | ---------------------------------------------- |
| 模块名       | `redisx`                                       |
| 发布版本     | 1.0.0                                          |
| 所属层级     | 存储扩展层 / Redis 标准化访问                  |
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

`redisx` 的 Goal 是提供 Redis 的标准化访问和治理封装，使缓存、分布式锁、计数器、限流辅助、会话和轻量队列辅助能力具备统一接口、统一 Key 规范、统一序列化、统一配置、统一弹性治理和统一观测。它屏蔽客户端差异，但不隐藏 Redis 的核心语义和限制。

### 1.1 为什么需要这个模块

- Redis 在业务中使用广泛，但 Key 命名、TTL、序列化、锁实现和错误处理经常不一致。
- 缓存问题如穿透、击穿、雪崩需要标准治理模式。
- 分布式锁若实现不规范，容易出现死锁、误释放和锁过期并发。
- Redis 调用必须纳入超时、重试、熔断、慢操作观测。

### 1.2 1.0 要解决的问题

- 统一 KeyBuilder 和命名规范。
- 统一缓存读写、TTL、批量操作和序列化。
- 统一分布式锁、计数器、限流辅助能力。
- 统一 Redis 调用错误码、超时、重试和熔断。
- 统一慢操作日志、指标和 Trace。

### 1.3 目标用户

- 业务服务开发者
- 平台基础设施开发者
- SRE / 运维人员
- 测试工程师

## 2. 1.0 发布目标

- MUST 提供 KV、Cache、Lock、Counter、RateLimitHelper 基础能力。
- MUST 强制 Key 命名规范和命名空间隔离。
- MUST 支持 TTL 默认策略，缓存写入必须明确 TTL 或声明永不过期理由。
- MUST 提供安全的分布式锁：唯一 token、过期时间、续期、释放校验。
- MUST 接入 configx、observex、resiliencx。

## 3. 核心场景

| 场景     | 说明                   | 1.0 期望结果                                     |
| -------- | ---------------------- | ------------------------------------------------ |
| 缓存查询 | 业务读取热点对象       | cache-aside 模式统一封装，miss/load/set 可观测   |
| 分布式锁 | 多实例处理同一资源     | 基于 token 的锁避免误释放，超时自动过期          |
| 计数限流 | 短信发送或接口访问计数 | 原子自增和 TTL 统一处理                          |
| 故障降级 | Redis 短暂不可用       | 按 resiliencx 策略快速失败或降级，避免拖垮主流程 |

## 4. 能力范围

| 能力域   | 1.0 必须具备的能力                                | 验收方式                |
| -------- | ------------------------------------------------- | ----------------------- |
| Key 规范 | namespace、domain、resource、id、purpose、version | KeyBuilder 测试通过     |
| KV 操作  | get/set/delete/exists/expire/batch                | 真实 Redis 集成测试通过 |
| 缓存模式 | cache-aside、null-cache、防击穿锁、TTL jitter     | 缓存场景测试通过        |
| 分布式锁 | tryLock、lease、renew、unlock token check         | 并发锁测试通过          |
| 计数器   | incr/decr、窗口计数、TTL 原子设置                 | 原子性测试通过          |
| 序列化   | JSON/Binary SPI、类型信息、兼容版本               | 序列化兼容测试通过      |
| 治理观测 | 超时、慢操作、错误、重试、熔断                    | 观测测试通过            |

## 5. 职责边界

### 5.1 模块内职责

- 提供 Redis 标准客户端封装和常见能力组件。
- 提供 Key 规范、序列化、TTL、连接池配置。
- 提供 Redis 错误模型和弹性治理接入。
- 提供测试工具和本地集成测试样例。

### 5.2 明确非目标

- 不封装 Redis 的全部命令集合。
- 不替代 Redis 集群运维、备份、扩缩容。
- 不承诺跨 Redis 集群的强一致锁。
- 不鼓励业务绕过 KeyBuilder 直接拼接 Key。

## 6. 依赖关系与分层约束

| 依赖类型 | 约束                                                       |
| -------- | ---------------------------------------------------------- |
| 上游依赖 | 依赖 kernel、configx、observex、resiliencx。               |
| 下游依赖 | 业务缓存、schedulex LockProvider、限流辅助可使用 redisx。  |
| 分层约束 | redisx 不应依赖业务模型；序列化通过类型和 codec SPI 完成。 |
| 契约依赖 | MUST 向 contracts 登记 Public API 契约和错误码契约。       |

## 7. 对外契约

### 7.1 公开能力面

| 契约                 | 定位                | 1.0 稳定承诺                   |
| -------------------- | ------------------- | ------------------------------ |
| RedisClientX         | 基础 Redis 访问入口 | 基础操作语义稳定               |
| CacheClient          | 缓存封装            | getOrLoad、put、evict 语义稳定 |
| RedisLock            | 分布式锁接口        | token/lease/unlock 语义稳定    |
| KeyBuilder           | Key 构造器          | 命名规则稳定                   |
| RedisSerializer SPI  | 序列化扩展点        | encode/decode 语义稳定         |
| RedisHealthIndicator | 健康检查            | 状态字段稳定                   |

### 7.2 1.0 逻辑接口基线

```text
Key pattern:
  {app}:{env}:{domain}:{resource}:{id}:{purpose}:v{version}

CacheClient
  get(key, type): Optional<T>
  put(key, value, ttl): void
  getOrLoad(key, ttl, loader): T
  evict(key): void

RedisLock
  tryLock(key, ttl, owner): LockLease
  renew(lease, ttl): boolean
  unlock(lease): boolean

Counter
  increment(key, delta, ttl?): long

RedisClientX
  get(key): byte[]?
  set(key, value, ttl?): void
  delete(key): boolean
  exists(key): boolean
  expire(key, ttl): boolean

RedisHealthIndicator
  check(): HealthState
  ping(): boolean
```

## 8. 配置契约

| 配置项                          | 含义            | 默认值 / 要求         | 稳定性 |
| ------------------------------- | --------------- | --------------------- | ------ |
| foundationx.redis.enabled       | 是否启用 redisx | false，由业务显式启用 | Stable |
| foundationx.redis.uri           | Redis 连接地址  | 必须配置              | Stable |
| foundationx.redis.namespace     | Key 命名空间    | 应用名 + 环境         | Stable |
| foundationx.redis.default-ttl   | 默认缓存 TTL    | 不得默认为永不过期    | Stable |
| foundationx.redis.timeout       | 调用超时        | 500ms                 | Stable |
| foundationx.redis.pool.max-size | 连接池大小      | 按环境配置            | Stable |
| foundationx.redis.serializer    | 序列化器        | json                  | Stable |
| foundationx.redis.key-version   | Key 版本        | 1                     | Stable |

## 9. 可观测契约

### 9.1 日志

- MUST 输出模块初始化结果、关键配置摘要和失败原因；敏感配置必须脱敏。
- MUST 在关键操作失败时输出 errorCode、operation、durationMs、traceId、resource。
- SHOULD 对慢操作输出 warn 级别日志，阈值由配置控制。
- MUST 对慢命令输出 keyPattern 而不是完整敏感 key。
- MUST 在锁续期失败、释放失败、锁竞争失败时输出诊断日志。

### 9.2 指标

| 指标名                                | 类型    | 标签                   | 说明                      |
| ------------------------------------- | ------- | ---------------------- | ------------------------- |
| foundationx_redis_commands_total      | Counter | operation,status       | Redis 命令次数            |
| foundationx_redis_command_duration_ms | Timer   | operation,status       | Redis 命令耗时            |
| foundationx_redis_cache_total         | Counter | cache,operation,result | 缓存命中/未命中/写入/删除 |
| foundationx_redis_lock_total          | Counter | lock,operation,status  | 锁操作次数                |
| foundationx_redis_pool_active         | Gauge   | client                 | 活跃连接数                |
| foundationx_redis_errors_total        | Counter | operation,errorCode    | Redis 错误数              |

### 9.3 Trace / 诊断事件

- MUST 接收并传播上游 trace context，不得无故丢失 requestId / traceId。
- SHOULD 为外部依赖调用创建 span，并标注 peer、operation、status、errorCode。
- MAY 输出模块内部诊断事件，用于启动分析和运行期排障。
- MUST 标注 redis.operation、redis.key_pattern、redis.db、peer.address。
- SHOULD 对 getOrLoad 的 loader 执行创建子 span。

## 10. 错误模型与失败策略

| 错误类别                   | 典型原因                       | 1.0 处理策略                       |
| -------------------------- | ------------------------------ | ---------------------------------- |
| REDIS_CONNECTION_FAILED    | 连接失败、认证失败、网络不可达 | 按 resiliencx 策略快速失败或重试   |
| REDIS_TIMEOUT              | 命令超时                       | 返回可识别超时错误                 |
| REDIS_SERIALIZATION_FAILED | 编码或解码失败                 | 不重试，返回数据格式错误           |
| REDIS_LOCK_NOT_ACQUIRED    | 锁竞争失败                     | 返回业务可处理状态，不作为系统异常 |
| REDIS_LOCK_RELEASE_FAILED  | 锁释放 token 不匹配或连接失败  | 记录告警，避免误释放               |

## 11. 安全、稳定性与兼容性要求

- MUST 对密码、token、accessKey、secretKey、连接串中的敏感片段做脱敏。
- MUST 保证公开 API 的异常不会泄漏内部凭据、主机隐私或完整连接串。
- MUST 为所有网络和外部依赖调用设置超时边界。
- SHOULD 支持最小权限原则，不要求业务使用高权限账号。
- MUST 不在日志中输出完整连接串和完整敏感 Key。
- MUST 对锁 owner 和业务 Key 做长度限制。
- MUST 支持 TLS 连接和认证配置。

## 12. 测试证据要求

| 测试类型 | 必须覆盖内容                             | 发布门禁  |
| -------- | ---------------------------------------- | --------- |
| 单元测试 | KeyBuilder、TTL jitter、序列化、错误映射 | MUST 通过 |
| 集成测试 | 真实 Redis KV、缓存、锁、计数器          | MUST 通过 |
| 并发测试 | 分布式锁竞争、续期、过期、误释放防护     | MUST 通过 |
| 故障测试 | 连接失败、超时、慢命令、序列化失败       | MUST 通过 |
| 观测测试 | 命令指标、慢操作日志、Trace 属性         | MUST 通过 |

## 13. 1.0 发布验收清单

- 业务只能通过标准 KeyBuilder 或受控 API 生成 Key。
- 缓存写入有 TTL 策略。
- 分布式锁不会误释放其他 owner 的锁。
- Redis 故障不会无限阻塞业务线程。

## 14. Definition of Done

- 公开 API、配置项、错误码、指标名完成冻结并记录兼容性说明。
- README、快速开始、配置参考、错误码参考、测试说明完成。
- MUST 能力均有自动化测试，CI 可重复执行。
- 示例工程或最小可运行样例通过。
- 发布包不包含测试密钥、临时文件、个人环境路径。

## 15. 1.0 后演进方向

- 支持 Redis Cluster 拓扑感知增强。
- 提供更多数据结构封装，但保持最小 API。
- 支持缓存一致性事件与 kafkax/natsx 联动。
