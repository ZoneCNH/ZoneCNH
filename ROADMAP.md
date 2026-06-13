# 🗺️ FoundationX ROADMAP

> 项目中长期规划的统一入口。不记录临时待办或过细实现细节。
>
> 编写规范见 [docs/governance/ROADMAP-RULES.md](./docs/governance/ROADMAP-RULES.md)（§1-54，含状态流转、决策规则、评审频率、标签规范）。
>
> 详细执行跟踪见 [module/FOUNDATION-TRACKER.md](./module/FOUNDATION-TRACKER.md)、[STATUS.md](./STATUS.md)、[DATAFLOW.md](./DATAFLOW.md)。

最后更新：2026-06-14

---

## Vision

构建完整的量化交易基础设施，实现从数据采集 → 因子计算 → Regime 识别 → 信号生成 → 风控执行 → 结算对账的端到端闭环。71 个模块各司其职，通过 contracts 契约解耦，x.go 作为组合根统一编排。

**长期目标：** 支撑多策略、多交易所、多资产类别的自动化量化交易系统。

---

## Current Focus

当前阶段最重要的三个方向：

1. **Foundation v1 基座闭环** — resiliencx 身份修复、Go baseline 统一、依赖矩阵 CI 化（阻塞所有后续阶段）
2. **分析域契约固化** — RegimeSnapshot / RegimeCard / DecisionCard DTO 定义（三引擎的前置条件）
3. **三引擎最小实现** — market_regime / macro_regime / regime_engine 核心逻辑（核心业务链路起点）
4. **SRE CI/CD 基础设施** — 机器池节点注册、Docker 服务编排、17 模块标准化 CI/CD 管线（部署自动化前置条件）

---

## Milestones

### v0.1.0 — Foundation v1 基座闭环

Status: In Progress
Priority: Critical
Target: v0.1.0
Target Date: 2026-08
Owner: ZoneCNH
Tags: architecture, maintenance

Description:

6 个基座模块 + x.go 组合根达到"可证明、可组合、可被上层消费"状态。所有后续阶段的前置条件。

Scope:

- resiliencx 身份重置（删除 Standard Source 叙事，回归 runtime resilience）
- Go baseline 统一到 Go 1.23
- foundationx compatibility 冻结
- Foundation 依赖矩阵 CI 化
- 各模块补最小 v1 能力（kernel/configx/observex/resiliencx/schedulex/testkitx）
- foundation-example 垂直烟雾测试
- x.go 体检与瘦身

Out of Scope:

- 存储层完整实现（redisx/kafkax/postgresx 等）
- 业务域模块开发
- secrectx / appx / runx 等新增模块

Done when:

- [ ] resiliencx README 不再包含 Standard Source / Generator / Harness 叙事
- [ ] 6 个模块 Go version 一致（1.23）
- [ ] xlibgate check-all exit code = 0
- [ ] foundation-example 可启动、可关闭、所有 make target 可运行
- [ ] x.go 体量合理（< 500KB），无业务逻辑泄漏
- [ ] 每个模块测试覆盖率 ≥ 80%（kernel ≥ 90%）

---

### v0.2.0 — 分析域：从数据到认知

Status: Planned
Priority: High
Target: v0.2.0
Target Date: 2026-11
Owner: ZoneCNH
Tags: feature, architecture

Description:

市场数据经因子计算、特征存储、因子评估，产出 RegimeSnapshot / RegimeCard / DecisionCard。核心业务链路的第一段。

Scope:

- 契约先行：固化 MarketDataProvider / MacroDataProvider / FactorInput / FactorOutput / RegimeSnapshot / RegimeCard / DecisionCard DTO
- 三引擎实现：market_regime（S1-S7）、macro_regime（M1-M7）、regime_engine（M×S 矩阵）
- 因子管线：factor-engine + feature-store + factor-eval + 初始因子库（10+ 基础因子）
- 黄金案例校验：2020 COVID / 2022 加息 / 2023 复苏

Out of Scope:

- 决策域和执行域
- 实盘交易
- 完整策略库

Done when:

- [ ] market_regime: S1-S7 分类器准确率 ≥ 80%（黄金案例集）
- [ ] macro_regime: M1-M7 分类器准确率 ≥ 80%（黄金案例集）
- [ ] regime_engine: M×S 矩阵 49 格全覆盖，冲突门逻辑正确
- [ ] factor-engine: ≥ 10 个因子可计算
- [ ] DecisionCard 输出可被下游消费
- [ ] 所有模块测试覆盖率 ≥ 80%

Blocked By:

- v0.1.0（Foundation v1）

---

### v0.3.0 — 决策域：从认知到信号

Status: Planned
Priority: High
Target: v0.3.0
Target Date: 2027-02
Owner: ZoneCNH
Tags: feature, architecture

Description:

DecisionCard 驱动信号生成，回测引擎验证策略，优化器调参。

Scope:

- 契约固化：SignalIntent / PortfolioTarget / BacktestConfig / BacktestReport / FactorFeedback
- signal-factory：DecisionCard 消费 + 信号生成 + 5 种策略模板
- backtest-engine：事件驱动引擎 + Tick 级回放 + 撮合模拟 + 回测报告
- optimizer：参数搜索 + Walk-forward 验证
- backtest → factor-eval 反馈闭环

Out of Scope:

- 实盘交易
- 完整风控系统
- 结算对账

Done when:

- [ ] DecisionCard → signal-factory → SignalIntent 端到端可跑通
- [ ] backtest-engine: 历史数据 Tick 级回放可运行
- [ ] 回测报告包含收益率、夏普比、最大回撤、胜率
- [ ] backtest → factor-eval 反馈闭环可运行
- [ ] 所有模块测试覆盖率 ≥ 80%

Blocked By:

- v0.2.0（分析域，至少 regime_engine + 契约）

---

### v0.4.0 — 执行域：从信号到交易

Status: Planned
Priority: High
Target: v0.4.0
Target Date: 2027-05
Owner: ZoneCNH
Tags: feature, security

Description:

SignalIntent 经风控放行、订单执行、组合管理，完成完整交易闭环。

Scope:

- 契约固化：RiskDecision / OrderIntent / ExecutionReport / PositionSnapshot / PnLReport / ExposureEvent
- risk-engine：trade_permission + VaR + 止损 + 持仓限额 + 压力测试 + DecisionCard 集成
- order-engine：统一订单接口 + 智能路由 + TWAP/VWAP + 滑点控制 + 交易所适配（paper trading）
- portfolio-engine：多策略资金分配 + 再平衡 + 仓位追踪
- 执行反馈闭环：fills/positions/PnL/exposure events → 决策域

Out of Scope:

- 实盘交易（仅 paper trading）
- 结算对账
- 另类数据

Done when:

- [ ] SignalIntent → risk-engine → paper order-engine → portfolio update 可跑通
- [ ] 策略只能通过 risk-engine 提交订单（P5 原则验证）
- [ ] 至少对接 2 个交易所 SDK（binance/okx）
- [ ] 执行反馈事件可回到决策域
- [ ] 所有模块测试覆盖率 ≥ 80%

Blocked By:

- v0.3.0（决策域，至少 signal-factory + 契约）

---

### v0.5.0 — 平台化：从交易到运维

Status: Planned
Priority: Medium
Target: v0.5.0
Target Date: 2027-08
Owner: ZoneCNH
Tags: feature, maintenance

Description:

结算对账、告警引擎、另类数据，完成生产化运维能力。

Scope:

- settlement：PnL 计算 + 交易所对账 + 资金流水
- alertx：策略异常 + 风控触发 + 系统健康三类告警
- alternative-data：链上数据 + 社交情绪 + 新闻 NLP
- 存储层分优先级实现：redisx / kafkax（P1 优先）、postgresx / clickhousex（P2 按数据量增长驱动）

Out of Scope:

- 实盘交易
- 完整监控平台

Done when:

- [ ] 每日 PnL 计算 + 交易所对账可运行
- [ ] 三类告警可触达
- [ ] 至少链上数据 + 社交情绪两类另类数据可用
- [ ] redisx / kafkax 完整实现

Blocked By:

- v0.4.0（执行域）

---

### v1.0.0 — 入口验收：完整闭环

Status: Planned
Priority: Medium
Target: v1.0.0
Target Date: 2027-10
Owner: ZoneCNH
Tags: architecture, testing

Description:

x.go 组合根串联所有模块，验证从数据采集到交易执行的完整闭环。

Scope:

- x.go wiring：configx → observex → resiliencx → schedulex → 数据域 → 分析域 → 决策域 → 执行域
- 端到端烟雾测试：market-data → factor → signal → risk → paper order → portfolio → settlement
- 优雅停机验证：所有组件按拓扑序停止，无 goroutine 泄漏
- 可观测性验证：metrics/logs/traces 覆盖完整链路

Out of Scope:

- 实盘交易
- 性能调优
- 多集群部署

Done when:

- [ ] x.go 只包含配置加载、依赖 wiring 和生命周期控制
- [ ] 端到端烟雾测试全绿
- [ ] 优雅停机无泄漏
- [ ] 可观测性覆盖完整链路
- [ ] xlibgate check-all 全绿

Blocked By:

- v0.4.0（执行域）+ v0.5.0（平台化，至少 settlement）

---

## Backlog

### 功能类

- [ ] 实盘交易模式（替代 paper trading） — `feature`
- [ ] 多集群部署支持 — `architecture`
- [ ] 策略市场 / 策略分享 — `feature`
- [ ] Web 管理界面 — `feature`
- [ ] 移动端监控 — `feature`

### 架构类

- [ ] secrectx 设计与实现（中期，不污染 configx） — `security`
- [ ] appx / runx 框架层（可选，当前不推荐） — `architecture`
- [ ] ratelimitx / lockx / eventx / httpx / cachex（按优先级排序：ratelimitx > cachex > lockx > eventx > httpx） — `architecture`
- [ ] 仓库命名规范化（`foundation-*` / `adapter-*` / `engine-*` 前缀） — `maintenance`

### 文档类

- [ ] observex 双重归属边界文档（基座 vs 横切） — `documentation`
- [ ] strategies 定位澄清（策略研究参考库） — `documentation`
- [ ] 快速开始文档 — `documentation`
- [ ] API 示例文档 — `documentation`

### 横切质量

- [ ] 每个模块 CI 独立 job + 覆盖率 ≥ 80% — `testing`
- [ ] xlibgate import check 全域覆盖 — `testing`
- [ ] Spec → Code 四源评分管线运行 — `testing`
- [ ] 追溯矩阵完整性检查（无孤儿 Task / 无空 AC） — `testing`
- [ ] 13 个交易所 SDK 版本化发布 — `maintenance`
- [ ] 宏观数据源适配器合并评估 — `maintenance`

---

## Risks & Dependencies

| 风险                                   | 级别     | Status     | 缓解措施                            |
| -------------------------------------- | -------- | ---------- | ----------------------------------- |
| 分析域/决策域/执行域完成度极低（5-8%） | Critical | Active     | 聚焦 v0.2.0，先固化契约再实现       |
| resiliencx 身份未修复                  | Critical | Active     | v0.1.0 最高优先级                   |
| x.go 2.8MB 体量异常                    | High     | Active     | v0.1.0 体检与瘦身                   |
| 13 个交易所 SDK 无版本号               | High     | Monitoring | Backlog 中跟进                      |
| 宏观数据源同质化                       | Medium   | Monitoring | Backlog 中评估合并                  |
| 单人开发 + AI 代理，资源有限           | Medium   | Active     | 严格优先级，先闭环后扩展            |
| 回测与实盘共享代码验证不足             | Medium   | Monitoring | v0.3.0 回测引擎必须验证共享代码路径 |

---

## Priority Rules

当资源冲突时，按以下优先级决策：

```text
1. 阻塞后续版本的任务 > 独立任务
2. 契约固化 > 具体实现（先接口后实现）
3. 核心链路（数据→分析→决策→执行）> 边缘能力（另类数据、存储扩展）
4. 身份修复 > 新功能开发
5. 测试覆盖 > 文档完善
```

---

## Deferred

> 延后处理的事项。移入前必须说明延后原因，移出时记录新目标版本。

当前无延后事项。

---

## Cancelled

> 已取消的事项。记录取消原因，保留历史决策上下文。

当前无取消事项。

---

## Release Gate

> 每个版本发布前必须满足以下门禁条件（§33）。

```md
- [ ] 当前版本目标全部完成或明确移出
- [ ] 关键测试通过
- [ ] README 已更新
- [ ] CHANGELOG 已更新
- [ ] 已知风险已记录
- [ ] 破坏性变更已说明（如有）
- [ ] 迁移说明已补充（如有）
- [ ] 没有未处理的 Critical 问题
```

---

## Review Rules

> Roadmap 应定期评审，避免变成过期文档（§27）。

| 项目阶段     | 建议频率       |
| ------------ | -------------- |
| 早期探索阶段 | 每 1-2 周      |
| 快速开发阶段 | 每 2-4 周      |
| 稳定维护阶段 | 每个版本结束后 |
| 长期维护项目 | 每 1-2 个月    |

长期未更新的条目应重新评估：30 天无变化检查状态，60 天评估版本归属，90 天考虑移入 Deferred 或 Backlog。

---

## Related Documents

| 文档                                                                   | 用途                                                               |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------ |
| [STATUS.md](./STATUS.md)                                               | 实时组件状态、健康度、风险追踪                                     |
| [DATAFLOW.md](./DATAFLOW.md)                                           | 三引擎数据流全景、M×S 矩阵、契约清单                               |
| [module/FOUNDATION-TRACKER.md](./module/FOUNDATION-TRACKER.md)         | Foundation v1 执行跟踪 — P0/P1/P2 Issue 检查清单                   |
| [module/](./module/)                                                   | 16 个基座模块 + x.go 的 23 节规格                                  |
| [docs/governance/](./docs/governance/)                                 | Spec 治理模板、生命周期、追溯与评分规则                            |
| [docs/governance/ROADMAP-RULES.md](./docs/governance/ROADMAP-RULES.md) | ROADMAP 编写规范 — 状态流转、决策规则、评审频率、标签规范（§1-54） |
| [CONSTITUTION.md](./CONSTITUTION.md)                                   | 系统宪法 — AI 代理最高治理文件                                     |
| [ARCHITECTURE.md](./ARCHITECTURE.md)                                   | 完整依赖拓扑、域间关系、运行时组装                                 |

---

## Changelog

### 2026-06-10

- 按 ROADMAP-RULES.md 规范（§1-54）优化，补齐 12 项合规缺口
- 增加 Owner / Tags / Target 字段到所有 Milestone（§5/§28/§36）
- 风险表增加 Status 列（Active / Monitoring）（§14）
- 增加 Deferred / Cancelled 区域（§10 状态流转）
- 增加 Release Gate 发布门禁（§33）
- 增加 Review Rules 评审频率（§27）
- Backlog 条目增加标签分类，清理模糊词"按需"（§28/§42）
- 头部增加 ROADMAP-RULES.md 规范引用
- Related Documents 增加 ROADMAP-RULES.md 链接

### 2026-06-09

- 初始化 ROADMAP.md
- 基于项目深度分析，制定六阶段交付路线图
- 综合 STATUS.md、ARCHITECTURE.md、CONSTITUTION.md、DATAFLOW.md、FOUNDATION-V1.md
- 识别核心矛盾：基座和数据层成熟（80%），核心业务链路空白（5-8%）
- 确定最高优先级：resiliencx 身份修复（F-001）

---

<p align="center">
  <i>构建稳定可靠的量化基础设施 ⚡ — 从基座到闭环，一步一步来。</i>
</p>
