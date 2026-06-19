# observex

## 1. 模块定位
observex 是 FoundationX 可观测底座（L4 Observability 层），vendor-neutral 统一日志、指标、追踪和跨模块观测上下文，通过 Exporter 接口契约屏蔽底层实现（OTel / Prometheus / Zap）。当前 Spec-Version v1.0.1、模块目标 Version v1.0.0、Runtime Tag v0.3.3（已发布，DoD 全部达成的 factory-grade 待 v1.0.0）。

## 2. 生产职责
- FR-001 Logger：结构化 JSON 输出、level 过滤、With 不变性、并发安全
- FR-002 Meter：Counter / Histogram / Gauge 注册与记录，label policy 基数控制
- FR-003 Tracer：span 生命周期、context 传播 trace_id / span_id
- FR-004 Exporter：ExportLogs / ExportMetrics / ExportSpans / Shutdown，Noop / Test / OTLP 三实现
- FR-005 Redaction：secret 字段自动脱敏为 `***`，redact.Check 检测泄露
- FR-006 Label Policy：AllowedLabels / ForbiddenLabels 检查
- FR-007 Health：health.JSON() 输出 ready / live / message / components schema

## 3. 边界定义
- 行为约束 BR-008：不直接绑定 Prometheus / OTel / Zap，通过 Exporter 接口抽象
- 指标命名强制 `foundationx_<module>_<operation>_<measure>`（BR-006）
- 日志 secret 字段强制自动脱敏（BR-007）
- label 基数受 AllowedLabels / ForbiddenLabels 控制（BR-002）

## 4. 不负责什么
- 不做告警升级（→ alertx）
- 不做业务判断或风控放行
- 不做 Prometheus / OTel / Zap 直接绑定
- 不把业务状态写死为 metrics 或 log 的强制枚举
- 不在 kernel 中创建强依赖（observex 作为可选注入）

## 5. 架构位置
L4 Observability 层（Spec 标注 L1 基础能力 / FEATURES 标注 L0 观测）。可依赖 kernel（L0 原语）与 stdlib；禁止依赖 configx / resiliencx / schedulex / 业务域实现。被 kernel.Deps、所有 L1 运行时模块、业务域、testkitx（FakeLogger / FakeMeter / FakeTracer）、x.go 消费。

## 6. 生命周期
- 初始化：observex 已完成初始化后 health.JSON() 输出 ready=true；未初始化输出 ready=false, live=false, message="not initialized"
- 运行：Logger / Meter / Tracer 并发安全（BR-001 / BR-005），exporter 不可达时静默降级
- Shutdown：Exporter.Shutdown flush 缓冲区；超时返回 ErrShutdownFailed，未发送数据写入本地退避文件（BR-004）
- Shutdown 期间并发 Export：进行中 Export 完成后关闭，新请求返回 ErrShutdownFailed（EC-010）

## 7. 标准目录结构
```text
observex/
├── observex.go          # Logger / Meter / Tracer 工厂
├── errors.go / options.go / redact.go / label_policy.go / health.go / recorder.go
├── logger/              # logger.go, fields.go（标准字段常量）
├── meter/               # meter.go, names.go（指标名常量）
├── tracer/              # tracer.go, propagation.go
├── exporter/{otlp,prometheus,noop,test}
├── internal/{buffer,sampler}
├── testdata/*.golden
└── example_test.go / benchmark_test.go / integration_test.go
```

## 8. 配置规范
typed Config 结构体（LoggingConfig / MetricsConfig / TracingConfig / RedactFields []string），带 `Validate()` 校验必填端点、合法 exporter 枚举、sample_rate 范围。关键项：logging.level=info / format=json / output=stdout；metrics.exporter=otlp / endpoint=otel-collector:4317 / interval=15s / prefix=foundationx_；tracing.sampler=parentbased_traceidratio / sample_rate=0.1 / propagation=tracecontext；redact_fields=[password,secret,api_key,token]。

## 9. 错误模型
typed sentinel errors：`ErrExporterFailed`(OBSERVE_EXPORTER_FAILED)、`ErrLabelForbidden`(OBSERVE_LABEL_FORBIDDEN)、`ErrBufferFull`(OBSERVE_BUFFER_FULL)、`ErrShutdownFailed`(OBSERVE_SHUTDOWN_FAILED)。消息格式 `observex: <operation>: <detail>`，使用 `%w` 包装保留底层错误链。exporter 不可达时调用方检查连通性并降级到 noop。

## 10. 日志规范
observex 本身是日志提供者（FR-001 Logger 接口）。标准字段常量 FieldTraceID / FieldSpanID / FieldComponent / FieldModule / FieldOperation / FieldErrorCode。结构化 JSON 输出，level 过滤（debug/info/warn/error），With 返回新实例保持不变性。secret 字段值自动替换为 `***`（redact_fields 列表 + 正则 `(?i)(password|passwd|secret|token|api[_-]?key|...)`）。日志事件名沿用 `observex.<component>.<event>` 点分层级（exporter.connected / disconnected / fallback）。

## 11. Metrics
observex 自观测指标统一 `foundationx_observex_*` 命名（对齐 BR-006）：
- `foundationx_observex_exporter_errors`（counter，发送失败次数）
- `foundationx_observex_exporter_queue_size`（gauge，待发送队列大小）
- `foundationx_observex_span_dropped`（counter，采样或队列满丢弃 span 数）
- `foundationx_observex_buffer_dropped`（counter，buffer 满丢弃条目）
- `foundationx_observex_label_forbidden`（counter，label policy 拒绝次数）

AllowedLabels = [component, module, operation, error_code, status, method, source]；ForbiddenLabels = [order_id, account_id, trace_id, request_id, user_id, session_id]。注：运行时仓库当前尚未落地这些自指标（实际使用 `client_*` 裸名），登记为 OQ-005 待实现。

## 12. Tracing
FR-003 Tracer 接口：Start(ctx, name, opts) → (ctx, Span)；Span.End / SetAttributes / RecordError / SpanID / TraceID。SpanConfig.Kind = client / server / internal / producer / consumer。子 span 继承父 trace_id（BR-003）；ctx 无 trace_id 时创建新 trace 并记录 warn 日志。采样器默认 parentbased_traceidratio，sample_rate=0.1，propagation=tracecontext（可选 b3 / both）。采样率=0 时不采样但不报错（EC-009）。

## 13. Reliability
- exporter 不可达（EC-001）：静默降级丢弃遥测数据，不影响业务，递增 exporter.errors counter
- 日志写入失败（EC-002）：降级到 stderr
- metrics buffer 满（EC-003）：丢弃最旧数据，递增 buffer.dropped counter
- Shutdown 超时（BR-004）：返回 ErrShutdownFailed，数据写入本地退避文件
- 并发 Logger + Exporter（EC-007）：-race 测试保证零 data race

## 14. Security
- 日志 secret 过滤：自动匹配 API key / token / password 模式脱敏
- metrics label 不含 PII：label value 白名单或正则过滤，ForbiddenLabels 拒绝高基数（order_id / account_id / user_id / session_id）
- tracing 采样策略：生产默认 parentbased_traceidratio 避免全量采集泄露敏感操作序列
- Secret 扫描门禁 gitleaks detect --no-git 零命中（NFR-009）

## 15. Performance SLO
| 操作 | 目标 | 条件 |
|------|------|------|
| 单条结构化日志写入 | < 5μs（不含 I/O flush） | 10 个预置 field，输出到内存 writer |
| metrics 记录（counter/histogram） | < 1μs | 单 counter + 3 attr，label policy 已预编译 |
| span 创建 + 结束 | < 2μs | 从带 parent trace 的 ctx 创建后立即 End |
| 常驻内存 | < 10MB | 全量 exporter 加载 + 100 goroutine 并发写入 |

## 16. 测试标准
- 单元测试覆盖率 ≥ 80%（NFR-005，实测 97.9%）
- -race 测试零 data race（NFR-006 / AC-008）
- go vet 零警告（NFR-007）、golangci-lint 零错误（NFR-008）
- TC-001 ~ TC-015 覆盖 Logger 不变性、Label Policy、Tracer 传播、Exporter 降级、Redaction、Health schema、Shutdown 超时
- Benchmark：日志 < 5μs / metrics < 1μs / span < 2μs
- 集成测试：exporter 不可达降级、端到端导出、100 goroutine 并发写入无 panic

## 17. Chaos
exporter 后端注入故障：不可达时调用方不 panic，返回 ErrExporterFailed 或静默降级（TC-004）。Shutdown deadline 注入：返回 ErrShutdownFailed，未发送数据写本地退避文件（TC-014）。buffer 压力注入：丢弃最旧数据并递增 dropped counter。goroutine 并发压力：100 并发写入零 data race。其余 chaos 维度 SPEC 未定义，待补充。

## 18. Contract
Logger 接口：Debug/Info/Warn/Error(msg, fields...) + With(fields) Logger + Named(name) Logger；Field{Key, Value any}。Meter：Counter/Histogram/Gauge，Add/Record/Set(ctx, value, attrs...)。Tracer：Start(ctx, name, opts...) (ctx, Span)；Span.End / SetAttributes / RecordError / SpanID / TraceID。Exporter：ExportLogs/Metrics/Spans + Shutdown。所有输入输出 schema 化（LogEntry / MetricPoint / SpanData / HealthStatus）。

## 19. CI Gate
通用：`go build ./...`、`go test ./... -race -count=1`、覆盖率 < 80% 阻塞（`go test -coverprofile` + `go tool cover -func`）、`go vet ./...`、`golangci-lint run`、`go mod tidy && git diff --exit-code`、`gitleaks detect --no-git`、Benchmark 附 PR comment。observex 专属：`make label-policy-check`、`make redaction-leak-check`、`make metrics-contract-check`、`go test -run TestHealthSchema ./...`。

## 20. Release Gate
DoD 清单：公共接口有 godoc、公共类型有 example_test.go、CHANGELOG.md 更新、README 含定位/快速开始/配置/API、覆盖率 ≥ 80%、-race 通过、Benchmark 无 > 10% 回退、vet/lint 零警告、label policy / redaction leak / metrics contract / Secret 扫描全通过、API 无破坏性变更（或 bump major）、所有 FR 和 EC 有对应测试。v0.3.3 已通过 `make release-final-check VERSION=v0.3.3`。

## 21. Versioning
semver。Spec-Version v1.0.1（规格文档）、模块 Version v1.0.0（API 冻结目标，尚未达成）、Runtime Tag v0.3.3（实证事实层）三轴独立。Logger/Meter/Tracer interface 变更 → major；字段规范变更 → minor + changelog；新增可选配置 → patch/minor；bug 修复 → patch。v0.4 已完成 foundationx 解耦，所有类型迁移到 kernel 原语（errx.Kind / healthx.Status）。

## 22. 兼容性策略
- Logger/Meter/Tracer interface 变更：major，发布迁移指南 + 兼容适配层，消费者下个 minor 内迁移
- 新增/删除必填字段：minor + changelog，新字段带默认值，旧字段 deprecated 保留两版本
- 新增可选配置字段：patch/minor，带默认值，旧配置继续工作
- 新增必填配置字段：minor，提供默认值并在 changelog 说明
- 边界情况 EC-001 ~ EC-010 全部有定义与降级路径

## 23. Failover
- exporter 不可达（EC-001）：静默降级到 noop exporter，丢弃遥测数据，递增 exporter.errors，不影响业务调用方
- 日志写入失败（EC-002）：降级到 stderr
- Exporter.Shutdown 超时（BR-004）：返回 ErrShutdownFailed，未发送数据写本地退避文件，可后续重放
- 采样率=0（EC-009）：不采样 span 但不报错，span.dropped counter 递增

## 24. Backpressure
- metrics buffer 满（EC-003）：丢弃最旧数据，递增 buffer.dropped counter
- 高基数 label 爆炸（EC-004）：label policy checker 拒绝返回 ErrLabelForbidden 或截断，递增 label.forbidden counter
- exporter 队列：gauge observex.exporter_queue_size 监控待发送队列大小
- bounded queue + overload protection 通过 buffer 上限与 label policy 实现

## 25. 审计要求
- secret 值脱敏审计：redact.Check 扫描文本报告泄露位置（TC-012），redaction leak check CI gate 阻塞
- exporter 连接状态审计：observex.exporter.connected / disconnected / fallback 日志事件
- 指标命名合规审计：metrics contract check CI gate（BR-006）
- 依赖边界审计：import check CI gate 阻塞直接 Prometheus/OTel/Zap 绑定（BR-008 / AC-015）

## 26. 熵减规则
全局 Entropy Rules + 模块特有禁项：
- 禁止 util dumping（observex.go / errors.go / options.go / redact.go 等职责分离）
- 禁止 hidden abstraction（Exporter 接口显式屏蔽 vendor 绑定）
- 禁止 cyclic dependency（依赖方向严格 kernel → observex，禁止反向）
- 禁止业务状态写死为 metrics/log 强制枚举

## 27. AI Constraints
全局 AI Constraints + 模块特有约束：
- 不新增未注册模块（observex 子目录固定：logger/meter/tracer/exporter）
- 不绕过 contracts（必须通过 Logger/Meter/Tracer/Exporter 接口）
- 不动态扩展目录（internal/buffer、internal/sampler 固定）
- 不直接 import Prometheus / OTel / Zap（BR-008 import check 阻塞）
- 不修改 Logger 原实例（BR-005 With 不变性）

## 28. Forbidden Patterns
- 全局可变状态共享 Logger（违反 BR-001 并发安全）
- With 修改原 Logger 实例（违反 BR-005 不变性，-race 测试失败）
- 高基数 label 直传 metrics（违反 BR-002，返回 ErrLabelForbidden）
- 指标命名不符合 foundationx_ 前缀（违反 BR-006，metrics contract check 阻塞）
- 日志输出未脱敏 secret（违反 BR-007，redaction leak check 阻塞）
- 直接编译期绑定 Prometheus/OTel/Zap（违反 BR-008，import check 阻塞）
- Shutdown 不 flush 缓冲区（违反 BR-004）

## 29. Production Ready Checklist
- [x] observability ready（FR-001~007 全部实现，自观测指标 OQ-005 待落地）
- [x] resilience ready（exporter 降级、buffer 丢弃、Shutdown 退避文件全实现）
- [x] replay ready（recorder.go 内存记录 + testdata golden 用于回放）
- [x] audit ready（redaction leak / metrics contract / import check 三 CI gate）
- [ ] rollback ready（v0.3.3 已发布，runtime tag 推进到 v1.0.0 前 factory=false）
- [x] 测试覆盖率 97.9%（门槛 80%）、-race 零 data race、vet/lint/gitleaks 全绿

## 30. Roadmap
- v1.0.0 foundation：API 冻结，runtime tag 从 v0.3.3 推进到 v1.0.0（当前主要缺口）
- OQ-001 评估自定义 redaction 模式（用户自定义 secret 正则）
- OQ-002 评估 tracing 采样率运行时动态调整
- OQ-003 评估 health JSON schema 自定义字段扩展
- OQ-005 落地 §17 自观测指标到运行时（替换 client_* 裸名）
- OQ-004 评估 metrics 聚合上报（批量发送减少网络开销）
