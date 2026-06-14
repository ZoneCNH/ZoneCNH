# 📊 项目状态监控

> FoundationX 量化交易基础设施的实时健康度与风险追踪
>
> 数据来源：各 GitHub 仓库实际状态，定期更新
>
> 最后更新：2026-06-14
>
> 同步基线：`module/` 为模块规格库 SSOT，`docs/governance/` 为 Spec 治理 SSOT，`docs/goal/` 为 Goal 规则 SSOT，`specs/` 已移除。
> 机器事实源：`.foundationx/status/index.json` — 由 `xlibgate fleet-status` 生成，供 CI 和自动投影消费。多维成熟度以该文件为准，本文手工块为投影。

---

## 组件明细表

### 基座

| 组件 | 版本 | 进度 | 仓库大小 | 说明 |
| ---- | ---- | ---- | -------- | ---- |
| [xlib-standard](https://github.com/ZoneCNH/xlib-standard) | v1.0.0 | █████ 100% | spec=100 mat=98 tsk=100 pln=100 prm=100 cod=100 | 标准事实源 / Go Reference Template；Generator/Harness/Evidence 已拆分至 xlib-harness / xlib-evidence；✅ .repo-contract.yaml (is_standard_source)；✅ GitHub Release v1.0.0 已发布|
| [xlib-harness](https://github.com/ZoneCNH/xlib-harness) | v1.0.0 | █████ 100% | spec=98 mat=100 tsk=98 pln=100 prm=100 cod=100 | 模块生成器与门禁执行器：generate/scaffold、spec-lint、boundary-check、traceability-gate；✅ CI 已部署 |
| [xlib-evidence](https://github.com/ZoneCNH/xlib-evidence) | v1.0.0 | █████ 100% | spec=98 mat=100 tsk=100 pln=100 prm=100 cod=100 | 证据收集与发布运行时：collect-coverage、generate-manifest、validate-manifest、report；✅ CI 已部署 |
| [xlibgate](https://github.com/ZoneCNH/xlibgate) | v1.0.0 | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | check/l2/trust 三组门禁；✅ .repo-contract.yaml，v1.0.0 已对齐（此前误标 v1.1.1）；trust CLI 已实现 |
| [kernel](https://github.com/ZoneCNH/kernel) | v1.0.0 | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | L0 原语 / 12 子包 / stdlib-only；✅ .repo-contract.yaml，v1.0.0 已对齐，建议 API 冻结 |
| [configx](https://github.com/ZoneCNH/configx) | v0.1.4 | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 配置管理；此前误标 v1.0.0，已按 git tag v0.1.4 修正；✅ .repo-contract.yaml |
| [observex](https://github.com/ZoneCNH/observex) | v0.3.1 | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 可观测性；此前误标 v1.0.0，已按 git tag v0.3.1 修正 |
| [testkitx](https://github.com/ZoneCNH/testkitx) | v0.4.0 | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | Fake / Fixture / Golden / Contract / Leak / Boundary / Manifest 测试工具包；此前误标 v1.0.0，已按 git tag v0.4.0 修正；test-only |
| [resiliencx](https://github.com/ZoneCNH/resiliencx) | v0.4.9 | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 弹性策略（timeout / retry / circuit / bulkhead / rate / fallback）；此前误标 v1.0.1，已按 git tag v0.4.9 修正 |
| [schedulex](https://github.com/ZoneCNH/schedulex) | v1.0.0 | █████ 100% | spec=98 mat=100 tsk=100 pln=100 prm=100 cod=100 | cron/interval/delay 调度；✅ .repo-contract.yaml，v1.0.0 已对齐；98.2% 覆盖，下游 smoke 通过 |
| [redisx](https://github.com/ZoneCNH/redisx) | v1.0.1 | █████ 100% | spec=98 mat=100 tsk=100 pln=100 prm=100 cod=100 | Redis L2 adapter；✅ .repo-contract.yaml，v1.0.1；此前误标 v1.0.0（tag 超前于表格）；Docker-backed Redis 验证通过 |
| [kafkax](https://github.com/ZoneCNH/kafkax) | v1.0.2 | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | Kafka L2 adapter；✅ .repo-contract.yaml，v1.0.2；此前误标 v1.0.0（tag 超前于表格）；真实 broker gates 已验证 |
| [natsx](https://github.com/ZoneCNH/natsx) | v1.0.0 | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | NATS L2 adapter；✅ .repo-contract.yaml；TLS 已实现；v1.0.0 生产就绪 |
| [postgresx](https://github.com/ZoneCNH/postgresx) | v1.0.0 | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | PostgreSQL；✅ .repo-contract.yaml；live integration 通过；v1.0.0 生产就绪 |
| [taosx](https://github.com/ZoneCNH/taosx) | v1.0.1 | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | TDengine L2 adapter；✅ .repo-contract.yaml；真实 taosWS 集成已验证；SPEC WHEN/THEN 已补齐 |
| [ossx](https://github.com/ZoneCNH/ossx) | v1.0.1 | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | Aliyun OSS L2 adapter；✅ .repo-contract.yaml，v1.0.1 已对齐；race/vet/build/release-check 已通过 |
| [clickhousex](https://github.com/ZoneCNH/clickhousex) | v1.0.1 | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | ClickHouse OLAP；✅ .repo-contract.yaml；git tag + CI 已部署 |
| [contracts](https://github.com/ZoneCNH/contracts) | v1.0.1-spec | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 跨域稳定端口/事件/DTO 契约；✅ .repo-contract.yaml；git tag v1.0.1-spec 已创建；pkg/contracts 已实现 |
| [transportx](https://github.com/ZoneCNH/transportx) | v1.1.1-spec | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 应用通信底座规格基线；✅ .repo-contract.yaml；git tag v1.1.1-spec 已创建；pkg/transportx 已实现 |
| [domainx](https://github.com/ZoneCNH/domainx) | v0.1.0 | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | ✅ .repo-contract.yaml；git tag v0.1.0 已创建；CI 已部署 |

> ⚠️ **版本注记**：observex / testkitx / resiliencx 此前误标为 v1.0.0/v1.0.0/v1.0.1，已按实际 git tag v0.3.1/v0.4.0/v0.4.9 修正。全部 20 模块 git tag + GitHub Release/CI 已于 Trust Alignment 迭代中完成对齐。

> **成熟度语义说明（2026-06-14 v2 Trust Alignment）**：上表"进度"反映的是本仓库 Spec 管线评分（spec→code），不代表生产就绪（factory grade）。下表提供多维度成熟度视图，以 ✅（完成）/ ❌（未完成）/ N/A（不适用）标注。全部维度已于 Trust Alignment 迭代中验证补齐（0 ⚠️ / 0 ?）。

<details>
<summary>📊 基座多维成熟度展开（点击展开）</summary>

| 模块 | SPEC | IMPL | RELEASE | LIVE INT | EXT CI | ADOPT | SOAK | FACTORY | 备注 |
|------|:----:|:----:|:-------:|:--------:|:------:|:-----:|:----:|:-------:|------|
| xlib-standard | ✅ | ✅ | ✅ | N/A | ✅ | N/A | N/A | ✅ | v1.0.0; GitHub Release 已发布; 9 CI workflows |
| xlib-harness | ✅ | ✅ | ✅ | N/A | ✅ | N/A | N/A | ✅ | v1.0.0; CI 已部署; generate/scaffold/spec-lint/boundary/traceability |
| xlib-evidence | ✅ | ✅ | ✅ | N/A | ✅ | N/A | N/A | ✅ | v1.0.0; CI 已部署; evidence collect/generate/validate/report |
| xlibgate | ✅ | ✅ | ✅ | N/A | ✅ | N/A | N/A | ✅ | v1.0.0; CI 已部署; 8 workflows; 此前误标 v1.1.1 |
| kernel | ✅ | ✅ | ✅ | N/A | ✅ | ✅ | N/A | ✅ | v1.0.0; 4 CI workflows; 13 下游消费者; API 冻结建议 |
| configx | ✅ | ✅ | ✅ | N/A | ✅ | ✅ | N/A | ✅ | v0.1.4; 4 CI workflows; 2 下游消费者; 此前误标 v1.0.0 |
| observex | ✅ | ✅ | ✅ | N/A | ✅ | ✅ | N/A | ✅ | v0.3.1; 4 CI workflows; 2 下游消费者; 已采用 |
| testkitx | ✅ | ✅ | ✅ | N/A | ✅ | N/A | N/A | N/A | v0.4.0; 4 CI workflows; test-only — factory grade 不适用 | v0.4.0; 4 CI workflows; test-only 非运行时模块 |
| resiliencx | ✅ | ✅ | ✅ | N/A | ✅ | ✅ | N/A | ✅ | v0.4.9; 9 CI workflows; 2 下游消费者; 已采用 |
| schedulex | ✅ | ✅ | ✅ | N/A | ✅ | ✅ | N/A | ✅ | v1.0.0; 6 CI workflows; 下游 smoke 通过; 1 下游消费者 |
| redisx | ✅ | ✅ | ✅ | ✅ | ✅ | N/A | N/A | ✅ | v1.0.1; 9 CI workflows; Docker-backed Redis 验证通过 |
| kafkax | ✅ | ✅ | ✅ | ✅ | ✅ | N/A | N/A | ✅ | v1.0.2; 8 CI workflows; 真实 broker gates 已验证 |
| natsx | ✅ | ✅ | ✅ | ✅ | ✅ | N/A | N/A | ✅ | v1.0.0; 6 CI workflows; TLS 已实现; live gate 已验证; 生产就绪 |
| postgresx | ✅ | ✅ | ✅ | ✅ | ✅ | N/A | N/A | ✅ | v1.0.0; 3 CI workflows; live integration 通过; migration runner; 生产就绪 |
| taosx | ✅ | ✅ | ✅ | ✅ | ✅ | N/A | N/A | ✅ | v1.0.1; 8 CI workflows; 真实 taosWS 已验证; SPEC WHEN/THEN 已补齐 (PR #374) |
| ossx | ✅ | ✅ | ✅ | ✅ | ✅ | N/A | N/A | ✅ | v1.0.1; CI 已部署; 真实 Aliyun OSS 集成已验证 |
| clickhousex | ✅ | ✅ | ✅ | ✅ | ✅ | N/A | N/A | ✅ | v1.0.1; CI 已部署+运行(Docker ClickHouse); git tag 已创建; SPEC+TRACEABILITY+TASKS 100% | v1.0.1; CI 已部署+运行(Docker ClickHouse); git tag 已创建; SPEC+TRACEABILITY+TASKS 100% |
| contracts | ✅ | ✅ | ✅ | N/A | ✅ | ✅ | N/A | ✅ | v1.0.1-spec; pkg/contracts 已实现 (PR #6); git tag + CI 已部署 |
| transportx | ✅ | ✅ | ✅ | N/A | ✅ | N/A | N/A | ✅ | v1.1.1-spec; pkg/transportx 已实现; 24节/25FR/57WHEN-THEN/32TC/AC矩阵完整 |
| domainx | ✅ | ✅ | ✅ | N/A | ✅ | N/A | N/A | ✅ | v0.1.0; CI 已部署+已运行; git tag 已创建 |

> **维度说明**：SPEC=规格完成 | IMPL=实现完成 | RELEASE=tag/release/manifest 一致 | LIVE INT=真实服务集成（非 mock） | EXT CI=外部 CI artifact | ADOPT=下游模块真实采用 | SOAK=生产或类生产长时间运行 | FACTORY=factory_grade_allowed（最高综合等级）

> **数据来源**：本表依据 `module/` 规格状态、公开 GitHub release 页面、GitHub Actions CI 最新运行状态（gh api 批量验证 2026-06-14）、FOUNDATION-DEPS.yaml 反向依赖图（ADOPT）及 `.worktree/v2.md` 分析。所有 46 个 `?` 维度已于 2026-06-14 Trust Alignment 批量验证补齐。
>
> **CI 构建状态**（最新 run，2026-06-14）：✅ 全部 20 模块已配置 CI workflows | Trust Alignment 5 模块本次部署: xlib-harness / xlib-evidence / ossx / clickhousex / domainx
>
> **管线评分注记**：上表 `pln/prm/cod` 列对外仓模块为 pass-through（未实际在目标 repo 运行验证），100 分仅表示 plan/prompt 文档模板完整，不代表代码可编译或已通过测试。CI 构建状态为此处补充机械证据。

</details>

### L2.5 · 领域共享层

| 组件 | 版本 | 进度 | 说明 |
| ---- | ---- | ---- | ---- |
| [decimalx](https://github.com/ZoneCNH/decimalx) | v0.1.0 | ███░ 80% | 高精度十进制类型 |
| [domain-market](https://github.com/ZoneCNH/domain-market) | v0.1.0 | ███░ 80% | 市场数据域模型 |
| [domain-exchange](https://github.com/ZoneCNH/domain-exchange) | v0.1.0 | ███░ 80% | 交易域模型 |
| [domain-macro](https://github.com/ZoneCNH/domain-macro) | v0.1.0 | ███░ 80% | 宏观数据域模型 |

### 数据域 · 行情

| 组件 | 类型 | 版本 | 进度 | 说明 |
| ---- | ---- | ---- | ---- | ---- |
| [binance](https://github.com/ZoneCNH/binance) | SDK | - | ███░ 80% | Binance CEX |
| [okx](https://github.com/ZoneCNH/okx) | SDK | - | ███░ 80% | OKX CEX |
| [bybit](https://github.com/ZoneCNH/bybit) | SDK | - | ███░ 80% | Bybit CEX |
| [bitget](https://github.com/ZoneCNH/bitget) | SDK | - | ███░ 80% | Bitget CEX |
| [kucoin](https://github.com/ZoneCNH/kucoin) | SDK | - | ███░ 80% | KuCoin CEX |
| [gate](https://github.com/ZoneCNH/gate) | SDK | - | ███░ 80% | Gate CEX |
| [mexc](https://github.com/ZoneCNH/mexc) | SDK | - | ███░ 80% | MEXC CEX |
| [htx](https://github.com/ZoneCNH/htx) | SDK | - | ███░ 80% | HTX CEX |
| [coinbase](https://github.com/ZoneCNH/coinbase) | SDK | - | ███░ 80% | Coinbase CEX |
| [hyperliquid](https://github.com/ZoneCNH/hyperliquid) | SDK | - | ███░ 80% | Hyperliquid DEX |
| [lighter](https://github.com/ZoneCNH/lighter) | SDK | - | ███░ 80% | Lighter DEX |
| [upbit](https://github.com/ZoneCNH/upbit) | SDK | - | ███░ 80% | Upbit CEX |
| [coinglass](https://github.com/ZoneCNH/coinglass) | SDK | - | ███░ 80% | 衍生品聚合数据 |
| [binance-market](https://github.com/ZoneCNH/binance-market) | Provider | v0.1.0 | ███░ 80% | Binance Kline/Ticker |
| [bybit-market](https://github.com/ZoneCNH/bybit-market) | Provider | v0.1.0 | ███░ 80% | Bybit Kline/Ticker |
| [bitget-market](https://github.com/ZoneCNH/bitget-market) | Provider | v0.1.0 | ███░ 80% | Bitget Kline/Ticker |
| [okx-market](https://github.com/ZoneCNH/okx-market) | Provider | v0.1.0 | ███░ 80% | OKX Kline/Ticker |
| [coinbase-market](https://github.com/ZoneCNH/coinbase-market) | Provider | v0.1.0 | ███░ 80% | Coinbase Kline/Ticker |

### 数据域 · 宏观

| 组件 | 版本 | 进度 | 说明 |
| ---- | ---- | ---- | ---- |
| [fred](https://github.com/ZoneCNH/fred) | - | ███░ 80% | 美联储 FRED |
| [treasury](https://github.com/ZoneCNH/treasury) | - | ███░ 80% | 美国财政部 |
| [yield-curve](https://github.com/ZoneCNH/yield-curve) | - | ███░ 80% | 收益率曲线 |
| [bea](https://github.com/ZoneCNH/bea) | - | ███░ 80% | 美国经济分析局 |
| [ecb](https://github.com/ZoneCNH/ecb) | - | ███░ 80% | 欧洲央行 |
| [uk-cb](https://github.com/ZoneCNH/uk-cb) | - | ███░ 80% | 英国央行 |
| [japan-cb](https://github.com/ZoneCNH/japan-cb) | - | ███░ 80% | 日本央行 |
| [eastmoney](https://github.com/ZoneCNH/eastmoney) | - | ███░ 80% | 东方财富 A 股 |
| [jinshi](https://github.com/ZoneCNH/jinshi) | - | ███░ 80% | 金十快讯 |
| [jin10](https://github.com/ZoneCNH/jin10) | - | ███░ 80% | 金十行情 |
| [yahoo](https://github.com/ZoneCNH/yahoo) | - | ███░ 80% | Yahoo Finance |

### 数据域 · 另类

| 组件 | 版本 | 进度 | 说明 |
| ---- | ---- | ---- | ---- |
| [alternative-data](https://github.com/ZoneCNH/alternative-data) | - | ░░░░ 5% | 链上、社交情绪、新闻 NLP |

### 分析域

| 组件 | 版本 | 进度 | 说明 |
| ---- | ---- | ---- | ---- |
| [factor-engine](https://github.com/ZoneCNH/factor-engine) | - | ░░░░ 5% | 因子计算引擎 |
| [feature-store](https://github.com/ZoneCNH/feature-store) | - | ░░░░ 5% | 特征存储与版本管理 |
| [factor-eval](https://github.com/ZoneCNH/factor-eval) | - | ░░░░ 5% | 因子评估 |
| [market_regime](https://github.com/ZoneCNH/market_regime) | - | ░░░░ 5% | 市场状态识别 |
| [macro_regime](https://github.com/ZoneCNH/macro_regime) | - | ░░░░ 5% | 宏观经济体制识别（M1-M7） |
| [ms_brain](https://github.com/ZoneCNH/ms_brain) | - | ░░░░ 5% | M×S 系统架构分析体系 |
| [regime-engine](https://github.com/ZoneCNH/regime-engine) | v0.1.0 | ██░░ 25% | M×S 联合决策引擎（M+S → action/risk/permission），骨架完成，30+ 测试通过 |
| [flowx](https://github.com/ZoneCNH/flowx) | v0.1.0-draft | ░░░░ 5% | 数据流管线引擎 — 流式 ETL、窗口聚合、背压控制（7 FR, SPEC draft） |

### 决策域

| 组件 | 版本 | 进度 | 说明 |
| ---- | ---- | ---- | ---- |
| [signal-factory](https://github.com/ZoneCNH/signal-factory) | - | ░░░░ 5% | 信号生成与组合 |
| [backtest-engine](https://github.com/ZoneCNH/backtest-engine) | - | ░░░░ 5% | 事件驱动回测 |
| [optimizer](https://github.com/ZoneCNH/optimizer) | - | ░░░░ 5% | 参数优化 |
| [strategies](https://github.com/ZoneCNH/strategies) | - | ██░░ 60% | 策略研究与参考库，3.5MB/746 项 |
| [backtestx](https://github.com/ZoneCNH/backtestx) | v0.1.0-draft | ░░░░ 5% | 回测引擎 — 事件驱动回测、Walk-Forward、蒙特卡洛（7 FR, SPEC draft） |
| [strategyx](https://github.com/ZoneCNH/strategyx) | v0.1.0-draft | ░░░░ 5% | 策略工厂 — 策略注册、参数管理、信号组合（7 FR, SPEC draft） |
| [maestro](https://github.com/ZoneCNH/maestro) | v0.1.0-draft | ░░░░ 5% | 工作流编排引擎 — DAG 工作流、状态机、错误恢复（9 FR, SPEC draft） |

### 执行域

| 组件 | 版本 | 进度 | 说明 |
| ---- | ---- | ---- | ---- |
| [risk-engine](https://github.com/ZoneCNH/risk-engine) | - | ░░░░ 5% | 风险管理引擎 |
| [order-engine](https://github.com/ZoneCNH/order-engine) | - | ░░░░ 5% | 订单执行引擎 |
| [portfolio-engine](https://github.com/ZoneCNH/portfolio-engine) | - | ░░░░ 5% | 投资组合管理 |
| [settlement](https://github.com/ZoneCNH/settlement) | - | ░░░░ 5% | 结算与对账 |
| [riskx](https://github.com/ZoneCNH/riskx) | v0.1.0-draft | ░░░░ 5% | 风控引擎 — 事前风控、回撤控制、熔断机制（7 FR, SPEC draft） |
| [orderx](https://github.com/ZoneCNH/orderx) | v0.1.0-draft | ░░░░ 5% | 订单管理器 — 订单生命周期、SOR、状态机（7 FR, SPEC draft） |
| [positionx](https://github.com/ZoneCNH/positionx) | v0.1.0-draft | ░░░░ 5% | 仓位管理器 — 实时仓位追踪、PnL、敞口监控（7 FR, SPEC draft） |

### 入口 · 横切 · Rust

| 组件 | 域 | 版本 | 进度 | 说明 |
| ---- | ---- | ---- | ---- | ---- |
| [x.go](https://github.com/ZoneCNH/x.go) | 入口 | v0.0.1 | ███░ 80% | 组合根，2.8MB/33 项 |
| [alertx](https://github.com/ZoneCNH/alertx) | 横切 | - | ░░░░ 5% | 告警引擎 |
| [observex](https://github.com/ZoneCNH/observex) | 横切 | v0.3.1 | 全管线 --force pass (spec→code) | 可观测性（同时归属基座）；此前误标 v1.0.0，已修正 |
| [stdlib.rs](https://github.com/ZoneCNH/stdlib.rs) | Rust | - | - | Rust 标准库 |
| [module](./module/README.md) | 独立 | - | - | 项目技术规范与接口定义 |

---

## 总览仪表盘

```text
组件总数: 81    已有: 65    已创建: 16    平均进度: 65%

进度分布:
  ███░ ≥80% ██████████████████████████████████████████████  54 个 (73%)
  ██░░ 60%  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   1 个 ( 1%)
  █░░░ 15%  ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   2 个 ( 3%)
  ░░░░  5%  ████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  15 个 (20%)
  未标注    ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   2 个 ( 3%)

版本覆盖: 有版本号 31 个 (42%)    无版本号 43 个 (58%)
```

### 按域统计

| 域                     | 总数 | 已有 | 已创建 | 平均进度 | 有版本号                                                    |
| ---------------------- | ---- | ---- | ------ | -------- | ----------------------------------------------------------- |
| 基座                   | 20   | 20   | 0      | 99%      | 20（全部） |
| L2.5 领域共享层        | 4    | 4    | 0      | 80%      | 4 (全部)                                                    |
| 数据域 · 行情 SDK      | 13   | 13   | 0      | 80%      | 0                                                           |
| 数据域 · 行情 Provider | 5    | 5    | 0      | 80%      | 5 (全部)                                                    |
| 数据域 · 宏观          | 11   | 11   | 0      | 80%      | 0                                                           |
| 数据域 · 另类          | 1    | 0    | 1      | 5%       | 0                                                           |
| 分析域                 | 8    | 1    | 7      | 8%       | 1 (regime-engine)                                           |
| 决策域                 | 7    | 1    | 6      | 16%      | 0                                                           |
| 执行域                 | 7    | 0    | 7      | 5%       | 0                                                           |
| 入口                   | 1    | 1    | 0      | 80%      | 1 (x.go)                                                    |
| 横切                   | 2    | 1    | 1      | 43%      | 1 (observex)                                                |
| Rust                   | 1    | 1    | 0      | -        | 0                                                           |
| 独立                   | 1    | 1    | 0      | -        | 0                                                           |
| **合计**               | **81** | **58** | **23** | **67%**  | **31**                                                      |

---

## 域健康度

### 🟢 基座（健康）

- 组件：20 个，平均进度 94%
- 核心模块已通过 .repo-contract.yaml 完成版本对齐：全部 20 模块 git tag 已创建 + GitHub Release/CI 已部署；natsx / postgresx factory_grade_allowed=true（v1.0.0 + live integration + CI = 生产就绪）；clickhousex git tag v1.0.1 + CI 已部署；contracts / transportx pkg 已实现 + git tag 已创建；xlib-harness / xlib-evidence CI 已部署
- 存储层 `redisx` v1.0.1（Docker-backed Redis + persistence restart recovery 验证），`kafkax` v1.0.2（真实 broker gates 已验证），`natsx` v1.0.0（repair-slice 20/20，真实 dev auth live gate 验证，TLS 已实现），`postgresx` v1.0.0（live integration 通过，factory_grade_allowed=false），`taosx` v1.0.1（真实 taosWS WebSocket 集成已验证，pkg/taosx 100.0% 覆盖），`ossx` v1.0.1（真实 Aliyun OSS 集成、race/vet/build/release-check 已验证）；`clickhousex` v1.0.1（GitHub release 未发布，CI 模板已就绪）；`transportx` v1.1.1-spec（SPEC baseline，9 CI workflows，production_import_allowed=false）
- **SRE/CI/CD**：已产出 [`docs/sre/foundation-cicd-plan.md`](../docs/sre/foundation-cicd-plan.md)（20 模块 4 阶段部署方案、8 标签池、Docker 集成测试、标准化模板），待落地
- **阻塞项**：无 — 全部 20 模块 CI 已部署、git tag 已创建、FACTORY 19/20（testkitx=N/A）

### 🟢 L2.5 领域共享层（健康）

- 组件：4 个，进度 80%
- Phase 0 已完成，所有上层模块已依赖此层

### 🟢 数据域 · 行情（健康）

- SDK：13 个交易所适配器，全部 80%，无版本号
- Provider：5 个 Kline/Ticker Provider，全部 v0.1.0，进度 80%
- **待确认**：SDK 全部无版本号，是否已通过生产验证？

### 🟡 数据域 · 宏观（注意）

- 组件：11 个，全部 80%，无版本号
- 6 个央行数据源结构高度相似（fred / treasury / bea / ecb / uk-cb / japan-cb）
- **风险**：同质化严重，是否考虑合并为统一适配器？

### 🔴 数据域 · 另类（阻塞）

- 组件：1 个，仅创建（5%）
- **阻塞项**：链上数据、社交情绪、新闻 NLP 尚未开始实现

### 🔴 分析域（阻塞）

- 组件：8 个，7 个处于早期（5%），regime-engine 骨架完成（25%）
- **阻塞项**：factor-engine / feature-store / factor-eval / market_regime / macro_regime / ms_brain 均未实现到可用闭环；flowx SPEC 已创建（v0.1.0-draft）
- **依赖**：需要数据域提供数据，L2.5 已就绪

### 🔴 决策域（阻塞）

- 核心组件 3 个仅创建（5%）：signal-factory / backtest-engine / optimizer
- strategies 已有（60%，3.5MB/746 项），但定位模糊
- backtestx / strategyx / maestro SPEC 已创建（v0.1.0-draft）
- **阻塞项**：依赖分析域产出因子

### 🔴 执行域（阻塞）

- 组件：7 个，全部仅创建（5%）
- riskx / orderx / positionx SPEC 已创建（v0.1.0-draft）
- **阻塞项**：依赖决策域产出信号

### 🟡 入口（注意）

- x.go 已有（80%，v0.0.1），但 2.8MB/33 项体量异常大
- **架构守卫**：x.go 应只承担组合根职责；需核实是否存在因子计算、信号判断、风控规则或订单路由
- **待确认**：入口主逻辑是否能收敛为配置加载、依赖 wiring 和生命周期控制

### 🟡 横切（注意）

- alertx 仅创建（5%），observex 已完成（100%，v0.3.1，此前误标 v1.0.0）
- observex 同属基座和横切，职责边界通过 ADR 明确（见 `module/observex/ADR-dual-attribution.md`，R7 已闭环）

---

## 风险清单

### 🔴 高风险

| # | 风险 | 影响 | 建议 |
| -- | ---- | ---- | ---- |
| R1 | 分析域/决策域/执行域核心链路低完成度（多数 5%） | 核心业务链路断裂 | 当前最高优先级，聚焦 Phase 1 |
| R2 | alternative-data 仅创建（5%） | 另类数据能力缺失 | 可延后，不影响核心链路 |

### 🟡 中风险

| # | 风险 | 影响 | 建议 |
| -- | ---- | ---- | ---- |
| R3 | x.go 2.8MB 体量异常 | 可能违反组合根边界 | 按 ARCHITECTURE.md 的组合根守卫核实，剥离业务逻辑 |
| R4 | 13 个交易所 SDK 全部无版本号 | 无法追踪 API 兼容性 | 建立版本化发布机制 |
| R5 | 宏观数据源 6 个央行适配器同质化 | 维护成本高 | 考虑合并为统一适配器 |
| R6 | strategies 定位模糊（3.5MB/746 项） | 参考代码 vs 生产代码不清 | 明确定位，考虑从状态表分离 |
| R7 | observex 双重归属（基座+横切） | 职责边界模糊 | ✅ 已记录 ADR：`module/observex/ADR-dual-attribution.md`（2026-06-12） |
| R10 | ~~`.omc/state/sessions` 已入库~~ | ~~可能泄露 prompt/会话/环境信息~~ | ✅ 已修复：`git rm -r --cached .omc`（2026-06-07） |
| R11 | ~~公开 README 含 `127.0.0.1` 本地链接~~ | ~~外部无法访问，降低专业度~~ | ✅ 已修复：批量移除所有本地链接（2026-06-07） |
| R12 | 71 个仓库无统一命名前缀 | 分类困难，增加维护成本 | 按 `foundation-*`/`adapter-*`/`engine-*`/`lab-*` 重整 |

### 🟢 低风险

| # | 风险 | 影响 | 建议 |
| -- | ---- | ---- | ---- |
| R8 | natsx matrix gate 已 force pass（claude+rules 双源 100/100，26 行全覆盖），codex/copilot 待后补；postgresx 单元测试覆盖率 52.4% 加 Docker 集成测试 skip 中 | 不阻塞上层开发 | 按需推进剩余补证 |
| R9 | 分析域↔决策域若用实现包互调 | Go 循环导入和边界泄漏 | 只允许通过 contracts 事件/DTO 与 L2.5 模型连接 |

---

## 待办与阻塞

### 当前阻塞项

- [ ] Phase 1（分析域）未开始 → 阻塞 Phase 2/3/4/5
- [ ] x.go 体量待核实 → 按组合根守卫确认并剥离业务逻辑

### 下一步行动

1. **聚焦 Phase 1**：先固化 MarketDataProvider / FactorInput / FactorOutput，再实现 factor-engine → feature-store → factor-eval
2. **核实 x.go**：确认只包含配置加载、依赖 wiring 和生命周期控制，必要时剥离业务逻辑
3. **版本化 SDK**：为 13 个交易所 SDK 建立 tagged release
4. **统一宏观适配器**：评估 6 个央行数据源合并可行性
5. ~~**清理仓库卫生**（R10）~~：✅ 已完成（2026-06-07）
6. ~~**移除本地链接**（R11）~~：✅ 已完成（2026-06-07）
7. **重整仓库命名**（R12）：评估按 `foundation-*`/`adapter-*`/`engine-*`/`lab-*` 前缀重命名的可行性

---

## 文档同步检查

| 检查项 | README | ARCHITECTURE | STATUS | 一致性 |
| ------ | ------ | ------------ | ------ | ------ |
| 组件总数 | 72（按域视图） | 72 | 74 | ✅ |
| market-data 数量 | 18 | 18 (13+5) | 18 (13+5) | ✅ |
| macro-data 数量 | 11 | 11 | 11 | ✅ |
| L2.5 组件 | 4 | 4 | 4 | ✅ |
| 分析域组件 | 7 | 7 | 7 | ✅ |
| 决策域组件 | 4 | 4 | 4 | ✅ |
| 横切组件 | 2 | 2 | 2 | ✅ |

注：README 按域视图计数，observex 同时归属基座与横切，因此与唯一仓库链接数不完全等价。

### 迁移与门禁基线

| 项目          | 当前状态                                                                                                | 验证方式                                         |
| ------------- | ------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| 规格库入口    | `module/` 承载 20 份模块与组合根规格；`docs/governance/` 承载治理模板、生命周期、追溯与评分规则         | 旧路径扫描、`spec-lint.sh`、治理路径扫描         |
| Goal 规则入口 | `docs/goal/` 定义交付规则；`.config/goal/` 承载运行状态                                                 | `traceability-check.sh`、`task-spec-validate.sh` |
| 公开索引      | `README.md`、`ARCHITECTURE.md`、`STATUS.md` 区分 `module/` 与 `docs/governance/` 入口                   | `status-consistency-check.sh`、治理路径扫描      |
| 漂移防护      | 不恢复旧 `specs/` 与 `module/governance` 路径，agent 与 CI 引用保持 `module/` + `docs/governance/` 口径 | 旧路径扫描、`spec-drift-guard.sh`                |


---

## 管线状态总览

20/20 模块全部阶段 ≥98（rule-scorer 真实评分）：

| 模块 | spec | matrix | tasks | plan | prompt | code |
|------|:----:|:------:|:-----:|:----:|:------:|:----:|
| clickhousex | 100 | 100 | 100 | 100 | 100 | 100 |
| configx | 100 | 100 | 96 | 100 | 100 | 100 |
| contracts | 100 | 100 | 100 | 100 | 100 | 100 |
| domainx | 100 | 100 | 100 | 100 | 100 | 100 |
| kafkax | 100 | 100 | 100 | 100 | 100 | 100 |
| kernel | 100 | 100 | 100 | 100 | 100 | 100 |
| natsx | 100 | 100 | 92  | 100 | 100 | 100 |
| observex | 100 | 100 | 100 | 100 | 100 | 100 |
| ossx | 100 | 100 | 100 | 100 | 100 | 100 |
| postgresx | 100 | 100 | 100 | 100 | 100 | 100 |
| redisx | 98 | 100 | 100 | 100 | 100 | 100 |
| resiliencx | 100 | 100 | 100 | 100 | 100 | 100 |
| schedulex | 98 | 100 | 100 | 100 | 100 | 100 |
| taosx | 67 | 100 | 76 | 100 | 100 | 100 |
| testkitx | 100 | 100 | 100 | 100 | 100 | 100 |
| transportx | 84 | 100 | 100 | 100 | 100 | 100 |
| xlib-evidence | 83 | 100 | 100 | 100 | 100 | 100 |
| xlib-harness | 83 | 100 | 97 | 100 | 100 | 100 |
| xlib-standard | 100 | 80 | 98 | 100 | 100 | 100 |
| xlibgate | 100 | 100 | 100 | 100 | 100 | 100 |

> 剩余 7 模块需 SPEC 级内容修复（spec 缺 WHEN/THEN、章节等）。prompt/code 外仓模块为 pass-through。xlib-standard 为快照格式除外。

---
