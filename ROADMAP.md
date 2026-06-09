# 🗺️ FoundationX ROADMAP

> 从 70 个模块的现状到量化交易基础设施完整闭环的执行路线图。
>
> 基于 2026-06-09 项目深度分析，综合 STATUS.md、ARCHITECTURE.md、CONSTITUTION.md、DATAFLOW.md 和 FOUNDATION-V1.md 制定。

最后更新：2026-06-09

---

## 现状快照

```text
组件总数: 70    已有: 54    已创建: 16    平均进度: 47%

按域分布:
  基座 (16)         ████████████████░░░░░░░░░░░░░░░░  54%  核心 80% / 存储 15%
  L2.5  (4)         ████████████████████████████████░  80%  ✅ 完成
  数据域 (34)       ████████████████████████████████░  72%  行情 80% / 宏观 80% / 另类 5%
  分析域 (7)        ███░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   8%  🔴 关键阻塞
  决策域 (4)        █████░░░░░░░░░░░░░░░░░░░░░░░░░░░  19%  🔴 关键阻塞
  执行域 (4)        ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   5%  🔴 关键阻塞
  入口/横切 (3)     ████████████████████████████░░░░░  60%  x.go 需瘦身
  Rust   (1)        -                                   独立
```

**核心矛盾：** 基座层和数据层已相对成熟（80%），但核心业务链路（分析 → 决策 → 执行）几乎空白（5-8%）。系统缺少从数据到交易的完整闭环。

---

## 目标里程碑

```text
                        2026 Q3           2026 Q4           2027 Q1           2027 Q2
                           │                 │                 │                 │
  Foundation v1 ◄──────────┤                 │                 │                 │
  (基座闭环)               │                 │                 │                 │
                           │                 │                 │                 │
  Phase 1: 分析域 ◄────────┼─────────────────┤                 │                 │
  (因子+Regime)            │                 │                 │                 │
                           │                 │                 │                 │
  Phase 2: 决策域 ◄────────┼─────────────────┼─────────────────┤                 │
  (信号+回测)              │                 │                 │                 │
                           │                 │                 │                 │
  Phase 3: 执行域 ◄────────┼─────────────────┼─────────────────┼─────────────────┤
  (风控+订单+组合)         │                 │                 │                 │
                           │                 │                 │                 │
  Phase 4: 平台化 ◄────────┼─────────────────┼─────────────────┼─────────────────┤
  (结算+告警+另类)         │                 │                 │                 │
                           ▼                 ▼                 ▼                 ▼
```

---

## 阶段一：Foundation v1 — 基座闭环校准

> **目标：** 6 个基座模块 + x.go 组合根达到"可证明、可组合、可被上层消费"状态。
>
> **退出条件：** foundation-example 垂直烟雾测试全绿，xlibgate check-all exit 0。
>
> **预计周期：** 8-10 周
>
> **阻塞关系：** 所有后续阶段的前置条件。

### 1.1 P0 身份与边界修复（第 1-3 周）

| # | 任务 | 仓库 | 优先级 | 状态 |
|---|------|------|--------|------|
| F-001 | resiliencx 身份重置：删除 Standard Source 叙事，回归 runtime resilience policy library | resiliencx | **P0 阻塞** | ⬜ |
| F-002 | Go baseline 统一到 Go 1.23（含 testkitx 降级） | 全部 6 模块 | **P0 阻塞** | ⬜ |
| F-003 | foundationx compatibility 冻结：configx/observex 不再新增 foundationx usage | configx, observex | **P0** | ⬜ |
| F-004 | Foundation 依赖矩阵 CI 化：check-deps.sh + kernel stdlib-only + testkitx production import 检查 | ZoneCNH (文档仓库) | **P0** | ⬜ |
| F-005 | resiliencx 最小 API 实现：policy/runner/operation + timeout/retry/circuit/bulkhead/ratelimit/fallback | resiliencx | **P0** | ⬜ |

### 1.2 P1 各模块补最小 v1 能力（第 3-7 周，可并行）

| # | 任务 | 仓库 | 依赖 |
|---|------|------|------|
| F-010 | kernel: API freeze + primitive admission gate + stdlib-only CI check | kernel | 无 |
| F-011 | configx: Provenance + EffectiveConfigHash + SanitizedManifest + StrictDecode + SecretPolicy | configx | F-010 |
| F-012 | observex: label policy checker + redaction leak checker + metrics contract + health JSON schema | observex | F-010 |
| F-013 | resiliencx: classifier + idempotency guard + event sink + noop + fake-clock tests | resiliencx | F-005 |
| F-014 | schedulex: DST/timezone golden + misfire contract + overlap contract + lock interface + leak/race tests | schedulex | 无 |
| F-015 | testkitx: production import boundary scanner + golden update guard + unified assert API | testkitx | 无 |
| F-016 | contracts: 基座层 API snapshot 文件固化 | contracts | F-010~F-015 |

### 1.3 P2 Foundation Example 闭环验证（第 7-10 周）

| # | 任务 | 说明 | 依赖 |
|---|------|------|------|
| F-020 | foundation-example 垂直烟雾测试 | demo app 启停 + configx 加载 + observex 注入 + resiliencx 包裹 + schedulex 调度 + testkitx 验证 + release manifest | F-010~F-016 |
| F-021 | x.go 体检与瘦身 | 确认只包含配置加载、依赖 wiring 和生命周期控制，剥离业务逻辑 | F-020 |
| F-022 | xlibgate check-all 全绿 | 所有 import 边界、Go baseline、release evidence 门禁通过 | F-020 |

### Foundation v1 验收清单

- [ ] resiliencx README 不再包含 Standard Source / Generator / Harness 叙事
- [ ] 6 个模块 Go version 一致（1.23）
- [ ] foundationx compatibility 依赖已冻结或迁移
- [ ] xlibgate check-all exit code = 0
- [ ] foundation-example 可启动、可关闭、所有 make target 可运行
- [ ] x.go 体量合理（< 500KB），无业务逻辑泄漏
- [ ] 每个模块测试覆盖率 ≥ 80%（kernel ≥ 90%）
- [ ] FOUNDATION-TRACKER.md 全部勾选

---

## 阶段二：分析域 — 从数据到认知

> **目标：** 市场数据经因子计算、特征存储、因子评估，产出 RegimeSnapshot/RegimeCard/DecisionCard。
>
> **退出条件：** market-data → market_regime → RegimeSnapshot 可跑通；macro-data → macro_regime → RegimeCard 可跑通；M+S → regime_engine → DecisionCard 可跑通。
>
> **预计周期：** 10-14 周
>
> **前置依赖：** Foundation v1 完成；L2.5 领域共享层已完成（✅）。

### 2.1 契约先行（第 1-2 周）

| # | 任务 | 仓库 | 说明 |
|---|------|------|------|
| A-001 | 固化 MarketDataProvider / MacroDataProvider 接口 | contracts | 数据域 → 分析域的稳定端口 |
| A-002 | 固化 FactorInput / FactorOutput / FactorEvaluation DTO | contracts | 因子计算的输入输出契约 |
| A-003 | 固化 RegimeSnapshot / RegimeCard / DecisionCard DTO | contracts | 三引擎输出契约（参考 DATAFLOW.md） |
| A-004 | 固化 RegimeSnapshotEvent / RegimeCardEvent / DecisionCardEvent 事件协议 | contracts | Kafka 事件 Topic |

### 2.2 三引擎实现（第 2-10 周，可并行）

| # | 任务 | 仓库 | 依赖 | 退出条件 |
|---|------|------|------|----------|
| A-010 | market_regime 实现：五维评分 + S1-S7 分类器 + PIT 时间约束 | market_regime | A-001, A-003 | market-data → RegimeSnapshot 可跑通 |
| A-011 | macro_regime 实现：LGIP 四因子 + M1-M7 分类器 + 防泄露过滤 | macro_regime | A-003 | macro-data → RegimeCard 可跑通 |
| A-012 | regime_engine 实现：M×S 联合决策矩阵 + 冲突门 + 风险放大 | regime_engine | A-010, A-011 | M+S → DecisionCard 可跑通 |
| A-013 | market_regime 黄金案例校验：历史事件 → 预期 S-State 回测 | market_regime | A-010 | 2020 COVID / 2022 加息 / 2023 复苏 |
| A-014 | macro_regime 黄金案例校验：历史事件 → 预期 M-State 回测 | macro_regime | A-011 | 同上 |

### 2.3 因子计算管线（第 4-12 周，与 2.2 并行）

| # | 任务 | 仓库 | 依赖 | 退出条件 |
|---|------|------|------|----------|
| A-020 | factor-engine 核心：Factor 接口 + 因子注册 + 计算调度 | factor-engine | A-001, A-002 | 至少 3 个因子可计算 |
| A-021 | feature-store 核心：特征版本管理 + 时间点查询 + IC 评估 | feature-store | A-002 | 因子值可存储和检索 |
| A-022 | factor-eval 核心：IC/IR/换手率评估 + 因子排名 | factor-eval | A-020, A-021 | 因子质量可评估 |
| A-023 | 初始因子库：动量、波动率、资金费率、OI 变化等 10+ 基础因子 | factor-engine | A-020 | 因子库可用 |

### 分析域验收清单

- [ ] market_regime: S1-S7 分类器准确率 ≥ 80%（黄金案例集）
- [ ] macro_regime: M1-M7 分类器准确率 ≥ 80%（黄金案例集）
- [ ] regime_engine: M×S 矩阵 49 格全覆盖，冲突门逻辑正确
- [ ] factor-engine: ≥ 10 个因子可计算，通过 FactorOutput 契约
- [ ] feature-store: 因子值可存储、可检索、可版本化
- [ ] factor-eval: IC/IR 计算正确，因子排名可用
- [ ] 三引擎输出 DTO 已固化到 contracts
- [ ] DecisionLog 审计日志结构完整
- [ ] 所有模块测试覆盖率 ≥ 80%

---

## 阶段三：决策域 — 从认知到信号

> **目标：** DecisionCard 驱动信号生成，回测引擎验证策略，优化器调参。
>
> **退出条件：** DecisionCard → signal-factory → SignalIntent 可跑通；SignalIntent → backtest-engine → 回测报告可跑通；backtest → factor-eval 反馈可跑通。
>
> **预计周期：** 8-12 周
>
> **前置依赖：** 分析域 Phase 1 完成（至少 A-001~A-003 + A-012）。

### 3.1 契约固化（第 1-2 周）

| # | 任务 | 仓库 | 说明 |
|---|------|------|------|
| D-001 | 固化 SignalIntent / PortfolioTarget DTO | contracts | 决策域 → 执行域的意图契约 |
| D-002 | 固化 BacktestConfig / BacktestReport DTO | contracts | 回测配置与结果契约 |
| D-003 | 固化 FactorFeedback 事件 | contracts | 回测 → factor-eval 的反馈契约 |

### 3.2 信号与回测（第 2-10 周，可并行）

| # | 任务 | 仓库 | 依赖 | 退出条件 |
|---|------|------|------|----------|
| D-010 | signal-factory 核心：DecisionCard 消费 + 信号生成 + 信号过滤 + 信号评分 | signal-factory | D-001, A-012 | DecisionCard → SignalIntent 可跑通 |
| D-011 | signal-factory 策略模板：trend_following / range_trading / breakout / hedge / cash | signal-factory | D-010 | 5 种模板可切换 |
| D-012 | backtest-engine 核心：事件驱动引擎 + Tick 级回放 + 撮合模拟 | backtest-engine | D-002, A-001 | 历史数据回放可运行 |
| D-013 | backtest-engine 回测报告：收益率、夏普比、最大回撤、胜率 | backtest-engine | D-012 | 回测报告可生成 |
| D-014 | backtest → factor-eval 反馈闭环 | factor-eval | D-013, D-003 | 回测结果可反馈到因子评估 |
| D-015 | optimizer 核心：参数搜索 + Walk-forward 验证 | optimizer | D-012 | 参数优化可运行 |

### 3.3 策略研究整合（第 4-8 周）

| # | 任务 | 仓库 | 依赖 | 说明 |
|---|------|------|------|------|
| D-020 | strategies 定位澄清 | strategies | 无 | 明确为策略研究参考库，非生产代码 |
| D-021 | 从 strategies 提取可复用策略模板到 signal-factory | signal-factory | D-020 | 精选 3-5 个策略模板 |

### 决策域验收清单

- [ ] signal-factory: DecisionCard → SignalIntent 端到端可跑通
- [ ] 5 种策略模板可切换，通过 DecisionCard.template 字段驱动
- [ ] backtest-engine: 历史数据 Tick 级回放，撮合模拟合理
- [ ] 回测报告包含收益率、夏普比、最大回撤、胜率
- [ ] backtest → factor-eval 反馈闭环可运行
- [ ] optimizer: Walk-forward 验证可运行
- [ ] strategies 定位明确，与 signal-factory 边界清晰
- [ ] 所有模块测试覆盖率 ≥ 80%

---

## 阶段四：执行域 — 从信号到交易

> **目标：** SignalIntent 经风控放行、订单执行、组合管理，完成完整交易闭环。
>
> **退出条件：** SignalIntent → risk-engine → paper order-engine → portfolio update 可跑通。
>
> **预计周期：** 10-14 周
>
> **前置依赖：** 决策域 Phase 2 完成（至少 D-001 + D-010）。

### 4.1 契约固化（第 1-2 周）

| # | 任务 | 仓库 | 说明 |
|---|------|------|------|
| E-001 | 固化 RiskDecision / OrderIntent / ExecutionReport DTO | contracts | 执行域内部契约 |
| E-002 | 固化 PositionSnapshot / PnLReport / ExposureEvent DTO | contracts | 执行域 → 决策域反馈契约 |
| E-003 | 固化 trade_permission / position_caps 端口 | contracts | risk-engine 消费 DecisionCard 的端口 |

### 4.2 风控与执行（第 2-12 周）

| # | 任务 | 仓库 | 依赖 | 退出条件 |
|---|------|------|------|----------|
| E-010 | risk-engine 核心：trade_permission 消费 + VaR + 止损 + 持仓限额 + 压力测试 | risk-engine | E-001, E-003, A-012 | SignalIntent → RiskDecision 可跑通 |
| E-011 | risk-engine DecisionCard 集成：消费 risk_tier / position_caps / risk_multiplier | risk-engine | E-010, A-012 | M×S 决策驱动风控参数 |
| E-012 | order-engine 核心：统一订单接口 + 智能路由 + TWAP/VWAP + 滑点控制 | order-engine | E-001 | OrderIntent → ExecutionReport 可跑通 |
| E-013 | order-engine 交易所适配：对接 binance/okx SDK（paper trading 模式） | order-engine | E-012 | Paper trading 可运行 |
| E-014 | portfolio-engine 核心：多策略资金分配 + 再平衡 + 仓位追踪 | portfolio-engine | E-001, E-002 | Portfolio update 可运行 |
| E-015 | 执行反馈闭环：fills/positions/PnL/exposure events → 决策域 | contracts | E-014, D-001 | 执行结果可反馈到决策域 |

### 执行域验收清单

- [ ] risk-engine: SignalIntent → RiskDecision 端到端可跑通
- [ ] risk-engine: DecisionCard 的 risk_tier/position_caps/risk_multiplier 生效
- [ ] order-engine: 统一订单接口，paper trading 可运行
- [ ] order-engine: 至少对接 2 个交易所 SDK（binance/okx）
- [ ] portfolio-engine: 多策略资金分配 + 再平衡可运行
- [ ] 执行反馈事件（fills/PnL/exposure）可回到决策域
- [ ] 策略只能通过 risk-engine 提交订单（P5 原则验证）
- [ ] 所有模块测试覆盖率 ≥ 80%

---

## 阶段五：平台化 — 从交易到运维

> **目标：** 结算对账、告警引擎、另类数据，完成生产化运维能力。
>
> **预计周期：** 8-10 周
>
> **前置依赖：** 执行域 Phase 3 完成。

### 5.1 结算与告警

| # | 任务 | 仓库 | 说明 |
|---|------|------|------|
| P-001 | settlement 核心：PnL 计算 + 交易所对账 + 资金流水 | settlement | 每日结算可运行 |
| P-002 | alertx 核心：策略异常告警 + 风控触发告警 + 系统健康告警 | alertx | 告警可触达 |
| P-003 | alertx 集成：接入 observex metrics + risk-engine 事件 | alertx | 端到端告警可运行 |

### 5.2 另类数据

| # | 任务 | 仓库 | 说明 |
|---|------|------|------|
| P-010 | alternative-data 链上数据：交易所净流入/流出、大额转账 | alternative-data | 链上指标可用 |
| P-011 | alternative-data 社交情绪：Twitter/Reddit 情绪分数 | alternative-data | 情绪指标可用 |
| P-012 | alternative-data 新闻 NLP：事件驱动信号 | alternative-data | 新闻信号可用 |

### 5.3 存储层按需实现

| # | 任务 | 仓库 | 优先级 | 说明 |
|---|------|------|--------|------|
| P-020 | redisx 完整实现 | redisx | P1 | 缓存、会话、分布式锁 |
| P-021 | kafkax 完整实现 | kafkax | P1 | 事件流、消息队列 |
| P-022 | postgresx 完整实现 | postgresx | P2 | 关系型存储、事务 |
| P-023 | clickhousex 完整实现 | clickhousex | P2 | OLAP 查询、分析 |
| P-024 | taosx 评估 | taosx | P3 | 时序数据（可选，ClickHouse 可替代） |
| P-025 | ossx 评估 | ossx | P3 | 对象存储（回测数据、模型快照） |

### 平台化验收清单

- [ ] settlement: 每日 PnL 计算 + 交易所对账可运行
- [ ] alertx: 策略异常、风控触发、系统健康三类告警可触达
- [ ] alternative-data: 至少链上数据 + 社交情绪两类可用
- [ ] redisx/kafkax 完整实现，通过 contracts 稳定端口
- [ ] 所有模块测试覆盖率 ≥ 80%

---

## 阶段六：入口验收 — 完整闭环

> **目标：** x.go 组合根串联所有模块，验证从数据采集到交易执行的完整闭环。
>
> **前置依赖：** Phase 3 + Phase 4 完成。

### 6.1 x.go 最终集成

| # | 任务 | 说明 |
|---|------|------|
| X-001 | x.go wiring：configx → observex → resiliencx → schedulex → 数据域 → 分析域 → 决策域 → 执行域 |
| X-002 | 端到端烟雾测试：market-data → factor → signal → risk → paper order → portfolio → settlement |
| X-003 | 优雅停机验证：所有组件按拓扑序停止，无 goroutine 泄漏 |
| X-004 | 可观测性验证：metrics/logs/traces 覆盖完整链路 |

### 入口验收清单

- [ ] x.go 只包含配置加载、依赖 wiring 和生命周期控制
- [ ] 端到端烟雾测试全绿
- [ ] 优雅停机无泄漏
- [ ] 可观测性覆盖完整链路
- [ ] xlibgate check-all 全绿

---

## 横向任务（贯穿所有阶段）

### 文档与治理

| # | 任务 | 周期 | 说明 |
|---|------|------|------|
| H-001 | 14 个交易所 SDK 版本化发布 | Phase 1 | 建立 tagged release 机制 |
| H-002 | 宏观数据源适配器评估 | Phase 2 | 评估 6 个央行适配器合并可行性 |
| H-003 | strategies 定位澄清 | Phase 2 | 明确为策略研究参考库 |
| H-004 | 仓库命名规范化评估 | Phase 3 | 评估 `foundation-*`/`adapter-*`/`engine-*` 前缀重命名 |
| H-005 | observex 双重归属边界文档 | Phase 1 | 基座 vs 横切职责界定 |
| H-006 | secrectx 设计文档 | Phase 3 | 中期补，不污染 configx |

### 质量门禁

| # | 任务 | 周期 | 说明 |
|---|------|------|------|
| Q-001 | 每个模块 CI 独立 job + 覆盖率 ≥ 80% | 贯穿 | Foundation v1 已要求 |
| Q-002 | xlibgate import check 全域覆盖 | Phase 2 | 扩展到业务域 |
| Q-003 | Spec → Code 四源评分管线运行 | 贯穿 | 每个模块通过 spec-code-pipeline |
| Q-004 | 追溯矩阵完整性检查 | 贯穿 | 无孤儿 Task / 无空 AC |

---

## 关键依赖链

```text
Foundation v1 (F-001~F-022)
  │
  ├──→ 分析域契约 (A-001~A-004)
  │      │
  │      ├──→ 三引擎实现 (A-010~A-014)
  │      │      │
  │      │      └──→ regime_engine (A-012)
  │      │             │
  │      │             ├──→ 决策域契约 (D-001~D-003)
  │      │             │      │
  │      │             │      └──→ signal-factory (D-010)
  │      │             │             │
  │      │             │             ├──→ backtest-engine (D-012)
  │      │             │             │      │
  │      │             │             │      └──→ optimizer (D-015)
  │      │             │             │
  │      │             │             └──→ 执行域契约 (E-001~E-003)
  │      │             │                    │
  │      │             │                    └──→ risk-engine (E-010)
  │      │             │                           │
  │      │             │                           └──→ order-engine (E-012)
  │      │             │                                  │
  │      │             │                                  └──→ portfolio-engine (E-014)
  │      │             │                                         │
  │      │             │                                         └──→ settlement (P-001)
  │      │             │
  │      └──→ 因子管线 (A-020~A-023) ←── backtest feedback (D-014)
  │
  └──→ 存储层 (P-020~P-025) ←── 按需，不阻塞核心链路
```

---

## 风险与缓解

| # | 风险 | 级别 | 影响 | 缓解措施 |
|---|------|------|------|----------|
| R1 | 分析域/决策域/执行域完成度极低（5-8%） | 🔴 高 | 核心业务链路断裂 | 聚焦 Phase 1，先固化契约再实现 |
| R2 | resiliencx 身份未修复 | 🔴 高 | Foundation 层两个"标准源"冲突 | F-001 最高优先级 |
| R3 | x.go 2.8MB 体量异常 | 🟡 中 | 可能违反组合根边界 | F-021 体检与瘦身 |
| R4 | 14 个交易所 SDK 无版本号 | 🟡 中 | 无法追踪 API 兼容性 | H-001 版本化发布 |
| R5 | 宏观数据源同质化 | 🟡 中 | 维护成本高 | H-002 合并评估 |
| R6 | 单人开发 + AI 代理，资源有限 | 🟡 中 | 进度可能延期 | 严格优先级，先闭环后扩展 |
| R7 | 回测与实盘共享代码验证不足 | 🟡 中 | P6 原则未落地 | Phase 2 回测引擎必须验证共享代码路径 |

---

## 优先级决策矩阵

当资源冲突时，按以下优先级决策：

```text
1. 阻塞后续阶段的任务 > 独立任务
2. 契约固化 > 具体实现（先接口后实现）
3. 核心链路（数据→分析→决策→执行）> 边缘能力（另类数据、存储扩展）
4. 身份修复 > 新功能开发
5. 测试覆盖 > 文档完善
```

---

## 进度追踪

本文件是路线图的权威来源。各阶段的实际执行状态追踪在以下位置：

| 制品 | 位置 | 说明 |
|------|------|------|
| Foundation v1 进度 | `module/FOUNDATION-TRACKER.md` | P0/P1/P2 Issue 检查清单 |
| 模块规格状态 | `module/*/SPEC.md` | 每个模块的 23 节规格 |
| 追溯矩阵 | `module/*/TRACEABILITY.md` | FR → AC → TC 映射 |
| Spec 生命周期 | `docs/governance/LIFECYCLE.md` | 六态状态机 |
| 项目健康度 | `STATUS.md` | 实时组件状态 |
| 数据流 | `DATAFLOW.md` | 三引擎数据流全景 |

---

## 附录：模块完成度现状

### 基座层（16 个）

| 模块 | 进度 | 版本 | 下一步 |
|------|------|------|--------|
| kernel | ███░ 80% | v0.7.3 | API freeze + admission gate |
| configx | ███░ 80% | v0.1.4 | Provenance + Hash + Schema |
| observex | ███░ 80% | v0.3.1 | label/redaction gate |
| resiliencx | ██░░ 50% | v0.4.8 | **身份重置 + 策略实现** |
| schedulex | ███░ 80% | v0.1.2 | DST/misfire/lock contract |
| testkitx | ███░ 80% | v0.4.0 | boundary scanner + assert API |
| xlib-standard | - | - | 稳定 |
| xlibgate | - | - | CI 化 |
| redisx | █░░░ 15% | - | 完整实现 |
| kafkax | █░░░ 15% | - | 完整实现 |
| natsx | ███░ 80% | - | 稳定 |
| postgresx | █░░░ 15% | - | 按需实现 |
| taosx | █░░░ 15% | - | 评估必要性 |
| ossx | █░░░ 15% | - | 按需实现 |
| clickhousex | █░░░ 15% | - | 按需实现 |
| contracts | ███░ 80% | - | 扩展契约 |

### 业务域（35 个）

| 域 | 总数 | 平均进度 | 关键模块 |
|----|------|----------|----------|
| L2.5 | 4 | 80% ✅ | decimalx, domain-market, domain-exchange, domain-macro |
| 数据域·行情 | 19 | 80% | 14 SDK + 5 Provider |
| 数据域·宏观 | 10 | 80% | fred, treasury, bea, ecb, ... |
| 数据域·另类 | 1 | 5% | alternative-data |
| 分析域 | 7 | 8% | **factor-engine, market_regime, macro_regime, regime-engine** |
| 决策域 | 4 | 19% | **signal-factory, backtest-engine, optimizer** |
| 执行域 | 4 | 5% | **risk-engine, order-engine, portfolio-engine, settlement** |
| 横切 | 2 | 43% | alertx (5%), observex (80%) |

---

<p align="center">
  <i>构建稳定可靠的量化基础设施 ⚡ — 从基座到闭环，一步一步来。</i>
</p>
