# 🏗️ 分层架构

> FoundationX 量化交易基础设施的完整依赖拓扑

## 依赖关系图

```
                           xlib-standard
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                              L0: kernel                                      │
└──────────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│               L1: configx · observex · testkitx · resiliencx · schedulex           │
└──────────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│           L2: redisx · kafkax · natsx · postgresx · taosx · ossx · clickhousex       │
└──────────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                            L3: contracts                                     │
└──────────────────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
┌──────────────┐  ┌──────────────────────┐  ┌──────────────────────┐
│  xgo-market  │  │   xgo-macro-data     │  │  xgo-alternative-data│
│  -data (14)  │  │      (10)            │  │  链上·社交·新闻NLP   │
└──────┬───────┘  └──────────┬───────────┘  └──────────┬───────────┘
       └──────────────────────┼─────────────────────────┘
                              ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                       L4.5: 因子层                                            │
│                                                                              │
│  ┌───────────────────┐    ┌───────────────────┐    ┌───────────────────┐     │
│  │  factor-engine    │    │  feature-store    │    │  factor-eval      │     │
│  │  因子计算引擎      │    │  特征存储与版本    │    │  IC/IR/换手率评估  │     │
│  └───────────────────┘    └───────────────────┘    └───────────────────┘     │
└──────────────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                        L5: 策略与信号层                                        │
│                                                                              │
│  ┌───────────────────┐    ┌───────────────────┐    ┌───────────────────┐     │
│  │  signal-factory   │    │  backtest-engine  │    │  optimizer        │     │
│  │  信号生成与组合    │    │  事件驱动回测      │    │  参数优化/贝叶斯   │     │
│  └───────────────────┘    └───────────────────┘    └───────────────────┘     │
└──────────────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                      L5.5: 风控与执行层                                        │
│                                                                              │
│  ┌───────────────────┐    ┌───────────────────┐    ┌───────────────────┐     │
│  │  risk-engine      │    │  order-engine     │    │  portfolio-engine │     │
│  │  VaR·止损·限额    │    │  路由·TWAP·滑点   │    │  头寸·再平衡·Kelly │     │
│  └───────────────────┘    └───────────────────┘    └───────────────────┘     │
└──────────────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                           L6: 平台服务层                                       │
│                                                                              │
│        ┌───────────────────┐    ┌───────────────────┐    ┌──────────────┐    │
│        │  settlement       │    │  dashboard        │    │  alertx      │    │
│        │  结算与对账        │    │  监控面板          │    │  告警引擎    │    │
│        └───────────────────┘    └───────────────────┘    └──────────────┘    │
└──────────────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                             L7: 应用层                                        │
│                                                                              │
│                            ┌──────────┐                                      │
│                            │  x.go    │                                      │
│                            │  主程序   │                                      │
│                            └──────────┘                                      │
└──────────────────────────────────────────────────────────────────────────────┘
```

## 各层说明

| 层级 | 名称 | 职责 | 组件 |
|------|------|------|------|
| LS | 标准库 | 基础类型与工具约定 | xlib-standard |
| L0 | 内核层 | 生命周期、依赖注入、启动引导 | kernel |
| L1 | 基础设施层 | 配置、可观测性、测试、弹性、调度 | configx, observex, testkitx, resiliencx, schedulex |
| L2 | 存储与中间件层 | 数据存储与消息中间件抽象 | redisx, kafkax, natsx, postgresx, taosx, ossx, clickhousex |
| L3 | 契约层 | 跨模块接口与协议定义 | contracts |
| L4 | 数据层 | 行情、宏观、另类数据采集 | xgo-market-data, xgo-macro-data, xgo-alternative-data |
| L4.5 | 因子层 | 因子计算、存储与评估 | factor-engine, feature-store, factor-eval |
| L5 | 策略与信号层 | 信号生成、回测、参数优化 | signal-factory, backtest-engine, optimizer |
| L5.5 | 风控与执行层 | 风险管理、订单执行、组合管理 | risk-engine, order-engine, portfolio-engine |
| L6 | 平台服务层 | 结算、监控、告警 | settlement, dashboard, alertx |
| L7 | 应用层 | 最终可执行程序，编排所有引擎 | x.go |

## 核心设计原则

1. **风控是独立引擎** — 策略只能通过 risk-engine 提交订单，不能直接调用 order-engine
2. **回测与实盘共享代码** — signal-factory / factor-engine / risk-engine 同一套，backtest-engine 只替换数据源
3. **contracts 定义一切接口** — 每层通过 L3 的接口通信，实现可替换
4. **数据不跨层** — L4 只负责采集和存储，因子计算在 L4.5，策略逻辑在 L5
5. **执行抽象交易所差异** — order-engine 对上层暴露统一接口，内部适配各交易所
6. **x.go 只做编排** — L7 不含业务逻辑，仅负责启动、配置加载和引擎组装

## 状态总览

| 组件 | 状态 | 说明 |
|------|------|------|
| xgo-market-data | ✅ 已有 | 14 个交易所 SDK |
| xgo-macro-data | ✅ 已有 | 10 个宏观数据源 |
| strategies | ✅ 已有 | FMZ 策略集合，待演进为 signal-factory |
| xgo-alternative-data | ❌ 待建 | 链上数据、社交情绪、新闻 NLP |
| factor-engine | ❌ 待建 | 从原始数据计算 alpha 因子 |
| feature-store | ❌ 待建 | 因子版本管理、IC 评估 |
| signal-factory | ⚠️ 演进中 | 当前 strategies 偏 FMZ，缺多因子组合 |
| backtest-engine | ❌ 待建 | 事件驱动回测、Tick 级回放 |
| optimizer | ❌ 待建 | 参数搜索、Walk-forward 验证 |
| risk-engine | ❌ 待建 | **最关键** — 事前/事中/事后风控 |
| order-engine | ❌ 待建 | 智能路由、TWAP/VWAP、滑点控制 |
| portfolio-engine | ❌ 待建 | 多策略资金分配、再平衡 |
| settlement | ❌ 待建 | PnL 计算、交易所对账 |
| dashboard | ❌ 待建 | 实时监控面板 |
| alertx | ❌ 待建 | 策略异常、风控触发告警 |
| x.go | ❌ 待建 | 主程序，编排所有引擎 |

## 建议实现顺序

```
Phase 1: factor-engine + feature-store     ← 数据变现的第一步
Phase 2: signal-factory + risk-engine      ← 有了因子才能生成信号，有了信号才需要风控
Phase 3: order-engine + portfolio-engine   ← 风控通过后才能执行
Phase 4: backtest-engine + optimizer       ← 回测验证以上所有模块
Phase 5: settlement + dashboard + alertx   ← 平台服务
Phase 6: x.go                              ← 最终编排
```

---

## L4 子模块明细

### xgo-market-data（行情数据）

| 模块 | 说明 |
|------|------|
| [binance](https://github.com/ZoneCNH/binance) | 币安 Binance |
| [okx](https://github.com/ZoneCNH/okx) | OKX |
| [bybit](https://github.com/ZoneCNH/bybit) | Bybit |
| [bitget](https://github.com/ZoneCNH/bitget) | Bitget |
| [kucoin](https://github.com/ZoneCNH/kucoin) | KuCoin |
| [gate](https://github.com/ZoneCNH/gate) | Gate.io |
| [mexc](https://github.com/ZoneCNH/mexc) | MEXC |
| [htx](https://github.com/ZoneCNH/htx) | HTX (火币) |
| [coinbase](https://github.com/ZoneCNH/coinbase) | Coinbase |
| [hyperliquid](https://github.com/ZoneCNH/hyperliquid) | Hyperliquid |
| [lighter](https://github.com/ZoneCNH/lighter) | Lighter |
| [upbit](https://github.com/ZoneCNH/upbit) | Upbit |
| [coinglass](https://github.com/ZoneCNH/coinglass) | Coinglass 加密货币数据 |
| [yield-curve](https://github.com/ZoneCNH/yield-curve) | 收益率曲线 |

### xgo-macro-data（宏观数据）

| 模块 | 说明 |
|------|------|
| [fred](https://github.com/ZoneCNH/fred) | 美联储经济数据 (FRED) |
| [treasury](https://github.com/ZoneCNH/treasury) | 美国国债/财政数据 |
| [bea](https://github.com/ZoneCNH/bea) | 美国经济分析局 (BEA) |
| [ecb](https://github.com/ZoneCNH/ecb) | 欧洲央行 (ECB) |
| [uk-cb](https://github.com/ZoneCNH/uk-cb) | 英国央行 |
| [japan-cb](https://github.com/ZoneCNH/japan-cb) | 日本央行 |
| [eastmoney](https://github.com/ZoneCNH/eastmoney) | 东方财富 |
| [jinshi](https://github.com/ZoneCNH/jinshi) | 金十快讯 |
| [jin10](https://github.com/ZoneCNH/jin10) | 金十快讯 |
| [yahoo](https://github.com/ZoneCNH/yahoo) | Yahoo Finance |
