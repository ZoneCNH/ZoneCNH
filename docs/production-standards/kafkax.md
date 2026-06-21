# kafkax

## 1. 模块定位
封装 Kafka 客户端，提供统一的生产者（同步/批量发送）、消费者（消费组 + 手动 offset）、序列化、健康检查和可观测集成。Status=Approved、Layer=基座·存储扩展、Version=v1.1.0（已发布）。背景：70+ 模块各自封装 Kafka 导致配置、序列化、offset 提交、健康检查、可观测和安全脱敏不一致。

## 2. 生产职责
- `Producer.Send(ctx, topic, key, value)`：同步单条发送，acks=all 默认，支持 retry
- `Producer.SendBatch(ctx, msgs)`：批量发送，部分失败返回首个可诊断错误
- `Consumer.Subscribe / Poll / Commit / Close`：消费组、轮询、手动 offset（at-least-once）
- `Health(ctx)`：基于 Kafka metadata 返回 Ready/Live
- 与 kernel 生命周期集成，metrics/tracing/logging 统一接入 observex

## 3. 边界定义
- 只负责 Kafka 客户端封装 + 观测适配，允许依赖 kernel、observex（interface-only）、Kafka 客户端库
- 禁止越过 FOUNDATION-DEPS.yaml 依赖上层业务域或 L2.5 领域共享层
- 所有阻塞/外部操作必须接受 `context.Context` 并返回 `error`
- 错误/日志脱敏边界：不得输出 message value、凭据、连接串

## 4. 不负责什么
- Kafka 集群管理、消息路由、exactly-once / Transactions / outbox 编排
- Schema Registry、Kafka Connect、异步 Producer 回调 API
- 业务事件信封 / 业务 schema / 业务幂等存储
- 消费失败转储编排（重试、转储、告警策略留作后续候选）
- 配置解析（→ configx）

## 5. 架构位置
属于 L2 基础设施适配器（存储扩展），位于基座层。消费者：market_data（Producer 发布行情）、signal_factory（Consumer 消费因子信号）、orderx（Producer 订单消息）、riskx（Consumer 风控消息）、业务域模块跨域事件通信。go.mod：`github.com/ZoneCNH/kafkax`，go 1.23。

## 6. 生命周期
- Producer/Consumer 在 kernel 应用启停时随应用生命周期创建与关闭
- `Close(ctx)` 处理最终 offset 提交和资源释放边界，失败必须返回错误不吞错，重复调用不 panic
- Health 周期性检查（`health_check_interval: 10s`）随应用运行持续执行，幂等无副作用
- ctx 取消/超时必须返回 `ctx.Err()` 或包装错误

## 7. 标准目录结构
```text
kafkax/
├── go.mod / go.sum / README.md / CHANGELOG.md / LICENSE / doc.go
├── kafkax.go          # Producer / Consumer 工厂
├── producer.go        # Producer 接口实现
├── consumer.go        # Consumer 接口实现
├── health.go          # HealthStatus / Health(ctx)
├── options.go         # Option 模式
├── errors.go          # 公共错误变量
├── codec.go           # Codec 接口及默认 JSON codec
├── dlq.go             # DeadLetterPublisher 边界
├── internal/{codec,retry}
├── testdata/docker-compose.yml
├── example_test.go / benchmark_test.go
└── integration_test.go  # //go:build integration
```

## 8. 配置规范
```yaml
kafkax:
  brokers: ["${KAFKAX_BROKER}"]
  producer: {acks: all, retries: 3, batch_size: 16384, linger_ms: 5,
             compression: snappy, max_message_bytes: 1048576, timeout: 30s}
  consumer: {group_id: "", auto_offset_reset: earliest, enable_auto_commit: false,
             max_poll_records: 500, poll_interval: 100ms,
             session_timeout: 45s, heartbeat_interval: 15s}
  retry: {max_attempts: 3}
  codec: json           # json / msgpack / protobuf
  health_check_interval: 10s
```
Option 模式：`WithBrokers / WithProducerAcks / WithProducerRetries / WithProducerCodec / WithGroupID / WithAutoOffsetReset` 等。非法 acks、负数重试、非法轮询参数在构造时返回 `ErrConfigInvalid`，不得静默降级。

## 9. 错误模型
typed sentinel errors：`ErrConnectionFailed / ErrAlreadySubscribed / ErrNotSubscribed / ErrInvalidMessage / ErrEmptyTopics / ErrEmptyBrokers / ErrSendFailed / ErrCommitFailed / ErrConfigInvalid`。格式 `"kafkax: <operation>: <detail>"`，`%w` 包装保留底层错误链，ctx 取消/超时必须返回 `ctx.Err()`。错误消息不包含 message key/value、凭据、连接串（BR-008）。

## 10. 日志规范
structured logging，关键事件：`kafkax.connected`(info) / `kafkax.disconnected`(warn) / `kafkax.rebalancing`(info) / `kafkax.send_failed`(error) / `kafkax.commit_failed`(error) / `kafkax.poll_failed`(error)。日志必须携带 traceId/requestId 并对 message value、SASL 密码、token、accessKey/secretKey、连接串脱敏。

## 11. Metrics
| 名称 | 类型 | 标签 |
|------|------|------|
| `kafkax.produce.duration` | histogram | topic,status |
| `kafkax.produce.errors` | counter | topic,error |
| `kafkax.produce.batch.size` | histogram | — |
| `kafkax.consume.duration` | histogram | topic,group,status |
| `kafkax.consume.lag` | gauge | partition offset 差值 |
| `kafkax.consume.messages` | counter | topic,group,status |
| `kafkax.consume.errors` | counter | topic,group,error |
| `kafkax.commit.errors` | counter | topic,group,error |
| `kafkax.retry.attempts` | counter | operation,reason |

## 12. Tracing
MUST 接收并传播上游 trace context，不丢失 requestId/traceId；MUST 在 message headers 注入 trace context；MUST 在消费端从 headers 恢复 trace context 并创建 consumer span；SHOULD 为 Kafka 操作创建 span 并标注 peer、operation、status、errorCode。

## 13. Reliability
- retry：Producer 默认 3 次，可配置，负数/非法返回配置错误，最终失败记录指标
- timeout：所有操作接受 ctx；producer timeout 30s、session_timeout 45s、heartbeat 15s
- backpressure：资源耗尽时返回包装错误并记录指标，不无限阻塞
- circuit breaker：Client 不内置；调用方或后续增强负责消费失败重试/转储编排（v1.0 baseline 不自动执行）
- Consumer rebalance：未成功 Commit 的消息允许重新投递

## 14. Security
| 要求 | 实现方式 |
|------|----------|
| SASL 认证 | 配置传入 SASL 凭证 |
| TLS 加密传输 | 配置启用 TLS |
| 凭证不写日志 | SASL 密码/token/accessKey/secretKey/连接串脱敏 |
| 错误不泄露消息内容 | 只含 topic/partition/offset/错误码/摘要 |
| Header 最小化传播 | 只传 trace context 和必要元数据 |

## 15. Performance SLO
| 操作 | 目标 | 测量 |
|------|------|------|
| 单条发送 | < 5ms | benchmark |
| 批量发送 100 条 | < 20ms | benchmark |
| 单条消费 | < 5ms | benchmark |
| 序列化 1KB JSON | < 10μs | benchmark |
| 常驻内存（空闲） | < 10MB | profiling |
| Consumer lag | < 1000 条 | integration test |

## 16. 测试标准
单元测试覆盖所有 FR/BR/边界，13 个 TC（TC-001..TC-013）覆盖 ProducerSend、SendBatch、Commit、Retry、Health、Subscribe、Poll/Context、Close、Config、AutoCommit、Sanitize。Benchmark 与集成测试（`//go:build integration`）覆盖完整 Send→Poll→Commit 链、批量、rebalance、断线恢复、消费失败边界。当前 pkg/kafkax 覆盖率 94.5%（>= 80% 门槛）。

## 17. Chaos
SPEC 未定义独立 chaos 矩阵。集成测试已覆盖等效维度：Kafka 不可达时 Send 返回错误且脱敏、断开后自动重连恢复消费、rebalance 期间 Commit 失败返回包装错误、资源耗尽返回包装错误不阻塞。Kafka 不可达时集成测试按 §19.2 skip 不阻塞发布。

## 18. Contract
```go
type Producer interface {
    Send(ctx, topic string, key, value []byte) error
    SendBatch(ctx, msgs []Message) error
    Close(ctx) error
}
type Consumer interface {
    Subscribe(ctx, topics []string) error
    Poll(ctx) (*Message, error)
    Commit(ctx, msg *Message) error
    Close(ctx) error
}
type Codec interface { Marshal(v any) ([]byte, error); Unmarshal(data []byte, v any) error }
```
Option 模式：`func NewProducer(opts ...ProducerOption) (Producer, error)`。Message 含 Topic/Partition/Offset/Key/Value/Headers/Timestamp；HealthStatus 含 Ready/Live/Message。

## 19. CI Gate
通用：`go build ./...`、`go test ./... -race -count=1`、覆盖率 `go tool cover -func`（< 80% 阻塞）、`go vet ./...`、`golangci-lint run`、`go mod tidy --exit-code`、`gitleaks detect --no-git`、`go test -bench=. -benchmem -count=3`。专属：`go test -tags=integration ./...`（Kafka 不可达时 skip 不阻塞）、TRACEABILITY.md 覆盖 FR-001..006 与 BR-001..009、SPEC.md 无未闭合代码块。

## 20. Release Gate
- [x] FEATURES/ACCEPTANCE 与 SPEC/TRACEABILITY 登记一致
- [x] go test/race/vet/coverage 门槛通过（pkg/kafkax 94.5%）
- [x] 外部依赖有 testkit 或 integration workflow 替身
- [x] goalcli secret scan 通过（无凭证/私有端点/实盘配置）
- [x] 版本标签 + CHANGELOG + release note 一致（GitHub release v1.1.0，PR#16）

## 21. Versioning
semver。Producer/Consumer 接口新增方法=minor（实现需跟上），删除/修改方法=major；Message 结构体变更=major（追加可选字段可 minor）；Option 新增字段=minor（带默认值）；默认 codec 变更=minor；指标名/标签语义变更视影响 minor/major。当前 v1.1.0，只升不降。

## 22. 兼容性策略
- 接口向后兼容：新增方法 minor，破坏性变更 major
- SendBatch 空列表返回 nil（幂等）；部分失败不回滚
- Consumer rebalance：重新分配 partition，未 Commit 消息允许重投
- Close 重复调用幂等（返回 nil 或 closed 错误，不 panic）
- Close 期间仍有 Send/Poll：尊重 ctx 取消返回 closed/ctx 错误

## 23. Failover
- Kafka 不可达时 Send 返回 `ErrConnectionFailed/ErrSendFailed`，按 retry 重试后失败
- 集成测试验证断开后自动重连并恢复消费
- Consumer rebalance 期间 Commit 失败返回 `ErrCommitFailed` 包装错误，调用方决定重试或关闭
- Producer Close 后 Send 返回 closed 错误不发送；Consumer Close 后 Poll 返回 closed 错误不拉取

## 24. Backpressure
- Producer：消息超过 `max_message_bytes` 返回 `ErrSendFailed`，不记录完整消息
- 资源耗尽/背压时返回包装错误并记录指标，不无限阻塞
- Consumer：`max_poll_records: 500` 限制单次拉取，`poll_interval: 100ms` 控制节奏
- 反序列化失败：返回可分类错误，不自动提交 offset，不输出 payload，调用方决定重试/跳过/转储/关闭

## 25. 审计要求
所有关键操作可追踪：Send/SendBatch/Subscribe/Poll/Commit/Close/Health 通过 metrics + trace span + structured log 形成证据链。错误不泄露 payload（BR-008）。Health 幂等无副作用（BR-007），多次调用可重复观察状态。Consumer offset 提交语义安全：`enable_auto_commit` 默认 false，未显式 Commit 不提交 offset（BR-009）。

## 26. 熵减规则
全局：禁止 util dumping、hidden abstraction、cyclic dependency。模块特有：接口契约集中在 Producer/Consumer/Codec/HealthChecker 四个抽象，Option 模式统一配置注入；错误集中在 errors.go；重试/序列化下沉到 internal 包。禁止隐式危险默认值（acks、auto_commit、retry 数值）。

## 27. AI Constraints
全局：AI 不允许新增未注册模块、绕过 contracts、动态扩展目录。模块特有：AI 修改 kafkax 必须保持 FR-001..006 / BR-001..009 行为约束，不得将默认 acks 降级、不得开启 auto_commit、不得在错误/日志输出 message value；所有公开操作必须保持 `context.Context` 参数和 `%w` 错误包装。

## 28. Forbidden Patterns
- 默认非 acks=all 发送（BR-001 禁止静默降级）
- 默认自动提交 offset（BR-002/BR-009 视为发布阻断）
- 忽略 ctx 取消/超时（BR-003 接口阻断）
- Close 吞掉 offset/释放失败（BR-004）
- 错误/日志含完整 payload 或凭据（BR-008 安全阻断）
- Health 改变订阅/offset/连接生命周期（BR-007）
- 业务 schema / 业务幂等下沉到 kafkax

## 29. Production Ready Checklist
- [x] observability ready（metrics 9 项 + trace context 传播 + structured log 脱敏）
- [x] resilience ready（retry 默认 3 次、ctx 传播、rebalance 重投、断线恢复）
- [x] audit ready（错误脱敏 BR-008、Health 幂等 BR-007、offset 安全 BR-009）
- [x] rollback ready（semver + 接口兼容策略 + Close 幂等）
- [x] coverage ready（pkg/kafkax 94.5%，race/vet/lint/secret 全通过）
- 集成测试由 integration workflow 在 SRE 池执行，Kafka 不可达时 skip 不阻塞

## 30. Roadmap
- v1.0 候选基线：Producer/Consumer/Health/Codec/manual offset（已完成）
- v1.1.0（已发布）：CI/Release 基线、pkg/kafkax 94.5% 覆盖、integration workflow
- 后续候选（不阻断）：异步 Producer 回调 API、Kafka Transactions、Consumer Assign 模式、Schema Registry、消费失败重试/转储编排
