# kafkax 1.0 目标定位与规格基线

| 字段 | 内容 |
| --- | --- |
| 模块名 | `kafkax` |
| 目标规格版本 | v1.0.0 |
| 当前实现版本参考 | v0.7.3 |
| 所属层级 | 基座 · 存储扩展 / Kafka 客户端封装 |
| 稳定级别 | Candidate；公开 API 进入 1.0 前仍需仲裁 |
| 文档状态 | Draft / 1.0 候选基线 |
| 发布日期基准 | 2026-06-12 |

## 术语约定

本文档中的 **MUST / 必须** 表示 1.0 候选基线阻断项；**SHOULD / 应该** 表示 1.0 推荐项，允许带明确理由延期；**MAY / 可以** 表示可选能力，不影响 1.0 候选基线。

## 1.0 判定原则

1. **现实基线优先**：1.0 只承诺当前规格和实现可验证的 Kafka 客户端封装能力。
2. **公开契约清晰**：Producer、Consumer、Message、Codec、Health、错误模型、配置和观测命名必须一致。
3. **上下文可控**：所有运行时操作必须接收 `context.Context`，支持超时、取消和错误返回。
4. **证据完整**：每个 MUST 能力都必须能追溯到验收条件、测试用例和交付任务。
5. **可演进**：未稳定能力只能作为非目标或后续候选，不得包装成 1.0 稳定承诺。

## 1. Goal 定位

`kafkax` 的 Goal 是提供 Kafka 的统一客户端接入层，标准化消息生产、消费、序列化、offset 提交、健康检查、错误处理和可观测集成。它支撑业务模块以一致方式使用 Kafka，但不隐藏 topic、partition、consumer group、offset 等核心语义。

### 1.1 为什么需要这个模块

- Producer / Consumer 配置若缺乏统一封装，会导致重试、超时、ack、offset 策略不一致。
- 序列化、错误和健康检查若缺乏统一契约，会增加业务重复实现和排障成本。
- 消费位点提交必须显式、可观测，避免自动提交导致数据丢失。
- Kafka 运行态需要统一 metrics、logging 和 tracing 命名，方便 SRE 排障。

### 1.2 1.0 候选基线要解决的问题

- 提供 `Producer`：`Send`、`SendBatch`、`Close`。
- 提供 `Consumer`：`Subscribe`、`Poll`、`Commit`、`Close`。
- 提供 `Message`、`Codec`、`HealthStatus` 与健康检查接口。
- 统一配置命名空间为 `kafkax.*`。
- 统一错误模型、边界行为和敏感数据脱敏要求。
- 统一 `kafkax.*` 指标、日志事件和 trace 传播要求。

### 1.3 目标用户

- 业务服务开发者
- 平台基础设施开发者
- SRE / 运维人员
- 测试工程师

## 2. 1.0 发布目标

- MUST 支持同步单条生产，并返回可包装的错误。
- MUST 支持批量生产；部分失败时返回第一个错误，已发送消息不回滚。
- MUST 支持消费组订阅、轮询和手动 offset 提交。
- MUST 禁用自动 offset 提交，默认 at-least-once。
- MUST 支持 JSON 默认 Codec，并允许替换 Codec。
- MUST 支持健康检查和 kernel 生命周期集成。
- MUST 输出 `kafkax.*` metrics、日志事件和 trace 关键标签。
- MUST 保证错误和日志不泄露消息 payload、凭据或完整连接串。

## 3. 核心场景

| 场景 | 说明 | 1.0 期望结果 |
| --- | --- | --- |
| 消息发布 | 服务将业务事件序列化后写入 Kafka topic | `Send(ctx, topic, key, value)` 成功或返回明确错误 |
| 批量发布 | 服务批量写入同一或多个 topic | `SendBatch(ctx, msgs)` 完成所有有效消息，部分失败返回第一个错误 |
| 消费处理 | 服务订阅 topic 并处理消息 | `Poll(ctx)` 返回 `Message`，处理成功后显式 `Commit(ctx, msg)` |
| 健康检查 | 应用启动或运行期检查 Kafka 可达性 | `Health(ctx)` 返回 ready/live 状态和错误上下文 |
| 可观测排障 | Kafka 发送、消费、commit 失败 | 输出脱敏日志、错误码、duration 和 `kafkax.*` 指标 |

## 4. 能力范围

| 能力域 | 1.0 必须具备的能力 | 验收方式 |
| --- | --- | --- |
| 生产者 | 同步发送、批量发送、acks、重试、关闭语义 | 单元测试和集成测试 |
| 消费者 | 订阅、轮询、手动提交、重复订阅防护、关闭语义 | 单元测试和集成测试 |
| 消息模型 | `Message` topic、partition、offset、key、value、headers、timestamp | 契约测试 |
| 序列化 | 默认 JSON Codec 和可替换 Codec | Codec 单元测试 |
| 健康检查 | Kafka metadata 可达性映射为 `HealthStatus` | 健康检查测试 |
| 错误模型 | 连接、订阅、消息、发送、提交错误可包装且脱敏 | 错误测试 |
| 可观测 | `kafkax.*` metrics、日志事件和 trace 标签 | 观测契约测试 |

## 5. 职责边界

### 5.1 模块内职责

- 提供 Kafka Producer / Consumer 的 Go 接口和实现。
- 提供 `Message`、`Codec`、`HealthStatus`、Option 配置和公共错误。
- 提供发送、消费、提交、关闭、健康检查的上下文和错误契约。
- 提供可观测集成点，命名空间统一为 `kafkax.*`。

### 5.2 明确非目标 / 后续候选

- 不替代 Kafka 集群管理平台。
- 不替代业务事件语义设计或业务 schema 治理。
- 不隐藏 partition、key、consumer group、offset 等 Kafka 核心概念。
- 不承诺 exactly-once、Kafka transactions 或跨 topic 原子写入。
- 不在 1.0 基线内承诺异步 Producer 回调 API。
- 不在 1.0 基线内承诺 Schema Registry 或 Kafka Connect 集成。
- 不在 1.0 基线内承诺深度死信队列编排；消费失败重试/转储策略留作后续候选。
- 不在 1.0 基线内承诺幂等存储 SPI；业务幂等由调用方自行实现。

## 6. 依赖关系与分层约束

| 依赖类型 | 约束 |
| --- | --- |
| 上游依赖 | 可依赖 stdlib、kernel 生命周期原语、observex interface-only、Kafka 客户端库。 |
| 禁止依赖 | 不依赖业务域模块，不依赖 L2.5 领域共享层，不强依赖 configx。 |
| 下游依赖 | 业务事件流、审计/日志管道、异步集成可使用 kafkax。 |
| 分层约束 | kafkax 不定义业务 schema；payload 由调用方和 Codec 管理。 |

## 7. 对外契约

| 契约 | 定位 | 1.0 候选承诺 |
| --- | --- | --- |
| `Producer` | 生产接口 | `Send`、`SendBatch`、`Close(ctx)` 语义稳定 |
| `Consumer` | 消费接口 | `Subscribe(ctx)`、`Poll`、`Commit`、`Close(ctx)` 语义稳定 |
| `Message` | Kafka 消息模型 | topic、partition、offset、key、value、headers、timestamp 字段稳定 |
| `Codec` | 序列化扩展点 | `Marshal` / `Unmarshal` 语义稳定 |
| `Health(ctx)` | 健康检查 | ready/live/error 映射稳定 |
| 公共错误 | 错误分类 | 可包装、可判定且脱敏 |

## 8. 配置与指标命名基线

| 配置项 | 含义 | 默认值 / 要求 | 稳定性 |
| --- | --- | --- | --- |
| `kafkax.brokers` | Kafka broker 地址列表 | 必须非空 | Candidate |
| `kafkax.producer.acks` | 生产确认级别 | `all` | Candidate |
| `kafkax.producer.retries` | 生产重试次数 | `3` | Candidate |
| `kafkax.producer.batch_size` | 批量大小 | `16384` | Candidate |
| `kafkax.producer.linger_ms` | 批量等待毫秒 | `5` | Candidate |
| `kafkax.producer.max_message_bytes` | 单条消息最大字节数 | `1048576` | Candidate |
| `kafkax.consumer.group_id` | 消费组 ID | Consumer 必须配置 | Candidate |
| `kafkax.consumer.enable_auto_commit` | 是否自动提交 offset | `false`，不可由默认值开启 | Candidate |
| `kafkax.consumer.max_poll_records` | 单次 Poll 最大记录数 | `500` | Candidate |
| `kafkax.consumer.session_timeout` | 会话超时 | `30s` | Candidate |
| `kafkax.consumer.heartbeat_interval` | 心跳间隔 | `10s` | Candidate |
| `kafkax.codec` | 序列化方式 | `json` | Candidate |
| `kafkax.health_check_interval` | 健康检查周期 | `10s` | Candidate |

## 9. 可观测契约

### 9.1 日志

- MUST 输出模块初始化结果、关键配置摘要和失败原因；敏感配置必须脱敏。
- MUST 在关键操作失败时输出 operation、duration、topic、partition、offset、error 和 trace 标识。
- MUST 避免输出完整消息 payload。
- SHOULD 对慢操作输出 warn 级别日志，阈值由配置控制。

### 9.2 指标

| 指标名 | 类型 | 标签 | 说明 |
| --- | --- | --- | --- |
| `kafkax.produce.duration` | histogram | topic,status | 发送耗时 |
| `kafkax.produce.errors` | counter | topic,error | 发送失败次数 |
| `kafkax.produce.batch.size` | histogram | topic | 批量发送消息数 |
| `kafkax.consume.duration` | histogram | topic,group,status | 消费处理耗时 |
| `kafkax.consume.lag` | gauge | topic,group,partition | 消费延迟 |
| `kafkax.consume.messages` | counter | topic,group,status | 消费消息数 |
| `kafkax.consume.errors` | counter | topic,group,error | 消费失败次数 |
| `kafkax.commit.errors` | counter | topic,group,error | offset 提交失败次数 |

### 9.3 Trace / 诊断事件

- MUST 接收并传播上游 trace context。
- SHOULD 为发送、消费和提交创建 span，并标注 topic、partition、offset、status、error。
- MAY 输出模块内部诊断事件，用于启动分析和运行期排障。

## 10. 错误模型与失败策略

| 错误类别 | 典型原因 | 1.0 处理策略 |
| --- | --- | --- |
| `ErrConnectionFailed` | broker 不可用、metadata 请求失败 | 返回错误并记录脱敏日志/指标 |
| `ErrSendFailed` | 序列化失败、broker 写入失败、消息过大 | 返回包装错误；已发送批次不回滚 |
| `ErrEmptyTopics` | 订阅 topic 为空 | `Subscribe(ctx, topics)` 立即返回错误 |
| `ErrAlreadySubscribed` | 重复订阅 | 返回错误，不改变原订阅 |
| `ErrNotSubscribed` | 未订阅即 Poll | 返回错误，不提交 offset |
| `ErrInvalidMessage` | nil 消息、非法 topic 或 offset | 返回错误，不发送或提交 |
| `ErrCommitFailed` | offset 提交失败或 rebalance 冲突 | 返回包装错误，由调用方决定重试 |

## 9. 1.0 发布验收清单

- MUST 对密码、token、accessKey、secretKey、连接串中的敏感片段做脱敏。
- MUST 保证公开 API 的错误不会泄露内部凭据、主机隐私或完整 payload。
- MUST 为所有网络和外部依赖调用设置超时边界。
- MUST 支持认证和加密配置。
- MUST 禁用自动 offset 提交的默认值。
- SHOULD 支持最小权限原则，不要求业务使用高权限账号。

## 12. 测试证据要求

| 测试类型 | 必须覆盖内容 | 发布门禁 |
| --- | --- | --- |
| 单元测试 | Producer、Consumer、Message、Codec、Health、公共错误 | MUST 通过 |
| 集成测试 | 真实 Kafka 发送、消费、提交、rebalance 基础场景 | MUST 通过；Kafka 不可用时可 skip 专属集成门禁 |
| 失败测试 | broker 不可达、空 topic、nil 消息、重复订阅、commit 失败、codec 失败 | MUST 通过 |
| 观测测试 | 指标名、日志脱敏、trace 标签 | MUST 通过 |
| 兼容测试 | 公共接口和配置默认值不发生未声明破坏 | MUST 通过 |

## 13. 1.0 候选发布验收清单

- [ ] `Producer` / `Consumer` / `Message` / `Codec` / `HealthStatus` 有 godoc 和示例。
- [ ] 所有运行时操作接收 `context.Context` 并返回错误。
- [ ] 配置命名空间统一为 `kafkax.*`。
- [ ] 指标命名空间统一为 `kafkax.*`。
- [ ] 错误、日志和 trace 均不泄露 payload 或敏感配置。
- [ ] `TRACEABILITY.md` 覆盖 FR-001..FR-006 和 BR-001..BR-009，并包含 Task 列。
- [ ] `SPEC.md` Open Questions 仅包含非阻断候选或已明确出界事项。

## 14. 后续演进候选

| 候选能力 | 进入条件 |
| --- | --- |
| 异步 Producer 回调 | 明确 API 兼容策略、错误语义和背压行为 |
| 消费失败重试/转储编排 | 明确 topic 命名、payload 脱敏、重试上限和告警策略 |
| 幂等存储 SPI | 明确存储依赖、幂等键来源和一致性边界 |
| Kafka transactions | 明确跨 topic / producer session 事务边界和失败恢复策略 |
| Schema Registry | 明确 schema 兼容策略、依赖方向和迁移路径 |
| 手动 partition assign | 明确与消费组模式的互斥规则和 rebalance 行为 |
