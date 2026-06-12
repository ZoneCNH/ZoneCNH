# kafkax 1.0 Goal 与规格基线

| 字段 | 内容 |
| --- | --- |
| 模块名 | `kafkax` |
| 目标版本 | v1.0.0 规格基线 |
| 所属层级 | 基座 · 存储扩展 / Kafka 客户端封装 |
| 稳定级别 | Public API Candidate；SPI Candidate；Internal 可演进 |
| 文档状态 | Draft（未仲裁；等待四源评分 / arbiter 判定） |
| 发布日期基准 | 2026-06-12 |

## 术语约定

本文档中的 **MUST / 必须** 表示 v1.0 规格基线的发布阻断项；**SHOULD / 应该** 表示 v1.0 推荐项，允许带明确理由延期；**MAY / 可以** 表示可选能力，不影响 v1.0 基线。

## 1.0 基线判定原则

1. **现实可交付**：v1.0 以当前 `kafkax` 客户端封装能力为中心，冻结 Producer、Consumer、Message、Codec、错误、配置和观测语义。
2. **边界清晰**：模块封装 Kafka 生产/消费、序列化、健康检查与可观测接入，不替代业务事件模型、Schema Registry、Kafka 集群管理或 exactly-once 业务事务。
3. **证据完整**：每个 MUST 能力都必须能追溯到验收标准、测试用例和实现任务。
4. **可观测**：生产、消费、提交、健康检查和错误路径必须输出最小可诊断信息，且不得泄露完整 payload 或敏感凭据。
5. **可演进**：v1.0 可以保留扩展点，但不得把未落地能力包装成稳定承诺。

## 1. Goal 定位

`kafkax` 的 Goal 是提供 Kafka 客户端的统一接入层：标准化 Producer、Consumer、Message、Codec、配置、错误处理、健康检查与可观测集成。它支撑业务模块安全地接入 Kafka，同时保留 Kafka 的 topic、partition、offset、consumer group 和 key 等核心语义。

### 1.1 为什么需要这个模块

- 多个业务模块直接使用 Kafka 客户端会导致配置、重试、超时和错误处理不一致。
- 消费组、offset 提交和上下文取消语义需要统一，否则容易出现数据丢失、重复消费或不可诊断的阻塞。
- 序列化、健康检查、metrics、tracing 和 logging 需要与基座治理约定一致。
- 错误消息和日志必须避免泄露 payload、凭据或连接串。

### 1.2 1.0 要解决的问题

- 统一 `Producer.Send`、`Producer.SendBatch`、`Consumer.Subscribe`、`Consumer.Poll`、`Consumer.Commit`、`Close` 和 `Health` 的接口语义。
- 统一 `Message` 结构、Header、Topic/Partition/Offset/Key/Value/Timestamp 字段边界。
- 统一 producer retry、consumer manual commit、context cancel/timeout 和错误包装规则。
- 统一 `kafkax.*` 配置命名与 `kafkax.*` 指标/log 事件命名。
- 明确 DLQ、事务、Schema Registry、业务事件信封、exactly-once 等非目标或未来项。

### 1.3 目标用户

- 业务服务开发者
- 平台基础设施开发者
- SRE / 运维人员
- 测试工程师

## 2. 1.0 发布目标

- MUST 提供标准 `Message` 数据模型，覆盖 topic、partition、offset、key、value、headers 和 timestamp。
- MUST 提供同步 `Send(ctx, topic, key, value)` 与批量 `SendBatch(ctx, msgs)` 生产接口，返回 Go `error` 并保留上下文取消语义。
- MUST 提供 Consumer 订阅、轮询、提交 offset 和关闭接口，默认手动提交以支持 at-least-once。
- MUST 提供可配置 producer retry，默认 3 次；consumer 不自动重试业务 handler，不内置 DLQ。
- MUST 提供 Codec SPI、健康检查、错误模型、配置 schema 和可观测集成。

## 3. 核心场景

| 场景 | 说明 | 1.0 期望结果 |
| --- | --- | --- |
| 单条生产 | 业务模块向 topic 发布一条消息 | `Send(ctx, ...)` 成功返回 nil，失败返回可包装错误 |
| 批量生产 | 业务模块批量发送消息 | 有效消息按顺序发送；部分失败返回第一个错误且不回滚已发送消息 |
| 消费处理 | Consumer 订阅 topic 并轮询消息 | `Poll(ctx)` 返回 `Message`；调用方处理后显式 `Commit(ctx, msg)` |
| 健康检查 | 应用启动或探针检查 Kafka 可达性 | `Health(ctx)` 返回 ready/live 状态和诊断消息 |
| 上下文取消 | 请求超时或应用关闭 | 所有阻塞操作响应 `ctx.Err()` 或关闭错误 |

## 4. 能力范围

| 能力域 | 1.0 必须具备的能力 | 验收方式 |
| --- | --- | --- |
| 生产者 | Send、SendBatch、key 分区、acks、retry、timeout | 单元测试 + 集成测试 |
| 消费者 | Subscribe、Poll、Commit、manual offset、Close | 单元测试 + 集成测试 |
| 数据模型 | Message、Header、Topic/Partition/Offset、Timestamp | 契约测试 |
| 序列化 | Codec SPI，默认 JSON，可扩展 msgpack/protobuf | Codec 单元测试 |
| 错误处理 | 公共错误、错误包装、context cancel、敏感信息保护 | 错误路径测试 |
| 健康检查 | Kafka metadata 可达性转为 ready/live | 健康检查测试 |
| 治理观测 | `kafkax.*` metrics、tracing、logging | 观测契约测试 / CI Gate |

## 5. 职责边界

### 5.1 模块内职责

- 提供 Kafka 标准生产和消费封装。
- 提供 `Message`、Header、Codec、配置和错误契约。
- 提供 producer retry、consumer manual commit、health check 和 observability 接入点。
- 接入 kernel 生命周期，并通过 observex 暴露 interface-only 观测能力。

### 5.2 明确非目标

- 不替代 Kafka 集群管理平台。
- 不替代业务事件语义设计；不定义 `EventEnvelope` 或业务 schema。
- 不隐藏分区、key、消费组、offset 等 Kafka 核心概念。
- 不默认承诺 exactly-once；Kafka transactions 和 outbox 属于未来项。
- 不在 v1.0 内置 Dead Letter Queue；调用方可基于错误分类自行转储，DLQ 作为未来增强。
- 不集成 Schema Registry；Avro/Proto schema 管理由业务或后续模块处理。

## 6. 依赖关系与分层约束

| 依赖类型 | 约束 |
| --- | --- |
| 上游依赖 | 可依赖 stdlib、kernel（L0 原语）、observex interface-only 和 Kafka 客户端库；配置由调用方或 configx 提供。 |
| 下游依赖 | 业务事件流、审计/日志管道、异步集成可使用 kafkax。 |
| 分层约束 | kafkax 不依赖具体业务 schema；不依赖业务域实现；不把事件契约治理内置到客户端封装。 |

## 7. 对外契约

### 7.1 公开能力面

| 契约 | 定位 | 1.0 稳定承诺 |
| --- | --- | --- |
| Producer | 生产接口 | Send / SendBatch 的 context、error 和关闭语义稳定 |
| Consumer | 消费接口 | Subscribe / Poll / Commit / Close 的 lifecycle 和 offset 语义稳定 |
| Message | Kafka 消息数据模型 | 字段含义稳定，只能兼容性追加可选字段 |
| Codec | 序列化扩展点 | Marshal / Unmarshal 语义稳定 |
| HealthStatus | 健康检查结果 | Ready / Live / Message 语义稳定 |
| Option | 配置扩展点 | 新增 option 必须有默认值且向后兼容 |

### 7.2 1.0 逻辑接口基线

```text
Producer
  Send(ctx, topic, key, value): error
  SendBatch(ctx, messages): error
  Close(ctx): error

Consumer
  Subscribe(ctx, topics): error
  Poll(ctx): Message | error
  Commit(ctx, message): error
  Close(ctx): error

HealthChecker
  Health(ctx): HealthStatus | error

Message
  topic, partition, offset, key, value, headers, timestamp

Codec
  Marshal(value): bytes | error
  Unmarshal(bytes, target): error
```

## 8. 配置与指标命名基线

| 配置项 | 含义 | 默认值 / 要求 | 稳定性 |
| --- | --- | --- | --- |
| kafkax.brokers | Kafka 地址列表 | 必须配置至少一个 broker | Candidate |
| kafkax.producer.acks | 生产确认级别 | all | Candidate |
| kafkax.producer.retries | 生产重试次数 | 3 | Candidate |
| kafkax.producer.batch_size | 批量大小 | 16384 | Candidate |
| kafkax.producer.linger_ms | 批量等待时间 | 5 | Candidate |
| kafkax.producer.max_message_bytes | 单条消息最大字节数 | 1048576 | Candidate |
| kafkax.consumer.group_id | 消费组 | Consumer 必须配置 | Candidate |
| kafkax.consumer.auto_offset_reset | 无 offset 时起始位置 | earliest | Candidate |
| kafkax.consumer.enable_auto_commit | 是否自动提交 | false；v1.0 不允许默认 true | Candidate |
| kafkax.consumer.max_poll_records | 单次 Poll 最大记录数 | 500 | Candidate |
| kafkax.codec | 序列化方式 | json | Candidate |
| kafkax.health_check_interval | 健康检查周期 | 10s | Candidate |

## 9. 可观测契约

### 9.1 日志

- MUST 输出模块初始化结果、关键配置摘要和失败原因；敏感配置必须脱敏。
- MUST 在关键操作失败时输出 errorCode、operation、durationMs、topic、partition、offset 和 traceId（如可用）。
- MUST NOT 输出完整 message value / payload。
- SHOULD 对慢操作输出 warn 级别日志，阈值由配置控制。

### 9.2 指标

| 指标名 | 类型 | 标签 | 说明 |
| --- | --- | --- | --- |
| kafkax.produce.duration | Histogram | topic,status | 生产耗时 |
| kafkax.produce.errors | Counter | topic,error | 生产失败次数 |
| kafkax.produce.batch.size | Histogram | topic | 批量发送消息数 |
| kafkax.consume.duration | Histogram | topic,group,status | 消费耗时 |
| kafkax.consume.messages | Counter | topic,group,status | 消费消息数 |
| kafkax.consume.errors | Counter | topic,group,error | 消费失败次数 |
| kafkax.consume.lag | Gauge | topic,group,partition | 消费积压 |

### 9.3 Trace / 诊断事件

- MUST 接收并传播调用方传入的 `context.Context`，不得无故丢失 trace 信息。
- SHOULD 为 Kafka 生产、消费和 commit 创建 span，并标注 topic、partition、operation、status、errorCode。
- MAY 输出模块内部诊断事件，用于启动分析和运行期排障。

## 10. 错误模型与失败策略

| 错误类别 | 典型原因 | 1.0 处理策略 |
| --- | --- | --- |
| ErrConnectionFailed | broker 不可用、metadata 请求失败 | 返回错误；调用方或健康检查决定降级 |
| ErrSendFailed | 序列化失败、超时、broker 写入失败 | producer 按配置重试；最终失败返回 wrapped error |
| ErrInvalidMessage | nil message、空 topic、非法 offset、value nil | 立即返回，不重试 |
| ErrEmptyTopics | Subscribe topics 为空 | 立即返回，不订阅 |
| ErrAlreadySubscribed | 重复订阅 | 返回错误，保持已有订阅 |
| ErrNotSubscribed | Poll 前未订阅 | 返回错误，不阻塞 |
| ErrCommitFailed | offset 提交失败 | 返回错误；调用方决定重试或终止消费循环 |
| context.Canceled / DeadlineExceeded | ctx 取消或超时 | 保留 `ctx.Err()` 语义并停止当前阻塞操作 |

## 9. 1.0 发布验收清单

- MUST 对密码、token、accessKey、secretKey、连接串中的敏感片段做脱敏。
- MUST 保证公开 API 的错误不会泄漏内部凭据、主机隐私或完整连接串。
- MUST 为网络和外部依赖调用设置超时边界或接受调用方 `context.Context` 控制。
- SHOULD 支持最小权限原则，不要求业务使用高权限账号。
- MUST 支持认证和加密配置的透传。
- MUST 避免在日志、错误和 metrics label 中输出完整消息 payload。
- MUST 对 Header 中的用户信息做最小化传播。

## 12. 测试证据要求

| 测试类型 | 必须覆盖内容 | 发布门禁 |
| --- | --- | --- |
| 单元测试 | Message、Header、错误分类、Codec、Option 默认值 | MUST 通过 |
| 集成测试 | 真实 Kafka 生产、消费、offset commit、rebalance 基础场景 | MUST 通过；Kafka 不可达时按集成测试约定 skip |
| 失败测试 | broker 不可用、Send 失败、Poll 取消、Commit 失败、非法消息 | MUST 通过 |
| 并发测试 | Producer / Consumer Close 与并发调用边界 | SHOULD 通过 race 检查 |
| 契约测试 | `kafkax.*` 配置、metrics/log 命名、敏感信息脱敏 | MUST 通过 |

## 13. 1.0 发布验收清单

- Producer / Consumer / Message / Codec / HealthStatus 公共 API 冻结并具备 godoc。
- 所有阻塞或外部依赖操作接受 `context.Context` 并返回 `error`。
- Consumer 默认 manual commit；不会自动提交 offset。
- Producer retry 有默认值和配置项；失败后返回可诊断错误。
- 健康检查、日志、metrics、trace 至少覆盖核心路径。
- TRACEABILITY 覆盖 FR-001..FR-006 与 BR-001..BR-009，并具备 Task 列。

## 14. Definition of Done

- 公开 API、配置项、错误码、指标名完成冻结并记录兼容性说明。
- README、快速开始、配置参考、错误码参考、测试说明完成。
- FR-001..FR-006 与 BR-001..BR-009 均有 TRACEABILITY Task 映射。

## 10. 1.0 后演进方向

- 异步 Producer 回调接口。
- Dead Letter Queue / retry topic 编排。
- Kafka transactions / outbox 模式组件。
- Schema Registry 深度适配。
- 业务事件信封 / EventEnvelope 与 contracts 模块联动。
