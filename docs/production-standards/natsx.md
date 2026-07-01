# natsx

## 1. 模块定位
封装 NATS 客户端，提供 Core NATS（发布/订阅、Request-Reply，at-most-once 低延迟）和 JetStream（持久化、消费组，at-least-once）统一封装与可观测集成。Status=Approved、Layer=基座·存储扩展、Version=v1.0.2 release / v1.0.3 tag-only。背景：70+ 模块需低延迟内部通信，各自封装 NATS 导致重连、Core/JetStream 混用、subject 命名、健康检查、可观测和安全脱敏不一致。

## 2. 生产职责
- Core NATS：`Publish(ctx, subject, msg)`、`Subscribe(ctx, subject, handler)`、`Request(ctx, subject, msg, timeout)`、`Reply`
- JetStream：`JetStreamClientX.Publish/Consume/AddStream/AddConsumer`（返回 PublishAck，ack 后 offset 推进，超 max_deliver 进 Dead Letter）
- `SubjectBuilder.Build/Parse`：`domain.resource.action.v{version}` 构造与解析
- `Health()`：连接正常 Ready/Live=true；JetStream 不可用 Ready=false/Live=true
- 与 kernel 生命周期集成，metrics/tracing/logging 接入 observex

## 3. 边界定义
- 允许依赖 kernel、configx（不解析配置源）、observex（interface-only）、resiliencx（可选）、nats.go
- 禁止依赖 kafkax/redisx/postgresx 等同层 L2 模块、L2.5 领域共享层、业务域、x.go
- 所有操作必须接受 `context.Context`，支持超时和取消（BR-003）
- Header/Trace 双向映射：traceId/messageId/schemaVersion 在 Envelope 与 NATS Header 间映射，冲突以 Envelope 为准

## 4. 不负责什么
- NATS 集群管理、消息路由（业务层决定 subject）、消息去重（应用层 idempotency key）
- NATS Leaf Node / Super-Cluster 配置
- 配置解析（→ configx）

## 5. 架构位置
L2 基础设施适配器（存储扩展）。消费者：market_data（Core NATS 实时行情）、signal-engine（Core NATS 因子信号）、order_engine（JetStream 订单事件）、risk_engine（JetStream 风控事件）、schedulerx（Request-Reply 分布式协调）。go.mod：`github.com/ZoneCNH/natsx`，go 1.23。

## 6. 生命周期
- Client 与 kernel 应用生命周期集成，应用启停时创建与关闭
- Subscription 在 Close/Drain 时正确释放资源（BR-009），Drain 超时返回 `ErrDrainTimeout`（默认 drain-timeout 30s）
- 自动重连默认指数退避（reconnect wait 2s、max-attempts -1 即无限），重连期间 Core NATS 消息丢失，JetStream 重连后恢复消费不丢消息
- Health 周期检查（health-check-interval 10s），幂等无副作用（BR-006）
- ping interval 30s、max-outstanding 3

## 7. 标准目录结构
```text
natsx/
├── go.mod / go.sum / README.md / CHANGELOG.md / LICENSE / doc.go
├── natsx.go          # PubSub/Request/JetStream 工厂
├── client.go         # Core NATS 发布订阅与 Request 实现
├── jetstream.go      # JetStreamClientX 实现
├── subscription.go   # Subscription 接口实现
├── health.go         # HealthStatus
├── options.go        # Option 模式
├── errors.go         # 公共错误变量
├── codec.go          # Codec 接口及默认 JSON codec
├── msg.go            # NatsMessageEnvelope 结构体
├── internal/{codec,reconnect}
├── testdata/nats-server.conf
├── example_test.go / benchmark_test.go
└── integration_test.go  # //go:build integration
```

## 8. 配置规范
稳定前缀 `foundationx.nats.*`。env canonical `FOUNDATIONX_NATS_*` 优先，legacy `NATS_*` 回退。
```yaml
foundationx:
  nats:
    enabled: false
    servers: ["${FOUNDATIONX_NATS_SERVERS}"]
    client-name: "foundationx"
    credentials: ""
    request: {timeout: 1s}
    reconnect: {wait: 2s, max-attempts: -1}
    ping: {interval: 30s, max-outstanding: 3}
    drain-timeout: 30s
    serializer: json
    jetstream: {enabled: false, domain: ""}
    health-check-interval: 10s
    tls: {enabled: false, ca-file: ""}
```
Option：`WithServers / WithClientName / WithCredentials / WithReconnectWait / WithMaxReconnects / WithJetStreamEnabled / WithCodec`。`ConfigFromEnv` 支持后缀 NAME/URL/SERVERS/TOKEN/USERNAME/PASSWORD/NKEY_SEED/CREDENTIALS_FILE 等，解析错误不得打印 token/password/nkey。

## 9. 错误模型
typed sentinel errors：`ErrConnectionFailed / ErrTimeout / ErrNoResponders / ErrStreamExists / ErrConsumerExists / ErrStreamNotFound / ErrJetStreamDisabled / ErrInvalidSubject / ErrDrainTimeout`。格式 `"natsx: <operation>: <detail>"`，`%w` 包装保留底层错误链。错误消息只含 subject，不含 data/payload/凭据（BR-008）。

## 10. 日志规范
structured logging，关键事件：`natsx.connected`(info) / `natsx.disconnected`(warn) / `natsx.reconnecting`(info) / `natsx.reconnected`(info) / `natsx.handler.panic`(error)。日志携带 traceId/messageId，对 credentials 路径、token、password、nkey seed、连接串脱敏。

## 11. Metrics
canonical `foundationx_nats_*` 前缀（legacy `natsx_*` 不属 1.0 契约）：
| 名称 | 类型 | 标签 |
|------|------|------|
| `foundationx_nats_publish_total` | counter | subject,status |
| `foundationx_nats_publish_duration_ms` | timer | — |
| `foundationx_nats_request_total` | counter | subject,status |
| `foundationx_nats_request_duration_ms` | timer | — |
| `foundationx_nats_consume_total` | counter | subject,consumer,status |
| `foundationx_nats_redelivery_total` | counter | stream,consumer |
| `foundationx_nats_connection_state` | gauge | server,state |

## 12. Tracing
`NatsMessageEnvelope` 携带 TraceID 字段，traceId/messageId/schemaVersion 在 Envelope 与 NATS Header 间双向映射；已有上游 Header 不得无故丢弃，冲突字段以 Envelope 显式字段为准并记录诊断事件。repair-slice 不主张分布式追踪；production distributed tracing 留作后续增强。

## 13. Reliability
- retry/backoff：自动重连默认指数退避（reconnect wait 2s、max-attempts -1），重连失败返回 `ErrConnectionFailed`
- timeout：request timeout 1s、drain-timeout 30s、ctx 取消返回 `ctx.Err()`
- backpressure：handler 必须快速返回（BR-004），长时间处理应异步化，阻塞 → Drain 超时
- circuit breaker：JetStream 超过 max_deliver 进入 Dead Letter；Client 不内置断路器
- 重连恢复：Core NATS 重连后自动恢复订阅；JetStream 重连后恢复消费不丢消息

## 14. Security
| 要求 | 实现方式 |
|------|----------|
| 凭证不硬编码 | 凭证文件或环境变量注入 |
| TLS 加密传输 | 配置启用 TLS |
| 凭证不写日志 | credentials 路径脱敏 |
| 错误不泄露消息内容 | 只含 subject，不含 data |

**生产 TLS 闭环（BLK-002，历史 release-blocking）**：repair-slice live integration 可用 redacted local/dev 凭证证明 secret-safe 加载；BLK-002 已按治理证据闭合，后续如生产 TLS 证据回退则重开。packet 路径见 `release/trust/foundation-maturity-evidence-matrix-20260615.md#blk-002`。

## 15. Performance SLO
| 操作 | 目标 | 测量 |
|------|------|------|
| 单条 Core NATS 发布 | < 1ms | benchmark |
| Request-Reply | < 5ms | benchmark |
| JetStream 单条发布 | < 2ms | benchmark |
| JetStream 单条消费 | < 2ms | benchmark |
| 序列化 1KB JSON | < 10μs | benchmark |
| 常驻内存 | < 5MB | profiling |
| handler 调度延迟 | < 100μs | benchmark |

CI smoke SLO（embedded）：Core Request ≤1500ms、JetStream Publish ≤2s、JetStream Fetch ≤4s（CI 稳定护栏，非生产 benchmark 替代）。

## 16. 测试标准
单元测试覆盖所有 FR/BR/NFR。TC-001（Core Pub/Sub/Unsubscribe/Drain）、TC-002（Request responder/no-responder/timeout/cancel）、TC-003（JetStream publish/pull/ack/nack redelivery/max-deliveries advisory + AddStream/AddConsumer 幂等/冲突）、TC-004（reconnect backoff/degraded health）、TC-005（Health 各路径）、TC-006..014（SubjectBuilder/Envelope/Config/Observability/Security/Benchmark/Layer boundary/Release evidence）。v1.0.3 实测：pkg/natsx 包级覆盖率 97.1%（v1.0.1=73.3% → v1.0.2=90.0% → v1.0.3=97.1%），race-clean。

## 17. Chaos
SPEC 未定义独立 chaos 矩阵。集成测试与 embedded 测试覆盖等效维度：连接断开后自动重连并恢复订阅、JetStream 断线重连不丢消息、handler panic 被 catch 不影响其他订阅、Drain 超时返回 `ErrDrainTimeout`、NATS 不可达时 Publish 返回 `ErrConnectionFailed`、JetStream disabled 时返回 `ErrJetStreamDisabled`。production reconnect exponential-backoff SLO gate 为外部阻塞项。

## 18. Contract
```go
type NatsPubSubClient interface {
    Publish(ctx, subject string, msg NatsMessageEnvelope) (PublishResult, error)
    Subscribe(ctx, subject string, handler NatsMessageHandler, opts ...SubscribeOption) (Subscription, error)
}
type NatsRequestClient interface {
    Request(ctx, subject string, msg NatsMessageEnvelope, timeout time.Duration) (NatsMessageEnvelope, error)
    Reply(ctx, subject string, handler NatsMessageHandler) (Subscription, error)
}
type JetStreamClientX interface {
    Publish(ctx, stream, subject string, msg NatsMessageEnvelope) (*PublishAck, error)
    Consume(ctx, stream, consumer string, handler NatsMessageHandler) (ConsumerHandle, error)
    AddStream(ctx, cfg *StreamConfig) error
    AddConsumer(ctx, stream string, cfg *ConsumerConfig) error
}
type SubjectBuilder interface { Build(domain, resource, action string, version int) (string, error); Parse(subject string) (SubjectParts, error) }
```
`NatsMessageEnvelope`：EventID/MessageID/SchemaVersion/TraceID/Subject/Headers/Payload。

## 19. CI Gate
通用：`go build`、`go test -race -count=1`、覆盖率 < 80% 阻塞、`go vet`、`golangci-lint run`、`go mod tidy --exit-code`、`gitleaks detect --no-git`、benchmark 附 PR comment。专属：`GOWORK=off go test ./pkg/natsx -count=1`、`GOWORK=off go vet ./pkg/natsx`、live gate default（unset 时 skip/pass）、local auth live integration（仅授权 dev 端点，凭据 redacted）、production TLS closure packet（授权生产环境 + 归档 TLS/SLO/signoff；BLK-002 已按治理证据闭合，后续回归时重开）。

## 20. Release Gate
- [x] FEATURES/ACCEPTANCE 与 SPEC/TRACEABILITY 登记一致（v1.0.3）
- [x] go test/race/vet/coverage 通过（pkg/natsx 97.1%，总覆盖率 84.2%）
- [x] embedded broker + local auth live integration 提供测试替身（redacted 凭据）
- [x] secret scan 通过（无 payload/凭据/连接串明文）
- [x] 版本标签 + CHANGELOG 一致（/home/workspace/natsx commit 20f801f / b5adee9，tag v1.0.3；tag-only 不等于 GitHub Release）
- [x] GitHub Release v1.0.2 发布证据（2026-06-18 published）
- [x] **BLK-002 生产 TLS 闭环 packet 归档**（治理证据已闭合；后续回归时重开）
- [x] 四源 98+ 仲裁、生产 benchmark 阈值 gate（治理证据已闭合；后续回归时重开）

## 21. Versioning
semver。PubSub/Request/JetStreamClientX 接口新增方法=minor，删除/修改=major；Subscription/NatsMessageEnvelope 变更=major；StreamConfig/ConsumerConfig 新增字段=minor（带默认值）；Option 新增=minor。当前 v1.0.2 release / v1.0.3 tag-only，只升不降。

## 22. 兼容性策略
- Core NATS 用于实时低延迟 at-most-once（BR-001）；JetStream 用于持久化 at-least-once（BR-002）
- AddStream/AddConsumer 配置兼容时返回 nil（幂等），配置冲突返回 `ErrStreamExists/ErrConsumerExists`
- JetStream disabled 时调用 JS 方法返回 `ErrJetStreamDisabled`
- 空 subject 返回 `ErrInvalidSubject`
- 配置：canonical `FOUNDATIONX_NATS_*` 优先于 legacy `NATS_*`

## 23. Failover
- NATS 不可达时 Publish 返回 `ErrConnectionFailed`
- 自动重连指数退避，重连期间 Core NATS 消息丢失，重连后自动恢复订阅
- JetStream 重连后自动恢复消费，不丢消息（持久化保证）
- JetStream 已启用但不可用时 Health 返回 `Ready:false, Live:true, Message:"jetstream unavailable"`
- Request 无 responder 超时返回 `ErrNoResponders`

## 24. Backpressure
- handler 必须快速返回（BR-004），长时间处理异步化；阻塞 → Drain 超时返回 `ErrDrainTimeout`
- Drain 处理完已接收消息后关闭订阅
- JetStream：消息未 ack 且超过 max_deliver 进入 Dead Letter
- 消息 payload 超限返回错误，不输出 payload 明文

## 25. 审计要求
所有关键操作可追踪：Publish/Subscribe/Request/JetStream 通过 `foundationx_nats_*` metrics + structured log + envelope TraceID 形成证据链。错误脱敏（BR-008），不输出 payload/凭据。Health 幂等无副作用（BR-006）。ConfigFromEnv 解析错误不打印 token/password/nkey/credentials 内容。生产 TLS 闭环 packet 是历史 release-blocking 治理产物，已闭合后作为回归审计证据保留。

## 26. 熵减规则
全局：禁止 util dumping、hidden abstraction、cyclic dependency。模块特有：公开 API 命名以 `goal.md` 1.0 逻辑接口基线为准（`NatsPubSubClient/NatsRequestClient/JetStreamClientX/NatsMessageEnvelope/SubjectBuilder`），不暴露泛化 `Client/JetStream`；配置稳定前缀 `foundationx.nats.*`；metrics canonical 前缀 `foundationx_nats_*`；canonical env 优先于 legacy alias。

## 27. AI Constraints
全局：AI 不允许新增未注册模块、绕过 contracts、动态扩展目录。模块特有：AI 修改 natsx 必须保持 FR-001..008 / BR-001..009 行为约束，不得误用 Core/JetStream 场景（BR-001/002）、不得在错误/日志输出 payload、不得用 legacy metric/env 名作 1.0 契约；所有公开操作必须保持 `context.Context` 与 `%w` 错误包装；生产晋升不得绕过 BLK-002 TLS 闭环证据；若证据回退必须重开 blocker。

## 28. Forbidden Patterns
- 用 JetStream 处理实时消息（BR-001 误用 → 延迟超标）
- 用 Core NATS 处理需持久化消息（BR-002 误用 → 丢消息）
- 接口签名不含 ctx 或忽略 ctx 取消（BR-003 编译/测试失败）
- handler 长时间阻塞同步处理（BR-004 → Drain 超时）
- 运行时创建 stream/consumer 而非启动时（BR-007）
- 错误/日志含 payload（BR-008 secret scan 阻断）
- Subscription 资源泄漏（BR-009 race 检测）
- 用 legacy `natsx_*` metric 名或 `NATS_*` env 作 1.0 契约

## 29. Production Ready Checklist
- [x] observability ready（foundationx_nats_* metrics 7 项 + envelope TraceID 传播 + structured log 脱敏）
- [x] resilience ready（自动重连指数退避、ctx 传播、JetStream 持久化、Drain 释放）
- [x] audit ready（错误脱敏 BR-008、Health 幂等 BR-006、ConfigFromEnv 不打印凭据）
- [x] rollback ready（semver + 接口兼容策略 + AddStream/AddConsumer 幂等）
- [x] coverage ready（pkg/natsx 97.1%，总 84.2%，race/vet/lint/secret 通过）
- [x] **production TLS closure packet（BLK-002）已按治理证据归档；后续证据回退时重开**
- 外部关注：四源 98+ 仲裁、生产 benchmark SLO gate、上层 consumer lifecycle/API 集成证据需持续保持

## 30. Roadmap
- v1.0.0（已发布）：Core NATS Pub/Sub/Request + JetStream Publish/Consume/AddStream/AddConsumer + Health + SubjectBuilder + Envelope
- v1.0.2（已发布）：GitHub Release 已发布，作为当前 release 证据
- v1.0.3（远端 tag-only）：pkg/natsx 覆盖率 97.1%，race-clean，CI/CD 路由 sre/* 机器池
- 待解决：NATS Leaf Node、JetStream KV Store、Object Store、Core NATS 丢失是否全走 JetStream、消息压缩
- 持续关注：生产 TLS 证据包、四源 98+ 仲裁、生产 benchmark 阈值回归验证
