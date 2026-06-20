# Product Spec: FoundationX

> FoundationX 量化交易基础设施的产品规格。

最后更新：2026-06-07
Status: Approved
Version: 1.0.0

---

## 1. Vision

FoundationX 是一套模块化的量化交易基础设施，为策略开发者提供开箱即用的数据采集、因子计算、信号生成、订单执行和风控能力。目标是让策略开发者专注于 alpha 研究，而不是基础设施搭建。

---

## 2. Target Users

| 用户角色   | 需求                                   |
| ---------- | -------------------------------------- |
| 策略开发者 | 专注因子和信号，不想搭基础设施         |
| 量化研究员 | 需要回测框架和历史数据                 |
| 运维工程师 | 需要可观测、可部署、可监控的系统       |
| AI 代理    | 需要清晰的模块边界和接口契约来自动开发 |

---

## 3. User Problems

- 量化系统搭建成本高，每个团队重复造轮子
- 模块间耦合严重，改一个模块影响全局
- 回测和实盘代码不共享，策略上线需要重写
- 风控逻辑分散在各处，无法统一管理
- 数据采集器按交易所拆分，新增交易所成本高
- 缺少统一的可观测性，故障定位困难

---

## 4. Product Goals

- **模块化**：70+ 独立模块，每个模块职责单一、可独立开发测试
- **分层架构**：基座 → 数据域 → 分析域 ⇄ 决策域 → 执行域 → x.go
- **回测/实盘共享**：因子、信号、风控代码在回测和实盘中完全共享
- **契约驱动**：跨域交互通过 `contracts` 定义的稳定接口
- **可观测**：统一的日志、指标、追踪、健康检查
- **AI 友好**：清晰的 spec、边界、验收标准，AI 代理可以按 spec 施工

---

## 5. Non-goals

- 不做 SaaS 平台（这是基础设施，不是产品）
- 不做策略推荐或 AI 自动交易
- 不做交易所本身（只做采集器和执行器）
- 不做移动端 App
- 不做实时协作（单用户部署）
- 不做通用回测框架（只服务 FoundationX 自己的策略）

---

## 6. Core Use Cases

### UC-01: 策略开发者接入新交易所

策略开发者需要接入 Binance 现货数据。
→ 使用 `market_data/binance` 采集器，配置 symbol 和 interval，启动后数据自动流入 Kafka。

### UC-02: 因子开发者添加新因子

因子开发者要实现一个新的动量因子。
→ 在 `factor_engine` 中实现 Factor 接口，注册到因子库，回测框架自动发现。

### UC-03: 风控规则调整

风控团队要调整最大持仓比例。
→ 修改 `risk_engine` 配置，无需改代码，热生效。

### UC-04: 系统故障排查

运维发现某个模块延迟升高。
→ 通过 `observex` 的 metrics 和 traces 定位到具体模块和方法。

### UC-05: AI 代理实现新模块

AI 代理被要求实现一个新的存储扩展模块。
→ 参考 `module/*/SPEC.md` 的 23 节结构，按 spec 施工，按验收标准自查。

---

## 7. MVP Scope (Foundation v1)

### Included

| 能力         | 模块                                                       |
| ------------ | ---------------------------------------------------------- |
| 生命周期管理 | kernel                                                     |
| 配置管理     | configx                                                    |
| 可观测性     | observex                                                   |
| 弹性策略     | resiliencx                                                 |
| 任务调度     | schedulex                                                  |
| 测试工具     | testkitx                                                   |
| Import 门禁  | xlibgate, xlib_standard                                    |
| 跨域契约     | contracts                                                  |
| 存储扩展     | redisx, kafkax, natsx, postgresx, taosx, ossx, clickhousex |

### Excluded (Future)

- 业务域模块（market_data, factor_engine, risk_engine 等）
- x.go 组合根的运行时实现（Foundation v1 仅保留组合根边界验收，不在 `module/` 下维护独立 x.go 规格）
- L2.5 领域共享层（decimalx, domain_market 等）
- 回测框架
- 实盘执行引擎
- Web UI / Dashboard

---

## 8. Success Metrics

| 指标           | 目标                                  | 度量方法                                                     |
| -------------- | ------------------------------------- | ------------------------------------------------------------ |
| 模块独立可测试 | 每个模块可以 `go test ./...` 独立运行 | CI 每个模块独立 job，覆盖率 ≥ 80%                            |
| 接口契约完整   | 所有跨域交互通过 `contracts` 接口     | xlibgate import check 零违规                                 |
| Spec 覆盖率    | Foundation 17/17 模块 spec 完整       | module/README.md 索引计数：Foundation=17，每个 spec 23/23 节 |
| CI Gate 通过   | 所有模块 CI 绿灯                      | xlibgate check-all exit code = 0                             |
| WHEN/THEN 覆盖 | 每个 FR 至少 1 条 WHEN/THEN           | TRACEABILITY.md 无空 AC 列                                   |
| 验收测试通过   | AT-001 至 AT-017 全部通过             | acceptance-tests.md 验收清单全勾                             |
| 术语统一       | 核心术语有权威定义                    | GLOSSARY.md 覆盖 ≥ 20 个术语                                 |
| 反需求明确     | 每个模块有不做清单                    | anti-requirements.md + 各 spec Non-goals 节                  |
| AI 可施工性    | AI 代理可以按 spec 独立实现模块       | Task Spec 必含 spec_ref、文件范围、验收标准和依赖关系        |

---

## 9. Stakeholders

| 角色      | 职责                                  |
| --------- | ------------------------------------- |
| ZoneCNH   | 产品负责人、架构师、唯一人类开发者    |
| AI 代理   | 按 spec 实现模块、写测试、review 代码 |
| GitHub CI | 自动化门禁、测试、构建                |
