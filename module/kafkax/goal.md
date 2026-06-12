# kafkax 1.0 Goal 与规格基线

| 字段 | 内容 |
| --- | --- |
| 模块名 | `kafkax` |
| 目标版本 | 1.0.0 baseline candidate |
| 所属层级 | 基座 · 存储扩展 / Kafka 客户端封装 |
| 稳定级别 | Candidate；Public API / SPI 需经四源评分与 arbiter 后冻结 |
| 文档状态 | Draft；本文件与 `SPEC.md`、`TRACEABILITY.md` 已对齐，尚未伪造 Approved |
| 发布日期基准 | 2026-06-12 |

## 术语约定

本文档中的 **MUST / 必须** 表示 1.0 发布阻断项；**SHOULD / 应该** 表示 1.0 推荐项，允许带明确理由延期；**MAY / 可以** 表示可选能力，不影响 1.0 发布。

## 1.0 发布判定原则

1. **稳定优先**：公开 API、配置项、错误码、指标名进入 1.0 后默认保持向后兼容。
2. **边界清晰**：`kafkax` 只提供 Kafka 客户端接入能力，不定义业务事件语义，不替代 Kafka 集群治理。
3. **证据完整**：每个 MUST 能力必须有单元测试、集成测试或契约测试证明。
4. **可观测**：生产、消费、提交、健康检查和错误路径必须输出最小可诊断日志与指标。
5. **可演进**：1.0 允许保留扩展点，但不得把未落地能力包装成稳定承诺。

## 1. Goal 定位

`kafkax` 的 1.0 Goal 是提供现实可交付的 Kafka 客户端封装基线：统一 `Producer`、`Consumer`、`Message`、`Codec`、配置、错误、健康检查、重试、DLQ 边界和可观测集成。它支撑应用以一致方式生产、消费、提交 offset 和诊断 Kafka 链路问题，但不隐藏 Kafka 的 topic、partition、consumer group、offset 等核心语义。

### 1.1 为什么需要这个模块

- Kafka 生产和消费若缺乏统一封装，会导致配置、重试、超时和错误处理不一致。
- Consumer offset 提交策略如果不统一，会出现重复消费、消息丢失或不可定位失败。
- 失败消息需要可分类、可重试、可进入 DLQ，并保留足够上下文用于审计。
- 消息链路需要统一指标、日志和 trace context，方便排障与容量评估。

### 1.2 1.0 要解决的问题

- 统一 `Producer`、`Consumer`、`Message`、`Codec` 和 Option 配置模型。
- 统一同步发送、批量发送、订阅、轮询、提交和关闭语义。
- 统一生产重试、消费错误分类、DLQ 发布边界和失败处理策略。
- 统一 `context.Context` 取消/超时、`error` 包装、敏感信息脱敏和错误码。
- 统一 `kafkax.*` 配置命名与 `kafkax_*` 指标命名。

### 1.3 目标用户

- 业务服务开发者
- 平台基础设施开发者
- SRE / 运维人员
- 测试工程师

## 2. 1.0 发布目标

- MUST 提供 `Message` 作为 1.0 消息数据模型，包含 topic、partition、offset、key、value、headers、timestamp。
- MUST 支持同步单条发送、批量发送和明确的发送错误返回；异步 Producer 回调不是 1.0 稳定承诺。
- MUST 支持消费者订阅、轮询、手动 offset 提交和关闭流程。
- MUST 支持生产重试配置、消费失败分类和 DLQ 发布接口边界；DLQ 消息必须保留原始 topic、partition、offset、key、headers、timestamp、errorCode、retryCount 和失败原因摘要。
- MUST 支持 `context.Context` 取消/超时和 `error` 链路，公开错误不得泄漏完整 payload 或敏感配置。
- MUST 支持健康检查、日志、指标和 trace context 传播的最小基线。

## 3. 核心场景

| 场景 | 说明 | 1.0 期望结果 |
| --- | --- | --- |
| 消息发布 | 业务服务向 Kafka topic 发布消息 | 同步返回成功或可诊断错误，生产指标可观测 |
| 批量发布 | 批量写入同一或多个 topic | 有效消息按 Kafka 语义发送，失败返回首个错误且不伪造回滚 |
| 消费处理 | 服务加入消费组并轮询消息 | handler 成功后显式提交 offset，失败按策略处理 |
| 消费失败 | 反序列化失败或业务处理失败 | 不可重试进入 DLQ，可重试按策略重试，失败原因可定位 |
| 链路追踪 | 请求触发 Kafka 消息并被异步消费 | trace context 通过 headers 传播，生产/消费 span 可串联 |

## 4. 能力范围

| 能力域 | 1.0 必须具备的能力 | 验收方式 |
| --- | --- | --- |
| 消息模型 | `Message`、headers、timestamp、offset 元数据 | 单元/契约测试通过 |
| 生产者 | `Send`、`SendBatch`、acks、key 分区、重试、超时 | 单元与集成测试通过 |
| 消费者 | `Subscribe`、`Poll`、`Commit`、手动提交、consumer group | 消费集成测试通过 |
| 失败处理 | 错误分类、重试上限、DLQ 发布边界、poison message 处理 | 失败场景测试通过 |
| 序列化 | `Codec` SPI、JSON 默认实现、可扩展 codec | Codec 测试通过 |
| 治理观测 | 健康检查、日志、生产/消费/提交/错误/重试/DLQ/lag 指标 | 观测测试通过 |

## 5. 职责边界

### 5.1 模块内职责

- 提供 Kafka 标准生产和消费封装。
- 提供 `Message`、headers、序列化和错误契约。
- 提供生产重试、消费失败分类、DLQ 发布边界和手动 offset 提交规则。
- 接入 kernel 生命周期、observex interface-only 观测能力和 configx 输出的配置值。

### 5.2 明确非目标

- 不替代 Kafka 集群管理平台。
- 不替代业务事件语义设计，也不定义业务 `EventEnvelope`。
- 不隐藏分区、key、消费组、位点等核心概念。
- 不默认承诺 exactly-once、Kafka Transactions 或 transactional outbox。
- 不在 1.0 稳定承诺中集成 Schema Registry、Kafka Connect 或跨 topic 原子写入。

## 6. 依赖关系与分层约束

| 依赖类型 | 约束 |
| --- | --- |
| 上游依赖 | 可依赖 stdlib、kernel L0 原语、observex interface-only 和 Kafka 客户端库；配置值由 configx 注入但 kafkax 不依赖配置解析实现。 |
| 下游依赖 | 业务事件流、审计/日志管道、异步集成可使用 kafkax。 |
| 分层约束 | kafkax 不依赖具体业务 schema；业务 payload 的语义与兼容性由业务或 contracts 负责。 |

## 7. 对外契约

### 7.1 公开能力面

| 契约 | 定位 | 1.0 稳定承诺 |
| --- | --- | --- |
| `Producer` | 生产接口 | send/sendBatch 的 context、错误和重试语义稳定 |
| `Consumer` | 消费接口 | subscribe/poll/commit/close 的手动提交语义稳定 |
| `Message` | Kafka 消息模型 | 核心字段稳定，只能追加可选字段 |
| `Codec` | 序列化扩展点 | marshal/unmarshal 语义稳定 |
| `HealthStatus` | 健康状态 | ready/live/message 语义稳定 |
| `DeadLetterPublisher` | DLQ 扩展边界 | DLQ 元数据和错误摘要字段稳定 |

### 7.2 1.0 逻辑接口基线

```text
Message
  topic       — Kafka topic
  partition   — Kafka partition
  offset      — Kafka offset（生产前可为空/零值，消费后必须有效）
  key         — Kafka key
  value       — payload bytes（错误和日志不得输出完整内容）
  headers     — trace context 与扩展元数据
  timestamp   — Kafka 消息时间

Producer
  Send(ctx, topic, key, value) error
  SendBatch(ctx, messages) error
  Close(ctx) error

Consumer
  Subscribe(ctx, topics) error
  Poll(ctx) (*Message, error)
  Commit(ctx, message) error
  Close(ctx) error

Codec
  Marshal(value) ([]byte, error)
  Unmarshal(data, target) error

DeadLetterPublisher
  Publish(ctx, originalMessage, failure) error
```

## 8. 配置与指标命名基线

| 类别 | 命名约定 | 示例 |
| --- | --- | --- |
| 配置 | `kafkax.*` | `kafkax.producer.acks`, `kafkax.consumer.enable_auto_commit` |
| 指标 | `kafkax_*` | `kafkax_produce_total`, `kafkax_consumer_lag` |
| 日志事件 | `kafkax.<event>` | `kafkax.send_failed`, `kafkax.commit_failed` |

## 9. 1.0 发布验收清单

- `Message`、`Producer`、`Consumer`、`Codec`、`HealthStatus` 和 DLQ 边界一致且可测试。
- 所有公开操作接受 `context.Context` 并返回 `error` 或可诊断状态。
- 消费失败不会无边界重试，DLQ 消息可定位原始 topic、partition、offset 和失败原因。
- 生产、消费、提交、健康检查和失败链路具备日志与指标。
- README、快速开始、配置参考、错误码参考、测试说明完成。
- FR-001..FR-006 与 BR-001..BR-009 均有 TRACEABILITY Task 映射。

## 10. 1.0 后演进方向

- 异步 Producer 回调 API。
- 事务性 outbox 或 Kafka Transactions 适配。
- Schema Registry 深度适配。
- 业务事件信封或 contracts MessageEnvelope 适配层。
- 延迟重试 Topic 管理增强。
