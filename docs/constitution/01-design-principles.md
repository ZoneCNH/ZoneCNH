> **效力声明**：本文件内容提取自 [`CONSTITUTION.md`](../../CONSTITUTION.md)（FoundationX 最高治理文件）。
> 如本文件与根目录 `CONSTITUTION.md` 有差异，以 `CONSTITUTION.md` 为准。
>
> [← 上一节](00-branch-discipline.md) · [↑ 目录](README.md) · [下一节 →](02-module-boundaries.md)

---

## 第一条：设计原则（十三条不变量）

以下十三条原则是系统架构的基石，任何代码变更不得违背。

### 1.1 基座原则

| 编号 | 原则                           | 含义                                                                                                        |
| ---- | ------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| P1   | Foundation 先边界后功能        | 先固化 `xlib_standard`、依赖矩阵、Go baseline 和 release gate，再扩大 L1 能力面                             |
| P2   | `xlib_standard` 不是运行时依赖 | 它是标准事实源和 Go Reference Template 二类职责（Generator/Harness/Evidence 已拆分至 `xlib_harness` / `xlib_evidence`），不承载业务运行 |
| P3   | `resiliencx` 只做运行时弹性    | timeout/retry/circuit/bulkhead/rate/fallback 属于它，交易风控属于 `risk_engine`                             |
| P4   | `testkitx` 只能 test-only      | 生产 import graph 不允许出现测试工具包                                                                      |

### 1.2 领域原则

| 编号 | 原则                           | 含义                                                                                             |
| ---- | ------------------------------ | ------------------------------------------------------------------------------------------------ |
| P5   | 风控是独立引擎                 | 策略只能通过 risk_engine 提交订单，不能直接调用 order_engine                                     |
| P6   | 回测与实盘共享代码             | signal_factory / factor_engine / risk_engine 同一套，backtest_engine 只替换数据源和撮合/回放环境 |
| P7   | `contracts` 只定义跨域稳定契约 | 跨域端口、事件协议、DTO 放在 contracts；域内接口留在域内，领域值对象放在 L2.5                    |
| P8   | 领域语义沉到 L2.5              | 多域共享的 Price/Qty/Tick/Quote/MacroPoint 等模型统一来自 decimalx / domain-\*，避免各域重复定义 |
| P9   | 数据职责不跨域                 | 数据域只负责采集、标准化和存储，因子计算在分析域，策略逻辑在决策域                               |
| P10  | 执行抽象交易所差异             | order_engine 对上层暴露统一接口，内部适配各交易所                                                |
| P11  | 反馈通过事件表达               | 执行结果、仓位、PnL、风险暴露以事件反馈决策域，避免执行域反向调用决策内部实现                    |
| P12  | x.go 只做组合根                | 不含业务逻辑，仅负责启动、配置加载、依赖组装和生命周期控制                                       |
| P13  | 域内平级协作                   | 同域模块不编号、不分先后，按需协作                                                               |

---
