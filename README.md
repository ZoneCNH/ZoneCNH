# 你好，我是 ZoneCNH 👋

**量化交易基础设施工程师** | 构建高性能、高可靠的金融数据与交易系统

## 🔧 技术栈

Go 🐹 (主要) · Rust 🦀 (底层) · Python 🐍 (脚本/数据) · TypeScript ⚡ (前端)

## 🏗️ 分层架构

> 📐 完整依赖拓扑、域间关系、运行时组装与子模块明细 → **[ARCHITECTURE.md](./ARCHITECTURE.md)**
>
> 🔄 三引擎数据流全景、M×S 联合决策矩阵与契约清单 → **[DATAFLOW.md](./DATAFLOW.md)**
>
> 📊 项目状态监控、健康度与风险追踪 → **[STATUS.md](./STATUS.md)**
>
> 🗺️ 六阶段交付路线图、任务编号与验收标准 → **[ROADMAP.md](./ROADMAP.md)**
>
> 🧱 Foundation 公开规格、依赖矩阵、执行跟踪与 ADR → **[module/](./module/)**
>
> 📋 19 个基座 Foundation 模块规格，另含 5 个 L2.5 领域共享规划/基线规格（L2.5 不作整体 release/factory 声明） → **[module/](./module/)**
>
> 🧭 Spec 治理模板、生命周期、追溯与评分规则 → **[docs/governance/](./docs/governance/)**
>
> 📜 系统宪法（AI 代理最高治理文件）→ **[CONSTITUTION.md](./CONSTITUTION.md)**

```text
入口: x.go (Composition Root: 启动 / 配置 / 组装)
      │
      ▼
标准: xlib-standard · xlib-harness · xlib-evidence · xlibgate（标准源、门禁生成/执行、证据收集、Trust Alignment，不参与运行时）
      │
      ▼
L0: kernel (stdlib-only primitives)
      │
      ▼
L1 primitives: configx / observex / resiliencx / schedulex
L1 Assembly: bootstrap (process assembly below x.go)
L1 测试: testkitx (test-only)
      │
      ▼
基座扩展: redisx / kafkax / natsx / postgresx / taosx / ossx / clickhousex / contracts / transportx
      │
      ▼
L2.5: domainx / decimalx / domain-market / domain-macro / domain-exchange (5/5 已发布；domain-market v1.1.0，其余 v1.0.0+；5/5 GitHub Release 已观测对账；5/5 factory grade；live/soak N/A)
      │
      ▼
业务流: 数据域 → 分析域 ↔ 决策域 → 执行域
数据域: market-data (14) / macro-data (10) / alternative-data
分析域: factor-engine / feature-store / factor-eval / market_regime / macro_regime / regime-engine / ms_brain / flowx
       三引擎: market_engine(market facts → S state) / macro_engine(macro facts → M state) / regime_engine(M+S → action/risk/permission)
决策域: signal-factory / backtest-engine / optimizer / backtestx / strategyx / maestro
执行域: risk-engine → order-engine → portfolio-engine / settlement ; riskx / orderx / positionx

反馈: backtest → factor-eval；fills / PnL / exposure events → 决策域
横切: alertx (告警) / observex (可观测)
```

## L2.5 v1.0.0 执行计划基线

| 模块 | 当前版本 | 目标版本 | 状态 | 模块文档 |
| --- | --- | --- | --- | --- |
| `decimalx` | v1.0.0 | v1.0.0 | v1.0.0 GitHub Release 已发布；API freeze 完成 | [module/decimalx](module/decimalx/goal.md) |
| `domainx` | v1.0.1 | v1.0.1 | 领域共享值对象基线；v1.0.1 GitHub Release 已发布 | [module/domainx](module/domainx/goal.md) |
| `domain-market` | v1.1.0 | v1.1.0 | 市场数据域模型 + canonical 类型（ProductLine/InstrumentKey/MarketFactEnvelope）+ Binance C/S ingestion 语义 | [module/domain-market](module/domain-market/goal.md) |
| `domain-macro` | v1.0.0 | v1.0.0 | v1.0.0 GitHub Release 已发布；no-lookahead 冻结 | [module/domain-macro](module/domain-macro/goal.md) |
| `domain-exchange` | v1.0.0 | v1.0.0 | v1.0.0 GitHub Release 已发布；Exchange SPI 冻结 | [module/domain-exchange](module/domain-exchange/goal.md) |

成熟度口径：5/5 已发布 v1.0.0+ GitHub Release（decimalx v1.0.0/domain-market v1.1.0/domain-macro v1.0.0/domain-exchange v1.0.0/domainx v1.0.1）；5/5 factory grade；live/soak N/A（纯值对象库，无运行时服务不需 EXT CI/adoption/soak 证据）。

依赖顺序：`decimalx` -> `domainx` -> `domain-market` / `domain-macro` -> `domain-exchange`。v1.0.0 是各模块的发布版本，GitHub Release/tag 已观测并对账。5/5 factory grade；live/soak N/A（纯值对象库）。

`domainx` 已归入 L2.5 领域共享层；机器事实层将其作为 L2.5 模块单独计入 20-module projection，不并入 19 个基座组件数。

## 📦 核心项目

### 基座 · 基础设施
- [xlib-standard](https://github.com/ZoneCNH/xlib-standard) — 标准事实源、Go Reference Template（Generator/Harness/Evidence 已拆分至 xlib-harness / xlib-evidence）；不作为运行时 import 依赖 `公开`
- [xlib-harness](https://github.com/ZoneCNH/xlib-harness) — 模块生成器与门禁执行器：generate/scaffold、spec-lint、boundary-check、traceability-gate；✅ v0.1.1 GitHub Release 已发布 `公开`
- [xlib-evidence](https://github.com/ZoneCNH/xlib-evidence) — 证据收集与发布运行时：collect-coverage、generate-manifest、validate-manifest、remote-evidence、report；✅ v0.2.0 GitHub Release 已发布，本地 Go runtime 验收通过（go test/race/vet/coverage 89.8%） `公开`
- [kernel](https://github.com/ZoneCNH/kernel) — L0 标准库扩展原语（error/time/context/lifecycle/health/sync） `公开`
- [configx](https://github.com/ZoneCNH/configx) — 显式配置加载、多源合并、StrictDecode、SecretString 脱敏、Provenance 追踪与 EffectiveConfigHash `公开`
- [observex](https://github.com/ZoneCNH/observex) — vendor-neutral 日志、指标、追踪、健康与脱敏契约 `公开`
- [resiliencx](https://github.com/ZoneCNH/resiliencx) — 运行时弹性策略（timeout/retry/circuit/bulkhead/rate/fallback） `公开`
- [schedulex](https://github.com/ZoneCNH/schedulex) — 任务调度运行时（cron/interval/delay、Overlap/Misfire 策略、Locker 扩展点、Clock 注入、v1.0.0 已发布，98.2% 覆盖） `公开`
- [bootstrap](https://github.com/ZoneCNH/bootstrap) — L1 Assembly 通用进程组装层（位于 L1 primitives 之上、x.go 入口之下）：configx/observex/resiliencx + lifecycx 统一组装 + 7 存储 adapter 可选构造（StoreSet 位掩码）；不承载业务语义 / service listener / domain contracts；✅ v0.1.0 GitHub Release 已发布，规格 v0.1.7 `公开`
- [testkitx](https://github.com/ZoneCNH/testkitx) — 测试专用 evidence/golden/fixture/boundary 工具包 `公开`
- [xlibgate](https://github.com/ZoneCNH/xlibgate) — import 边界、go.mod、Go baseline、release evidence、Trust Alignment 门禁 `公开`

> **公开投影口径**：版本 / release / factory 状态以 `.foundationx/status/index.json` + `.foundationx/blockers.json` 为准；BLK-001~008 历史项已 resolved，BLK-009 / BLK-010 / BLK-011 仍 open；Foundation 整体维持 non-factory 投影。
>
> `configx` v1.0.0、`observex` v0.3.1、`testkitx` v0.4.0、`resiliencx` v0.4.9 已发布；此前版本误标已修正。

### 基座 · 存储与中间件

- [postgresx](https://github.com/ZoneCNH/postgresx) — PostgreSQL — 关系型存储、事务、迁移（v1.0.0 已发布；live integration 通过；factory_grade_allowed=false；单元测试 52.4% + Docker integration skip，BLK-006 open） `公开`
- [redisx](https://github.com/ZoneCNH/redisx) — Redis L2 adapter（v1.0.1 已发布；KV/TTL、Hash/List、Pipeline、Cache-aside、Lock/RateLimit、Pool、Persistence restart recovery；Docker-backed Redis 验证通过） `公开`
- [clickhousex](https://github.com/ZoneCNH/clickhousex) — ClickHouse — OLAP 查询、批量写入（v1.0.1 GitHub Release 已发布；Docker ClickHouse CI 已部署；BLK-003 open；非 factory） `公开`
- [taosx](https://github.com/ZoneCNH/taosx) — TDengine L2 adapter contract（pkg/taosx v1.0.1；真实 taosWS WebSocket 集成已验证；SPEC 评分 67，BLK-007 open；非 factory） `公开`
- [kafkax](https://github.com/ZoneCNH/kafkax) — Kafka — 消息队列、事件流（v1.0.2 已发布；真实 broker gates 已验证） `公开`
- [natsx](https://github.com/ZoneCNH/natsx) — NATS 内部通信模块（v1.0.0 已发布；Core NATS / JetStream、Drain/reconnect/degraded health、canonical `FOUNDATIONX_NATS_*` 配置和真实 dev auth live gate 已验证；正式四源 98+ arbiter 与生产 TLS gate 待补，BLK-001/BLK-002 open；非 factory） `公开`
- [ossx](https://github.com/ZoneCNH/ossx) — Aliyun OSS 对象存储 L2 adapter（v1.0.2-alpha 已交付 pkg/ossx 源码/8文件/12测试/import 可编译；BLK-010 open；非 factory：真实 Aliyun adapter 与 integration evidence 待补 TASK-OSSX-005） `公开`

### 基座 · 契约与传输

- [contracts](https://github.com/ZoneCNH/contracts) — 跨域稳定端口、事件协议与 DTO 契约（含 §8.4 Binance C/S ingestion contract）；✅ v1.2.0 GitHub Release 已发布 `公开`
- [transportx](https://github.com/ZoneCNH/transportx) — 应用通信底座规格基线（Envelope/Endpoint、ServiceIdentity、QoS、Codec、RPC、EventBus、Stream、Outbox/Inbox、Audit Plane、Data Classification、SchemaRegistry 与 conformance gates）；✅ v1.1.1-spec GitHub Release 已发布 `公开`

### L2.5 · 领域共享层

- [decimalx](https://github.com/ZoneCNH/decimalx) — 高精度十进制类型（Decimal/Price/Qty/Ratio/Money）；v1.0.0 GitHub Release 已发布 `公开`
- [domainx](https://github.com/ZoneCNH/domainx) — 领域共享值对象：Order/Position/Trade/Portfolio/ExecutionReport 枚举与类型；L2.5 design baseline；公开 v1.0.1 GitHub Release/tag 已观测并已对账为 release=true；factory grade；live/soak N/A（纯值对象库） `公开`
- [domain-market](https://github.com/ZoneCNH/domain-market) — 市场数据域模型（Tick/Quote/Bar/OrderBook）+ canonical 类型（ProductLine/InstrumentKey/MarketFactEnvelope）+ Binance C/S ingestion 语义；v1.1.0 `公开`
- [domain-macro](https://github.com/ZoneCNH/domain-macro) — 宏观经济领域共享模型：国家/地区/指标/发布日历、MacroPoint/MacroState；v1.0.0 GitHub Release 已发布 `公开`
- [domain-exchange](https://github.com/ZoneCNH/domain-exchange) — 交易域模型（VenueAdapter 13 方法接口）；v1.0.0 GitHub Release 已发布 `公开`

### 数据域 · market-data（14: 1 dispatch + 12 SDK + 1 C/S Module）

**行情接收与分发：**

- [market-data](https://github.com/ZoneCNH/market-data) — Downstream Dispatch Port 接收侧模块；接收 adapter 归一化事件，执行校验、幂等、排序和分发 `公开`

**交易所 SDK / C/S Module：**

- [binance](https://github.com/ZoneCNH/binance) — 币安 Binance Market Data C/S Module (Spot/USDⓈ-M/COIN-M/Options)；spec v1.0.0 `公开`
- [okx](https://github.com/ZoneCNH/okx) — OKX `公开`
- [bybit](https://github.com/ZoneCNH/bybit) — Bybit `公开`
- [bitget](https://github.com/ZoneCNH/bitget) — Bitget `公开`
- [kucoin](https://github.com/ZoneCNH/kucoin) — KuCoin `公开`
- [gate](https://github.com/ZoneCNH/gate) — Gate.io `公开`
- [mexc](https://github.com/ZoneCNH/mexc) — MEXC `公开`
- [htx](https://github.com/ZoneCNH/htx) — HTX (火币) `公开`
- [coinbase](https://github.com/ZoneCNH/coinbase) — Coinbase `公开`
- [hyperliquid](https://github.com/ZoneCNH/hyperliquid) — Hyperliquid `公开`
- [lighter](https://github.com/ZoneCNH/lighter) — Lighter `公开`
- [upbit](https://github.com/ZoneCNH/upbit) — Upbit `公开`
- [coinglass](https://github.com/ZoneCNH/coinglass) — Coinglass 加密货币数据 `公开`

### 数据域 · macro-data

- [fred](https://github.com/ZoneCNH/fred) — 美联储经济数据 (FRED) `公开`
- [treasury](https://github.com/ZoneCNH/treasury) — 美国国债/财政数据 `公开`
- [yield-curve](https://github.com/ZoneCNH/yield-curve) — 收益率曲线 `公开`
- [bea](https://github.com/ZoneCNH/bea) — 美国经济分析局 (BEA) `公开`
- [ecb](https://github.com/ZoneCNH/ecb) — 欧洲央行 (ECB) `公开`
- [uk-cb](https://github.com/ZoneCNH/uk-cb) — 英国央行 `公开`
- [japan-cb](https://github.com/ZoneCNH/japan-cb) — 日本央行 `公开`
- [eastmoney](https://github.com/ZoneCNH/eastmoney) — 东方财富 `公开`
- [jin10](https://github.com/ZoneCNH/jin10) — 金十数据 SDK（开放 API + Flash 快讯） `公开`
- [yahoo](https://github.com/ZoneCNH/yahoo) — Yahoo Finance `公开`

### 数据域 · alternative-data

- [alternative-data](https://github.com/ZoneCNH/alternative-data) — 链上数据、社交情绪、新闻 NLP `公开`

### 分析域

- [factor-engine](https://github.com/ZoneCNH/factor-engine) — 因子计算引擎 `公开`
- [feature-store](https://github.com/ZoneCNH/feature-store) — 特征存储与版本管理 `公开`
- [factor-eval](https://github.com/ZoneCNH/factor-eval) — 因子评估 `公开`
- [market_regime](https://github.com/ZoneCNH/market_regime) — 市场状态识别（S1-S7：多头趋势/挤空/空头/踩踏/震荡/低波/压缩） `私有`
- [macro_regime](https://github.com/ZoneCNH/macro_regime) — 宏观经济体制识别（M1-M7：流动牛市/再通复苏/软着繁荣/鹰派通胀/衰退降息/信用去杠/滞胀冲击） `私有`
- [regime-engine](https://github.com/ZoneCNH/regime-engine) — M×S 联合决策引擎（M state + S state → action A-E / risk_tier / position_caps / trade_permission） `私有`
- [ms_brain](https://github.com/ZoneCNH/ms_brain) — M×S 系统架构分析体系 `私有`
- [flowx](https://github.com/ZoneCNH/flowx) — 数据流管线引擎（流式 ETL、窗口聚合、背压控制） `公开`

### 决策域

- [signal-factory](https://github.com/ZoneCNH/signal-factory) — 信号生成与组合 `公开`
- [backtest-engine](https://github.com/ZoneCNH/backtest-engine) — 事件驱动回测引擎 `公开`
- [optimizer](https://github.com/ZoneCNH/optimizer) — 参数优化 `公开`
- [backtestx](https://github.com/ZoneCNH/backtestx) — 回测引擎（事件驱动、Walk-Forward、蒙特卡洛） `公开`
- [strategyx](https://github.com/ZoneCNH/strategyx) — 策略工厂（策略注册、参数管理、信号组合） `公开`
- [maestro](https://github.com/ZoneCNH/maestro) — 工作流编排引擎（DAG 工作流、状态机、错误恢复） `公开`

### 执行域

- [risk-engine](https://github.com/ZoneCNH/risk-engine) — 风险管理引擎 `公开`
- [order-engine](https://github.com/ZoneCNH/order-engine) — 订单执行引擎 `公开`
- [portfolio-engine](https://github.com/ZoneCNH/portfolio-engine) — 投资组合管理 `公开`
- [settlement](https://github.com/ZoneCNH/settlement) — 结算与对账 `公开`
- [riskx](https://github.com/ZoneCNH/riskx) — 风控引擎（事前风控、回撤控制、熔断机制） `公开`
- [orderx](https://github.com/ZoneCNH/orderx) — 订单管理器（订单生命周期、SOR、状态机） `公开`
- [positionx](https://github.com/ZoneCNH/positionx) — 仓位管理器（实时仓位追踪、PnL、敞口监控） `公开`

### 横切 · 入口

- [alertx](https://github.com/ZoneCNH/alertx) — 告警引擎 `公开`
- [x.go](https://github.com/ZoneCNH/x.go) — 组合根，负责启动、配置加载与引擎组装 `私有`
- [module](./module/README.md) — 项目技术规范、接口定义与 Goal 适配模块索引
- [docs/governance](./docs/governance/README.md) — Spec → Code 交付治理、模板、门禁与评分规则
- [docs/sre/foundation-cicd-plan.md](./docs/sre/foundation-cicd-plan.md) — 基座层 19 模块 + L2.5 领域共享 CI/CD 部署执行方案（SRE 机器池 4 阶段）
- [docs/RSI_SG_001_complete_standard_v1.1_zh.md](./docs/RSI_SG_001_complete_standard_v1.1_zh.md) — RSI 递归自我改进完整标准中文版 v1.1

## 📊 GitHub 统计

<p align="center">
  <img src="https://github-readme-stats.vercel.app/api?username=ZoneCNH&show_icons=true&theme=radical&hide_border=true" alt="GitHub 统计" />
</p>

---

<p align="center">
  <i>构建稳定可靠的量化基础设施 ⚡</i>
</p>
