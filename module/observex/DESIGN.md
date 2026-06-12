# observex 设计方案

> Design ID: DESIGN-observex-v1
> Source Spec: [SPEC.md](./SPEC.md) v1.0.1
> Source Goal: [goal.md](./goal.md) 1.0 发布基线
> 生成日期：2026-06-12

---

## 1. 架构概述

observex 是 Foundation L1 运行时横切能力层中的可观测底座，提供 **vendor-neutral** 的日志、指标、追踪抽象。通过接口契约屏蔽底层实现（OTel SDK、Prometheus、Zap 等），使 70+ 模块统一接入而不绑定任何供应商。

```text
┌──────────────────────────────────────────────────────────────┐
│                    业务 / 领域模块（通过 Logger/Meter/Tracer） │
│  factor-engine   risk-engine   order-engine   binance  ...    │
└──────────┬──────────┬──────────┬──────────┬──────────────────┘
           │          │          │          │
           ▼          ▼          ▼          ▼
┌──────────────────────────────────────────────────────────────┐
│                    observex (L1 可观测抽象)                    │
│                                                              │
│  Logger ──── Meter ──── Tracer ──── Exporter ──── Health     │
│  ──────     ──────     ────────    ────────     ──────       │
│  结构化      指标注册   span 管理    后端适配      健康检查     │
│  日志        与采集     上下文传播   SPI           JSON schema │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  Redaction ─── Label Policy ─── 标准字段常量          │    │
│  │  脱敏引擎       基数控制          trace_id/span_id/... │    │
│  └──────────────────────────────────────────────────────┘    │
└──────────┬───────────────────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────────────────┐
│             Exporter 实现（可选依赖，按需引入）                  │
│  OTLP (gRPC/HTTP)  │  Prometheus  │  Noop  │  Test (Fake)   │
└──────────────────────────────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────────────────┐
│              第三方可观测平台（非本模块范围）                     │
│  Grafana / Jaeger / ELK / Prometheus / OTel Collector        │
└──────────────────────────────────────────────────────────────┘
```

### 1.1 设计原则

1. **接口先行，实现后置**：Logger/Meter/Tracer 全部是接口，具体实现可替换。消费者只依赖接口，不依赖具体 exporter。
2. **不变性（Immutability）**：`Logger.With()` 返回新实例，不修改原实例。所有字段追加操作创建新 slice。
3. **并发安全**：Logger/Meter 的实现使用 `sync.RWMutex` 保护内部状态，通过 `-race` 测试验证。
4. **静默降级**：exporter 不可达时不 panic、不阻塞业务，静默丢弃或降级到 stderr。
5. **零依赖核心**：核心接口包（`logger/`、`meter/`、`tracer/`）仅依赖 stdlib。exporter 实现为可选依赖。
6. **安全优先**：脱敏在输出前自动执行，label 基数在记录时强制检查，避免 PII 泄露和 Prometheus OOM。

---

## 2. 核心组件设计

### 2.1 Logger — 结构化日志

**核心类型**：

```go
type Logger interface {
    Debug(msg string, fields ...Field)
    Info(msg string, fields ...Field)
    Warn(msg string, fields ...Field)
    Error(msg string, fields ...Field)
    With(fields ...Field) Logger
    Named(name string) Logger
}

type Field struct {
    Key   string
    Value any
}
```

**设计决策**：

| 决策 | 理由 |
|------|------|
| 6 方法接口（含 Debug/Named） | 覆盖日志级别全谱 + 子 logger 创建，与 SPEC FR-001 对齐 |
| `With()` 返回新 Logger，不修改原实例 | 满足 BR-005 不变性要求；goroutine 安全共享基础 logger |
| `Named()` 创建子 logger | 支持按模块分层命名，如 `observex.otlp.exporter` |
| 输出格式 JSON/text 可配置 | JSON 适合生产采集，text 适合开发调试 |
| 内部使用 `sync.RWMutex` | 平衡读多写少场景下的并发性能 |

**With 不变性实现**：

```go
func (l *loggerImpl) With(fields ...Field) Logger {
    l.mu.RLock()
    defer l.mu.RUnlock()
    // 深拷贝现有 fields + 追加新 fields
    newFields := make([]Field, len(l.fields)+len(fields))
    copy(newFields, l.fields)
    copy(newFields[len(l.fields):], fields)
    return &loggerImpl{
        level:  l.level,
        fields: newFields,
        writer: l.writer,
    }
}
```

### 2.2 Meter — 指标注册与采集

**核心类型**：

```go
type Meter interface {
    Counter(name string) Counter
    Histogram(name string) Histogram
    Gauge(name string) Gauge
}

type Counter interface{ Add(ctx context.Context, value float64, attrs ...Attr) }
type Histogram interface{ Record(ctx context.Context, value float64, attrs ...Attr) }
type Gauge interface{ Set(ctx context.Context, value float64, attrs ...Attr) }
```

**设计决策**：

| 决策 | 理由 |
|------|------|
| 方法名 `Add/Record/Set`（非 `increment/record/supplier`） | 与 SPEC §9.2 对齐；Go 社区惯例（OTel API 使用 `Add/Record`） |
| 每次 Add/Record/Set 前检查 label policy | 在入口处拦截不合规 label，而非事后扫描 |
| 指标名正则校验：`^[a-z][a-z0-9_]*_[a-z0-9_]+$` | 防止非标准命名导致 exporter 拒绝或采集端解析错误 |
| 命名前缀 `foundationx_` | 在 Prometheus 等后端中统一过滤 FoundationX 系列指标 |

**Label Policy 两阶段检查**：

```
                ┌──────────────┐
  Add(attrs) →  │ 命名合规？    │ → NO → ErrLabelForbidden
                └──────┬───────┘
                       │ YES
                       ▼
                ┌──────────────┐
                │ label 在      │ → YES → 记录指标
                │ AllowedLabels │
                │ 中？          │ → NO  → 继续
                └──────┬───────┘
                       ▼
                ┌──────────────┐
                │ label 在      │ → YES → ErrLabelForbidden
                │ ForbiddenLabels│
                │ 中？          │ → NO  → 记录指标
                └──────────────┘
```

### 2.3 Tracer — 链路追踪

**核心类型**：

```go
type Tracer interface {
    Start(ctx context.Context, name string, opts ...SpanOption) (context.Context, Span)
}

type Span interface {
    End()
    SetAttributes(attrs ...Attr)
    RecordError(err error)
    SpanID() string
    TraceID() string
}
```

**设计决策**：

| 决策 | 理由 |
|------|------|
| trace_id/span_id 通过 `context.Context` 传播 | Go 标准惯例；跨 goroutine 自动继承 |
| context key 使用 unexported 类型 | 防止外部包意外覆盖 context value |
| 子 span 继承父 trace_id | 满足 BR-003 上下文传播要求 |
| span 创建时使用原子递增的 span ID | 并发安全，无锁竞争 |
| `SpanKind` 枚举（client/server/internal/producer/consumer） | 与 OpenTelemetry SpanKind 对齐，方便 exporter 映射 |

**Context 传播机制**：

```go
type contextKey struct{} // unexported，防止外部冲突

func (t *tracerImpl) Start(ctx context.Context, name string, opts ...SpanOption) (context.Context, Span) {
    parentTraceID := extractTraceID(ctx) // 从 ctx 读父 trace_id
    if parentTraceID == "" {
        parentTraceID = generateTraceID() // 新 trace
    }
    span := &spanImpl{
        traceID: parentTraceID,
        spanID:  generateSpanID(),
    }
    return context.WithValue(ctx, contextKey{}, span), span
}
```

### 2.4 Exporter — 后端适配 SPI

**核心类型**：

```go
type Exporter interface {
    ExportLogs(ctx context.Context, entries []LogEntry) error
    ExportMetrics(ctx context.Context, metrics []MetricPoint) error
    ExportSpans(ctx context.Context, spans []SpanData) error
    Shutdown(ctx context.Context) error
}
```

**设计决策**：

| 决策 | 理由 |
|------|------|
| 三个独立 Export 方法（非统一 Export） | 日志/指标/span 的数据模型不同，分开便于类型安全 |
| `Shutdown()` 必须 flush 缓冲区 | 满足 BR-004；优雅停机不丢数据 |
| Noop exporter 所有方法返回 nil | 测试和无观测后端的默认行为 |
| Test exporter 记录到内存 slice | 供测试断言，验证导出数据的正确性 |
| OTLP exporter 使用 build tag 控制 | 避免核心包引入 OTel SDK 重依赖 |

**三种 Exporter 实现**：

| Exporter | 行为 | 用途 |
|----------|------|------|
| `noop` | 所有方法返回 nil | 默认，无观测后端时静默运行 |
| `test` | 记录所有 entries/metrics/spans 到 slice | 单元测试断言 |
| `otlp` | gRPC/HTTP 发送到 OTel Collector | 生产环境 |

### 2.5 Redaction — 脱敏引擎

**设计决策**：

| 决策 | 理由 |
|------|------|
| 正则匹配字段名（非字段值） | 性能优先；字段值匹配假阳性高且不可控 |
| 脱敏在 Logger 输出前自动执行 | 不依赖调用方显式调用 |
| 仅替换 value 为 `***`，保留 key | 方便排查（知道哪个字段被脱敏） |
| 支持嵌套 map 递归脱敏 | 覆盖复杂日志结构 |
| 正则预编译 | 每次输出不重复编译 |

**Secret 识别模式**：

```text
(?i)(password|passwd|secret|token|api[_-]?key|access[_-]?key|private[_-]?key|credential|auth)
```

### 2.6 Health — 健康检查

**设计决策**：

| 决策 | 理由 |
|------|------|
| JSON schema 输出（`ready/live/message/components`） | 与 Kubernetes health probe 兼容 |
| 不实现 checker 接口，仅定义 schema | checker 由各模块（redisx/kafkax/postgresx）自行实现 |
| `HealthStatus` 结构体独立于 kernel | 避免循环依赖；observex 是 L1，kernel 是 L0 |

---

## 3. 性能设计

### 3.1 性能预算

| 操作 | 目标 | 设计保证 |
|------|------|----------|
| 单条结构化日志写入 | < 5μs（不含 I/O flush） | 内存 buffer + 批量 flush |
| metrics 记录 | < 1μs | 原子操作计数器，无锁 histogram |
| span 创建 + 结束 | < 2μs | 原子 ID 生成，内存 span 存储 |

### 3.2 性能优化策略

- **批量 flush**：日志/metrics 通过 buffer 批量发送，减少 I/O 频率
- **原子计数**：Counter 使用 `atomic.Int64`，避免锁竞争
- **预编码**：标准字段名预存为 `[]byte`，避免重复字符串分配
- **零分配路径**：Noop exporter 完全零分配（直接返回 nil）

---

## 4. 安全设计

### 4.1 脱敏策略

- **自动执行**：Logger 输出前自动调用 `Redact()`，不依赖调用方
- **字段名匹配**：仅匹配 key（`password`/`token`/`api_key` 等），不扫描 value
- **防御深度**：同时提供 `Check(input string)` 用于主动扫描文本

### 4.2 Label 基数控制

- **白名单**：仅 `component`/`module`/`operation`/`error_code`/`status`/`method`/`source` 允许
- **黑名单**：`order_id`/`account_id`/`trace_id`/`request_id`/`user_id`/`session_id` 禁止
- **运行时检查**：每次 Add/Record/Set 前验证，返回 `ErrLabelForbidden` 拒绝

### 4.3 敏感信息保护

- 不将内部凭据、主机隐私或完整连接串写入日志
- 公开 API 的 error message 不含栈追踪（内部日志保留）
- 审计事件与普通诊断事件分离（v1.1 完整实现）

---

## 5. 扩展点

### 5.1 当前 1.0 扩展点

| 扩展点 | 方式 | 说明 |
|--------|------|------|
| Exporter | 实现 `Exporter` 接口 | 可添加任意后端适配（如 Jaeger、Datadog） |
| Logger 输出 | 实现 `io.Writer` | 可自定义输出目标（文件、网络、syslog） |
| Redaction 模式 | 通过 `observex.redact_fields` 配置 | 可扩展脱敏字段列表 |

### 5.2 v1.1 规划扩展点

| 扩展点 | 方式 | 说明 |
|--------|------|------|
| AuditPublisher | 实现 `AuditPublisher` 接口 | 安全审计事件独立通道 |
| DiagnosticPublisher | 实现 `DiagnosticPublisher` 接口 | 模块诊断事件 |
| ObservationAdapter SPI | 实现 `ObservationAdapter` 接口 | 统一的后端适配抽象（替代当前 Exporter） |

---

## 6. 依赖关系

```text
observex（L1 运行时横切）
  ├── 允许依赖: kernel（L0 原语）、stdlib
  ├── 自管配置: 通过 §11 Config struct + mapstructure 自管理，不依赖 configx 运行时
  ├── 禁止依赖: configx、resiliencx、schedulex、redisx、kafkax、业务域实现
  └── v1.1: contracts（登记 API 契约和错误码契约）
```

### 6.1 消费者依赖方向

```text
kernel (L0)  ←─  observex (L1)
                    ↑
    ┌───────────────┼───────────────┐
    │               │               │
configx       resiliencx      schedulex (L1)
    │               │               │
    └───────────────┼───────────────┘
                    ↓
            redisx/kafkax/natsx/... (存储扩展)
                    ↓
              业务域模块 (factor-engine/risk-engine/...)
```

---

## 7. 未决问题

1. **采样策略**：是否需要支持运行时动态调整采样率？（当前 SPEC 未定义，但 goal.md §8 提及）
2. **指标聚合**：是否需要支持客户端聚合上报（减少网络开销）？
3. **自定义脱敏**：是否需要支持用户自定义 secret 正则模式？
4. **Trace Baggage**：是否需要支持 W3C Baggage 传播（跨进程业务数据传递）？

---

## 8. 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-12 | v1 | 初始版本：架构概述、6 个核心组件设计、性能/安全设计、扩展点、依赖关系 |
