# observex 发布版本 1.0 Goal 定位与实现标准

| 字段         | 内容                                           |
| ------------ | ---------------------------------------------- |
| 模块名       | `observex`                                     |
| 发布版本     | 1.0.0                                          |
| 所属层级     | L1 运行时横切能力 / 可观测性                   |
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

`observex` 的 Goal 是为 xlib 和业务系统提供统一可观测能力，使日志、指标、链路追踪、审计事件和诊断事件具备一致的数据模型、字段规范、上下文传播和扩展方式。它不绑定单一观测平台，而是提供稳定抽象和标准适配点。

### 1.1 为什么需要这个模块

- 没有统一观测模型，故障排查会依赖各模块私有日志和字段。
- 存储、消息、调度、弹性治理等模块必须输出统一指标，否则无法建立横向 SLO。
- Trace 上下文必须贯穿配置、缓存、数据库、消息和任务，否则跨模块定位困难。
- 审计事件和诊断事件需要区分，避免把安全审计混入普通业务日志。

### 1.2 1.0 要解决的问题

- 统一结构化日志字段。
- 统一指标命名、类型和标签。
- 统一 Trace/Baggage 上下文传播。
- 统一审计事件与诊断事件模型。
- 为第三方观测平台提供适配 SPI。

### 1.3 目标用户

- 业务服务开发者
- 平台基础设施开发者
- SRE / 运维人员
- 测试工程师

## 2. 1.0 发布目标

- MUST 提供 Logger、Meter（SPEC.md 用名，本文档部分位置记为 MetricRegistry）、Tracer、Exporter、Health 五类基础抽象（1.0 范围）；AuditPublisher、DiagnosticEventPublisher、ObservationAdapter SPI 推迟到 v1.1。
- MUST 定义标准字段：traceId、spanId、requestId、tenantId、module、operation、errorCode、durationMs。
- MUST 支持无观测后端时的 Noop 实现，保证业务不因观测系统缺失而不可启动。
- MUST 支持上下文传播和跨线程/异步场景的上下文绑定。
- MUST 为所有 xlib 模块提供观测接入指南。

## 3. 核心场景

| 场景         | 说明                                            | 1.0 期望结果                               |
| ------------ | ----------------------------------------------- | ------------------------------------------ |
| 请求排障     | 用户请求经过缓存、数据库、消息发送              | 通过 traceId 串联全部模块调用              |
| 性能分析     | 线上出现慢查询或慢消费                          | 通过 duration 指标和慢操作日志定位瓶颈     |
| 容量观测     | Kafka 积压、Redis 慢操作、PostgreSQL 连接池紧张 | 统一指标可被监控系统采集和告警             |
| 安全审计     | 配置变更、对象存储签名 URL 创建                 | 审计事件独立输出并保留必要字段             |
| 观测后端降级 | 生产环境 Jaeger/OTLP Collector 临时不可达       | 业务不中断，Trace 数据降级到本地缓冲或丢弃 |

## 4. 能力范围

| 能力域     | 要求                                               | 验收方式                                               |
| ---------- | -------------------------------------------------- | ------------------------------------------------------ |
| 结构化日志 | 标准字段、日志等级、脱敏、错误上下文               | 日志字段快照测试通过                                   |
| 指标       | Counter、Gauge、Timer、Histogram、标签约束         | 指标注册和采集测试通过                                 |
| 链路追踪   | span 创建、上下文传播、异步上下文恢复              | 跨线程 Trace 测试通过                                  |
| 审计事件   | actor、action、resource、result、reason、timestamp | v1.1 规划（非 1.0）；schema 测试                       |
| 诊断事件   | 模块启动、配置刷新、熔断打开、任务失败等事件       | v1.1 规划（非 1.0）；事件枚举测试                      |
| 后端适配   | Noop、Console、平台适配 SPI                        | 无后端降级测试通过；ObservationAdapter SPI 推迟到 v1.1 |
| 采样与限流 | 日志采样、Trace 采样、事件限流                     | 高压测试通过                                           |

## 5. 职责边界

### 5.1 模块内职责

- 提供可观测抽象和标准字段。
- 提供默认 Noop/Console 实现和后端适配 SPI。
- 提供上下文传播工具。
- 定义 xlib 模块观测接入规范。

### 5.2 明确非目标

- 不替代 Prometheus、Grafana、ELK、Jaeger、OpenTelemetry Collector 等平台。
- 不强制单一日志框架或指标后端。
- 不负责业务指标口径设计，只提供承载规范。
- 不在 kernel 中创建强依赖。
- **Audit / Diagnostic / ObservationAdapter SPI 推迟到 v1.1**：1.0 聚焦 Logger/Meter/Tracer/Exporter/Health 五类基础抽象，审计事件、诊断事件和平台适配 SPI 作为 1.0 后演进方向（见 §15）。

## 6. 依赖关系与分层约束

| 依赖类型 | 约束                                                                                          |
| -------- | --------------------------------------------------------------------------------------------- |
| 上游依赖 | 依赖 kernel。observex 通过自身 Config 结构体（SPEC §11）管理观测配置，不依赖 configx 运行时。 |
| 下游依赖 | 所有运行时模块应该接入 observex。                                                             |
| 分层约束 | observex 不得依赖 redisx、kafkax 等具体扩展；具体 exporter 通过 adapter/SPI 引入。            |
| 契约依赖 | MUST 向 contracts 登记 Public API 契约和错误码契约。                                          |

## 7. 对外契约

### 7.1 公开能力面

| 契约                                  | 定位                      | 1.0 稳定承诺                                                                   |
| ------------------------------------- | ------------------------- | ------------------------------------------------------------------------------ |
| XLogger                               | 结构化日志入口            | 字段语义稳定                                                                   |
| MetricRegistry（SPEC.md 用名: Meter） | 指标注册和记录入口        | 指标类型稳定                                                                   |
| Tracer                                | span 生命周期和上下文传播 | Trace 语义稳定                                                                 |
| AuditEvent                            | 审计事件模型              | v1.1 规划（非 1.0）                                                            |
| DiagnosticEvent                       | 诊断事件模型              | v1.1 规划（非 1.0）                                                            |
| HealthIndicator                       | 健康检查抽象              | 状态字段稳定；各扩展模块（redisx、kafkax、postgresx 等）实现此接口上报组件健康 |
| ObservationAdapter SPI                | 后端适配扩展点            | v1.1 规划（非 1.0）                                                            |

### 7.2 1.0 逻辑接口基线

> 接口权威定义见 [SPEC.md §9](./SPEC.md#9-interface-contract)。若与本文档其他部分冲突，以 SPEC.md 为准。

```text
Logger
  Debug(msg, fields)
  Info(msg, fields)
  Warn(msg, fields)
  Error(msg, fields)
  With(fields) Logger
  Named(name) Logger

Meter
  Counter(name) Counter
  Histogram(name) Histogram
  Gauge(name) Gauge

Counter.Add(ctx, value, attrs)
Histogram.Record(ctx, value, attrs)
Gauge.Set(ctx, value, attrs)

Tracer
  Start(ctx, name, opts): (ctx, Span)

Span
  End()
  SetAttributes(attrs)
  RecordError(err)
  SpanID(): string
  TraceID(): string

Exporter
  ExportLogs(ctx, entries) error
  ExportMetrics(ctx, metrics) error
  ExportSpans(ctx, spans) error
  Shutdown(ctx) error

Health
  JSON(): []byte  // 符合 SPEC FR-007 health JSON schema

// --- v1.1 规划（非 1.0 范围）---
// AuditPublisher.publish(AuditEvent)
// DiagnosticPublisher.publish(DiagnosticEvent)
// ObservationAdapter SPI
```

## 8. 配置契约

| 配置项                                | 含义             | 默认值 / 要求               | 稳定性 |
| ------------------------------------- | ---------------- | --------------------------- | ------ |
| foundationx.observe.enabled           | 是否启用观测     | true                        | Stable |
| foundationx.observe.backend           | 观测后端         | noop                        | Stable |
| foundationx.observe.log.level         | 默认日志级别     | info                        | Stable |
| foundationx.observe.trace.sample-rate | Trace 采样率     | 1.0 for dev；生产由配置决定 | Stable |
| foundationx.observe.metric.prefix     | 指标前缀         | xlib                        | Stable |
| foundationx.observe.slow-threshold    | 慢操作阈值       | 按模块默认                  | Stable |
| foundationx.observe.audit.enabled     | 是否启用审计事件 | true                        | Stable |

## 9. 可观测契约

### 9.1 日志

- MUST 输出结构化日志，不允许只输出拼接字符串作为关键运行日志。
- MUST 包含 module、operation、status、durationMs、traceId/requestId。
- MUST 对敏感字段统一脱敏。
- SHOULD 对高频错误支持采样，避免日志风暴。

### 9.2 指标

| 指标名                                   | 类型    | 标签                    | 说明                     |
| ---------------------------------------- | ------- | ----------------------- | ------------------------ |
| foundationx_observe_events_total         | Counter | module,eventType,status | 诊断/审计事件输出次数    |
| foundationx_observe_export_errors_total  | Counter | backend,signal          | 观测数据导出失败次数     |
| foundationx_observe_log_dropped_total    | Counter | reason                  | 日志被采样或限流丢弃次数 |
| foundationx_observe_trace_spans_total    | Counter | module,status           | span 创建数量            |
| foundationx_observe_metric_registry_size | Gauge   | backend                 | 已注册指标数量           |

### 9.3 Trace / 诊断事件

- MUST 支持从 XContext 中提取和注入 TraceContext。
- MUST 支持异步任务、消息消费、调度任务中的上下文恢复。
- SHOULD 对观测后端导出失败创建诊断事件，但不得递归产生无限日志。

## 10. 错误模型与失败策略

| 错误类别                    | 典型原因                | 1.0 处理策略                             |
| --------------------------- | ----------------------- | ---------------------------------------- |
| OBSERVE_BACKEND_UNAVAILABLE | 观测后端不可用          | 降级到 Noop 或本地缓冲，不阻断业务主流程 |
| OBSERVE_CONTEXT_LOST        | 异步边界未恢复上下文    | 记录诊断事件，业务继续                   |
| OBSERVE_EXPORT_FAILED       | 指标/Trace/日志导出失败 | 按限流策略记录并重试或丢弃               |
| OBSERVE_INVALID_METRIC      | 指标名或标签不合法      | 开发期阻断，生产期拒绝注册并告警         |

## 11. 安全、稳定性与兼容性要求

- MUST 对密码、token、accessKey、secretKey、连接串中的敏感片段做脱敏。
- MUST 保证公开 API 的异常不会泄漏内部凭据、主机隐私或完整连接串。
- MUST 为所有网络和外部依赖调用设置超时边界。
- SHOULD 支持最小权限原则，不要求业务使用高权限账号。
- MUST 将审计事件与普通诊断事件分离。
- MUST 支持敏感字段统一脱敏策略。
- SHOULD 限制标签基数，避免把用户输入直接作为指标标签。

## 12. 测试证据要求

| 测试类型     | 必须覆盖内容                                       | 发布门禁  |
| ------------ | -------------------------------------------------- | --------- |
| 单元测试     | 日志字段、指标注册、Trace context、审计事件 schema | MUST 通过 |
| 并发测试     | 异步上下文传播、span 生命周期、指标并发记录        | MUST 通过 |
| 后端适配测试 | Noop/Console/SPI fallback                          | MUST 通过 |
| 集成测试     | 与 configx、resiliencx、redisx 至少三个模块集成    | MUST 通过 |
| 安全测试     | 敏感字段脱敏、指标高基数限制                       | MUST 通过 |

## 13. 1.0 发布验收清单

- 任一运行时模块接入 observex 后可以输出统一日志、指标和 Trace。
- 观测后端不可用不影响业务主流程启动。
- 指标名和日志字段通过标准检查。
- 审计事件模型具备稳定 schema。

## 14. Definition of Done

- 公开 API、配置项、错误码、指标名完成冻结并记录兼容性说明。
- README、快速开始、配置参考、错误码参考、测试说明完成。
- MUST 能力均有自动化测试，CI 可重复执行。
- 示例工程或最小可运行样例通过。
- 发布包不包含测试密钥、临时文件、个人环境路径。

## 15. 1.0 后演进方向

- 引入更多 exporter 适配器。
- 支持 SLO 模板和仪表盘生成。
- 引入日志动态采样和异常聚合。
