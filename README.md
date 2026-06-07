# 你好，我是 ZoneCNH 👋

**量化交易基础设施工程师** | 构建高性能、高可靠的金融数据与交易系统

## 🔧 技术栈

Go 🐹 (主要) · Rust 🦀 (底层) · Python 🐍 (脚本/数据) · TypeScript ⚡ (前端)

## 🏗️ 分层架构

> 📐 完整依赖拓扑、域间关系、运行时组装与子模块明细 → **[ARCHITECTURE.md](./ARCHITECTURE.md)**
>
> 🔄 三引擎数据流全景、M×S 联合决策矩阵与契约清单 → **[DATAFLOW.md](./DATAFLOW.md)**
>
> 📊 项目状态监控、健康度与风险追踪 → **[STATUS.md](./STATUS.md)**

```
入口: x.go (Composition Root: 启动 / 配置 / 组装)
      │
      ▼
基座: xlib-standard / kernel / configx / observex / testkitx / resiliencx / schedulex
      redisx / kafkax / natsx / postgresx / taosx / ossx / clickhousex / contracts
      │
      ▼
L2.5: decimalx / domain-market / domain-exchange / domain-macro
      │
      ▼
业务流: 数据域 → 分析域 ↔ 决策域 → 执行域
数据域: market-data (19) / macro-data (10) / alternative-data
分析域: factor-engine / feature-store / factor-eval / market_regime / macro_regime / regime-engine / mxs
       三引擎: market_engine(market facts → S state) / macro_engine(macro facts → M state) / regime_engine(M+S → action/risk/permission)
决策域: signal-factory / backtest-engine / optimizer / strategies
执行域: risk-engine → order-engine → portfolio-engine / settlement

反馈: backtest → factor-eval；fills / PnL / exposure events → 决策域
横切: alertx (告警) / observex (可观测)
```

## 📦 核心项目

### 基座 · 基础设施

- [kernel](https://github.com/ZoneCNH/kernel) — 核心基础框架 `公开` [本地](https://127.0.0.1/?folder=/home/kernel)
- [configx](https://github.com/ZoneCNH/configx) — 配置管理模块 `公开` [本地](https://127.0.0.1/?folder=/home/configx)
- [resiliencx](https://github.com/ZoneCNH/resiliencx) — 弹性与容错模块 `公开` [本地](https://127.0.0.1/?folder=/home/resiliencx)
- [observex](https://github.com/ZoneCNH/observex) — 可观测性模块 `公开` [本地](https://127.0.0.1/?folder=/home/observex)
- [schedulex](https://github.com/ZoneCNH/schedulex) — 调度任务模块 `公开` [本地](https://127.0.0.1/?folder=/home/schedulex)
- [testkitx](https://github.com/ZoneCNH/testkitx) — 测试工具包 `公开` [本地](https://127.0.0.1/?folder=/home/testkitx)
- [xlib-standard](https://github.com/ZoneCNH/xlib-standard) — 基础库规范（基座的前置依赖） `公开` [本地](https://127.0.0.1/?folder=/home/xlib-standard)
- [xlibgate](https://github.com/ZoneCNH/xlibgate) — 门禁与验证运行时 `公开` [本地](https://127.0.0.1/?folder=/home/xlibgate)

### 基座 · 存储与中间件

- [postgresx](https://github.com/ZoneCNH/postgresx) — PostgreSQL 模块 `公开` [本地](https://127.0.0.1/?folder=/home/postgresx)
- [redisx](https://github.com/ZoneCNH/redisx) — Redis 模块 `公开` [本地](https://127.0.0.1/?folder=/home/redisx)
- [clickhousex](https://github.com/ZoneCNH/clickhousex) — ClickHouse 模块 `公开` [本地](https://127.0.0.1/?folder=/home/clickhousex)
- [taosx](https://github.com/ZoneCNH/taosx) — TDengine 模块 `公开` [本地](https://127.0.0.1/?folder=/home/taosx)
- [kafkax](https://github.com/ZoneCNH/kafkax) — Kafka 模块 `公开` [本地](https://127.0.0.1/?folder=/home/kafkax)
- [natsx](https://github.com/ZoneCNH/natsx) — NATS 内部通信模块 `公开` [本地](https://127.0.0.1/?folder=/home/natsx)
- [ossx](https://github.com/ZoneCNH/ossx) — 对象存储 (OSS) 模块 `公开` [本地](https://127.0.0.1/?folder=/home/ossx)

### 基座 · 契约层

- [contracts](https://github.com/ZoneCNH/contracts) — 跨域稳定端口、事件协议与 DTO 契约 `公开` [本地](https://127.0.0.1/?folder=/home/contracts)

### L2.5 · 领域共享层

- [decimalx](https://github.com/ZoneCNH/decimalx) — 高精度十进制类型（Decimal/Price/Qty/Ratio/Money） `公开` [本地](https://127.0.0.1/?folder=/home/decimalx)
- [domain-market](https://github.com/ZoneCNH/domain-market) — 市场数据域模型（Tick/Quote/Bar/OrderBook） `公开` [本地](https://127.0.0.1/?folder=/home/domain-market)
- [domain-exchange](https://github.com/ZoneCNH/domain-exchange) — 交易域模型（VenueAdapter 13 方法接口） `公开` [本地](https://127.0.0.1/?folder=/home/domain-exchange)
- [domain-macro](https://github.com/ZoneCNH/domain-macro) — 宏观数据域模型（MacroPoint/MacroState） `公开` [本地](https://127.0.0.1/?folder=/home/domain-macro)

### 数据域 · market-data（SDK 14 + Provider 5）

**交易所 SDK：**
- [binance](https://github.com/ZoneCNH/binance) — 币安 Binance `公开` [本地](https://127.0.0.1/?folder=/home/binance)
- [okx](https://github.com/ZoneCNH/okx) — OKX `公开` [本地](https://127.0.0.1/?folder=/home/okx)
- [bybit](https://github.com/ZoneCNH/bybit) — Bybit `公开` [本地](https://127.0.0.1/?folder=/home/bybit)
- [bitget](https://github.com/ZoneCNH/bitget) — Bitget `公开` [本地](https://127.0.0.1/?folder=/home/bitget)
- [kucoin](https://github.com/ZoneCNH/kucoin) — KuCoin `公开` [本地](https://127.0.0.1/?folder=/home/kucoin)
- [gate](https://github.com/ZoneCNH/gate) — Gate.io `公开` [本地](https://127.0.0.1/?folder=/home/gate)
- [mexc](https://github.com/ZoneCNH/mexc) — MEXC `公开` [本地](https://127.0.0.1/?folder=/home/mexc)
- [htx](https://github.com/ZoneCNH/htx) — HTX (火币) `公开` [本地](https://127.0.0.1/?folder=/home/htx)
- [coinbase](https://github.com/ZoneCNH/coinbase) — Coinbase `公开` [本地](https://127.0.0.1/?folder=/home/coinbase)
- [hyperliquid](https://github.com/ZoneCNH/hyperliquid) — Hyperliquid `公开` [本地](https://127.0.0.1/?folder=/home/hyperliquid)
- [lighter](https://github.com/ZoneCNH/lighter) — Lighter `公开` [本地](https://127.0.0.1/?folder=/home/lighter)
- [upbit](https://github.com/ZoneCNH/upbit) — Upbit `公开` [本地](https://127.0.0.1/?folder=/home/upbit)
- [coinglass](https://github.com/ZoneCNH/coinglass) — Coinglass 加密货币数据 `公开` [本地](https://127.0.0.1/?folder=/home/coinglass)
- [yield-curve](https://github.com/ZoneCNH/yield-curve) — 收益率曲线 `公开` [本地](https://127.0.0.1/?folder=/home/yield-curve)

**Kline/Ticker Provider：**
- [binance-market](https://github.com/ZoneCNH/binance-market) — Binance `公开` [本地](https://127.0.0.1/?folder=/home/binance-market)
- [bybit-market](https://github.com/ZoneCNH/bybit-market) — Bybit `公开` [本地](https://127.0.0.1/?folder=/home/bybit-market)
- [bitget-market](https://github.com/ZoneCNH/bitget-market) — Bitget SPOT `公开` [本地](https://127.0.0.1/?folder=/home/bitget-market)
- [okx-market](https://github.com/ZoneCNH/okx-market) — OKX `公开` [本地](https://127.0.0.1/?folder=/home/okx-market)
- [coinbase-market](https://github.com/ZoneCNH/coinbase-market) — Coinbase `公开` [本地](https://127.0.0.1/?folder=/home/coinbase-market)

### 数据域 · macro-data

- [fred](https://github.com/ZoneCNH/fred) — 美联储经济数据 (FRED) `公开` [本地](https://127.0.0.1/?folder=/home/fred)
- [treasury](https://github.com/ZoneCNH/treasury) — 美国国债/财政数据 `公开` [本地](https://127.0.0.1/?folder=/home/treasury)
- [bea](https://github.com/ZoneCNH/bea) — 美国经济分析局 (BEA) `公开` [本地](https://127.0.0.1/?folder=/home/bea)
- [ecb](https://github.com/ZoneCNH/ecb) — 欧洲央行 (ECB) `公开` [本地](https://127.0.0.1/?folder=/home/ecb)
- [uk-cb](https://github.com/ZoneCNH/uk-cb) — 英国央行 `公开` [本地](https://127.0.0.1/?folder=/home/uk-cb)
- [japan-cb](https://github.com/ZoneCNH/japan-cb) — 日本央行 `公开` [本地](https://127.0.0.1/?folder=/home/japan-cb)
- [eastmoney](https://github.com/ZoneCNH/eastmoney) — 东方财富 `公开` [本地](https://127.0.0.1/?folder=/home/eastmoney)
- [jinshi](https://github.com/ZoneCNH/jinshi) — 金十快讯 `公开` [本地](https://127.0.0.1/?folder=/home/jinshi)
- [jin10](https://github.com/ZoneCNH/jin10) — 金十行情 `公开` [本地](https://127.0.0.1/?folder=/home/jin10)
- [yahoo](https://github.com/ZoneCNH/yahoo) — Yahoo Finance `公开` [本地](https://127.0.0.1/?folder=/home/yahoo)

### 数据域 · alternative-data

- [alternative-data](https://github.com/ZoneCNH/alternative-data) — 链上数据、社交情绪、新闻 NLP `公开` [本地](https://127.0.0.1/?folder=/home/alternative-data)

### 分析域

- [factor-engine](https://github.com/ZoneCNH/factor-engine) — 因子计算引擎 `公开` [本地](https://127.0.0.1/?folder=/home/factor-engine)
- [feature-store](https://github.com/ZoneCNH/feature-store) — 特征存储与版本管理 `公开` [本地](https://127.0.0.1/?folder=/home/feature-store)
- [factor-eval](https://github.com/ZoneCNH/factor-eval) — 因子评估 `公开` [本地](https://127.0.0.1/?folder=/home/factor-eval)
- [market_regime](https://github.com/ZoneCNH/market_regime) — 市场状态识别（S1-S7：多头趋势/挤空/空头/踩踏/震荡/低波/压缩） `私有` [本地](https://127.0.0.1/?folder=/home/market_regime)
- [macro_regime](https://github.com/ZoneCNH/macro_regime) — 宏观经济体制识别（M1-M7：流动牛市/再通复苏/软着繁荣/鹰派通胀/衰退降息/信用去杠/滞胀冲击） `私有` [本地](https://127.0.0.1/?folder=/home/macro_regime)
- [regime-engine](https://github.com/ZoneCNH/regime-engine) — M×S 联合决策引擎（M state + S state → action A-E / risk_tier / position_caps / trade_permission） `私有` [本地](https://127.0.0.1/?folder=/home/regime-engine)
- [mxs](https://github.com/ZoneCNH/mxs) — M×S 系统架构分析体系 `私有` [本地](https://127.0.0.1/?folder=/home/mxs)

### 决策域

- [signal-factory](https://github.com/ZoneCNH/signal-factory) — 信号生成与组合 `公开` [本地](https://127.0.0.1/?folder=/home/signal-factory)
- [backtest-engine](https://github.com/ZoneCNH/backtest-engine) — 事件驱动回测引擎 `公开` [本地](https://127.0.0.1/?folder=/home/backtest-engine)
- [optimizer](https://github.com/ZoneCNH/optimizer) — 参数优化 `公开` [本地](https://127.0.0.1/?folder=/home/optimizer)
- [strategies](https://github.com/ZoneCNH/strategies) — 策略研究与信号参考 `公开` [本地](https://127.0.0.1/?folder=/home/strategies)

### 执行域

- [risk-engine](https://github.com/ZoneCNH/risk-engine) — 风险管理引擎 `公开` [本地](https://127.0.0.1/?folder=/home/risk-engine)
- [order-engine](https://github.com/ZoneCNH/order-engine) — 订单执行引擎 `公开` [本地](https://127.0.0.1/?folder=/home/order-engine)
- [portfolio-engine](https://github.com/ZoneCNH/portfolio-engine) — 投资组合管理 `公开` [本地](https://127.0.0.1/?folder=/home/portfolio-engine)
- [settlement](https://github.com/ZoneCNH/settlement) — 结算与对账 `公开` [本地](https://127.0.0.1/?folder=/home/settlement)

### 横切 · 入口 · Rust

- [alertx](https://github.com/ZoneCNH/alertx) — 告警引擎 `公开` [本地](https://127.0.0.1/?folder=/home/alertx)
- [x.go](https://github.com/ZoneCNH/x.go) — 组合根，负责启动、配置加载与引擎组装 `私有` [本地](https://127.0.0.1/?folder=/home/x.go)
- [stdlib.rs](https://github.com/ZoneCNH/stdlib.rs) — Rust 标准库 `公开` [本地](https://127.0.0.1/?folder=/home/stdlib.rs)
- [specs](https://github.com/ZoneCNH/specs) — 项目技术规范与接口定义 `私有` [本地](https://127.0.0.1/?folder=/home/specs)

## 📊 GitHub 统计

<p align="center">
  <img src="https://github-readme-stats.vercel.app/api?username=ZoneCNH&show_icons=true&theme=radical&hide_border=true" alt="GitHub 统计" />
</p>

---

<p align="center">
  <i>构建稳定可靠的量化基础设施 ⚡</i>
</p>
