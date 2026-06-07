# 🏗️ 分层架构

> FoundationX 量化交易基础设施的完整依赖拓扑
>
> 按职责域组织，拆分代码依赖、业务流与运行时组装视角

## 架构视图

依赖、业务流和运行时组装刻意分开呈现：业务数据从数据域走向执行域，代码依赖不反向穿透；`x.go` 是组合根（Composition Root），不是业务链路终点。

> 🔄 三引擎数据流全景（market_engine→S / macro_engine→M / regime_engine→DecisionCard）、M×S 矩阵、契约固化清单 → **[DATAFLOW.md](./DATAFLOW.md)**

### 代码依赖拓扑

```text
依赖方向：左侧模块可以导入右侧模块。

x.go ───────────────► 基座运行时 / L2.5 / 数据域 / 分析域 / 决策域 / 执行域

数据域 ─┐
分析域 ─┼──────────► L2.5 Domain Shared
决策域 ─┤             decimalx · domain-market · domain-exchange · domain-macro
执行域 ─┘
   │
   ├───────────────► contracts
   │                  跨域稳定端口、事件协议、DTO 契约
   │
   └───────────────► 基座运行时 Foundation
                      L0: kernel
                      L1 runtime: configx · observex · resiliencx · schedulex
                      L1 test-only: testkitx
                      扩展: redisx · kafkax · natsx · postgresx · taosx · ossx · clickhousex
                      契约: contracts

标准与门禁：
  xlib-standard ─── 标准事实源 / 模板 / Gate / Evidence，不参与业务运行
  xlibgate      ─── import 边界、go.mod、Go baseline、release evidence 机器门禁

横切关注点：
  alertx   ─── 策略异常、风控触发告警
  observex ─── 统一 metrics / tracing / logging（同时作为基座组件提供底层能力）
```

### 业务流与反馈

```text
market-data (19) ──────────────► market_regime ──┐
  domain-market (Bar/Tick/OB)     S1-S7 状态     │
  质量门禁 → 特征 → 分类器       bias/permission  │
                                               ├──► regime-engine ──► DecisionCard
macro-data (10) ───────────────► macro_regime ──┘     M×S 融合        action A-E
  domain-macro (MacroPoint)      M1-M7 状态           冲突门           profile
  LGIP 四因子                    LGIP 得分            风险放大          risk_tier
                                                                 position_caps
factor-engine ◄──► feature-store ◄──► factor-eval                     template
              │                         ▲
              ▼                         │
signal-factory ◄── backtest-engine ─────┘    ◄── DecisionCard (action/risk/template)
      │              ▲
      ▼              │
optimizer ───────────┘
      │
      ▼
risk-engine ───► order-engine ───► portfolio-engine ───► settlement
  ◄── trade_permission                │                 │
      position_caps                   └──── fills ──────┤
      risk_multiplier                                  ▼
                              决策域 ◄──── positions / PnL / exposure events
```

### 运行时组装

```text
x.go
  ├── load config
  ├── init observability / alerting
  ├── create data providers
  ├── wire analytics engines
  ├── wire decision engines
  ├── wire execution engines
  └── run lifecycle / graceful shutdown
```

## 各域说明

| 域     | 职责                                                                                                                          | 组件                                                                                                                                                       |
| ------ | ----------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 基座   | 标准源、L0 原语、L1 运行时横切能力、测试期证据、存储扩展、稳定契约                                                            | xlib-standard, kernel, configx, observex, testkitx, resiliencx, schedulex, xlibgate, redisx, kafkax, natsx, postgresx, taosx, ossx, clickhousex, contracts |
| L2.5   | 领域值对象和语义模型，上层统一依赖                                                                                            | decimalx, domain-market, domain-exchange, domain-macro                                                                                                     |
| 数据域 | 行情、宏观、另类数据采集                                                                                                      | market-data (14 SDK + 5 Provider), macro-data (10), alternative-data                                                                                       |
| 分析域 | 因子计算、特征存储、因子评估、市场/宏观环境分类、M×S 联合决策（三引擎：market_engine→S / macro_engine→M / regime_engine→M+S） | factor-engine, feature-store, factor-eval, market_regime, macro_regime, regime-engine, ms_brain                                                            |
| 决策域 | 信号生成、历史回测、参数优化（并行协作）                                                                                      | signal-factory, backtest-engine, optimizer, strategies                                                                                                     |
| 执行域 | 风险管理、订单执行、组合管理、结算                                                                                            | risk-engine, order-engine, portfolio-engine, settlement                                                                                                    |
| 入口   | 启动、配置加载、依赖组装、生命周期控制                                                                                        | x.go                                                                                                                                                       |
| 横切   | 告警、可观测性                                                                                                                | alertx, observex                                                                                                                                           |

## Foundation v1 规格文档

Foundation 6 模块的详细规格、依赖矩阵、执行跟踪和 ADR 集中在 `module/` 目录：

| 文档 | 定位 |
|------|------|
| [`module/foundation-modules.md`](./module/foundation-modules.md) | Why & What — 模块定位、边界、能力需求、验证标准 |
| [`module/FOUNDATION-SPEC.md`](./module/FOUNDATION-SPEC.md) | How & Check — 接口签名、目录结构、CI gate、测试矩阵、Release DoD |
| [`module/FOUNDATION-V1.md`](./module/FOUNDATION-V1.md) | v1 路线图 — 产品定义、一致性修复、Issue 拆分 |
| [`module/FOUNDATION-DEPS.yaml`](./module/FOUNDATION-DEPS.yaml) | 机器可读依赖矩阵，CI 可消费 |
| [`module/ADR-foundationx-exit.md`](./module/ADR-foundationx-exit.md) | ADR：foundationx 兼容退出计划 |
| [`module/FOUNDATION-TRACKER.md`](./module/FOUNDATION-TRACKER.md) | 执行跟踪器 — P0/P1/P2 Issue 检查清单 |
| [`CONSTITUTION.md`](./CONSTITUTION.md) | 模块宪法 — 16 模块最高治理文件，AI 代理和人类贡献者的权威参考 |

16 个基座模块的独立完整规格（23 节结构：行为规格 WHEN/THEN、接口契约、业务规则、错误处理、边界场景、验收标准、目录结构、CI Gate、测试矩阵、性能预算、可观测输出、发布 DoD），按架构层级组织。完整索引见 [`specs/README.md`](./specs/README.md)。全部 16 模块已完成 23 节结构升级。

| 层级 | 模块 | 完整规格 |
|------|------|----------|
| **L0 原语** | kernel | [`specs/kernel/SPEC.md`](./specs/kernel/SPEC.md) |
| **L1 运行时** | configx | [`specs/configx/SPEC.md`](./specs/configx/SPEC.md) |
| | observex | [`specs/observex/SPEC.md`](./specs/observex/SPEC.md) |
| | resiliencx | [`specs/resiliencx/SPEC.md`](./specs/resiliencx/SPEC.md) |
| | schedulex | [`specs/schedulex/SPEC.md`](./specs/schedulex/SPEC.md) |
| **L1 测试** | testkitx | [`specs/testkitx/SPEC.md`](./specs/testkitx/SPEC.md) |
| **门禁** | xlib-standard | [`specs/xlib-standard/SPEC.md`](./specs/xlib-standard/SPEC.md) |
| | xlibgate | [`specs/xlibgate/SPEC.md`](./specs/xlibgate/SPEC.md) |
| **存储扩展** | redisx | [`specs/redisx/SPEC.md`](./specs/redisx/SPEC.md) |
| | kafkax | [`specs/kafkax/SPEC.md`](./specs/kafkax/SPEC.md) |
| | natsx | [`specs/natsx/SPEC.md`](./specs/natsx/SPEC.md) |
| | postgresx | [`specs/postgresx/SPEC.md`](./specs/postgresx/SPEC.md) |
| | taosx | [`specs/taosx/SPEC.md`](./specs/taosx/SPEC.md) |
| | ossx | [`specs/ossx/SPEC.md`](./specs/ossx/SPEC.md) |
| | clickhousex | [`specs/clickhousex/SPEC.md`](./specs/clickhousex/SPEC.md) |
| **契约** | contracts | [`specs/contracts/SPEC.md`](./specs/contracts/SPEC.md) |
| **组合根** | x.go | [`specs/xgo/SPEC.md`](./specs/xgo/SPEC.md) |

### 规格体系与治理文档

| 文档 | 定位 |
|------|------|
| [`docs/product/product-spec.md`](./docs/product/product-spec.md) | 产品规格 — Vision、Users、Goals、MVP Scope |
| [`docs/testing/test-strategy.md`](./docs/testing/test-strategy.md) | 测试策略 — 覆盖率、格式、工具、CI 集成 |
| [`docs/testing/acceptance-tests.md`](./docs/testing/acceptance-tests.md) | 验收测试 — 端到端验收场景和检查清单 |
| [`docs/ai/agent-rules.md`](./docs/ai/agent-rules.md) | AI 代理规则 — 编码、测试、安全、禁止事项 |
| [`docs/ai/prompt-templates.md`](./docs/ai/prompt-templates.md) | Prompt 模板 — 审查、拆分、实现、自查、修复 |
| [`docs/ai/code-review-rules.md`](./docs/ai/code-review-rules.md) | 代码审查规则 — AI 代理审查标准和流程 |
| [`GLOSSARY.md`](./GLOSSARY.md) | 术语表 — 系统核心概念和缩写定义 |
| [`specs/DEFINITION-OF-READY.md`](./specs/DEFINITION-OF-READY.md) | Spec Ready — spec 可以进入开发的前置条件 |
| [`specs/DEFINITION-OF-DONE.md`](./specs/DEFINITION-OF-DONE.md) | Spec Done — 模块实现完成的验收条件 |
| [`specs/TRACEABILITY.md`](./specs/TRACEABILITY.md) | 需求追踪 — FR → AC → TC → 实现全覆盖 |
| [`specs/anti-requirements.md`](./specs/anti-requirements.md) | 反需求 — 明确不做之事，防止范围蔓延 |
| [`module/ADR-TEMPLATE.md`](./module/ADR-TEMPLATE.md) | ADR 模板 — 架构决策记录标准格式 |
| [`specs/TASK-TEMPLATE.md`](./specs/TASK-TEMPLATE.md) | Task 模板 — AI 代理任务拆分标准格式 |

## Foundation 第一阶段闭环

这 6 个基础模块可以构成第一阶段最小闭环：`kernel` 提供 L0 原语，`configx` / `observex` / `resiliencx` / `schedulex` 提供 L1 运行时横切能力，`testkitx` 只服务测试期。`xlib-standard` 是标准事实源和门禁输入，不作为运行时依赖。

| 模块            | 层级          | 拥有                                                                                                        | 不拥有                                                     |
| --------------- | ------------- | ----------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| `xlib-standard` | 标准源        | 标准事实源、模板、Gate、Evidence                                                                            | 业务运行、运行时依赖、模块实现身份                         |
| `kernel`        | L0 原语       | error、time、context、lifecycle、shutdown、health、validation、sync、version、minimal retry                 | 配置解析、观测后端、存储、网络、业务 DTO、全局可变单例     |
| `configx`       | L1 运行时     | explicit source、merge、decode、validate、sanitize、provenance、config hash                                 | secret backend、全局配置中心、自动发现、业务配置结构体     |
| `observex`      | L1 运行时契约 | logger、metrics、tracer、field、redactor、label policy、health schema、noop、memory recorder                | Prometheus/Otel/Zap 直接绑定、alert routing、业务监控规则  |
| `resiliencx`    | L1 运行时策略 | timeout、retry、circuit、bulkhead、rate limit、fallback、budget、classifier、idempotency hint、policy event | 交易风控、订单风险、交易所 SDK、调度、存储后端             |
| `schedulex`     | L1 运行时调度 | trigger、clock、misfire、overlap、jitter、EventSink、Locker interface、snapshot                             | 分布式锁实现、队列、exactly-once、业务任务语义             |
| `testkitx`      | L1 test-only  | assert、golden、contract、fixture、harness、fake clock、recorder、leak、boundary、manifest                  | production import、真实外部系统、L2/L3/chaos/soak 测试替代 |

### `resiliencx` 身份修复

`resiliencx` 必须回到 operational resilience：对不稳定外部依赖、任务、数据源、交易所 API、消息处理和调度任务提供可组合故障控制策略。`risk-engine` 才负责 trading risk，二者不能混用。

当前 P0 是把 Standard Source / Go Reference Template / Generator / Harness / Evidence Runtime 叙事迁回 `xlib-standard`，并让 `resiliencx` 围绕 timeout、retry、circuit、bulkhead、rate limit、fallback 和 policy event 建模。

| 边界     | `kernel.retryx`                        | `resiliencx`                                      |
| -------- | -------------------------------------- | ------------------------------------------------- |
| 层级     | L0 primitive                           | L1 runtime policy                                 |
| 主要职责 | backoff、retry marker、简单 retry loop | timeout、retry、circuit、bulkhead、rate、fallback |
| 观测     | 不负责完整 metrics                     | 输出 policy events，交给 `observex` 记录          |
| 状态     | 尽量无状态                             | circuit breaker / limiter 可有状态                |
| 依赖     | stdlib only                            | 可依赖 `kernel`，观测通过接口注入                 |
| 使用场景 | 基础库内部轻量重试                     | 外部 API、交易所、数据源、消息、任务执行          |

### Foundation 依赖矩阵

| From \ To  | kernel    | configx | observex       | testkitx   | resiliencx | schedulex | x.go | business |
| ---------- | --------- | ------- | -------------- | ---------- | ---------- | --------- | ---- | -------- |
| kernel     | -         | 禁止    | 禁止           | 禁止       | 禁止       | 禁止      | 禁止 | 禁止     |
| configx    | 允许      | -       | 禁止           | test-only  | 禁止       | 禁止      | 禁止 | 禁止     |
| observex   | 允许      | 禁止    | -              | test-only  | 禁止       | 禁止      | 禁止 | 禁止     |
| resiliencx | 允许      | 禁止    | interface-only | test-only  | -          | 禁止      | 禁止 | 禁止     |
| schedulex  | 允许/可选 | 禁止    | interface-only | test-only  | 禁止       | -         | 禁止 | 禁止     |
| testkitx   | 允许      | test    | test           | -          | test       | test      | 禁止 | 禁止     |
| x.go       | 允许      | 允许    | 允许           | 禁止(prod) | 允许       | 允许      | -    | 允许     |

## 边界与接口职责

| 边界                                                | 放什么                                                      | 不放什么                                         |
| --------------------------------------------------- | ----------------------------------------------------------- | ------------------------------------------------ |
| `xlib-standard`                                     | 标准事实源、模板、Gate、Evidence                            | 运行时业务依赖、具体弹性策略实现                 |
| `kernel`                                            | 最小稳定原语和 stdlib-only 基础能力                         | 配置解析、观测后端、业务 DTO、存储/网络适配器    |
| `configx` / `observex` / `resiliencx` / `schedulex` | L1 横切运行时能力，彼此通过窄接口协作                       | 业务模型、组合根职责、对彼此的强耦合反向依赖     |
| `testkitx`                                          | 测试、golden、contract、fixture、harness、boundary evidence | production import graph、真实外部系统入口        |
| `L2.5`                                              | 多个业务域共享的领域值对象、枚举、语义模型                  | Provider 实现、策略逻辑、执行策略                |
| `contracts`                                         | 跨域稳定端口、事件协议、DTO 契约                            | 域内接口、临时适配器、通用工具函数、领域模型全集 |
| `x.go`                                              | 配置加载、依赖创建、模块 wiring、生命周期管理               | 因子计算、信号判断、风控规则、订单路由           |
| `observex` / `alertx`                               | 指标、追踪、日志、告警事件                                  | 业务决策和风控放行逻辑                           |

## 域间关系与反馈

- **数据域 → 分析域**：单向，原始数据和标准化行情进入因子计算。
- **分析域 ↔ 决策域**：因子驱动信号生成；回测结果和评估指标反馈到 factor-eval / feature-store。
- **决策域 → 执行域**：信号必须先经过 risk-engine，禁止绕过风控直接调用 order-engine。
- **执行域 → 决策域**：通过 fills / positions / PnL / exposure events 反馈组合再平衡和策略调整，不反向直接调用决策内部实现。
- **x.go → 各域**：只做启动和组装依赖，不参与业务链路计算。

## 依赖守卫

| 守卫       | 允许                                                     | 禁止                                                | 验收方式                                  |
| ---------- | -------------------------------------------------------- | --------------------------------------------------- | ----------------------------------------- |
| Foundation 矩阵 | L0/L1/runtime/test-only 依赖符合 Foundation 依赖矩阵 | 反向依赖、运行时导入 `testkitx`、L1 模块彼此强耦合 | `xlibgate` 或 import graph 检查 |
| Go baseline | Foundation 模块共享 Go toolchain baseline | `testkitx` 单独拉高下游测试工具链，或 `configx` / `observex` 长期停留 `foundationx` 兼容垫片 | `go.mod` 扫描与 release evidence |
| `resiliencx` 身份 | timeout/retry/circuit/bulkhead/rate/fallback/policy event | Standard Source、Generator、Harness 主身份回流到 `resiliencx` | README/docs 一致性 gate + contract tests |
| `testkitx` 边界 | 仅测试包、测试 fixture、harness、boundary evidence 导入 | production Go 文件导入 `testkitx` | `make boundary-testkit` 或 import scan |
| 可观测脱敏 | 低基数、非敏感 label；secret redaction 覆盖日志、health、manifest | `order_id`、`account_id`、`api_key`、trace id 等进入普通 metrics label | schema/golden + secret leak test |
| 业务域依赖 | 数据域/分析域/决策域/执行域导入 L2.5、contracts 和基座   | 业务域互相导入实现包，尤其执行域反向导入决策域      | `go list` 或依赖图中无业务域实现包反向边  |
| 决策到执行 | signal-factory / optimizer 通过 risk-engine 提交执行意图 | 绕过 risk-engine 直接调用 order-engine 或交易所 SDK | paper trade 链路能证明 risk gate 必经     |
| 执行反馈   | fills / positions / PnL / exposure 以事件进入决策域      | execution 包同步调用 strategy / backtest 内部实现   | 事件 topic、DTO 和消费方在 contracts 固化 |
| contracts  | 跨域端口、事件协议、DTO                                  | 领域模型全集、通用工具、域内临时接口                | 新增契约必须说明消费方、生产方和稳定期    |
| x.go       | 读取配置、创建依赖、连接模块、管理生命周期               | 因子计算、信号生成、风控判断、订单路由              | 入口包只出现 wiring / lifecycle 测试      |

## 契约固化优先级

1. **数据输入契约**：MarketDataProvider / MacroDataProvider
2. **因子契约**：FactorInput / FactorOutput / FactorEvaluation
3. **决策契约**：SignalIntent / PortfolioTarget
4. **执行契约**：RiskDecision / OrderIntent / ExecutionReport
5. **反馈契约**：PositionSnapshot / PnLReport / ExposureEvent

## 核心设计原则

1. **Foundation 先边界后功能** — 先固化 `xlib-standard`、依赖矩阵、Go baseline 和 release gate，再扩大 L1 能力面
2. **`xlib-standard` 不是运行时依赖** — 它是标准事实源、模板、Gate 和 Evidence 输入，不承载业务运行
3. **`resiliencx` 只做运行时弹性** — timeout/retry/circuit/bulkhead/rate/fallback 属于它，交易风控属于 `risk-engine`
4. **`testkitx` 只能 test-only** — 生产 import graph 不允许出现测试工具包
5. **风控是独立引擎** — 策略只能通过 risk-engine 提交订单，不能直接调用 order-engine
6. **回测与实盘共享代码** — signal-factory / factor-engine / risk-engine 同一套，backtest-engine 只替换数据源和撮合/回放环境
7. **contracts 只定义跨域稳定契约** — 跨域端口、事件协议、DTO 放在 contracts；域内接口留在域内，领域值对象放在 L2.5
8. **领域语义沉到 L2.5** — 多域共享的 Price/Qty/Tick/Quote/MacroPoint 等模型统一来自 decimalx / domain-\*，避免各域重复定义
9. **数据职责不跨域** — 数据域只负责采集、标准化和存储，因子计算在分析域，策略逻辑在决策域
10. **执行抽象交易所差异** — order-engine 对上层暴露统一接口，内部适配各交易所
11. **反馈通过事件表达** — 执行结果、仓位、PnL、风险暴露以事件反馈决策域，避免执行域反向调用决策内部实现
12. **x.go 只做组合根** — 不含业务逻辑，仅负责启动、配置加载、依赖组装和生命周期控制
13. **域内平级协作** — 同域模块不编号、不分先后，按需协作

## 进度校准标准

| 等级 | 图形      | 定义                                 |
| ---- | --------- | ------------------------------------ |
| 初始 | ░░░░ 5%   | 仅 README + LICENSE，无业务代码      |
| 骨架 | █░░░ 15%  | 有 go.mod + 接口定义，核心逻辑未实现 |
| 半成 | ██░░ 50%  | 核心功能可用，缺少边界场景和文档     |
| 成熟 | ███░ 80%  | 核心功能完整，有测试覆盖，可用于生产 |
| 发布 | ███░ 90%  | 版本化发布，文档完整，长期维护       |
| 完备 | ████ 100% | 全功能、全测试、全文档、生产验证     |

## 状态总览

| 域                    | 组件                                                            | 版本   | 状态      | 进度     | 说明                                                                                      |
| --------------------- | --------------------------------------------------------------- | ------ | --------- | -------- | ----------------------------------------------------------------------------------------- |
| **基座**              |                                                                 |        |           |          |                                                                                           |
| 基座                  | [kernel](https://github.com/ZoneCNH/kernel)                     | v0.7.3 | ✅ 已有   | ███░ 80% | L0 标准库扩展原语：error/time/context/lifecycle/health/sync，保持 stdlib-only             |
| 基座                  | [configx](https://github.com/ZoneCNH/configx)                   | v0.1.4 | ✅ 已有   | ███░ 80% | 显式配置加载、合并、校验、脱敏、provenance 与 config hash                                  |
| 基座                  | [observex](https://github.com/ZoneCNH/observex)                 | v0.3.1 | ✅ 已有   | ███░ 80% | vendor-neutral 日志、指标、追踪、健康、字段和 label policy 契约                            |
| 基座                  | [testkitx](https://github.com/ZoneCNH/testkitx)                 | v0.4.0 | ✅ 已有   | ███░ 80% | 测试专用 evidence/golden/fixture/harness/boundary 工具包，禁止生产导入                    |
| 基座                  | [resiliencx](https://github.com/ZoneCNH/resiliencx)             | v0.4.8 | ⚠️ P0     | ██░░ 50% | 身份需从标准模板库修正为运行时弹性策略库：timeout/retry/circuit/bulkhead/rate/fallback    |
| 基座                  | [schedulex](https://github.com/ZoneCNH/schedulex)               | v0.1.2 | ✅ 已有   | ███░ 80% | 确定性任务调度：trigger/clock/misfire/overlap/jitter/EventSink/Locker interface           |
| 基座                  | [xlibgate](https://github.com/ZoneCNH/xlibgate)                 | -      | ✅ 已有   | -        | import 边界、go.mod、Go baseline、release evidence 机器门禁                               |
| 基座                  | [xlib-standard](https://github.com/ZoneCNH/xlib-standard)       | -      | ✅ 已有   | -        | 标准事实源、模板、Gate 与 Evidence；不参与运行时依赖                                      |
| 基座                  | [redisx](https://github.com/ZoneCNH/redisx)                     | -      | ✅ 已有   | █░░░ 15% | Redis，仅骨架                                                                             |
| 基座                  | [kafkax](https://github.com/ZoneCNH/kafkax)                     | -      | ✅ 已有   | █░░░ 15% | Kafka，仅骨架                                                                             |
| 基座                  | [natsx](https://github.com/ZoneCNH/natsx)                       | -      | ✅ 已有   | ███░ 80% | NATS，349KB/27 项                                                                         |
| 基座                  | [postgresx](https://github.com/ZoneCNH/postgresx)               | -      | ✅ 已有   | █░░░ 15% | PostgreSQL，仅骨架                                                                        |
| 基座                  | [taosx](https://github.com/ZoneCNH/taosx)                       | -      | ✅ 已有   | █░░░ 15% | TDengine，仅骨架                                                                          |
| 基座                  | [ossx](https://github.com/ZoneCNH/ossx)                         | -      | ✅ 已有   | █░░░ 15% | 对象存储，仅骨架                                                                          |
| 基座                  | [clickhousex](https://github.com/ZoneCNH/clickhousex)           | -      | ✅ 已有   | █░░░ 15% | ClickHouse，仅骨架                                                                        |
| 基座                  | [contracts](https://github.com/ZoneCNH/contracts)               | -      | ✅ 已有   | ███░ 80% | 跨域稳定端口/事件/DTO 契约，191KB/27 项                                                   |
| **L2.5 · 领域共享层** |                                                                 |        |           |          |                                                                                           |
| L2.5                  | [decimalx](https://github.com/ZoneCNH/decimalx)                 | v0.1.0 | ✅ P0     | ███░ 80% | 高精度十进制类型（Decimal/Price/Qty/Ratio/Money）                                         |
| L2.5                  | [domain-market](https://github.com/ZoneCNH/domain-market)       | v0.1.0 | ✅ P0     | ███░ 80% | 市场数据域模型（Tick/Quote/Bar/OrderBook）                                                |
| L2.5                  | [domain-exchange](https://github.com/ZoneCNH/domain-exchange)   | v0.1.0 | ✅ P0     | ███░ 80% | 交易域模型（VenueAdapter 13 方法接口）                                                    |
| L2.5                  | [domain-macro](https://github.com/ZoneCNH/domain-macro)         | v0.1.0 | ✅ P0     | ███░ 80% | 宏观数据域模型（MacroPoint/MacroState）                                                   |
| **数据域 · 行情**     |                                                                 |        |           |          |                                                                                           |
| 数据域                | [binance](https://github.com/ZoneCNH/binance)                   | -      | ✅ 已有   | ███░ 80% | Binance CEX SDK                                                                           |
| 数据域                | [okx](https://github.com/ZoneCNH/okx)                           | -      | ✅ 已有   | ███░ 80% | OKX CEX SDK                                                                               |
| 数据域                | [bybit](https://github.com/ZoneCNH/bybit)                       | -      | ✅ 已有   | ███░ 80% | Bybit CEX SDK                                                                             |
| 数据域                | [bitget](https://github.com/ZoneCNH/bitget)                     | -      | ✅ 已有   | ███░ 80% | Bitget CEX SDK                                                                            |
| 数据域                | [kucoin](https://github.com/ZoneCNH/kucoin)                     | -      | ✅ 已有   | ███░ 80% | KuCoin CEX SDK                                                                            |
| 数据域                | [gate](https://github.com/ZoneCNH/gate)                         | -      | ✅ 已有   | ███░ 80% | Gate CEX SDK                                                                              |
| 数据域                | [mexc](https://github.com/ZoneCNH/mexc)                         | -      | ✅ 已有   | ███░ 80% | MEXC CEX SDK                                                                              |
| 数据域                | [htx](https://github.com/ZoneCNH/htx)                           | -      | ✅ 已有   | ███░ 80% | HTX CEX SDK                                                                               |
| 数据域                | [coinbase](https://github.com/ZoneCNH/coinbase)                 | -      | ✅ 已有   | ███░ 80% | Coinbase CEX SDK                                                                          |
| 数据域                | [hyperliquid](https://github.com/ZoneCNH/hyperliquid)           | -      | ✅ 已有   | ███░ 80% | Hyperliquid DEX SDK                                                                       |
| 数据域                | [lighter](https://github.com/ZoneCNH/lighter)                   | -      | ✅ 已有   | ███░ 80% | Lighter DEX SDK                                                                           |
| 数据域                | [upbit](https://github.com/ZoneCNH/upbit)                       | -      | ✅ 已有   | ███░ 80% | Upbit CEX SDK                                                                             |
| 数据域                | [coinglass](https://github.com/ZoneCNH/coinglass)               | -      | ✅ 已有   | ███░ 80% | 衍生品聚合数据                                                                            |
| 数据域                | [yield-curve](https://github.com/ZoneCNH/yield-curve)           | -      | ✅ 已有   | ███░ 80% | 收益率曲线                                                                                |
| 数据域                | [binance-market](https://github.com/ZoneCNH/binance-market)     | v0.1.0 | ✅ P0     | ███░ 80% | Binance Kline/Ticker Provider                                                             |
| 数据域                | [bybit-market](https://github.com/ZoneCNH/bybit-market)         | v0.1.0 | ✅ P0     | ███░ 80% | Bybit Kline/Ticker Provider                                                               |
| 数据域                | [bitget-market](https://github.com/ZoneCNH/bitget-market)       | v0.1.0 | ✅ P0     | ███░ 80% | Bitget Kline/Ticker Provider                                                              |
| 数据域                | [okx-market](https://github.com/ZoneCNH/okx-market)             | v0.1.0 | ✅ P0     | ███░ 80% | OKX Kline/Ticker Provider                                                                 |
| 数据域                | [coinbase-market](https://github.com/ZoneCNH/coinbase-market)   | v0.1.0 | ✅ P0     | ███░ 80% | Coinbase Kline/Ticker Provider                                                            |
| **数据域 · 宏观**     |                                                                 |        |           |          |                                                                                           |
| 数据域                | [fred](https://github.com/ZoneCNH/fred)                         | -      | ✅ 已有   | ███░ 80% | 美联储 FRED                                                                               |
| 数据域                | [treasury](https://github.com/ZoneCNH/treasury)                 | -      | ✅ 已有   | ███░ 80% | 美国财政部                                                                                |
| 数据域                | [bea](https://github.com/ZoneCNH/bea)                           | -      | ✅ 已有   | ███░ 80% | 美国经济分析局                                                                            |
| 数据域                | [ecb](https://github.com/ZoneCNH/ecb)                           | -      | ✅ 已有   | ███░ 80% | 欧洲央行                                                                                  |
| 数据域                | [uk-cb](https://github.com/ZoneCNH/uk-cb)                       | -      | ✅ 已有   | ███░ 80% | 英国央行                                                                                  |
| 数据域                | [japan-cb](https://github.com/ZoneCNH/japan-cb)                 | -      | ✅ 已有   | ███░ 80% | 日本央行                                                                                  |
| 数据域                | [eastmoney](https://github.com/ZoneCNH/eastmoney)               | -      | ✅ 已有   | ███░ 80% | 东方财富 A 股                                                                             |
| 数据域                | [jinshi](https://github.com/ZoneCNH/jinshi)                     | -      | ✅ 已有   | ███░ 80% | 金十快讯                                                                                  |
| 数据域                | [jin10](https://github.com/ZoneCNH/jin10)                       | -      | ✅ 已有   | ███░ 80% | 金十行情                                                                                  |
| 数据域                | [yahoo](https://github.com/ZoneCNH/yahoo)                       | -      | ✅ 已有   | ███░ 80% | Yahoo Finance                                                                             |
| **数据域 · 另类**     |                                                                 |        |           |          |                                                                                           |
| 数据域                | [alternative-data](https://github.com/ZoneCNH/alternative-data) | -      | 🔨 已创建 | ░░░░ 5%  | 链上、社交情绪、新闻 NLP                                                                  |
| **分析域**            |                                                                 |        |           |          |                                                                                           |
| 分析域                | [factor-engine](https://github.com/ZoneCNH/factor-engine)       | -      | 🔨 已创建 | ░░░░ 5%  | 从原始数据计算 alpha 因子                                                                 |
| 分析域                | [feature-store](https://github.com/ZoneCNH/feature-store)       | -      | 🔨 已创建 | ░░░░ 5%  | 因子版本管理、IC 评估                                                                     |
| 分析域                | [factor-eval](https://github.com/ZoneCNH/factor-eval)           | -      | 🔨 已创建 | ░░░░ 5%  | IC/IR/换手率评估                                                                          |
| 分析域                | [market_regime](https://github.com/ZoneCNH/market_regime)       | -      | 🔨 已创建 | ░░░░ 5%  | 市场状态识别（S1-S7：多头趋势/挤空/空头/踩踏/震荡/低波/压缩）                             |
| 分析域                | [macro_regime](https://github.com/ZoneCNH/macro_regime)         | -      | 🔨 已创建 | ░░░░ 5%  | 宏观经济体制识别（M1-M7：流动牛市/再通复苏/软着繁荣/鹰派通胀/衰退降息/信用去杠/滞胀冲击） |
| 分析域                | [regime-engine](https://github.com/ZoneCNH/regime-engine)       | -      | 🔨 已创建 | ░░░░ 5%  | M×S 联合决策引擎（M+S → action/risk_tier/position_caps/trade_permission）                 |
| 分析域                | [ms_brain](https://github.com/ZoneCNH/ms_brain)                 | -      | ✅ 已有   | -        | M×S 系统架构分析体系                                                                      |
| **决策域**            |                                                                 |        |           |          |                                                                                           |
| 决策域                | [signal-factory](https://github.com/ZoneCNH/signal-factory)     | -      | 🔨 已创建 | ░░░░ 5%  | 多因子信号生成、过滤、评分                                                                |
| 决策域                | [backtest-engine](https://github.com/ZoneCNH/backtest-engine)   | -      | 🔨 已创建 | ░░░░ 5%  | 事件驱动回测、Tick 级回放                                                                 |
| 决策域                | [optimizer](https://github.com/ZoneCNH/optimizer)               | -      | 🔨 已创建 | ░░░░ 5%  | 参数搜索、Walk-forward 验证                                                               |
| 决策域                | [strategies](https://github.com/ZoneCNH/strategies)             | -      | ✅ 已有   | ██░░ 60% | 策略研究与参考库，3.5MB/746 项                                                            |
| **执行域**            |                                                                 |        |           |          |                                                                                           |
| 执行域                | [risk-engine](https://github.com/ZoneCNH/risk-engine)           | -      | 🔨 已创建 | ░░░░ 5%  | VaR、止损、持仓限额、压力测试                                                             |
| 执行域                | [order-engine](https://github.com/ZoneCNH/order-engine)         | -      | 🔨 已创建 | ░░░░ 5%  | 智能路由、TWAP/VWAP、滑点控制                                                             |
| 执行域                | [portfolio-engine](https://github.com/ZoneCNH/portfolio-engine) | -      | 🔨 已创建 | ░░░░ 5%  | 多策略资金分配、再平衡                                                                    |
| 执行域                | [settlement](https://github.com/ZoneCNH/settlement)             | -      | 🔨 已创建 | ░░░░ 5%  | PnL 计算、交易所对账                                                                      |
| **入口**              |                                                                 |        |           |          |                                                                                           |
| 入口                  | [x.go](https://github.com/ZoneCNH/x.go)                         | v0.0.1 | ✅ 已有   | ███░ 80% | 组合根，2.8MB/33 项                                                                       |
| **横切**              |                                                                 |        |           |          |                                                                                           |
| 横切                  | [alertx](https://github.com/ZoneCNH/alertx)                     | -      | 🔨 已创建 | ░░░░ 5%  | 策略异常、风控触发告警                                                                    |
| 横切                  | [observex](https://github.com/ZoneCNH/observex)                 | v0.3.1 | ✅ 已有   | ███░ 80% | 可观测性（同时归属基座，提供底层 metrics/tracing/logging）                                |
| **Rust**              |                                                                 |        |           |          |                                                                                           |
| Rust                  | [stdlib.rs](https://github.com/ZoneCNH/stdlib.rs)               | -      | ✅ 已有   | -        | Rust 标准库                                                                               |
| **独立**              |                                                                 |        |           |          |                                                                                           |
| 独立                  | [specs](https://github.com/ZoneCNH/specs)                       | -      | ✅ 已有   | -        | 项目技术规范与接口定义                                                                    |

## 建议实现顺序

```text
Foundation P0: 基础闭环校准 ← kernel + configx + observex + testkitx + resiliencx + schedulex
               1. resiliencx 从标准模板身份改回运行时弹性策略库
               2. xlib-standard 固定为标准事实源 / 模板 / Gate / Evidence
               3. configx / observex 迁移到 kernel，或标注 foundationx 兼容期
               4. 统一 Foundation Go baseline
               5. 用 xlibgate / 脚本执行依赖矩阵、testkitx 边界和 release evidence

Phase 0: 领域共享层 ← decimalx + domain-market + domain-exchange + domain-macro
         ✅ 已完成 (v0.1.0)，所有上层模块已依赖此层

Phase 1: 分析域   ← factor-engine + feature-store + factor-eval
         先固化 MarketDataProvider / FactorInput / FactorOutput；
         退出条件是 market provider → factor-engine → factor-eval 可跑通

Phase 2: 决策域   ← signal-factory + backtest-engine + optimizer
         先固化 SignalIntent / PortfolioTarget；
         退出条件是 signal → backtest → factor feedback 可跑通

Phase 3: 执行域   ← risk-engine + order-engine + portfolio-engine
         先固化 RiskDecision / OrderIntent / ExecutionReport；
         退出条件是 signal → risk-engine → paper order-engine → portfolio update 可跑通

Phase 4: 平台化   ← settlement + alertx + alternative-data
         先固化 PositionSnapshot / PnLReport / ExposureEvent；
         生产化运维能力；执行反馈以事件回到决策域

Phase 5: 入口验收 ← x.go
         只补最终 wiring 和生命周期，验证完整闭环，不新增业务逻辑
```
