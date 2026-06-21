# 🚧 边界、域间关系与依赖守卫

## 边界与接口职责

| 边界                                                | 放什么                                                                       | 不放什么                                         |
| --------------------------------------------------- | ---------------------------------------------------------------------------- | ------------------------------------------------ |
| `xlib_standard`                                     | 标准事实源、Go Reference Template（Generator/Harness/Evidence 已拆分至 xlib_harness / xlib_evidence） | 运行时业务依赖、具体弹性策略实现                 |
| `kernel`                                            | 最小稳定原语和 stdlib-only 基础能力                                          | 配置解析、观测后端、业务 DTO、存储/网络适配器    |
| `configx` / `observex` / `resiliencx` / `schedulex` | L1 primitives 横切运行时能力，彼此通过窄接口协作                              | 业务模型、组合根职责、对彼此的强耦合反向依赖     |
| `testkitx`                                          | 测试、golden、contract、fixture、harness、boundary evidence                  | production import graph、真实外部系统入口        |
| `L2.5`                                              | 多个业务域共享的领域值对象、枚举、语义模型                                   | Provider 实现、策略逻辑、执行策略                |
| `contracts`                                         | 跨域稳定端口、事件协议、DTO 契约                                             | 域内接口、临时适配器、通用工具函数、领域模型全集 |
| `transportx`                                        | 应用通信底座契约：Envelope/Endpoint、ServiceIdentity、QoS、Codec、RPC、EventBus、Stream、Outbox/Inbox、Audit Plane、Data Classification、SchemaRegistry、conformance gate | 具体 broker/client、协议 SDK、业务语义、领域模型全集 |
| `composer`                                          | 配置加载、依赖创建、模块 wiring、生命周期管理                                | 因子计算、信号判断、风控规则、订单路由           |
| `observex` / `alertx`                               | 指标、追踪、日志、告警事件                                                   | 业务决策和风控放行逻辑                           |

## 域间关系与反馈

- **数据域 → 分析域**：单向，原始数据和标准化行情进入因子计算。
- **分析域 ↔ 决策域**：因子驱动信号生成；回测结果和评估指标反馈到 factor_eval / feature_store。
- **决策域 → 执行域**：信号必须先经过 riskx，禁止绕过风控直接调用 orderx。
- **执行域 → 决策域**：通过 fills / positions / PnL / exposure events 反馈组合再平衡和策略调整，不反向直接调用决策内部实现。
- **composer → 各域**：只做启动和组装依赖，不参与业务链路计算。

## 依赖守卫

| 守卫              | 允许                                                              | 禁止                                                                                         | 验收方式                                  |
| ----------------- | ----------------------------------------------------------------- | -------------------------------------------------------------------------------------------- | ----------------------------------------- |
| Foundation 矩阵   | L0/L1/runtime/test-only 依赖符合 Foundation 依赖矩阵              | 反向依赖、运行时导入 `testkitx`、L1 模块彼此强耦合                                           | `xlibgate` 或 import graph 检查           |
| Go baseline       | Foundation 模块共享 Go toolchain baseline                         | `testkitx` 单独拉高下游测试工具链，或 `configx` / `observex` 长期停留 `foundationx` 兼容垫片 | `go.mod` 扫描与 release evidence          |
| `resiliencx` 身份 | timeout/retry/circuit/bulkhead/rate/fallback/Compose/InstrumentStrategy/panic recovery | Standard Source、Generator、Harness 主身份回流到 `resiliencx`                                | README/docs 一致性 gate + contract tests  |
| `testkitx` 边界   | 仅测试包、测试 fixture、harness、boundary evidence 导入           | production Go 文件导入 `testkitx`                                                            | `make boundary-testkit` 或 import scan    |
| 可观测脱敏        | 低基数、非敏感 label；secret redaction 覆盖日志、health、manifest | `order_id`、`account_id`、`api_key`、trace id 等进入普通 metrics label                       | schema/golden + secret leak test          |
| 业务域依赖        | 数据域/分析域/决策域/执行域导入 L2.5、contracts 和基座            | 业务域互相导入实现包，尤其执行域反向导入决策域                                               | `go list` 或依赖图中无业务域实现包反向边  |
| 决策到执行        | signal_factory / optimizer 通过 riskx 提交执行意图                | 绕过 riskx 直接调用 orderx 或交易所 SDK                                                      | paper trade 链路能证明 risk gate 必经     |
| 执行反馈          | fills / positions / PnL / exposure 以事件进入决策域               | execution 包同步调用 strategy / backtest 内部实现                                            | 事件 topic、DTO 和消费方在 contracts 固化 |
| contracts         | 跨域端口、事件协议、DTO                                           | 领域模型全集、通用工具、域内临时接口                                                         | 新增契约必须说明消费方、生产方和稳定期    |
| transportx        | Envelope/Endpoint、ServiceIdentity、QoS、Codec、RPC、EventBus、Stream、Outbox/Inbox、Audit Plane、Data Classification、SchemaRegistry、conformance gate | 具体 broker/client、协议 SDK、业务语义、领域模型                                             | 新增通信契约必须说明 runtime / adapter 边界、QoS/codec/schema 兼容期和审计要求 |
| composer          | 读取配置、创建依赖、连接模块、管理生命周期                        | 因子计算、信号生成、风控判断、订单路由                                                       | 入口包只出现 wiring / lifecycle 测试      |

## 契约固化优先级

1. **数据输入契约**：MarketDataProvider / MacroDataProvider
2. **因子契约**：FactorInput / FactorOutput / FactorEvaluation
3. **决策契约**：SignalIntent / PortfolioTarget
4. **执行契约**：RiskDecision / OrderIntent / ExecutionReport
5. **反馈契约**：PositionSnapshot / PnLReport / ExposureEvent
