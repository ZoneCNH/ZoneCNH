# 🏗️ 分层架构

> FoundationX 量化交易基础设施的完整依赖拓扑
>
> 按职责域组织，拆分代码依赖、业务流与运行时组装视角

## 架构视图

依赖、业务流和运行时组装刻意分开呈现：业务数据从数据域走向执行域，代码依赖不反向穿透；`x.go` 是治理/工具 CLI，`composer` 是组合根（Composition Root），不是业务链路终点。

> 🔄 三引擎数据流全景（market_engine→S / macro_engine→M / regime_engine→DecisionCard）、M×S 矩阵、契约固化清单 → **[DATAFLOW.md](./DATAFLOW.md)**
>
> 🗺️ 六阶段交付路线图、任务编号与验收标准 → **[ROADMAP.md](./ROADMAP.md)**

### 代码依赖拓扑

```text
依赖方向：左侧模块可以导入右侧模块。

composer ───────────► 基座运行时 / L2.5 / 数据域 / 分析域 / 决策域 / 执行域

数据域 ─┐
分析域 ─┼──────────► L2.5 Domain Shared
决策域 ─┤             domainx · decimalx · domain_market · domain_exchange · domain_macro
执行域 ─┘
   │
   ├───────────────► contracts
   │                  跨域稳定端口、事件协议、DTO 契约
   │
   ├───────────────► transportx
   │                  跨 runtime / adapter 传输契约
   │
   └───────────────► 基座运行时 Foundation
                      L0: kernel
                      L1 primitives: configx · observex · resiliencx · schedulex
                      L1 assembly: bootstrap（进程入口组装，位于 primitives 之上）
                      L1 test-only: testkitx
                      扩展: redisx · kafkax · natsx · postgresx · taosx · ossx · clickhousex
                      契约: contracts · transportx
                      

标准与门禁：
  xlib_standard ─── 标准事实源 / Go Reference Template，v1.0.1 发布验收通过，不参与业务运行
  xlib_harness  ─── 模块生成器（generate）与门禁执行器（spec-lint / boundary / traceability / format-check）
  xlib_evidence ─── 证据收集与发布运行时（coverage / manifest / remote evidence / report）
  xlibgate      ─── import 边界、go.mod、Go baseline、release evidence、L2 发布就绪、Trust Alignment 机器门禁

横切关注点：
  alertx   ─── 策略异常、风控触发告警
  observex ─── 统一 metrics / tracing / logging（同时作为基座组件提供底层能力）
```

### 业务流与反馈

```text
market_data (14) ──────────────► market_regime ──┐
  domain_market (Bar/Tick/OB)     S1-S7 状态     │
  质量门禁 → 特征 → 分类器       bias/permission  │
                                               ├──► regime_engine ──► DecisionCard
macro_data (10) ───────────────► macro_regime ──┘     M×S 融合        action A-E
  domain_macro (MacroPoint)      M1-M7 状态           冲突门           profile
  LGIP 四因子                    LGIP 得分            风险放大          risk_tier
                                                                      position_caps
factor_engine ◄──► feature_store ◄──► factor_eval
              │      ▲                  ▲  ▲
              ▼      │                  │  │
            flowx ───┘                  │  │  (因子评估 + DecisionCard)
              (ETL)                     │  │
              │                         │  │
              │           regime_engine─┘  │
              │                │           │
              │                ▼           │
              │          signal_factory ◄──┘
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
```

### 运行时组装

```text
composer / service main
  └── bootstrap.Build(ctx, Spec{Module, Stores, Hooks})
      ├── validate module/context
      ├── configx: .env + XGO_{MODULE}_*
      ├── observex: logger / metrics / tracing / health
      ├── StoreSet（可选，仅聚合进程）
      │   ├── None: adapter 默认，不构造存储
      │   └── TD / PG / Redis / Kafka / NATS / CH（OSS 预留）
      ├── resiliencx: 默认运行时弹性策略
      ├── lifecycx.Manager: 注册基础组件与 closerComponent
      └── App{Config, Observe, Resilience, Lifecycle, ConfigHash}
          ├── service main 注册业务组件
          ├── App.Run(ctx): Lifecycle.Start + shutdownx.NotifyContext
          └── App.Shutdown(ctx): Lifecycle.Stop / 幂等清理
```

`bootstrap` 只组装进程入口，不承载业务语义、domain/contracts、HTTP/gRPC listener 或跨进程编排；跨进程 composer 属于上层入口职责。Adapter 进程使用 `Stores=None`，`market_data` / `macro_data` 聚合进程可使用 `Stores=All` 或位组合。
