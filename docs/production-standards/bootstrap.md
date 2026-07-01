# bootstrap

## 1. 模块定位
bootstrap 是 Foundation L1 Assembly 通用进程组装层，位于 L1 primitives 之上、具体入口 `x.go` 之下。封装所有数据域进程（23 adapter + 2 聚合层 + 未来分析域/决策域）共有的 configx 加载 + observex 初始化 + resiliencx 初始化 + lifecycx 生命周期编排，存储适配器作为聚合层可选件按位掩码启用。将服务 main 从 ~150 行裸胶水降到 5-8 行。Status=Draft（SPEC 待四源 ≥98 分转 Approved），Spec-version v0.1.7，module-version v0.1.0-runtime / v0.1.7-spec。

## 2. 生产职责
- FR-001 Build 入口：`Build(ctx, Spec) (*App, error)` 组装 config → observe → stores（按 Stores 位掩码）→ resilience → lifecycle
- FR-002 configx 加载：`configx.NewLoader` + `EnvFileSource(.env)` + `NewAllEnvSource("XGO_")` + SecretString 脱敏
- FR-003 observex 初始化：`observex.New(ctx, Config)` + 统一 label policy
- FR-004 stores 可选构造：按 Spec.Stores 位掩码构造 7 存储 adapter（v0.1.0 仅 Stores=None 路径就绪）
- FR-005 lifecycle 编排：顺序 Start → 等信号 → 逆序 Stop，失败回滚
- FR-006 组件注册：`App.Lifecycle.Register(components...)`
- FR-007 信号捕获：SIGINT/SIGTERM → Run 返回 → 逆序 Stop（kernel.shutdownx 语义）
- FR-008 EffectiveConfigHash 暴露：App.ConfigHash（SHA-256）用于启动日志与配置漂移排查

## 3. 边界定义
行为约束 BR-001 ~ BR-008：不得 import domain_market/domain_macro/domainx/contracts（禁业务语义）；不得 import 任何数据域子模块 binance/fred/…（禁采集逻辑）；不得起 HTTP/gRPC server（源码无 `net.Listen`）；只向下依赖 kernel/configx/observex/resiliencx/存储适配器，不向上穿透 L2.5/业务域/x.go；adapter 进程 Spec.Stores 必须为 None；仅聚合层 Spec.Stores 可非 None；Spec.Stores 位掩码控制未启用存储不构造不连接；文档批准前不得新增运行时代码或依赖。

## 4. 不负责什么
不内置 admin HTTP server / metrics endpoint（各服务自己的事）；不内置 graceful shutdown 编排策略（用 kernel.shutdownx）；不内置连接池管理（kafkax/natsx 各自管理）；不承载领域语义（domain_market/domain_macro 归 L2.5）；不 import 业务域模块（binance/fred/…）；不起 HTTP/gRPC server（仅组装 Component，不起 `net.Listen`）。是 Foundation 内 L1 Assembly 横切能力，不是 configx/observex/resiliencx 原子能力替代。

## 5. 架构位置
L1 Assembly（基座进程组装层）。依赖方向：向下组合 kernel（L0: lifecycx, shutdownx）+ configx/observex/resiliencx（L1 primitives）+ 受控 L2 存储适配器（taosx/postgresx/redisx/kafkax/natsx/ossx/clickhousex）；禁止向上依赖 domain-*、contracts、任何业务域模块或 x.go。位于 L1 primitives 之上、具体入口 x.go 之下。已登记进 FOUNDATION-DEPS.yaml modules 与 allowed_deps 节，定位为 L1 Assembly（不属于 L1 primitive）。

## 6. 生命周期
- Build：configx 加载 → observex 初始化 → stores 构造（按 Stores 位掩码）→ resiliencx 默认策略 → lifecycx.Manager 创建
- Run：注册 Component 顺序 Start → 阻塞等待 SIGINT/SIGTERM → 逆序 Stop；任一 Component Start 失败回滚已启动的 Component
- Shutdown：逆序 Stop 所有已注册 Component，幂等（重复调用返回 nil）
- 7 存储 adapter 未实现 lifecycx.Component（有 Close 无 Start/Name），bootstrap 用 `closerComponent` wrapper 适配（Start=no-op, Stop=Close）

## 7. 标准目录结构
```text
github.com/ZoneCNH/bootstrap（独立仓库）
├── go.mod                         # module github.com/ZoneCNH/bootstrap, go 1.23
├── go.sum / README.md
├── pkg/bootstrap/
│   ├── doc.go
│   ├── bootstrap.go               # Build / Run / Shutdown
│   ├── spec.go                    # Spec / StoreSet / App / Stores
│   ├── config.go                  # configx 加载封装
│   ├── observe.go                 # observex 初始化封装
│   ├── stores.go                  # 7 存储 adapter 构造（按 StoreSet）
│   ├── lifecycle.go               # lifecycx.Manager 编排 + 信号捕获
│   ├── errors.go                  # ErrEmptyModule 等
│   └── version.go
└── scripts/
    └── boundary-gates.sh          # 5 道边界门禁（§20）
```

## 8. 配置规范
bootstrap 自身配置经 configx 加载，统一前缀 `XGO_`（SPEC §11）：`XGO_{MODULE}_LOG_LEVEL=info`、`XGO_{MODULE}_METRICS_ADDR=:9091`（通用）；聚合层额外 `XGO_{MODULE}_PG_HOST`、`XGO_{MODULE}_TD_HOST` 等（详见 Bootstrap SOP §七）。Spec 结构体（SPEC §9.1）：`Spec{Module string, Stores StoreSet, Hooks []func(*App) error}`。StoreSet 位掩码（uint8）：None=0, TD=1<<0, PG=1<<1, Redis=1<<2, Kafka=1<<3, NATS=1<<4, OSS=1<<5, CH=1<<6, All=0b1111111。所有 `*_PASSWORD`/`*_SECRET`/`*_KEY` 字段经 SecretString 自动脱敏。

## 9. 错误模型
公共错误（SPEC §10.2）：`ErrEmptyModule`（Spec.Module 为空，不可重试）、`ErrInvalidSpec`（Spec 字段非法，不可重试）、`ErrStoreConstructFailed`（存储 adapter 构造失败，可重试退避后重试 Build）、`ErrLifecycleStartFailed`（Component Start 失败，不可重试已回滚）、`ErrUnsupportedStore`（Stores 位掩码含未实现的存储，v0.1.0 非 None 位返回）、`ErrConfigLoad`、`ErrObserveInit`。错误处理（SPEC §12）：Build 时各阶段失败关闭已建组件；Run 时 Start 失败回滚 errors.Join；Shutdown 时 Stop 失败继续逆序 Stop 其余 errors.Join。

## 10. 日志规范
bootstrap 经 observex 初始化 Logger，NFR-004 要求 Build/Shutdown 记录 observex metrics + 日志。SPEC §18 定义 metrics 但未细化 log 字段。configx SecretString 自动脱敏所有 `*_PASSWORD`/`*_SECRET`/`*_KEY`，bootstrap 不记录原始凭据，只记录 ConfigHash（FR-008）。App.Observe 持有 `*observex.Client` 仅供 Shutdown 时 Close，不暴露 Logger getter（OQ-001：configx/observex/resiliencx Client 均无业务 getter），服务要可观测自行 `observex.New`。

## 11. Metrics
SPEC §18 定义 5 个 metric：
- `bootstrap_build_total`（Counter，label: module, stores）
- `bootstrap_build_duration_ms`（Histogram，label: module）
- `bootstrap_shutdown_total`（Counter，label: module）
- `bootstrap_lifecycle_start_total`（Counter，label: module, component, result）
- `bootstrap_lifecycle_stop_total`（Counter，label: module, component, result）

metrics 经 observex Client 注入；bootstrap 持有 Client 句柄做统一 Close。

## 12. Tracing
SPEC 未定义独立 Tracing 接口。bootstrap 经 observex 初始化 Tracer，但 App.Observe 不暴露 Tracer getter（OQ-001）。服务要 tracing 自行 `observex.New`。Build/Run/Shutdown 的 trace span 约定遵循 observex 全局规范（SPEC 未细化）。ConfigHash（FR-008）提供启动到运行时的配置关联标识。

## 13. Reliability
- FR-005 lifecycle 编排：顺序 Start → 逆序 Stop，任一 Component Start 失败回滚（kernel.lifecycx.Manager 语义）
- FR-007 信号捕获：SIGINT/SIGTERM 触发 Run 返回逆序 Stop，超时强制退出（kernel.shutdownx 语义）
- Shutdown 幂等（FR-005 重复调用返回 nil）
- resiliencx 默认弹性策略（FR-001 Build 注入）
- Build 时各阶段失败关闭已建组件（config 失败→不构造后续；observe 失败→关闭 configx；store 失败→关闭已建组件）

## 14. Security
- configx SecretString 自动脱敏所有 `*_PASSWORD`/`*_SECRET`/`*_KEY`（FR-002）
- bootstrap 不记录原始凭据，只记录 ConfigHash（SPEC §19）
- 存储连接凭据经 configx 加载，不硬编码
- App.Observe/App.Config/App.Resilience 仅供 Shutdown 时 Close，不暴露内部状态
- foundationx 依赖白名单：仅 `pkg/bootstrap/stores.go` 允许 import foundationx（OQ-004 迁移中），其他文件零命中

## 15. Performance SLO
| 指标 | 预算 |
| --- | --- |
| Build（Stores=None） | < 50ms |
| Build（Stores=All） | < 500ms（含 7 存储连接） |
| Run 信号→Stop 延迟 | < 100ms |
| Shutdown（7 存储） | < 5s（graceful drain） |

## 16. 测试标准
TC-BS-001 ~ TC-BS-009（SPEC §16）：TC-BS-001 Build 成功 Stores=None、TC-BS-002 Build 成功 Stores=All（v0.2.0 准入）、TC-BS-003 Spec.Module 空→ErrEmptyModule、TC-BS-004 Stores=TD|PG 部分构造（v0.2.0）、TC-BS-005 Run SIGTERM→逆序 Stop、TC-BS-006 Start 失败→回滚、TC-BS-007 Shutdown 幂等、TC-BS-008 go.mod 无 domain/contracts（boundary-gate）、TC-BS-009 adapter Spec.Stores=None 编译期约束。v0.1.0 已发布 10 测试全过 -race -count=1，boundary-gates.sh 5 道全过。

## 17. Chaos
bootstrap 为进程组装层，无长尾请求路径，不适用网络故障/依赖崩溃/慢响应类混沌测试。生命周期可靠性通过 kernel.lifecycx.Manager 保证（顺序 Start/逆序 Stop/失败回滚）。边界情况（SPEC §13）：ctx 为 nil → Build 返回 validation error；重复 Shutdown 幂等返回 nil；SIGTERM 在 Build 期间 → Build 检查 ctx.Err() 提前返回；Stores 位掩码含未实现存储 → 构造时返回 ErrUnsupportedStore。具体混沌维度遵循 README 全局规范，本模块待定义（SPEC 未细化）。

## 18. Contract
公开接口契约由 SPEC §9 严格定义：
- §9.1 公开类型：Spec / StoreSet（uint8 位掩码 7 存储）/ App / Stores（强类型字段 nil=未启用）
- §9.2 核心方法：`Build(ctx, Spec) (*App, error)` / `App.Run(ctx) error` / `App.Shutdown(ctx) error`
- §9.3 基座真实 API 对接：configx `NewLoader/AddSource/Load/New`、observex `New`、resiliencx `New`、kernel lifecycx `NewManager/Start/Stop`
- OQ-001 约束：configx/observex/resiliencx Client 均无业务 getter（只有 Close/HealthCheck），App 不暴露内部 logger
- OQ-003 约束：7 存储 adapter 未实现 Component，bootstrap 用 closerComponent wrapper 适配
- 升级兼容性（SPEC §21）：v0.1.0 冻结 Build/Run/Shutdown/Spec/App 签名；StoreSet 新增存储位用高位；Stores struct 新增字段为指针

## 19. CI Gate
通用 Go Gate：`go build ./...` / `go test ./... -race -count=1` / `go vet ./...` / 覆盖率 / lint。
boundary-gates.sh 5 道专属 Gate（SPEC §20）：
1. 禁业务语义：go.mod 无 domain_market/domain_macro/domainx/contracts（grep 零命中）
2. 禁采集逻辑：go.mod 无数据域子模块 binance/fred/…（grep 零命中）
3. 禁 transport 实体：源码无 `net.Listen`（grep 零命中）
4. 依赖方向：只向下依赖 kernel/configx/observex/resiliencx/存储（依赖图扫描）
5. 组件可插拔：Stores 位掩码控制（TC-BS-004）
6. foundationx 退出（白名单+计时）：仅 `pkg/bootstrap/stores.go` 允许 import，其他文件零命中（OQ-004）

## 20. Release Gate
ACCEPTANCE §5 DoD（当前全部未勾选，运行时证据待 /home/workspace/bootstrap 复验）：[ ] FEATURES/ACCEPTANCE 与 SPEC/TRACEABILITY 一致；[ ] AC/TC 与运行时测试名一致；[ ] go test/-race/vet/coverage 通过；[ ] 外部服务依赖有测试替身；[ ] 安全检查通过；[ ] 版本号/标签/CHANGELOG 一致。
SPEC §22 v0.1.0 已发布（2026-06-17）：[x] go build/test -race（10 测试）/boundary-gates.sh 5 道/CHANGELOG+README/GitHub Release v0.1.0/Stores=None 路径端到端就绪。
v0.2.0 准入项：[ ] Stores=All 与位组合冒烟（market_data 接入）；[ ] foundationx 依赖移除；[ ] binance 接入验证（main.go ≤10 行）；[ ] SPEC 四源 ≥98 分转 Approved。

## 21. Versioning
semver。module-version v0.1.0-runtime / v0.1.7-spec（运行时已发布 v0.1.0，SPEC 仍为 Draft）。go.mod：`module github.com/ZoneCNH/bootstrap`，`go 1.23`。依赖：kernel v1.0.0、configx v1.0.0、observex v0.3.1、resiliencx v0.4.9、foundationx v0.1.1（过渡期，OQ-004 待清零）、7 存储 adapter（taosx v1.0.1/postgresx v1.0.0/redisx v1.0.1/kafkax v1.0.2/natsx v1.0.0/clickhousex v1.0.1，ossx 暂不 require）。升级兼容性：v0.1.0 冻结 Build/Run/Shutdown/Spec/App 签名（NFR-002）。

## 22. 兼容性策略
向后兼容（SPEC §21）：v0.1.0 冻结 Build/Run/Shutdown/Spec/App 签名；StoreSet 位掩码新增存储位用高位不破坏现有位；Stores struct 新增字段为指针（nil=未启用）不破坏现有消费者。边界情况（SPEC §13）：Spec.Stores=None + 服务试图访问 App.Stores → App.Stores 为 nil，调用方需检查 `app.Stores != nil`（BR-005 通过 Spec.Module allowlist 校验保证 adapter 进程不持有 Stores）；重复 Shutdown 幂等返回 nil；Stores 位掩码含未实现存储返回 ErrUnsupportedStore。

## 23. Failover
lifecycle 编排保证 Start 失败回滚（FR-005 + kernel.lifecycx.Manager BR-002）：任一 Component Start 失败时逆序 Stop 已启动的 Component，返回 errors.Join。Shutdown 失败继续逆序 Stop 其余 Component（errors.Join 聚合）。Shutdown 幂等（重复调用返回 nil）。SIGTERM 在 Build 期间 → Build 检查 ctx.Err() 提前返回。resiliencx 默认弹性策略注入 Build（FR-001）。ErrStoreConstructFailed 可重试（退避后重试 Build）。

## 24. Backpressure
bootstrap 为进程组装层，无持续流量需 backpressure。7 存储 adapter 的连接池管理由各自负责（kafkax/natsx 各自管理，bootstrap 不内置）。lifecycx.Manager 顺序 Start 保证依赖顺序（先启 config → observe → stores → 服务 Component）。Stores 位掩码控制按需构造（BR-007 未启用的存储不构造不连接）。Shutdown graceful drain 预算 < 5s（7 存储）。closerComponent wrapper 适配 7 存储 adapter 的 Close 语义。

## 25. 审计要求
App.ConfigHash（FR-008）暴露 configx EffectiveConfigHash（SHA-256）用于启动日志与配置漂移排查。configx SecretString 自动脱敏保证凭据不泄露到日志。metrics `bootstrap_build_total`（label: module, stores）+ `bootstrap_shutdown_total`（label: module）记录生命周期审计点。boundary-gates.sh 5 道 CI Gate 保证依赖边界可审计（禁业务语义/禁采集/禁 server/依赖方向/store 位掩码）。foundationx 白名单 CI 规则保证迁移进度可审计。

## 26. 熵减规则
全局 Entropy Rules + 模块特有禁项（SPEC §4.2 + BR-001~008）：
- BR-001/002：禁业务语义 + 禁采集逻辑（不得 import domain-*/contracts/数据域子模块）
- BR-003：禁 transport 实体（源码无 net.Listen）
- BR-004：只向下依赖不向上穿透（L1 Assembly 边界纯净）
- 禁止 util dumping（pkg/bootstrap 按职责切分 bootstrap/spec/config/observe/stores/lifecycle/errors）
- 禁止 hidden abstraction（§9 接口契约严格定义，closerComponent wrapper 显式声明）

## 27. AI Constraints
全局 AI Constraints + 模块特有约束：
- BR-008：文档批准前不得新增运行时代码或依赖（SPEC 仍为 Draft，禁止扩大运行时）
- 禁止新增未注册存储位（7 存储位固定，新增走 SPEC + FR-004 流程，用高位不破坏现有位）
- 禁止绕过 contracts 边界（不得 import domain-*/业务域模块）
- 禁止起 HTTP/gRPC server（BR-003 源码无 net.Listen）
- 禁止暴露基座 Client 内部状态（OQ-001 App 不暴露 Logger/Metrics/Tracer getter）
- AI 生成代码必须通过 boundary-gates.sh 5 道 + foundationx 白名单

## 28. Forbidden Patterns
- 禁止 global mutable state（App 由 Build 显式创建，非单例）
- 禁止向上依赖（BR-004 不得 import L2.5/业务域/x.go）
- 禁止 transport 实体（BR-003 net.Listen）
- 禁止业务语义混入（BR-001 domain_market/domain_macro/contracts）
- 禁止采集逻辑混入（BR-002 binance/fred/…）
- 禁止内置 graceful shutdown 编排（用 kernel.shutdownx）
- 禁止内置连接池管理（kafkax/natsx 各自管理）
- 禁止 App 暴露基座 Client 业务 getter（OQ-001）

## 29. Production Ready Checklist
- [x] build entry ready（FR-001 Build(ctx, Spec) 入口，Stores=None 路径端到端就绪，v0.1.0 已发布）
- [x] configx loading ready（FR-002 configx loader + XGO_ 环境源 + SecretString 脱敏 + ConfigHash 暴露）
- [x] lifecycle orchestration ready（FR-005/006/007 顺序 Start/逆序 Stop/失败回滚/信号捕获，v0.1.0 已发布）
- [x] boundary gates ready（BR-001~008 boundary-gates.sh 5 道全过，v0.1.0 已发布）
- [~] stores optional ready（FR-004 Stores=None 就绪；非 None 存储位为 v0.2.0 准入，TC-BS-002/004 Pending）
- [~] spec approved ready（SPEC 仍为 Draft，待四源 ≥98 分门禁转 Approved，v0.2.0 准入项）
- [~] foundationx exit ready（OQ-004 Open，pkg/bootstrap/stores.go:217 残留 1 行，bootstrap v0.1.1 一行替换清零）
- [ ] release dod ready（ACCEPTANCE §5 DoD 6 项全部未勾选，运行时证据待 /home/workspace/bootstrap 复验归档）

## 30. Roadmap
- v0.1.0（2026-06-17 已发布）：初始 SPEC + 实现，Build/Run/Shutdown + Spec/StoreSet/App + 7 存储 Component 适配 + 5 道边界门禁；Stores=None 路径端到端就绪（adapter 23 接入）
- v0.1.x patch（计划）：foundationx 依赖清零（OQ-004，bootstrap v0.1.1 一行替换 stores.go:217）
- v0.2.0 准入项：Stores=All 与位组合端到端冒烟（market_data 接入验证）；binance 接入验证（main.go ≤10 行）；SPEC 四源 ≥98 分转 Approved
- v0.1.7（2026-06-18 SPEC）：明确 bootstrap 定位为 Foundation L1 Assembly（位于 L1 primitives 之上、x.go 入口之下，只做进程组装/生命周期/可选 adapter 构造）
- Open Questions（OQ-001~004 已确认）：基座 Client 无业务 getter（不改基座）/ 已登记 FOUNDATION-DEPS / 存储 adapter 未实现 Component（closerComponent wrapper）/ foundationx 迁移
