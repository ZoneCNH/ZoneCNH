# observex 完整规格

> Foundation L1 运行时契约。vendor-neutral 日志、指标、追踪、健康与脱敏契约。

最后更新：2026-06-07

---

## 1. Metadata

- Status: Active
- Owner: ZoneCNH
- Layer: L1 基础能力
- Version: v0.7.3
- Repository: [github.com/ZoneCNH/observex](https://github.com/ZoneCNH/observex)
- Related: [CONSTITUTION.md](../CONSTITUTION.md), [ARCHITECTURE.md](../ARCHITECTURE.md)

---

## 2. Summary

`observex` 是可观测底座，统一日志、指标、追踪和跨模块观测上下文。vendor-neutral 设计，通过接口契约屏蔽底层实现（OTel、Prometheus、Zap 等）。

---

## 3. Problem

70+ 模块各自接入可观测框架，接口不统一、字段不规范、脱敏缺失，导致：

- 日志格式不一致，跨模块关联困难
- 指标命名不规范，label 高基数导致 Prometheus OOM
- 追踪上下文丢失，跨模块调用链断裂
- secret 值泄露到日志/metrics/span 中
- 切换 exporter 需要修改所有模块代码

---

## 4. Goals

- 统一 Logger / Meter / Tracer 接口，vendor-neutral
- 标准字段规范：trace_id、span_id、component、module、operation、error_code
- 指标命名规范：`foundationx_<module>_<operation>_<measure>`
- label policy 控制（白名单 + 高基数禁止列表）
- 日志/metrics 脱敏策略
- health JSON schema 输出
- 测试 exporter 用于模块单测

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
THEN 拒绝记录或自动截断

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
THEN 拒绝记录，返回错误或 warning

### FR-007: Health

WHEN 调用 `health.JSON()` 输出
THEN 符合 health JSON schema（ready、live、message、components）

---

## 8. Business Rules

| 编号 | 规则 |
|------|------|
| BR-001 | Logger 实现必须并发安全 |
| BR-002 | Meter 实现必须控制 label 基数，高基数 label 被拒绝或截断 |
| BR-003 | Tracer 必须从 context.Context 传播 trace_id / span_id |
| BR-004 | Exporter.Shutdown 必须 flush 缓冲区 |
| BR-005 | With 返回新实例，不修改原 Logger（不变性） |
| BR-006 | 指标命名必须符合 `foundationx_<module>_<op>_<measure>` |
| BR-007 | 日志中 secret 字段必须自动脱敏 |
| BR-008 | 不直接绑定 Prometheus/Otel/Zap，通过 Exporter 接口抽象 |

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

---

## 12. Error Handling

| 错误 | 调用方处理 |
|------|-----------|
| `ErrExporterFailed` | 检查 exporter 端点连通性，降级到 noop exporter |
| `ErrLabelForbidden` | 检查 label 名，使用 AllowedLabels 中的替代 |
| `ErrBufferFull` | 增大 buffer 或降低采集频率 |
| `ErrShutdownFailed` | 检查 exporter 连接状态；若连接未关闭，执行手动清理 |

**错误消息格式：** `"observex: <operation>: <detail>"`
**错误包装：** 使用 `%w` 保留底层错误链

---

## 13. Edge Cases

| 场景 | 预期行为 |
|------|----------|
| exporter 不可达 | 静默降级，丢弃遥测数据，不影响业务 |
| 日志写入失败 | 降级到 stderr |
| metrics buffer 满 | 丢弃最旧数据，记录 dropped 计数 |
| 高基数 label 爆炸 | label policy checker 拒绝或截断 |
| secret 值传入日志字段 | 自动脱敏为 `***` |
| With(nil fields) | 返回原实例（不变性） |
| 并发调用 Logger + Exporter | 无 data race（-race 测试通过） |
| tracing context 跨 goroutine | 保持同一 trace_id |
| 采样率 = 0 | 不采样任何 span，但不报错 |

---

## 14. Directory Structure

```
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

```
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

- 当前状态：v0.1.0 remote（见 `ADR-foundationx-exit.md`）
- 计划：v0.4 前迁移到 kernel 原语（`errx.Kind` 替代 `foundationx.ErrorKind`，`healthx.Status` 替代 `foundationx.HealthStatus`）

---

## 16. Testing

### 16.1 单元测试

| 测试场景 | 验证点 |
|----------|--------|
| 结构化日志字段 | `Info("msg", Field{...})` 输出 JSON |
| log level 过滤 | level=info → debug 日志不输出 |
| logger.With 不变性 | `With` 返回新实例，不修改原 logger |
| metrics 注册 | counter/histogram/gauge 创建和记录 |
| label 基数控制 | 高基数 label 被拒绝 |
| span 创建 + 结束 | trace_id / span_id 正确传播 |
| context 传播 | 跨 goroutine 保持同一 trace |
| redaction | secret 字段被替换为 `***` |
| label policy | forbidden label 被拒绝 |
| health schema | 输出符合 JSON schema |

### 16.2 Given/When/Then 用例

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

### 16.3 Benchmark

| 场景 | 目标 |
|------|------|
| 单条结构化日志写入 | < 5μs（不含 I/O flush） |
| metrics 记录（counter/histogram） | < 1μs |
| span 创建 + 结束 | < 2μs |

### 16.4 集成测试

| 场景 | 验证点 |
|------|--------|
| exporter 不可达降级 | exporter 返回错误 → 不影响业务 |
| 完整链路 | Logger + Meter + Tracer + Exporter 端到端 |

---

## 17. Performance Budget

| 操作 | 目标 | 测量方式 |
|------|------|----------|
| 单条结构化日志写入 | < 5μs（不含 I/O flush） | benchmark test |
| metrics 记录（counter/histogram） | < 1μs | benchmark test |
| span 创建 + 结束 | < 2μs | benchmark test |
| 常驻内存 | < 10MB | profiling |

---

## 18. Observability

| 类型 | 名称 | 说明 |
|------|------|------|
| metric | `observex.exporter.errors` | counter，exporter 发送失败次数 |
| metric | `observex.exporter.queue.size` | gauge，待发送队列大小 |
| metric | `observex.span.dropped` | counter，因采样或队列满丢弃的 span 数 |
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

```
(?i)(password|passwd|secret|token|api[_-]?key|access[_-]?key|private[_-]?key|credential|auth)
```

---

## 20. CI Gate

### 20.1 通用 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 任何测试失败或 data race |
| 覆盖率 | `go test ./... -coverprofile=cover.out && go tool cover -func=cover.out` | 总覆盖率 < 80% |
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

| 变更类型 | 版本升级 |
|----------|----------|
| Logger / Meter / Tracer interface 变更 | **major** |
| 字段规范变更 | **minor** + changelog（所有 emit 日志/metrics 的模块需同步更新） |
| 新增可选配置字段 | patch / minor |
| 新增必填配置字段 | **minor**（带默认值） |
| 修复 bug | **patch** |

---

## 22. Release DoD

- [ ] 所有公共接口有 godoc 注释
- [ ] 所有公共类型有示例代码
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

- 是否需要支持自定义 redaction 模式（用户自定义 secret 正则）？
- 是否需要支持 metrics 聚合上报（批量发送减少网络开销）？
- tracing 采样率是否需要支持运行时动态调整？
- health JSON schema 是否需要支持自定义字段扩展？
