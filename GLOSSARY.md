# GLOSSARY — FoundationX 术语表

> FoundationX 系统中使用的专业术语及其定义。

最后更新：2026-06-07
Status: Approved

---

## 架构术语

### L2.5（领域共享层）

- **英文名：** Domain Shared Layer
- **中文名：** 领域共享层
- **定义：** 位于 L1 运行时模块和 L2 业务域模块之间的共享层，提供跨域通用的类型和工具，避免业务域之间的直接依赖。
- **所属模块：** `decimalx`、`domain-market`、`domain-exchange`、`domain-macro`

---

### 组合根（Composition Root）

- **英文名：** Composition Root
- **中文名：** 组合根
- **定义：** 应用中唯一知道所有模块具体实现的位置，负责读取配置、创建模块实例、组装依赖并启动应用。只做组合，不含业务逻辑。
- **所属模块：** `x.go`

---

### 横切（Cross-cutting）

- **英文名：** Cross-cutting Concern
- **中文名：** 横切关注点
- **定义：** 贯穿多个领域的通用能力，如告警、可观测性。横切模块被所有领域依赖，但不依赖任何业务域模块。
- **所属模块：** `alertx`、`observex`

---

### Domain Shared（领域共享模块）

- **英文名：** Domain Shared Module
- **中文名：** 领域共享模块
- **定义：** L2.5 层的模块，提供跨域通用的领域类型（如价格精度、交易所枚举、市场元数据），消除业务域之间的耦合。
- **所属模块：** `decimalx`、`domain-market`、`domain-exchange`、`domain-macro`

---

### 基座扩展（Foundation Extension）

- **英文名：** Foundation Extension
- **中文名：** 基座扩展
- **定义：** 在 kernel（L0 原语）之上提供中间件能力的模块，如 Redis 客户端、Kafka 客户端。被业务域模块通过接口消费。
- **所属模块：** `redisx`、`kafkax`、`postgresx` 等

---

### 契约（Contract）

- **英文名：** Contract
- **中文名：** 契约
- **定义：** 定义跨域接口的模块，是模块间通信的唯一合法通道。消费方通过 `contracts` 包获取接口定义，实现方在各自模块中实现。禁止跨域直接 import 实现。
- **所属模块：** `contracts`

---

### 门禁（Gate）

- **英文名：** Gate
- **中文名：** 门禁
- **定义：** 统一的访问控制和权限校验层，所有外部请求必须通过门禁校验后才能进入系统内部。
- **所属模块：** `xlibgate`

---

### 标准事实源（Standard of Truth）

- **英文名：** Standard of Truth
- **中文名：** 标准事实源
- **定义：** 系统中权威的数据来源，定义某个数据域的唯一真实值。其他模块必须从此获取数据，不得自行维护副本。
- **所属模块：** `xlib-standard`

---

### 弹性策略（Resilience Policy）

- **英文名：** Resilience Policy
- **中文名：** 弹性策略
- **定义：** 对外部调用的保护策略集合，包括重试、超时、熔断、降级等机制，防止级联故障。
- **所属模块：** `resiliencx`

---

## 量化交易术语

### 因子（Factor）

- **英文名：** Factor
- **中文名：** 因子
- **定义：** 量化交易中用于预测资产未来收益的变量或指标，如动量因子、波动率因子。因子通过因子引擎计算和管理。
- **所属模块：** `factor-engine`（待创建 spec）

---

### 信号（Signal）

- **英文名：** Signal
- **中文名：** 信号
- **定义：** 由一个或多个因子组合生成的交易决策指示，表示买入、卖出或持有。信号是策略引擎的输出，风控引擎的输入。
- **所属模块：** `signal-factory`（待创建 spec）

---

### Alpha（超额收益）

- **英文名：** Alpha
- **中文名：** 超额收益
- **定义：** 投资组合相对于基准（如市场指数）的超额回报。正 Alpha 表示跑赢市场，负 Alpha 表示跑输市场。量化策略的核心目标是持续获取正 Alpha。
- **所属模块：** 无特定模块，是量化交易的核心目标概念

---

### Regime（市场状态）

- **英文名：** Regime
- **中文名：** 市场状态
- **定义：** 市场运行的状态分类。系统使用 S1-S7 描述微观结构状态（如趋势、震荡、突破），M1-M7 描述宏观环境状态（如牛市、熊市、高波动）。策略根据当前 Regime 调整参数。
- **所属模块：** `factor-engine`、`signal-factory`

---

### DecisionCard（决策卡）

- **英文名：** DecisionCard
- **中文名：** 决策卡
- **定义：** 信号工厂输出的标准化交易决策结构体，包含交易方向、目标仓位、置信度、来源因子、风控约束等字段。是信号工厂到风控引擎的传递载体。
- **所属模块：** `signal-factory`

---

### TradePermission（交易许可）

- **英文名：** TradePermission
- **中文名：** 交易许可
- **定义：** 风控引擎对 DecisionCard 审批后的结果，包含是否允许交易、允许的仓位上限、附加条件（如止损线）。只有获得 TradePermission 的决策才能提交给订单引擎。
- **所属模块：** `risk-engine`（待创建 spec）

---

### PositionCaps（仓位上限）

- **英文名：** PositionCaps
- **中文名：** 仓位上限
- **定义：** 风控引擎设定的单品种和组合层面的仓位限制，包括单品种最大持仓、行业集中度上限、总杠杆上限等。TradePermission 中的允许仓位不会超过 PositionCaps。
- **所属模块：** `risk-engine`（待创建 spec）

---

### Walk-forward（滚动回测）

- **英文名：** Walk-forward Analysis
- **中文名：** 滚动回测
- **定义：** 将历史数据分为多个训练窗口和测试窗口，用训练窗口优化参数、测试窗口验证效果，逐段向前滚动。避免过拟合，是策略验证的标准方法。
- **所属模块：** `backtest-engine`（待创建 spec）

---

### IC / IR（信息系数 / 信息比率）

- **英文名：** Information Coefficient / Information Ratio
- **中文名：** 信息系数 / 信息比率
- **定义：** IC 衡量因子预测值与实际收益的相关性（Rank IC 通常 > 0.03 为有效因子）。IR 是因子 IC 的均值与标准差之比，衡量因子预测的稳定性（IR > 0.5 为优秀因子）。
- **所属模块：** `factor-eval`

---

### Slippage（滑点）

- **英文名：** Slippage
- **中文名：** 滑点
- **定义：** 预期成交价格与实际成交价格之间的差异。回测引擎使用滑点模型模拟真实交易成本，实盘通过 ExecutionReport 中的成交均价与决策价对比来度量实际滑点。
- **所属模块：** `backtest-engine`（待创建 spec）、`order-engine`（待创建 spec）

---

### TWAP / VWAP（时间加权均价 / 成交量加权均价）

- **英文名：** Time-Weighted Average Price / Volume-Weighted Average Price
- **中文名：** 时间加权均价 / 成交量加权均价
- **定义：** TWAP 将大单拆分为等时间间隔的小单执行，VWAP 按历史成交量分布拆分。两者都是算法交易的执行策略，用于降低大单对市场的冲击成本。
- **所属模块：** `order-engine`（待创建 spec）

---

### ExecutionReport（成交回报）

- **英文名：** ExecutionReport
- **中文名：** 成交回报
- **定义：** 订单引擎从交易所收到的成交确认，包含成交价格、数量、手续费、时间戳等。通过事件发布到决策域，用于更新持仓和计算实际滑点。
- **所属模块：** `order-engine`（待创建 spec）

---

### PortfolioTarget（目标持仓）

- **英文名：** PortfolioTarget
- **中文名：** 目标持仓
- **定义：** 优化器输出的最优持仓组合，包含每个品种的目标权重或数量。与当前持仓对比后生成 OrderIntent，提交给风控引擎审批。
- **所属模块：** `optimizer`（待创建 spec）、`portfolio-engine`（待创建 spec）

---

### FactorInput / FactorOutput（因子输入 / 因子输出）

- **英文名：** FactorInput / FactorOutput
- **中文名：** 因子输入 / 因子输出
- **定义：** FactorInput 是因子计算所需的标准化输入结构（行情快照、时间戳、品种列表）。FactorOutput 是因子计算结果（因子值、置信度、元数据）。两者定义在 `contracts` 中，确保因子引擎与上下游解耦。
- **所属模块：** `contracts`、`factor-engine`
