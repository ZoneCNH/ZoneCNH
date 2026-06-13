# kafkax 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-13
Source: module/kafkax/SPEC.md（1.0 候选规格） + `kafkax@05cd018ebfa5c853f35efe920cc9dde8134c49b7` 实现证据
Evidence-Anchor: `05cd018ebfa5c853f35efe920cc9dde8134c49b7`
Gate-Evidence: `go test ./...`、真实 broker `kafka-integration` / `kafka-fault-injection` / `kafka-metrics-golden` / `kafka-admin-golden`、`traceability-check`、`boundary`、`kafka-contract`、`score --min 9.8` = 10/10、`make integration`、`make release-check`
Release-Boundary: 真实 broker fixture 外置并脱敏；PR 合入和 tag 前不宣称正式发布。

| Requirement | Description | Acceptance Criteria | Test Case | Task | Status |
| ----------- | ----------- | ------------------- | --------- | ---- | ------ |
| FR-001 | Producer.Send | 可用时发送成功；Kafka 不可用或 value nil 时返回错误 | TC-001, TC-004 | KAFKAX-T01 Producer send contract | ✅ |
| FR-002 | Producer.SendBatch | 有效批次全部发送；部分失败返回第一个错误；空列表返回 nil | TC-002, TC-004 | KAFKAX-T02 Batch send contract | ✅ |
| FR-003 | Consumer.Subscribe | 正常连接加入消费组；空 topics 或重复订阅返回错误 | TC-001, TC-006 | KAFKAX-T03 Subscribe contract | ✅ |
| FR-004 | Consumer.Poll | 有消息返回消息；无消息阻塞至新消息或 ctx 超时；ctx 取消返回 ctx.Err() | TC-001, TC-007 | KAFKAX-T04 Poll contract | ✅ |
| FR-005 | Consumer.Commit | 有效消息提交 offset；nil 或非法 offset 返回错误 | TC-003, TC-008 | KAFKAX-T05 Commit contract | ✅ |
| FR-006 | Health | Kafka metadata 成功返回 ready/live；不可达返回 unhealthy 和错误上下文 | TC-005 | KAFKAX-T06 Health contract | ✅ |
| BR-001 | Producer 默认同步发送且 acks=all | 默认配置必须是同步确认；非法 acks 在构造或发送前返回错误 | TC-001, TC-009 | KAFKAX-T07 Producer defaults | ✅ |
| BR-002 | Consumer 默认手动 offset 提交 | 默认禁用自动提交；成功处理后由调用方显式 Commit | TC-003, TC-010 | KAFKAX-T08 Manual commit defaults | ✅ |
| BR-003 | 所有运行时操作接受 context.Context | Send、SendBatch、Subscribe、Poll、Commit、Close、Health 均支持取消/超时 | TC-007, TC-011 | KAFKAX-T09 Context propagation | ✅ |
| BR-004 | Consumer Close 时处理最终 offset 边界 | Close(ctx) 尝试完成已确认的提交/释放；失败返回错误且不吞错 | TC-008, TC-012 | KAFKAX-T10 Close semantics | ✅ |
| BR-005 | Producer 重试策略可配置且默认 3 次 | retries 默认 3；负值配置被拒绝；最终失败返回包装错误 | TC-004, TC-009 | KAFKAX-T11 Retry config | ✅ |
| BR-006 | Consumer 轮询间隔和批量参数可配置 | max_poll_records、session_timeout、heartbeat_interval 合法性校验 | TC-006, TC-009 | KAFKAX-T12 Consumer config validation | ✅ |
| BR-007 | Health() 幂等且无副作用 | 多次调用不改变订阅、offset、连接生命周期；错误可重复观察 | TC-005 | KAFKAX-T13 Health idempotency | ✅ |
| BR-008 | 错误消息不包含消息内容 | 错误和日志不得输出 value/payload 或敏感配置 | TC-013 | KAFKAX-T14 Sanitized errors | ✅ |
| BR-009 | Consumer 不自动提交 offset | enable_auto_commit 默认 false；自动提交配置不得覆盖默认安全语义 | TC-003, TC-010 | KAFKAX-T15 No auto commit | ✅ |

## Task Catalog

| Task | Scope | Evidence |
| ---- | ----- | -------- |
| KAFKAX-T01 | Producer.Send API、错误包装、nil value 校验 | unit + `kafka-integration` |
| KAFKAX-T02 | Producer.SendBatch 空批次、部分失败、批量成功 | unit + `kafka-integration` |
| KAFKAX-T03 | Consumer.Subscribe topic 校验和重复订阅 | unit + `kafka-contract` |
| KAFKAX-T04 | Consumer.Poll 阻塞、ctx 取消和消息返回 | unit + `kafka-integration` |
| KAFKAX-T05 | Consumer.Commit 有效/无效消息和 offset | unit + `kafka-integration` |
| KAFKAX-T06 | Health metadata 成功/失败映射 | unit + `kafka-admin-golden` |
| KAFKAX-T07 | Producer 默认值和 acks 校验 | unit + `kafka-contract` |
| KAFKAX-T08 | 手动提交默认行为 | unit + `kafka-integration` |
| KAFKAX-T09 | context 传播、取消和超时 | unit + `kafka-fault-injection` |
| KAFKAX-T10 | Close(ctx) 提交/释放/重复关闭语义 | unit + `kafka-fault-injection` |
| KAFKAX-T11 | Producer retries 配置和失败语义 | unit + `kafka-fault-injection` |
| KAFKAX-T12 | Consumer 配置合法性 | unit + `kafka-contract` |
| KAFKAX-T13 | Health 幂等性 | unit + `kafka-admin-golden` |
| KAFKAX-T14 | 错误和日志脱敏 | unit + `kafka-metrics-golden` + `release-check` secret scan |
| KAFKAX-T15 | 禁用自动提交默认值 | unit + `kafka-contract` + `kafka-integration` |
