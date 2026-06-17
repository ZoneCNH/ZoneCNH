# bootstrap 规格

- Status: Draft
- Spec-Version: v0.1.7
- Last-Updated: 2026-06-18
- Owner: ZoneCNH
- Layer: L1 基础能力
- Version: v0.1.0-runtime / v0.1.7-spec
- Repository: [github.com/ZoneCNH/bootstrap](https://github.com/ZoneCNH/bootstrap)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md), [module/FOUNDATION-DEPS.yaml](../FOUNDATION-DEPS.yaml), [module/ADR-foundationx-exit.md](../ADR-foundationx-exit.md), `kernel`, `configx`, `observex`, `resiliencx`

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
- 存储适配器作为可选件（`Spec.Stores` 位掩码；adapter `None`，聚合层 `Stable`）
- 封装 resiliencx 默认弹性策略
- 统一信号捕获与优雅关闭（对齐 kernel.shutdownx）

### 3.1 职责范围（bootstrap OWNS）

- `Build(ctx, Spec) (*App, error)` 入口：组装 config + observe + stores（按 Spec）+ lifecycle
- `App.Run(ctx)`：阻塞 + 信号捕获 + 逆序 Stop
- `App.Shutdown(ctx)`：显式关闭
- StoreSet 位掩码与存储 Component 适配

## 4. 非目标

> 下列事项明确不属于 bootstrap 职责，防止范围蔓延。每条标注"由谁负责"。

### 4.1 不内置的服务与策略

- ❌ 不内置 admin HTTP server / metrics endpoint —— 由各服务自己的入口负责
- ❌ 不内置 graceful shutdown 编排策略 —— 使用 `kernel.shutdownx`
- ❌ 不内置连接池管理 —— 由 `kafkax`/`natsx` 等存储适配器各自管理
- ❌ 不起 HTTP/gRPC server（仅组装 Component，源码无 `net.Listen`）

### 4.2 不承载的领域语义

- ❌ 不承载领域语义 —— `domain-market`/`domain-macro` 归 L2.5
- ❌ 不 import 业务域模块 —— `binance`/`fred`/… 由各自 adapter 仓库负责

### 4.3 治理边界

`bootstrap` 是 L1 横切能力，与 configx/observex/resiliencx 平级。它只向下依赖基座（kernel/configx/observex/resiliencx + L2 存储适配器），不向上穿透到 L2.5 领域层或业务域。

## 5. 消费者

| 消费者 | 使用方式 | Stores |
| --- | --- | --- |
| 数据域 adapter（23） | `Build(Spec{Stores: None})` | 零存储 |
| 数据域聚合层（market-data/macro-data，2） | `Build(Spec{Stores: Stable})` | 6 个稳定存储（不含 OSS，见 OQ-005） |
| 未来分析域/决策域服务 | `Build(Spec{Stores: 按需})` | 按需 |

## 6. 功能需求

### FR-001: Build 入口

WHEN 调用 `Build(ctx, Spec)` 且 ctx 有效、Spec.Module 非空
THEN 返回初始化的 `*App`，内部完成：configx 加载 → observex 初始化 → stores 构造（按 Stores 位掩码）→ resiliencx 默认策略 → lifecycx.Manager 创建

WHEN 调用 `Build(ctx, Spec)` 且 Spec.Module 为空
THEN 返回 validation error

WHEN 调用 `Build(ctx, Spec)` 且 Spec.Stores 为 None
THEN `App.Stores` 为 nil（adapter 零存储，不构造任何存储适配器）

WHEN 调用 `Build(ctx, Spec)` 且 Spec.Stores 含某存储位
THEN 构造该存储适配器并注册进 Lifecycle

**AC-001**：Build(Spec{Module:"binance", Stores:None}) 返回非 nil `*App`，nil error；App.Stores == nil。（→ TC-BS-001）

### FR-002: configx 加载

WHEN Build 执行 config 加载
THEN 必须使用 `configx.NewLoader` + `EnvFileSource(.env)` + `NewAllEnvSource("XGO_")`，经 `configx.New(ctx, Config)` 创建 Client
AND 所有 `*_PASSWORD`/`*_SECRET`/`*_KEY` 字段经 SecretString 自动脱敏

**AC-002**：Build 成功后 `App.Config` 非 nil；构造一个含 `XGO_TEST_PASSWORD` 的 .env，加载后日志/返回值中该字段为脱敏占位符而非明文。（→ TC-BS-010）

### FR-003: observex 初始化

WHEN Build 执行 observex 初始化
THEN 必须使用 `observex.New(ctx, Config, opts...)` 创建 Client，opts 注入统一 label policy
AND App.Observe 仅供 Shutdown 时 Close；服务取 logger 自行 `observex.New`（OQ-001：Client 无业务 getter）

**AC-003**：Build 成功后 `App.Observe` 非 nil 且类型为 `*observex.Client`；`HealthCheck(ctx)` 返回 nil。（→ TC-BS-011）

### FR-004: stores 可选构造

> **v0.1.0 实现状态**：runtime 仅 `Stores=None` 路径端到端就绪；任何非 None 位都返回 `ErrUnsupportedStore`。FR-004 完整目标态在 v0.2.0 准入（详见 §22）。下列 WHEN/THEN 描述目标态，与 §22 v0.2.0 准入项绑定。

WHEN Spec.Stores 含 TD 位
THEN 构造 `taosx` adapter，注册进 Lifecycle，`App.Stores.TD` 可用

WHEN Spec.Stores 为 None
THEN 不构造任何存储 adapter，`App.Stores` 为 nil

（PG/Redis/Kafka/NATS/CH 同理，各位独立控制；OSS 位详见 OQ-005。）

**AC-004**：Build(Spec{Stores: TD|PG}) 后 App.Stores.TD/App.Stores.PG 非 nil，其余位字段为 nil。（→ TC-BS-004）

### FR-005: lifecycle 编排

WHEN 调用 `App.Run(ctx)`
THEN 注册的 Component 顺序 Start → 阻塞等待 SIGINT/SIGTERM → 逆序 Stop
AND 任一 Component Start 失败时回滚已启动的 Component

WHEN 调用 `App.Shutdown(ctx)`
THEN 逆序 Stop 所有已注册 Component，幂等（重复调用安全）

**AC-005a**：Run 收到 SIGTERM 后 < 100ms 内全部 Component Stop 完成。（→ TC-BS-005）
**AC-005b**：Component Start 失败 → 已启动 Component 的 Stop 被调用，返回 errors.Join。（→ TC-BS-006）
**AC-005c**：连续两次 Shutdown，第二次返回 nil。（→ TC-BS-007）

### FR-006: 组件注册

WHEN 服务 main 构造自己的 client/server 后
THEN 调用 `App.Lifecycle.Register(components...)` 注册进 Manager
AND 注册的 Component 必须实现 `lifecycx.Component`（Name/Start/Stop）

**AC-006**：注册一个 stub Component，Run 后该 Component 的 Start 被调用且 Name() 匹配。（→ TC-BS-012）

### FR-007: 信号捕获

WHEN 进程收到 SIGINT 或 SIGTERM
THEN Run 返回，触发逆序 Stop
AND 使用 `kernel.shutdownx` 语义，超时强制退出

**AC-007**：Run 期间发 SIGTERM，Run 返回 nil，shutdownx 超时强制退出语义生效（可观测到 deadline）。（→ TC-BS-005，与 FR-005a 共用）

### FR-008: EffectiveConfigHash 暴露

WHEN Build 完成
THEN `App.ConfigHash` 暴露 configx EffectiveConfigHash（SHA-256），用于启动日志与配置漂移排查

**AC-008**：Build 成功后 App.ConfigHash 为 64 字符十六进制字符串；相同配置两次 Build 得到相同 hash，不同配置得到不同 hash。（→ TC-BS-013）

## 7. 行为规则

| ID | 规则 | 违反时 |
| --- | --- | --- |
| BR-001 | bootstrap 不得 import domain-market/domain-macro/domainx/contracts（禁业务语义） | CI Gate 禁业务语义项 fail；编译期 import 即被 xlibgate 阻断 |
| BR-002 | bootstrap 不得 import 任何数据域子模块（binance/fred/…）（禁采集逻辑） | CI Gate 禁采集逻辑项 fail；xlibgate 阻断 |
| BR-003 | bootstrap 不得起 HTTP/gRPC server（源码无 `net.Listen`） | CI Gate 禁 transport 实体项 fail |
| BR-004 | bootstrap 只向下依赖 kernel/configx/observex/resiliencx/存储适配器，不向上 | 依赖图扫描 fail；新增非法 import edge 被 FOUNDATION-DEPS 阻断 |
| BR-005 | adapter 进程的 Spec.Stores 必须为 None；App.Stores 为 nil | Build 入口 Spec.Module allowlist 校验拒绝；TC-BS-009 失败 |
| BR-006 | 仅聚合层（market-data/macro-data）的 Spec.Stores 可非 None | Build 入口 Spec.Module allowlist 校验拒绝非聚合层带存储位的 Spec |
| BR-007 | Spec.Stores 位掩码控制；未启用的存储不构造不连接 | 代码审查 + TC-BS-004 验证；构造了未启用位即 fail |
| BR-008 | 文档批准前不得新增运行时代码或依赖 | SPEC Status != Approved 时，runtime 仓库 PR 被 pipeline-arbiter gate 阻断 |
| BR-009 | bootstrap 不得 import foundationx（对齐 ADR-foundationx-exit） | CI Gate foundationx 零容忍项 fail；`grep -rn foundationx` 命中即阻断 |

## 8. 非功能需求

| ID | 类别 | 需求 |
| --- | --- | --- |
| NFR-001 | 职责单一 | 只做组装，不做业务/采集/领域逻辑 |
| NFR-002 | 稳定性 | v0.1.0 后 Build/Run/Shutdown 签名不破坏性变更 |
| NFR-003 | 边界纯净 | public API 不暴露 domain DTO / transport tag / storage tag |
| NFR-004 | 可观测 | Build/Shutdown 记录日志事件（§18.3，v0.1.x 已实现）；metrics 上报为 v0.2.0 目标，受 OQ-001 约束 |
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
    "github.com/ZoneCNH/taosx"
    "github.com/ZoneCNH/postgresx"
    "github.com/ZoneCNH/redisx"
    "github.com/ZoneCNH/kafkax"
    "github.com/ZoneCNH/natsx"
    "github.com/ZoneCNH/clickhousex"
    // OSS：ossx 仓库当前 0 pkg 源码，不 import；OSS 位运行时返回 ErrUnsupportedStore（见 OQ-005）
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
    TD     StoreSet = 1 << 0  // taosx
    PG     StoreSet = 1 << 1  // postgresx
    Redis  StoreSet = 1 << 2  // redisx
    Kafka  StoreSet = 1 << 3  // kafkax
    NATS   StoreSet = 1 << 4  // natsx
    OSS    StoreSet = 1 << 5  // ossx（仓库 0 pkg 源码，启用即 ErrUnsupportedStore，见 OQ-005）
    CH     StoreSet = 1 << 6  // clickhousex
    Stable StoreSet = TD | PG | Redis | Kafka | NATS | CH  // 聚合层默认：6 个已就绪存储，不含 OSS
    All    StoreSet = Stable | OSS  // 全部 7 位；当前等价于 Stable（OSS 位被 FR-004 拒绝）
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
// 字段为对应 adapter 的强类型 *Client，避免消费者 type assert。
type Stores struct {
    TD    *taosx.Client
    PG    *postgresx.Client
    Redis *redisx.Client
    Kafka *kafkax.Client
    NATS  *natsx.Client
    OSS   interface{}        // 占位：ossx 仓库 0 pkg 源码，OSS 位运行时永远 nil；待 ossx 补源码后改为 *ossx.Client（OQ-005）
    CH    *clickhousex.Client
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
// adapter:  None   (0b0000000)
// 聚合层:   Stable (0b0111111)  // 6 个已就绪存储，不含 OSS（见 OQ-005）
// 全量:     All    (0b1111111)  // 当前等价 Stable（OSS 位被 FR-004 拒绝）
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
| Spec.Stores = None + 服务试图访问 App.Stores | App.Stores 为 nil；调用方需在访问前检查 `app.Stores != nil`；BR-005 通过 Build 入口 Spec.Module allowlist 校验保证 adapter 进程不持有 Stores |
| Spec.Stores 含 OSS 位 | Build 返回 ErrUnsupportedStore（ossx 仓库 0 pkg 源码，详见 OQ-005）；聚合层应使用 Stable 而非 All |
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
    // 存储适配器（按 Stores 位掩码构造，全部 require；OSS 除外，见下方注记）
    github.com/ZoneCNH/taosx         v1.0.1
    github.com/ZoneCNH/postgresx     v1.0.0   // PG_PASSWORD 脱敏用 postgresx.SecretString（OQ-004 v3）
    github.com/ZoneCNH/redisx        v1.0.1
    github.com/ZoneCNH/kafkax        v1.0.2
    github.com/ZoneCNH/natsx         v1.0.0
    github.com/ZoneCNH/clickhousex   v1.0.1
    // OSS: github.com/ZoneCNH/ossx — 暂不 require（仓库 0 pkg 源码），待 OQ-005 关闭后加入
)
```

> **ADR-foundationx-exit 迁移注记**（OQ-004，2026-06-18 v3 实测纠错）：
> bootstrap 当前 `pkg/bootstrap/stores.go:217` import `github.com/ZoneCNH/foundationx/pkg/foundationx` 用 `SecretString` 包 `PG_PASSWORD`。
> **v3 纠错（取代 v2 误判）**：实测 ZoneCNH/postgresx@v1.0.0 已完成 foundationx 退出——`Config.Password` 是本地 `postgresx.SecretString`（pkg/postgresx/secret.go: `type SecretString string`），`Validate` 用本地 `NewError`/`ErrorKindConfig`，`go.mod` 不含 foundationx。v2 当时基于 GOMODCACHE 旧快照得出"postgresx 传染"结论，实际 GitHub tag v1.0.0 已是独立版本。
> **真实清零路径**：bootstrap v0.1.1 一行替换即可——`stores.go:217 foundationx.SecretString(...)` → `postgresx.SecretString(...)`，删 import，`go mod tidy`。无需上游联动。
> CI 规则 `grep -rn "foundationx" --include="*.go"` 在 bootstrap v0.1.1 后应全仓零命中。

### 15.2 依赖方向

```
bootstrap (L1)
  ├─► kernel (L0): lifecycx, shutdownx
  ├─► configx (L1): NewLoader, Source, New
  ├─► observex (L1): New
  ├─► resiliencx (L1): New
  └─► L2 存储适配器: taosx/postgresx/redisx/kafkax/natsx/clickhousex（OSS 见 OQ-005）
```

**禁止向上依赖**：不得 import domain-*、contracts、任何业务域模块，也不得 import foundationx（详见 ADR-foundationx-exit 与 OQ-004）。

## 16. 测试

### 16.1 测试矩阵

| TC ID | 覆盖 FR/AC | 类型 | 场景 | 命令 |
| --- | --- | --- | --- | --- |
| TC-BS-001 | FR-001 / AC-001 | 单元 | Build 成功，Stores=None，App.Stores 为 nil | `go test -run TestBuildAdapter` |
| TC-BS-002 | FR-001 / AC-004 | 集成 | Build 成功，Stores=Stable，App.Stores 全非 nil（OSS 位除外） | `go test -run TestBuildAggregate` |
| TC-BS-003 | FR-001 | 单元 | Spec.Module 为空 → ErrEmptyModule | `go test -run TestBuildEmptyModule` |
| TC-BS-004 | FR-004 / AC-004 | 单元 | Stores=TD\|PG，仅构造 TD+PG，其余 nil | `go test -run TestBuildPartialStores` |
| TC-BS-005 | FR-005 / AC-005a / FR-007 | 单元 | Run 收到 SIGTERM → 逆序 Stop | `go test -run TestRunShutdown` |
| TC-BS-006 | FR-005 / AC-005b | 单元 | Component Start 失败 → 回滚 | `go test -run TestStartRollback` |
| TC-BS-007 | FR-005 / AC-005c | 单元 | Shutdown 幂等（二次返回 nil） | `go test -run TestShutdownIdempotent` |
| TC-BS-008 | BR-001 | 门禁 | go.mod 无 domain-market/contracts | boundary-gate |
| TC-BS-009 | BR-005 | 单元 | adapter Spec.Stores=None 编译期约束 | `go test -run TestAdapterZeroStore` |
| TC-BS-010 | FR-002 / AC-002 | 单元 | 含 `XGO_TEST_PASSWORD` 的 .env 加载后字段脱敏 | `go test -run TestConfigSecretRedaction` |
| TC-BS-011 | FR-003 / AC-003 | 单元 | Build 后 App.Observe 非 nil 且 HealthCheck 通过 | `go test -run TestObserveInit` |
| TC-BS-012 | FR-006 / AC-006 | 单元 | stub Component 注册后 Run 触发其 Start 且 Name 匹配 | `go test -run TestComponentRegister` |
| TC-BS-013 | FR-008 / AC-008 | 单元 | ConfigHash 为 64 字符 hex；同配置同 hash，异配置异 hash | `go test -run TestConfigHash` |
| TC-BS-014 | FR-004 / OQ-005 | 单元 | Build(Spec{Stores: OSS}) 返回 ErrUnsupportedStore | `go test -run TestOSSUnsupported` |

### 16.2 测试工具与数据

- 框架：`testing` + `testify`
- Mock：`testkitx`
- 覆盖率：`go tool cover`，目标 ≥ 80%
- 竞态：`go test -race -count=1`
- testdata：`testdata/.env.sample`（含脱敏验证用 `XGO_TEST_PASSWORD`）

## 17. 性能预算

| 指标 | 预算 |
| --- | --- |
| Build（Stores=None） | < 50ms |
| Build（Stores=All） | < 500ms（含 7 存储连接） |
| Run 信号→Stop 延迟 | < 100ms |
| Shutdown（7 存储） | < 5s（graceful drain） |

## 18. 可观测性

> **metrics 实现约束（对齐 OQ-001）**：`observex.Client` 无 `Metrics()` getter，bootstrap **不能**直接通过 observex Client 上报下列指标。v0.1.x runtime 采用**启动/关闭日志事件**（见 Logging）记录 Build/Shutdown 状态；下列 metrics 表为 v0.2.0 目标态，待 bootstrap 自建轻量 prometheus registry（或 services main 显式持 observex.New 后由服务自行上报）后启用。在 metrics 路径就绪前，§18 metrics 不构成本版本 NFR 硬约束。

### 18.1 Metrics（v0.2.0 目标态）

| 指标 | 类型 | label |
| --- | --- | --- |
| `bootstrap_build_total` | Counter | module, stores |
| `bootstrap_build_duration_ms` | Histogram | module |
| `bootstrap_shutdown_total` | Counter | module |
| `bootstrap_lifecycle_start_total` | Counter | module, component, result |
| `bootstrap_lifecycle_stop_total` | Counter | module, component, result |

### 18.2 Tracing

| Span 名 | 说明 |
| --- | --- |
| `bootstrap.Build` | config/observe/stores/lifecycle 组装全过程 |
| `bootstrap.Run` | 信号等待 + 逆序 Stop |
| `bootstrap.Shutdown` | 逆序 Stop（幂等） |

### 18.3 Logging（v0.1.x 已实现路径）

| 事件 | 级别 | 说明 |
| --- | --- | --- |
| Build 成功 | info | 含 module、stores 位掩码、ConfigHash 前 12 位 |
| Build 失败 | error | 含失败阶段（config/observe/stores/lifecycle）与 error |
| Component Start/Stop | info | 含 component Name 与 result |
| Shutdown 完成 | info | 含耗时 |

## 19. 安全

- configx SecretString 自动脱敏所有 `*_PASSWORD`/`*_SECRET`/`*_KEY`
- bootstrap 不记录原始凭据，只记录 ConfigHash
- 存储连接凭据经 configx 加载，不硬编码

## 20. CI Gate

### 20.1 通用 Gate（所有模块共享，不可修改）

| Gate | 命令 | 通过条件 |
| --- | --- | --- |
| 编译 | `go build ./...` | 零错误 |
| 测试 | `go test ./... -race -count=1` | 全部通过 |
| 覆盖率 | `mkdir -p .coverage && go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | ≥ 80% |
| Vet | `go vet ./...` | 零警告 |
| Lint | `golangci-lint run` | 零警告 |
| 依赖 | `go mod tidy && git diff --exit-code` | 无变更 |
| 安全 | `gitleaks detect --no-git` | 零泄露 |
| Benchmark | `go test -bench=. -benchmem` | 在预算内（§17） |

### 20.2 模块专属 Gate

| Gate | 规则 | 校验 |
| --- | --- | --- |
| 禁业务语义 | go.mod 无 domain-market/domain-macro/domainx/contracts | `grep` 零命中 |
| 禁采集逻辑 | go.mod 无数据域子模块（binance/fred/…） | `grep` 零命中 |
| 禁 transport 实体 | 源码无 `net.Listen` | grep 零命中 |
| 依赖方向 | 只向下依赖 kernel/configx/observex/resiliencx/存储 | 依赖图扫描 |
| 组件可插拔 | Stores 位掩码控制 | TC-BS-004 |
| foundationx 零容忍 | 全仓库无 foundationx import（对齐 ADR-foundationx-exit 与 FOUNDATION-DEPS allowed_deps） | `grep -rn "foundationx" --include="*.go"` 零命中 |
| OSS 位禁用 | Build(Spec{Stores: OSS}) 返回 ErrUnsupportedStore（OQ-005 关闭前） | TC-BS-014 |

## 21. 升级兼容性

- v0.1.0 冻结 Build/Run/Shutdown/Spec/App 签名
- StoreSet 位掩码新增存储位时用高位，不破坏现有位
- Stores struct 新增字段时为指针（nil=未启用），不破坏现有消费者
- `Stable` 与 `All`：当前 `All == Stable`（OSS 位被 FR-004 拒绝）；待 OQ-005 关闭（ossx 补源码）后 `All` 才真正含 OSS。消费者应优先用 `Stable` 以避免未来 `All` 语义变化带来的回归。

## 22. Release DoD

### v0.1.0（已发布 2026-06-17）

- [x] go build ./... 通过
- [x] go test ./... -race -count=1 全过（10 测试）
- [x] boundary-gates.sh 5 道全过
- [x] CHANGELOG + README
- [x] GitHub Release v0.1.0
- [x] `Stores=None` 路径端到端就绪（adapter 23 接入）

### v0.2.0 准入项（含 SPEC Approved）

- [ ] `Stores=Stable` 与位组合端到端冒烟（market-data 接入验证）
- [ ] foundationx 依赖清零（bootstrap v0.1.1：`stores.go:217` 的 `foundationx.SecretString` 替换为 `postgresx.SecretString` + go.mod 清理；对齐 OQ-004 v3，`grep -rn foundationx` 零命中）
- [ ] binance 接入验证（main.go ≤10 行）
- [ ] SPEC 经四源 ≥98 分门禁，状态从 Draft 转 Approved

> **治理说明**：runtime v0.1.0 已先于 SPEC Approved 发布（走 `Stores=None` stub 路径），属受控的"实现领先规格"情形。SPEC Approved 仍为进入 v0.2.0 完整 Stores 路径的硬门禁，不得跳过。

## 23. 开放问题

| OQ | 问题 | 状态 | 结论 |
| --- | --- | --- | --- |
| OQ-001 | observex Client logger/metrics/tracer 私有无 getter | ✅ 已确认（2026-06-17） | configx/observex/resiliencx Client **均无业务 getter**（只有 Close/HealthCheck）。bootstrap 不暴露内部 logger，服务自行 observex.New。无需改基座。 |
| OQ-002 | 是否需要登记 FOUNDATION-DEPS.yaml？ | ✅ 已登记（2026-06-17） | bootstrap 已登记进 `module/FOUNDATION-DEPS.yaml` modules 与 allowed_deps 节，依赖方向：kernel/configx/observex/resiliencx + 6 存储。 |
| OQ-003 | 存储适配器是否已实现 lifecycx.Component？ | ✅ 已确认（2026-06-17） | 7 存储 adapter **未实现 Component**（有 Close 无 Start/Name）。bootstrap 用 `closerComponent` wrapper 适配，不改已发布适配器。 |
| OQ-004 | bootstrap 直 import foundationx — v3 实测：postgresx 已独立，仅 bootstrap 自身遗留 1 行 | Open（bootstrap v0.1.1 简单替换） | `pkg/bootstrap/stores.go:217` 残留 foundationx.SecretString 是历史遗留单点。postgresx@v1.0.0 实测已用本地 SecretString（pkg/postgresx/secret.go）+ 本地 NewError/ErrorKindConfig（pkg/postgresx/error.go）。清零路径：bootstrap v0.1.1 替换 `foundationx.SecretString(...)` 为 `postgresx.SecretString(...)` + go.mod 清理。详见 ADR-foundationx-exit v3（2026-06-18）+ BLK-009 v3。 |
| OQ-005 | ossx 仓库 0 pkg 源码，OSS 位无法启用 | Blocking（聚合层Stores 受限） | OSS 位已声明但 `Stores.OSS` 为 interface{} 占位，启用即 `ErrUnsupportedStore`。聚合层当前用 `Stable`（6 存储）。阻塞条件：ossx 补 pkg/ossx 源码并发 release。解决后：§9.1 删 OSS interface{} 占位改 `*ossx.Client`、§15.1 加 ossx require、§5 消费者表可从 Stable 回到 All。 |

---

## Appendix A: 发布状态

| 项目 | 状态 | 说明 |
| --- | --- | --- |
| SPEC | Draft | 本文件，待四源评分后转 Approved |
| Runtime implementation | Pending | 独立仓库 github.com/ZoneCNH/bootstrap，SPEC Approved 后进入 |
| FOUNDATION-DEPS 登记 | Pending | 需登记为 L1 模块 |

---

## Appendix B: 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-06-17 | v0.1.0 | 初始 SPEC：Build/Run/Shutdown + Spec/StoreSet/App + 7 存储 Component 适配 + 5 道边界门禁；基于 configx/observex/kernel 真实 API 对接 | ZoneCNH |
| 2026-06-17 | v0.1.1 | 实现前核实修正：确认 OQ-001（基座 Client 无业务 getter）/ OQ-003（存储适配器未实现 Component）；§9.3 改为 closerComponent wrapper 方案；App.Observe 标注仅供 Close | ZoneCNH |
| 2026-06-17 | v0.1.2 | 文档-代码漂移收口：§6 FR-004 标注 v0.1.0 stub 实现状态；§15.1 补声明 foundationx v0.1.1（runtime 实测）+ ossx 显式行 + ADR-foundationx-exit 迁移注记；§22 拆分 v0.1.0 已完成 / v0.2.0 准入；§23 OQ-002 翻 ✅ + 新增 OQ-004（foundationx 迁移） | ZoneCNH |
| 2026-06-18 | v0.1.3 | 7 项微调：§6 FR-001 删 metrics 鸡蛋问题；FR-004 加 v0.1.0 stub 行内注解；§9.1 StoreSet 改显式位号；§9.1 Stores 字段改强类型；§13 删 nil panic 措辞；§22/§23 OQ-004 提前到 v0.1.x；与 BLK-009 配对登记 | ZoneCNH |
| 2026-06-18 | v0.1.4 | SPEC↔runtime 远程仓库实测对账：§9.1 import 删 ossx（远程 bootstrap go.mod 不含 ossx）；§9.1 Stores.OSS 改 interface{} 占位（ossx 仓库 0 pkg 源码）；§15.1 ossx require 行注释为"暂不 require"；§20 CI Gate 新增 foundationx 白名单+计时规则（仅 stores.go 允许，其他文件零命中） | ZoneCNH |
| 2026-06-18 | v0.1.5 | C 阶段实测发现 OQ-004 真实根因：foundationx 不是 bootstrap 主动选择，而是 postgresx@v1.0.0 公开 API 传染（Config.Password foundationx.SecretString）。§15.1 迁移注记 v2 修订；§23 OQ-004 状态从"v0.1.x patch 优先"改为"待 postgresx v1.1.0 解锁"；BLK-009 重写为分阶段三步关闭条件；与 ADR-foundationx-exit v2 联动登记 postgresx 真实瓶颈 | ZoneCNH |
| 2026-06-18 | v0.1.6 | v3 实测纠错（取代 v2 误判）：实测 postgresx@v1.0.0 已完成 foundationx 退出（pkg/postgresx/secret.go 本地 SecretString + pkg/postgresx/error.go 本地 NewError，go.mod 无 foundationx）。v2 当时基于 GOMODCACHE 旧快照判断为"postgresx 传染"是错误。§15.1 迁移注记 v3 + §23 OQ-004 + ADR v3 时间线全部更正；BLK-009 重写为单一一行替换任务；bootstrap v0.1.1 1 行替换即可关闭 BLK-009a | ZoneCNH |
| 2026-06-18 | v0.1.7 | 结构性修复合并入主线（rebase 到 v0.1.6 之上）：R1 追溯链——FR-001~008 全部补 AC 子句，§16 补 TC-BS-010~014，闭合 FR→AC→TC；R2 OSS 矛盾——§9.1 引入 `Stable` 常量（All\OSS），§5/§13/§21 同步，新增 OQ-005；S1 附录改 Appendix A/B；S2 Metadata 补 Owner/Repository/Last-Updated；S3 §4 重组（OWNS 移入 §3.1）；S4 BR 表补"违反时"列 + 新增 BR-009（foundationx 零容忍）；S5 §18 拆 metrics/tracing/logging 并对齐 OQ-001；S6 FR-003 签名统一为 opts...；S7 §20 补通用 8 项 Gate。OQ-004 采用 v3 结论（postgresx 已独立），§15.1/§22 同步为 postgresx.SecretString 一行替换路径。 | ZoneCNH |
