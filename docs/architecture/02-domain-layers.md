## 思路推演 — 2026-06-14 业务域模块化决策

### 为什么新增 7 个业务域模块

在此次推演之前，分析/决策/执行域仅有早期占位仓库（factor-engine、backtest-engine、risk-engine 等），缺乏规范化规格和接口契约。本次以 23 节 SPEC 结构为每个域创建了具名模块（X 后缀），形成从数据到执行的完整链路：

```text
factor-eval ──► signal-factory ──► riskx ──► orderx ──► positionx   (实盘)
(因子评估)     (信号生成)         (风控)    (订单)    (仓位)

backtestx ──► optimizer ──► strategyx ──► maestro                  (反馈→编排)
(回测验证)    (参数优化)   (策略工厂)    (工作流)
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
| 基座   | 标准源、生成器、证据运行时、L0 原语、L1 primitives、L1 Assembly 进程组装层、测试期证据、存储扩展、稳定契约与传输契约 | xlib-standard, xlib-harness, xlib-evidence, kernel, configx, observex, testkitx, resiliencx, schedulex, bootstrap, xlibgate, redisx, kafkax, natsx, postgresx, taosx, ossx, clickhousex, contracts, transportx |
| L2.5   | 领域共享值对象和语义模型，上层统一依赖                                                                                        | domainx, decimalx, domain-market, domain-exchange, domain-macro                                                                                         |
| 数据域 | 行情、宏观、另类数据采集                                                                                                      | market-data (14: 1 dispatch + 12 SDK + 1 C/S Module), macro-data (10), alternative-data                                                                                       |
| 分析域 | 因子计算、特征存储、因子评估、市场/宏观环境分类、数据流管线、M×S 联合决策（三引擎：market_engine→S / macro_engine→M / regime_engine→M+S） | factor-engine, feature-store, factor-eval, market-regime, macro-regime, regime-engine, ms-brain, flowx                                                              |
| 决策域 | 信号生成、历史回测、参数优化、策略工厂、工作流编排（并行协作）                                                                  | signal-factory, backtest-engine, optimizer, backtestx, strategyx, maestro                                                                          |
| 执行域 | 风险管理、订单执行、仓位管理、结算                                                                                              | risk-engine, order-engine, portfolio-engine, settlement, riskx, orderx, positionx                                                                              |
| 入口   | 启动、配置加载、依赖组装、生命周期控制                                                                                        | x.go                                                                                                                                                       |
| 横切   | 告警、可观测性                                                                                                                | alertx, observex                                                                                                                                           |

