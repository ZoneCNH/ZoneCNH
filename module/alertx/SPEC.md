# alertx 规格

- Status: Approved
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-26
- Owner: ZoneCNH
- Layer: 横切 · 业务层消费者（见 ADR-001 D1）
- Version: v1.0.0
- Repository: [github.com/ZoneCNH/alertx](https://github.com/ZoneCNH/alertx)
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/observex`, `module/contracts`, `ADR-001-foundations.md`

> 架构基线已由 `ADR-001-foundations.md` 钉死：横切消费者（layer: business / domain: crosscut，单向下游依赖 observex + contracts）/ 双订阅 / YAML DSL 规则 / 首版 runtime tag v1.0.0。本 SPEC 据此展开 23 节。Status=Draft，待 Spec 阶段 arbiter gate pass 后自动翻 Approved。

---

## 1. 摘要

`alertx` 是横切层的告警引擎，订阅 observex 的指标/日志/追踪导出流与业务域状态事件，按 YAML 规则 DSL 评估并触发告警（去重、分级、路由到通知渠道）。alertx 是横切关注点，不属于任何业务域，只告警不决策。

```text
observex (metrics/logs/traces 导出流) + 业务域状态事件（contracts.AlertEvent）
  ↓ 双订阅
alertx（规则评估 → 去重抑制 → 分级 → 生命周期状态机）
  ↓
通知渠道（webhook / email / pagerduty，vendor-neutral Notifier 抽象）
```

### 1.1 核心职责

- 提供规则引擎：加载 YAML 规则 DSL，评估 observex 导出 + 业务事件 → 匹配规则
- 提供去重抑制：相同 DedupKey 在 SuppressWindow 内合并，避免告警风暴
- 提供分级路由：severity（critical/warning/info）映射通知渠道，vendor-neutral Notifier 抽象
- 提供生命周期：firing → pending → resolved → suppressed 状态机
- 提供健康导出：health.JSON 对齐 observex schema，自观测指标 `foundationx_alertx_*`
- 提供规则热加载：运行时重载规则文件无需重启

---

## 2. 问题与背景

告警需求分散在各业务域与可观测层，缺乏统一引擎，导致：

- **告警逻辑分散**：风控触发、策略异常、系统健康三类告警由各模块自行实现通知（riskx 直发 webhook、observex 输出无人消费），逻辑重复且不一致
- **无去重抑制**：同一条件在抖动场景下每秒触发 N 次通知（实测 exporter 队列饱和时每秒 10+ 告警），造成告警风暴淹没真实信号
- **通知渠道硬编码**：每个告警源直接绑定 webhook/email 实现，切换渠道需改代码，无法按 severity 路由（critical 应 page、info 只 log）
- **observex 输出无人消费**：observex 导出 LogEntry/MetricPoint/SpanData/HealthStatus，但无下游评估其阈值，系统健康问题依赖人工巡检
- **无跨模块关联**：同一 trace 跨模块的告警无法用 trace_id 串联，根因定位需人工拼接

---

## 3. 目标

- 提供规则引擎 `RuleEvaluator`，加载 YAML DSL 规则，评估输入事件流 → 匹配规则产出 `AlertEvent`（对应 FR-001）
- 提供去重抑制 `Deduper`，按 `DedupKey` + `SuppressWindow` 合并重复告警（FR-002）
- 提供 severity 分级，`critical`/`warning`/`info` 映射 I4-I5/I2-I3/I0-I1 事件等级（FR-003）
- 提供通知路由 `Notifier`，vendor-neutral 抽象，支持 webhook/email/pagerduty 渠道（FR-004）
- 提供生命周期状态机 `firing`/`pending`/`resolved`/`suppressed`（FR-005）
- 提供健康导出 `health.JSON` + 自观测指标 `foundationx_alertx_*`（FR-006）
- 提供规则热加载 `RuleStore`，运行时重载规则文件（FR-007）

---

## 4. 非目标

- 不做指标/日志/追踪的采集与导出（→ `observex`，observex 是 producer，alertx 是 consumer）
- 不做业务决策或风控放行（alertx 只告警不决策；决策由 riskx/orderx 负责）
- 不做自动修复（→ 各模块自身的 resiliencx 弹性策略；alertx 只通知，不执行恢复动作）
- 不直接绑定 Prometheus/PagerDuty SDK（通过 Notifier 接口抽象，vendor-neutral）
- 不做监控大盘可视化（→ 外部 dashboard；alertx 只产出告警事件与通知）

> 边界约束来源：[`docs/architecture/03-boundaries.md`](../../docs/architecture/03-boundaries.md) §横切边界（"observex/alertx：指标、追踪、日志、告警事件"）+ `ADR-001-foundations.md` D1。

---

## 5. 消费者

| 消费者 | 使用方式 |
|--------|----------|
| 运维/监控 | 接收 `Notifier` 路由的告警通知（webhook/email/pagerduty） |
| 业务域模块（riskx/strategyx） | 经 contracts.`AlertEvent` envelope 直接 emit 策略/风控类告警（双订阅的业务侧输入） |
| 下游订阅者（dashboard/incident manager） | 经 `AlertSink.SubscribeAlerts` 订阅告警事件流 |
| observex | alertx 实现 `Exporter` 接口消费 observex 导出（metrics/logs/traces） |
| composer | 在组合根拉起 alertx 独立进程，注入 observex + contracts 依赖 |

---

## 6. 功能需求

### FR-001: 规则引擎

WHEN 加载 YAML 规则文件且规则 DSL 语法合法
THEN 解析为 `[]contracts.AlertRule`，存入 `RuleStore`，记录 `foundationx_alertx_rules_loaded` gauge

WHEN 加载 YAML 规则文件且规则 DSL 语法非法（缺字段/类型错误/未知操作符）
THEN 返回 `ErrRuleInvalid`，进程启动阻塞（不可降级为 warn）

WHEN 输入事件到达 `RuleEvaluator.Evaluate(ctx, input)` 且匹配某规则 Condition
THEN 产出 `AlertEvent`（含 Source/Severity/Message/Context/TraceID/DedupKey）

WHEN 输入事件到达且不匹配任何启用规则
THEN 不产出 AlertEvent，记录 `foundationx_alertx_evaluations` counter

WHEN 规则 `Enabled = false`
THEN 该规则被跳过，不参与评估

### FR-002: 去重抑制

WHEN 新 AlertEvent 的 DedupKey 在 SuppressWindow 内已存在活跃告警
THEN 新事件状态置为 `suppressed`，不发送通知，递增 `foundationx_alertx_dedup_suppressed` counter

WHEN 新 AlertEvent 的 DedupKey 超出 SuppressWindow 或无活跃告警
THEN 事件状态置为 `firing`，进入通知流程

WHEN DedupKey 为空
THEN 由 alertx 按 (Source, subject) 派生默认 DedupKey

### FR-003: 分级

WHEN AlertEvent.Severity = `critical`（映射 I4-I5）
THEN 路由到所有配置的 paging-capable 渠道（pagerduty/webhook）

WHEN AlertEvent.Severity = `warning`（映射 I2-I3）
THEN 路由到通知渠道（email/webhook），不触发 paging

WHEN AlertEvent.Severity = `info`（映射 I0-I1）
THEN 仅记录日志，不调用任何通知渠道

### FR-004: 通知路由

WHEN `Notifier.Notify(ctx, event)` 被调用且 channel 配置可达
THEN 按 event.Severity 路由到对应渠道，发送通知，返回 nil

WHEN 通知发送失败（网络错误/渠道拒绝）
THEN 按指数退避重试（最多 3 次），全部失败后递增 `foundationx_alertx_notify_failed` counter 并返回 `ErrNotifyFailed`

WHEN 同一 AlertEvent 的通知已成功发送
THEN 不重复发送（通知幂等，由 DedupKey + event.ID 去重）

WHEN 配置了未知 channel ID
THEN 启动时规则校验失败，返回 `ErrChannelUnknown`，阻塞启动

### FR-005: 生命周期

WHEN AlertEvent 首次触发且通过去重
THEN 状态 = `firing`，记录 FiredAt，发送通知

WHEN 规则 Condition 持续匹配但因 SuppressWindow 被抑制
THEN 状态 = `suppressed`，不发送通知

WHEN 规则 Condition 不再匹配（恢复条件满足）
THEN 状态 = `resolved`，记录 ResolvedAt，按规则配置决定是否发送 resolve 通知

WHEN 规则 Condition 短暂抖动（flap）
THEN 在 pending 窗口内不立即触发 firing，避免抖动告警

### FR-006: 健康导出

WHEN 调用 `health.JSON()` 且 alertx 已完成初始化
THEN 输出符合 health JSON schema（ready/live/message/components 四字段，对齐 observex HealthStatus）

WHEN 任一通知渠道后端持续不可达
THEN 对应 component live=false，整体 ready=false，但不 panic

WHEN alertx 运行中
THEN 导出自观测指标：`foundationx_alertx_alerts_fired`(counter) / `_dedup_suppressed`(counter) / `_notify_failed`(counter) / `_rules_loaded`(gauge) / `_evaluations`(counter)

### FR-007: 规则热加载

WHEN 规则文件被修改且 `RuleStore` 检测到变更（fsnotify 或轮询）
THEN 重新加载规则，校验 DSL，校验通过则原子替换内存中的规则集

WHEN 热加载的规则 DSL 校验失败
THEN 保留旧规则集，记录 error 日志，递增 `foundationx_alertx_reload_failed` counter，不中断评估

WHEN 热加载成功
THEN 记录 `foundationx_alertx_rules_loaded` 更新为新规则数

---

## 7. 行为约束

| 编号 | 规则 | 违反时 |
|------|------|--------|
| BR-001 | 告警不丢失：评估产出的 AlertEvent 必须进入去重/通知流程，不得因内部错误静默丢弃 | 若丢弃，记 error 日志并递增 `foundationx_alertx_alerts_dropped` counter；CI gate（告警不丢失检查）阻塞 |
| BR-002 | 通知幂等：同一 DedupKey + event.ID 的通知最多发送一次 | 重复发送时记 warn 日志，CI gate（通知幂等检查）阻塞 |
| BR-003 | SuppressWindow 强制：规则未设 SuppressWindow 时使用全局默认值（非零），不允许零窗口导致告警风暴 | 零窗口规则在加载时被拒绝，返回 `ErrSuppressWindowZero` |
| BR-004 | 规则 DSL 校验失败必须阻塞启动 | 启动时返回 `ErrRuleInvalid`，进程退出码非零，不进入评估循环 |
| BR-005 | 通知渠道配置必须完整：规则引用的 channel ID 必须在配置中已定义 | 启动时返回 `ErrChannelUnknown`，阻塞启动 |
| BR-006 | severity 映射不可降级：critical 必须尝试 paging 渠道，不得因某渠道失败而降级为 warning 通知 | 降级行为记 error 日志，CI gate 阻塞 |
| BR-007 | 自观测指标命名必须符合 `foundationx_alertx_<measure>` | 命名不符时 metrics contract check 阻塞 CI |

---

## 8. 接口契约

```go
// RuleEvaluator 评估输入事件，匹配规则产出 AlertEvent。
type RuleEvaluator interface {
    // Evaluate 评估单个输入事件，返回匹配的 AlertEvent 切片（可能为空）。
    // input 是归一化的事件载体（observex 导出项或业务 AlertEvent）。
    Evaluate(ctx context.Context, input Event) ([]contracts.AlertEvent, error)
}

// Deduper 对 AlertEvent 去重抑制，决定是否进入通知流程。
type Deduper interface {
    // Check 返回经过去重决策后的 AlertEvent 及其最终 Status。
    // 若被抑制，返回 Status=suppressed 的副本。
    Check(ctx context.Context, event contracts.AlertEvent) (contracts.AlertEvent, error)
}

// Notifier 按 severity 路由并发送告警通知。vendor-neutral，渠道实现注入。
type Notifier interface {
    // Notify 发送告警通知。按 event.Severity 路由到配置的渠道。
    // 实现必须幂等（BR-002）并指数退避重试（FR-004）。
    Notify(ctx context.Context, event contracts.AlertEvent) error
}

// AlertStore 持久化告警实例生命周期状态。
type AlertStore interface {
    // Active 返回当前活跃（firing/pending）的告警实例，按 DedupKey 索引。
    Active(ctx context.Context) (map[string]contracts.AlertEvent, error)
    // Upsert 创建或更新告警实例。
    Upsert(ctx context.Context, event contracts.AlertEvent) error
    // Resolve 将告警实例标记为 resolved。
    Resolve(ctx context.Context, dedupKey string, at time.Time) error
}

// RuleStore 加载与热重载规则。实现 contracts.AlertRuleStore。
// 详见 contracts.AlertRuleStore（pkg/contracts/alert.go）。
```

> 所有接口遵循 CONSTITUTION §4.1：窄接口（≤7 方法）、`context.Context` 第一参数、`error` 最后返回值、编译期断言 `var _ Interface = (*impl)(nil)`。

---

## 9. 数据模型

| 类型 | 定义来源 | 关键字段 |
|------|----------|----------|
| `contracts.AlertEvent` | `pkg/contracts/alert.go` | ID/Source/Severity/Status/Message/Context/FiredAt/ResolvedAt(`*time.Time`)/TraceID/DedupKey |
| `contracts.AlertRule` | `pkg/contracts/alert.go` | ID/Name/Source/Severity/Condition/DedupKey/SuppressWindow/Channels/Enabled |
| `contracts.Severity` | `pkg/contracts/alert.go` | critical / warning / info |
| `contracts.AlertStatus` | `pkg/contracts/alert.go` | firing / pending / resolved / suppressed |
| `Event`（评估输入） | alertx 本地 | 归一化载体，包装 observex LogEntry/MetricPoint/SpanData 或业务 AlertEvent |
| `Notification` | alertx 本地 | EventID/Channel/Payload/SentAt/Attempts |

> 金额类字段使用 `decimalx`，不使用 `float64`（CONSTITUTION §4.2）。alertx 主要处理指标阈值与文本，涉及金额的场景（如 PnL 告警上下文）从源事件透传，不做算术。

---

## 10. 配置 Schema

```yaml
# alertx 配置（configx，每项有默认值）
rules_file: "/etc/alertx/rules.yaml"      # 规则 DSL 文件路径
suppress_window_default: "5m"             # 全局默认抑制窗口（BR-003）
reload_interval: "30s"                    # 规则热加载轮询间隔（FR-007）
health_port: 8080                         # health.JSON 导出端口（FR-006）

channels:                                 # 通知渠道配置（FR-004）
  webhook-ops:
    type: webhook
    url: "${ALERTX_WEBHOOK_URL}"          # 敏感：环境变量
    timeout: "10s"
  pagerduty:
    type: pagerduty
    routing_key: "${ALERTX_PD_ROUTING_KEY}" # 敏感：环境变量
  email:
    type: email
    smtp_host: "${ALERTX_SMTP_HOST}"
    from: "alertx@zonenh.io"

observability:
  metrics_prefix: "foundationx_alertx"    # 强制前缀（BR-007）
  log_level: "info"
```

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `rules_file` | `/etc/alertx/rules.yaml` | 规则 DSL 文件 |
| `suppress_window_default` | `5m` | 全局默认抑制窗口 |
| `reload_interval` | `30s` | 热加载轮询间隔 |
| `health_port` | `8080` | 健康导出端口 |
| `channels.*.url` | — | 敏感，环境变量注入（ALERTX_WEBHOOK_URL 等） |

> 敏感项（url/routing_key/smtp_host）必须经环境变量注入，不得硬编码（CONSTITUTION §9）。脱敏由 observex.Redactor 处理。

---

## 11. 错误处理

| 错误 | 触发条件 | 处理 | 错误码 |
|------|----------|------|--------|
| `ErrRuleInvalid` | 规则 DSL 校验失败（FR-001/BR-004） | 阻塞启动，退出码非零 | `ALERTX_RULE_INVALID` |
| `ErrChannelUnknown` | 规则引用未定义 channel（BR-005） | 阻塞启动 | `ALERTX_CHANNEL_UNKNOWN` |
| `ErrSuppressWindowZero` | 规则 SuppressWindow=0 且无默认（BR-003） | 阻塞启动 | `ALERTX_SUPPRESS_WINDOW_ZERO` |
| `ErrNotifyFailed` | 通知重试耗尽（FR-004） | 记 error，递增 counter，返回错误 | `ALERTX_NOTIFY_FAILED` |
| `ErrRuleLoadFailed` | 热加载失败（FR-007） | 保留旧规则，记 error，不中断 | `ALERTX_RULE_LOAD_FAILED` |
| `ErrStoreUnavailable` | AlertStore 不可达 | 告警降级为内存处理，记 warn | `ALERTX_STORE_UNAVAILABLE` |

> 所有 error 使用 sentinel + `%w` 包装，消息格式 `"alertx: <operation>: <detail>"`（CONSTITUTION §8.2）。errors.go 公共定义。

---

## 12. 边界情况

| 编号 | 场景 | 处理 | 对应 TC |
|------|------|------|---------|
| EC-001 | 空规则文件（0 条规则） | 启动成功，rules_loaded=0，评估无匹配 | TC-008 |
| EC-002 | 评估超时（单事件评估 >100ms） | 取消评估，记 warn，丢弃该事件结果 | TC-009 |
| EC-003 | 多 goroutine 并发触发同一 DedupKey | Deduper 并发安全，仅一个 firing | TC-010 |
| EC-004 | 通知渠道持续失败 | 指数退避 3 次，失败后记 error，不阻塞评估循环 | TC-011 |
| EC-005 | 规则 Condition 引用未知 metric | 规则校验阶段拒绝（若可静态检测），否则运行时该规则永不匹配 | TC-012 |
| EC-006 | 内存资源耗尽（告警积压） | AlertStore 达上限时拒绝新告警，记 error，递增 dropped counter | TC-013 |
| EC-007 | observex 导出流中断 | alertx 继续处理业务侧订阅，记 warn，health component 标 degraded | TC-014 |
| EC-008 | 规则热加载与评估并发 | 原子替换规则集（sync.RWMutex），评估用旧快照完成当前批次 | TC-015 |
| EC-009 | trace_id 缺失的业务事件 | DedupKey 派生忽略 trace_id，通知不带 trace 关联 | TC-016 |
| EC-010 | 进程收到 SIGTERM | 优雅关闭：flush 待发送通知，关闭 AlertStore，退出 | TC-017 |

---

## 13. 目录结构

```text
alertx/
├── cmd/alertx/main.go              # 独立进程入口（signal handling + graceful shutdown）
├── pkg/alertx/                     # 公开 API 面
│   ├── version.go                  # Version = "v1.0.0"
│   ├── client.go                   # Engine 工厂 + New
│   ├── evaluator.go                # RuleEvaluator 实现（FR-001）
│   ├── dedup.go                    # Deduper 实现（FR-002）
│   ├── notifier.go                 # Notifier 接口（FR-004）
│   ├── health.go                   # health.JSON（FR-006）
│   ├── errors.go                   # sentinel errors（§11）
│   ├── options.go labels.go        # 配置选项 + 指标标签
│   └── memory_*.go                 # 内存实现（单测用）
├── internal/
│   ├── channel/                    # webhook.go email.go pagerduty.go（通知渠道）
│   ├── subscribe/                  # observex 订阅 + 业务事件订阅（双订阅）
│   ├── config/                     # 规则 DSL 解析 + configx 集成
│   ├── store/                      # AlertStore 实现
│   └── tools/{apisnapshot,releasemanifest}/  # 代码生成工具（移植自 observex）
├── contracts/                      # public_api.snapshot + schema
├── examples/                       # basic/rule/webhook main.go + _test.go
├── testkit/                        # assert/fixture/golden（下游可复用）
├── scripts/                        # check_boundary/check_secrets/generate_manifest 等
├── release/manifest/               # 发布证据产物
├── docs/adr/                       # ADR-001 +
├── .github/workflows/              # ci/release/security/integration
├── Makefile                        # release-version/ci/release-check 链
├── Dockerfile                      # 独立进程容器化
└── go.mod                          # module github.com/ZoneCNH/alertx
```

> 测试与源同目录（`*_test.go`），testdata/ 放测试数据（CONSTITUTION §5.3）。cmd/ 是独立进程与 observex 库布局的关键差异。

---

## 14. 依赖

| 依赖 | 版本约束 | 用途 | 类型 |
|------|----------|------|------|
| `github.com/ZoneCNH/observex` | v0.3.1+ | 告警输入源（Exporter 接口消费 LogEntry/MetricPoint/SpanData） | 直接 |
| `github.com/ZoneCNH/contracts` | v1.6.0（待发，含 alert 契约） | AlertEvent/AlertRule/Severity/Port 接口 | 直接 |
| `github.com/ZoneCNH/kernel` | v1.0.0 | Deps 注入、原语 | 直接 |
| `github.com/ZoneCNH/configx` | v1.0.0 | typed Config + Validate | 直接 |
| `github.com/ZoneCNH/resiliencx` | v0.4.9 | 通知重试退避 | 直接 |
| `fsnotify` (或轮询) | — | 规则热加载文件监听（FR-007） | 第三方，经 spec 批准 |
| `gopkg.in/yaml.v3` | — | 规则 DSL 解析 | 第三方，经 spec 批准 |

> 第三方依赖须在 §15 测试矩阵中验证不引入安全漏洞（govulncheck + gitleaks）。禁止反向依赖：alertx 不得被 observex/contracts/kernel 依赖（单向下游）。

---

## 15. 测试

### 15.1 测试矩阵

| TC | FR/BR | 类型 | 场景 | 期望结果 |
|----|-------|------|------|----------|
| TC-001 | FR-001 | 单元 | 合法 YAML 加载 | rules_loaded gauge 正确 |
| TC-002 | FR-001 | 单元 | 非法 DSL 加载 | 返回 ErrRuleInvalid |
| TC-003 | FR-001 | 单元 | 事件匹配规则 | 产出 AlertEvent |
| TC-004 | FR-002 | 单元 | DedupKey 窗口内重复 | Status=suppressed |
| TC-005 | FR-003 | 单元 | severity 路由 | critical→paging 渠道 |
| TC-006 | FR-004 | 单元 | 通知失败重试 | 指数退避 3 次 |
| TC-007 | FR-005 | 单元 | 状态机 firing→resolved | ResolvedAt 记录 |
| TC-008 | EC-001 | 单元 | 空规则文件 | 启动成功 |
| TC-009 | EC-002 | 单元 | 评估超时 | 取消 + warn |
| TC-010 | EC-003 | 单元(-race) | 并发同 DedupKey | 仅一个 firing |
| TC-011 | EC-004 | 单元 | 渠道持续失败 | 不阻塞评估 |
| TC-012 | EC-005 | 单元 | 未知 metric 引用 | 运行时不匹配 |
| TC-013 | EC-006 | 单元 | 内存耗尽 | dropped counter |
| TC-014 | EC-007 | 集成 | observex 中断 | health degraded |
| TC-015 | EC-008 | 单元(-race) | 热加载并发 | 原子替换 |
| TC-016 | EC-009 | 单元 | trace_id 缺失 | DedupKey 正常派生 |
| TC-017 | EC-010 | 集成 | SIGTERM | 优雅关闭 |
| TC-018 | FR-006 | 单元 | health.JSON | 四字段 schema |
| TC-019 | FR-007 | 单元 | 规则热加载 | rules_loaded 更新 |
| TC-020 | BR-001/002 | 集成 | AT-007 横切贯穿 | 告警不丢失+幂等 |

### 15.2 验收标准（AC）

| AC 编号 | 对应需求 | 验收条件 |
|---------|----------|----------|
| AC-001 | §6 FR-001 | 合法 YAML 规则加载为 AlertRule 切片；非法 DSL 返回 ErrRuleInvalid 并阻塞启动；事件匹配规则产出 AlertEvent |
| AC-002 | §6 FR-002 | 同 DedupKey 在 SuppressWindow 内的重复告警被抑制（Status=suppressed）；空 DedupKey 由 alertx 派生 |
| AC-003 | §6 FR-003 | critical 路由 paging 渠道；warning 路由通知不 paging；info 仅记日志不通知 |
| AC-004 | §6 FR-004 | 通知按 severity 路由；失败指数退避重试 3 次；通知幂等（同 event.ID 不重复发送） |
| AC-005 | §6 FR-005 | 状态机 firing→suppressed→resolved 正确流转；抖动场景 pending 窗口生效；ResolvedAt 记录 |
| AC-006 | §6 FR-006 | health.JSON 输出 ready/live/message/components 四字段；渠道不可达时 component live=false 不 panic；自观测指标命名 foundationx_alertx_* |
| AC-007 | §6 FR-007 | 规则文件变更触发热加载；校验通过则原子替换；校验失败保留旧规则集不中断 |
| AC-008 | §7 BR-001 | 评估产出的 AlertEvent 不丢失（dropped counter 监控）；CI alert-no-loss-check 通过 |
| AC-009 | §7 BR-002 | 通知幂等：同 DedupKey+event.ID 最多发送一次；CI notify-idempotent-check 通过 |
| AC-010 | §7 BR-003 | 零 SuppressWindow 规则被拒绝（用全局默认）；SuppressWindow 强制非零 |
| AC-011 | §7 BR-004 | DSL 校验失败阻塞启动（退出码非零），不进入评估循环 |
| AC-012 | §7 BR-005 | 规则引用未定义 channel 启动时返回 ErrChannelUnknown 阻塞 |
| AC-013 | §7 BR-006 | critical 必须尝试 paging，不因渠道失败降级为 warning |
| AC-014 | §7 BR-007 | 指标命名符合 foundationx_alertx_\<measure\>；CI metrics-contract-check 通过 |
| AC-015 | §12 EC-010 | SIGTERM 触发优雅关闭：flush 待发送通知，关闭 AlertStore，干净退出 |

### 15.3 覆盖率与工具

- 单元覆盖率 ≥ 80%（CONSTITUTION §5.1，L1 运行时分级）
- 公共接口覆盖率 100%、错误路径覆盖率 100%
- `-race` 必须通过（CONSTITUTION §5.2）
- 三段式命名 `TestFunc_Scenario_ExpectedBehavior`（CONSTITUTION §5.3）
- Benchmark：规则评估延迟（§17 性能预算守护）
- 集成测试 `//go:build integration`：AT-007 横切贯穿（alertx 收事件+通知+trace ID+多模块并发不丢）
- Soak ≥ 10min：常驻引擎，监控内存/goroutine 泄漏
- Fuzz：规则 DSL 解析函数补 `*_fuzz_test.go`（CI `-fuzztime=30s`）

---

## 16. 性能预算

| 操作 | 目标 | 条件 | 测量方式 |
|------|------|------|----------|
| 规则评估（单事件） | < 1ms | 100 条规则 | Benchmark |
| 告警端到端（评估→通知） | < 100ms | 单渠道 webhook | 集成测试计时 |
| 通知重试退避 | 指数 1s/2s/4s | 渠道不可达 | 单元测试 |
| 规则热加载 | < 50ms | 100 条规则 | 单元测试 |
| 内存占用（10k 活跃告警） | < 100MB | AlertStore in-memory | Soak |

> 性能预算由 Benchmark + Soak 守护，PR 须附 Benchmark 结果，回归 >10% 阻塞合并。

---

## 17. 可观测性

### 17.1 自观测指标（`foundationx_alertx_*`）

| 指标 | 类型 | 说明 |
|------|------|------|
| `foundationx_alertx_alerts_fired` | counter | 触发的告警数（firing 状态） |
| `foundationx_alertx_dedup_suppressed` | counter | 被去重抑制的告警数 |
| `foundationx_alertx_notify_failed` | counter | 通知失败次数 |
| `foundationx_alertx_rules_loaded` | gauge | 已加载规则数 |
| `foundationx_alertx_evaluations` | counter | 规则评估总次数 |
| `foundationx_alertx_alerts_dropped` | counter | 丢弃的告警数（BR-001 监控） |
| `foundationx_alertx_reload_failed` | counter | 热加载失败次数 |

### 17.2 日志与脱敏

- 结构化日志（zap/slog），`logger.With(...)` 子 logger
- 敏感字段（webhook url/routing key/smtp host）必须经 observex.Redactor 脱敏（CONSTITUTION §6.4）
- 告警 Context 透传时，producer 负责脱敏，alertx 不二次处理

### 17.3 Tracing

- 评估→去重→通知链路用 observex span 关联，trace_id 从输入事件继承
- 跨订阅源（observex/业务）的告警用 trace_id 串联

---

## 18. 安全

| 项 | 要求 |
|----|------|
| 硬编码 secret | 禁止。webhook url/routing key/smtp host 必须环境变量注入，gitleaks detect --no-git 零命中 |
| 日志脱敏 | 敏感字段经 observex.Redactor（§17.2） |
| 输入校验 | 规则 DSL 严格 schema 校验；AlertEvent Context 值长度限制（防 OOM） |
| 通知 payload | webhook payload 不含 secret；email 不在标题放敏感数据 |
| 依赖安全 | govulncheck 零漏洞（CI security gate） |

---

## 19. CI Gate

### 19.1 通用 Gate（不可改，CONSTITUTION §20.1）

- `build`：`go build ./...`
- `test`：`go test ./...`
- `race`：`go test -race ./...`（必须通过）
- `coverage`：覆盖率 ≥ 80%，`< 80% 阻塞合并`
- `vet`：`go vet ./...`
- `lint`：`golangci-lint run`（errcheck/govet/staticcheck/gocyclo≤15）
- `tidy`：`go mod tidy` 无 diff
- `gitleaks`：secret 扫描零命中
- `bench`：Benchmark 无 >10% 回退

### 19.2 alertx 专属 Gate

- `rule-dsl-check`：规则 DSL schema + 语义校验（BR-003/004/005）
- `notify-idempotent-check`：通知幂等性检查（BR-002）
- `alert-no-loss-check`：告警不丢失检查（BR-001）
- `metrics-contract-check`：指标命名 `foundationx_alertx_*`（BR-007）

---

## 20. 升级兼容性

| 变更类型 | 分类 | 流程 |
|----------|------|------|
| 新增 FR/规则操作符 | MINOR（向后兼容） | Spec-Version minor bump，无需迁移 |
| AlertEvent 字段新增（可选） | MINOR | 默认零值，旧消费者兼容 |
| Severity 常量值变更 | MAJOR（Breaking） | 必须走 contracts BR-010 兼容层 + 迁移指南 |
| Notifier 接口方法变更 | MAJOR（Breaking） | §10.2 迁移步骤，alertx 自实现可控制面 |
| 规则 DSL 语法变更 | MAJOR（Breaking） | 旧规则文件须转换，提供迁移工具 |

> Spec-Version（v1.0.0）与 Runtime-Version（v1.0.0 tag）双轴独立（CONSTITUTION §10.4.1），首版对齐，后续独立演进。版本只升不降。

---

## 21. 发布 DoD

- [ ] 所有 FR（FR-001~007）有对应 TC 且全部 PASS
- [ ] 所有 BR（BR-001~007）有 CI gate 守护
- [ ] 单元覆盖率 ≥ 80%，公共接口 + 错误路径 100%
- [ ] `-race` 零 data race
- [ ] Benchmark 满足 §16 性能预算
- [ ] AT-007 横切贯穿集成测试 PASS
- [ ] Soak ≥ 10min 无内存/goroutine 泄漏
- [ ] build/vet/lint/tidy 全绿
- [ ] 无硬编码 secret，gitleaks 零命中
- [ ] godoc 完整（所有导出声明注释）
- [ ] README + CHANGELOG 含 v1.0.0 heading
- [ ] `pkg/alertx/version.go` Version = v1.0.0
- [ ] `release/manifest/v1.0.0.json` + sha256（11 checks passed）
- [ ] git tag v1.0.0 + GitHub Release 发布
- [ ] registry.yaml lifecycle=active，依赖（contracts v1.6.0/observex v0.3.1+）已发

---

## 22. 待解决问题

### Blocking（开发前必须解决）

（无 — ADR-001-foundations.md 已闭合全部 Blocking 项）

### Non-blocking

- [ ] AlertStore 持久化后端选型（in-memory / Redis / Postgres）：首版用 in-memory，后续按 Soak 结果决定
- [ ] 规则 DSL 是否支持聚合窗口（如 "5 分钟内 metric 均值 > X"）：首版仅支持瞬时值，聚合列为 Future

### Future

- [ ] 告警分组与关联（同一 incident 的多个告警聚合展示）
- [ ] 告警静默维护窗口（planned maintenance 期间抑制）
- [ ] 基于 ML 的告警异常检测（替代静态阈值）

---

## 23. 变更历史

| 日期 | Spec-Version | Runtime Tag | 变更 |
|------|--------------|-------------|------|
| 2026-06-26 | v1.0.0 | v1.0.0（待发） | 初始 23 节规格；ADR-001 钉死架构基线；contracts alert 契约落地 |

> 版本轴映射：Spec-Version（本文档版本）与 Runtime Tag（git tag / pkg/alertx/version.go）双轴独立（CONSTITUTION §10.4.1）。首版对齐 v1.0.0。
