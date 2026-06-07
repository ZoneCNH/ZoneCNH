# observex 完整规格

> Foundation L1 运行时契约。vendor-neutral 日志、指标、追踪、健康与脱敏契约。

最后更新：2026-06-07

---

## 1. 定位

`observex` 是可观测底座，统一日志、指标、追踪和跨模块观测上下文。

### 核心职责

- structured logging
- metrics registry / exporter
- tracing / span / baggage / context propagation
- trace_id、span_id、component、module、operation、error_code 字段规范
- OpenTelemetry 兼容层
- 采样策略
- 脱敏策略
- 测试 exporter
- label policy checker
- redaction leak checker
- metrics contract（指标命名规范检查）
- health JSON schema
- memory recorder contract

### 明确不做

- 不做告警升级（告警策略属于 `alertx`）
- 不做业务判断
- 不决定风控放行
- 不应把业务状态写死为 metrics 或 log 的强制枚举
- 不做 Prometheus/Otel/Zap 直接绑定

---

## 2. 接口契约

### 2.1 Logger

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

### 2.2 Meter

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

### 2.3 Tracer

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

### 2.4 Exporter

```go
type Exporter interface {
    ExportLogs(ctx context.Context, entries []LogEntry) error
    ExportMetrics(ctx context.Context, metrics []MetricPoint) error
    ExportSpans(ctx context.Context, spans []SpanData) error
    Shutdown(ctx context.Context) error
}
```

### 2.5 契约约束

- `Logger` 的实现必须是并发安全的
- `Meter` 的实现必须控制 label 基数，高基数 label 应被拒绝或截断
- `Tracer` 必须从 `context.Context` 传播 `trace_id` / `span_id`
- `Exporter.Shutdown` 必须 flush 缓冲区
- `With` 返回新实例，不修改原 logger（不变性）

### 2.6 Label Policy

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

### 2.7 指标命名规范

```
foundationx_<module>_<operation>_<measure>

示例：
  foundationx_kernel_module_start_duration
  foundationx_configx_load_duration
  foundationx_resiliencx_retry_attempts
  foundationx_schedulex_job_triggered
```

---

## 3. 目录结构

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

## 4. 依赖

### 4.1 go.mod

```
module github.com/ZoneCNH/observex

go 1.23
```

### 4.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| kernel（L0 原语） | configx, resiliencx, schedulex |
| stdlib | testkitx（仅 test） |
| OTel SDK（可选） | 所有业务域实现 |

### 4.3 foundationx 兼容

- 当前状态：v0.1.0 remote（见 `ADR-foundationx-exit.md`）
- 计划：v0.4 前迁移到 kernel 原语（`errx.Kind` 替代 `foundationx.ErrorKind`，`healthx.Status` 替代 `foundationx.HealthStatus`）

---

## 5. CI Gate

### 5.1 通用 Gate

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

### 5.2 observex 专属 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| label policy check | `make label-policy-check` | 指标 label 不符合规范 |
| redaction leak check | `make redaction-leak-check` | secret 值出现在日志/metrics/span |
| metrics contract | `make metrics-contract-check` | 指标命名不符合 `foundationx_<module>_<op>_<measure>` |
| health JSON schema | `go test -run TestHealthSchema ./...` | health 输出不符合 schema |

---

## 6. 测试矩阵

### 6.1 单元测试

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

### 6.2 集成测试

| 场景 | 验证点 |
|------|--------|
| exporter 不可达降级 | exporter 返回错误 → 不影响业务 |

### 6.3 Benchmark

| 场景 | 目标 |
|------|------|
| 单条结构化日志写入 | < 5μs（不含 I/O flush） |
| metrics 记录（counter/histogram） | < 1μs |
| span 创建 + 结束 | < 2μs |

---

## 7. 性能预算

| 操作 | 目标 | 测量方式 |
|------|------|----------|
| 单条结构化日志写入 | < 5μs（不含 I/O flush） | benchmark test |
| metrics 记录（counter/histogram） | < 1μs | benchmark test |
| span 创建 + 结束 | < 2μs | benchmark test |
| 常驻内存 | < 10MB | profiling |

---

## 8. 可观测输出

| 类型 | 名称 | 说明 |
|------|------|------|
| metric | `observex.exporter.errors` | counter，exporter 发送失败次数 |
| metric | `observex.exporter.queue.size` | gauge，待发送队列大小 |
| metric | `observex.span.dropped` | counter，因采样或队列满丢弃的 span 数 |
| log | `observex.exporter.connected` | info，exporter 连接成功 |
| log | `observex.exporter.disconnected` | warn，exporter 连接断开 |
| log | `observex.exporter.fallback` | warn，降级到备用 exporter |

---

## 9. 故障模式

| 故障场景 | 降级行为 | 是否阻塞启动 |
|----------|----------|--------------|
| exporter 不可达 | **静默降级**：丢弃遥测数据但不影响业务，记录内部警告 | 否 |
| 日志写入失败 | **降级到 stderr**：确保最低可观测能力 | 否 |
| metrics buffer 满 | **丢弃最旧数据**：记录 dropped 计数 | 否 |

---

## 10. 安全要求

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

## 11. 配置 schema

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

## 12. 升级兼容

| 变更类型 | 版本升级 |
|----------|----------|
| Logger / Meter / Tracer interface 变更 | **major** |
| 字段规范变更 | **minor** + changelog（所有 emit 日志/metrics 的模块需同步更新） |
| 新增可选配置字段 | patch / minor |
| 新增必填配置字段 | **minor**（带默认值） |
| 修复 bug | **patch** |

---

## 13. 发布 DoD

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
