# bootstrap 规格

- Status: Draft
- Spec-Version: v0.1.2
- Last-Created: 2026-06-17
- Layer: L1 基础能力
- Version: v0.1.0-runtime / v0.1.2-spec
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `kernel`, `configx`, `observex`, `resiliencx`

> 本文件发布 bootstrap L1 进程启动组装层的规格基线，不引入运行时代码。后续实现进入独立仓库 `github.com/ZoneCNH/bootstrap`。对齐 [数据域基础架构报告 §十三](../../docs/report/data-domain-infrastructure-20260617.md) 与 [Bootstrap SOP](../../docs/sre/data-domain-bootstrap.md)。

---

## 1. 摘要

`bootstrap` 是 L1 通用进程组装层。它封装所有数据域进程（23 adapter + 2 聚合层 + 未来分析域/决策域）共有的 **configx 加载 + observex 初始化 + lifecycx 生命周期编排**，存储适配器作为聚合层的可选件按位掩码启用。

服务 main 从 ~150 行裸胶水（裸 `signal.NotifyContext` + 手动 config 加载 + 手动 lifecycle）降到 **5-8 行**：

```go
app, _ := bootstrap.Build(ctx, bootstrap.Spec{Module: "binance", Stores: bootstrap.None})
defer app.Shutdown(ctx)
// 注入 app.Observe / app.Stores 到 client/server
app.Run(ctx)
```

## 2. 问题与背景

70+ 服务的 main 各自组装 configx/observex/lifecycx，导致：

- 同样的 config 加载 + observex 初始化 + lifecycle 编排胶水在 25+ 进程逐字复制
- `kernel.lifecycx` 已有 `Component`/`Manager` 抽象（顺序启动+逆序停止+失败回滚），但没有串联层把它和 configx/observex 接通
- 生命周期处理不统一（有的裸 signal，有的 partial lifecycle），重启/关闭行为不一致
- adapter 错误地 import 存储适配器（违反采集与落库解耦）

`bootstrap` 补齐这个串联层。

## 3. 目标

- 封装 configx 加载（FileSource + EnvSource + SecretString 脱敏）
- 封装 observex 初始化（Logger/Metrics/Tracer/Health，统一 label policy）
- 封装 lifecycx.Manager 编排（注册组件 → 顺序 Start → 等信号 → 逆序 Stop）
- 存储适配器作为可选件（`Spec.Stores` 位掩码；adapter `None`，聚合层 `All`）
- 封装 resiliencx 默认弹性策略
- 统一信号捕获与优雅关闭（对齐 kernel.shutdownx）

## 4. 非目标

### 4.1 What bootstrap OWNS

- `Build(ctx, Spec) (*App, error)` 入口：组装 config + observe + stores（按 Spec）+ lifecycle
- `App.Run(ctx)`：阻塞 + 信号捕获 + 逆序 Stop
- `App.Shutdown(ctx)`：显式关闭
- StoreSet 位掩码与 7 存储 Component 适配

### 4.2 What bootstrap MUST NOT own

- ❌ 不内置 admin HTTP server / metrics endpoint（各服务自己的事）
- ❌ 不内置 graceful shutdown 编排策略（用 kernel.shutdownx）
- ❌ 不内置连接池管理（kafkax/natsx 各自管理）
- ❌ 不承载领域语义（domain-market/domain-macro 归 L2.5）
- ❌ 不 import 业务域模块（binance/fred/…）
- ❌ 不起 HTTP/gRPC server（仅组装 Component，不起 `net.Listen`）

### 4.3 Governance boundary

`bootstrap` 是 L1 横切能力，与 configx/observex/resiliencx 平级。它只向下依赖基座（kernel/configx/observex/resiliencx + L2 存储适配器），不向上穿透到 L2.5 领域层或业务域。

## 5. 消费者

| 消费者 | 使用方式 | Stores |
| --- | --- | --- |
| 数据域 adapter（23） | `Build(Spec{Stores: None})` | 零存储 |
| 数据域聚合层（market-data/macro-data，2） | `Build(Spec{Stores: All})` | 全存储 |
| 未来分析域/决策域服务 | `Build(Spec{Stores: 按需})` | 按需 |

## 6. 功能需求

### FR-001: Build 入口

WHEN 调用 `Build(ctx, Spec)` 且 ctx 有效、Spec.Module 非空
THEN 返回初始化的 `*App`，内部完成：configx 加载 → observex 初始化 → stores 构造（按 Stores 位掩码）→ resiliencx 默认策略 → lifecycx.Manager 创建
AND metrics 计数 `bootstrap_build_total{module}` +1

WHEN 调用 `Build(ctx, Spec)` 且 Spec.Module 为空
THEN 返回 validation error

WHEN 调用 `Build(ctx, Spec)` 且 Spec.Stores 为 None
THEN `App.Stores` 为 nil（adapter 零存储，不构造任何存储适配器）

WHEN 调用 `Build(ctx, Spec)` 且 Spec.Stores 含某存储位
THEN 构造该存储适配器并注册进 Lifecycle

### FR-002: configx 加载

WHEN Build 执行 config 加载
THEN 必须使用 `configx.NewLoader` + `EnvFileSource(.env)` + `NewAllEnvSource("XGO_")`，经 `configx.New(ctx, Config)` 创建 Client
AND 所有 `*_PASSWORD`/`*_SECRET`/`*_KEY` 字段经 SecretString 自动脱敏

### FR-003: observex 初始化

WHEN Build 执行 observex 初始化
THEN 必须使用 `observex.New(ctx, Config)` 创建 Client，注入统一 label policy
AND App.Observe 暴露 Logger/Metrics/Tracer/Health 供服务使用

### FR-004: stores 可选构造

WHEN Spec.Stores 含 TD 位
THEN 构造 `taosx` adapter，注册进 Lifecycle，`App.Stores.TD` 可用

WHEN Spec.Stores 为 None
THEN 不构造任何存储 adapter，`App.Stores` 为 nil

（PG/Redis/Kafka/NATS/OSS/CH 同理，各位独立控制）

### FR-005: lifecycle 编排

WHEN 调用 `App.Run(ctx)`
THEN 注册的 Component 顺序 Start → 阻塞等待 SIGINT/SIGTERM → 逆序 Stop
AND 任一 Component Start 失败时回滚已启动的 Component

WHEN 调用 `App.Shutdown(ctx)`
THEN 逆序 Stop 所有已注册 Component，幂等（重复调用安全）

### FR-006: 组件注册

WHEN 服务 main 构造自己的 client/server 后
THEN 调用 `App.Lifecycle.Register(components...)` 注册进 Manager
AND 注册的 Component 必须实现 `lifecycx.Component`（Name/Start/Stop）

### FR-007: 信号捕获

WHEN 进程收到 SIGINT 或 SIGTERM
THEN Run 返回，触发逆序 Stop
AND 使用 `kernel.shutdownx` 语义，超时强制退出

### FR-008: EffectiveConfigHash 暴露

WHEN Build 完成
THEN `App.ConfigHash` 暴露 configx EffectiveConfigHash（SHA-256），用于启动日志与配置漂移排查

## 7. 行为规则

| ID | 规则 |
| --- | --- |
| BR-001 | bootstrap 不得 import domain-market/domain-macro/domainx/contracts（禁业务语义） |
| BR-002 | bootstrap 不得 import 任何数据域子模块（binance/fred/…）（禁采集逻辑） |
| BR-003 | bootstrap 不得起 HTTP/gRPC server（源码无 `net.Listen`） |
| BR-004 | bootstrap 只向下依赖 kernel/configx/observex/resiliencx/存储适配器，不向上 |
| BR-005 | adapter 进程的 Spec.Stores 必须为 None；App.Stores 为 nil |
| BR-006 | 仅聚合层（market-data/macro-data）的 Spec.Stores 可非 None |
| BR-007 | Spec.Stores 位掩码控制；未启用的存储不构造不连接 |
| BR-008 | 文档批准前不得新增运行时代码或依赖 |

## 8. 非功能需求

| ID | 类别 | 需求 |
| --- | --- | --- |
| NFR-001 | 职责单一 | 只做组装，不做业务/采集/领域逻辑 |
| NFR-002 | 稳定性 | v0.1.0 后 Build/Run/Shutdown 签名不破坏性变更 |
| NFR-003 | 边界纯净 | public API 不暴露 domain DTO / transport tag / storage tag |
| NFR-004 | 可观测 | Build/Shutdown 记录 observex metrics + 日志 |
| NFR-005 | 零存储默认 | Stores 默认 None；必须显式启用才连存储 |

## 9. 接口契约

### 9.1 公开类型

```go
package bootstrap

import (
    "context"
    "github.com/ZoneCNH/configx"
    "github.com/ZoneCNH/kernel/lifecycx"
    "github.com/ZoneCNH/observex"
    "github.com/ZoneCNH/resiliencx"
)

// Spec 描述一个进程的标准组件清单。
type Spec struct {
    Module    string          // 进程名，如 "binance" / "market-data"
    Stores    StoreSet        // 位掩码；adapter 传 None，聚合层传 All
    Hooks     []func(*App) error  // 可选 hook（注册自定义组件）
}

// StoreSet 是存储启用的位掩码。
type StoreSet uint8

const (
    None   StoreSet = 0
    TD     StoreSet = 1 << iota  // taosx
    PG                            // postgresx
    Redis                         // redisx
    Kafka                         // kafkax
    NATS                          // natsx
    OSS                           // ossx
    CH                            // clickhousex
    All    StoreSet = TD | PG | Redis | Kafka | NATS | OSS | CH
)

// App 是组装后的运行时句柄。
type App struct {
    Config     *configx.Client    // 仅供 Shutdown 时 Close；无业务 getter
    Observe    *observex.Client   // 仅供 Shutdown 时 Close；服务取 logger 自行 observex.New
    Stores     *Stores            // 按 Spec.Stores 启用的子集；None 时为 nil
    Resilience *resiliencx.Client // 仅供 Shutdown 时 Close
    Lifecycle  *lifecycx.Manager  // 统一 Start/Stop 编排
    ConfigHash string             // configx EffectiveConfigHash（启动日志用）
}

// Stores 持有启用的存储适配器（nil 字段表示未启用）。
type Stores struct {
    TD, PG, Redis, Kafka, NATS, OSS, CH interface{} // 各为对应 adapter 的 *Client
}
```

### 9.2 核心方法

```go
// Build 是唯一入口：config → observex → stores（按 Spec）→ resilience → lifecycle。
func Build(ctx context.Context, spec Spec) (*App, error)

// Run 阻塞直到 SIGINT/SIGTERM，然后逆序 Stop 所有 Component。
func (a *App) Run(ctx context.Context) error

// Shutdown 逆序 Stop 所有 Component（幂等）。
func (a *App) Shutdown(ctx context.Context) error
```

### 9.3 基座真实 API 对接（已查实）

bootstrap 内部调用以下**真实存在**的基座 API（非假设）：

| 基座 | 真实 API | 包路径 |
| --- | --- | --- |
| configx | `configx.NewLoader()` → `AddSource()` → `Load(ctx)` → `configx.New(ctx, Config)` | `github.com/ZoneCNH/configx` (`pkg/configx/`) |
| configx Source | `NewEnvFileSource(name)`, `NewAllEnvSource(prefix)` | 同上 |
| observex | `observex.New(ctx, Config, opts...) (*Client, error)` | `github.com/ZoneCNH/observex` (`pkg/observex/`) |
| resiliencx | `resiliencx.New(ctx, Config, opts...) (*Client, error)` | `github.com/ZoneCNH/resiliencx` (`pkg/resiliencx/`) |
| kernel lifecycx | `lifecycx.NewManager(components...)`, `Manager.Start/Stop(ctx)` | `github.com/ZoneCNH/kernel/lifecycx` |

> **已查实约束（OQ-001/OQ-003 已确认，2026-06-17）**：
>
> 1. **configx/observex/resiliencx Client 均无业务 getter**：三者 Client 只有 `Close(ctx)` + `HealthCheck(ctx)`，**没有** `Logger()`/`Metrics()`/`Tracer()` getter。因此 bootstrap **不试图从 Client 暴露内部 logger/metrics**——服务要可观测，自行 `observex.New`。bootstrap 只持有 Client 句柄做统一 Close。
>
> 2. **7 存储适配器未实现 `lifecycx.Component`**：全部有 `Close(ctx) error`，但都没有 `Start(ctx)` / `Name() string`。bootstrap 内部用 `closerComponent` wrapper 把 `*Client` + `Close` 适配成 `Component`（`Start` = no-op，`Stop` = `Close`），不改已发布的 7 个适配器。
>
> 3. **App 不暴露 Observe.Logger()**（取不到）。App 持有 `*observex.Client` 仅供 Shutdown 时 Close，不供服务取 logger。

## 10. 数据模型

### 10.1 StoreSet 位掩码

```go
// 7 个存储位，uint8 足够。
// adapter: None (0b0000000)
// 聚合层: All  (0b1111111)
// 可组合: TD | PG | Redis
```

### 10.2 公共错误

| 错误 | 触发 | 可重试 |
| --- | --- | --- |
| ErrEmptyModule | Spec.Module 为空 | 否 |
| ErrInvalidSpec | Spec 字段非法 | 否 |
| ErrStoreConstructFailed | 存储 adapter 构造失败 | 是（退避后重试 Build） |
| ErrLifecycleStartFailed | Component Start 失败 | 否（已回滚） |

## 11. 配置模式

bootstrap 自身的配置经 configx 加载，统一前缀 `XGO_`：

```bash
# 通用（所有进程）
XGO_{MODULE}_LOG_LEVEL=info
XGO_{MODULE}_METRICS_ADDR=:9091

# 聚合层额外（adapter 不持有）
XGO_{MODULE}_PG_HOST=...
XGO_{MODULE}_TD_HOST=...
# ...（详见 Bootstrap SOP §七）
```

## 12. 错误处理

| 场景 | 处理 |
| --- | --- |
| Build 时 configx 加载失败 | 返回 ErrConfigLoad，不构造后续 |
| Build 时 observex 初始化失败 | 返回 ErrObserveInit，关闭已建 configx |
| Build 时 store 构造失败 | 返回 ErrStoreConstructFailed，关闭已建组件 |
| Run 时 Component Start 失败 | 回滚已启动 Component，返回 errors.Join |
| Shutdown 时 Component Stop 失败 | 继续逆序 Stop 其余，errors.Join 返回 |

## 13. 边界情况

| 情况 | 处理 |
| --- | --- |
| ctx 为 nil | Build 返回 validation error |
| Spec.Stores = None + 服务试图访问 App.Stores | App.Stores 为 nil，服务访问会 nil panic（设计意图：adapter 不应访问存储） |
| 重复 Shutdown | 幂等，第二次返回 nil |
| SIGTERM 在 Build 期间 | Build 应检查 ctx.Err()，提前返回 |
| Stores 位掩码含未实现的存储 | 构造时返回 ErrUnsupportedStore |

## 14. 目录结构

```
github.com/ZoneCNH/bootstrap（独立仓库）
├── go.mod                         # module github.com/ZoneCNH/bootstrap
├── pkg/
│   └── bootstrap/
│       ├── doc.go
│       ├── bootstrap.go           # Build / Run / Shutdown
│       ├── spec.go                # Spec / StoreSet / App / Stores
│       ├── config.go              # configx 加载封装
│       ├── observe.go             # observex 初始化封装
│       ├── stores.go              # 7 存储 adapter 构造（按 StoreSet）
│       ├── lifecycle.go           # lifecycx.Manager 编排 + 信号捕获
│       ├── errors.go              # ErrEmptyModule 等
│       └── version.go
├── go.sum
├── README.md
└── scripts/
    └── boundary-gates.sh          # 5 道边界门禁（§20）
```

## 15. 依赖

### 15.1 go.mod

```go
module github.com/ZoneCNH/bootstrap

go 1.23

require (
    github.com/ZoneCNH/kernel        v1.0.0   // lifecycx, shutdownx
    github.com/ZoneCNH/configx       v1.0.0
    github.com/ZoneCNH/observex      v0.3.1
    github.com/ZoneCNH/resiliencx    v0.4.9
    // 过渡期依赖（见下方 ADR-foundationx-exit 迁移注记）
    github.com/ZoneCNH/foundationx   v0.1.1   // ⚠️ 仅 stores.go 用 SecretString 包 PG_PASSWORD
    // 存储适配器（按 Stores 位掩码构造，全部 require）
    github.com/ZoneCNH/taosx         v1.0.1
    github.com/ZoneCNH/postgresx     v1.0.0
    github.com/ZoneCNH/redisx        v1.0.1
    github.com/ZoneCNH/kafkax        v1.0.2
    github.com/ZoneCNH/natsx         v1.0.0
    github.com/ZoneCNH/ossx          v1.0.1   // ⚠️ 当前 0 源码，Stores.OSS 永远 nil
    github.com/ZoneCNH/clickhousex   v1.0.1
)
```

> **ADR-foundationx-exit 迁移注记**（OQ-004）：
> bootstrap 当前 `pkg/bootstrap/stores.go` 直接 import `github.com/ZoneCNH/foundationx/pkg/foundationx` 用 `SecretString` 脱敏 `XGO_<MODULE>_PG_PASSWORD`。这与本仓库 `module/ADR-foundationx-exit.md` 决定（foundationx 是过渡性依赖、新原语放 kernel）冲突。
> 迁移路径：v0.2.0 前必须把 `foundationx.SecretString` 替换为 `kernel/errx.RedactedString` 或 `configx` 本地脱敏类型，`go mod tidy` 后 go.mod 不再含 foundationx。CI 中已有规则 `grep -rn "foundationx" --include="*.go"` 不应新增 — bootstrap 是该规则的当前破例方，需在 v0.2.0 修复。

### 15.2 依赖方向

```
bootstrap (L1)
  ├─► kernel (L0): lifecycx, shutdownx
  ├─► configx (L1): NewLoader, Source, New
  ├─► observex (L1): New
  ├─► resiliencx (L1): New
  └─► L2 存储适配器: taosx/postgresx/redisx/kafkax/natsx/ossx/clickhousex
```

**禁止向上依赖**：不得 import domain-*、contracts、任何业务域模块。

## 16. 测试

| TC ID | 覆盖 FR | 场景 | 命令 |
| --- | --- | --- | --- |
| TC-BS-001 | FR-001 | Build 成功，Stores=None，App.Stores 为 nil | `go test -run TestBuildAdapter` |
| TC-BS-002 | FR-001 | Build 成功，Stores=All，App.Stores 全非 nil | `go test -run TestBuildAggregate` |
| TC-BS-003 | FR-001 | Spec.Module 为空 → ErrEmptyModule | `go test -run TestBuildEmptyModule` |
| TC-BS-004 | FR-004 | Stores=TD\|PG，仅构造 TD+PG，其余 nil | `go test -run TestBuildPartialStores` |
| TC-BS-005 | FR-005 | Run 收到 SIGTERM → 逆序 Stop | `go test -run TestRunShutdown` |
| TC-BS-006 | FR-005 | Component Start 失败 → 回滚 | `go test -run TestStartRollback` |
| TC-BS-007 | FR-005 | Shutdown 幂等（二次返回 nil） | `go test -run TestShutdownIdempotent` |
| TC-BS-008 | BR-001 | go.mod 无 domain-market/contracts | boundary-gate |
| TC-BS-009 | BR-005 | adapter Spec.Stores=None 编译期约束 | `go test -run TestAdapterZeroStore` |

## 17. 性能预算

| 指标 | 预算 |
| --- | --- |
| Build（Stores=None） | < 50ms |
| Build（Stores=All） | < 500ms（含 7 存储连接） |
| Run 信号→Stop 延迟 | < 100ms |
| Shutdown（7 存储） | < 5s（graceful drain） |

## 18. 可观测性

| 指标 | 类型 | label |
| --- | --- | --- |
| `bootstrap_build_total` | Counter | module, stores |
| `bootstrap_build_duration_ms` | Histogram | module |
| `bootstrap_shutdown_total` | Counter | module |
| `bootstrap_lifecycle_start_total` | Counter | module, component, result |
| `bootstrap_lifecycle_stop_total` | Counter | module, component, result |

## 19. 安全

- configx SecretString 自动脱敏所有 `*_PASSWORD`/`*_SECRET`/`*_KEY`
- bootstrap 不记录原始凭据，只记录 ConfigHash
- 存储连接凭据经 configx 加载，不硬编码

## 20. CI Gate

| 门禁 | 规则 | 校验 |
| --- | --- | --- |
| 禁业务语义 | go.mod 无 domain-market/domain-macro/domainx/contracts | `grep` 零命中 |
| 禁采集逻辑 | go.mod 无数据域子模块（binance/fred/…） | `grep` 零命中 |
| 禁 transport 实体 | 源码无 `net.Listen` | grep 零命中 |
| 依赖方向 | 只向下依赖 kernel/configx/observex/resiliencx/存储 | 依赖图扫描 |
| 组件可插拔 | Stores 位掩码控制 | TC-BS-004 |

## 21. 升级兼容性

- v0.1.0 冻结 Build/Run/Shutdown/Spec/App 签名
- StoreSet 位掩码新增存储位时用高位，不破坏现有位
- Stores struct 新增字段时为指针（nil=未启用），不破坏现有消费者

## 22. Release DoD

### v0.1.0（已发布 2026-06-17）

- [x] go build ./... 通过
- [x] go test ./... -race -count=1 全过（10 测试）
- [x] boundary-gates.sh 5 道全过
- [x] CHANGELOG + README
- [x] GitHub Release v0.1.0
- [x] `Stores=None` 路径端到端就绪（adapter 23 接入）

### v0.2.0 准入项（含 SPEC Approved）

- [ ] `Stores=All` 与位组合端到端冒烟（market-data 接入验证）
- [ ] foundationx 依赖移除（替换为 kernel/configx 原生脱敏，对齐 ADR-foundationx-exit）
- [ ] binance 接入验证（main.go ≤10 行）
- [ ] SPEC 经四源 ≥98 分门禁，状态从 Draft 转 Approved

## 23. 开放问题

| OQ | 问题 | 状态 | 结论 |
| --- | --- | --- | --- |
| OQ-001 | observex Client logger/metrics/tracer 私有无 getter | ✅ 已确认（2026-06-17） | configx/observex/resiliencx Client **均无业务 getter**（只有 Close/HealthCheck）。bootstrap 不暴露内部 logger，服务自行 observex.New。无需改基座。 |
| OQ-002 | 是否需要登记 FOUNDATION-DEPS.yaml？ | ✅ 已登记（2026-06-17） | bootstrap 已登记进 `module/FOUNDATION-DEPS.yaml` modules 与 allowed_deps 节，依赖方向：kernel/configx/observex/resiliencx + 6 存储。 |
| OQ-003 | 存储适配器是否已实现 lifecycx.Component？ | ✅ 已确认（2026-06-17） | 7 存储 adapter **未实现 Component**（有 Close 无 Start/Name）。bootstrap 用 `closerComponent` wrapper 适配，不改已发布适配器。 |
| OQ-004 | bootstrap 直 import foundationx 与 ADR-foundationx-exit 冲突 | Open（v0.2.0 修复） | `pkg/bootstrap/stores.go` 直接 import `foundationx.SecretString`。v0.2.0 必须迁移到 `kernel/errx.RedactedString` 或 configx 本地脱敏（详见 §15.1 迁移注记）。 |

---

## 发布状态

| 项目 | 状态 | 说明 |
| --- | --- | --- |
| SPEC | Draft | 本文件，待四源评分后转 Approved |
| Runtime implementation | Pending | 独立仓库 github.com/ZoneCNH/bootstrap，SPEC Approved 后进入 |
| FOUNDATION-DEPS 登记 | Pending | 需登记为 L1 模块 |

---

## 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-06-17 | v0.1.0 | 初始 SPEC：Build/Run/Shutdown + Spec/StoreSet/App + 7 存储 Component 适配 + 5 道边界门禁；基于 configx/observex/kernel 真实 API 对接 | ZoneCNH |
| 2026-06-17 | v0.1.1 | 实现前核实修正：确认 OQ-001（基座 Client 无业务 getter）/ OQ-003（存储适配器未实现 Component）；§9.3 改为 closerComponent wrapper 方案；App.Observe 标注仅供 Close | ZoneCNH |
| 2026-06-17 | v0.1.2 | 文档-代码漂移收口：§6 FR-004 标注 v0.1.0 stub 实现状态；§15.1 补声明 foundationx v0.1.1（runtime 实测）+ ossx 显式行 + ADR-foundationx-exit 迁移注记；§22 拆分 v0.1.0 已完成 / v0.2.0 准入；§23 OQ-002 翻 ✅ + 新增 OQ-004（foundationx 迁移） | ZoneCNH |
