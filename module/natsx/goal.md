# natsx 发布版本 1.0 Goal 定位与实现标准

| 字段 | 内容 |
| --- | --- |
| 模块名 | `natsx` |
| 发布版本 | 1.0.0 |
| 所属层级 | 消息扩展层 / NATS 轻量消息与服务通信 |
| 稳定级别 | Public API Stable；SPI Stable；Internal 可演进 |
| 文档状态 | 1.0 发布基线文档 |
| 发布日期基准 | 2026-06-09 |

## 术语约定

本文档中的 **MUST / 必须** 表示 1.0 发布阻断项；**SHOULD / 应该** 表示 1.0 推荐项，允许带明确理由延期；**MAY / 可以** 表示可选能力，不影响 1.0 发布。

## 1.0 发布判定原则

1. **稳定优先**：公开 API、配置项、错误码、指标名一旦进入 1.0，默认需要向后兼容。
2. **边界清晰**：模块只能解决自身层级的问题，不能向上侵入业务，也不能横向替代其他模块。
3. **证据完整**：每个 MUST 能力都必须有单元测试、关键路径集成测试或契约测试证明。
4. **可观测**：所有运行时模块必须输出最小可诊断信息，包括错误、耗时、调用量和关键状态。
5. **可演进**：1.0 允许保留扩展点，但不得把未稳定能力包装成稳定承诺。

## 1. Goal 定位

`natsx` 的 Goal 是提供 NATS 的统一轻量消息通信封装，覆盖发布订阅、请求响应、JetStream 持久化、低延迟事件总线、服务内通信、序列化、Header、Trace 传播、重连、超时和观测。它强调轻量、实时和内部通信边界，避免与 Kafka 的大规模事件流定位混淆。

### 1.1 为什么需要这个模块

- 内部服务和边缘场景常需要低延迟、轻量级 pub/sub 或 request/reply。
- NATS subject 命名、Header、重连、JetStream 消费语义需要统一。
- 请求响应模式若没有超时和 Trace，会造成隐性阻塞。
- 需要明确 NATS 与 Kafka 的使用边界：NATS 偏实时轻量，Kafka 偏高吞吐持久事件流。

### 1.2 1.0 要解决的问题

- 统一 NATS publish/subscribe/request/reply。
- 统一 subject 命名、Header、消息 Envelope。
- 统一 JetStream stream、consumer、ack、重投递策略。
- 统一重连、超时、错误分类和观测。
- 提供与 observex 和 resiliencx 的集成。

### 1.3 目标用户

- 业务服务开发者
- 平台基础设施开发者
- SRE / 运维人员
- 测试工程师

## 2. 1.0 发布目标

- MUST 提供 PubSubClient、RequestReplyClient、JetStreamClient 三类基础能力。
- MUST 定义 subject 命名规范：domain.resource.action.version。
- MUST 支持 Header 注入 traceId、messageId、schemaVersion。
- MUST 支持请求响应超时和错误映射。
- MUST 支持 JetStream ack/nack/term 和重复消息处理。

## 3. 核心场景

| 场景 | 说明 | 1.0 期望结果 |
| --- | --- | --- |
| 内部事件通知 | 设备状态变化通知多个内部组件 | 低延迟 publish/subscribe，订阅者快速收到 |
| 请求响应 | 服务间轻量 RPC 式调用 | request 设置超时，response 带 trace context |
| 持久事件 | 需要 JetStream 保留短期事件 | 消费 ack 后确认处理，失败重投递 |
| 边缘通信 | 边缘节点与中心轻量事件同步 | 断线重连和缓冲策略可配置 |

## 4. 能力范围

| 能力域 | 1.0 必须具备的能力 | 验收方式 |
| --- | --- | --- |
| Subject 规范 | domain.resource.action.v1、通配符约束 | 命名检查测试通过 |
| 发布订阅 | publish、subscribe、queue group、unsubscribe | 真实 NATS 集成测试通过 |
| 请求响应 | request、reply、timeout、错误响应 | 超时测试通过 |
| JetStream | stream、consumer、ack/nack、durable consumer | 持久消费测试通过 |
| 序列化 | JSON/Binary/Proto SPI、schemaVersion | 兼容性测试通过 |
| 重连治理 | 断线重连、连接状态事件、退避 | 故障测试通过 |
| 观测 | 低延迟指标、错误、重投递、ack 耗时 | 观测测试通过 |

## 5. 职责边界

### 5.1 模块内职责

- 提供 NATS 标准客户端封装。
- 提供 subject、Header、Envelope 和序列化规则。
- 提供 JetStream 基础持久化消费能力。
- 提供请求响应超时、错误和 Trace 传播。

### 5.2 明确非目标

- 不替代 Kafka 的大规模持久事件流和长期回放场景。
- 不承诺复杂事务消息。
- 不替代服务治理或 RPC 框架的全部能力。
- 不隐藏 NATS subject 和 consumer 语义。

## 6. 依赖关系与分层约束

| 依赖类型 | 约束 |
| --- | --- |
| 上游依赖 | 依赖 kernel、configx、observex、resiliencx；MUST 向 contracts 登记事件契约和错误码契约。 |
| 下游依赖 | 实时内部事件、轻量请求响应、边缘消息可使用 natsx。 |
| 分层约束 | natsx 不依赖 kafkax；两者通过文档明确边界。 |

## 7. 对外契约

### 7.1 公开能力面

| 契约 | 定位 | 1.0 稳定承诺 |
| --- | --- | --- |
| NatsPubSubClient | 发布订阅接口 | publish/subscribe 语义稳定 |
| NatsRequestClient | 请求响应接口 | timeout 和错误语义稳定 |
| JetStreamClientX | 持久消息接口 | ack/nack/consumer 语义稳定 |
| NatsMessageEnvelope | 消息信封 | 核心字段稳定 |
| SubjectBuilder | subject 构造器 | 命名规则稳定 |

### 7.2 1.0 逻辑接口基线

```text
Subject pattern:
  {domain}.{resource}.{action}.v{version}

NatsPubSubClient
  publish(subject, message): PublishResult
  subscribe(subject, handler): Subscription

NatsRequestClient
  request(subject, message, timeout): Response
  reply(subject, handler): Subscription

JetStreamClientX
  publish(stream, subject, message): PublishAck
  consume(stream, consumer, handler): ConsumerHandle

NatsMessageEnvelope (extends contracts MessageEnvelope baseline)
  eventId              — 全局唯一消息标识（基线字段）
  schemaVersion        — 消息 schema 版本（基线字段）
  traceId              — 分布式追踪 ID（基线字段）
  payload              — 业务载荷（基线字段）
  headers              — 扩展头信息（基线字段）
  subject              — NATS subject 路由（natsx 扩展）
  messageId            — 消息标识（natsx 扩展，与 eventId 同义）

SubjectBuilder
  build(domain, resource, action, version): string
  parse(subject): SubjectParts
```

## 8. 配置契约

| 配置项 | 含义 | 默认值 / 要求 | 稳定性 |
| --- | --- | --- | --- |
| foundationx.nats.enabled | 是否启用 natsx | false，由业务显式启用 | Stable |
| foundationx.nats.servers | NATS server 列表 | 必须配置 | Stable |
| foundationx.nats.client-name | 客户端名称 | 应用名 | Stable |
| foundationx.nats.request.timeout | 请求响应默认超时 | 1s | Stable |
| foundationx.nats.reconnect.max-attempts | 重连次数 | -1 表示持续重连，生产需明确 | Stable |
| foundationx.nats.jetstream.enabled | 是否启用 JetStream | false | Stable |
| foundationx.nats.serializer | 序列化器 | json | Stable |

## 9. 可观测契约

### 9.1 日志

- MUST 输出模块初始化结果、关键配置摘要和失败原因；敏感配置必须脱敏。
- MUST 在关键操作失败时输出 errorCode、operation、durationMs、traceId、resource。
- SHOULD 对慢操作输出 warn 级别日志，阈值由配置控制。
- MUST 包含 subject、messageId、operation、stream、consumer。
- MUST 对 request timeout、reconnect、ack failure 输出结构化日志。

### 9.2 指标

| 指标名 | 类型 | 标签 | 说明 |
| --- | --- | --- | --- |
| foundationx_nats_publish_total | Counter | subject,status | 发布次数 |
| foundationx_nats_publish_duration_ms | Timer | subject,status | 发布耗时 |
| foundationx_nats_request_total | Counter | subject,status | 请求次数 |
| foundationx_nats_request_duration_ms | Timer | subject,status | 请求耗时 |
| foundationx_nats_consume_total | Counter | subject,consumer,status | 消费次数 |
| foundationx_nats_redelivery_total | Counter | stream,consumer | 重投递次数 |
| foundationx_nats_connection_state | Gauge | server,state | 连接状态 |

### 9.3 Trace / 诊断事件

- MUST 接收并传播上游 trace context，不得无故丢失 requestId / traceId。
- SHOULD 为外部依赖调用创建 span，并标注 peer、operation、status、errorCode。
- MAY 输出模块内部诊断事件，用于启动分析和运行期排障。
- MUST 在 NATS Header 中传播 trace context。
- SHOULD 对 request/reply 两端建立 client/server span。

## 10. 错误模型与失败策略

| 错误类别 | 典型原因 | 1.0 处理策略 |
| --- | --- | --- |
| NATS_CONNECTION_FAILED | server 不可达、认证失败 | 按重连策略处理并输出状态 |
| NATS_REQUEST_TIMEOUT | 请求响应超时 | 返回超时错误，不无限等待 |
| NATS_PUBLISH_FAILED | 发布失败或 JetStream ack 失败 | 按策略重试或返回失败 |
| NATS_DESERIALIZATION_FAILED | 消息解码失败 | JetStream 场景可 nack 或 term |
| NATS_ACK_FAILED | ack/nack/term 失败 | 记录错误并按消费语义处理 |

## 11. 安全、稳定性与兼容性要求

- MUST 对密码、token、accessKey、secretKey、连接串中的敏感片段做脱敏。
- MUST 保证公开 API 的异常不会泄漏内部凭据、主机隐私或完整连接串。
- MUST 为所有网络和外部依赖调用设置超时边界。
- SHOULD 支持最小权限原则，不要求业务使用高权限账号。
- MUST 支持认证、TLS 配置。
- MUST 避免在 subject 中包含敏感个人信息。
- SHOULD 限制通配符订阅范围，避免误订阅敏感 subject。

## 12. 测试证据要求

| 测试类型 | 必须覆盖内容 | 发布门禁 |
| --- | --- | --- |
| 单元测试 | SubjectBuilder、Envelope、错误映射、序列化 | MUST 通过 |
| 集成测试 | 真实 NATS pub/sub、request/reply、queue group | MUST 通过 |
| JetStream 测试 | publish ack、consume ack/nack、redelivery | MUST 通过 |
| 故障测试 | 断线重连、请求超时、解码失败 | MUST 通过 |
| 观测测试 | 日志、指标、Trace Header | MUST 通过 |

## 13. 1.0 发布验收清单

- subject 命名统一并可校验。
- request/reply 必须有超时。
- JetStream 消费失败处理明确。
- NATS 与 Kafka 使用边界在文档中清晰说明。

## 14. Definition of Done

- 公开 API、配置项、错误码、指标名完成冻结并记录兼容性说明。
- README、快速开始、配置参考、错误码参考、测试说明完成。
- MUST 能力均有自动化测试，CI 可重复执行。
- 示例工程或最小可运行样例通过。
- 发布包不包含测试密钥、临时文件、个人环境路径。

## 15. 1.0 后演进方向

- 支持 service discovery 风格的 NATS Service API 封装。
- 支持边缘离线缓冲策略。
- 支持与 contracts 的 subject schema 管理联动。
