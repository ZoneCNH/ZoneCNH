# 🏗️ 分层架构

> FoundationX 量化交易基础设施的完整依赖拓扑
>
> 按职责域组织，域内模块平级协作，域间按数据流方向依赖

## 依赖关系图

```
                           xlib-standard
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                           基座 (Foundation)                                   │
│                                                                              │
│   kernel → configx · observex · testkitx · resiliencx · schedulex            │
│                                                                              │
│   redisx · kafkax · natsx · postgresx · taosx · ossx · clickhousex           │
│                                                                              │
│   contracts                                                                  │
└──────────────────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
┌──────────────┐  ┌──────────────────────┐  ┌──────────────────────┐
│  market-data │  │   macro-data         │  │  alternative-data    │
│    (14)      │  │      (10)            │  │  链上·社交·新闻NLP   │
└──────┬───────┘  └──────────┬───────────┘  └──────────┬───────────┘
       └──────────────────────┼─────────────────────────┘
                              │
                      ┌───────┴───────┐
                      │   数据域       │
                      │  (Data)       │
                      └───────┬───────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                           分析域 (Analytics)                                  │
│                                                                              │
│    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                  │
│    │ factor-engine │◄──►│ feature-store │◄──►│ factor-eval  │                  │
│    └──────────────┘    └──────────────┘    └──────────────┘                  │
│              ▲                  ▲                  ▲                          │
│              └──────────────────┼──────────────────┘                          │
│                        互相反馈，非线性                                        │
└──────────────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                           决策域 (Decision)                                   │
│                                                                              │
│    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                  │
│    │signal-factory│    │backtest-engine│    │  optimizer   │                  │
│    └──────┬───────┘    └──────┬───────┘    └──────┬───────┘                  │
│           └──────────────────┼────────────────────┘                          │
│                      并行协作，回测反馈因子评估                                 │
└──────────────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                           执行域 (Execution)                                  │
│                                                                              │
│    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                  │
│    │ risk-engine   │───►│ order-engine  │───►│portfolio-    │                  │
│    │              │    │              │    │engine        │                  │
│    └──────────────┘    └──────────────┘    └──────────────┘                  │
│                                                                              │
│    ┌──────────────┐                                                          │
│    │ settlement   │                                                          │
│    └──────────────┘                                                          │
└──────────────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                              x.go                                            │
└──────────────────────────────────────────────────────────────────────────────┘

横切关注点：
  alertx (告警) ─── 贯穿所有域，从每个域收集事件
  observex (可观测) ─── 贯穿所有域，统一 metrics / tracing / logging
```

## 各域说明

| 域 | 职责 | 组件 |
|------|------|------|
| 基座 | 生命周期、依赖注入、配置、可观测、存储、契约 | kernel, configx, observex, testkitx, resiliencx, schedulex, redisx, kafkax, natsx, postgresx, taosx, ossx, clickhousex, contracts |
| 数据域 | 行情、宏观、另类数据采集 | market-data, macro-data, alternative-data |
| 分析域 | 因子计算、特征存储、因子评估（互相反馈） | factor-engine, feature-store, factor-eval |
| 决策域 | 信号生成、历史回测、参数优化（并行协作） | signal-factory, backtest-engine, optimizer |
| 执行域 | 风险管理、订单执行、组合管理、结算 | risk-engine, order-engine, portfolio-engine, settlement |
| 入口 | 启动、配置加载、引擎组装 | x.go |
| 横切 | 告警、可观测性 | alertx, observex |

## 域间关系

```
数据域 ────→ 分析域 ────→ 决策域 ────→ 执行域 ────→ x.go
              ▲            │
              └────────────┘   回测结果反馈因子评估
                   反馈
```

- **数据域 → 分析域**：单向，原始数据流入因子计算
- **分析域 ↔ 决策域**：双向，因子驱动信号生成，回测结果反馈因子评估
- **决策域 → 执行域**：单向，信号经风控后提交执行
- **执行域 → 决策域**：反馈，执行结果影响组合再平衡和策略调整

## 核心设计原则

1. **风控是独立引擎** — 策略只能通过 risk-engine 提交订单，不能直接调用 order-engine
2. **回测与实盘共享代码** — signal-factory / factor-engine / risk-engine 同一套，backtest-engine 只替换数据源
3. **contracts 定义一切接口** — 域间通过 L3 的接口通信，实现可替换
4. **数据不跨域** — 数据域只负责采集和存储，因子计算在分析域，策略逻辑在决策域
5. **执行抽象交易所差异** — order-engine 对上层暴露统一接口，内部适配各交易所
6. **x.go 只做编排** — 不含业务逻辑，仅负责启动、配置加载和引擎组装
7. **域内平级协作** — 同域模块不编号、不分先后，按需协作

## 状态总览

| 域 | 组件 | 状态 | 说明 |
|------|------|------|------|
| 基座 | kernel, configx, observex, ... | ✅ 已有 | L0-L3 完整 |
| 数据域 | market-data | ✅ 已有 | 14 个交易所 SDK |
| 数据域 | macro-data | ✅ 已有 | 10 个宏观数据源 |
| 数据域 | alternative-data | ❌ 待建 | 链上数据、社交情绪、新闻 NLP |
| 分析域 | factor-engine | ❌ 待建 | 从原始数据计算 alpha 因子 |
| 分析域 | feature-store | ❌ 待建 | 因子版本管理、IC 评估 |
| 分析域 | factor-eval | ❌ 待建 | IC/IR/换手率评估 |
| 决策域 | signal-factory | ⚠️ 演进中 | 当前 strategies 偏 FMZ，缺多因子组合 |
| 决策域 | backtest-engine | ❌ 待建 | 事件驱动回测、Tick 级回放 |
| 决策域 | optimizer | ❌ 待建 | 参数搜索、Walk-forward 验证 |
| 执行域 | risk-engine | ❌ 待建 | **最关键** — 事前/事中/事后风控 |
| 执行域 | order-engine | ❌ 待建 | 智能路由、TWAP/VWAP、滑点控制 |
| 执行域 | portfolio-engine | ❌ 待建 | 多策略资金分配、再平衡 |
| 执行域 | settlement | ❌ 待建 | PnL 计算、交易所对账 |
| 入口 | x.go | ❌ 待建 | 主程序，编排所有引擎 |
| 横切 | alertx | ❌ 待建 | 策略异常、风控触发告警 |

## 建议实现顺序

```
Phase 1: 分析域  ← factor-engine + feature-store + factor-eval，数据变现第一步
Phase 2: 决策域  ← signal-factory + backtest-engine + optimizer，有了因子才能生成信号
Phase 3: 执行域  ← risk-engine + order-engine + portfolio-engine，风控通过后才能执行
Phase 4: 平台化  ← settlement + alertx，生产化
Phase 5: 入口    ← x.go，最终编排
```

---

## 数据域子模块明细

### market-data（行情数据）

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

### macro-data（宏观数据）

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
