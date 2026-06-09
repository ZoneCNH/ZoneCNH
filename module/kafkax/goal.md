# kafkax 发布版本 1.0 Goal 定位与实现标准

| 字段 | 内容 |
| --- | --- |
| 模块名 | `kafkax` |
| 发布版本 | 1.0.0 |
| 所属层级 | 消息扩展层 / Kafka 事件流 |
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

`kafkax` 的 Goal 是提供 Kafka 的统一事件流接入能力，标准化消息生产、消费、事件信封、序列化、Header、重试、死信、幂等、事务边界、位点处理和可观测。它支撑高吞吐、可追踪、可治理的异步事件处理，但不隐藏 Kafka 的分区、消费组和位点等核心语义。

### 1.1 为什么需要这个模块

- Kafka 生产和消费若缺乏统一事件信封，会导致上下游无法追踪和演进。
- 消费失败处理如果不统一，会出现消息丢失、无限重试或死信不可读。
- 幂等消费和位点提交是可靠消息处理核心，必须从 1.0 明确定义。
- 消息链路需要贯穿 traceId、eventId、schemaVersion，方便排障和审计。

### 1.2 1.0 要解决的问题

- 统一 Producer、ConsumerContainer、MessageHandler、Serializer。
- 统一 EventEnvelope 和 Header 规范。
- 统一消费重试、死信、延迟重试和失败分类。
- 统一幂等键、去重存储 SPI 和事务边界策略。
- 统一生产/消费指标、积压、失败、重试和 Trace。

### 1.3 目标用户

- 业务服务开发者
- 平台基础设施开发者
- SRE / 运维人员
- 测试工程师

## 2. 1.0 发布目标

- MUST 提供标准事件信封，包含 eventId、eventType、schemaVersion、source、occurredAt、traceId、idempotencyKey。
- MUST 支持同步/异步生产和回调结果。
- MUST 支持消费者容器、并发度、手动/自动受控提交。
- MUST 支持消费失败重试和死信 Topic。
- MUST 支持幂等消费扩展点，默认不承诺 exactly-once。

## 3. 核心场景

| 场景 | 说明 | 1.0 期望结果 |
| --- | --- | --- |
| 事件发布 | 订单服务发布订单已创建事件 | 事件信封完整，生产结果可观测 |
| 消费处理 | 库存服务消费订单事件 | handler 成功后提交位点，失败按策略重试 |
| 消费失败 | 事件格式错误或业务处理失败 | 不可重试进入死信，可重试进入重试策略 |
| 链路追踪 | 请求触发事件并被异步消费 | 生产和消费 span 通过 traceId 串联 |

## 4. 能力范围

| 能力域 | 1.0 必须具备的能力 | 验收方式 |
| --- | --- | --- |
| 事件信封 | EventEnvelope、Header、schemaVersion、trace 信息 | 契约测试通过 |
| 生产者 | send、sendBatch、key 分区、回调、确认级别 | 真实 Kafka 集成测试通过 |
| 消费者 | ConsumerContainer、并发、位点提交、rebalance 处理 | 消费集成测试通过 |
| 失败处理 | 错误分类、重试 Topic、DLQ、poison message 处理；DLQ 消息必须保留原始 topic、partition、offset、eventId、errorCode、retryCount 和失败原因；最大重试次数默认 3，超过后转入 DLQ 并触发告警指标 | 失败场景测试通过 |
| 幂等 | idempotencyKey、去重 SPI、重复消息跳过 | 重复投递测试通过 |
| 序列化 | JSON/Avro/Proto SPI、schema 版本 | 兼容性测试通过 |
| 治理观测 | 生产/消费/积压/错误/重试/死信指标 | 观测测试通过 |

## 5. 职责边界

### 5.1 模块内职责

- 提供 Kafka 标准生产和消费封装。
- 提供事件信封、Header、序列化和契约规则。
- 提供消费失败、重试、死信和幂等处理框架。
- 接入 configx、observex、resiliencx。

### 5.2 明确非目标

- 不替代 Kafka 集群管理平台。
- 不替代业务事件语义设计。
- 不隐藏分区、key、消费组、位点等核心概念。
- 不默认承诺 exactly-once；事务能力需要明确使用限制。

## 6. 依赖关系与分层约束

| 依赖类型 | 约束 |
| --- | --- |
| 上游依赖 | 依赖 kernel、configx、observex、resiliencx；MUST 向 contracts 登记事件契约和错误码契约。 |
| 下游依赖 | 业务事件流、审计/日志管道、异步集成可使用 kafkax。 |
| 分层约束 | kafkax 不依赖具体业务 schema；schema 通过 contracts 或 serializer SPI 管理。 |

## 7. 对外契约

### 7.1 公开能力面

| 契约 | 定位 | 1.0 稳定承诺 |
| --- | --- | --- |
| KafkaProducerX | 生产接口 | send 结果和错误语义稳定 |
| KafkaConsumerContainer | 消费容器 | 生命周期和位点提交语义稳定 |
| MessageHandler | 业务处理接口 | 成功/失败/重试结果语义稳定 |
| EventEnvelope | 事件信封 | 核心字段稳定，只能追加可选字段 |
| KafkaSerializer SPI | 序列化扩展点 | encode/decode 语义稳定 |
| DeadLetterPublisher | 死信发布接口 | 死信字段稳定 |

### 7.2 1.0 逻辑接口基线

```text
EventEnvelope<T> (extends contracts MessageEnvelope baseline)
  eventId          — 全局唯一消息标识（基线字段）
  schemaVersion    — 消息 schema 版本（基线字段）
  traceId          — 分布式追踪 ID（基线字段）
  payload          — 业务载荷（基线字段）
  headers          — 扩展头信息（基线字段）
  eventType        — 事件类型（kafkax 扩展）
  source           — 事件来源（kafkax 扩展）
  occurredAt       — 事件发生时间（kafkax 扩展）
  idempotencyKey   — 幂等键（kafkax 扩展）

KafkaProducerX
  send(topic, key, envelope): SendResult
  sendBatch(records): BatchSendResult

MessageHandler
  handle(ConsumerContext, EventEnvelope<T>): HandlerResult

HandlerResult
  success | retry(reason) | deadLetter(reason) | skip(reason)
```

## 8. 配置契约

| 配置项 | 含义 | 默认值 / 要求 | 稳定性 |
| --- | --- | --- | --- |
| foundationx.kafka.enabled | 是否启用 kafkax | false，由业务显式启用 | Stable |
| foundationx.kafka.bootstrap-servers | Kafka 地址 | 必须配置 | Stable |
| foundationx.kafka.client-id | 客户端标识 | 应用名 | Stable |
| foundationx.kafka.producer.acks | 生产确认级别 | all | Stable |
| foundationx.kafka.consumer.group-id | 消费组 | 消费者必须配置 | Stable |
| foundationx.kafka.consumer.concurrency | 消费并发 | 1 | Stable |
| foundationx.kafka.retry.max-attempts | 消费最大重试 | 3 | Stable |
| foundationx.kafka.dlq.suffix | 死信 Topic 后缀 | .DLQ | Stable |
| foundationx.kafka.serializer | 序列化器 | json | Stable |
| foundationx.kafka.producer.timeout | 生产者发送超时 | 30s | Stable |
| foundationx.kafka.consumer.session-timeout | 消费者会话超时 | 45s | Stable |
| foundationx.kafka.consumer.heartbeat-interval | 心跳间隔 | 15s | Stable |

## 9. 可观测契约

### 9.1 日志

- MUST 输出模块初始化结果、关键配置摘要和失败原因；敏感配置必须脱敏。
- MUST 在关键操作失败时输出 errorCode、operation、durationMs、traceId、resource。
- SHOULD 对慢操作输出 warn 级别日志，阈值由配置控制。
- MUST 生产和消费日志包含 topic、partition、offset、eventId、eventType、consumerGroup。
- MUST 对 payload 做大小限制和敏感字段脱敏，默认不打印完整 payload。

### 9.2 指标

| 指标名 | 类型 | 标签 | 说明 |
| --- | --- | --- | --- |
| foundationx_kafka_produce_total | Counter | topic,eventType,status | 消息生产次数 |
| foundationx_kafka_produce_duration_ms | Timer | topic,status | 生产耗时 |
| foundationx_kafka_consume_total | Counter | topic,group,eventType,status | 消费次数 |
| foundationx_kafka_consume_duration_ms | Timer | topic,group,eventType,status | 消费耗时 |
| foundationx_kafka_retry_total | Counter | topic,eventType,reason | 重试次数 |
| foundationx_kafka_dlq_total | Counter | topic,eventType,reason | 死信次数 |
| foundationx_kafka_consumer_lag | Gauge | topic,group,partition | 消费积压 |

### 9.3 Trace / 诊断事件

- MUST 接收并传播上游 trace context，不得无故丢失 requestId / traceId。
- SHOULD 为外部依赖调用创建 span，并标注 peer、operation、status、errorCode。
- MAY 输出模块内部诊断事件，用于启动分析和运行期排障。
- MUST 在消息 Header 中注入 trace context。
- MUST 在消费端从 Header 恢复 trace context，并创建 consumer span。

## 10. 错误模型与失败策略

| 错误类别 | 典型原因 | 1.0 处理策略 |
| --- | --- | --- |
| KAFKA_PRODUCE_FAILED | broker 不可用、序列化失败、超时 | 按错误类型决定重试或失败 |
| KAFKA_CONSUME_FAILED | handler 执行失败 | 按 HandlerResult 和 retryPolicy 处理 |
| KAFKA_DESERIALIZATION_FAILED | payload 与 schema 不兼容 | 不可重试，进入死信 |
| KAFKA_COMMIT_FAILED | 位点提交失败 | 记录错误并由容器决定重试或再均衡处理 |
| KAFKA_IDEMPOTENT_DUPLICATE | 检测到重复消息 | 跳过并记录幂等命中 |

## 11. 安全、稳定性与兼容性要求

- MUST 对密码、token、accessKey、secretKey、连接串中的敏感片段做脱敏。
- MUST 保证公开 API 的异常不会泄漏内部凭据、主机隐私或完整连接串。
- MUST 为所有网络和外部依赖调用设置超时边界。
- SHOULD 支持最小权限原则，不要求业务使用高权限账号。
- MUST 支持认证和加密配置。
- MUST 避免在日志中输出完整消息 payload。
- MUST 对 Header 中的用户信息做最小化传播。

## 12. 测试证据要求

| 测试类型 | 必须覆盖内容 | 发布门禁 |
| --- | --- | --- |
| 单元测试 | EventEnvelope、Header、错误分类、HandlerResult | MUST 通过 |
| 集成测试 | 真实 Kafka 生产、消费、位点提交、rebalance 基础场景 | MUST 通过 |
| 失败测试 | 序列化失败、broker 不可用、handler 失败、死信 | MUST 通过 |
| 幂等测试 | 重复消息、重复 eventId、重复 idempotencyKey | MUST 通过 |
| 契约测试 | 事件 schema 向后兼容、DLQ schema | MUST 通过 |

## 13. 1.0 发布验收清单

- 事件信封统一且具备版本字段。
- 消费失败不会无边界重试。
- 死信消息可被定位到原始 topic、partition、offset、eventId。
- 生产和消费链路可通过 traceId 串联。

## 14. Definition of Done

- 公开 API、配置项、错误码、指标名完成冻结并记录兼容性说明。
- README、快速开始、配置参考、错误码参考、测试说明完成。
- MUST 能力均有自动化测试，CI 可重复执行。
- 示例工程或最小可运行样例通过。
- 发布包不包含测试密钥、临时文件、个人环境路径。

## 15. 1.0 后演进方向

- 支持事务性 outbox 模式组件。
- 支持延迟重试 Topic 管理增强。
- 支持 schema registry 深度适配。
