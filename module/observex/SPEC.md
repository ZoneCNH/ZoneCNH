# observex 完整规格

> Foundation L1 运行时契约。vendor-neutral 日志、指标、追踪、健康与脱敏契约。

最后更新：2026-06-12

---

## 1. Metadata

- Status: Review
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-12
- Owner: ZoneCNH
- Layer: L1 基础能力
- Version: v0.7.3
- Repository: [github.com/ZoneCNH/observex](https://github.com/ZoneCNH/observex)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md)

---

### 1.1 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-07 | v1.0.0 | 初始版本 | ZoneCNH |
| 2026-06-12 | v1.0.1 | 结构修复：BR违反时列、Data Model补充、FR异常路径、Open Questions分类、配置表格化 | ZoneCNH |
| 2026-06-12 | v1.0.1 | 状态 Draft → Review（Claude 99 + Rules 100，两源评分通过，待 Codex/Copilot 凑齐四源） | ZoneCNH |

## 2. Summary

`observex` 是可观测底座，统一日志、指标、追踪和跨模块观测上下文。vendor-neutral 设计，通过接口契约屏蔽底层实现（OTel、Prometheus、Zap 等）。

### 2.1 核心职责

- 提供 Logger / Meter / Tracer / Exporter / Health 五类 vendor-neutral 接口抽象
- 实现结构化日志输出、level 过滤、With 不变性、并发安全
- 实现 Counter / Histogram / Gauge 指标注册与 label policy 基数控制
- 实现 span 生命周期管理、context 传播 trace_id / span_id
- 实现日志/metrics 自动脱敏（secret 字段值替换为 `***`）
- 提供 Noop / Test / OTLP 三种 Exporter 实现，支持优雅 Shutdown
- 提供 Health JSON schema 输出（ready / live / message / components）

### 2.2 明确不做

- 不做告警升级（由 `alertx` 负责）
- 不做业务判断或风控放行（由 `risk-engine` 负责）
- 不直接绑定 Prometheus / OTel / Zap 实现（通过 Exporter 接口抽象）
- 不把业务状态写死为 metrics 或 log 的强制枚举
- 不在 kernel 中创建强依赖（observex 作为可选注入）

---

## 3. Problem

70+ 模块各自接入可观测框架，接口不统一、字段不规范、脱敏缺失，导致：

- 日志格式不一致，跨模块关联困难（同一 trace 跨 3 个模块需人工拼接日志行）
- 指标命名不规范，label 高基数导致 Prometheus OOM（实测单个模块产生 2000+ 唯一 label 组合）
- 追踪上下文丢失，跨模块调用链断裂（goroutine 边界处 trace_id 传播失败率 ~15%）
- secret 值泄露到日志/metrics/span 中（无统一脱敏层，依赖各模块自行实现）
- 切换 exporter 需要修改所有模块代码（OTel→Prometheus 迁移需改动 70+ 个 go.mod）

---

## 4. Goals

- 统一 Logger / Meter / Tracer 接口，vendor-neutral，通过 Exporter 适配任意后端
- 标准字段规范：trace_id、span_id、component、module、operation、error_code
- 指标命名规范：`foundationx_<module>_<operation>_<measure>`
- label policy 控制（白名单 + 高基数禁止列表 + 运行时检查）
- 日志/metrics 脱敏策略（自动匹配 secret 字段名并替换值）
- health.JSON() 输出符合既定 JSON schema（ready/live/message/components 四字段，兼容 K8s probe）
- 测试 exporter 用于模块单测（记录到内存 slice，供断言使用）

---

## 5. Non-goals

- 不做告警升级（→ `alertx`）
- 不做业务判断或风控放行
- 不做 Prometheus/Otel/Zap 直接绑定（通过 Exporter 接口抽象）
- 不把业务状态写死为 metrics 或 log 的强制枚举

---

## 6. Consumers

| 消费者 | 使用方式 |
|--------|----------|
| `kernel.Deps` | 接收 `observex.Logger`、`observex.Meter`、`observex.Tracer` |
| 所有 L1 运行时模块 | 通过 Logger/Meter/Tracer 接口输出可观测数据 |
| 业务域模块 | 通过 Logger 记录业务日志，通过 Meter 采集业务指标 |
| `testkitx` | 提供 FakeLogger / FakeMeter / FakeTracer 用于测试 |
| `x.go` | 创建 Exporter，注入到 kernel.Deps |

---

## 7. Functional Requirements

### FR-001: Logger

WHEN 调用 `Info(msg, fields...)` 且 level >= info
THEN 输出结构化日志，包含 msg 和所有 fields

WHEN 调用 `Debug(msg, fields...)` 且 level = info
THEN 不输出（level 过滤）

WHEN 调用 `With(fields...)`
THEN 返回新 Logger 实例，原实例不变（不变性）

WHEN 多个 goroutine 并发调用同一 Logger
THEN 无数据竞争（并发安全）

### FR-002: Meter

WHEN 调用 `Counter(name).Add(ctx, value, attrs...)`
THEN 对应计数器累加 value

WHEN 调用 `Histogram(name).Record(ctx, value, attrs...)`
THEN 记录一条直方图样本

WHEN 调用 `Gauge(name).Set(ctx, value, attrs...)`
THEN 设置仪表盘值

WHEN label 值在 ForbiddenLabels 中
THEN 拒绝记录并返回 `ErrLabelForbidden`

### FR-003: Tracer

WHEN 调用 `Tracer.Start(ctx, name)`
THEN 创建新 span，返回带 span 的 ctx

WHEN 调用 `span.End()`
THEN 结束 span，上报到 exporter

WHEN 调用 `span.RecordError(err)`
THEN 记录错误事件到 span

WHEN ctx 中已有 trace_id
THEN 子 span 继承同一 trace_id（上下文传播）

### FR-004: Exporter

WHEN 调用 `ExportLogs(ctx, entries)` 且 exporter 正常连接
THEN 日志条目成功发送到后端，返回 nil

WHEN 调用 `ExportMetrics(ctx, metrics)` 且 exporter 正常连接
THEN 指标数据点成功发送到后端，返回 nil

WHEN 调用 `ExportSpans(ctx, spans)` 且 exporter 正常连接
THEN span 数据成功发送到后端，返回 nil

WHEN 调用 `ExportLogs(ctx, entries)` 且 exporter 不可达
THEN 返回错误，不影响业务调用方

WHEN 调用 `Shutdown(ctx)`
THEN flush 缓冲区，释放资源

### FR-005: Redaction

WHEN 日志字段名匹配 secret 模式（password、token、api_key 等）
THEN 字段值被替换为 `***`

WHEN 调用 `redact.Check(input)` 扫描文本
THEN 检测并报告泄露的 secret 值

### FR-006: Label Policy

WHEN 指标 label 在 AllowedLabels 中
THEN 允许记录

WHEN 指标 label 在 ForbiddenLabels 中
THEN 拒绝记录，返回 `ErrLabelForbidden`

WHEN 调用独立 label policy checker 检查 label 合规性
THEN 返回 label 是否在允许列表或禁止列表中的判定结果

### FR-007: Health

WHEN 调用 `health.JSON()` 且 observex 已完成初始化
THEN 输出符合 health JSON schema（ready、live、message、components 四字段）

WHEN 调用 `health.JSON()` 且 observex 尚未初始化
THEN 输出默认健康状态（ready=false, live=false, message="not initialized", components=[]）

WHEN 任一 exporter 后端不可达
THEN 对应 component 的 live 字段为 false，整体 ready 为 false，但不 panic

---

## 8. Business Rules

| 编号 | 规则 | 违反时 |
|------|------|--------|
| BR-001 | Logger 实现必须并发安全 | 出现 data race 则 `-race` 测试失败，CI gate 阻塞，禁止合并 |
| BR-002 | Meter 实现必须控制 label 基数，高基数 label 被拒绝或截断 | 返回 `ErrLabelForbidden`，指标记录被丢弃，并递增 `observex.label.forbidden` counter |
| BR-003 | Tracer 必须从 context.Context 传播 trace_id / span_id | 跨 goroutine 丢失上下文时，创建新的 trace_id（独立 trace），并记录 warn 日志 |
| BR-004 | Exporter.Shutdown 必须 flush 缓冲区 | 超时未 flush 完成则返回 `ErrShutdownFailed`，未发送数据写入本地退避文件 |
| BR-005 | With 返回新实例，不修改原 Logger（不变性） | 若实现修改原实例，`-race` 测试失败（并发场景触发 data race），CI gate 阻塞 |
| BR-006 | 指标命名必须符合 `foundationx_<module>_<op>_<measure>` | 返回 `ErrLabelForbidden`，指标注册被拒绝，CI gate（metrics contract check）阻塞 |
| BR-007 | 日志中 secret 字段必须自动脱敏 | secret 值出现在日志输出中则 redaction leak check 失败，CI gate 阻塞 |
| BR-008 | 不直接绑定 Prometheus/Otel/Zap，通过 Exporter 接口抽象 | import graph 中出现直接依赖 Prometheus/Otel/Zap 的编译期绑定则 CI gate（import check）阻塞，代码审查拒绝 |

---

## 9. Interface Contract

### 9.1 Logger

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

### 9.2 Meter

```go
type Meter interface {
    Counter(name string) Counter
    Histogram(name string) Histogram
    Gauge(name string) Gauge
}

type Counter interface{ Add(ctx context.Context, value float64, attrs ...Attr) }
type Histogram interface{ Record(ctx context.Context, value float64, attrs ...Attr) }
type Gauge interface{ Set(ctx context.Context, value float64, attrs ...Attr) }

type Attr struct{ Key, Value string }
```

### 9.3 Tracer

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

type SpanOption func(*SpanConfig)
type SpanConfig struct {
    Kind SpanKind // client / server / internal / producer / consumer
}
```

### 9.4 Exporter

```go
type Exporter interface {
    ExportLogs(ctx context.Context, entries []LogEntry) error
    ExportMetrics(ctx context.Context, metrics []MetricPoint) error
    ExportSpans(ctx context.Context, spans []SpanData) error
    Shutdown(ctx context.Context) error
}
```

### 9.5 Label Policy

```go
// 指标命名前缀
// foundationx_<module>_<operation>_<measure>

// label 允许列表
var AllowedLabels = []string{
    "component", "module", "operation", "error_code",
    "status", "method", "source",
}

// label 禁止列表（高基数）
var ForbiddenLabels = []string{
    "order_id", "account_id", "trace_id", "request_id",
    "user_id", "session_id",
}
```

---

## 10. Data Model

### 10.1 公共错误

```go
var (
    ErrExporterFailed   = errors.New("observex: exporter failed")
    ErrLabelForbidden   = errors.New("observex: label forbidden")
    ErrBufferFull       = errors.New("observex: buffer full")
    ErrShutdownFailed   = errors.New("observex: shutdown failed")
)
```

### 10.2 标准字段常量

```go
const (
    FieldTraceID    = "trace_id"
    FieldSpanID     = "span_id"
    FieldComponent  = "component"
    FieldModule     = "module"
    FieldOperation  = "operation"
    FieldErrorCode  = "error_code"
)
```

### 10.3 LogEntry

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| Timestamp | `time.Time` | 是 | 日志产生时间 |
| Level | `string` | 是 | 日志等级（debug/info/warn/error） |
| Message | `string` | 是 | 日志消息正文 |
| Fields | `[]Field` | 否 | 结构化字段（已执行脱敏后） |
| TraceID | `string` | 否 | 关联 trace_id |
| SpanID | `string` | 否 | 关联 span_id |

### 10.4 MetricPoint

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| Name | `string` | 是 | 指标名（符合 `foundationx_<module>_<op>_<measure>`） |
| Kind | `string` | 是 | counter / histogram / gauge |
| Value | `float64` | 是 | 指标数值 |
| Attrs | `[]Attr` | 否 | label 属性和值 |
| Timestamp | `time.Time` | 是 | 采集时间 |

### 10.5 SpanData

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| TraceID | `string` | 是 | trace 唯一标识 |
| SpanID | `string` | 是 | span 唯一标识 |
| ParentSpanID | `string` | 否 | 父 span ID（根 span 时为空） |
| Name | `string` | 是 | span 名称 |
| Kind | `SpanKind` | 是 | client / server / internal / producer / consumer |
| StartTime | `time.Time` | 是 | span 开始时间 |
| EndTime | `time.Time` | 否 | span 结束时间（未结束时为零值） |
| Attrs | `[]Attr` | 否 | span 属性 |
| Status | `string` | 否 | ok / error |

### 10.6 HealthStatus

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| Ready | `bool` | 是 | 整体就绪状态（所有 component 的 live 均为 true） |
| Live | `bool` | 是 | 进程存活状态 |
| Message | `string` | 否 | 人类可读的状态消息 |
| Components | `[]ComponentHealth` | 否 | 子组件健康状态列表 |

**ComponentHealth**：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| Name | `string` | 是 | 组件名（如 "otlp-exporter"、"logger"） |
| Live | `bool` | 是 | 组件存活状态 |
| Ready | `bool` | 是 | 组件就绪状态 |
| Message | `string` | 否 | 组件状态消息 |

---

## 11. Config Schema

```yaml
observex:
  logging:
    level: info
    format: json              # json / text
    output: stdout            # stdout / file / both
    file_path: /var/log/app.log
    max_size: 100MB
    max_backups: 5
  metrics:
    enabled: true
    exporter: otlp            # otlp / prometheus / noop
    endpoint: otel-collector:4317
    interval: 15s
    prefix: fx
  tracing:
    enabled: true
    exporter: otlp
    endpoint: otel-collector:4317
    sampler: parentbased_traceidratio
    sample_rate: 0.1
    propagation: tracecontext # tracecontext / b3 / both
  redact_fields:
    - password
    - secret
    - api_key
    - token
```

| 配置项 | 类型 | 默认值 | 必填 | 说明 |
|--------|------|--------|------|------|
| `observex.logging.level` | `string` | `info` | 否 | 日志等级：debug / info / warn / error |
| `observex.logging.format` | `string` | `json` | 否 | 输出格式：json / text |
| `observex.logging.output` | `string` | `stdout` | 否 | 输出目标：stdout / file / both |
| `observex.logging.file_path` | `string` | `/var/log/app.log` | 否（output=file时是） | 日志文件路径 |
| `observex.logging.max_size` | `string` | `100MB` | 否 | 日志文件最大大小 |
| `observex.logging.max_backups` | `int` | `5` | 否 | 最大保留备份文件数 |
| `observex.metrics.enabled` | `bool` | `true` | 否 | 是否启用指标采集 |
| `observex.metrics.exporter` | `string` | `otlp` | 否 | 指标 exporter：otlp / prometheus / noop |
| `observex.metrics.endpoint` | `string` | `otel-collector:4317` | 否（exporter!=noop时是） | exporter 端点地址 |
| `observex.metrics.interval` | `string` | `15s` | 否 | 指标采集间隔 |
| `observex.metrics.prefix` | `string` | `fx` | 否 | 指标名前缀 |
| `observex.tracing.enabled` | `bool` | `true` | 否 | 是否启用链路追踪 |
| `observex.tracing.exporter` | `string` | `otlp` | 否 | 追踪 exporter：otlp / noop |
| `observex.tracing.endpoint` | `string` | `otel-collector:4317` | 否（exporter!=noop时是） | exporter 端点地址 |
| `observex.tracing.sampler` | `string` | `parentbased_traceidratio` | 否 | 采样策略 |
| `observex.tracing.sample_rate` | `float64` | `0.1` | 否 | 采样率（0.0 ~ 1.0） |
| `observex.tracing.propagation` | `string` | `tracecontext` | 否 | 传播协议：tracecontext / b3 / both |
| `observex.redact_fields` | `[]string` | `[password, secret, api_key, token]` | 否 | 需脱敏的字段名列表 |

### Config 结构体

```go
type Config struct {
    Logging   LoggingConfig   `mapstructure:"logging"`
    Metrics   MetricsConfig   `mapstructure:"metrics"`
    Tracing   TracingConfig   `mapstructure:"tracing"`
    RedactFields []string     `mapstructure:"redact_fields"`
}

func (c *Config) Validate() error {
    // 校验必填端点、合法 exporter 枚举值、sample_rate 范围等
}
```

---

## 12. Error Handling

| 错误 | 错误码 | 调用方处理 |
|------|--------|-----------|
| `ErrExporterFailed` | `OBSERVE_EXPORTER_FAILED` | 检查 exporter 端点连通性，降级到 noop exporter |
| `ErrLabelForbidden` | `OBSERVE_LABEL_FORBIDDEN` | 检查 label 名，使用 AllowedLabels 中的替代 |
| `ErrBufferFull` | `OBSERVE_BUFFER_FULL` | 增大 buffer 或降低采集频率 |
| `ErrShutdownFailed` | `OBSERVE_SHUTDOWN_FAILED` | 检查 exporter 连接状态；若连接未关闭，执行手动清理 |

**错误消息格式：** `"observex: <operation>: <detail>"`
**错误包装：** 使用 `%w` 保留底层错误链

---

## 13. Edge Cases

- exporter 不可达（EC-001）：静默降级，丢弃遥测数据，不影响业务；递增 `observex.exporter.errors` counter
- 日志写入失败（EC-002）：降级到 stderr
- metrics buffer 满（EC-003）：丢弃最旧数据，递增 `observex.buffer.dropped` counter
- 高基数 label 爆炸（EC-004）：label policy checker 拒绝（返回 `ErrLabelForbidden`）或截断
- secret 值传入日志字段（EC-005）：自动脱敏为 `***`
- With(nil fields)（EC-006）：返回原实例（不变性）
- 并发调用 Logger + Exporter（EC-007）：无 data race（`-race` 测试通过）
- tracing context 跨 goroutine（EC-008）：保持同一 trace_id
- 采样率 = 0（EC-009）：不采样任何 span，但不报错；`observex.span.dropped` counter 递增

---

## 14. Directory Structure

```text
observex/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go
├── observex.go                 # Logger / Meter / Tracer 工厂
├── errors.go
├── options.go
├── logger/
│   ├── logger.go
│   └── fields.go               # 标准字段常量
├── meter/
│   ├── meter.go
│   └── names.go                # 指标名常量
├── tracer/
│   ├── tracer.go
│   └── propagation.go
├── exporter/
│   ├── otlp/
│   ├── prometheus/
│   ├── noop/
│   └── test/                   # FakeExporter
├── redact.go                   # 日志/metrics 脱敏
├── label_policy.go             # label policy checker
├── health.go                   # health JSON schema
├── recorder.go                 # memory recorder
├── internal/
│   ├── buffer/
│   └── sampler/
├── testdata/
│   └── *.golden
├── example_test.go
├── benchmark_test.go
└── integration_test.go
```

---

## 15. Dependencies

### 15.1 go.mod

```text
module github.com/ZoneCNH/observex

go 1.23
```

### 15.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| kernel（L0 原语） | configx, resiliencx, schedulex |
| stdlib | testkitx（仅 test） |
| OTel SDK（可选） | 所有业务域实现 |

### 15.3 foundationx 兼容

- v0.4 已完成 foundationx 解耦：`internal/foundationx` 已物理删除，contract tests 已重写
- 所有 foundationx 类型已迁移到 kernel 原语（`errx.Kind`、`healthx.Status`）
- 详情见 `docs/foundationx-compatibility.md` 和 `FOUNDATION-TRACKER.md`

---

## 16. Testing

### 16.1 单元测试

| 测试场景 | 验证点 |
|----------|--------|
| 结构化日志字段 | `Info("msg", Field{...})` 输出 JSON |
| log level 过滤 | level=info → debug 日志不输出 |
| logger.With 不变性 | `With` 返回新实例，不修改原 logger |
| metrics 注册 | counter/histogram/gauge 创建和记录 |
| label 基数控制 | 高基数 label 被拒绝并返回 `ErrLabelForbidden` |
| span 创建 + 结束 | trace_id / span_id 正确传播 |
| context 传播 | 跨 goroutine 保持同一 trace |
| redaction | secret 字段被替换为 `***` |
| label policy | forbidden label 被拒绝，allowed label 通过 |
| health schema | 输出符合 JSON schema；未初始化时输出默认状态 |

### 16.2 验收标准（AC）

| AC 编号 | 对应 FR | 验收条件 |
|---------|---------|----------|
| AC-001 | FR-001 | Logger 所有等级输出符合结构化 JSON；level 过滤正确；With 返回新实例且原实例不变；并发调用无 data race |
| AC-002 | FR-002 | Counter/Histogram/Gauge 记录数值正确；ForbiddenLabels 被拒绝并返回 ErrLabelForbidden |
| AC-003 | FR-003 | span 创建/结束正确；RecordError 记录错误事件；子 span 继承父 trace_id；跨 goroutine context 传播 |
| AC-004 | FR-004 | ExportLogs/Metrics/Spans 正常导出返回 nil；exporter 不可达时返回错误但不 panic；Shutdown 后 buffer 已 flush |
| AC-005 | FR-005 | secret 字段值被替换为 ***；redact.Check 检测文本中泄露的 secret |
| AC-006 | FR-006 | AllowedLabels 通过、ForbiddenLabels 拒绝；独立 checker 返回正确判定 |
| AC-007 | FR-007 | 已初始化时输出符合 schema 的 JSON；未初始化时 ready=false；exporter 不可达时对应 component live=false |
| AC-008 | BR-001 | -race 测试零 data race |
| AC-009 | BR-002 | ForbiddenLabels 被拒绝并返回 ErrLabelForbidden；observex.label.forbidden counter 递增 |
| AC-010 | BR-003 | 跨 goroutine 保持同一 trace_id；丢失上下文时创建新 trace 并记录 warn |
| AC-011 | BR-004 | Shutdown 后数据已发送；超时返回 ErrShutdownFailed |
| AC-012 | BR-005 | 并发 With 调用后原实例不变；-race 测试零 data race |
| AC-013 | BR-006 | 不合规命名返回 ErrLabelForbidden；CI Gate metrics contract check 通过 |
| AC-014 | BR-007 | secret 值不出现在日志输出中；CI Gate redaction leak check 通过 |
| AC-015 | BR-008 | import graph 中无直接 Prometheus/Otel/Zap 绑定；CI Gate import check 通过 |


### 16.3 Given/When/Then 用例

**TC-001: Logger.With 不变性**
Given 原始 logger `l1`
When 调用 `l2 := l1.With(Field{"k", "v"})`
Then `l1` 不含字段 k，`l2` 包含字段 k

**TC-002: Label Policy 拒绝高基数**
Given ForbiddenLabels 包含 `order_id`
When 调用 `Counter("test").Add(ctx, 1, Attr{"order_id", "12345"})`
Then 返回 `ErrLabelForbidden`，计数器值不变

**TC-003: Tracer 上下文传播**
Given 在 goroutine A 中创建 span
When goroutine B 从 ctx 中读取 trace_id
Then trace_id 与 A 中创建的一致

**TC-004: Exporter 不可达降级**
Given exporter 后端不可用
When 写入日志、指标或 span
Then 调用方不 panic，返回 `ErrExporterFailed` 或静默降级

**TC-004a: Exporter 正常导出**
Given exporter 后端可用
When 调用 `ExportLogs(ctx, entries)`
Then 返回 nil，日志条目成功发送

**TC-004b: Exporter 正常导出指标**
Given exporter 后端可用
When 调用 `ExportMetrics(ctx, metrics)`
Then 返回 nil，指标数据点成功发送

**TC-004c: Exporter 正常导出 Span**
Given exporter 后端可用
When 调用 `ExportSpans(ctx, spans)`
Then 返回 nil，span 数据成功发送

**TC-005: Redaction 脱敏**
Given 日志字段包含 secret、token 或 password
When 写入结构化日志
Then 输出中敏感值被替换为 `***`

**TC-005a: redact.Check 扫描文本**
Given 包含 `api_key=sk-abc123` 的文本
When 调用 `redact.Check(text)`
Then 返回检测到的泄露 secret 位置

**TC-006: Health schema 正常**
Given observex 已初始化
When 调用 Health
Then 返回符合约定 JSON schema 的健康状态

**TC-006a: Health 未初始化**
Given observex 尚未初始化
When 调用 Health
Then 返回 ready=false, live=false, message="not initialized"

**TC-007: Metrics 命名规范**
Given 指标名不符合命名规范
When 注册 counter 或 histogram
Then 返回命名错误并拒绝注册

**TC-007a: 独立 label policy checker**
Given label 名在 ForbiddenLabels 中
When 调用 `labelpolicy.Check("order_id")`
Then 返回 false

### 16.4 Benchmark

| 场景 | 目标 |
|------|------|
| 单条结构化日志写入 | < 5μs（不含 I/O flush） |
| metrics 记录（counter/histogram） | < 1μs |
| span 创建 + 结束 | < 2μs |

### 16.5 集成测试

| 场景 | 验证点 |
|------|--------|
| exporter 不可达降级 | exporter 返回错误 → 不影响业务 |
| exporter 正常导出端到端 | Logger + Meter + Tracer + Exporter 完整链路通过 |
| 并发写入 + exporter 降级 | 100 goroutine 并发写入时无 data race、无 panic |

---

## 17. Performance Budget

| 操作 | 目标 | 条件 | 测量方式 |
|------|------|------|----------|
| 单条结构化日志写入 | < 5μs（不含 I/O flush） | 10 个预置 field，输出到内存 writer | benchmark test |
| metrics 记录（counter/histogram） | < 1μs | 单 counter + 3 个 attr，label policy 已预编译 | benchmark test |
| span 创建 + 结束 | < 2μs | 从带 parent trace 的 ctx 创建 span，立即 End | benchmark test |
| 常驻内存 | < 10MB | 全量 exporter 加载 + 100 goroutine 并发写入 | profiling（`go test -benchmem -memprofile`） |

---

## 18. Observability

| 类型 | 名称 | 说明 |
|------|------|------|
| metric | `observex.exporter.errors` | counter，exporter 发送失败次数 |
| metric | `observex.exporter.queue.size` | gauge，待发送队列大小 |
| metric | `observex.span.dropped` | counter，因采样或队列满丢弃的 span 数 |
| metric | `observex.buffer.dropped` | counter，因 buffer 满丢弃的数据条目 |
| metric | `observex.label.forbidden` | counter，label policy 拒绝次数 |
| log | `observex.exporter.connected` | info，exporter 连接成功 |
| log | `observex.exporter.disconnected` | warn，exporter 连接断开 |
| log | `observex.exporter.fallback` | warn，降级到备用 exporter |

---

## 19. Security

| 要求 | 实现方式 |
|------|----------|
| 日志中 secret 过滤 | 自动匹配 API key / token / password 模式并脱敏 |
| metrics label 不含 PII | label value 白名单或正则过滤 |
| tracing 采样策略 | 生产环境默认 parentbased_traceidratio，避免全量采集泄露敏感操作序列 |

### secret 识别模式

```text
(?i)(password|passwd|secret|token|api[_-]?key|access[_-]?key|private[_-]?key|credential|auth)
```

---

## 20. CI Gate

### 20.1 通用 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 任何测试失败或 data race |
| 覆盖率 | `mkdir -p .coverage && go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | 总覆盖率 < 80% |
| vet | `go vet ./...` | 任何 vet 错误 |
| lint | `golangci-lint run` | 任何 lint 错误 |
| 依赖检查 | `go mod tidy && git diff --exit-code go.mod go.sum` | go.mod 不整洁 |
| Secret 扫描 | `gitleaks detect --no-git` | 泄露 secret |
| Benchmark | `go test -bench=. -benchmem -count=3 ./...` | 结果附在 PR comment |

### 20.2 observex 专属 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| label policy check | `make label-policy-check` | 指标 label 不符合规范 |
| redaction leak check | `make redaction-leak-check` | secret 值出现在日志/metrics/span |
| metrics contract | `make metrics-contract-check` | 指标命名不符合 `foundationx_<module>_<op>_<measure>` |
| health JSON schema | `go test -run TestHealthSchema ./...` | health 输出不符合 schema |

---

## 21. Upgrade Compatibility

| 变更类型 | 版本升级 | 迁移方式 |
|----------|----------|----------|
| Logger / Meter / Tracer interface 变更 | **major** | 发布迁移指南，提供兼容适配层（旧接口 wrapper 到新接口），所有消费者需在下一个 minor 版本内完成迁移 |
| 字段规范变更（新增/删除必填字段） | **minor** + changelog | 新字段设为可选（带默认值），旧字段标记 deprecated 保留两个版本后移除；消费者按 changelog 同步更新日志/metrics 输出 |
| 新增可选配置字段 | patch / minor | 无需迁移，新字段带默认值，旧配置继续工作 |
| 新增必填配置字段 | **minor**（带默认值） | 提供默认值，旧配置不修改可继续运行；默认值在 changelog 中说明 |
| 修复 bug | **patch** | 无需迁移 |

---

## 22. Release DoD

- [ ] 所有公共接口有 godoc 注释
- [ ] 所有公共类型有示例代码（`example_test.go`）
- [ ] CHANGELOG.md 已更新
- [ ] README.md 包含：模块定位、快速开始、配置说明、API 概览
- [ ] 单元测试覆盖率 ≥ 80%
- [ ] `-race` 测试通过
- [ ] Benchmark 结果无 > 10% 回退
- [ ] `go vet` 无警告
- [ ] `golangci-lint` 无错误
- [ ] label policy check 通过
- [ ] redaction leak check 通过
- [ ] metrics contract check 通过
- [ ] Secret 扫描通过
- [ ] 公共 API 无破坏性变更（或已 bump major）
- [ ] 所有 Functional Requirements 有对应测试
- [ ] 所有 Edge Cases 有对应测试

---

## 23. Open Questions

### Blocking（阻塞开发）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| — | 无 | — | — |

### Non-blocking（不阻塞开发）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-001 | 是否需要支持自定义 redaction 模式（用户自定义 secret 正则）？ | 待评估 | ZoneCNH |
| OQ-002 | tracing 采样率是否需要支持运行时动态调整？ | 待评估 | ZoneCNH |
| OQ-003 | health JSON schema 是否需要支持自定义字段扩展？ | 待评估 | ZoneCNH |

### Future（未来考虑）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-004 | 是否需要支持 metrics 聚合上报（批量发送减少网络开销）？ | 待评估 | — |
