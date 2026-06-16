# 🏗️ 分层架构

> FoundationX 量化交易基础设施的完整依赖拓扑
>
> 按职责域组织，拆分代码依赖、业务流与运行时组装视角

## 架构视图

依赖、业务流和运行时组装刻意分开呈现：业务数据从数据域走向执行域，代码依赖不反向穿透；`x.go` 是组合根（Composition Root），不是业务链路终点。

> 🔄 三引擎数据流全景（market_engine→S / macro_engine→M / regime_engine→DecisionCard）、M×S 矩阵、契约固化清单 → **[DATAFLOW.md](./DATAFLOW.md)**
>
> 🗺️ 六阶段交付路线图、任务编号与验收标准 → **[ROADMAP.md](./ROADMAP.md)**

### 代码依赖拓扑

```text
依赖方向：左侧模块可以导入右侧模块。

x.go ───────────────► 基座运行时 / L2.5 / 数据域 / 分析域 / 决策域 / 执行域

数据域 ─┐
分析域 ─┼──────────► L2.5 Domain Shared
决策域 ─┤             domainx · decimalx · domain-market · domain-exchange · domain-macro
执行域 ─┘
   │
   ├───────────────► contracts
   │                  跨域稳定端口、事件协议、DTO 契约
   │
   ├───────────────► transportx
   │                  跨 runtime / adapter 传输契约
   │
   └───────────────► 基座运行时 Foundation (19)
                      L0: kernel
                      L1 runtime: configx · observex · resiliencx · schedulex
                      L1 test-only: testkitx
                      扩展: redisx · kafkax · natsx · postgresx · taosx · ossx · clickhousex
                      契约: contracts · transportx
                      

标准与门禁：
  xlib-standard ─── 标准事实源 / Go Reference Template，不参与业务运行
  xlib-harness  ─── 模块生成器（generate）与门禁执行器（spec-lint / boundary / traceability / format-check）
  xlib-evidence ─── 证据收集与发布运行时（coverage / manifest / remote evidence / report）
  xlibgate      ─── import 边界、go.mod、Go baseline、release evidence、L2 发布就绪、Trust Alignment 机器门禁

横切关注点：
  alertx   ─── 策略异常、风控触发告警
  observex ─── 统一 metrics / tracing / logging（同时作为基座组件提供底层能力）
```text

### 业务流与反馈

```text
market-data (14) ──────────────► market_regime ──┐
  domain-market (Bar/Tick/OB)     S1-S7 状态     │
  质量门禁 → 特征 → 分类器       bias/permission  │
                                               ├──► regime-engine ──► DecisionCard
macro-data (10) ───────────────► macro_regime ──┘     M×S 融合        action A-E
  domain-macro (MacroPoint)      M1-M7 状态           冲突门           profile
  LGIP 四因子                    LGIP 得分            风险放大          risk_tier
                                                                      position_caps
factor-engine ◄──► feature-store ◄──► factor-eval
              │      ▲                  ▲  ▲
              ▼      │                  │  │
            flowx ───┘                  │  │  (因子评估 + DecisionCard)
              (ETL)                     │  │
              │                         │  │
              │           regime-engine─┘  │
              │                │           │
              │                ▼           │
              │          signal-factory ◄──┘
              │                │
              │                ├──► riskx ──► orderx ──► positionx  (实盘路径)
              │                │      ▲         ▲           │
              │                │      │         │           ▼
              │                │      └─ fills ─┘   决策域 ◄── positions/PnL
              │                │
              │                └──► backtestx ──► optimizer ──► strategyx  (回测→反馈)
              │                                                      ▲
              │                                                      │
              └──► maestro ──────────────────────────────────────────┘  (编排注入)
```text

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
```text

## 思路推演 — 2026-06-14 业务域模块化决策

### 为什么新增 7 个业务域模块

在此次推演之前，分析/决策/执行域仅有早期占位仓库（factor-engine、backtest-engine、risk-engine 等），缺乏规范化规格和接口契约。本次以 23 节 SPEC 结构为每个域创建了具名模块（X 后缀），形成从数据到执行的完整链路：

```text
flowx ──► signal-factory ──► strategyx ──► maestro ──► riskx ──► orderx ──► positionx
(数据管线) (信号生成)       (策略工厂)  (工作流)     (风控)     (订单)     (仓位)
```

### 命名约定：为什么是 X 后缀

| 旧名（占位） | 新名 | 理由 |
|---|---|---|
| risk-engine | riskx | 统一 Foundation 命名风格（configx, redisx, kafkax...），旧名保留为 GitHub 仓库并存但以新 SPEC 为准 |
| order-engine | orderx | 同上 |
| portfolio-engine | positionx | 职责更精确——定位为跨账户仓位管理，而非完整投资组合 |
| backtest-engine | backtestx | 同上 |
| (无) | maestro | 新概念——工作流编排填补了策略到执行之间的空白 |
| (无) | flowx | 新概念——数据流管线填补了行情到因子之间的空白 |

### 关键边界决策

1. **contracts 不拥有传输**：contracts 定义"传什么"（DTO、端口、事件协议），但不绑定 HTTP/gRPC/Kafka/NATS 实现。传输职责在 transportx 和具体 adapter。

2. **transportx 不承载业务 DTO**：transportx 定义"怎么传"（Envelope、Middleware、Error mapping），但不定义 MarketEvent、OrderCommand 等业务对象。业务 DTO 归 contracts。

3. **maestro 不计算、不判断、不下单**：maestro 是纯编排引擎——它协调 strategyx（计算信号）、riskx（风控判断）、orderx（下单执行），自己不含业务逻辑。

4. **回测与实盘共享代码**：backtestx 明确规定必须使用与实盘相同的 factor-engine、strategyx、riskx 代码路径，杜绝回测偏差。

5. **Module Identity**：全部 9 个新规格模块均含 FR（Module Identity），要求 README H1 = 模块名、go.mod = `github.com/ZoneCNH/<module>`，禁止 xlib-standard 身份残留。

### 各域说明

| 域     | 职责                                                                                                                          | 组件                                                                                                                                                       |
| ------ | ----------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 基座   | 标准源、生成器、证据运行时、L0 原语、L1 运行时横切能力、测试期证据、存储扩展、稳定契约与传输契约                                         | xlib-standard, xlib-harness, xlib-evidence, kernel, configx, observex, testkitx, resiliencx, schedulex, xlibgate, redisx, kafkax, natsx, postgresx, taosx, ossx, clickhousex, contracts, transportx |
| L2.5   | 领域共享值对象和语义模型，上层统一依赖                                                                                        | domainx, decimalx, domain-market, domain-exchange, domain-macro                                                                                         |
| 数据域 | 行情、宏观、另类数据采集                                                                                                      | market-data (14: 1 dispatch + 12 SDK + 1 C/S Module), macro-data (10), alternative-data                                                                                       |
| 分析域 | 因子计算、特征存储、因子评估、市场/宏观环境分类、数据流管线、M×S 联合决策（三引擎：market_engine→S / macro_engine→M / regime_engine→M+S） | factor-engine, feature-store, factor-eval, market_regime, macro_regime, regime-engine, ms_brain, flowx                                                              |
| 决策域 | 信号生成、历史回测、参数优化、策略工厂、工作流编排（并行协作）                                                                  | signal-factory, backtest-engine, optimizer, backtestx, strategyx, maestro                                                                          |
| 执行域 | 风险管理、订单执行、仓位管理、结算                                                                                              | risk-engine, order-engine, portfolio-engine, settlement, riskx, orderx, positionx                                                                              |
| 入口   | 启动、配置加载、依赖组装、生命周期控制                                                                                        | x.go                                                                                                                                                       |
| 横切   | 告警、可观测性                                                                                                                | alertx, observex                                                                                                                                           |

## Foundation 规格文档（公开投影）

Foundation 模块的详细规格、依赖矩阵、执行跟踪和 ADR 集中在 `module/` 目录：

| 文档                                                                     | 定位                                                              |
| ------------------------------------------------------------------------ | ----------------------------------------------------------------- |
| [`module/foundation-modules.md`](./module/foundation-modules.md)         | Why & What — 模块定位、边界、能力需求、验证标准                   |
| [`module/FOUNDATION-SPEC.md`](./module/FOUNDATION-SPEC.md)               | How & Check — 接口签名、目录结构、CI gate、测试矩阵、Release DoD  |
| [`module/FOUNDATION-V1.md`](./module/FOUNDATION-V1.md)                   | v1 路线图 — 产品定义、一致性修复、Issue 拆分                      |
| [`module/FOUNDATION-DEPS.yaml`](./module/FOUNDATION-DEPS.yaml)           | 机器可读依赖矩阵，CI 可消费                                       |
| [`module/ADR-foundationx-exit.md`](./module/ADR-foundationx-exit.md)     | ADR：foundationx 兼容退出计划                                     |
| [`module/FOUNDATION-TRACKER.md`](./module/FOUNDATION-TRACKER.md)         | 执行跟踪器 — P0/P1/P2 Issue 检查清单                              |
| [`ROADMAP.md`](./ROADMAP.md)                                             | 六阶段交付路线图 — 任务编号、依赖链、验收标准                     |
| [`docs/governance/ROADMAP-RULES.md`](./docs/governance/ROADMAP-RULES.md) | ROADMAP 编写规范 — 状态流转、版本规划、任务拆分、维护原则         |
| [`CONSTITUTION.md`](./CONSTITUTION.md)                                   | 系统宪法 — FoundationX 全系统最高治理文件，覆盖模块实现与交付管线 |
| [`docs/sre/foundation-cicd-plan.md`](./docs/sre/foundation-cicd-plan.md) | SRE CI/CD — 基座层 19 模块 4 阶段部署方案、机器池架构、标准化模板   |

19 个基座模块的独立规格均为 23 节结构：行为规格 WHEN/THEN、接口契约、业务规则、错误处理、边界场景、验收标准、目录结构、CI Gate、测试矩阵、性能预算、可观测输出、发布 DoD。完整索引见 [`module/README.md`](./module/README.md)。`x.go` 组合根仍作为运行时入口维护，但不再作为 `module/` 下的模块规格。

| 层级          | 模块          | 完整规格                                                         |
| ------------- | ------------- | ---------------------------------------------------------------- |
| **L0 原语**   | kernel        | [`module/kernel/SPEC.md`](./module/kernel/SPEC.md)               |
| **L1 运行时** | configx       | [`module/configx/SPEC.md`](./module/configx/SPEC.md)             |
|               | observex      | [`module/observex/SPEC.md`](./module/observex/SPEC.md)           |
|               | resiliencx    | [`module/resiliencx/SPEC.md`](./module/resiliencx/SPEC.md)       |
|               | schedulex     | [`module/schedulex/SPEC.md`](./module/schedulex/SPEC.md)         |
| **L1 测试**   | testkitx      | [`module/testkitx/SPEC.md`](./module/testkitx/SPEC.md)           |
| **门禁**      | xlib-standard | [`module/xlib-standard/SPEC.md`](./module/xlib-standard/SPEC.md) |
|               | xlibgate      | [`module/xlibgate/SPEC.md`](./module/xlibgate/SPEC.md)           |
|               | xlib-harness  | [`module/xlib-harness/SPEC.md`](./module/xlib-harness/SPEC.md)   |
|               | xlib-evidence | [`module/xlib-evidence/SPEC.md`](./module/xlib-evidence/SPEC.md) |
| **存储扩展**  | redisx        | [`module/redisx/SPEC.md`](./module/redisx/SPEC.md)               |
|               | kafkax        | [`module/kafkax/SPEC.md`](./module/kafkax/SPEC.md)               |
|               | natsx         | [`module/natsx/SPEC.md`](./module/natsx/SPEC.md)                 |
|               | postgresx     | [`module/postgresx/SPEC.md`](./module/postgresx/SPEC.md)         |
|               | taosx         | [`module/taosx/SPEC.md`](./module/taosx/SPEC.md)                 |
|               | ossx          | [`module/ossx/SPEC.md`](./module/ossx/SPEC.md)                   |
|               | clickhousex   | [`module/clickhousex/SPEC.md`](./module/clickhousex/SPEC.md)     |
| **契约/传输** | contracts     | [`module/contracts/SPEC.md`](./module/contracts/SPEC.md)         |
|               | transportx    | [`module/transportx/SPEC.md`](./module/transportx/SPEC.md)       |
| **L2.5 · 领域共享层** | domainx       | [`module/domainx/SPEC.md`](./module/domainx/SPEC.md)             |

### 规格体系与治理文档

| 文档                                                                                 | 定位                                                        |
| ------------------------------------------------------------------------------------ | ----------------------------------------------------------- |
| [`docs/product/product-spec.md`](./docs/product/product-spec.md)                     | 产品规格 — Vision、Users、Goals、MVP Scope                  |
| [`docs/testing/test-strategy.md`](./docs/testing/test-strategy.md)                   | 测试策略 — 覆盖率、格式、工具、CI 集成                      |
| [`docs/testing/acceptance-tests.md`](./docs/testing/acceptance-tests.md)             | 验收测试 — 端到端验收场景和检查清单                         |
| [`docs/ai/agent-rules.md`](./docs/ai/agent-rules.md)                                 | AI 代理规则 — 编码、测试、安全、禁止事项                    |
| [`docs/ai/prompt-templates.md`](./docs/ai/prompt-templates.md)                       | Prompt 模板 — 审查、拆分、实现、自查、修复                  |
| [`docs/ai/code-review-rules.md`](./docs/ai/code-review-rules.md)                     | 代码审查规则 — AI 代理审查标准和流程                        |
| [`GLOSSARY.md`](./GLOSSARY.md)                                                       | 术语表 — 系统核心概念和缩写定义                             |
| [`docs/governance/DEFINITION-OF-READY.md`](./docs/governance/DEFINITION-OF-READY.md) | Spec Ready — spec 可以进入开发的前置条件                    |
| [`docs/governance/DEFINITION-OF-DONE.md`](./docs/governance/DEFINITION-OF-DONE.md)   | Spec Done — 模块实现完成的验收条件                          |
| [`docs/governance/TRACEABILITY.md`](./docs/governance/TRACEABILITY.md)               | 需求追踪 — FR → AC → TC → 实现全覆盖                        |
| [`docs/governance/anti-requirements.md`](./docs/governance/anti-requirements.md)     | 反需求 — 明确不做之事，防止范围蔓延                         |
| [`module/ADR-TEMPLATE.md`](./module/ADR-TEMPLATE.md)                                 | ADR 模板 — 架构决策记录标准格式                             |
| [`docs/governance/TASK-TEMPLATE.md`](./docs/governance/TASK-TEMPLATE.md)             | Task 模板 — AI 代理任务拆分标准格式                         |
| [`docs/governance/LIFECYCLE.md`](./docs/governance/LIFECYCLE.md)                     | 规格生命周期 — 六态状态机、流转规则、CI 集成                |
| [`docs/governance/SPEC-TEMPLATE.md`](./docs/governance/SPEC-TEMPLATE.md)             | 23 节结构模板 — 新建模块规格时复制本文件                    |
| [`docs/governance/AGENT-SPEC-TEMPLATE.md`](./docs/governance/AGENT-SPEC-TEMPLATE.md) | Agent Spec 模板 — 五层规格体系第五层，AI 代理角色/约束/协作 |

## Foundation 第一阶段闭环

这 6 个基础模块可以构成第一阶段最小闭环：`kernel` 提供 L0 原语，`configx` / `observex` / `resiliencx` / `schedulex` 提供 L1 运行时横切能力，`testkitx` 只服务测试期。

`xlib-standard` 是独立 Go module，承担标准事实源和 Go Reference Template 二类职责（Generator/Harness/Evidence 已拆分至 `xlib-harness` / `xlib-evidence`），不作为其他模块的运行时 import 依赖。

| 模块            | 层级          | 拥有                                                                                                                                                     | 不拥有                                                     |
| --------------- | ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| `xlib-standard` | 标准源        | 标准事实源、Go Reference Template（Generator/Harness/Evidence 已拆分至 xlib-harness / xlib-evidence）                          | 业务运行、运行时 import 依赖、模块实现身份                 |
| `kernel`        | L0 原语       | 12 子包轻量工具集：lifecycx/errx/healthx/obsx/retryx/shutdownx/syncx/timex/validx/versionx/contextx/contracttest（stdlib-only）                          | 配置解析、观测后端、存储、网络、业务 DTO、全局可变单例     |
| `configx`       | L1 运行时     | explicit source、merge、decode、validate、sanitize、provenance、config hash                                                                              | secret backend、全局配置中心、自动发现、业务配置结构体     |
| `observex`      | L1 运行时契约 | logger、metrics、tracer、field、redactor、label policy、health schema、noop、memory recorder                                                             | Prometheus/Otel/Zap 直接绑定、alert routing、业务监控规则  |
| `resiliencx`    | L1 运行时策略 | timeout、retry、circuit breaker、bulkhead、rate limiter、fallback、Policies 组合（budget/classifier/idempotency hint 为 v1.2+ 演进）                     | 交易风控、订单风险、交易所 SDK、调度、存储后端             |
| `schedulex`     | L1 运行时调度 | cron/interval/delay trigger、OverlapPolicy（Skip/Queue/Replace）、MisfirePolicy（Skip/RunOnce/CatchUp）、jitter、EventSink、Locker interface、Clock 注入 | 分布式锁实现、exactly-once、业务任务语义                   |
| `testkitx`      | L1 test-only  | FakeConfig/FakeLogger/FakeMeter/FakeTracer/FakeClock/FakeBreaker、Eventually、GoldenUpdate、BoundaryCheck、GoroutineLeakCheck、contract test             | production import、真实外部系统、L2/L3/chaos/soak 测试替代 |

### `resiliencx` 身份修复

`resiliencx` 必须回到 operational resilience：对不稳定外部依赖、任务、数据源、交易所 API、消息处理和调度任务提供可组合故障控制策略。

`risk-engine` 才负责 trading risk，二者不能混用。

`xlib-standard` v1.0.0 已发布（tag v1.0.0, PR #115），标准源和 Go Reference Template 职责已完整落地。Generator / Harness Gate / Evidence Runtime 职责已于 PR #233 拆分至 `xlib-harness` 和 `xlib-evidence`。`resiliencx` 已围绕 timeout、retry、circuit、bulkhead、rate limit、fallback 和 policy event 完成身份修复，测试覆盖率 100%。

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
| resiliencx | 允许      | 允许    | interface-only | test-only  | -          | 禁止      | 禁止 | 禁止     |
| schedulex  | 允许/可选 | 禁止    | interface-only | test-only  | 禁止       | -         | 禁止 | 禁止     |
| testkitx   | 允许      | test    | test           | -          | test       | test      | 禁止 | 禁止     |
| x.go       | 允许      | 允许    | 允许           | 禁止(prod) | 允许       | 允许      | -    | 允许     |

## 边界与接口职责

| 边界                                                | 放什么                                                                       | 不放什么                                         |
| --------------------------------------------------- | ---------------------------------------------------------------------------- | ------------------------------------------------ |
| `xlib-standard`                                     | 标准事实源、Go Reference Template（Generator/Harness/Evidence 已拆分至 xlib-harness / xlib-evidence） | 运行时业务依赖、具体弹性策略实现                 |
| `kernel`                                            | 最小稳定原语和 stdlib-only 基础能力                                          | 配置解析、观测后端、业务 DTO、存储/网络适配器    |
| `configx` / `observex` / `resiliencx` / `schedulex` | L1 横切运行时能力，彼此通过窄接口协作                                        | 业务模型、组合根职责、对彼此的强耦合反向依赖     |
| `testkitx`                                          | 测试、golden、contract、fixture、harness、boundary evidence                  | production import graph、真实外部系统入口        |
| `L2.5`                                              | 多个业务域共享的领域值对象、枚举、语义模型                                   | Provider 实现、策略逻辑、执行策略                |
| `contracts`                                         | 跨域稳定端口、事件协议、DTO 契约                                             | 域内接口、临时适配器、通用工具函数、领域模型全集 |
| `transportx`                                        | 应用通信底座契约：Envelope/Endpoint、ServiceIdentity、QoS、Codec、RPC、EventBus、Stream、Outbox/Inbox、Audit Plane、Data Classification、SchemaRegistry、conformance gate | 具体 broker/client、协议 SDK、业务语义、领域模型全集 |
| `x.go`                                              | 配置加载、依赖创建、模块 wiring、生命周期管理                                | 因子计算、信号判断、风控规则、订单路由           |
| `observex` / `alertx`                               | 指标、追踪、日志、告警事件                                                   | 业务决策和风控放行逻辑                           |

## 域间关系与反馈

- **数据域 → 分析域**：单向，原始数据和标准化行情进入因子计算。
- **分析域 ↔ 决策域**：因子驱动信号生成；回测结果和评估指标反馈到 factor-eval / feature-store。
- **决策域 → 执行域**：信号必须先经过 risk-engine，禁止绕过风控直接调用 order-engine。
- **执行域 → 决策域**：通过 fills / positions / PnL / exposure events 反馈组合再平衡和策略调整，不反向直接调用决策内部实现。
- **x.go → 各域**：只做启动和组装依赖，不参与业务链路计算。

## 依赖守卫

| 守卫              | 允许                                                              | 禁止                                                                                         | 验收方式                                  |
| ----------------- | ----------------------------------------------------------------- | -------------------------------------------------------------------------------------------- | ----------------------------------------- |
| Foundation 矩阵   | L0/L1/runtime/test-only 依赖符合 Foundation 依赖矩阵              | 反向依赖、运行时导入 `testkitx`、L1 模块彼此强耦合                                           | `xlibgate` 或 import graph 检查           |
| Go baseline       | Foundation 模块共享 Go toolchain baseline                         | `testkitx` 单独拉高下游测试工具链，或 `configx` / `observex` 长期停留 `foundationx` 兼容垫片 | `go.mod` 扫描与 release evidence          |
| `resiliencx` 身份 | timeout/retry/circuit/bulkhead/rate/fallback/policy event         | Standard Source、Generator、Harness 主身份回流到 `resiliencx`                                | README/docs 一致性 gate + contract tests  |
| `testkitx` 边界   | 仅测试包、测试 fixture、harness、boundary evidence 导入           | production Go 文件导入 `testkitx`                                                            | `make boundary-testkit` 或 import scan    |
| 可观测脱敏        | 低基数、非敏感 label；secret redaction 覆盖日志、health、manifest | `order_id`、`account_id`、`api_key`、trace id 等进入普通 metrics label                       | schema/golden + secret leak test          |
| 业务域依赖        | 数据域/分析域/决策域/执行域导入 L2.5、contracts 和基座            | 业务域互相导入实现包，尤其执行域反向导入决策域                                               | `go list` 或依赖图中无业务域实现包反向边  |
| 决策到执行        | signal-factory / optimizer 通过 risk-engine 提交执行意图          | 绕过 risk-engine 直接调用 order-engine 或交易所 SDK                                          | paper trade 链路能证明 risk gate 必经     |
| 执行反馈          | fills / positions / PnL / exposure 以事件进入决策域               | execution 包同步调用 strategy / backtest 内部实现                                            | 事件 topic、DTO 和消费方在 contracts 固化 |
| contracts         | 跨域端口、事件协议、DTO                                           | 领域模型全集、通用工具、域内临时接口                                                         | 新增契约必须说明消费方、生产方和稳定期    |
| transportx        | Envelope/Endpoint、ServiceIdentity、QoS、Codec、RPC、EventBus、Stream、Outbox/Inbox、Audit Plane、Data Classification、SchemaRegistry、conformance gate | 具体 broker/client、协议 SDK、业务语义、领域模型                                             | 新增通信契约必须说明 runtime / adapter 边界、QoS/codec/schema 兼容期和审计要求 |
| x.go              | 读取配置、创建依赖、连接模块、管理生命周期                        | 因子计算、信号生成、风控判断、订单路由                                                       | 入口包只出现 wiring / lifecycle 测试      |

## 契约固化优先级

1. **数据输入契约**：MarketDataProvider / MacroDataProvider
2. **因子契约**：FactorInput / FactorOutput / FactorEvaluation
3. **决策契约**：SignalIntent / PortfolioTarget
4. **执行契约**：RiskDecision / OrderIntent / ExecutionReport
5. **反馈契约**：PositionSnapshot / PnLReport / ExposureEvent

## 核心设计原则

1. **Foundation 先边界后功能** — 先固化 `xlib-standard`、依赖矩阵、Go baseline 和 release gate，再扩大 L1 能力面
2. **`xlib-standard` 不是运行时依赖** — 它是独立 Go module，承担标准事实源和 Go Reference Template 职责（Generator/Harness/Evidence 已拆分至 `xlib-harness` / `xlib-evidence`），不承载业务运行
3. **`resiliencx` 只做运行时弹性** — timeout/retry/circuit/bulkhead/rate/fallback 属于它，交易风控属于 `risk-engine`
4. **`testkitx` 只能 test-only** — 生产 import graph 不允许出现测试工具包
5. **风控是独立引擎** — 策略只能通过 risk-engine 提交订单，不能直接调用 order-engine
6. **回测与实盘共享代码** — signal-factory / factor-engine / risk-engine 同一套，backtest-engine 只替换数据源和撮合/回放环境
7. **contracts 只定义跨域稳定契约** — 跨域端口、事件协议、DTO 放在 contracts；域内接口留在域内，领域值对象放在 L2.5
8. **transportx 只定义应用通信底座契约** — Envelope/Endpoint、ServiceIdentity、QoS、Codec、RPC、EventBus、Stream、Outbox/Inbox、Audit Plane、Data Classification、SchemaRegistry 和 conformance gate 放在 transportx；具体 broker/client、协议 SDK、业务语义和领域模型留在 adapter 或业务域内
9. **领域语义沉到 L2.5** — 多域共享的 Price/Qty/Tick/Quote/MacroPoint 等模型统一来自 decimalx / domain-\*，避免各域重复定义
10. **数据职责不跨域** — 数据域只负责采集、标准化和存储，因子计算在分析域，策略逻辑在决策域
11. **执行抽象交易所差异** — order-engine 对上层暴露统一接口，内部适配各交易所
12. **反馈通过事件表达** — 执行结果、仓位、PnL、风险暴露以事件反馈决策域，避免执行域反向调用决策内部实现
13. **x.go 只做组合根** — 不含业务逻辑，仅负责启动、配置加载、依赖组装和生命周期控制
14. **域内平级协作** — 同域模块不编号、不分先后，按需协作

## 进度校准标准

| 等级 | 图形      | 定义                                 |
| ---- | --------- | ------------------------------------ |
| 初始 | ░░░░ 5%   | 仅 README + LICENSE，无业务代码      |
| 骨架 | █░░░ 15%  | 有 go.mod + 接口定义，核心逻辑未实现                                                    |
| 规格 | ██░░ 30%  | 完整 SPEC + TRACEABILITY + goal，文档就绪但未实现                                      |
| 半成 | ███░ 50%  | 核心功能可用或完整文档+任务就绪（tasks/prompts/evidence 齐备），缺少边界场景或代码实现  |
| 成熟 | ███░ 80%  | 核心功能完整，有测试覆盖，可用于生产 |
| 发布 | ███░ 90%  | 版本化发布，文档完整，长期维护       |
| 完备 | Spec→Code 满分 | 全功能、全测试、全文档、生产验证（定义口径，不构成单模块状态判断） |

## 状态总览

> **公开投影口径**：架构矩阵中的进度是 Spec→Code 管线投影；release/factory 以 `.foundationx/status/index.json` + `.foundationx/blockers.json` 为准。存在 RELEASE=❌ 或 BLK-001/002/003/006/007/008 open 时，不投影为 Foundation factory grade。

| 域                    | 组件                                                            | 版本   | 状态      | Spec→Code 投影 | 说明                                                                                      |
| --------------------- | --------------------------------------------------------------- | ------ | --------- | -------- | ----------------------------------------------------------------------------------------- |
| **基座**              |                                                                 |        |           |          |                                                                                           |
| 基座                  | [kernel](https://github.com/ZoneCNH/kernel)                     | v1.0.0 | ✅ 已发布 | Spec→Code 完成 | L0 原语 / 12 子包轻量工具集：lifecycx/errx/healthx/obsx/retryx/shutdownx/syncx/timex/validx/versionx/contextx/contracttest，stdlib-only，v1.0.0 已发布 |
| 基座                  | [configx](https://github.com/ZoneCNH/configx)                   | v1.0.0 | ✅ 已发布 | Spec→Code 完成 | 显式配置加载、多源合并（YAML/TOML/JSON/.env/Env/Map）、StrictDecode、SecretString 脱敏、SecretPolicy、Provenance、EffectiveConfigHash、SanitizedManifest、HealthCheck、Metrics；97.1% 覆盖率；此前误标 v0.1.4 已修正 |
| 基座                  | [observex](https://github.com/ZoneCNH/observex)                 | v0.3.1 | ✅ 已发布 | Spec→Code 完成 | vendor-neutral 日志、指标、追踪、健康、字段和 label policy 契约；此前误标 v1.0.0 已修正 |
| 基座                  | [testkitx](https://github.com/ZoneCNH/testkitx)                 | v0.4.0 | ✅ 已发布 | Spec→Code 完成 | Fake / Fixture / Golden / Contract / Leak / Boundary / Manifest 测试工具包；test-only；禁止生产导入；factory grade 不适用 |
| 基座                  | [resiliencx](https://github.com/ZoneCNH/resiliencx)             | v0.4.9 | ✅ 已发布 | Spec→Code 完成 | 运行时弹性策略库：timeout/retry/circuit/bulkhead/rate/fallback；此前误标 v1.0.1 已修正 |
| 基座                  | [schedulex](https://github.com/ZoneCNH/schedulex)               | v1.0.0 | ✅ 已发布 | Spec→Code 完成 | cron/interval/delay 调度、OverlapPolicy（Skip/Queue/Replace）、MisfirePolicy（Skip/RunOnce/CatchUp）、EventSink、Locker、Clock 注入；98.2% 覆盖，release-check 通过 |
| 基座                  | [xlibgate](https://github.com/ZoneCNH/xlibgate)                 | v1.0.0 | ✅ 已发布 | Spec→Code 完成 | check / l2 / trust 三组门禁；全管线评分 100 |
| 基座                  | [xlib-standard](https://github.com/ZoneCNH/xlib-standard)       | v1.0.0 | ✅ 已发布 | Spec→Code 完成 | 标准事实源、Go Reference Template；Generator/Harness/Evidence 已拆分，不参与运行时 import |
| 基座                  | [xlib-harness](https://github.com/ZoneCNH/xlib-harness)         | v0.1.0 | ✅ 已发布 | Spec→Code 完成 | 模块生成器与门禁执行器：generate/scaffold、spec-lint、boundary-check、traceability-gate；✅ GitHub Release v0.1.0 已发布 |
| 基座                  | [xlib-evidence](https://github.com/ZoneCNH/xlib-evidence)       | v0.1.0 | ✅ 已发布 | Spec→Code 完成 | 证据收集与发布运行时：collect-coverage、generate-manifest、validate-manifest、report；✅ GitHub Release v0.1.0 已发布 |
| 基座                  | [redisx](https://github.com/ZoneCNH/redisx)                     | v1.0.1 | ✅ 已发布 | Spec→Code 完成 | Redis L2 adapter：KV/TTL/Hash/List/Pipeline/Cache-aside/Lock/RateLimit/Pool/Persistence restart recovery；Docker-backed Redis 验证通过 |
| 基座                  | [kafkax](https://github.com/ZoneCNH/kafkax)                     | v1.0.2 | ✅ 已发布 | Spec→Code 完成 | Kafka L2 adapter — 消息队列、事件流（v1.0.0 已发布，driver-neutral API + kafka-go 生产驱动，真实 broker gates） |
| 基座                  | [natsx](https://github.com/ZoneCNH/natsx)                       | v1.0.0 | ✅ 已发布 | Spec→Code 完成 | NATS L2 adapter：Core NATS / JetStream、Drain/reconnect/degraded health、canonical `FOUNDATIONX_NATS_*` 配置和真实 dev auth live gate 已验证；repair-slice 20/20；正式四源 98+ arbiter 与生产 TLS gate 待补（BLK-001/BLK-002）；非 factory |
| 基座                  | [postgresx](https://github.com/ZoneCNH/postgresx)               | v1.0.0 | ✅ 已发布 | Spec→Code 完成 | PostgreSQL — 关系型存储、事务、迁移；live integration 通过；BLK-006 open（52.4% coverage + Docker integration skip）；非 factory |
| 基座                  | [taosx](https://github.com/ZoneCNH/taosx)                       | v1.0.1 | ✅ 已发布 | Spec→Code 完成 | TDengine L2 adapter contract；真实 taosWS WebSocket 集成测试已通过；BLK-007 open（SPEC 67）；非 factory |
| 基座                  | [ossx](https://github.com/ZoneCNH/ossx)                         | v1.0.1 | ✅ 已发布 | Spec→Code 完成 | Aliyun OSS 对象存储 L2 adapter；真实 Aliyun OSS 集成测试、race、vet、build、release-check 与 100.0% 覆盖已验证（仅覆盖验证口径，不等同于 factory-ready）；BLK-008 open：API 文档 / integration evidence / quickstart / release manifest 未归档；非 factory；S3/MinIO/Azure/GCS Provider 仅保留扩展位 |
| 基座                  | [clickhousex](https://github.com/ZoneCNH/clickhousex)           | v1.0.1 | ✅ 已发布 | Spec→Code 完成 | ClickHouse — OLAP 查询、批量写入；✅ GitHub Release v1.0.1 已发布；BLK-003 open；非 factory |
| 基座                  | [contracts](https://github.com/ZoneCNH/contracts)               | v1.2.0 | ✅ 已发布 | Spec→Code 完成 | 跨域稳定端口/事件/DTO 契约（含 §8.4 Binance C/S ingestion contract）；spec-only；✅ GitHub Release v1.2.0 已发布 |
| 基座                  | [transportx](https://github.com/ZoneCNH/transportx)             | v1.1.1-spec | ✅ 已发布 | Spec→Code 完成 | 应用通信底座规格基线；✅ GitHub Release v1.1.1-spec 已发布 |
| **L2.5 · 领域共享层** |                                                                 |        |           |          |                                                                                           |
| L2.5                  | [domainx](https://github.com/ZoneCNH/domainx)                   | v1.0.1 | ✅ 已有   | Spec→Code 完成 | 领域共享值对象基线：Order/Position/Trade/Portfolio/ExecutionReport 与 OrderState/OrderType/OrderSide 枚举（8 FR，8 TC，6 tasks）；公开 v1.0.1 GitHub Release/tag 已观测并完成 release 对账；factory grade；live/soak N/A（纯值对象库） |
| L2.5                  | [decimalx](https://github.com/ZoneCNH/decimalx)                 | v1.0.0 | ✅ 已有   | Spec→Code 完成 | 高精度十进制类型（Decimal/Price/Qty/Ratio/Money）；v1.0.0 GitHub Release 已发布；8 FR Done；factory grade；live/soak N/A（纯值对象库） |
| L2.5                  | [domain-market](https://github.com/ZoneCNH/domain-market)       | v1.1.0 | ✅ 已有   | Spec→Code 完成 | 市场数据域模型（Tick/Quote/Bar/OrderBook）+ canonical 类型（ProductLine/InstrumentKey/MarketFactEnvelope）+ Binance C/S ingestion 语义 §10.1；v1.1.0；factory grade；live/soak N/A（纯值对象库） |
| L2.5                  | [domain-exchange](https://github.com/ZoneCNH/domain-exchange)   | v1.0.0 | ✅ 已有   | Spec→Code 完成 | 交易域模型（VenueAdapter 13 方法接口）；v1.0.0 GitHub Release 已发布；7 FR Done；factory grade；live/soak N/A（纯值对象库）            |
| L2.5                  | [domain-macro](https://github.com/ZoneCNH/domain-macro)         | v1.0.0 | ✅ 已有   | Spec→Code 完成 | 宏观数据域模型（MacroPoint/MacroState）；v1.0.0 GitHub Release 已发布；7 FR Done；factory grade；live/soak N/A（纯值对象库）           |
| **数据域 · 行情**     |                                                                 |        |           |          |                                                                                           |
| 数据域                | [binance](https://github.com/ZoneCNH/binance)                   | v1.0.0-spec | ✅ 已有 | ░░░░  5% | Binance Market Data C/S Module (client+server)；Spec-Only；4产品线；spec v1.0.0                       |
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
| **数据域 · 宏观**     |                                                                 |        |           |          |                                                                                           |
| 数据域                | [fred](https://github.com/ZoneCNH/fred)                         | -      | ✅ 已有   | ███░ 80% | 美联储 FRED                                                                               |
| 数据域                | [treasury](https://github.com/ZoneCNH/treasury)                 | -      | ✅ 已有   | ███░ 80% | 美国财政部                                                                                |
| 数据域                | [yield-curve](https://github.com/ZoneCNH/yield-curve)           | -      | ✅ 已有   | ███░ 80% | 收益率曲线                                                                                |
| 数据域                | [bea](https://github.com/ZoneCNH/bea)                           | -      | ✅ 已有   | ███░ 80% | 美国经济分析局                                                                            |
| 数据域                | [ecb](https://github.com/ZoneCNH/ecb)                           | -      | ✅ 已有   | ███░ 80% | 欧洲央行                                                                                  |
| 数据域                | [uk-cb](https://github.com/ZoneCNH/uk-cb)                       | -      | ✅ 已有   | ███░ 80% | 英国央行                                                                                  |
| 数据域                | [japan-cb](https://github.com/ZoneCNH/japan-cb)                 | -      | ✅ 已有   | ███░ 80% | 日本央行                                                                                  |
| 数据域                | [eastmoney](https://github.com/ZoneCNH/eastmoney)               | -      | ✅ 已有   | ███░ 80% | 东方财富 A 股                                                                             |
| 数据域                | [jin10](https://github.com/ZoneCNH/jin10)                       | v0.2.0 | ✅ 已有   | ███░ 80% | 金十数据 SDK：openapi（宏观数据）+ flash（实时快讯）                                      |
| 数据域                | [yahoo](https://github.com/ZoneCNH/yahoo)                       | -      | ✅ 已有   | ███░ 80% | Yahoo Finance                                                                             |
| **数据域 · 另类**     |                                                                 |        |           |          |                                                                                           |
| 数据域                | [alternative-data](https://github.com/ZoneCNH/alternative-data) | -      | 🔨 已创建 | ░░░░ 5%  | 链上、社交情绪、新闻 NLP                                                                  |
| **分析域**            |                                                                 |        |           |          |                                                                                           |
| 分析域                | [factor-engine](https://github.com/ZoneCNH/factor-engine)       | -      | 🔨 已创建 | ░░░░ 5%  | 从原始数据计算 alpha 因子                                                                 |
| 分析域                | [feature-store](https://github.com/ZoneCNH/feature-store)       | -      | 🔨 已创建 | ░░░░ 5%  | 因子版本管理、IC 评估                                                                     |
| 分析域                | [factor-eval](https://github.com/ZoneCNH/factor-eval)           | -      | 🔨 已创建 | ░░░░ 5%  | IC/IR/换手率评估                                                                          |
| 分析域                | [market_regime](https://github.com/ZoneCNH/market_regime)       | -      | 🔨 已创建 | ░░░░ 5%  | 市场状态识别（S1-S7：多头趋势/挤空/空头/踩踏/震荡/低波/压缩）                             |
| 分析域                | [macro_regime](https://github.com/ZoneCNH/macro_regime)         | -      | 🔨 已创建 | ░░░░ 5%  | 宏观经济体制识别（M1-M7：流动牛市/再通复苏/软着繁荣/鹰派通胀/衰退降息/信用去杠/滞胀冲击） |
| 分析域                | [regime-engine](https://github.com/ZoneCNH/regime-engine)       | v0.1.0 | 🔨 已创建 | ██░░ 25% | M×S 联合决策引擎（M+S → action/risk/permission），骨架完成，30+ 测试通过                 |
| 分析域                | [ms_brain](https://github.com/ZoneCNH/ms_brain)                 | -      | ✅ 已有   | -        | M×S 系统架构分析体系                                                                      |
| 分析域                | [flowx](https://github.com/ZoneCNH/flowx)                       | v0.1.0-draft | 🔨 已创建 | ░░░░ 5%  | 数据流管线引擎 — 实时流式 ETL、窗口聚合、背压控制（7 FR, SPEC draft）                    |
| **决策域**            |                                                                 |        |           |          |                                                                                           |
| 决策域                | [signal-factory](https://github.com/ZoneCNH/signal-factory)     | -      | 🔨 已创建 | ░░░░ 5%  | 多因子信号生成、过滤、评分                                                                |
| 决策域                | [backtest-engine](https://github.com/ZoneCNH/backtest-engine)   | -      | 🔨 已创建 | ░░░░ 5%  | 事件驱动回测、Tick 级回放                                                                 |
| 决策域                | [backtestx](https://github.com/ZoneCNH/backtestx)               | v0.1.0-draft | 🔨 已创建 | ░░░░ 5%  | 回测引擎 — 事件驱动回测、Walk-Forward、蒙特卡洛（7 FR, SPEC draft）                      |
| 决策域                | [strategyx](https://github.com/ZoneCNH/strategyx)               | v0.1.0-draft | 🔨 已创建 | ░░░░ 5%  | 策略工厂 — 策略注册、参数管理、信号组合（7 FR, SPEC draft）                              |
| 决策域                | [maestro](https://github.com/ZoneCNH/maestro)                   | v0.1.0-draft | 🔨 已创建 | ░░░░ 5%  | 工作流编排引擎 — DAG 工作流、状态机、错误恢复（9 FR, SPEC draft）                        |
| 决策域                | [optimizer](https://github.com/ZoneCNH/optimizer)               | -      | 🔨 已创建 | ░░░░ 5%  | 参数搜索、Walk-forward 验证                                                               |
| **执行域**            |                                                                 |        |           |          |                                                                                           |
| 执行域                | [risk-engine](https://github.com/ZoneCNH/risk-engine)           | -      | 🔨 已创建 | ░░░░ 5%  | VaR、止损、持仓限额、压力测试                                                             |
| 执行域                | [riskx](https://github.com/ZoneCNH/riskx)                       | v0.1.0-draft | 🔨 已创建 | ░░░░ 5%  | 风控引擎 — 事前风控、回撤控制、熔断机制（7 FR, SPEC draft）                              |
| 执行域                | [order-engine](https://github.com/ZoneCNH/order-engine)         | -      | 🔨 已创建 | ░░░░ 5%  | 智能路由、TWAP/VWAP、滑点控制                                                             |
| 执行域                | [orderx](https://github.com/ZoneCNH/orderx)                     | v0.1.0-draft | 🔨 已创建 | ░░░░ 5%  | 订单管理器 — 订单生命周期、SOR、状态机（7 FR, SPEC draft）                               |
| 执行域                | [portfolio-engine](https://github.com/ZoneCNH/portfolio-engine) | -      | 🔨 已创建 | ░░░░ 5%  | 多策略资金分配、再平衡                                                                    |
| 执行域                | [positionx](https://github.com/ZoneCNH/positionx)               | v0.1.0-draft | 🔨 已创建 | ░░░░ 5%  | 仓位管理器 — 实时仓位追踪、PnL、敞口监控（7 FR, SPEC draft）                             |
| 执行域                | [settlement](https://github.com/ZoneCNH/settlement)             | -      | 🔨 已创建 | ░░░░ 5%  | PnL 计算、交易所对账                                                                      |
| **入口**              |                                                                 |        |           |          |                                                                                           |
| 入口                  | [x.go](https://github.com/ZoneCNH/x.go)                         | v0.0.1 | ✅ 已有   | ███░ 80% | 组合根，2.8MB/33 项                                                                       |
| **横切**              |                                                                 |        |           |          |                                                                                           |
| 横切                  | [alertx](https://github.com/ZoneCNH/alertx)                     | -      | 🔨 已创建 | ░░░░ 5%  | 策略异常、风控触发告警                                                                    |
| 横切                  | [observex](https://github.com/ZoneCNH/observex)                 | v0.3.1 | ✅ 已发布 | █████ 100% | 可观测性（同时归属基座，提供底层 metrics/tracing/logging）                                |
| **独立**              |                                                                 |        |           |          |                                                                                           |
| 独立                  | [module](./module/README.md)                                    | -      | ✅ 已有   | -        | 项目技术规范、接口定义与 Goal 适配模块索引                                                |
| 独立                  | [docs/governance](./docs/governance/README.md)                  | -      | ✅ 已有   | -        | Spec → Code 交付治理、模板、门禁与评分规则                                                |

## 本地开发路径

> 所有模块代码仓库统一位于 `/home/{module}/`，其中 `{module}` 与 GitHub 仓库名一一对应。本地路径仅用于开发时快速定位代码，不参与运行时。

| 域                | 模块                                                                                                      | 本地路径                                    |
| ----------------- | --------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| **基座**          |                                                                                                           |                                             |
| 基座              | kernel                                                                                                    | `/home/kernel/`                             |
| 基座              | configx                                                                                                   | `/home/configx/`                            |
| 基座              | observex                                                                                                  | `/home/observex/`                           |
| 基座              | testkitx                                                                                                  | `/home/testkitx/`                           |
| 基座              | resiliencx                                                                                                | `/home/resiliencx/`                         |
| 基座              | schedulex                                                                                                 | `/home/schedulex/`                          |
| 基座              | xlibgate                                                                                                  | `/home/xlibgate/`                           |
| 基座              | xlib-standard                                                                                             | `/home/xlib-standard/`                      |
| 基座              | redisx                                                                                                    | `/home/redisx/`                             |
| 基座              | kafkax                                                                                                    | `/home/kafkax/`                             |
| 基座              | natsx                                                                                                     | `/home/natsx/`                              |
| 基座              | postgresx                                                                                                 | `/home/postgresx/`                          |
| 基座              | clickhousex                                                                                               | `/home/clickhousex/`                        |
| 基座              | taosx                                                                                                     | `/home/taosx/`                              |
| 基座              | ossx                                                                                                      | `/home/ossx/`                               |
| 基座              | contracts                                                                                                 | `/home/contracts/`                          |
| 基座              | transportx                                                                                                | `/home/transportx/`                         |
| **L2.5**          |                                                                                                           |                                             |
| L2.5              | domainx                                                                                                   | `/home/domainx/`                            |
| L2.5              | decimalx                                                                                                  | `/home/decimalx/`                           |
| L2.5              | domain-market                                                                                             | `/home/domain-market/`                      |
| L2.5              | domain-exchange                                                                                           | `/home/domain-exchange/`                    |
| L2.5              | domain-macro                                                                                              | `/home/domain-macro/`                       |
| **数据域 · 行情** |                                                                                                           |                                             |
| 数据域            | binance                                                                                                   | `/home/binance/`                            |
| 数据域            | okx                                                                                                       | `/home/okx/`                                |
| 数据域            | bybit                                                                                                     | `/home/bybit/`                              |
| 数据域            | bitget                                                                                                    | `/home/bitget/`                             |
| 数据域            | coinbase                                                                                                  | `/home/coinbase/`                           |
| 数据域            | gate                                                                                                      | `/home/gate/`                               |
| 数据域            | kucoin                                                                                                    | `/home/kucoin/`                             |
| 数据域            | mexc                                                                                                      | `/home/mexc/`                               |
| 数据域            | htx                                                                                                       | `/home/htx/`                                |
| 数据域            | upbit                                                                                                     | `/home/upbit/`                              |
| 数据域            | hyperliquid                                                                                               | `/home/hyperliquid/`                        |
| 数据域            | lighter                                                                                                   | `/home/lighter/`                            |
| 数据域            | coinglass                                                                                                 | `/home/coinglass/`                          |
| **数据域 · 宏观** |                                                                                                           |                                             |
| 数据域            | fred                                                                                                      | `/home/fred/`                               |
| 数据域            | treasury                                                                                                  | `/home/treasury/`                           |
| 数据域            | bea                                                                                                       | `/home/bea/`                                |
| 数据域            | ecb                                                                                                       | `/home/ecb/`                                |
| 数据域            | uk-cb                                                                                                     | `/home/uk-cb/`                              |
| 数据域            | japan-cb                                                                                                  | `/home/japan-cb/`                           |
| 数据域            | eastmoney                                                                                                 | `/home/eastmoney/`                          |
| 数据域            | jin10                                                                                                     | `/home/jin10/`                              |
| 数据域            | yahoo                                                                                                     | `/home/yahoo/`                              |
| 数据域            | yield-curve                                                                                               | `/home/yield-curve/`                        |
| **分析域**        |                                                                                                           |                                             |
| 分析域            | flowx                                                                                                     | `/home/flowx/`                              |
| **决策域**        |                                                                                                           |                                             |
| 决策域            | backtestx                                                                                                 | `/home/backtestx/`                          |
| 决策域            | strategyx                                                                                                 | `/home/strategyx/`                          |
| 决策域            | maestro                                                                                                   | `/home/maestro/`                            |
| **执行域**        |                                                                                                           |                                             |
| 执行域            | riskx                                                                                                     | `/home/riskx/`                              |
| 执行域            | orderx                                                                                                    | `/home/orderx/`                             |
| 执行域            | positionx                                                                                                 | `/home/positionx/`                          |
| **入口**          |                                                                                                           |                                             |
| 入口              | x.go                                                                                                      | `/home/x.go/`                               |

> 完整仓库 URL 映射见上方状态总览表。分析域（flowx）、决策域（backtestx/strategyx/maestro）、执行域（riskx/orderx/positionx）模块 SPEC 已发布（v0.1.0-draft）。

## 建议实现顺序

```text
Foundation P0: 基础闭环校准 ← kernel + configx + observex + testkitx + resiliencx + schedulex
               1. resiliencx 从标准模板身份改回运行时弹性策略库
               2. xlib-standard 固定为标准事实源 / Go Reference Template（Generator / Harness Gate / Evidence Runtime 已拆分至 xlib-harness / xlib-evidence）
               3. configx / observex 迁移到 kernel，或标注 foundationx 兼容期
               4. 统一 Foundation Go baseline
               5. 用 xlibgate / 脚本执行依赖矩阵、testkitx 边界和 release evidence

Phase 0: 领域共享层 ← domainx + decimalx + domain-market + domain-exchange + domain-macro
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
```text
