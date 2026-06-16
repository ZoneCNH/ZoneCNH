# market-data 规格

- Status: Approved
- Spec-Version: v0.1.0
- Last-Updated: 2026-06-17
- Owner: ZoneCNH
- Layer: 数据域 · 行情接收与分发
- Module-Version: v0.1.0
- Related: CONITUTION.md, ARCHITECTURE.md, module/domain-market, module/contracts, module/binance

> 本文件发布 downstream dispatch port / receiving-side SPEC 的文档基线，不引入运行时代码、依赖或 wire schema。`market-data` 的运行时实现为 Pending，等待 `module/domain-market` 与 `module/contracts` 的对应契约在 runtime 稳定后再落地。

---

## 1. 摘要

`market-data` 是交易所行情 adapter 与内部行情消费链路之间的接收侧模块。它接收 adapter 已归一化的市场事件，执行接收侧校验、幂等判定、排序键约束和分发结果表达，并向上游 adapter 返回可审计的 dispatch outcome。

`module/binance` 在采集 Binance 原始数据后，不直接写入存储、队列或策略入口；它必须通过本规格定义的 downstream dispatch port 将归一化事件交给 `market-data` 接收侧。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | downstream dispatch port 语义、接收侧校验、幂等键约束、排序键约束、ack/reject/failure 分类、分发可观测性要求 |
| Depends on | `module/domain-market` canonical market event 语义；`module/contracts` wire / service contract |
| Consumed by | `module/binance` 与其他交易所 adapter |
| Excludes | 交易所 HTTP/WS adapter、provider DTO、protobuf/gRPC/REST schema、Kafka/NATS/DB 实现、策略/回测/执行逻辑 |

## 3. 术语

| 术语 | 定义 |
| --- | --- |
| AcceptedMarketEvent | adapter 已完成来源归一化、时间标注与基础合法性检查后交给 `market-data` 的事件载荷。必须引用 `domain-market` canonical `MarketFactEnvelope` 语义，不携带交易所原始 DTO。 |
| DownstreamDispatchPort | adapter 调用 `market-data` 接收侧的抽象端口；用于提交单条或批量事件并获取接收结果。 |
| DispatchAck | 接收侧确认事件已被接受，可由后续持久化/队列/消费链路处理。 |
| DispatchReject | 接收侧拒绝事件；为不可重试的契约、质量或幂等冲突问题。 |
| DispatchFailure | 接收侧暂时无法完成接收；调用方可按 retry policy 重试。 |
| IdempotencyKey | 同一 venue、product line、instrument、channel、event time、source sequence 与 payload fingerprint 组合出的稳定去重键。 |
| OrderingKey | 保证同一 venue + product line + instrument + channel 内事件顺序约束的分区键。 |

## 4. downstream dispatch port 契约

### 4.1 端口语义

`DownstreamDispatchPort` 是文档级端口名称。后续实现可用本语义映射为进程内接口、消息总线生产者或 RPC client，但不得改变以下语义：

```text
Dispatch(ctx, AcceptedMarketEvent) -> DispatchOutcome
DispatchBatch(ctx, []AcceptedMarketEvent) -> []DispatchOutcome
```

### 4.2 输入字段要求

| 字段 | 必填 | 说明 |
| --- | --- | --- |
| venue | 是 | 交易所或来源场所，如 Binance；取值归属由上游 contract 冻结 |
| productLine | 是 | canonical 产品线：spot、um_perp、cm_perp、option |
| instrumentKey | 是 | canonical instrument 标识；不得直接使用未归一化 symbol 作为唯一键 |
| channel | 是 | trade、kline、bookTicker、depth、funding 等来源通道 |
| eventTime | 是 | 交易所事件时间；缺失或晚于 receivedAt 超出容忍窗口时拒绝 |
| receivedAt | 是 | adapter 接收时间；用于延迟、stale 与 future gate |
| sourceSequence | 条件必填 | 通道存在 sequence/update id 时必须提供 |
| payload | 是 | 引用 domain-market canonical MarketFactEnvelope 语义的载荷，不允许原始 Binance DTO |
| quality | 是 | 来源质量、延迟、可靠性与降级原因 |
| idempotencyKey | 是 | 稳定去重键；重复提交必须产生可审计 outcome |
| orderingKey | 是 | 同一排序域内事件必须可串行化处理 |
| schemaVersion | 是 | 契约 schema 版本 |

### 4.3 输出结果

| Outcome | 可重试 | 语义 |
| --- | --- | --- |
| DispatchAck | 否 | 事件被接收侧接受；重复提交同一 idempotencyKey 可返回幂等 ack |
| DispatchReject | 否 | 事件违反契约、质量门禁、幂等冲突或排序不可恢复；adapter 不得无限重试 |
| DispatchFailure | 是 | 接收侧内部暂时不可用、背压或下游依赖不可用；adapter 可按退避策略重试 |

### 4.4 拒绝原因分类

| Reject Reason | 触发条件 | Retryable |
| --- | --- | --- |
| contract_violation | 缺少必填字段、枚举不在 canonical contract、payload 类型不匹配 | 否 |
| quality_gate | eventTime stale/future/invalid、quality 不达标 | 否 |
| idempotency_conflict | 同一 idempotencyKey 但 payload 不匹配 | 否 |
| ordering_violation | sequence 倒退/跳跃、orderingKey 内顺序破坏 | 否 |
| backpressure | 接收侧背压、下游不可用 | 是 |
| internal_error | 接收侧内部错误 | 是 |

## 5. 非目标

- 不实现 transport adapter（HTTP、WebSocket、Kafka producer/consumer）
- 不定义 proto/gRPC schema（由 module/contracts 拥有）
- 不拥有 storage engine
- 不暴露 query API
- 不实现策略、因子或回测逻辑

## 6. 消费者

| 消费者 | 使用方式 |
| --- | --- |
| `module/binance` server | 通过 DownstreamDispatchPort 提交已校验、去重后的 Binance 行情事件 |
| 其他 exchange adapter | 同 Binance，通过同一 dispatch port 提交归一化事件 |
| 下游持久化/队列链路 | 消费 dispatch ack 后的事件进行持久化或转发 |

## 7. 功能需求

| ID | 需求 | WHEN | THEN |
| --- | --- | --- | --- |
| FR-MD-001 | dispatch-port | Binance adapter 完成事件归一化后提交事件 | 必须调用 downstream dispatch port，不得绕过 market-data 直写存储、队列或策略入口 |
| FR-MD-002 | canonical-input | 接收侧接收 AcceptedMarketEvent | 输入必须引用 domain-market canonical MarketFactEnvelope、ProductLine 与 InstrumentKey 语义，不泄漏 Binance 原始 DTO |
| FR-MD-003 | idempotency | 同一 idempotencyKey 的重复提交 | 必须产生确定 outcome（幂等 ack 或 conflict reject） |
| FR-MD-004 | ordering | 同一 orderingKey 下的序列 | 必须检测 sequence 倒退、跳跃和重复 |
| FR-MD-005 | quality-gate | eventTime、receivedAt 或 quality 不合法 | fail-closed，返回 DispatchReject 并含具体 reject reason |
| FR-MD-006 | retry-classification | 接收侧处理失败 | 必须区分不可重试 reject 与可重试 failure |
| FR-MD-007 | batch-semantics | 批量提交事件 | 必须逐条返回 outcome，不因单条失败丢弃整批 |
| FR-MD-008 | observability | 任一 dispatch 调用完成 | 必须可按 venue/productLine/channel/outcome/reason 统计 |

## 8. 业务规则

| ID | 规则 | 验证方式 |
| --- | --- | --- |
| BR-MD-001 | adapter 不得绕过 dispatch port 直写下游存储/队列/策略入口 | CI import check + code review |
| BR-MD-002 | dispatch 输入载荷必须是 domain-market MarketFactEnvelope，禁止 Binance 原始 DTO | CI type/lint check |
| BR-MD-003 | dispatch port 不定义 vendor DTO 或 wire schema | spec lint |
| BR-MD-004 | stale/future/dirty 数据必须 fail-closed，不在无 quality 标签下静默通过 | 测试用例 |
| BR-MD-005 | adapter 不得将 DispatchFailure 当作成功；必须按 retry policy 或上游 backpressure 处理 | 测试用例 |
| BR-MD-006 | 本次任务只更新 markdown 文档，无运行时代码或依赖 | 文件变更审计 |

## 9. 接口契约

DownstreamDispatchPort 语义如上 §4，暂无 Go interface 定义（runtime pending）。

## 10. 数据模型

无运行时数据模型；AcceptedMarketEvent 引用 domain-market MarketFactEnvelope。

## 11. 配置模式

无运行时配置；后续实现阶段定义 dispatch 超时、重试策略、背压阈值。

## 12. 错误处理

见 §4.4 拒绝原因分类。

## 13. 边界情况

- 批量提交中部分成功部分失败：逐条返回 outcome
- 同一 idempotencyKey 不同 payload：reject（idempotency_conflict）
- 跨 session 去重：依赖 idempotency store TTL
- backpressure 时的降级策略：DispatchFailure + retry policy

## 14. 目录结构

```text
module/market-data/
  SPEC.md
  goal.md
  TRACEABILITY.md
  IMPLEMENTATION-PLAN.md
  tasks/
```

## 15. 依赖

- 允许：module/domain-market canonical 类型
- 允许：module/contracts wire contract 类型
- 允许：kernel（基础 errors）
- 禁止：exchange adapter 内部实现
- 禁止：storage/query/strategy 模块
- 禁止：vendor DTO

## 16. 测试

- 文档基线阶段：TRACEABILITY.md 引用检查、边界扫描
- 后续实现阶段：幂等测试、排序测试、quality gate 测试、batch semantics 测试、contract tests

## 17. 性能预算

- 单条 Dispatch: < 100us（不含 I/O）
- 批量 Dispatch(100): < 1ms（不含 I/O）
- 后续实现阶段细化

## 18. 可观测性

- Metrics: dispatch_total, dispatch_errors, dispatch_latency
- 维度: venue, productLine, channel, outcome, reason
- 后续实现阶段定义具体 metric 名称和类型

## 19. 安全

- 不读取密钥
- 不连接远程服务
- Fail-closed 默认策略

## 20. CI 门禁

- spec-lint.sh 通过
- traceability-check.sh 通过
- 文档引用完整性检查

## 21. 升级兼容性

- DownstreamDispatchPort 语义 v1.x 稳定
- 新增 reject reason 为追加，不删除已有 reason
- 新增必填字段为 breaking change

## 22. 发布 DoD

- [ ] SPEC Approved
- [ ] TRACEABILITY.md 完成且全链路闭合
- [ ] Adapter Gate: module/binance SPEC 引用本 dispatch port
- [ ] 所有 AC 达到 Baseline Published
- [ ] 无运行时代码引入

## 23. 待解决问题

- DownstreamDispatchPort 的最终实现形态（进程内接口 / 消息生产者 / RPC client）？
- idempotency store 的 backing storage 选型？
- 是否需要支持事件重放（replay）？

---

## Appendix A: 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-06-17 | v0.1.0 | 初始 docs baseline：DownstreamDispatchPort、AcceptedMarketEvent、FR-MD-001~008 | ZoneCNH |
