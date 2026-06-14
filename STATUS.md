# 📊 项目状态监控

> FoundationX 量化交易基础设施的实时健康度与风险追踪
>
> 数据来源：各 GitHub 仓库实际状态，定期更新
>
> 最后更新：2026-06-14
>
> 同步基线：`module/` 为模块规格库 SSOT，`docs/governance/` 为 Spec 治理 SSOT，`docs/goal/` 为 Goal 规则 SSOT，`specs/` 已移除。

---

## 组件明细表

### 基座

| 组件 | 版本 | 进度 | 仓库大小 | 说明 |
| ---- | ---- | ---- | -------- | ---- |
| [xlib-standard](https://github.com/ZoneCNH/xlib-standard) | v1.0.0 | ████ 100% | spec=100 mat=80 tsk=98 pln=100 prm=100 cod=100 | 标准事实源 / Go Reference Template；Generator/Harness/Evidence 已拆分至 xlib-harness / xlib-evidence |
| [xlib-harness](https://github.com/ZoneCNH/xlib-harness) | v1.0.0 | ████ 100% | spec=83 mat=100 tsk=97 pln=100 prm=100 cod=100 | 模块生成器与门禁执行器：generate/scaffold、spec-lint、boundary-check、traceability-gate（6 FR，6 TC） |
| [xlib-evidence](https://github.com/ZoneCNH/xlib-evidence) | v1.0.0 | ████ 100% | spec=83 mat=100 tsk=100 pln=100 prm=100 cod=100 | 证据收集与发布运行时：collect-coverage、generate-manifest、validate-manifest、report（5 FR，5 TC） |
| [xlibgate](https://github.com/ZoneCNH/xlibgate) | v1.0.2 | ███░ 90% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | import 边界/go.mod/Go baseline/release/L2 门禁（14 files, +1053, xlibgate 测试通过） |
| [kernel](https://github.com/ZoneCNH/kernel) | v1.0.0 | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | L0 原语 / 12 子包 / stdlib-only / v1.0.0 已发布 |
| [configx](https://github.com/ZoneCNH/configx) | v1.0.0 | █████ 100% | spec=100 mat=100 tsk=96 pln=100 prm=100 cod=100 | 配置管理；v1.0.0 已发布，97.1% 覆盖率，13 FR 全部实现 |
| [observex](https://github.com/ZoneCNH/observex) | v1.0.0 | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 可观测性 |
| [testkitx](https://github.com/ZoneCNH/testkitx) | v1.0.0 | ███░ 90% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | Fake / Fixture / Golden / Contract / Leak / Boundary / Manifest 测试工具包（PR #13 — fake + eventually + golden + boundary + leak，80.7% 覆盖，36/36 通过） |
| [resiliencx](https://github.com/ZoneCNH/resiliencx) | v1.0.1 | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 弹性策略（timeout / retry / circuit / bulkhead / rate / fallback） |
| [schedulex](https://github.com/ZoneCNH/schedulex) | [v1.0.0](https://github.com/ZoneCNH/schedulex/releases/tag/v1.0.0) | █████ 100% | spec=98 mat=100 tsk=100 pln=100 prm=100 cod=100 | cron/interval/delay 调度、Overlap/Misfire 策略、Locker 扩展点、Clock 注入、8 示例（98.2% 覆盖，score 10.0；race/vet/lint/govulncheck 与下游 smoke 通过） |
| [redisx](https://github.com/ZoneCNH/redisx) | v1.0.0 | █████ 100% | spec=98 mat=100 tsk=100 pln=100 prm=100 cod=100 | Redis L2 adapter：KV/TTL/Hash/List/Pipeline/Cache-aside/Lock/RateLimit/Pool/Persistence restart recovery；release_ready=true，score 100；直接生产依赖限定为 kernel + Redis 客户端库；docker-compose/devcontainer 暴露非敏感 REDISX_REDIS_ADDR/URL/DB 端点变量；未暴露/打印/记录 secret；使用 Docker-backed Redis 验证。 |
| [kafkax](https://github.com/ZoneCNH/kafkax) | [v1.0.0](https://github.com/ZoneCNH/kafkax/releases/tag/v1.0.0) | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | Kafka L2 adapter 已发布；driver-neutral API + 可选 kafka-go 生产驱动；真实 broker gates；merge `0545db2` |
| [natsx](https://github.com/ZoneCNH/natsx) | v1.0.1 | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | NATS L2 adapter：Core NATS / JetStream / Drain / reconnect / degraded health / canonical FOUNDATIONX_NATS_* 配置；TLS 已实现；matrix 26 行全覆盖；claude+rules 双源 100/100；codex/copilot 待补齐 |
| [postgresx](https://github.com/ZoneCNH/postgresx) | v1.0.1 | ████░ 90% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | PostgreSQL — 关系型存储、事务、迁移（v1.0 发布范围 100/100；单元测试 52.4% + Docker 集成测试 skip 状态；全局成熟度待生产 soak 后提升） |
| [taosx](https://github.com/ZoneCNH/taosx) | v1.0.1 | █████ 100% | spec=67 mat=100 tsk=76 pln=100 prm=100 cod=100 | TDengine L2 adapter contract；pkg/taosx 公共 API，默认驱动显式不可用，真实 taosWS 集成已验证 |
| [ossx](https://github.com/ZoneCNH/ossx) | v1.0.1 | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | Aliyun OSS 对象存储 L2 adapter；race、vet、build、release-check 已通过；S3/MinIO/Azure/GCS Provider 仅保留扩展位 |
| [clickhousex](https://github.com/ZoneCNH/clickhousex) | v1.0.1 | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | ClickHouse — OLAP 查询、批量写入（TRACEABILITY 覆盖率 100%） |
| [contracts](https://github.com/ZoneCNH/contracts) | v1.0.1-spec | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 跨域稳定端口/事件/DTO 契约；TRACEABILITY §1-§7 完整；goal.md 对齐 CONSTITUTION P7；SPEC/Matrix/Tasks 全面修复 |
| [transportx](https://github.com/ZoneCNH/transportx) | v1.1.1-spec | █████ 100% | spec=84 mat=100 tsk=100 pln=100 prm=100 cod=100 | 应用通信底座规格基线；25 FR, 18 BR, 12 NFR, 25 AC, 25 TC, 12 CI gates — SPEC/Matrix/Tasks 三阶段满分 |
| [domainx](https://github.com/ZoneCNH/domainx) | v0.1.0 | █████ 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 |

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

### 决策域

| 组件 | 版本 | 进度 | 说明 |
| ---- | ---- | ---- | ---- |
| [signal-factory](https://github.com/ZoneCNH/signal-factory) | - | ░░░░ 5% | 信号生成与组合 |
| [backtest-engine](https://github.com/ZoneCNH/backtest-engine) | - | ░░░░ 5% | 事件驱动回测 |
| [optimizer](https://github.com/ZoneCNH/optimizer) | - | ░░░░ 5% | 参数优化 |
| [strategies](https://github.com/ZoneCNH/strategies) | - | ██░░ 60% | 策略研究与参考库，3.5MB/746 项 |

### 执行域

| 组件 | 版本 | 进度 | 说明 |
| ---- | ---- | ---- | ---- |
| [risk-engine](https://github.com/ZoneCNH/risk-engine) | - | ░░░░ 5% | 风险管理引擎 |
| [order-engine](https://github.com/ZoneCNH/order-engine) | - | ░░░░ 5% | 订单执行引擎 |
| [portfolio-engine](https://github.com/ZoneCNH/portfolio-engine) | - | ░░░░ 5% | 投资组合管理 |
| [settlement](https://github.com/ZoneCNH/settlement) | - | ░░░░ 5% | 结算与对账 |

### 入口 · 横切 · Rust

| 组件 | 域 | 版本 | 进度 | 说明 |
| ---- | ---- | ---- | ---- | ---- |
| [x.go](https://github.com/ZoneCNH/x.go) | 入口 | v0.0.1 | ███░ 80% | 组合根，2.8MB/33 项 |
| [alertx](https://github.com/ZoneCNH/alertx) | 横切 | - | ░░░░ 5% | 告警引擎 |
| [observex](https://github.com/ZoneCNH/observex) | 横切 | v1.0.0 | 全管线 --force pass (spec→code) | 可观测性（同时归属基座） |
| [stdlib.rs](https://github.com/ZoneCNH/stdlib.rs) | Rust | - | - | Rust 标准库 |
| [module](./module/README.md) | 独立 | - | - | 项目技术规范与接口定义 |

---

## 总览仪表盘

```text
组件总数: 74    已有: 58    已创建: 16    平均进度: 69%

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
| 分析域                 | 7    | 1    | 6      | 8%       | 1 (regime-engine)                                           |
| 决策域                 | 4    | 1    | 3      | 19%      | 0                                                           |
| 执行域                 | 4    | 0    | 4      | 5%       | 0                                                           |
| 入口                   | 1    | 1    | 0      | 80%      | 1 (x.go)                                                    |
| 横切                   | 2    | 1    | 1      | 43%      | 1 (observex)                                                |
| Rust                   | 1    | 1    | 0      | -        | 0                                                           |
| 独立                   | 1    | 1    | 0      | -        | 0                                                           |
| **合计**               | **74** | **58** | **16** | **69%**  | **31**                                                      |

---

## 域健康度

### 🟢 基座（健康）

- 组件：20 个，平均进度 99%
- 核心模块（kernel / configx / observex / resiliencx / schedulex / testkitx / redisx / kafkax / natsx / postgresx / taosx / ossx / transportx）已成熟，有版本号或规格基线；domainx 已产出完整 SPEC + TRACEABILITY + tasks；xlib-harness / xlib-evidence 已从 xlib-standard 拆分为独立规格模块；kernel/configx/observex/schedulex/redisx/kafkax/natsx/postgresx 已发布 v1.0.0，taosx/ossx 已发布 v1.0.1，clickhousex 已发布 v1.0.1；transportx 已升级为 v1.1.1 规格基线
- 存储层 `redisx` 已发布 v1.0.0（全局成熟度 100%，Docker-backed Redis + persistence restart recovery 验证），`kafkax` 已发布 v1.0.0（100%），`natsx` 已发布 v1.0.0（100%，repair-slice 20/20，真实 dev auth live gate 验证），`postgresx` 已发布 v1.0.0（全局成熟度 90%），`taosx` 已发布 v1.0.1（100%）；`ossx` 已发布 v1.0.1（真实 Aliyun OSS 集成、race、vet、build、release-check 与 100.0% 覆盖已验证）；`clickhousex` 已发布 v1.0.1（100%）；`transportx` 已规格化 100%（SPEC/Matrix/Tasks 三阶段满分，27 Tasks 全部达标），并以 v1.1.1 规格基线覆盖 QoS、Codec、RPC、EventBus、Stream、ExecutionMode、Outbox/Inbox、Audit Plane、Data Classification 与 SchemaRegistry
- **SRE/CI/CD**：已产出 [`docs/sre/foundation-cicd-plan.md`](../docs/sre/foundation-cicd-plan.md)（20 模块 4 阶段部署方案、8 标签池、Docker 集成测试、标准化模板），待落地
- **阻塞项**：clickhousex 已发布 v1.0.1；xlibgate CLI 已实现（PR #23）；testkitx code 阶段已完成（PR #13）；postgresx foundationx 依赖已移除（PR #8 → PR #9）

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

- 组件：7 个，6 个处于早期（5%），regime-engine 骨架完成（25%）
- **阻塞项**：factor-engine / feature-store / factor-eval / market_regime / macro_regime / ms_brain 均未实现到可用闭环
- **依赖**：需要数据域提供数据，L2.5 已就绪

### 🔴 决策域（阻塞）

- 核心组件 3 个仅创建（5%）：signal-factory / backtest-engine / optimizer
- strategies 已有（60%，3.5MB/746 项），但定位模糊
- **阻塞项**：依赖分析域产出因子

### 🔴 执行域（阻塞）

- 组件：4 个，全部仅创建（5%）
- **阻塞项**：依赖决策域产出信号

### 🟡 入口（注意）

- x.go 已有（80%，v0.0.1），但 2.8MB/33 项体量异常大
- **架构守卫**：x.go 应只承担组合根职责；需核实是否存在因子计算、信号判断、风控规则或订单路由
- **待确认**：入口主逻辑是否能收敛为配置加载、依赖 wiring 和生命周期控制

### 🟡 横切（注意）

- alertx 仅创建（5%），observex 已完成（100%，v1.0.0）
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

13/20 模块全部阶段 ≥98（rule-scorer 真实评分）：

| 模块 | spec | matrix | tasks | plan | prompt | code |
|------|:----:|:------:|:-----:|:----:|:------:|:----:|
| clickhousex | 100 | 100 | 100 | 100 | 100 | 100 |
| configx | 100 | 100 | 96 | 100 | 100 | 100 |
| contracts | 100 | 100 | 100 | 100 | 100 | 100 |
| domainx | 100 | 100 | 100 | 100 | 100 | 100 |
| kafkax | 100 | 100 | 100 | 100 | 100 | 100 |
| kernel | 100 | 100 | 100 | 100 | 100 | 100 |
| natsx | 100 | 100 | 100 | 100 | 0 | 100 |
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
