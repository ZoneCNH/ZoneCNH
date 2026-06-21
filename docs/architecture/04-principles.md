# 📐 核心设计原则与进度校准

## 核心设计原则

1. **Foundation 先边界后功能** — 先固化 `xlib_standard`、依赖矩阵、Go baseline 和 release gate，再扩大 L1 能力面
2. **`xlib_standard` 不是运行时依赖** — 它是独立 Go module，承担标准事实源和 Go Reference Template 职责（Generator/Harness/Evidence 已拆分至 `xlib_harness` / `xlib_evidence`），不承载业务运行
3. **`resiliencx` 只做运行时弹性** — timeout/retry/circuit/bulkhead/rate/fallback 属于它，交易风控属于 `risk_engine`
4. **`testkitx` 只能 test-only** — 生产 import graph 不允许出现测试工具包
5. **风控是独立引擎** — 策略只能通过 risk_engine 提交订单，不能直接调用 order_engine
6. **回测与实盘共享代码** — signal_factory / factor_engine / risk_engine 同一套，backtest_engine 只替换数据源和撮合/回放环境
7. **contracts 只定义跨域稳定契约** — 跨域端口、事件协议、DTO 放在 contracts；域内接口留在域内，领域值对象放在 L2.5
8. **transportx 只定义应用通信底座契约** — Envelope/Endpoint、ServiceIdentity、QoS、Codec、RPC、EventBus、Stream、Outbox/Inbox、Audit Plane、Data Classification、SchemaRegistry 和 conformance gate 放在 transportx；具体 broker/client、协议 SDK、业务语义和领域模型留在 adapter 或业务域内
9. **领域语义沉到 L2.5** — 多域共享的 Price/Qty/Tick/Quote/MacroPoint 等模型统一来自 decimalx / domain-\*，避免各域重复定义
10. **数据职责不跨域** — 数据域只负责采集、标准化和存储，因子计算在分析域，策略逻辑在决策域
11. **执行抽象交易所差异** — order_engine 对上层暴露统一接口，内部适配各交易所
12. **反馈通过事件表达** — 执行结果、仓位、PnL、风险暴露以事件反馈决策域，避免执行域反向调用决策内部实现
13. **composer 只做组合根** — 不含业务逻辑，仅负责启动、配置加载、依赖组装和生命周期控制
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
